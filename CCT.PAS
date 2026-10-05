{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
  @description: CCT - Coordinate Conversion and Transformation
  Pipeline subset: unitconvert, axisswap, affine, helmert (3/7 params),
  cart, UTM, Mercator, Transverse Mercator and longlat.
}
Program Cct;

Const
 PI = 3.14159265358979323846;
 DEG = PI / 180.0;
 ARCSEC = DEG / 3600.0;
 MaxSteps = 16;
 MaxTokens = 32;

Type
 TOp = (opNone, opUnitConvert, opAxisSwap, opAffine, opHelmert,
        opCart, opUTM, opMerc, opTMerc, opLongLat);
 TStep = Record
  Op : TOp;
  Inverse, OmitForward, OmitInverse : Boolean;
  XYInRad, XYOutRad, ZInFeet, ZOutFeet : Boolean;
  HasXYIn, HasXYOut, HasZIn, HasZOut : Boolean;
  Zone : Integer;
  South : Boolean;
  A, F, K0, Lat0, Lon0, X0, Y0 : Real;
  DX, DY, DZ, RX, RY, RZ, Scale : Real;
  RateX, RateY, RateZ, RateRX, RateRY, RateRZ, RateScale : Real;
  Epoch : Real;
  HasEpoch : Boolean;
  Order : String[16];
  Affine : Array[1..4] Of Real;
 End;
 TTokens = Array[1..MaxTokens] Of String[255];

Var
 Steps : Array[1..MaxSteps] Of TStep;
 StepCount, Decimals : Integer;
 Cols : Array[1..4] Of Integer;
 ColCount : Integer;
 ZConstant, TConstant : Real;
 HaveZConstant, HaveTConstant, InverseAll, Verbose, VeryVerbose : Boolean;
 InputName, OutputName, ErrorText : String;
 InputFile, OutputFile : Text;
 OwnInput, OwnOutput : Boolean;

Function UpperString(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do S[I] := UpCase(S[I]);
 UpperString := S;
End;

Function LowerString(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do If S[I] In ['A'..'Z'] Then S[I] := Chr(Ord(S[I]) + 32);
 LowerString := S;
End;

Function ParseReal(S : String; Var V : Real) : Boolean;
Var Err : Integer;
Begin Val(S, V, Err); ParseReal := Err = 0; End;

Function PowerR(A, B : Real) : Real;
Begin
 If A > 0.0 Then PowerR := Exp(B * Ln(A))
 Else If (A = 0.0) And (B > 0.0) Then PowerR := 0.0
 Else PowerR := 0.0;
End;

Function TanR(X : Real) : Real; Begin TanR := Sin(X) / Cos(X); End;
Function D2R(X : Real) : Real; Begin D2R := X * DEG; End;
Function R2D(X : Real) : Real; Begin R2D := X / DEG; End;

Function Atan2R(Y, X : Real) : Real;
Var A : Real;
Begin
 If X > 0 Then A := ArcTan(Y / X)
 Else If X < 0 Then Begin
  A := ArcTan(Y / X);
  If Y >= 0 Then A := A + PI Else A := A - PI;
 End Else If Y > 0 Then A := PI / 2
 Else If Y < 0 Then A := -PI / 2 Else A := 0;
 Atan2R := A;
End;

Procedure InitStep(Var S : TStep);
Var I : Integer;
Begin
 S.Op := opNone; S.Inverse := False; S.OmitForward := False; S.OmitInverse := False;
 S.XYInRad := False; S.XYOutRad := False; S.ZInFeet := False; S.ZOutFeet := False;
 S.HasXYIn := False; S.HasXYOut := False; S.HasZIn := False; S.HasZOut := False;
 S.Zone := 0; S.South := False; S.A := 6378137.0; S.F := 1.0 / 298.257223563;
 S.K0 := 1.0; S.Lat0 := 0.0; S.Lon0 := 0.0; S.X0 := 0.0; S.Y0 := 0.0;
 S.DX := 0.0; S.DY := 0.0; S.DZ := 0.0; S.RX := 0.0; S.RY := 0.0; S.RZ := 0.0;
 S.Scale := 0.0; S.RateX := 0.0; S.RateY := 0.0; S.RateZ := 0.0;
 S.RateRX := 0.0; S.RateRY := 0.0; S.RateRZ := 0.0; S.RateScale := 0.0;
 S.Epoch := 0.0; S.HasEpoch := False; S.Order := '1,2';
 For I := 1 To 4 Do S.Affine[I] := 0.0;
 S.Affine[1] := 1.0; S.Affine[4] := 1.0;
End;

Function GetParam(Arg, Key : String) : String;
Begin
 If Copy(Arg, 1, Length(Key)) = Key Then
  GetParam := Copy(Arg, Length(Key) + 1, Length(Arg) - Length(Key))
 Else GetParam := '';
End;

Procedure ParseStepParam(Var S : TStep; Arg : String);
Var V, U : String; R : Real; Err : Integer;
Begin
 V := GetParam(Arg, '+proj=');
 If V <> '' Then Begin
  U := LowerString(V);
  If U = 'unitconvert' Then S.Op := opUnitConvert Else
  If U = 'axisswap' Then S.Op := opAxisSwap Else
  If U = 'affine' Then S.Op := opAffine Else
  If U = 'helmert' Then S.Op := opHelmert Else
  If U = 'cart' Then S.Op := opCart Else
  If U = 'utm' Then S.Op := opUTM Else
  If U = 'merc' Then S.Op := opMerc Else
  If U = 'tmerc' Then S.Op := opTMerc Else
  If (U = 'longlat') Or (U = 'latlong') Then S.Op := opLongLat;
 End;
 If Arg = '+inv' Then S.Inverse := Not S.Inverse;
 If Arg = '+omit_fwd' Then S.OmitForward := True;
 If Arg = '+omit_inv' Then S.OmitInverse := True;
 If Arg = '+south' Then S.South := True;
 V := GetParam(Arg, '+zone='); If (V <> '') Then Begin Val(V, S.Zone, Err); If Err <> 0 Then S.Zone := 0; End;
 V := GetParam(Arg, '+ellps=');
 If V = 'GRS80' Then Begin S.A := 6378137.0; S.F := 1.0 / 298.257222101; End
 Else If V = 'clrk66' Then Begin S.A := 6378206.4; S.F := 1.0 / 294.978698214; End;
 V := GetParam(Arg, '+datum=');
 If V = 'WGS84' Then Begin S.A := 6378137.0; S.F := 1.0 / 298.257223563; End;
 V := GetParam(Arg, '+a='); If (V <> '') And ParseReal(V, R) Then S.A := R;
 V := GetParam(Arg, '+f='); If (V <> '') And ParseReal(V, R) Then S.F := R;
 V := GetParam(Arg, '+rf='); If (V <> '') And ParseReal(V, R) And (R <> 0) Then S.F := 1.0 / R;
 V := GetParam(Arg, '+k_0='); If (V <> '') And ParseReal(V, R) Then S.K0 := R;
 V := GetParam(Arg, '+k='); If (V <> '') And ParseReal(V, R) Then S.K0 := R;
 V := GetParam(Arg, '+lat_0='); If (V <> '') And ParseReal(V, R) Then S.Lat0 := R;
 V := GetParam(Arg, '+lon_0='); If (V <> '') And ParseReal(V, R) Then S.Lon0 := R;
 V := GetParam(Arg, '+x_0='); If (V <> '') And ParseReal(V, R) Then S.X0 := R;
 V := GetParam(Arg, '+y_0='); If (V <> '') And ParseReal(V, R) Then S.Y0 := R;
 V := GetParam(Arg, '+x='); If (V <> '') And ParseReal(V, R) Then S.DX := R;
 V := GetParam(Arg, '+y='); If (V <> '') And ParseReal(V, R) Then S.DY := R;
 V := GetParam(Arg, '+z='); If (V <> '') And ParseReal(V, R) Then S.DZ := R;
 V := GetParam(Arg, '+rx='); If (V <> '') And ParseReal(V, R) Then S.RX := R;
 V := GetParam(Arg, '+ry='); If (V <> '') And ParseReal(V, R) Then S.RY := R;
 V := GetParam(Arg, '+rz='); If (V <> '') And ParseReal(V, R) Then S.RZ := R;
 V := GetParam(Arg, '+s='); If (V <> '') And ParseReal(V, R) Then S.Scale := R;
 V := GetParam(Arg, '+dx='); If (V <> '') And ParseReal(V, R) Then S.RateX := R;
 V := GetParam(Arg, '+dy='); If (V <> '') And ParseReal(V, R) Then S.RateY := R;
 V := GetParam(Arg, '+dz='); If (V <> '') And ParseReal(V, R) Then S.RateZ := R;
 V := GetParam(Arg, '+drx='); If (V <> '') And ParseReal(V, R) Then S.RateRX := R;
 V := GetParam(Arg, '+dry='); If (V <> '') And ParseReal(V, R) Then S.RateRY := R;
 V := GetParam(Arg, '+drz='); If (V <> '') And ParseReal(V, R) Then S.RateRZ := R;
 V := GetParam(Arg, '+ds='); If (V <> '') And ParseReal(V, R) Then S.RateScale := R;
 V := GetParam(Arg, '+t_epoch='); If (V <> '') And ParseReal(V, R) Then Begin S.Epoch := R; S.HasEpoch := True; End;
 V := GetParam(Arg, '+convention='); If V <> '' Then S.Order := V;
 V := GetParam(Arg, '+xy_in='); If V <> '' Then Begin S.HasXYIn := True; S.XYInRad := V = 'rad'; End;
 V := GetParam(Arg, '+xy_out='); If V <> '' Then Begin S.HasXYOut := True; S.XYOutRad := V = 'rad'; End;
 V := GetParam(Arg, '+z_in='); If V <> '' Then Begin S.HasZIn := True; S.ZInFeet := V = 'ft'; End;
 V := GetParam(Arg, '+z_out='); If V <> '' Then Begin S.HasZOut := True; S.ZOutFeet := V = 'ft'; End;
 V := GetParam(Arg, '+order='); If V <> '' Then S.Order := V;
 V := GetParam(Arg, '+s11='); If (V <> '') And ParseReal(V, R) Then S.Affine[1] := R;
 V := GetParam(Arg, '+s12='); If (V <> '') And ParseReal(V, R) Then S.Affine[2] := R;
 V := GetParam(Arg, '+s21='); If (V <> '') And ParseReal(V, R) Then S.Affine[3] := R;
 V := GetParam(Arg, '+s22='); If (V <> '') And ParseReal(V, R) Then S.Affine[4] := R;
 V := GetParam(Arg, '+xoff='); If (V <> '') And ParseReal(V, R) Then S.DX := R;
 V := GetParam(Arg, '+yoff='); If (V <> '') And ParseReal(V, R) Then S.DY := R;
 V := GetParam(Arg, '+zoff='); If (V <> '') And ParseReal(V, R) Then S.DZ := R;
End;

Procedure ShowHelp;
Begin
 WriteLn('CCT - Cette commande permet d''effectuer des transformations de coordonn'+#130+'es et ',
         'pipelines (subset autonome).');
 WriteLn;
 WriteLn('Syntaxe: CCT [options] +proj=pipeline +step +proj=... [fichier]');
 WriteLn;
 WriteLn('Options: -c colonnes -d n -z valeur -t valeur -I -o fichier -v -vv -V -h');
 WriteLn('Coordonnees traitees: X Y [Z [T]]. Operations: unitconvert, axisswap, affine,');
 WriteLn('helmert, cart, utm, merc, tmerc, longlat.');
 WriteLn('Les grilles datum et les autres operations ne sont pas disponibles.');
End;

Procedure ParseColumns(S : String);
Var I, N, StartPos, Err : Integer;
Begin
 ColCount := 0; StartPos := 1;
 For I := 1 To Length(S) + 1 Do
  If (I > Length(S)) Or (S[I] = ',') Then Begin
   If ColCount < 4 Then Begin
    Inc(ColCount); Val(Copy(S, StartPos, I - StartPos), N, Err);
    If Err = 0 Then Cols[ColCount] := N Else Cols[ColCount] := ColCount;
   End;
   StartPos := I + 1;
  End;
 If ColCount < 2 Then Begin ColCount := 2; Cols[1] := 1; Cols[2] := 2; End;
End;

Procedure ParseTokens(Line : String; Var T : TTokens; Var Count : Integer);
Var I, N : Integer; S : String;
Begin
 Count := 0; I := 1;
 While (I <= Length(Line)) And (Count < MaxTokens) Do Begin
  While (I <= Length(Line)) And (Line[I] In [' ', #9]) Do Inc(I);
  If I <= Length(Line) Then Begin
   N := I;
   While (I <= Length(Line)) And Not (Line[I] In [' ', #9]) Do Inc(I);
   Inc(Count); S := Copy(Line, N, I - N); T[Count] := S;
  End;
 End;
End;

Function GeodeticToXYZ(Lon, Lat, H, A, F : Real; Var X, Y, Z : Real) : Boolean;
Var E2, N : Real;
Begin
 E2 := F * (2.0 - F);
 N := A / Sqrt(1.0 - E2 * Sqr(Sin(Lat)));
 X := (N + H) * Cos(Lat) * Cos(Lon);
 Y := (N + H) * Cos(Lat) * Sin(Lon);
 Z := (N * (1.0 - E2) + H) * Sin(Lat);
 GeodeticToXYZ := True;
End;

Procedure XYZToGeodetic(X, Y, Z, A, F : Real; Var Lon, Lat, H : Real);
Var E2, P, Phi, N : Real; I : Integer;
Begin
 E2 := F * (2.0 - F); P := Sqrt(X * X + Y * Y);
 Lon := Atan2R(Y, X);
 If P < 0.0000001 Then Begin Lat := PI / 2; H := Abs(Z) - A * Sqrt(1-E2); End
 Else Begin
  Phi := ArcTan(Z / (P * (1.0-E2)));
  For I := 1 To 8 Do Begin
   N := A / Sqrt(1.0-E2*Sqr(Sin(Phi)));
   Phi := ArcTan((Z + E2*N*Sin(Phi)) / P);
  End;
  N := A / Sqrt(1.0-E2*Sqr(Sin(Phi)));
  Lat := Phi; H := P / Cos(Phi) - N;
 End;
End;

Function ApplyProjection(Var S : TStep; X, Y, Z, T : Real;
                         Backward : Boolean; Var OX, OY, OZ, OT : Real) : Boolean;
Var Lon, Lat, Lam, Phi, E2, EP2, N, TT, CC, AA, M, M0, K, XMet, YMet, E1, Mu, P1 : Real;
 I : Integer;
Begin
 ApplyProjection := True; OX := X; OY := Y; OZ := Z; OT := T;
 E2 := S.F * (2.0-S.F); EP2 := E2/(1.0-E2);
 If Backward Then Begin
  If S.Op = opLongLat Then Begin OX := X; OY := Y; Exit; End;
  If S.Op = opMerc Then Begin
   XMet := X-S.X0; YMet := Y-S.Y0; Lam := D2R(S.Lon0)+XMet/S.A;
   Phi := PI/2-2*ArcTan(Exp(-YMet/S.A));
  For I := 1 To 8 Do Phi := PI/2-2*ArcTan(Exp(-YMet/S.A)*PowerR((1-Sqrt(E2)*Sin(Phi))/(1+Sqrt(E2)*Sin(Phi)),Sqrt(E2)/2));
   OX := Lam; OY := Phi; Exit;
  End;
  If (S.Op = opUTM) Or (S.Op = opTMerc) Then Begin
   If S.Op = opUTM Then Begin S.Lon0 := (S.Zone-1)*6-180+3; S.K0 := 0.9996; S.X0 := 500000; If S.South Then S.Y0 := 10000000; End;
   XMet := X-S.X0; YMet := Y-S.Y0;
   M := YMet/S.K0;
   Mu := M/(S.A*(1-E2/4-3*Sqr(E2)/64-5*E2*E2*E2/256));
   E1 := (1-Sqrt(1-E2))/(1+Sqrt(1-E2));
   P1 := Mu+(3*E1/2-27*PowerR(E1,3)/32)*Sin(2*Mu)+(21*Sqr(E1)/16-55*PowerR(E1,4)/32)*Sin(4*Mu)+151*PowerR(E1,3)/96*Sin(6*Mu)+1097*PowerR(E1,4)/512*Sin(8*Mu);
   N := S.A/Sqrt(1-E2*Sqr(Sin(P1))); TT := Sqr(TanR(P1)); CC := EP2*Sqr(Cos(P1));
   K := S.A*(1-E2)/PowerR(1-E2*Sqr(Sin(P1)),1.5); AA := XMet/(N*S.K0);
   OY := P1-(N*TanR(P1)/K)*(Sqr(AA)/2-(5+3*TT+10*CC-4*Sqr(CC)-9*EP2)*PowerR(AA,4)/24+(61+90*TT+298*CC+45*Sqr(TT)-252*EP2-3*Sqr(CC))*PowerR(AA,6)/720);
   OX := D2R(S.Lon0)+(AA-(1+2*TT+CC)*PowerR(AA,3)/6+(5-2*CC+28*TT-3*Sqr(CC)+8*EP2+24*Sqr(TT))*PowerR(AA,5)/120)/Cos(P1);
   Exit;
  End;
 End Else Begin
  If S.Op = opLongLat Then Begin OX := X; OY := Y; Exit; End;
  If S.Op = opMerc Then Begin
   If Abs(Y) >= PI/2 Then Begin ApplyProjection := False; Exit; End;
   OX := S.X0+S.A*(X-D2R(S.Lon0));
  OY := S.Y0+S.A*Ln(TanR(PI/4+Y/2)*PowerR((1-Sqrt(E2)*Sin(Y))/(1+Sqrt(E2)*Sin(Y)),Sqrt(E2)/2));
   Exit;
  End;
  If (S.Op = opUTM) Or (S.Op = opTMerc) Then Begin
   If S.Op = opUTM Then Begin S.Lon0 := (S.Zone-1)*6-180+3; S.K0 := 0.9996; S.X0 := 500000; If S.South Then S.Y0 := 10000000; End;
   Lon := X; Lat := Y; Lam := Lon-D2R(S.Lon0); Phi := Lat;
   N := S.A/Sqrt(1-E2*Sqr(Sin(Phi))); TT := Sqr(TanR(Phi)); CC := EP2*Sqr(Cos(Phi)); AA := Cos(Phi)*Lam;
   M := S.A*((1-E2/4-3*Sqr(E2)/64-5*PowerR(E2,3)/256)*Phi-(3*E2/8+3*Sqr(E2)/32+45*PowerR(E2,3)/1024)*Sin(2*Phi)+(15*Sqr(E2)/256+45*PowerR(E2,3)/1024)*Sin(4*Phi)-35*PowerR(E2,3)/3072*Sin(6*Phi));
   M0 := S.A*((1-E2/4-3*Sqr(E2)/64-5*PowerR(E2,3)/256)*D2R(S.Lat0)-(3*E2/8+3*Sqr(E2)/32+45*PowerR(E2,3)/1024)*Sin(2*D2R(S.Lat0))+(15*Sqr(E2)/256+45*PowerR(E2,3)/1024)*Sin(4*D2R(S.Lat0))-35*PowerR(E2,3)/3072*Sin(6*D2R(S.Lat0)));
   OX := S.X0+S.K0*N*(AA+(1-TT+CC)*PowerR(AA,3)/6+(5-18*TT+Sqr(TT)+72*CC-58*EP2)*PowerR(AA,5)/120);
   OY := S.Y0+S.K0*(M-M0+N*TanR(Phi)*(Sqr(AA)/2+(5-TT+9*CC+4*Sqr(CC))*PowerR(AA,4)/24+(61-58*TT+Sqr(TT)+600*CC-330*EP2)*PowerR(AA,6)/720));
   Exit;
  End;
 End;
 ApplyProjection := False;
End;

Procedure ApplyStep(Var S : TStep; Var X, Y, Z, T : Real; Backward : Boolean; Var OK : Boolean);
Var A, B, C, D, F, M, Det, RX, RY, RZ, Scale, DX, DY, DZ : Real;
 TX, TY, TZ, TT : Real;
Begin
 OK := True;
 If S.Op = opUnitConvert Then Begin
  If Backward Then Begin
   If S.HasXYOut And (Not S.XYOutRad) Then Begin X := X*DEG; Y := Y*DEG; End;
   If S.HasXYIn And (Not S.XYInRad) Then Begin X := X/DEG; Y := Y/DEG; End;
  If S.HasZOut And S.ZOutFeet Then Z := Z*0.3048;
  If S.HasZIn And S.ZInFeet Then Z := Z/0.3048;
  End Else Begin
   If S.HasXYIn And (Not S.XYInRad) Then Begin X := X*DEG; Y := Y*DEG; End;
   If S.HasXYOut And (Not S.XYOutRad) Then Begin X := X/DEG; Y := Y/DEG; End;
   If S.HasZIn And S.ZInFeet Then Z := Z*0.3048;
   If S.HasZOut And S.ZOutFeet Then Z := Z/0.3048;
  End;
  Exit;
 End;
 If S.Op = opAxisSwap Then Begin
  If Backward Then Begin
   A := X; B := Y;
   If Pos('2,1', S.Order) > 0 Then Begin X := B; Y := A; End;
  End Else If Pos('2,1', S.Order) > 0 Then Begin A := X; X := Y; Y := A; End;
  Exit;
 End;
 If S.Op = opAffine Then Begin
  A := S.Affine[1]; B := S.Affine[2]; C := S.Affine[3]; D := S.Affine[4];
  Det := A*D-B*C;
  If Abs(Det) < 1.0E-20 Then Begin OK := False; Exit; End;
  If Backward Then Begin
   M := X-S.DX; F := Y-S.DY;
   X := (D*M-B*F)/Det; Y := (A*F-C*M)/Det;
  End Else Begin M := X; F := Y; X := A*M+B*F+S.DX; Y := C*M+D*F+S.DY; End;
  If Backward Then Z := Z-S.DZ Else Z := Z+S.DZ;
  Exit;
 End;
 If S.Op = opHelmert Then Begin
  DX := S.DX; DY := S.DY; DZ := S.DZ;
  RX := S.RX*ARCSEC; RY := S.RY*ARCSEC; RZ := S.RZ*ARCSEC; Scale := 1.0+S.Scale*1E-6;
  If S.HasEpoch Then Begin
   M := T-S.Epoch;
   DX := DX+S.RateX*M; DY := DY+S.RateY*M; DZ := DZ+S.RateZ*M;
   RX := RX+S.RateRX*M*ARCSEC; RY := RY+S.RateRY*M*ARCSEC; RZ := RZ+S.RateRZ*M*ARCSEC;
   Scale := Scale+(S.RateScale*M)*1E-6;
  End;
  If S.Order = 'coordinate_frame' Then Begin RX := -RX; RY := -RY; RZ := -RZ; End;
  A := X; B := Y; C := Z;
  If Backward Then Begin
    X := (A-DX-RZ*B+RY*C)/Scale;
    Y := (B-DY+RZ*A-RX*C)/Scale;
    Z := (C-DZ-RY*A+RX*B)/Scale;
  End Else Begin
    X := DX+Scale*(A-RZ*B+RY*C);
    Y := DY+Scale*(RZ*A-RX*C+B);
    Z := DZ+Scale*(-RY*A+RX*B+C);
  End;
  Exit;
 End;
 If S.Op = opCart Then Begin
  If Backward Then XYZToGeodetic(X,Y,Z,S.A,S.F,X,Y,Z)
  Else GeodeticToXYZ(X,Y,Z,S.A,S.F,X,Y,Z);
  Exit;
 End;
 If (S.Op = opUTM) Or (S.Op = opMerc) Or (S.Op = opTMerc) Or (S.Op = opLongLat) Then Begin
  If Not ApplyProjection(S,X,Y,Z,T,Backward,TX,TY,TZ,TT) Then OK := False
  Else Begin X := TX; Y := TY; Z := TZ; T := TT; End;
  Exit;
 End;
 OK := False;
End;

Procedure ProcessPipeline(Var X, Y, Z, T : Real; Var OK : Boolean);
Var I, Idx : Integer; Backward : Boolean;
Begin
 OK := True;
 For I := 1 To StepCount Do Begin
  Idx := I; If InverseAll Then Idx := StepCount-I+1;
    Backward := (Steps[Idx].Inverse And (Not InverseAll)) Or
            ((Not Steps[Idx].Inverse) And InverseAll);
  If (Not Backward And Steps[Idx].OmitForward) Or
      (Backward And Steps[Idx].OmitInverse) Then Begin End
    Else Begin
    ApplyStep(Steps[Idx], X, Y, Z, T, Backward, OK);
    If Not OK Then Exit;
    End;
 End;
End;

Procedure WriteFormatted(Var F : Text; Value : Real);
Var S : String;
Begin
 Str(Value:0:Decimals,S); Write(F,S);
End;

Procedure ProcessInput;
Var Line, TrimLine : String; Tokens : TTokens; N, I, C : Integer;
 MinRequired : Integer;
 X, Y, Z, T, V : Real; OK, HasToken, CoordsOK : Boolean;
Begin
 While Not EOF(InputFile) Do Begin
  ReadLn(InputFile,Line);
  TrimLine:=Line;
  While (TrimLine<>'') And (TrimLine[1] In [' ',#9]) Do Delete(TrimLine,1,1);
  If (TrimLine='') Or (TrimLine[1]='#') Then WriteLn(OutputFile,Line)
  Else Begin
   ParseTokens(Line,Tokens,N);
  MinRequired := Cols[1]; If Cols[2] > MinRequired Then MinRequired := Cols[2];
  If N < MinRequired Then WriteLn(OutputFile,ErrorText)
   Else Begin
    X:=0; Y:=0; Z:=0; T:=0;
    Val(Tokens[Cols[1]],X,I); HasToken:=I=0;
    Val(Tokens[Cols[2]],Y,I); HasToken:=HasToken And (I=0);
    CoordsOK:=HasToken;
    If (ColCount>=3) And (N>=Cols[3]) Then Begin Val(Tokens[Cols[3]],Z,I); CoordsOK:=CoordsOK And (I=0); End;
    If (ColCount>=4) And (N>=Cols[4]) Then Begin Val(Tokens[Cols[4]],T,I); CoordsOK:=CoordsOK And (I=0); End;
    If HaveZConstant And ((ColCount<3) Or (N<Cols[3])) Then Z:=ZConstant;
    If HaveTConstant And ((ColCount<4) Or (N<Cols[4])) Then T:=TConstant;
    If Not CoordsOK Then WriteLn(OutputFile,ErrorText)
    Else Begin
     ProcessPipeline(X,Y,Z,T,OK);
     If Not OK Then WriteLn(OutputFile,ErrorText)
     Else Begin
      For C := 1 To N Do Begin
       If C>1 Then Write(OutputFile,' ');
       V:=0; HasToken:=False;
       For I:=1 To ColCount Do If C=Cols[I] Then Begin
        Case I Of 1:V:=X; 2:V:=Y; 3:V:=Z; 4:V:=T; End;
        HasToken:=True;
       End;
       If HasToken Then WriteFormatted(OutputFile,V) Else Write(OutputFile,Tokens[C]);
      End;
      If HaveZConstant And ((ColCount<3) Or (N<Cols[3])) Then Begin Write(OutputFile,' '); WriteFormatted(OutputFile,Z); End;
      If HaveTConstant And ((ColCount<4) Or (N<Cols[4])) Then Begin Write(OutputFile,' '); WriteFormatted(OutputFile,T); End;
      WriteLn(OutputFile);
     End;
    End;
   End;
  End;
 End;
End;

Procedure ParseColumnList(S : String);
Var I, N, Err, StartPos : Integer;
Begin
 ColCount:=0; StartPos:=1;
 For I:=1 To Length(S)+1 Do If (I>Length(S)) Or (S[I]=',') Then Begin
  If ColCount<4 Then Begin
   Inc(ColCount); Val(Copy(S,StartPos,I-StartPos),N,Err);
   If (Err<>0) Or (N<1) Or (N>MaxTokens) Then Begin
    WriteLn('Erreur: colonne invalide pour -c.'); Halt(1);
   End;
   Cols[ColCount]:=N;
  End;
  StartPos:=I+1;
 End;
 If ColCount<2 Then Begin ColCount:=2; Cols[1]:=1; Cols[2]:=2; End;
End;

Var I, CurrentStep, Err : Integer; Arg : String;
BEGIN
 Decimals:=6; ZConstant:=0; TConstant:=0; HaveZConstant:=False; HaveTConstant:=False;
 InverseAll:=False; Verbose:=False; VeryVerbose:=False; ErrorText:='*';
 InputName:=''; OutputName:=''; OwnInput:=False; OwnOutput:=False;
 ColCount:=4; Cols[1]:=1; Cols[2]:=2; Cols[3]:=3; Cols[4]:=4; StepCount:=0; CurrentStep:=0;
 For I:=1 To MaxSteps Do InitStep(Steps[I]);
 I:=1;
 While I<=ParamCount Do Begin
  Arg:=ParamStr(I);
  If (Arg='-h') Or (Arg='--help') Or (Arg='/?') Then Begin ShowHelp; Halt(0); End Else
  If Arg='-V' Then Begin WriteLn('CCT Pascal 1.0'); Halt(0); End Else
  If Arg='-I' Then InverseAll:=True Else
  If Arg='-v' Then Verbose:=True Else If Arg='-vv' Then Begin Verbose:=True; VeryVerbose:=True; End Else
  If Arg='-d' Then Begin
   Inc(I); If I>ParamCount Then Begin WriteLn('Erreur: -d attend un entier.'); Halt(1); End;
   Val(ParamStr(I),Decimals,Err);
   If (Err<>0) Or (Decimals<0) Or (Decimals>15) Then Begin WriteLn('Erreur: precision -d invalide (0..15).'); Halt(1); End;
  End Else
  If Copy(Arg,1,2)='-d' Then Begin
   Val(Copy(Arg,3,Length(Arg)-2),Decimals,Err);
   If (Err<>0) Or (Decimals<0) Or (Decimals>15) Then Begin WriteLn('Erreur: precision -d invalide (0..15).'); Halt(1); End;
  End Else
  If Arg='-c' Then Begin Inc(I); If I>ParamCount Then Halt(1); ParseColumnList(ParamStr(I)); End Else
  If Arg='-z' Then Begin
   Inc(I); If I>ParamCount Then Begin WriteLn('Erreur: valeur manquante apres -z.'); Halt(1); End;
   HaveZConstant:=ParseReal(ParamStr(I),ZConstant);
   If Not HaveZConstant Then Begin WriteLn('Erreur: -z attend une valeur numerique.'); Halt(1); End;
  End Else
  If Arg='-t' Then Begin
   Inc(I); If I>ParamCount Then Begin WriteLn('Erreur: valeur manquante apres -t.'); Halt(1); End;
   HaveTConstant:=ParseReal(ParamStr(I),TConstant);
   If Not HaveTConstant Then Begin WriteLn('Erreur: -t attend une valeur numerique.'); Halt(1); End;
  End Else
  If Arg='-o' Then Begin Inc(I); If I>ParamCount Then Halt(1); OutputName:=ParamStr(I); End Else
  If Copy(Arg,1,2)='-o' Then OutputName:=Copy(Arg,3,Length(Arg)-2) Else
  If Arg='+proj=pipeline' Then Begin End Else
  If Arg='+step' Then Begin
   If StepCount>=MaxSteps Then Begin WriteLn('Erreur: trop d''etapes.'); Halt(1); End;
   Inc(StepCount); CurrentStep:=StepCount; InitStep(Steps[CurrentStep]);
  End Else If Copy(Arg,1,1)='+' Then Begin
   If StepCount=0 Then Begin StepCount:=1; CurrentStep:=1; InitStep(Steps[1]); End;
   ParseStepParam(Steps[CurrentStep],Arg);
  End Else If Arg<>'' Then Begin
   If InputName<>'' Then Begin WriteLn('Erreur: un seul fichier d''entree est accepte.'); Halt(1); End;
   InputName:=Arg;
  End;
  Inc(I);
 End;
 If StepCount=0 Then Begin WriteLn('Erreur: operation +proj absente.'); ShowHelp; Halt(1); End;
 For I:=1 To StepCount Do If Steps[I].Op=opNone Then Begin WriteLn('Erreur: operation de pipeline inconnue a l''etape ',I); Halt(1); End;
 If Verbose Then Begin
  WriteLn('Etapes: ',StepCount);
  If VeryVerbose Then For I:=1 To StepCount Do WriteLn('  ',I,': ',Ord(Steps[I].Op),' inverse=',Steps[I].Inverse);
 End;
 Assign(InputFile,InputName);
 If InputName='' Then InputFile:=Input;
 If InputName<>'' Then Begin {$I-} Reset(InputFile); Err:=IOResult; {$I+} If Err<>0 Then Begin WriteLn('Erreur: fichier introuvable: ',InputName); Halt(1); End; OwnInput:=True; End;
 Assign(OutputFile,OutputName);
 If OutputName='' Then OutputFile:=Output
 Else Begin
  If (InputName<>'') And (UpperString(InputName)=UpperString(OutputName)) Then Begin
   WriteLn('Erreur: les fichiers d''entree et de sortie doivent etre differents.'); Halt(1);
  End;
  {$I-} Rewrite(OutputFile); Err:=IOResult; {$I+}
  If Err<>0 Then Begin WriteLn('Erreur: impossible de creer ',OutputName); Halt(1); End;
  OwnOutput:=True;
 End;
 ProcessInput;
 If OwnInput Then Close(InputFile);
 If OwnOutput Then Close(OutputFile);
END.
