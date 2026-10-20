{ @author: Sylvain Maltais (support@gladir.com)
 @created: 2026
 @website(https://www.gladir.com/geo-commander)
 @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
 @description: Standalone Mapfile renderer }

Program SHP2IMG;

{$X+}

Uses Dos;

{$IFNDEF FPC}
 {$N+}
{$ENDIF}
Const
 MaxLayers=64;
 MaxStyles=8;
 MaxPoints=2048;
 MaxParts=256;

Type
 TColor=Record
  R,G,B: Byte;
 End;
 TStyle=Record
  Color,Outline:TColor;
  Fill,Edge:Boolean;
  Width,Size:Integer;
 End;
 PLayer=^TLayer;
 TLayer=Record
  Name,Data:String;
  Kind:Integer;
  Active:Boolean;
  Count:Integer;
  Styles:Array[1..MaxStyles] Of TStyle;
  Next:PLayer;
 End;
 TRow=Array[0..3071] Of Byte;
 PRow=^TRow;
 TPoint=Record
  X,Y:Double;
 End;

Var
 MapName,OutName,ImageType,ShapePath,BasePath,Selection,DebugLayer:String;
 W,H,LayerCount,RepeatCount,DebugLevel,LayerDebug,PixelLimit,PointLimit:LongInt;
 XMin,YMin,XMax,YMax:Real;
 Background:TColor;
 SizeSet,ExtentSet,TypeSet,HaveSize,HaveExtent:Boolean;
 First,Last:PLayer;
 Rows:Array[0..1023] Of PRow;
 Points:Array[0..MaxPoints-1] Of TPoint;
 Starts:Array[0..MaxParts] Of Integer;
 Crossings:Array[0..MaxPoints-1] Of Double;
 MF:Text;
 MC:Char;
 Token:String;
 MapLine:LongInt;
 Chunk:Array[0..4095] Of Byte;
 ChunkLen:Integer;
 A1,A2:LongInt;

Procedure Fail(S:String);Begin
 WriteLn('Erreur: ',S); Halt(1);
End;

Function Upper(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 To Length(S) Do S[I]:=UpCase(S[I]); Upper:=S;
End;

Procedure NextChar;Begin
 If EOF(MF) Then MC:=#0 Else
 Begin
  Read(MF,MC); If MC=#10 Then Inc(MapLine);
 End;
End;

Procedure NextToken;
Var
 Q:Char;
Begin
 Token:='';
 Repeat
 While MC In [' ',#9,#10,#13] Do NextChar;
 If MC='#' Then Begin
  While Not (MC In [#0,#10,#13]) Do NextChar;
 End
 Else Break;
 Until False;
 If MC In ['"',#39] Then Begin
  Q:=MC; NextChar;
  While MC<>Q Do Begin
   If MC=#0 Then Fail('chaine Mapfile non terminee');
   If Length(Token)=255 Then Fail('element Mapfile de plus de 255 octets');
   Token:=Token+MC; NextChar;
  End; NextChar;
 End Else
 While Not (MC In [#0,' ',#9,#10,#13,'#']) Do Begin
  If Length(Token)=255 Then Fail('element Mapfile de plus de 255 octets');
  Token:=Token+MC; NextChar;
 End;
End;

Procedure ParseError(S:String);Begin
 WriteLn('Ligne du Mapfile: ',MapLine); Fail(S+' (element: '+Token+')');
End;

Function Number(S:String):Real;
Var
 V:Real;
 E:Integer;
Begin
 Val(S,V,E); If E<>0 Then Fail('nombre invalide: '+S);
 If (V<>V) Or (Abs(V)>1.0E12) Then Fail(
 'nombre hors de la plage finie prise en charge (+/-1e12)');
 Number:=V;
End;

Function Whole(S:String; Lo,Hi:LongInt):LongInt;
Var
 V:LongInt;
 E:Integer;
Begin
 Val(S,V,E); If E<>0 Then Fail('entier invalide: '+S);
 If (V<Lo) Or (V>Hi) Then Fail('entier hors limites: '+S); Whole:=V;
End;

Function ReadNum:Real;Begin
 If Token='' Then ParseError('nombre manquant'); ReadNum:=Number(Token); NextToken;
End;

Function ReadInt(Lo,Hi:LongInt):LongInt;Begin
 ReadInt:=Whole(Token,Lo,Hi); NextToken;
End;

Procedure ReadColor(Var C:TColor);Begin
 C.R:=ReadInt(0,255); C.G:=ReadInt(0,255); C.B:=ReadInt(0,255);
End;

Procedure DefaultStyle(Var S:TStyle);Begin
 S.Color.R:=0; S.Color.G:=0; S.Color.B:=0; S.Outline:=S.Color;
 S.Fill:=False; S.Edge:=False; S.Width:=1; S.Size:=5;
End;

Procedure ParseStyle(Var S:TStyle);
Var
 K:String;
Begin
 DefaultStyle(S);
 While Upper(Token)<>'END' Do Begin
  K:=Upper(Token); NextToken;
  If K='COLOR' Then Begin
   ReadColor(S.Color); S.Fill:=True;
  End
  Else If K='OUTLINECOLOR' Then Begin
   ReadColor(S.Outline); S.Edge:=True;
  End
  Else If K='WIDTH' Then S.Width:=ReadInt(1,64) Else
  If K='SIZE' Then S.Size:=ReadInt(1,64)
              Else ParseError('directive STYLE non prise en charge: '+K);
 End; NextToken;
 If Not S.Fill And Not S.Edge Then ParseError('STYLE exige COLOR ou OUTLINECOLOR');
End;

Procedure ParseClass(L:PLayer);
Var
 K:String;
Begin
 While Upper(Token)<>'END' Do Begin
  K:=Upper(Token); NextToken;
  If K='NAME' Then Begin
   If Token='' Then ParseError('NAME manquant dans CLASS'); NextToken;
  End
  Else If K='STYLE' Then Begin
   If L^.Count=MaxStyles Then ParseError('8 blocs STYLE au maximum');
   Inc(L^.Count); ParseStyle(L^.Styles[L^.Count]);
  End Else ParseError('directive CLASS non prise en charge: '+K);
 End; NextToken;
End;

Procedure ParseLayer;
Var
 L:PLayer;
 K:String;
 Classes:Integer;
Begin
 If LayerCount=MaxLayers Then ParseError('64 couches au maximum');
 {$IFNDEF FPC}
  If MaxAvail<SizeOf(TLayer) Then Fail('memoire du tas insuffisante pour les couches');
 {$ENDIF}
 New(L); L^.Name:=''; L^.Data:=''; L^.Kind:=-1; L^.Active:=False;
 L^.Count:=0; L^.Next:=Nil; Classes:=0; Inc(LayerCount);
 If First=Nil Then First:=L Else Last^.Next:=L; Last:=L;
 While Upper(Token)<>'END' Do Begin
  K:=Upper(Token); NextToken;
  If K='NAME' Then Begin
   L^.Name:=Token; NextToken;
  End
  Else If K='DATA' Then Begin
   L^.Data:=Token; NextToken;
  End
  Else If K='TYPE' Then Begin
   K:=Upper(Token); NextToken;
   If K='POINT' Then L^.Kind:=1 Else If K='LINE' Then L^.Kind:=3 Else
   If K='POLYGON' Then L^.Kind:=5 Else ParseError(
   'TYPE doit etre POINT, LINE ou POLYGON');
  End Else If K='STATUS' Then Begin
   K:=Upper(Token); NextToken;
   If (K<>'ON') And (K<>'OFF') And (K<>'DEFAULT') Then ParseError('STATUS invalide');
   L^.Active:=K<>'OFF';
  End Else If K='CLASS' Then Begin
   Inc(Classes);
   If Classes>1 Then ParseError('une seule CLASS sans condition par couche');
   ParseClass(L);
  End Else ParseError('directive LAYER non prise en charge: '+K);
 End; NextToken;
 If (L^.Name='') Or (L^.Data='') Or (L^.Kind=-1) Or (L^.Count=0) Then  ParseError(
 'LAYER exige NAME TYPE DATA et CLASS STYLE');
End;

Function AbsolutePath(S:String):Boolean;Begin
 AbsolutePath:=False;
 If S<>'' Then AbsolutePath:=(S[1]='/') Or (S[1]='\') Or (Pos(':',S)>0);
End;

Function JoinPath(A,B:String):String;Begin
 If AbsolutePath(B) Then JoinPath:=B Else
 Begin
  If (A<>'') And Not (A[Length(A)] In ['/','\']) Then A:=A+'/';
  If Length(A)+Length(B)>255 Then Fail('chemin de plus de 255 octets'); JoinPath:=A+B;
 End;
End;

Function ShapeFileName(L:PLayer):String;
Var
 S:String;
 I,P:Integer;
Begin
 S:=L^.Data; P:=0;
 For I:=1 To Length(S) Do  If S[I] In ['/','\'] Then P:=0 Else If S[I]='.' Then P:=I;
 If P=0 Then Begin
  If Length(S)>251 Then Fail('chemin DATA trop long'); S:=S+'.shp';
 End
 Else If Upper(Copy(S,P,255))<>'.SHP' Then Fail('DATA doit designer un fichier .shp XY');
 ShapeFileName:=JoinPath(JoinPath(BasePath,ShapePath),S);
End;

Procedure LoadMap;
Var
 K:String;
 D:DirStr;
 N:NameStr;
 E:ExtStr;
 L,P:PLayer;
Begin
 FSplit(MapName,D,N,E); BasePath:=D; MapLine:=1;
 Assign(MF,MapName); {$I-} Reset(MF); {$I+}
 If IOResult<>0 Then Fail('impossible d''ouvrir le Mapfile: '+MapName);
 NextChar; NextToken; If Upper(Token)<>'MAP' Then ParseError('MAP attendu'); NextToken;
 While Upper(Token)<>'END' Do Begin
  K:=Upper(Token); NextToken;
  If K='SIZE' Then Begin
   HaveSize:=True;
   If SizeSet Then Begin
    ReadInt(1,1024); ReadInt(1,1024);
   End
    Else
   Begin
    W:=ReadInt(1,1024); H:=ReadInt(1,1024);
   End;
  End Else If K='EXTENT' Then Begin
   HaveExtent:=True;
   If ExtentSet Then Begin
    ReadNum; ReadNum; ReadNum; ReadNum;
   End
    Else
   Begin
    XMin:=ReadNum; YMin:=ReadNum; XMax:=ReadNum; YMax:=ReadNum;
   End;
  End Else If K='IMAGECOLOR' Then ReadColor(Background) Else
  If K='IMAGETYPE' Then Begin
   If Not TypeSet Then ImageType:=Upper(Token); NextToken;
  End
  Else If K='SHAPEPATH' Then Begin
   ShapePath:=Token; NextToken;
  End
  Else If K='NAME' Then Begin
   If Token='' Then ParseError('NAME manquant dans MAP'); NextToken;
  End
  Else If K='LAYER' Then ParseLayer
                    Else ParseError('directive MAP non prise en charge: '+K);
 End; NextToken; If Token<>'' Then ParseError('texte inattendu apres MAP END'); Close(MF);
 If Not (HaveSize Or SizeSet) Or Not (HaveExtent Or ExtentSet) Then Fail(
 'SIZE et EXTENT sont obligatoires');
 If (XMin>=XMax) Or (YMin>=YMax) Then Fail('EXTENT doit avoir des bornes croissantes');
 If W*H>PixelLimit Then Fail('image matricielle depassant MAX_PIXELS');
 If (ImageType<>'PNG') And (ImageType<>'BMP') Then Fail('IMAGETYPE doit etre png ou bmp');
 L:=First;
 While L<>Nil Do Begin
  P:=L^.Next;
  While P<>Nil Do Begin
   If P^.Name=L^.Name Then Fail('NAME de LAYER en double'); P:=P^.Next;
  End;
  L:=L^.Next;
 End;
End;

Procedure Help;Begin
 WriteLn('SHP2IMG - Cette commande permet d''effectuer un rendu autonome d''un sous-ensemble ',
         'Mapfile MapServer.');
 WriteLn;
 WriteLn('Syntaxe: SHP2IMG -m mapfile [-o image] [options]');
 WriteLn;
 WriteLn('  -m FICHIER          Mapfile obligatoire; chemins relatifs a son repertoire');
 WriteLn('  -o FICHIER          Fichier de sortie (par defaut output.png ou output.bmp)');
 WriteLn('  -e xmin ymin xmax ymax  Remplace l''emprise, sans ajustement des proportions');
 WriteLn('  -s largeur hauteur  Remplace SIZE (1..1024 pour chaque dimension)');
 WriteLn('  -l "nom nom" ...     Selectionne les noms, en un ou plusieurs arguments; active OFF');
 WriteLn('  -i png|bmp          Remplace IMAGETYPE (png par defaut)');
 WriteLn('  -all_debug N        Diagnostics de la carte et de toutes les couches (0..5)');
 WriteLn('  -map_debug N        Diagnostics de la carte (0..5)');
 WriteLn('  -layer_debug NOM N  Diagnostics d''une couche (0..5)');
 WriteLn('                      0 desactive les diagnostics; 1..5 affichent le meme bilan');
 WriteLn('  -p N                Effectue N rendus, ecrit le dernier (1..100)');
 WriteLn('  -c MAX_PIXELS N     Reduit la limite de l''image (1..131072 pixels RGB)');
 WriteLn('  -c MAX_POINTS N     Reduit la limite de points par enregistrement (1..2048)');
 WriteLn('  /?, -h, --help      Affiche cette aide; options/configurations inconnues refusees');
 WriteLn;
 WriteLn('MAP: NAME SIZE EXTENT IMAGECOLOR IMAGETYPE SHAPEPATH LAYER ... END');
 WriteLn('LAYER: NAME TYPE POINT|LINE|POLYGON STATUS ON|OFF|DEFAULT DATA CLASS');
 WriteLn('CLASS: NAME facultatif, une classe sans condition, au plus 8 blocs STYLE');
 WriteLn('STYLE: COLOR/OUTLINECOLOR r g b (0..255), WIDTH/SIZE entier (1..64)');
 WriteLn('Blocs END imbriques, commentaires #, chaines entre guillemets ou apostrophes.');
 WriteLn('Par defaut: fond blanc, couches OFF, WIDTH 1, SIZE 5 pour les points.');
 WriteLn(
 'Couches/styles traces dans l''ordre du fichier. -l active seulement les noms choisis.');
 WriteLn(
 'SHP XY Null/Point/MultiPoint/Polyline/Polygon, 256 parties/enregistrement, 64 couches.')
 ;
 WriteLn(
 'Polygones: remplissage pair-impair avec trous; brosses circulaires points/lignes.');
 WriteLn('LINE avec deux couleurs: contour de 1 pixel autour du trait de largeur WIDTH.');
 WriteLn('Bornes aux centres des pixels 0..largeur-1 et hauteur-1..0; lignes decoupees.');
 WriteLn(
 'BMP: 24 bits, du bas vers le haut; PNG: RGB 8 bits, DEFLATE non compresse, filtre 0.');
 WriteLn(
 'Tas requis: 3*largeur*hauteur + enregistrements de couches + gestion (tas DOS TP7).');
 WriteLn(
 'Elements/chemins/selection <=255 octets; SHP IEEE-754 x86, octet faible en premier.');
 WriteLn('Coordonnees geographiques et de pixels transformes limitees a +/-1e12.');
 WriteLn(
 'Sans transformation de projection, DBF, styles par expression, etiquettes, symboles,');
 WriteLn(
 'GeoJSON, OUTPUTFORMAT, INCLUDE ni dependances externes. Les directives non prises');
 WriteLn(
 'en charge sont refusees, meme dans les couches OFF. La geometrie doit respecter TYPE.');
End;

Function ArgValue(Var I:Integer):String;Begin
 Inc(I); If I>ParamCount Then Fail('valeur d''option manquante'); ArgValue:=ParamStr(I);
End;

Procedure Options;
Var
 I:Integer;
 K,S:String;
Begin
 I:=1;
 While I<=ParamCount Do Begin
  K:=Upper(ParamStr(I));
  If (K='/?') Or (K='-H') Or (K='--HELP') Then Begin
   Help; Halt(0);
  End
  Else If K='-M' Then MapName:=ArgValue(I) Else
  If K='-O' Then OutName:=ArgValue(I) Else
  If K='-I' Then Begin
   ImageType:=Upper(ArgValue(I)); TypeSet:=True;
  End
  Else If K='-S' Then Begin
   W:=Whole(ArgValue(I),1,1024); H:=Whole(ArgValue(I),1,1024); SizeSet:=True;
  End
  Else If K='-E' Then Begin
   XMin:=Number(ArgValue(I)); YMin:=Number(ArgValue(I));
   XMax:=Number(ArgValue(I)); YMax:=Number(ArgValue(I)); ExtentSet:=True;
  End Else If K='-P' Then RepeatCount:=Whole(ArgValue(I),1,100) Else
  If K='-MAP_DEBUG' Then DebugLevel:=Whole(ArgValue(I),0,5) Else
  If K='-ALL_DEBUG' Then Begin
   DebugLevel:=Whole(ArgValue(I),0,5); LayerDebug:=DebugLevel;
  End
  Else If K='-LAYER_DEBUG' Then Begin
   DebugLayer:=ArgValue(I); LayerDebug:=Whole(ArgValue(I),0,5);
  End
  Else If K='-C' Then Begin
   S:=Upper(ArgValue(I));
   If S='MAX_PIXELS' Then PixelLimit:=Whole(ArgValue(I),1,131072) Else
   If S='MAX_POINTS' Then PointLimit:=Whole(ArgValue(I),1,MaxPoints)
                     Else Fail('configuration non prise en charge: '+S);
  End Else If K='-L' Then Begin
   S:=ArgValue(I); If (S='') Or (S[1]='-') Then Fail('noms de couches manquants');
   If Length(Selection)+Length(S)+1>255 Then Fail('selection de couches trop longue');
   Selection:=Selection+' '+S;
   While I<ParamCount Do Begin
    S:=ParamStr(I+1); If S='' Then Fail('nom de couche vide'); If S[1]='-' Then Break;
    Inc(I);
    If Length(Selection)+Length(S)+1>255 Then Fail('selection de couches trop longue');
    Selection:=Selection+' '+S;
   End;
  End Else Fail('option non prise en charge: '+ParamStr(I)); Inc(I);
 End;
 If MapName='' Then Fail('-m Mapfile est obligatoire (voir --help)');
End;

Procedure SelectLayers;
Var
 S,N:String;
 I:Integer;
 L:PLayer;
 Found:Boolean;
Begin
 If Selection<>'' Then Begin
  L:=First;
  While L<>Nil Do Begin
   L^.Active:=False; L:=L^.Next;
  End;
  S:=Selection;
  While S<>'' Do Begin
   While (S<>'') And (S[1] In [' ',#9]) Do Delete(S,1,1);
   I:=1;
   While (I<=Length(S)) And Not (S[I] In [' ',#9]) Do Inc(I);
   N:=Copy(S,1,I-1); Delete(S,1,I); If N<>'' Then Begin
    Found:=False; L:=First;
    While L<>Nil Do Begin
     If L^.Name=N Then Begin
      Found:=True; L^.Active:=True;
     End; L:=L^.Next;
    End; If Not Found Then Fail('couche selectionnee inconnue: '+N);
   End;
  End;
 End;
 If DebugLayer<>'' Then Begin
  Found:=False; L:=First;
  While L<>Nil Do Begin
   If L^.Name=DebugLayer Then Found:=True; L:=L^.Next;
  End;
  If Not Found Then Fail('couche de diagnostic inconnue: '+DebugLayer);
 End;
End;

Procedure Pixel(X,Y:LongInt; C:TColor);
Var
 J:Integer;
Begin
 If (X<0) Or (Y<0) Or (X>=W) Or (Y>=H) Then Exit;
 J:=X*3; Rows[Y]^[J]:=C.R; Rows[Y]^[J+1]:=C.G; Rows[Y]^[J+2]:=C.B;
End;

Procedure Brush(X,Y:LongInt; Diameter:Integer; C:TColor);
Var
 I,J,R,Hi,Offset:Integer;
 DX,DY:LongInt;
Begin
 R:=Diameter Div 2; Hi:=Diameter-1-R; Offset:=0;
 If Not Odd(Diameter) Then Offset:=1;
 For J:=-R To Hi Do
 For I:=-R To Hi Do Begin
  DX:=2*I+Offset; DY:=2*J+Offset;
  If DX*DX+DY*DY<=LongInt(Diameter)*Diameter Then Pixel(X+I,Y+J,C);
 End;
End;

Function Code(X,Y:Real; Margin:Integer):Integer;
Var
 C:Integer;
Begin
 C:=0; If X<-Margin Then C:=1 Else If X>W-1+Margin Then C:=2;
 If Y<-Margin Then C:=C Or 4 Else If Y>H-1+Margin Then C:=C Or 8; Code:=C;
End;

Procedure Line(X1,Y1,X2,Y2:Real; Width:Integer; C:TColor);
Var
 A,B,O,Margin:Integer;
 X,Y:Real;
 IX,IY,EX,EY,DX,DY,SX,SY,Err,E2:LongInt;
Begin
 Margin:=Width Div 2; A:=Code(X1,Y1,Margin); B:=Code(X2,Y2,Margin);
 While (A Or B)<>0 Do Begin
  If (A And B)<>0 Then Exit;
  O:=A; If O=0 Then O:=B;
  If (O And 8)<>0 Then Begin
   Y:=H-1+Margin; X:=X1+(X2-X1)*(Y-Y1)/(Y2-Y1);
  End
  Else If (O And 4)<>0 Then Begin
   Y:=-Margin; X:=X1+(X2-X1)*(Y-Y1)/(Y2-Y1);
  End
  Else If (O And 2)<>0 Then Begin
   X:=W-1+Margin; Y:=Y1+(Y2-Y1)*(X-X1)/(X2-X1);
  End
   Else
  Begin
   X:=-Margin; Y:=Y1+(Y2-Y1)*(X-X1)/(X2-X1);
  End;
  If O=A Then Begin
   X1:=X; Y1:=Y; A:=Code(X1,Y1,Margin);
  End
   Else
  Begin
   X2:=X; Y2:=Y; B:=Code(X2,Y2,Margin);
  End;
 End;
 IX:=Round(X1); IY:=Round(Y1); EX:=Round(X2); EY:=Round(Y2);
 DX:=Abs(EX-IX); DY:=-Abs(EY-IY); SX:=1; SY:=1;
 If IX>EX Then SX:=-1; If IY>EY Then SY:=-1; Err:=DX+DY;
 Repeat
 Brush(IX,IY,Width,C); If (IX=EX) And (IY=EY) Then Break;
 E2:=2*Err; If E2>=DY Then Begin
  Err:=Err+DY; IX:=IX+SX;
 End;
 If E2<=DX Then Begin
  Err:=Err+DX; IY:=IY+SY;
 End;
 Until False;
End;
{ Iterative heapsort: bounded stack, O(n log n) even for hostile rings. }

Procedure SiftCrossings(Root,Count:Integer);
Var
 Child:Integer;
 V:Double;
Begin
 V:=Crossings[Root]; Child:=2*Root+1;
 While Child<Count Do Begin
  If Child+1<Count Then If Crossings[Child]<Crossings[Child+1] Then Inc(Child);
  If V>=Crossings[Child] Then Break;
  Crossings[Root]:=Crossings[Child]; Root:=Child; Child:=2*Root+1;
 End; Crossings[Root]:=V;
End;

Procedure SortCrossings(N:Integer);
Var
 I:Integer;
 V:Double;
Begin
 If N<2 Then Exit;
 For I:=N Div 2-1 Downto 0 Do SiftCrossings(I,N);
 For I:=N-1 Downto 1 Do Begin
  V:=Crossings[0]; Crossings[0]:=Crossings[I]; Crossings[I]:=V; SiftCrossings(0,I);
 End;
End;

Procedure DrawGeometry(Typ,NP,NT:Integer; L:PLayer);
Var
 S:TStyle;
 SI,P,I,J,K,N,Y,X,LeftX,RightX:Integer;
 V,T:Double;
Begin
 For SI:=1 To L^.Count Do Begin
  S:=L^.Styles[SI];
  If Typ In [1,8] Then Begin
   For I:=0 To NT-1 Do If (Points[I].X>=-64) And (Points[I].X<W+64) And
   (Points[I].Y>=-64) And (Points[I].Y<H+64) Then Begin
    X:=Round(Points[I].X); Y:=Round(Points[I].Y);
    If S.Edge Then Brush(X,Y,S.Size,S.Outline);
    If S.Fill Then Begin
     K:=S.Size; If S.Edge Then K:=K-2*S.Width;
     If K>0 Then Brush(X,Y,K,S.Color);
    End;
   End;
  End Else
  Begin
   If (Typ=5) And S.Fill Then
   For Y:=0 To H-1 Do Begin
    N:=0;
    For P:=0 To NP-1 Do
    For I:=Starts[P] To Starts[P+1]-2 Do Begin
     J:=I+1;
     If ((Points[I].Y<=Y) And (Points[J].Y>Y)) Or
     ((Points[J].Y<=Y) And (Points[I].Y>Y)) Then Begin
      Crossings[N]:=Points[I].X+(Y-Points[I].Y)*(Points[J].X-Points[I].X)/(Points[J].Y-
      Points[I].Y); Inc(N);
     End;
    End;
    SortCrossings(N);
    If Odd(N) Then Fail(
    'nombre impair d''intersections du polygone sur une ligne de balayage');
    I:=0;
    While I<N Do Begin
     V:=Crossings[I]; T:=Crossings[I+1];
     If (T>=0) And (V<=W-1) Then Begin
      If V<0 Then V:=0; If T>W-1 Then T:=W-1;
      LeftX:=Trunc(V); If LeftX<V Then Inc(LeftX); RightX:=Trunc(T);
      For X:=LeftX To RightX Do Pixel(X,Y,S.Color);
     End; Inc(I,2);
    End;
   End;
   If (Typ=3) Or S.Edge Then
   For P:=0 To NP-1 Do
   For I:=Starts[P] To Starts[P+1]-2 Do Begin
    If Typ=3 Then Begin
     K:=S.Width; If S.Edge And S.Fill Then K:=K+2;
     If S.Edge Then Line(Points[I].X,Points[I].Y,Points[I+1].X,Points[I+1].Y,K,S.Outline);
     If S.Fill Then Line(Points[I].X,Points[I].Y,Points[I+1].X,Points[I+1].Y,S.Width,
     S.Color);
    End Else Line(Points[I].X,Points[I].Y,Points[I+1].X,Points[I+1].Y,S.Width,S.Outline);
   End;
  End;
 End;
End;

Procedure OpenBinary(Var F:File; S:String; Writing:Boolean);Begin
 Assign(F,S); {$I-} If Writing Then Rewrite(F,1) Else Reset(F,1); {$I+}
 If IOResult<>0 Then Fail('impossible d''ouvrir/creer: '+S);
End;

Function ReadByte(Var F:File):Byte;
Var
 B:Byte;
 N:Word;
Begin
 {$I-} BlockRead(F,B,1,N); {$I+}
 If (IOResult<>0) Or (N<>1) Then Fail('fichier SHP tronque'); ReadByte:=B;
End;

Function Read32(Var F:File; BE:Boolean):LongInt;
Var
 I:Integer;
 B:Array[0..3] Of Byte;
 V:LongInt;
Begin
 For I:=0 To 3 Do B[I]:=ReadByte(F);
 If BE Then Begin
  If B[0]>=128 Then Fail('longueur SHP invalide'); V:=0;
  For I:=0 To 3 Do V:=V*256+B[I];
 End
  Else
 Begin
  If B[3]>=128 Then Fail('nombre/type SHP negatif'); V:=0;
  For I:=3 Downto 0 Do V:=V*256+B[I];
 End;
 Read32:=V;
End;

Function ReadDouble(Var F:File):Real;
Var
 D:Double;
 B:Array[0..7] Of Byte;
 I:Integer;
Begin
 For I:=0 To 7 Do B[I]:=ReadByte(F);
 If ((B[7] And 127)=127) And ((B[6] And 240)=240) Then Fail('valeur SHP NaN ou infinie');
 Move(B,D,8); If Abs(D)>1.0E12 Then Fail('coordonnee SHP hors de la plage finie');
 ReadDouble:=D;
End;

Procedure ReadPoint(Var F:File; I:Integer);Begin
 Points[I].X:=ReadDouble(F); Points[I].Y:=ReadDouble(F);
End;

Procedure TransformPoints(NT:Integer);
Var
 I:Integer;
 X,Y:Double;
Begin
 For I:=0 To NT-1 Do Begin
  X:=(Points[I].X-XMin)/(XMax-XMin)*(W-1);
  Y:=(YMax-Points[I].Y)/(YMax-YMin)*(H-1);
  If (Abs(X)>1.0E12) Or (Abs(Y)>1.0E12) Then Fail(
  'coordonnee de pixel transformee trop grande');
  Points[I].X:=X; Points[I].Y:=Y;
 End;
End;

Procedure RenderLayer(L:PLayer);
Var
 F:File;
 S:String;
 Total,Words,Bytes,EndPos,Typ,HeaderType,RecNo,V,NP,NT:LongInt;
 I,P:Integer;
Begin
 S:=ShapeFileName(L); OpenBinary(F,S,False); Total:=FileSize(F);
 If Total<100 Then Fail('en-tete SHP tronque');
 If Read32(F,True)<>9994 Then Fail('signature SHP invalide'); Seek(F,24);
 Words:=Read32(F,True);
 If Odd(Total) Or (Words<>Total Div 2) Then Fail('longueur du fichier SHP invalide');
 If Read32(F,False)<>1000 Then Fail('version SHP invalide'); HeaderType:=Read32(F,False);
 If Not (HeaderType In [0,1,3,5,8]) Then Fail(
 'seuls les types SHP XY 0/1/3/5/8 sont pris en charge');
 If (HeaderType<>0) And (HeaderType<>L^.Kind) And Not ((HeaderType=8) And (L^.Kind=1))
 Then Fail('type SHP incompatible avec TYPE de LAYER');
 Seek(F,100); RecNo:=0;
 While FilePos(F)<Total Do Begin
  If Total-FilePos(F)<12 Then Fail('enregistrement SHP tronque'); Inc(RecNo);
  If Read32(F,True)<>RecNo Then Fail('numero d''enregistrement SHP invalide');
  Words:=Read32(F,True);
  If (Words<2) Or (Words>(Total-FilePos(F)) Div 2) Then Fail(
  'longueur d''enregistrement SHP invalide');
  Bytes:=Words*2; EndPos:=FilePos(F)+Bytes; Typ:=Read32(F,False); NP:=0; NT:=0;
  If (Typ<>0) And (Typ<>HeaderType) Then Fail('types SHP melanges');
  If Typ=0 Then Begin
   If Bytes<>4 Then Fail('geometrie nulle invalide');
  End
  Else If Typ=1 Then Begin
   If Bytes<>20 Then Fail('longueur de geometrie Point invalide'); NT:=1; ReadPoint(F,0);
  End
   Else
  Begin
   If Bytes<40 Then Fail('geometrie SHP tronquee'); Seek(F,FilePos(F)+32);
   If Typ<>8 Then Begin
    If Bytes<44 Then Fail('trace SHP tronque'); NP:=Read32(F,False);
    If (NP<1) Or (NP>MaxParts) Then Fail('limite de parties SHP depassee');
   End;
   NT:=Read32(F,False);
   If (NT<1) Or (NT>PointLimit) Then Fail('limite de points SHP depassee');
   V:=40; If Typ<>8 Then V:=44+NP*4;
   If Bytes<>V+NT*16 Then Fail('longueur de geometrie SHP incoherente');
   If Typ<>8 Then Begin
    For I:=0 To NP-1 Do Begin
     V:=Read32(F,False); If V>=NT Then Fail('indice de partie SHP invalide');
     Starts[I]:=V;
     If I=0 Then Begin
      If V<>0 Then Fail('le premier indice de partie SHP doit etre zero');
     End
     Else If Starts[I]<=Starts[I-1] Then Fail('indices de parties SHP non croissants');
    End; Starts[NP]:=NT;
   End;
   For I:=0 To NT-1 Do ReadPoint(F,I);
   If Typ<>8 Then
   For P:=0 To NP-1 Do Begin
    I:=Starts[P]; V:=Starts[P+1]-I;
    If (V<2) Or ((Typ=5) And (V<4)) Then Fail('partie SHP trop courte');
    If Typ=5 Then If (Points[I].X<>Points[Starts[P+1]-1].X) Or
    (Points[I].Y<>Points[Starts[P+1]-1].Y) Then Fail('anneau du polygone SHP non ferme');
   End;
  End;
  If FilePos(F)<>EndPos Then Fail('limite d''enregistrement SHP incoherente');
  If Typ<>0 Then Begin
   TransformPoints(NT); DrawGeometry(Typ,NP,NT,L);
  End;
 End; Close(F);
 If (LayerDebug>0) And ((DebugLayer='') Or (DebugLayer=L^.Name)) Then  WriteLn('Couche ',
 L^.Name,': ',RecNo,' enregistrements depuis ',S);
End;

Procedure PutByte(Var F:File; B:Byte);
Var
 N:Word;
Begin
 {$I-} BlockWrite(F,B,1,N); {$I+}
 If (IOResult<>0) Or (N<>1) Then Fail('echec d''ecriture de l''image');
End;

Procedure PutLE(Var F:File; V:LongInt; N:Integer);
Var
 I:Integer;
Begin
 For I:=1 To N Do Begin
  PutByte(F,V And 255); V:=V Shr 8;
 End;
End;

Procedure PutBE(Var F:File; V:LongInt);Begin
 PutByte(F,(V Shr 24) And 255); PutByte(F,(V Shr 16) And 255);
 PutByte(F,(V Shr 8) And 255); PutByte(F,V And 255);
End;

Procedure SaveBMP(Var F:File);
Var
 Stride,Bytes:LongInt;
 X,Y,I:Integer;
Begin
 Stride:=((W*3+3) Div 4)*4; Bytes:=Stride*H;
 PutByte(F,66); PutByte(F,77); PutLE(F,54+Bytes,4); PutLE(F,0,4); PutLE(F,54,4);
 PutLE(F,40,4); PutLE(F,W,4); PutLE(F,H,4); PutLE(F,1,2); PutLE(F,24,2);
 PutLE(F,0,4); PutLE(F,Bytes,4);
 For I:=1 To 4 Do PutLE(F,0,4);
 For Y:=H-1 Downto 0 Do Begin
  For X:=0 To W-1 Do Begin
   PutByte(F,Rows[Y]^[X*3+2]); PutByte(F,Rows[Y]^[X*3+1]); PutByte(F,Rows[Y]^[X*3]);
  End;
  For I:=W*3+1 To Stride Do PutByte(F,0);
 End;
End;

Function CRCByte(C:LongInt; B:Byte):LongInt;
Var
 I:Integer;
Begin
 C:=C Xor B;
 For I:=1 To 8 Do If Odd(C) Then C:=(C Shr 1) Xor -306674912 Else C:=C Shr 1;
 CRCByte:=C;
End;

Procedure AddByte(B:Byte);Begin
 If ChunkLen=4096 Then Fail('debordement interne du bloc PNG'); Chunk[ChunkLen]:=B;
 Inc(ChunkLen);
End;

Procedure AddBE(V:LongInt);Begin
 AddByte((V Shr 24) And 255); AddByte((V Shr 16) And 255); AddByte((V Shr 8) And 255);
 AddByte(V And 255);
End;

Procedure PNGChunk(Var F:File; Kind:String);
Var
 C:LongInt;
 I:Integer;
Begin
 PutBE(F,ChunkLen); C:=-1;
 For I:=1 To 4 Do Begin
  PutByte(F,Ord(Kind[I])); C:=CRCByte(C,Ord(Kind[I]));
 End;
 For I:=0 To ChunkLen-1 Do Begin
  PutByte(F,Chunk[I]); C:=CRCByte(C,Chunk[I]);
 End;
 PutBE(F,C Xor -1); ChunkLen:=0;
End;

Procedure FilterByte(B:Byte);Begin
 AddByte(B); A1:=(A1+B) Mod 65521; A2:=(A2+A1) Mod 65521;
End;

Procedure SavePNG(Var F:File);
Var
 S:String;
 I,Y,N:Integer;
Begin
 S:=#137+'PNG'+#13+#10+#26+#10;
 For I:=1 To 8 Do PutByte(F,Ord(S[I])); ChunkLen:=0;
 AddBE(W); AddBE(H); AddByte(8); AddByte(2); AddByte(0); AddByte(0); AddByte(0);
 PNGChunk(F,'IHDR');
 AddByte(120); AddByte(1); A1:=1; A2:=0;
 For Y:=0 To H-1 Do Begin
  If Y=H-1 Then AddByte(1) Else AddByte(0); N:=W*3+1;
  AddByte(N And 255); AddByte(N Shr 8); AddByte((65535-N) And 255);
  AddByte((65535-N) Shr 8);
  FilterByte(0);
  For I:=0 To W*3-1 Do FilterByte(Rows[Y]^[I]); PNGChunk(F,'IDAT');
 End;
 AddByte(A2 Shr 8); AddByte(A2 And 255); AddByte(A1 Shr 8); AddByte(A1 And 255);
 PNGChunk(F,'IDAT'); PNGChunk(F,'IEND');
End;

Procedure Render;
Var
 X,Y:Integer;
 R:LongInt;
 L:PLayer;
 F:File;
Begin
 For Y:=0 To H-1 Do Begin
  {$IFNDEF FPC}
   If MaxAvail<W*3 Then Fail('memoire du tas insuffisante pour l''image RGB');
  {$ENDIF}
  GetMem(Rows[Y],W*3);
 End;
 For R:=1 To RepeatCount Do Begin
  For Y:=0 To H-1 Do
  For X:=0 To W-1 Do Pixel(X,Y,Background);
  L:=First;
  While L<>Nil Do Begin
   If L^.Active Then RenderLayer(L); L:=L^.Next;
  End;
 End;
 If OutName='' Then Begin
  If ImageType='PNG' Then OutName:='output.png' Else OutName:='output.bmp';
 End;
 OpenBinary(F,OutName,True); If ImageType='PNG' Then SavePNG(F) Else SaveBMP(F);
 {$I-} Close(F); {$I+} If IOResult<>0 Then Fail('echec de fermeture de l''image');
 For Y:=0 To H-1 Do FreeMem(Rows[Y],W*3);
 While First<>Nil Do Begin
  L:=First; First:=First^.Next; Dispose(L);
 End;
 If DebugLevel>0 Then WriteLn('Rendu: ',W,' x ',H,' ',ImageType,' (',RepeatCount,
 ' passages): ',OutName);
End;

BEGIN
 First:=Nil; Last:=Nil; MapName:=''; OutName:=''; ImageType:='PNG';
 ShapePath:=''; Selection:=''; DebugLayer:=''; LayerCount:=0;
 RepeatCount:=1; DebugLevel:=0; LayerDebug:=0; PixelLimit:=131072; PointLimit:=MaxPoints;
 SizeSet:=False; ExtentSet:=False; TypeSet:=False; HaveSize:=False; HaveExtent:=False;
 Background.R:=255; Background.G:=255; Background.B:=255;
 Options; LoadMap; SelectLayers; Render;
END.
