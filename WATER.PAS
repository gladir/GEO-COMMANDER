{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program WATER;

Uses Strings;

Type
 WaterRec=Record
  Nom:PChar;
  Superficie:LongInt; { Km2 }
  TypeWater:(Ocean,Mer,Lac,Golfe,Baie);
  Salinite:(Douce,Sale);
 End;

Const
 Waters:Array[0..59]of WaterRec=(
  (Nom:'Aral';Superficie:66457;TypeWater:Lac;Salinite:Douce),
  (Nom:'Athabasca';Superficie:7920;TypeWater:Lac;Salinite:Douce),
  (Nom:'Baie d''Hudson';Superficie:730121;TypeWater:Baie;Salinite:Sale),
  (Nom:'Baikal';Superficie:31500;TypeWater:Lac;Salinite:Douce),
  (Nom:'Balkash';Superficie:18428;TypeWater:Lac;Salinite:Douce),
  (Nom:'Dubwant';Superficie:4144;TypeWater:Lac;Salinite:Douce),
  (Nom:'Eri‚';Superficie:25719;TypeWater:Lac;Salinite:Douce),
  (Nom:'Eyre';Superficie:6216;TypeWater:Lac;Salinite:Douce),
  (Nom:'Golfe de Californie';Superficie:153069;TypeWater:Golfe;Salinite:Sale),
  (Nom:'Golfe du Mexique';Superficie:1507639;TypeWater:Golfe;Salinite:Sale),
  (Nom:'Grand Lac de l''Esclave Canada';Superficie:28930;TypeWater:Lac;Salinite:Douce),
  (Nom:'Grand Lac de l''Ours';Superficie:31080;TypeWater:Lac;Salinite:Douce),
  (Nom:'Oc‚an Pacifique';Superficie:166242517;TypeWater:Ocean;Salinite:Sale),
  (Nom:'Golfe Persique';Superficie:229992;TypeWater:Golfe;Salinite:Sale),
  (Nom:'Great Salt Lake';Superficie:4662;TypeWater:Lac;Salinite:Douce),
  (Nom:'Issyk-Kul';Superficie:6200;TypeWater:Lac;Salinite:Douce),
  (Nom:'Kioga';Superficie:4403;TypeWater:Lac;Salinite:Douce),
  (Nom:'Koko-Nor';Superficie:4222;TypeWater:Lac;Salinite:Douce),
  (Nom:'Ladoga';Superficie:18130;TypeWater:Lac;Salinite:Douce),
  (Nom:'Malawi';Superficie:30800;TypeWater:Lac;Salinite:Douce),
  (Nom:'Mer Baltique';Superficie:382025;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer Caspienne';Superficie:394299;TypeWater:Mer;Salinite:Douce),
  (Nom:'Mer de Bering';Superficie:2261070;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer de Chine M‚rdionale';Superficie:2974615;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer de Chine Orientale';Superficie:664594;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer des Cara‹bes';Superficie:2515926;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer d''Okhotsk';Superficie:1392125;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer du Japon';Superficie:1012949;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer du Nord';Superficie:427091;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer d''Andaman';Superficie:564879;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer Jaune';Superficie:293965;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer M‚diterran‚e';Superficie:2509969;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer Noire';Superficie:507899;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mer Rouge';Superficie:452991;TypeWater:Mer;Salinite:Sale),
  (Nom:'Mweru';Superficie:4196;TypeWater:Lac;Salinite:Douce),
  (Nom:'Nicaragua';Superficie:8001;TypeWater:Lac;Salinite:Douce),
  (Nom:'Nyasa';Superficie:30044;TypeWater:Lac;Salinite:Douce),
  (Nom:'Oc‚an Atlantique';Superficie:86557800;TypeWater:Ocean;Salinite:Sale),
  (Nom:'Oc‚an Indien';Superficie:73427795;TypeWater:Ocean;Salinite:Sale),
  (Nom:'Oc‚an Arctique';Superficie:9485098;TypeWater:Ocean;Salinite:Sale),
  (Nom:'Onega';Superficie:9891;TypeWater:Lac;Salinite:Douce),
  (Nom:'Ontario';Superficie:19477;TypeWater:Lac;Salinite:Douce),
  (Nom:'Reindeer';Superficie:6330;TypeWater:Lac;Salinite:Douce),
  (Nom:'Rudolf';Superficie:6405;TypeWater:Lac;Salinite:Douce),
  (Nom:'Sup‚rieur';Superficie:82414;TypeWater:Lac;Salinite:Douce),
  (Nom:'Tchad';Superficie:25760;TypeWater:Lac;Salinite:Douce),
  (Nom:'Victoria';Superficie:69485;TypeWater:Lac;Salinite:Douce),
  (Nom:'Huron';Superficie:59596;TypeWater:Lac;Salinite:Douce),
  (Nom:'Manitoba';Superficie:4706;TypeWater:Lac;Salinite:Douce),
  (Nom:'Michigan';Superficie:59596;TypeWater:Lac;Salinite:Douce),
  (Nom:'Mobutu Sese Seko';Superficie:5299;TypeWater:Lac;Salinite:Douce),
  (Nom:'Nettiling';Superficie:5051;TypeWater:Lac;Salinite:Douce),
  (Nom:'Nipigon';Superficie:4843;TypeWater:Lac;Salinite:Douce),
  (Nom:'Tanganyika';Superficie:32893;TypeWater:Lac;Salinite:Douce),
  (Nom:'Titicaca';Superficie:8135;TypeWater:Lac;Salinite:Douce),
  (Nom:'Torrens';Superficie:5698;TypeWater:Lac;Salinite:Douce),
  (Nom:'Urmia';Superficie:6001;TypeWater:Lac;Salinite:Douce),
  (Nom:'Vanem';Superficie:5545;TypeWater:Lac;Salinite:Douce),
  (Nom:'Winnepegosis';Superficie:5403;TypeWater:Lac;Salinite:Douce),
  (Nom:'Winnipeg';Superficie:23553;TypeWater:Lac;Salinite:Douce)
 );

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I]in['‚','Š','ˆ',#233]Then S[I]:='E'Else
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Var
 I,J:Integer;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('WATER : Cette commande permet de retourner les informations d''une ',
                   'superficie d''eau.');
  WriteLn;
  WriteLn('Syntaxe : WATER [eau]');
  WriteLn;
  WriteLn(' eau   Ce parametre peut ˆtre un lac, un ocean, une baie ou golfe');
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
   For J:=Low(Waters) to High(Waters)do Begin
    If StrToUpper(StrPas(Waters[J].Nom))=StrToUpper(ParamStr(I))Then Begin
     WriteLn(PadRight('Nom : ',20),Waters[J].Nom);
     WriteLn(PadRight('Superficie : ',20),Waters[J].Superficie,' Km2');
     Write(PadRight('Type : ',20));
     Case Waters[J].TypeWater of
      Ocean:WriteLn('Oc‚an');
      Mer:WriteLn('Mer');
      Lac:WriteLn('Lac');
      Golfe:WriteLn('Golfe');
      Baie:WriteLn('Baie');
     End;
     Write(PadRight('Salinit‚ : ',20));
     Case Waters[J].Salinite of
      Douce:WriteLn('Douce');
      Sale:WriteLn('Sal‚');
     End;
    End;
   End;
  End;
 End;
END.