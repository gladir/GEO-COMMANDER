{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TRIANGLE;

{$E+,N+}

Const
 EarthRadius=6371000;  { Rayon moyen de la Terre en mŠtres }

Type
 TPoint=Record
  lat,lon:Double;  { Latitude et longitude en degr‚s }
  dist:Double;     { Distance au point inconnu en mŠtres }
 End;

Function ArcCos(a:Real):Real;
Const
 PI=3.141592653589793;
Begin
 If Abs(a)=1.0 Then ArcCos := (1-a)*PI/2.0
               Else ArcCos := Arctan(-a/Sqrt(1-a*a))+2*Arctan(1);
End;

Function ArcSin(a:Real):Real;
Const
 PI=3.141592653589793;
Begin
 If Abs(a)=1.0Then ArcSin:=PI/2.0
              Else ArcSin:=ArcTan(a/Sqrt(1-a*a));
End;

Function Arctan2(y,x:Double):Double;
Const
 PI=3.141592653589793;
Begin
 If x>0 Then Arctan2:=Arctan(y/x) Else
 If(x<0)and(y>=0)Then Arctan2:=Arctan(y/x)+PI Else
 If(x<0)And(y<0)Then Arctan2:=Arctan(y/x)-PI Else
 If(x=0)And(y>0)Then Arctan2:=PI/2 Else
 If(x=0)And(y<0)Then Arctan2:=-PI/2
                Else Arctan2:=0;  { Cas x = 0 et y = 0, angle ind‚fini }
End;

 { Conversion de degr‚s en radians }
Function DegToRad(deg:Double):Double;Begin
 DegToRad:=deg*Pi/180;
End;

 { Conversion de radians en degr‚s }
Function RadToDeg(rad:Double):Double;Begin
 RadToDeg:=rad*180/Pi;
End;

 { Conversion de latitude/longitude en coordonn‚es cart‚siennes (X, Y, Z) }
Procedure LatLonToXYZ(lat,lon:Double;Var x,y,z:Double);
Var
 latRad,lonRad:Double;
Begin
 latRad:=DegToRad(lat);
 lonRad:=DegToRad(lon);

 x:=EarthRadius*Cos(latRad)*Cos(lonRad);
 y:=EarthRadius*Cos(latRad)*sin(lonRad);
 z:=EarthRadius*Sin(latRad);
End;

 { Fonction de trilat‚ration }
Procedure Trilaterate(p1,p2,p3:TPoint;Var lat,lon:Double);
Var
 x1, y1, z1, x2, y2, z2, x3, y3, z3: Double;
 exx, exy, exz, i, eyx, eyy, eyz, j, ezx, ezy, ezz, x, y, z, d, a, b: Double;
Begin
  { Conversion des 3 points en coordonn‚es cart‚siennes }
 LatLonToXYZ(p1.lat, p1.lon, x1, y1, z1);
 LatLonToXYZ(p2.lat, p2.lon, x2, y2, z2);
 LatLonToXYZ(p3.lat, p3.lon, x3, y3, z3);

  { Vecteur unit‚ ex dans la direction de p2 - p1 }
 exx:=(x2 - x1) / sqrt(sqr(x2 - x1) + sqr(y2 - y1) + sqr(z2 - z1));
 exy:=(y2 - y1) / sqrt(sqr(x2 - x1) + sqr(y2 - y1) + sqr(z2 - z1));
 exz:=(z2 - z1) / sqrt(sqr(x2 - x1) + sqr(y2 - y1) + sqr(z2 - z1));

  { Distance entre p1 et p2 }
 d:=sqrt(sqr(x2 - x1) + sqr(y2 - y1) + sqr(z2 - z1));

  { Projeter p3 sur le vecteur ex }
 i:=exx * (x3 - x1) + exy * (y3 - y1) + exz * (z3 - z1);

  { Vecteur unit‚ ey perpendiculaire … ex }
 eyx:=(x3 - x1 - i * exx) / sqrt(sqr(x3 - x1 - i * exx) + sqr(y3 - y1 - i * exy) + sqr(z3 - z1 - i * exz));
 eyy:=(y3 - y1 - i * exy) / sqrt(sqr(x3 - x1 - i * exx) + sqr(y3 - y1 - i * exy) + sqr(z3 - z1 - i * exz));
 eyz:=(z3 - z1 - i * exz) / sqrt(sqr(x3 - x1 - i * exx) + sqr(y3 - y1 - i * exy) + sqr(z3 - z1 - i * exz));

  { Projeter p3 sur ey }
 j:=eyx * (x3 - x1) + eyy * (y3 - y1) + eyz * (z3 - z1);

  { Vecteur unit‚ ez perpendiculaire … ex et ey }
 ezx:=exy * eyz - exz * eyy;
 ezy:=exz * eyx - exx * eyz;
 ezz:=exx * eyy - exy * eyx;

  { Calculer x et y }
 x:=(sqr(p1.dist) - sqr(p2.dist) + sqr(d)) / (2 * d);
 y:=(sqr(p1.dist) - sqr(p3.dist) + sqr(i) + sqr(j)) / (2 * j) - (i / j) * x;

  { Calculer z }
 a:=sqr(p1.dist) - sqr(x) - sqr(y);
 If a<0 Then z:=0
        Else z:=sqrt(a);

  { Convertir (x, y, z) en latitude et longitude }
 lat:=RadToDeg(arcsin(z/EarthRadius));
 lon:=RadToDeg(arctan2(y,x));
End;

Var
 p1,p2,p3:TPoint;
 lat,lon:Double;
 Err:Word;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('TRIANGLE : Cette commande permet la triangulation d''une position ',
                     ' en utilisant un algorithme de trilat‚ration ',
                     'g‚ographique. ');
  WriteLn;
  WriteLn('Syntaxe : TRIANGLE lat1 lon1 dist1 lat2 lon2 dist2 lat3 lon3 dist3');
  WriteLn;
  WriteLn(' lat1   Lattitude de la premiŠre coordonn‚e');
  WriteLn(' lon1   Longitude de la premiŠre coordonn‚es');
  WriteLn(' dist1  La distance de la premiŠre coordonn‚e');
  WriteLn(' lat2   Lattitude de la deuxiŠme coordonn‚e');
  WriteLn(' lon2   Longitude de la deuxiŠme coordonn‚e');
  WriteLn(' dist2  La distance de la deuxiŠme coordonn‚e');
  WriteLn(' lat3   Lattitude de la troisiŠme coordonn‚e');
  WriteLn(' lon3   Longitude de la troisiŠme coordonn‚e');
  WriteLn(' dist3  La distance de la troisiŠme coordonn‚e');
  WriteLn;
  WriteLn('Exemple : triangle 48.8566 2.3522 5000 48.8584 2.2945 3000 48.8738 2.2950 4000');
 End
  Else
 If ParamCount>0Then Begin
   { D‚finition des 3 points de r‚f‚rence et leurs distances }
  Val(ParamStr(1),p1.lat,Err);
  If Err>0 Then Begin
   WriteLn('La latitude 1 n''est pas valide');
   Halt(1);
  End;
  Val(ParamStr(2),p1.lon,Err);
  If Err>0 Then Begin
   WriteLn('La longitude 1 n''est pas valide');
   Halt(1);
  End;
  Val(ParamStr(3),p1.dist,Err);
  If Err>0 Then Begin
   WriteLn('La distance 1 n''est pas valide');
   Halt(1);
  End;
  Val(ParamStr(4),p2.lat,Err);
  If Err>0 Then Begin
   WriteLn('La latitude 2 n''est pas valide');
   Halt(1);
  End;
  Val(ParamStr(5),p2.lon,Err);
  If Err>0 Then Begin
   WriteLn('La longitude 2 n''est pas valide');
   Halt(1);
  End;
  Val(ParamStr(6),p2.dist,Err);
  If Err>0 Then Begin
   WriteLn('La distance 2 n''est pas valide');
   Halt(1);
  End;
  Val(ParamStr(7),p3.lat,Err);
  If Err>0 Then Begin
   WriteLn('La latitude 3 n''est pas valide');
   Halt(1);
  End;
  Val(ParamStr(8),p3.lon,Err);
  If Err>0 Then Begin
   WriteLn('La longitude 3 n''est pas valide');
   Halt(1);
  End;
  Val(ParamStr(9),p3.dist,Err);
  If Err>0 Then Begin
   WriteLn('La distance 3 n''est pas valide');
   Halt(1);
  End;

   { Calcul de la position inconnue }
   Trilaterate(p1, p2, p3, lat, lon);

   { Affichage du r‚sultat }
  Writeln('Latitude: ', lat:0:6, ' Longitude: ', lon:0:6);
 End;
END.