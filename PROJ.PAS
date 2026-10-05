{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
  @description: PROJ - projection cartographique directe/inverse
  Projections: UTM, Mercator, Transverse Mercator, LCC, EQC, SINU, CEA.
  Datum: grilles NTv2 .gsb; binaire: paires de doubles IEEE-754 little-endian.
}
Program Proj;

{$IFDEF FPC}
Uses Windows;
{$ELSE}
Uses Dos;
{$ENDIF}

Const
 PI = 3.14159265358979323846;
 DEG = PI / 180.0;
 A_WGS84 = 6378137.0;
 F_WGS84 = 1.0 / 298.257223563;

Type
 TProjection = (prjUnknown, prjLongLat, prjUTM, prjMerc, prjTMerc, prjLCC,
                prjEQC, prjSinu, prjCEA);
 TParams = Record
  Projection : TProjection;
  A, B, E2, F : Real;
  Zone : Integer;
  South, Over, HasLat1, HasLat2 : Boolean;
  Lat0, Lon0, Lat1, Lat2, LatTS, K0, X0, Y0, PM, UnitFactor, LonWrap : Real;
  Axis : String[3];
 End;
 TNTRecord = Packed Record
  Key : Array[1..8] Of Char;
  Value : Array[1..8] Of Char;
 End;
 TNTNode = Packed Record
  LatShift, LonShift, LatAccuracy, LonAccuracy : Single;
 End;

Var
 P : TParams;
Inverse, SwapIn, SwapOut, EchoInput, Verbose, Detailed, ShowFactors : Boolean;
BinaryInput, BinaryOutput : Boolean;
 Decimals, DMSPrecision : Integer;
 FixedDMS : Boolean;
 FormatString, ErrorText, CommentChar : String;
Multiplier : Real;
 GridFileName : String[127];
 HasGrid, GridBigEndian : Boolean;

Function SwapLong(V : LongInt) : LongInt;
Var B : Array[1..4] Of Byte; T : Byte;
Begin
 Move(V, B, 4);
 T := B[1]; B[1] := B[4]; B[4] := T;
 T := B[2]; B[2] := B[3]; B[3] := T;
 Move(B, V, 4); SwapLong := V;
End;

Function SwapSingle(V : Single) : Single;
Var B : Array[1..4] Of Byte; T : Byte;
Begin
 Move(V, B, 4);
 T := B[1]; B[1] := B[4]; B[4] := T;
 T := B[2]; B[2] := B[3]; B[3] := T;
 Move(B, V, 4); SwapSingle := V;
End;

Function SwapDouble(V : Double) : Double;
Var B : Array[1..8] Of Byte; I : Integer; T : Byte;
Begin
 Move(V, B, 8);
 For I := 1 To 4 Do Begin T := B[I]; B[I] := B[9-I]; B[9-I] := T; End;
 Move(B, V, 8); SwapDouble := V;
End;

Function GridReadRecord(Var F : File; Var R : TNTRecord) : Boolean;
Var N : Word;
Begin
 BlockRead(F, R, SizeOf(R), N);
 GridReadRecord := N = SizeOf(R);
End;

Function GridKey(R : TNTRecord) : String;
Var I : Integer; S : String;
Begin
 S := '';
 For I := 1 To 8 Do If R.Key[I] <> #0 Then S := S + R.Key[I];
 While (S <> '') And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
 GridKey := S;
End;

Function GridInt(R : TNTRecord) : LongInt;
Var V : LongInt;
Begin
 Move(R.Value[1], V, 4);
 If GridBigEndian Then V := SwapLong(V);
 GridInt := V;
End;

Function GridDouble(R : TNTRecord) : Real;
Var V : Double;
Begin
 Move(R.Value[1], V, 8);
 If GridBigEndian Then V := SwapDouble(V);
 GridDouble := V;
End;

Function GridFloat(V : Single) : Real;
Begin
 If GridBigEndian Then V := SwapSingle(V);
 GridFloat := V;
End;

Function ReadGridShift(Longitude, Latitude : Real;
                Var ShiftLon, ShiftLat : Real) : Boolean;
Var
 F : File;
 R : TNTRecord;
 N00, N10, N01, N11 : TNTNode;
 I, OverviewCount, SubHeaderCount, GridCount : LongInt;
 BestData, CurrentData, SkipBytes : LongInt;
 SouthLat, NorthLat, EastLong, WestLong, LatInc, LonInc : Real;
 BestSouth, BestEast, BestLatInc, BestLonInc : Real;
 BestCols, BestRows : LongInt;
 Key : String;
 V, ColF, RowF, DX, DY : Real;
 C0, R0 : LongInt;
 N : Word;
 HeaderOK, HaveSouth, HaveNorth, HaveEast, HaveWest, HaveLatInc, HaveLonInc : Boolean;
Begin
 ReadGridShift := False;
 BestLatInc := 1.0E30; BestData := -1;
 Assign(F, GridFileName);
 {$I-}
 Reset(F, 1);
 I := IOResult;
 {$I+}
 If I <> 0 Then Exit;
 GridBigEndian := False;
 If Not GridReadRecord(F, R) Then Begin Close(F); Exit; End;
 If GridKey(R) <> 'NUM_OREC' Then Begin Close(F); Exit; End;
 OverviewCount := GridInt(R);
 If OverviewCount <> 11 Then Begin
  If SwapLong(OverviewCount) = 11 Then Begin
   GridBigEndian := True;
   OverviewCount := 11;
  End;
 End;
 If GridBigEndian Then Begin
  { R has to be byte-swapped only for its numeric value. }
 End;
 If OverviewCount <> 11 Then Begin Close(F); Exit; End;
 For I := 2 To OverviewCount Do If Not GridReadRecord(F, R) Then Begin Close(F); Exit; End;
 If GridKey(R) = '' Then Begin Close(F); Exit; End;
 { Rewind and skip the overview so each subgrid header can be scanned. }
 Seek(F, OverviewCount * SizeOf(TNTRecord));
 SubHeaderCount := 11;
 For I := 2 To 11 Do Begin
  If Not GridReadRecord(F, R) Then Begin Close(F); Exit; End;
  If GridKey(R) = 'NUM_SREC' Then SubHeaderCount := GridInt(R);
 End;
 Seek(F, OverviewCount * SizeOf(TNTRecord));
 While Not EOF(F) Do Begin
  SouthLat := 0; NorthLat := 0; EastLong := 0; WestLong := 0;
  LatInc := 0; LonInc := 0; GridCount := 0;
  HaveSouth := False; HaveNorth := False; HaveEast := False; HaveWest := False;
  HaveLatInc := False; HaveLonInc := False;
  HeaderOK := True;
  For I := 1 To SubHeaderCount Do Begin
   If Not GridReadRecord(F, R) Then Begin HeaderOK := False; Break; End;
  Key := GridKey(R);
  If Key = 'S_LAT' Then Begin SouthLat := GridDouble(R); HaveSouth := True; End Else
  If Key = 'N_LAT' Then Begin NorthLat := GridDouble(R); HaveNorth := True; End Else
  If Key = 'E_LONG' Then Begin EastLong := GridDouble(R); HaveEast := True; End Else
  If Key = 'W_LONG' Then Begin WestLong := GridDouble(R); HaveWest := True; End Else
  If Key = 'LAT_INC' Then Begin LatInc := GridDouble(R); HaveLatInc := True; End Else
  If Key = 'LONG_INC' Then Begin LonInc := GridDouble(R); HaveLonInc := True; End Else
  If Key = 'GS_COUNT' Then GridCount := GridInt(R);
  End;
  If Not HeaderOK Then Break;
  CurrentData := FilePos(F);
  If HaveSouth And HaveNorth And HaveEast And HaveWest And HaveLatInc And
    HaveLonInc And (GridCount > 0) And (LatInc > 0.0) And (LonInc > 0.0) Then Begin
    V := Latitude * 3600.0;
    DX := Longitude * 3600.0;
    If (V >= SouthLat) And (V <= NorthLat) And
      (DX >= -WestLong) And (DX <= -EastLong) Then
   If LatInc < BestLatInc Then Begin
    BestLatInc := LatInc; BestLonInc := LonInc;
      BestSouth := SouthLat; BestEast := -EastLong;
    BestCols := Trunc((WestLong - EastLong) / LonInc + 0.5) + 1;
    BestRows := Trunc((NorthLat - SouthLat) / LatInc + 0.5) + 1;
    BestData := CurrentData;
   End;
  End;
  SkipBytes := GridCount * SizeOf(TNTNode);
  Seek(F, CurrentData + SkipBytes);
 End;
 If BestData < 0 Then Begin Close(F); Exit; End;
 ColF := (BestEast - Longitude * 3600.0) / BestLonInc;
 RowF := (Latitude * 3600.0 - BestSouth) / BestLatInc;
 C0 := Trunc(ColF); R0 := Trunc(RowF);
 If C0 >= BestCols - 1 Then Begin C0 := BestCols - 2; ColF := BestCols - 1; End;
 If R0 >= BestRows - 1 Then Begin R0 := BestRows - 2; RowF := BestRows - 1; End;
 If (C0 < 0) Or (R0 < 0) Or (BestCols < 2) Or (BestRows < 2) Then Begin Close(F); Exit; End;
 DX := ColF - C0; DY := RowF - R0;
 Seek(F, BestData + (R0 * BestCols + C0) * SizeOf(TNTNode));
 BlockRead(F, N00, SizeOf(N00), N);
 Seek(F, BestData + (R0 * BestCols + C0 + 1) * SizeOf(TNTNode));
 BlockRead(F, N10, SizeOf(N10), N);
 Seek(F, BestData + ((R0 + 1) * BestCols + C0) * SizeOf(TNTNode));
 BlockRead(F, N01, SizeOf(N01), N);
 Seek(F, BestData + ((R0 + 1) * BestCols + C0 + 1) * SizeOf(TNTNode));
 BlockRead(F, N11, SizeOf(N11), N);
 Close(F);
 V := GridFloat(N00.LonShift) * (1.0 - DX) * (1.0 - DY)
   + GridFloat(N10.LonShift) * DX * (1.0 - DY)
   + GridFloat(N01.LonShift) * (1.0 - DX) * DY
   + GridFloat(N11.LonShift) * DX * DY;
 ShiftLon := V / 3600.0;
 V := GridFloat(N00.LatShift) * (1.0 - DX) * (1.0 - DY)
   + GridFloat(N10.LatShift) * DX * (1.0 - DY)
   + GridFloat(N01.LatShift) * (1.0 - DX) * DY
   + GridFloat(N11.LatShift) * DX * DY;
 ShiftLat := V / 3600.0;
 ReadGridShift := True;
End;

Function ReadBinaryBytes(Var Buffer; Count : Word; Var Actual : Word) : Boolean;
{$IFDEF FPC}
Var BytesRead : DWORD; Handle : THandle;
{$ELSE}
Var R : Registers;
{$ENDIF}
Begin
 Actual := 0;
 {$IFDEF FPC}
 Handle := GetStdHandle(STD_INPUT_HANDLE);
 BytesRead := 0;
 If ReadFile(Handle, Buffer, Count, BytesRead, Nil) Then Actual := BytesRead;
 {$ELSE}
 R.AH := $3F; R.BX := 0; R.CX := Count;
 R.DS := Seg(Buffer); R.DX := Ofs(Buffer);
 Intr($21, R);
 If R.Flags And 1 = 0 Then Actual := R.AX;
 {$ENDIF}
 ReadBinaryBytes := Actual = Count;
End;

Function WriteBinaryBytes(Var Buffer; Count : Word) : Boolean;
{$IFDEF FPC}
Var BytesWritten : DWORD; Handle : THandle;
{$ELSE}
Var R : Registers;
{$ENDIF}
Begin
 {$IFDEF FPC}
 Handle := GetStdHandle(STD_OUTPUT_HANDLE);
 BytesWritten := 0;
 WriteBinaryBytes := WriteFile(Handle, Buffer, Count, BytesWritten, Nil) And
                     (BytesWritten = Count);
 {$ELSE}
 R.AH := $40; R.BX := 1; R.CX := Count;
 R.DS := Seg(Buffer); R.DX := Ofs(Buffer);
 Intr($21, R);
 WriteBinaryBytes := (R.Flags And 1 = 0) And (R.AX = Count);
 {$ENDIF}
End;

Procedure WriteBinaryCoordinate(X, Y : Real);
Var DX, DY : Double;
Begin
 DX := X; DY := Y;
 WriteBinaryBytes(DX, SizeOf(DX));
 WriteBinaryBytes(DY, SizeOf(DY));
End;

Function UpperString(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do S[I] := UpCase(S[I]);
 UpperString := S;
End;

Function DegToRad(X : Real) : Real; Begin DegToRad := X * DEG; End;
Function RadToDeg(X : Real) : Real; Begin RadToDeg := X / DEG; End;
Function Tan(X : Real) : Real; Begin Tan := Sin(X) / Cos(X); End;

Function PowReal(Base, Exponent : Real) : Real;
Begin
 If Base > 0.0 Then PowReal := Exp(Exponent * Ln(Base))
 Else If (Base = 0.0) And (Exponent > 0.0) Then PowReal := 0.0
 Else PowReal := 0.0;
End;

Function LowerString(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do S[I] := Chr(Ord(UpCase(S[I])) + 32);
 LowerString := S;
End;

Function ArcTan2(Y, X : Real) : Real;
Var A : Real;
Begin
 If X > 0.0 Then A := ArcTan(Y / X)
 Else If X < 0.0 Then Begin
  A := ArcTan(Y / X);
  If Y >= 0.0 Then A := A + PI Else A := A - PI;
 End Else If Y > 0.0 Then A := PI / 2.0
 Else If Y < 0.0 Then A := -PI / 2.0 Else A := 0.0;
 ArcTan2 := A;
End;

Function ParseReal(S : String; Var V : Real) : Boolean;
Var Err : Integer;
Begin Val(S, V, Err); ParseReal := Err = 0; End;

Function ParamValue(S, Key : String) : String;
Begin
 If Copy(S, 1, Length(Key)) = Key Then
  ParamValue := Copy(S, Length(Key) + 1, Length(S) - Length(Key))
 Else ParamValue := '';
End;

Procedure InitParams;
Begin
 P.Projection := prjUnknown;
 P.A := A_WGS84; P.F := F_WGS84;
 P.B := P.A * (1.0 - P.F); P.E2 := P.F * (2.0 - P.F);
 P.Zone := 0; P.South := False; P.Over := False;
 P.HasLat1 := False; P.HasLat2 := False;
 P.Lat0 := 0.0; P.Lon0 := 0.0; P.Lat1 := 0.0; P.Lat2 := 0.0; P.LatTS := 0.0;
 P.K0 := 1.0; P.X0 := 0.0; P.Y0 := 0.0; P.PM := 0.0;
 P.UnitFactor := 1.0; P.LonWrap := 0.0; P.Axis := 'enu';
 GridFileName := ''; HasGrid := False; GridBigEndian := False;
End;

Function ApplyDatumGrid(Var Longitude, Latitude : Real;
                        Reverse : Boolean) : Boolean;
Var ShiftLon, ShiftLat, SourceLon, SourceLat, NewLon, NewLat : Real;
 I : Integer; OK : Boolean;
Begin
 If Not HasGrid Then Begin ApplyDatumGrid := True; Exit; End;
 If Not Reverse Then Begin
  OK := ReadGridShift(Longitude, Latitude, ShiftLon, ShiftLat);
  If OK Then Begin Longitude := Longitude - ShiftLon; Latitude := Latitude + ShiftLat; End;
 End Else Begin
  SourceLon := Longitude; SourceLat := Latitude; OK := True;
  For I := 1 To 6 Do Begin
   If Not ReadGridShift(SourceLon, SourceLat, ShiftLon, ShiftLat) Then Begin OK := False; Break; End;
  NewLon := Longitude + ShiftLon; NewLat := Latitude - ShiftLat;
   SourceLon := NewLon; SourceLat := NewLat;
  End;
  If OK Then Begin Longitude := SourceLon; Latitude := SourceLat; End;
 End;
 ApplyDatumGrid := OK;
End;

Procedure SetEllipsoid(Name : String);
Var S : String;
Begin
 S := UpperString(Name);
 If S = 'WGS84' Then Begin P.A := 6378137.0; P.F := 1.0 / 298.257223563; End Else
 If (S = 'GRS80') Or (S = 'NAD83') Then Begin P.A := 6378137.0; P.F := 1.0 / 298.257222101; End Else
 If (S = 'CLRK66') Or (S = 'CLARKE1866') Then Begin P.A := 6378206.4; P.F := 1.0 / 294.978698214; End Else
 If (S = 'INTL') Or (S = 'INTERNATIONAL') Then Begin P.A := 6378388.0; P.F := 1.0 / 297.0; End Else
 If S = 'GRS67' Then Begin P.A := 6378160.0; P.F := 1.0 / 298.247167427; End;
 P.B := P.A * (1.0 - P.F);
 P.E2 := P.F * (2.0 - P.F);
End;

Procedure SetUnit(Name : String);
Var S : String;
Begin
 S := UpperString(Name);
 If (S = 'M') Or (S = 'METRE') Or (S = 'METER') Then P.UnitFactor := 1.0 Else
 If (S = 'KM') Then P.UnitFactor := 1000.0 Else
 If (S = 'FT') Or (S = 'FOOT') Then P.UnitFactor := 0.3048 Else
 If (S = 'US-FT') Or (S = 'USFT') Then P.UnitFactor := 1200.0 / 3937.0 Else
 If (S = 'MI') Or (S = 'MILE') Then P.UnitFactor := 1609.344;
End;

Procedure ParseProjectionParams(StartIndex : Integer);
Var I, Err : Integer; S, V : String; R : Real;
Begin
 For I := StartIndex To ParamCount Do Begin
  S := ParamStr(I);
  V := ParamValue(S, '+proj=');
  If V <> '' Then Begin
   V := UpperString(V);
  If V = 'LONGLAT' Then P.Projection := prjLongLat Else
   If V = 'UTM' Then P.Projection := prjUTM Else
   If V = 'MERC' Then P.Projection := prjMerc Else
   If V = 'TMERC' Then P.Projection := prjTMerc Else
  If V = 'LCC' Then P.Projection := prjLCC Else
  If (V = 'EQC') Or (V = 'EQUIRECTANGULAR') Then P.Projection := prjEQC Else
  If (V = 'SINU') Or (V = 'SINUSOIDAL') Then P.Projection := prjSinu Else
  If (V = 'CEA') Or (V = 'CYLINDRICAL_EQUAL_AREA') Then P.Projection := prjCEA;
  End;
  V := ParamValue(S, '+zone=');
  If V <> '' Then Begin
   Val(V, P.Zone, Err);
   If Err <> 0 Then P.Zone := 0;
  End;
  If S = '+south' Then P.South := True;
  If S = '+over' Then P.Over := True;
  V := ParamValue(S, '+ellps='); If V <> '' Then SetEllipsoid(V);
  V := ParamValue(S, '+nadgrids=');
  If V = '' Then V := ParamValue(S, '+grids=');
  If V <> '' Then Begin
   If V[1] = '@' Then Delete(V, 1, 1);
   If UpperString(V) <> 'NULL' Then Begin GridFileName := V; HasGrid := True; End;
  End;
  V := ParamValue(S, '+datum=');
  If V = 'WGS84' Then SetEllipsoid('WGS84') Else If V = 'NAD83' Then SetEllipsoid('GRS80');
  V := ParamValue(S, '+a='); If (V <> '') And ParseReal(V, R) Then P.A := R;
  V := ParamValue(S, '+b='); If (V <> '') And ParseReal(V, R) Then P.B := R;
  V := ParamValue(S, '+f='); If (V <> '') And ParseReal(V, R) Then P.F := R;
  V := ParamValue(S, '+rf='); If (V <> '') And ParseReal(V, R) And (R <> 0.0) Then P.F := 1.0 / R;
  V := ParamValue(S, '+lat_0='); If (V <> '') And ParseReal(V, R) Then P.Lat0 := R;
  V := ParamValue(S, '+lon_0='); If (V <> '') And ParseReal(V, R) Then P.Lon0 := R;
  V := ParamValue(S, '+lat_1='); If (V <> '') And ParseReal(V, R) Then Begin P.Lat1 := R; P.HasLat1 := True; End;
  V := ParamValue(S, '+lat_2='); If (V <> '') And ParseReal(V, R) Then Begin P.Lat2 := R; P.HasLat2 := True; End;
  V := ParamValue(S, '+lat_ts='); If (V <> '') And ParseReal(V, R) Then P.LatTS := R;
  V := ParamValue(S, '+k_0=');
  If (V <> '') And ParseReal(V, R) Then P.K0 := R
  Else Begin
   V := ParamValue(S, '+k=');
   If (V <> '') And ParseReal(V, R) Then P.K0 := R;
  End;
  V := ParamValue(S, '+x_0='); If (V <> '') And ParseReal(V, R) Then P.X0 := R;
  V := ParamValue(S, '+y_0='); If (V <> '') And ParseReal(V, R) Then P.Y0 := R;
  V := ParamValue(S, '+pm=');
  If (V <> '') And ParseReal(V, R) Then P.PM := R
  Else If UpperString(V) = 'PARIS' Then P.PM := 2.33722917;
  V := ParamValue(S, '+units='); If V <> '' Then SetUnit(V);
  V := ParamValue(S, '+lon_wrap='); If (V <> '') And ParseReal(V, R) Then P.LonWrap := R;
  V := ParamValue(S, '+axis='); If V <> '' Then P.Axis := LowerString(V);
 End;
 If P.Projection = prjUTM Then Begin
  If (P.Zone < 1) Or (P.Zone > 60) Then P.Projection := prjUnknown
  Else Begin P.Lon0 := (P.Zone - 1) * 6 - 180 + 3; P.K0 := 0.9996; P.X0 := 500000.0; If P.South Then P.Y0 := 10000000.0; End;
 End;
 If P.B > 0.0 Then P.F := (P.A - P.B) / P.A;
 P.E2 := P.F * (2.0 - P.F);
End;

Procedure ShowHelp;
Begin
 Writeln('PROJ - Cette commande permet d''effectuer une projection cartographique directe/inverse autonome.');
 Writeln;
 Writeln('Syntaxe: PROJ [options] +proj=utm|merc|tmerc|lcc|eqc|sinu|cea [parametres]');
 WriteLn;
 Writeln('Entree standard: longitude latitude; inverse: X Y.');
 Writeln('Options: -I -d<n> -e<texte> -E -f<format> -r -s -S -m<facteur>');
 Writeln('         -t<char> -v -V -w<n> -W<n> -l -l=<id> -lp -lP -le -lu');
 Writeln('         -b: paires IEEE-754 little-endian (2 doubles X/Y par point).');
 Writeln('         -i entree binaire seule; -o sortie binaire seule.');
 Writeln('Parametres acceptes: +ellps +datum +a +b +f +rf +zone +south,');
 Writeln(' +lat_0 +lon_0 +lat_1 +lat_2 +x_0 +y_0 +k_0 +k, +units,');
 Writeln(' +axis +pm +lon_wrap +over +nadgrids=<NTv2 .gsb>.');
 Writeln;
 Writeln('Projections ellipsoidales: UTM, Mercator, Transverse Mercator, LCC.');
 Writeln('Projections supplementaires (spheriques, rayon +a): eqc, sinu, cea.');
 Writeln('Grilles datum NTv2 .gsb via +nadgrids=<fichier>; une grille par commande.');
 Writeln('Les flux binaires -b/-i/-o sont des paires de doubles little-endian.');
 Writeln('GeoTIFF grids, CTable2 et les projections non listees ne sont pas integres.');
End;

Procedure ShowList(Kind : String);
Var S : String;
Begin
 If (Kind = '-l') Or (Kind = '-lp') Then Begin
  Writeln('merc  Mercator'); Writeln('tmerc Transverse Mercator');
  Writeln('utm   Universal Transverse Mercator'); Writeln('lcc   Lambert Conformal Conic');
  Writeln('eqc   Equirectangular (spherique)');
  Writeln('sinu  Sinusoidale (spherique)');
  Writeln('cea   Cylindrique equivalente (spherique)');
 End Else If Kind = '-le' Then Begin
  Writeln('WGS84  a=6378137 rf=298.257223563');
  Writeln('GRS80  a=6378137 rf=298.257222101');
  Writeln('clrk66 a=6378206.4 rf=294.978698214');
  Writeln('intl   a=6378388 rf=297');
 End Else If Kind = '-lu' Then Begin
  Writeln('m metre; km kilometre; ft foot; us-ft US survey foot; mi mile');
 End Else If Kind = '-lP' Then Begin
  Writeln('+proj=merc: Mercator ellipsoidale, +lon_0 +lat_ts ou +k_0.');
  Writeln('+proj=tmerc: Transverse Mercator ellipsoidale, +lat_0 +lon_0 +k_0.');
  Writeln('+proj=utm: UTM WGS84/ellipsoide choisi, +zone et +south.');
  Writeln('+proj=lcc: Lambert conique conforme, +lat_1 +lat_2 +lat_0 +lon_0.');
  Writeln('+proj=eqc: equirectangulaire spherique, +lat_ts +lat_0 +lon_0.');
  Writeln('+proj=sinu: sinusoidale spherique, +lat_0 +lon_0.');
  Writeln('+proj=cea: cylindrique equivalente spherique, +lat_ts +lon_0.');
 End Else If Copy(Kind, 1, 3) = '-l=' Then Begin
  S := Copy(Kind, 4, Length(Kind) - 3);
    If (S = 'utm') Or (S = 'merc') Or (S = 'tmerc') Or (S = 'lcc') Or
      (S = 'eqc') Or (S = 'sinu') Or (S = 'cea') Then Begin
   Writeln('+proj=', S, ': projection cartographique ellipsoidale WGS84.');
   Writeln('Parametres et conventions: voir PROJ /? et +proj parameters.');
  End Else Writeln('Projection inconnue: ', S);
 End;
 Halt(0);
End;

Procedure NormalizeLongitude(Var L : Real);
Begin
 If P.Over Then Exit;
 While L > 180.0 Do L := L - 360.0;
 While L < -180.0 Do L := L + 360.0;
End;

Function MeridionalArc(Lat : Real) : Real;
Var E2, E4, E6 : Real;
Begin
 E2 := P.E2; E4 := E2 * E2; E6 := E4 * E2;
 MeridionalArc := P.A * ((1.0 - E2 / 4.0 - 3.0 * E4 / 64.0 - 5.0 * E6 / 256.0) * Lat
  - (3.0 * E2 / 8.0 + 3.0 * E4 / 32.0 + 45.0 * E6 / 1024.0) * Sin(2.0 * Lat)
  + (15.0 * E4 / 256.0 + 45.0 * E6 / 1024.0) * Sin(4.0 * Lat)
  - (35.0 * E6 / 3072.0) * Sin(6.0 * Lat));
End;

Procedure TMForward(LatDeg, LonDeg : Real; Var X, Y : Real);
Var Lat, Lon, L0, E2, EP2, N, T, C, A1, M, M0 : Real;
Begin
 E2 := P.E2; EP2 := E2 / (1.0 - E2);
 Lat := DegToRad(LatDeg); Lon := DegToRad(LonDeg + P.PM); L0 := DegToRad(P.Lon0);
 A1 := Cos(Lat) * (Lon - L0);
 N := P.A / Sqrt(1.0 - E2 * Sqr(Sin(Lat)));
 T := Sqr(Tan(Lat)); C := EP2 * Sqr(Cos(Lat));
 M := MeridionalArc(Lat); M0 := MeridionalArc(DegToRad(P.Lat0));
 X := P.X0 + P.K0 * N * (A1 + (1.0 - T + C) * A1 * A1 * A1 / 6.0
  + (5.0 - 18.0 * T + T * T + 72.0 * C - 58.0 * EP2) * A1 * A1 * A1 * A1 * A1 / 120.0
  + (61.0 - 479.0 * T + 179.0 * T * T - T * T * T) * A1 * A1 * A1 * A1 * A1 * A1 * A1 / 5040.0);
 Y := P.Y0 + P.K0 * (M - M0 + N * Tan(Lat) * (A1 * A1 / 2.0
  + (5.0 - T + 9.0 * C + 4.0 * C * C) * A1 * A1 * A1 * A1 / 24.0
  + (61.0 - 58.0 * T + T * T + 600.0 * C - 330.0 * EP2) * A1 * A1 * A1 * A1 * A1 * A1 / 720.0));
 X := X / P.UnitFactor;
 Y := Y / P.UnitFactor;
End;

Procedure TMInverse(X, Y : Real; Var LatDeg, LonDeg : Real);
Var E2, EP2, E1, M, Mu, Phi, N1, T1, C1, R1, D, L0, Fp : Real;
 I : Integer;
Begin
 E2 := P.E2; EP2 := E2 / (1.0 - E2); E1 := (1.0 - Sqrt(1.0 - E2)) / (1.0 + Sqrt(1.0 - E2));
 X := (X * P.UnitFactor - P.X0); Y := (Y * P.UnitFactor - P.Y0);
 M := MeridionalArc(DegToRad(P.Lat0)) + Y / P.K0;
 Mu := M / (P.A * (1.0 - E2 / 4.0 - 3.0 * Sqr(E2) / 64.0 - 5.0 * E2 * E2 * E2 / 256.0));
 Phi := Mu + (3.0 * E1 / 2.0 - 27.0 * E1 * E1 * E1 / 32.0) * Sin(2.0 * Mu)
  + (21.0 * E1 * E1 / 16.0 - 55.0 * E1 * E1 * E1 * E1 / 32.0) * Sin(4.0 * Mu)
  + (151.0 * E1 * E1 * E1 / 96.0) * Sin(6.0 * Mu)
  + (1097.0 * E1 * E1 * E1 * E1 / 512.0) * Sin(8.0 * Mu);
 For I := 1 To 3 Do Begin
  Fp := (MeridionalArc(Phi) - M) / (P.A * (1.0 - E2) / PowReal(1.0 - E2 * Sqr(Sin(Phi)), 1.5));
  Phi := Phi - Fp;
 End;
 N1 := P.A / Sqrt(1.0 - E2 * Sqr(Sin(Phi)));
 T1 := Sqr(Tan(Phi)); C1 := EP2 * Sqr(Cos(Phi));
 R1 := P.A * (1.0 - E2) / PowReal(1.0 - E2 * Sqr(Sin(Phi)), 1.5);
 D := X / (N1 * P.K0); L0 := DegToRad(P.Lon0);
 LatDeg := RadToDeg(Phi - (N1 * Tan(Phi) / R1) * (D * D / 2.0
  - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * C1 * C1 - 9.0 * EP2) * PowReal(D, 4) / 24.0
  + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * T1 * T1 - 252.0 * EP2 - 3.0 * C1 * C1) * PowReal(D, 6) / 720.0));
 LonDeg := RadToDeg(L0 + (D - (1.0 + 2.0 * T1 + C1) * PowReal(D, 3) / 6.0
  + (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * C1 * C1 + 8.0 * EP2 + 24.0 * T1 * T1) * PowReal(D, 5) / 120.0) / Cos(Phi)) - P.PM;
End;

Function MercT(Phi : Real) : Real;
Begin
 MercT := Tan(PI / 4.0 + Phi / 2.0) * PowReal((1.0 - Sqrt(P.E2) * Sin(Phi)) /
  (1.0 + Sqrt(P.E2) * Sin(Phi)), Sqrt(P.E2) / 2.0);
End;

Procedure ProjectForward(Lat, Lon : Real; Var X, Y : Real);
Var Phi, Lam, E, K, T, M1, M2, N, F, Rho, Rho0, Theta, Ts : Real;
Begin
 If P.Projection = prjLongLat Then Begin X := Lon + P.PM; Y := Lat; Exit; End;
 If P.Projection = prjTMerc Then Begin TMForward(Lat, Lon, X, Y); Exit; End;
 Phi := DegToRad(Lat); Lam := DegToRad(Lon + P.PM - P.Lon0); E := Sqrt(P.E2);
 If P.Projection = prjUTM Then Begin TMForward(Lat, Lon, X, Y); Exit; End;
 If P.Projection = prjMerc Then Begin
  If Abs(Lat) >= 89.999999 Then Begin X := 0.0; Y := 0.0; Exit; End;
  K := P.K0;
  If P.Lat1 <> 0.0 Then K := Cos(DegToRad(P.Lat1)) / Sqrt(1.0 - P.E2 * Sqr(Sin(DegToRad(P.Lat1))));
  X := (P.X0 + P.A * K * Lam) / P.UnitFactor;
  Y := (P.Y0 + P.A * K * Ln(Tan(PI / 4.0 + Phi / 2.0) * PowReal((1.0 - E * Sin(Phi)) / (1.0 + E * Sin(Phi)), E / 2.0))) / P.UnitFactor;
  Exit;
 End;
 If P.Projection = prjEQC Then Begin
  K := Cos(DegToRad(P.LatTS));
  X := (P.X0 + P.A * P.K0 * K * Lam) / P.UnitFactor;
  Y := (P.Y0 + P.A * P.K0 * (Phi - DegToRad(P.Lat0))) / P.UnitFactor;
  Exit;
 End;
 If P.Projection = prjSinu Then Begin
  X := (P.X0 + P.A * P.K0 * Lam * Cos(Phi)) / P.UnitFactor;
  Y := (P.Y0 + P.A * P.K0 * (Phi - DegToRad(P.Lat0))) / P.UnitFactor;
  Exit;
 End;
 If P.Projection = prjCEA Then Begin
  K := Cos(DegToRad(P.LatTS));
  If Abs(K) < 0.000000001 Then Begin X := 0.0; Y := 0.0; Exit; End;
  X := (P.X0 + P.A * P.K0 * K * Lam) / P.UnitFactor;
  Y := (P.Y0 + P.A * P.K0 * Sin(Phi) / K) / P.UnitFactor;
  Exit;
 End;
 If P.Projection = prjLCC Then Begin
  If Not P.HasLat1 Then P.Lat1 := P.Lat0;
  If Not P.HasLat2 Then P.Lat2 := P.Lat1;
  M1 := Cos(DegToRad(P.Lat1)) / Sqrt(1.0 - P.E2 * Sqr(Sin(DegToRad(P.Lat1))));
  T := Tan(PI / 4.0 - DegToRad(P.Lat1) / 2.0) /
      PowReal((1.0 - E * Sin(DegToRad(P.Lat1))) / (1.0 + E * Sin(DegToRad(P.Lat1))), E / 2.0);
  If Abs(P.Lat1 - P.Lat2) < 0.0000001 Then N := Sin(DegToRad(P.Lat1)) Else Begin
   M2 := Cos(DegToRad(P.Lat2)) / Sqrt(1.0 - P.E2 * Sqr(Sin(DegToRad(P.Lat2))));
   Ts := Tan(PI / 4.0 - DegToRad(P.Lat2) / 2.0) /
        PowReal((1.0 - E * Sin(DegToRad(P.Lat2))) / (1.0 + E * Sin(DegToRad(P.Lat2))), E / 2.0);
   N := Ln(M1 / M2) / Ln(T / Ts);
  End;
  F := M1 / (N * PowReal(T, N));
  T := Tan(PI / 4.0 - Phi / 2.0) / PowReal((1.0 - E * Sin(Phi)) / (1.0 + E * Sin(Phi)), E / 2.0);
  Rho := P.A * F * PowReal(T, N);
  Ts := Tan(PI / 4.0 - DegToRad(P.Lat0) / 2.0) /
          PowReal((1.0 - E * Sin(DegToRad(P.Lat0))) / (1.0 + E * Sin(DegToRad(P.Lat0))), E / 2.0);
        Rho0 := P.A * F * PowReal(Ts, N); Theta := N * Lam;
  X := (P.X0 + Rho * Sin(Theta)) / P.UnitFactor;
  Y := (P.Y0 + Rho0 - Rho * Cos(Theta)) / P.UnitFactor;
 End;
End;

Procedure ProjectInverse(X, Y : Real; Var Lat, Lon : Real);
Var E, T, Phi, XMet, YMet, M1, M2, T1, T2, NN, FF, Rho, Rho0, Theta, K : Real;
 I : Integer;
Begin
 If P.Projection = prjLongLat Then Begin Lon := X - P.PM; Lat := Y; Exit; End;
 If (P.Projection = prjUTM) Or (P.Projection = prjTMerc) Then Begin TMInverse(X, Y, Lat, Lon); Exit; End;
 XMet := X * P.UnitFactor - P.X0; YMet := Y * P.UnitFactor - P.Y0; E := Sqrt(P.E2);
 If P.Projection = prjMerc Then Begin
  K := P.K0;
  If P.Lat1 <> 0.0 Then K := Cos(DegToRad(P.Lat1)) / Sqrt(1.0 - P.E2 * Sqr(Sin(DegToRad(P.Lat1))));
  Lon := P.Lon0 + RadToDeg(XMet / (P.A * K)) - P.PM;
  T := Exp(-YMet / (P.A * K));
  Phi := PI / 2.0 - 2.0 * ArcTan(T);
  For I := 1 To 10 Do
  Phi := PI / 2.0 - 2.0 * ArcTan(T * PowReal((1.0 - E * Sin(Phi)) / (1.0 + E * Sin(Phi)), E / 2.0));
  Lat := RadToDeg(Phi); Exit;
 End;
 If P.Projection = prjEQC Then Begin
  K := Cos(DegToRad(P.LatTS));
  If Abs(K) < 0.000000001 Then Begin Lat := 0.0; Lon := 0.0; Exit; End;
  Lon := P.Lon0 + RadToDeg(XMet / (P.A * P.K0 * K)) - P.PM;
  Lat := P.Lat0 + RadToDeg(YMet / (P.A * P.K0));
  Exit;
 End;
 If P.Projection = prjSinu Then Begin
  Phi := DegToRad(P.Lat0) + YMet / (P.A * P.K0);
  If Abs(Cos(Phi)) < 0.000000001 Then Begin Lat := RadToDeg(Phi); Lon := P.Lon0; Exit; End;
  Lon := P.Lon0 + RadToDeg(XMet / (P.A * P.K0 * Cos(Phi))) - P.PM;
  Lat := RadToDeg(Phi);
  Exit;
 End;
 If P.Projection = prjCEA Then Begin
  K := Cos(DegToRad(P.LatTS));
  If Abs(YMet * K / (P.A * P.K0)) > 1.0 Then Begin Lat := 0.0; Lon := 0.0; Exit; End;
  Lon := P.Lon0 + RadToDeg(XMet / (P.A * P.K0 * K)) - P.PM;
  Lat := RadToDeg(ArcTan2(YMet * K,
            Sqrt(Sqr(P.A * P.K0) - Sqr(YMet * K))));
  Exit;
 End;
 If P.Projection = prjLCC Then Begin
  If Not P.HasLat1 Then P.Lat1 := P.Lat0;
  If Not P.HasLat2 Then P.Lat2 := P.Lat1;
  M1 := Cos(DegToRad(P.Lat1)) / Sqrt(1.0 - P.E2 * Sqr(Sin(DegToRad(P.Lat1))));
  T1 := Tan(PI / 4.0 - DegToRad(P.Lat1) / 2.0) /
        PowReal((1.0 - E * Sin(DegToRad(P.Lat1))) / (1.0 + E * Sin(DegToRad(P.Lat1))), E / 2.0);
  If Abs(P.Lat1 - P.Lat2) < 0.0000001 Then NN := Sin(DegToRad(P.Lat1)) Else Begin
   M2 := Cos(DegToRad(P.Lat2)) / Sqrt(1.0 - P.E2 * Sqr(Sin(DegToRad(P.Lat2))));
   T2 := Tan(PI / 4.0 - DegToRad(P.Lat2) / 2.0) /
        PowReal((1.0 - E * Sin(DegToRad(P.Lat2))) / (1.0 + E * Sin(DegToRad(P.Lat2))), E / 2.0);
   NN := Ln(M1 / M2) / Ln(T1 / T2);
  End;
  FF := M1 / (NN * PowReal(T1, NN));
  T1 := Tan(PI / 4.0 - DegToRad(P.Lat0) / 2.0) /
          PowReal((1.0 - E * Sin(DegToRad(P.Lat0))) / (1.0 + E * Sin(DegToRad(P.Lat0))), E / 2.0);
        Rho0 := P.A * FF * PowReal(T1, NN);
  Rho := Sqrt(XMet * XMet + Sqr(Rho0 - YMet));
  If NN < 0.0 Then Rho := -Rho;
  Theta := ArcTan2(XMet, Rho0 - YMet);
  T := PowReal(Rho / (P.A * FF), 1.0 / NN);
  Phi := PI / 2.0 - 2.0 * ArcTan(T);
  For I := 1 To 10 Do Phi := PI / 2.0 - 2.0 * ArcTan(T * PowReal((1.0 - E * Sin(Phi)) / (1.0 + E * Sin(Phi)), E / 2.0));
  Lat := RadToDeg(Phi); Lon := P.Lon0 + RadToDeg(Theta / NN) - P.PM; Exit;
 End;
 Lat := 0.0; Lon := 0.0;
End;

Procedure PrintNumber(Value : Real);
Var S, Fmt : String; I, Width, Prec, Err : Integer;
Begin
 Width := 0; Prec := Decimals;
 If FormatString <> '' Then Begin
  Fmt := FormatString;
  I := Pos('%', Fmt);
  If I > 0 Then Begin
   Delete(Fmt, 1, I);
   While (Fmt <> '') And (Fmt[1] In ['+', '-', ' ', '#', '0']) Do Delete(Fmt, 1, 1);
   I := 1; While (I <= Length(Fmt)) And (Fmt[I] In ['0'..'9']) Do Inc(I);
  If I > 1 Then Begin
   Val(Copy(Fmt, 1, I - 1), Width, Err);
   If Err <> 0 Then Width := 0;
  End;
   Delete(Fmt, 1, I - 1);
   If (Fmt <> '') And (Fmt[1] = '.') Then Begin
    Delete(Fmt, 1, 1); I := 1;
    While (I <= Length(Fmt)) And (Fmt[I] In ['0'..'9']) Do Inc(I);
    If I > 1 Then Begin
     Val(Copy(Fmt, 1, I - 1), Prec, Err);
     If Err <> 0 Then Prec := Decimals;
    End;
   End;
  End;
 End;
 If Prec < 0 Then Prec := Decimals;
 If Prec > 12 Then Prec := 12;
 If Width > 60 Then Width := 60;
 Str(Value:Width:Prec, S); Write(S);
End;

Procedure WriteDMS(Value : Real);
Var D, M, Width, I : Integer; Sec, Frac : Real; S : String;
Begin
 D := Trunc(Abs(Value)); Frac := (Abs(Value) - D) * 60.0;
 M := Trunc(Frac); Sec := (Frac - M) * 60.0;
 Frac := 1.0; For I := 1 To DMSPrecision Do Frac := Frac * 10.0;
 Sec := Trunc(Sec * Frac + 0.5) / Frac;
 If Sec >= 60.0 Then Begin Sec := 0.0; Inc(M); If M >= 60 Then Begin M := 0; Inc(D); End; End;
 If Value < 0.0 Then Write('-');
 If FixedDMS Then Write(D:3) Else Write(D);
 Write(':'); If FixedDMS Then Write(M:2) Else Write(M);
 Width := 3 + DMSPrecision; Str(Sec:Width:DMSPrecision, S);
 While (Length(S) > 0) And (S[1] = ' ') Do Delete(S, 1, 1);
 If FixedDMS Then While Length(S) < Width Do S := '0' + S;
 Write(':', S);
End;

Procedure ShowVerbose;
Begin
 Write('Projection: ');
 Case P.Projection Of
  prjUTM: WriteLn('UTM zone ', P.Zone);
  prjMerc: WriteLn('Mercator');
  prjTMerc: WriteLn('Transverse Mercator');
  prjLCC: WriteLn('Lambert Conformal Conic');
  prjEQC: WriteLn('Equirectangular (spherical)');
  prjSinu: WriteLn('Sinusoidal (spherical)');
  prjCEA: WriteLn('Cylindrical equal-area (spherical)');
  Else WriteLn('longlat');
 End;
 WriteLn('Ellipsoid: a=', P.A:0:3, ' b=', P.B:0:3, ' rf=', 1.0 / P.F:0:9);
 WriteLn('Origin: lat_0=', P.Lat0:0:6, ' lon_0=', P.Lon0:0:6,
         ' x_0=', P.X0:0:3, ' y_0=', P.Y0:0:3);
 WriteLn('Scale: k_0=', P.K0:0:9, ' units=', P.UnitFactor:0:9,
         ' axis=', P.Axis);
 If HasGrid Then WriteLn('Datum grid: ', GridFileName);
End;

Procedure ReadTextInput;
Var Line, Rest, SX, SY, Extra : String; X, Y, Lat, Lon, OutX, OutY, Mult : Real;
 I : Integer; Valid, GridOK : Boolean;
Begin
 While Not EOF(Input) Do Begin
  ReadLn(Line); Rest := Line;
  While (Rest <> '') And (Rest[1] In [' ', #9]) Do Delete(Rest, 1, 1);
  If (Rest = '') Or (Rest[1] = CommentChar[1]) Then WriteLn(Line)
  Else Begin
   SX := ''; SY := ''; Extra := '';
   I := 1;
   While (I <= Length(Rest)) And Not (Rest[I] In [' ', #9]) Do Begin SX := SX + Rest[I]; Inc(I); End;
   While (I <= Length(Rest)) And (Rest[I] In [' ', #9]) Do Inc(I);
   While (I <= Length(Rest)) And Not (Rest[I] In [' ', #9]) Do Begin SY := SY + Rest[I]; Inc(I); End;
   While (I <= Length(Rest)) And (Rest[I] In [' ', #9]) Do Inc(I);
   Extra := Copy(Rest, I, Length(Rest) - I + 1);
   Valid := (SX <> '') And (SY <> '') And ParseReal(SX, X) And ParseReal(SY, Y);
   If Not Valid Then WriteLn(ErrorText) Else Begin
   If SwapIn Then Begin Mult := X; X := Y; Y := Mult; End;
  If Inverse Then Begin X := X * Multiplier; Y := Y * Multiplier; End;
   If Inverse Then Begin
    If P.Projection = prjLongLat Then Begin Lon := X; Lat := Y; End
    Else ProjectInverse(X, Y, Lat, Lon);
    GridOK := ApplyDatumGrid(Lon, Lat, True);
   End Else Begin
    Lat := Y; Lon := X;
    NormalizeLongitude(Lon);
    GridOK := ApplyDatumGrid(Lon, Lat, False);
    If GridOK Then ProjectForward(Lat, Lon, OutX, OutY);
    X := OutX * Multiplier; Y := OutY * Multiplier;
   End;
   If GridOK Then Begin
    If Inverse Then Begin X := Lon; Y := Lat; End;
    If SwapOut Then Begin Mult := X; X := Y; Y := Mult; End;
    If BinaryOutput Then WriteBinaryCoordinate(X, Y)
    Else Begin
     If EchoInput Then Write(SX, ' ', SY, ' ');
     If Inverse Then Begin
      If DMSPrecision >= 0 Then Begin WriteDMS(Lon); Write(' '); WriteDMS(Lat); End
      Else Begin PrintNumber(Lon); Write(' '); PrintNumber(Lat); End;
     End Else Begin PrintNumber(X); Write(' '); PrintNumber(Y); End;
     If Extra <> '' Then Write(' ', Extra);
     WriteLn;
    End;
    If ShowFactors Or Detailed Then Begin
     WriteLn('  Factors S/P/aire: non disponibles pour ce modele autonome.');
     If Detailed Then WriteLn('  lon=', Lon:0:8, ' lat=', Lat:0:8, ' X=', X:0:3, ' Y=', Y:0:3);
    End;
   End Else WriteLn(ErrorText);
  End;
  End;
 End;
End;

Procedure ProcessCoordinate(X, Y : Real; Var OutX, OutY : Real;
                            Var Valid : Boolean);
Var Lat, Lon, Temp : Real;
Begin
 Valid := True;
 If SwapIn Then Begin Temp := X; X := Y; Y := Temp; End;
 If Inverse Then Begin
  X := X * Multiplier; Y := Y * Multiplier;
  If P.Projection = prjLongLat Then Begin Lon := X; Lat := Y; End
  Else ProjectInverse(X, Y, Lat, Lon);
  Valid := ApplyDatumGrid(Lon, Lat, True);
  OutX := Lon; OutY := Lat;
 End Else Begin
  Lat := Y; Lon := X;
  NormalizeLongitude(Lon);
  Valid := ApplyDatumGrid(Lon, Lat, False);
  If Valid Then ProjectForward(Lat, Lon, OutX, OutY);
  OutX := OutX * Multiplier; OutY := OutY * Multiplier;
 End;
 If SwapOut Then Begin Temp := OutX; OutX := OutY; OutY := Temp; End;
End;

Procedure ReadBinaryInput;
Var X, Y, OutX, OutY : Double;
 Actual : Word;
 Valid : Boolean;
Begin
 While ReadBinaryBytes(X, SizeOf(X), Actual) Do Begin
  If Not ReadBinaryBytes(Y, SizeOf(Y), Actual) Then Exit;
  ProcessCoordinate(X, Y, OutX, OutY, Valid);
  If Not Valid Then Exit;
  If BinaryOutput Then WriteBinaryCoordinate(OutX, OutY)
  Else Begin PrintNumber(OutX); Write(' '); PrintNumber(OutY); WriteLn; End;
 End;
End;

Var I, Err : Integer; Arg, ValArg : String; R : Real;
BEGIN
 InitParams;
 Inverse := False; SwapIn := False; SwapOut := False; EchoInput := False;
 Verbose := False; Detailed := False; ShowFactors := False;
 BinaryInput := False; BinaryOutput := False;
 Decimals := 3; DMSPrecision := -1; FixedDMS := False;
 FormatString := ''; ErrorText := '*'; CommentChar := '#'; Multiplier := 1.0;
 I := 1;
 While I <= ParamCount Do Begin
  Arg := ParamStr(I);
  If (Arg = '/?') Or (Arg = '-h') Or (Arg = '--help') Then Begin ShowHelp; Halt(0); End;
  If (Arg = '-l') Or (Arg = '-lp') Or (Arg = '-lP') Or (Arg = '-le') Or (Arg = '-lu') Or (Copy(Arg, 1, 3) = '-l=') Then ShowList(Arg);
  If Arg = '-I' Then Inverse := True Else
  If Arg = '-r' Then SwapIn := True Else
  If Arg = '-s' Then SwapOut := True Else
  If Arg = '-E' Then EchoInput := True Else
  If Arg = '-S' Then ShowFactors := True Else
  If Arg = '-v' Then Verbose := True Else
  If Arg = '-V' Then Begin Detailed := True; Verbose := True; End Else
  If Arg = '-b' Then Begin BinaryInput := True; BinaryOutput := True; End Else
  If Arg = '-i' Then BinaryInput := True Else
  If Arg = '-o' Then BinaryOutput := True Else
  If Arg = '-d' Then Begin
   Inc(I);
   If I > ParamCount Then Begin WriteLn('Erreur: -d attend un entier.'); Halt(1); End;
   Val(ParamStr(I), Decimals, Err);
   If (Err <> 0) Or (Decimals < 0) Or (Decimals > 15) Then Begin
    WriteLn('Erreur: precision -d invalide (0..15).'); Halt(1);
   End;
  End Else
  If Copy(Arg, 1, 2) = '-d' Then Begin
   Val(Copy(Arg, 3, Length(Arg) - 2), Decimals, Err);
   If (Err <> 0) Or (Decimals < 0) Or (Decimals > 15) Then Begin
    WriteLn('Erreur: precision -d invalide (0..15).'); Halt(1);
   End;
  End Else
  If Arg = '-f' Then Begin Inc(I); If I > ParamCount Then Halt(1); FormatString := ParamStr(I); End Else
  If Copy(Arg, 1, 2) = '-f' Then FormatString := Copy(Arg, 3, Length(Arg) - 2) Else
  If Arg = '-e' Then Begin Inc(I); If I > ParamCount Then Halt(1); ErrorText := ParamStr(I); End Else
  If Arg = '-t' Then Begin Inc(I); If I > ParamCount Then Halt(1); CommentChar := Copy(ParamStr(I), 1, 1); End Else
  If (Copy(Arg, 1, 2) = '-t') And (Length(Arg) > 2) Then CommentChar := Copy(Arg, 3, 1) Else
  If (Copy(Arg, 1, 2) = '-w') Or (Copy(Arg, 1, 2) = '-W') Then Begin
   FixedDMS := Arg[2] = 'W'; DMSPrecision := 0;
    If Length(Arg) > 2 Then Begin
     Val(Copy(Arg, 3, Length(Arg) - 2), DMSPrecision, Err);
     If (Err <> 0) Or (DMSPrecision < 0) Or (DMSPrecision > 10) Then Begin
      WriteLn('Erreur: precision DMS invalide (0..10).'); Halt(1);
     End;
    End;
  End Else If (Arg = '-m') Or (Copy(Arg, 1, 2) = '-m') Then Begin
   If Arg = '-m' Then Begin Inc(I); If I > ParamCount Then Halt(1); ValArg := ParamStr(I); End
   Else ValArg := Copy(Arg, 3, Length(Arg) - 2);
  End Else ValArg := '';
  If ValArg <> '' Then Begin
  If (ValArg[1] = '1') And (Length(ValArg) > 1) And (ValArg[2] In ['/', ':']) Then Begin
    Delete(ValArg, 1, 2); If ParseReal(ValArg, R) And (R <> 0.0) Then Multiplier := 1.0 / R;
   End Else If ParseReal(ValArg, R) Then Multiplier := R;
  End;
  Inc(I);
 End;
 ParseProjectionParams(1);
 If (P.Projection = prjUnknown) Then Begin Writeln('Erreur: projection absente ou non prise en charge.'); ShowHelp; Halt(1); End;
 If Verbose Then ShowVerbose;
 If FormatString <> '' Then DMSPrecision := -1;
 If BinaryInput Then ReadBinaryInput Else ReadTextInput;
END.
