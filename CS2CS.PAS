{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CS2CS;

Uses
 Dos;

Const
 PI       = 3.14159265358979323846;
 A_WGS84  = 6378137.0;
 F_WGS84  = 1.0 / 298.257223563;
 K0       = 0.9996;

Type
 TProjection = (
 prjUnknown,
 prjLongLat,
 prjUTM
 );
 TProjDef = Record
  Projection : TProjection;
  Zone       : Integer;
  South      : Boolean;
 End;

Var
 SourceProj : TProjDef;
 DestProj   : TProjDef;

Function Tan(X : Real) : Real;Begin
 Tan := Sin(X) / Cos(X);
End;

Function DegToRad(D : Real) : Real;Begin
 DegToRad := D * PI / 180.0;
End;

Procedure InitProjection(Var P : TProjDef);Begin
 P.Projection := prjUnknown;
 P.Zone       := 0;
 P.South      := False;
End;

Procedure ParseProjection(StartParam, EndParam : Integer;
                          Var P : TProjDef);
Var
 I : Integer;
 Err:Word;
 S : String;
Begin
 InitProjection(P);
 For I := StartParam To EndParam Do Begin
  S := ParamStr(I);
  If S = '+proj=longlat' Then      P.Projection := prjLongLat Else
  If S = '+proj=utm' Then      P.Projection := prjUTM Else
  If Copy(S, 1, 6) = '+zone=' Then      Val(Copy(S, 7, Length(S) - 6), P.Zone, Err) Else
  If S = '+south' Then      P.South := True;
 End;
End;

Procedure LatLonToUTM(Latitude, Longitude : Real;                      Zone : Integer;
                      South : Boolean;                      Var Easting, Northing : Real);
Var
 F, E2, EP2       : Real;
 Lat, Lon         : Real;
 LonOrigin        : Real;
 LonOriginRad     : Real;
 N, T, C, AA, M   : Real;
Begin
 F   := F_WGS84;
 E2  := F * (2.0 - F);
 EP2 := E2 / (1.0 - E2);
 Lat := DegToRad(Latitude);
 Lon := DegToRad(Longitude);
 LonOrigin :=
 (Zone - 1) * 6 - 180 + 3;
 LonOriginRad := DegToRad(LonOrigin);
 N :=
 A_WGS84 /
 Sqrt(1.0 - E2 * Sqr(Sin(Lat)));
 T := Sqr(Tan(Lat));
 C := EP2 * Sqr(Cos(Lat));
 AA :=
 Cos(Lat) * (Lon - LonOriginRad);
 M :=
 A_WGS84 *
 (
 (1.0 -
 E2 / 4.0 -
 3.0 * Sqr(E2) / 64.0 -
 5.0 * E2 * Sqr(E2) / 256.0) * Lat
 -
 (3.0 * E2 / 8.0 +
 3.0 * Sqr(E2) / 32.0 +
 45.0 * E2 * Sqr(E2) / 1024.0) *
 Sin(2.0 * Lat)
 +
 (15.0 * Sqr(E2) / 256.0 +
 45.0 * E2 * Sqr(E2) / 1024.0) *
 Sin(4.0 * Lat)
 -
 (35.0 * E2 * Sqr(E2) / 3072.0) *
 Sin(6.0 * Lat)
 );
 Easting :=
 K0 * N *
 (
 AA +
 (1.0 - T + C) *
 AA * AA * AA / 6.0 +
 (5.0 - 18.0 * T +
 T * T +
 72.0 * C -
 58.0 * EP2) *
 AA * AA * AA * AA * AA / 120.0
 )
 + 500000.0;
 Northing :=
 K0 *
 (
 M +
 N * Tan(Lat) *
 (
 AA * AA / 2.0 +
 (5.0 - T +
 9.0 * C +
 4.0 * C * C) *
 AA * AA * AA * AA / 24.0 +
 (61.0 -
 58.0 * T +
 T * T +
 600.0 * C -
 330.0 * EP2) *
 AA * AA * AA * AA * AA * AA / 720.0
 )
 );
 If South Then    Northing := Northing + 10000000.0;
End;

Procedure ShowHelp;Begin
 Writeln('CS2CS - Cette commande permet d''effectuer la conversion de coordonn'+#130+'es.');
 Writeln;
 Writeln('Syntaxe:');
 Writeln('  CS2CS <source> +to <destination>');
 Writeln;
 Writeln('Exemple:');
 Writeln('  CS2CS +proj=longlat +datum=WGS84');
 Writeln('         +to +proj=utm +zone=18 +datum=WGS84');
 Writeln;
 Writeln('Le programme lit Longitude Latitude depuis STDIN.');
End;

Var
 I          : Integer;
 ToPosition : Integer;
 Longitude  : Real;
 Latitude   : Real;
 Easting    : Real;
 Northing   : Real;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  ShowHelp;
  Halt(0);
 End;
 ToPosition := 0;
 For I := 1 To ParamCount Do    If ParamStr(I) = '+to' Then      ToPosition := I;
 If ToPosition = 0 Then Begin
  Writeln('Erreur: param'+#138+'tre +to manquant.');
  Halt(1);
 End;
 ParseProjection(
 1,
 ToPosition - 1,
 SourceProj
 );
 ParseProjection(
 ToPosition + 1,
 ParamCount,
 DestProj
 );
 If SourceProj.Projection <> prjLongLat Then Begin
  Writeln('Erreur: projection source non support'+#130+'e.');
  Halt(1);
 End;
 If DestProj.Projection <> prjUTM Then Begin
  Writeln('Erreur: projection destination non support'+#130+'e.');
  Halt(1);
 End;
 If DestProj.Zone = 0 Then Begin
  Writeln('Erreur: zone UTM non specifi'+#130+'e.');
  Halt(1);
 End;
 While Not Eof(Input) Do Begin
  ReadLn(Longitude, Latitude);
  LatLonToUTM(
  Latitude,
  Longitude,
  DestProj.Zone,
  DestProj.South,
  Easting,
  Northing
  );
  Writeln(
  Easting:12:3,
  ' ',
  Northing:12:3
  );
 End;
END.
