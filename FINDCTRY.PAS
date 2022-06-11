{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FindCtry;

Uses Strings;

Const
 CountryList:Array[0..248]of PChar=(
  'Afghanistan','Afrique du sud','Albanie','Alg‚rie','Allemagne',
  'Andorre','Angola','Anguilla','Antarctique','Antigua et Barbuda',
  'Arabie saoudite','Argentine','Arm‚nie','Aruba','Australie',
  'Autriche','Azerbaidjan','Bahamas','Bahrein','Bangladesh',
  'Barbade','Belgique','Belize','Benin','Bermudes','Bhutan',
  'Bi‚lorussie','Bonaire','Bosnie-Herzegovine','Botswana','Br‚sil',
  'Brunei Darussalam','Bulgarie','Burkina Faso','Burundi','Cambodge',
  'Cameroun','Canada','Cap-Vert','Centrafrique','Chili','Chine',
  'Chypre','Colombie','Comores','Congo-Brazzaville','Cor‚e du Nord',
  'Cor‚e du Sud','Costa Rica','Cote d''Ivoire','Croatie','Cuba',
  'Curacao','Danemark','Djibouti','Dominique','Egypte',
  'Emirats arabes unis','Equateur','Erythr‚e','Espagne',
  'Estonie','Etats-Unis','Ethiopie','Fidji','Finlande','France',
  'Gabon','Gambie','Georgie','Georgie du Sud','Ghana','Gibraltar',
  'GrŠce','Grenade','Groenland','Guadeloupe','Guam','Guatemala',
  'Guernesey','Guin‚e','Guin‚e equatoriale','Guin‚e-Bissau',
  'Guyana','Guyane','Ha‹ti','Honduras','Hong Kong','Hongrie',
  'Ile Bouvet','Ile Christmas','Ile de Man','Ile Heard','Ile Norfolk',
  'Iles Aland','Iles Caimans','Iles Cocos','Iles Cook','Iles Feroe',
  'Iles Malouines','Iles Mariannes du Nord','Iles Marshall',
  'Iles mineures','Iles Salomon','Iles Turques-et-Caiques','Iles Vierges',
  'Iles Vierges des Etats-Unis','Inde','Indon‚sie','Irak','Iran',
  'Irlande','Islande','Isra‰l','Italie','Jamaique','Japon','Jersey',
  'Jordanie','Kazakhstan','Kenya','Kirghizistan','Kiribati',
  'Kosovo','Koweit','Laos','Lesotho','Lettonie','Liban','Liberia',
  'Libye','Liechtenstein','Lituanie','Luxembourg','Macao','Macedoine',
  'Madagascar','Malaisie','Malawi','Maldives','Mali','Malte',
  'Maroc','Martinique','Maurice','Mauritanie','Mayotte','Mexique',
  'Micronesie','Moldavie','Monaco','Mongolie','Montenegro',
  'Montserrat','Mozambique','Myanmar','Namibie','Nauru','N‚pal',
  'Nicaragua','Niger','Nigeria','Nig‚ria','Nioue','NorvŠge',
  'Nouvelle-Caledonie','Nouvelle-Z‚lande','Oman','Ouganda',
  'Ouzb‚kistan','Pakistan','Palaos','Panama','Papouasie-Nouvelle Guin‚e',
  'Paraguay','Pays-Bas','P‚rou','Philippines','Pitcairn','Pologne',
  'Polynesie Francaise','Porto Rico','Portugal','Qatar',
  'R‚publique d‚mocratique du congo','R‚publique Dominicaine',
  'R‚publique Togolaise','Reunion','Roumanie','Royaume-Uni','Russie',
  'Rwanda','Sahara Occidental','Saint-Barthelemy',
  'Saint-Christophe-et-Nieves','Saint-Marin','Saint-Martin',
  'Saint-Pierre et Miquelon','Saint-Vincent-et-les Grenadines',
  'Sainte-Helene','Sainte-Lucie','Salvador','Samoa',
  'Samoa americaines','Sao Tome-et-Principe','S‚n‚gal','Serbie',
  'Seychelles','Sierra Leone','Singapour','Slovaquie','Slovenie',
  'Somalie','Soudan','Sri Lanka','Sud-Soudan','Suede','Suisse',
  'Surinam','Svalbard et Ile Jan Mayen','Swaziland','Syrie',
  'Tadjikistan','Ta‹wan','Tanzanie','Tchad','Tchequie',
  'Terres australes fran‡aises','Territoire britannique de l''oc‚an Indien',
  'Territoire palestinien','Tha‹lande','Timor Oriental','Tokelau',
  'Tonga','Trinidad et Tobago','Tunisie','Turkmenistan','Turquie',
  'Tuvalu','Ukraine','Uruguay','Vanuatu','Vatican','Venezuela',
  'Vietnam','Wallis-et-Futuna','Y‚men','Zambie','Zimbabwe'
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
 For I:=Low(CountryList) to High(CountryList) do Begin
  If StrToUpper(StrPas(CountryList[I]))=StrToUpper(CurrWord)Then Begin
   If FileName<>''Then Begin
    If(_Lines in Option)Then Begin
     WriteLn('Pays trouve dans la ligne numero ',LineNumber,' :');
    End;
   End;
   WriteLn(StrPas(CountryList[I]));
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
   For J:=Low(CountryList) to High(CountryList) do Begin
    If(StrLen(CountryList[J])>Length(CurrWord))and
      (StrToUpper(StrPas(CountryList[J]))=
      StrToUpper(Copy(CurrLine,BeginWord,StrLen(CountryList[J]))))Then Begin
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
  WriteLn('FINDCTRY : Cette commande permet de detecter les pays ',
                      'mentionne dans un texte.');
  WriteLn;
  WriteLn('Syntaxe : FINDCTRY "message"');
  WriteLn('          FINCCTRY /FILE:fichier [/LINES]');
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

