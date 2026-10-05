{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
  @description: Clone minimaliste de la commande qgis_process de QGIS
}

Program QGIS_PROCESS;

Const
 VersionStr='1.0';
 EarthRadius=6371008.8;   { Rayon moyen de la Terre (spherique), en metres }
 MercatorRadius=6378137.0;{ Rayon utilise par EPSG:3857 }
 MaxAlgo=6;
 MaxParam=21;
 MaxOut=18;
 MaxArg=30;

Type
 AlgoRec=Record
  Id:String[24];
  Title:String[40];
  Group:String[24];
  Descr:String[70];
 End;
 ParamRec=Record
  A:Byte;
  Name:String[12];
  Typ:String[8];
  Desc:String[50];
  Def:String[10];
 End;
 OutRec=Record
  A:Byte;
  Name:String[14];
  Typ:String[8];
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
   Descr:'Computes the center and size of a bounding box.')
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
  (A:5;Name:'INPUT';Typ:'file';Desc:'Input GeoJSON file';Def:''),
  (A:6;Name:'XMIN';Typ:'number';Desc:'Minimum X';Def:''),
  (A:6;Name:'YMIN';Typ:'number';Desc:'Minimum Y';Def:''),
  (A:6;Name:'XMAX';Typ:'number';Desc:'Maximum X';Def:''),
  (A:6;Name:'YMAX';Typ:'number';Desc:'Maximum Y';Def:'')
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
  (A:6;Name:'HEIGHT';Typ:'number';Desc:'Height of the extent')
 );

Var
 JsonMode:Boolean;
 Cmd,AlgoId:String;
 ArgName,ArgVal:Array[1..MaxArg]of String;
 ArgCount:Integer;
 ResName,ResVal:Array[1..MaxArg]of String;
 ResCount:Integer;

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

Function IntToStr(L:LongInt):String;
Var
 S:String;
Begin
 Str(L,S);
 IntToStr:=S;
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
 WriteLn('Example: QGIS_PROCESS run native:calculatedistance --X1=-73.57 --Y1=45.50 --X2=2.35 --Y2=48.85');
End;

Procedure ShowList;
Var
 I:Integer;
Begin
 If JsonMode Then Begin
  WriteLn('{"providers":{"native":{"id":"native","name":"QGIS (native)","algorithms":{');
  For I:=1 to MaxAlgo do Begin
   Write(' ',JsonStr(Algos[I].Id),':{"id":',JsonStr(Algos[I].Id),
         ',"name":',JsonStr(Algos[I].Title),'}');
   If I<MaxAlgo Then WriteLn(',') Else WriteLn;
  End;
  WriteLn('}}}}');
 End
  Else
 Begin
  WriteLn('Available algorithms');
  WriteLn;
  WriteLn('QGIS (native)');
  For I:=1 to MaxAlgo do WriteLn(#9,Algos[I].Id,#9,Algos[I].Title);
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
  If P.Def='' Then Fail('Error: missing required parameter '+Name);
  V:=P.Def;
 End;
 NeedStr:=V;
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
 Src,Dst:String;
Begin
 X:=NeedReal(A,'X');Y:=NeedReal(A,'Y');
 Src:=StrUpper(NeedStr(A,'SOURCE_CRS'));
 Dst:=StrUpper(NeedStr(A,'TARGET_CRS'));
 If(Src<>'EPSG:4326')and(Src<>'EPSG:3857')Then Fail('Error: unsupported SOURCE_CRS '+Src);
 If(Dst<>'EPSG:4326')and(Dst<>'EPSG:3857')Then Fail('Error: unsupported TARGET_CRS '+Dst);
 If Src<>Dst Then Begin
  If Src='EPSG:4326'Then Begin
   If Abs(Y)>=90Then Fail('Error: latitude out of range for EPSG:3857');
   Y:=MercatorRadius*Ln(Sin(Pi/4+Deg2Rad(Y)/2)/Cos(Pi/4+Deg2Rad(Y)/2));
   X:=MercatorRadius*Deg2Rad(X);
  End
   Else
  Begin
   X:=Rad2Deg(X/MercatorRadius);
   Y:=Rad2Deg(2*ArcTan(Exp(Y/MercatorRadius))-Pi/2);
  End;
 End;
 AddRes('X',RealToStr(X));
 AddRes('Y',RealToStr(Y));
End;

{ Parcourt un fichier GeoJSON et calcule l'etendue de ses coordonnees }
Procedure RunExtent(A:Integer);
Var
 FileName,Win,Tok:String;
 F:Text;
 C:Char;
 InCoords:Boolean;
 Depth,Idx,Features,Points:Integer;
 MinX,MinY,MaxX,MaxY,X,Y:Real;
 Have:Boolean;

 Procedure Flush;
 Var
  R:Real;
  Err:Integer;
 Begin
  If Tok<>''Then Begin
   Val(Tok,R,Err);
   If Err=0Then Begin
    Inc(Idx);
    If Idx=1Then X:=R Else
    If Idx=2Then Begin
     Y:=R;
     Inc(Points);
     If Not Have Then Begin
      MinX:=X;MaxX:=X;MinY:=Y;MaxY:=Y;Have:=True;
     End
      Else
     Begin
      If X<MinX Then MinX:=X;
      If X>MaxX Then MaxX:=X;
      If Y<MinY Then MinY:=Y;
      If Y>MaxY Then MaxY:=Y;
     End;
    End;
   End;
   Tok:='';
  End;
 End;

Begin
 FileName:=NeedStr(A,'INPUT');
 {$I-}
 Assign(F,FileName);
 Reset(F);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to open input file '+FileName);
 Win:='';Tok:='';
 InCoords:=False;Have:=False;
 Depth:=0;Idx:=0;Features:=0;Points:=0;
 X:=0;Y:=0;
 While Not EOF(F)do Begin
  Read(F,C);
  If InCoords Then Begin
   Case C of
    '0'..'9','-','+','.','e','E':Tok:=Tok+C;
    '[':Begin Flush;Inc(Depth);Idx:=0;End;
    ']':Begin
     Flush;
     Dec(Depth);
     If Depth<=0Then Begin InCoords:=False;Win:='';End;
    End;
    Else Flush;
   End;
  End
   Else
  Begin
   If Length(Win)>=13Then Win:=Copy(Win,2,255);
   Win:=Win+C;
   If Copy(Win,Length(Win)-8,9)='"Feature"'Then Inc(Features);
   If Win='"coordinates"'Then Begin
    InCoords:=True;Depth:=0;Idx:=0;Tok:='';
   End;
  End;
 End;
 Close(F);
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
