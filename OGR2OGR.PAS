{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/geo-commander)
  @abstract: Standalone vector converter/processor
  @description: Turbo Pascal 7 / Free Pascal compatible; no external backend.
}
Program Ogr2Ogr;

Uses Dos;

{$IFNDEF FPC}{$N+}{$ENDIF}

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
Var N: TJson;
Begin
 N:=NewNode(3); N^.Value:=NewString(S); NodeString:=N;
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

Function ParseCRS(S: String; DefaultCode: LongInt): LongInt;
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
 If (N<>4326) And (N<>4269) And (N<>3857) And (N<>900913) And
   Not ((N>=32601) And (N<=32660)) And
   Not ((N>=32701) And (N<=32760)) And
   Not ((N>=26901) And (N<=26923)) Then Fail('CRS non implemente: '+S);
 If N=900913 Then N:=3857;
 ParseCRS:=N;
End;

Function InputCRS(Root: TJson): LongInt;
Var C, P: TJson;
Begin
 C:=FindNode(Root,'crs');
 If C=Nil Then Begin InputCRS:=4326; Exit; End;
 P:=FindNode(C,'properties');
 If P<>Nil Then P:=FindNode(P,'name');
 InputCRS:=ParseCRS(NodeValue(P),4326);
End;

Procedure SetCRS(Root: TJson; Code: LongInt);
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
 P:=NewNode(5); Str(Code,S); S:='urn:ogc:def:crs:EPSG::'+S;
 AddPair(P,'name',NodeString(S)); AddPair(C,'properties',P);
 AddPair(Root,'crs',C);
End;

{ Snyder transverse Mercator series, WGS84 or GRS80; no datum shift.
  UTM domain restricted to latitude -80..84 and +/- 6 degrees of meridian. }
Procedure UTMParameters(Code: LongInt; Var Lon0,E2,FalseNorth: Real);
Var Zone: LongInt; F: Real;
Begin
 F:=1/298.257223563; FalseNorth:=0;
 If (Code>=26901) And (Code<=26923) Then Begin
  Zone:=Code-26900; F:=1/298.257222101;
 End Else If Code>=32701 Then Begin Zone:=Code-32700; FalseNorth:=10000000; End
 Else Zone:=Code-32600;
 Lon0:=(Zone*6-183)*Pi/180; E2:=F*(2-F);
End;

Procedure UTMForward(Code: LongInt; Var X,Y: Real);
Var L0,E2,FN,L,P,N,T,C,A,M,E4,E6,EP: Real;
Begin
 UTMParameters(Code,L0,E2,FN); L:=X*Pi/180; P:=Y*Pi/180;
 If (Y < -80) Or (Y > 84) Or (Abs(L-L0)>6*Pi/180+1E-12) Then
  Fail('coordonnees hors domaine UTM (latitude -80..84, meridien +/-6 degres)');
 If ((FN=0) And (Y<0)) Or ((FN<>0) And (Y>0)) Then Fail('hemisphere UTM incompatible');
 EP:=E2/(1-E2); E4:=E2*E2; E6:=E4*E2;
 N:=WebRadius/Sqrt(1-E2*Sqr(Sin(P))); T:=Sqr(Sin(P)/Cos(P));
 C:=EP*Sqr(Cos(P)); A:=Cos(P)*(L-L0);
 M:=WebRadius*((1-E2/4-3*E4/64-5*E6/256)*P-
  (3*E2/8+3*E4/32+45*E6/1024)*Sin(2*P)+
  (15*E4/256+45*E6/1024)*Sin(4*P)-35*E6/3072*Sin(6*P));
 X:=500000+0.9996*N*(A+(1-T+C)*A*Sqr(A)/6+
  (5-18*T+T*T+72*C-58*EP)*A*Sqr(Sqr(A))/120);
 Y:=FN+0.9996*(M+N*Sin(P)/Cos(P)*(A*A/2+
  (5-T+9*C+4*C*C)*Sqr(Sqr(A))/24+
  (61-58*T+T*T+600*C-330*EP)*Sqr(A)*Sqr(Sqr(A))/720));
End;

Procedure UTMInverse(Code: LongInt; Var X,Y: Real);
Var L0,E2,FN,E1,MU,P,N,R,T,C,D,EP,E4,E6,L,Lat: Real;
Begin
 UTMParameters(Code,L0,E2,FN); EP:=E2/(1-E2); E4:=Sqr(E2); E6:=E4*E2;
 If (X<100000) Or (X>900000) Or (Y<0) Or (Y>10000000) Then Fail('coordonnees UTM invalides');
 MU:=(Y-FN)/(0.9996*WebRadius*(1-E2/4-3*E4/64-5*E6/256));
 E1:=(1-Sqrt(1-E2))/(1+Sqrt(1-E2));
 P:=MU+(3*E1/2-27*E1*Sqr(E1)/32)*Sin(2*MU)+
  (21*Sqr(E1)/16-55*Sqr(Sqr(E1))/32)*Sin(4*MU)+
  151*E1*Sqr(E1)/96*Sin(6*MU)+1097*Sqr(Sqr(E1))/512*Sin(8*MU);
 N:=WebRadius/Sqrt(1-E2*Sqr(Sin(P)));
 R:=WebRadius*(1-E2)/((1-E2*Sqr(Sin(P)))*Sqrt(1-E2*Sqr(Sin(P))));
 T:=Sqr(Sin(P)/Cos(P)); C:=EP*Sqr(Cos(P)); D:=(X-500000)/(N*0.9996);
 Lat:=P-N*Sin(P)/Cos(P)/R*(D*D/2-(5+3*T+10*C-4*C*C-9*EP)*Sqr(Sqr(D))/24+
  (61+90*T+298*C+45*T*T-252*EP-3*C*C)*Sqr(D)*Sqr(Sqr(D))/720);
 L:=L0+(D-(1+2*T+C)*D*Sqr(D)/6+
  (5-2*C+28*T-3*C*C+8*EP+24*T*T)*D*Sqr(Sqr(D))/120)/Cos(P);
 X:=L*180/Pi; Y:=Lat*180/Pi;
 If (Y < -80.000001) Or (Y > 84.000001) Or (Abs(L-L0)>6*Pi/180+1E-8) Then Fail('coordonnees hors domaine UTM');
End;

Procedure ProjectXY(SrcCode,DstCode: LongInt; Var X,Y: Real);
Begin
 If SrcCode=DstCode Then Exit;
 If SrcCode=3857 Then Begin
  X:=X/WebRadius*180/Pi;
  If Abs(Y/WebRadius)>710 Then Fail('ordonnee Mercator invalide');
  Y:=(2*ArcTan(Exp(Y/WebRadius))-Pi/2)*180/Pi;
 End Else If (SrcCode<>4326) And (SrcCode<>4269) Then UTMInverse(SrcCode,X,Y);
 If DstCode=3857 Then Begin
  If Abs(Y)>85.0511287798066 Then Fail('latitude hors domaine EPSG:3857');
  X:=WebRadius*X*Pi/180;
  Y:=WebRadius*Ln(Sin(Pi/4+Y*Pi/360)/Cos(Pi/4+Y*Pi/360));
 End Else If (DstCode<>4326) And (DstCode<>4269) Then UTMForward(DstCode,X,Y);
End;

Procedure TransformCoordinates(N: TJson; SrcCode, DstCode: LongInt);
Var C: TJson; X, Y: Real; Err: Integer; S: String;
Begin
 If (N=Nil) Or (N^.Kind<>4) Or (N^.First=Nil) Then Exit;
 C:=N^.First;
 If C^.Kind=2 Then Begin
  If C^.Next=Nil Then Fail('coordonnees GeoJSON invalides');
  Val(NodeValue(C),X,Err); If Err<>0 Then Fail('coordonnees invalides');
  Val(NodeValue(C^.Next),Y,Err); If Err<>0 Then Fail('coordonnees invalides');
  ProjectXY(SrcCode,DstCode,X,Y);
  Str(X:0:12,S); C^.Value:=NewString(TrimString(S));
  Str(Y:0:12,S); C^.Next^.Value:=NewString(TrimString(S));
 End Else Begin
  While C<>Nil Do Begin TransformCoordinates(C,SrcCode,DstCode); C:=C^.Next; End;
 End;
End;

Procedure TransformGeometry(N: TJson; SrcCode, DstCode: LongInt);
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

{ All format adapters use the same feature tree and filtering pipeline. }
Const
 MaxFields = 128;
 MaxParts = 1024;
Type
 TField = Record
  Name: String[250]; Kind: Char; Width, Decimals: Byte;
 End;
 TRingPtr = ^TRing;
 TRing = Record
  Co, Poly: TJson; Depth: Integer; Next: TRingPtr;
 End;
Var
 Fields: Array[1..MaxFields] Of TField;
 FieldCount: Integer;
 WChunk: TJson;
 WPos: Integer;
 WChar: Char;

Function NumberNode(X: Real): TJson;
Var S: String; N: TJson;
Begin
 Str(X:0:12,S); N:=NewNode(2); N^.Value:=NewString(TrimString(S)); NumberNode:=N;
End;

Function XYNode(X,Y: Real): TJson;
Var N: TJson;
Begin
 N:=NewNode(4); AddNode(N,NumberNode(X)); AddNode(N,NumberNode(Y)); XYNode:=N;
End;

Function GeometryNode(T: String; Co: TJson): TJson;
Var N: TJson;
Begin
 N:=NewNode(5); AddPair(N,'type',NodeString(T)); AddPair(N,'coordinates',Co); GeometryNode:=N;
End;

Function CollectionNode: TJson;
Var N: TJson;
Begin
 N:=NewNode(5); AddPair(N,'type',NodeString('FeatureCollection'));
 AddPair(N,'features',NewNode(4)); CollectionNode:=N;
End;

Procedure AddFeature(Root,Geom,Props: TJson);
Var F: TJson;
Begin
 F:=NewNode(5); AddPair(F,'type',NodeString('Feature'));
 AddPair(F,'geometry',Geom); AddPair(F,'properties',Props);
 AddNode(FindNode(Root,'features'),F);
End;

Function NodeCount(N: TJson): LongInt;
Var C: TJson; K: LongInt;
Begin
 K:=0; If N<>Nil Then Begin C:=N^.First; While C<>Nil Do Begin Inc(K); C:=C^.Next; End; End;
 NodeCount:=K;
End;

Function NodeReal(N: TJson): Real;
Var X: Real;
Begin
 If N=Nil Then Fail('coordonnee manquante');
 If Not IsNumber(NodeValue(N),X) Then Fail('coordonnee non numerique');
 NodeReal:=X;
End;

Function ChangeExtension(Path,Ext: String): String;
Var Old: String;
Begin
 Old:=FileExtension(Path); ChangeExtension:=Copy(Path,1,Length(Path)-Length(Old))+Ext;
End;

Function SideFile(Path,Ext: String): String;
Var S: String;
Begin
 S:=ChangeExtension(Path,Ext);
 If Not FileExistsLocal(S) Then S:=ChangeExtension(Path,UpperString(Ext));
 SideFile:=S;
End;

Procedure FreeTree(N: TJson);
Var C,T: TJson;
Begin
 If N=Nil Then Exit;
 C:=N^.First; While C<>Nil Do Begin T:=C^.Next; FreeTree(C); C:=T; End;
 If N^.Key<>Nil Then FreeMem(N^.Key,Length(N^.Key^)+1);
 If N^.Value<>Nil Then FreeMem(N^.Value,Length(N^.Value^)+1);
 Dispose(N);
End;

{ Streaming CSV: cells are chunked so WKT may exceed the short-string limit.
  Only attribute values and field names have a 250 byte limit. }
Function ReadCSVCell(Var F: Text; Var EndRow,WasQuoted: Boolean): TJson;
Var Cell: TJson; S: String; C: Char; Done,Closed: Boolean;
Begin
 Cell:=NewNode(4); S:=''; EndRow:=False; WasQuoted:=False; Done:=False; Closed:=False;
 If EOF(F) Then Begin EndRow:=True; ReadCSVCell:=Cell; Exit; End;
 Read(F,C);
 If C='"' Then Begin
  WasQuoted:=True;
  While Not Done Do Begin
   If EOF(F) Then Fail('CSV: guillemet non termine'); Read(F,C);
   If C='"' Then Begin
    If EOF(F) Then Begin Closed:=True; Done:=True; End
    Else Begin
     Read(F,C);
     If C<>'"' Then Begin Closed:=True; Done:=True; End
     Else Begin S:=S+C; If Length(S)=250 Then Begin AddNode(Cell,NodeString(S)); S:=''; End; End;
    End;
   End Else Begin S:=S+C; If Length(S)=250 Then Begin AddNode(Cell,NodeString(S)); S:=''; End; End;
  End;
  If Closed And EOF(F) And (C='"') Then EndRow:=True
  Else If C=',' Then EndRow:=False
  Else If C In [#10,#13] Then Begin
   EndRow:=True;
   If (C=#13) And Not EOF(F) Then Begin
    { Text input normalizes CRLF under DOS/Windows; ReadLn consumes LF. }
    If EOLn(F) Then ReadLn(F);
   End;
  End Else Fail('CSV: caractere apres guillemet');
 End Else Begin
  Repeat
   If C=',' Then Done:=True
   Else If C In [#10,#13] Then Begin Done:=True; EndRow:=True;
    If (C=#13) And Not EOF(F) Then If EOLn(F) Then ReadLn(F);
   End Else Begin S:=S+C; If Length(S)=250 Then Begin AddNode(Cell,NodeString(S)); S:=''; End; End;
   If Not Done Then Begin If EOF(F) Then Begin Done:=True; EndRow:=True; End Else Read(F,C); End;
  Until Done;
 End;
 If S<>'' Then AddNode(Cell,NodeString(S)); ReadCSVCell:=Cell;
End;

Function CellString(Cell: TJson): String;
Var C: TJson; S: String;
Begin
 S:=''; C:=Cell^.First;
 While C<>Nil Do Begin
  If Length(S)+Length(NodeValue(C))>250 Then Fail('CSV: attribut/nom de plus de 250 octets');
  S:=S+NodeValue(C); C:=C^.Next;
 End;
 CellString:=S;
End;

Procedure WNext;
Begin
 While WChunk<>Nil Do Begin
  If WPos<=Length(WChunk^.Value^) Then Begin WChar:=WChunk^.Value^[WPos]; Inc(WPos); Exit; End;
  WChunk:=WChunk^.Next; WPos:=1;
 End;
 WChar:=#0;
End;

Procedure WWhite;
Begin
 While WChar In [' ',#9,#10,#13] Do WNext;
End;

Function WWord: String;
Var S: String;
Begin
 WWhite; S:='';
 While UpCase(WChar) In ['A'..'Z'] Do Begin
  If Length(S)>30 Then Fail('WKT: mot trop long'); S:=S+UpCase(WChar); WNext;
 End;
 WWhite; WWord:=S;
End;

Function WNumber: Real;
Var S: String; X: Real;
Begin
 WWhite; S:='';
 While WChar In ['0'..'9','-','+','.','e','E'] Do Begin
  If Length(S)>40 Then Fail('WKT: nombre trop long'); S:=S+WChar; WNext;
 End;
 If Not IsNumber(S,X) Then Fail('WKT: nombre attendu'); WWhite; WNumber:=X;
End;

Function WGroup(Level: Integer): TJson;
Var N,C: TJson; X,Y: Real;
Begin
 If WChar<>'(' Then Fail('WKT: parenthese attendue'); WNext; WWhite; N:=NewNode(4);
 Repeat
  If Level>1 Then C:=WGroup(Level-1)
  Else Begin X:=WNumber; Y:=WNumber; C:=XYNode(X,Y); End;
  AddNode(N,C); WWhite;
  If WChar=')' Then Begin WNext; WWhite; Break; End;
  If WChar<>',' Then Fail('WKT: separateur attendu (seulement XY)'); WNext; WWhite;
 Until False;
 WGroup:=N;
End;

Function CellGeometry(Cell: TJson): TJson;
Var T: String; Co,N: TJson; Level: Integer; X,Y: Real;
Begin
 WChunk:=Cell^.First; WPos:=1; WNext; T:=WWord;
 If T='' Then Begin CellGeometry:=NewNode(0); Exit; End;
 If T='POINT' Then T:='Point' Else If T='LINESTRING' Then T:='LineString'
 Else If T='POLYGON' Then T:='Polygon' Else If T='MULTIPOINT' Then T:='MultiPoint'
 Else If T='MULTILINESTRING' Then T:='MultiLineString' Else If T='MULTIPOLYGON' Then T:='MultiPolygon'
 Else Fail('WKT: type non supporte '+T);
 Level:=1; If (T='Polygon') Or (T='MultiLineString') Then Level:=2;
 If T='MultiPolygon' Then Level:=3;
 If WChar='E' Then Begin
  If WWord<>'EMPTY' Then Fail('WKT: seul XY ou EMPTY est supporte'); Co:=NewNode(4);
 End Else If T='MultiPoint' Then Begin
  If WChar<>'(' Then Fail('WKT: parenthese attendue'); WNext; WWhite; Co:=NewNode(4);
  Repeat
   If WChar='(' Then Begin N:=WGroup(1); If NodeCount(N)<>1 Then Fail('WKT MultiPoint invalide'); N:=N^.First; End
   Else Begin X:=WNumber; Y:=WNumber; N:=XYNode(X,Y); End;
   AddNode(Co,N);
   If WChar=')' Then Begin WNext; WWhite; Break; End;
   If WChar<>',' Then Fail('WKT MultiPoint invalide'); WNext; WWhite;
  Until False;
 End Else Begin
  Co:=WGroup(Level);
  If T='Point' Then Begin If NodeCount(Co)<>1 Then Fail('WKT Point invalide'); Co:=Co^.First; End;
 End;
 If WChar<>#0 Then Fail('WKT: texte supplementaire'); CellGeometry:=GeometryNode(T,Co);
End;

Procedure WriteCSVQuoted(Var F: Text; S: String);
Var I: Integer;
Begin
 Write(F,'"'); For I:=1 To Length(S) Do Begin If S[I]='"' Then Write(F,'"'); Write(F,S[I]); End; Write(F,'"');
End;

Procedure WriteWGroup(Var F: Text; N: TJson; Level: Integer);
Var C: TJson; First: Boolean;
Begin
 Write(F,'('); C:=N^.First; First:=True;
 While C<>Nil Do Begin
  If Not First Then Write(F,','); First:=False;
  If Level=1 Then Begin
   If NodeCount(C)<>2 Then Fail('CSV WKT: seulement XY; utilisez -dim XY');
   Write(F,NodeValue(C^.First),' ',NodeValue(C^.First^.Next));
  End Else WriteWGroup(F,C,Level-1);
  C:=C^.Next;
 End; Write(F,')');
End;

Procedure WriteWKT(Var F: Text; G: TJson);
Var T: String; Co: TJson; Level: Integer;
Begin
 If (G=Nil) Or (G^.Kind=0) Then Exit;
 T:=NodeValue(FindNode(G,'type')); Co:=FindNode(G,'coordinates');
 If (T<>'Point') And (T<>'LineString') And (T<>'Polygon') And (T<>'MultiPoint') And
    (T<>'MultiLineString') And (T<>'MultiPolygon') Then Fail('CSV WKT: geometrie non supportee '+T);
 Write(F,UpperString(T),' ');
 If (Co=Nil) Or (Co^.First=Nil) Then Begin Write(F,'EMPTY'); Exit; End;
 If T='Point' Then Begin
  If NodeCount(Co)<>2 Then Fail('CSV WKT: seulement XY; utilisez -dim XY');
  Write(F,'(',NodeValue(Co^.First),' ',NodeValue(Co^.First^.Next),')');
 End Else Begin
  Level:=1; If (T='Polygon') Or (T='MultiLineString') Then Level:=2; If T='MultiPolygon' Then Level:=3;
  WriteWGroup(F,Co,Level);
 End;
End;

Procedure GatherFields(Root: TJson; DBF: Boolean);
Var F,P,C: TJson; I,J: Integer; S: String; K: Char;
Begin
 FieldCount:=0; F:=FindNode(Root,'features')^.First;
 While F<>Nil Do Begin
  P:=FindNode(F,'properties'); C:=Nil; If P<>Nil Then C:=P^.First;
  While C<>Nil Do Begin
   S:=NodeKey(C);
   If S='' Then Fail('nom de champ vide');
   If Not DBF And (UpperString(S)='WKT') Then Fail('CSV: champ WKT reserve');
   If DBF And (Length(S)>10) Then Fail('DBF: nom de champ >10 octets: '+S);
   I:=1; While (I<=FieldCount) And (Fields[I].Name<>S) Do Inc(I);
   If I>FieldCount Then Begin
    If FieldCount=MaxFields Then Fail('plus de 128 champs'); Inc(FieldCount);
    For J:=1 To I-1 Do If DBF And (UpperString(Fields[J].Name)=UpperString(S)) Then Fail('DBF: noms de champs ambigus');
    Fields[I].Name:=S; Fields[I].Kind:='?'; Fields[I].Width:=1; Fields[I].Decimals:=0;
   End;
   K:='?'; Case C^.Kind Of 1: K:='L'; 2: K:='N'; 3: K:='C'; 4,5: Fail('CSV/DBF: attribut complexe non supporte: '+S); End;
   If K<>'?' Then Begin
    If Fields[I].Kind='?' Then Fields[I].Kind:=K
    Else If Fields[I].Kind<>K Then Begin
     If DBF Then Fail('DBF: types mixtes pour '+S);
    End;
   End;
   J:=Length(NodeValue(C)); If J>250 Then Fail('attribut >250 octets');
   If J>Fields[I].Width Then Fields[I].Width:=J;
   If (K='N') And ((Pos('.',NodeValue(C))>0) Or (Pos('E',UpperString(NodeValue(C)))>0)) Then Fields[I].Decimals:=12;
   C:=C^.Next;
  End; F:=F^.Next;
 End;
 For I:=1 To FieldCount Do Begin
  If Fields[I].Kind='?' Then Fields[I].Kind:='C';
  If Fields[I].Kind='N' Then Fields[I].Width:=32;
  If Fields[I].Kind='L' Then Fields[I].Width:=1;
 End;
End;

{ .prj writer uses standard ESRI WKT1 plus the outer EPSG authority.
  Reader accepts explicit EPSG authorities and common named UTM WKT1.
  Unknown projections are rejected unless -s_srs supplies an override. }
Procedure SavePRJ(Path: String; Code: LongInt);
Var F: Text; L0,E2,FN: Real; NAD: Boolean;
Begin
 Assign(F,ChangeExtension(Path,'.prj')); Rewrite(F);
 NAD:=(Code=4269) Or ((Code>=26901) And (Code<=26923));
 If (Code<>4326) And (Code<>4269) Then Write(F,'PROJCS["EPSG:',Code,'",');
 If NAD Then Write(F,'GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137,298.257222101]],')
 Else Write(F,'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],');
 Write(F,'PRIMEM["Greenwich",0],UNIT["Degree",0.0174532925199433]');
 If Code=3857 Then Write(F,'],PROJECTION["Mercator_Auxiliary_Sphere"],PARAMETER["central_meridian",0],PARAMETER["standard_parallel_1",0],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["Meter",1]')
 Else If (Code<>4326) And (Code<>4269) Then Begin
  UTMParameters(Code,L0,E2,FN);
  Write(F,'],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",',L0*180/Pi:0:6,'],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",',FN:0:0,'],UNIT["Meter",1]');
 End;
 WriteLn(F,',AUTHORITY["EPSG","',Code,'"]]'); Close(F);
End;

Function LoadPRJ(Path: String): LongInt;
Var F: Text; C: Char; Token,U,S: String; Code,Zone,Candidate: LongInt;
 Err,I,State,Depth,AuthorityDepth: Integer;
 InQuote,Projected,NAD,WGS,South,UTM,Transverse: Boolean;
Begin
 S:=SideFile(Path,'.prj'); LoadPRJ:=4326;
 If HasSource Or Not FileExistsLocal(S) Then Exit;
 Assign(F,S); Reset(F); InQuote:=False; Token:=''; Code:=0; Zone:=0; State:=0;
 Projected:=False; NAD:=False; WGS:=False; South:=False; UTM:=False; U:='';
 Depth:=0; AuthorityDepth:=0; Transverse:=False;
 While Not EOF(F) Do Begin
  Read(F,C);
  If C='"' Then Begin
   If InQuote Then Begin
    Token:=UpperString(Token);
    If State=1 Then Begin
      Val(Token,Candidate,Err);
      If (Err=0) And (AuthorityDepth=2) Then Code:=Candidate;
      State:=0;
     End Else If Token='EPSG' Then Begin State:=1; AuthorityDepth:=Depth; End;
    If (Pos('NAD83',Token)>0) Or (Pos('NORTH_AMERICAN_1983',Token)>0) Or
       (Pos('NORTH AMERICAN 1983',Token)>0) Then NAD:=True;
     If (Pos('WGS_1984',Token)>0) Or (Pos('WGS 84',Token)>0) Or (Pos('WGS84',Token)>0) Then WGS:=True;
    If Token='TRANSVERSE_MERCATOR' Then Transverse:=True;
    I:=Pos('UTM',Token);
    If I>0 Then Begin
     UTM:=True; S:=Copy(Token,I+3,250);
     While (S<>'') And Not (S[1] In ['0'..'9']) Do Delete(S,1,1);
     U:=''; While (S<>'') And (S[1] In ['0'..'9']) Do Begin U:=U+S[1]; Delete(S,1,1); End;
     Val(U,Zone,Err); If Err<>0 Then Zone:=0;
     South:=(Pos('S',S)>0) Or (Pos('SOUTH',Token)>0);
    End;
   End Else Token:='';
   InQuote:=Not InQuote;
  End Else If InQuote Then Begin
   If Length(Token)>=250 Then Fail('PRJ: nom trop long'); Token:=Token+C;
  End Else Begin
   If C In ['A'..'Z','a'..'z'] Then Begin U:=U+UpCase(C); If Length(U)>30 Then U:=''; End
  Else Begin
   If (U='PROJCS') Or (U='PROJCRS') Then Projected:=True; U:='';
   If C='[' Then Inc(Depth) Else If C=']' Then Dec(Depth);
  End;
  End;
 End; Close(F);
 If Code<>0 Then Begin Str(Code,S); LoadPRJ:=ParseCRS(S,4326); Exit; End;
 If Projected And Transverse And UTM And (WGS Or NAD) And (Zone>=1) And (Zone<=60) Then Begin
  If NAD Then Code:=26900+Zone Else If South Then Code:=32700+Zone Else Code:=32600+Zone;
  Str(Code,S); LoadPRJ:=ParseCRS(S,4326); Exit;
 End;
 If Projected Then Fail('PRJ non reconnu: utilisez -s_srs EPSG:code');
 If NAD Then LoadPRJ:=4269 Else If WGS Then LoadPRJ:=4326
 Else Fail('PRJ sans EPSG ou datum reconnu: utilisez -s_srs');
End;

Function LoadCSV(Path: String): TJson;
Var F: Text; Cells: Array[1..MaxFields] Of TJson;
 Quoted: Array[1..MaxFields] Of Boolean;
 N,I,J,WI,XI,YI: Integer; EndRow,Q: Boolean; Root,G,P,V: TJson; S,U: String; X,Y: Real;
Begin
 Assign(F,Path); {$I-} Reset(F); {$I+} If IOResult<>0 Then Fail('impossible d''ouvrir '+Path);
 If EOF(F) Then Fail('CSV vide'); N:=0; WI:=0; XI:=0; YI:=0;
 Repeat
  If N=MaxFields Then Fail('CSV: plus de 128 colonnes'); Inc(N);
  { Reuse the global schema to avoid a 32 KB local array on TP7's stack. }
  V:=ReadCSVCell(F,EndRow,Q); Fields[N].Name:=CellString(V); FreeTree(V);
  If (N=1) And (Copy(Fields[N].Name,1,3)=#239#187#191) Then Delete(Fields[N].Name,1,3);
  If Fields[N].Name='' Then Fail('CSV: nom de colonne vide');
  For J:=1 To N-1 Do If UpperString(Fields[J].Name)=UpperString(Fields[N].Name) Then Fail('CSV: colonne dupliquee');
  U:=UpperString(Fields[N].Name); If U='WKT' Then WI:=N;
  If (U='LON') Or (U='LONGITUDE') Or (U='X') Then XI:=N;
  If (U='LAT') Or (U='LATITUDE') Or (U='Y') Then YI:=N;
 Until EndRow;
 If (WI=0) And ((XI=0) Or (YI=0)) Then Fail('CSV: WKT ou colonnes lon/lat, longitude/latitude, x/y requises');
 Root:=CollectionNode;
 While Not EOF(F) Do Begin
  For I:=1 To N Do Begin
   Cells[I]:=ReadCSVCell(F,EndRow,Quoted[I]);
   If EndRow And (I<N) Then Fail('CSV: colonnes manquantes');
  End;
  If Not EndRow Then Fail('CSV: trop de colonnes');
  P:=NewNode(5);
  If WI<>0 Then G:=CellGeometry(Cells[WI])
  Else Begin
   S:=CellString(Cells[XI]); U:=CellString(Cells[YI]);
   If (S='') And (U='') Then G:=NewNode(0)
   Else Begin If Not IsNumber(S,X) Or Not IsNumber(U,Y) Then Fail('CSV: coordonnees invalides'); G:=GeometryNode('Point',XYNode(X,Y)); End;
  End;
  For I:=1 To N Do Begin
   If (I<>WI) And ((WI<>0) Or ((I<>XI) And (I<>YI))) Then Begin
    S:=CellString(Cells[I]); V:=NodeString(S);
    If Not Quoted[I] Then Begin
     If S='' Then Begin FreeTree(V); V:=NewNode(0); End
     Else If IsNumber(S,X) Then V^.Kind:=2
     Else If (S='true') Or (S='false') Then V^.Kind:=1;
    End;
    AddPair(P,Fields[I].Name,V);
   End; FreeTree(Cells[I]);
  End;
  AddFeature(Root,G,P);
 End; Close(F); SetCRS(Root,LoadPRJ(Path)); LoadCSV:=Root;
End;

Procedure SaveCSV(Path: String; Root: TJson; Code: LongInt);
Var F: Text; Ft,P,V: TJson; I: Integer;
Begin
 GatherFields(Root,False); Assign(F,Path); Rewrite(F); Write(F,'WKT');
 For I:=1 To FieldCount Do Begin Write(F,','); WriteCSVQuoted(F,Fields[I].Name); End; WriteLn(F);
 Ft:=FindNode(Root,'features')^.First;
 While Ft<>Nil Do Begin
  Write(F,'"'); WriteWKT(F,FindNode(Ft,'geometry')); Write(F,'"'); P:=FindNode(Ft,'properties');
  For I:=1 To FieldCount Do Begin
   Write(F,','); V:=FindNode(P,Fields[I].Name);
   If V<>Nil Then If V^.Kind=3 Then WriteCSVQuoted(F,NodeValue(V)) Else If V^.Kind<>0 Then Write(F,NodeValue(V));
  End; WriteLn(F); Ft:=Ft^.Next;
 End; Close(F); SavePRJ(Path,Code);
End;

{ Shapefile/DBF binary I/O. IEEE Double is explicitly eight bytes (not Real).
  Files are streamed; no packed record or platform alignment assumptions. }
Procedure OpenBinary(Var F: File; Path: String; Writing: Boolean);
Begin
 Assign(F,Path); {$I-} If Writing Then Rewrite(F,1) Else Reset(F,1); {$I+}
 If IOResult<>0 Then Fail('impossible d''ouvrir/creer '+Path);
End;

Function ReadByte(Var F: File): Byte;
Var B: Byte; N: Word;
Begin
 BlockRead(F,B,1,N); If N<>1 Then Fail('fichier binaire tronque'); ReadByte:=B;
End;

Procedure PutByte(Var F: File; B: Byte);
Begin
 BlockWrite(F,B,1);
End;

Function ReadLE(Var F: File; N: Integer): LongInt;
Var I: Integer; X,M: LongInt; B: Byte;
Begin
 X:=0; M:=1;
 For I:=1 To N Do Begin
  B:=ReadByte(F);
  If (I=4) And (B>=128) Then Fail('binaire: entier signe/longueur non supporte');
  X:=X+LongInt(B)*M; If I<N Then M:=M*256;
 End; ReadLE:=X;
End;

Function ReadBE(Var F: File): LongInt;
Var I: Integer; X: LongInt; B: Byte;
Begin
 X:=0; For I:=1 To 4 Do Begin B:=ReadByte(F); If (I=1) And (B>=128) Then Fail('longueur binaire invalide'); X:=X*256+B; End; ReadBE:=X;
End;

Procedure PutLE(Var F: File; X: LongInt; N: Integer);
Var I: Integer;
Begin
 If X<0 Then Fail('entier binaire negatif');
 For I:=1 To N Do Begin PutByte(F,X Mod 256); X:=X Div 256; End;
End;

Procedure PutBE(Var F: File; X: LongInt);
Var B: Array[1..4] Of Byte; I: Integer;
Begin
 For I:=4 DownTo 1 Do Begin B[I]:=X Mod 256; X:=X Div 256; End;
 For I:=1 To 4 Do PutByte(F,B[I]);
End;

Function ReadDouble(Var F: File): Real;
Var D: Double; B: Array[1..8] Of Byte; I: Integer;
Begin
 For I:=1 To 8 Do B[I]:=ReadByte(F);
 { TP7 and the supported FPC x86/x64 targets are little endian IEEE-754. }
 If (B[8] And 127=127) And (B[7] And 240=240) Then Fail('Shapefile: NaN/infini');
 Move(B,D,8); ReadDouble:=D;
End;

Procedure PutDouble(Var F: File; X: Real);
Var D: Double; B: Array[1..8] Of Byte; I: Integer;
Begin
 D:=X; Move(D,B,8); For I:=1 To 8 Do PutByte(F,B[I]);
End;

Procedure PutZeros(Var F: File; N: LongInt);
Var I: LongInt;
Begin
 For I:=1 To N Do PutByte(F,0);
End;

Procedure PutBytes(Var F: File; S: String);
Var I: Integer;
Begin
 For I:=1 To Length(S) Do PutByte(F,Ord(S[I]));
End;

Function ReadBytes(Var F: File; N: Integer): String;
Var S: String; I: Integer;
Begin
 If N>250 Then Fail('DBF: champ >250 octets'); S:='';
 For I:=1 To N Do S:=S+Chr(ReadByte(F)); ReadBytes:=S;
End;

Procedure ReadDBFHeader(Var F: File; Var Rows: LongInt; Var HLen,RLen: Integer);
Var I,J: Integer; N: LongInt; S: String; B: Byte;
Begin
 B:=ReadByte(F); If B<>3 Then Fail('DBF: seul dBASE III sans memo est supporte');
 Seek(F,4); Rows:=ReadLE(F,4); N:=ReadLE(F,2);
 If (N<33) Or ((N-33) Mod 32<>0) Or (N>33+32*MaxFields) Then Fail('DBF: en-tete invalide');
 HLen:=N; N:=ReadLE(F,2); If (N<1) Or (N>32001) Then Fail('DBF: longueur enregistrement invalide'); RLen:=N;
 FieldCount:=(HLen-33) Div 32; J:=1;
 For I:=1 To FieldCount Do Begin
  Seek(F,32+LongInt(I-1)*32); S:=ReadBytes(F,11);
  While (S<>'') And (S[Length(S)]=#0) Do Delete(S,Length(S),1);
  If (S='') Or (Pos(#0,S)>0) Then Fail('DBF: nom de champ invalide'); Fields[I].Name:=S;
  Fields[I].Kind:=Chr(ReadByte(F));
  If Not (Fields[I].Kind In ['C','N','F','L','D']) Then Fail('DBF: type non supporte '+Fields[I].Kind);
  Seek(F,32+LongInt(I-1)*32+16); Fields[I].Width:=ReadByte(F); Fields[I].Decimals:=ReadByte(F);
  If (Fields[I].Width=0) Or (Fields[I].Width>250) Then Fail('DBF: largeur invalide');
  Inc(J,Fields[I].Width);
 End;
 If J<>RLen Then Fail('DBF: longueur champs incoherente');
 Seek(F,HLen-1); If ReadByte(F)<>13 Then Fail('DBF: terminateur absent');
 If Rows>(FileSize(F)-HLen) Div RLen Then Fail('DBF tronque');
End;

Function ReadDBFRow(Var F: File; Var Deleted: Boolean): TJson;
Var P,V: TJson; I: Integer; S: String; X: Real; B: Byte;
Begin
 B:=ReadByte(F); Deleted:=B=42; If (B<>32) And Not Deleted Then Fail('DBF: statut enregistrement invalide');
 P:=NewNode(5);
 For I:=1 To FieldCount Do Begin
  S:=ReadBytes(F,Fields[I].Width); V:=NewNode(0);
  If Fields[I].Kind='C' Then Begin
   While (S<>'') And (S[Length(S)]=' ') Do Delete(S,Length(S),1);
   If S<>'' Then V:=NodeString(S);
  End Else Begin
   S:=TrimString(S);
   If (Fields[I].Kind='L') And (S<>'') And (S<>'?') Then Begin
    V:=NewNode(1); If UpCase(S[1]) In ['Y','T'] Then V^.Value:=NewString('true')
    Else If UpCase(S[1]) In ['N','F'] Then V^.Value:=NewString('false') Else Fail('DBF: booleen invalide');
   End Else If (Fields[I].Kind='D') And (S<>'') Then V:=NodeString(S)
   Else If (Fields[I].Kind In ['N','F']) And (S<>'') Then Begin
    If Not IsNumber(S,X) Then Fail('DBF: nombre invalide'); V:=NewNode(2); V^.Value:=NewString(S);
   End;
  End; AddPair(P,Fields[I].Name,V);
 End; ReadDBFRow:=P;
End;

Function RingContains(Ring: TJson; X,Y: Real): Boolean;
Var A,B: TJson; AX,AY,BX,BY: Real; Inside: Boolean;
Begin
 Inside:=False; A:=Ring^.First;
 If A=Nil Then Begin RingContains:=False; Exit; End;
 B:=A^.Next;
 While B<>Nil Do Begin
  AX:=NodeReal(A^.First); AY:=NodeReal(A^.First^.Next);
  BX:=NodeReal(B^.First); BY:=NodeReal(B^.First^.Next);
  If (AY>Y)<>(BY>Y) Then If X<(BX-AX)*(Y-AY)/(BY-AY)+AX Then Inside:=Not Inside;
  A:=B; B:=B^.Next;
 End; RingContains:=Inside;
End;

{ As in QGIS_PROCESS: nesting parity identifies exteriors, not file winding.
  This also handles disjoint multipart polygons and islands in holes. }
Function AssemblePolygon(Parts: TJson): TJson;
Var Rings,R,T,Shell: TRingPtr; Multi,Poly,C: TJson; X,Y: Real; N: Integer;
Begin
 Rings:=Nil; C:=Parts^.First;
 While C<>Nil Do Begin
  New(R); R^.Co:=C; R^.Poly:=Nil; R^.Depth:=0; R^.Next:=Rings; Rings:=R; C:=C^.Next;
 End;
 R:=Rings;
 While R<>Nil Do Begin
  X:=NodeReal(R^.Co^.First^.First); Y:=NodeReal(R^.Co^.First^.First^.Next);
  T:=Rings;
  While T<>Nil Do Begin If T<>R Then If RingContains(T^.Co,X,Y) Then Inc(R^.Depth); T:=T^.Next; End;
  R:=R^.Next;
 End;
 Multi:=NewNode(4); N:=0; R:=Rings;
 While R<>Nil Do Begin
  If Not Odd(R^.Depth) Then Begin
   Poly:=NewNode(4); AddNode(Poly,R^.Co); R^.Poly:=Poly; AddNode(Multi,Poly); Inc(N);
  End; R:=R^.Next;
 End;
 R:=Rings;
 While R<>Nil Do Begin
  If Odd(R^.Depth) Then Begin
   X:=NodeReal(R^.Co^.First^.First); Y:=NodeReal(R^.Co^.First^.First^.Next); Shell:=Nil; T:=Rings;
   While T<>Nil Do Begin
    If T^.Depth=R^.Depth-1 Then If RingContains(T^.Co,X,Y) Then Shell:=T;
    T:=T^.Next;
   End;
   If Shell=Nil Then Fail('Shapefile: trou sans exterieur'); AddNode(Shell^.Poly,R^.Co);
  End; R:=R^.Next;
 End;
 While Rings<>Nil Do Begin R:=Rings^.Next; Dispose(Rings); Rings:=R; End;
 If N=1 Then AssemblePolygon:=GeometryNode('Polygon',Multi^.First)
 Else AssemblePolygon:=GeometryNode('MultiPolygon',Multi);
End;

Procedure ValidatePath(Co: TJson; Polygon: Boolean);
Var C: TJson; N: LongInt; X,Y,PrevX,PrevY,Area: Real;
Begin
 N:=NodeCount(Co);
 If (N<2) Or (Polygon And (N<4)) Then Fail('Shapefile: chemin trop court');
 C:=Co^.First; Area:=0; PrevX:=0; PrevY:=0;
 While C<>Nil Do Begin
  If (C^.Kind<>4) Or (NodeCount(C)<>2) Then Fail('Shapefile: seulement XY; utilisez -dim XY');
  X:=NodeReal(C^.First); Y:=NodeReal(C^.First^.Next);
  If C<>Co^.First Then Area:=Area+PrevX*Y-X*PrevY;
  PrevX:=X; PrevY:=Y; C:=C^.Next;
 End;
 If Polygon Then Begin
  If Area=0 Then Fail('Shapefile: anneau de surface nulle');
  If (NodeReal(Co^.First^.First)<>NodeReal(Co^.Last^.First)) Or
     (NodeReal(Co^.First^.First^.Next)<>NodeReal(Co^.Last^.First^.Next)) Then Fail('Shapefile: anneau non ferme');
 End;
End;

Function LoadShapefile(Path: String): TJson;
Var F,D: File; Root,P,G,Co,Part: TJson; HasDBF,Deleted: Boolean;
 HLen,RLen: Integer; Rows,RecNo,FileEnd,RecEnd,Bytes,Typ,HeaderType,NP,NT,I,J: LongInt;
 Starts: Array[1..MaxParts+1] Of LongInt; X,Y: Real; S: String;
Begin
 OpenBinary(F,Path,False); If FileSize(F)<100 Then Fail('Shapefile: en-tete tronque');
 If ReadBE(F)<>9994 Then Fail('signature Shapefile invalide'); Seek(F,24); FileEnd:=ReadBE(F);
 If (FileEnd<50) Or (FileEnd<>FileSize(F) Div 2) Or Odd(FileSize(F)) Then Fail('Shapefile: longueur invalide'); FileEnd:=FileSize(F);
 If ReadLE(F,4)<>1000 Then Fail('Shapefile: version invalide'); HeaderType:=ReadLE(F,4);
 If (HeaderType<>0) And (HeaderType<>1) And (HeaderType<>3) And (HeaderType<>5) And (HeaderType<>8) Then
  Fail('Shapefile: seulement Null/Point/Polyline/Polygon/MultiPoint XY (pas Z/M)');
 Seek(F,100); S:=SideFile(Path,'.dbf'); HasDBF:=FileExistsLocal(S); Rows:=0;
 If HasDBF Then Begin OpenBinary(D,S,False); ReadDBFHeader(D,Rows,HLen,RLen); Seek(D,HLen); End;
 Root:=CollectionNode; RecNo:=0;
 While FilePos(F)<FileEnd Do Begin
  If FileEnd-FilePos(F)<12 Then Fail('Shapefile: enregistrement tronque');
  Inc(RecNo); If ReadBE(F)<>RecNo Then Fail('Shapefile: numero enregistrement invalide');
  Bytes:=ReadBE(F); If (Bytes<2) Or (Bytes>(FileEnd-FilePos(F)) Div 2) Then Fail('Shapefile: longueur enregistrement invalide');
  Bytes:=Bytes*2; RecEnd:=FilePos(F)+Bytes; Typ:=ReadLE(F,4);
  If (Typ<>0) And (Typ<>HeaderType) Then Fail('Shapefile: types mixtes'); G:=NewNode(0);
  If Typ=1 Then Begin
   If Bytes<>20 Then Fail('Shapefile Point invalide'); X:=ReadDouble(F); Y:=ReadDouble(F); G:=GeometryNode('Point',XYNode(X,Y));
  End Else If (Typ=3) Or (Typ=5) Then Begin
   If Bytes<44 Then Fail('Shapefile: chemin tronque'); Seek(F,FilePos(F)+32); NP:=ReadLE(F,4); NT:=ReadLE(F,4);
   If (NP<1) Or (NP>MaxParts) Or (NT<1) Or (NT>(Bytes-44) Div 16) Then Fail('Shapefile: parties/points invalides');
   If Bytes<>44+NP*4+NT*16 Then Fail('Shapefile: longueur chemin incoherente');
   For I:=1 To NP Do Starts[I]:=ReadLE(F,4); Starts[NP+1]:=NT;
   If Starts[1]<>0 Then Fail('Shapefile: premier index invalide'); Co:=NewNode(4);
   For I:=1 To NP Do Begin
    If (Starts[I]>=Starts[I+1]) Or (Starts[I+1]>NT) Then Fail('Shapefile: index partie invalide');
    Part:=NewNode(4); For J:=Starts[I] To Starts[I+1]-1 Do Begin X:=ReadDouble(F); Y:=ReadDouble(F); AddNode(Part,XYNode(X,Y)); End;
    ValidatePath(Part,Typ=5); AddNode(Co,Part);
   End;
   If Typ=5 Then G:=AssemblePolygon(Co)
   Else If NP=1 Then G:=GeometryNode('LineString',Co^.First) Else G:=GeometryNode('MultiLineString',Co);
  End Else If Typ=8 Then Begin
   If Bytes<40 Then Fail('Shapefile MultiPoint tronque'); Seek(F,FilePos(F)+32); NT:=ReadLE(F,4);
   If (NT<1) Or (NT>(Bytes-40) Div 16) Then Fail('Shapefile MultiPoint invalide');
   If Bytes<>40+NT*16 Then Fail('Shapefile MultiPoint incoherent'); Co:=NewNode(4);
   For I:=1 To NT Do Begin X:=ReadDouble(F); Y:=ReadDouble(F); AddNode(Co,XYNode(X,Y)); End;
   G:=GeometryNode('MultiPoint',Co);
  End Else If (Typ<>0) Or (Bytes<>4) Then Fail('Shapefile: type/enregistrement non supporte');
  Seek(F,RecEnd); Deleted:=False; P:=NewNode(5);
  If HasDBF Then Begin If RecNo>Rows Then Fail('DBF: moins de lignes que SHP'); P:=ReadDBFRow(D,Deleted); End;
  If Not Deleted Then AddFeature(Root,G,P) Else Begin FreeTree(G); FreeTree(P); End;
 End;
 If HasDBF Then Begin If RecNo<>Rows Then Fail('DBF: nombre de lignes incoherent'); Close(D); End;
 Close(F); SetCRS(Root,LoadPRJ(Path)); LoadShapefile:=Root;
End;

Function ShapeClass(G: TJson): Integer;
Var T: String;
Begin
 ShapeClass:=0; If (G=Nil) Or (G^.Kind=0) Then Exit;
 T:=NodeValue(FindNode(G,'type'));
 If T='Point' Then ShapeClass:=1 Else If (T='LineString') Or (T='MultiLineString') Then ShapeClass:=3
 Else If (T='Polygon') Or (T='MultiPolygon') Then ShapeClass:=5 Else If T='MultiPoint' Then ShapeClass:=8
 Else Fail('Shapefile: geometrie non supportee '+T);
End;

Procedure ShapeCounts(G: TJson; Var NP,NT: LongInt);
Var C,P,R: TJson; Typ: Integer; T: String;
Begin
 NP:=0; NT:=0; Typ:=ShapeClass(G); If Typ=0 Then Exit;
 C:=FindNode(G,'coordinates'); If (C=Nil) Or (C^.Kind<>4) Or (C^.First=Nil) Then Fail('Shapefile: geometrie vide (utilisez null)');
 T:=NodeValue(FindNode(G,'type'));
 If Typ=1 Then Begin
  If NodeCount(C)<>2 Then Fail('Shapefile: Point XY requis; utilisez -dim XY');
  NT:=1;
 End Else If Typ=8 Then Begin
  P:=C^.First; While P<>Nil Do Begin
   If NodeCount(P)<>2 Then Fail('Shapefile: MultiPoint XY requis'); Inc(NT); P:=P^.Next;
  End;
 End Else If T='LineString' Then Begin ValidatePath(C,False); NP:=1; NT:=NodeCount(C); End
 Else If T='MultiPolygon' Then Begin
  P:=C^.First;
  While P<>Nil Do Begin
   If P^.First=Nil Then Fail('Shapefile: polygone vide'); R:=P^.First;
   While R<>Nil Do Begin ValidatePath(R,True); Inc(NP); NT:=NT+NodeCount(R); R:=R^.Next; End;
   P:=P^.Next;
  End;
 End Else Begin
  P:=C^.First;
  While P<>Nil Do Begin ValidatePath(P,Typ=5); Inc(NP); NT:=NT+NodeCount(P); P:=P^.Next; End;
 End;
 If NP>MaxParts Then Fail('Shapefile: plus de 1024 parties');
End;

Procedure ShapeHeader(Var F: File; Words: LongInt; Typ: Integer; XMin,YMin,XMax,YMax: Real);
Begin
 PutBE(F,9994); PutZeros(F,20); PutBE(F,Words); PutLE(F,1000,4); PutLE(F,Typ,4);
 PutDouble(F,XMin); PutDouble(F,YMin); PutDouble(F,XMax); PutDouble(F,YMax); PutZeros(F,32);
End;

Procedure ReverseRing(Co: TJson; Exterior: Boolean);
Var A,B,C,Prev,Next: TJson; Area,AX,AY,BX,BY: Real;
Begin
 Area:=0; A:=Co^.First; B:=A^.Next;
 While B<>Nil Do Begin
  AX:=NodeReal(A^.First); AY:=NodeReal(A^.First^.Next); BX:=NodeReal(B^.First); BY:=NodeReal(B^.First^.Next);
  Area:=Area+AX*BY-BX*AY; A:=B; B:=B^.Next;
 End;
 If Area=0 Then Fail('Shapefile: anneau de surface nulle');
 If (Exterior And (Area>0)) Or (Not Exterior And (Area<0)) Then Begin
  Prev:=Nil; C:=Co^.First; Co^.Last:=C;
  While C<>Nil Do Begin Next:=C^.Next; C^.Next:=Prev; Prev:=C; C:=Next; End; Co^.First:=Prev;
 End;
End;

{ Walking paths twice writes part offsets first, then coordinates. }
Procedure WriteShapePath(Var F: File; Co: TJson; Offsets,Polygon,Exterior: Boolean; Var Offset: LongInt);
Var C: TJson;
Begin
 If Offsets Then Begin
  PutLE(F,Offset,4); Offset:=Offset+NodeCount(Co); If Polygon Then ReverseRing(Co,Exterior);
 End Else Begin
  C:=Co^.First; While C<>Nil Do Begin PutDouble(F,NodeReal(C^.First)); PutDouble(F,NodeReal(C^.First^.Next)); C:=C^.Next; End;
 End;
End;

Procedure WriteShapePaths(Var F: File; G: TJson; Offsets: Boolean);
Var Co,P,R: TJson; T: String; Offset: LongInt; Exterior: Boolean;
Begin
 Co:=FindNode(G,'coordinates'); T:=NodeValue(FindNode(G,'type')); Offset:=0;
 If T='LineString' Then WriteShapePath(F,Co,Offsets,False,False,Offset)
 Else If T='MultiPolygon' Then Begin
  P:=Co^.First; While P<>Nil Do Begin
   R:=P^.First; Exterior:=True;
   While R<>Nil Do Begin WriteShapePath(F,R,Offsets,True,Exterior,Offset); Exterior:=False; R:=R^.Next; End;
   P:=P^.Next;
  End;
 End Else Begin
  R:=Co^.First; Exterior:=True;
  While R<>Nil Do Begin WriteShapePath(F,R,Offsets,T='Polygon',Exterior,Offset); Exterior:=False; R:=R^.Next; End;
 End;
End;

Procedure SaveDBF(Path: String; Root: TJson; Rows: LongInt);
Var F: File; I,RLen: Integer; Ft,P,V: TJson; S: String; X: Real;
 Y,M,D,DOW: Word;
Begin
 RLen:=1; For I:=1 To FieldCount Do Inc(RLen,Fields[I].Width);
 OpenBinary(F,ChangeExtension(Path,'.dbf'),True); GetDate(Y,M,D,DOW);
 PutByte(F,3); PutByte(F,(Y-1900) Mod 256); PutByte(F,M); PutByte(F,D);
 PutLE(F,Rows,4); PutLE(F,33+32*FieldCount,2); PutLE(F,RLen,2); PutZeros(F,20);
 For I:=1 To FieldCount Do Begin
  PutBytes(F,Fields[I].Name); PutZeros(F,11-Length(Fields[I].Name)); PutByte(F,Ord(Fields[I].Kind));
  PutZeros(F,4); PutByte(F,Fields[I].Width); PutByte(F,Fields[I].Decimals); PutZeros(F,14);
 End; PutByte(F,13); Ft:=FindNode(Root,'features')^.First;
 While Ft<>Nil Do Begin
  PutByte(F,32); P:=FindNode(Ft,'properties');
  For I:=1 To FieldCount Do Begin
   V:=FindNode(P,Fields[I].Name); S:='';
   If (V<>Nil) And (V^.Kind<>0) Then Begin
    S:=NodeValue(V);
    If Fields[I].Kind='L' Then Begin If S='true' Then S:='T' Else S:='F'; End;
    If Fields[I].Kind='N' Then Begin
     If Not IsNumber(S,X) Then Fail('DBF: nombre invalide'); Str(X:0:Fields[I].Decimals,S); S:=TrimString(S);
    End;
   End Else If Fields[I].Kind='L' Then S:='?';
   If Length(S)>Fields[I].Width Then Fail('DBF: valeur trop large pour '+Fields[I].Name);
   While Length(S)<Fields[I].Width Do Begin If Fields[I].Kind='N' Then S:=' '+S Else S:=S+' '; End;
   PutBytes(F,S);
  End; Ft:=Ft^.Next;
 End; PutByte(F,26); Close(F);
End;

Procedure SaveShapefile(Path: String; Root: TJson; Code: LongInt);
Var F,H: File; Ft,G,Co,C: TJson; Typ,T: Integer; NP,NT,Words,Total,Rows,Offset,RecNo: LongInt;
 HasPoint: Boolean; XMin,YMin,XMax,YMax,BXMin,BYMin,BXMax,BYMax: Real;
Begin
 GatherFields(Root,True); Typ:=0; Rows:=0; Total:=50; HasPoint:=False;
 XMin:=0; YMin:=0; XMax:=0; YMax:=0; Ft:=FindNode(Root,'features')^.First;
 While Ft<>Nil Do Begin
  G:=FindNode(Ft,'geometry'); T:=ShapeClass(G); ShapeCounts(G,NP,NT);
  If T<>0 Then Begin If (Typ<>0) And (Typ<>T) Then Fail('Shapefile: une seule famille de geometrie par fichier'); Typ:=T; End;
  Words:=2; If T=1 Then Words:=10 Else If T=8 Then Words:=20+NT*8 Else If T<>0 Then Words:=22+NP*2+NT*8;
  Total:=Total+4+Words; Inc(Rows); GetGeometryBounds(G,HasPoint,XMin,YMin,XMax,YMax); Ft:=Ft^.Next;
 End;
 OpenBinary(F,Path,True); OpenBinary(H,ChangeExtension(Path,'.shx'),True);
 ShapeHeader(F,Total,Typ,XMin,YMin,XMax,YMax); ShapeHeader(H,50+Rows*4,Typ,XMin,YMin,XMax,YMax);
 Offset:=50; RecNo:=0; Ft:=FindNode(Root,'features')^.First;
 While Ft<>Nil Do Begin
  Inc(RecNo); G:=FindNode(Ft,'geometry'); T:=ShapeClass(G); ShapeCounts(G,NP,NT);
  Words:=2; If T=1 Then Words:=10 Else If T=8 Then Words:=20+NT*8 Else If T<>0 Then Words:=22+NP*2+NT*8;
  PutBE(H,Offset); PutBE(H,Words); Offset:=Offset+4+Words;
  PutBE(F,RecNo); PutBE(F,Words); PutLE(F,T,4);
  If T=1 Then Begin Co:=FindNode(G,'coordinates'); PutDouble(F,NodeReal(Co^.First)); PutDouble(F,NodeReal(Co^.First^.Next)); End
  Else If T<>0 Then Begin
   HasPoint:=False; GetGeometryBounds(G,HasPoint,BXMin,BYMin,BXMax,BYMax);
   PutDouble(F,BXMin); PutDouble(F,BYMin); PutDouble(F,BXMax); PutDouble(F,BYMax);
   If T=8 Then Begin
    PutLE(F,NT,4); C:=FindNode(G,'coordinates')^.First;
    While C<>Nil Do Begin PutDouble(F,NodeReal(C^.First)); PutDouble(F,NodeReal(C^.First^.Next)); C:=C^.Next; End;
   End Else Begin PutLE(F,NP,4); PutLE(F,NT,4); WriteShapePaths(F,G,True); WriteShapePaths(F,G,False); End;
  End; Ft:=Ft^.Next;
 End; Close(F); Close(H); SaveDBF(Path,Root,Rows); SavePRJ(Path,Code);
End;

Function LoadLayer(Path: String): TJson;
Var Ext: String;
Begin
 Ext:=FileExtension(Path);
 If Ext='.CSV' Then LoadLayer:=LoadCSV(Path)
 Else If Ext='.SHP' Then LoadLayer:=LoadShapefile(Path) Else LoadLayer:=LoadGeoJSON(Path);
End;

Procedure SaveLayer(Path: String; Root: TJson; Code: LongInt);
Begin
 If (FormatName='CSV') Then SaveCSV(Path,Root,Code)
 Else If (FormatName='ESRI SHAPEFILE') Or (FormatName='SHAPEFILE') Then SaveShapefile(Path,Root,Code)
 Else SaveGeoJSON(Path,Root);
End;

Procedure ProcessLayer;
Var Root, Features, F, NextF, Geom, PrevF, Props: TJson;
 SrcCode, DstCode: LongInt;
 Keep, HasPoint: Boolean;
 XMin,YMin,XMax,YMax: Real;
 CountIn, CountOut: LongInt;
Begin
 Root:=LoadLayer(Src); Features:=FindNode(Root,'features');
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
 SaveLayer(Dst,Root,DstCode);
 If Not Quiet Then WriteLn(CountOut,' of ',CountIn,' features written to ',Dst);
 FreeTree(Root);
End;

Procedure ShowFormats;
Begin
 WriteLn('Formats standalone lecture/ecriture:');
 WriteLn('  GeoJSON (.geojson, .json): FeatureCollection, geometries et attributs JSON.');
 WriteLn('  CSV (.csv): entree WKT ou lon/lat, longitude/latitude, x/y; sortie WKT.');
 WriteLn('    WKT XY: Point, LineString, Polygon et leurs variantes Multi, EMPTY.');
 WriteLn('    Virgule, guillemets doubles, lignes multiples; attributs <=250 octets.');
 WriteLn('    Valeurs non quotees: nombres, true/false, vide=null; quotees=chaines.');
 WriteLn('  ESRI Shapefile (.shp + .shx/.dbf/.prj): XY Point, MultiPoint,');
 WriteLn('    Polyline/Polygon multipart et trous; null; une famille par fichier.');
 WriteLn('    DBF dBASE III C/N/F/L/D en lecture; C/N/L en sortie, <=128 champs,');
 WriteLn('    noms <=10 octets, texte <=250 octets, nombres largeur 32/12 decimales.');
 WriteLn('    Types mixtes/attributs complexes refuses; champs C vides => null,');
 WriteLn('    espaces finaux perdus; dates lues comme texte; pas de conversion encodage.');
 WriteLn('    <=1024 parties/feature; anneaux fermes non degeneres requis; pas Z/M.');
 WriteLn('CRS: EPSG:4326, 3857 (900913), 4269, 32601..32660, 32701..32760,');
 WriteLn('     NAD83 UTM nord 26901..26923. GRS80/WGS84, AUCUN datum shift.');
 WriteLn('UTM: latitude -80..84, bon hemisphere, +/-6 degres du meridien central.');
 WriteLn('CSV/Shapefile: .prj WKT1 avec EPSG ou nom UTM; absent => EPSG:4326.');
 WriteLn('PRJ inconnu: fournir -s_srs. CSV ecrit aussi un .prj. GeoJSON projete');
 WriteLn('utilise le membre crs historique (pas du RFC 7946 strict).');
 WriteLn('Non supportes: GML/KML/KMZ, GeoPackage, autres formats/CRS.');
End;

Procedure StandaloneHelp;
Begin
 WriteLn('OGR2OGR - Cette commande permet d''effectuer des operations de conversion, reprojection ',
        'et filtres vectoriels.');
 WriteLn;
 WriteLn('Syntaxe: OGR2OGR [options] destination source; aucun programme externe.');
 WriteLn;
 WriteLn('Options:');
 WriteLn('  -f, -of FORMAT       GeoJSON, CSV, "ESRI Shapefile"');
 WriteLn('                       sans -f, format deduit de l''extension destination');
 WriteLn('  -s_srs CRS           assigne le CRS source avant les traitements');
 WriteLn('  -t_srs CRS           reprojette vers le CRS cible');
 WriteLn('  -a_srs CRS           assigne un CRS sans changer les coordonnees');
 WriteLn('  -select champs       conserve les champs listes par virgules');
 WriteLn('  -where condition     comparaisons =, !=, <>, <, <=, >, >= et AND');
 WriteLn('  -spat xmin ymin xmax ymax');
 WriteLn('                       filtre par intersection des enveloppes geometriques');
 WriteLn('  -spat_srs CRS        CRS du filtre spatial (non implemente)');
 WriteLn('  -clipsrc fichier     decoupe par un polygone source (non implemente)');
 WriteLn('  -clipdst fichier     decoupe par un polygone cible (non implemente)');
 WriteLn('  -nln nom             nom de couche destination (non implemente)');
 WriteLn('  -nlt type            type geometrique de sortie (non implemente)');
 WriteLn('  -dim XY              supprime les composantes Z et M');
 WriteLn('  -overwrite           autorise le remplacement des fichiers existants');
 WriteLn('  -append, -update     ajout/mise a jour de la destination (non implementes)');
 WriteLn('  -progress            affiche la progression (non implemente)');
 WriteLn('  -q                   supprime le message recapitulatif');
 WriteLn('  --formats            liste les formats, CRS et leurs limites');
 WriteLn('  --version, -V        affiche la version de cette implementation');
 WriteLn('  -h, --help, /?       affiche cette aide');
 WriteLn;
 WriteLn('Les filtres s''appliquent avant reprojection; -a_srs assigne sans transformer.');
 WriteLn('Couche en memoire, limites de memoire TP7; JSON chaines <=250 octets.');
 WriteLn('CSV/Shapefile: XY uniquement, attributs scalaires; details avec --formats.');
 WriteLn('Formats non supportes: GPKG, GML, KML, KMZ.');
 WriteLn('Non implementes: SQL, -ct, options de pilotes, transactions et skipfailures.');
End;

Procedure StandaloneParse;
Var I, J, E: Integer; Arg, Value, Ext, S: String; V: Real;
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
  If (Arg='--version') Or (Arg='-V') Then Begin WriteLn('OGR2OGR Pascal standalone GeoJSON/CSV/Shapefile'); Halt(0); End Else
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
 FormatName:=UpperString(FormatName); Ext:=FileExtension(Src);
 If (Ext<>'.GEOJSON') And (Ext<>'.JSON') And (Ext<>'.CSV') And (Ext<>'.SHP') Then FailUsage('format source non implemente');
 Ext:=FileExtension(Dst);
 If FormatName='' Then Begin
  If Ext='.CSV' Then FormatName:='CSV' Else If Ext='.SHP' Then FormatName:='ESRI SHAPEFILE'
  Else If (Ext='.JSON') Or (Ext='.GEOJSON') Or (Ext='') Then FormatName:='GEOJSON'
  Else FailUsage('format destination non implemente');
 End;
 If FormatName='JSON' Then FormatName:='GEOJSON'; If FormatName='SHAPEFILE' Then FormatName:='ESRI SHAPEFILE';
 If (FormatName<>'GEOJSON') And (FormatName<>'CSV') And (FormatName<>'ESRI SHAPEFILE') Then FailUsage('format non implemente: '+FormatName);
 S:='.geojson'; If FormatName='CSV' Then S:='.csv' Else If FormatName='ESRI SHAPEFILE' Then S:='.shp';
 If Ext='' Then Begin Dst:=Dst+S; Ext:=UpperString(S); End;
 If (FormatName='CSV') And (Ext<>'.CSV') Then FailUsage('destination CSV: extension .csv requise');
 If (FormatName='ESRI SHAPEFILE') And (Ext<>'.SHP') Then FailUsage('destination Shapefile: extension .shp requise');
 If (FormatName='GEOJSON') And (Ext<>'.GEOJSON') And (Ext<>'.JSON') Then FailUsage('destination GeoJSON: extension .geojson/.json requise');
 If HasLayerName Then FailUsage('-nln non implemente');
 If GeometryType<>'' Then FailUsage('-nlt non implemente');
 If HasDim Then Begin If UpperString(Dimension)<>'XY' Then FailUsage('seule la dimension XY est supportee'); DropDimensions:=True; End;
 If HasSpatSRS Then FailUsage('-spat_srs non implemente');
 If HasClipSrc Or HasClipDst Then FailUsage('-clipsrc/-clipdst non implementes');
 If FileExistsLocal(Dst) And (Not Overwrite) Then FailUsage('destination existante: utilisez -overwrite');
 If (FormatName='CSV') Or (FormatName='ESRI SHAPEFILE') Then Begin
  If FileExistsLocal(SideFile(Dst,'.prj')) And Not Overwrite Then FailUsage('PRJ existant: utilisez -overwrite');
 End;
 If FormatName='ESRI SHAPEFILE' Then Begin
  If (FileExistsLocal(SideFile(Dst,'.dbf')) Or FileExistsLocal(SideFile(Dst,'.shx'))) And Not Overwrite Then FailUsage('fichiers Shapefile existants: utilisez -overwrite');
 End;
 If UpperString(Src)=UpperString(Dst) Then FailUsage('source et destination doivent etre differentes');
End;

BEGIN
 StandaloneParse;
 ProcessLayer;
END.
