{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/geo-commander)
  @abstract: Standalone GeoJSON vector converter/processor
  @description: Turbo Pascal 7 / Free Pascal compatible; no external backend.
}
Program Ogr2Ogr;

Uses Dos;

Const
 MaxText = 255;
 MaxDepth = 100;
 WebRadius = 6378137.0;

Type
 TJson = ^TJsonRec;
 TStringPtr = ^String;
 TJsonRec = Record
  Kind: Byte;                 { 0 null, 1 boolean, 2 number, 3 string, 4 array, 5 object }
  Key, Value: TStringPtr;
  First, Last, Next: TJson;
 End;

Var
 Src, Dst, FormatName, TargetSRS, SourceSRS, AssignSRS: String;
 SelectFields, WhereExpr: String;
 SpatialSRS, GeometryType, Dimension: String;
 HasTarget, HasSource, HasAssign, HasSelect, HasWhere: Boolean;
 HasClipSrc, HasClipDst, HasSpat, HasSpatSRS, Overwrite: Boolean;
 HasLayerName, HasDim, DropDimensions, Quiet: Boolean;
 SpatXMin, SpatYMin, SpatXMax, SpatYMax: Real;
 PF: Text;
 JsonChar: Char;
 PName: String;
 PBuffer: Array[0..16383] Of Char;

Function UpperString(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
 UpperString:=S;
End;

Function TrimString(S: String): String;
Begin
 While (S<>'') And (S[1] In [' ',#9,#10,#13]) Do Delete(S,1,1);
 While (S<>'') And (S[Length(S)] In [' ',#9,#10,#13]) Do Delete(S,Length(S),1);
 TrimString:=S;
End;

Function IsNumber(S: String; Var Value: Real): Boolean;
Var Err: Integer;
Begin
 Val(S,Value,Err);
 IsNumber:=Err=0;
End;

Function FileExtension(S: String): String;
Var I, DotPos, BasePos: Integer;
Begin
 DotPos:=0; BasePos:=1;
 For I:=1 To Length(S) Do Begin
  If (S[I]='\') Or (S[I]='/') Then Begin BasePos:=I+1; DotPos:=0; End
  Else If S[I]='.' Then DotPos:=I;
 End;
 If (DotPos=0) Or (DotPos<BasePos) Then FileExtension:=''
 Else FileExtension:=UpperString(Copy(S,DotPos,Length(S)-DotPos+1));
End;

Function FileExistsLocal(FileName: String): Boolean;
Var F: File; Code: Integer;
Begin
 Assign(F,FileName);
 {$I-} Reset(F); Code:=IOResult; {$I+}
 FileExistsLocal:=Code=0;
 If Code=0 Then Close(F);
End;

Procedure Fail(Message: String);
Begin
 WriteLn('Erreur: ',Message);
 Halt(1);
End;

Procedure FailUsage(Message: String);
Begin
 WriteLn('Erreur: ',Message);
 WriteLn('Utilisez OGR2OGR /? pour l''aide.');
 Halt(1);
End;

Procedure NeedValue(Var I: Integer; OptionName: String; Var Value: String);
Begin
 Inc(I);
 If I>ParamCount Then FailUsage('valeur manquante apres '+OptionName);
 Value:=ParamStr(I);
End;

Function NewString(S: String): TStringPtr;
Var P: TStringPtr;
Begin
 GetMem(P,Length(S)+1);
 Move(S,P^,Length(S)+1);
 NewString:=P;
End;

Function NewNode(K: Byte): TJson;
Var N: TJson;
Begin
 New(N);
 N^.Kind:=K; N^.Key:=Nil; N^.Value:=Nil;
 N^.First:=Nil; N^.Last:=Nil; N^.Next:=Nil;
 NewNode:=N;
End;

Function NodeString(S: String): TJson;
Begin
 NodeString:=NewNode(3);
 NodeString^.Value:=NewString(S);
End;

Function NodeValue(N: TJson): String;
Begin
 If (N=Nil) Or (N^.Value=Nil) Then NodeValue:=''
 Else NodeValue:=N^.Value^;
End;

Function NodeKey(N: TJson): String;
Begin
 If (N=Nil) Or (N^.Key=Nil) Then NodeKey:=''
 Else NodeKey:=N^.Key^;
End;

Procedure AddNode(Parent, Child: TJson);
Begin
 Child^.Next:=Nil;
 If Parent^.Last=Nil Then Parent^.First:=Child
 Else Parent^.Last^.Next:=Child;
 Parent^.Last:=Child;
End;

Procedure AddPair(Parent: TJson; Key: String; Child: TJson);
Begin
 Child^.Key:=NewString(Key);
 AddNode(Parent,Child);
End;

Function FindNode(Parent: TJson; Key: String): TJson;
Var C: TJson;
Begin
 FindNode:=Nil;
 If (Parent=Nil) Or (Parent^.Kind<>5) Then Exit;
 C:=Parent^.First;
 While C<>Nil Do Begin
  If NodeKey(C)=Key Then Begin FindNode:=C; Exit; End;
  C:=C^.Next;
 End;
End;

Procedure ParserFail(Message: String);
Begin
 Fail('GeoJSON invalide dans '+PName+' ('+Message+')');
End;

Procedure NextChar;
Begin
 If EOF(PF) Then JsonChar:=#0 Else Read(PF,JsonChar);
End;

Procedure SkipWhite;
Begin
 While JsonChar In [' ',#9,#10,#13,#26] Do NextChar;
End;

Function HexDigit(C: Char): Integer;
Begin
 If C In ['0'..'9'] Then HexDigit:=Ord(C)-Ord('0')
 Else If UpCase(C) In ['A'..'F'] Then HexDigit:=Ord(UpCase(C))-Ord('A')+10
 Else HexDigit:=-1;
End;

Function ReadJsonString: String;
Var S: String; C: Char; H, I, Code: Integer;
Begin
 S:=''; NextChar;
 While JsonChar<>'"' Do Begin
  If JsonChar=#0 Then ParserFail('chaine non terminee');
  C:=JsonChar; NextChar;
  If C='\' Then Begin
  C:=JsonChar;
   If C=#0 Then ParserFail('chaine non terminee');
   NextChar;
   Case C Of
    '"','\','/': S:=S+C;
    'b': S:=S+#8;
    'f': S:=S+#12;
    'n': S:=S+#10;
    'r': S:=S+#13;
    't': S:=S+#9;
    'u': Begin
     Code:=0;
     For I:=1 To 4 Do Begin
      H:=HexDigit(JsonChar);
      If H<0 Then ParserFail('sequence unicode invalide');
      Code:=Code*16+H; NextChar;
     End;
     If Code<128 Then S:=S+Chr(Code)
     Else If Code<2048 Then S:=S+Chr(192+(Code Div 64))+Chr(128+(Code Mod 64))
     Else S:=S+Chr(224+(Code Div 4096))+Chr(128+((Code Div 64) Mod 64))+Chr(128+(Code Mod 64));
    End;
    Else ParserFail('sequence d''echappement invalide');
   End;
  End Else S:=S+C;
  If Length(S)>250 Then ParserFail('chaine de plus de 250 caracteres');
 End;
 NextChar;
 ReadJsonString:=S;
End;

Function ParseJson(Depth: Integer): TJson;
Var N, C: TJson; S, K: String; More: Boolean;
Begin
 SkipWhite;
 If Depth>MaxDepth Then ParserFail('imbrication trop profonde');
 Case JsonChar Of
  '{': Begin
   N:=NewNode(5); NextChar; SkipWhite;
  If JsonChar='}' Then NextChar
   Else Begin
    Repeat
     SkipWhite;
    If JsonChar<>'"' Then ParserFail('cle attendue');
     K:=ReadJsonString; SkipWhite;
    If JsonChar<>':' Then ParserFail('deux-points attendu');
     NextChar; C:=ParseJson(Depth+1); AddPair(N,K,C); SkipWhite;
    More:=JsonChar=',';
     If More Then NextChar;
    Until Not More;
    If JsonChar<>'}' Then ParserFail('accolade fermante attendue');
    NextChar;
   End;
   ParseJson:=N;
  End;
  '[': Begin
   N:=NewNode(4); NextChar; SkipWhite;
  If JsonChar=']' Then NextChar
   Else Begin
    Repeat
     C:=ParseJson(Depth+1); AddNode(N,C); SkipWhite;
    More:=JsonChar=',';
     If More Then NextChar;
    Until Not More;
    If JsonChar<>']' Then ParserFail('crochet fermant attendu');
    NextChar;
   End;
   ParseJson:=N;
  End;
  '"': Begin N:=NodeString(ReadJsonString); ParseJson:=N; End;
  '-','0'..'9': Begin
   S:='';
  While JsonChar In ['0'..'9','-','+','.','e','E'] Do Begin
    If Length(S)>=40 Then ParserFail('nombre trop long');
    S:=S+JsonChar; NextChar;
   End;
   N:=NewNode(2); N^.Value:=NewString(S); ParseJson:=N;
  End;
  't','f','n': Begin
   S:='';
  While JsonChar In ['a'..'z'] Do Begin S:=S+JsonChar; NextChar; End;
   If S='null' Then N:=NewNode(0)
   Else If (S='true') Or (S='false') Then Begin
    N:=NewNode(1); N^.Value:=NewString(S);
   End Else ParserFail('mot-cle invalide');
   ParseJson:=N;
  End;
  Else ParserFail('caractere inattendu');
 End;
End;

Function LoadGeoJSON(FileName: String): TJson;
Var Root: TJson;
Begin
 PName:=FileName;
 {$I-} Assign(PF,FileName); Reset(PF); {$I+}
 If IOResult<>0 Then Fail('impossible d''ouvrir '+FileName);
 SetTextBuf(PF,PBuffer); NextChar; Root:=ParseJson(0); SkipWhite; Close(PF);
 If JsonChar<>#0 Then Fail('texte apres la fin du GeoJSON '+FileName);
 If (Root^.Kind<>5) Or (NodeValue(FindNode(Root,'type'))<>'FeatureCollection') Or
    (FindNode(Root,'features')=Nil) Or (FindNode(Root,'features')^.Kind<>4) Then
  Fail('seules les GeoJSON FeatureCollection sont prises en charge: '+FileName);
 LoadGeoJSON:=Root;
End;

Procedure WriteQuoted(Var F: Text; S: String);
Var I: Integer; C: Char;
Begin
 Write(F,'"');
 For I:=1 To Length(S) Do Begin
  C:=S[I];
  Case C Of
   '"': Write(F,'\"');
   '\': Write(F,'\\');
   #8: Write(F,'\b');
   #9: Write(F,'\t');
   #10: Write(F,'\n');
   #12: Write(F,'\f');
   #13: Write(F,'\r');
   Else If Ord(C)<32 Then Write(F,' ')
   Else Write(F,C);
  End;
 End;
 Write(F,'"');
End;

Procedure WriteJson(Var F: Text; N: TJson);
Var C: TJson; First: Boolean;
Begin
 Case N^.Kind Of
  0: Write(F,'null');
  1,2: Write(F,NodeValue(N));
  3: WriteQuoted(F,NodeValue(N));
  4: Begin
   Write(F,'['); C:=N^.First; First:=True;
   While C<>Nil Do Begin
    If Not First Then Write(F,','); First:=False;
    WriteJson(F,C); C:=C^.Next;
   End;
   Write(F,']');
  End;
  5: Begin
   Write(F,'{'); C:=N^.First; First:=True;
   While C<>Nil Do Begin
    If Not First Then Write(F,','); First:=False;
    WriteQuoted(F,NodeKey(C)); Write(F,':'); WriteJson(F,C); C:=C^.Next;
   End;
   Write(F,'}');
  End;
 End;
End;

Procedure SaveGeoJSON(FileName: String; Root: TJson);
Var F: Text;
Begin
 {$I-} Assign(F,FileName); Rewrite(F); {$I+}
 If IOResult<>0 Then Fail('impossible de creer '+FileName);
 SetTextBuf(F,PBuffer); WriteJson(F,Root); WriteLn(F); Close(F);
End;

Function ParseCRS(S: String; DefaultCode: Integer): Integer;
Var U, T: String; P, I, Err: Integer; N: LongInt;
Begin
 U:=UpperString(TrimString(S));
 If U='' Then Begin ParseCRS:=DefaultCode; Exit; End;
 If (U='OGC:CRS84') Or (U='CRS84') Or (U='WGS84') Then Begin ParseCRS:=4326; Exit; End;
 If (Copy(U,1,5)='EPSG:') Or (Pos('URN:',U)=1) Or (Pos('HTTP:',U)=1) Then Begin
  P:=0;
  For I:=Length(U) DownTo 1 Do If U[I] In [':','/'] Then Begin P:=I; Break; End;
  T:=Copy(U,P+1,12);
 End Else T:=U;
 Val(T,N,Err);
 If Err<>0 Then Fail('CRS non reconnu: '+S);
 If (N<>4326) And (N<>3857) And (N<>900913) Then
  Fail('CRS non implemente: '+S+' (seuls EPSG:4326 et EPSG:3857 sont disponibles)');
 If N=900913 Then N:=3857;
 ParseCRS:=N;
End;

Function InputCRS(Root: TJson): Integer;
Var C, P: TJson;
Begin
 C:=FindNode(Root,'crs');
 If C=Nil Then Begin InputCRS:=4326; Exit; End;
 P:=FindNode(C,'properties');
 If P<>Nil Then P:=FindNode(P,'name');
 InputCRS:=ParseCRS(NodeValue(P),4326);
End;

Procedure SetCRS(Root: TJson; Code: Integer);
Var C, P, Prev, Cur: TJson; S: String;
Begin
 Prev:=Nil; Cur:=Root^.First;
 While Cur<>Nil Do Begin
  If NodeKey(Cur)='crs' Then Begin
   If Prev=Nil Then Root^.First:=Cur^.Next Else Prev^.Next:=Cur^.Next;
   If Root^.Last=Cur Then Root^.Last:=Prev;
   Break;
  End;
  Prev:=Cur; Cur:=Cur^.Next;
 End;
 If Code=4326 Then Exit;
 C:=NewNode(5); AddPair(C,'type',NodeString('name'));
 P:=NewNode(5); S:='urn:ogc:def:crs:EPSG::3857';
 AddPair(P,'name',NodeString(S)); AddPair(C,'properties',P);
 AddPair(Root,'crs',C);
End;

Procedure TransformCoordinates(N: TJson; SrcCode, DstCode: Integer);
Var C: TJson; X, Y: Real; Err: Integer; S: String;
Begin
 If (N=Nil) Or (N^.Kind<>4) Or (N^.First=Nil) Then Exit;
 C:=N^.First;
 If C^.Kind=2 Then Begin
  If C^.Next=Nil Then Fail('coordonnees GeoJSON invalides');
  Val(NodeValue(C),X,Err); If Err<>0 Then Fail('coordonnees invalides');
  Val(NodeValue(C^.Next),Y,Err); If Err<>0 Then Fail('coordonnees invalides');
  If (SrcCode=4326) And (DstCode=3857) Then Begin
   If Abs(Y)>85.0511287798066 Then Fail('latitude hors domaine EPSG:3857');
   X:=WebRadius*X*Pi/180;
  Y:=WebRadius*Ln(Sin(Pi/4+Y*Pi/360)/Cos(Pi/4+Y*Pi/360));
  End Else If (SrcCode=3857) And (DstCode=4326) Then Begin
   X:=X/WebRadius*180/Pi;
   Y:=(2*ArcTan(Exp(Y/WebRadius))-Pi/2)*180/Pi;
  End;
  Str(X:0:12,S); C^.Value:=NewString(TrimString(S));
  Str(Y:0:12,S); C^.Next^.Value:=NewString(TrimString(S));
 End Else Begin
  While C<>Nil Do Begin TransformCoordinates(C,SrcCode,DstCode); C:=C^.Next; End;
 End;
End;

Procedure TransformGeometry(N: TJson; SrcCode, DstCode: Integer);
Var C: TJson;
Begin
 If N=Nil Then Exit;
 If N^.Kind=5 Then Begin
  C:=N^.First;
  While C<>Nil Do Begin
   If NodeKey(C)='coordinates' Then TransformCoordinates(C,SrcCode,DstCode)
   Else TransformGeometry(C,SrcCode,DstCode);
   C:=C^.Next;
  End;
 End Else If N^.Kind=4 Then Begin
  C:=N^.First;
  While C<>Nil Do Begin TransformGeometry(C,SrcCode,DstCode); C:=C^.Next; End;
 End;
End;

Procedure DropCoordinateDimensions(N: TJson);
Var C, Prev: TJson;
Begin
 If (N=Nil) Or (N^.Kind<>4) Or (N^.First=Nil) Then Exit;
 C:=N^.First;
 If C^.Kind=2 Then Begin
  C:=C^.Next;
  If C=Nil Then Exit;
  Prev:=C; C:=C^.Next;
  If C=Nil Then Exit;
  Prev^.Next:=Nil; N^.Last:=Prev;
 End Else While C<>Nil Do Begin DropCoordinateDimensions(C); C:=C^.Next; End;
End;

Procedure DropGeometryDimensions(N: TJson);
Var C: TJson;
Begin
 If N=Nil Then Exit;
 If N^.Kind=5 Then Begin
  C:=N^.First;
  While C<>Nil Do Begin
   If NodeKey(C)='coordinates' Then DropCoordinateDimensions(C)
   Else DropGeometryDimensions(C);
   C:=C^.Next;
  End;
 End Else If N^.Kind=4 Then Begin
  C:=N^.First;
  While C<>Nil Do Begin DropGeometryDimensions(C); C:=C^.Next; End;
 End;
End;

Procedure GetBounds(N: TJson; Var HasPoint: Boolean; Var XMin,YMin,XMax,YMax: Real);
Var C: TJson; X,Y: Real; Err: Integer;
Begin
 If (N=Nil) Or (N^.Kind<>4) Or (N^.First=Nil) Then Exit;
 C:=N^.First;
 If C^.Kind=2 Then Begin
  If C^.Next=Nil Then Exit;
  Val(NodeValue(C),X,Err); If Err<>0 Then Exit;
  Val(NodeValue(C^.Next),Y,Err); If Err<>0 Then Exit;
  If Not HasPoint Then Begin XMin:=X; XMax:=X; YMin:=Y; YMax:=Y; HasPoint:=True; End
  Else Begin
   If X<XMin Then XMin:=X; If X>XMax Then XMax:=X;
   If Y<YMin Then YMin:=Y; If Y>YMax Then YMax:=Y;
  End;
 End Else While C<>Nil Do Begin GetBounds(C,HasPoint,XMin,YMin,XMax,YMax); C:=C^.Next; End;
End;

Procedure GetGeometryBounds(N: TJson; Var HasPoint: Boolean; Var XMin,YMin,XMax,YMax: Real);
Var C: TJson;
Begin
 If N=Nil Then Exit;
 If N^.Kind=5 Then Begin
  C:=N^.First;
  While C<>Nil Do Begin
   If NodeKey(C)='coordinates' Then GetBounds(C,HasPoint,XMin,YMin,XMax,YMax)
   Else GetGeometryBounds(C,HasPoint,XMin,YMin,XMax,YMax);
   C:=C^.Next;
  End;
 End Else If N^.Kind=4 Then Begin
  C:=N^.First;
  While C<>Nil Do Begin GetGeometryBounds(C,HasPoint,XMin,YMin,XMax,YMax); C:=C^.Next; End;
 End;
End;

Function PropertyMatches(Props: TJson; Clause: String): Boolean;
Var I, OpPos, OpLen: Integer; Op, FieldName, Wanted, Actual: String;
 X, Y: Real; V: TJson;
Begin
 Clause:=TrimString(Clause); OpPos:=0; OpLen:=0; Op:='';
 For I:=1 To Length(Clause) Do Begin
  If (I<Length(Clause)) And ((Copy(Clause,I,2)='>=') Or (Copy(Clause,I,2)='<=') Or (Copy(Clause,I,2)='<>') Or (Copy(Clause,I,2)='!=')) Then Begin
   OpPos:=I; OpLen:=2; Op:=Copy(Clause,I,2); Break;
  End;
  If Clause[I]='=' Then Begin OpPos:=I; OpLen:=1; Op:='='; Break; End;
  If Clause[I]='>' Then Begin OpPos:=I; OpLen:=1; Op:='>'; Break; End;
  If Clause[I]='<' Then Begin OpPos:=I; OpLen:=1; Op:='<'; Break; End;
 End;
 If OpPos=0 Then Fail('expression -where non prise en charge: '+Clause);
 FieldName:=TrimString(Copy(Clause,1,OpPos-1));
 If (Length(FieldName)>=2) And (FieldName[1]='"') And (FieldName[Length(FieldName)]='"') Then
  FieldName:=Copy(FieldName,2,Length(FieldName)-2);
 Wanted:=TrimString(Copy(Clause,OpPos+OpLen,MaxText));
 If Length(Wanted)>=2 Then
  If ((Wanted[1]='''') And (Wanted[Length(Wanted)]='''')) Or
     ((Wanted[1]='"') And (Wanted[Length(Wanted)]='"')) Then
   Wanted:=Copy(Wanted,2,Length(Wanted)-2);
 V:=FindNode(Props,FieldName);
 If V=Nil Then Begin PropertyMatches:=False; Exit; End;
 If V^.Kind=0 Then Begin PropertyMatches:=False; Exit; End;
 Actual:=NodeValue(V);
 If (V^.Kind=2) And IsNumber(Wanted,Y) And IsNumber(Actual,X) Then Begin
  If Op='=' Then PropertyMatches:=X=Y Else
  If (Op='<>') Or (Op='!=') Then PropertyMatches:=X<>Y Else
  If Op='>' Then PropertyMatches:=X>Y Else
  If Op='<' Then PropertyMatches:=X<Y Else
  If Op='>=' Then PropertyMatches:=X>=Y Else
  If Op='<=' Then PropertyMatches:=X<=Y Else PropertyMatches:=False;
 End Else Begin
  If (Op<>'=') And (Op<>'<>') And (Op<>'!=') Then
   Fail('comparaison ordonnee -where requiert un champ numerique: '+FieldName);
  If Op='=' Then PropertyMatches:=Actual=Wanted
  Else If (Op='<>') Or (Op='!=') Then PropertyMatches:=Actual<>Wanted
  Else PropertyMatches:=False;
 End;
End;

Function WhereMatches(Props: TJson; Expression: String): Boolean;
Var I, StartAt: Integer; Part, U: String; InQuote: Boolean; Q: Char;
Begin
 If Pos(' OR ',UpperString(Expression))>0 Then
  Fail('OR n''est pas supporte dans -where; utilisez AND');
 WhereMatches:=True; StartAt:=1; I:=1; InQuote:=False; Q:=#0;
 While I<=Length(Expression)+1 Do Begin
  If I<=Length(Expression) Then Begin
   If InQuote Then Begin If Expression[I]=Q Then InQuote:=False; End
   Else If Expression[I] In ['''','"'] Then Begin InQuote:=True; Q:=Expression[I]; End;
  End;
  U:=UpperString(Copy(Expression,I,5));
  If (I>Length(Expression)) Or ((Not InQuote) And (U=' AND ')) Then Begin
   Part:=TrimString(Copy(Expression,StartAt,I-StartAt));
   If Not PropertyMatches(Props,Part) Then Begin WhereMatches:=False; Exit; End;
   If I<=Length(Expression) Then Begin Inc(I,4); StartAt:=I+1; End;
  End;
  Inc(I);
 End;
End;

Function SelectedField(FieldName: String): Boolean;
Var S, Part: String; P: Integer;
Begin
 S:=SelectFields;
 While S<>'' Do Begin
  P:=Pos(',',S);
  If P=0 Then Begin Part:=TrimString(S); S:=''; End
  Else Begin Part:=TrimString(Copy(S,1,P-1)); Delete(S,1,P); End;
  If Part=FieldName Then Begin SelectedField:=True; Exit; End;
 End;
 SelectedField:=False;
End;

Procedure RetainProperties(Props: TJson);
Var C, Prev, Following: TJson;
Begin
 Prev:=Nil; C:=Props^.First;
 While C<>Nil Do Begin
  Following:=C^.Next;
  If Not SelectedField(NodeKey(C)) Then Begin
   If Prev=Nil Then Props^.First:=Following Else Prev^.Next:=Following;
   If Props^.Last=C Then Props^.Last:=Prev;
  End Else Prev:=C;
  C:=Following;
 End;
End;

Procedure ProcessLayer;
Var Root, Features, F, NextF, Geom, PrevF, Props: TJson;
 SrcCode, DstCode: Integer;
 Keep, HasPoint: Boolean;
 XMin,YMin,XMax,YMax: Real;
 CountIn, CountOut: LongInt;
Begin
 Root:=LoadGeoJSON(Src); Features:=FindNode(Root,'features');
 If HasSource Then SrcCode:=ParseCRS(SourceSRS,4326) Else SrcCode:=InputCRS(Root);
 DstCode:=SrcCode;
 If HasTarget Then DstCode:=ParseCRS(TargetSRS,SrcCode);
 CountIn:=0; CountOut:=0; F:=Features^.First; PrevF:=Nil;
 While F<>Nil Do Begin
  NextF:=F^.Next; Inc(CountIn); Keep:=True;
  If NodeValue(FindNode(F,'type'))<>'Feature' Then Fail('la collection contient un objet autre qu''une Feature');
  Props:=FindNode(F,'properties');
  Geom:=FindNode(F,'geometry');
  If HasWhere And (Not WhereMatches(Props,WhereExpr)) Then Keep:=False;
  If Keep And HasSpat Then Begin
  HasPoint:=False; GetGeometryBounds(Geom,HasPoint,XMin,YMin,XMax,YMax);
   Keep:=HasPoint And (XMax>=SpatXMin) And (XMin<=SpatXMax) And
         (YMax>=SpatYMin) And (YMin<=SpatYMax);
  End;
  If Keep Then Begin
  If DstCode<>SrcCode Then TransformGeometry(Geom,SrcCode,DstCode);
  If DropDimensions Then DropGeometryDimensions(Geom);
  If HasSelect And (Props<>Nil) Then RetainProperties(Props);
   Inc(CountOut); PrevF:=F;
  End Else Begin
   If PrevF=Nil Then Features^.First:=NextF Else PrevF^.Next:=NextF;
   If Features^.Last=F Then Features^.Last:=PrevF;
  End;
  F:=NextF;
 End;
 If HasAssign Then DstCode:=ParseCRS(AssignSRS,DstCode);
 SetCRS(Root,DstCode);
 SaveGeoJSON(Dst,Root);
 If Not Quiet Then WriteLn(CountOut,' of ',CountIn,' features written to ',Dst);
End;

Procedure ShowFormats;
Begin
 WriteLn('Formats standalone disponibles: GeoJSON (.geojson, .json)');
 WriteLn('CRS integres: EPSG:4326 et EPSG:3857.');
End;

Procedure StandaloneHelp;
Begin
 WriteLn('OGR2OGR - Cette commande permet d''effectuer des operations de conversion, reprojection ',
        'et filtres vectoriels.');
 WriteLn;
 WriteLn('Syntaxe: OGR2OGR GeoJSON en entree/sortie, aucun programme externe.');
 WriteLn;
 WriteLn('  -s_srs CRS  -t_srs CRS  -a_srs CRS  (EPSG:4326 / EPSG:3857)');
 WriteLn('  -select champs  -where champ op valeur [AND ...]  -spat xmin ymin xmax ymax');
 WriteLn('  -dim XY  -overwrite  -q  --formats  --help');
 WriteLn;
 WriteLn('Non supportes: autres formats/CRS, clipsrc/clipdst, spat_srs, append/update, SQL, nln/nlt.');
End;

Procedure StandaloneParse;
Var I, J, E: Integer; Arg, Value: String; V: Real;
Begin
 Src:=''; Dst:=''; FormatName:=''; SourceSRS:=''; TargetSRS:=''; AssignSRS:='';
 SelectFields:=''; WhereExpr:=''; HasSource:=False; HasTarget:=False; HasAssign:=False;
 HasSelect:=False; HasWhere:=False; HasSpat:=False; HasSpatSRS:=False;
 HasClipSrc:=False; HasClipDst:=False; HasLayerName:=False; GeometryType:='';
 HasDim:=False; DropDimensions:=False; Quiet:=False; Overwrite:=False;
 I:=1;
 While I<=ParamCount Do Begin
  Arg:=ParamStr(I);
  If (Arg='-h') Or (Arg='--help') Or (Arg='/?') Then Begin StandaloneHelp; Halt(0); End Else
  If Arg='--formats' Then Begin ShowFormats; Halt(0); End Else
  If (Arg='--version') Or (Arg='-V') Then Begin WriteLn('OGR2OGR Pascal standalone GeoJSON'); Halt(0); End Else
  If (Arg='-f') Or (Arg='-of') Then Begin NeedValue(I,Arg,FormatName); End Else
  If Arg='-s_srs' Then Begin NeedValue(I,Arg,SourceSRS); HasSource:=True; End Else
  If Arg='-t_srs' Then Begin NeedValue(I,Arg,TargetSRS); HasTarget:=True; End Else
  If Arg='-a_srs' Then Begin NeedValue(I,Arg,AssignSRS); HasAssign:=True; End Else
  If Arg='-select' Then Begin NeedValue(I,Arg,SelectFields); HasSelect:=True; End Else
  If Arg='-where' Then Begin NeedValue(I,Arg,WhereExpr); HasWhere:=True; End Else
  If Arg='-spat' Then Begin
   If I+4>ParamCount Then FailUsage('-spat attend xmin ymin xmax ymax');
   For J:=1 To 4 Do Begin Inc(I); Val(ParamStr(I),V,E); If E<>0 Then FailUsage('coordonnees -spat invalides');
    Case J Of 1: SpatXMin:=V; 2: SpatYMin:=V; 3: SpatXMax:=V; 4: SpatYMax:=V; End;
   End;
   If (SpatXMin>SpatXMax) Or (SpatYMin>SpatYMax) Then FailUsage('emprise -spat invalide');
   HasSpat:=True;
  End Else
  If Arg='-spat_srs' Then Begin NeedValue(I,Arg,SpatialSRS); HasSpatSRS:=True; End Else
  If Arg='-clipsrc' Then Begin NeedValue(I,Arg,Value); HasClipSrc:=True; End Else
  If Arg='-clipdst' Then Begin NeedValue(I,Arg,Value); HasClipDst:=True; End Else
  If Arg='-nln' Then Begin NeedValue(I,Arg,Value); HasLayerName:=True; End Else
  If Arg='-nlt' Then Begin NeedValue(I,Arg,GeometryType); End Else
  If Arg='-dim' Then Begin NeedValue(I,Arg,Dimension); HasDim:=True; End Else
  If Arg='-overwrite' Then Overwrite:=True Else
  If Arg='-q' Then Quiet:=True Else
  If Arg='-progress' Then FailUsage('-progress non implemente') Else
  If (Arg='-append') Or (Arg='-update') Or (Arg='-addfields') Or (Arg='-sql') Or
     (Arg='-dialect') Or (Arg='-ct') Or (Arg='-order') Or (Arg='-lco') Or
     (Arg='-dsco') Or (Arg='-oo') Or (Arg='-doo') Or (Arg='-gt') Or
     (Arg='-skipfailures') Then FailUsage(Arg+' non implemente') Else Begin
   If (Arg<>'') And (Arg[1]='-') Then FailUsage('option inconnue '+Arg);
   If Dst='' Then Dst:=Arg Else If Src='' Then Src:=Arg Else FailUsage('un seul fichier source est pris en charge');
  End;
  Inc(I);
 End;
 If (Dst='') Or (Src='') Then FailUsage('destination et source sont requises');
 If (FormatName<>'') And (UpperString(FormatName)<>'GEOJSON') And (UpperString(FormatName)<>'JSON') Then
  FailUsage('format non implemente: '+FormatName);
 If (FileExtension(Src)<>'.GEOJSON') And (FileExtension(Src)<>'.JSON') Then FailUsage('source GeoJSON requise');
 If FileExtension(Dst)='' Then Dst:=Dst+'.geojson';
 If (FileExtension(Dst)<>'.GEOJSON') And (FileExtension(Dst)<>'.JSON') Then FailUsage('destination GeoJSON requise');
 If HasLayerName Then FailUsage('-nln non implemente');
 If GeometryType<>'' Then FailUsage('-nlt non implemente');
 If HasDim Then Begin If UpperString(Dimension)<>'XY' Then FailUsage('seule la dimension XY est supportee'); DropDimensions:=True; End;
 If HasSpatSRS Then FailUsage('-spat_srs non implemente');
 If HasClipSrc Or HasClipDst Then FailUsage('-clipsrc/-clipdst non implementes');
 If FileExistsLocal(Dst) And (Not Overwrite) Then FailUsage('destination existante: utilisez -overwrite');
End;

BEGIN
 StandaloneParse;
 ProcessLayer;
END.
