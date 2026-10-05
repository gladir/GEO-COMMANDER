{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CS2CS;

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

Function RadToDeg(R : Real) : Real;Begin
 RadToDeg := R * 180.0 / PI;
End;

Procedure InitProjection(Var P : TProjDef);Begin
 P.Projection := prjUnknown;
 P.Zone       := 0;
 P.South      := False;
End;

Procedure ParseProjection(StartParam, EndParam : Integer;
                          Var P : TProjDef);
Var
 I    : Integer;
 Err  : Word;
 S    : String;
Begin
 InitProjection(P);
 For I := StartParam To EndParam Do Begin
  S := ParamStr(I);
  If S = '+proj=longlat' Then P.Projection := prjLongLat Else
  If S = '+proj=utm' Then P.Projection := prjUTM Else
  If Copy(S, 1, 6) = '+zone=' Then
   Val(Copy(S, 7, Length(S) - 6), P.Zone, Err) Else
  If S = '+south' Then P.South := True;
 End;
End;

Procedure LatLonToUTM(Latitude, Longitude : Real; Zone : Integer;
                      South : Boolean; Var Easting, Northing : Real);
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
 LonOrigin := (Zone - 1) * 6 - 180 + 3;
 LonOriginRad := DegToRad(LonOrigin);
 N := A_WGS84 / Sqrt(1.0 - E2 * Sqr(Sin(Lat)));
 T := Sqr(Tan(Lat));
 C := EP2 * Sqr(Cos(Lat));
 AA := Cos(Lat) * (Lon - LonOriginRad);
 M := A_WGS84 *
  ((1.0 - E2 / 4.0 - 3.0 * Sqr(E2) / 64.0 -
    5.0 * E2 * Sqr(E2) / 256.0) * Lat -
   (3.0 * E2 / 8.0 + 3.0 * Sqr(E2) / 32.0 +
    45.0 * E2 * Sqr(E2) / 1024.0) * Sin(2.0 * Lat) +
   (15.0 * Sqr(E2) / 256.0 + 45.0 * E2 * Sqr(E2) / 1024.0) *
    Sin(4.0 * Lat) -
   (35.0 * E2 * Sqr(E2) / 3072.0) * Sin(6.0 * Lat));
 Easting := K0 * N *
  (AA + (1.0 - T + C) * AA * AA * AA / 6.0 +
   (5.0 - 18.0 * T + T * T + 72.0 * C - 58.0 * EP2) *
    AA * AA * AA * AA * AA / 120.0) + 500000.0;
 Northing := K0 * (M + N * Tan(Lat) *
  (AA * AA / 2.0 +
   (5.0 - T + 9.0 * C + 4.0 * C * C) *
    AA * AA * AA * AA / 24.0 +
   (61.0 - 58.0 * T + T * T + 600.0 * C - 330.0 * EP2) *
    AA * AA * AA * AA * AA * AA / 720.0));
 If South Then Northing := Northing + 10000000.0;
End;

Procedure UTMToLatLon(Easting, Northing : Real; Zone : Integer;
                      South : Boolean; Var Latitude, Longitude : Real);
Var
 F, E2, EP2, E1 : Real;
 X, Y, M, Mu   : Real;
 Phi1, N1, T1  : Real;
 C1, R1, D, L0 : Real;
Begin
 F := F_WGS84;
 E2 := F * (2.0 - F);
 EP2 := E2 / (1.0 - E2);
 E1 := (1.0 - Sqrt(1.0 - E2)) / (1.0 + Sqrt(1.0 - E2));
 X := Easting - 500000.0;
 Y := Northing;
 If South Then Y := Y - 10000000.0;
 M := Y / K0;
 Mu := M / (A_WGS84 * (1.0 - E2 / 4.0 - 3.0 * Sqr(E2) / 64.0 -
      5.0 * E2 * Sqr(E2) / 256.0));
 Phi1 := Mu + (3.0 * E1 / 2.0 - 27.0 * E1 * E1 * E1 / 32.0) * Sin(2.0 * Mu)
       + (21.0 * E1 * E1 / 16.0 - 55.0 * E1 * E1 * E1 * E1 / 32.0) * Sin(4.0 * Mu)
       + (151.0 * E1 * E1 * E1 / 96.0) * Sin(6.0 * Mu)
       + (1097.0 * E1 * E1 * E1 * E1 / 512.0) * Sin(8.0 * Mu);
 N1 := A_WGS84 / Sqrt(1.0 - E2 * Sqr(Sin(Phi1)));
 T1 := Sqr(Tan(Phi1));
 C1 := EP2 * Sqr(Cos(Phi1));
 R1 := A_WGS84 * (1.0 - E2) /
       ((1.0 - E2 * Sqr(Sin(Phi1))) *
        Sqrt(1.0 - E2 * Sqr(Sin(Phi1))));
 D := X / (N1 * K0);
 Latitude := Phi1 - (N1 * Tan(Phi1) / R1) *
  (D * D / 2.0 - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * C1 * C1 -
   9.0 * EP2) * D * D * D * D / 24.0 +
   (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * T1 * T1 -
    252.0 * EP2 - 3.0 * C1 * C1) * D * D * D * D * D * D / 720.0);
 L0 := DegToRad((Zone - 1) * 6 - 180 + 3);
 Longitude := L0 + (D - (1.0 + 2.0 * T1 + C1) * D * D * D / 6.0 +
  (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * C1 * C1 +
   8.0 * EP2 + 24.0 * T1 * T1) * D * D * D * D * D / 120.0) /
  Cos(Phi1);
 Latitude := RadToDeg(Latitude);
 Longitude := RadToDeg(Longitude);
End;

Procedure ShowHelp;Begin
 Writeln('CS2CS - Cette commande permet de transformer des coordonn',#130,
         'es (longlat WGS84 / UTM WGS84).');
 WriteLn;
 Writeln('Syntaxe: CS2CS [options] <source> +to <destination>');
 WriteLn;
 Writeln('  -I              transformation inverse');
 Writeln('  -d <n>           nombre de decimales');
 Writeln('  -f <format>      format numerique, ex. "%.8f"');
 Writeln('  -e <texte>       texte pour une ligne invalide');
 Writeln('  -E              afficher aussi les coordonnees en entree');
 Writeln('  -r / -s         inverser X/Y en entree / sortie');
 Writeln('  -t<char>         marqueur de commentaire (defaut: #)');
 Writeln('  -v              afficher les projections utilisees');
 Writeln('  -w<n> / -W<n>   sortie angulaire en DMS');
 Writeln('  -l, -l=<id>, -lp, -lP, -le, -lm, -lu : listes');
 WriteLn;
 Writeln('Les projections implementes sont +proj=longlat et +proj=utm.');
 Writeln('--3d conserve une coordonnee Z fournie (sans promotion de CRS).');
 Writeln('--area, --bbox, --authority, --accuracy, --only-best,');
 Writeln('--no-ballpark et --s_epoch/--t_epoch necessitent le moteur PROJ');
 Writeln('et sont refusees par cette implementation autonome.');
End;

Procedure ShowList(Kind : String);
Var ProjectionId : String;
Begin
 If (Kind = '-l') Or (Kind = '-lp') Then Begin
  Writeln('Projections disponibles:');
  Writeln('  longlat  Coordonnees geographiques WGS84');
  Writeln('  utm      Universal Transverse Mercator WGS84');
 End Else
 If Kind = '-lP' Then Begin
  Writeln('+proj=longlat : longitude/latitude geographiques sur WGS84.');
  Writeln('+proj=utm     : projection UTM WGS84, avec +zone=<1..60>');
  Writeln('                et +south pour l''hemisphere sud.');
 End Else
 If Kind = '-le' Then Writeln('Ellipsoide disponible: WGS84 (a=6378137, f=1/298.257223563)') Else
 If Kind = '-lm' Then Writeln('Meridien d''origine disponible: Greenwich (0 degre)') Else
 If Kind = '-lu' Then Begin
  Writeln('Unites disponibles:');
  Writeln('  m       metre');
  Writeln('  degree  degre');
 End Else
 If Copy(Kind, 1, 3) = '-l=' Then Begin
  ProjectionId := Copy(Kind, 4, Length(Kind) - 3);
  If ProjectionId = 'utm' Then Begin
   Writeln('+proj=utm : projection transverse de Mercator universelle.');
   Writeln('Parametres: ellipsoide WGS84, +zone=<1..60>, +south facultatif.');
  End Else If ProjectionId = 'longlat' Then
   Writeln('+proj=longlat : longitude et latitude geographiques WGS84.')
  Else Begin
   Writeln('Projection inconnue: ', ProjectionId);
   Halt(1);
  End;
 End;
 Halt(0);
End;

Function ProjectionName(P : TProjDef) : String;
Var S, NameText : String;
Begin
 If P.Projection = prjLongLat Then ProjectionName := 'longlat WGS84' Else
 If P.Projection = prjUTM Then Begin
  Str(P.Zone, S);
  NameText := 'UTM zone ' + S;
  If P.South Then NameText := NameText + ' sud';
  NameText := NameText + ' WGS84';
  ProjectionName := NameText;
 End Else ProjectionName := 'inconnue';
End;

Procedure WritePaddedInteger(Value, Width : Integer);Var S : String;Begin
 Str(Value:0, S);
 While Length(S) < Width Do S := '0' + S;
 Write(S);
End;

Procedure WriteDMS(Value : Real; Precision : Integer; FixedWidth : Boolean);
Var
 A, MinutesValue, Seconds, Scale : Real;
 Degrees, Minutes, Width, I : Integer;
 S : String;
Begin
 A := Abs(Value);
 Degrees := Trunc(A);
 MinutesValue := (A - Degrees) * 60.0;
 Minutes := Trunc(MinutesValue);
 Seconds := (MinutesValue - Minutes) * 60.0;
 Scale := 1.0;
 For I := 1 To Precision Do Scale := Scale * 10.0;
 Seconds := Trunc(Seconds * Scale + 0.5) / Scale;
 If Seconds >= 60.0 Then Begin
  Seconds := 0.0;
  Inc(Minutes);
  If Minutes >= 60 Then Begin
   Minutes := 0;
   Inc(Degrees);
  End;
 End;
 If Value < 0 Then Write('-');
 If FixedWidth Then WritePaddedInteger(Degrees, 3) Else Write(Degrees);
 Write(':');
 If FixedWidth Then WritePaddedInteger(Minutes, 2) Else Begin
  Str(Minutes:0, S);
  Write(S);
 End;
 Write(':');
 Width := 2 + Precision + 1;
 Str(Seconds:Width:Precision, S);
 While (Length(S) > 0) And (S[1] = ' ') Do Delete(S, 1, 1);
 If FixedWidth Then Begin
  While Length(S) < Width Do S := '0' + S;
 End;
 Write(S);
End;

Function FormatNumber(Value : Real; Precision : Integer;
                      FormatString : String) : String;
Var
 I, J, Width, FPrecision, Err : Integer;
 S : String;
 Ch : Char;
Begin
 Width := 0;
 FPrecision := Precision;
 I := 1;
 While (I <= Length(FormatString)) And (FormatString[I] <> '%') Do Inc(I);
 If I <= Length(FormatString) Then Begin
  Inc(I);
  While (I <= Length(FormatString)) And
        (FormatString[I] In ['+', '-', ' ', '#', '0']) Do Inc(I);
  J := I;
  While (I <= Length(FormatString)) And (FormatString[I] In ['0'..'9']) Do Inc(I);
  If I > J Then Val(Copy(FormatString, J, I - J), Width, Err);
  If (I <= Length(FormatString)) And (FormatString[I] = '.') Then Begin
   Inc(I);
   J := I;
   While (I <= Length(FormatString)) And (FormatString[I] In ['0'..'9']) Do Inc(I);
   If I > J Then Val(Copy(FormatString, J, I - J), FPrecision, Err);
  End;
  If I <= Length(FormatString) Then Begin
   Ch := FormatString[I];
   If Ch In ['f', 'F', 'e', 'E', 'g', 'G'] Then Begin
    { Turbo Pascal's Str formats fixed-point values; the directive precision
      remains useful even when exponent/general formatting was requested. }
   End;
  End;
 End;
 If FPrecision < 0 Then FPrecision := 0;
 If FPrecision > 15 Then FPrecision := 15;
 If Width < 0 Then Width := 0;
 Str(Value:Width:FPrecision, S);
 FormatNumber := S;
End;

Function NextToken(Var S : String) : String;
Var I : Integer;
Begin
 While (Length(S) > 0) And (S[1] In [' ', #9]) Do Delete(S, 1, 1);
 I := 1;
 While (I <= Length(S)) And Not (S[I] In [' ', #9]) Do Inc(I);
 NextToken := Copy(S, 1, I - 1);
 Delete(S, 1, I - 1);
End;

Function TryValue(S : String; Var V : Real) : Boolean;
Var Err : Integer;
Begin
 Val(S, V, Err);
 TryValue := Err = 0;
End;

Procedure ShowVerbose(Source, Dest : TProjDef);Begin
 Writeln('Source:      ', ProjectionName(Source));
 Writeln('Destination: ', ProjectionName(Dest));
 Writeln('Ellipsoide:  WGS84');
End;

Var
 I, ToPosition, Decimals, DMSPrecision, Err : Integer;
 Longitude, Latitude, X, Y, OutX, OutY, Z : Real;
 TempReal : Real;
 TempProj : TProjDef;
 Line, WorkLine, TokenX, TokenY, TokenZ, FormatString : String;
 ErrorText, CommentMark, Arg : String;
 Inverse, EchoInput, SwapInput, SwapOutput, Verbose : Boolean;
 DMSOutput, FixedDMS, Has3D, Failed : Boolean;

BEGIN
 Decimals := 3;
 DMSPrecision := 0;
 FormatString := '';
 ErrorText := '*';
 CommentMark := '#';
 Inverse := False;
 EchoInput := False;
 SwapInput := False;
 SwapOutput := False;
 Verbose := False;
 DMSOutput := False;
 FixedDMS := False;
 Has3D := False;

 I := 1;
 While I <= ParamCount Do Begin
  Arg := ParamStr(I);
  If (Arg = '-h') Or (Arg = '--help') Or (Arg = '/?') Or
     (Arg = '/h') Or (Arg = '/H') Then Begin
   ShowHelp;
   Halt(0);
  End;
  If (Arg = '-l') Or (Arg = '-lp') Or (Arg = '-lP') Or
     (Arg = '-le') Or (Arg = '-lm') Or (Arg = '-lu') Or
     (Copy(Arg, 1, 3) = '-l=') Then ShowList(Arg);
  If Arg = '-I' Then Inverse := True Else
  If Arg = '-E' Then EchoInput := True Else
  If Arg = '-r' Then SwapInput := True Else
  If Arg = '-s' Then SwapOutput := True Else
  If Arg = '-v' Then Verbose := True Else
  If Arg = '--3d' Then Has3D := True Else
  If Arg = '-d' Then Begin
   Inc(I);
   If I > ParamCount Then Begin Writeln('Erreur: valeur manquante apres -d.'); Halt(1); End;
   Val(ParamStr(I), Decimals, Err);
   If (Err <> 0) Or (Decimals < 0) Or (Decimals > 15) Then Begin
    Writeln('Erreur: precision -d invalide (0..15).'); Halt(1);
   End;
  End Else
  If Arg = '-f' Then Begin
   Inc(I);
   If I > ParamCount Then Begin Writeln('Erreur: format manquant apres -f.'); Halt(1); End;
   FormatString := ParamStr(I);
  End Else
  If Arg = '-e' Then Begin
   Inc(I);
   If I > ParamCount Then Begin Writeln('Erreur: texte manquant apres -e.'); Halt(1); End;
   ErrorText := ParamStr(I);
  End Else
  If Arg = '-t' Then Begin
   Inc(I);
   If I > ParamCount Then Begin Writeln('Erreur: caractere manquant apres -t.'); Halt(1); End;
   CommentMark := Copy(ParamStr(I), 1, 1);
  End Else
  If (Copy(Arg, 1, 2) = '-t') And (Length(Arg) > 2) Then
   CommentMark := Copy(Arg, 3, 1) Else
  If (Copy(Arg, 1, 2) = '-w') Or (Copy(Arg, 1, 2) = '-W') Then Begin
   DMSOutput := True;
   FixedDMS := Arg[2] = 'W';
  Err := 0;
  If Length(Arg) > 2 Then Val(Copy(Arg, 3, Length(Arg) - 2), DMSPrecision, Err)
   Else If I < ParamCount Then Begin
    Inc(I);
    Val(ParamStr(I), DMSPrecision, Err);
   End;
  If (Err <> 0) Or (DMSPrecision < 0) Or (DMSPrecision > 10) Then Begin
    Writeln('Erreur: precision DMS invalide (0..10).'); Halt(1);
   End;
  End Else
  If (Arg = '--area') Or (Arg = '--bbox') Or (Arg = '--authority') Or
     (Arg = '--accuracy') Or (Copy(Arg, 1, 7) = '--area=') Or
     (Copy(Arg, 1, 7) = '--bbox=') Or (Copy(Arg, 1, 12) = '--authority=') Or
     (Copy(Arg, 1, 11) = '--accuracy=') Or
    (Arg = '--only-best') Or (Copy(Arg, 1, 12) = '--only-best=') Or
     (Arg = '--no-ballpark') Or (Arg = '--s_epoch') Or
     (Arg = '--t_epoch') Or (Copy(Arg, 1, 10) = '--s_epoch=') Or
     (Copy(Arg, 1, 10) = '--t_epoch=') Then Begin
   Writeln('Erreur: ', Arg,
    ' exige le catalogue et le moteur de selection d''operations PROJ,');
   Writeln('qui ne sont pas integres a cette version autonome de CS2CS.');
   Halt(1);
  End;
  Inc(I);
 End;

 ToPosition := 0;
 For I := 1 To ParamCount Do
  If ParamStr(I) = '+to' Then ToPosition := I;
 If ToPosition = 0 Then Begin
  Writeln('Erreur: parametre +to manquant.');
  Halt(1);
 End;
 ParseProjection(1, ToPosition - 1, SourceProj);
 ParseProjection(ToPosition + 1, ParamCount, DestProj);
 If Inverse Then Begin
  TempProj := SourceProj;
  SourceProj := DestProj;
  DestProj := TempProj;
 End;
 If SourceProj.Projection = prjUnknown Then Begin
  Writeln('Erreur: projection source non supportee.'); Halt(1);
 End;
 If DestProj.Projection = prjUnknown Then Begin
  Writeln('Erreur: projection destination non supportee.'); Halt(1);
 End;
 If (SourceProj.Projection = prjUTM) And
    ((SourceProj.Zone < 1) Or (SourceProj.Zone > 60)) Then Begin
  Writeln('Erreur: zone UTM source invalide (1..60).'); Halt(1);
 End;
 If (DestProj.Projection = prjUTM) And
    ((DestProj.Zone < 1) Or (DestProj.Zone > 60)) Then Begin
  Writeln('Erreur: zone UTM destination invalide (1..60).'); Halt(1);
 End;
 If Verbose Then ShowVerbose(SourceProj, DestProj);

 While Not Eof(Input) Do Begin
  ReadLn(Line);
  WorkLine := Line;
  While (Length(WorkLine) > 0) And (WorkLine[1] In [' ', #9]) Do
   Delete(WorkLine, 1, 1);
  If WorkLine = '' Then Writeln(Line)
  Else If WorkLine[1] = CommentMark[1] Then Writeln(Line)
  Else Begin
   WorkLine := Line;
   TokenX := NextToken(WorkLine);
   TokenY := NextToken(WorkLine);
   TokenZ := '';
   X := 0.0; Y := 0.0; Z := 0.0;
   Failed := (TokenX = '') Or (TokenY = '') Or
             (Not TryValue(TokenX, X)) Or (Not TryValue(TokenY, Y));
   If Not Failed Then Begin
    If Has3D Then Begin
     TokenZ := NextToken(WorkLine);
     If (TokenZ <> '') And (TokenZ[1] <> CommentMark[1]) Then
      If Not TryValue(TokenZ, Z) Then Failed := True;
    End;
   End;
   If Failed Then Writeln(ErrorText)
   Else Begin
    If SwapInput Then Begin
     Longitude := Y;
     Latitude := X;
    End Else Begin
     Longitude := X;
     Latitude := Y;
    End;
    If SourceProj.Projection = prjLongLat Then Begin
     If DestProj.Projection = prjLongLat Then Begin
      OutX := Longitude; OutY := Latitude;
     End Else Begin
      LatLonToUTM(Latitude, Longitude, DestProj.Zone,
                  DestProj.South, OutX, OutY);
     End;
    End Else If DestProj.Projection = prjLongLat Then Begin
     UTMToLatLon(Longitude, Latitude, SourceProj.Zone,
                 SourceProj.South, OutY, OutX);
    End Else If (SourceProj.Zone = DestProj.Zone) And
                 (SourceProj.South = DestProj.South) Then Begin
     OutX := Longitude; OutY := Latitude;
    End Else Begin
     Failed := True;
    End;
    If Failed Then Writeln(ErrorText)
    Else Begin
     If SwapOutput Then Begin
      TempReal := OutX; OutX := OutY; OutY := TempReal;
     End;
     If EchoInput Then Begin
      If SwapInput Then Write(TokenX, ' ', TokenY, ' ')
      Else Write(TokenX, ' ', TokenY, ' ');
      If Has3D And (TokenZ <> '') Then Write(TokenZ, ' ');
     End;
     If DMSOutput And (DestProj.Projection = prjLongLat) Then Begin
      WriteDMS(OutX, DMSPrecision, FixedDMS);
      Write(' ');
      WriteDMS(OutY, DMSPrecision, FixedDMS);
     End Else Begin
      Write(FormatNumber(OutX, Decimals, FormatString));
      Write(' ');
      Write(FormatNumber(OutY, Decimals, FormatString));
     End;
     If Has3D And (TokenZ <> '') Then Write(' ', FormatNumber(Z, Decimals, FormatString));
     Writeln;
    End;
   End;
  End;
 End;
END.