{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FindCity;

Uses Strings;

Const
 CityList:Array[0..258]of PChar=(
  'Abu Dhabi','Abuja','Accra','Achgabat','Adamstown','Addis-Abeba',
  'Alger','Alma','Alofi','Amman','Amsterdam','Andorre-la-Vieille',
  'Ankara','Antananarivo','Apia','Asmara','Astana','Asunci¢n',
  'AthŠnes','Avarua','Bagdad','Bakou','Bamako','Bandar Seri Begawan',
  'Bangkok','Bangui','Banjul','Basse-Terre','Basseterre','Belgrade',
  'Belmopan','Berlin','Berne','Beyrouth','Bissau','Bichkek',
  'Bogot ','Boston','Brasilia','Bratislava','Brazzaville',
  'Bridgetown','Bruxelles','Bucarest','Budapest','Buenos Aires',
  'Bujumbura','Canberra','Caracas','Castries','Cayenne',
  'Charlotte Amalie','Chibougamau','Chisinau','Cockburn Town',
  'Colombo','Conakry','Copenhague','Dacca','Dakar','Damas',
  'Djibouti','Djouba','Dili','Dodoma','Doha','Douchanb‚',
  'Douglas','Dublin','Erevan','Flying Fish Cove','Fort-de-France',
  'Freetown','Funafuti','Gaborone','George Town','Georgetown',
  'Gibraltar','Grytviken','Guatemala','Gustavia','Hag†t¤a',
  'Hamilton','Hano‹','Harare','Helsinki','Hong Kong','Honiara',
  'Islamabad','Jakarta','Jamestown','J‚rusalem','Kaboul',
  'Kampala','Khartoum','Katmandou','Kiev','Kigali','Kingston',
  'Kingstown','Kinshasa','Kowe‹t','Kralendijk','Kuala Lumpur',
  'Laƒyoune','Laval','La Havane','La Tuque','La Valette',
  'Le Caire','Libreville','Lilongwe','Lima','Lisbonne',
  'Ljubljana','Lom‚','Londres','Longueuil','Longyearbyen',
  'Los Angeles','Luanda','Lusaka','Luxembourg','Lyon','Macao',
  'Madrid','Malabo','Mal‚','Mamoudzou','Monaco','Managua',
  'Manama','Manille','Mariehamn','Majuro','Maputo','Marseille',
  'Mascate','Maseru','Mata-Utu','Mbabane','Melekeok',
  'Melekeok - Palau State Capital','Mexico','Minsk','Mogadiscio',
  'Monrovia','Montevideo','Montreal','Montr‚al','Moroni','Moscou',
  'Munich','Nairobi','Nassau','Nay Pyi Taw','Ndjamena','New Delhi',
  'New York','Niamey','Nicosie','Nouakchott','Noum‚a',
  'Nuku''alofa','Nuuk','Oranjestad','Oslo','Ottawa','Ouagadougou',
  'Oulan-Bator','Pago Pago','Palikir','Panam ','Papeete',
  'Paramaribo','Paris','P‚kin','Philipsburg','Phnom Penh','Plymouth',
  'Podgorica','Port-au-Prince','Port-Cartier','Port-d''Espagne',
  'Port-aux-Fran‡ais','Port-Louis','Port Moresby','Port Stanley',
  'Port-Vila','Porto Novo','Prague','Pretoria','Praia','Pristina',
  'Pyongyang','Qu‚bec','Quito','Rabat','Reykjav¡k','Riga',
  'Rio de Janeiro','Riyad','Road Town','Rome','Roseau','Saint-Denis',
  'Saint John''s','Saint-Georges','Saint Helier','Saint-Marin',
  'Saint-Pierre','Saint-Pierre-Port','Saipan','Sanaa','San Francisco',
  'San Juan','San Jos‚','San Salvador','Santo Domingo',
  'Santiago du Chili','Sao Tom‚','Sarajevo','S‚oul','Sept-Iles',
  'Singapour','Skopje','Sofia','Stockholm','Sucre','Suva','Tachkent',
  'Tallinn','Taipei','Tarawa-Sud','Tbilissi','Tegucigalpa','T‚h‚ran',
  'Thimphou','Tirana','Tokyo','T¢rshavn','Tripoli','Tunis','Vaduz',
  'Varsovie','Vatican City','Victoria','Vienne','Vientiane','Vilnius',
  'Washington','Wellington','West Island','Willemstad','Windhoek',
  'Yamoussoukro','Yaound‚','Yaren','Zagreb'
 );

Var
 LineNumber:LongInt;
 Option:Set of (_Lines);
 BeginWord,I,J:Integer;
 FoundMultiWord:Boolean;
 SourceFile:Text;
 FileName,CurrLine,CurrWord:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function IsLetter(Chr:Char):Boolean;Begin
 IsLetter:=Chr in ['A'..'Z','a'..'z','‚','ˆ','Š','…','ƒ','“','‡'];
End;

Procedure CompileWord;
Var
 I:Integer;
Begin
 For I:=Low(CityList) to High(CityList) do Begin
  If StrToUpper(StrPas(CityList[I]))=StrToUpper(CurrWord)Then Begin
   If FileName<>''Then Begin
    If(_Lines in Option)Then Begin
     WriteLn('Ville trouve dans la ligne numero ',LineNumber,' :');
    End;
   End;
   WriteLn(StrPas(CityList[I]));
   Exit;
  End;
 End;
End;

Procedure ParseLineDetectCity;
Var
 J:Integer;
Begin
 CurrWord:='';
 BeginWord:=1;
 For I:=1 to Length(CurrLine)do Begin
  If(IsLetter(CurrLine[I]))Then CurrWord:=CurrWord+CurrLine[I]
   Else
  Begin
   FoundMultiWord:=False;
   For J:=Low(CityList) to High(CityList) do Begin
    If(StrLen(CityList[J])>Length(CurrWord))and
      (StrToUpper(StrPas(CityList[J]))=
      StrToUpper(Copy(CurrLine,BeginWord,StrLen(CityList[J]))))Then Begin
     FoundMultiWord:=True;
     Break;
    End;
   End;
   If(FoundMultiWord)Then Begin
    CurrWord:=CurrWord+CurrLine[I]
   End
    Else
   Begin
    CompileWord;
    CurrWord:='';
    BeginWord:=I+1;
   End;
  End;
 End;
 CompileWord;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('FINDCITY : Cette commande permet de detecter les villes ',
                      'mentionne un texte.');
  WriteLn;
  WriteLn('Syntaxe : FINDCITY "message"');
  WriteLn('          FINCCITY /FILE:fichier [/LINES]');
  WriteLn;
  WriteLn(' /FILE:  Ce parametre permet d''indiquer le fichier a analyser');
  WriteLn(' /LINES  Ce parametre permet d''afficher le numero de ligne');
 End
  Else
 Begin
  Option:=[];
  LineNumber:=0;
  FileName:='';
  CurrLine:='';
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/LINES'Then Include(Option,_Lines);
   If StrToUpper(Copy(ParamStr(I),1,6))='/FILE:'Then Begin
    FileName:=Copy(ParamStr(I),7,255);
   End
    Else
   Begin
    If CurrLine=''Then CurrLine:=ParamStr(I)
                  Else CurrLine:=CurrLine+' '+ParamStr(I);
   End;
  End;
  If FileName<>''Then Begin
    Assign(SourceFile,FileName);
    Reset(SourceFile);
    While Not EOF(SourceFile)do Begin
     Inc(LineNumber);
     ReadLn(SourceFile,CurrLine);
     ParseLineDetectCity;
    End;
    Close(SourceFile);
   End
    Else
   ParseLineDetectCity;
 End;
END.
