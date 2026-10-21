{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application QGIS

  Interface graphique (VGA 640x480) avec menus deroulants, barre d'outils,
  panneau des couches, canevas cartographique, table d'attributs, outils
  d'identification, de selection et de mesure.

  Formats lus : GeoJSON, Shapefile (.shp/.dbf/.prj), CSV (colonnes X/Y, lon/lat,
  degres-minutes ou colonne WKT), grilles ESRI ASCII (.asc) et projets .qgs.
  Formats ecrits : GeoJSON, projet .qgs, DXF, PNG et BMP (carte).
  Systemes de coordonnees affiches : EPSG:4326 et EPSG:3857 (les autres
  systemes sont affiches tels quels, sans reprojection).

  Les algorithmes de traitement (Vecteur, Raster, Traitement) sont executes par
  QGIS_PROCESS (QGIS_PROCESS.EXE doit etre dans le meme repertoire, le repertoire
  courant ou le PATH).

  Syntaxe : QGIS [options] [fichiers]

  Options : --help, --version, --nologo, --noversioncheck, --noplugins,
            --nocustomization, --optionspath, --configpath, --profiles-path,
            --profile, --project, --snapshot, --code, --python, --dxf-export,
            --dxf-extent (et --width, --height, --extent, --dxf-scale-denom,
            --dxf-encoding, --dxf-symbology-mode, --dxf-preset).
  Les options --snapshot et --dxf-export travaillent sans interface graphique.
  Les options --code et --python utilisent l'interpreteur Python du systeme
  (python3, python ou py) : il n'y a pas d'interpreteur integre.

  Note : developpe et teste avec Free Pascal. La syntaxe reste compatible avec
  Turbo Pascal 7, mais la taille du programme n'a pas ete verifiee sous
  Turbo Pascal (limites de 64 Ko de code et de donnees).
}

Program QGIS;

{$IFDEF FPC}
 {$MODE TP}
 {$Q-}
 {$R-}
 {$OVERFLOWCHECKS OFF}
{$ELSE}
 {$N+,E+}
 {$M 16384,0,400000}
{$ENDIF}

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse,Dos
     {$ELSE}
      Crt,Graph,Dos
     {$ENDIF};

Const
 VersionStr='1.00';
 QgisCompat='3.34';
 AppTitle='QGIS - Clone Pascal';

 { Dimensions de l'interface }
 MenuH=20;
 ToolH=28;
 StatH=30;
 PanelW=160;
 RowH=14;

 { Limites : plus petites avec Turbo Pascal (blocs de 64 Ko) }
{$IFDEF FPC}
 MaxPtsF=1000000;
 MaxPartsF=100000;
 MaxFeat=400000;
 MaxOff=64000000;
 MaxRaster=4000000;
 MaxLines=4000;
{$ELSE}
 MaxPtsF=3999;
 MaxPartsF=15999;
 MaxFeat=8000;
 MaxOff=65000;
 MaxRaster=15000;
 MaxLines=1000;
{$ENDIF}
 MaxFields=32;
 MaxLayers=16;
 MaxAlgos=260;
 MaxParams=40;
 MaxCross=511;
 MaxHist=8;

 { Types de couche }
 lkVector=1;
 lkRaster=2;

 { Types de geometrie }
 gkNone=0;
 gkPoint=1;
 gkLine=2;
 gkPoly=3;

 { Systemes de coordonnees }
 crsOther=0;
 crs4326=1;
 crs3857=2;

 { Outils }
 tlPan=0;
 tlZoomIn=1;
 tlZoomOut=2;
 tlIdentify=3;
 tlSelect=4;
 tlMeasure=5;

 { Evenements }
 evNone=0;
 evKey=1;
 evDown=2;
 evUp=3;
 evMove=4;

 { Commandes }
 cmNone=0;
 cmNew=1; cmOpen=2; cmSave=3; cmSaveAs=4; cmRecent=5; cmExportImage=6;
 cmExportDXF=7; cmProjProps=8; cmQuit=9;
 cmSelAll=10; cmDeselect=11; cmSelInvert=12; cmSelExpr=13; cmCopyExtent=14;
 cmToolPan=20; cmToolZoomIn=21; cmToolZoomOut=22; cmToolIdentify=23;
 cmToolSelect=24; cmToolMeasure=25; cmZoomAll=26; cmZoomLayer=27;
 cmZoomSel=28; cmZoomPrev=29; cmZoomNext=30; cmAttrTable=31; cmLabels=32;
 cmRefresh=33; cmPanel=34; cmGrid=35;
 cmAddVector=40; cmAddCSV=41; cmAddRaster=42; cmRemoveLayer=43; cmLayerUp=44;
 cmLayerDown=45; cmLayerColor=46; cmLayerProps=47; cmSaveLayer=48;
 cmLayerFill=49; cmLayerVis=50;
 cmCrs4326=60; cmCrs3857=61; cmCrsLayer=62; cmOptions=63; cmProfileInfo=64;
 cmCmdLine=65; cmBackground=66;
 cmPlugins=70; cmPython=71;
 cmVecBuffer=80; cmVecCentroids=81; cmVecHull=82; cmVecSimplify=83;
 cmVecReproject=84; cmVecClip=85; cmVecDissolve=86; cmVecBBox=87;
 cmVecPolyLines=88; cmVecExtent=89;
 cmRasSlope=100; cmRasAspect=101; cmRasHillshade=102; cmRasContour=103;
 cmRasFill=104; cmRasCalc=105; cmRasPolygonize=106;
 cmToolbox=110; cmProcHistory=111; cmProcLast=112; cmProcLog=113;
 cmHelp=120; cmAbout=121; cmUpdate=122;

Type
 TPt=Record
  X,Y:Double;
 End;
 PPtArr=^TPtArr;
 TPtArr=Array[0..MaxPtsF]of TPt;
 PLongArr=^TLongArr;
 TLongArr=Array[0..MaxPartsF]of LongInt;
 PByteArr=^TByteArr;
 TByteArr=Array[0..MaxPartsF]of Byte;
 PStr=^String;
 PStrArr=^TStrArr;
 TStrArr=Array[0..MaxFields]of PStr;
 PFeature=^TFeature;
 TFeature=Record
  Kind:Byte;
  Sel:Boolean;
  NPts,NParts:LongInt;
  Pts:PPtArr;
  Ends:PLongArr;
  Outer:PByteArr;
  NA:Integer;
  Attr:PStrArr;
  MinX,MinY,MaxX,MaxY:Double;
 End;
 PFeatArr=^TFeatArr;
 TFeatArr=Array[1..MaxFeat]of PFeature;
 PSingleArr=^TSingleArr;
 TSingleArr=Array[0..MaxRaster]of Single;
 POffBuf=^TOffBuf;
 TOffBuf=Array[0..MaxOff]of Byte;

 TLayer=Record
  Used,Visible,Fill:Boolean;
  Kind:Byte;
  GType:Byte;
  Name:String[40];
  Source:String;
  CRS:String[24];
  CrsId:Byte;
  Color:Byte;
  NF,Cap:LongInt;
  Feats:PFeatArr;
  NFld:Integer;
  Fld:Array[1..MaxFields]of String[24];
  LblFld:Integer;
  HasExt:Boolean;
  MinX,MinY,MaxX,MaxY:Double;
  RW,RH:LongInt;
  RX0,RY0,RCell,RMin,RMax,RNoData:Double;
  RData:PSingleArr;
 End;

 TEvent=Record
  What:Byte;
  X,Y:LongInt;
  Key:Char;
  Ext:Boolean;
  Btn:Byte;
  Dbl:Boolean;
 End;

 TMenuItem=Record
  Caption:String[34];
  Short:String[12];
  Cmd:Integer;
 End;
 TMenu=Record
  Title:String[12];
  Hot:Byte;
  AltKey:Byte;
  X,W,DX:Integer;
  N:Integer;
  Hidden:Boolean;
  Items:Array[0..22]of TMenuItem;
 End;

 PLineList=^TLineList;
 TLineList=Array[1..MaxLines]of PStr;

 TParam=Record
  Name:String[30];
  Typ:String[20];
  Desc:String[120];
  Req:Boolean;
  Def:String[40];
  Value:String;
 End;

 TRectSave=Record
  W,H:LongInt;
  Rows:Array[0..599]of Pointer;
 End;

Var
 { Options de ligne de commande }
 OptNoLogo,OptNoVerCheck,OptNoPlugins,OptNoCustom:Boolean;
 OptOptionsPath,OptConfigPath,OptProfilesPath,OptProfile:String;
 OptProject,OptSnapshot,OptCode,OptPython,OptDxfExport,OptDxfExtent:String;
 OptExtent,OptDxfEncoding,OptDxfPreset,OptDxfSymb,OptDxfScale:String;
 OptWidth,OptHeight:LongInt;
 OptFiles:Array[1..16]of String;
 OptNFiles:Integer;

 { Profil et reglages }
 ProfileDir,SettingsFile,TmpDir,ProcDir:String;
 LastDir:String;
 Recent:Array[1..5]of String;
 NRecent:Integer;
 Background:Byte;

 { Projet }
 Lay:Array[1..MaxLayers]of TLayer;
 NLay,ActiveLay:Integer;
 ProjCrsId:Byte;
 ProjCRS:String[24];
 ProjFile,ProjTitle:String;
 Dirty:Boolean;

 { Vue }
 CX,CY,UPP:Double;
 ClipL,ClipT,ClipR,ClipB:LongInt;
 Hist:Array[1..MaxHist]of Record X,Y,U:Double; End;
 HistN,HistPos:Integer;
 ShowPanel,ShowLabels,ShowGrid:Boolean;
 Tool:Byte;

 { Surface de rendu }
 OffScr:Boolean;
 OffBuf:POffBuf;
 OffW,OffH:LongInt;
 ScrW,ScrH:LongInt;
 GraphOn:Boolean;

 { Souris et clavier }
 MouseOk:Boolean;
 MouseHid:Integer;
 PrevMX,PrevMY,PrevMB:LongInt;
 Tick,LastDownTick,LastDownX,LastDownY:LongInt;

 { Interface }
 Menus:Array[0..9]of TMenu;
 NMenus:Integer;
 MenuOpen,MenuSel:Integer;
 MenuSave:TRectSave;
 MenuSaveOk:Boolean;
 StatusMsg:String;
 Running:Boolean;
 MeasPts:Array[1..64]of TPt;
 MeasN:Integer;
 LastMapX,LastMapY:Double;
 ToolHot:Integer;

 { Traitement }
 QPath:String;
 NAlgo:Integer;
 AlgoId:Array[1..MaxAlgos]of String[44];
 AlgoTitle:Array[1..MaxAlgos]of String[43];
 LastAlgo:String;
 LastLog:String;
 RunCount:LongInt;

 { Tampons de lecture des fichiers }
 TmpPts:PPtArr;
 TmpEnds:PLongArr;
 TmpGrp:PLongArr;
 TmpN,TmpParts:LongInt;
 XCross:Array[0..MaxCross]of Double;

{ ------------------------------------------------------------------ }
{ Utilitaires                                                         }
{ ------------------------------------------------------------------ }

Function StrUp(Const S:String):String;
Var
 I:Integer;
 R:String;
Begin
 R:=S;
 For I:=1 to Length(R)do R[I]:=UpCase(R[I]);
 StrUp:=R;
End;

Function StrLow(Const S:String):String;
Var
 I:Integer;
 R:String;
Begin
 R:=S;
 For I:=1 to Length(R)do If R[I] in['A'..'Z']Then R[I]:=Chr(Ord(R[I])+32);
 StrLow:=R;
End;

Function Trim(Const S:String):String;
Var
 A,B:Integer;
Begin
 A:=1;
 B:=Length(S);
 While(A<=B)and(S[A]<=' ')do Inc(A);
 While(B>=A)and(S[B]<=' ')do Dec(B);
 Trim:=Copy(S,A,B-A+1);
End;

Function IntStr(V:LongInt):String;
Var
 S:String;
Begin
 Str(V,S);
 IntStr:=S;
End;

Function RealStr(V:Double;Dec:Integer):String;
Var
 S:String;
Begin
 Str(V:0:Dec,S);
 RealStr:=S;
End;

{ Nombre le plus court possible (6 decimales au maximum) }
Function NumStr(V:Double):String;
Var
 S:String;
 L:Integer;
Begin
 If Abs(V)>=1E15 Then Begin
  Str(V:0:0,S);
 End
  Else
 Begin
  Str(V:0:6,S);
  If Pos('.',S)>0 Then Begin
   L:=Length(S);
   While(L>0)and(S[L]='0')do Dec(L);
   If(L>0)and(S[L]='.')Then Dec(L);
   S:=Copy(S,1,L);
  End;
 End;
 If S='-0' Then S:='0';
 NumStr:=S;
End;

Function StrToReal(Const S:String;Var V:Double):Boolean;
Var
 E:Integer;
 T:String;
Begin
 T:=Trim(S);
 If T='' Then Begin
  StrToReal:=False;
  Exit;
 End;
 Val(T,V,E);
 StrToReal:=E=0;
End;

Function StrToLong(Const S:String;Var V:LongInt):Boolean;
Var
 E:Integer;
 T:String;
Begin
 T:=Trim(S);
 If T='' Then Begin
  StrToLong:=False;
  Exit;
 End;
 Val(T,V,E);
 StrToLong:=E=0;
End;

Function PadR(Const S:String;N:Integer):String;
Var
 R:String;
Begin
 R:=S;
 While Length(R)<N do R:=R+' ';
 PadR:=Copy(R,1,N);
End;

Function MinL(A,B:LongInt):LongInt;
Begin
 If A<B Then MinL:=A Else MinL:=B;
End;

Function MaxL(A,B:LongInt):LongInt;
Begin
 If A>B Then MaxL:=A Else MaxL:=B;
End;

Function MinD(A,B:Double):Double;
Begin
 If A<B Then MinD:=A Else MinD:=B;
End;

Function MaxD(A,B:Double):Double;
Begin
 If A>B Then MaxD:=A Else MaxD:=B;
End;

Function ClampL(V,A,B:LongInt):LongInt;
Begin
 If V<A Then V:=A;
 If V>B Then V:=B;
 ClampL:=V;
End;

Function DirSep:Char;
Begin
 {$IFDEF UNIX}
 DirSep:='/';
 {$ELSE}
 DirSep:='\';
 {$ENDIF}
End;

Function IsSep(C:Char):Boolean;
Begin
 IsSep:=(C='/')or(C='\');
End;

Function JoinPath(Const D,N:String):String;
Begin
 If D='' Then JoinPath:=N Else
 If IsSep(D[Length(D)])Then JoinPath:=D+N
                       Else JoinPath:=D+DirSep+N;
End;

Function DirOf(Const P:String):String;
Var
 I:Integer;
Begin
 I:=Length(P);
 While(I>0)and Not IsSep(P[I])and(P[I]<>':')do Dec(I);
 If I<=1 Then DirOf:=Copy(P,1,I) Else
 If P[I]=':' Then DirOf:=Copy(P,1,I)
             Else DirOf:=Copy(P,1,I-1);
End;

Function FileOf(Const P:String):String;
Var
 I:Integer;
Begin
 I:=Length(P);
 While(I>0)and Not IsSep(P[I])and(P[I]<>':')do Dec(I);
 FileOf:=Copy(P,I+1,255);
End;

Function ExtOf(Const P:String):String;
Var
 I:Integer;
 N:String;
Begin
 N:=FileOf(P);
 I:=Length(N);
 While(I>0)and(N[I]<>'.')do Dec(I);
 If I=0 Then ExtOf:='' Else ExtOf:=StrLow(Copy(N,I,255));
End;

Function BaseOf(Const P:String):String;
Var
 I:Integer;
 N:String;
Begin
 N:=FileOf(P);
 I:=Length(N);
 While(I>0)and(N[I]<>'.')do Dec(I);
 If I=0 Then BaseOf:=N Else BaseOf:=Copy(N,1,I-1);
End;

Function ChangeExt(Const P,E:String):String;
Var
 I:Integer;
Begin
 I:=Length(P);
 While(I>0)and(P[I]<>'.')and Not IsSep(P[I])do Dec(I);
 If(I=0)or IsSep(P[I])Then ChangeExt:=P+E Else ChangeExt:=Copy(P,1,I-1)+E;
End;

Function IsAbsPath(Const P:String):Boolean;
Begin
 IsAbsPath:=(Length(P)>0)and(IsSep(P[1])or((Length(P)>1)and(P[2]=':')));
End;

Function FileExist(Const P:String):Boolean;
Var
 F:File;
 A:Word;
Begin
 If P='' Then Begin
  FileExist:=False;
  Exit;
 End;
 Assign(F,P);
 GetFAttr(F,A);
 FileExist:=(DosError=0)and((A and Directory)=0);
End;

Function DirExist(Const P:String):Boolean;
Var
 F:File;
 A:Word;
Begin
 If P='' Then Begin
  DirExist:=False;
  Exit;
 End;
 Assign(F,P);
 GetFAttr(F,A);
 DirExist:=(DosError=0)and((A and Directory)<>0);
End;

Function FullPath(Const P:String):String;
Var
 D:String;
Begin
 If P='' Then Begin
  FullPath:='';
  Exit;
 End;
 If IsAbsPath(P)Then FullPath:=P Else Begin
  GetDir(0,D);
  FullPath:=JoinPath(D,P);
 End;
End;

Procedure MakeDirs(Const P:String);
Var
 I:Integer;
 S:String;
Begin
 If P=''Then Exit;
 For I:=1 to Length(P)do Begin
  If IsSep(P[I])and(I>1)and(P[I-1]<>':')Then Begin
   S:=Copy(P,1,I-1);
   If Not DirExist(S)Then Begin
    {$I-}MkDir(S);{$I+}
    If IOResult<>0 Then;
   End;
  End;
 End;
 If Not DirExist(P)Then Begin
  {$I-}MkDir(P);{$I+}
  If IOResult<>0 Then;
 End;
End;

Function ReadFirstLine(Const FN:String):String;
Var
 F:Text;
 S:String;
Begin
 S:='';
 Assign(F,FN);
 {$I-}Reset(F);{$I+}
 If IOResult=0 Then Begin
  {$I-}ReadLn(F,S);{$I+}
  If IOResult<>0 Then S:='';
  Close(F);
 End;
 ReadFirstLine:=S;
End;

Function FileSizeOf(Const FN:String):LongInt;
Var
 F:File;
Begin
 Assign(F,FN);
 {$I-}Reset(F,1);{$I+}
 If IOResult<>0 Then Begin
  FileSizeOf:=-1;
  Exit;
 End;
 FileSizeOf:=FileSize(F);
 Close(F);
End;

{ Remplace les caracteres non alphanumeriques (noms de couches DXF) }
Function Sanitize(Const S:String):String;
Var
 I:Integer;
 R:String;
Begin
 R:=StrUp(S);
 For I:=1 to Length(R)do
  If Not(R[I] in['A'..'Z','0'..'9','_','-'])Then R[I]:='_';
 If R=''Then R:='0';
 Sanitize:=R;
End;

Function ReplaceAll(Const S,A,B:String):String;
Var
 R,T:String;
 P:Integer;
Begin
 If A=''Then Begin
  ReplaceAll:=S;
  Exit;
 End;
 R:='';
 T:=S;
 P:=Pos(A,T);
 While P>0 do Begin
  R:=R+Copy(T,1,P-1)+B;
  Delete(T,1,P+Length(A)-1);
  P:=Pos(A,T);
 End;
 ReplaceAll:=R+T;
End;

{ ------------------------------------------------------------------ }
{ Souris                                                              }
{ ------------------------------------------------------------------ }

{$IFNDEF FPC}
 Function MouseDriverFound: Boolean;
 Var
  Regs: Registers;
 Begin
  Regs.AX := 0;
  Intr($33, Regs);
  MouseDriverFound := Regs.AX = $FFFF;
 End;

 Procedure ShowMouse;
 Var
  Regs: Registers;
 Begin
  Regs.AX := $0001;
  Intr($33, Regs);
 End;

 Procedure HideMouse;
 Var
  Regs: Registers;
 Begin
  Regs.AX := $0002;
  Intr($33, Regs);
 End;

 Procedure GetMouseState(Var X, Y, Button: LongInt);
 Var
  Regs: Registers;
 Begin
  Regs.AX := $0003;
  Intr($33, Regs);
  Button := Regs.BX;
  X := Regs.CX;
  Y := Regs.DX;
 End;
{$ELSE}
 Function MouseDriverFound: Boolean;
 Begin
  PtcMouse.InitMouse;
  MouseDriverFound := True;
 End;

 Procedure ShowMouse;
 Begin
  PtcMouse.ShowMouse;
 End;

 Procedure HideMouse;
 Begin
  PtcMouse.HideMouse;
 End;

 Procedure GetMouseState(Var X, Y, Button: LongInt);
 Var
  LX,LY,LB:LongInt;
 Begin
  PtcMouse.GetMouseState(LX,LY,LB);
  X:=LX;
  Y:=LY;
  Button:=LB;
 End;
{$ENDIF}

{ Masque le curseur pendant un dessin (appels imbriques possibles) }
Procedure HM;
Begin
 If Not GraphOn Then Exit;
 If MouseOk and(MouseHid=0)Then HideMouse;
 Inc(MouseHid);
End;

Procedure SM;
Begin
 If Not GraphOn Then Exit;
 If MouseHid>0 Then Dec(MouseHid);
 If MouseOk and(MouseHid=0)Then ShowMouse;
End;

{ ------------------------------------------------------------------ }
{ Systemes de coordonnees                                             }
{ ------------------------------------------------------------------ }

Function CrsIdOf(Const S:String):Byte;
Var
 U:String;
Begin
 U:=StrUp(S);
 If(U='EPSG:4326')or(U='CRS:84')or(U='WGS84')Then CrsIdOf:=crs4326 Else
 If(U='EPSG:3857')or(U='EPSG:900913')or(U='EPSG:3785')Then CrsIdOf:=crs3857
                                                       Else CrsIdOf:=crsOther;
End;

Procedure XfPt(FromId,ToId:Byte;Var X,Y:Double);
Const
 R=6378137.0;
Var
 Lat:Double;
Begin
 If(FromId=ToId)or(FromId=crsOther)or(ToId=crsOther)Then Exit;
 If(FromId=crs4326)and(ToId=crs3857)Then Begin
  Lat:=Y;
  If Lat>85.05112878 Then Lat:=85.05112878;
  If Lat<-85.05112878 Then Lat:=-85.05112878;
  X:=X*Pi/180*R;
  Y:=R*Ln(Sin((Lat+90)*Pi/360)/Cos((Lat+90)*Pi/360));
 End
  Else
 If(FromId=crs3857)and(ToId=crs4326)Then Begin
  X:=X/R*180/Pi;
  Y:=(2*ArcTan(Exp(Y/R))-Pi/2)*180/Pi;
 End;
End;

{ Distance sur la sphere (haversine) entre deux positions lon/lat en degres }
Function GeoDist(Lon1,Lat1,Lon2,Lat2:Double):Double;
Const
 R=6371008.8;
Var
 A,B,C:Double;
Begin
 A:=(Lat2-Lat1)*Pi/360;
 B:=(Lon2-Lon1)*Pi/360;
 C:=Sin(A)*Sin(A)+Cos(Lat1*Pi/180)*Cos(Lat2*Pi/180)*Sin(B)*Sin(B);
 If C>1 Then C:=1;
 GeoDist:=2*R*ArcTan(Sqrt(C)/Sqrt(1-C+1E-300));
End;

{ Distance entre deux points exprimes dans le SCR du projet }
Function ProjDist(A,B:TPt):Double;
Var
 X1,Y1,X2,Y2:Double;
Begin
 X1:=A.X;Y1:=A.Y;X2:=B.X;Y2:=B.Y;
 If ProjCrsId=crs3857 Then Begin
  XfPt(crs3857,crs4326,X1,Y1);
  XfPt(crs3857,crs4326,X2,Y2);
 End;
 If ProjCrsId<>crsOther Then ProjDist:=GeoDist(X1,Y1,X2,Y2)
                        Else ProjDist:=Sqrt(Sqr(X2-X1)+Sqr(Y2-Y1));
End;

{ ------------------------------------------------------------------ }
{ Surface de rendu (ecran ou memoire)                                 }
{ ------------------------------------------------------------------ }

Procedure SetClip(L,T,R,B:LongInt);
Begin
 ClipL:=L;ClipT:=T;ClipR:=R;ClipB:=B;
End;

Procedure SPix(X,Y:LongInt;C:Byte);
Begin
 If(X<ClipL)or(X>ClipR)or(Y<ClipT)or(Y>ClipB)Then Exit;
 If OffScr Then OffBuf^[Y*OffW+X]:=C
           Else PutPixel(X,Y,C);
End;

Procedure SHLine(X1,X2,Y:LongInt;C:Byte);
Var
 X,T:LongInt;
Begin
 If(Y<ClipT)or(Y>ClipB)Then Exit;
 If X1>X2 Then Begin T:=X1;X1:=X2;X2:=T;End;
 If X1<ClipL Then X1:=ClipL;
 If X2>ClipR Then X2:=ClipR;
 If X1>X2 Then Exit;
 If OffScr Then Begin
  For X:=X1 to X2 do OffBuf^[Y*OffW+X]:=C;
 End
  Else
 Begin
  SetColor(C);
  Line(X1,Y,X2,Y);
 End;
End;

Procedure SBar(X1,Y1,X2,Y2:LongInt;C:Byte);
Var
 Y:LongInt;
Begin
 If X1<ClipL Then X1:=ClipL;
 If Y1<ClipT Then Y1:=ClipT;
 If X2>ClipR Then X2:=ClipR;
 If Y2>ClipB Then Y2:=ClipB;
 If(X1>X2)or(Y1>Y2)Then Exit;
 If OffScr Then Begin
  For Y:=Y1 to Y2 do SHLine(X1,X2,Y,C);
 End
  Else
 Begin
  SetFillStyle(SolidFill,C);
  Bar(X1,Y1,X2,Y2);
 End;
End;

{ Trait deja decoupe a la fenetre }
Procedure SLineI(X1,Y1,X2,Y2:LongInt;C:Byte);
Var
 DX,DY,SX,SY,E,E2:LongInt;
Begin
 If Not OffScr Then Begin
  SetColor(C);
  Line(X1,Y1,X2,Y2);
  Exit;
 End;
 DX:=Abs(X2-X1);
 DY:=-Abs(Y2-Y1);
 If X1<X2 Then SX:=1 Else SX:=-1;
 If Y1<Y2 Then SY:=1 Else SY:=-1;
 E:=DX+DY;
 While True do Begin
  SPix(X1,Y1,C);
  If(X1=X2)and(Y1=Y2)Then Exit;
  E2:=2*E;
  If E2>=DY Then Begin
   E:=E+DY;
   X1:=X1+SX;
  End;
  If E2<=DX Then Begin
   E:=E+DX;
   Y1:=Y1+SY;
  End;
 End;
End;

{ Decoupage de Liang-Barsky ; retourne False si le segment est hors fenetre }
Function ClipSeg(Var X1,Y1,X2,Y2:Double;XMin,YMin,XMax,YMax:Double):Boolean;
Var
 T0,T1,DX,DY:Double;
 Ok:Boolean;
 Procedure Test(P,Q:Double);
 Var
  R:Double;
 Begin
  If Not Ok Then Exit;
  If P=0 Then Begin
   If Q<0 Then Ok:=False;
   Exit;
  End;
  R:=Q/P;
  If P<0 Then Begin
   If R>T1 Then Ok:=False Else If R>T0 Then T0:=R;
  End
   Else
  Begin
   If R<T0 Then Ok:=False Else If R<T1 Then T1:=R;
  End;
 End;
Begin
 T0:=0;T1:=1;Ok:=True;
 DX:=X2-X1;DY:=Y2-Y1;
 Test(-DX,X1-XMin);
 Test(DX,XMax-X1);
 Test(-DY,Y1-YMin);
 Test(DY,YMax-Y1);
 If Ok Then Begin
  If T1<1 Then Begin
   X2:=X1+T1*DX;
   Y2:=Y1+T1*DY;
  End;
  If T0>0 Then Begin
   X1:=X1+T0*DX;
   Y1:=Y1+T0*DY;
  End;
 End;
 ClipSeg:=Ok;
End;

Procedure SLineD(X1,Y1,X2,Y2:Double;C:Byte);
Begin
 If(Abs(X1)>1E9)or(Abs(Y1)>1E9)or(Abs(X2)>1E9)or(Abs(Y2)>1E9)Then Exit;
 If ClipSeg(X1,Y1,X2,Y2,ClipL,ClipT,ClipR,ClipB)Then
  SLineI(Round(X1),Round(Y1),Round(X2),Round(Y2),C);
End;

{ Sauvegarde et restauration d'une zone de l'ecran }
Type
 TRow=Array[0..4095]of Byte;
 PRow=^TRow;

Procedure SaveRect(X,Y,W,H:LongInt;Var R:TRectSave);
Var
 I,J:LongInt;
 P:PRow;
Begin
 If H>600 Then H:=600;
 If W>4096 Then W:=4096;
 R.W:=W;R.H:=H;
 For I:=0 to H-1 do Begin
  GetMem(P,W);
  For J:=0 to W-1 do P^[J]:=GetPixel(X+J,Y+I);
  R.Rows[I]:=P;
 End;
End;

Procedure RestoreRect(X,Y:LongInt;Var R:TRectSave);
Var
 I,J:LongInt;
 P:PRow;
Begin
 For I:=0 to R.H-1 do Begin
  P:=R.Rows[I];
  If P<>Nil Then Begin
   For J:=0 to R.W-1 do PutPixel(X+J,Y+I,P^[J]);
   FreeMem(P,R.W);
   R.Rows[I]:=Nil;
  End;
 End;
 R.H:=0;
End;

{ ------------------------------------------------------------------ }
{ Jeux de caracteres : UTF-8 / Latin-1 <-> page de code DOS (CP437)  }
{ ------------------------------------------------------------------ }

Const
 Cp437ToLatin1:Array[128..255]of Byte=(
  199,252,233,226,228,224,229,231,234,235,232,239,238,236,196,197,
  201,230,198,244,246,242,251,249,255,214,220,162,163,165,63,63,
  225,237,243,250,241,209,170,186,191,63,172,189,188,161,171,187,
  63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,
  63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,
  63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,
  63,63,63,63,63,63,181,63,63,63,63,63,63,63,63,63,
  63,177,63,63,63,63,247,63,176,63,183,63,63,178,63,63);

Var
 Latin1ToCp437:Array[128..255]of Byte;

Procedure InitCharsets;
Var
 I:Integer;
Begin
 For I:=128 to 255 do Latin1ToCp437[I]:=63;
 For I:=255 downto 128 do
  If Cp437ToLatin1[I]<>63 Then Latin1ToCp437[Cp437ToLatin1[I]]:=I;
End;

{ Texte lu dans un fichier (UTF-8, sinon Latin-1) vers la page de code DOS }
Function FromExternal(Const S:String):String;
Var
 I,N:Integer;
 B,B2:Byte;
 Cp:LongInt;
 R:String;
 Function Cont(K:Integer):Boolean;
 Begin
  Cont:=(K<=N)and((Ord(S[K])and $C0)=$80);
 End;
 Procedure Put(C:LongInt);
 Begin
  If Length(R)>=255 Then Exit;
  If C<128 Then R:=R+Chr(C) Else
  If C<256 Then R:=R+Chr(Latin1ToCp437[C])
           Else R:=R+'?';
 End;
Begin
 R:='';
 N:=Length(S);
 I:=1;
 While I<=N do Begin
  B:=Ord(S[I]);
  If B<128 Then Begin
   Put(B);
   Inc(I);
  End
   Else
  If(B>=$C2)and(B<=$DF)and Cont(I+1)Then Begin
   B2:=Ord(S[I+1]);
   Cp:=((B and $1F)shl 6)or(B2 and $3F);
   Put(Cp);
   Inc(I,2);
  End
   Else
  If(B>=$E0)and(B<=$EF)and Cont(I+1)and Cont(I+2)Then Begin
   Put(256);
   Inc(I,3);
  End
   Else
  If(B>=$F0)and(B<=$F7)and Cont(I+1)and Cont(I+2)and Cont(I+3)Then Begin
   Put(256);
   Inc(I,4);
  End
   Else Begin
   Put(B);
   Inc(I);
  End;
 End;
 FromExternal:=R;
End;

{ ------------------------------------------------------------------ }
{ Chaines entreposees dans le tas                                     }
{ ------------------------------------------------------------------ }

Function NewStr(Const S:String):PStr;
Var
 P:PStr;
Begin
 GetMem(P,Length(S)+1);
 Move(S,P^,Length(S)+1);
 NewStr:=P;
End;

Procedure FreeStr(P:PStr);
Begin
 If P<>Nil Then FreeMem(P,Length(P^)+1);
End;
{ ------------------------------------------------------------------ }
{ Couches et entites                                                  }
{ ------------------------------------------------------------------ }

Const
 LayerColors:Array[0..7]of Byte=(LightGreen,LightBlue,Yellow,LightRed,LightCyan,LightMagenta,Brown,LightGray);
 LayerDark:Array[0..15]of Byte=(Black,Blue,Green,Cyan,Red,Magenta,Brown,DarkGray,Black,Blue,Green,Cyan,Red,Magenta,Brown,DarkGray);

Var
 LoadErr:String;
 ColorCount:Integer;
 AttrV:Array[1..MaxFields]of String[120];
 AttrMax:Integer;
 GrpCounter:LongInt;
 PartStart:LongInt;
 TmpKind:Byte;
 Truncated:Boolean;
 JF:File;
 JBuf:Array[0..4095]of Char;
 JP,JN:LongInt;
 JEof:Boolean;
 JCrsName:String;

Procedure InitLayer(Var L:TLayer);
Begin
 FillChar(L,SizeOf(L),0);
 L.Visible:=True;
 L.Fill:=True;
 L.CRS:='EPSG:4326';
 L.CrsId:=crs4326;
End;

Procedure FreeFeature(F:PFeature);
Var
 I:Integer;
Begin
 If F=Nil Then Exit;
 If F^.Pts<>Nil Then FreeMem(F^.Pts,F^.NPts*SizeOf(TPt));
 If F^.Ends<>Nil Then FreeMem(F^.Ends,F^.NParts*SizeOf(LongInt));
 If F^.Outer<>Nil Then FreeMem(F^.Outer,F^.NParts);
 If F^.Attr<>Nil Then Begin
  For I:=0 to F^.NA-1 do FreeStr(F^.Attr^[I]);
  FreeMem(F^.Attr,F^.NA*SizeOf(PStr));
 End;
 Dispose(F);
End;

Procedure FreeLayerData(Var L:TLayer);
Var
 I:LongInt;
Begin
 If L.Feats<>Nil Then Begin
  For I:=1 to L.NF do FreeFeature(L.Feats^[I]);
  FreeMem(L.Feats,L.Cap*SizeOf(PFeature));
  L.Feats:=Nil;
 End;
 If L.RData<>Nil Then Begin
  FreeMem(L.RData,L.RW*L.RH*SizeOf(Single));
  L.RData:=Nil;
 End;
 L.NF:=0;L.Cap:=0;
End;

Procedure ClearAttrs;
Var
 I:Integer;
Begin
 For I:=1 to MaxFields do AttrV[I]:='';
 AttrMax:=0;
End;

Procedure ResetTmp;
Begin
 TmpN:=0;TmpParts:=0;PartStart:=0;GrpCounter:=0;TmpKind:=gkNone;
 ClearAttrs;
End;

Function FieldIndex(Var L:TLayer;Const Name:String):Integer;
Var
 I:Integer;
 N:String;
Begin
 N:=Copy(Name,1,24);
 For I:=1 to L.NFld do
  If L.Fld[I]=N Then Begin
   FieldIndex:=I;
   Exit;
  End;
 If L.NFld>=MaxFields Then Begin
  FieldIndex:=0;
  Exit;
 End;
 Inc(L.NFld);
 L.Fld[L.NFld]:=N;
 FieldIndex:=L.NFld;
End;

Procedure SetAttr(I:Integer;Const V:String);
Begin
 If(I<1)or(I>MaxFields)Then Exit;
 AttrV[I]:=Copy(FromExternal(V),1,120);
 If I>AttrMax Then AttrMax:=I;
End;

Procedure AddTmpPt(X,Y:Double);
Begin
 If TmpN>=MaxPtsF Then Begin
  Truncated:=True;
  Exit;
 End;
 TmpPts^[TmpN].X:=X;
 TmpPts^[TmpN].Y:=Y;
 Inc(TmpN);
End;

Procedure FinishPart;
Begin
 If TmpN<=PartStart Then Exit;
 If TmpParts>=MaxPartsF Then Exit;
 TmpEnds^[TmpParts]:=TmpN;
 TmpGrp^[TmpParts]:=GrpCounter;
 Inc(TmpParts);
 PartStart:=TmpN;
End;

{ Ajoute l'entite decrite par les tampons a la couche }
Procedure CommitFeature(Var L:TLayer);
Var
 F:PFeature;
 NewCap:LongInt;
 NewF:PFeatArr;
 I:LongInt;
 P:PStrArr;
Begin
 If L.NF>=MaxFeat Then Begin
  Truncated:=True;
  Exit;
 End;
 If L.NF>=L.Cap Then Begin
  If L.Cap=0 Then NewCap:=256 Else NewCap:=L.Cap*2;
  If NewCap>MaxFeat Then NewCap:=MaxFeat;
  GetMem(NewF,NewCap*SizeOf(PFeature));
  If L.Feats<>Nil Then Begin
   Move(L.Feats^,NewF^,L.NF*SizeOf(PFeature));
   FreeMem(L.Feats,L.Cap*SizeOf(PFeature));
  End;
  L.Feats:=NewF;
  L.Cap:=NewCap;
 End;
 New(F);
 FillChar(F^,SizeOf(F^),0);
 F^.Kind:=TmpKind;
 If TmpParts=0 Then F^.Kind:=gkNone;
 If F^.Kind<>gkNone Then Begin
  F^.NPts:=TmpN;
  F^.NParts:=TmpParts;
  GetMem(F^.Pts,TmpN*SizeOf(TPt));
  Move(TmpPts^,F^.Pts^,TmpN*SizeOf(TPt));
  GetMem(F^.Ends,TmpParts*SizeOf(LongInt));
  Move(TmpEnds^,F^.Ends^,TmpParts*SizeOf(LongInt));
  GetMem(F^.Outer,TmpParts);
  For I:=0 to TmpParts-1 do
   If(I=0)or(TmpGrp^[I]<>TmpGrp^[I-1])Then F^.Outer^[I]:=1
                                       Else F^.Outer^[I]:=0;
  F^.MinX:=1E300;F^.MinY:=1E300;F^.MaxX:=-1E300;F^.MaxY:=-1E300;
  For I:=0 to TmpN-1 do Begin
   If TmpPts^[I].X<F^.MinX Then F^.MinX:=TmpPts^[I].X;
   If TmpPts^[I].X>F^.MaxX Then F^.MaxX:=TmpPts^[I].X;
   If TmpPts^[I].Y<F^.MinY Then F^.MinY:=TmpPts^[I].Y;
   If TmpPts^[I].Y>F^.MaxY Then F^.MaxY:=TmpPts^[I].Y;
  End;
  If L.GType=gkNone Then L.GType:=F^.Kind;
  If L.HasExt Then Begin
   If F^.MinX<L.MinX Then L.MinX:=F^.MinX;
   If F^.MinY<L.MinY Then L.MinY:=F^.MinY;
   If F^.MaxX>L.MaxX Then L.MaxX:=F^.MaxX;
   If F^.MaxY>L.MaxY Then L.MaxY:=F^.MaxY;
  End
   Else
  Begin
   L.MinX:=F^.MinX;L.MinY:=F^.MinY;L.MaxX:=F^.MaxX;L.MaxY:=F^.MaxY;
   L.HasExt:=True;
  End;
 End;
 If AttrMax>0 Then Begin
  F^.NA:=AttrMax;
  GetMem(P,AttrMax*SizeOf(PStr));
  For I:=0 to AttrMax-1 do P^[I]:=NewStr(AttrV[I+1]);
  F^.Attr:=P;
 End;
 Inc(L.NF);
 L.Feats^[L.NF]:=F;
 ResetTmp;
End;

Function FeatAttr(Var L:TLayer;F:PFeature;Idx:Integer):String;
Begin
 If(F=Nil)or(Idx<1)or(Idx>F^.NA)or(F^.Attr=Nil)Then FeatAttr:='' Else FeatAttr:=F^.Attr^[Idx-1]^;
End;

{ Guess du SCR d'une couche d'apres l'etendue de ses coordonnees }
Procedure GuessCrs(Var L:TLayer);
Begin
 If L.CRS<>'EPSG:4326' Then Exit;
 If Not L.HasExt Then Exit;
 If(L.MinX<-180.001)or(L.MaxX>180.001)or(L.MinY<-90.001)or(L.MaxY>90.001)Then Begin
  L.CRS:='EPSG:3857';
  L.CrsId:=crs3857;
 End;
End;

Procedure SetLayerCrs(Var L:TLayer;Const S:String);
Begin
 L.CRS:=Copy(S,1,24);
 L.CrsId:=CrsIdOf(S);
End;

Procedure RecalcExtent(Var L:TLayer);
Var
 I:LongInt;
 F:PFeature;
Begin
 L.HasExt:=False;
 For I:=1 to L.NF do Begin
  F:=L.Feats^[I];
  If F^.Kind<>gkNone Then
   If L.HasExt Then Begin
    If F^.MinX<L.MinX Then L.MinX:=F^.MinX;
    If F^.MinY<L.MinY Then L.MinY:=F^.MinY;
    If F^.MaxX>L.MaxX Then L.MaxX:=F^.MaxX;
    If F^.MaxY>L.MaxY Then L.MaxY:=F^.MaxY;
   End
    Else
   Begin
    L.MinX:=F^.MinX;L.MinY:=F^.MinY;L.MaxX:=F^.MaxX;L.MaxY:=F^.MaxY;
    L.HasExt:=True;
   End;
 End;
End;

{ ------------------------------------------------------------------ }
{ Lecture tamponnee (JSON, grilles ASCII)                             }
{ ------------------------------------------------------------------ }

Function OpenStream(Const FN:String):Boolean;
Begin
 Assign(JF,FN);
 {$I-}Reset(JF,1);{$I+}
 If IOResult<>0 Then Begin
  OpenStream:=False;
  Exit;
 End;
 JP:=0;JN:=0;JEof:=False;
 OpenStream:=True;
End;

Procedure CloseStream;
Begin
 Close(JF);
End;

Function JPeek:Char;
Begin
 If JP>=JN Then Begin
  If JEof Then Begin
   JPeek:=#0;
   Exit;
  End;
  JN:=0;
  {$I-}BlockRead(JF,JBuf,SizeOf(JBuf),JN);{$I+}
  If IOResult<>0 Then JN:=0;
  JP:=0;
  If JN<=0 Then Begin
   JEof:=True;
   JN:=0;
   JPeek:=#0;
   Exit;
  End;
 End;
 JPeek:=JBuf[JP];
End;

Procedure JAdv;
Begin
 If JP<JN Then Inc(JP);
End;

Procedure JSkipWs;
Begin
 While(JPeek in[' ',#9,#10,#13])and Not JEof do JAdv;
End;

Function HexVal(C:Char):Integer;
Begin
 Case C of
  '0'..'9':HexVal:=Ord(C)-48;
  'a'..'f':HexVal:=Ord(C)-87;
  'A'..'F':HexVal:=Ord(C)-55;
  Else HexVal:=0;
 End;
End;

{ Lit une chaine JSON (le guillemet ouvrant est le caractere courant) }
Procedure JStr(Var S:String);
Var
 C,E:Char;
 I,Code:Integer;
Begin
 S:='';
 JAdv;
 While True do Begin
  C:=JPeek;
  If JEof Then Exit;
  JAdv;
  If C='"' Then Exit;
  If C='\' Then Begin
   E:=JPeek;
   JAdv;
   Case E of
    'n','r','t':C:=' ';
    'b','f':C:=' ';
    'u':Begin
     Code:=0;
     For I:=1 to 4 do Begin
      Code:=Code*16+HexVal(JPeek);
      JAdv;
     End;
     If Code<256 Then C:=Chr(Code) Else C:='?';
    End;
    Else C:=E;
   End;
  End;
  If Length(S)<255 Then S:=S+C;
 End;
End;

{ Lit un jeton brut (nombre, true, false, null) }
Procedure JToken(Var S:String);
Var
 C:Char;
Begin
 S:='';
 While True do Begin
  C:=JPeek;
  If JEof or(C in[',',']','}',' ',#9,#10,#13])Then Exit;
  If Length(S)<255 Then S:=S+C;
  JAdv;
 End;
End;

Procedure JSkip;
Var
 Depth:Integer;
 C:Char;
 Dummy:String;
Begin
 JSkipWs;
 C:=JPeek;
 If C='"' Then Begin
  JStr(Dummy);
  Exit;
 End;
 If(C='{')or(C='[')Then Begin
  Depth:=0;
  While Not JEof do Begin
   C:=JPeek;
   If C='"' Then JStr(Dummy) Else Begin
    JAdv;
    If(C='{')or(C='[')Then Inc(Depth);
    If(C='}')or(C=']')Then Begin
     Dec(Depth);
     If Depth=0 Then Exit;
    End;
   End;
  End;
  Exit;
 End;
 JToken(Dummy);
End;

Function JIsNumStart(C:Char):Boolean;
Begin
 JIsNumStart:=C in['0'..'9','-','+','.'];
End;

{ Element suivant d'un conteneur JSON : True si le curseur est sur un element,
  False a la fermeture (le caractere de fermeture est consomme) }
Function JNext(Close:Char):Boolean;
Var
 C:Char;
Begin
 JNext:=False;
 While Not JEof do Begin
  JSkipWs;
  C:=JPeek;
  If C=Close Then Begin
   JAdv;
   Exit;
  End;
  If C=',' Then JAdv Else Begin
   JNext:=True;
   Exit;
  End;
 End;
End;

{ Lit une cle d'objet et le ':' qui la suit }
Procedure JKey(Var Key:String);
Begin
 JStr(Key);
 JSkipWs;
 If JPeek=':' Then JAdv;
 JSkipWs;
End;

{ Lit un tableau de coordonnees ; retourne la profondeur (1=position) }
Function JCoords:Integer;
Var
 Depth,Sub,Cnt:Integer;
 X,Y,V:Double;
 S:String;
Begin
 JAdv;
 JSkipWs;
 Depth:=0;
 If JIsNumStart(JPeek)Then Begin
  Cnt:=0;
  X:=0;Y:=0;
  While JNext(']')do Begin
   JToken(S);
   If S='' Then JAdv Else Begin
    If Not StrToReal(S,V)Then V:=0;
    Inc(Cnt);
    If Cnt=1 Then X:=V Else If Cnt=2 Then Y:=V;
   End;
  End;
  If Cnt>=2 Then AddTmpPt(X,Y);
  JCoords:=1;
  Exit;
 End;
 While JNext(']')do Begin
  If JPeek='[' Then Begin
   Sub:=JCoords;
   If Sub+1>Depth Then Depth:=Sub+1;
   If Sub=2 Then FinishPart;
  End
   Else JSkip;
 End;
 If Depth=3 Then Inc(GrpCounter);
 JCoords:=Depth;
End;

Function KindOfType(Const T:String):Byte;
Begin
 KindOfType:=gkNone;
 If Pos('point',T)>0 Then KindOfType:=gkPoint Else
 If Pos('linestring',T)>0 Then KindOfType:=gkLine Else
 If Pos('polygon',T)>0 Then KindOfType:=gkPoly;
End;

Procedure JParseGeometry;
Var
 Key,T:String;
 K:Byte;
 Sub:Integer;
Begin
 JSkipWs;
 If JPeek<>'{' Then Begin
  JSkip;
  Exit;
 End;
 JAdv;
 T:='';
 While JNext('}')do Begin
  If JPeek='"' Then Begin
   JKey(Key);
   If Key='type' Then Begin
    If JPeek='"' Then JStr(T) Else JSkip;
    T:=StrLow(T);
   End
    Else
   If(Key='coordinates')and(JPeek='[')Then Begin
    Sub:=JCoords;
    If(Sub=1)or(Sub=2)Then FinishPart;
   End
    Else
   If(Key='geometries')and(JPeek='[')Then Begin
    JAdv;
    While JNext(']')do JParseGeometry;
   End
    Else JSkip;
  End
   Else JAdv;
 End;
 K:=KindOfType(T);
 If K>TmpKind Then TmpKind:=K;
End;

Procedure JParseProps(Var L:TLayer);
Var
 Key,V:String;
 C:Char;
 Idx:Integer;
Begin
 JSkipWs;
 If JPeek<>'{' Then Begin
  JSkip;
  Exit;
 End;
 JAdv;
 While JNext('}')do Begin
  If JPeek='"' Then Begin
   JKey(Key);
   C:=JPeek;
   If C='"' Then JStr(V) Else
   If(C='{')or(C='[')Then Begin
    JSkip;
    V:='';
   End
    Else
   Begin
    JToken(V);
    If V='null' Then V:='';
   End;
   Idx:=FieldIndex(L,Key);
   If Idx>0 Then SetAttr(Idx,V);
  End
   Else JAdv;
 End;
End;

Procedure JParseCrs;
Var
 Key:String;
Begin
 JSkipWs;
 If JPeek<>'{' Then Begin
  JSkip;
  Exit;
 End;
 JAdv;
 While JNext('}')do Begin
  If JPeek='"' Then Begin
   JKey(Key);
   If JPeek='{' Then JParseCrs Else
   If(JPeek='"')and(Key='name')Then JStr(JCrsName)
                               Else JSkip;
  End
   Else JAdv;
 End;
End;

Procedure JParseFeature(Var L:TLayer;IsRoot:Boolean);
Var
 Key,T:String;
 Sub:Integer;
Begin
 JSkipWs;
 If JPeek<>'{' Then Begin
  JSkip;
  Exit;
 End;
 JAdv;
 T:='';
 While JNext('}')do Begin
  If JPeek='"' Then Begin
   JKey(Key);
   If Key='type' Then Begin
    If JPeek='"' Then JStr(T) Else JSkip;
   End
    Else
   If Key='properties' Then JParseProps(L) Else
   If Key='geometry' Then JParseGeometry Else
   If Key='crs' Then JParseCrs Else
   If(Key='coordinates')and(JPeek='[')Then Begin
    Sub:=JCoords;
    If(Sub=1)or(Sub=2)Then FinishPart;
   End
    Else
   If(Key='geometries')and(JPeek='[')Then Begin
    JAdv;
    While JNext(']')do JParseGeometry;
   End
    Else
   If(Key='features')and(JPeek='[')Then Begin
    JAdv;
    While JNext(']')do Begin
     ResetTmp;
     JParseFeature(L,False);
    End;
   End
    Else JSkip;
  End
   Else JAdv;
 End;
 If TmpKind=gkNone Then TmpKind:=KindOfType(StrLow(T));
 If Not IsRoot Then CommitFeature(L) Else
 If StrLow(T)<>'featurecollection' Then CommitFeature(L);
End;

Function EpsgFromName(Const S:String):String;
Var
 I:Integer;
 Num:String;
Begin
 EpsgFromName:='';
 If Pos('CRS84',StrUp(S))>0 Then Begin
  EpsgFromName:='EPSG:4326';
  Exit;
 End;
 If Pos('EPSG',StrUp(S))=0 Then Exit;
 Num:='';
 I:=Length(S);
 While(I>0)and(S[I] in['0'..'9'])do Begin
  Num:=S[I]+Num;
  Dec(I);
 End;
 If Num<>'' Then EpsgFromName:='EPSG:'+Num;
End;

Function AllocTmp:Boolean;
Begin
 If TmpPts=Nil Then Begin
  GetMem(TmpPts,(MaxPtsF+1)*SizeOf(TPt));
  GetMem(TmpEnds,(MaxPartsF+1)*SizeOf(LongInt));
  GetMem(TmpGrp,(MaxPartsF+1)*SizeOf(LongInt));
 End;
 AllocTmp:=TmpPts<>Nil;
End;

Function LoadGeoJSON(Var L:TLayer;Const FN:String):Boolean;
Var
 E:String;
Begin
 LoadGeoJSON:=False;
 If Not AllocTmp Then Begin
  LoadErr:='Memoire insuffisante';
  Exit;
 End;
 If Not OpenStream(FN)Then Begin
  LoadErr:='Impossible d''ouvrir '+FN;
  Exit;
 End;
 ResetTmp;
 JCrsName:='';
 Truncated:=False;
 JSkipWs;
 If JPeek=#$EF Then Begin
  JAdv;JAdv;JAdv;
  JSkipWs;
 End;
 If JPeek<>'{' Then Begin
  CloseStream;
  LoadErr:='Ce fichier n''est pas du GeoJSON : '+FN;
  Exit;
 End;
 JParseFeature(L,True);
 CloseStream;
 If JCrsName<>'' Then Begin
  E:=EpsgFromName(JCrsName);
  If E<>'' Then SetLayerCrs(L,E);
 End;
 If JCrsName='' Then GuessCrs(L);
 If L.NF=0 Then Begin
  LoadErr:='Aucune entite dans '+FN;
  Exit;
 End;
 LoadGeoJSON:=True;
End;
{ ------------------------------------------------------------------ }
{ Shapefile                                                           }
{ ------------------------------------------------------------------ }

Const
{$IFDEF FPC}
 SBufMax=8000000;
{$ELSE}
 SBufMax=65000;
{$ENDIF}

Type
 TByteBuf=Array[0..SBufMax]of Byte;
 PByteBuf=^TByteBuf;

Var
 SBuf:PByteBuf;

Function RdL(Off:LongInt):LongInt;
Var
 V:LongInt;
Begin
 Move(SBuf^[Off],V,4);
 RdL:=V;
End;

Function RdD(Off:LongInt):Double;
Var
 V:Double;
Begin
 Move(SBuf^[Off],V,8);
 RdD:=V;
End;

Function DetectPrj(Const S:String):String;
Var
 U,Name:String;
 I,J,P:Integer;
 Num:String;
Begin
 U:=StrUp(S);
 DetectPrj:='';
 If S='' Then Exit;
 If(Pos('WEB_MERCATOR',U)>0)or(Pos('PSEUDO-MERCATOR',U)>0)or(Pos('"EPSG","3857"',U)>0)Then Begin
  DetectPrj:='EPSG:3857';
  Exit;
 End;
 If Copy(U,1,6)='GEOGCS' Then Begin
  DetectPrj:='EPSG:4326';
  Exit;
 End;
 If Copy(U,1,6)='PROJCS' Then Begin
  P:=0;
  For I:=1 to Length(U)-18 do
   If Copy(U,I,18)='AUTHORITY["EPSG","' Then P:=I+18;
  If P>0 Then Begin
   Num:='';
   J:=P;
   While(J<=Length(U))and(U[J] in['0'..'9'])do Begin
    Num:=Num+U[J];
    Inc(J);
   End;
   If Num<>'' Then Begin
    DetectPrj:='EPSG:'+Num;
    Exit;
   End;
  End;
  Name:='';
  I:=Pos('"',S);
  If I>0 Then Begin
   J:=I+1;
   While(J<=Length(S))and(S[J]<>'"')do Begin
    Name:=Name+S[J];
    Inc(J);
   End;
  End;
  DetectPrj:='USER:'+Copy(Name,1,18);
 End;
End;

Procedure ApplyPrj(Var L:TLayer;Const FN:String);
Var
 S:String;
Begin
 S:=DetectPrj(ReadFirstLine(ChangeExt(FN,'.prj')));
 If S='' Then S:=DetectPrj(ReadFirstLine(ChangeExt(FN,'.PRJ')));
 If S<>'' Then SetLayerCrs(L,S) Else GuessCrs(L);
End;

Function ShpRingArea(Start,Stop:LongInt):Double;
Var
 I:LongInt;
 A:Double;
Begin
 A:=0;
 For I:=Start to Stop-1 do Begin
  If I=Stop-1 Then
   A:=A+(TmpPts^[I].X*TmpPts^[Start].Y-TmpPts^[Start].X*TmpPts^[I].Y)
  Else
   A:=A+(TmpPts^[I].X*TmpPts^[I+1].Y-TmpPts^[I+1].X*TmpPts^[I].Y);
 End;
 ShpRingArea:=A/2;
End;

Function LoadShapefile(Var L:TLayer;Const FN:String):Boolean;
Var
 SF,DF:File;
 Hdr:Array[0..99]of Byte;
 RH:Array[0..7]of Byte;
 ShpType,Typ,NP,NPt,I,J,Cnt:LongInt;
 ContLen,Got:LongInt;
 HasDbf:Boolean;
 DbfRecs,DbfHdrLen,DbfRecLen,NDf:LongInt;
 DbfOff,DbfLen:Array[1..MaxFields]of LongInt;
 DbfIdx:Array[1..MaxFields]of Integer;
 DH:Array[0..31]of Byte;
 DRec:Array[0..4095]of Byte;
 Fld:String;
 Rn:LongInt;
 PStart,PEnd,Part:LongInt;
 Ar:Double;
 Dbfn:String;
 Ok:Boolean;
 K:Integer;
Begin
 LoadShapefile:=False;
 If Not AllocTmp Then Begin
  LoadErr:='Memoire insuffisante';
  Exit;
 End;
 Assign(SF,FN);
 {$I-}Reset(SF,1);{$I+}
 If IOResult<>0 Then Begin
  LoadErr:='Impossible d''ouvrir '+FN;
  Exit;
 End;
 {$I-}BlockRead(SF,Hdr,100,Got);{$I+}
 If(IOResult<>0)or(Got<100)Then Begin
  Close(SF);
  LoadErr:='Fichier .shp invalide';
  Exit;
 End;
 Move(Hdr[32],ShpType,4);
 If SBuf=Nil Then GetMem(SBuf,SBufMax+1);
 If SBuf=Nil Then Begin
  Close(SF);
  LoadErr:='Memoire insuffisante';
  Exit;
 End;
 { Table dBASE }
 HasDbf:=False;
 NDf:=0;
 Dbfn:=ChangeExt(FN,'.dbf');
 If Not FileExist(Dbfn)Then Dbfn:=ChangeExt(FN,'.DBF');
 If FileExist(Dbfn)Then Begin
  Assign(DF,Dbfn);
  {$I-}Reset(DF,1);{$I+}
  If IOResult=0 Then Begin
   BlockRead(DF,DH,32,Got);
   If Got=32 Then Begin
    Move(DH[4],DbfRecs,4);
    DbfHdrLen:=DH[8]+DH[9]*256;
    DbfRecLen:=DH[10]+DH[11]*256;
    If(DbfRecLen>0)and(DbfRecLen<4090)Then Begin
     HasDbf:=True;
     Cnt:=1;
     While(Cnt*32<DbfHdrLen-1)and(NDf<MaxFields)do Begin
      BlockRead(DF,DH,32,Got);
      If(Got<32)or(DH[0]=$0D)Then Cnt:=DbfHdrLen
      Else Begin
       Inc(NDf);
       Fld:='';
       For I:=0 to 10 do If DH[I]<>0 Then Fld:=Fld+Chr(DH[I]);
       DbfLen[NDf]:=DH[16];
       If NDf=1 Then DbfOff[NDf]:=1 Else DbfOff[NDf]:=DbfOff[NDf-1]+DbfLen[NDf-1];
       DbfIdx[NDf]:=FieldIndex(L,Fld);
       Inc(Cnt);
      End;
     End;
     Seek(DF,DbfHdrLen);
    End;
   End;
   If Not HasDbf Then Close(DF);
  End;
 End;
 ResetTmp;
 Truncated:=False;
 Rn:=0;
 Ok:=True;
 While Ok and Not Eof(SF)do Begin
  {$I-}BlockRead(SF,RH,8,Got);{$I+}
  If(IOResult<>0)or(Got<8)Then Ok:=False Else Begin
   ContLen:=(LongInt(RH[4])*16777216+LongInt(RH[5])*65536+LongInt(RH[6])*256+RH[7])*2;
   Inc(Rn);
   ResetTmp;
   If(ContLen<4)or(ContLen>SBufMax)Then Begin
    { Enregistrement trop gros : on saute son contenu }
    If ContLen>=0 Then Seek(SF,FilePos(SF)+ContLen);
    TmpKind:=gkNone;
    Typ:=0;
    ContLen:=0;
   End
    Else
   Begin
    BlockRead(SF,SBuf^,ContLen,Got);
    If Got<ContLen Then Ok:=False;
    Typ:=RdL(0);
   End;
   If Ok Then Begin
    TmpKind:=gkNone;
    If ContLen>=4 Then Begin
     Case Typ of
      1,11,21:Begin
       If ContLen>=20 Then Begin
        AddTmpPt(RdD(4),RdD(12));
        FinishPart;
        TmpKind:=gkPoint;
       End;
      End;
      8,18,28:Begin
       If ContLen>=40 Then Begin
        NPt:=RdL(36);
        For I:=0 to NPt-1 do
         If 40+I*16+16<=ContLen Then AddTmpPt(RdD(40+I*16),RdD(48+I*16));
        FinishPart;
        TmpKind:=gkPoint;
       End;
      End;
      3,13,23,5,15,25:Begin
       If ContLen>=44 Then Begin
        NP:=RdL(36);
        NPt:=RdL(40);
        If(NP>0)and(NP<=MaxPartsF)and(NPt>0)and(44+NP*4+NPt*16<=ContLen)Then Begin
         For I:=0 to NPt-1 do
          AddTmpPt(RdD(44+NP*4+I*16),RdD(52+NP*4+I*16));
         For Part:=0 to NP-1 do Begin
          PStart:=RdL(44+Part*4);
          If Part=NP-1 Then PEnd:=NPt Else PEnd:=RdL(44+(Part+1)*4);
          If PEnd>TmpN Then PEnd:=TmpN;
          If PEnd>PStart Then Begin
           If Typ in[5,15,25]Then Begin
            Ar:=ShpRingArea(PStart,PEnd);
            If(Ar<=0)or(Part=0)Then Inc(GrpCounter);
           End
            Else Inc(GrpCounter);
           TmpEnds^[TmpParts]:=PEnd;
           TmpGrp^[TmpParts]:=GrpCounter;
           Inc(TmpParts);
          End;
         End;
         If Typ in[5,15,25]Then TmpKind:=gkPoly Else TmpKind:=gkLine;
        End;
       End;
      End;
     End;
    End;
    { Attributs }
    If HasDbf and(Rn<=DbfRecs)Then Begin
     BlockRead(DF,DRec,DbfRecLen,Got);
     If Got=DbfRecLen Then
      For K:=1 to NDf do Begin
       Fld:='';
       For J:=0 to DbfLen[K]-1 do
        If Length(Fld)<120 Then Fld:=Fld+Chr(DRec[DbfOff[K]+J]);
       SetAttr(DbfIdx[K],Trim(Fld));
      End;
    End;
    CommitFeature(L);
   End;
  End;
 End;
 Close(SF);
 If HasDbf Then Close(DF);
 ApplyPrj(L,FN);
 If L.NF=0 Then Begin
  LoadErr:='Aucune entite dans '+FN;
  Exit;
 End;
 LoadShapefile:=True;
End;

{ ------------------------------------------------------------------ }
{ WKT (lecture incrementale) et coordonnees texte                     }
{ ------------------------------------------------------------------ }

Var
 WType:String;
 WDepth,WKind,WPoly,WCnt:Integer;
 WNum:String;
 WCur:Array[1..4]of Double;
 WInWord:Boolean;

Procedure WktBegin;
Begin
 TmpN:=0;TmpParts:=0;PartStart:=0;GrpCounter:=0;TmpKind:=gkNone;
 WType:='';WDepth:=0;WKind:=gkNone;WPoly:=0;WCnt:=0;WNum:='';WInWord:=True;
End;

Procedure WktFlushNum;
Var
 V:Double;
Begin
 If WNum<>'' Then Begin
  If Not StrToReal(WNum,V)Then V:=0;
  Inc(WCnt);
  If WCnt<=4 Then WCur[WCnt]:=V;
  WNum:='';
 End;
End;

Procedure WktEndPos;
Begin
 WktFlushNum;
 If WCnt>=2 Then AddTmpPt(WCur[1],WCur[2]);
 WCnt:=0;
End;

Procedure WktFeed(C:Char);
Var
 U:String;
Begin
 If WInWord Then Begin
  If C='(' Then Begin
   U:=StrUp(WType);
   WKind:=gkNone;
   If Pos('POINT',U)>0 Then WKind:=gkPoint Else
   If Pos('LINESTRING',U)>0 Then WKind:=gkLine Else
   If Pos('POLYGON',U)>0 Then WKind:=gkPoly;
   If Pos('MULTIPOLYGON',U)>0 Then WPoly:=1 Else WPoly:=0;
   WInWord:=False;
   WDepth:=1;
  End
   Else
  If C in['A'..'Z','a'..'z']Then WType:=WType+C;
  Exit;
 End;
 Case C of
  '(':Inc(WDepth);
  ')':Begin
   WktEndPos;
   FinishPart;
   Dec(WDepth);
   If(WKind=gkPoly)and(WDepth=WPoly)Then Inc(GrpCounter);
  End;
  ',':WktEndPos;
  ' ',#9,#10,#13:WktFlushNum;
  Else If C in['0'..'9','+','-','.','e','E']Then WNum:=WNum+C;
 End;
End;

Procedure WktEnd;
Begin
 WktEndPos;
 FinishPart;
 TmpKind:=WKind;
End;

{ Nombre decimal ou degres-minutes-secondes (50d12'N, 66d22'W...) }
Function ParseCoord(Const S:String;Var V:Double):Boolean;
Var
 I,N:Integer;
 Num:String;
 Parts:Array[1..3]of Double;
 T:Double;
 Neg:Boolean;
 C:Char;
 Dec:Boolean;
Begin
 ParseCoord:=False;
 If StrToReal(S,V)Then Begin
  ParseCoord:=True;
  Exit;
 End;
 N:=0;Num:='';Neg:=False;Dec:=False;
 For I:=1 to Length(S)+1 do Begin
  If I<=Length(S)Then C:=S[I] Else C:=' ';
  If C in['0'..'9']Then Num:=Num+C Else
  If(C='.')or(C=',')Then Begin
   If Num<>'' Then Num:=Num+'.';
   Dec:=True;
  End
   Else
  Begin
   If Num<>'' Then Begin
    If Num[Length(Num)]='.' Then Delete(Num,Length(Num),1);
    If(N<3)and StrToReal(Num,T)Then Begin
     Inc(N);
     Parts[N]:=T;
    End;
    Num:='';
   End;
   If(C in['S','s','W','w','O','o'])Then Neg:=True;
   If C='-' Then Neg:=True;
  End;
 End;
 If Dec Then;
 If N=0 Then Exit;
 T:=Parts[1];
 If N>=2 Then T:=T+Parts[2]/60;
 If N>=3 Then T:=T+Parts[3]/3600;
 If Neg Then T:=-T;
 V:=T;
 ParseCoord:=True;
End;

{ ------------------------------------------------------------------ }
{ CSV                                                                 }
{ ------------------------------------------------------------------ }

Function ColIs(Const Name:String;Const List:String):Boolean;
Begin
 ColIs:=Pos(','+StrLow(Trim(Name))+',',','+List+',')>0;
End;

{ Lit un champ ; RowEnd est vrai si une fin de ligne (ou de fichier) a ete lue }
Procedure CsvField(Var S:String;Delim:Char;Var RowEnd:Boolean);
Var
 C:Char;
 InQ,Fin:Boolean;
Begin
 S:='';
 RowEnd:=False;
 InQ:=False;
 Fin:=False;
 If JPeek='"' Then Begin
  JAdv;
  InQ:=True;
  While InQ and Not JEof do Begin
   C:=JPeek;
   If Not JEof Then Begin
    JAdv;
    If C='"' Then Begin
     If JPeek='"' Then Begin
      JAdv;
      If Length(S)<255 Then S:=S+'"';
     End
      Else InQ:=False;
    End
     Else If Length(S)<255 Then S:=S+C;
   End;
  End;
 End;
 While Not Fin do Begin
  C:=JPeek;
  If JEof Then Begin
   RowEnd:=True;
   Fin:=True;
  End
   Else
  If C=Delim Then Begin
   JAdv;
   Fin:=True;
  End
   Else
  If(C=#13)or(C=#10)Then Begin
   JAdv;
   If(C=#13)and(JPeek=#10)Then JAdv;
   RowEnd:=True;
   Fin:=True;
  End
   Else
  Begin
   JAdv;
   If Length(S)<255 Then S:=S+C;
  End;
 End;
End;

{ Champ contenant du WKT : analyse directement dans le flux (longueur illimitee) }
Procedure CsvWktField(Delim:Char;Var RowEnd:Boolean);
Var
 C:Char;
 Q,Fin:Boolean;
Begin
 WktBegin;
 RowEnd:=False;
 Fin:=False;
 Q:=False;
 If JPeek='"' Then Begin
  JAdv;
  Q:=True;
 End;
 While Not Fin do Begin
  C:=JPeek;
  If JEof Then Begin
   RowEnd:=True;
   Fin:=True;
  End
   Else
  If Q and(C='"')Then Begin
   JAdv;
   If JPeek='"' Then Begin
    JAdv;
    WktFeed('"');
   End
    Else Q:=False;
  End
   Else
  If Not Q and(C=Delim)Then Begin
   JAdv;
   Fin:=True;
  End
   Else
  If Not Q and((C=#13)or(C=#10))Then Begin
   JAdv;
   If(C=#13)and(JPeek=#10)Then JAdv;
   RowEnd:=True;
   Fin:=True;
  End
   Else
  Begin
   JAdv;
   WktFeed(C);
  End;
 End;
 WktEnd;
End;

Function LoadCSV(Var L:TLayer;Const FN:String):Boolean;
Var
 C:Char;
 Delim:Char;
 Cnt:Array[1..4]of Integer;
 I,Col,NC,XCol,YCol,WCol,Best:Integer;
 Names:Array[1..MaxFields]of String[24];
 FIdx:Array[1..MaxFields]of Integer;
 S,XS,YS,Nm:String;
 RowEnd,Blank:Boolean;
 X,Y:Double;
Const
 Delims:Array[1..4]of Char=(',',';',#9,'|');
Begin
 LoadCSV:=False;
 If Not AllocTmp Then Begin
  LoadErr:='Memoire insuffisante';
  Exit;
 End;
 If Not OpenStream(FN)Then Begin
  LoadErr:='Impossible d''ouvrir '+FN;
  Exit;
 End;
 { Choix du separateur d'apres la ligne d'en-tete }
 For I:=1 to 4 do Cnt[I]:=0;
 C:=JPeek;
 While Not JEof and(C<>#10)and(C<>#13)do Begin
  For I:=1 to 4 do If C=Delims[I]Then Inc(Cnt[I]);
  JAdv;
  C:=JPeek;
 End;
 CloseStream;
 Best:=1;
 For I:=2 to 4 do If Cnt[I]>Cnt[Best]Then Best:=I;
 Delim:=Delims[Best];
 OpenStream(FN);
 If JPeek=#$EF Then Begin
  JAdv;JAdv;JAdv;
 End;
 NC:=0;
 RowEnd:=False;
 While Not RowEnd do Begin
  CsvField(S,Delim,RowEnd);
  If NC<MaxFields Then Begin
   Inc(NC);
   Nm:=Trim(S);
   If Nm='' Then Nm:='field_'+IntStr(NC);
   Names[NC]:=Nm;
   FIdx[NC]:=FieldIndex(L,Names[NC]);
  End;
 End;
 XCol:=0;YCol:=0;WCol:=0;
 For I:=1 to NC do Begin
  If(XCol=0)and ColIs(Names[I],'x,lon,long,longitude,lng,lon_dd,easting,xcoord')Then XCol:=I;
  If(YCol=0)and ColIs(Names[I],'y,lat,latitude,lat_dd,northing,ycoord')Then YCol:=I;
  If(WCol=0)and ColIs(Names[I],'wkt,geom,geometry,the_geom,wkt_geom')Then WCol:=I;
 End;
 If(XCol=0)or(YCol=0)Then Begin
  XCol:=0;YCol:=0;
 End;
 ResetTmp;
 Truncated:=False;
 C:=JPeek;
 While Not JEof do Begin
  ResetTmp;
  XS:='';YS:='';
  Col:=0;
  RowEnd:=False;
  Blank:=False;
  Repeat
   Inc(Col);
   If Col=WCol Then CsvWktField(Delim,RowEnd) Else Begin
    CsvField(S,Delim,RowEnd);
    If(Col=1)and RowEnd and(S='')Then Blank:=True;
    If Col<=NC Then SetAttr(FIdx[Col],S);
    If Col=XCol Then XS:=S;
    If Col=YCol Then YS:=S;
   End;
  Until RowEnd;
  If Not Blank Then Begin
   If(WCol=0)and(XCol>0)Then
    If ParseCoord(XS,X)and ParseCoord(YS,Y)Then Begin
     AddTmpPt(X,Y);
     FinishPart;
     TmpKind:=gkPoint;
    End;
   CommitFeature(L);
  End;
  C:=JPeek;
 End;
 CloseStream;
 GuessCrs(L);
 If L.NF=0 Then Begin
  LoadErr:='Aucune ligne de donnees dans '+FN;
  Exit;
 End;
 LoadCSV:=True;
End;

{ ------------------------------------------------------------------ }
{ Grille ESRI ASCII                                                   }
{ ------------------------------------------------------------------ }

Function AscToken(Var S:String):Boolean;
Var
 C:Char;
Begin
 S:='';
 JSkipWs;
 C:=JPeek;
 While Not JEof and Not(C in[' ',#9,#10,#13])do Begin
  If Length(S)<40 Then S:=S+C;
  JAdv;
  C:=JPeek;
 End;
 AscToken:=S<>'';
End;

Function LoadASC(Var L:TLayer;Const FN:String):Boolean;
Var
 S,Key:String;
 NC,NR,Sx,R,Cc,RWo,RHo:LongInt;
 XLL,YLL,Cell,NoData,V:Double;
 XCenter,YCenter,Pend,HaveCell:Boolean;
 Idx:LongInt;
 First:Boolean;
 NVals:LongInt;
Begin
 LoadASC:=False;
 If Not OpenStream(FN)Then Begin
  LoadErr:='Impossible d''ouvrir '+FN;
  Exit;
 End;
 NC:=0;NR:=0;XLL:=0;YLL:=0;Cell:=1;NoData:=-9999;
 XCenter:=False;YCenter:=False;Pend:=False;HaveCell:=False;NVals:=0;
 While Not Pend and AscToken(Key)do Begin
  Key:=StrLow(Key);
  If Key='ncols' Then Begin AscToken(S);StrToLong(S,NC);End Else
  If Key='nrows' Then Begin AscToken(S);StrToLong(S,NR);End Else
  If Key='xllcorner' Then Begin AscToken(S);StrToReal(S,XLL);End Else
  If Key='xllcenter' Then Begin AscToken(S);StrToReal(S,XLL);XCenter:=True;End Else
  If Key='yllcorner' Then Begin AscToken(S);StrToReal(S,YLL);End Else
  If Key='yllcenter' Then Begin AscToken(S);StrToReal(S,YLL);YCenter:=True;End Else
  If Key='cellsize' Then Begin AscToken(S);StrToReal(S,Cell);HaveCell:=True;End Else
  If Key='nodata_value' Then Begin AscToken(S);StrToReal(S,NoData);End
  Else Pend:=True;
 End;
 If(NC<=0)or(NR<=0)or(Cell<=0)or Not HaveCell or Not Pend Then Begin
  CloseStream;
  LoadErr:='En-tete de grille ASCII invalide : '+FN;
  Exit;
 End;
 If XCenter Then XLL:=XLL-Cell/2;
 If YCenter Then YLL:=YLL-Cell/2;
 Sx:=1;
 While((NC+Sx-1)div Sx)*((NR+Sx-1)div Sx)>MaxRaster do Inc(Sx);
 RWo:=(NC+Sx-1)div Sx;
 RHo:=(NR+Sx-1)div Sx;
 GetMem(L.RData,RWo*RHo*SizeOf(Single));
 If L.RData=Nil Then Begin
  CloseStream;
  LoadErr:='Memoire insuffisante';
  Exit;
 End;
 L.RW:=RWo;L.RH:=RHo;
 For Idx:=0 to RWo*RHo-1 do L.RData^[Idx]:=-1E30;
 L.RMin:=1E300;L.RMax:=-1E300;
 First:=True;
 For R:=0 to NR-1 do
  For Cc:=0 to NC-1 do Begin
   If First and Pend Then Begin
    S:=Key;
    First:=False;
   End
    Else
   Begin
    First:=False;
    If Not AscToken(S)Then S:='';
   End;
   If S<>'' Then Inc(NVals);
   If(R mod Sx=0)and(Cc mod Sx=0)Then Begin
    If StrToReal(S,V)Then Begin
     Idx:=(R div Sx)*RWo+(Cc div Sx);
     If Abs(V-NoData)>1E-9 Then Begin
      L.RData^[Idx]:=V;
      If V<L.RMin Then L.RMin:=V;
      If V>L.RMax Then L.RMax:=V;
     End;
    End;
   End;
  End;
 CloseStream;
 If NVals<NC*NR Then Begin
  FreeMem(L.RData,RWo*RHo*SizeOf(Single));
  L.RData:=Nil;
  L.RW:=0;L.RH:=0;
  LoadErr:='Grille ASCII incomplete : '+FN;
  Exit;
 End;
 If L.RMin>L.RMax Then Begin
  L.RMin:=0;L.RMax:=1;
 End;
 L.Kind:=lkRaster;
 L.RX0:=XLL;
 L.RY0:=YLL+NR*Cell;
 L.RCell:=Cell*Sx;
 L.RNoData:=-1E30;
 L.MinX:=XLL;L.MinY:=YLL;L.MaxX:=XLL+NC*Cell;L.MaxY:=YLL+NR*Cell;
 L.HasExt:=True;
 ApplyPrj(L,FN);
 LoadASC:=True;
End;

{ ------------------------------------------------------------------ }
{ Ajout et suppression de couches                                     }
{ ------------------------------------------------------------------ }

Procedure PickLabelField(Var L:TLayer);
Var
 I:Integer;
 N:String;
Begin
 L.LblFld:=0;
 For I:=1 to L.NFld do Begin
  N:=StrLow(L.Fld[I]);
  If(N='name')or(N='nom')or(N='label')or(N='title')or(N='nam')Then Begin
   L.LblFld:=I;
   Exit;
  End;
 End;
 If L.NFld>0 Then L.LblFld:=1;
End;

Function ExtIsVector(Const E:String):Boolean;
Begin
 ExtIsVector:=(E='.geojson')or(E='.json')or(E='.shp')or(E='.csv')or(E='.txt')or(E='.tsv');
End;

Function AddLayerFromFile(Const FN,LName:String):Integer;
Var
 I:Integer;
 E:String;
 Ok:Boolean;
Begin
 AddLayerFromFile:=0;
 LoadErr:='';
 If NLay>=MaxLayers Then Begin
  LoadErr:='Trop de couches (maximum '+IntStr(MaxLayers)+')';
  Exit;
 End;
 If Not FileExist(FN)Then Begin
  LoadErr:='Fichier introuvable : '+FN;
  Exit;
 End;
 E:=ExtOf(FN);
 If Not(ExtIsVector(E)or(E='.asc'))Then Begin
  LoadErr:='Format non pris en charge ('+E+') ; utiliser GeoJSON, SHP, CSV ou ASC';
  Exit;
 End;
 For I:=NLay downto 1 do Lay[I+1]:=Lay[I];
 InitLayer(Lay[1]);
 Inc(NLay);
 Lay[1].Used:=True;
 If LName<>'' Then Lay[1].Name:=Copy(LName,1,40) Else Lay[1].Name:=Copy(BaseOf(FN),1,40);
 Lay[1].Source:=FN;
 Lay[1].Color:=LayerColors[ColorCount mod 8];
 Inc(ColorCount);
 If E='.asc' Then Ok:=LoadASC(Lay[1],FN) Else
 If(E='.geojson')or(E='.json')Then Ok:=LoadGeoJSON(Lay[1],FN) Else
 If E='.shp' Then Ok:=LoadShapefile(Lay[1],FN)
             Else Ok:=LoadCSV(Lay[1],FN);
 If Not Ok Then Begin
  FreeLayerData(Lay[1]);
  For I:=1 to NLay-1 do Lay[I]:=Lay[I+1];
  Dec(NLay);
  Exit;
 End;
 If Lay[1].Kind=0 Then Lay[1].Kind:=lkVector;
 If Lay[1].Kind=lkVector Then PickLabelField(Lay[1]);
 If NLay=1 Then Begin
  ProjCrsId:=Lay[1].CrsId;
  ProjCRS:=Lay[1].CRS;
 End;
 ActiveLay:=1;
 Dirty:=True;
 AddLayerFromFile:=1;
End;

Procedure RemoveLayerAt(Idx:Integer);
Var
 I:Integer;
Begin
 If(Idx<1)or(Idx>NLay)Then Exit;
 FreeLayerData(Lay[Idx]);
 For I:=Idx to NLay-1 do Lay[I]:=Lay[I+1];
 Dec(NLay);
 If ActiveLay>NLay Then ActiveLay:=NLay;
 If(ActiveLay=0)and(NLay>0)Then ActiveLay:=1;
 Dirty:=True;
End;

Procedure ClearProject;
Begin
 While NLay>0 do RemoveLayerAt(NLay);
 ActiveLay:=0;
 ProjFile:='';
 ProjTitle:='';
 ProjCrsId:=crs4326;
 ProjCRS:='EPSG:4326';
 MeasN:=0;
 Dirty:=False;
End;
{ ------------------------------------------------------------------ }
{ Ecriture GeoJSON                                                    }
{ ------------------------------------------------------------------ }

Function JEsc(Const S:String):String;
Var
 I:Integer;
 R,H:String;
 C:Char;
Begin
 R:='';
 For I:=1 to Length(S)do Begin
  C:=S[I];
  If C='"' Then R:=R+'\"' Else
  If C='\' Then R:=R+'\\' Else
  If C<' ' Then R:=R+' ' Else
  If Ord(C)>127 Then Begin
   H:='0123456789abcdef';
   R:=R+'\u00'+H[(Cp437ToLatin1[Ord(C)]shr 4)+1]+H[(Cp437ToLatin1[Ord(C)]and 15)+1];
  End
   Else R:=R+C;
 End;
 JEsc:=R;
End;

Function LooksNumeric(Const S:String):Boolean;
Var
 V:Double;
Begin
 LooksNumeric:=False;
 If S='' Then Exit;
 If Not(S[1] in['0'..'9','-'])Then Exit;
 If(Length(S)>1)and(S[1]='0')and(S[2] in['0'..'9'])Then Exit;
 If(Length(S)>1)and(S[1]='-')and(S[2]='0')and(Length(S)>2)and(S[3] in['0'..'9'])Then Exit;
 If Pos('E',StrUp(S))>0 Then Exit;
 LooksNumeric:=StrToReal(S,V);
End;

Procedure WritePt(Var T:Text;Const P:TPt);
Begin
 Write(T,'[',NumStr(P.X),',',NumStr(P.Y),']');
End;

Procedure WriteRing(Var T:Text;F:PFeature;P:LongInt);
Var
 A,B,I:LongInt;
Begin
 If P=0 Then A:=0 Else A:=F^.Ends^[P-1];
 B:=F^.Ends^[P];
 Write(T,'[');
 For I:=A to B-1 do Begin
  If I>A Then Write(T,',');
  WritePt(T,F^.Pts^[I]);
 End;
 Write(T,']');
End;

Procedure WriteGeometry(Var T:Text;F:PFeature);
Var
 I,N:LongInt;
 Open:Boolean;
Begin
 If F^.Kind=gkNone Then Begin
  Write(T,'null');
  Exit;
 End;
 Case F^.Kind of
  gkPoint:Begin
   If F^.NPts=1 Then Begin
    Write(T,'{"type":"Point","coordinates":');
    WritePt(T,F^.Pts^[0]);
   End
    Else
   Begin
    Write(T,'{"type":"MultiPoint","coordinates":[');
    For I:=0 to F^.NPts-1 do Begin
     If I>0 Then Write(T,',');
     WritePt(T,F^.Pts^[I]);
    End;
    Write(T,']');
   End;
   Write(T,'}');
  End;
  gkLine:Begin
   If F^.NParts=1 Then Begin
    Write(T,'{"type":"LineString","coordinates":');
    WriteRing(T,F,0);
   End
    Else
   Begin
    Write(T,'{"type":"MultiLineString","coordinates":[');
    For I:=0 to F^.NParts-1 do Begin
     If I>0 Then Write(T,',');
     WriteRing(T,F,I);
    End;
    Write(T,']');
   End;
   Write(T,'}');
  End;
  gkPoly:Begin
   N:=0;
   For I:=0 to F^.NParts-1 do If F^.Outer^[I]=1 Then Inc(N);
   If N<=1 Then Begin
    Write(T,'{"type":"Polygon","coordinates":[');
    For I:=0 to F^.NParts-1 do Begin
     If I>0 Then Write(T,',');
     WriteRing(T,F,I);
    End;
    Write(T,']');
   End
    Else
   Begin
    Write(T,'{"type":"MultiPolygon","coordinates":[');
    Open:=False;
    For I:=0 to F^.NParts-1 do Begin
     If F^.Outer^[I]=1 Then Begin
      If Open Then Write(T,'],');
      Write(T,'[');
      Open:=True;
     End
      Else Write(T,',');
     WriteRing(T,F,I);
    End;
    If Open Then Write(T,']');
    Write(T,']');
   End;
   Write(T,'}');
  End;
 End;
End;

Function WriteGeoJSON(Var L:TLayer;Const FN:String;OnlySel:Boolean):Boolean;
Var
 T:Text;
 I,J:LongInt;
 F:PFeature;
 Comma:Boolean;
 V:String;
Begin
 WriteGeoJSON:=False;
 Assign(T,FN);
 {$I-}Rewrite(T);{$I+}
 If IOResult<>0 Then Exit;
 Write(T,'{"type":"FeatureCollection","name":"',JEsc(L.Name),'",');
 If L.CRS<>'EPSG:4326' Then
  If Copy(L.CRS,1,5)='EPSG:' Then
   Write(T,'"crs":{"type":"name","properties":{"name":"urn:ogc:def:crs:EPSG::',Copy(L.CRS,6,10),'"}},');
 WriteLn(T,'"features":[');
 Comma:=False;
 For I:=1 to L.NF do Begin
  F:=L.Feats^[I];
  If F^.Sel or Not OnlySel Then Begin
   If Comma Then WriteLn(T,',');
   Comma:=True;
   Write(T,'{"type":"Feature","properties":{');
   For J:=1 to L.NFld do Begin
    If J>1 Then Write(T,',');
    V:=FeatAttr(L,F,J);
    Write(T,'"',JEsc(L.Fld[J]),'":');
    If LooksNumeric(V)Then Write(T,V) Else Write(T,'"',JEsc(V),'"');
   End;
   Write(T,'},"geometry":');
   WriteGeometry(T,F);
   Write(T,'}');
  End;
 End;
 WriteLn(T);
 WriteLn(T,']}');
 Close(T);
 WriteGeoJSON:=IOResult=0;
End;

{ ------------------------------------------------------------------ }
{ DXF (format R12 ASCII)                                              }
{ ------------------------------------------------------------------ }

Var
 DxfCnt:LongInt;

Procedure DxfG(Var T:Text;Code:Integer;Const V:String);
Begin
 WriteLn(T,Code:3);
 WriteLn(T,V);
End;

Procedure DxfXYZ(Var T:Text;X,Y:Double);
Begin
 DxfG(T,10,RealStr(X,6));
 DxfG(T,20,RealStr(Y,6));
 DxfG(T,30,'0.0');
End;

Procedure TransformToProj(Var L:TLayer;Var X,Y:Double);
Begin
 If L.CrsId<>ProjCrsId Then XfPt(L.CrsId,ProjCrsId,X,Y);
End;

{ Etendue de la couche dans le SCR du projet }
Procedure LayerProjExtent(Var L:TLayer;Var X1,Y1,X2,Y2:Double);
Var
 A,B,C,D:Double;
Begin
 A:=L.MinX;B:=L.MinY;C:=L.MaxX;D:=L.MaxY;
 TransformToProj(L,A,B);
 TransformToProj(L,C,D);
 X1:=MinD(A,C);X2:=MaxD(A,C);
 Y1:=MinD(B,D);Y2:=MaxD(B,D);
End;

Function ExportDXF(Const FN:String;UseExt:Boolean;EX1,EY1,EX2,EY2:Double):Boolean;
Var
 T:Text;
 I,K,J,A,B,P:LongInt;
 L:Integer;
 F:PFeature;
 LName:String;
 X,Y,MnX,MnY,MxX,MxY:Double;
 Pt:TPt;
 Closed:Boolean;
 FX1,FY1,FX2,FY2:Double;
Begin
 ExportDXF:=False;
 DxfCnt:=0;
 Assign(T,FN);
 {$I-}Rewrite(T);{$I+}
 If IOResult<>0 Then Exit;
 MnX:=1E300;MnY:=1E300;MxX:=-1E300;MxY:=-1E300;
 For L:=1 to NLay do
  If(Lay[L].Kind=lkVector)and Lay[L].HasExt Then Begin
   LayerProjExtent(Lay[L],FX1,FY1,FX2,FY2);
   MnX:=MinD(MnX,FX1);MnY:=MinD(MnY,FY1);MxX:=MaxD(MxX,FX2);MxY:=MaxD(MxY,FY2);
  End;
 If MnX>MxX Then Begin
  MnX:=0;MnY:=0;MxX:=0;MxY:=0;
 End;
 If OptDxfScale<>'' Then DxfG(T,999,'Scale denominator '+OptDxfScale);
 DxfG(T,999,'Exported by QGIS.PAS (clone Pascal)');
 DxfG(T,0,'SECTION');DxfG(T,2,'HEADER');
 DxfG(T,9,'$ACADVER');DxfG(T,1,'AC1009');
 DxfG(T,9,'$DWGCODEPAGE');
 If StrUp(OptDxfEncoding)='UTF-8' Then DxfG(T,3,'ANSI_1252') Else
 If OptDxfEncoding<>'' Then DxfG(T,3,OptDxfEncoding)
                       Else DxfG(T,3,'ANSI_1252');
 DxfG(T,9,'$EXTMIN');DxfXYZ(T,MnX,MnY);
 DxfG(T,9,'$EXTMAX');DxfXYZ(T,MxX,MxY);
 DxfG(T,0,'ENDSEC');
 DxfG(T,0,'SECTION');DxfG(T,2,'TABLES');
 DxfG(T,0,'TABLE');DxfG(T,2,'LTYPE');DxfG(T,70,'1');
 DxfG(T,0,'LTYPE');DxfG(T,2,'CONTINUOUS');DxfG(T,70,'0');DxfG(T,3,'Solid line');
 DxfG(T,72,'65');DxfG(T,73,'0');DxfG(T,40,'0.0');
 DxfG(T,0,'ENDTAB');
 K:=0;
 For L:=1 to NLay do If Lay[L].Kind=lkVector Then Inc(K);
 DxfG(T,0,'TABLE');DxfG(T,2,'LAYER');DxfG(T,70,IntStr(K+1));
 DxfG(T,0,'LAYER');DxfG(T,2,'0');DxfG(T,70,'0');DxfG(T,62,'7');DxfG(T,6,'CONTINUOUS');
 For L:=1 to NLay do
  If Lay[L].Kind=lkVector Then Begin
   DxfG(T,0,'LAYER');DxfG(T,2,Sanitize(Lay[L].Name));DxfG(T,70,'0');
   DxfG(T,62,IntStr(1+(Lay[L].Color mod 7)));DxfG(T,6,'CONTINUOUS');
  End;
 DxfG(T,0,'ENDTAB');
 DxfG(T,0,'ENDSEC');
 DxfG(T,0,'SECTION');DxfG(T,2,'ENTITIES');
 For L:=1 to NLay do
  If Lay[L].Kind=lkVector Then Begin
   LName:=Sanitize(Lay[L].Name);
   For I:=1 to Lay[L].NF do Begin
    F:=Lay[L].Feats^[I];
    If F^.Kind<>gkNone Then Begin
     FX1:=F^.MinX;FY1:=F^.MinY;FX2:=F^.MaxX;FY2:=F^.MaxY;
     TransformToProj(Lay[L],FX1,FY1);
     TransformToProj(Lay[L],FX2,FY2);
     If Not UseExt or((MaxD(FX1,FX2)>=EX1)and(MinD(FX1,FX2)<=EX2)and
                      (MaxD(FY1,FY2)>=EY1)and(MinD(FY1,FY2)<=EY2))Then Begin
      If F^.Kind=gkPoint Then Begin
       For J:=0 to F^.NPts-1 do Begin
        X:=F^.Pts^[J].X;Y:=F^.Pts^[J].Y;
        TransformToProj(Lay[L],X,Y);
        DxfG(T,0,'POINT');DxfG(T,8,LName);DxfXYZ(T,X,Y);
        Inc(DxfCnt);
       End;
      End
       Else
      Begin
       For P:=0 to F^.NParts-1 do Begin
        If P=0 Then A:=0 Else A:=F^.Ends^[P-1];
        B:=F^.Ends^[P];
        Closed:=F^.Kind=gkPoly;
        DxfG(T,0,'POLYLINE');DxfG(T,8,LName);DxfG(T,66,'1');
        If Closed Then DxfG(T,70,'1') Else DxfG(T,70,'0');
        For J:=A to B-1 do Begin
         Pt:=F^.Pts^[J];
         X:=Pt.X;Y:=Pt.Y;
         TransformToProj(Lay[L],X,Y);
         DxfG(T,0,'VERTEX');DxfG(T,8,LName);DxfXYZ(T,X,Y);
        End;
        DxfG(T,0,'SEQEND');DxfG(T,8,LName);
        Inc(DxfCnt);
       End;
      End;
     End;
    End;
   End;
  End;
 DxfG(T,0,'ENDSEC');
 DxfG(T,0,'EOF');
 Close(T);
 ExportDXF:=IOResult=0;
End;

{ ------------------------------------------------------------------ }
{ Ecriture PNG et BMP de la surface hors ecran                        }
{ ------------------------------------------------------------------ }

Const
 VgaPal:Array[0..15,0..2]of Byte=(
  (0,0,0),(0,0,170),(0,170,0),(0,170,170),(170,0,0),(170,0,170),(170,85,0),(170,170,170),
  (85,85,85),(85,85,255),(85,255,85),(85,255,255),(255,85,85),(255,85,255),(255,255,85),(255,255,255));
 PngBlk=32768;

Var
 CrcTab:Array[0..255]of LongInt;
 CrcReady:Boolean;
 PngBuf:^TByteArr;

Procedure CrcInit;
Var
 N,K:Integer;
 C:LongInt;
Begin
 For N:=0 to 255 do Begin
  C:=N;
  For K:=1 to 8 do
   If(C and 1)<>0 Then C:=(C shr 1)xor(-306674912)
                  Else C:=C shr 1;
  CrcTab[N]:=C;
 End;
 CrcReady:=True;
End;

Function CrcUpdate(Crc:LongInt;Var Buf;Len:LongInt):LongInt;
Var
 I:LongInt;
 B:^TByteArr;
Begin
 B:=@Buf;
 For I:=0 to Len-1 do Crc:=CrcTab[(Crc xor B^[I])and 255]xor(Crc shr 8);
 CrcUpdate:=Crc;
End;

Procedure PutBE(Var A:Array of Byte;V:LongInt);
Begin
 A[0]:=(V shr 24)and 255;
 A[1]:=(V shr 16)and 255;
 A[2]:=(V shr 8)and 255;
 A[3]:=V and 255;
End;

Procedure PngChunk(Var F:File;Typ:String;Var Data;Len:LongInt);
Var
 H:Array[0..3]of Byte;
 Crc:LongInt;
Begin
 PutBE(H,Len);
 BlockWrite(F,H,4);
 BlockWrite(F,Typ[1],4);
 Crc:=CrcUpdate(-1,Typ[1],4);
 If Len>0 Then Begin
  BlockWrite(F,Data,Len);
  Crc:=CrcUpdate(Crc,Data,Len);
 End;
 PutBE(H,Crc xor(-1));
 BlockWrite(F,H,4);
End;

Function RawByte(I:LongInt):Byte;
Var
 Row,Col:LongInt;
Begin
 Row:=I div(OffW+1);
 Col:=I mod(OffW+1);
 If Col=0 Then RawByte:=0 Else RawByte:=OffBuf^[Row*OffW+Col-1];
End;

Function SavePNG(Const FN:String):Boolean;
Var
 F:File;
 Sig:Array[0..7]of Byte;
 Ihdr:Array[0..12]of Byte;
 Pal:Array[0..47]of Byte;
 I,J,Raw,Nb,Pos,N,Crc,IdatLen:LongInt;
 A,B:LongInt;
 H:Array[0..4]of Byte;
 Z:Array[0..3]of Byte;
 TagI:String;
Begin
 SavePNG:=False;
 If Not CrcReady Then CrcInit;
 Assign(F,FN);
 {$I-}Rewrite(F,1);{$I+}
 If IOResult<>0 Then Exit;
 Sig[0]:=137;Sig[1]:=80;Sig[2]:=78;Sig[3]:=71;Sig[4]:=13;Sig[5]:=10;Sig[6]:=26;Sig[7]:=10;
 BlockWrite(F,Sig,8);
 PutBE(Ihdr,OffW);
 Z[0]:=0;
 PutBE(Z,OffH);
 Move(Z,Ihdr[4],4);
 Ihdr[8]:=8;Ihdr[9]:=3;Ihdr[10]:=0;Ihdr[11]:=0;Ihdr[12]:=0;
 PngChunk(F,'IHDR',Ihdr,13);
 For I:=0 to 15 do
  For J:=0 to 2 do Pal[I*3+J]:=VgaPal[I,J];
 PngChunk(F,'PLTE',Pal,48);
 Raw:=(OffW+1)*OffH;
 Nb:=(Raw+PngBlk-1)div PngBlk;
 IdatLen:=2+Raw+5*Nb+4;
 A:=1;B:=0;
 For I:=0 to Raw-1 do Begin
  A:=(A+RawByte(I))mod 65521;
  B:=(B+A)mod 65521;
 End;
 PutBE(Z,IdatLen);
 BlockWrite(F,Z,4);
 TagI:='IDAT';
 BlockWrite(F,TagI[1],4);
 Crc:=CrcUpdate(-1,TagI[1],4);
 H[0]:=$78;H[1]:=1;
 BlockWrite(F,H,2);
 Crc:=CrcUpdate(Crc,H,2);
 Pos:=0;
 GetMem(PngBuf,PngBlk);
 While Pos<Raw do Begin
  N:=Raw-Pos;
  If N>PngBlk Then N:=PngBlk;
  If Pos+N>=Raw Then H[0]:=1 Else H[0]:=0;
  H[1]:=N and 255;H[2]:=(N shr 8)and 255;
  H[3]:=(not N)and 255;H[4]:=((not N)shr 8)and 255;
  BlockWrite(F,H,5);
  Crc:=CrcUpdate(Crc,H,5);
  For I:=0 to N-1 do PngBuf^[I]:=RawByte(Pos+I);
  BlockWrite(F,PngBuf^,N);
  Crc:=CrcUpdate(Crc,PngBuf^,N);
  Pos:=Pos+N;
 End;
 FreeMem(PngBuf,PngBlk);
 PutBE(Z,(B shl 16)or A);
 BlockWrite(F,Z,4);
 Crc:=CrcUpdate(Crc,Z,4);
 PutBE(Z,Crc xor(-1));
 BlockWrite(F,Z,4);
 PngChunk(F,'IEND',Z,0);
 Close(F);
 SavePNG:=IOResult=0;
End;

Function SaveBMP(Const FN:String):Boolean;
Var
 F:File;
 Hd:Array[0..53]of Byte;
 Pal:Array[0..255,0..3]of Byte;
 Row:Array[0..4095]of Byte;
 I,X,Y,Stride,Size:LongInt;
 Procedure LE(Off,V:LongInt);
 Begin
  Hd[Off]:=V and 255;
  Hd[Off+1]:=(V shr 8)and 255;
  Hd[Off+2]:=(V shr 16)and 255;
  Hd[Off+3]:=(V shr 24)and 255;
 End;
Begin
 SaveBMP:=False;
 If OffW>4092 Then Exit;
 Stride:=((OffW+3)div 4)*4;
 Size:=54+1024+Stride*OffH;
 FillChar(Hd,SizeOf(Hd),0);
 Hd[0]:=Ord('B');Hd[1]:=Ord('M');
 LE(2,Size);LE(10,54+1024);
 LE(14,40);LE(18,OffW);LE(22,OffH);
 Hd[26]:=1;Hd[28]:=8;
 LE(34,Stride*OffH);LE(46,16);
 FillChar(Pal,SizeOf(Pal),0);
 For I:=0 to 15 do Begin
  Pal[I,0]:=VgaPal[I,2];Pal[I,1]:=VgaPal[I,1];Pal[I,2]:=VgaPal[I,0];
 End;
 Assign(F,FN);
 {$I-}Rewrite(F,1);{$I+}
 If IOResult<>0 Then Exit;
 BlockWrite(F,Hd,54);
 BlockWrite(F,Pal,1024);
 FillChar(Row,SizeOf(Row),0);
 For Y:=OffH-1 downto 0 do Begin
  For X:=0 to OffW-1 do Row[X]:=OffBuf^[Y*OffW+X];
  BlockWrite(F,Row,Stride);
 End;
 Close(F);
 SaveBMP:=IOResult=0;
End;
{ ------------------------------------------------------------------ }
{ Profil, reglages et lancement de commandes externes                 }
{ ------------------------------------------------------------------ }

Var
 LoadWarn:String;
 PExtOk:Boolean;
 PEx1,PEy1,PEx2,PEy2:Double;
 XBuf:PByteBuf;
 XLen:LongInt;

Procedure EnsureDirs;
Begin
 MakeDirs(TmpDir);
 MakeDirs(ProcDir);
 MakeDirs(DirOf(SettingsFile));
End;

Procedure SetupProfile;
Var
 Root,Prof:String;
Begin
 If OptConfigPath<>'' Then Root:=JoinPath(OptConfigPath,'profiles') Else
 If OptProfilesPath<>'' Then Root:=OptProfilesPath Else Begin
  {$IFDEF UNIX}
  If GetEnv('HOME')<>'' Then Root:=JoinPath(GetEnv('HOME'),'.local/share/QGIS/QGIS3/profiles')
                        Else Root:=JoinPath(DirOf(ParamStr(0)),'QGIS3/profiles');
  {$ELSE}
  If GetEnv('APPDATA')<>'' Then Root:=JoinPath(GetEnv('APPDATA'),'QGIS\QGIS3\profiles')
                           Else Root:=JoinPath(DirOf(ParamStr(0)),'QGIS3\profiles');
  {$ENDIF}
 End;
 If OptProfile<>'' Then Prof:=OptProfile Else Prof:='default';
 ProfileDir:=JoinPath(Root,Prof);
 If OptOptionsPath<>'' Then SettingsFile:=JoinPath(JoinPath(OptOptionsPath,'QGIS'),'QGIS3.ini')
                       Else SettingsFile:=JoinPath(JoinPath(ProfileDir,'QGIS'),'QGIS3.ini');
 TmpDir:=JoinPath(ProfileDir,'tmp');
 ProcDir:=JoinPath(ProfileDir,'process');
End;

Procedure LoadSettings;
Var
 T:Text;
 S,K,V:String;
 P,I,E:Integer;
Begin
 NRecent:=0;
 Assign(T,SettingsFile);
 {$I-}Reset(T);{$I+}
 If IOResult<>0 Then Exit;
 While Not Eof(T)do Begin
  {$I-}ReadLn(T,S);{$I+}
  If IOResult<>0 Then S:='';
  P:=Pos('=',S);
  If P>1 Then Begin
   K:=StrLow(Trim(Copy(S,1,P-1)));
   V:=Trim(Copy(S,P+1,255));
   If K='lastdir' Then LastDir:=V Else
   If K='background' Then Begin
    Val(V,I,E);
    If(E=0)and(I>=0)and(I<=15)Then Background:=I;
   End
    Else
   If K='labels' Then ShowLabels:=V='1' Else
   If K='grid' Then ShowGrid:=V='1' Else
   If K='panel' Then ShowPanel:=V<>'0' Else
   If(Copy(K,1,6)='recent')and(NRecent<5)and(V<>'')Then Begin
    Inc(NRecent);
    Recent[NRecent]:=V;
   End;
  End;
 End;
 Close(T);
End;

Procedure SaveSettings;
Var
 T:Text;
 I:Integer;
Begin
 EnsureDirs;
 Assign(T,SettingsFile);
 {$I-}Rewrite(T);{$I+}
 If IOResult<>0 Then Exit;
 WriteLn(T,'[General]');
 WriteLn(T,'LastDir=',LastDir);
 WriteLn(T,'Background=',Background);
 If ShowLabels Then WriteLn(T,'Labels=1') Else WriteLn(T,'Labels=0');
 If ShowGrid Then WriteLn(T,'Grid=1') Else WriteLn(T,'Grid=0');
 If ShowPanel Then WriteLn(T,'Panel=1') Else WriteLn(T,'Panel=0');
 For I:=1 to NRecent do WriteLn(T,'Recent',I,'=',Recent[I]);
 Close(T);
 If IOResult<>0 Then;
End;

Procedure AddRecent(Const FN:String);
Var
 I,J:Integer;
Begin
 For I:=1 to NRecent do
  If Recent[I]=FN Then Begin
   For J:=I downto 2 do Recent[J]:=Recent[J-1];
   Recent[1]:=FN;
   Exit;
  End;
 If NRecent<5 Then Inc(NRecent);
 For J:=NRecent downto 2 do Recent[J]:=Recent[J-1];
 Recent[1]:=FN;
End;

{ ------------------------------------------------------------------ }
{ Commandes externes (QGIS_PROCESS, interpreteur Python)              }
{ ------------------------------------------------------------------ }

Function FindQgisProcess:String;
Var
 Nm,P:String;
Begin
 {$IFDEF UNIX}
 Nm:='qgis_process';
 {$ELSE}
 Nm:='qgis_process.exe';
 {$ENDIF}
 FindQgisProcess:='';
 P:=JoinPath(DirOf(ParamStr(0)),Nm);
 If FileExist(P)Then Begin
  FindQgisProcess:=P;
  Exit;
 End;
 P:=FullPath(Nm);
 If FileExist(P)Then Begin
  FindQgisProcess:=P;
  Exit;
 End;
 P:=FSearch(Nm,GetEnv('PATH'));
 If P<>'' Then FindQgisProcess:=FullPath(P);
End;

Var
 ScriptT:Text;

{ Les commandes sont ecrites dans un fichier de commandes (.sh ou .bat) afin de
  ne pas etre limitees a 255 caracteres }
Procedure ScriptOpen;
Var
 Script:String;
Begin
 EnsureDirs;
 {$IFDEF UNIX}
 Script:=JoinPath(TmpDir,'run.sh');
 {$ELSE}
 Script:=JoinPath(TmpDir,'run.bat');
 {$ENDIF}
 Assign(ScriptT,Script);
 {$I-}Rewrite(ScriptT);{$I+}
 If IOResult<>0 Then Exit;
 {$IFDEF UNIX}
 WriteLn(ScriptT,'#!/bin/sh');
 {$ELSE}
 WriteLn(ScriptT,'@echo off');
 {$ENDIF}
End;

Procedure ScriptAdd(Const S:String);
Begin
 Write(ScriptT,S);
End;

{ Execute le fichier de commandes ; la sortie est redirigee dans OutFile }
Function ScriptRun(Const OutFile:String):Integer;
Var
 Script:String;
Begin
 {$IFDEF UNIX}
 Script:=JoinPath(TmpDir,'run.sh');
 {$ELSE}
 Script:=JoinPath(TmpDir,'run.bat');
 {$ENDIF}
 WriteLn(ScriptT,' > "',OutFile,'" 2>&1');
 Close(ScriptT);
 If IOResult<>0 Then;
 SwapVectors;
 {$IFDEF UNIX}
 Exec('/bin/sh','"'+Script+'"');
 {$ELSE}
 Exec(GetEnv('COMSPEC'),'/C "'+Script+'"');
 {$ENDIF}
 SwapVectors;
 If DosError<>0 Then ScriptRun:=-1 Else ScriptRun:=DosExitCode;
End;

Function RunShell(Const Cmd,OutFile:String):Integer;
Begin
 ScriptOpen;
 ScriptAdd(Cmd);
 RunShell:=ScriptRun(OutFile);
End;

Function QuoteArg(Const S:String):String;
Begin
 If(Pos(' ',S)>0)or(S='')Then QuoteArg:='"'+S+'"' Else QuoteArg:=S;
End;

Function QpRun(Const Args,OutFile:String):Integer;
Begin
 If QPath='' Then Begin
  QpRun:=-1;
  Exit;
 End;
 QpRun:=RunShell(QuoteArg(QPath)+' '+Args,OutFile);
End;

{ ------------------------------------------------------------------ }
{ Listes de lignes de texte                                           }
{ ------------------------------------------------------------------ }

Procedure FreeLines(Var P:PLineList;Var N:Integer);
Var
 I:Integer;
Begin
 If P=Nil Then Exit;
 For I:=1 to N do FreeStr(P^[I]);
 FreeMem(P,MaxLines*SizeOf(PStr));
 P:=Nil;
 N:=0;
End;

Procedure NewLines(Var P:PLineList;Var N:Integer);
Begin
 GetMem(P,MaxLines*SizeOf(PStr));
 N:=0;
End;

Procedure AddLine(P:PLineList;Var N:Integer;Const S:String);
Begin
 If N>=MaxLines Then Exit;
 Inc(N);
 P^[N]:=NewStr(S);
End;

{ Remplace les tabulations et les caracteres hors ASCII }
Function CleanLine(Const S:String):String;
Var
 I:Integer;
 R:String;
 C:Char;
Begin
 R:='';
 For I:=1 to Length(S)do Begin
  C:=S[I];
  If C=#9 Then Begin
   Repeat
    R:=R+' ';
   Until(Length(R)mod 8=0)or(Length(R)>=250);
  End
   Else
  If C=#13 Then
   Else
  If(C<' ')Then R:=R+' ' Else
  If Ord(C)>126 Then R:=R+'?' Else R:=R+C;
  If Length(R)>250 Then Begin
   CleanLine:=R;
   Exit;
  End;
 End;
 CleanLine:=R;
End;

Procedure LoadFileLines(Const FN:String;Var P:PLineList;Var N:Integer);
Var
 T:Text;
 S:String;
Begin
 NewLines(P,N);
 Assign(T,FN);
 {$I-}Reset(T);{$I+}
 If IOResult<>0 Then Exit;
 While Not Eof(T)and(N<MaxLines)do Begin
  {$I-}ReadLn(T,S);{$I+}
  If IOResult<>0 Then S:='';
  AddLine(P,N,CleanLine(S));
 End;
 Close(T);
End;

{ Coupe un texte (lignes separees par '|') pour tenir dans Width caracteres }
Procedure TextToLines(Const Txt:String;Width:Integer;Var P:PLineList;Var N:Integer);
Var
 I,Last:Integer;
 Cur,Word:String;
 Procedure Flush;
 Begin
  AddLine(P,N,Cur);
  Cur:='';
 End;
Begin
 NewLines(P,N);
 Cur:='';
 Word:='';
 For I:=1 to Length(Txt)+1 do Begin
  If I>Length(Txt)Then Last:=1 Else Last:=0;
  If Last=1 Then Begin
   If Length(Cur)+Length(Word)>Width Then Flush;
   Cur:=Cur+Word;
   Flush;
  End
   Else
  If Txt[I]='|' Then Begin
   If Length(Cur)+Length(Word)>Width Then Flush;
   Cur:=Cur+Word;
   Word:='';
   Flush;
  End
   Else
  If Txt[I]=' ' Then Begin
   If Length(Cur)+Length(Word)>Width Then Flush;
   Cur:=Cur+Word+' ';
   Word:='';
  End
   Else
  Begin
   Word:=Word+Txt[I];
   If Length(Word)>Width Then Begin
    If Cur<>'' Then Flush;
    Cur:=Word;
    Flush;
    Word:='';
   End;
  End;
 End;
End;

{ ------------------------------------------------------------------ }
{ Projet .qgs                                                         }
{ ------------------------------------------------------------------ }

Function XmlEsc(Const S:String):String;
Var
 R:String;
Begin
 R:=ReplaceAll(S,'&','&amp;');
 R:=ReplaceAll(R,'<','&lt;');
 R:=ReplaceAll(R,'>','&gt;');
 R:=ReplaceAll(R,'"','&quot;');
 XmlEsc:=R;
End;

Function XmlUnesc(Const S:String):String;
Var
 R:String;
Begin
 R:=ReplaceAll(S,'&lt;','<');
 R:=ReplaceAll(R,'&gt;','>');
 R:=ReplaceAll(R,'&quot;','"');
 R:=ReplaceAll(R,'&apos;','''');
 R:=ReplaceAll(R,'&amp;','&');
 XmlUnesc:=R;
End;

Function RelPath(Const Dir,Src:String):String;
Var
 P:String;
Begin
 P:=JoinPath(Dir,'');
 If(Dir<>'')and(StrLow(Copy(Src,1,Length(P)))=StrLow(P))Then RelPath:='./'+Copy(Src,Length(P)+1,255)
                                                         Else RelPath:=Src;
End;

Function GeomName(G:Byte):String;
Begin
 Case G of
  gkPoint:GeomName:='Point';
  gkLine:GeomName:='Line';
  gkPoly:GeomName:='Polygon';
  Else GeomName:='No Geometry';
 End;
End;

Function SaveProject(Const FN:String):Boolean;
Var
 T:Text;
 I:Integer;
 Dir,Id:String;
 X1,Y1,X2,Y2:Double;
 Function LId(I:Integer):String;
 Begin
  LId:=Sanitize(Lay[I].Name)+'_'+IntStr(I);
 End;
Begin
 SaveProject:=False;
 Dir:=DirOf(FullPath(FN));
 Assign(T,FN);
 {$I-}Rewrite(T);{$I+}
 If IOResult<>0 Then Exit;
 WriteLn(T,'<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>');
 WriteLn(T,'<qgis projectname="',XmlEsc(ProjTitle),'" version="',QgisCompat,'.0-Pascal">');
 WriteLn(T,'  <title>',XmlEsc(ProjTitle),'</title>');
 WriteLn(T,'  <projectCrs>');
 WriteLn(T,'    <spatialrefsys><authid>',ProjCRS,'</authid></spatialrefsys>');
 WriteLn(T,'  </projectCrs>');
 WriteLn(T,'  <layer-tree-group>');
 For I:=1 to NLay do Begin
  Write(T,'    <layer-tree-layer id="',LId(I),'" name="',XmlEsc(Lay[I].Name),'" source="',XmlEsc(RelPath(Dir,Lay[I].Source)),'" providerKey=');
  If Lay[I].Kind=lkRaster Then Write(T,'"gdal"') Else Write(T,'"ogr"');
  If Lay[I].Visible Then WriteLn(T,' checked="Qt::Checked" expanded="1"/>')
                    Else WriteLn(T,' checked="Qt::Unchecked" expanded="1"/>');
 End;
 WriteLn(T,'  </layer-tree-group>');
 X1:=CX-UPP*(ClipR-ClipL)/2;X2:=CX+UPP*(ClipR-ClipL)/2;
 Y1:=CY-UPP*(ClipB-ClipT)/2;Y2:=CY+UPP*(ClipB-ClipT)/2;
 WriteLn(T,'  <mapcanvas name="theMapCanvas">');
 WriteLn(T,'    <units>',Ord(ProjCrsId=crs3857),'</units>');
 WriteLn(T,'    <extent><xmin>',NumStr(X1),'</xmin><ymin>',NumStr(Y1),'</ymin><xmax>',NumStr(X2),'</xmax><ymax>',NumStr(Y2),'</ymax></extent>');
 WriteLn(T,'    <destinationsrs><spatialrefsys><authid>',ProjCRS,'</authid></spatialrefsys></destinationsrs>');
 WriteLn(T,'  </mapcanvas>');
 WriteLn(T,'  <projectlayers>');
 For I:=1 to NLay do Begin
  Id:=LId(I);
  If Lay[I].Kind=lkRaster Then WriteLn(T,'    <maplayer type="raster">')
  Else WriteLn(T,'    <maplayer type="vector" geometry="',GeomName(Lay[I].GType),'">');
  WriteLn(T,'      <id>',Id,'</id>');
  WriteLn(T,'      <datasource>',XmlEsc(RelPath(Dir,Lay[I].Source)),'</datasource>');
  WriteLn(T,'      <layername>',XmlEsc(Lay[I].Name),'</layername>');
  WriteLn(T,'      <srs><spatialrefsys><authid>',Lay[I].CRS,'</authid></spatialrefsys></srs>');
  If Lay[I].Kind=lkRaster Then WriteLn(T,'      <provider>gdal</provider>')
                          Else WriteLn(T,'      <provider encoding="UTF-8">ogr</provider>');
  WriteLn(T,'      <customproperties><Option type="Map"><Option name="pascal_color" value="',Lay[I].Color,'" type="QString"/></Option></customproperties>');
  WriteLn(T,'    </maplayer>');
 End;
 WriteLn(T,'  </projectlayers>');
 WriteLn(T,'</qgis>');
 Close(T);
 SaveProject:=IOResult=0;
End;

Function ReadWhole(Const FN:String):Boolean;
Var
 F:File;
 Got:LongInt;
 Sz:LongInt;
Begin
 ReadWhole:=False;
 Sz:=FileSizeOf(FN);
 If(Sz<=0)or(Sz>SBufMax)Then Begin
  LoadErr:='Fichier projet vide ou trop gros';
  Exit;
 End;
 GetMem(XBuf,Sz+1);
 Assign(F,FN);
 {$I-}Reset(F,1);{$I+}
 If IOResult<>0 Then Begin
  FreeMem(XBuf,Sz+1);
  XBuf:=Nil;
  Exit;
 End;
 BlockRead(F,XBuf^,Sz,Got);
 Close(F);
 XBuf^[Sz]:=0;
 XLen:=Got;
 ReadWhole:=True;
End;

Function XFind(Const Pat:String;From,Upto:LongInt):LongInt;
Var
 I,J,N:LongInt;
 Ok:Boolean;
Begin
 XFind:=-1;
 N:=Length(Pat);
 If Upto>XLen Then Upto:=XLen;
 I:=From;
 While I<=Upto-N do Begin
  If XBuf^[I]=Ord(Pat[1])Then Begin
   Ok:=True;
   J:=2;
   While Ok and(J<=N)do Begin
    If XBuf^[I+J-1]<>Ord(Pat[J])Then Ok:=False;
    Inc(J);
   End;
   If Ok Then Begin
    XFind:=I;
    Exit;
   End;
  End;
  Inc(I);
 End;
End;

Function XSub(A,B:LongInt):String;
Var
 S:String;
 I:LongInt;
Begin
 S:='';
 If B-A>255 Then B:=A+255;
 For I:=A to B-1 do S:=S+Chr(XBuf^[I]);
 XSub:=S;
End;

{ Contenu de <Tag>...</Tag> dans [From,Upto] }
Function XText(Const Tag:String;From,Upto:LongInt):String;
Var
 A,B:LongInt;
Begin
 XText:='';
 A:=XFind('<'+Tag+'>',From,Upto);
 If A<0 Then Exit;
 A:=A+Length(Tag)+2;
 B:=XFind('</'+Tag+'>',A,Upto);
 If B<0 Then Exit;
 XText:=XmlUnesc(XSub(A,B));
End;

{ Valeur de l'attribut Name dans l'etiquette ouvrante comprise dans [From,Upto] }
Function XAttr(From,Upto:LongInt;Const Name:String):String;
Var
 A,B:LongInt;
Begin
 XAttr:='';
 A:=XFind(' '+Name+'="',From,Upto);
 If A<0 Then Exit;
 A:=A+Length(Name)+3;
 B:=XFind('"',A,Upto);
 If B<0 Then Exit;
 XAttr:=XmlUnesc(XSub(A,B));
End;

Function ResolveSource(Const Src,Dir:String):String;
Var
 S:String;
 P:Integer;
Begin
 S:=Src;
 P:=Pos('|',S);
 If P>0 Then S:=Copy(S,1,P-1);
 P:=Pos('?',S);
 If P>0 Then S:=Copy(S,1,P-1);
 If Copy(S,1,8)='file:///' Then Begin
  {$IFDEF UNIX}
  S:=Copy(S,8,255);
  {$ELSE}
  S:=Copy(S,9,255);
  {$ENDIF}
 End
  Else If Copy(S,1,7)='file://' Then S:=Copy(S,8,255);
 If Copy(S,1,2)='./' Then S:=Copy(S,3,255);
 If Not IsAbsPath(S)Then S:=JoinPath(Dir,S);
 ResolveSource:=S;
End;

Function LoadProject(Const FN:String):Boolean;
Type
 TInfo=Record
  Id:String[60];
  Name:String[60];
  Src:String;
  Chk:Boolean;
 End;
Var
 Dir,S,Authid,Id:String;
 Tree:Array[1..MaxLayers]of TInfo;
 NT,NM,I,J,K,Skipped,Loaded:Integer;
 Ml:Array[1..MaxLayers]of Record
  Id:String[60];
  Name:String[60];
  Src:String;
  Col:Integer;
 End;
 P,Q,E,Pe:LongInt;
 Code:Integer;
 Order:Array[1..MaxLayers]of Integer;
 NO:Integer;
Begin
 LoadProject:=False;
 LoadErr:='';
 LoadWarn:='';
 PExtOk:=False;
 If ExtOf(FN)='.qgz' Then Begin
  LoadErr:='Les projets compresses .qgz ne sont pas pris en charge ; enregistrer en .qgs';
  Exit;
 End;
 If Not FileExist(FN)Then Begin
  LoadErr:='Fichier introuvable : '+FN;
  Exit;
 End;
 If Not ReadWhole(FN)Then Begin
  If LoadErr=''Then LoadErr:='Lecture impossible : '+FN;
  Exit;
 End;
 If XFind('<qgis',0,XLen)<0 Then Begin
  FreeMem(XBuf,XLen+1);XBuf:=Nil;
  LoadErr:='Ce fichier n''est pas un projet QGIS : '+FN;
  Exit;
 End;
 ClearProject;
 Dir:=DirOf(FullPath(FN));
 ProjTitle:=XText('title',0,XLen);
 P:=XFind('<projectCrs>',0,XLen);
 If P>=0 Then Begin
  Authid:=XText('authid',P,XLen);
  If Authid<>'' Then Begin
   ProjCRS:=Copy(Authid,1,24);
   ProjCrsId:=CrsIdOf(Authid);
  End;
 End;
 { Arbre des couches }
 NT:=0;
 P:=0;
 Repeat
  P:=XFind('<layer-tree-layer ',P,XLen);
  If P>=0 Then Begin
   Pe:=XFind('>',P,XLen);
   If Pe<0 Then P:=-1 Else Begin
    If NT<MaxLayers Then Begin
     Inc(NT);
     Tree[NT].Id:=XAttr(P,Pe,'id');
     Tree[NT].Name:=XAttr(P,Pe,'name');
     Tree[NT].Src:=XAttr(P,Pe,'source');
     Tree[NT].Chk:=Pos('Unchecked',XAttr(P,Pe,'checked'))=0;
    End;
    P:=Pe;
   End;
  End;
 Until P<0;
 { Couches du projet }
 NM:=0;
 P:=0;
 Repeat
  P:=XFind('<maplayer',P,XLen);
  If P>=0 Then Begin
   Pe:=XFind('</maplayer>',P,XLen);
   If Pe<0 Then P:=-1 Else Begin
    If NM<MaxLayers Then Begin
     Inc(NM);
     Ml[NM].Id:=XText('id',P,Pe);
     Ml[NM].Name:=XText('layername',P,Pe);
     Ml[NM].Src:=XText('datasource',P,Pe);
     Ml[NM].Col:=-1;
     Q:=XFind('name="pascal_color" value="',P,Pe);
     If Q>=0 Then Begin
      Q:=Q+27;
      E:=XFind('"',Q,Pe);
      If E>Q Then Begin
       Val(XSub(Q,E),Ml[NM].Col,Code);
       If Code<>0 Then Ml[NM].Col:=-1;
      End;
     End;
    End;
    P:=Pe;
   End;
  End;
 Until P<0;
 { Etendue sauvegardee }
 P:=XFind('<mapcanvas',0,XLen);
 If P>=0 Then Begin
  PExtOk:=True;
  S:=XText('xmin',P,XLen);If Not StrToReal(S,PEx1)Then PExtOk:=False;
  S:=XText('ymin',P,XLen);If Not StrToReal(S,PEy1)Then PExtOk:=False;
  S:=XText('xmax',P,XLen);If Not StrToReal(S,PEx2)Then PExtOk:=False;
  S:=XText('ymax',P,XLen);If Not StrToReal(S,PEy2)Then PExtOk:=False;
 End;
 { Ordre de chargement : du bas vers le haut de l'arbre }
 NO:=0;
 If NT>0 Then Begin
  For I:=NT downto 1 do Begin
   K:=0;
   For J:=1 to NM do If Ml[J].Id=Tree[I].Id Then K:=J;
   If K>0 Then Begin
    Inc(NO);
    Order[NO]:=K;
   End;
  End;
 End;
 If NO=0 Then
  For I:=NM downto 1 do Begin
   Inc(NO);
   Order[NO]:=I;
  End;
 Skipped:=0;
 Loaded:=0;
 For I:=1 to NO do Begin
  K:=Order[I];
  S:=ResolveSource(Ml[K].Src,Dir);
  Id:=Ml[K].Name;
  If AddLayerFromFile(S,Id)>0 Then Begin
   Inc(Loaded);
   If Ml[K].Col>=0 Then Lay[1].Color:=Ml[K].Col;
   For J:=1 to NT do
    If Tree[J].Id=Ml[K].Id Then Lay[1].Visible:=Tree[J].Chk;
  End
   Else
  Begin
   Inc(Skipped);
   If LoadWarn='' Then LoadWarn:=LoadErr;
  End;
 End;
 FreeMem(XBuf,XLen+1);
 XBuf:=Nil;
 ProjFile:=FN;
 Dirty:=False;
 If Skipped>0 Then LoadWarn:=IntStr(Skipped)+' couche(s) non chargee(s) : '+LoadWarn;
 If NLay>0 Then ActiveLay:=1;
 LoadProject:=True;
End;
{ ------------------------------------------------------------------ }
{ Vue cartographique                                                  }
{ ------------------------------------------------------------------ }

Var
 VCX,VCY:Double;           { Centre de la fenetre en pixels }
 VX1,VY1,VX2,VY2:Double;   { Etendue visible dans le SCR du projet }
 ScPts:PPtArr;
 ScCap:LongInt;
 ScEnds:PLongArr;
 ScEndCap:LongInt;
 ScN,ScParts:LongInt;
 InHistMove:Boolean;

Procedure UpdateView;
Var
 W,H:Double;
Begin
 W:=ClipR-ClipL+1;
 H:=ClipB-ClipT+1;
 VCX:=ClipL+W/2;
 VCY:=ClipT+H/2;
 VX1:=CX-(W/2)*UPP;VX2:=CX+(W/2)*UPP;
 VY1:=CY-(H/2)*UPP;VY2:=CY+(H/2)*UPP;
End;

Procedure SetupCanvas;
Begin
 If ShowPanel Then SetClip(PanelW,MenuH+ToolH,ScrW-1,ScrH-StatH-1)
              Else SetClip(0,MenuH+ToolH,ScrW-1,ScrH-StatH-1);
 UpdateView;
End;

Function MapToPxX(X:Double):Double;
Begin
 MapToPxX:=VCX+(X-CX)/UPP;
End;

Function MapToPxY(Y:Double):Double;
Begin
 MapToPxY:=VCY-(Y-CY)/UPP;
End;

Function PxToMapX(X:Double):Double;
Begin
 PxToMapX:=CX+(X-VCX)*UPP;
End;

Function PxToMapY(Y:Double):Double;
Begin
 PxToMapY:=CY-(Y-VCY)*UPP;
End;

Procedure PushView;
Var
 I:Integer;
Begin
 If InHistMove Then Exit;
 If HistPos<HistN Then HistN:=HistPos;
 If HistN>=MaxHist Then Begin
  For I:=2 to HistN do Hist[I-1]:=Hist[I];
  Dec(HistN);
 End;
 Inc(HistN);
 Hist[HistN].X:=CX;Hist[HistN].Y:=CY;Hist[HistN].U:=UPP;
 HistPos:=HistN;
End;

Procedure SetView(X,Y,U:Double);
Begin
 CX:=X;CY:=Y;UPP:=U;
 If UPP<1E-9 Then UPP:=1E-9;
 If UPP>1E8 Then UPP:=1E8;
 UpdateView;
 PushView;
End;

Procedure ZoomToExtent(X1,Y1,X2,Y2:Double);
Var
 W,H,U,UX,UY,Pad:Double;
Begin
 W:=ClipR-ClipL+1;
 H:=ClipB-ClipT+1;
 If X2<X1 Then Begin U:=X1;X1:=X2;X2:=U;End;
 If Y2<Y1 Then Begin U:=Y1;Y1:=Y2;Y2:=U;End;
 If ProjCrsId=crs4326 Then Pad:=0.05 Else Pad:=500;
 If(X2-X1<Pad/100)and(Y2-Y1<Pad/100)Then Begin
  X1:=X1-Pad;X2:=X2+Pad;Y1:=Y1-Pad;Y2:=Y2+Pad;
 End;
 UX:=(X2-X1)/W;
 UY:=(Y2-Y1)/H;
 If UX>UY Then U:=UX Else U:=UY;
 SetView((X1+X2)/2,(Y1+Y2)/2,U*1.06);
End;

Procedure ZoomWorld;
Begin
 If ProjCrsId=crs3857 Then ZoomToExtent(-20037508,-20037508,20037508,20037508) Else
 If ProjCrsId=crs4326 Then ZoomToExtent(-180,-90,180,90)
                      Else ZoomToExtent(-1000,-1000,1000,1000);
End;

Function ZoomAllExtent(Var X1,Y1,X2,Y2:Double;OnlyVisible:Boolean):Boolean;
Var
 I:Integer;
 A,B,C,D:Double;
 Any:Boolean;
Begin
 Any:=False;
 For I:=1 to NLay do
  If(Lay[I].Visible or Not OnlyVisible)and Lay[I].HasExt Then Begin
   LayerProjExtent(Lay[I],A,B,C,D);
   If Any Then Begin
    X1:=MinD(X1,A);Y1:=MinD(Y1,B);X2:=MaxD(X2,C);Y2:=MaxD(Y2,D);
   End
    Else
   Begin
    X1:=A;Y1:=B;X2:=C;Y2:=D;
    Any:=True;
   End;
  End;
 ZoomAllExtent:=Any;
End;

Procedure ZoomAll;
Var
 X1,Y1,X2,Y2:Double;
Begin
 If ZoomAllExtent(X1,Y1,X2,Y2,True)Then ZoomToExtent(X1,Y1,X2,Y2)
                                   Else ZoomWorld;
End;

Procedure ZoomLayerIdx(I:Integer);
Var
 X1,Y1,X2,Y2:Double;
Begin
 If(I<1)or(I>NLay)Then Exit;
 If Not Lay[I].HasExt Then Exit;
 LayerProjExtent(Lay[I],X1,Y1,X2,Y2);
 ZoomToExtent(X1,Y1,X2,Y2);
End;

Function SelectionExtent(Var X1,Y1,X2,Y2:Double):Boolean;
Var
 I:Integer;
 J:LongInt;
 F:PFeature;
 A,B,C,D:Double;
 Any:Boolean;
Begin
 Any:=False;
 For I:=1 to NLay do
  If Lay[I].Kind=lkVector Then
   For J:=1 to Lay[I].NF do Begin
    F:=Lay[I].Feats^[J];
    If F^.Sel and(F^.Kind<>gkNone)Then Begin
     A:=F^.MinX;B:=F^.MinY;C:=F^.MaxX;D:=F^.MaxY;
     TransformToProj(Lay[I],A,B);
     TransformToProj(Lay[I],C,D);
     If Any Then Begin
      X1:=MinD(X1,MinD(A,C));Y1:=MinD(Y1,MinD(B,D));
      X2:=MaxD(X2,MaxD(A,C));Y2:=MaxD(Y2,MaxD(B,D));
     End
      Else
     Begin
      X1:=MinD(A,C);Y1:=MinD(B,D);X2:=MaxD(A,C);Y2:=MaxD(B,D);
      Any:=True;
     End;
    End;
   End;
 SelectionExtent:=Any;
End;

Procedure ApplyHist(P:Integer);
Begin
 If(P<1)or(P>HistN)Then Exit;
 HistPos:=P;
 CX:=Hist[P].X;CY:=Hist[P].Y;UPP:=Hist[P].U;
 UpdateView;
End;

Procedure ZoomFactor(F:Double);
Begin
 SetView(CX,CY,UPP*F);
End;

Procedure PanBy(DXpx,DYpx:Double);
Begin
 SetView(CX+DXpx*UPP,CY-DYpx*UPP,UPP);
End;

{ Echelle approximative (denominateur) pour un ecran de 96 dpi }
Function ScaleDenom:Double;
Var
 Mpp,Lat,X,Y:Double;
Begin
 If ProjCrsId=crs4326 Then Mpp:=UPP*111319.49*Cos(CY*Pi/180) Else
 If ProjCrsId=crs3857 Then Begin
  X:=CX;Y:=CY;
  XfPt(crs3857,crs4326,X,Y);
  Lat:=Y;
  Mpp:=UPP*Cos(Lat*Pi/180);
 End
  Else Mpp:=UPP;
 ScaleDenom:=Mpp*96/0.0254;
End;

Function MetersPerPixel:Double;
Begin
 MetersPerPixel:=ScaleDenom*0.0254/96;
End;

Function CoordStr(X,Y:Double):String;
Begin
 If ProjCrsId=crs4326 Then CoordStr:=RealStr(X,5)+','+RealStr(Y,5) Else
 If ProjCrsId=crs3857 Then CoordStr:=RealStr(X,1)+','+RealStr(Y,1)
                      Else CoordStr:=RealStr(X,2)+','+RealStr(Y,2);
End;

{ ------------------------------------------------------------------ }
{ Rendu                                                               }
{ ------------------------------------------------------------------ }

Procedure EnsureScr(NP,NPa:LongInt);
Begin
 If NP>ScCap Then Begin
  If ScPts<>Nil Then FreeMem(ScPts,ScCap*SizeOf(TPt));
  ScCap:=NP+NP div 2+16;
  If ScCap>MaxPtsF+1 Then ScCap:=MaxPtsF+1;
  GetMem(ScPts,ScCap*SizeOf(TPt));
 End;
 If NPa>ScEndCap Then Begin
  If ScEnds<>Nil Then FreeMem(ScEnds,ScEndCap*SizeOf(LongInt));
  ScEndCap:=NPa+NPa div 2+16;
  If ScEndCap>MaxPartsF+1 Then ScEndCap:=MaxPartsF+1;
  GetMem(ScEnds,ScEndCap*SizeOf(LongInt));
 End;
End;

{ Projette les sommets d'une entite en pixels (sommets voisins fusionnes) }
Procedure FeatToScreen(Var L:TLayer;F:PFeature);
Var
 P,I,A,B:LongInt;
 X,Y,SX,SY,LX,LY:Double;
 Need,First:Boolean;
Begin
 EnsureScr(F^.NPts,F^.NParts);
 Need:=L.CrsId<>ProjCrsId;
 ScN:=0;ScParts:=0;
 For P:=0 to F^.NParts-1 do Begin
  If P=0 Then A:=0 Else A:=F^.Ends^[P-1];
  B:=F^.Ends^[P];
  First:=True;
  LX:=0;LY:=0;
  For I:=A to B-1 do Begin
   X:=F^.Pts^[I].X;Y:=F^.Pts^[I].Y;
   If Need Then XfPt(L.CrsId,ProjCrsId,X,Y);
   SX:=VCX+(X-CX)/UPP;
   SY:=VCY-(Y-CY)/UPP;
   If First or(Abs(SX-LX)>=0.5)or(Abs(SY-LY)>=0.5)or(I=B-1)Then Begin
    ScPts^[ScN].X:=SX;ScPts^[ScN].Y:=SY;
    Inc(ScN);
    LX:=SX;LY:=SY;
    First:=False;
   End;
  End;
  ScEnds^[ScParts]:=ScN;
  Inc(ScParts);
 End;
End;

Procedure FillScreenPoly(C:Byte);
Var
 Y,YMin,YMax,P,I,A,B,J,N,K:LongInt;
 MnY,MxY,Yc,X1,Y1,X2,Y2,T:Double;
 XA,XB:LongInt;
Begin
 MnY:=1E300;MxY:=-1E300;
 For I:=0 to ScN-1 do Begin
  If ScPts^[I].Y<MnY Then MnY:=ScPts^[I].Y;
  If ScPts^[I].Y>MxY Then MxY:=ScPts^[I].Y;
 End;
 If(MxY<ClipT)or(MnY>ClipB)Then Exit;
 If MnY<ClipT Then MnY:=ClipT;
 If MxY>ClipB+1 Then MxY:=ClipB+1;
 YMin:=Trunc(MnY);
 YMax:=Trunc(MxY)+1;
 If YMax>ClipB Then YMax:=ClipB;
 For Y:=YMin to YMax do Begin
  Yc:=Y+0.5;
  N:=0;
  A:=0;
  For P:=0 to ScParts-1 do Begin
   B:=ScEnds^[P];
   If B-A>=2 Then
    For I:=A to B-1 do Begin
     If I=B-1 Then J:=A Else J:=I+1;
     Y1:=ScPts^[I].Y;Y2:=ScPts^[J].Y;
     If(Y1<=Yc)<>(Y2<=Yc)Then Begin
      X1:=ScPts^[I].X;X2:=ScPts^[J].X;
      If N<=MaxCross Then Begin
       XCross[N]:=X1+(Yc-Y1)/(Y2-Y1)*(X2-X1);
       Inc(N);
      End;
     End;
    End;
   A:=B;
  End;
  { Tri par insertion }
  For I:=1 to N-1 do Begin
   T:=XCross[I];
   K:=I-1;
   While(K>=0)and(XCross[K]>T)do Begin
    XCross[K+1]:=XCross[K];
    Dec(K);
   End;
   XCross[K+1]:=T;
  End;
  K:=0;
  While K+1<N do Begin
   If(XCross[K+1]>=ClipL)and(XCross[K]<=ClipR+1)Then Begin
    XA:=Trunc(XCross[K]+0.5);
    XB:=Trunc(XCross[K+1]-0.5);
    If XB<XA Then XB:=XA;
    SHLine(XA,XB,Y,C);
   End;
   K:=K+2;
  End;
 End;
End;

Procedure OutlineScreen(C:Byte;Closed:Boolean);
Var
 P,I,A,B:LongInt;
Begin
 A:=0;
 For P:=0 to ScParts-1 do Begin
  B:=ScEnds^[P];
  If(B-A=1)and(Abs(ScPts^[A].X)<1E7)and(Abs(ScPts^[A].Y)<1E7)Then SPix(Round(ScPts^[A].X),Round(ScPts^[A].Y),C);
  For I:=A to B-2 do
   SLineD(ScPts^[I].X,ScPts^[I].Y,ScPts^[I+1].X,ScPts^[I+1].Y,C);
  If Closed and(B-A>2)Then
   SLineD(ScPts^[B-1].X,ScPts^[B-1].Y,ScPts^[A].X,ScPts^[A].Y,C);
  A:=B;
 End;
End;

Procedure DrawPointMark(X,Y:Double;Fill,Edge:Byte);
Var
 IX,IY:LongInt;
Begin
 If(Abs(X)>1E7)or(Abs(Y)>1E7)Then Exit;
 IX:=Round(X);IY:=Round(Y);
 If(IX<ClipL-3)or(IX>ClipR+3)or(IY<ClipT-3)or(IY>ClipB+3)Then Exit;
 SBar(IX-2,IY-2,IX+2,IY+2,Fill);
 SLineI(IX-3,IY-3,IX+3,IY-3,Edge);
 SLineI(IX-3,IY+3,IX+3,IY+3,Edge);
 SLineI(IX-3,IY-3,IX-3,IY+3,Edge);
 SLineI(IX+3,IY-3,IX+3,IY+3,Edge);
End;

Function FeatInView(Var L:TLayer;F:PFeature):Boolean;
Var
 A,B,C,D:Double;
Begin
 A:=F^.MinX;B:=F^.MinY;C:=F^.MaxX;D:=F^.MaxY;
 If L.CrsId<>ProjCrsId Then Begin
  XfPt(L.CrsId,ProjCrsId,A,B);
  XfPt(L.CrsId,ProjCrsId,C,D);
 End;
 FeatInView:=(C>=VX1)and(A<=VX2)and(D>=VY1)and(B<=VY2);
End;

Procedure DrawFeatureScr(Var L:TLayer;F:PFeature;Sel:Boolean);
Var
 Fc,Lc:Byte;
 I:LongInt;
Begin
 If Sel Then Begin
  Fc:=Yellow;Lc:=Red;
 End
  Else
 Begin
  Fc:=L.Color;Lc:=LayerDark[L.Color and 15];
 End;
 FeatToScreen(L,F);
 Case F^.Kind of
  gkPoint:Begin
   For I:=0 to ScN-1 do DrawPointMark(ScPts^[I].X,ScPts^[I].Y,Fc,Lc);
  End;
  gkLine:Begin
   If Sel Then OutlineScreen(Red,False) Else OutlineScreen(Lc,False);
  End;
  gkPoly:Begin
   If L.Fill or Sel Then FillScreenPoly(Fc);
   OutlineScreen(Lc,True);
  End;
 End;
End;

Function RampColor(T:Double):Byte;
Const
 Ramp:Array[0..9]of Byte=(Blue,LightBlue,Cyan,LightCyan,LightGreen,Green,Yellow,Brown,LightRed,White);
Var
 I:Integer;
Begin
 If T<0 Then T:=0;
 If T>0.9999 Then T:=0.9999;
 I:=Trunc(T*10);
 RampColor:=Ramp[I];
End;

Procedure DrawRaster(Var L:TLayer);
Var
 PX,PY,C,R:LongInt;
 X,Y,XX,YY,V,Rng:Double;
 Need:Boolean;
Begin
 If L.RData=Nil Then Exit;
 Need:=L.CrsId<>ProjCrsId;
 Rng:=L.RMax-L.RMin;
 If Rng<=0 Then Rng:=1;
 For PY:=ClipT to ClipB do Begin
  Y:=CY-(PY+0.5-VCY)*UPP;
  For PX:=ClipL to ClipR do Begin
   X:=CX+(PX+0.5-VCX)*UPP;
   XX:=X;YY:=Y;
   If Need Then XfPt(ProjCrsId,L.CrsId,XX,YY);
   C:=Trunc((XX-L.RX0)/L.RCell);
   R:=Trunc((L.RY0-YY)/L.RCell);
   If(XX>=L.RX0)and(YY<=L.RY0)and(C>=0)and(C<L.RW)and(R>=0)and(R<L.RH)Then Begin
    V:=L.RData^[R*L.RW+C];
    If V>-1E29 Then SPix(PX,PY,RampColor((V-L.RMin)/Rng));
   End;
  End;
 End;
End;

Procedure DrawGrid;
Var
 Raw,Mag,Step,V,Lo,Hi:Double;
 K:Integer;
 P:Double;
Begin
 Raw:=90*UPP;
 If Raw<=0 Then Exit;
 Mag:=Exp(Ln(10)*Int(Ln(Raw)/Ln(10)));
 If Raw<Mag Then Mag:=Mag/10;
 If Raw<=Mag Then Step:=Mag Else
 If Raw<=2*Mag Then Step:=2*Mag Else
 If Raw<=5*Mag Then Step:=5*Mag
                Else Step:=10*Mag;
 Lo:=VX1;Hi:=VX2;
 V:=Int(Lo/Step)*Step;
 K:=0;
 While(V<=Hi)and(K<200)do Begin
  P:=MapToPxX(V);
  SLineD(P,ClipT,P,ClipB,LightGray);
  V:=V+Step;
  Inc(K);
 End;
 Lo:=VY1;Hi:=VY2;
 V:=Int(Lo/Step)*Step;
 K:=0;
 While(V<=Hi)and(K<200)do Begin
  P:=MapToPxY(V);
  SLineD(ClipL,P,ClipR,P,LightGray);
  V:=V+Step;
  Inc(K);
 End;
End;

Procedure DrawLabels(Var L:TLayer);
Var
 I,Cnt:LongInt;
 F:PFeature;
 S:String;
 X,Y:Double;
 TX,TY:LongInt;
Begin
 If OffScr or(L.LblFld<1)Then Exit;
 Cnt:=0;
 SetColor(Black);
 For I:=1 to L.NF do Begin
  If Cnt>=400 Then Exit;
  F:=L.Feats^[I];
  If(F^.Kind<>gkNone)and FeatInView(L,F)Then Begin
   S:=FeatAttr(L,F,L.LblFld);
   If S<>'' Then Begin
    S:=Copy(S,1,24);
    If F^.Kind=gkPoint Then Begin
     X:=F^.Pts^[0].X;Y:=F^.Pts^[0].Y;
     If L.CrsId<>ProjCrsId Then XfPt(L.CrsId,ProjCrsId,X,Y);
     TX:=Round(MapToPxX(X))+6;
     TY:=Round(MapToPxY(Y))-3;
    End
     Else
    Begin
     X:=(F^.MinX+F^.MaxX)/2;Y:=(F^.MinY+F^.MaxY)/2;
     If L.CrsId<>ProjCrsId Then XfPt(L.CrsId,ProjCrsId,X,Y);
     TX:=Round(MapToPxX(X))-Length(S)*4;
     TY:=Round(MapToPxY(Y))-4;
    End;
    If(TX>=ClipL)and(TX+Length(S)*8<=ClipR)and(TY>=ClipT)and(TY+8<=ClipB)Then Begin
     OutTextXY(TX,TY,S);
     Inc(Cnt);
    End;
   End;
  End;
 End;
End;

Procedure DrawScaleBar;
Var
 Mpp,Target,Mag,Len:Double;
 Px,X0,Y0:LongInt;
 S:String;
Begin
 If OffScr Then Exit;
 Mpp:=MetersPerPixel;
 If Mpp<=0 Then Exit;
 Target:=100*Mpp;
 Mag:=Exp(Ln(10)*Int(Ln(Target)/Ln(10)));
 If Target<Mag Then Mag:=Mag/10;
 If Target>=5*Mag Then Len:=5*Mag Else
 If Target>=2*Mag Then Len:=2*Mag Else Len:=Mag;
 Px:=Round(Len/Mpp);
 If Px<10 Then Exit;
 X0:=ClipL+12;
 Y0:=ClipB-14;
 If(X0+Px>ClipR)Then Exit;
 SBar(X0-4,Y0-14,X0+Px+60,Y0+8,White);
 SLineI(X0,Y0,X0+Px,Y0,Black);
 SLineI(X0,Y0-3,X0,Y0+3,Black);
 SLineI(X0+Px,Y0-3,X0+Px,Y0+3,Black);
 If Len>=1000 Then S:=NumStr(Len/1000)+' km' Else S:=NumStr(Len)+' m';
 SetColor(Black);
 OutTextXY(X0,Y0-12,S);
End;

Procedure DrawMeasure;
Var
 I:Integer;
 X,Y,PX,PY:Double;
Begin
 PX:=0;PY:=0;
 For I:=1 to MeasN do Begin
  X:=MapToPxX(MeasPts[I].X);
  Y:=MapToPxY(MeasPts[I].Y);
  If I>1 Then SLineD(PX,PY,X,Y,Red);
  DrawPointMark(X,Y,Red,Black);
  PX:=X;PY:=Y;
 End;
End;

Procedure RenderMap;
Var
 I:Integer;
 J:LongInt;
 F:PFeature;
Begin
 UpdateView;
 SBar(ClipL,ClipT,ClipR,ClipB,Background);
 If ShowGrid Then DrawGrid;
 For I:=NLay downto 1 do
  If Lay[I].Visible Then Begin
   If Lay[I].Kind=lkRaster Then DrawRaster(Lay[I]) Else Begin
    For J:=1 to Lay[I].NF do Begin
     F:=Lay[I].Feats^[J];
     If(F^.Kind<>gkNone)and Not F^.Sel and FeatInView(Lay[I],F)Then DrawFeatureScr(Lay[I],F,False);
    End;
    For J:=1 to Lay[I].NF do Begin
     F:=Lay[I].Feats^[J];
     If(F^.Kind<>gkNone)and F^.Sel and FeatInView(Lay[I],F)Then DrawFeatureScr(Lay[I],F,True);
    End;
   End;
  End;
 If ShowLabels Then
  For I:=NLay downto 1 do
   If Lay[I].Visible and(Lay[I].Kind=lkVector)Then DrawLabels(Lay[I]);
 If MeasN>0 Then DrawMeasure;
 DrawScaleBar;
End;

{ Rendu hors ecran dans OffBuf (largeur W, hauteur H) ; l'etendue est celle du
  projet (UseExt faux) ou celle donnee dans le SCR du projet }
Function RenderOffscreen(W,H:LongInt;UseExt:Boolean;EX1,EY1,EX2,EY2:Double):Boolean;
Var
 SvL,SvT,SvR,SvB:LongInt;
 SvCX,SvCY,SvU:Double;
 X1,Y1,X2,Y2,Pad:Double;
 Have:Boolean;
Begin
 RenderOffscreen:=False;
 If(W<16)or(H<16)or(W*H>MaxOff)Then Begin
  LoadErr:='Dimensions de l''image invalides ou trop grandes';
  Exit;
 End;
 GetMem(OffBuf,W*H);
 If OffBuf=Nil Then Begin
  LoadErr:='Memoire insuffisante';
  Exit;
 End;
 OffW:=W;OffH:=H;
 FillChar(OffBuf^,W*H,Background);
 SvL:=ClipL;SvT:=ClipT;SvR:=ClipR;SvB:=ClipB;
 SvCX:=CX;SvCY:=CY;SvU:=UPP;
 OffScr:=True;
 SetClip(0,0,W-1,H-1);
 If UseExt Then Begin
  X1:=EX1;Y1:=EY1;X2:=EX2;Y2:=EY2;
  Have:=True;
  Pad:=1;
 End
  Else
 Begin
  Have:=ZoomAllExtent(X1,Y1,X2,Y2,True);
  Pad:=1.06;
  If Have Then Begin
   If ProjCrsId=crs4326 Then Begin
    If(X2-X1<0.0001)and(Y2-Y1<0.0001)Then Begin
     X1:=X1-0.05;X2:=X2+0.05;Y1:=Y1-0.05;Y2:=Y2+0.05;
    End;
   End;
  End;
 End;
 If Have Then Begin
  CX:=(X1+X2)/2;
  CY:=(Y1+Y2)/2;
  If(X2-X1)/W>(Y2-Y1)/H Then UPP:=(X2-X1)/W*Pad Else UPP:=(Y2-Y1)/H*Pad;
  If UPP<=0 Then UPP:=1;
 End
  Else
 Begin
  CX:=0;CY:=0;
  If ProjCrsId=crs4326 Then UPP:=360/W Else UPP:=40000000/W;
 End;
 UpdateView;
 RenderMap;
 OffScr:=False;
 SetClip(SvL,SvT,SvR,SvB);
 CX:=SvCX;CY:=SvCY;UPP:=SvU;
 UpdateView;
 RenderOffscreen:=True;
End;

Procedure FreeOffscreen;
Begin
 If OffBuf<>Nil Then FreeMem(OffBuf,OffW*OffH);
 OffBuf:=Nil;
End;
{ ------------------------------------------------------------------ }
{ Interface : primitives                                              }
{ ------------------------------------------------------------------ }

Type
 TDlg=Record
  X,Y,W,H:LongInt;
  Sv:TRectSave;
 End;
 TListBox=Record
  X,Y,W,H:LongInt;
  Top,Sel,Rows:LongInt;
 End;

Var
 PickMap:Array[1..MaxLines]of Integer;

Procedure Box3D(X1,Y1,X2,Y2:LongInt;Raised:Boolean);
Begin
 SetFillStyle(SolidFill,LightGray);
 Bar(X1,Y1,X2,Y2);
 If Raised Then SetColor(White) Else SetColor(DarkGray);
 Line(X1,Y1,X2,Y1);
 Line(X1,Y1,X1,Y2);
 If Raised Then SetColor(DarkGray) Else SetColor(White);
 Line(X2,Y1,X2,Y2);
 Line(X1,Y2,X2,Y2);
End;

Procedure Sunken(X1,Y1,X2,Y2:LongInt;Fill:Byte);
Begin
 SetFillStyle(SolidFill,Fill);
 Bar(X1,Y1,X2,Y2);
 SetColor(DarkGray);
 Line(X1,Y1,X2,Y1);
 Line(X1,Y1,X1,Y2);
 SetColor(White);
 Line(X2,Y1,X2,Y2);
 Line(X1,Y2,X2,Y2);
End;

Procedure Txt(X,Y:LongInt;C:Byte;Const S:String);
Begin
 SetColor(C);
 OutTextXY(X,Y,S);
End;

Procedure DrawButton(X,Y,W,H:LongInt;Const Cap:String;Down:Boolean);
Var
 TX:LongInt;
Begin
 Box3D(X,Y,X+W-1,Y+H-1,Not Down);
 TX:=X+(W-Length(Cap)*8)div 2;
 If Down Then Inc(TX);
 Txt(TX,Y+(H-8)div 2+Ord(Down),Black,Cap);
End;

Function InRect(X,Y,X1,Y1,X2,Y2:LongInt):Boolean;
Begin
 InRect:=(X>=X1)and(X<=X2)and(Y>=Y1)and(Y<=Y2);
End;

{ ------------------------------------------------------------------ }
{ Evenements                                                          }
{ ------------------------------------------------------------------ }

Procedure WaitTick;
Begin
 Delay(10);
 Inc(Tick);
End;

Function GetEvent(Var E:TEvent):Boolean;
Var
 X,Y,B:LongInt;
Begin
 FillChar(E,SizeOf(E),0);
 GetEvent:=True;
 If KeyPressed Then Begin
  E.What:=evKey;
  E.Key:=ReadKey;
  If E.Key=#0 Then Begin
   E.Ext:=True;
   E.Key:=ReadKey;
  End;
  Exit;
 End;
 If MouseOk Then Begin
  GetMouseState(X,Y,B);
  E.X:=X;E.Y:=Y;
  If((B and 1)<>0)and((PrevMB and 1)=0)Then Begin
   E.What:=evDown;E.Btn:=1;
   E.Dbl:=(Tick-LastDownTick<40)and(Abs(X-LastDownX)<5)and(Abs(Y-LastDownY)<5);
   LastDownTick:=Tick;LastDownX:=X;LastDownY:=Y;
   If E.Dbl Then LastDownTick:=-1000;
  End
   Else
  If((B and 2)<>0)and((PrevMB and 2)=0)Then Begin
   E.What:=evDown;E.Btn:=2;
  End
   Else
  If((B and 1)=0)and((PrevMB and 1)<>0)Then Begin
   E.What:=evUp;E.Btn:=1;
  End
   Else
  If((B and 2)=0)and((PrevMB and 2)<>0)Then Begin
   E.What:=evUp;E.Btn:=2;
  End
   Else
  If(X<>PrevMX)or(Y<>PrevMY)Then E.What:=evMove;
  If E.What=evDown Then Begin
   If E.Btn=1 Then PrevMB:=PrevMB or 1 Else PrevMB:=PrevMB or 2;
  End
   Else
  If E.What=evUp Then Begin
   If E.Btn=1 Then PrevMB:=PrevMB and not 1 Else PrevMB:=PrevMB and not 2;
  End
   Else PrevMB:=B;
  PrevMX:=X;PrevMY:=Y;
  If E.What<>evNone Then Exit;
 End;
 E.What:=evNone;
 GetEvent:=False;
End;

{ Vide les evenements en attente }
Procedure FlushEvents;
Var
 E:TEvent;
 N:Integer;
Begin
 N:=0;
 While GetEvent(E)and(N<200)do Inc(N);
End;

{ ------------------------------------------------------------------ }
{ Boites de dialogue                                                  }
{ ------------------------------------------------------------------ }

Procedure DlgOpen(Var D:TDlg;W,H:LongInt;Const Title:String);
Begin
 If W>ScrW-4 Then W:=ScrW-4;
 If H>ScrH-4 Then H:=ScrH-4;
 If H>599 Then H:=599;
 D.W:=W;D.H:=H;
 D.X:=(ScrW-W)div 2;
 D.Y:=(ScrH-H)div 2;
 HM;
 SaveRect(D.X,D.Y,W+2,H+2,D.Sv);
 SetFillStyle(SolidFill,Black);
 Bar(D.X+2,D.Y+2,D.X+W+1,D.Y+H+1);
 Box3D(D.X,D.Y,D.X+W-1,D.Y+H-1,True);
 SetFillStyle(SolidFill,Blue);
 Bar(D.X+3,D.Y+3,D.X+W-4,D.Y+17);
 Txt(D.X+8,D.Y+6,White,Copy(Title,1,(W-16)div 8));
 SM;
End;

Procedure DlgClose(Var D:TDlg);
Begin
 HM;
 RestoreRect(D.X,D.Y,D.Sv);
 SM;
End;

Procedure LbInit(Var Lb:TListBox;X,Y,W,H:LongInt);
Begin
 Lb.X:=X;Lb.Y:=Y;Lb.W:=W;Lb.H:=H;
 Lb.Top:=1;Lb.Sel:=1;
 Lb.Rows:=(H-4)div 12;
End;

Procedure LbDraw(Var Lb:TListBox;P:PLineList;N:LongInt;UseMap:Boolean);
Var
 I,Idx,Y,TW,TH,Tp:LongInt;
 S:String;
Begin
 HM;
 Sunken(Lb.X,Lb.Y,Lb.X+Lb.W-1,Lb.Y+Lb.H-1,White);
 TW:=(Lb.W-20)div 8;
 For I:=0 to Lb.Rows-1 do Begin
  Idx:=Lb.Top+I;
  If Idx<=N Then Begin
   Y:=Lb.Y+3+I*12;
   If UseMap Then S:=P^[PickMap[Idx]]^ Else S:=P^[Idx]^;
   If Idx=Lb.Sel Then Begin
    SetFillStyle(SolidFill,Blue);
    Bar(Lb.X+2,Y-1,Lb.X+Lb.W-17,Y+9);
    Txt(Lb.X+4,Y,White,Copy(S,1,TW));
   End
    Else Txt(Lb.X+4,Y,Black,Copy(S,1,TW));
  End;
 End;
 { Barre de defilement }
 Box3D(Lb.X+Lb.W-16,Lb.Y+1,Lb.X+Lb.W-2,Lb.Y+13,True);
 Txt(Lb.X+Lb.W-13,Lb.Y+4,Black,#30);
 Box3D(Lb.X+Lb.W-16,Lb.Y+Lb.H-14,Lb.X+Lb.W-2,Lb.Y+Lb.H-2,True);
 Txt(Lb.X+Lb.W-13,Lb.Y+Lb.H-11,Black,#31);
 SetFillStyle(SolidFill,DarkGray);
 Bar(Lb.X+Lb.W-16,Lb.Y+14,Lb.X+Lb.W-2,Lb.Y+Lb.H-15);
 If N>Lb.Rows Then Begin
  TH:=Lb.H-30;
  Tp:=Lb.Y+14+((Lb.Top-1)*(TH-8))div(N-Lb.Rows+1);
  Box3D(Lb.X+Lb.W-16,Tp,Lb.X+Lb.W-2,Tp+8,True);
 End;
 SM;
End;

Procedure LbFix(Var Lb:TListBox;N:LongInt);
Begin
 If Lb.Sel>N Then Lb.Sel:=N;
 If Lb.Sel<1 Then Lb.Sel:=1;
 If Lb.Sel<Lb.Top Then Lb.Top:=Lb.Sel;
 If Lb.Sel>=Lb.Top+Lb.Rows Then Lb.Top:=Lb.Sel-Lb.Rows+1;
 If Lb.Top>N-Lb.Rows+1 Then Lb.Top:=N-Lb.Rows+1;
 If Lb.Top<1 Then Lb.Top:=1;
End;

{ Gere une touche de navigation ; retourne True si la touche a ete traitee }
Function LbKey(Var Lb:TListBox;N:LongInt;Var E:TEvent):Boolean;
Begin
 LbKey:=False;
 If(E.What<>evKey)or Not E.Ext Then Exit;
 Case Ord(E.Key)of
  72:Dec(Lb.Sel);
  80:Inc(Lb.Sel);
  73:Dec(Lb.Sel,Lb.Rows-1);
  81:Inc(Lb.Sel,Lb.Rows-1);
  71:Lb.Sel:=1;
  79:Lb.Sel:=N;
  Else Exit;
 End;
 LbFix(Lb,N);
 LbKey:=True;
End;

{ Clic dans la liste : retourne 1 si un element a ete choisi, 2 si defilement }
Function LbClick(Var Lb:TListBox;X,Y:LongInt;N:LongInt):Integer;
Var
 Idx:LongInt;
Begin
 LbClick:=0;
 If Not InRect(X,Y,Lb.X,Lb.Y,Lb.X+Lb.W-1,Lb.Y+Lb.H-1)Then Exit;
 If X>=Lb.X+Lb.W-16 Then Begin
  If Y<Lb.Y+14 Then Dec(Lb.Top) Else
  If Y>Lb.Y+Lb.H-15 Then Inc(Lb.Top) Else
  If Y<Lb.Y+Lb.H div 2 Then Dec(Lb.Top,Lb.Rows) Else Inc(Lb.Top,Lb.Rows);
  If Lb.Top>N-Lb.Rows+1 Then Lb.Top:=N-Lb.Rows+1;
  If Lb.Top<1 Then Lb.Top:=1;
  LbClick:=2;
  Exit;
 End;
 Idx:=Lb.Top+(Y-Lb.Y-3)div 12;
 If(Idx>=1)and(Idx<=N)and(Idx<Lb.Top+Lb.Rows)Then Begin
  Lb.Sel:=Idx;
  LbClick:=1;
 End;
End;

{ Affiche un texte defilant ; retourne a la fermeture }
Procedure ViewLines(Const Title:String;P:PLineList;N:Integer;W,H:LongInt);
Var
 D:TDlg;
 Lb:TListBox;
 E:TEvent;
 Done:Boolean;
 BX,BY,R:Integer;
Begin
 DlgOpen(D,W,H,Title);
 LbInit(Lb,D.X+8,D.Y+24,W-16,H-62);
 Lb.Sel:=0;
 BX:=D.X+W div 2-30;
 BY:=D.Y+H-30;
 HM;
 DrawButton(BX,BY,60,22,'OK',False);
 SM;
 LbDraw(Lb,P,N,False);
 Done:=False;
 While Not Done do Begin
  If GetEvent(E)Then Begin
   If E.What=evKey Then Begin
    If Not E.Ext and((E.Key=#27)or(E.Key=#13))Then Done:=True Else
    If E.Ext Then Begin
     Case Ord(E.Key)of
      72:Dec(Lb.Top);
      80:Inc(Lb.Top);
      73:Dec(Lb.Top,Lb.Rows);
      81:Inc(Lb.Top,Lb.Rows);
      71:Lb.Top:=1;
      79:Lb.Top:=N;
     End;
     If Lb.Top>N-Lb.Rows+1 Then Lb.Top:=N-Lb.Rows+1;
     If Lb.Top<1 Then Lb.Top:=1;
     LbDraw(Lb,P,N,False);
    End;
   End
    Else
   If(E.What=evDown)and(E.Btn=1)Then Begin
    If InRect(E.X,E.Y,BX,BY,BX+59,BY+21)Then Done:=True Else Begin
     R:=LbClick(Lb,E.X,E.Y,N);
     If R>0 Then Begin
      Lb.Sel:=0;
      LbDraw(Lb,P,N,False);
     End;
    End;
   End;
  End
   Else WaitTick;
 End;
 DlgClose(D);
 FlushEvents;
End;

Procedure MsgBox(Const Title,Text:String);
Var
 P:PLineList;
 N:Integer;
 H:LongInt;
Begin
 TextToLines(Text,58,P,N);
 H:=N*12+70;
 If H>300 Then H:=300;
 If H<110 Then H:=110;
 ViewLines(Title,P,N,500,H);
 FreeLines(P,N);
End;

Procedure ViewFile(Const Title,FN:String);
Var
 P:PLineList;
 N:Integer;
Begin
 LoadFileLines(FN,P,N);
 If N=0 Then AddLine(P,N,'(aucune sortie)');
 ViewLines(Title,P,N,ScrW-40,ScrH-60);
 FreeLines(P,N);
End;

Function AskYesNo(Const Title,Text:String):Boolean;
Var
 D:TDlg;
 E:TEvent;
 P:PLineList;
 N,I:Integer;
 H:LongInt;
 Done,Res:Boolean;
 BY:LongInt;
Begin
 TextToLines(Text,48,P,N);
 H:=N*12+70;
 DlgOpen(D,420,H,Title);
 HM;
 For I:=1 to N do Txt(D.X+14,D.Y+28+(I-1)*12,Black,P^[I]^);
 BY:=D.Y+H-32;
 DrawButton(D.X+110,BY,70,22,'Oui',False);
 DrawButton(D.X+240,BY,70,22,'Non',False);
 SM;
 Done:=False;Res:=False;
 While Not Done do Begin
  If GetEvent(E)Then Begin
   If(E.What=evKey)and Not E.Ext Then Begin
    If UpCase(E.Key)in['O','Y',#13]Then Begin
     Res:=True;Done:=True;
    End
     Else
    If UpCase(E.Key)in['N',#27]Then Done:=True;
   End
    Else
   If(E.What=evDown)and(E.Btn=1)Then Begin
    If InRect(E.X,E.Y,D.X+110,BY,D.X+179,BY+21)Then Begin
     Res:=True;Done:=True;
    End
     Else
    If InRect(E.X,E.Y,D.X+240,BY,D.X+309,BY+21)Then Done:=True;
   End;
  End
   Else WaitTick;
 End;
 DlgClose(D);
 FreeLines(P,N);
 FlushEvents;
 AskYesNo:=Res;
End;

Function InputBox(Const Title,Prompt:String;Var S:String;MaxLen:Integer):Boolean;
Var
 D:TDlg;
 E:TEvent;
 Done,Res,Fresh:Boolean;
 Tmp:String;
 BY,FW:LongInt;
 Procedure Redraw;
 Var
  V:String;
 Begin
  HM;
  Sunken(D.X+14,D.Y+50,D.X+D.W-15,D.Y+66,White);
  V:=Tmp+'_';
  If Length(V)>FW Then V:=Copy(V,Length(V)-FW+1,FW);
  Txt(D.X+18,D.Y+54,Black,V);
  SM;
 End;
Begin
 DlgOpen(D,480,126,Title);
 FW:=(480-36)div 8;
 HM;
 Txt(D.X+14,D.Y+28,Black,Copy(Prompt,1,56));
 BY:=D.Y+126-34;
 DrawButton(D.X+150,BY,70,22,'OK',False);
 DrawButton(D.X+260,BY,70,22,'Annuler',False);
 SM;
 Tmp:=S;
 Fresh:=True;
 Redraw;
 Done:=False;Res:=False;
 While Not Done do Begin
  If GetEvent(E)Then Begin
   If E.What=evKey Then Begin
    If Not E.Ext Then Begin
     If E.Key=#13 Then Begin
      Res:=True;Done:=True;
     End
      Else
     If E.Key=#27 Then Done:=True Else
     If E.Key=#8 Then Begin
      If Length(Tmp)>0 Then Dec(Tmp[0]);
      Fresh:=False;
      Redraw;
     End
      Else
     If E.Key=#21 Then Begin
      Tmp:='';
      Fresh:=False;
      Redraw;
     End
      Else
     If(E.Key>=' ')and(Length(Tmp)<MaxLen)Then Begin
      If Fresh Then Tmp:='';
      Fresh:=False;
      Tmp:=Tmp+E.Key;
      Redraw;
     End;
    End;
   End
    Else
   If(E.What=evDown)and(E.Btn=1)Then Begin
    If InRect(E.X,E.Y,D.X+150,BY,D.X+219,BY+21)Then Begin
     Res:=True;Done:=True;
    End
     Else
    If InRect(E.X,E.Y,D.X+260,BY,D.X+329,BY+21)Then Done:=True;
   End;
  End
   Else WaitTick;
 End;
 DlgClose(D);
 If Res Then S:=Tmp;
 FlushEvents;
 InputBox:=Res;
End;

{ Selection dans une liste avec filtre a la frappe ; Sel recoit l'index d'origine }
Function PickList(Const Title:String;P:PLineList;N:Integer;Var Sel:Integer;Filterable:Boolean):Boolean;
Var
 D:TDlg;
 Lb:TListBox;
 E:TEvent;
 Done,Res:Boolean;
 Flt:String;
 M,I:Integer;
 BX,BY,R:LongInt;
 Procedure Refilter;
 Var
  K:Integer;
  U:String;
 Begin
  M:=0;
  U:=StrUp(Flt);
  For K:=1 to N do
   If(Flt='')or(Pos(U,StrUp(P^[K]^))>0)Then Begin
    Inc(M);
    PickMap[M]:=K;
   End;
  Lb.Sel:=1;Lb.Top:=1;
 End;
 Procedure Redraw;
 Begin
  HM;
  If Filterable Then Begin
   Sunken(D.X+8,D.Y+22,D.X+D.W-9,D.Y+38,White);
   Txt(D.X+12,D.Y+26,Black,Copy('Filtre : '+Flt+'_',1,(D.W-24)div 8));
  End;
  SM;
  LbDraw(Lb,P,M,True);
 End;
Begin
 DlgOpen(D,ScrW-80,ScrH-80,Title);
 If Filterable Then LbInit(Lb,D.X+8,D.Y+42,D.W-16,D.H-84)
               Else LbInit(Lb,D.X+8,D.Y+24,D.W-16,D.H-66);
 BX:=D.X+D.W div 2-100;
 BY:=D.Y+D.H-30;
 HM;
 DrawButton(BX,BY,80,22,'OK',False);
 DrawButton(BX+120,BY,80,22,'Annuler',False);
 SM;
 Flt:='';
 Refilter;
 If(Sel>=1)and(Sel<=N)Then Begin
  For I:=1 to M do If PickMap[I]=Sel Then Lb.Sel:=I;
  LbFix(Lb,M);
 End;
 Redraw;
 Done:=False;Res:=False;
 While Not Done do Begin
  If GetEvent(E)Then Begin
   If E.What=evKey Then Begin
    If E.Ext Then Begin
     If LbKey(Lb,M,E)Then Redraw;
    End
     Else
    If E.Key=#27 Then Done:=True Else
    If E.Key=#13 Then Begin
     If M>0 Then Res:=True;
     Done:=True;
    End
     Else
    If Filterable Then Begin
     If E.Key=#8 Then Begin
      If Length(Flt)>0 Then Dec(Flt[0]);
      Refilter;
      Redraw;
     End
      Else
     If(E.Key>=' ')and(Length(Flt)<30)Then Begin
      Flt:=Flt+E.Key;
      Refilter;
      Redraw;
     End;
    End;
   End
    Else
   If(E.What=evDown)and(E.Btn=1)Then Begin
    If InRect(E.X,E.Y,BX,BY,BX+79,BY+21)Then Begin
     If M>0 Then Res:=True;
     Done:=True;
    End
     Else
    If InRect(E.X,E.Y,BX+120,BY,BX+199,BY+21)Then Done:=True Else Begin
     R:=LbClick(Lb,E.X,E.Y,M);
     If R>0 Then Redraw;
     If(R=1)and E.Dbl Then Begin
      Res:=True;Done:=True;
     End;
    End;
   End;
  End
   Else WaitTick;
 End;
 DlgClose(D);
 If Res Then Sel:=PickMap[Lb.Sel];
 FlushEvents;
 PickList:=Res;
End;

{ Boite de dialogue de selection de fichier }
Function FileDlg(Const Title,Filter:String;Save:Boolean;Var Path:String):Boolean;
Var
 D:TDlg;
 Lb:TListBox;
 E:TEvent;
 P:PLineList;
 N:Integer;
 Done,Res,Fresh:Boolean;
 Dir,Name:String;
 BX,BY,R:LongInt;
 Procedure Fill;
 Var
  SR:SearchRec;
  Dirs,Files:PLineList;
  ND,NF,K,J:Integer;
  Ex:String;
  Ok:Boolean;
  Tmp:PStr;
 Begin
  FreeLines(P,N);
  NewLines(P,N);
  NewLines(Dirs,ND);
  NewLines(Files,NF);
  {$IFDEF UNIX}
  FindFirst(JoinPath(Dir,'*'),AnyFile,SR);
  {$ELSE}
  FindFirst(JoinPath(Dir,'*.*'),AnyFile,SR);
  {$ENDIF}
  While(DosError=0)do Begin
   If(SR.Attr and Directory)<>0 Then Begin
    If(SR.Name<>'.')Then AddLine(Dirs,ND,'['+SR.Name+']');
   End
    Else
   Begin
    Ok:=Filter='';
    Ex:=ExtOf(SR.Name);
    If Not Ok Then Ok:=Pos(Ex+';',Filter+';')>0;
    If Ok Then AddLine(Files,NF,SR.Name);
   End;
   FindNext(SR);
  End;
  {$IFDEF FPC}
  FindClose(SR);
  {$ENDIF}
  { Tri simple (insertion) }
  For K:=2 to ND do Begin
   Tmp:=Dirs^[K];J:=K-1;
   While(J>=1)and(StrUp(Dirs^[J]^)>StrUp(Tmp^))do Begin
    Dirs^[J+1]:=Dirs^[J];Dec(J);
   End;
   Dirs^[J+1]:=Tmp;
  End;
  For K:=2 to NF do Begin
   Tmp:=Files^[K];J:=K-1;
   While(J>=1)and(StrUp(Files^[J]^)>StrUp(Tmp^))do Begin
    Files^[J+1]:=Files^[J];Dec(J);
   End;
   Files^[J+1]:=Tmp;
  End;
  For K:=1 to ND do Begin
   AddLine(P,N,Dirs^[K]^);
   FreeStr(Dirs^[K]);
  End;
  For K:=1 to NF do Begin
   AddLine(P,N,Files^[K]^);
   FreeStr(Files^[K]);
  End;
  FreeMem(Dirs,MaxLines*SizeOf(PStr));
  FreeMem(Files,MaxLines*SizeOf(PStr));
  Lb.Sel:=1;Lb.Top:=1;
 End;
 Procedure Redraw;
 Var
  V:String;
 Begin
  HM;
  Sunken(D.X+8,D.Y+22,D.X+D.W-9,D.Y+38,White);
  Txt(D.X+12,D.Y+26,Black,Copy(Dir,Length(Dir)-(D.W-28)div 8+1,255));
  Sunken(D.X+8,D.Y+D.H-62,D.X+D.W-9,D.Y+D.H-46,White);
  V:=Name+'_';
  If Length(V)>(D.W-28)div 8 Then V:=Copy(V,Length(V)-(D.W-28)div 8+1,255);
  Txt(D.X+12,D.Y+D.H-58,Black,V);
  SM;
  LbDraw(Lb,P,N,False);
 End;
 Procedure GoDir(Const NewDir:String);
 Var
  Old:String;
 Begin
  Old:=Dir;
  {$I-}ChDir(NewDir);{$I+}
  If IOResult=0 Then Begin
   GetDir(0,Dir);
   Fill;
  End
   Else Dir:=Old;
 End;
 Procedure Choose;
 Var
  S:String;
 Begin
  S:=P^[Lb.Sel]^;
  If S[1]='[' Then Begin
   S:=Copy(S,2,Length(S)-2);
   GoDir(JoinPath(Dir,S));
   Redraw;
  End
   Else Begin
   Name:=S;
   Res:=True;
   Done:=True;
  End;
 End;
 Procedure Accept;
 Var
  F:String;
 Begin
  F:=Name;
  If F='' Then Exit;
  If DirExist(JoinPath(Dir,F))and Not Save Then Begin
   GoDir(JoinPath(Dir,F));
   Name:='';
   Redraw;
   Exit;
  End;
  If IsAbsPath(F)Then Begin
   Dir:=DirOf(F);
   Name:=FileOf(F);
  End;
  Res:=True;
  Done:=True;
 End;
Var
 Old:String;
Begin
 GetDir(0,Old);
 P:=Nil;N:=0;
 If(Path<>'')and DirExist(DirOf(FullPath(Path)))Then Begin
  Dir:=DirOf(FullPath(Path));
  Name:=FileOf(Path);
 End
  Else
 Begin
  If(LastDir<>'')and DirExist(LastDir)Then Dir:=LastDir Else GetDir(0,Dir);
  Name:='';
 End;
 {$I-}ChDir(Dir);{$I+}
 If IOResult<>0 Then GetDir(0,Dir);
 Fresh:=Name<>'';
 DlgOpen(D,ScrW-120,ScrH-60,Title);
 LbInit(Lb,D.X+8,D.Y+44,D.W-16,D.H-114);
 BX:=D.X+D.W div 2-100;
 BY:=D.Y+D.H-30;
 HM;
 If Save Then DrawButton(BX,BY,80,22,'Enregistrer',False) Else DrawButton(BX,BY,80,22,'Ouvrir',False);
 DrawButton(BX+120,BY,80,22,'Annuler',False);
 SM;
 Fill;
 Redraw;
 Done:=False;Res:=False;
 While Not Done do Begin
  If GetEvent(E)Then Begin
   If E.What=evKey Then Begin
    If E.Ext Then Begin
     If LbKey(Lb,N,E)Then Begin
      If(P^[Lb.Sel]^[1]<>'[')Then Name:=P^[Lb.Sel]^;
      Fresh:=True;
      Redraw;
     End;
    End
     Else
    If E.Key=#27 Then Done:=True Else
    If E.Key=#13 Then Begin
     If Name<>'' Then Accept Else Choose;
    End
     Else
    If E.Key=#8 Then Begin
     If Length(Name)>0 Then Dec(Name[0]);
     Fresh:=False;
     Redraw;
    End
     Else
    If E.Key=#21 Then Begin
     Name:='';
     Fresh:=False;
     Redraw;
    End
     Else
    If(E.Key>=' ')and(Length(Name)<200)Then Begin
     If Fresh Then Name:='';
     Fresh:=False;
     Name:=Name+E.Key;
     Redraw;
    End;
   End
    Else
   If(E.What=evDown)and(E.Btn=1)Then Begin
    If InRect(E.X,E.Y,BX,BY,BX+79,BY+21)Then Accept Else
    If InRect(E.X,E.Y,BX+120,BY,BX+199,BY+21)Then Done:=True Else Begin
     R:=LbClick(Lb,E.X,E.Y,N);
     If R=1 Then Begin
      If P^[Lb.Sel]^[1]<>'[' Then Name:=P^[Lb.Sel]^;
      Fresh:=True;
      If E.Dbl Then Choose;
      If Not Done Then Redraw;
     End
      Else If R=2 Then Redraw;
    End;
   End;
  End
   Else WaitTick;
 End;
 DlgClose(D);
 FreeLines(P,N);
 If Res Then Begin
  If IsAbsPath(Name)Then Path:=Name Else Path:=JoinPath(Dir,Name);
  LastDir:=Dir;
 End;
 {$I-}ChDir(Old);{$I+}
 If IOResult<>0 Then;
 FlushEvents;
 FileDlg:=Res;
End;

{ Formulaire de parametres (algorithmes de traitement) }
Function FormDlg(Const Title:String;Var Prm:Array of TParam;N:Integer):Boolean;
Var
 D:TDlg;
 E:TEvent;
 Done,Res:Boolean;
 Foc,Top,Rows,I,Idx:Integer;
 BX,BY,FW,LW:LongInt;
 Procedure Redraw;
 Var
  K,Y:LongInt;
  V,Info:String;
 Begin
  HM;
  SetFillStyle(SolidFill,LightGray);
  Bar(D.X+4,D.Y+20,D.X+D.W-5,D.Y+D.H-40);
  For K:=0 to Rows-1 do Begin
   Idx:=Top+K;
   If Idx<N Then Begin
    Y:=D.Y+24+K*20;
    If Prm[Idx].Req Then Txt(D.X+10,Y+4,Red,Copy(Prm[Idx].Name,1,LW))
                    Else Txt(D.X+10,Y+4,Black,Copy(Prm[Idx].Name,1,LW));
    Sunken(D.X+12+LW*8,Y,D.X+D.W-12,Y+16,White);
    V:=Prm[Idx].Value;
    If Idx=Foc Then V:=V+'_';
    If Length(V)>FW Then V:=Copy(V,Length(V)-FW+1,FW);
    Txt(D.X+16+LW*8,Y+4,Black,V);
    If Idx=Foc Then Begin
     SetColor(Blue);
     Rectangle(D.X+11+LW*8,Y-1,D.X+D.W-11,Y+17);
    End;
   End;
  End;
  Info:=Prm[Foc].Typ;
  If Prm[Foc].Req Then Info:=Info+' (obligatoire)' Else Info:=Info+' (facultatif)';
  Txt(D.X+10,D.Y+D.H-36-12,DarkGray,Copy(Info,1,(D.W-20)div 8));
  Txt(D.X+10,D.Y+D.H-36-22-12,Black,Copy(Prm[Foc].Desc,1,(D.W-20)div 8));
  SM;
 End;
Begin
 Rows:=8;
 DlgOpen(D,ScrW-60,Rows*20+130,Title);
 LW:=26;
 FW:=(D.W-LW*8-36)div 8;
 BX:=D.X+D.W div 2-100;
 BY:=D.Y+D.H-30;
 HM;
 DrawButton(BX,BY,80,22,'Executer',False);
 DrawButton(BX+120,BY,80,22,'Annuler',False);
 SM;
 Foc:=0;Top:=0;
 Redraw;
 Done:=False;Res:=False;
 While Not Done do Begin
  If GetEvent(E)Then Begin
   If E.What=evKey Then Begin
    If E.Ext Then Begin
     If E.Key=#83 Then Prm[Foc].Value:='' Else
     If E.Key=#80 Then Inc(Foc) Else
     If E.Key=#72 Then Dec(Foc) Else
     If E.Key=#81 Then Foc:=Foc+Rows Else
     If E.Key=#73 Then Foc:=Foc-Rows;
     If Foc<0 Then Foc:=0;
     If Foc>=N Then Foc:=N-1;
     If Foc<Top Then Top:=Foc;
     If Foc>=Top+Rows Then Top:=Foc-Rows+1;
     Redraw;
    End
     Else
    If E.Key=#27 Then Done:=True Else
    If E.Key=#13 Then Begin
     Res:=True;Done:=True;
    End
     Else
    If E.Key=#9 Then Begin
     Foc:=(Foc+1)mod N;
     If Foc<Top Then Top:=Foc;
     If Foc>=Top+Rows Then Top:=Foc-Rows+1;
     Redraw;
    End
     Else
    If E.Key=#8 Then Begin
     If Length(Prm[Foc].Value)>0 Then Dec(Prm[Foc].Value[0]);
     Redraw;
    End
     Else
    If E.Key=#21 Then Begin
     Prm[Foc].Value:='';
     Redraw;
    End
     Else
    If(E.Key>=' ')and(Length(Prm[Foc].Value)<250)Then Begin
     Prm[Foc].Value:=Prm[Foc].Value+E.Key;
     Redraw;
    End;
   End
    Else
   If(E.What=evDown)and(E.Btn=1)Then Begin
    If InRect(E.X,E.Y,BX,BY,BX+79,BY+21)Then Begin
     Res:=True;Done:=True;
    End
     Else
    If InRect(E.X,E.Y,BX+120,BY,BX+199,BY+21)Then Done:=True Else
    If InRect(E.X,E.Y,D.X+8,D.Y+24,D.X+D.W-9,D.Y+24+Rows*20-1)Then Begin
     I:=Top+(E.Y-D.Y-24)div 20;
     If(I>=0)and(I<N)Then Foc:=I;
     Redraw;
    End;
   End;
  End
   Else WaitTick;
 End;
 DlgClose(D);
 FlushEvents;
 FormDlg:=Res;
End;
{ ------------------------------------------------------------------ }
{ Menus, barre d'outils, panneau des couches, barre d'etat            }
{ ------------------------------------------------------------------ }

Type
 TToolBtn=Record
  Cmd:Integer;
  Icon:Integer;
  X:Integer;
  Hint:String[40];
 End;

Var
 TBtn:Array[1..20]of TToolBtn;
 NBtn:Integer;
 CurMenu:Integer;

Procedure ExecCmd(Cmd:Integer);Forward;

Procedure MenuBegin(Idx:Integer;Const Title:String;Hot,Alt:Byte);
Begin
 CurMenu:=Idx;
 Menus[Idx].Title:=Title;
 Menus[Idx].Hot:=Hot;
 Menus[Idx].AltKey:=Alt;
 Menus[Idx].N:=0;
 Menus[Idx].Hidden:=False;
End;

Procedure MI(Const Cap,Short:String;Cmd:Integer);
Begin
 With Menus[CurMenu]do Begin
  Items[N].Caption:=Cap;
  Items[N].Short:=Short;
  Items[N].Cmd:=Cmd;
  Inc(N);
 End;
End;

Procedure MSep;
Begin
 MI('','',cmNone);
End;

Procedure InitMenus;
Begin
 NMenus:=10;
 MenuBegin(0,'Projet',1,25);
 MI('Nouveau','Ctrl+N',cmNew);
 MI('Ouvrir...','Ctrl+O',cmOpen);
 MI('Projets recents...','',cmRecent);
 MI('Enregistrer','Ctrl+S',cmSave);
 MI('Enregistrer sous...','',cmSaveAs);
 MSep;
 MI('Exporter la carte en image...','',cmExportImage);
 MI('Exporter en DXF...','',cmExportDXF);
 MSep;
 MI('Proprietes du projet...','',cmProjProps);
 MSep;
 MI('Quitter','Ctrl+Q',cmQuit);

 MenuBegin(1,'Edition',1,18);
 MI('Selectionner tout','Ctrl+A',cmSelAll);
 MI('Deselectionner tout','Ctrl+D',cmDeselect);
 MI('Inverser la selection','',cmSelInvert);
 MI('Selectionner par expression...','',cmSelExpr);

 MenuBegin(2,'Vue',1,47);
 MI('Deplacer la carte','',cmToolPan);
 MI('Zoom avant','',cmToolZoomIn);
 MI('Zoom arriere','',cmToolZoomOut);
 MI('Identifier les entites','',cmToolIdentify);
 MI('Selectionner les entites','',cmToolSelect);
 MI('Mesurer une distance','',cmToolMeasure);
 MSep;
 MI('Zoom sur tout','Home',cmZoomAll);
 MI('Zoom sur la couche','',cmZoomLayer);
 MI('Zoom sur la selection','',cmZoomSel);
 MI('Zoom precedent','',cmZoomPrev);
 MI('Zoom suivant','',cmZoomNext);
 MSep;
 MI('Table d''attributs','F6',cmAttrTable);
 MI('Etiquettes','',cmLabels);
 MI('Grille','',cmGrid);
 MI('Panneau des couches','',cmPanel);
 MSep;
 MI('Rafraichir','F5',cmRefresh);

 MenuBegin(3,'Couche',1,46);
 MI('Ajouter une couche vecteur...','Ctrl+V',cmAddVector);
 MI('Ajouter un texte delimite...','Ctrl+T',cmAddCSV);
 MI('Ajouter une couche raster...','Ctrl+R',cmAddRaster);
 MSep;
 MI('Supprimer la couche','Suppr',cmRemoveLayer);
 MI('Monter la couche','',cmLayerUp);
 MI('Descendre la couche','',cmLayerDown);
 MI('Couche visible','',cmLayerVis);
 MI('Remplir les polygones','',cmLayerFill);
 MI('Changer la couleur','',cmLayerColor);
 MSep;
 MI('Enregistrer en GeoJSON...','',cmSaveLayer);
 MI('Proprietes de la couche...','',cmLayerProps);

 MenuBegin(4,'Reglages',1,19);
 MI('SCR du projet : EPSG:4326','',cmCrs4326);
 MI('SCR du projet : EPSG:3857','',cmCrs3857);
 MI('SCR de la couche active','',cmCrsLayer);
 MSep;
 MI('Couleur de fond...','',cmBackground);
 MI('Profil utilisateur...','',cmProfileInfo);
 MI('Options de lancement...','',cmCmdLine);

 MenuBegin(5,'Extensions',2,45);
 MI('Gestionnaire d''extensions...','',cmPlugins);
 MI('Executer un script Python...','',cmPython);

 MenuBegin(6,'Vecteur',5,20);
 MI('Tampon...','',cmVecBuffer);
 MI('Centroides...','',cmVecCentroids);
 MI('Enveloppe convexe...','',cmVecHull);
 MI('Simplifier...','',cmVecSimplify);
 MI('Reprojeter la couche...','',cmVecReproject);
 MI('Decouper...','',cmVecClip);
 MI('Dissoudre...','',cmVecDissolve);
 MI('Boites englobantes...','',cmVecBBox);
 MI('Polygones en lignes...','',cmVecPolyLines);
 MI('Etendue de la couche...','',cmVecExtent);

 MenuBegin(7,'Raster',3,30);
 MI('Ajouter une couche raster...','',cmAddRaster);
 MSep;
 MI('Pente...','',cmRasSlope);
 MI('Exposition...','',cmRasAspect);
 MI('Ombrage...','',cmRasHillshade);
 MI('Courbes de niveau...','',cmRasContour);
 MI('Combler les vides...','',cmRasFill);
 MI('Calculatrice raster...','',cmRasCalc);
 MI('Polygoniser...','',cmRasPolygonize);

 MenuBegin(8,'Traitement',4,23);
 MI('Boite a outils...','F9',cmToolbox);
 MI('Relancer le dernier algorithme','',cmProcLast);
 MSep;
 MI('Historique','',cmProcHistory);
 MI('Journal du dernier algorithme','',cmProcLog);

 MenuBegin(9,'Aide',3,32);
 MI('Aide en ligne de commande','F1',cmHelp);
 MI('Rechercher une mise a jour...','',cmUpdate);
 MSep;
 MI('A propos de QGIS...','',cmAbout);
End;

Function NameToMenu(Const N:String):Integer;
Var
 I:Integer;
Begin
 NameToMenu:=-1;
 For I:=0 to NMenus-1 do
  If StrUp(Menus[I].Title)=StrUp(N)Then NameToMenu:=I;
End;

{ Menus masques par le fichier custom.ini du profil (lignes HideMenu=nom) }
Procedure ApplyCustomization;
Var
 T:Text;
 S,K,V:String;
 P,I:Integer;
Begin
 If OptNoCustom Then Exit;
 Assign(T,JoinPath(ProfileDir,'custom.ini'));
 {$I-}Reset(T);{$I+}
 If IOResult<>0 Then Exit;
 While Not Eof(T)do Begin
  {$I-}ReadLn(T,S);{$I+}
  If IOResult<>0 Then S:='';
  P:=Pos('=',S);
  If P>1 Then Begin
   K:=StrLow(Trim(Copy(S,1,P-1)));
   V:=Trim(Copy(S,P+1,255));
   If K='hidemenu' Then Begin
    I:=NameToMenu(V);
    If(I>=0)and(I<>0)and(I<>NMenus-1)Then Menus[I].Hidden:=True;
   End;
  End;
 End;
 Close(T);
End;

Function ItemH(Var M:TMenu;I:Integer):Integer;
Begin
 If M.Items[I].Cmd=cmNone Then ItemH:=8 Else ItemH:=16;
End;

Function ItemTop(Var M:TMenu;I:Integer):Integer;
Var
 K,Y:Integer;
Begin
 Y:=3;
 For K:=0 to I-1 do Y:=Y+ItemH(M,K);
 ItemTop:=Y;
End;

Function MenuHeight(Var M:TMenu):Integer;
Begin
 MenuHeight:=ItemTop(M,M.N)+3;
End;

Procedure LayoutMenus;
Var
 I,K,X,W,L:Integer;
Begin
 X:=6;
 For I:=0 to NMenus-1 do
  If Not Menus[I].Hidden Then Begin
   Menus[I].X:=X;
   X:=X+Length(Menus[I].Title)*8+8;
   W:=0;
   For K:=0 to Menus[I].N-1 do Begin
    L:=Length(Menus[I].Items[K].Caption)*8+24;
    If Menus[I].Items[K].Short<>'' Then L:=L+16+Length(Menus[I].Items[K].Short)*8;
    If L>W Then W:=L;
   End;
   Menus[I].W:=W+16;
   Menus[I].DX:=Menus[I].X-4;
   If Menus[I].DX+Menus[I].W>ScrW-2 Then Menus[I].DX:=ScrW-2-Menus[I].W;
  End;
End;

Function LayerIsVector:Boolean;
Begin
 LayerIsVector:=(ActiveLay>=1)and(ActiveLay<=NLay)and(Lay[ActiveLay].Kind=lkVector);
End;

Function LayerIsRaster:Boolean;
Begin
 LayerIsRaster:=(ActiveLay>=1)and(ActiveLay<=NLay)and(Lay[ActiveLay].Kind=lkRaster);
End;

Function AnyVector:Boolean;
Var
 I:Integer;
Begin
 AnyVector:=False;
 For I:=1 to NLay do If Lay[I].Kind=lkVector Then AnyVector:=True;
End;

Function IsEnabled(Cmd:Integer):Boolean;
Begin
 Case Cmd of
  cmSelAll,cmDeselect,cmSelInvert,cmSelExpr,cmAttrTable,cmSaveLayer:IsEnabled:=LayerIsVector;
  cmZoomLayer,cmRemoveLayer,cmLayerVis,cmLayerColor,cmLayerProps,cmCrsLayer:IsEnabled:=ActiveLay>0;
  cmLayerFill:IsEnabled:=LayerIsVector;
  cmLayerUp:IsEnabled:=ActiveLay>1;
  cmLayerDown:IsEnabled:=(ActiveLay>0)and(ActiveLay<NLay);
  cmZoomSel:IsEnabled:=AnyVector;
  cmZoomPrev:IsEnabled:=HistPos>1;
  cmZoomNext:IsEnabled:=HistPos<HistN;
  cmExportDXF:IsEnabled:=AnyVector;
  cmRecent:IsEnabled:=NRecent>0;
  cmPlugins:IsEnabled:=Not OptNoPlugins and(QPath<>'');
  cmPython:IsEnabled:=Not OptNoPlugins;
  cmUpdate:IsEnabled:=Not OptNoVerCheck;
  cmVecBuffer..cmVecExtent,cmRasSlope..cmRasPolygonize,cmToolbox,cmProcLast,cmProcHistory,cmProcLog:
   IsEnabled:=QPath<>'';
  Else IsEnabled:=True;
 End;
End;

Function IsChecked(Cmd:Integer):Boolean;
Begin
 Case Cmd of
  cmToolPan:IsChecked:=Tool=tlPan;
  cmToolZoomIn:IsChecked:=Tool=tlZoomIn;
  cmToolZoomOut:IsChecked:=Tool=tlZoomOut;
  cmToolIdentify:IsChecked:=Tool=tlIdentify;
  cmToolSelect:IsChecked:=Tool=tlSelect;
  cmToolMeasure:IsChecked:=Tool=tlMeasure;
  cmLabels:IsChecked:=ShowLabels;
  cmGrid:IsChecked:=ShowGrid;
  cmPanel:IsChecked:=ShowPanel;
  cmCrs4326:IsChecked:=ProjCrsId=crs4326;
  cmCrs3857:IsChecked:=ProjCrsId=crs3857;
  cmLayerFill:IsChecked:=LayerIsVector and Lay[ActiveLay].Fill;
  cmLayerVis:IsChecked:=(ActiveLay>0)and Lay[ActiveLay].Visible;
  Else IsChecked:=False;
 End;
End;

{ ------------------------------------------------------------------ }
{ Barre de menus                                                      }
{ ------------------------------------------------------------------ }

Procedure DrawMenuBar;
Var
 I,X,W:Integer;
Begin
 HM;
 SetFillStyle(SolidFill,LightGray);
 Bar(0,0,ScrW-1,MenuH-1);
 SetColor(DarkGray);
 Line(0,MenuH-1,ScrW-1,MenuH-1);
 For I:=0 to NMenus-1 do
  If Not Menus[I].Hidden Then Begin
   X:=Menus[I].X;
   W:=Length(Menus[I].Title)*8;
   If MenuOpen=I Then Begin
    SetFillStyle(SolidFill,Blue);
    Bar(X-4,2,X+W+3,MenuH-3);
    Txt(X,6,White,Menus[I].Title);
    SetColor(White);
   End
    Else Begin
    Txt(X,6,Black,Menus[I].Title);
    SetColor(Black);
   End;
   Line(X+(Menus[I].Hot-1)*8,15,X+Menus[I].Hot*8-1,15);
  End;
 SM;
End;

Procedure DrawDropdown(M:Integer);
Var
 I,X,Y,W,H,IH:Integer;
 C:Byte;
Begin
 HM;
 X:=Menus[M].DX;
 W:=Menus[M].W;
 H:=MenuHeight(Menus[M]);
 Box3D(X,MenuH,X+W,MenuH+H,True);
 For I:=0 to Menus[M].N-1 do Begin
  Y:=MenuH+ItemTop(Menus[M],I);
  IH:=ItemH(Menus[M],I);
  If Menus[M].Items[I].Cmd=cmNone Then Begin
   SetColor(DarkGray);
   Line(X+3,Y+3,X+W-3,Y+3);
   SetColor(White);
   Line(X+3,Y+4,X+W-3,Y+4);
  End
   Else Begin
   If I=MenuSel Then Begin
    SetFillStyle(SolidFill,Blue);
    Bar(X+2,Y,X+W-2,Y+IH-1);
    C:=White;
   End
    Else Begin
    SetFillStyle(SolidFill,LightGray);
    Bar(X+2,Y,X+W-2,Y+IH-1);
    If IsEnabled(Menus[M].Items[I].Cmd)Then C:=Black Else C:=DarkGray;
   End;
   If IsChecked(Menus[M].Items[I].Cmd)Then Txt(X+6,Y+4,C,#251);
   Txt(X+18,Y+4,C,Menus[M].Items[I].Caption);
   If Menus[M].Items[I].Short<>'' Then
    Txt(X+W-8-Length(Menus[M].Items[I].Short)*8,Y+4,C,Menus[M].Items[I].Short);
  End;
 End;
 SM;
End;

Procedure CloseMenu;
Begin
 If MenuOpen<0 Then Exit;
 HM;
 If MenuSaveOk Then Begin
  RestoreRect(Menus[MenuOpen].DX,MenuH,MenuSave);
  MenuSaveOk:=False;
 End;
 MenuOpen:=-1;
 MenuSel:=-1;
 SM;
 DrawMenuBar;
End;

Procedure OpenMenu(M:Integer);
Var
 X,H:Integer;
Begin
 If(M<0)or(M>=NMenus)or Menus[M].Hidden Then Exit;
 If MenuOpen=M Then Exit;
 If MenuOpen>=0 Then CloseMenu;
 MenuOpen:=M;
 MenuSel:=-1;
 X:=Menus[M].DX;
 H:=MenuHeight(Menus[M]);
 HM;
 SaveRect(X,MenuH,Menus[M].W+2,H+2,MenuSave);
 MenuSaveOk:=True;
 SM;
 DrawMenuBar;
 DrawDropdown(M);
End;

Function MenuBarHit(X,Y:LongInt):Integer;
Var
 I:Integer;
Begin
 MenuBarHit:=-1;
 If Y>=MenuH Then Exit;
 For I:=0 to NMenus-1 do
  If Not Menus[I].Hidden Then
   If(X>=Menus[I].X-4)and(X<=Menus[I].X+Length(Menus[I].Title)*8+3)Then MenuBarHit:=I;
End;

Function MenuItemHit(M:Integer;X,Y:LongInt):Integer;
Var
 I:Integer;
 Yt:Integer;
Begin
 MenuItemHit:=-1;
 If(M<0)or(X<Menus[M].DX)or(X>Menus[M].DX+Menus[M].W)Then Exit;
 For I:=0 to Menus[M].N-1 do Begin
  Yt:=MenuH+ItemTop(Menus[M],I);
  If(Y>=Yt)and(Y<Yt+ItemH(Menus[M],I))and(Menus[M].Items[I].Cmd<>cmNone)Then MenuItemHit:=I;
 End;
End;

Procedure MenuMove(Step:Integer);
Var
 K,N:Integer;
Begin
 N:=Menus[MenuOpen].N;
 If MenuSel<0 Then Begin
  If Step>0 Then MenuSel:=-1 Else MenuSel:=N;
 End;
 For K:=1 to N do Begin
  MenuSel:=MenuSel+Step;
  If MenuSel<0 Then MenuSel:=N-1;
  If MenuSel>=N Then MenuSel:=0;
  If(Menus[MenuOpen].Items[MenuSel].Cmd<>cmNone)and IsEnabled(Menus[MenuOpen].Items[MenuSel].Cmd)Then Begin
   DrawDropdown(MenuOpen);
   Exit;
  End;
 End;
End;

Procedure MenuSwitchTo(Dir:Integer);
Var
 M,K:Integer;
Begin
 M:=MenuOpen;
 For K:=1 to NMenus do Begin
  M:=(M+Dir+NMenus)mod NMenus;
  If Not Menus[M].Hidden Then Begin
   OpenMenu(M);
   Exit;
  End;
 End;
End;

{ ------------------------------------------------------------------ }
{ Barre d'outils                                                      }
{ ------------------------------------------------------------------ }

Procedure AddBtn(Cmd,Icon:Integer;Const Hint:String);
Var
 X:Integer;
Begin
 If NBtn=0 Then X:=4 Else X:=TBtn[NBtn].X+26;
 Inc(NBtn);
 TBtn[NBtn].Cmd:=Cmd;
 TBtn[NBtn].Icon:=Icon;
 TBtn[NBtn].X:=X;
 TBtn[NBtn].Hint:=Hint;
End;

Procedure BtnGap;
Begin
 If NBtn>0 Then Inc(TBtn[NBtn].X,0);
End;

Procedure InitToolbar;
Begin
 NBtn:=0;
 AddBtn(cmNew,1,'Nouveau projet');
 AddBtn(cmOpen,2,'Ouvrir un projet');
 AddBtn(cmSave,3,'Enregistrer le projet');
 AddBtn(cmToolPan,4,'Deplacer la carte');
 TBtn[NBtn].X:=TBtn[NBtn].X+8;
 AddBtn(cmToolZoomIn,5,'Zoom avant');
 AddBtn(cmToolZoomOut,6,'Zoom arriere');
 AddBtn(cmToolIdentify,7,'Identifier les entites');
 AddBtn(cmToolSelect,8,'Selectionner les entites');
 AddBtn(cmToolMeasure,9,'Mesurer une distance');
 AddBtn(cmZoomAll,10,'Zoom sur tout');
 TBtn[NBtn].X:=TBtn[NBtn].X+8;
 AddBtn(cmZoomLayer,11,'Zoom sur la couche');
 AddBtn(cmZoomSel,12,'Zoom sur la selection');
 AddBtn(cmZoomPrev,13,'Zoom precedent');
 AddBtn(cmZoomNext,14,'Zoom suivant');
 AddBtn(cmAttrTable,15,'Table d''attributs');
 TBtn[NBtn].X:=TBtn[NBtn].X+8;
 AddBtn(cmToolbox,16,'Boite a outils de traitement');
End;

Procedure DrawIcon(X,Y,Ic:Integer);
Begin
 SetColor(Black);
 SetLineStyle(SolidLn,0,NormWidth);
 Case Ic of
  1:Begin
   Rectangle(X+3,Y+1,X+12,Y+14);
   Line(X+8,Y+1,X+12,Y+5);
   Line(X+8,Y+1,X+8,Y+5);
   Line(X+8,Y+5,X+12,Y+5);
  End;
  2:Begin
   Rectangle(X+1,Y+5,X+14,Y+13);
   Line(X+1,Y+5,X+3,Y+3);
   Line(X+3,Y+3,X+6,Y+3);
   Line(X+6,Y+3,X+7,Y+5);
   SetColor(Brown);
   Line(X+2,Y+7,X+13,Y+7);
  End;
  3:Begin
   Rectangle(X+2,Y+2,X+13,Y+13);
   Rectangle(X+5,Y+2,X+10,Y+6);
   Rectangle(X+4,Y+9,X+11,Y+13);
  End;
  4:Begin
   Line(X+8,Y+1,X+8,Y+14);
   Line(X+1,Y+8,X+14,Y+8);
   Line(X+8,Y+1,X+6,Y+3);Line(X+8,Y+1,X+10,Y+3);
   Line(X+8,Y+14,X+6,Y+12);Line(X+8,Y+14,X+10,Y+12);
   Line(X+1,Y+8,X+3,Y+6);Line(X+1,Y+8,X+3,Y+10);
   Line(X+14,Y+8,X+12,Y+6);Line(X+14,Y+8,X+12,Y+10);
  End;
  5,6:Begin
   Circle(X+6,Y+6,5);
   Line(X+10,Y+10,X+14,Y+14);
   Line(X+3,Y+6,X+9,Y+6);
   If Ic=5 Then Line(X+6,Y+3,X+6,Y+9);
  End;
  7:Begin
   Circle(X+8,Y+8,6);
   Line(X+8,Y+7,X+8,Y+11);
   PutPixel(X+8,Y+5,Black);
  End;
  8:Begin
   SetLineStyle(DottedLn,0,NormWidth);
   Rectangle(X+1,Y+2,X+11,Y+10);
   SetLineStyle(SolidLn,0,NormWidth);
   Line(X+7,Y+6,X+13,Y+14);
   Line(X+7,Y+6,X+7,Y+12);
   Line(X+7,Y+12,X+13,Y+14);
  End;
  9:Begin
   Line(X+1,Y+13,X+14,Y+2);
   Line(X+1,Y+13,X+1,Y+10);
   Line(X+4,Y+10,X+4,Y+8);
   Line(X+8,Y+7,X+8,Y+5);
   Line(X+12,Y+4,X+12,Y+2);
   SetColor(Red);
   PutPixel(X+1,Y+14,Red);PutPixel(X+14,Y+1,Red);
  End;
  10:Begin
   Circle(X+8,Y+8,6);
   Ellipse(X+8,Y+8,0,360,3,6);
   Line(X+2,Y+8,X+14,Y+8);
  End;
  11:Begin
   Rectangle(X+1,Y+2,X+9,Y+9);
   Circle(X+9,Y+9,4);
   Line(X+12,Y+12,X+15,Y+15);
  End;
  12:Begin
   SetLineStyle(DottedLn,0,NormWidth);
   Rectangle(X+1,Y+2,X+9,Y+9);
   SetLineStyle(SolidLn,0,NormWidth);
   Circle(X+9,Y+9,4);
   Line(X+12,Y+12,X+15,Y+15);
   SetColor(Red);
   Rectangle(X+3,Y+4,X+6,Y+7);
  End;
  13:Begin
   Line(X+2,Y+8,X+13,Y+8);
   Line(X+2,Y+8,X+6,Y+4);
   Line(X+2,Y+8,X+6,Y+12);
  End;
  14:Begin
   Line(X+2,Y+8,X+13,Y+8);
   Line(X+13,Y+8,X+9,Y+4);
   Line(X+13,Y+8,X+9,Y+12);
  End;
  15:Begin
   Rectangle(X+1,Y+2,X+14,Y+13);
   Line(X+1,Y+6,X+14,Y+6);
   Line(X+1,Y+10,X+14,Y+10);
   Line(X+6,Y+2,X+6,Y+13);
   Line(X+10,Y+2,X+10,Y+13);
  End;
  16:Begin
   Circle(X+8,Y+8,4);
   Circle(X+8,Y+8,1);
   Line(X+8,Y+1,X+8,Y+4);Line(X+8,Y+12,X+8,Y+15);
   Line(X+1,Y+8,X+4,Y+8);Line(X+12,Y+8,X+15,Y+8);
   Line(X+3,Y+3,X+5,Y+5);Line(X+11,Y+11,X+13,Y+13);
   Line(X+13,Y+3,X+11,Y+5);Line(X+3,Y+13,X+5,Y+11);
  End;
 End;
End;

Procedure DrawToolbar;
Var
 I:Integer;
 Down,En:Boolean;
Begin
 HM;
 SetFillStyle(SolidFill,LightGray);
 Bar(0,MenuH,ScrW-1,MenuH+ToolH-1);
 SetColor(DarkGray);
 Line(0,MenuH+ToolH-1,ScrW-1,MenuH+ToolH-1);
 For I:=1 to NBtn do Begin
  Down:=IsChecked(TBtn[I].Cmd)and(TBtn[I].Cmd>=cmToolPan)and(TBtn[I].Cmd<=cmToolMeasure);
  En:=IsEnabled(TBtn[I].Cmd);
  If Down Then Box3D(TBtn[I].X,MenuH+2,TBtn[I].X+23,MenuH+25,False)
          Else Box3D(TBtn[I].X,MenuH+2,TBtn[I].X+23,MenuH+25,True);
  DrawIcon(TBtn[I].X+4+Ord(Down),MenuH+6+Ord(Down),TBtn[I].Icon);
  If Not En Then Begin
   { Bouton inactif : trame grisee }
   SetColor(LightGray);
   SetLineStyle(DottedLn,0,NormWidth);
   Rectangle(TBtn[I].X+3,MenuH+5,TBtn[I].X+20,MenuH+22);
   SetLineStyle(SolidLn,0,NormWidth);
  End;
 End;
 SM;
End;

Function ToolbarHit(X,Y:LongInt):Integer;
Var
 I:Integer;
Begin
 ToolbarHit:=0;
 If(Y<MenuH)or(Y>=MenuH+ToolH)Then Exit;
 For I:=1 to NBtn do
  If(X>=TBtn[I].X)and(X<=TBtn[I].X+23)Then ToolbarHit:=I;
End;

{ ------------------------------------------------------------------ }
{ Panneau des couches et barre d'etat                                 }
{ ------------------------------------------------------------------ }

Procedure DrawPanel;
Var
 I,Y:Integer;
 S:String;
 FC:Byte;
Begin
 If Not ShowPanel Then Exit;
 HM;
 SetFillStyle(SolidFill,LightGray);
 Bar(0,MenuH+ToolH,PanelW-1,ScrH-StatH-1);
 Box3D(0,MenuH+ToolH,PanelW-1,MenuH+ToolH+14,True);
 Txt(6,MenuH+ToolH+4,Black,'Couches');
 Sunken(2,MenuH+ToolH+17,PanelW-3,ScrH-StatH-3,White);
 For I:=1 to NLay do Begin
  Y:=MenuH+ToolH+20+(I-1)*RowH;
  If Y+RowH>ScrH-StatH-3 Then Exit;
  If I=ActiveLay Then Begin
   SetFillStyle(SolidFill,Blue);
   Bar(4,Y-1,PanelW-5,Y+RowH-3);
   FC:=White;
  End
   Else FC:=Black;
  { Case a cocher }
  SetColor(Black);
  Rectangle(7,Y,16,Y+9);
  If I=ActiveLay Then SetColor(White);
  If Lay[I].Visible Then Begin
   Line(9,Y+4,11,Y+7);
   Line(11,Y+7,14,Y+2);
  End;
  { Symbole de la couche }
  If Lay[I].Kind=lkRaster Then Begin
   SetFillStyle(SolidFill,LightCyan);
   Bar(20,Y,28,Y+8);
   SetColor(Black);
   Rectangle(20,Y,28,Y+8);
   Line(20,Y+4,28,Y+4);
   Line(24,Y,24,Y+8);
  End
   Else
  Begin
   SetFillStyle(SolidFill,Lay[I].Color);
   SetColor(LayerDark[Lay[I].Color and 15]);
   Case Lay[I].GType of
    gkLine:Begin
     Line(20,Y+8,28,Y);
     Line(20,Y+7,28,Y-1);
    End;
    gkPoint:Begin
     Bar(22,Y+2,26,Y+6);
     Rectangle(21,Y+1,27,Y+7);
    End;
    Else Begin
     Bar(20,Y,28,Y+8);
     Rectangle(20,Y,28,Y+8);
    End;
   End;
  End;
  S:=Copy(Lay[I].Name,1,(PanelW-38)div 8);
  Txt(32,Y+1,FC,S);
 End;
 SM;
End;

Function PanelHit(X,Y:LongInt;Var OnCheck:Boolean):Integer;
Var
 I:Integer;
 Yt:Integer;
Begin
 PanelHit:=0;
 OnCheck:=False;
 If Not ShowPanel Then Exit;
 If(X<0)or(X>=PanelW)Then Exit;
 For I:=1 to NLay do Begin
  Yt:=MenuH+ToolH+20+(I-1)*RowH-1;
  If(Y>=Yt)and(Y<Yt+RowH)Then Begin
   PanelHit:=I;
   OnCheck:=(X>=5)and(X<=18);
  End;
 End;
End;

Procedure DrawStatusMsg;
Begin
 HM;
 SetFillStyle(SolidFill,LightGray);
 Bar(0,ScrH-StatH,ScrW-1,ScrH-StatH+14);
 Txt(6,ScrH-StatH+4,Black,Copy(StatusMsg,1,(ScrW-12)div 8));
 SM;
End;

Procedure SetMsg(Const S:String);
Begin
 StatusMsg:=S;
 If GraphOn Then DrawStatusMsg;
End;

Procedure DrawStatusInfo;
Var
 Y:Integer;
 S:String;
Begin
 HM;
 Y:=ScrH-StatH+15;
 SetFillStyle(SolidFill,LightGray);
 Bar(0,Y,ScrW-1,ScrH-1);
 Sunken(2,Y,2+30*8+8,ScrH-2,LightGray);
 S:=CoordStr(LastMapX,LastMapY);
 Txt(6,Y+4,Black,Copy(S,1,30));
 Sunken(268,Y,268+20*8+8,ScrH-2,LightGray);
 S:='Echelle 1:'+RealStr(ScaleDenom,0);
 Txt(272,Y+4,Black,Copy(S,1,20));
 Sunken(444,Y,444+14*8+8,ScrH-2,LightGray);
 Txt(448,Y+4,Black,Copy(ProjCRS,1,14));
 Sunken(564,Y,ScrW-3,ScrH-2,LightGray);
 If Dirty Then Txt(568,Y+4,Red,'modifie');
 SM;
End;

Procedure RedrawMapArea;
Begin
 HM;
 SetupCanvas;
 RenderMap;
 SM;
 DrawStatusInfo;
End;

Procedure RedrawAll;
Begin
 HM;
 If MenuOpen>=0 Then Begin
  If MenuSaveOk Then Begin
   RestoreRect(Menus[MenuOpen].DX,MenuH,MenuSave);
   MenuSaveOk:=False;
  End;
  MenuOpen:=-1;
 End;
 SetFillStyle(SolidFill,LightGray);
 Bar(0,0,ScrW-1,ScrH-1);
 SetupCanvas;
 DrawMenuBar;
 DrawToolbar;
 DrawPanel;
 RenderMap;
 DrawStatusMsg;
 DrawStatusInfo;
 SM;
End;

Procedure RedrawPanelAndTools;
Begin
 DrawToolbar;
 DrawPanel;
 DrawStatusInfo;
End;
{ ------------------------------------------------------------------ }
{ Interrogation des entites, selection, table d'attributs            }
{ ------------------------------------------------------------------ }

Type
 POrdArr=^TOrdArr;
 TOrdArr=Array[1..MaxFeat]of LongInt;

Var
 AttrZoom:Boolean;

{ Choix dans une liste de lignes ; Sel recoit l'index choisi }
Function SmallPickL(Const Title:String;P:PLineList;N:Integer;Var Sel:Integer):Boolean;
Var
 D:TDlg;
 Lb:TListBox;
 E:TEvent;
 I,W:Integer;
 Done,Res:Boolean;
 BX,BY,R,H:LongInt;
Begin
 W:=0;
 For I:=1 to N do If Length(P^[I]^)>W Then W:=Length(P^[I]^);
 H:=N*12+86;
 If H>ScrH-60 Then H:=ScrH-60;
 If W*8+60<260 Then W:=(260-60)div 8;
 If W*8+60>ScrW-40 Then W:=(ScrW-100)div 8;
 DlgOpen(D,W*8+60,H,Title);
 LbInit(Lb,D.X+8,D.Y+24,D.W-16,D.H-66);
 If(Sel>=1)and(Sel<=N)Then Lb.Sel:=Sel;
 LbFix(Lb,N);
 BX:=D.X+D.W div 2-70;
 BY:=D.Y+D.H-30;
 HM;
 DrawButton(BX,BY,60,22,'OK',False);
 DrawButton(BX+80,BY,60,22,'Annuler',False);
 SM;
 LbDraw(Lb,P,N,False);
 Done:=False;Res:=False;
 While Not Done do Begin
  If GetEvent(E)Then Begin
   If E.What=evKey Then Begin
    If E.Ext Then Begin
     If LbKey(Lb,N,E)Then LbDraw(Lb,P,N,False);
    End
     Else
    If E.Key=#27 Then Done:=True Else
    If E.Key=#13 Then Begin
     Res:=True;Done:=True;
    End;
   End
    Else
   If(E.What=evDown)and(E.Btn=1)Then Begin
    If InRect(E.X,E.Y,BX,BY,BX+59,BY+21)Then Begin
     Res:=True;Done:=True;
    End
     Else
    If InRect(E.X,E.Y,BX+80,BY,BX+139,BY+21)Then Done:=True Else Begin
     R:=LbClick(Lb,E.X,E.Y,N);
     If R>0 Then LbDraw(Lb,P,N,False);
     If(R=1)and E.Dbl Then Begin
      Res:=True;Done:=True;
     End;
    End;
   End;
  End
   Else WaitTick;
 End;
 DlgClose(D);
 If Res Then Sel:=Lb.Sel;
 FlushEvents;
 SmallPickL:=Res;
End;

{ Choix dans une courte liste (elements separes par '|') }
Function SmallPick(Const Title,Items:String;Var Sel:Integer):Boolean;
Var
 P:PLineList;
 N:Integer;
Begin
 TextToLines(Items,250,P,N);
 SmallPick:=SmallPickL(Title,P,N,Sel);
 FreeLines(P,N);
End;

{ ------------------------------------------------------------------ }
{ Geometrie ecran : recherche d'entites                               }
{ ------------------------------------------------------------------ }

Function SegDist(PX,PY,X1,Y1,X2,Y2:Double):Double;
Var
 DX,DY,T,L2:Double;
Begin
 DX:=X2-X1;DY:=Y2-Y1;
 L2:=DX*DX+DY*DY;
 If L2<=0 Then T:=0 Else T:=((PX-X1)*DX+(PY-Y1)*DY)/L2;
 If T<0 Then T:=0;
 If T>1 Then T:=1;
 SegDist:=Sqrt(Sqr(PX-(X1+T*DX))+Sqr(PY-(Y1+T*DY)));
End;

{ Distance en pixels d'un point a l'entite deja projetee dans ScPts }
Function ScreenDist(Kind:Byte;PX,PY:Double):Double;
Var
 P,I,A,B,J,Cr:LongInt;
 D,Best,Y1,Y2,X1,X2:Double;
Begin
 Best:=1E30;
 A:=0;
 Cr:=0;
 For P:=0 to ScParts-1 do Begin
  B:=ScEnds^[P];
  If Kind=gkPoint Then Begin
   For I:=A to B-1 do Begin
    D:=Sqrt(Sqr(PX-ScPts^[I].X)+Sqr(PY-ScPts^[I].Y));
    If D<Best Then Best:=D;
   End;
  End
   Else
  Begin
   For I:=A to B-1 do Begin
    If I=B-1 Then Begin
     If Kind=gkPoly Then J:=A Else J:=-1;
    End
     Else J:=I+1;
    If J>=0 Then Begin
     X1:=ScPts^[I].X;Y1:=ScPts^[I].Y;X2:=ScPts^[J].X;Y2:=ScPts^[J].Y;
     D:=SegDist(PX,PY,X1,Y1,X2,Y2);
     If D<Best Then Best:=D;
     If Kind=gkPoly Then
      If(Y1<=PY)<>(Y2<=PY)Then
       If PX<X1+(PY-Y1)/(Y2-Y1)*(X2-X1)Then Inc(Cr);
    End;
   End;
  End;
  A:=B;
 End;
 If(Kind=gkPoly)and Odd(Cr)Then Best:=0;
 ScreenDist:=Best;
End;

Function FeatureAt(Var L:TLayer;PX,PY,Tol:Double):LongInt;
Var
 I,Found:LongInt;
 F:PFeature;
 D,Best:Double;
Begin
 Found:=0;
 Best:=Tol+1;
 For I:=1 to L.NF do Begin
  F:=L.Feats^[I];
  If(F^.Kind<>gkNone)and FeatInView(L,F)Then Begin
   FeatToScreen(L,F);
   D:=ScreenDist(F^.Kind,PX,PY);
   If(D<=Tol)and(D<Best)Then Begin
    Best:=D;
    Found:=I;
   End;
  End;
 End;
 FeatureAt:=Found;
End;

Function FeatureHitsRect(F:PFeature;RL,RT,RR,RB:Double):Boolean;
Var
 P,I,A,B,Cr,J:LongInt;
 X1,Y1,X2,Y2,CxR,CyR:Double;
 Hit:Boolean;
Begin
 FeatureHitsRect:=False;
 Hit:=False;
 A:=0;
 Cr:=0;
 CxR:=(RL+RR)/2;CyR:=(RT+RB)/2;
 For P:=0 to ScParts-1 do Begin
  B:=ScEnds^[P];
  For I:=A to B-1 do Begin
   X1:=ScPts^[I].X;Y1:=ScPts^[I].Y;
   If(X1>=RL)and(X1<=RR)and(Y1>=RT)and(Y1<=RB)Then Hit:=True;
   If F^.Kind<>gkPoint Then Begin
    If I=B-1 Then Begin
     If F^.Kind=gkPoly Then J:=A Else J:=-1;
    End
     Else J:=I+1;
    If J>=0 Then Begin
     X2:=ScPts^[J].X;Y2:=ScPts^[J].Y;
     If ClipSeg(X1,Y1,X2,Y2,RL,RT,RR,RB)Then Hit:=True;
     X1:=ScPts^[I].X;Y1:=ScPts^[I].Y;X2:=ScPts^[J].X;Y2:=ScPts^[J].Y;
     If F^.Kind=gkPoly Then
      If(Y1<=CyR)<>(Y2<=CyR)Then
       If CxR<X1+(CyR-Y1)/(Y2-Y1)*(X2-X1)Then Inc(Cr);
    End;
   End;
  End;
  A:=B;
 End;
 If(F^.Kind=gkPoly)and Odd(Cr)Then Hit:=True;
 FeatureHitsRect:=Hit;
End;

Function SelectInRect(Var L:TLayer;X1,Y1,X2,Y2:Double;Add:Boolean):LongInt;
Var
 I,N:LongInt;
 F:PFeature;
 T:Double;
Begin
 If X1>X2 Then Begin T:=X1;X1:=X2;X2:=T;End;
 If Y1>Y2 Then Begin T:=Y1;Y1:=Y2;Y2:=T;End;
 N:=0;
 For I:=1 to L.NF do Begin
  F:=L.Feats^[I];
  If Not Add Then F^.Sel:=False;
  If(F^.Kind<>gkNone)and FeatInView(L,F)Then Begin
   FeatToScreen(L,F);
   If FeatureHitsRect(F,X1,Y1,X2,Y2)Then Begin
    F^.Sel:=True;
   End;
  End;
  If F^.Sel Then Inc(N);
 End;
 SelectInRect:=N;
End;

Function CountSelected(Var L:TLayer):LongInt;
Var
 I,N:LongInt;
Begin
 N:=0;
 If L.Kind=lkVector Then
  For I:=1 to L.NF do If L.Feats^[I]^.Sel Then Inc(N);
 CountSelected:=N;
End;

Function TotalSelected:LongInt;
Var
 I:Integer;
 N:LongInt;
Begin
 N:=0;
 For I:=1 to NLay do N:=N+CountSelected(Lay[I]);
 TotalSelected:=N;
End;

Procedure ClearSelection;
Var
 I:Integer;
 J:LongInt;
Begin
 For I:=1 to NLay do
  If Lay[I].Kind=lkVector Then
   For J:=1 to Lay[I].NF do Lay[I].Feats^[J]^.Sel:=False;
End;

{ Selection par expression simple : champ OP valeur }
Function SelectByExpr(Var L:TLayer;Const Expr:String):LongInt;
Const
 Ops:Array[1..7]of String[6]=('<=','>=','!=','<>',' like ','=','<');
Var
 I,N:LongInt;
 K,P,OpIdx:Integer;
 Fld,Val1,Op,U,V:String;
 FI:Integer;
 A,B:Double;
 Num,Ok:Boolean;
 F:PFeature;
 C:Integer;
Begin
 SelectByExpr:=-1;
 U:=StrLow(Expr);
 OpIdx:=0;P:=0;
 For K:=1 to 7 do
  If OpIdx=0 Then Begin
   P:=Pos(Ops[K],U);
   If P>1 Then OpIdx:=K;
  End;
 If OpIdx=0 Then Begin
  P:=Pos('>',U);
  If P>1 Then Begin
   OpIdx:=8;
  End;
 End;
 If OpIdx=0 Then Exit;
 Fld:=Trim(Copy(Expr,1,P-1));
 If OpIdx=8 Then Begin
  Op:='>';
  Val1:=Trim(Copy(Expr,P+1,255));
 End
  Else
 Begin
  Op:=Trim(Ops[OpIdx]);
  Val1:=Trim(Copy(Expr,P+Length(Ops[OpIdx]),255));
 End;
 If Op='<>' Then Op:='!=';
 If(Length(Val1)>=2)and(Val1[1] in['''','"'])Then Val1:=Copy(Val1,2,Length(Val1)-2);
 If(Length(Fld)>=2)and(Fld[1]='"')Then Fld:=Copy(Fld,2,Length(Fld)-2);
 FI:=0;
 For K:=1 to L.NFld do If StrUp(L.Fld[K])=StrUp(Fld)Then FI:=K;
 If FI=0 Then Exit;
 N:=0;
 For I:=1 to L.NF do Begin
  F:=L.Feats^[I];
  V:=FeatAttr(L,F,FI);
  Num:=StrToReal(V,A)and StrToReal(Val1,B);
  If Num Then Begin
   If A<B Then C:=-1 Else If A>B Then C:=1 Else C:=0;
  End
   Else Begin
   If StrUp(V)<StrUp(Val1)Then C:=-1 Else If StrUp(V)>StrUp(Val1)Then C:=1 Else C:=0;
  End;
  Ok:=False;
  If Op='=' Then Ok:=C=0 Else
  If Op='!=' Then Ok:=C<>0 Else
  If Op='<' Then Ok:=C<0 Else
  If Op='>' Then Ok:=C>0 Else
  If Op='<=' Then Ok:=C<=0 Else
  If Op='>=' Then Ok:=C>=0 Else
  If Op='like' Then Ok:=Pos(StrUp(Val1),StrUp(V))>0;
  F^.Sel:=Ok;
  If Ok Then Inc(N);
 End;
 SelectByExpr:=N;
End;

Procedure InvertSelection(Var L:TLayer);
Var
 I:LongInt;
Begin
 For I:=1 to L.NF do L.Feats^[I]^.Sel:=Not L.Feats^[I]^.Sel;
End;

{ ------------------------------------------------------------------ }
{ Mesures et description des entites                                  }
{ ------------------------------------------------------------------ }

Function RingLength(Var L:TLayer;F:PFeature;A,B:LongInt;Closed:Boolean):Double;
Var
 I:LongInt;
 S:Double;
 Function Seg(P,Q:TPt):Double;
 Var
  X1,Y1,X2,Y2:Double;
 Begin
  X1:=P.X;Y1:=P.Y;X2:=Q.X;Y2:=Q.Y;
  If L.CrsId=crs3857 Then Begin
   XfPt(crs3857,crs4326,X1,Y1);
   XfPt(crs3857,crs4326,X2,Y2);
   Seg:=GeoDist(X1,Y1,X2,Y2);
  End
   Else
  If L.CrsId=crs4326 Then Seg:=GeoDist(X1,Y1,X2,Y2)
                     Else Seg:=Sqrt(Sqr(X2-X1)+Sqr(Y2-Y1));
 End;
Begin
 S:=0;
 For I:=A to B-2 do S:=S+Seg(F^.Pts^[I],F^.Pts^[I+1]);
 If Closed and(B-A>2)Then S:=S+Seg(F^.Pts^[B-1],F^.Pts^[A]);
 RingLength:=S;
End;

Function RingArea(Var L:TLayer;F:PFeature;A,B:LongInt):Double;
Const
 R=6371008.8;
Var
 I,J:LongInt;
 S,X1,Y1,X2,Y2:Double;
Begin
 S:=0;
 For I:=A to B-1 do Begin
  If I=B-1 Then J:=A Else J:=I+1;
  X1:=F^.Pts^[I].X;Y1:=F^.Pts^[I].Y;X2:=F^.Pts^[J].X;Y2:=F^.Pts^[J].Y;
  If L.CrsId=crs3857 Then Begin
   XfPt(crs3857,crs4326,X1,Y1);
   XfPt(crs3857,crs4326,X2,Y2);
  End;
  If L.CrsId<>crsOther Then
   S:=S+(X2-X1)*Pi/180*(2+Sin(Y1*Pi/180)+Sin(Y2*Pi/180))
  Else S:=S+(X1*Y2-X2*Y1)*2;
 End;
 If L.CrsId<>crsOther Then RingArea:=Abs(S)*R*R/2 Else RingArea:=Abs(S)/2;
End;

Procedure FeatureMeasures(Var L:TLayer;F:PFeature;Var Len,Area:Double);
Var
 P,A,B:LongInt;
Begin
 Len:=0;Area:=0;
 A:=0;
 For P:=0 to F^.NParts-1 do Begin
  B:=F^.Ends^[P];
  If F^.Kind=gkLine Then Len:=Len+RingLength(L,F,A,B,False) Else
  If F^.Kind=gkPoly Then Begin
   Len:=Len+RingLength(L,F,A,B,True);
   If F^.Outer^[P]=1 Then Area:=Area+RingArea(L,F,A,B)
                     Else Area:=Area-RingArea(L,F,A,B);
  End;
  A:=B;
 End;
End;

Function GeomLabel(K:Byte):String;
Begin
 Case K of
  gkPoint:GeomLabel:='Point';
  gkLine:GeomLabel:='Ligne';
  gkPoly:GeomLabel:='Polygone';
  Else GeomLabel:='Sans geometrie';
 End;
End;

Procedure IdentifyFeature(LIdx:Integer;FIdx:LongInt);
Var
 P:PLineList;
 N,I:Integer;
 F:PFeature;
 Len,Area:Double;
 U,S:String;
Begin
 F:=Lay[LIdx].Feats^[FIdx];
 NewLines(P,N);
 AddLine(P,N,'Couche   : '+Lay[LIdx].Name);
 AddLine(P,N,'Entite   : '+IntStr(FIdx)+' / '+IntStr(Lay[LIdx].NF));
 AddLine(P,N,'Geometrie: '+GeomLabel(F^.Kind));
 If Lay[LIdx].CrsId=crsOther Then U:=' (unites de la couche)' Else U:='';
 If F^.Kind=gkPoint Then
  AddLine(P,N,'X, Y     : '+NumStr(F^.Pts^[0].X)+', '+NumStr(F^.Pts^[0].Y));
 If F^.Kind in[gkLine,gkPoly]Then Begin
  FeatureMeasures(Lay[LIdx],F,Len,Area);
  If F^.Kind=gkPoly Then S:='Perimetre: ' Else S:='Longueur : ';
  If Lay[LIdx].CrsId=crsOther Then AddLine(P,N,S+RealStr(Len,3)+U)
  Else AddLine(P,N,S+RealStr(Len/1000,3)+' km');
  If F^.Kind=gkPoly Then Begin
   If Lay[LIdx].CrsId=crsOther Then AddLine(P,N,'Aire     : '+RealStr(Area,3)+U)
   Else AddLine(P,N,'Aire     : '+RealStr(Area/1000000,3)+' km2');
  End;
 End;
 AddLine(P,N,'Sommets  : '+IntStr(F^.NPts)+' dans '+IntStr(F^.NParts)+' partie(s)');
 AddLine(P,N,'');
 AddLine(P,N,'Attributs :');
 For I:=1 to Lay[LIdx].NFld do
  AddLine(P,N,'  '+PadR(Lay[LIdx].Fld[I],14)+' = '+FeatAttr(Lay[LIdx],F,I));
 ViewLines('Resultats de l''identification',P,N,520,300);
 FreeLines(P,N);
End;

Procedure IdentifyRaster(LIdx:Integer;MX,MY:Double);
Var
 X,Y,V:Double;
 C,R:LongInt;
 S:String;
Begin
 X:=MX;Y:=MY;
 If Lay[LIdx].CrsId<>ProjCrsId Then XfPt(ProjCrsId,Lay[LIdx].CrsId,X,Y);
 C:=Trunc((X-Lay[LIdx].RX0)/Lay[LIdx].RCell);
 R:=Trunc((Lay[LIdx].RY0-Y)/Lay[LIdx].RCell);
 If(X<Lay[LIdx].RX0)or(Y>Lay[LIdx].RY0)or(C<0)or(C>=Lay[LIdx].RW)or(R<0)or(R>=Lay[LIdx].RH)Then
  SetMsg('Hors de la couche raster '+Lay[LIdx].Name)
 Else Begin
  V:=Lay[LIdx].RData^[R*Lay[LIdx].RW+C];
  If V<-1E29 Then S:='aucune donnee' Else S:=NumStr(V);
  SetMsg(Lay[LIdx].Name+' : colonne '+IntStr(C+1)+', ligne '+IntStr(R+1)+', valeur = '+S);
 End;
End;

Procedure LayerProperties(I:Integer);
Var
 P:PLineList;
 N,K:Integer;
 S:String;
Begin
 If(I<1)or(I>NLay)Then Exit;
 NewLines(P,N);
 AddLine(P,N,'Nom      : '+Lay[I].Name);
 AddLine(P,N,'Source   : '+Lay[I].Source);
 AddLine(P,N,'SCR      : '+Lay[I].CRS);
 If Lay[I].Kind=lkRaster Then Begin
  AddLine(P,N,'Type     : Raster (grille ASCII)');
  AddLine(P,N,'Taille   : '+IntStr(Lay[I].RW)+' x '+IntStr(Lay[I].RH)+' cellules');
  AddLine(P,N,'Cellule  : '+NumStr(Lay[I].RCell));
  AddLine(P,N,'Minimum  : '+NumStr(Lay[I].RMin));
  AddLine(P,N,'Maximum  : '+NumStr(Lay[I].RMax));
 End
  Else
 Begin
  AddLine(P,N,'Type     : Vecteur - '+GeomLabel(Lay[I].GType));
  AddLine(P,N,'Entites  : '+IntStr(Lay[I].NF)+' ('+IntStr(CountSelected(Lay[I]))+' selectionnee(s))');
  AddLine(P,N,'Champs   : '+IntStr(Lay[I].NFld));
 End;
 If Lay[I].HasExt Then Begin
  AddLine(P,N,'Etendue  :');
  AddLine(P,N,'   X de '+NumStr(Lay[I].MinX)+' a '+NumStr(Lay[I].MaxX));
  AddLine(P,N,'   Y de '+NumStr(Lay[I].MinY)+' a '+NumStr(Lay[I].MaxY));
 End;
 If Lay[I].Kind=lkVector Then Begin
  AddLine(P,N,'');
  AddLine(P,N,'Champs :');
  For K:=1 to Lay[I].NFld do Begin
   S:='  '+PadR(Lay[I].Fld[K],24);
   If K=Lay[I].LblFld Then S:=S+' (etiquette)';
   AddLine(P,N,S);
  End;
 End;
 ViewLines('Proprietes de la couche',P,N,520,300);
 FreeLines(P,N);
End;

{ ------------------------------------------------------------------ }
{ Table d'attributs                                                   }
{ ------------------------------------------------------------------ }

Function AttrLess(Var L:TLayer;Col:Integer;A,B:LongInt;Desc:Boolean):Boolean;
Var
 SA,SB:String;
 NA,NB:Double;
 R:Boolean;
Begin
 If Col=0 Then Begin
  NA:=A;NB:=B;
  R:=NA<NB;
 End
  Else
 Begin
  SA:=FeatAttr(L,L.Feats^[A],Col);
  SB:=FeatAttr(L,L.Feats^[B],Col);
  If StrToReal(SA,NA)and StrToReal(SB,NB)Then R:=NA<NB
  Else R:=StrUp(SA)<StrUp(SB);
 End;
 If Desc Then AttrLess:=Not R and(A<>B) Else AttrLess:=R;
End;

Procedure SortOrder(Var L:TLayer;OrdA:POrdArr;Col:Integer;Desc:Boolean);
Var
 Gap,I,J,T:LongInt;
Begin
 Gap:=L.NF div 2;
 While Gap>0 do Begin
  For I:=Gap+1 to L.NF do Begin
   T:=OrdA^[I];
   J:=I;
   While(J>Gap)and AttrLess(L,Col,T,OrdA^[J-Gap],Desc)do Begin
    OrdA^[J]:=OrdA^[J-Gap];
    J:=J-Gap;
   End;
   OrdA^[J]:=T;
  End;
  Gap:=Gap div 2;
 End;
End;

Procedure AttrTable(LIdx:Integer);
Var
 D:TDlg;
 E:TEvent;
 OrdA:POrdArr;
 I,K:LongInt;
 Done:Boolean;
 Top,Cur,Rows,ColOff,NCol:LongInt;
 ColW:Array[0..MaxFields]of Integer;
 SortCol:Integer;
 SortDesc:Boolean;
 BY:LongInt;
 W,H:LongInt;
 Procedure ComputeWidths;
 Var
  C,R,M,Lim:LongInt;
  S:String;
 Begin
  ColW[0]:=7;
  For C:=1 to Lay[LIdx].NFld do Begin
   M:=Length(Lay[LIdx].Fld[C]);
   Lim:=Lay[LIdx].NF;
   If Lim>100 Then Lim:=100;
   For R:=1 to Lim do Begin
    S:=FeatAttr(Lay[LIdx],Lay[LIdx].Feats^[R],C);
    If Length(S)>M Then M:=Length(S);
   End;
   If M>22 Then M:=22;
   ColW[C]:=M+1;
  End;
 End;
 Procedure Redraw;
 Var
  R,C,X,Y,Idx,Fi:LongInt;
  S:String;
  Sel:Boolean;
  Fg:Byte;
  Nsel:LongInt;
 Begin
  HM;
  SetFillStyle(SolidFill,LightGray);
  Bar(D.X+4,D.Y+20,D.X+W-5,D.Y+H-4);
  { En-tete }
  X:=D.X+8;
  Y:=D.Y+24;
  For C:=ColOff to NCol-1 do Begin
   If X+ColW[C]*8+4>D.X+W-24 Then C:=NCol Else Begin
    Box3D(X,Y,X+ColW[C]*8+3,Y+13,True);
    If C=0 Then S:='fid' Else S:=Lay[LIdx].Fld[C];
    If C=SortCol Then Begin
     If SortDesc Then S:=Copy(S,1,ColW[C]-1)+#31 Else S:=Copy(S,1,ColW[C]-1)+#30;
    End;
    Txt(X+2,Y+3,Black,Copy(S,1,ColW[C]));
    X:=X+ColW[C]*8+4;
   End;
  End;
  { Lignes }
  Sunken(D.X+8,Y+14,D.X+W-9,Y+14+Rows*12+3,White);
  For R:=0 to Rows-1 do Begin
   Idx:=Top+R;
   If Idx<=Lay[LIdx].NF Then Begin
    Fi:=OrdA^[Idx];
    Sel:=Lay[LIdx].Feats^[Fi]^.Sel;
    Y:=D.Y+24+14+2+R*12;
    If Sel Then Begin
     SetFillStyle(SolidFill,Blue);
     Fg:=White;
    End
     Else Begin
     If Idx=Cur Then SetFillStyle(SolidFill,LightCyan) Else SetFillStyle(SolidFill,White);
     Fg:=Black;
    End;
    Bar(D.X+9,Y-1,D.X+W-10,Y+10);
    X:=D.X+8;
    For C:=ColOff to NCol-1 do Begin
     If X+ColW[C]*8+4>D.X+W-24 Then C:=NCol Else Begin
      If C=0 Then S:=IntStr(Fi) Else S:=FeatAttr(Lay[LIdx],Lay[LIdx].Feats^[Fi],C);
      Txt(X+2,Y+1,Fg,Copy(S,1,ColW[C]));
      X:=X+ColW[C]*8+4;
     End;
    End;
   End;
  End;
  Nsel:=CountSelected(Lay[LIdx]);
  Txt(D.X+10,D.Y+H-48,Black,IntStr(Lay[LIdx].NF)+' entites, '+IntStr(Nsel)+' selectionnee(s) - Haut/Bas, Espace=selection, Entree=zoom');
  DrawButton(D.X+W-100,BY,90,22,'Fermer',False);
  DrawButton(D.X+10,BY,120,22,'Deselectionner',False);
  DrawButton(D.X+140,BY,100,22,'Tout select.',False);
  DrawButton(D.X+250,BY,100,22,'Zoom select.',False);
  SM;
 End;
 Procedure Fix;
 Begin
  If Cur<1 Then Cur:=1;
  If Cur>Lay[LIdx].NF Then Cur:=Lay[LIdx].NF;
  If Cur<Top Then Top:=Cur;
  If Cur>=Top+Rows Then Top:=Cur-Rows+1;
  If Top<1 Then Top:=1;
 End;
 Function HeaderCol(X,Y:LongInt):Integer;
 Var
  C,XX:LongInt;
 Begin
  HeaderCol:=-1;
  If(Y<D.Y+24)or(Y>D.Y+37)Then Exit;
  XX:=D.X+8;
  For C:=ColOff to NCol-1 do Begin
   If(X>=XX)and(X<XX+ColW[C]*8+4)Then HeaderCol:=C;
   XX:=XX+ColW[C]*8+4;
  End;
 End;
 Procedure SortBy(C:Integer);
 Begin
  If SortCol=C Then SortDesc:=Not SortDesc Else Begin
   SortCol:=C;
   SortDesc:=False;
  End;
  SortOrder(Lay[LIdx],OrdA,C,SortDesc);
  Top:=1;
 End;
 Procedure ToggleCur;
 Var
  F:PFeature;
 Begin
  F:=Lay[LIdx].Feats^[OrdA^[Cur]];
  F^.Sel:=Not F^.Sel;
 End;
Var
 X1,Y1,X2,Y2:Double;
 R:LongInt;
Begin
 If(LIdx<1)or(LIdx>NLay)or(Lay[LIdx].Kind<>lkVector)Then Begin
  MsgBox('Table d''attributs','Cette couche n''a pas de table d''attributs.');
  Exit;
 End;
 If Lay[LIdx].NF=0 Then Exit;
 AttrZoom:=False;
 GetMem(OrdA,Lay[LIdx].NF*SizeOf(LongInt));
 For I:=1 to Lay[LIdx].NF do OrdA^[I]:=I;
 W:=ScrW-30;
 H:=ScrH-40;
 DlgOpen(D,W,H,'Table d''attributs - '+Lay[LIdx].Name);
 NCol:=Lay[LIdx].NFld+1;
 ComputeWidths;
 Rows:=(H-24-14-4-56)div 12;
 BY:=D.Y+H-30;
 Top:=1;Cur:=1;ColOff:=0;SortCol:=-1;SortDesc:=False;
 Redraw;
 Done:=False;
 While Not Done do Begin
  If GetEvent(E)Then Begin
   If E.What=evKey Then Begin
    If E.Ext Then Begin
     Case Ord(E.Key)of
      72:Dec(Cur);
      80:Inc(Cur);
      73:Dec(Cur,Rows-1);
      81:Inc(Cur,Rows-1);
      71:Cur:=1;
      79:Cur:=Lay[LIdx].NF;
      75:If ColOff>0 Then Dec(ColOff);
      77:If ColOff<NCol-1 Then Inc(ColOff);
     End;
     Fix;
     Redraw;
    End
     Else
    If E.Key=#27 Then Done:=True Else
    If E.Key=' ' Then Begin
     ToggleCur;
     Redraw;
    End
     Else
    If E.Key=#13 Then Begin
     Lay[LIdx].Feats^[OrdA^[Cur]]^.Sel:=True;
     AttrZoom:=True;
     Done:=True;
    End;
   End
    Else
   If(E.What=evDown)and(E.Btn=1)Then Begin
    If InRect(E.X,E.Y,D.X+W-100,BY,D.X+W-11,BY+21)Then Done:=True Else
    If InRect(E.X,E.Y,D.X+10,BY,D.X+129,BY+21)Then Begin
     For I:=1 to Lay[LIdx].NF do Lay[LIdx].Feats^[I]^.Sel:=False;
     Redraw;
    End
     Else
    If InRect(E.X,E.Y,D.X+140,BY,D.X+239,BY+21)Then Begin
     For I:=1 to Lay[LIdx].NF do Lay[LIdx].Feats^[I]^.Sel:=True;
     Redraw;
    End
     Else
    If InRect(E.X,E.Y,D.X+250,BY,D.X+349,BY+21)Then Begin
     If SelectionExtent(X1,Y1,X2,Y2)Then Begin
      AttrZoom:=True;
      Done:=True;
     End;
    End
     Else
    Begin
     K:=HeaderCol(E.X,E.Y);
     If K>=0 Then Begin
      SortBy(K);
      Cur:=1;
      Redraw;
     End
      Else
     If InRect(E.X,E.Y,D.X+9,D.Y+24+14+1,D.X+W-10,D.Y+24+14+Rows*12+1)Then Begin
      R:=Top+(E.Y-(D.Y+24+14+1))div 12;
      If(R>=1)and(R<=Lay[LIdx].NF)Then Begin
       Cur:=R;
       ToggleCur;
       Redraw;
       If E.Dbl Then Done:=True;
      End;
     End;
    End;
   End;
  End
   Else WaitTick;
 End;
 DlgClose(D);
 FreeMem(OrdA,Lay[LIdx].NF*SizeOf(LongInt));
 FlushEvents;
End;
{ ------------------------------------------------------------------ }
{ Aide                                                                }
{ ------------------------------------------------------------------ }

Procedure HelpLines(P:PLineList;Var N:Integer);
Begin
 AddLine(P,N,'QGIS - Clone Pascal '+VersionStr+' (compatible QGIS '+QgisCompat+')');
 AddLine(P,N,'');
 AddLine(P,N,'Syntaxe : QGIS [options] [fichiers]');
 AddLine(P,N,'');
 AddLine(P,N,'Options :');
 AddLine(P,N,'  --help                 Affiche l''aide des parametres');
 AddLine(P,N,'  --version              Affiche la version de QGIS');
 AddLine(P,N,'  --nologo               N''affiche pas le logo de demarrage');
 AddLine(P,N,'  --noversioncheck       Desactive la verification de nouvelle version');
 AddLine(P,N,'  --noplugins            Desactive le chargement des plugins');
 AddLine(P,N,'  --nocustomization      Desactive les personnalisations de l''interface');
 AddLine(P,N,'                         (CUSTOM.INI du profil, lignes HideMenu=nom)');
 AddLine(P,N,'  --optionspath <path>   Repertoire des options (reglages) de QGIS');
 AddLine(P,N,'  --configpath <path>    Repertoire de configuration (remplace le profil)');
 AddLine(P,N,'  --profiles-path <path> Emplacement des profils QGIS');
 AddLine(P,N,'  --profile <nom>        Utilise un profil QGIS particulier');
 AddLine(P,N,'  --project <fichier>    Ouvre un projet QGIS (.qgs)');
 AddLine(P,N,'  --snapshot <fichier>   Produit une capture de la carte (.png ou .bmp)');
 AddLine(P,N,'  --width <n>            Largeur de la capture (defaut 800)');
 AddLine(P,N,'  --height <n>           Hauteur de la capture (defaut 600)');
 AddLine(P,N,'  --extent <x1,y1,x2,y2> Etendue de la capture (SCR du projet)');
 AddLine(P,N,'  --code <fichier>       Execute du code Python au demarrage');
 AddLine(P,N,'  --python <fichier>     Execute un script Python');
 AddLine(P,N,'  --dxf-export <fichier> Export DXF des couches vecteur');
 AddLine(P,N,'  --dxf-extent <x1,y1,x2,y2>  Etendue utilisee pour l''export DXF');
 AddLine(P,N,'  --dxf-scale-denom <n>  Denominateur d''echelle du DXF');
 AddLine(P,N,'  --dxf-encoding <nom>   Encodage du DXF (ex. CP1252)');
 AddLine(P,N,'  --dxf-symbology-mode <no|symbollayer|feature>  (accepte)');
 AddLine(P,N,'  --dxf-preset <nom>     Prereglage de visibilite (accepte)');
 AddLine(P,N,'');
 AddLine(P,N,'Fichiers : projets .qgs, couches .geojson .json .shp .csv, rasters .asc');
 AddLine(P,N,'');
 AddLine(P,N,'Les algorithmes (menus Vecteur, Raster et Traitement) sont executes par');
 AddLine(P,N,'QGIS_PROCESS, qui doit etre dans le meme repertoire, le repertoire courant');
 AddLine(P,N,'ou le PATH.');
 AddLine(P,N,'');
 AddLine(P,N,'Raccourcis : Alt+lettre = menu, Ctrl+N/O/S = projet, Ctrl+V/T/R = ajouter');
 AddLine(P,N,'  F5 rafraichir, F6 table, F9 boite a outils, Home tout, +/- zoom, fleches');
 AddLine(P,N,'  deplacement, Ctrl+Q quitter.');
End;

{ ------------------------------------------------------------------ }
{ Algorithmes de traitement (QGIS_PROCESS)                            }
{ ------------------------------------------------------------------ }

Function ListFile:String;
Begin
 ListFile:=JoinPath(TmpDir,'algos.txt');
End;

Function LogFile:String;
Begin
 LogFile:=JoinPath(TmpDir,'lastrun.txt');
End;

Function HistoryFile:String;
Begin
 HistoryFile:=JoinPath(ProcDir,'history.log');
End;

Function NeedQgisProcess:Boolean;
Begin
 NeedQgisProcess:=QPath<>'';
 If QPath='' Then
  MsgBox('QGIS_PROCESS introuvable','Les algorithmes de traitement sont executes par QGIS_PROCESS. Placer QGIS_PROCESS (ou QGIS_PROCESS.EXE) dans le meme repertoire que QGIS, dans le repertoire courant ou dans le PATH.');
End;

Function LoadAlgos:Boolean;
Var
 P:PLineList;
 N,I,T:Integer;
 S:String;
Begin
 LoadAlgos:=NAlgo>0;
 If NAlgo>0 Then Exit;
 If Not NeedQgisProcess Then Exit;
 SetMsg('Lecture de la liste des algorithmes...');
 If QpRun('list',ListFile)<>0 Then Begin
  SetMsg('');
  MsgBox('Erreur','Impossible d''obtenir la liste des algorithmes.');
  Exit;
 End;
 LoadFileLines(ListFile,P,N);
 For I:=1 to N do Begin
  S:=P^[I]^;
  If(Length(S)>8)and(S[1]=' ')and(NAlgo<MaxAlgos)Then Begin
   S:=Trim(S);
   T:=Pos(' ',S);
   If T>0 Then Begin
    Inc(NAlgo);
    AlgoId[NAlgo]:=Copy(S,1,T-1);
    AlgoTitle[NAlgo]:=Trim(Copy(S,T+1,255));
   End;
  End;
 End;
 FreeLines(P,N);
 SetMsg('');
 LoadAlgos:=NAlgo>0;
End;

{ Chemin GeoJSON d'une couche (exporte la couche si necessaire) }
Function LayerGeoJsonPath(I:Integer):String;
Var
 E,Path:String;
Begin
 E:=ExtOf(Lay[I].Source);
 If((E='.geojson')or(E='.json'))and FileExist(Lay[I].Source)Then Begin
  LayerGeoJsonPath:=Lay[I].Source;
  Exit;
 End;
 EnsureDirs;
 Path:=JoinPath(ProcDir,'layer_'+Sanitize(Lay[I].Name)+'.geojson');
 If WriteGeoJSON(Lay[I],Path,False)Then LayerGeoJsonPath:=Path Else LayerGeoJsonPath:='';
End;

{ Lit les parametres d'un algorithme dans la sortie de "help" }
Function ReadHelp(Const Id:String;Var Prm:Array of TParam;Var NP:Integer;Var Title:String):Boolean;
Var
 P:PLineList;
 N,I:Integer;
 S,T:String;
 InArgs:Boolean;
 Cur:Integer;
 K:Integer;
Begin
 ReadHelp:=False;
 NP:=0;
 Title:=Id;
 If QpRun('help '+Id,JoinPath(TmpDir,'help.txt'))<>0 Then Exit;
 LoadFileLines(JoinPath(TmpDir,'help.txt'),P,N);
 If N=0 Then Exit;
 K:=Pos(' (',P^[1]^);
 If K>1 Then Title:=Copy(P^[1]^,1,K-1);
 InArgs:=False;
 Cur:=-1;
 For I:=1 to N do Begin
  S:=P^[I]^;
  If S='Arguments' Then InArgs:=True Else
  If S='Outputs' Then InArgs:=False Else
  If InArgs and(Length(S)>0)and(S[1]<>' ')and(S[1]<>'-')Then Begin
   K:=Pos(': ',S);
   If(K>1)and(NP<=High(Prm))Then Begin
    Cur:=NP;
    Inc(NP);
    Prm[Cur].Name:=Copy(S,1,K-1);
    Prm[Cur].Desc:=Copy(S,K+2,120);
    Prm[Cur].Typ:='';
    Prm[Cur].Req:=False;
    Prm[Cur].Def:='';
    Prm[Cur].Value:='';
   End;
  End
   Else
  If InArgs and(Cur>=0)and(Length(S)>0)and(S[1]=' ')Then Begin
   T:=Trim(S);
   If Copy(T,1,14)='Argument type:' Then Prm[Cur].Typ:=Trim(Copy(T,15,40)) Else
   If T='Required' Then Prm[Cur].Req:=True Else
   If Copy(T,1,14)='Default value:' Then Prm[Cur].Def:=Trim(Copy(T,15,40));
  End;
 End;
 FreeLines(P,N);
 ReadHelp:=True;
End;

Function NextVectorLayer(After:Integer):Integer;
Var
 I:Integer;
Begin
 NextVectorLayer:=0;
 For I:=After+1 to NLay do
  If Lay[I].Kind=lkVector Then Begin
   NextVectorLayer:=I;
   Exit;
  End;
End;

Function NextRasterLayer(After:Integer):Integer;
Var
 I:Integer;
Begin
 NextRasterLayer:=0;
 For I:=After+1 to NLay do
  If Lay[I].Kind=lkRaster Then Begin
   NextRasterLayer:=I;
   Exit;
  End;
End;

Procedure FillDefaults(Const Id:String;Var Prm:Array of TParam;NP:Integer);
Var
 I,VecCount,RasCount,Cur:Integer;
 T:String;
Begin
 VecCount:=0;
 RasCount:=0;
 Inc(RunCount);
 For I:=0 to NP-1 do Begin
  T:=Prm[I].Typ;
  Prm[I].Value:=Prm[I].Def;
  If T='vector' Then Begin
   Inc(VecCount);
   Cur:=0;
   If VecCount=1 Then Begin
    If LayerIsVector Then Cur:=ActiveLay Else Cur:=NextVectorLayer(0);
   End
    Else Begin
    Cur:=NextVectorLayer(0);
    If Cur=ActiveLay Then Cur:=NextVectorLayer(Cur);
   End;
   If Cur>0 Then Prm[I].Value:=LayerGeoJsonPath(Cur);
  End
   Else
  If T='raster' Then Begin
   Inc(RasCount);
   Cur:=0;
   If RasCount=1 Then Begin
    If LayerIsRaster Then Cur:=ActiveLay Else Cur:=NextRasterLayer(0);
   End
    Else Begin
    Cur:=NextRasterLayer(0);
    If Cur=ActiveLay Then Cur:=NextRasterLayer(Cur);
   End;
   If Cur>0 Then Prm[I].Value:=Lay[Cur].Source;
  End
   Else
  If T='vectorDestination' Then
   Prm[I].Value:=JoinPath(ProcDir,'out'+IntStr(RunCount)+'.geojson')
  Else
  If T='rasterDestination' Then
   Prm[I].Value:=JoinPath(ProcDir,'out'+IntStr(RunCount)+'.asc')
  Else
  If T='fileDestination' Then
   Prm[I].Value:=JoinPath(ProcDir,'out'+IntStr(RunCount)+'.txt')
  Else
  If T='crs' Then Begin
   If Prm[I].Def='' Then Prm[I].Value:=ProjCRS;
  End;
 End;
End;

{ Ajoute les couches produites par un algorithme (section "Results") }
Function LoadResults(Const Title:String):Integer;
Var
 P:PLineList;
 N,I,K,Added:Integer;
 S,Nm,V:String;
 InRes:Boolean;
 E:String;
Begin
 Added:=0;
 LoadFileLines(LogFile,P,N);
 InRes:=False;
 For I:=1 to N do Begin
  S:=P^[I]^;
  If S='Results' Then InRes:=True Else
  If InRes and(Length(S)>2)and(S[1]<>'-')Then Begin
   K:=Pos(':',S);
   If K>1 Then Begin
    Nm:=Copy(S,1,K-1);
    V:=Trim(Copy(S,K+1,255));
    E:=ExtOf(V);
    If FileExist(V)and((E='.geojson')or(E='.json')or(E='.asc'))Then
     If AddLayerFromFile(V,Copy(Title+' '+Nm,1,40))>0 Then Inc(Added);
   End;
  End;
 End;
 FreeLines(P,N);
 LoadResults:=Added;
End;

Procedure RunAlgorithm(Const Id:String);
Var
 Prm:Array[0..MaxParams-1]of TParam;
 NP,I,Code,Added:Integer;
 Title:String;
 H:Text;
 Ok:Boolean;
Begin
 If Not NeedQgisProcess Then Exit;
 EnsureDirs;
 SetMsg('Lecture des parametres de '+Id+'...');
 If Not ReadHelp(Id,Prm,NP,Title)Then Begin
  SetMsg('');
  MsgBox('Algorithme inconnu','QGIS_PROCESS ne connait pas l''algorithme '+Id+'.');
  Exit;
 End;
 SetMsg('');
 FillDefaults(Id,Prm,NP);
 LastAlgo:=Id;
 Ok:=False;
 While Not Ok do Begin
  If NP>0 Then
   If Not FormDlg(Title+' ('+Id+')',Prm,NP)Then Exit;
  Ok:=True;
  For I:=0 to NP-1 do
   If Ok and Prm[I].Req and(Prm[I].Value='')Then Begin
    Ok:=False;
    MsgBox('Parametre manquant','Le parametre '+Prm[I].Name+' est obligatoire.');
   End;
 End;
 SetMsg('Execution de '+Id+'...');
 ScriptOpen;
 ScriptAdd(QuoteArg(QPath)+' run '+Id);
 For I:=0 to NP-1 do
  If Prm[I].Value<>'' Then ScriptAdd(' '+QuoteArg('--'+Prm[I].Name+'='+Prm[I].Value));
 Code:=ScriptRun(LogFile);
 Assign(H,HistoryFile);
 {$I-}Append(H);{$I+}
 If IOResult<>0 Then Begin
  {$I-}Rewrite(H);{$I+}
  If IOResult<>0 Then Code:=Code;
 End;
 {$I-}
 Write(H,'run ',Id);
 For I:=0 to NP-1 do
  If Prm[I].Value<>'' Then Write(H,' --',Prm[I].Name,'=',Prm[I].Value);
 WriteLn(H,'  -> ',Code);
 Close(H);
 {$I+}
 If IOResult<>0 Then;
 Added:=0;
 If Code=0 Then Added:=LoadResults(Title);
 LastLog:=LogFile;
 If Code<>0 Then Begin
  SetMsg('Echec de '+Id+' (code '+IntStr(Code)+')');
  ViewFile('Erreur - '+Id+' (code '+IntStr(Code)+')',LogFile);
 End
  Else
 Begin
  If Added>0 Then Begin
   SetMsg(Title+' : termine, '+IntStr(Added)+' couche(s) ajoutee(s)');
   If NLay=Added Then ZoomAll;
   Dirty:=True;
  End
   Else
  Begin
   SetMsg(Title+' : termine');
   ViewFile('Resultat - '+Id,LogFile);
  End;
 End;
End;

Procedure Toolbox;
Var
 P:PLineList;
 N,I,Sel:Integer;
Begin
 If Not LoadAlgos Then Exit;
 NewLines(P,N);
 For I:=1 to NAlgo do AddLine(P,N,PadR(AlgoId[I],42)+AlgoTitle[I]);
 Sel:=1;
 If PickList('Boite a outils de traitement (taper pour filtrer)',P,N,Sel,True)Then Begin
  FreeLines(P,N);
  RunAlgorithm(AlgoId[Sel]);
 End
  Else FreeLines(P,N);
End;

{ Execute un script Python avec l'interpreteur du systeme }
Function RunPython(Const Script:String;Const OutFile:String):Integer;
Var
 Code:Integer;
Begin
 Code:=RunShell('python3 '+QuoteArg(Script),OutFile);
 If(Code<>0)and(Code<>1)Then Code:=RunShell('python '+QuoteArg(Script),OutFile);
 If(Code<>0)and(Code<>1)Then Code:=RunShell('py '+QuoteArg(Script),OutFile);
 RunPython:=Code;
End;
{ ------------------------------------------------------------------ }
{ Commandes                                                           }
{ ------------------------------------------------------------------ }

Const
 ColorNames='Vert clair|Bleu clair|Jaune|Rouge clair|Cyan clair|Magenta clair|Brun|Gris clair|Vert|Bleu|Rouge|Magenta|Cyan|Noir|Gris fonce|Blanc';
 ColorCodes:Array[1..16]of Byte=(LightGreen,LightBlue,Yellow,LightRed,LightCyan,LightMagenta,Brown,LightGray,Green,Blue,Red,Magenta,Cyan,Black,DarkGray,White);

Var
 Dragging,RubberOn:Boolean;
 DragX0,DragY0,DragX1,DragY1:LongInt;

Function ConfirmDiscard:Boolean;
Begin
 If Dirty and(NLay>0)Then ConfirmDiscard:=AskYesNo('QGIS','Le projet a ete modifie. Abandonner les modifications ?')
                     Else ConfirmDiscard:=True;
End;

Procedure FullRedraw;
Begin
 RedrawAll;
End;

Procedure ShowLoadError;
Begin
 If LoadErr<>'' Then MsgBox('Erreur de chargement',LoadErr);
End;

Procedure AddFile(Const FN:String);
Begin
 If AddLayerFromFile(FN,'')>0 Then Begin
  If Truncated Then SetMsg('Attention : couche tronquee (limite de memoire atteinte)')
               Else SetMsg('Couche ajoutee : '+Lay[1].Name);
  If NLay=1 Then Begin
   SetupCanvas;
   ZoomAll;
  End;
  FullRedraw;
 End
  Else ShowLoadError;
End;

Procedure OpenProjectFile(Const FN:String);
Begin
 If Not ConfirmDiscard Then Exit;
 If LoadProject(FN)Then Begin
  AddRecent(FullPath(FN));
  SetupCanvas;
  If PExtOk Then ZoomToExtent(PEx1,PEy1,PEx2,PEy2) Else ZoomAll;
  FullRedraw;
  If LoadWarn<>'' Then MsgBox('Projet',LoadWarn)
                  Else SetMsg('Projet ouvert : '+FN);
 End
  Else Begin
  If LoadErr<>'' Then MsgBox('Erreur de chargement',LoadErr);
  FullRedraw;
 End;
End;

Procedure DoSaveAs;
Var
 Path:String;
Begin
 Path:=ProjFile;
 If Path='' Then Path:=JoinPath(LastDir,'projet.qgs');
 If FileDlg('Enregistrer le projet sous','.qgs',True,Path)Then Begin
  If ExtOf(Path)<>'.qgs' Then Path:=Path+'.qgs';
  If FileExist(Path)Then
   If Not AskYesNo('Enregistrer',FileOf(Path)+' existe deja. Remplacer ?')Then Exit;
  ProjFile:=Path;
  If SaveProject(Path)Then Begin
   Dirty:=False;
   AddRecent(FullPath(Path));
   SetMsg('Projet enregistre : '+Path);
  End
   Else MsgBox('Erreur','Impossible d''ecrire '+Path);
  DrawStatusInfo;
 End;
End;

Procedure DoSave;
Begin
 If ProjFile='' Then DoSaveAs Else Begin
  If SaveProject(ProjFile)Then Begin
   Dirty:=False;
   SetMsg('Projet enregistre : '+ProjFile);
  End
   Else MsgBox('Erreur','Impossible d''ecrire '+ProjFile);
  DrawStatusInfo;
 End;
End;

Procedure DoExportImage;
Var
 Path:String;
 W,H:LongInt;
 Ok:Boolean;
Begin
 Path:=JoinPath(LastDir,'carte.png');
 If Not FileDlg('Exporter la carte en image (.png ou .bmp)','.png;.bmp',True,Path)Then Exit;
 If ExtOf(Path)<>'.bmp' Then Begin
  If ExtOf(Path)<>'.png' Then Path:=Path+'.png';
 End;
 W:=ClipR-ClipL+1;
 H:=ClipB-ClipT+1;
 SetMsg('Rendu de l''image...');
 If Not RenderOffscreen(W,H,True,VX1,VY1,VX2,VY2)Then Begin
  MsgBox('Erreur',LoadErr);
  Exit;
 End;
 If ExtOf(Path)='.bmp' Then Ok:=SaveBMP(Path) Else Ok:=SavePNG(Path);
 FreeOffscreen;
 If Ok Then SetMsg('Image enregistree : '+Path)
       Else MsgBox('Erreur','Impossible d''ecrire '+Path);
End;

Procedure DoExportDXF;
Var
 Path:String;
Begin
 Path:=JoinPath(LastDir,'export.dxf');
 If Not FileDlg('Exporter en DXF','.dxf',True,Path)Then Exit;
 If ExtOf(Path)<>'.dxf' Then Path:=Path+'.dxf';
 If ExportDXF(Path,False,0,0,0,0)Then SetMsg('DXF enregistre ('+IntStr(DxfCnt)+' entites) : '+Path)
                                 Else MsgBox('Erreur','Impossible d''ecrire '+Path);
End;

Procedure SetTool(T:Byte);
Begin
 Tool:=T;
 RubberOn:=False;
 Dragging:=False;
 Case T of
  tlPan:SetMsg('Deplacer la carte : glisser avec la souris');
  tlZoomIn:SetMsg('Zoom avant : cliquer ou tracer un rectangle');
  tlZoomOut:SetMsg('Zoom arriere : cliquer sur la carte');
  tlIdentify:SetMsg('Identifier : cliquer sur une entite de la couche active');
  tlSelect:SetMsg('Selection : cliquer ou tracer un rectangle (couche active)');
  tlMeasure:SetMsg('Mesure : clic gauche = point, clic droit = recommencer');
 End;
 DrawToolbar;
End;

Procedure ChooseColor(Var C:Byte;Const Title:String);
Var
 Sel,I:Integer;
Begin
 Sel:=1;
 For I:=1 to 16 do If ColorCodes[I]=C Then Sel:=I;
 If SmallPick(Title,ColorNames,Sel)Then C:=ColorCodes[Sel];
End;

Procedure SelectionMsg;
Begin
 SetMsg(IntStr(TotalSelected)+' entite(s) selectionnee(s)');
End;

Procedure DoSelectExpr;
Var
 S:String;
 N:LongInt;
Begin
 If Not LayerIsVector Then Exit;
 S:='';
 If InputBox('Selection par expression','champ = valeur  (=, !=, <, >, <=, >=, LIKE)',S,80)Then Begin
  N:=SelectByExpr(Lay[ActiveLay],S);
  If N<0 Then MsgBox('Expression invalide','Syntaxe : champ OP valeur, ou OP est =, !=, <, >, <=, >= ou LIKE. Champs de la couche : '+IntStr(Lay[ActiveLay].NFld))
  Else Begin
   RedrawMapArea;
   SelectionMsg;
  End;
 End;
End;

Procedure MoveLayer(Dir:Integer);
Var
 T:TLayer;
 A,B:Integer;
Begin
 A:=ActiveLay;
 B:=A+Dir;
 If(A<1)or(B<1)or(B>NLay)Then Exit;
 T:=Lay[A];Lay[A]:=Lay[B];Lay[B]:=T;
 ActiveLay:=B;
 Dirty:=True;
 FullRedraw;
End;

Procedure SetProjCrs(Id:Byte;Const Name:String);
Begin
 ProjCrsId:=Id;
 ProjCRS:=Name;
 Dirty:=True;
 ZoomAll;
 FullRedraw;
End;

Procedure ShowText(Const Title:String;Const Lines:String);
Begin
 MsgBox(Title,Lines);
End;

Procedure DoCmdLineInfo;
Var
 P:PLineList;
 N:Integer;
 S:String;
 Procedure Opt(Const Nm,V:String);
 Begin
  If V<>'' Then AddLine(P,N,'  '+Nm+' '+V);
 End;
Begin
 NewLines(P,N);
 AddLine(P,N,'Profil        : '+ProfileDir);
 AddLine(P,N,'Reglages      : '+SettingsFile);
 If QPath<>'' Then S:=QPath Else S:='(introuvable)';
 AddLine(P,N,'QGIS_PROCESS  : '+S);
 AddLine(P,N,'');
 AddLine(P,N,'Options actives :');
 If OptNoLogo Then AddLine(P,N,'  --nologo');
 If OptNoVerCheck Then AddLine(P,N,'  --noversioncheck');
 If OptNoPlugins Then AddLine(P,N,'  --noplugins');
 If OptNoCustom Then AddLine(P,N,'  --nocustomization');
 Opt('--profile',OptProfile);
 Opt('--configpath',OptConfigPath);
 Opt('--optionspath',OptOptionsPath);
 Opt('--profiles-path',OptProfilesPath);
 Opt('--project',OptProject);
 ViewLines('Options de lancement',P,N,ScrW-60,260);
 FreeLines(P,N);
End;

Procedure DoAbout;
Begin
 ShowText('A propos de QGIS','QGIS - Clone Pascal '+VersionStr+'|Compatible avec les parametres de QGIS '+QgisCompat+'|Turbo Pascal 7 / Free Pascal|Projet GEO Commander - https://www.gladir.com/geo-commander|Auteur : Sylvain Maltais (support@gladir.com)');
End;

Procedure DoPython;
Var
 Path:String;
Begin
 Path:=JoinPath(LastDir,'script.py');
 If Not FileDlg('Executer un script Python','.py',False,Path)Then Exit;
 EnsureDirs;
 SetMsg('Execution de '+FileOf(Path)+'...');
 If RunPython(Path,LogFile)<>0 Then SetMsg('Le script a signale une erreur')
                               Else SetMsg('Script termine');
 LastLog:=LogFile;
 ViewFile('Sortie de '+FileOf(Path),LogFile);
End;

Procedure ProcAlgo(Const Id:String);
Begin
 RunAlgorithm(Id);
 FullRedraw;
End;

Procedure ExecCmd(Cmd:Integer);
Var
 Path:String;
 X1,Y1,X2,Y2:Double;
 Sel,I:Integer;
 S:String;
 P:PLineList;
 N:Integer;
Begin
 If Not IsEnabled(Cmd)Then Exit;
 Case Cmd of
  cmNew:Begin
   If ConfirmDiscard Then Begin
    ClearProject;
    SetupCanvas;
    ZoomWorld;
    FullRedraw;
    SetMsg('Nouveau projet');
   End;
  End;
  cmOpen:Begin
   Path:=ProjFile;
   If FileDlg('Ouvrir un projet QGIS (.qgs)','.qgs',False,Path)Then OpenProjectFile(Path);
  End;
  cmRecent:Begin
   NewLines(P,N);
   For I:=1 to NRecent do AddLine(P,N,Recent[I]);
   Sel:=1;
   If SmallPickL('Projets recents',P,N,Sel)Then Path:=Recent[Sel] Else Path:='';
   FreeLines(P,N);
   If Path<>'' Then OpenProjectFile(Path);
  End;
  cmSave:DoSave;
  cmSaveAs:DoSaveAs;
  cmExportImage:DoExportImage;
  cmExportDXF:DoExportDXF;
  cmProjProps:Begin
   S:=ProjTitle;
   If InputBox('Proprietes du projet','Titre du projet (SCR : '+ProjCRS+')',S,60)Then Begin
    ProjTitle:=S;
    Dirty:=True;
    DrawStatusInfo;
   End;
  End;
  cmQuit:If ConfirmDiscard Then Running:=False;

  cmSelAll:Begin
   For I:=1 to Lay[ActiveLay].NF do Lay[ActiveLay].Feats^[I]^.Sel:=True;
   RedrawMapArea;
   SelectionMsg;
  End;
  cmDeselect:Begin
   ClearSelection;
   RedrawMapArea;
   SelectionMsg;
  End;
  cmSelInvert:Begin
   InvertSelection(Lay[ActiveLay]);
   RedrawMapArea;
   SelectionMsg;
  End;
  cmSelExpr:DoSelectExpr;

  cmToolPan:SetTool(tlPan);
  cmToolZoomIn:SetTool(tlZoomIn);
  cmToolZoomOut:SetTool(tlZoomOut);
  cmToolIdentify:SetTool(tlIdentify);
  cmToolSelect:SetTool(tlSelect);
  cmToolMeasure:SetTool(tlMeasure);
  cmZoomAll:Begin
   ZoomAll;
   RedrawMapArea;
  End;
  cmZoomLayer:Begin
   ZoomLayerIdx(ActiveLay);
   RedrawMapArea;
  End;
  cmZoomSel:Begin
   If SelectionExtent(X1,Y1,X2,Y2)Then Begin
    ZoomToExtent(X1,Y1,X2,Y2);
    RedrawMapArea;
   End
    Else SetMsg('Aucune entite selectionnee');
  End;
  cmZoomPrev:Begin
   InHistMove:=True;
   ApplyHist(HistPos-1);
   InHistMove:=False;
   RedrawMapArea;
   DrawToolbar;
  End;
  cmZoomNext:Begin
   InHistMove:=True;
   ApplyHist(HistPos+1);
   InHistMove:=False;
   RedrawMapArea;
   DrawToolbar;
  End;
  cmAttrTable:Begin
   If LayerIsVector Then Begin
    AttrTable(ActiveLay);
    If AttrZoom and SelectionExtent(X1,Y1,X2,Y2)Then ZoomToExtent(X1,Y1,X2,Y2);
    RedrawMapArea;
    SelectionMsg;
   End
    Else MsgBox('Table d''attributs','Selectionner une couche vecteur dans le panneau des couches.');
  End;
  cmLabels:Begin
   ShowLabels:=Not ShowLabels;
   RedrawMapArea;
  End;
  cmGrid:Begin
   ShowGrid:=Not ShowGrid;
   RedrawMapArea;
  End;
  cmPanel:Begin
   ShowPanel:=Not ShowPanel;
   FullRedraw;
  End;
  cmRefresh:FullRedraw;

  cmAddVector:Begin
   Path:='';
   If FileDlg('Ajouter une couche vecteur','.geojson;.json;.shp;.csv;.txt',False,Path)Then AddFile(Path);
  End;
  cmAddCSV:Begin
   Path:='';
   If FileDlg('Ajouter un texte delimite','.csv;.txt;.tsv',False,Path)Then AddFile(Path);
  End;
  cmAddRaster:Begin
   Path:='';
   If FileDlg('Ajouter une couche raster (grille ASCII)','.asc',False,Path)Then AddFile(Path);
  End;
  cmRemoveLayer:Begin
   RemoveLayerAt(ActiveLay);
   FullRedraw;
  End;
  cmLayerUp:MoveLayer(-1);
  cmLayerDown:MoveLayer(1);
  cmLayerVis:Begin
   Lay[ActiveLay].Visible:=Not Lay[ActiveLay].Visible;
   Dirty:=True;
   FullRedraw;
  End;
  cmLayerFill:Begin
   Lay[ActiveLay].Fill:=Not Lay[ActiveLay].Fill;
   FullRedraw;
  End;
  cmLayerColor:Begin
   ChooseColor(Lay[ActiveLay].Color,'Couleur de la couche');
   Dirty:=True;
   FullRedraw;
  End;
  cmLayerProps:LayerProperties(ActiveLay);
  cmSaveLayer:Begin
   Path:=JoinPath(LastDir,Sanitize(Lay[ActiveLay].Name)+'.geojson');
   If FileDlg('Enregistrer la couche en GeoJSON','.geojson;.json',True,Path)Then Begin
    If(ExtOf(Path)<>'.geojson')and(ExtOf(Path)<>'.json')Then Path:=Path+'.geojson';
    If WriteGeoJSON(Lay[ActiveLay],Path,(CountSelected(Lay[ActiveLay])>0)and
       AskYesNo('Enregistrer','Enregistrer seulement les entites selectionnees ?'))Then
     SetMsg('Couche enregistree : '+Path)
    Else MsgBox('Erreur','Impossible d''ecrire '+Path);
   End;
  End;

  cmCrs4326:SetProjCrs(crs4326,'EPSG:4326');
  cmCrs3857:SetProjCrs(crs3857,'EPSG:3857');
  cmCrsLayer:SetProjCrs(Lay[ActiveLay].CrsId,Lay[ActiveLay].CRS);
  cmBackground:Begin
   ChooseColor(Background,'Couleur de fond de la carte');
   RedrawMapArea;
  End;
  cmProfileInfo,cmCmdLine:DoCmdLineInfo;

  cmPlugins:Begin
   If QpRun('plugins',LogFile)=0 Then ViewFile('Gestionnaire d''extensions',LogFile)
   Else MsgBox('Erreur','Impossible d''obtenir la liste des extensions.');
  End;
  cmPython:DoPython;

  cmVecBuffer:ProcAlgo('native:buffer');
  cmVecCentroids:ProcAlgo('native:centroids');
  cmVecHull:ProcAlgo('native:convexhull');
  cmVecSimplify:ProcAlgo('native:simplifygeometries');
  cmVecReproject:ProcAlgo('native:reprojectlayer');
  cmVecClip:ProcAlgo('native:clip');
  cmVecDissolve:ProcAlgo('native:dissolve');
  cmVecBBox:ProcAlgo('native:boundingboxes');
  cmVecPolyLines:ProcAlgo('native:polygonstolines');
  cmVecExtent:ProcAlgo('native:layerextent');
  cmRasSlope:ProcAlgo('gdal:slope');
  cmRasAspect:ProcAlgo('gdal:aspect');
  cmRasHillshade:ProcAlgo('gdal:hillshade');
  cmRasContour:ProcAlgo('gdal:contour');
  cmRasFill:ProcAlgo('gdal:fillnodata');
  cmRasCalc:ProcAlgo('gdal:rastercalculator');
  cmRasPolygonize:ProcAlgo('gdal:polygonize');

  cmToolbox:Begin
   Toolbox;
   FullRedraw;
  End;
  cmProcLast:Begin
   If LastAlgo='' Then MsgBox('Traitement','Aucun algorithme n''a encore ete execute.')
                  Else ProcAlgo(LastAlgo);
  End;
  cmProcHistory:Begin
   If FileExist(HistoryFile)Then ViewFile('Historique de traitement',HistoryFile)
   Else MsgBox('Traitement','L''historique est vide.');
  End;
  cmProcLog:Begin
   If(LastLog<>'')and FileExist(LastLog)Then ViewFile('Journal du dernier algorithme',LastLog)
   Else MsgBox('Traitement','Aucun journal disponible.');
  End;

  cmHelp:Begin
   NewLines(P,N);
   HelpLines(P,N);
   ViewLines('Aide',P,N,ScrW-60,ScrH-60);
   FreeLines(P,N);
  End;
  cmAbout:DoAbout;
  cmUpdate:MsgBox('Mise a jour','Aucune mise a jour disponible : la verification n''est pas possible hors ligne.');
 End;
 DrawToolbar;
End;

{ ------------------------------------------------------------------ }
{ Evenements de la carte                                              }
{ ------------------------------------------------------------------ }

Procedure RubberXor(X0,Y0,X1,Y1:LongInt);
Begin
 HM;
 SetWriteMode(XORPut);
 SetColor(White);
 Rectangle(X0,Y0,X1,Y1);
 SetWriteMode(CopyPut);
 SM;
End;

Function InCanvas(X,Y:LongInt):Boolean;
Begin
 InCanvas:=InRect(X,Y,ClipL,ClipT,ClipR,ClipB);
End;

Procedure MeasureAdd(MX,MY:Double);
Var
 I:Integer;
 Tot:Double;
Begin
 If MeasN>=64 Then Exit;
 Inc(MeasN);
 MeasPts[MeasN].X:=MX;
 MeasPts[MeasN].Y:=MY;
 Tot:=0;
 For I:=2 to MeasN do Tot:=Tot+ProjDist(MeasPts[I-1],MeasPts[I]);
 If ProjCrsId=crsOther Then SetMsg('Distance : '+RealStr(Tot,3)+' unites')
 Else If Tot>=1000 Then SetMsg('Distance : '+RealStr(Tot/1000,3)+' km ('+RealStr(Tot,0)+' m)')
 Else SetMsg('Distance : '+RealStr(Tot,2)+' m');
 RedrawMapArea;
End;

Procedure CanvasDown(Var E:TEvent);
Var
 MX,MY:Double;
 Idx:LongInt;
 L,K:Integer;
 WasSel:Boolean;
Begin
 MX:=PxToMapX(E.X);
 MY:=PxToMapY(E.Y);
 If E.Btn=2 Then Begin
  If Tool=tlMeasure Then Begin
   MeasN:=0;
   RedrawMapArea;
   SetMsg('Mesure reinitialisee');
  End;
  Exit;
 End;
 Case Tool of
  tlPan:Begin
   Dragging:=True;
   DragX0:=E.X;DragY0:=E.Y;DragX1:=E.X;DragY1:=E.Y;
  End;
  tlZoomIn,tlSelect:Begin
   Dragging:=True;
   DragX0:=E.X;DragY0:=E.Y;DragX1:=E.X;DragY1:=E.Y;
   RubberXor(DragX0,DragY0,DragX1,DragY1);
   RubberOn:=True;
  End;
  tlZoomOut:Begin
   SetView(MX,MY,UPP*2);
   RedrawMapArea;
  End;
  tlMeasure:MeasureAdd(MX,MY);
  tlIdentify:Begin
   If ActiveLay<1 Then SetMsg('Aucune couche active') Else
   If Lay[ActiveLay].Kind=lkRaster Then IdentifyRaster(ActiveLay,MX,MY)
   Else Begin
    { Couche active d'abord, puis les autres couches visibles }
    L:=ActiveLay;
    Idx:=FeatureAt(Lay[L],E.X,E.Y,5);
    K:=0;
    While(Idx=0)and(K<NLay)do Begin
     Inc(K);
     If(K<>ActiveLay)and Lay[K].Visible and(Lay[K].Kind=lkVector)Then Begin
      Idx:=FeatureAt(Lay[K],E.X,E.Y,5);
      If Idx>0 Then L:=K;
     End;
    End;
    If Idx>0 Then Begin
     WasSel:=Lay[L].Feats^[Idx]^.Sel;
     Lay[L].Feats^[Idx]^.Sel:=True;
     RedrawMapArea;
     IdentifyFeature(L,Idx);
     Lay[L].Feats^[Idx]^.Sel:=WasSel;
     RedrawMapArea;
    End
     Else SetMsg('Aucune entite a cet endroit');
   End;
  End;
 End;
End;

Procedure CanvasUp(Var E:TEvent);
Var
 DX,DY:LongInt;
 Idx:LongInt;
Begin
 If Not Dragging Then Exit;
 Dragging:=False;
 If RubberOn Then Begin
  RubberXor(DragX0,DragY0,DragX1,DragY1);
  RubberOn:=False;
 End;
 DX:=E.X-DragX0;
 DY:=E.Y-DragY0;
 Case Tool of
  tlPan:Begin
   If(Abs(DX)>1)or(Abs(DY)>1)Then Begin
    PanBy(-DX,-DY);
    RedrawMapArea;
   End;
  End;
  tlZoomIn:Begin
   If(Abs(DX)<4)and(Abs(DY)<4)Then Begin
    SetView(PxToMapX(E.X),PxToMapY(E.Y),UPP/2);
   End
    Else
   ZoomToExtent(PxToMapX(DragX0),PxToMapY(DragY0),PxToMapX(E.X),PxToMapY(E.Y));
   RedrawMapArea;
  End;
  tlSelect:Begin
   If ActiveLay<1 Then Exit;
   If Lay[ActiveLay].Kind<>lkVector Then Begin
    SetMsg('La couche active n''est pas une couche vecteur');
    Exit;
   End;
   ClearSelection;
   If(Abs(DX)<4)and(Abs(DY)<4)Then Begin
    Idx:=FeatureAt(Lay[ActiveLay],E.X,E.Y,5);
    If Idx>0 Then Lay[ActiveLay].Feats^[Idx]^.Sel:=True;
   End
    Else SelectInRect(Lay[ActiveLay],DragX0,DragY0,E.X,E.Y,False);
   RedrawMapArea;
   SelectionMsg;
  End;
 End;
End;

Procedure CanvasMove(Var E:TEvent);
Begin
 LastMapX:=PxToMapX(E.X);
 LastMapY:=PxToMapY(E.Y);
 If Dragging Then Begin
  If RubberOn Then Begin
   RubberXor(DragX0,DragY0,DragX1,DragY1);
   DragX1:=ClampL(E.X,ClipL,ClipR);
   DragY1:=ClampL(E.Y,ClipT,ClipB);
   RubberXor(DragX0,DragY0,DragX1,DragY1);
  End
   Else Begin
   DragX1:=E.X;DragY1:=E.Y;
  End;
 End;
 DrawStatusInfo;
End;

Procedure PanelDown(Var E:TEvent);
Var
 I:Integer;
 OnCheck:Boolean;
 S:String;
 Sel:Integer;
Begin
 I:=PanelHit(E.X,E.Y,OnCheck);
 If I<=0 Then Exit;
 If E.Btn=2 Then Begin
  ActiveLay:=I;
  DrawPanel;
  S:='Zoom sur la couche|Table d''attributs|Proprietes|Monter|Descendre|Changer la couleur|Supprimer';
  Sel:=1;
  If SmallPick(Lay[I].Name,S,Sel)Then Begin
   Case Sel of
    1:ExecCmd(cmZoomLayer);
    2:ExecCmd(cmAttrTable);
    3:ExecCmd(cmLayerProps);
    4:ExecCmd(cmLayerUp);
    5:ExecCmd(cmLayerDown);
    6:ExecCmd(cmLayerColor);
    7:ExecCmd(cmRemoveLayer);
   End;
  End;
  Exit;
 End;
 If OnCheck Then Begin
  Lay[I].Visible:=Not Lay[I].Visible;
  Dirty:=True;
  RedrawMapArea;
  DrawPanel;
 End
  Else
 Begin
  ActiveLay:=I;
  DrawPanel;
  If E.Dbl Then LayerProperties(I);
 End;
End;

{ ------------------------------------------------------------------ }
{ Traitement des evenements                                           }
{ ------------------------------------------------------------------ }

Procedure RunMenuItem;
Var
 C:Integer;
Begin
 If(MenuOpen<0)or(MenuSel<0)Then Exit;
 C:=Menus[MenuOpen].Items[MenuSel].Cmd;
 If C=cmNone Then Exit;
 If Not IsEnabled(C)Then Exit;
 CloseMenu;
 ExecCmd(C);
End;

Procedure HandleMenuKey(Var E:TEvent);
Begin
 If E.Ext Then Begin
  Case Ord(E.Key)of
   72:MenuMove(-1);
   80:MenuMove(1);
   75:MenuSwitchTo(-1);
   77:MenuSwitchTo(1);
  End;
 End
  Else
 Begin
  If E.Key=#27 Then CloseMenu Else
  If E.Key=#13 Then RunMenuItem;
 End;
End;

Procedure HandleKey(Var E:TEvent);
Var
 I:Integer;
 Step:Double;
Begin
 If MenuOpen>=0 Then Begin
  If E.Ext Then Begin
   For I:=0 to NMenus-1 do
    If(Menus[I].AltKey=Ord(E.Key))and Not Menus[I].Hidden Then Begin
     OpenMenu(I);
     Exit;
    End;
  End;
  HandleMenuKey(E);
  Exit;
 End;
 If E.Ext Then Begin
  For I:=0 to NMenus-1 do
   If(Menus[I].AltKey=Ord(E.Key))and Not Menus[I].Hidden Then Begin
    OpenMenu(I);
    Exit;
   End;
  Step:=(ClipR-ClipL)*0.2;
  Case Ord(E.Key)of
   59:ExecCmd(cmHelp);
   63:ExecCmd(cmRefresh);
   64:ExecCmd(cmAttrTable);
   67:ExecCmd(cmToolbox);
   68:ExecCmd(cmQuit);
   71:ExecCmd(cmZoomAll);
   72:Begin
    PanBy(0,-Step);
    RedrawMapArea;
   End;
   80:Begin
    PanBy(0,Step);
    RedrawMapArea;
   End;
   75:Begin
    PanBy(-Step,0);
    RedrawMapArea;
   End;
   77:Begin
    PanBy(Step,0);
    RedrawMapArea;
   End;
   73:Begin
    ZoomFactor(0.5);
    RedrawMapArea;
   End;
   81:Begin
    ZoomFactor(2);
    RedrawMapArea;
   End;
   83:ExecCmd(cmRemoveLayer);
  End;
 End
  Else
 Begin
  Case E.Key of
   #14:ExecCmd(cmNew);
   #15:ExecCmd(cmOpen);
   #19:ExecCmd(cmSave);
   #17:ExecCmd(cmQuit);
   #1:ExecCmd(cmSelAll);
   #4:ExecCmd(cmDeselect);
   #22:ExecCmd(cmAddVector);
   #20:ExecCmd(cmAddCSV);
   #18:ExecCmd(cmAddRaster);
   '+','=':Begin
    ZoomFactor(0.5);
    RedrawMapArea;
   End;
   '-','_':Begin
    ZoomFactor(2);
    RedrawMapArea;
   End;
   #27:Begin
    If MeasN>0 Then Begin
     MeasN:=0;
     RedrawMapArea;
    End;
   End;
  End;
 End;
End;

Procedure HandleDown(Var E:TEvent);
Var
 B,I:Integer;
Begin
 If E.Btn=1 Then Begin
  If MenuOpen>=0 Then Begin
   B:=MenuBarHit(E.X,E.Y);
   If B>=0 Then Begin
    If B=MenuOpen Then CloseMenu Else OpenMenu(B);
    Exit;
   End;
   I:=MenuItemHit(MenuOpen,E.X,E.Y);
   If I>=0 Then Begin
    MenuSel:=I;
    RunMenuItem;
   End
    Else CloseMenu;
   Exit;
  End;
  B:=MenuBarHit(E.X,E.Y);
  If B>=0 Then Begin
   OpenMenu(B);
   Exit;
  End;
 End
  Else
 If MenuOpen>=0 Then Begin
  CloseMenu;
  Exit;
 End;
 I:=ToolbarHit(E.X,E.Y);
 If(I>0)and(E.Btn=1)Then Begin
  ExecCmd(TBtn[I].Cmd);
  Exit;
 End;
 If InCanvas(E.X,E.Y)Then CanvasDown(E) Else
 If ShowPanel and(E.X<PanelW)and(E.Y>=MenuH+ToolH)Then PanelDown(E);
End;

Procedure HandleUp(Var E:TEvent);
Begin
 If E.Btn=1 Then CanvasUp(E);
End;

Procedure HandleMove(Var E:TEvent);
Var
 B,I,H:Integer;
Begin
 If MenuOpen>=0 Then Begin
  B:=MenuBarHit(E.X,E.Y);
  If(B>=0)and(B<>MenuOpen)Then OpenMenu(B) Else Begin
   I:=MenuItemHit(MenuOpen,E.X,E.Y);
   If(I<>MenuSel)and(I>=0)Then Begin
    MenuSel:=I;
    DrawDropdown(MenuOpen);
   End;
  End;
  Exit;
 End;
 H:=ToolbarHit(E.X,E.Y);
 If H<>ToolHot Then Begin
  ToolHot:=H;
  If H>0 Then SetMsg(TBtn[H].Hint) Else SetMsg('');
 End;
 If Dragging or InCanvas(E.X,E.Y)Then CanvasMove(E);
End;

Procedure HandleEvent(Var E:TEvent);
Begin
 Case E.What of
  evKey:HandleKey(E);
  evDown:HandleDown(E);
  evUp:HandleUp(E);
  evMove:HandleMove(E);
 End;
End;

Procedure MainLoop;
Var
 E:TEvent;
Begin
 While Running do Begin
  If GetEvent(E)Then HandleEvent(E) Else WaitTick;
 End;
End;
{ ------------------------------------------------------------------ }
{ Ligne de commande                                                   }
{ ------------------------------------------------------------------ }

Function ParseExtent(Const S:String;Var X1,Y1,X2,Y2:Double):Boolean;
Var
 V:Array[1..4]of Double;
 P,K:Integer;
 T,Part:String;
Begin
 ParseExtent:=False;
 T:=S+',';
 K:=0;
 While(T<>'')and(K<4)do Begin
  P:=Pos(',',T);
  If P=0 Then P:=Pos(';',T);
  If P=0 Then P:=Length(T)+1;
  Part:=Trim(Copy(T,1,P-1));
  Delete(T,1,P);
  Inc(K);
  If Not StrToReal(Part,V[K])Then Exit;
 End;
 If K<>4 Then Exit;
 X1:=V[1];Y1:=V[2];X2:=V[3];Y2:=V[4];
 ParseExtent:=(X2>X1)and(Y2>Y1);
End;

Procedure PrintHelp;
Var
 P:PLineList;
 N,I:Integer;
Begin
 NewLines(P,N);
 HelpLines(P,N);
 For I:=1 to N do WriteLn(P^[I]^);
 FreeLines(P,N);
End;

Procedure BadOption(Const S:String);
Begin
 WriteLn('Erreur : ',S);
 WriteLn('Essayer QGIS --help pour la liste des options.');
 Halt(1);
End;

Procedure ParseArgs;
Var
 I,P:Integer;
 A,Nm,V:String;
 HasV:Boolean;
 Function Need:String;
 Begin
  If HasV Then Need:=V Else Begin
   If I<ParamCount Then Begin
    Inc(I);
    Need:=ParamStr(I);
   End
    Else BadOption('l''option '+Nm+' attend une valeur.');
  End;
 End;
Begin
 OptNFiles:=0;
 OptWidth:=800;
 OptHeight:=600;
 I:=1;
 While I<=ParamCount do Begin
  A:=ParamStr(I);
  If(A='/?')or(A='-h')or(A='-?')Then A:='--help';
  If A='-v' Then A:='--version';
  If Copy(A,1,2)='--' Then Begin
   P:=Pos('=',A);
   HasV:=P>0;
   If HasV Then Begin
    Nm:=StrLow(Copy(A,1,P-1));
    V:=Copy(A,P+1,255);
   End
    Else Begin
    Nm:=StrLow(A);
    V:='';
   End;
   If Nm='--help' Then Begin
    PrintHelp;
    Halt(0);
   End
    Else
   If Nm='--version' Then Begin
    WriteLn('QGIS ',VersionStr,' ''Pascal'' (clone compatible QGIS ',QgisCompat,')');
    Halt(0);
   End
    Else
   If Nm='--nologo' Then OptNoLogo:=True Else
   If Nm='--noversioncheck' Then OptNoVerCheck:=True Else
   If Nm='--noplugins' Then OptNoPlugins:=True Else
   If Nm='--nocustomization' Then OptNoCustom:=True Else
   If Nm='--optionspath' Then OptOptionsPath:=Need Else
   If Nm='--configpath' Then OptConfigPath:=Need Else
   If Nm='--profiles-path' Then OptProfilesPath:=Need Else
   If Nm='--profile' Then OptProfile:=Need Else
   If Nm='--project' Then OptProject:=Need Else
   If Nm='--snapshot' Then OptSnapshot:=Need Else
   If Nm='--code' Then OptCode:=Need Else
   If Nm='--python' Then OptPython:=Need Else
   If Nm='--dxf-export' Then OptDxfExport:=Need Else
   If Nm='--dxf-extent' Then OptDxfExtent:=Need Else
   If Nm='--dxf-scale-denom' Then OptDxfScale:=Need Else
   If Nm='--dxf-encoding' Then OptDxfEncoding:=Need Else
   If Nm='--dxf-symbology-mode' Then OptDxfSymb:=Need Else
   If Nm='--dxf-preset' Then OptDxfPreset:=Need Else
   If Nm='--extent' Then OptExtent:=Need Else
   If Nm='--width' Then Begin
    If Not StrToLong(Need,OptWidth)Then BadOption('--width attend un entier.');
   End
    Else
   If Nm='--height' Then Begin
    If Not StrToLong(Need,OptHeight)Then BadOption('--height attend un entier.');
   End
    Else
   { Options acceptees sans effet }
   If(Nm='--lang')or(Nm='--customizationfile')or(Nm='--globalsettingsfile')or
     (Nm='--authdbdirectory')Then V:=Need Else
   If(Nm='--skipbadlayers')or(Nm='--hide-browser')or(Nm='--dxf-use-title')or
     (Nm='--dxf-no-oblique')or(Nm='--dxf-force-2d')or(Nm='--dxf-mtext')or
     (Nm='--version-migration')Then
   Else BadOption('option inconnue '+A);
  End
   Else
  Begin
   If OptNFiles<16 Then Begin
    Inc(OptNFiles);
    OptFiles[OptNFiles]:=A;
   End;
  End;
  Inc(I);
 End;
End;

{ ------------------------------------------------------------------ }
{ Initialisation                                                      }
{ ------------------------------------------------------------------ }

Procedure InitializeGraphics;
Var
 Driver, Mode: Integer;
 ErrCode: Integer;
Begin
 {$IFDEF FPC}
  Driver:=VGA;
  Mode:=VGAHi;
 {$ELSE}
  Driver:=Detect;
  Mode:=VGAHi;
 {$ENDIF}
 InitGraph(Driver,Mode,'');
 ErrCode:=GraphResult;
 If ErrCode=grOk Then Begin
  SetColor(White);
  SetLineStyle(0,0,1);
 End
  Else
 Begin
  WriteLn('Erreur graphique : ',GraphErrorMsg(ErrCode));
  Halt;
 End;
 ScrW:=GetMaxX+1;
 ScrH:=GetMaxY+1;
 GraphOn:=True;
End;

Procedure InitGlobals;
Begin
 InitCharsets;
 FillChar(Lay,SizeOf(Lay),0);
 NLay:=0;ActiveLay:=0;
 ProjCrsId:=crs4326;
 ProjCRS:='EPSG:4326';
 ProjTitle:='';ProjFile:='';
 Dirty:=False;
 CX:=0;CY:=0;UPP:=0.5;
 HistN:=0;HistPos:=0;
 ShowPanel:=True;ShowLabels:=False;ShowGrid:=False;
 Tool:=tlPan;
 Background:=White;
 MouseHid:=0;
 MenuOpen:=-1;MenuSel:=-1;MenuSaveOk:=False;
 ColorCount:=0;
 Running:=True;
 MeasN:=0;
 Tick:=0;LastDownTick:=-1000;
 PrevMX:=0;PrevMY:=0;PrevMB:=0;
 StatusMsg:='';
 ToolHot:=0;
 Dragging:=False;RubberOn:=False;
 NAlgo:=0;LastAlgo:='';LastLog:='';RunCount:=0;
 NRecent:=0;LastDir:='';
 TmpPts:=Nil;TmpEnds:=Nil;TmpGrp:=Nil;SBuf:=Nil;
 ScPts:=Nil;ScEnds:=Nil;ScCap:=0;ScEndCap:=0;
 OffBuf:=Nil;OffScr:=False;GraphOn:=False;
 InHistMove:=False;
 CrcReady:=False;
 DxfCnt:=0;
End;

{ Charge le projet et les fichiers donnes en parametre ; retourne le nombre
  d'erreurs }
Function LoadStartup(Gui:Boolean):Integer;
Var
 I,Err:Integer;
 Msg:String;
Begin
 Err:=0;
 Msg:='';
 If OptProject<>'' Then Begin
  If LoadProject(OptProject)Then Begin
   AddRecent(FullPath(OptProject));
   If LoadWarn<>'' Then Msg:=Msg+LoadWarn+'|';
  End
   Else Begin
   Inc(Err);
   Msg:=Msg+LoadErr+'|';
  End;
 End;
 For I:=1 to OptNFiles do Begin
  If ExtOf(OptFiles[I])='.qgs' Then Begin
   If LoadProject(OptFiles[I])Then AddRecent(FullPath(OptFiles[I])) Else Begin
    Inc(Err);
    Msg:=Msg+LoadErr+'|';
   End;
  End
   Else
  If AddLayerFromFile(OptFiles[I],'')=0 Then Begin
   Inc(Err);
   Msg:=Msg+LoadErr+'|';
  End;
 End;
 If Msg<>'' Then Begin
  If Gui Then MsgBox('Chargement',Msg) Else Begin
   Delete(Msg,Length(Msg),1);
   WriteLn('Erreur : ',ReplaceAll(Msg,'|',#13#10+'         '));
  End;
 End;
 LoadStartup:=Err;
End;

Procedure RunScripts(Gui:Boolean);
Var
 Script:String;
 Code:Integer;
Begin
 Script:=OptCode;
 If Script='' Then Script:=OptPython;
 If Script='' Then Exit;
 If Not FileExist(Script)Then Begin
  If Gui Then MsgBox('Script Python','Fichier introuvable : '+Script)
         Else WriteLn('Erreur : script introuvable : ',Script);
  Exit;
 End;
 EnsureDirs;
 Code:=RunPython(Script,LogFile);
 LastLog:=LogFile;
 If Gui Then Begin
  ViewFile('Sortie de '+FileOf(Script)+' (code '+IntStr(Code)+')',LogFile);
 End
  Else
 Begin
  If Code=-1 Then WriteLn('Erreur : impossible d''executer l''interpreteur Python.')
  Else Begin
   If Code<>0 Then WriteLn('Le script Python s''est termine avec le code ',Code);
   Script:=ReadFirstLine(LogFile);
  End;
 End;
End;

Function RunHeadless:Integer;
Var
 X1,Y1,X2,Y2:Double;
 UseExt,Ok:Boolean;
 Err:Integer;
Begin
 RunHeadless:=0;
 SetClip(0,0,OptWidth-1,OptHeight-1);
 Err:=LoadStartup(False);
 If(NLay=0)and(Err>0)Then Begin
  RunHeadless:=2;
  Exit;
 End;
 RunScripts(False);
 If OptDxfExport<>'' Then Begin
  UseExt:=False;
  If OptDxfExtent<>'' Then Begin
   If Not ParseExtent(OptDxfExtent,X1,Y1,X2,Y2)Then Begin
    WriteLn('Erreur : --dxf-extent attend xmin,ymin,xmax,ymax');
    RunHeadless:=1;
    Exit;
   End;
   UseExt:=True;
  End;
  If Not AnyVector Then Begin
   WriteLn('Erreur : aucune couche vecteur a exporter.');
   RunHeadless:=2;
   Exit;
  End;
  If ExportDXF(OptDxfExport,UseExt,X1,Y1,X2,Y2)Then
   WriteLn('Export DXF : ',DxfCnt,' entite(s) -> ',OptDxfExport)
  Else Begin
   WriteLn('Erreur : impossible d''ecrire ',OptDxfExport);
   RunHeadless:=3;
   Exit;
  End;
 End;
 If OptSnapshot<>'' Then Begin
  If NLay=0 Then Begin
   WriteLn('Erreur : aucune couche a representer.');
   RunHeadless:=2;
   Exit;
  End;
  UseExt:=False;
  If OptExtent<>'' Then Begin
   If Not ParseExtent(OptExtent,X1,Y1,X2,Y2)Then Begin
    WriteLn('Erreur : --extent attend xmin,ymin,xmax,ymax');
    RunHeadless:=1;
    Exit;
   End;
   UseExt:=True;
  End
   Else
  If PExtOk and(OptProject<>'')Then Begin
   X1:=PEx1;Y1:=PEy1;X2:=PEx2;Y2:=PEy2;
   UseExt:=True;
  End;
  If Not RenderOffscreen(OptWidth,OptHeight,UseExt,X1,Y1,X2,Y2)Then Begin
   WriteLn('Erreur : ',LoadErr);
   RunHeadless:=3;
   Exit;
  End;
  If ExtOf(OptSnapshot)='.bmp' Then Ok:=SaveBMP(OptSnapshot) Else Ok:=SavePNG(OptSnapshot);
  FreeOffscreen;
  If Ok Then WriteLn('Capture enregistree : ',OptSnapshot,' (',OptWidth,'x',OptHeight,')')
  Else Begin
   WriteLn('Erreur : impossible d''ecrire ',OptSnapshot);
   RunHeadless:=3;
  End;
 End;
End;

Procedure ShowSplash;
Var
 X,Y,N:Integer;
 E:TEvent;
Begin
 HM;
 SetFillStyle(SolidFill,White);
 Bar(0,0,ScrW-1,ScrH-1);
 X:=ScrW div 2;
 Y:=ScrH div 2-60;
 SetColor(Green);
 SetFillStyle(SolidFill,LightGreen);
 Circle(X,Y,50);
 Circle(X,Y,49);
 Circle(X,Y,48);
 Circle(X,Y,47);
 Circle(X,Y,46);
 Circle(X,Y,36);
 Circle(X,Y,35);
 SetColor(Black);
 Line(X+22,Y+24,X+58,Y+60);
 Line(X+23,Y+24,X+59,Y+60);
 Line(X+22,Y+25,X+58,Y+61);
 Line(X+24,Y+24,X+60,Y+60);
 SetColor(Blue);
 Circle(X-4,Y-4,6);
 Circle(X+10,Y+8,4);
 SetColor(Red);
 Circle(X-14,Y+10,3);
 SetColor(Black);
 OutTextXY(X-Length('QGIS - Clone Pascal')*4,Y+90,'QGIS - Clone Pascal');
 OutTextXY(X-Length('Version '+VersionStr)*4,Y+106,'Version '+VersionStr);
 OutTextXY(X-Length('Compatible avec les parametres de QGIS '+QgisCompat)*4,Y+122,'Compatible avec les parametres de QGIS '+QgisCompat);
 SetColor(DarkGray);
 OutTextXY(X-Length('GEO Commander - gladir.com')*4,Y+150,'GEO Commander - gladir.com');
 If OptNoPlugins Then OutTextXY(X-Length('(extensions desactivees)')*4,Y+170,'(extensions desactivees)');
 SM;
 N:=0;
 While N<150 do Begin
  If GetEvent(E)Then Begin
   If(E.What=evKey)or(E.What=evDown)Then N:=1000;
  End
   Else WaitTick;
  Inc(N);
 End;
 FlushEvents;
End;

Procedure RunGui;
Begin
 InitializeGraphics;
 MouseOk:=MouseDriverFound;
 If MouseOk Then ShowMouse;
 InitMenus;
 ApplyCustomization;
 LayoutMenus;
 InitToolbar;
 SetupCanvas;
 ZoomWorld;
 If Not OptNoLogo Then ShowSplash;
 RedrawAll;
 SetMsg('Pret - Alt+lettre ou souris pour les menus, F1 = aide');
 If(OptProject<>'')or(OptNFiles>0)Then Begin
  LoadStartup(True);
  SetupCanvas;
  If PExtOk and(OptProject<>'')Then ZoomToExtent(PEx1,PEy1,PEx2,PEy2) Else ZoomAll;
  RedrawAll;
 End;
 If(OptCode<>'')or(OptPython<>'')Then Begin
  RunScripts(True);
  RedrawAll;
 End;
 MainLoop;
 SaveSettings;
 If MouseOk Then HideMouse;
 CloseGraph;
End;

Var
 ExitCode:Integer;

BEGIN
 InitGlobals;
 ParseArgs;
 SetupProfile;
 LoadSettings;
 QPath:=FindQgisProcess;
 If(OptDxfExport<>'')or(OptSnapshot<>'')Then Begin
  ExitCode:=RunHeadless;
  Halt(ExitCode);
 End;
 RunGui;
END.
