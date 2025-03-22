{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program MONTAIN;

Type
 Montagne=Record
  Nom:String[30];
  Continent: string[10];
  Hauteur:Integer;
 End;

Const
 Montagnes: array[1..40] of Montagne = (
  (Nom:'Everest'; Continent: 'Asie';Hauteur:8848),
  (Nom:'K2'; Continent: 'Asie'; Hauteur: 8611),
  (Nom:'Kangchenjunga'; Continent: 'Asie'; Hauteur: 8586),
  (Nom:'Lhotse'; Continent: 'Asie'; Hauteur: 8516),
  (Nom:'Makalu'; Continent: 'Asie'; Hauteur: 8485),
  (Nom:'Cho Oyu'; Continent: 'Asie'; Hauteur: 8201),
  (Nom:'Dhaulagiri I'; Continent: 'Asie'; Hauteur: 8167),
  (Nom:'Manaslu'; Continent: 'Asie'; Hauteur: 8163),
  (Nom:'Nanga Parbat'; Continent: 'Asie'; Hauteur: 8125),
  (Nom:'Annapurna I'; Continent: 'Asie'; Hauteur: 8091),
  (Nom:'Gasherbrum I'; Continent: 'Asie'; Hauteur: 8080),
  (Nom:'Broad Peak'; Continent: 'Asie'; Hauteur: 8047),
  (Nom:'Gasherbrum II'; Continent: 'Asie'; Hauteur: 8035),
  (Nom:'Shishapangma'; Continent: 'Asie'; Hauteur: 8027),
  (Nom:'Gyachung Kang'; Continent: 'Asie'; Hauteur: 7952),
  (Nom:'Himalchuli'; Continent: 'Asie'; Hauteur: 7893),
  (Nom:'Distaghil Sar'; Continent: 'Asie'; Hauteur: 7885),
  (Nom:'Rakaposhi'; Continent: 'Asie'; Hauteur: 7788),
  (Nom:'Jannu'; Continent: 'Asie'; Hauteur: 7710),
  (Nom:'Tirich Mir'; Continent: 'Asie'; Hauteur: 7708),
  (Nom:'McKinley'; Continent: 'AmÇrique du Nord'; Hauteur: 6190),
  (Nom:'Elbrus'; Continent: 'Europe'; Hauteur: 5642),
  (Nom:'Kilimanjaro'; Continent: 'Afrique'; Hauteur: 5895),
  (Nom:'Vinson'; Continent: 'Antarctique'; Hauteur: 4892),
  (Nom:'Aconcagua'; Continent: 'AmÇrique du Sud'; Hauteur: 6961),
  (Nom:'St. Elias'; Continent: 'AmÇrique du Nord'; Hauteur: 5489),
  (Nom:'PopocatÇpetl'; Continent: 'AmÇrique du Nord'; Hauteur: 5452),
  (Nom:'Fuji'; Continent: 'Asie'; Hauteur: 3776),
  (Nom:'Kosciuszko'; Continent: 'OcÇanie'; Hauteur: 2228),
  (Nom:'Blanc'; Continent: 'Europe'; Hauteur: 4807),
  (Nom:'Erebus'; Continent: 'Antarctique'; Hauteur: 3794),
  (Nom:'Mountain'; Continent: 'Afrique'; Hauteur: 1086),
  (Nom:'Vesuvius'; Continent: 'Europe'; Hauteur: 1281),
  (Nom:'Taranaki'; Continent: 'OcÇanie'; Hauteur: 2518),
  (Nom:'Puncak Jaya'; Continent: 'OcÇanie'; Hauteur: 4884),
  (Nom:'McGinnis'; Continent: 'AmÇrique du Nord'; Hauteur: 3965),
  (Nom:'Hood'; Continent: 'AmÇrique du Nord'; Hauteur: 3426),
  (Nom:'Etna'; Continent: 'Europe'; Hauteur: 3329),
  (Nom:'Ararat'; Continent: 'Asie'; Hauteur: 5137),
  (Nom:'Mauna Kea'; Continent: 'OcÇanie'; Hauteur: 4207)
 );

Var
 i:Integer;
 MontagneParam:String;
 Found:Boolean;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I]in['ê','Ç','ä','à',#232,#233,#234]Then S[I]:='E'Else
  If S[I]in['å',#238]Then S[I]:='I'Else
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('MONTAIN : Cette commande permet de retourner ',
          'les informations sur la montagne spÇcifiÇ');
  WriteLn;
  Writeln('Syntaxe: MONTAIN nom');
  WriteLn;
  WriteLn(' nom  Ce paramätre permet d''indiquer le nom de la montagne.');
 End
  Else
 If ParamCount>0Then Begin
  MontagneParam:=StrToUpper(ParamStr(1));
  Found:=False;
  For i:=1 to High(Montagnes) do Begin
   If StrToUpper(Montagnes[i].Nom)=StrToUpper(MontagneParam)Then Begin
    WriteLn('Nom de la montagne : ', Montagnes[i].Nom);
    WriteLn('Continent : ', Montagnes[i].Continent);
    WriteLn('Hauteur : ', Montagnes[i].Hauteur, ' mätres');
    Found:=True;
    Break;
   End;
  End;
  If Not(Found)Then Writeln('Montagne non trouvÇ');
 End
  Else
 WriteLn('Paramätre requis !');
END.
