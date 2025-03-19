{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program PARIS2G;

Uses
 Crt;

Const
 ParisToGreenwichOffset=2.3373;  { Diff‚rence en degr‚s }

Var
 LongitudeParis,LongitudeGreenwich:Real;
 Err:Word;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('PARIS2G : Cette commande permet de convertir la longitude du ',
          'm‚riden de Paris vers le m‚riden de Greenwich.');
  WriteLn;
  WriteLn('Syntaxe : PARIS2G [longitude]');
  WriteLn;
  WriteLn(' longitude  Longitude de m‚ridien de Paris');
 End
  Else
 If ParamCount>0 Then Begin
  Val(ParamStr(1),longitudeParis,Err);
  If Err>0 Then Begin
   WriteLn('Le premier objet n''est pas valide');
   Halt(1);
  End;
   { Conversion : soustraction du d‚calage }
  longitudeGreenwich := longitudeParis - ParisToGreenwichOffset;
  WriteLn('Longitude ‚quivalente selon le m‚ridien de Greenwich : ', longitudeGreenwich:0:6, ' degr‚s');
 End
  Else
 Begin
  ClrScr;
  Writeln('Conversion de la longitude du meridien de Paris vers Greenwich');
  Writeln('----------------------------------------------------------------');

  Write('Entrez la longitude (en degres) selon le meridien de Paris : ');
  ReadLn(longitudeParis);

   { Conversion : soustraction du d‚calage }
  longitudeGreenwich := longitudeParis - ParisToGreenwichOffset;
  WriteLn('Longitude equivalente selon le meridien de Greenwich : ', longitudeGreenwich:0:6, ' degres');
  WriteLn;
  Write('Appuyez sur une touche pour quitter...');
  ReadKey;
 End;
END.
