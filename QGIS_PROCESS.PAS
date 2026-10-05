{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
  @description: Clone minimaliste de la commande qgis_process de QGIS

  Les couches vectorielles sont des fichiers GeoJSON (EPSG:4326 ou EPSG:3857),
  les rasters sont des fichiers ESRI ASCII Grid (.asc).

  Note : les algorithmes de couches et de rasters allouent de grands blocs de
  memoire (plus de 64 Ko) : utiliser Free Pascal (mode -Mtp possible) ou un
  Turbo Pascal en mode protege.
}

Program QGIS_PROCESS;

Const
 VersionStr='1.1';
 EarthRadius=6371008.8;   { Rayon moyen de la Terre (spherique), en metres }
 MercatorRadius=6378137.0;{ Rayon utilise par EPSG:3857 }
 MaxAlgo=16;
 MaxParam=56;
 MaxOut=29;
 MaxArg=30;
 MaxCells=40000000;

Type
 AlgoRec=Record
  Id:String[28];
  Title:String[40];
  Group:String[24];
  Descr:String[120];
 End;
 ParamRec=Record
  A:Byte;
  Name:String[18];
  Typ:String[18];
  Desc:String[64];
  Def:String[12];    { '' = obligatoire, '*' = facultatif }
 End;
 OutRec=Record
  A:Byte;
  Name:String[14];
  Typ:String[18];
  Desc:String[40];
 End;

Const
 Algos:Array[1..MaxAlgo]of AlgoRec=(
  (Id:'native:calculatedistance';Title:'Distance between two points';
   Group:'Vector analysis';
   Descr:'Computes the great-circle distance between two lon/lat points.'),
  (Id:'native:calculatebearing';Title:'Bearing between two points';
   Group:'Vector analysis';
   Descr:'Computes the initial bearing from point 1 to point 2.'),
  (Id:'native:destinationpoint';Title:'Destination point';
   Group:'Vector analysis';
   Descr:'Computes the point reached from a start point, bearing and distance.'),
  (Id:'native:reprojectpoint';Title:'Reproject point';
   Group:'Vector general';
   Descr:'Converts a point between EPSG:4326 and EPSG:3857.'),
  (Id:'native:layerextent';Title:'Extract layer extent';
   Group:'Vector general';
   Descr:'Computes the bounding box of the geometries of a GeoJSON file.'),
  (Id:'native:pointsonextent';Title:'Extent center';
   Group:'Vector general';
   Descr:'Computes the center and size of a bounding box.'),
  (Id:'native:buffer';Title:'Buffer';
   Group:'Vector geometry';
   Descr:'Buffers the features by a distance in layer units (round caps/joins, dissolved result).'),
  (Id:'native:centroids';Title:'Centroids';
   Group:'Vector geometry';
   Descr:'Creates a point layer with the centroid of each feature.'),
  (Id:'native:clip';Title:'Clip';
   Group:'Vector overlay';
   Descr:'Clips the features of a layer with the polygons of an overlay layer.'),
  (Id:'native:convexhull';Title:'Convex hull';
   Group:'Vector geometry';
   Descr:'Computes the convex hull of each feature.'),
  (Id:'native:extractbyexpression';Title:'Extract by expression';
   Group:'Vector selection';
   Descr:'Extracts the features for which an expression is true.'),
  (Id:'native:reprojectlayer';Title:'Reproject layer';
   Group:'Vector general';
   Descr:'Reprojects a layer between EPSG:4326 and EPSG:3857.'),
  (Id:'native:polygonstolines';Title:'Polygons to lines';
   Group:'Vector geometry';
   Descr:'Converts the rings of polygon features to line features.'),
  (Id:'native:pixelstopoints';Title:'Raster pixels to points';
   Group:'Raster analysis';
   Descr:'Creates a point for the center of each valid pixel of an ASCII grid.'),
  (Id:'gdal:cliprasterbyextent';Title:'Clip raster by extent';
   Group:'Raster extraction';
   Descr:'Clips an ASCII grid to an extent (xmin,xmax,ymin,ymax), like gdal_translate -projwin.'),
  (Id:'gdal:warpreproject';Title:'Warp (reproject)';
   Group:'Raster projections';
   Descr:'Reprojects an ASCII grid between EPSG:4326 and EPSG:3857, like gdalwarp.')
 );

 Params:Array[1..MaxParam]of ParamRec=(
  (A:1;Name:'X1';Typ:'number';Desc:'Longitude of point 1 (degrees)';Def:''),
  (A:1;Name:'Y1';Typ:'number';Desc:'Latitude of point 1 (degrees)';Def:''),
  (A:1;Name:'X2';Typ:'number';Desc:'Longitude of point 2 (degrees)';Def:''),
  (A:1;Name:'Y2';Typ:'number';Desc:'Latitude of point 2 (degrees)';Def:''),
  (A:2;Name:'X1';Typ:'number';Desc:'Longitude of point 1 (degrees)';Def:''),
  (A:2;Name:'Y1';Typ:'number';Desc:'Latitude of point 1 (degrees)';Def:''),
  (A:2;Name:'X2';Typ:'number';Desc:'Longitude of point 2 (degrees)';Def:''),
  (A:2;Name:'Y2';Typ:'number';Desc:'Latitude of point 2 (degrees)';Def:''),
  (A:3;Name:'X';Typ:'number';Desc:'Longitude of start point (degrees)';Def:''),
  (A:3;Name:'Y';Typ:'number';Desc:'Latitude of start point (degrees)';Def:''),
  (A:3;Name:'BEARING';Typ:'number';Desc:'Bearing, clockwise from north (degrees)';Def:''),
  (A:3;Name:'DISTANCE';Typ:'number';Desc:'Distance (meters)';Def:''),
  (A:4;Name:'X';Typ:'number';Desc:'X coordinate of the point';Def:''),
  (A:4;Name:'Y';Typ:'number';Desc:'Y coordinate of the point';Def:''),
  (A:4;Name:'SOURCE_CRS';Typ:'crs';Desc:'Source CRS (EPSG:4326 or EPSG:3857)';Def:'EPSG:4326'),
  (A:4;Name:'TARGET_CRS';Typ:'crs';Desc:'Target CRS (EPSG:4326 or EPSG:3857)';Def:'EPSG:3857'),
  (A:5;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:6;Name:'XMIN';Typ:'number';Desc:'Minimum X';Def:''),
  (A:6;Name:'YMIN';Typ:'number';Desc:'Minimum Y';Def:''),
  (A:6;Name:'XMAX';Typ:'number';Desc:'Maximum X';Def:''),
  (A:6;Name:'YMAX';Typ:'number';Desc:'Maximum Y';Def:''),
  (A:7;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:7;Name:'DISTANCE';Typ:'number';Desc:'Buffer distance in layer units (negative erodes polygons)';Def:''),
  (A:7;Name:'SEGMENTS';Typ:'number';Desc:'Segments used to approximate a quarter circle';Def:'5'),
  (A:7;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:8;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:8;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:9;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:9;Name:'OVERLAY';Typ:'vector';Desc:'Overlay polygon GeoJSON file';Def:''),
  (A:9;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:10;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:10;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:11;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:11;Name:'EXPRESSION';Typ:'expression';Desc:'Expression, e.g. "pop" > 1000 AND "name" LIKE ''M%''';Def:''),
  (A:11;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Matching features (GeoJSON file)';Def:''),
  (A:11;Name:'FAIL_OUTPUT';Typ:'vectorDestination';Desc:'Non-matching features (GeoJSON file)';Def:'*'),
  (A:12;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:12;Name:'TARGET_CRS';Typ:'crs';Desc:'Target CRS (EPSG:4326 or EPSG:3857)';Def:''),
  (A:12;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:13;Name:'INPUT';Typ:'vector';Desc:'Input polygon GeoJSON file';Def:''),
  (A:13;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:14;Name:'INPUT_RASTER';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:14;Name:'RASTER_BAND';Typ:'number';Desc:'Band number (only 1 is available)';Def:'1'),
  (A:14;Name:'FIELD_NAME';Typ:'string';Desc:'Name of the field holding the pixel value';Def:'VALUE'),
  (A:14;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:15;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:15;Name:'EXTENT';Typ:'extent';Desc:'Clipping extent: xmin,xmax,ymin,ymax [EPSG:code]';Def:''),
  (A:15;Name:'NODATA';Typ:'number';Desc:'Nodata value of the output';Def:'*'),
  (A:15;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:16;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:16;Name:'SOURCE_CRS';Typ:'crs';Desc:'Source CRS (EPSG:4326 or EPSG:3857)';Def:'EPSG:4326'),
  (A:16;Name:'TARGET_CRS';Typ:'crs';Desc:'Target CRS (EPSG:4326 or EPSG:3857)';Def:''),
  (A:16;Name:'RESAMPLING';Typ:'enum';Desc:'0 = nearest neighbour, 1 = bilinear';Def:'0'),
  (A:16;Name:'NODATA';Typ:'number';Desc:'Nodata value of the output';Def:'*'),
  (A:16;Name:'TARGET_RESOLUTION';Typ:'number';Desc:'Output pixel size in target CRS units';Def:'*'),
  (A:16;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:'')
 );

 Outs:Array[1..MaxOut]of OutRec=(
  (A:1;Name:'DISTANCE';Typ:'number';Desc:'Distance in meters'),
  (A:1;Name:'DISTANCE_KM';Typ:'number';Desc:'Distance in kilometers'),
  (A:2;Name:'BEARING';Typ:'number';Desc:'Initial bearing (0-360 degrees)'),
  (A:2;Name:'FINAL_BEARING';Typ:'number';Desc:'Final bearing (0-360 degrees)'),
  (A:3;Name:'X';Typ:'number';Desc:'Longitude of destination'),
  (A:3;Name:'Y';Typ:'number';Desc:'Latitude of destination'),
  (A:4;Name:'X';Typ:'number';Desc:'Reprojected X'),
  (A:4;Name:'Y';Typ:'number';Desc:'Reprojected Y'),
  (A:5;Name:'XMIN';Typ:'number';Desc:'Minimum X'),
  (A:5;Name:'YMIN';Typ:'number';Desc:'Minimum Y'),
  (A:5;Name:'XMAX';Typ:'number';Desc:'Maximum X'),
  (A:5;Name:'YMAX';Typ:'number';Desc:'Maximum Y'),
  (A:5;Name:'FEATURE_COUNT';Typ:'number';Desc:'Number of features'),
  (A:5;Name:'POINT_COUNT';Typ:'number';Desc:'Number of vertices'),
  (A:6;Name:'CENTER_X';Typ:'number';Desc:'Center X'),
  (A:6;Name:'CENTER_Y';Typ:'number';Desc:'Center Y'),
  (A:6;Name:'WIDTH';Typ:'number';Desc:'Width of the extent'),
  (A:6;Name:'HEIGHT';Typ:'number';Desc:'Height of the extent'),
  (A:7;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Buffered layer'),
  (A:8;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Centroids layer'),
  (A:9;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Clipped layer'),
  (A:10;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Convex hulls layer'),
  (A:11;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Matching features'),
  (A:11;Name:'FAIL_OUTPUT';Typ:'vectorDestination';Desc:'Non-matching features'),
  (A:12;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Reprojected layer'),
  (A:13;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Lines layer'),
  (A:14;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Points layer'),
  (A:15;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Clipped raster'),
  (A:16;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Reprojected raster')
 );

Type
 PStr=^String;
 PJ=^TJ;
 TJ=Record
  Kind:Byte;          { 0 null, 1 booleen, 2 nombre, 3 chaine, 4 tableau, 5 objet }
  Key,Val:PStr;
  First,Last,Next:PJ;
 End;
 TPt=Record X,Y:Real;End;
 PPts=^TPtArr;
 TPtArr=Array[0..8000000]of TPt;
 PPath=^TPath;
 TPath=Record
  N:LongInt;
  Pts:PPts;
  Poly:Integer;
  Area:Real;
  Next:PPath;
 End;
 TGeom=Record          { Cls: 0 aucune, 1 points, 2 lignes, 3 polygones }
  Cls:Byte;
  First,Last:PPath;
  Count,NPoly:Integer;
 End;
 TEdge=Record X1,Y1,X2,Y2:Real;End;
 PEdges=^TEdgeArr;
 TEdgeArr=Array[0..8000000]of TEdge;
 PSplit=^TSplit;
 TSplit=Record T,X,Y:Real;Next:PSplit;End;
 PSplitArr=^TSplitArr;
 TSplitArr=Array[0..8000000]of PSplit;
 PLongs=^TLongs;
 TLongs=Array[0..8000000]of LongInt;
 PReals=^TReals;
 TReals=Array[0..8000000]of Real;
 PBools=^TBools;
 TBools=Array[0..8000000]of Boolean;
 PPathArr=Array[0..8000000]of PPath;
 TRaster=Record
  NC,NR:LongInt;
  XLL,YLL,Cell,NoData:Real;
  Data:PReals;
 End;
 TVal=Record
  K:Byte;               { 0 nul, 1 nombre, 2 chaine, 3 booleen }
  N:Real;
  S:String;
 End;

Var
 JsonMode:Boolean;
 Cmd,AlgoId:String;
 ArgName,ArgVal:Array[1..MaxArg]of String;
 ArgCount:Integer;
 ResName,ResVal:Array[1..MaxArg]of String;
 ResCount:Integer;

{ ------------------------------------------------------------------ }
{ Utilitaires                                                         }
{ ------------------------------------------------------------------ }

Function StrUpper(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do S[I]:=UpCase(S[I]);
 StrUpper:=S;
End;

Function RealToStr(R:Real):String;
Var
 S:String;
Begin
 Str(R:0:6,S);
 RealToStr:=S;
End;

{ Nombre avec 9 decimales au maximum, sans zeros inutiles }
Function NumStr(R:Real):String;
Var
 S:String;
 L:Integer;
Begin
 If Abs(R)<5E-10Then R:=0;
 Str(R:0:9,S);
 If Pos('.',S)>0Then Begin
  L:=Length(S);
  While S[L]='0'do Dec(L);
  If S[L]='.'Then Dec(L);
  S:=Copy(S,1,L);
 End;
 NumStr:=S;
End;

Function IntToStr(L:LongInt):String;
Var
 S:String;
Begin
 Str(L,S);
 IntToStr:=S;
End;

Function MinR(A,B:Real):Real;Begin If A<B Then MinR:=A Else MinR:=B;End;
Function MaxR(A,B:Real):Real;Begin If A>B Then MaxR:=A Else MaxR:=B;End;

Function FloorR(X:Real):Real;
Var
 T:Real;
Begin
 T:=Int(X);
 If(X<T)Then T:=T-1;
 FloorR:=T;
End;

{ Arrondi en entier long, borne pour eviter les debordements }
Function RoundL(X:Real):LongInt;
Begin
 X:=FloorR(X+0.5);
 If X>1E9Then X:=1E9;
 If X<-1E9Then X:=-1E9;
 RoundL:=Trunc(X);
End;

Function FloorL(X:Real):LongInt;
Begin
 X:=FloorR(X);
 If X>1E9Then X:=1E9;
 If X<-1E9Then X:=-1E9;
 FloorL:=Trunc(X);
End;

Function Atan2(Y,X:Real):Real;
Begin
 If X>0Then Atan2:=ArcTan(Y/X) Else
 If X<0Then Begin
  If Y>=0Then Atan2:=ArcTan(Y/X)+Pi
         Else Atan2:=ArcTan(Y/X)-Pi;
 End
  Else
 If Y>0Then Atan2:=Pi/2 Else
 If Y<0Then Atan2:=-Pi/2
       Else Atan2:=0;
End;

Function ArcSin(X:Real):Real;
Begin
 If X>=1Then ArcSin:=Pi/2 Else
 If X<=-1Then ArcSin:=-Pi/2
         Else ArcSin:=ArcTan(X/Sqrt(1-X*X));
End;

Function Deg2Rad(D:Real):Real;Begin Deg2Rad:=D*Pi/180;End;
Function Rad2Deg(R:Real):Real;Begin Rad2Deg:=R*180/Pi;End;

Function NormDeg(D:Real):Real;
Begin
 While D<0do D:=D+360;
 While D>=360do D:=D-360;
 NormDeg:=D;
End;

Function IsNumber(S:String):Boolean;
Var
 R:Real;
 Err:Integer;
Begin
 If S=''Then Begin
  IsNumber:=False;
  Exit;
 End;
 Val(S,R,Err);
 IsNumber:=Err=0;
End;

Function JsonStr(S:String):String;
Var
 I:Integer;
 T:String;
Begin
 T:='"';
 For I:=1 to Length(S)do Begin
  If(S[I]='"')or(S[I]='\')Then T:=T+'\';
  T:=T+S[I];
 End;
 JsonStr:=T+'"';
End;

Function JsonVal(S:String):String;
Begin
 If IsNumber(S)Then JsonVal:=S
               Else JsonVal:=JsonStr(S);
End;

Procedure Fail(Msg:String);Begin
 If JsonMode Then WriteLn('{"error":',JsonStr(Msg),'}')
             Else WriteLn(Msg);
 Halt(1);
End;

Function AllocBlock(Size:LongInt):Pointer;
Var
 P:Pointer;
Begin
 If Size<1Then Size:=1;
 GetMem(P,Size);
 AllocBlock:=P;
End;

{ ------------------------------------------------------------------ }
{ Arbre JSON                                                          }
{ ------------------------------------------------------------------ }

Function MkStr(S:String):PStr;
Var
 P:PStr;
Begin
 GetMem(P,Length(S)+1);
 Move(S,P^,Length(S)+1);
 MkStr:=P;
End;

Function NewJ(K:Byte):PJ;
Var
 P:PJ;
Begin
 New(P);
 P^.Kind:=K;
 P^.Key:=Nil;P^.Val:=Nil;
 P^.First:=Nil;P^.Last:=Nil;P^.Next:=Nil;
 NewJ:=P;
End;

Function JVal(P:PJ):String;
Begin
 If(P=Nil)or(P^.Val=Nil)Then JVal:='' Else JVal:=P^.Val^;
End;

Function JKey(P:PJ):String;
Begin
 If(P=Nil)or(P^.Key=Nil)Then JKey:='' Else JKey:=P^.Key^;
End;

Procedure JAdd(Par,Ch:PJ);Begin
 Ch^.Next:=Nil;
 If Par^.Last=Nil Then Par^.First:=Ch
                  Else Par^.Last^.Next:=Ch;
 Par^.Last:=Ch;
End;

Procedure JAddKV(Par:PJ;Key:String;Ch:PJ);Begin
 Ch^.Key:=MkStr(Key);
 JAdd(Par,Ch);
End;

Function JFind(Obj:PJ;Const Key:String):PJ;
Var
 C:PJ;
Begin
 JFind:=Nil;
 If(Obj=Nil)or(Obj^.Kind<>5)Then Exit;
 C:=Obj^.First;
 While C<>Nil do Begin
  If JKey(C)=Key Then Begin
   JFind:=C;
   Exit;
  End;
  C:=C^.Next;
 End;
End;

Function JNum(R:Real):PJ;
Var
 N:PJ;
Begin
 N:=NewJ(2);
 N^.Val:=MkStr(NumStr(R));
 JNum:=N;
End;

Function JText(S:String):PJ;
Var
 N:PJ;
Begin
 N:=NewJ(3);
 N^.Val:=MkStr(S);
 JText:=N;
End;

Function JClone(P:PJ):PJ;
Var
 N,C:PJ;
Begin
 N:=NewJ(P^.Kind);
 N^.Key:=P^.Key;
 N^.Val:=P^.Val;
 C:=P^.First;
 While C<>Nil do Begin
  JAdd(N,JClone(C));
  C:=C^.Next;
 End;
 JClone:=N;
End;

{ Remplace Old par NewN dans la liste des enfants de Par }
Procedure JReplace(Par,Old,NewN:PJ);
Var
 C:PJ;
Begin
 NewN^.Key:=Old^.Key;
 NewN^.Next:=Old^.Next;
 If Par^.First=Old Then Par^.First:=NewN
  Else
 Begin
  C:=Par^.First;
  While C^.Next<>Old do C:=C^.Next;
  C^.Next:=NewN;
 End;
 If Par^.Last=Old Then Par^.Last:=NewN;
End;

Procedure JRemoveKey(Par:PJ;Key:String);
Var
 C,Prev:PJ;
Begin
 Prev:=Nil;
 C:=Par^.First;
 While C<>Nil do Begin
  If JKey(C)=Key Then Begin
   If Prev=Nil Then Par^.First:=C^.Next Else Prev^.Next:=C^.Next;
   If Par^.Last=C Then Par^.Last:=Prev;
   Exit;
  End;
  Prev:=C;
  C:=C^.Next;
 End;
End;

Var
 PF:Text;
 PCh:Char;
 PBuf:Array[0..16383]of Char;
 ParseName:String;

Procedure NextCh;Begin
 If EOF(PF)Then PCh:=#0
           Else Read(PF,PCh);
End;

Procedure PFail(Msg:String);Begin
 Fail('Error: invalid JSON in '+ParseName+' ('+Msg+')');
End;

Procedure SkipWs;Begin
 While PCh in[' ',#9,#10,#13,#26]do NextCh;
End;

Function ParseStrRaw:String;
Var
 S:String;
Begin
 S:='';
 NextCh;
 While PCh<>'"'do Begin
  If PCh=#0Then PFail('unterminated string');
  If Length(S)>=250Then PFail('string longer than 250 characters');
  If PCh='\'Then Begin
   S:=S+PCh;
   NextCh;
   If PCh=#0Then PFail('unterminated string');
  End;
  S:=S+PCh;
  NextCh;
 End;
 NextCh;
 ParseStrRaw:=S;
End;

Function ParseValue(Depth:Integer):PJ;
Var
 N,C:PJ;
 S,K:String;
 More:Boolean;
Begin
 SkipWs;
 If Depth>200Then PFail('nesting too deep');
 Case PCh of
  '{':Begin
   N:=NewJ(5);
   NextCh;SkipWs;
   If PCh='}'Then NextCh
    Else
   Begin
    Repeat
     SkipWs;
     If PCh<>'"'Then PFail('key expected');
     K:=ParseStrRaw;
     SkipWs;
     If PCh<>':'Then PFail('":" expected');
     NextCh;
     C:=ParseValue(Depth+1);
     JAddKV(N,K,C);
     SkipWs;
     More:=False;
     If PCh=','Then Begin NextCh;More:=True;End;
    Until Not More;
    If PCh<>'}'Then PFail('"}" expected');
    NextCh;
   End;
   ParseValue:=N;
  End;
  '[':Begin
   N:=NewJ(4);
   NextCh;SkipWs;
   If PCh=']'Then NextCh
    Else
   Begin
    Repeat
     C:=ParseValue(Depth+1);
     JAdd(N,C);
     SkipWs;
     More:=False;
     If PCh=','Then Begin NextCh;More:=True;End;
    Until Not More;
    If PCh<>']'Then PFail('"]" expected');
    NextCh;
   End;
   ParseValue:=N;
  End;
  '"':Begin
   N:=NewJ(3);
   N^.Val:=MkStr(ParseStrRaw);
   ParseValue:=N;
  End;
  '-','0'..'9':Begin
   S:='';
   While PCh in['0'..'9','-','+','.','e','E']do Begin
    If Length(S)>=40Then PFail('number too long');
    S:=S+PCh;
    NextCh;
   End;
   N:=NewJ(2);
   N^.Val:=MkStr(S);
   ParseValue:=N;
  End;
  't','f','n':Begin
   S:='';
   While PCh in['a'..'z']do Begin
    If Length(S)>=10Then PFail('unexpected token');
    S:=S+PCh;
    NextCh;
   End;
   If S='true'Then Begin N:=NewJ(1);N^.Val:=MkStr('true');End Else
   If S='false'Then Begin N:=NewJ(1);N^.Val:=MkStr('false');End Else
   If S='null'Then N:=NewJ(0)
              Else PFail('unexpected token '+S);
   ParseValue:=N;
  End;
  Else PFail('unexpected character');
 End;
End;

{ Charge un fichier GeoJSON et le normalise en FeatureCollection }
Function LoadLayer(FileName:String):PJ;
Var
 R,Col,Arr,F:PJ;
 T:String;
Begin
 ParseName:=FileName;
 {$I-}
 Assign(PF,FileName);
 Reset(PF);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to open input file '+FileName);
 SetTextBuf(PF,PBuf);
 NextCh;
 R:=ParseValue(0);
 Close(PF);
 If R^.Kind<>5Then Fail('Error: '+FileName+' is not a GeoJSON object');
 T:=JVal(JFind(R,'type'));
 If T='FeatureCollection'Then Begin
  Arr:=JFind(R,'features');
  If(Arr=Nil)or(Arr^.Kind<>4)Then Fail('Error: '+FileName+' has no features array');
  LoadLayer:=R;
  Exit;
 End;
 Col:=NewJ(5);
 JAddKV(Col,'type',JText('FeatureCollection'));
 Arr:=NewJ(4);
 JAddKV(Col,'features',Arr);
 If T='Feature'Then JAdd(Arr,R)
  Else
 If(T='Point')or(T='MultiPoint')or(T='LineString')or(T='MultiLineString')or
   (T='Polygon')or(T='MultiPolygon')Then Begin
  F:=NewJ(5);
  JAddKV(F,'type',JText('Feature'));
  JAddKV(F,'properties',NewJ(5));
  JAddKV(F,'geometry',R);
  JAdd(Arr,F);
 End
  Else
 Fail('Error: '+FileName+' is not a supported GeoJSON file');
 LoadLayer:=Col;
End;

Procedure WriteJ(Var F:Text;P:PJ);
Var
 C:PJ;
Begin
 Case P^.Kind of
  0:Write(F,'null');
  1,2:Write(F,JVal(P));
  3:Write(F,'"',JVal(P),'"');
  4:Begin
   Write(F,'[');
   C:=P^.First;
   While C<>Nil do Begin
    WriteJ(F,C);
    If C^.Next<>Nil Then Begin
     Write(F,',');
     If JKey(P)='features'Then WriteLn(F);
    End;
    C:=C^.Next;
   End;
   Write(F,']');
  End;
  5:Begin
   Write(F,'{');
   C:=P^.First;
   While C<>Nil do Begin
    Write(F,'"',JKey(C),'":');
    WriteJ(F,C);
    If C^.Next<>Nil Then Write(F,',');
    C:=C^.Next;
   End;
   Write(F,'}');
  End;
 End;
End;

Procedure SaveLayer(FileName:String;Root:PJ);
Var
 F:Text;
Begin
 {$I-}
 Assign(F,FileName);
 Rewrite(F);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to create output file '+FileName);
 WriteJ(F,Root);
 WriteLn(F);
 Close(F);
End;

Function LayerFeatures(Root:PJ):PJ;Begin
 LayerFeatures:=JFind(Root,'features');
End;

{ Remplace la geometrie d'une entite (Nil = geometrie nulle) }
Procedure SetGeom(Feat,G:PJ);
Var
 Old:PJ;
Begin
 If G=Nil Then G:=NewJ(0);
 Old:=JFind(Feat,'geometry');
 If Old=Nil Then JAddKV(Feat,'geometry',G)
            Else JReplace(Feat,Old,G);
End;

{ ------------------------------------------------------------------ }
{ Systemes de coordonnees                                             }
{ ------------------------------------------------------------------ }

Function ParseEpsg(S,What:String):Integer;
Var
 U:String;
 N,Err:Integer;
Begin
 U:=StrUpper(S);
 If Copy(U,1,5)='EPSG:'Then Begin
  Val(Copy(U,6,10),N,Err);
  If(Err=0)and((N=4326)or(N=3857))Then Begin
   ParseEpsg:=N;
   Exit;
  End;
 End;
 Fail('Error: unsupported '+What+' '+S+' (only EPSG:4326 and EPSG:3857 are supported)');
End;

{ Transforme un point entre EPSG:4326 et EPSG:3857 (Faux si hors domaine) }
Function TryTransform(Src,Dst:Integer;Var X,Y:Real):Boolean;
Var
 A:Real;
Begin
 TryTransform:=True;
 If Src=Dst Then Exit;
 If Src=4326Then Begin
  If Abs(Y)>=89.9999Then Begin TryTransform:=False;Exit;End;
  A:=Pi/4+Deg2Rad(Y)/2;
  Y:=MercatorRadius*Ln(Sin(A)/Cos(A));
  X:=MercatorRadius*Deg2Rad(X);
 End
  Else
 Begin
  X:=Rad2Deg(X/MercatorRadius);
  Y:=Rad2Deg(2*ArcTan(Exp(Y/MercatorRadius))-Pi/2);
 End;
End;

Procedure TransformPt(Src,Dst:Integer;Var X,Y:Real);Begin
 If Not TryTransform(Src,Dst,X,Y)Then
  Fail('Error: latitude out of range for EPSG:3857');
End;

{ Systeme de coordonnees declare dans un fichier GeoJSON (defaut 4326) }
Function LayerCrs(Root:PJ):Integer;
Var
 C,P:PJ;
 S:String;
Begin
 LayerCrs:=4326;
 C:=JFind(Root,'crs');
 If C=Nil Then Exit;
 P:=JFind(JFind(C,'properties'),'name');
 S:=StrUpper(JVal(P));
 If Pos('3857',S)>0Then LayerCrs:=3857 Else
 If(Pos('4326',S)>0)or(Pos('CRS84',S)>0)Then LayerCrs:=4326
  Else
 Fail('Error: unsupported layer CRS '+JVal(P)+' (only EPSG:4326 and EPSG:3857 are supported)');
End;

Procedure SetLayerCrs(Root:PJ;Epsg:Integer);
Var
 C,P:PJ;
Begin
 JRemoveKey(Root,'crs');
 If Epsg=3857Then Begin
  C:=NewJ(5);
  JAddKV(C,'type',JText('name'));
  P:=NewJ(5);
  JAddKV(P,'name',JText('urn:ogc:def:crs:EPSG::3857'));
  JAddKV(C,'properties',P);
  JAddKV(Root,'crs',C);
 End;
End;

{ Transforme en place tous les couples de coordonnees d'une geometrie }
Procedure TransformCoords(N:PJ;Src,Dst:Integer);
Var
 C:PJ;
 X,Y:Real;
 E:Integer;
Begin
 If(N=Nil)or(N^.Kind<>4)Then Exit;
 C:=N^.First;
 If C=Nil Then Exit;
 If C^.Kind=2Then Begin
  If C^.Next=Nil Then Fail('Error: invalid coordinates');
  Val(JVal(C),X,E);
  If E<>0Then Fail('Error: invalid coordinate');
  Val(JVal(C^.Next),Y,E);
  If E<>0Then Fail('Error: invalid coordinate');
  TransformPt(Src,Dst,X,Y);
  C^.Val:=MkStr(NumStr(X));
  C^.Next^.Val:=MkStr(NumStr(Y));
 End
  Else
 While C<>Nil do Begin
  TransformCoords(C,Src,Dst);
  C:=C^.Next;
 End;
End;

{ ------------------------------------------------------------------ }
{ Geometries                                                          }
{ ------------------------------------------------------------------ }

Procedure InitGeom(Var G:TGeom);Begin
 G.Cls:=0;G.First:=Nil;G.Last:=Nil;G.Count:=0;G.NPoly:=0;
End;

Function NewPath(Var G:TGeom;N:LongInt;Poly:Integer):PPath;
Var
 P:PPath;
Begin
 New(P);
 If N<1Then N:=1;
 P^.Pts:=AllocBlock(N*SizeOf(TPt));
 P^.N:=N;P^.Poly:=Poly;P^.Area:=0;P^.Next:=Nil;
 If G.Last=Nil Then G.First:=P
               Else G.Last^.Next:=P;
 G.Last:=P;
 Inc(G.Count);
 NewPath:=P;
End;

Procedure LinkPath(Var G:TGeom;P:PPath);Begin
 P^.Next:=Nil;
 If G.Last=Nil Then G.First:=P
               Else G.Last^.Next:=P;
 G.Last:=P;
 Inc(G.Count);
End;

Procedure FreeGeom(Var G:TGeom);
Var
 P,Q:PPath;
Begin
 P:=G.First;
 While P<>Nil do Begin
  Q:=P^.Next;
  FreeMem(P^.Pts,P^.N*SizeOf(TPt));
  Dispose(P);
  P:=Q;
 End;
 InitGeom(G);
End;

Function CopyPath(Var G:TGeom;S:PPath;Poly:Integer):PPath;
Var
 P:PPath;
Begin
 P:=NewPath(G,S^.N,Poly);
 Move(S^.Pts^,P^.Pts^,S^.N*SizeOf(TPt));
 CopyPath:=P;
End;

Function NumOf(P:PJ):Real;
Var
 R:Real;
 E:Integer;
Begin
 Val(JVal(P),R,E);
 If E<>0Then Fail('Error: invalid coordinate');
 NumOf:=R;
End;

Procedure AddPathFrom(Var G:TGeom;Arr:PJ;Poly:Integer);
Var
 N,I:LongInt;
 C:PJ;
 P:PPath;
Begin
 If Arr^.Kind<>4Then Fail('Error: invalid coordinates');
 N:=0;
 C:=Arr^.First;
 While C<>Nil do Begin Inc(N);C:=C^.Next;End;
 P:=NewPath(G,N,Poly);
 P^.N:=N;
 C:=Arr^.First;
 I:=0;
 While C<>Nil do Begin
  If(C^.Kind<>4)or(C^.First=Nil)or(C^.First^.Next=Nil)Then Fail('Error: invalid coordinates');
  P^.Pts^[I].X:=NumOf(C^.First);
  P^.Pts^[I].Y:=NumOf(C^.First^.Next);
  Inc(I);
  C:=C^.Next;
 End;
End;

Procedure AddPointFrom(Var G:TGeom;Co:PJ);
Var
 P:PPath;
Begin
 If(Co^.Kind<>4)or(Co^.First=Nil)or(Co^.First^.Next=Nil)Then Exit;
 P:=NewPath(G,1,0);
 P^.Pts^[0].X:=NumOf(Co^.First);
 P^.Pts^[0].Y:=NumOf(Co^.First^.Next);
End;

{ Aplatit une geometrie GeoJSON en liste de chemins }
Procedure Flatten(Geom:PJ;Var G:TGeom);
Var
 T:String;
 Co,C,R:PJ;
Begin
 InitGeom(G);
 If(Geom=Nil)or(Geom^.Kind<>5)Then Exit;
 T:=JVal(JFind(Geom,'type'));
 If T='GeometryCollection'Then Fail('Error: GeometryCollection is not supported');
 Co:=JFind(Geom,'coordinates');
 If(Co=Nil)or(Co^.Kind<>4)Then Exit;
 If T='Point'Then Begin
  G.Cls:=1;
  AddPointFrom(G,Co);
 End
  Else
 If T='MultiPoint'Then Begin
  G.Cls:=1;
  C:=Co^.First;
  While C<>Nil do Begin AddPointFrom(G,C);C:=C^.Next;End;
 End
  Else
 If T='LineString'Then Begin
  G.Cls:=2;
  AddPathFrom(G,Co,0);
 End
  Else
 If T='MultiLineString'Then Begin
  G.Cls:=2;
  C:=Co^.First;
  While C<>Nil do Begin AddPathFrom(G,C,0);C:=C^.Next;End;
 End
  Else
 If T='Polygon'Then Begin
  G.Cls:=3;
  C:=Co^.First;
  While C<>Nil do Begin AddPathFrom(G,C,0);C:=C^.Next;End;
  G.NPoly:=1;
 End
  Else
 If T='MultiPolygon'Then Begin
  G.Cls:=3;
  R:=Co^.First;
  While R<>Nil do Begin
   C:=R^.First;
   While C<>Nil do Begin AddPathFrom(G,C,G.NPoly);C:=C^.Next;End;
   Inc(G.NPoly);
   R:=R^.Next;
  End;
 End
  Else
 Fail('Error: unsupported geometry type '+T);
End;

Function CoordNode(X,Y:Real):PJ;
Var
 N:PJ;
Begin
 N:=NewJ(4);
 JAdd(N,JNum(X));
 JAdd(N,JNum(Y));
 CoordNode:=N;
End;

Function PathNode(P:PPath;Closed:Boolean):PJ;
Var
 N:PJ;
 I:LongInt;
Begin
 N:=NewJ(4);
 For I:=0 to P^.N-1do JAdd(N,CoordNode(P^.Pts^[I].X,P^.Pts^[I].Y));
 If Closed and((P^.Pts^[0].X<>P^.Pts^[P^.N-1].X)or(P^.Pts^[0].Y<>P^.Pts^[P^.N-1].Y))Then
  JAdd(N,CoordNode(P^.Pts^[0].X,P^.Pts^[0].Y));
 PathNode:=N;
End;

Function GeomNode(T:String;Co:PJ):PJ;
Var
 N:PJ;
Begin
 N:=NewJ(5);
 JAddKV(N,'type',JText(T));
 JAddKV(N,'coordinates',Co);
 GeomNode:=N;
End;

{ Construit Polygon ou MultiPolygon (Nil si vide) }
Function BuildPolygons(Var G:TGeom):PJ;
Var
 P:PPath;
 Last,NP:Integer;
 Multi,Cur:PJ;
Begin
 BuildPolygons:=Nil;
 If G.First=Nil Then Exit;
 Multi:=NewJ(4);
 Cur:=Nil;NP:=0;Last:=-1;
 P:=G.First;
 While P<>Nil do Begin
  If(Cur=Nil)or(P^.Poly<>Last)Then Begin
   Cur:=NewJ(4);
   JAdd(Multi,Cur);
   Inc(NP);
   Last:=P^.Poly;
  End;
  JAdd(Cur,PathNode(P,True));
  P:=P^.Next;
 End;
 If NP=1Then BuildPolygons:=GeomNode('Polygon',Multi^.First)
        Else BuildPolygons:=GeomNode('MultiPolygon',Multi);
End;

Function BuildLines(Var G:TGeom):PJ;
Var
 P:PPath;
 Multi:PJ;
Begin
 BuildLines:=Nil;
 If G.First=Nil Then Exit;
 If G.Count=1Then BuildLines:=GeomNode('LineString',PathNode(G.First,False))
  Else
 Begin
  Multi:=NewJ(4);
  P:=G.First;
  While P<>Nil do Begin
   JAdd(Multi,PathNode(P,False));
   P:=P^.Next;
  End;
  BuildLines:=GeomNode('MultiLineString',Multi);
 End;
End;

Function BuildPoints(Var G:TGeom):PJ;
Var
 P:PPath;
 Multi:PJ;
Begin
 BuildPoints:=Nil;
 If G.First=Nil Then Exit;
 If G.Count=1Then BuildPoints:=GeomNode('Point',CoordNode(G.First^.Pts^[0].X,G.First^.Pts^[0].Y))
  Else
 Begin
  Multi:=NewJ(4);
  P:=G.First;
  While P<>Nil do Begin
   JAdd(Multi,CoordNode(P^.Pts^[0].X,P^.Pts^[0].Y));
   P:=P^.Next;
  End;
  BuildPoints:=GeomNode('MultiPoint',Multi);
 End;
End;

{ Aire signee d'un anneau (positive = sens anti-horaire) }
Function RingArea(P:PPath):Real;
Var
 I,J:LongInt;
 S,Ox,Oy:Real;
Begin
 Ox:=P^.Pts^[0].X;Oy:=P^.Pts^[0].Y;
 S:=0;
 For I:=0 to P^.N-1do Begin
  J:=I+1;
  If J>=P^.N Then J:=0;
  S:=S+(P^.Pts^[I].X-Ox)*(P^.Pts^[J].Y-Oy)-(P^.Pts^[J].X-Ox)*(P^.Pts^[I].Y-Oy);
 End;
 RingArea:=S/2;
End;

{ Etat d'un point par rapport a un anneau : 0 dehors, 1 dedans, 2 sur le bord }
Function PointInRing(P:PPath;X,Y,Tol:Real):Integer;
Var
 I,J:LongInt;
 Xi,Yi,Xj,Yj,Cr,L:Real;
 Inside:Boolean;
Begin
 Inside:=False;
 For I:=0 to P^.N-1do Begin
  J:=I+1;
  If J>=P^.N Then J:=0;
  Xi:=P^.Pts^[I].X;Yi:=P^.Pts^[I].Y;
  Xj:=P^.Pts^[J].X;Yj:=P^.Pts^[J].Y;
  L:=Sqrt(Sqr(Xj-Xi)+Sqr(Yj-Yi));
  If L>0Then Begin
   Cr:=((Xj-Xi)*(Y-Yi)-(X-Xi)*(Yj-Yi))/L;
   If(Abs(Cr)<=Tol)and(X>=MinR(Xi,Xj)-Tol)and(X<=MaxR(Xi,Xj)+Tol)and
     (Y>=MinR(Yi,Yj)-Tol)and(Y<=MaxR(Yi,Yj)+Tol)Then Begin
    PointInRing:=2;
    Exit;
   End;
  End;
  If((Yi>Y)<>(Yj>Y))and(X<(Xj-Xi)*(Y-Yi)/(Yj-Yi)+Xi)Then Inside:=Not Inside;
 End;
 If Inside Then PointInRing:=1 Else PointInRing:=0;
End;

{ ------------------------------------------------------------------ }
{ Tri d'index                                                         }
{ ------------------------------------------------------------------ }

Var
 SB:PEdges;
 SP:PPts;
 SMode:Integer;

Function CmpR(A,B:Real):Integer;Begin
 If A<B Then CmpR:=-1 Else
 If A>B Then CmpR:=1
        Else CmpR:=0;
End;

Function CmpIdx(A,B:LongInt):Integer;
Var
 C:Integer;
Begin
 C:=0;
 Case SMode of
  0:Begin
   C:=CmpR(SB^[A].X1,SB^[B].X1);
   If C=0Then C:=CmpR(SB^[A].Y1,SB^[B].Y1);
   If C=0Then C:=CmpR(SB^[A].X2,SB^[B].X2);
   If C=0Then C:=CmpR(SB^[A].Y2,SB^[B].Y2);
  End;
  1:Begin
   C:=CmpR(SP^[A].X,SP^[B].X);
   If C=0Then C:=CmpR(SP^[A].Y,SP^[B].Y);
  End;
  2:Begin
   C:=CmpR(SB^[A].X1,SB^[B].X1);
   If C=0Then C:=CmpR(SB^[A].Y1,SB^[B].Y1);
  End;
  3:C:=CmpR(SB^[A].X1,SB^[B].X1);
 End;
 CmpIdx:=C;
End;

Procedure SortIdx(Idx:PLongs;Lo,Hi:LongInt);
Var
 I,J,Pv,T:LongInt;
Begin
 While Lo<Hi do Begin
  Pv:=Idx^[(Lo+Hi)div 2];
  I:=Lo;J:=Hi;
  Repeat
   While CmpIdx(Idx^[I],Pv)<0do Inc(I);
   While CmpIdx(Idx^[J],Pv)>0do Dec(J);
   If I<=J Then Begin
    T:=Idx^[I];Idx^[I]:=Idx^[J];Idx^[J]:=T;
    Inc(I);Dec(J);
   End;
  Until I>J;
  If J-Lo<Hi-I Then Begin
   SortIdx(Idx,Lo,J);
   Lo:=I;
  End
   Else
  Begin
   SortIdx(Idx,I,Hi);
   Hi:=J;
  End;
 End;
End;

{ ------------------------------------------------------------------ }
{ Moteur de superposition de polygones (union, intersection, difference) }
{ Principe : decoupage de toutes les aretes a leurs intersections, puis  }
{ conservation des segments qui separent l'interieur de l'exterieur du   }
{ resultat (regle du nombre d'enroulement non nul), puis reassemblage    }
{ en anneaux.                                                            }
{ ------------------------------------------------------------------ }

Var
 SnapQ,OvEps:Real;
 OvAll,OvBox:PEdges;
 OvSp:PSplitArr;
 OvTot:LongInt;
 KeepOrient:Boolean;   { Vrai : conserve le sens des anneaux fournis }
 SlabN:LongInt;
 SlabMin,SlabH:Real;
 SlabStart,SlabEdge:PLongs;
 OvNA:LongInt;

Function Snap(V:Real):Real;Begin
 If SnapQ>0Then Snap:=FloorR(V/SnapQ+0.5)*SnapQ
           Else Snap:=V;
End;

Function EdgeCount(Var G:TGeom):LongInt;
Var
 P:PPath;
 N:LongInt;
Begin
 N:=0;
 P:=G.First;
 While P<>Nil do Begin Inc(N,P^.N);P:=P^.Next;End;
 EdgeCount:=N;
End;

{ Ajoute les aretes des anneaux de G (exterieurs anti-horaires, trous horaires) }
Procedure FillEdges(Var G:TGeom;E:PEdges;Var N:LongInt);
Var
 P:PPath;
 I,J:LongInt;
 Prev:Integer;
 Rev:Boolean;
 A:Real;
 X1,Y1,X2,Y2:Real;
Begin
 Prev:=-1;
 P:=G.First;
 While P<>Nil do Begin
  A:=RingArea(P);
  If KeepOrient Then Rev:=False Else
  If P^.Poly<>Prev Then Rev:=A<0
                   Else Rev:=A>0;
  Prev:=P^.Poly;
  For I:=0 to P^.N-1do Begin
   J:=I+1;
   If J>=P^.N Then J:=0;
   X1:=Snap(P^.Pts^[I].X);Y1:=Snap(P^.Pts^[I].Y);
   X2:=Snap(P^.Pts^[J].X);Y2:=Snap(P^.Pts^[J].Y);
   If Rev Then Begin
    E^[N].X1:=X2;E^[N].Y1:=Y2;E^[N].X2:=X1;E^[N].Y2:=Y1;
   End
    Else
   Begin
    E^[N].X1:=X1;E^[N].Y1:=Y1;E^[N].X2:=X2;E^[N].Y2:=Y2;
   End;
   If(X1<>X2)or(Y1<>Y2)Then Inc(N);
  End;
  P:=P^.Next;
 End;
End;

Function Winding(E:PEdges;N:LongInt;QX,QY:Real):LongInt;
Var
 I,W:LongInt;
 L:Real;
Begin
 W:=0;
 For I:=0 to N-1do With E^[I]do Begin
  If Y1<=QY Then Begin
   If Y2>QY Then Begin
    L:=(X2-X1)*(QY-Y1)-(QX-X1)*(Y2-Y1);
    If L>0Then Inc(W);
   End;
  End
   Else
  If Y2<=QY Then Begin
   L:=(X2-X1)*(QY-Y1)-(QX-X1)*(Y2-Y1);
   If L<0Then Dec(W);
  End;
 End;
 Winding:=W;
End;

Function SlabOf(Y:Real):LongInt;
Var
 K:LongInt;
Begin
 K:=FloorL((Y-SlabMin)/SlabH);
 If K<0Then K:=0;
 If K>=SlabN Then K:=SlabN-1;
 SlabOf:=K;
End;

{ Index des aretes par tranches horizontales, pour accelerer les nombres d'enroulement }
Procedure BuildSlabs(NT:LongInt;MinY,MaxY:Real);
Var
 I,K,S0,S1:LongInt;
 Fill:PLongs;
Begin
 SlabN:=NT div 4+1;
 If SlabN>4096Then SlabN:=4096;
 SlabMin:=MinY;
 SlabH:=(MaxY-MinY)/SlabN;
 If SlabH<=0Then SlabH:=1;
 SlabStart:=AllocBlock((SlabN+2)*SizeOf(LongInt));
 Fill:=AllocBlock((SlabN+2)*SizeOf(LongInt));
 For K:=0 to SlabN+1do Begin SlabStart^[K]:=0;Fill^[K]:=0;End;
 For I:=0 to NT-1do Begin
  S0:=SlabOf(OvBox^[I].Y1);S1:=SlabOf(OvBox^[I].Y2);
  For K:=S0 to S1 do Inc(SlabStart^[K+1]);
 End;
 For K:=1 to SlabN do SlabStart^[K]:=SlabStart^[K]+SlabStart^[K-1];
 SlabEdge:=AllocBlock((SlabStart^[SlabN]+1)*SizeOf(LongInt));
 For I:=0 to NT-1do Begin
  S0:=SlabOf(OvBox^[I].Y1);S1:=SlabOf(OvBox^[I].Y2);
  For K:=S0 to S1 do Begin
   SlabEdge^[SlabStart^[K]+Fill^[K]]:=I;
   Inc(Fill^[K]);
  End;
 End;
 FreeMem(Fill,(SlabN+2)*SizeOf(LongInt));
End;

Procedure WindingAB(QX,QY:Real;Var Wa,Wb:LongInt);
Var
 K,E,S:LongInt;
 L:Real;
 D:LongInt;
Begin
 Wa:=0;Wb:=0;
 S:=SlabOf(QY);
 For K:=SlabStart^[S] to SlabStart^[S+1]-1do Begin
  E:=SlabEdge^[K];
  D:=0;
  With OvAll^[E]do Begin
   If Y1<=QY Then Begin
    If Y2>QY Then Begin
     L:=(X2-X1)*(QY-Y1)-(QX-X1)*(Y2-Y1);
     If L>0Then D:=1;
    End;
   End
    Else
   If Y2<=QY Then Begin
    L:=(X2-X1)*(QY-Y1)-(QX-X1)*(Y2-Y1);
    If L<0Then D:=-1;
   End;
  End;
  If E<OvNA Then Wa:=Wa+D Else Wb:=Wb+D;
 End;
End;

Procedure AddSplit(E:LongInt;T,X,Y:Real);
Var
 S,C,Prev:PSplit;
Begin
 New(S);
 S^.T:=T;S^.X:=X;S^.Y:=Y;
 Prev:=Nil;
 C:=OvSp^[E];
 While(C<>Nil)and(C^.T<T)do Begin Prev:=C;C:=C^.Next;End;
 S^.Next:=C;
 If Prev=Nil Then OvSp^[E]:=S Else Prev^.Next:=S;
 Inc(OvTot);
End;

Procedure ProjSplit(E:LongInt;Px,Py,L,Dx,Dy:Real);
Var
 T,D:Real;
Begin
 D:=Abs((Px-OvAll^[E].X1)*Dy-(Py-OvAll^[E].Y1)*Dx)/L;
 If D>SnapQ*4Then Exit;
 T:=((Px-OvAll^[E].X1)*Dx+(Py-OvAll^[E].Y1)*Dy)/(L*L);
 If(T>1E-12)and(T<1-1E-12)Then AddSplit(E,T,Px,Py);
End;

Procedure NodeEdges(I,J:LongInt);
Var
 Dx1,Dy1,Dx2,Dy2,Den,L1,L2,T,U,Px,Py,Rx,Ry:Real;
Begin
 Dx1:=OvAll^[I].X2-OvAll^[I].X1;Dy1:=OvAll^[I].Y2-OvAll^[I].Y1;
 Dx2:=OvAll^[J].X2-OvAll^[J].X1;Dy2:=OvAll^[J].Y2-OvAll^[J].Y1;
 L1:=Sqrt(Dx1*Dx1+Dy1*Dy1);
 L2:=Sqrt(Dx2*Dx2+Dy2*Dy2);
 Den:=Dx1*Dy2-Dy1*Dx2;
 If Abs(Den)<=1E-12*L1*L2 Then Begin
  { paralleles : on ne decoupe que si elles se recouvrent }
  ProjSplit(I,OvAll^[J].X1,OvAll^[J].Y1,L1,Dx1,Dy1);
  ProjSplit(I,OvAll^[J].X2,OvAll^[J].Y2,L1,Dx1,Dy1);
  ProjSplit(J,OvAll^[I].X1,OvAll^[I].Y1,L2,Dx2,Dy2);
  ProjSplit(J,OvAll^[I].X2,OvAll^[I].Y2,L2,Dx2,Dy2);
 End
  Else
 Begin
  Rx:=OvAll^[J].X1-OvAll^[I].X1;
  Ry:=OvAll^[J].Y1-OvAll^[I].Y1;
  T:=(Rx*Dy2-Ry*Dx2)/Den;
  U:=(Rx*Dy1-Ry*Dx1)/Den;
  If(T<-1E-12)or(T>1+1E-12)or(U<-1E-12)or(U>1+1E-12)Then Exit;
  If T<=1E-12Then Begin Px:=OvAll^[I].X1;Py:=OvAll^[I].Y1;End Else
  If T>=1-1E-12Then Begin Px:=OvAll^[I].X2;Py:=OvAll^[I].Y2;End Else
  If U<=1E-12Then Begin Px:=OvAll^[J].X1;Py:=OvAll^[J].Y1;End Else
  If U>=1-1E-12Then Begin Px:=OvAll^[J].X2;Py:=OvAll^[J].Y2;End
   Else
  Begin
   Px:=Snap(OvAll^[I].X1+T*Dx1);
   Py:=Snap(OvAll^[I].Y1+T*Dy1);
  End;
  If(T>1E-12)and(T<1-1E-12)Then AddSplit(I,T,Px,Py);
  If(U>1E-12)and(U<1-1E-12)Then AddSplit(J,U,Px,Py);
 End;
End;

{ Mode 0 : union (nettoyage) de A, 1 : A inter B, 2 : A moins B }
Procedure Overlay(Mode:Integer;Var A,B:TGeom;Var R:TGeom);
Var
 NA,NB,NT,I,J,NS,NU,KN,Cur,Best,P,Q,Lo,Hi,Mid,RN,Cnt:LongInt;
 Wa,Wb:LongInt;
 MinX,MinY,MaxX,MaxY,Ext,Tol:Real;
 Have,InL,InR,Ok:Boolean;
 Sub,Kp:PEdges;
 Idx,Ord:PLongs;
 Used:PBools;
 RB:PPts;
 S,Nx:PSplit;
 Px,Py,Mx,My,Dx,Dy,Len,Ep,Qx,Qy,Ang,BestAng,Ex,Ey,Sx,Sy:Real;
 EG,HG:TGeom;
 Pa,Pb,Hp:PPath;
 HArr:^PPathArr;
 HN:LongInt;
 Owner:Integer;
 BestArea:Real;
 K:Integer;

 Procedure Bounds(Var G:TGeom);
 Var
  Pt:PPath;
  Q:LongInt;
 Begin
  Pt:=G.First;
  While Pt<>Nil do Begin
   For Q:=0 to Pt^.N-1do Begin
    If Not Have Then Begin
     MinX:=Pt^.Pts^[Q].X;MaxX:=MinX;MinY:=Pt^.Pts^[Q].Y;MaxY:=MinY;Have:=True;
    End
     Else
    Begin
     If Pt^.Pts^[Q].X<MinX Then MinX:=Pt^.Pts^[Q].X;
     If Pt^.Pts^[Q].X>MaxX Then MaxX:=Pt^.Pts^[Q].X;
     If Pt^.Pts^[Q].Y<MinY Then MinY:=Pt^.Pts^[Q].Y;
     If Pt^.Pts^[Q].Y>MaxY Then MaxY:=Pt^.Pts^[Q].Y;
    End;
   End;
   Pt:=Pt^.Next;
  End;
 End;

 Procedure Emit(X1,Y1,X2,Y2:Real);
 Var
  T:Real;
 Begin
  If(X1=X2)and(Y1=Y2)Then Exit;
  If(X1>X2)or((X1=X2)and(Y1>Y2))Then Begin
   T:=X1;X1:=X2;X2:=T;
   T:=Y1;Y1:=Y2;Y2:=T;
  End;
  Sub^[NS].X1:=X1;Sub^[NS].Y1:=Y1;Sub^[NS].X2:=X2;Sub^[NS].Y2:=Y2;
  Inc(NS);
 End;

 Function Inside(Wa,Wb:LongInt):Boolean;Begin
  Case Mode of
   0:Inside:=Wa>0;
   1:Inside:=(Wa>0)and(Wb>0);
   Else Inside:=(Wa>0)and(Wb<=0);
  End;
 End;

Begin
 InitGeom(R);
 R.Cls:=3;
 Have:=False;
 Bounds(A);
 If Mode<>0Then Bounds(B);
 If Not Have Then Exit;
 Ext:=MaxR(MaxX-MinX,MaxY-MinY);
 If Ext<=0Then Exit;
 SnapQ:=Ext*1E-9;
 OvEps:=Ext*1E-8;
 Tol:=SnapQ*4;
 NT:=EdgeCount(A);
 If Mode<>0Then NT:=NT+EdgeCount(B);
 If NT<3Then Exit;
 OvAll:=AllocBlock(NT*SizeOf(TEdge));
 NA:=0;
 FillEdges(A,OvAll,NA);
 NT:=NA;
 If Mode<>0Then FillEdges(B,OvAll,NT);
 NB:=NT-NA;
 If NT<3Then Begin
  FreeMem(OvAll,(NT+1)*SizeOf(TEdge));
  Exit;
 End;
 { boites englobantes et decoupage }
 OvBox:=AllocBlock(NT*SizeOf(TEdge));
 OvSp:=AllocBlock(NT*SizeOf(PSplit));
 For I:=0 to NT-1do Begin
  OvBox^[I].X1:=MinR(OvAll^[I].X1,OvAll^[I].X2);
  OvBox^[I].X2:=MaxR(OvAll^[I].X1,OvAll^[I].X2);
  OvBox^[I].Y1:=MinR(OvAll^[I].Y1,OvAll^[I].Y2);
  OvBox^[I].Y2:=MaxR(OvAll^[I].Y1,OvAll^[I].Y2);
  OvSp^[I]:=Nil;
 End;
 OvTot:=0;
 OvNA:=NA;
 BuildSlabs(NT,MinY,MaxY);
 { balayage selon X : seules les aretes dont les boites se chevauchent sont comparees }
 Idx:=AllocBlock(NT*SizeOf(LongInt));
 For I:=0 to NT-1do Idx^[I]:=I;
 SB:=OvBox;SMode:=3;
 If NT>1Then SortIdx(Idx,0,NT-1);
 For P:=0 to NT-2do Begin
  I:=Idx^[P];
  Q:=P+1;
  While Q<NT do Begin
   J:=Idx^[Q];
   If OvBox^[J].X1>OvBox^[I].X2+Tol Then Q:=NT
    Else
   Begin
    If Not((OvBox^[J].Y1>OvBox^[I].Y2+Tol)or(OvBox^[J].Y2<OvBox^[I].Y1-Tol))Then NodeEdges(I,J);
    Inc(Q);
   End;
  End;
 End;
 FreeMem(Idx,NT*SizeOf(LongInt));
 { segments elementaires }
 Sub:=AllocBlock((NT+OvTot)*SizeOf(TEdge));
 NS:=0;
 For I:=0 to NT-1do Begin
  Px:=OvAll^[I].X1;Py:=OvAll^[I].Y1;
  S:=OvSp^[I];
  While S<>Nil do Begin
   Emit(Px,Py,S^.X,S^.Y);
   Px:=S^.X;Py:=S^.Y;
   Nx:=S^.Next;
   Dispose(S);
   S:=Nx;
  End;
  Emit(Px,Py,OvAll^[I].X2,OvAll^[I].Y2);
 End;
 FreeMem(OvSp,NT*SizeOf(PSplit));
 FreeMem(OvBox,NT*SizeOf(TEdge));
 { elimination des doublons }
 Idx:=AllocBlock(NS*SizeOf(LongInt));
 For I:=0 to NS-1do Idx^[I]:=I;
 SB:=Sub;SMode:=0;
 If NS>1Then SortIdx(Idx,0,NS-1);
 NU:=0;
 For I:=0 to NS-1do Begin
  If(I=0)or(CmpIdx(Idx^[I],Idx^[I-1])<>0)Then Begin
   Idx^[NU]:=Idx^[I];
   Inc(NU);
  End;
 End;
 { classement : on garde les segments entre l'interieur et l'exterieur }
 Kp:=AllocBlock((NU+1)*SizeOf(TEdge));
 KN:=0;
 For I:=0 to NU-1do Begin
  P:=Idx^[I];
  Dx:=Sub^[P].X2-Sub^[P].X1;
  Dy:=Sub^[P].Y2-Sub^[P].Y1;
  Len:=Sqrt(Dx*Dx+Dy*Dy);
  If Len>0Then Begin
   Mx:=(Sub^[P].X1+Sub^[P].X2)/2;
   My:=(Sub^[P].Y1+Sub^[P].Y2)/2;
   Ep:=OvEps;
   If Ep>0.1*Len Then Ep:=0.1*Len;
   Qx:=Mx-Dy/Len*Ep;Qy:=My+Dx/Len*Ep;
   WindingAB(Qx,Qy,Wa,Wb);
   InL:=Inside(Wa,Wb);
   Qx:=Mx+Dy/Len*Ep;Qy:=My-Dx/Len*Ep;
   WindingAB(Qx,Qy,Wa,Wb);
   InR:=Inside(Wa,Wb);
   If InL<>InR Then Begin
    If InL Then Begin
     Kp^[KN].X1:=Sub^[P].X1;Kp^[KN].Y1:=Sub^[P].Y1;
     Kp^[KN].X2:=Sub^[P].X2;Kp^[KN].Y2:=Sub^[P].Y2;
    End
     Else
    Begin
     Kp^[KN].X1:=Sub^[P].X2;Kp^[KN].Y1:=Sub^[P].Y2;
     Kp^[KN].X2:=Sub^[P].X1;Kp^[KN].Y2:=Sub^[P].Y1;
    End;
    Inc(KN);
   End;
  End;
 End;
 FreeMem(Idx,NS*SizeOf(LongInt));
 FreeMem(SlabEdge,(SlabStart^[SlabN]+1)*SizeOf(LongInt));
 FreeMem(SlabStart,(SlabN+2)*SizeOf(LongInt));
 FreeMem(Sub,(NT+OvTot)*SizeOf(TEdge));
 FreeMem(OvAll,NT*SizeOf(TEdge));
 If KN>0Then Begin
  { reassemblage des anneaux }
  Ord:=AllocBlock(KN*SizeOf(LongInt));
  Used:=AllocBlock(KN*SizeOf(Boolean));
  For I:=0 to KN-1do Begin Ord^[I]:=I;Used^[I]:=False;End;
  SB:=Kp;SMode:=2;
  If KN>1Then SortIdx(Ord,0,KN-1);
  RB:=AllocBlock((KN+2)*SizeOf(TPt));
  InitGeom(EG);InitGeom(HG);
  For I:=0 to KN-1do Begin
   If Not Used^[Ord^[I]]Then Begin
    Cur:=Ord^[I];
    Sx:=Kp^[Cur].X1;Sy:=Kp^[Cur].Y1;
    RN:=0;
    Ok:=False;
    Repeat
     Used^[Cur]:=True;
     RB^[RN].X:=Kp^[Cur].X1;RB^[RN].Y:=Kp^[Cur].Y1;
     Inc(RN);
     Ex:=Kp^[Cur].X2;Ey:=Kp^[Cur].Y2;
     If(Ex=Sx)and(Ey=Sy)Then Ok:=True
      Else
     Begin
      { recherche des segments partant de (Ex,Ey) }
      Lo:=0;Hi:=KN;
      While Lo<Hi do Begin
       Mid:=(Lo+Hi)div 2;
       If(Kp^[Ord^[Mid]].X1<Ex)or((Kp^[Ord^[Mid]].X1=Ex)and(Kp^[Ord^[Mid]].Y1<Ey))Then Lo:=Mid+1
                                                                                  Else Hi:=Mid;
      End;
      Best:=-1;BestAng:=-10;
      Dx:=Ex-Kp^[Cur].X1;Dy:=Ey-Kp^[Cur].Y1;
      While(Lo<KN)and(Kp^[Ord^[Lo]].X1=Ex)and(Kp^[Ord^[Lo]].Y1=Ey)do Begin
       P:=Ord^[Lo];
       If Not Used^[P]Then Begin
        Mx:=Kp^[P].X2-Ex;My:=Kp^[P].Y2-Ey;
        Ang:=Atan2(Dx*My-Dy*Mx,Dx*Mx+Dy*My);
        If Ang>BestAng Then Begin BestAng:=Ang;Best:=P;End;
       End;
       Inc(Lo);
      End;
      If Best<0Then Cur:=-1 Else Cur:=Best;
     End;
    Until Ok or(Cur<0);
    If Ok and(RN>=3)Then Begin
     Pa:=NewPath(EG,RN+1,0);
     { l'anneau est range dans EG puis deplace selon son aire }
     Move(RB^,Pa^.Pts^,RN*SizeOf(TPt));
     Pa^.Pts^[RN]:=Pa^.Pts^[0];
     Pa^.N:=RN+1;
     Pa^.Area:=RingArea(Pa);
    End;
   End;
  End;
  FreeMem(RB,(KN+2)*SizeOf(TPt));
  FreeMem(Used,KN*SizeOf(Boolean));
  FreeMem(Ord,KN*SizeOf(LongInt));
  { separation exterieurs / trous }
  Pa:=EG.First;
  EG.First:=Nil;EG.Last:=Nil;EG.Count:=0;
  While Pa<>Nil do Begin
   Pb:=Pa^.Next;
   If Pa^.Area>0Then LinkPath(EG,Pa)
                Else LinkPath(HG,Pa);
   Pa:=Pb;
  End;
  { rattachement des trous au plus petit exterieur qui les contient }
  Hp:=HG.First;
  While Hp<>Nil do Begin
   Hp^.Poly:=-1;
   BestArea:=0;
   K:=0;
   Pa:=EG.First;
   While Pa<>Nil do Begin
    If(Pa^.Area>Abs(Hp^.Area))and((Hp^.Poly<0)or(Pa^.Area<BestArea))Then Begin
     Cnt:=0;
     Owner:=2;
     While(Cnt<Hp^.N-1)and(Owner=2)do Begin
      Owner:=PointInRing(Pa,Hp^.Pts^[Cnt].X,Hp^.Pts^[Cnt].Y,Tol);
      Inc(Cnt);
     End;
     If Owner=1Then Begin
      Hp^.Poly:=K;
      BestArea:=Pa^.Area;
     End;
    End;
    Inc(K);
    Pa:=Pa^.Next;
   End;
   Hp:=Hp^.Next;
  End;
  { sortie : chaque exterieur suivi de ses trous }
  HN:=HG.Count;
  HArr:=AllocBlock((HN+1)*SizeOf(PPath));
  K:=0;
  Hp:=HG.First;
  While Hp<>Nil do Begin HArr^[K]:=Hp;Inc(K);Hp:=Hp^.Next;End;
  K:=0;
  Pa:=EG.First;
  While Pa<>Nil do Begin
   Pb:=Pa^.Next;
   Pa^.Poly:=K;
   LinkPath(R,Pa);
   For I:=0 to HN-1do
    If HArr^[I]^.Poly=K Then LinkPath(R,HArr^[I]);
   Inc(K);
   Pa:=Pb;
  End;
  FreeMem(HArr,(HN+1)*SizeOf(PPath));
  R.NPoly:=K;
  FreeMem(Kp,(NU+1)*SizeOf(TEdge));
 End
  Else
 FreeMem(Kp,(NU+1)*SizeOf(TEdge));
End;

{ ------------------------------------------------------------------ }
{ Traitements vectoriels                                              }
{ ------------------------------------------------------------------ }

Procedure RingToGeom(Var G:TGeom;Const Pts:PPts;N:LongInt;Poly:Integer);
Var
 P:PPath;
Begin
 P:=NewPath(G,N+1,Poly);
 Move(Pts^,P^.Pts^,N*SizeOf(TPt));
 P^.Pts^[N]:=P^.Pts^[0];
 P^.N:=N+1;
End;

{ Ajoute un cercle de rayon D autour de (X,Y) }
Procedure AddCircle(Var G:TGeom;X,Y,D:Real;Seg:Integer;Poly:Integer);
Var
 N,K:LongInt;
 P:PPath;
 A:Real;
Begin
 N:=4*Seg;
 P:=NewPath(G,N+1,Poly);
 For K:=0 to N-1do Begin
  A:=2*Pi*K/N;
  P^.Pts^[K].X:=X+D*Cos(A);
  P^.Pts^[K].Y:=Y+D*Sin(A);
 End;
 P^.Pts^[N]:=P^.Pts^[0];
 P^.N:=N+1;
End;

{ Intersection de deux segments (Faux s'ils ne se coupent pas) }
Function SegCross(Ax,Ay,Bx,By,Cx,Cy,Dx,Dy:Real;Var Ix,Iy:Real):Boolean;
Var
 Rx,Ry,Sx,Sy,Den,T,U:Real;
Begin
 SegCross:=False;
 Rx:=Bx-Ax;Ry:=By-Ay;Sx:=Dx-Cx;Sy:=Dy-Cy;
 Den:=Rx*Sy-Ry*Sx;
 If Abs(Den)<=1E-14*Sqrt(Rx*Rx+Ry*Ry)*Sqrt(Sx*Sx+Sy*Sy)Then Exit;
 T:=((Cx-Ax)*Sy-(Cy-Ay)*Sx)/Den;
 U:=((Cx-Ax)*Ry-(Cy-Ay)*Rx)/Den;
 If(T>=0)and(T<=1)and(U>=0)and(U<=1)Then Begin
  Ix:=Ax+T*Rx;Iy:=Ay+T*Ry;
  SegCross:=True;
 End;
End;

{ Courbe de decalage brute d'une ligne : la ligne est parcourue aller puis retour
  et decalee a droite du sens de parcours (joints et extremites arrondis), ce qui
  donne un anneau ferme. Ses auto-intersections sont eliminees ensuite par
  Overlay (enroulement > 0). Un anneau de polygone est traite comme une ligne
  fermee pour obtenir la bande qui entoure sa frontiere. }
Procedure OffsetPath(Var G:TGeom;P:PPath;D:Real;Seg:Integer;Poly:Integer);
Var
 Q,Cyc,Out:PPts;
 M,I,K,CN,ON,Mm:LongInt;
 Ax,Ay,Vx,Vy,Bx,By,L0,L1,D0x,D0y,D1x,D1y,N0x,N0y,N1x,N1y,Cr,Dt,A0,A1,Sw,Ix,Iy:Real;
 Pa:PPath;

 Procedure Emit(X,Y:Real);Begin
  Out^[ON].X:=X;Out^[ON].Y:=Y;
  Inc(ON);
 End;

Begin
 If D<=0Then Exit;
 Q:=AllocBlock(P^.N*SizeOf(TPt));
 M:=0;
 For I:=0 to P^.N-1do
  If(M=0)or(P^.Pts^[I].X<>Q^[M-1].X)or(P^.Pts^[I].Y<>Q^[M-1].Y)Then Begin
   Q^[M]:=P^.Pts^[I];
   Inc(M);
  End;
 If M=1Then Begin
  AddCircle(G,Q^[0].X,Q^[0].Y,D,Seg,Poly);
  FreeMem(Q,P^.N*SizeOf(TPt));
  Exit;
 End;
 { chemin cyclique : aller puis retour }
 CN:=2*M-2;
 Cyc:=AllocBlock(CN*SizeOf(TPt));
 For I:=0 to M-1do Cyc^[I]:=Q^[I];
 For I:=1 to M-2do Cyc^[M-1+I]:=Q^[M-1-I];
 Out:=AllocBlock((CN*(4*Seg+4)+2)*SizeOf(TPt));
 ON:=0;
 For I:=0 to CN-1do Begin
  K:=(I+CN-1)mod CN;
  Ax:=Cyc^[K].X;Ay:=Cyc^[K].Y;
  Vx:=Cyc^[I].X;Vy:=Cyc^[I].Y;
  K:=(I+1)mod CN;
  Bx:=Cyc^[K].X;By:=Cyc^[K].Y;
  L0:=Sqrt(Sqr(Vx-Ax)+Sqr(Vy-Ay));
  L1:=Sqrt(Sqr(Bx-Vx)+Sqr(By-Vy));
  D0x:=(Vx-Ax)/L0;D0y:=(Vy-Ay)/L0;
  D1x:=(Bx-Vx)/L1;D1y:=(By-Vy)/L1;
  N0x:=D0y*D;N0y:=-D0x*D;
  N1x:=D1y*D;N1y:=-D1x*D;
  Cr:=D0x*D1y-D0y*D1x;
  Dt:=D0x*D1x+D0y*D1y;
  If(Cr>1E-12)or((Cr>=-1E-12)and(Dt<0))Then Begin
   { virage exterieur (ou demi-tour) : arc de cercle autour du sommet }
   A0:=Atan2(N0y,N0x);
   A1:=Atan2(N1y,N1x);
   Sw:=A1-A0;
   While Sw<0do Sw:=Sw+2*Pi;
   While Sw>=2*Pi do Sw:=Sw-2*Pi;
   If(Abs(Cr)<=1E-12)and(Dt<0)Then Sw:=Pi;
   Mm:=Trunc(Sw/(Pi/2)*Seg+0.999999);
   If Mm<1Then Mm:=1;
   Emit(Vx+N0x,Vy+N0y);
   For K:=1 to Mm-1do
    Emit(Vx+D*Cos(A0+Sw*K/Mm),Vy+D*Sin(A0+Sw*K/Mm));
   Emit(Vx+N1x,Vy+N1y);
  End
   Else
  If Cr<-1E-12Then Begin
   { virage interieur : les decalages se croisent }
   If SegCross(Ax+N0x,Ay+N0y,Vx+N0x,Vy+N0y,Vx+N1x,Vy+N1y,Bx+N1x,By+N1y,Ix,Iy)Then
    Emit(Ix,Iy)
   Else Begin
    Emit(Vx+N0x,Vy+N0y);
    Emit(Vx,Vy);
    Emit(Vx+N1x,Vy+N1y);
   End;
  End
   Else
  Emit(Vx+N0x,Vy+N0y);
 End;
 Pa:=NewPath(G,ON+1,Poly);
 Move(Out^,Pa^.Pts^,ON*SizeOf(TPt));
 Pa^.Pts^[ON]:=Pa^.Pts^[0];
 Pa^.N:=ON+1;
 FreeMem(Out,(CN*(4*Seg+4)+2)*SizeOf(TPt));
 FreeMem(Cyc,CN*SizeOf(TPt));
 FreeMem(Q,P^.N*SizeOf(TPt));
End;

{ Tampon d'une geometrie aplatie }
Procedure BufferGeom(Var G:TGeom;Dist:Real;Seg:Integer;Var R:TGeom);
Var
 A,B:TGeom;
 P,Q:PPath;
 Prev,K:Integer;
 Ext:Boolean;
 I,J:LongInt;
 Tmp:TPt;
Begin
 InitGeom(R);
 InitGeom(A);InitGeom(B);
 A.Cls:=3;B.Cls:=3;
 K:=0;
 Case G.Cls of
  1:If Dist>0Then Begin
   P:=G.First;
   While P<>Nil do Begin
    AddCircle(A,P^.Pts^[0].X,P^.Pts^[0].Y,Dist,Seg,K);
    Inc(K);
    P:=P^.Next;
   End;
  End;
  2:If Dist>0Then Begin
   P:=G.First;
   While P<>Nil do Begin
    OffsetPath(A,P,Dist,Seg,K);
    Inc(K);
    P:=P^.Next;
   End;
  End;
  3:If Dist<>0Then Begin
   { polygone : anneaux orientes (exterieur anti-horaire, trou horaire) }
   Prev:=-1;
   P:=G.First;
   While P<>Nil do Begin
    Ext:=P^.Poly<>Prev;
    Prev:=P^.Poly;
    Q:=CopyPath(A,P,K);
    If(Ext and(RingArea(Q)<0))or((Not Ext)and(RingArea(Q)>0))Then
     For I:=0 to Q^.N div 2-1do Begin
      J:=Q^.N-1-I;
      Tmp:=Q^.Pts^[I];Q^.Pts^[I]:=Q^.Pts^[J];Q^.Pts^[J]:=Tmp;
     End;
    Inc(K);
    P:=P^.Next;
   End;
   { bande de largeur |Dist| autour de la frontiere }
   P:=G.First;
   While P<>Nil do Begin
    If Dist>0Then OffsetPath(A,P,Dist,Seg,K)
             Else OffsetPath(B,P,-Dist,Seg,K);
    Inc(K);
    P:=P^.Next;
   End;
  End;
 End;
 If A.First<>Nil Then Begin
  KeepOrient:=True;
  If(G.Cls=3)and(Dist<0)Then Overlay(2,A,B,R)
                        Else Overlay(0,A,B,R);
  KeepOrient:=False;
 End;
 FreeGeom(A);
 FreeGeom(B);
End;

{ Enveloppe convexe (chaine monotone d'Andrew) }
Procedure HullGeom(Var G:TGeom;Var R:TGeom);
Var
 P:PPath;
 Pts,Srt:PPts;
 Idx,Chain:PLongs;
 N,I,K,T,M,Total:LongInt;
 Pa:PPath;

 Function Cross(O,A,B:LongInt):Real;Begin
  Cross:=(Srt^[A].X-Srt^[O].X)*(Srt^[B].Y-Srt^[O].Y)-(Srt^[A].Y-Srt^[O].Y)*(Srt^[B].X-Srt^[O].X);
 End;

Begin
 InitGeom(R);
 Total:=0;
 P:=G.First;
 While P<>Nil do Begin Inc(Total,P^.N);P:=P^.Next;End;
 If Total=0Then Exit;
 Pts:=AllocBlock(Total*SizeOf(TPt));
 N:=0;
 P:=G.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-1do Begin Pts^[N]:=P^.Pts^[I];Inc(N);End;
  P:=P^.Next;
 End;
 Idx:=AllocBlock(Total*SizeOf(LongInt));
 For I:=0 to Total-1do Idx^[I]:=I;
 SP:=Pts;SMode:=1;
 If Total>1Then SortIdx(Idx,0,Total-1);
 { points tries, sans doublons }
 Srt:=AllocBlock(Total*SizeOf(TPt));
 N:=0;
 For I:=0 to Total-1do
  If(I=0)or(CmpIdx(Idx^[I],Idx^[I-1])<>0)Then Begin
   Srt^[N]:=Pts^[Idx^[I]];
   Inc(N);
  End;
 FreeMem(Idx,Total*SizeOf(LongInt));
 FreeMem(Pts,Total*SizeOf(TPt));
 If N=1Then Begin
  R.Cls:=1;
  Pa:=NewPath(R,1,0);
  Pa^.Pts^[0]:=Srt^[0];
 End
  Else
 Begin
  Chain:=AllocBlock((2*N+2)*SizeOf(LongInt));
  K:=0;
  For I:=0 to N-1do Begin
   While(K>=2)and(Cross(Chain^[K-2],Chain^[K-1],I)<=0)do Dec(K);
   Chain^[K]:=I;Inc(K);
  End;
  T:=K+1;
  For I:=N-2 downto 0do Begin
   While(K>=T)and(Cross(Chain^[K-2],Chain^[K-1],I)<=0)do Dec(K);
   Chain^[K]:=I;Inc(K);
  End;
  M:=K-1;   { le dernier point repete le premier }
  If M<3Then Begin
   R.Cls:=2;
   Pa:=NewPath(R,2,0);
   Pa^.Pts^[0]:=Srt^[0];
   Pa^.Pts^[1]:=Srt^[N-1];
  End
   Else
  Begin
   R.Cls:=3;
   Pa:=NewPath(R,M+1,0);
   For I:=0 to M-1do Pa^.Pts^[I]:=Srt^[Chain^[I]];
   Pa^.Pts^[M]:=Pa^.Pts^[0];
   R.NPoly:=1;
  End;
  FreeMem(Chain,(2*N+2)*SizeOf(LongInt));
 End;
 FreeMem(Srt,Total*SizeOf(TPt));
End;

{ Centroide d'une geometrie aplatie }
Procedure CentroidGeom(Var G:TGeom;Var Cx,Cy:Real;Var Ok:Boolean);
Var
 P:PPath;
 I,J:LongInt;
 Sa,Sx,Sy,A,Ox,Oy,L,Mx,My,N:Real;
 Prev:Integer;
Begin
 Ok:=False;
 If G.First=Nil Then Exit;
 Ox:=G.First^.Pts^[0].X;Oy:=G.First^.Pts^[0].Y;
 Sa:=0;Sx:=0;Sy:=0;
 If G.Cls=3Then Begin
  { le premier anneau d'un polygone est son exterieur (aire positive),
    les suivants sont des trous (aire negative) }
  Prev:=-1;
  P:=G.First;
  While P<>Nil do Begin
   A:=Abs(RingArea(P));
   If P^.Poly=Prev Then A:=-A;
   Prev:=P^.Poly;
   Mx:=0;My:=0;L:=0;
   For I:=0 to P^.N-1do Begin
    J:=I+1;
    If J>=P^.N Then J:=0;
    N:=(P^.Pts^[I].X-Ox)*(P^.Pts^[J].Y-Oy)-(P^.Pts^[J].X-Ox)*(P^.Pts^[I].Y-Oy);
    Mx:=Mx+((P^.Pts^[I].X-Ox)+(P^.Pts^[J].X-Ox))*N;
    My:=My+((P^.Pts^[I].Y-Oy)+(P^.Pts^[J].Y-Oy))*N;
    L:=L+N;
   End;
   If L<>0Then Begin
    Sa:=Sa+A;
    Sx:=Sx+A*Mx/(3*L);
    Sy:=Sy+A*My/(3*L);
   End;
   P:=P^.Next;
  End;
  If Sa<>0Then Begin
   Cx:=Ox+Sx/Sa;Cy:=Oy+Sy/Sa;
   Ok:=True;
   Exit;
  End;
 End;
 If G.Cls=2Then Begin
  { barycentre des segments pondere par leur longueur }
  P:=G.First;
  Sa:=0;Sx:=0;Sy:=0;
  While P<>Nil do Begin
   For I:=0 to P^.N-2do Begin
    L:=Sqrt(Sqr(P^.Pts^[I+1].X-P^.Pts^[I].X)+Sqr(P^.Pts^[I+1].Y-P^.Pts^[I].Y));
    Sa:=Sa+L;
    Sx:=Sx+L*((P^.Pts^[I].X+P^.Pts^[I+1].X)/2-Ox);
    Sy:=Sy+L*((P^.Pts^[I].Y+P^.Pts^[I+1].Y)/2-Oy);
   End;
   P:=P^.Next;
  End;
  If Sa>0Then Begin
   Cx:=Ox+Sx/Sa;Cy:=Oy+Sy/Sa;
   Ok:=True;
   Exit;
  End;
 End;
 { moyenne des sommets (points, ou geometries degenerees) }
 P:=G.First;
 Sx:=0;Sy:=0;Sa:=0;
 While P<>Nil do Begin
  I:=P^.N;
  { un anneau ferme repete son premier sommet }
  If(G.Cls=3)and(I>1)and(P^.Pts^[0].X=P^.Pts^[I-1].X)and(P^.Pts^[0].Y=P^.Pts^[I-1].Y)Then Dec(I);
  For J:=0 to I-1do Begin
   Sx:=Sx+(P^.Pts^[J].X-Ox);
   Sy:=Sy+(P^.Pts^[J].Y-Oy);
   Sa:=Sa+1;
  End;
  P:=P^.Next;
 End;
 If Sa>0Then Begin
  Cx:=Ox+Sx/Sa;Cy:=Oy+Sy/Sa;
  Ok:=True;
 End;
End;

{ Distance d'un point a un segment }
Function DistSeg(Px,Py,X1,Y1,X2,Y2:Real):Real;
Var
 Dx,Dy,L2,T:Real;
Begin
 Dx:=X2-X1;Dy:=Y2-Y1;
 L2:=Dx*Dx+Dy*Dy;
 If L2<=0Then T:=0
  Else
 Begin
  T:=((Px-X1)*Dx+(Py-Y1)*Dy)/L2;
  If T<0Then T:=0;
  If T>1Then T:=1;
 End;
 DistSeg:=Sqrt(Sqr(Px-(X1+T*Dx))+Sqr(Py-(Y1+T*Dy)));
End;

{ Point dans (ou sur le bord) du polygone defini par les aretes orientees E }
Function InsideOrOn(E:PEdges;N:LongInt;X,Y,Tol:Real):Boolean;
Var
 I:LongInt;
Begin
 If Winding(E,N,X,Y)<>0Then Begin
  InsideOrOn:=True;
  Exit;
 End;
 For I:=0 to N-1do
  If DistSeg(X,Y,E^[I].X1,E^[I].Y1,E^[I].X2,E^[I].Y2)<=Tol Then Begin
   InsideOrOn:=True;
   Exit;
  End;
 InsideOrOn:=False;
End;

{ Decoupe les chemins de lignes de G par le polygone (aretes E) }
Procedure ClipLines(Var G:TGeom;E:PEdges;N:LongInt;Tol:Real;Var R:TGeom);
Var
 P:PPath;
 K,I,Cnt,M:LongInt;
 Ts:PReals;
 Ax,Ay,Bx,By,Dx,Dy,Den,Rx,Ry,T,U,L,Tmp,Mx,My:Real;
 Pieces:TGeom;
 Pa,Pc:PPath;
 Buf:PPts;
 BN:LongInt;

 Procedure AddT(V:Real);Begin
  If(V>1E-12)and(V<1-1E-12)Then Begin
   Ts^[Cnt]:=V;Inc(Cnt);
  End;
 End;

Begin
 InitGeom(R);
 R.Cls:=2;
 Ts:=AllocBlock((2*N+4)*SizeOf(Real));
 P:=G.First;
 While P<>Nil do Begin
  InitGeom(Pieces);
  For K:=0 to P^.N-2do Begin
   Ax:=P^.Pts^[K].X;Ay:=P^.Pts^[K].Y;Bx:=P^.Pts^[K+1].X;By:=P^.Pts^[K+1].Y;
   Dx:=Bx-Ax;Dy:=By-Ay;
   L:=Sqrt(Dx*Dx+Dy*Dy);
   If L>0Then Begin
    Cnt:=0;
    Ts^[Cnt]:=0;Inc(Cnt);
    For I:=0 to N-1do Begin
     Rx:=E^[I].X2-E^[I].X1;Ry:=E^[I].Y2-E^[I].Y1;
     Den:=Dx*Ry-Dy*Rx;
     If Abs(Den)<=1E-12*L*Sqrt(Rx*Rx+Ry*Ry)Then Begin
      { paralleles : projection des extremites de l'arete sur le segment }
      If DistSeg(E^[I].X1,E^[I].Y1,Ax,Ay,Bx,By)<=Tol Then AddT(((E^[I].X1-Ax)*Dx+(E^[I].Y1-Ay)*Dy)/(L*L));
      If DistSeg(E^[I].X2,E^[I].Y2,Ax,Ay,Bx,By)<=Tol Then AddT(((E^[I].X2-Ax)*Dx+(E^[I].Y2-Ay)*Dy)/(L*L));
     End
      Else
     Begin
      T:=((E^[I].X1-Ax)*Ry-(E^[I].Y1-Ay)*Rx)/Den;
      U:=((E^[I].X1-Ax)*Dy-(E^[I].Y1-Ay)*Dx)/Den;
      If(T>=0)and(T<=1)and(U>=-1E-12)and(U<=1+1E-12)Then AddT(T);
     End;
    End;
    Ts^[Cnt]:=1;Inc(Cnt);
    { tri par insertion }
    For I:=1 to Cnt-1do Begin
     Tmp:=Ts^[I];
     M:=I-1;
     While(M>=0)and(Ts^[M]>Tmp)do Begin Ts^[M+1]:=Ts^[M];Dec(M);End;
     Ts^[M+1]:=Tmp;
    End;
    For I:=0 to Cnt-2do Begin
     If Ts^[I+1]-Ts^[I]>1E-12Then Begin
      Mx:=Ax+(Ts^[I]+Ts^[I+1])/2*Dx;
      My:=Ay+(Ts^[I]+Ts^[I+1])/2*Dy;
      If InsideOrOn(E,N,Mx,My,Tol)Then Begin
       Pa:=NewPath(Pieces,2,0);
       Pa^.Pts^[0].X:=Ax+Ts^[I]*Dx;Pa^.Pts^[0].Y:=Ay+Ts^[I]*Dy;
       Pa^.Pts^[1].X:=Ax+Ts^[I+1]*Dx;Pa^.Pts^[1].Y:=Ay+Ts^[I+1]*Dy;
      End;
     End;
    End;
   End;
  End;
  { fusion des morceaux consecutifs }
  If Pieces.Count>0Then Begin
   Buf:=AllocBlock((2*Pieces.Count+2)*SizeOf(TPt));
   BN:=0;
   Pa:=Pieces.First;
   While Pa<>Nil do Begin
    If(BN>0)and((Buf^[BN-1].X<>Pa^.Pts^[0].X)or(Buf^[BN-1].Y<>Pa^.Pts^[0].Y))Then Begin
     Pc:=NewPath(R,BN,0);
     Move(Buf^,Pc^.Pts^,BN*SizeOf(TPt));
     Pc^.N:=BN;
     BN:=0;
    End;
    If BN=0Then Begin Buf^[0]:=Pa^.Pts^[0];BN:=1;End;
    Buf^[BN]:=Pa^.Pts^[1];Inc(BN);
    Pa:=Pa^.Next;
   End;
   If BN>0Then Begin
    Pc:=NewPath(R,BN,0);
    Move(Buf^,Pc^.Pts^,BN*SizeOf(TPt));
    Pc^.N:=BN;
   End;
   FreeMem(Buf,(2*Pieces.Count+2)*SizeOf(TPt));
  End;
  FreeGeom(Pieces);
  P:=P^.Next;
 End;
 FreeMem(Ts,(2*N+4)*SizeOf(Real));
End;

{ ------------------------------------------------------------------ }
{ Expressions (native:extractbyexpression)                            }
{ ------------------------------------------------------------------ }

Var
 ExprS:String;
 ExprP:Integer;
 ExprProps:PJ;

Procedure EFail(Msg:String);Begin
 Fail('Error: invalid expression ('+Msg+') near position '+IntToStr(ExprP));
End;

Function VNull:TVal;
Var V:TVal;
Begin V.K:=0;V.N:=0;V.S:='';VNull:=V;End;

Function VNum(R:Real):TVal;
Var V:TVal;
Begin V.K:=1;V.N:=R;V.S:='';VNum:=V;End;

Function VStr(S:String):TVal;
Var V:TVal;
Begin V.K:=2;V.N:=0;V.S:=S;VStr:=V;End;

Function VBool(B:Boolean):TVal;
Var V:TVal;
Begin
 V.K:=3;V.S:='';
 If B Then V.N:=1 Else V.N:=0;
 VBool:=V;
End;

Function ToNum(V:TVal;Var R:Real):Boolean;
Var
 E:Integer;
Begin
 ToNum:=False;
 Case V.K of
  1,3:Begin R:=V.N;ToNum:=True;End;
  2:Begin
   Val(V.S,R,E);
   ToNum:=(E=0)and(V.S<>'');
  End;
 End;
End;

Function ToStr(V:TVal):String;Begin
 Case V.K of
  1:ToStr:=NumStr(V.N);
  2:ToStr:=V.S;
  3:If V.N<>0Then ToStr:='true' Else ToStr:='false';
  Else ToStr:='';
 End;
End;

Function Unesc(S:String):String;
Var
 I:Integer;
 T:String;
Begin
 T:='';
 I:=1;
 While I<=Length(S)do Begin
  If(S[I]='\')and(I<Length(S))Then Begin
   Inc(I);
   Case S[I] of
    'n':T:=T+#10;
    't':T:=T+#9;
    'r':T:=T+#13;
    Else T:=T+S[I];
   End;
  End
   Else
  T:=T+S[I];
  Inc(I);
 End;
 Unesc:=T;
End;

Function PropVal(Name:String):TVal;
Var
 N:PJ;
 R:Real;
 E:Integer;
Begin
 PropVal:=VNull;
 N:=JFind(ExprProps,Name);
 If N=Nil Then Exit;
 Case N^.Kind of
  1:PropVal:=VBool(JVal(N)='true');
  2:Begin
   Val(JVal(N),R,E);
   If E=0Then PropVal:=VNum(R);
  End;
  3:PropVal:=VStr(Unesc(JVal(N)));
 End;
End;

Procedure ESkip;Begin
 While(ExprP<=Length(ExprS))and(ExprS[ExprP]in[' ',#9])do Inc(ExprP);
End;

Function EKw(Kw:String):Boolean;
Var
 L:Integer;
Begin
 ESkip;
 L:=Length(Kw);
 EKw:=False;
 If StrUpper(Copy(ExprS,ExprP,L))=Kw Then
  If(ExprP+L>Length(ExprS))or Not(UpCase(ExprS[ExprP+L])in['A'..'Z','0'..'9','_'])Then Begin
   Inc(ExprP,L);
   EKw:=True;
  End;
End;

Function EOp(Op:String):Boolean;Begin
 ESkip;
 EOp:=False;
 If Copy(ExprS,ExprP,Length(Op))=Op Then Begin
  Inc(ExprP,Length(Op));
  EOp:=True;
 End;
End;

Function LikeMatch(Const S,Pat:String;I,J:Integer):Boolean;
Begin
 If J>Length(Pat)Then LikeMatch:=I>Length(S)
  Else
 If Pat[J]='%'Then Begin
  LikeMatch:=True;
  While I<=Length(S)+1do Begin
   If LikeMatch(S,Pat,I,J+1)Then Exit;
   Inc(I);
  End;
  LikeMatch:=False;
 End
  Else
 If I>Length(S)Then LikeMatch:=False
  Else
 If(Pat[J]='_')or(Pat[J]=S[I])Then LikeMatch:=LikeMatch(S,Pat,I+1,J+1)
                              Else LikeMatch:=False;
End;

Function DoCompare(Op:Integer;A,B:TVal):TVal;
Var
 C:Integer;
 Ra,Rb:Real;
 Sa,Sb:String;
Begin
 If(A.K=0)or(B.K=0)Then Begin DoCompare:=VNull;Exit;End;
 If ToNum(A,Ra)and ToNum(B,Rb)and Not((A.K=2)and(B.K=2))Then C:=CmpR(Ra,Rb)
  Else
 Begin
  Sa:=ToStr(A);Sb:=ToStr(B);
  If Sa<Sb Then C:=-1 Else If Sa>Sb Then C:=1 Else C:=0;
 End;
 Case Op of
  1:DoCompare:=VBool(C=0);
  2:DoCompare:=VBool(C<>0);
  3:DoCompare:=VBool(C<0);
  4:DoCompare:=VBool(C>0);
  5:DoCompare:=VBool(C<=0);
  Else DoCompare:=VBool(C>=0);
 End;
End;

Function EvalOr:TVal;Forward;

Function EvalPrimary:TVal;
Var
 V,W:TVal;
 S,Name:String;
 C:Char;
 R,Ra:Real;
 E:Integer;
 Start:Integer;
Begin
 ESkip;
 If ExprP>Length(ExprS)Then EFail('unexpected end of expression');
 C:=ExprS[ExprP];
 If C='('Then Begin
  Inc(ExprP);
  V:=EvalOr;
  If Not EOp(')')Then EFail('")" expected');
  EvalPrimary:=V;
 End
  Else
 If C in['0'..'9','.']Then Begin
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(ExprS[ExprP]in['0'..'9','.'])do Inc(ExprP);
  If(ExprP<=Length(ExprS))and(ExprS[ExprP]in['e','E'])Then Begin
   Inc(ExprP);
   If(ExprP<=Length(ExprS))and(ExprS[ExprP]in['+','-'])Then Inc(ExprP);
   While(ExprP<=Length(ExprS))and(ExprS[ExprP]in['0'..'9'])do Inc(ExprP);
  End;
  Val(Copy(ExprS,Start,ExprP-Start),R,E);
  If E<>0Then EFail('invalid number');
  EvalPrimary:=VNum(R);
 End
  Else
 If C=''''Then Begin
  S:='';
  Inc(ExprP);
  While True do Begin
   If ExprP>Length(ExprS)Then EFail('unterminated string');
   If ExprS[ExprP]=''''Then Begin
    If(ExprP<Length(ExprS))and(ExprS[ExprP+1]='''')Then Begin
     S:=S+'''';
     Inc(ExprP,2);
    End
     Else
    Begin
     Inc(ExprP);
     Break;
    End;
   End
    Else
   Begin
    S:=S+ExprS[ExprP];
    Inc(ExprP);
   End;
  End;
  EvalPrimary:=VStr(S);
 End
  Else
 If C='"'Then Begin
  Inc(ExprP);
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(ExprS[ExprP]<>'"')do Inc(ExprP);
  If ExprP>Length(ExprS)Then EFail('unterminated field name');
  Name:=Copy(ExprS,Start,ExprP-Start);
  Inc(ExprP);
  EvalPrimary:=PropVal(Name);
 End
  Else
 If UpCase(C)in['A'..'Z','_']Then Begin
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(UpCase(ExprS[ExprP])in['A'..'Z','0'..'9','_'])do Inc(ExprP);
  Name:=Copy(ExprS,Start,ExprP-Start);
  If StrUpper(Name)='TRUE'Then EvalPrimary:=VBool(True) Else
  If StrUpper(Name)='FALSE'Then EvalPrimary:=VBool(False) Else
  If StrUpper(Name)='NULL'Then EvalPrimary:=VNull
   Else
  Begin
   ESkip;
   If(ExprP<=Length(ExprS))and(ExprS[ExprP]='(')Then Begin
    Inc(ExprP);
    V:=EvalOr;
    W:=VNull;
    If EOp(',')Then W:=EvalOr;
    If Not EOp(')')Then EFail('")" expected');
    Name:=StrUpper(Name);
    If Name='LOWER'Then Begin
     If V.K=0Then EvalPrimary:=V
      Else
     Begin
      S:=ToStr(V);
      For E:=1 to Length(S)do If S[E]in['A'..'Z']Then S[E]:=Chr(Ord(S[E])+32);
      EvalPrimary:=VStr(S);
     End;
    End Else
    If Name='UPPER'Then Begin
     If V.K=0Then EvalPrimary:=V Else EvalPrimary:=VStr(StrUpper(ToStr(V)));
    End Else
    If(Name='LENGTH')or(Name='LEN')Then Begin
     If V.K=0Then EvalPrimary:=V Else EvalPrimary:=VNum(Length(ToStr(V)));
    End Else
    If Name='ABS'Then Begin
     If ToNum(V,R)and(V.K<>0)Then EvalPrimary:=VNum(Abs(R)) Else EvalPrimary:=VNull;
    End Else
    If Name='SQRT'Then Begin
     If ToNum(V,R)and(V.K<>0)and(R>=0)Then EvalPrimary:=VNum(Sqrt(R)) Else EvalPrimary:=VNull;
    End Else
    If Name='ROUND'Then Begin
     If ToNum(V,R)and(V.K<>0)Then Begin
      If W.K=0Then EvalPrimary:=VNum(FloorR(R+0.5))
       Else
      Begin
       Ra:=1;
       For E:=1 to Round(W.N)do Ra:=Ra*10;
       EvalPrimary:=VNum(FloorR(R*Ra+0.5)/Ra);
      End;
     End
      Else
     EvalPrimary:=VNull;
    End
     Else
    EFail('unknown function '+Name);
   End
    Else
   EvalPrimary:=PropVal(Name);
  End;
 End
  Else
 EFail('unexpected character "'+C+'"');
End;

Function EvalUnary:TVal;
Var
 V:TVal;
 R:Real;
Begin
 EvalUnary:=VNull;
 If EOp('-')Then Begin
  V:=EvalUnary;
  If ToNum(V,R)and(V.K<>0)Then EvalUnary:=VNum(-R) Else EvalUnary:=VNull;
 End
  Else
 EvalUnary:=EvalPrimary;
End;

Function EvalMul:TVal;
Var
 V,W:TVal;
 A,B:Real;
 Op:Char;
Begin
 V:=EvalUnary;
 While(EOp('*')or EOp('/')or EOp('%'))do Begin
  Op:=ExprS[ExprP-1];
  W:=EvalUnary;
  If ToNum(V,A)and ToNum(W,B)and(V.K<>0)and(W.K<>0)Then Begin
   If Op='*'Then V:=VNum(A*B) Else
   If B=0Then V:=VNull Else
   If Op='/'Then V:=VNum(A/B)
            Else V:=VNum(A-B*Int(A/B));
  End
   Else
  V:=VNull;
 End;
 EvalMul:=V;
End;

Function EvalAdd:TVal;
Var
 V,W:TVal;
 A,B:Real;
 Op:Char;
Begin
 V:=EvalMul;
 Repeat
  ESkip;
  If EOp('||')Then Begin
   W:=EvalMul;
   If(V.K=0)or(W.K=0)Then V:=VNull Else V:=VStr(ToStr(V)+ToStr(W));
  End
   Else
  If EOp('+')or EOp('-')Then Begin
   Op:=ExprS[ExprP-1];
   W:=EvalMul;
   If ToNum(V,A)and ToNum(W,B)and(V.K<>0)and(W.K<>0)Then Begin
    If Op='+'Then V:=VNum(A+B) Else V:=VNum(A-B);
   End
    Else
   V:=VNull;
  End
   Else
  Break;
 Until False;
 EvalAdd:=V;
End;

Function EvalCompare:TVal;
Var
 V,W,X:TVal;
 Op:Integer;
 Neg,Found:Boolean;
Begin
 V:=EvalAdd;
 ESkip;
 Op:=0;
 If EOp('<=')Then Op:=5 Else
 If EOp('>=')Then Op:=6 Else
 If EOp('<>')or EOp('!=')Then Op:=2 Else
 If EOp('==')or EOp('=')Then Op:=1 Else
 If EOp('<')Then Op:=3 Else
 If EOp('>')Then Op:=4;
 If Op>0Then Begin
  W:=EvalAdd;
  V:=DoCompare(Op,V,W);
 End
  Else
 If EKw('IS')Then Begin
  Neg:=EKw('NOT');
  If Not EKw('NULL')Then EFail('NULL expected');
  V:=VBool((V.K=0)<>Neg);
 End
  Else
 If EKw('LIKE')Then Begin
  W:=EvalAdd;
  If(V.K=0)or(W.K=0)Then V:=VNull Else V:=VBool(LikeMatch(ToStr(V),ToStr(W),1,1));
 End
  Else
 If EKw('ILIKE')Then Begin
  W:=EvalAdd;
  If(V.K=0)or(W.K=0)Then V:=VNull
                    Else V:=VBool(LikeMatch(StrUpper(ToStr(V)),StrUpper(ToStr(W)),1,1));
 End
  Else
 Begin
  Neg:=False;
  Found:=False;
  If EKw('NOT')Then Begin
   Neg:=True;
   If Not EKw('IN')Then EFail('IN expected');
   Found:=True;
  End
   Else
  If EKw('IN')Then Found:=True;
  If Found Then Begin
   If Not EOp('(')Then EFail('"(" expected');
   Found:=False;
   Repeat
    W:=EvalAdd;
    X:=DoCompare(1,V,W);
    If(X.K=3)and(X.N<>0)Then Found:=True;
   Until Not EOp(',');
   If Not EOp(')')Then EFail('")" expected');
   If V.K=0Then V:=VNull Else V:=VBool(Found<>Neg);
  End;
 End;
 EvalCompare:=V;
End;

Function EvalNot:TVal;
Var
 V:TVal;
Begin
 EvalNot:=VNull;
 If EKw('NOT')Then Begin
  V:=EvalNot;
  If V.K=0Then EvalNot:=V Else EvalNot:=VBool(V.N=0);
 End
  Else
 EvalNot:=EvalCompare;
End;

Function EvalAnd:TVal;
Var
 V,W:TVal;
Begin
 V:=EvalNot;
 While EKw('AND')do Begin
  W:=EvalNot;
  If((V.K<>0)and(V.N=0))or((W.K<>0)and(W.N=0))Then V:=VBool(False) Else
  If(V.K=0)or(W.K=0)Then V:=VNull
                    Else V:=VBool(True);
 End;
 EvalAnd:=V;
End;

Function EvalOr:TVal;
Var
 V,W:TVal;
Begin
 V:=EvalAnd;
 While EKw('OR')do Begin
  W:=EvalAnd;
  If((V.K<>0)and(V.N<>0))or((W.K<>0)and(W.N<>0))Then V:=VBool(True) Else
  If(V.K=0)or(W.K=0)Then V:=VNull
                    Else V:=VBool(False);
 End;
 EvalOr:=V;
End;

Function EvalFeature(Expr:String;Props:PJ):Boolean;
Var
 V:TVal;
Begin
 ExprS:=Expr;
 ExprP:=1;
 ExprProps:=Props;
 V:=EvalOr;
 ESkip;
 If ExprP<=Length(ExprS)Then EFail('unexpected token');
 EvalFeature:=(V.K in[1,3])and(V.N<>0);
End;

{ ------------------------------------------------------------------ }
{ Rasters (ESRI ASCII Grid)                                           }
{ ------------------------------------------------------------------ }

Var
 RF:Text;
 RBuf:Array[0..16383]of Char;
 RTok:String;

Function RTokNext:Boolean;
Var
 C:Char;
Begin
 RTok:='';
 RTokNext:=False;
 While Not EOF(RF)do Begin
  Read(RF,C);
  If C in[' ',#9,#10,#13,#26]Then Begin
   If RTok<>''Then Begin RTokNext:=True;Exit;End;
  End
   Else
  Begin
   If Length(RTok)>=250Then Fail('Error: invalid raster token');
   RTok:=RTok+C;
  End;
 End;
 RTokNext:=RTok<>'';
End;

Procedure RNum(Const S:String;Var R:Real);
Var
 E:Integer;
Begin
 Val(S,R,E);
 If E<>0Then Fail('Error: invalid number "'+S+'" in raster');
End;

Procedure ReadRaster(FileName:String;Var R:TRaster);
Var
 Key:String;
 V,Dx,Dy:Real;
 HaveNC,HaveNR,HaveX,HaveY,HaveC,CenterX,CenterY:Boolean;
 I,Total:LongInt;
 Pending:Boolean;
Begin
 {$I-}
 Assign(RF,FileName);
 Reset(RF);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to open raster file '+FileName);
 SetTextBuf(RF,RBuf);
 R.NoData:=-9999;
 R.NC:=0;R.NR:=0;R.XLL:=0;R.YLL:=0;R.Cell:=0;
 Dx:=0;Dy:=0;
 HaveNC:=False;HaveNR:=False;HaveX:=False;HaveY:=False;HaveC:=False;
 CenterX:=False;CenterY:=False;
 Pending:=False;
 While Not Pending and RTokNext do Begin
  Key:=StrUpper(RTok);
  If Key='NCOLS'Then Begin RTokNext;RNum(RTok,V);R.NC:=Round(V);HaveNC:=True;End Else
  If Key='NROWS'Then Begin RTokNext;RNum(RTok,V);R.NR:=Round(V);HaveNR:=True;End Else
  If Key='XLLCORNER'Then Begin RTokNext;RNum(RTok,R.XLL);HaveX:=True;End Else
  If Key='YLLCORNER'Then Begin RTokNext;RNum(RTok,R.YLL);HaveY:=True;End Else
  If Key='XLLCENTER'Then Begin RTokNext;RNum(RTok,R.XLL);HaveX:=True;CenterX:=True;End Else
  If Key='YLLCENTER'Then Begin RTokNext;RNum(RTok,R.YLL);HaveY:=True;CenterY:=True;End Else
  If Key='CELLSIZE'Then Begin RTokNext;RNum(RTok,R.Cell);HaveC:=True;End Else
  If Key='DX'Then Begin RTokNext;RNum(RTok,Dx);End Else
  If Key='DY'Then Begin RTokNext;RNum(RTok,Dy);End Else
  If Key='NODATA_VALUE'Then Begin RTokNext;RNum(RTok,R.NoData);End
   Else
  Pending:=True;
 End;
 If Not(HaveNC and HaveNR and HaveX and HaveY)Then Fail('Error: invalid ASCII grid header in '+FileName);
 If Not HaveC Then Begin
  If(Dx>0)and(Dx=Dy)Then Begin R.Cell:=Dx;HaveC:=True;End;
 End;
 If(Not HaveC)or(R.Cell<=0)Then Fail('Error: invalid or non-square cell size in '+FileName);
 If(R.NC<1)or(R.NR<1)Then Fail('Error: invalid raster size in '+FileName);
 Total:=R.NC*R.NR;
 If Total>MaxCells Then Fail('Error: raster is too large');
 If CenterX Then R.XLL:=R.XLL-R.Cell/2;
 If CenterY Then R.YLL:=R.YLL-R.Cell/2;
 R.Data:=AllocBlock(Total*SizeOf(Real));
 For I:=0 to Total-1do Begin
  If I>0Then Begin
   If Not RTokNext Then Fail('Error: raster data truncated in '+FileName);
  End
   Else
  If Not Pending Then Fail('Error: raster has no data in '+FileName);
  RNum(RTok,V);
  R.Data^[I]:=V;
 End;
 Close(RF);
End;

Procedure WriteRaster(FileName:String;Var R:TRaster);
Var
 F:Text;
 I,J:LongInt;
Begin
 {$I-}
 Assign(F,FileName);
 Rewrite(F);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to create output file '+FileName);
 WriteLn(F,'ncols ',R.NC);
 WriteLn(F,'nrows ',R.NR);
 WriteLn(F,'xllcorner ',NumStr(R.XLL));
 WriteLn(F,'yllcorner ',NumStr(R.YLL));
 WriteLn(F,'cellsize ',NumStr(R.Cell));
 WriteLn(F,'NODATA_value ',NumStr(R.NoData));
 For I:=0 to R.NR-1do Begin
  For J:=0 to R.NC-1do Begin
   If J>0Then Write(F,' ');
   Write(F,NumStr(R.Data^[I*R.NC+J]));
  End;
  WriteLn(F);
 End;
 Close(F);
End;

Function IsNoData(Var R:TRaster;V:Real):Boolean;Begin
 IsNoData:=Abs(V-R.NoData)<=1E-9*MaxR(1,Abs(R.NoData));
End;

{ ------------------------------------------------------------------ }
{ Aide et liste                                                       }
{ ------------------------------------------------------------------ }

Procedure ShowGeneralHelp;Begin
 WriteLn('QGIS Processing Executor (clone) - ',VersionStr);
 WriteLn;
 WriteLn('Usage: QGIS_PROCESS [--help] [--version] [--json] [command] [algorithm id] [parameters]');
 WriteLn;
 WriteLn('Options:');
 WriteLn('  --help, -h, /?   Display this help');
 WriteLn('  --version        Display the version');
 WriteLn('  --json           Output results in JSON format');
 WriteLn;
 WriteLn('Available commands:');
 WriteLn('  plugins          List available (and active) plugins');
 WriteLn('  list             List all available processing algorithms');
 WriteLn('  help             Show help for an algorithm (help ALGORITHM_ID)');
 WriteLn('  run              Run an algorithm (run ALGORITHM_ID --PARAM=VALUE ...)');
 WriteLn;
 WriteLn('Vector layers are GeoJSON files, rasters are ESRI ASCII Grid (.asc) files.');
 WriteLn;
 WriteLn('Example: QGIS_PROCESS run native:calculatedistance --X1=-73.57 --Y1=45.50 --X2=2.35 --Y2=48.85');
 WriteLn('Example: QGIS_PROCESS run native:buffer --INPUT=cities.geojson --DISTANCE=0.5 --OUTPUT=out.geojson');
End;

Procedure ShowList;
Var
 I,P,Cnt:Integer;
 Prefix,Name:String;
Begin
 If JsonMode Then Begin
  WriteLn('{"providers":{');
  For P:=1 to 2do Begin
   If P=1Then Begin Prefix:='native:';Name:='QGIS (native c++)';End
         Else Begin Prefix:='gdal:';Name:='GDAL';End;
   Write('"',Copy(Prefix,1,Length(Prefix)-1),'":{"id":"',Copy(Prefix,1,Length(Prefix)-1),
         '","name":',JsonStr(Name),',"algorithms":{');
   Cnt:=0;
   For I:=1 to MaxAlgo do If Copy(Algos[I].Id,1,Length(Prefix))=Prefix Then Begin
    If Cnt>0Then Write(',');
    WriteLn;
    Write(' ',JsonStr(Algos[I].Id),':{"id":',JsonStr(Algos[I].Id),
          ',"name":',JsonStr(Algos[I].Title),'}');
    Inc(Cnt);
   End;
   WriteLn;
   Write('}}');
   If P=1Then WriteLn(',') Else WriteLn;
  End;
  WriteLn('}}');
 End
  Else
 Begin
  WriteLn('Available algorithms');
  For P:=1 to 2do Begin
   If P=1Then Begin Prefix:='native:';Name:='QGIS (native c++)';End
         Else Begin Prefix:='gdal:';Name:='GDAL';End;
   WriteLn;
   WriteLn(Name);
   For I:=1 to MaxAlgo do If Copy(Algos[I].Id,1,Length(Prefix))=Prefix Then
    WriteLn(#9,Algos[I].Id,#9,Algos[I].Title);
  End;
 End;
End;

Procedure ShowPlugins;Begin
 If JsonMode Then WriteLn('{"plugins":{}}')
  Else
 Begin
  WriteLn('Available plugins');
  WriteLn;
  WriteLn('(none)');
 End;
End;

Procedure ShowAlgoHelp(A:Integer);
Var
 I:Integer;
 First:Boolean;
Begin
 If JsonMode Then Begin
  WriteLn('{"id":',JsonStr(Algos[A].Id),',"name":',JsonStr(Algos[A].Title),
          ',"group":',JsonStr(Algos[A].Group),
          ',"description":',JsonStr(Algos[A].Descr),',"parameters":{');
  First:=True;
  For I:=1 to MaxParam do If Params[I].A=A Then Begin
   If Not First Then Write(',');
   First:=False;
   Write(JsonStr(Params[I].Name),':{"type":',JsonStr(Params[I].Typ),
         ',"description":',JsonStr(Params[I].Desc),
         ',"default":',JsonStr(Params[I].Def),'}');
  End;
  Write('},"outputs":{');
  First:=True;
  For I:=1 to MaxOut do If Outs[I].A=A Then Begin
   If Not First Then Write(',');
   First:=False;
   Write(JsonStr(Outs[I].Name),':{"type":',JsonStr(Outs[I].Typ),
         ',"description":',JsonStr(Outs[I].Desc),'}');
  End;
  WriteLn('}}');
 End
  Else
 Begin
  WriteLn(Algos[A].Title,' (',Algos[A].Id,')');
  WriteLn;
  WriteLn('----------------');
  WriteLn('Description');
  WriteLn('----------------');
  WriteLn(Algos[A].Descr);
  WriteLn;
  WriteLn('----------------');
  WriteLn('Arguments');
  WriteLn('----------------');
  WriteLn;
  For I:=1 to MaxParam do If Params[I].A=A Then Begin
   WriteLn(Params[I].Name,': ',Params[I].Desc);
   WriteLn(#9,'Argument type:',#9,Params[I].Typ);
   If Params[I].Def='*'Then WriteLn(#9,'Optional') Else
   If Params[I].Def<>''Then WriteLn(#9,'Default value:',#9,Params[I].Def)
                       Else WriteLn(#9,'Required');
   WriteLn;
  End;
  WriteLn('----------------');
  WriteLn('Outputs');
  WriteLn('----------------');
  WriteLn;
  For I:=1 to MaxOut do If Outs[I].A=A Then Begin
   WriteLn(Outs[I].Name,': ',Outs[I].Desc);
   WriteLn(#9,'Output type:',#9,Outs[I].Typ);
   WriteLn;
  End;
 End;
End;

{ ------------------------------------------------------------------ }
{ Arguments                                                           }
{ ------------------------------------------------------------------ }

Function FindAlgo(Id:String):Integer;
Var
 I:Integer;
Begin
 FindAlgo:=0;
 Id:=StrUpper(Id);
 For I:=1 to MaxAlgo do If StrUpper(Algos[I].Id)=Id Then Begin
  FindAlgo:=I;
  Exit;
 End;
End;

{ Retourne la valeur d'un argument (Faux s'il est absent) }
Function GetArg(Name:String;Var Value:String):Boolean;
Var
 I:Integer;
Begin
 GetArg:=False;
 Name:=StrUpper(Name);
 For I:=1 to ArgCount do If ArgName[I]=Name Then Begin
  Value:=ArgVal[I];
  GetArg:=True;
  Exit;
 End;
End;

Function ParamDef(A:Integer;Name:String;Var P:ParamRec):Boolean;
Var
 I:Integer;
Begin
 ParamDef:=False;
 For I:=1 to MaxParam do If(Params[I].A=A)and(Params[I].Name=Name)Then Begin
  P:=Params[I];
  ParamDef:=True;
  Exit;
 End;
End;

{ Valide les arguments puis retourne la valeur finale du parametre }
Function NeedStr(A:Integer;Name:String):String;
Var
 V:String;
 P:ParamRec;
Begin
 If Not ParamDef(A,Name,P)Then Fail('Internal error: unknown parameter '+Name);
 If Not GetArg(Name,V)Then Begin
  If P.Def=''Then Fail('Error: missing required parameter '+Name);
  If P.Def='*'Then V:='' Else V:=P.Def;
 End;
 NeedStr:=V;
End;

Function HasArg(Name:String):Boolean;
Var
 V:String;
Begin
 HasArg:=GetArg(Name,V)and(V<>'');
End;

Function NeedReal(A:Integer;Name:String):Real;
Var
 V:String;
 R:Real;
 Err:Integer;
Begin
 V:=NeedStr(A,Name);
 Val(V,R,Err);
 If Err<>0Then Fail('Error: invalid value for parameter '+Name+': '+V);
 NeedReal:=R;
End;

Procedure AddRes(Name,Value:String);Begin
 Inc(ResCount);
 ResName[ResCount]:=Name;
 ResVal[ResCount]:=Value;
End;

{ ------------------------------------------------------------------ }
{ Algorithmes                                                         }
{ ------------------------------------------------------------------ }

Function Haversine(X1,Y1,X2,Y2:Real):Real;
Var
 DLat,DLon,A:Real;
Begin
 DLat:=Deg2Rad(Y2-Y1);
 DLon:=Deg2Rad(X2-X1);
 A:=Sqr(Sin(DLat/2))+Cos(Deg2Rad(Y1))*Cos(Deg2Rad(Y2))*Sqr(Sin(DLon/2));
 Haversine:=EarthRadius*2*Atan2(Sqrt(A),Sqrt(1-A));
End;

Function Bearing(X1,Y1,X2,Y2:Real):Real;
Var
 P1,P2,DL:Real;
Begin
 P1:=Deg2Rad(Y1);
 P2:=Deg2Rad(Y2);
 DL:=Deg2Rad(X2-X1);
 Bearing:=NormDeg(Rad2Deg(Atan2(Sin(DL)*Cos(P2),
                 Cos(P1)*Sin(P2)-Sin(P1)*Cos(P2)*Cos(DL))));
End;

Procedure RunDistance(A:Integer);
Var
 X1,Y1,X2,Y2,D:Real;
Begin
 X1:=NeedReal(A,'X1');Y1:=NeedReal(A,'Y1');
 X2:=NeedReal(A,'X2');Y2:=NeedReal(A,'Y2');
 D:=Haversine(X1,Y1,X2,Y2);
 AddRes('DISTANCE',RealToStr(D));
 AddRes('DISTANCE_KM',RealToStr(D/1000));
End;

Procedure RunBearing(A:Integer);
Var
 X1,Y1,X2,Y2:Real;
Begin
 X1:=NeedReal(A,'X1');Y1:=NeedReal(A,'Y1');
 X2:=NeedReal(A,'X2');Y2:=NeedReal(A,'Y2');
 AddRes('BEARING',RealToStr(Bearing(X1,Y1,X2,Y2)));
 AddRes('FINAL_BEARING',RealToStr(NormDeg(Bearing(X2,Y2,X1,Y1)+180)));
End;

Procedure RunDestination(A:Integer);
Var
 X,Y,B,D,Delta,P1,P2,L2:Real;
Begin
 X:=NeedReal(A,'X');Y:=NeedReal(A,'Y');
 B:=Deg2Rad(NeedReal(A,'BEARING'));
 D:=NeedReal(A,'DISTANCE');
 Delta:=D/EarthRadius;
 P1:=Deg2Rad(Y);
 P2:=ArcSin(Sin(P1)*Cos(Delta)+Cos(P1)*Sin(Delta)*Cos(B));
 L2:=Deg2Rad(X)+Atan2(Sin(B)*Sin(Delta)*Cos(P1),Cos(Delta)-Sin(P1)*Sin(P2));
 L2:=Rad2Deg(L2);
 While L2>180do L2:=L2-360;
 While L2<-180do L2:=L2+360;
 AddRes('X',RealToStr(L2));
 AddRes('Y',RealToStr(Rad2Deg(P2)));
End;

Procedure RunReproject(A:Integer);
Var
 X,Y:Real;
 Src,Dst:Integer;
Begin
 X:=NeedReal(A,'X');Y:=NeedReal(A,'Y');
 Src:=ParseEpsg(NeedStr(A,'SOURCE_CRS'),'SOURCE_CRS');
 Dst:=ParseEpsg(NeedStr(A,'TARGET_CRS'),'TARGET_CRS');
 TransformPt(Src,Dst,X,Y);
 AddRes('X',RealToStr(X));
 AddRes('Y',RealToStr(Y));
End;

{ Parcourt un fichier GeoJSON et calcule l'etendue de ses coordonnees }
Procedure RunExtent(A:Integer);
Var
 FileName:String;
 Root,Arr,F:PJ;
 G:TGeom;
 P:PPath;
 I:LongInt;
 Features,Points:LongInt;
 MinX,MinY,MaxX,MaxY:Real;
 Have:Boolean;
Begin
 FileName:=NeedStr(A,'INPUT');
 Root:=LoadLayer(FileName);
 Arr:=LayerFeatures(Root);
 Features:=0;Points:=0;Have:=False;
 MinX:=0;MinY:=0;MaxX:=0;MaxY:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  Inc(Features);
  Flatten(JFind(F,'geometry'),G);
  P:=G.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-1do Begin
    Inc(Points);
    If Not Have Then Begin
     MinX:=P^.Pts^[I].X;MaxX:=MinX;MinY:=P^.Pts^[I].Y;MaxY:=MinY;Have:=True;
    End
     Else
    Begin
     If P^.Pts^[I].X<MinX Then MinX:=P^.Pts^[I].X;
     If P^.Pts^[I].X>MaxX Then MaxX:=P^.Pts^[I].X;
     If P^.Pts^[I].Y<MinY Then MinY:=P^.Pts^[I].Y;
     If P^.Pts^[I].Y>MaxY Then MaxY:=P^.Pts^[I].Y;
    End;
   End;
   P:=P^.Next;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 If Not Have Then Fail('Error: no coordinates found in '+FileName);
 AddRes('XMIN',RealToStr(MinX));
 AddRes('YMIN',RealToStr(MinY));
 AddRes('XMAX',RealToStr(MaxX));
 AddRes('YMAX',RealToStr(MaxY));
 AddRes('FEATURE_COUNT',IntToStr(Features));
 AddRes('POINT_COUNT',IntToStr(Points));
End;

Procedure RunCenter(A:Integer);
Var
 X1,Y1,X2,Y2:Real;
Begin
 X1:=NeedReal(A,'XMIN');Y1:=NeedReal(A,'YMIN');
 X2:=NeedReal(A,'XMAX');Y2:=NeedReal(A,'YMAX');
 AddRes('CENTER_X',RealToStr((X1+X2)/2));
 AddRes('CENTER_Y',RealToStr((Y1+Y2)/2));
 AddRes('WIDTH',RealToStr(Abs(X2-X1)));
 AddRes('HEIGHT',RealToStr(Abs(Y2-Y1)));
End;

Procedure RunBuffer(A:Integer);
Var
 Root,Arr,F,Node:PJ;
 G,R:TGeom;
 Dist:Real;
 Seg:Integer;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Dist:=NeedReal(A,'DISTANCE');
 Seg:=Round(NeedReal(A,'SEGMENTS'));
 If(Seg<1)or(Seg>64)Then Fail('Error: SEGMENTS must be between 1 and 64');
 Out:=NeedStr(A,'OUTPUT');
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   If(Dist=0)and(G.Cls=3)Then Node:=JFind(F,'geometry')
    Else
   Begin
    BufferGeom(G,Dist,Seg,R);
    Node:=BuildPolygons(R);
    FreeGeom(R);
   End;
   If Node<>JFind(F,'geometry')Then SetGeom(F,Node);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunCentroids(A:Integer);
Var
 Root,Arr,F:PJ;
 G:TGeom;
 Cx,Cy:Real;
 Ok:Boolean;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Out:=NeedStr(A,'OUTPUT');
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   CentroidGeom(G,Cx,Cy,Ok);
   If Ok Then SetGeom(F,GeomNode('Point',CoordNode(Cx,Cy)))
         Else SetGeom(F,Nil);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunConvexHull(A:Integer);
Var
 Root,Arr,F,Node:PJ;
 G,R:TGeom;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Out:=NeedStr(A,'OUTPUT');
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   HullGeom(G,R);
   Case R.Cls of
    1:Node:=BuildPoints(R);
    2:Node:=BuildLines(R);
    3:Node:=BuildPolygons(R);
    Else Node:=Nil;
   End;
   SetGeom(F,Node);
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunPolygonsToLines(A:Integer);
Var
 Root,Arr,F:PJ;
 G,R:TGeom;
 P:PPath;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Out:=NeedStr(A,'OUTPUT');
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   If G.Cls<>3Then Fail('Error: the input layer must contain polygons');
   InitGeom(R);
   R.Cls:=2;
   P:=G.First;
   While P<>Nil do Begin
    CopyPath(R,P,0);
    P:=P^.Next;
   End;
   SetGeom(F,BuildLines(R));
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunReprojectLayer(A:Integer);
Var
 Root,Arr,F,Gn:PJ;
 Src,Dst:Integer;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Dst:=ParseEpsg(NeedStr(A,'TARGET_CRS'),'TARGET_CRS');
 Out:=NeedStr(A,'OUTPUT');
 Src:=LayerCrs(Root);
 Arr:=LayerFeatures(Root);
 If Src<>Dst Then Begin
  F:=Arr^.First;
  While F<>Nil do Begin
   Gn:=JFind(F,'geometry');
   If(Gn<>Nil)and(Gn^.Kind=5)Then TransformCoords(JFind(Gn,'coordinates'),Src,Dst);
   F:=F^.Next;
  End;
 End;
 SetLayerCrs(Root,Dst);
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunExtract(A:Integer);
Var
 Root,Arr,F,Nx,FailArr:PJ;
 Expr,Out,OutFail:String;
 WantFail:Boolean;
 FailRoot:PJ;
 Props:PJ;
 Keep:Boolean;
 C:PJ;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Expr:=NeedStr(A,'EXPRESSION');
 Out:=NeedStr(A,'OUTPUT');
 OutFail:=NeedStr(A,'FAIL_OUTPUT');
 WantFail:=OutFail<>'';
 FailRoot:=Nil;FailArr:=Nil;
 If WantFail Then Begin
  FailRoot:=NewJ(5);
  JAddKV(FailRoot,'type',JText('FeatureCollection'));
  C:=JFind(Root,'crs');
  If C<>Nil Then JAddKV(FailRoot,'crs',JClone(C));
  FailArr:=NewJ(4);
  JAddKV(FailRoot,'features',FailArr);
 End;
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 Arr^.First:=Nil;Arr^.Last:=Nil;
 While F<>Nil do Begin
  Nx:=F^.Next;
  Props:=JFind(F,'properties');
  Keep:=EvalFeature(Expr,Props);
  If Keep Then JAdd(Arr,F)
   Else
  If WantFail Then JAdd(FailArr,F);
  F:=Nx;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
 If WantFail Then Begin
  SaveLayer(OutFail,FailRoot);
  AddRes('FAIL_OUTPUT',OutFail);
 End;
End;

Procedure RunClip(A:Integer);
Var
 Root,Ov,Arr,OvArr,F,Nx:PJ;
 G,R,B,Bf:TGeom;
 Out:String;
 P,Q:PPath;
 MinX,MinY,MaxX,MaxY,Ext,Tol:Real;
 NB,I,N,NPoly,K:LongInt;
 Edges,Boxes:PEdges;
 Keep,Have:Boolean;
 Poly:Integer;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Ov:=LoadLayer(NeedStr(A,'OVERLAY'));
 Out:=NeedStr(A,'OUTPUT');
 { regroupe les polygones de la couche de superposition }
 InitGeom(B);
 B.Cls:=3;
 OvArr:=LayerFeatures(Ov);
 F:=OvArr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   If G.Cls<>3Then Fail('Error: the overlay layer must contain polygons');
   P:=G.First;
   While P<>Nil do Begin
    Q:=P^.Next;
    P^.Poly:=P^.Poly+B.NPoly;
    LinkPath(B,P);
    P:=Q;
   End;
   B.NPoly:=B.NPoly+G.NPoly;
  End;
  F:=F^.Next;
 End;
 If B.First=Nil Then Fail('Error: the overlay layer has no polygon');
 { boite englobante de chaque polygone de superposition }
 NPoly:=B.NPoly;
 Boxes:=AllocBlock(NPoly*SizeOf(TEdge));
 For K:=0 to NPoly-1do Begin Boxes^[K].X1:=1E300;Boxes^[K].Y1:=1E300;Boxes^[K].X2:=-1E300;Boxes^[K].Y2:=-1E300;End;
 P:=B.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-1do Begin
   If P^.Pts^[I].X<Boxes^[P^.Poly].X1 Then Boxes^[P^.Poly].X1:=P^.Pts^[I].X;
   If P^.Pts^[I].X>Boxes^[P^.Poly].X2 Then Boxes^[P^.Poly].X2:=P^.Pts^[I].X;
   If P^.Pts^[I].Y<Boxes^[P^.Poly].Y1 Then Boxes^[P^.Poly].Y1:=P^.Pts^[I].Y;
   If P^.Pts^[I].Y>Boxes^[P^.Poly].Y2 Then Boxes^[P^.Poly].Y2:=P^.Pts^[I].Y;
  End;
  P:=P^.Next;
 End;
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 Arr^.First:=Nil;Arr^.Last:=Nil;
 While F<>Nil do Begin
  Nx:=F^.Next;
  Flatten(JFind(F,'geometry'),G);
  Keep:=False;
  If G.Cls<>0Then Begin
   { boite de l'entite }
   Have:=False;
   MinX:=0;MinY:=0;MaxX:=0;MaxY:=0;
   P:=G.First;
   While P<>Nil do Begin
    For I:=0 to P^.N-1do Begin
     If Not Have Then Begin
      MinX:=P^.Pts^[I].X;MaxX:=MinX;MinY:=P^.Pts^[I].Y;MaxY:=MinY;Have:=True;
     End
      Else
     Begin
      If P^.Pts^[I].X<MinX Then MinX:=P^.Pts^[I].X;
      If P^.Pts^[I].X>MaxX Then MaxX:=P^.Pts^[I].X;
      If P^.Pts^[I].Y<MinY Then MinY:=P^.Pts^[I].Y;
      If P^.Pts^[I].Y>MaxY Then MaxY:=P^.Pts^[I].Y;
     End;
    End;
    P:=P^.Next;
   End;
   { polygones de superposition susceptibles de toucher l'entite }
   InitGeom(Bf);
   Bf.Cls:=3;
   P:=B.First;
   While P<>Nil do Begin
    Poly:=P^.Poly;
    If(Boxes^[Poly].X1<=MaxX)and(Boxes^[Poly].X2>=MinX)and
      (Boxes^[Poly].Y1<=MaxY)and(Boxes^[Poly].Y2>=MinY)Then Begin
     CopyPath(Bf,P,Poly);
    End;
    P:=P^.Next;
   End;
   If Bf.First<>Nil Then Begin
    Q:=Bf.First;
    While Q<>Nil do Begin
     For I:=0 to Q^.N-1do Begin
      If Q^.Pts^[I].X<MinX Then MinX:=Q^.Pts^[I].X;
      If Q^.Pts^[I].X>MaxX Then MaxX:=Q^.Pts^[I].X;
      If Q^.Pts^[I].Y<MinY Then MinY:=Q^.Pts^[I].Y;
      If Q^.Pts^[I].Y>MaxY Then MaxY:=Q^.Pts^[I].Y;
     End;
     Q:=Q^.Next;
    End;
    Ext:=MaxR(MaxX-MinX,MaxY-MinY);
    If Ext<=0Then Ext:=1;
    SnapQ:=Ext*1E-9;
    Tol:=SnapQ*4;
    Case G.Cls of
     3:Begin
      Overlay(1,G,Bf,R);
      If R.First<>Nil Then Begin
       SetGeom(F,BuildPolygons(R));
       Keep:=True;
      End;
      FreeGeom(R);
     End;
     2,1:Begin
      NB:=EdgeCount(Bf);
      Edges:=AllocBlock(NB*SizeOf(TEdge));
      N:=0;
      FillEdges(Bf,Edges,N);
      If G.Cls=2Then Begin
       ClipLines(G,Edges,N,Tol,R);
       If R.First<>Nil Then Begin
        SetGeom(F,BuildLines(R));
        Keep:=True;
       End;
       FreeGeom(R);
      End
       Else
      Begin
       InitGeom(R);
       R.Cls:=1;
       P:=G.First;
       While P<>Nil do Begin
        If InsideOrOn(Edges,N,P^.Pts^[0].X,P^.Pts^[0].Y,Tol)Then CopyPath(R,P,0);
        P:=P^.Next;
       End;
       If R.First<>Nil Then Begin
        SetGeom(F,BuildPoints(R));
        Keep:=True;
       End;
       FreeGeom(R);
      End;
      FreeMem(Edges,NB*SizeOf(TEdge));
     End;
    End;
   End;
   FreeGeom(Bf);
  End;
  If Keep Then JAdd(Arr,F);
  FreeGeom(G);
  F:=Nx;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunPixelsToPoints(A:Integer);
Var
 R:TRaster;
 F:Text;
 Out,Fld:String;
 I,J:LongInt;
 First:Boolean;
 V:Real;
Begin
 ReadRaster(NeedStr(A,'INPUT_RASTER'),R);
 If Round(NeedReal(A,'RASTER_BAND'))<>1Then Fail('Error: only band 1 is available');
 Fld:=NeedStr(A,'FIELD_NAME');
 Out:=NeedStr(A,'OUTPUT');
 {$I-}
 Assign(F,Out);
 Rewrite(F);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to create output file '+Out);
 WriteLn(F,'{"type":"FeatureCollection","features":[');
 First:=True;
 For I:=0 to R.NR-1do Begin
  For J:=0 to R.NC-1do Begin
   V:=R.Data^[I*R.NC+J];
   If Not IsNoData(R,V)Then Begin
    If Not First Then WriteLn(F,',');
    First:=False;
    Write(F,'{"type":"Feature","properties":{',JsonStr(Fld),':',NumStr(V),
          '},"geometry":{"type":"Point","coordinates":[',
          NumStr(R.XLL+(J+0.5)*R.Cell),',',NumStr(R.YLL+(R.NR-I-0.5)*R.Cell),']}}');
   End;
  End;
 End;
 WriteLn(F);
 WriteLn(F,']}');
 Close(F);
 AddRes('OUTPUT',Out);
End;

Procedure ParseExtent(S:String;Var X1,X2,Y1,Y2:Real);
Var
 P,K:Integer;
 V:Array[1..4]of Real;
 T:String;
Begin
 P:=Pos('[',S);
 If P>0Then S:=Copy(S,1,P-1);
 For K:=1 to 4do Begin
  P:=Pos(',',S);
  If(K<4)and(P=0)Then Fail('Error: EXTENT must be xmin,xmax,ymin,ymax');
  If K<4Then Begin T:=Copy(S,1,P-1);S:=Copy(S,P+1,255);End
        Else T:=S;
  While(T<>'')and(T[1]=' ')do T:=Copy(T,2,255);
  While(T<>'')and(T[Length(T)]=' ')do T:=Copy(T,1,Length(T)-1);
  If Not IsNumber(T)Then Fail('Error: invalid EXTENT value "'+T+'"');
  Val(T,V[K],P);
 End;
 X1:=V[1];X2:=V[2];Y1:=V[3];Y2:=V[4];
 If(X2<=X1)or(Y2<=Y1)Then Fail('Error: invalid EXTENT (max must be greater than min)');
End;

Procedure RunClipRaster(A:Integer);
Var
 R,O:TRaster;
 X1,X2,Y1,Y2,YTop,NewNd:Real;
 C0,C1,R0,R1,I,J:LongInt;
 Out:String;
 SetNd:Boolean;
 V:Real;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 ParseExtent(NeedStr(A,'EXTENT'),X1,X2,Y1,Y2);
 Out:=NeedStr(A,'OUTPUT');
 SetNd:=HasArg('NODATA');
 NewNd:=R.NoData;
 If SetNd Then NewNd:=NeedReal(A,'NODATA');
 YTop:=R.YLL+R.NR*R.Cell;
 C0:=RoundL((X1-R.XLL)/R.Cell);
 C1:=RoundL((X2-R.XLL)/R.Cell);
 R0:=RoundL((YTop-Y2)/R.Cell);
 R1:=RoundL((YTop-Y1)/R.Cell);
 If C0<0Then C0:=0;
 If R0<0Then R0:=0;
 If C1>R.NC Then C1:=R.NC;
 If R1>R.NR Then R1:=R.NR;
 If(C1<=C0)or(R1<=R0)Then Fail('Error: the extent does not intersect the raster');
 O.NC:=C1-C0;O.NR:=R1-R0;
 O.XLL:=R.XLL+C0*R.Cell;
 O.YLL:=YTop-R1*R.Cell;
 O.Cell:=R.Cell;
 O.NoData:=NewNd;
 O.Data:=AllocBlock(O.NC*O.NR*SizeOf(Real));
 For I:=0 to O.NR-1do
  For J:=0 to O.NC-1do Begin
   V:=R.Data^[(I+R0)*R.NC+J+C0];
   If IsNoData(R,V)Then V:=NewNd;
   O.Data^[I*O.NC+J]:=V;
  End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

Procedure RunWarp(A:Integer);
Var
 R,O:TRaster;
 Src,Dst,Resamp:Integer;
 Out:String;
 NewNd,MinX,MinY,MaxX,MaxY,X,Y,Res,W,H,YTop,Col,Row,Fx,Fy,Wx,Wy,Wt,Sum,V:Real;
 K,I,J,Q,Cc,Rr,Cx,Cy:LongInt;
 Ok:Boolean;
 Have:Boolean;

 Procedure Upd(Px,Py:Real);Begin
  Ok:=TryTransform(Src,Dst,Px,Py);
  If Ok Then Begin
   If Not Have Then Begin MinX:=Px;MaxX:=Px;MinY:=Py;MaxY:=Py;Have:=True;End
    Else
   Begin
    If Px<MinX Then MinX:=Px;
    If Px>MaxX Then MaxX:=Px;
    If Py<MinY Then MinY:=Py;
    If Py>MaxY Then MaxY:=Py;
   End;
  End;
 End;


Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 Src:=ParseEpsg(NeedStr(A,'SOURCE_CRS'),'SOURCE_CRS');
 Dst:=ParseEpsg(NeedStr(A,'TARGET_CRS'),'TARGET_CRS');
 Resamp:=Round(NeedReal(A,'RESAMPLING'));
 If(Resamp<>0)and(Resamp<>1)Then Fail('Error: RESAMPLING must be 0 (nearest) or 1 (bilinear)');
 Out:=NeedStr(A,'OUTPUT');
 NewNd:=R.NoData;
 If HasArg('NODATA')Then NewNd:=NeedReal(A,'NODATA');
 YTop:=R.YLL+R.NR*R.Cell;
 { etendue de sortie : transformation du contour du raster source }
 Have:=False;
 MinX:=0;MaxX:=0;MinY:=0;MaxY:=0;
 For K:=0 to 40do Begin
  X:=R.XLL+(R.NC*R.Cell)*K/40;
  Upd(X,R.YLL);
  Upd(X,YTop);
  Y:=R.YLL+(R.NR*R.Cell)*K/40;
  Upd(R.XLL,Y);
  Upd(R.XLL+R.NC*R.Cell,Y);
 End;
 If Not Have Then Fail('Error: the raster cannot be reprojected');
 W:=MaxX-MinX;H:=MaxY-MinY;
 If HasArg('TARGET_RESOLUTION')Then Res:=NeedReal(A,'TARGET_RESOLUTION')
  Else
 If Src=Dst Then Res:=R.Cell
  Else
 Res:=Sqrt(W*W+H*H)/Sqrt(Sqr(R.NC*1.0)+Sqr(R.NR*1.0));
 If Res<=0Then Fail('Error: invalid target resolution');
 O.NC:=RoundL(W/Res);
 O.NR:=RoundL(H/Res);
 If O.NC<1Then O.NC:=1;
 If O.NR<1Then O.NR:=1;
 If O.NC*O.NR>MaxCells Then Fail('Error: output raster is too large');
 O.XLL:=MinX;
 O.Cell:=Res;
 O.YLL:=MaxY-O.NR*Res;
 O.NoData:=NewNd;
 O.Data:=AllocBlock(O.NC*O.NR*SizeOf(Real));
 For I:=0 to O.NR-1do Begin
  For J:=0 to O.NC-1do Begin
   X:=O.XLL+(J+0.5)*Res;
   Y:=MaxY-(I+0.5)*Res;
   V:=NewNd;
   If TryTransform(Dst,Src,X,Y)Then Begin
    Col:=(X-R.XLL)/R.Cell;
    Row:=(YTop-Y)/R.Cell;
    If(Col>=0)and(Col<R.NC)and(Row>=0)and(Row<R.NR)Then Begin
     If Resamp=0Then Begin
      V:=R.Data^[FloorL(Row)*R.NC+FloorL(Col)];
      If IsNoData(R,V)Then V:=NewNd;
     End
      Else
     Begin
      Fx:=Col-0.5;Fy:=Row-0.5;
      Cc:=FloorL(Fx);Rr:=FloorL(Fy);
      Wx:=Fx-Cc;Wy:=Fy-Rr;
      Sum:=0;Wt:=0;
      For Q:=0 to 3do Begin
       If Q and 1=0Then Fx:=1-Wx Else Fx:=Wx;
       If Q and 2=0Then Fy:=1-Wy Else Fy:=Wy;
       Cx:=Cc+(Q and 1);
       Cy:=Rr+(Q shr 1);
       If(Cx>=0)and(Cx<R.NC)and(Cy>=0)and(Cy<R.NR)Then Begin
        V:=R.Data^[Cy*R.NC+Cx];
        If Not IsNoData(R,V)Then Begin
         Sum:=Sum+V*Fx*Fy;
         Wt:=Wt+Fx*Fy;
        End;
       End;
      End;
      If Wt>0Then V:=Sum/Wt Else V:=NewNd;
     End;
    End;
   End;
   O.Data^[I*O.NC+J]:=V;
  End;
 End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

Procedure RunAlgo(A:Integer);
Var
 I,J:Integer;
 P:ParamRec;
Begin
 { Verifie qu'aucun parametre inconnu n'a ete passe }
 For I:=1 to ArgCount do
  If Not ParamDef(A,ArgName[I],P)Then
   If Not((ArgName[I]='DISTANCE_UNITS')or(ArgName[I]='AREA_UNITS')or
          (ArgName[I]='ELLIPSOID')or(ArgName[I]='PROJECT_PATH'))Then
    Fail('Error: unknown parameter '+ArgName[I]);
 ResCount:=0;
 Case A of
  1:RunDistance(A);
  2:RunBearing(A);
  3:RunDestination(A);
  4:RunReproject(A);
  5:RunExtent(A);
  6:RunCenter(A);
  7:RunBuffer(A);
  8:RunCentroids(A);
  9:RunClip(A);
  10:RunConvexHull(A);
  11:RunExtract(A);
  12:RunReprojectLayer(A);
  13:RunPolygonsToLines(A);
  14:RunPixelsToPoints(A);
  15:RunClipRaster(A);
  16:RunWarp(A);
 End;
 If JsonMode Then Begin
  WriteLn('{"algorithm_details":{"id":',JsonStr(Algos[A].Id),
          ',"name":',JsonStr(Algos[A].Title),'},"inputs":{');
  For I:=1 to ArgCount do Begin
   Write(' ',JsonStr(ArgName[I]),':',JsonVal(ArgVal[I]));
   If I<ArgCount Then WriteLn(',') Else WriteLn;
  End;
  WriteLn('},"results":{');
  For J:=1 to ResCount do Begin
   Write(' ',JsonStr(ResName[J]),':',JsonVal(ResVal[J]));
   If J<ResCount Then WriteLn(',') Else WriteLn;
  End;
  WriteLn('}}');
 End
  Else
 Begin
  WriteLn('QGIS Processing Executor (clone) - ',VersionStr);
  WriteLn('Running ',Algos[A].Id,' [',Algos[A].Title,']');
  WriteLn;
  WriteLn('----------------');
  WriteLn('Inputs');
  WriteLn('----------------');
  WriteLn;
  For I:=1 to ArgCount do WriteLn(ArgName[I],':',#9,ArgVal[I]);
  WriteLn;
  WriteLn('----------------');
  WriteLn('Results');
  WriteLn('----------------');
  WriteLn;
  For J:=1 to ResCount do WriteLn(ResName[J],':',#9,ResVal[J]);
 End;
End;

{ Analyse la ligne de commande : options, commande, algorithme et parametres }
Procedure ParseArgs;
Var
 I,P:Integer;
 S,Name:String;
 N:Integer;
Begin
 JsonMode:=False;
 Cmd:='';AlgoId:='';
 ArgCount:=0;
 N:=0;
 For I:=1 to ParamCount do Begin
  S:=ParamStr(I);
  If StrUpper(S)='--JSON'Then JsonMode:=True Else
  If(StrUpper(S)='--NO-PYTHON')or(StrUpper(S)='--VERBOSE')Then Begin End Else
  If(S='/?')or(S='-h')or(S='/h')or(S='/H')or(StrUpper(S)='--HELP')Then Begin
   If Cmd=''Then Cmd:='--help';
  End
   Else
  If StrUpper(S)='--VERSION'Then Begin
   If Cmd=''Then Cmd:='--version';
  End
   Else
  Begin
   P:=Pos('=',S);
   If(P>0)and(N>0)Then Begin
    Name:=Copy(S,1,P-1);
    While(Name<>'')and(Name[1]in['-','/'])do Name:=Copy(Name,2,255);
    Inc(ArgCount);
    If ArgCount>MaxArg Then Fail('Error: too many parameters');
    ArgName[ArgCount]:=StrUpper(Name);
    ArgVal[ArgCount]:=Copy(S,P+1,255);
   End
    Else
   Begin
    Inc(N);
    If N=1Then Cmd:=S Else
    If N=2Then AlgoId:=S
          Else Fail('Error: unexpected argument '+S);
   End;
  End;
 End;
End;

Var
 A:Integer;
BEGIN
 ParseArgs;
 If(Cmd='')or(Cmd='--help')Then ShowGeneralHelp Else
 If Cmd='--version'Then Begin
  If JsonMode Then WriteLn('{"version":"',VersionStr,'"}')
              Else WriteLn('QGIS_PROCESS clone ',VersionStr);
 End
  Else
 If StrUpper(Cmd)='LIST'Then ShowList Else
 If StrUpper(Cmd)='PLUGINS'Then ShowPlugins Else
 If(StrUpper(Cmd)='HELP')or(StrUpper(Cmd)='RUN')Then Begin
  If AlgoId=''Then Fail('Error: missing algorithm id');
  A:=FindAlgo(AlgoId);
  If A=0Then Fail('Error: algorithm "'+AlgoId+'" not found');
  If StrUpper(Cmd)='HELP'Then ShowAlgoHelp(A)
                         Else RunAlgo(A);
 End
  Else
 Fail('Error: unknown command "'+Cmd+'"');
END.
