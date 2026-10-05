{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
  @description: Interpreteur de commandes geographiques
  Les traitements de couches utilisent QGIS_PROCESS.EXE (moteur Pascal du depot).
  Les rasters pris en charge par ce moteur sont principalement les grilles .ASC.
}

Program Geo;

Uses
 Dos;

Const
 PI = 3.14159265358979323846;
 EarthRadiusKm = 6371.0088;
 MaxTokens = 10;

Type
 TTokenArray = Array[1..MaxTokens] Of String[255];
 TCity = Record
  Name : String[20];
  Latitude, Longitude : Real;
 End;

Const
 Cities : Array[1..5] Of TCity = (
  (Name:'Montreal'; Latitude:45.5017; Longitude:-73.5673),
  (Name:'Quebec';   Latitude:46.8139; Longitude:-71.2080),
  (Name:'Ottawa';   Latitude:45.4215; Longitude:-75.6972),
  (Name:'Toronto';  Latitude:43.6532; Longitude:-79.3832),
  (Name:'Paris';    Latitude:48.8566; Longitude:2.3522)
 );

Function UpperString(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do S[I] := UpCase(S[I]);
 UpperString := S;
End;

Function FileExtension(FileName : String) : String;
Var I, LastDot : Integer;
Begin
 LastDot := 0;
 For I := 1 To Length(FileName) Do If FileName[I] = '.' Then LastDot := I;
 If LastDot = 0 Then FileExtension := ''
 Else FileExtension := UpperString(Copy(FileName, LastDot, Length(FileName) - LastDot + 1));
End;

Function DefaultReprojectName(FileName : String) : String;
Var I, LastDot : Integer;
Begin
 LastDot := 0;
 For I := 1 To Length(FileName) Do If FileName[I] = '.' Then LastDot := I;
 If LastDot = 0 Then LastDot := Length(FileName) + 1;
 DefaultReprojectName := Copy(FileName, 1, LastDot - 1) + '_reprojected.geojson';
End;

Function DegToRad(D : Real) : Real;
Begin
 DegToRad := D * PI / 180.0;
End;

Function ArcTan2(Y, X : Real) : Real;
Var A : Real;
Begin
 If X > 0.0 Then A := ArcTan(Y / X)
 Else If X < 0.0 Then Begin
  A := ArcTan(Y / X);
  If Y >= 0.0 Then A := A + PI
  Else A := A - PI;
 End Else If Y > 0.0 Then A := PI / 2.0
 Else If Y < 0.0 Then A := -PI / 2.0
 Else A := 0.0;
 ArcTan2 := A;
End;

Procedure ParseLine(Line : String; Var Tokens : TTokenArray;
                    Var Count : Integer);
Var I : Integer; InQuote : Boolean; Ch : Char; S : String;
Begin
 Count := 0;
 I := 1;
 While (I <= Length(Line)) And (Count < MaxTokens) Do Begin
  While (I <= Length(Line)) And (Line[I] In [' ', #9]) Do Inc(I);
  If I <= Length(Line) Then Begin
   InQuote := False;
   If Line[I] = '"' Then Begin InQuote := True; Inc(I); End;
   S := '';
   While I <= Length(Line) Do Begin
    Ch := Line[I];
    If InQuote Then Begin
     If Ch = '"' Then Begin Inc(I); Break; End;
     S := S + Ch;
    End Else Begin
     If Ch In [' ', #9] Then Break;
     S := S + Ch;
    End;
    Inc(I);
   End;
   While (I <= Length(Line)) And Not (Line[I] In [' ', #9]) Do Inc(I);
   If S <> '' Then Begin
    Inc(Count);
    Tokens[Count] := S;
   End;
  End;
 End;
End;

Function IsNumber(S : String; Var Value : Real) : Boolean;
Var Code : Integer;
Begin
 Val(S, Value, Code);
 IsNumber := Code = 0;
End;

Function CityCoordinates(Name : String; Var Lat, Lon : Real) : Boolean;
Var I : Integer; Key : String;
Begin
 Key := UpperString(Name);
 CityCoordinates := False;
 For I := 1 To 5 Do
  If UpperString(Cities[I].Name) = Key Then Begin
   Lat := Cities[I].Latitude;
   Lon := Cities[I].Longitude;
   CityCoordinates := True;
  End;
End;

Function DistanceKm(Lat1, Lon1, Lat2, Lon2 : Real) : Real;
Var P1, P2, DL, DN, A : Real;
Begin
 P1 := DegToRad(Lat1);
 P2 := DegToRad(Lat2);
 DL := DegToRad(Lat2 - Lat1);
 DN := DegToRad(Lon2 - Lon1);
 A := Sqr(Sin(DL / 2.0)) + Cos(P1) * Cos(P2) * Sqr(Sin(DN / 2.0));
 If A < 0.0 Then A := 0.0;
 If A > 1.0 Then A := 1.0;
 DistanceKm := 2.0 * EarthRadiusKm * ArcTan2(Sqrt(A), Sqrt(1.0 - A));
End;

Function QuoteArg(S : String) : String;
Var I : Integer; NeedsQuotes : Boolean;
Begin
 NeedsQuotes := False;
 For I := 1 To Length(S) Do
  If S[I] In [' ', #9] Then NeedsQuotes := True;
 If NeedsQuotes Then QuoteArg := '"' + S + '"'
 Else QuoteArg := S;
End;

Procedure RunProcessing(Algorithm, Parameters : String);
Var CommandLine : String;
Begin
 CommandLine := 'run ' + Algorithm + ' ' + Parameters;
 If Length(CommandLine) > 127 Then Begin
  Writeln('Erreur: ligne d''execution trop longue pour le mode Turbo Pascal.');
  Exit;
 End;
 SwapVectors;
 Exec('QGIS_PROCESS.EXE', CommandLine);
 SwapVectors;
 If DosError <> 0 Then
  Writeln('Erreur: QGIS_PROCESS.EXE introuvable ou impossible a lancer (code ', DosError, ').');
End;

Procedure ShowHelp;
Begin
 Writeln('GEO - interpreteur geographique : ');
 Writeln('Cette commande permet d''inspecter des donn'+#130+'es g'+#130+'ographiques, de convertir et reprojeter');
 Writeln('des couches, de lancer des traitements raster et d''obtenir des distances.');
 Writeln('Les traitements de couches utilisent QGIS_PROCESS.EXE.');
 Writeln;
 Writeln('Commandes:');
 Writeln('  INFO fichier');
 Writeln('  CONVERT entree.asc sortie.asc');
 Writeln('  REPROJECT entree.geojson EPSG:4326 [sortie.geojson]');
 Writeln('  BUFFER entree.geojson sortie.geojson distance');
 Writeln('  DISTANCE ville1 ville2 | DISTANCE lat1 lon1 lat2 lon2');
 Writeln('  COORD latitude longitude');
 Writeln('  ELEVATION terrain.asc latitude longitude');
 Writeln('  SLOPE entree.asc sortie.asc');
 Writeln('  CONTOUR entree.asc sortie.geojson intervalle');
 Writeln('  WATERSHED entree.asc sortie.asc');
 Writeln('  HILLSHADE entree.asc sortie.asc');
 Writeln('  RASTERIZE entree.geojson sortie.asc');
 Writeln('  VECTORIZE entree.asc sortie.geojson');
 Writeln('  MAP fichier.geojson');
 Writeln('  HELP | EXIT | QUIT');
 Writeln;
 Writeln('Les traitements raster passent par QGIS_PROCESS.EXE du meme dossier.');
 Writeln('Les formats raster du moteur sont surtout ESRI ASCII Grid (.asc);');
 Writeln('les couches vecteur prises en charge sont principalement GeoJSON.');
 Writeln('BUFFER utilise les unites planes de la couche, pas une distance geodesique.');
 Writeln('ELEVATION echantillonne une grille ESRI ASCII; donnez le DEM explicitement.');
 Writeln('MAP affiche des informations textuelles, pas une fenetre cartographique.');
 Writeln('WATERSHED n''est pas fourni par le moteur integre.');
End;

Procedure CommandInfo(FileName : String);
Var
 Ext, S : String;
 InfoFile, SourceFile : Text;
 Code : Integer;
Begin
 Ext := FileExtension(FileName);
 If (Ext = '.ASC') Or (Ext = '.TXT') Then Begin
  Assign(SourceFile, FileName);
  {$I-}
  Reset(SourceFile);
  Code := IOResult;
  {$I+}
  If Code <> 0 Then Begin Writeln('Erreur: impossible d''ouvrir ', FileName); Exit; End;
  Writeln('Grille ESRI ASCII: ', FileName);
  For Code := 1 To 6 Do Begin
   If EOF(SourceFile) Then Break;
   ReadLn(SourceFile, S);
   Writeln('  ', S);
  End;
  Close(SourceFile);
 End Else
 If (Ext = '.JSON') Or (Ext = '.GEOJSON') Or
   (Ext = '.SHP') Or (Ext = '.GPKG') Then
  Begin
   RunProcessing('gdal:ogrinfo', '--INPUT=' + QuoteArg(FileName) +
                 ' --SUMMARY_ONLY=true --OUTPUT="GEOINFO.TXT"');
   Assign(InfoFile, 'GEOINFO.TXT');
   {$I-}
   Reset(InfoFile);
   Code := IOResult;
   {$I+}
   If Code = 0 Then Begin
    While Not EOF(InfoFile) Do Begin ReadLn(InfoFile, S); Writeln(S); End;
    Close(InfoFile);
    {$I-}
    Erase(InfoFile);
    IOResult;
    {$I+}
   End;
  End
  Else If (Ext = '.TIF') Or (Ext = '.TIFF') Then
   Writeln('INFO raster GeoTIFF non fourni par le moteur. Les grilles .ASC sont affichees ci-dessus.')
  Else
  Writeln('INFO: format non inspecte directement. Fichier: ', FileName);
End;

Procedure CommandElevation(FileName, LatText, LonText : String);
Var
 Lat, Lon, CellSize, XOrigin, YOrigin, Value, Sample, NoData : Real;
 NCols, NRows, Col, Row, R, C, Code : LongInt;
 Key, HeaderValue : String;
 HeaderTokens : TTokenArray;
 HeaderCount, HeaderIndex : Integer;
 Found, HaveX, HaveY, HaveCell, HaveCols, HaveRows : Boolean;
 XCenter, YCenter, HaveNoData : Boolean;
 GridFile : Text;
Begin
 If Not IsNumber(LatText, Lat) Or Not IsNumber(LonText, Lon) Then Begin
  Writeln('Erreur: ELEVATION attend un raster ASCII, latitude et longitude numeriques.');
  Exit;
 End;
 Assign(GridFile, FileName);
 {$I-}
 Reset(GridFile);
 Code := IOResult;
 {$I+}
 If Code <> 0 Then Begin Writeln('Erreur: impossible d''ouvrir ', FileName); Exit; End;
 NCols := 0; NRows := 0; XOrigin := 0.0; YOrigin := 0.0; CellSize := 0.0;
 HaveX := False; HaveY := False; HaveCell := False;
 HaveCols := False; HaveRows := False;
 XCenter := False; YCenter := False; HaveNoData := False;
 HeaderIndex := 0;
 While (HeaderIndex < 6) And Not EOF(GridFile) Do Begin
  ReadLn(GridFile, Key);
  ParseLine(Key, HeaderTokens, HeaderCount);
  If HeaderCount >= 2 Then Begin
   Key := UpperString(HeaderTokens[1]);
   HeaderValue := HeaderTokens[2];
   If Key = 'NCOLS' Then Begin Val(HeaderValue, NCols, Code); HaveCols := Code = 0; End Else
   If Key = 'NROWS' Then Begin Val(HeaderValue, NRows, Code); HaveRows := Code = 0; End Else
   If (Key = 'XLLCORNER') Or (Key = 'XLLCENTER') Then Begin
    HaveX := IsNumber(HeaderValue, XOrigin);
    XCenter := Key = 'XLLCENTER';
   End Else
   If (Key = 'YLLCORNER') Or (Key = 'YLLCENTER') Then Begin
    HaveY := IsNumber(HeaderValue, YOrigin);
    YCenter := Key = 'YLLCENTER';
   End Else
   If Key = 'CELLSIZE' Then Begin
    HaveCell := IsNumber(HeaderValue, CellSize);
   End Else
   If Key = 'NODATA_VALUE' Then Begin
    HaveNoData := IsNumber(HeaderValue, NoData);
   End;
  End;
  Inc(HeaderIndex);
 End;
 If (Not HaveCols) Or (Not HaveRows) Or (Not HaveX) Or (Not HaveY) Or
    (Not HaveCell) Or (CellSize <= 0.0) Then Begin
  Close(GridFile);
  Writeln('Erreur: entete ESRI ASCII Grid invalide.');
  Exit;
 End;
 If XCenter Then XOrigin := XOrigin - CellSize / 2.0;
 If YCenter Then YOrigin := YOrigin - CellSize / 2.0;
 Col := Trunc((Lon - XOrigin) / CellSize);
 Row := NRows - 1 - Trunc((Lat - YOrigin) / CellSize);
 If (Col < 0) Or (Col >= NCols) Or (Row < 0) Or (Row >= NRows) Then Begin
  Close(GridFile);
  Writeln('Coordonnee hors de l''emprise du raster.');
  Exit;
 End;
 Found := False;
 For R := 0 To NRows - 1 Do Begin
  For C := 0 To NCols - 1 Do Begin
   Read(GridFile, Value);
  If (R = Row) And (C = Col) Then Begin
   Sample := Value;
   Found := True;
  End;
  End;
  ReadLn(GridFile);
 End;
 Close(GridFile);
 If Found And HaveNoData And (Abs(Sample - NoData) < 0.0000001) Then
  Writeln('Aucune donnee d''elevation dans cette cellule (NoData).')
 Else If Found Then Writeln('Elevation: ', Sample:0:3, ' m (cellule la plus proche)')
 Else Writeln('Erreur: impossible de lire la cellule du raster.');
End;

Procedure Dispatch(Count : Integer; Var T : TTokenArray);
Var
 Cmd, DistanceText : String;
 Lat1, Lon1, Lat2, Lon2, D, Factor : Real;
 OutputName : String;
Begin
 If Count = 0 Then Exit;
 Cmd := UpperString(T[1]);
 If (Cmd = 'EXIT') Or (Cmd = 'QUIT') Then Halt(0) Else
 If (Cmd = 'HELP') Or (Cmd = '?') Then ShowHelp Else
 If Cmd = 'INFO' Then Begin
  If Count < 2 Then Writeln('Usage: INFO fichier') Else CommandInfo(T[2]);
 End Else
 If Cmd = 'MAP' Then Begin
  If Count < 2 Then Writeln('Usage: MAP fichier.geojson')
  Else Begin
   Writeln('Apercu cartographique indisponible dans le prompt texte.');
   CommandInfo(T[2]);
  End;
 End Else
 If Cmd = 'COORD' Then Begin
  If (Count < 3) Or (Not IsNumber(T[2], Lat1)) Or (Not IsNumber(T[3], Lon1)) Then
   Writeln('Usage: COORD latitude longitude')
  Else If (Lat1 < -90.0) Or (Lat1 > 90.0) Or (Lon1 < -180.0) Or (Lon1 > 180.0) Then
   Writeln('Erreur: latitude/longitude hors limites.')
  Else Writeln('WGS84: latitude ', Lat1:0:6, ', longitude ', Lon1:0:6);
 End Else
 If Cmd = 'DISTANCE' Then Begin
  If Count >= 3 Then Begin
   If CityCoordinates(T[2], Lat1, Lon1) And CityCoordinates(T[3], Lat2, Lon2) Then
    Writeln(DistanceKm(Lat1, Lon1, Lat2, Lon2):0:3, ' km')
   Else If (Count >= 5) And IsNumber(T[2], Lat1) And IsNumber(T[3], Lon1) And
           IsNumber(T[4], Lat2) And IsNumber(T[5], Lon2) Then
    Writeln(DistanceKm(Lat1, Lon1, Lat2, Lon2):0:3, ' km')
   Else Writeln('Villes connues: Montreal, Quebec, Ottawa, Toronto, Paris.')
  End Else Writeln('Usage: DISTANCE ville1 ville2 | DISTANCE lat1 lon1 lat2 lon2');
 End Else
 If Cmd = 'ELEVATION' Then Begin
  If Count < 4 Then Writeln('Usage: ELEVATION terrain.asc latitude longitude')
  Else CommandElevation(T[2], T[3], T[4]);
 End Else
 If Cmd = 'CONVERT' Then Begin
  If Count < 3 Then Writeln('Usage: CONVERT entree.asc sortie.asc')
    Else If (FileExtension(T[3]) <> '.ASC') And
      (FileExtension(T[3]) <> '.TIF') And
      (FileExtension(T[3]) <> '.TIFF') Then
   Writeln('Erreur: sorties prises en charge: .ASC, .TIF, .TIFF (pas PNG).')
  Else RunProcessing('gdal:translate', '--INPUT=' + QuoteArg(T[2]) +
    ' --OUTPUT=' + QuoteArg(T[3]));
 End Else
 If Cmd = 'REPROJECT' Then Begin
  If Count < 3 Then Writeln('Usage: REPROJECT entree.geojson EPSG:code [sortie.geojson]')
  Else Begin
   If Count >= 4 Then OutputName := T[4]
   Else OutputName := DefaultReprojectName(T[2]);
   RunProcessing('native:reprojectlayer', '--INPUT=' + QuoteArg(T[2]) +
    ' --TARGET_CRS=' + QuoteArg(T[3]) + ' --OUTPUT=' + QuoteArg(OutputName));
  End;
 End Else
 If Cmd = 'BUFFER' Then Begin
  If Count < 4 Then Writeln('Usage: BUFFER entree.geojson sortie.geojson distance')
  Else Begin
   DistanceText := T[4];
   Factor := 1.0;
   If Length(DistanceText) > 2 Then Begin
    If UpperString(Copy(DistanceText, Length(DistanceText) - 1, 2)) = 'KM' Then Begin
     Factor := 1000.0;
     Delete(DistanceText, Length(DistanceText) - 1, 2);
    End Else If UpperString(Copy(DistanceText, Length(DistanceText), 1)) = 'M' Then
     Delete(DistanceText, Length(DistanceText), 1);
   End;
   If Not IsNumber(DistanceText, D) Then Writeln('Erreur: distance numerique attendue.')
   Else Begin
    D := D * Factor;
    Str(D:0:3, DistanceText);
    RunProcessing('native:buffer', '--INPUT=' + QuoteArg(T[2]) +
       ' --DISTANCE=' + DistanceText + ' --OUTPUT=' + QuoteArg(T[3]));
   End;
  End;
 End Else
 If Cmd = 'SLOPE' Then Begin
  If Count < 3 Then Writeln('Usage: SLOPE entree.asc sortie.asc')
  Else RunProcessing('gdal:slope', '--INPUT=' + QuoteArg(T[2]) +
       ' --OUTPUT=' + QuoteArg(T[3]));
 End Else
 If Cmd = 'CONTOUR' Then Begin
  If Count < 4 Then Writeln('Usage: CONTOUR entree.asc sortie.geojson intervalle')
  Else RunProcessing('gdal:contour', '--INPUT=' + QuoteArg(T[2]) +
       ' --OUTPUT=' + QuoteArg(T[3]) + ' --INTERVAL=' + T[4]);
 End Else
 If Cmd = 'HILLSHADE' Then Begin
  If Count < 3 Then Writeln('Usage: HILLSHADE entree.asc sortie.asc')
  Else RunProcessing('gdal:hillshade', '--INPUT=' + QuoteArg(T[2]) +
       ' --OUTPUT=' + QuoteArg(T[3]));
 End Else
 If Cmd = 'RASTERIZE' Then Begin
  If Count < 3 Then Writeln('Usage: RASTERIZE entree.geojson sortie.asc')
  Else RunProcessing('gdal:rasterize', '--INPUT=' + QuoteArg(T[2]) +
       ' --OUTPUT=' + QuoteArg(T[3]));
 End Else
 If Cmd = 'VECTORIZE' Then Begin
  If Count < 3 Then Writeln('Usage: VECTORIZE entree.asc sortie.geojson')
  Else RunProcessing('gdal:polygonize', '--INPUT=' + QuoteArg(T[2]) +
       ' --OUTPUT=' + QuoteArg(T[3]));
 End Else
 If Cmd = 'WATERSHED' Then
  Writeln('Erreur: WATERSHED n''est pas implemente par QGIS_PROCESS.EXE.')
 Else Writeln('Commande inconnue: ', T[1], ' (tapez HELP).');
End;

Var
 Line : String;
 Tokens : TTokenArray;
 TokenCount : Integer;

BEGIN
 If (ParamCount > 0) And
   ((ParamStr(1) = '/?') Or (UpperString(ParamStr(1)) = '/H') Or
    (UpperString(ParamStr(1)) = '-H') Or
    (UpperString(ParamStr(1)) = '--HELP')) Then Begin
  ShowHelp;
  Halt(0);
 End;
 Writeln('GEO - interpreteur de commandes geographiques');
 Writeln('Tapez HELP pour la liste des commandes, EXIT pour quitter.');
 Repeat
  Write('GEO> ');
  ReadLn(Line);
  ParseLine(Line, Tokens, TokenCount);
  Dispatch(TokenCount, Tokens);
 Until False;
END.
