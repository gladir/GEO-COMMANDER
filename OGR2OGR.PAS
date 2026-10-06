{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
  @description: OGR2OGR - conversion et traitements vectoriels autonomes
  Formats reellement pris en charge par le backend: GeoJSON, Shapefile,
  GeoPackage, CSV/TXT, GML/XML, KML et KMZ. Pas d'append natif.
}
Program Ogr2Ogr;

Uses Dos;

Const
 MaxParams = 24;
 MaxLine = 255;

Type
 TStringArray = Array[1..MaxParams] Of String[255];

Var
 Src, Dst, FormatName, TargetSRS, SourceSRS, AssignSRS : String;
 SelectFields, WhereExpr, ClipSrc, ClipDst, NewLayerName : String;
 SpatialSRS, GeometryType, Dimension : String;
 HasTarget, HasSource, HasAssign, HasSelect, HasWhere : Boolean;
 HasClipSrc, HasClipDst, HasSpat, HasSpatSRS, Overwrite : Boolean;
 HasLayerName, HasDim, DropDimensions, Quiet : Boolean;
 SpatXMin, SpatYMin, SpatXMax, SpatYMax : Real;
 TempFiles : Array[1..MaxParams] Of String;
 TempCount, TempSeq : Integer;

Function UpperString(S : String) : String;
Var I : Integer;
Begin
 For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
 UpperString:=S;
End;

Function IsNumber(S : String; Var Value : Real) : Boolean;
Var Err : Integer;
Begin Val(S,Value,Err); IsNumber:=Err=0; End;

Function FileExtension(S : String) : String;
Var I, DotPos, BasePos : Integer;
Begin
 DotPos:=0; BasePos:=1;
 For I:=1 To Length(S) Do Begin
  If (S[I]='\') Or (S[I]='/') Then Begin BasePos:=I+1; DotPos:=0; End
  Else If S[I]='.' Then DotPos:=I;
 End;
 If (DotPos=0) Or (DotPos<BasePos) Then FileExtension:=''
 Else FileExtension:=UpperString(Copy(S,DotPos,Length(S)-DotPos+1));
End;

Function QuoteArg(S : String) : String;
Var I : Integer; NeedQuote : Boolean;
Begin
 NeedQuote:=False;
 For I:=1 To Length(S) Do If S[I] In [' ',#9] Then NeedQuote:=True;
 If NeedQuote Then QuoteArg:='"'+S+'"' Else QuoteArg:=S;
End;

Function RealText(Value : Real) : String;
Var S : String;
Begin
 Str(Value:0:10,S);
 While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
 While (S<>'') And (S[Length(S)]='0') Do Delete(S,Length(S),1);
 If (S<>'') And (S[Length(S)]='.') Then Delete(S,Length(S),1);
 RealText:=S;
End;

Function FormatFits(FormatName, FileName : String) : Boolean;
Var F,E : String;
Begin
 F:=UpperString(FormatName); E:=FileExtension(FileName);
 FormatFits:=False;
 If (F='GEOJSON') Or (F='JSON') Then FormatFits:=(E='.GEOJSON') Or (E='.JSON');
 If (F='ESRI SHAPEFILE') Or (F='ESRI_SHAPEFILE') Or (F='SHP') Then FormatFits:=E='.SHP';
 If (F='GPKG') Or (F='GEOPACKAGE') Then FormatFits:=E='.GPKG';
 If (F='CSV') Then FormatFits:=(E='.CSV') Or (E='.TXT');
 If (F='GML') Then FormatFits:=(E='.GML') Or (E='.XML');
 If F='KML' Then FormatFits:=E='.KML';
 If F='KMZ' Then FormatFits:=E='.KMZ';
End;

Function ExtensionForFormat(FormatName : String) : String;
Var F : String;
Begin
 F:=UpperString(FormatName);
 If (F='GEOJSON') Or (F='JSON') Then ExtensionForFormat:='.geojson' Else
 If (F='GPKG') Or (F='GEOPACKAGE') Then ExtensionForFormat:='.gpkg' Else
 If (F='ESRI SHAPEFILE') Or (F='ESRI_SHAPEFILE') Or (F='SHP') Then ExtensionForFormat:='.shp' Else
 If F='CSV' Then ExtensionForFormat:='.csv' Else
 If F='GML' Then ExtensionForFormat:='.gml' Else
 If F='KML' Then ExtensionForFormat:='.kml' Else
 If F='KMZ' Then ExtensionForFormat:='.kmz' Else ExtensionForFormat:='';
End;

Function HasExtension(FileName : String) : Boolean;
Var I, BasePos : Integer;
Begin
 HasExtension:=False; BasePos:=1;
 For I:=1 To Length(FileName) Do Begin
  If (FileName[I]='\') Or (FileName[I]='/') Then Begin BasePos:=I+1; HasExtension:=False; End
  Else If (FileName[I]='.') And (I>=BasePos) Then HasExtension:=True;
 End;
End;

Function FileExistsLocal(FileName : String) : Boolean;
Var F : File; Code : Integer;
Begin
 Assign(F,FileName);
 {$I-} Reset(F); Code:=IOResult; {$I+}
 FileExistsLocal:=Code=0;
 If Code=0 Then Close(F);
End;

Procedure DeleteLocalFile(FileName : String);
Var F : File; Code : Integer;
Begin
 If FileName='' Then Exit;
 Assign(F,FileName);
 {$I-}
 Reset(F,1); Code:=IOResult;
 If Code=0 Then Close(F);
 Erase(F); Code:=IOResult;
 {$I+}
End;

Function RunAlgorithm(Algorithm, Parameters, ExpectedOutput : String) : Boolean;
Var CommandLine : String; OK : Boolean;
Begin
 RunAlgorithm:=False;
 CommandLine:='run '+Algorithm;
 If Parameters<>'' Then CommandLine:=CommandLine+' '+Parameters;
 If Length(CommandLine)>127 Then Begin
  WriteLn('Erreur: arguments trop longs pour Exec DOS (127 caracteres).');
  WriteLn('Raccourcissez les chemins ou les expressions.');
  Exit;
 End;
 SwapVectors;
 Exec('QGIS_PROCESS.EXE',CommandLine);
 SwapVectors;
 If DosError<>0 Then Begin
  WriteLn('Erreur: QGIS_PROCESS.EXE introuvable ou impossible a lancer (code ',DosError,').');
  Exit;
 End;
 If ExpectedOutput<>'' Then Begin
  OK:=FileExistsLocal(ExpectedOutput);
  RunAlgorithm:=OK;
  If Not OK Then WriteLn('Erreur: le backend n''a pas cree ',ExpectedOutput);
 End Else RunAlgorithm:=True;
End;

Function NewTemporaryGeoJSON : String;
Var S : String;
Begin
 Inc(TempSeq);
 Str(TempSeq,S);
 NewTemporaryGeoJSON:='T'+S+'.JSON';
 If TempCount<MaxParams Then Begin Inc(TempCount); TempFiles[TempCount]:='T'+S+'.JSON'; End;
End;

Procedure CleanupTemps;
Var I : Integer;
Begin
 For I:=1 To TempCount Do DeleteLocalFile(TempFiles[I]);
 TempCount:=0;
End;

Procedure ShowFormats;
Begin
 WriteLn('Formats vectoriels du backend QGIS_PROCESS:');
 WriteLn('  GeoJSON (.geojson, .json)');
 WriteLn('  ESRI Shapefile (.shp)');
 WriteLn('  GeoPackage (.gpkg)');
 WriteLn('  CSV/TXT, GML/XML, KML, KMZ');
 WriteLn('Lecture/creation limitee aux capacites de QGIS_PROCESS.EXE.');
End;

Procedure ShowHelp;
Begin
 WriteLn('OGR2OGR - Cette commande permet d''effectuer des operations de conversion, reprojection ',
        'et filtres vectoriels (clone autonome).');
 WriteLn;
 WriteLn('Syntaxe: OGR2OGR [options] destination source [couche...]');
 WriteLn;
 WriteLn('  -f, -of FORMAT       GeoJSON, GPKG, ESRI Shapefile, CSV, GML, KML, KMZ');
 WriteLn('  -s_srs CRS           assigne le CRS source avant les traitements');
 WriteLn('  -t_srs CRS           reprojette vers le CRS cible');
 WriteLn('  -a_srs CRS           assigne un CRS sans changer les coordonnees');
 WriteLn('  -select champs       conserve les champs listes par virgules');
 WriteLn('  -where expression    filtre attributaire (syntaxe d''expression QGIS)');
 WriteLn('  -spat xmin ymin xmax ymax  filtre par emprise');
 WriteLn('  -clipsrc fichier     decoupe par le polygone source');
 WriteLn('  -clipdst fichier     decoupe par le polygone cible');
 WriteLn('  -nln nom             nom de couche (non pris en charge par ce backend)');
 WriteLn('  -nlt type            type geometrique (non pris en charge par ce backend)');
 WriteLn('  -overwrite           remplace la destination (comportement par defaut)');
 WriteLn('  -append, -update     non pris en charge par le backend integre');
 WriteLn('  -progress            progression du moteur');
 WriteLn('  -q                   silencieux (non pris en charge par le moteur)');
 WriteLn('  --formats            liste les formats disponibles');
 WriteLn('  -h, --help, /?       affiche cette aide');
 WriteLn;
 WriteLn('Filtres supportes: -select, -where, -spat, -clipsrc, -clipdst.');
 WriteLn('Non implementes: SQL arbitraire, -ct, options de creation pilotes,');
 WriteLn('append/update, nlt, et noms de couches explicites.');
 WriteLn('Les traitements utilisent QGIS_PROCESS.EXE et acceptent des chemins');
 WriteLn('GeoJSON, SHP, GPKG, CSV/TXT, GML/XML, KML et KMZ.');
 WriteLn('Limite DOS: ligne de commande backend de 127 caracteres.');
End;

Procedure FailUsage(Message : String);
Begin
 WriteLn('Erreur: ',Message);
 WriteLn('Utilisez OGR2OGR /? pour l''aide.');
 Halt(1);
End;

Procedure NeedValue(Var I : Integer; OptionName : String; Var Value : String);
Begin
 Inc(I);
 If I>ParamCount Then FailUsage('valeur manquante apres '+OptionName);
 Value:=ParamStr(I);
End;

Procedure RunStage(Algorithm, Parameters : String; Var CurrentFile : String;
                   CurrentIsTemp : Boolean);
Var OutFile : String; OK : Boolean;
Begin
 OutFile:=NewTemporaryGeoJSON;
 OK:=RunAlgorithm(Algorithm,Parameters+' --OUTPUT='+QuoteArg(OutFile),OutFile);
 If Not OK Then Begin CleanupTemps; Halt(1); End;
 If CurrentIsTemp Then DeleteLocalFile(CurrentFile);
 CurrentFile:=OutFile;
End;

Procedure RunFinalSave(CurrentFile : String);
Var Parameters : String;
Begin
 Parameters:='--INPUT='+QuoteArg(CurrentFile)+' --OUTPUT='+QuoteArg(Dst);
 If Not RunAlgorithm('native:savefeatures',Parameters,Dst) Then Begin CleanupTemps; Halt(1); End;
 CleanupTemps;
End;

Procedure ProcessOGR2OGR;
Var CurrentFile, Parameters, ExtText : String;
 CurrentIsTemp, AnyStage : Boolean;
Begin
 CurrentFile:=Src; CurrentIsTemp:=False; AnyStage:=False;
 If HasSource Then Begin
  RunStage('native:assignprojection','--INPUT='+QuoteArg(CurrentFile)+
   ' --CRS='+QuoteArg(SourceSRS),CurrentFile,CurrentIsTemp);
  CurrentIsTemp:=True; AnyStage:=True;
 End;
 If HasClipSrc Then Begin
  RunStage('native:clip','--INPUT='+QuoteArg(CurrentFile)+' --OVERLAY='+
   QuoteArg(ClipSrc),CurrentFile,CurrentIsTemp);
  CurrentIsTemp:=True; AnyStage:=True;
 End;
 If HasSpat Then Begin
  ExtText:=RealText(SpatXMin); Parameters:='--INPUT='+QuoteArg(CurrentFile)+' --EXTENT='+
   ExtText+',';
  ExtText:=RealText(SpatXMax); Parameters:=Parameters+ExtText+',';
  ExtText:=RealText(SpatYMin); Parameters:=Parameters+ExtText+',';
  ExtText:=RealText(SpatYMax); Parameters:=Parameters+ExtText;
  RunStage('native:extractbyextent',Parameters,CurrentFile,CurrentIsTemp);
  CurrentIsTemp:=True; AnyStage:=True;
 End;
 If HasWhere Then Begin
  RunStage('native:extractbyexpression','--INPUT='+QuoteArg(CurrentFile)+
   ' --EXPRESSION='+QuoteArg(WhereExpr),CurrentFile,CurrentIsTemp);
  CurrentIsTemp:=True; AnyStage:=True;
 End;
 If HasSelect Then Begin
  RunStage('native:retainfields','--INPUT='+QuoteArg(CurrentFile)+
   ' --FIELDS='+QuoteArg(SelectFields),CurrentFile,CurrentIsTemp);
  CurrentIsTemp:=True; AnyStage:=True;
 End;
 If HasTarget Then Begin
  RunStage('native:reprojectlayer','--INPUT='+QuoteArg(CurrentFile)+
   ' --TARGET_CRS='+QuoteArg(TargetSRS),CurrentFile,CurrentIsTemp);
  CurrentIsTemp:=True; AnyStage:=True;
 End;
 If HasClipDst Then Begin
  RunStage('native:clip','--INPUT='+QuoteArg(CurrentFile)+' --OVERLAY='+
   QuoteArg(ClipDst),CurrentFile,CurrentIsTemp);
  CurrentIsTemp:=True; AnyStage:=True;
 End;
 If DropDimensions Then Begin
  RunStage('native:dropmzvalues','--INPUT='+QuoteArg(CurrentFile)+
   ' --DROP_Z_VALUES=true --DROP_M_VALUES=true',CurrentFile,CurrentIsTemp);
  CurrentIsTemp:=True; AnyStage:=True;
 End;
 If HasAssign Then Begin
  RunStage('native:assignprojection','--INPUT='+QuoteArg(CurrentFile)+
   ' --CRS='+QuoteArg(AssignSRS),CurrentFile,CurrentIsTemp);
  CurrentIsTemp:=True; AnyStage:=True;
 End;
 If AnyStage Then RunFinalSave(CurrentFile)
 Else If Not RunAlgorithm('native:savefeatures','--INPUT='+QuoteArg(Src)+
        ' --OUTPUT='+QuoteArg(Dst),Dst) Then Halt(1);
End;

Procedure ParseCommandLine;
Var I : Integer; Arg, Value : String; Numeric : Array[1..4] Of Real;
 J : Integer;
Begin
 Src:=''; Dst:=''; FormatName:=''; TargetSRS:=''; SourceSRS:=''; AssignSRS:='';
 SelectFields:=''; WhereExpr:=''; ClipSrc:=''; ClipDst:=''; NewLayerName:='';
 SpatialSRS:=''; GeometryType:=''; Dimension:='';
 HasTarget:=False; HasSource:=False; HasAssign:=False; HasSelect:=False; HasWhere:=False;
 HasClipSrc:=False; HasClipDst:=False; HasSpat:=False; HasSpatSRS:=False;
 Overwrite:=False; HasLayerName:=False; HasDim:=False; DropDimensions:=False; Quiet:=False;
 I:=1;
 While I<=ParamCount Do Begin
  Arg:=ParamStr(I);
  If (Arg='-h') Or (Arg='--help') Or (Arg='/?') Then Begin ShowHelp; Halt(0); End Else
  If Arg='--formats' Then Begin ShowFormats; Halt(0); End Else
  If (Arg='--version') Or (Arg='-V') Then Begin WriteLn('OGR2OGR Pascal 1.0 (QGIS_PROCESS backend)'); Halt(0); End Else
  If (Arg='-f') Or (Arg='-of') Then Begin NeedValue(I,Arg,FormatName); End Else
  If Arg='-s_srs' Then Begin NeedValue(I,Arg,SourceSRS); HasSource:=True; End Else
  If Arg='-t_srs' Then Begin NeedValue(I,Arg,TargetSRS); HasTarget:=True; End Else
  If Arg='-a_srs' Then Begin NeedValue(I,Arg,AssignSRS); HasAssign:=True; End Else
  If Arg='-select' Then Begin NeedValue(I,Arg,SelectFields); HasSelect:=True; End Else
  If Arg='-where' Then Begin NeedValue(I,Arg,WhereExpr); HasWhere:=True; End Else
  If Arg='-clipsrc' Then Begin NeedValue(I,Arg,ClipSrc); HasClipSrc:=True; End Else
  If Arg='-clipdst' Then Begin NeedValue(I,Arg,ClipDst); HasClipDst:=True; End Else
  If Arg='-spat_srs' Then Begin NeedValue(I,Arg,SpatialSRS); HasSpatSRS:=True; End Else
  If Arg='-spat' Then Begin
   If I+4>ParamCount Then FailUsage('-spat attend xmin ymin xmax ymax');
   For J:=1 To 4 Do Begin Inc(I); If Not IsNumber(ParamStr(I),Numeric[J]) Then FailUsage('coordonnees -spat invalides'); End;
   SpatXMin:=Numeric[1]; SpatYMin:=Numeric[2]; SpatXMax:=Numeric[3]; SpatYMax:=Numeric[4];
   If (SpatXMin>SpatXMax) Or (SpatYMin>SpatYMax) Then FailUsage('emprise -spat invalide');
   HasSpat:=True;
  End Else
  If Arg='-nln' Then Begin NeedValue(I,Arg,NewLayerName); HasLayerName:=True; End Else
  If Arg='-nlt' Then Begin NeedValue(I,Arg,GeometryType); End Else
  If Arg='-dim' Then Begin NeedValue(I,Arg,Dimension); HasDim:=True; End Else
  If Arg='-overwrite' Then Overwrite:=True Else
  If (Arg='-append') Or (Arg='-update') Or (Arg='-addfields') Then
   FailUsage(Arg+' non pris en charge par le backend integre.') Else
  If (Arg='-sql') Or (Arg='-dialect') Or (Arg='-ct') Or (Arg='-order') Or
     (Arg='-lco') Or (Arg='-dsco') Or (Arg='-oo') Or (Arg='-doo') Or
     (Arg='-gt') Or (Arg='-skipfailures') Then Begin
   If (Arg='-sql') Or (Arg='-dialect') Or (Arg='-ct') Or (Arg='-order') Or
      (Arg='-lco') Or (Arg='-dsco') Or (Arg='-oo') Or (Arg='-doo') Or (Arg='-gt') Then
    NeedValue(I,Arg,Value);
   FailUsage(Arg+' non pris en charge par le backend integre.');
  End Else
  If Arg='-progress' Then Begin End Else
  If Arg='-q' Then Quiet:=True Else Begin
   If (Arg<>'') And (Arg[1]='-') Then FailUsage('option inconnue '+Arg);
   If Dst='' Then Dst:=Arg Else If Src='' Then Src:=Arg
   Else FailUsage('plusieurs couches/fichiers source ne sont pas supportes');
  End;
  Inc(I);
 End;
 If (Dst='') Or (Src='') Then FailUsage('destination et source sont requises');
 If (FormatName<>'') And (Not FormatFits(FormatName,Dst)) Then Begin
  If (Not HasExtension(Dst)) And (ExtensionForFormat(FormatName)<>'') Then
   Dst:=Dst+ExtensionForFormat(FormatName)
  Else FailUsage('format ou extension de destination non pris en charge/incompatible');
 End;
 If (FormatName='') And (FileExtension(Dst)='') Then Dst:=Dst+'.geojson';
 If (FileExtension(Dst)<>'.GEOJSON') And (FileExtension(Dst)<>'.JSON') And
    (FileExtension(Dst)<>'.SHP') And (FileExtension(Dst)<>'.GPKG') And
    (FileExtension(Dst)<>'.CSV') And (FileExtension(Dst)<>'.TXT') And
    (FileExtension(Dst)<>'.GML') And (FileExtension(Dst)<>'.XML') And
    (FileExtension(Dst)<>'.KML') And (FileExtension(Dst)<>'.KMZ') Then
  FailUsage('format de destination non disponible dans le backend integre');
 If HasLayerName Then FailUsage('-nln indisponible: les pilotes d''ecriture du backend derivent le nom du fichier');
 If GeometryType<>'' Then FailUsage('-nlt n''est pas implemente dans le backend');
 If HasDim Then Begin
  If UpperString(Dimension)<>'XY' Then FailUsage('seule la dimension XY peut etre forcee');
  DropDimensions:=True;
 End;
 If HasSpatSRS Then FailUsage('-spat_srs n''est pas disponible; -spat utilise le CRS de la source');
 If FileExistsLocal(Dst) And (Not Overwrite) Then
  FailUsage('la destination existe deja; utilisez -overwrite');
 If Quiet Then FailUsage('-q non disponible: le backend affiche ses messages de traitement');
 If HasClipSrc And (Pos(',',ClipSrc)>0) Then FailUsage('-clipsrc prend uniquement un fichier polygonal');
 If HasClipDst And (Pos(',',ClipDst)>0) Then FailUsage('-clipdst prend uniquement un fichier polygonal');
 Randomize;
 TempCount:=0; TempSeq:=Random(8000)+1000;
End;

BEGIN
 ParseCommandLine;
 ProcessOGR2OGR;
END.
