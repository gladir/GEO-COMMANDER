{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DOMAIN;

Uses Strings;

Type
 CountryGeoRecord=Record
  Country:PChar;
  Latitude,LatiDeg:Byte;
  LatiDirection:Char;
  Longitude,LongDeg:Byte;
  LongDirection:Char;
  Superficie:LongInt; { Km2 }
  Capital:PChar;
  Domain:PChar; { Extension de nom de domaine }
 End;

Const
 Country:Array[0..248]of CountryGeoRecord=(
  (Country:       'Afghanistan';
   Latitude:      33;
   LatiDeg:       55;
   LatiDirection: 'N';
   Longitude:     67;
   LongDeg:       40;
   LongDirection: 'E';
   Superficie:    647500;
   Capital:       'Kaboul';
   Domain:        '.af'
  ),
  (Country:       'Afrique du sud';
   Latitude:      28;
   LatiDeg:       28;
   LatiDirection: 'S';
   Longitude:     24;
   LongDeg:       40;
   LongDirection: 'E';
   Superficie:    1219912;
   Capital:       'Pretoria';
   Domain:        '.za'
  ),
  (Country:       'Albanie';
   Latitude:      41;
   LatiDeg:       9;
   LatiDirection: 'N';
   Longitude:     20;
   LongDeg:       10;
   LongDirection: 'E';
   Superficie:    28748;
   Capital:       'Tirana';
   Domain:        '.al'
  ),
  (Country:       'Algerie';
   Latitude:      28;
   LatiDeg:       1;
   LatiDirection: 'N';
   Longitude:     1;
   LongDeg:       39;
   LongDirection: 'E';
   Superficie:    2381740;
   Capital:       'Alger';
   Domain:        '.dz'
  ),
  (Country:       'Allemagne';
   Latitude:      51;
   LatiDeg:       9;
   LatiDirection: 'N';
   Longitude:     10;
   LongDeg:       27;
   LongDirection: 'E';
   Superficie:    357021;
   Capital:       'Berlin';
   Domain:        '.de'
  ),
  (Country:       'Andorre';
   Latitude:      42;
   LatiDeg:       32;
   LatiDirection: 'N';
   Longitude:     1;
   LongDeg:       35;
   LongDirection: 'E';
   Superficie:    468;
   Capital:       'Andorre-la-Vieille';
   Domain:        '.ad'
  ),
  (Country:       'Angola';
   Latitude:      11;
   LatiDeg:       12;
   LatiDirection: 'S';
   Longitude:     17;
   LongDeg:       52;
   LongDirection: 'E';
   Superficie:    1246700;
   Capital:       'Luanda';
   Domain:        '.ao'
  ),
  (Country:       'Anguilla';
   Latitude:      18;
   LatiDeg:       13;
   LatiDirection: 'N';
   Longitude:     63;
   LongDeg:       4;
   LongDirection: 'O';
   Superficie:    102;
   Capital:       'The Valley';
   Domain:        '.ai'
  ),
  (Country:       'Antarctique';
   Latitude:      75;
   LatiDeg:       15;
   LatiDirection: 'S';
   Longitude:     0;
   LongDeg:       0;
   LongDirection: 'E';
   Superficie:    14000000;
   Capital:       '';
   Domain:        '.aq'
  ),
  (Country:       'Antigua et Barbuda';
   Latitude:      17;
   LatiDeg:       21;
   LatiDirection: 'N';
   Longitude:     61;
   LongDeg:       47;
   LongDirection: 'O';
   Superficie:    443;
   Capital:       'Saint John''s';
   Domain:        '.ag'
  ),
  (Country:       'Arabie saoudite';
   Latitude:      23;
   LatiDeg:       53;
   LatiDirection: 'N';
   Longitude:     45;
   LongDeg:       4;
   LongDirection: 'E';
   Superficie:    1960582;
   Capital:       'Riyad';
   Domain:        '.sa'
  ),
  (Country:       'Argentine';
   Latitude:      38;
   LatiDeg:       25;
   LatiDirection: 'S';
   Longitude:     63;
   LongDeg:       35;
   LongDirection: 'O';
   Superficie:    2766890;
   Capital:       'Buenos Aires';
   Domain:        '.ar'
  ),
  (Country:       'Armenie';
   Latitude:      40;
   LatiDeg:       3;
   LatiDirection: 'N';
   Longitude:     45;
   LongDeg:       6;
   LongDirection: 'E';
   Superficie:    29800;
   Capital:       'Erevan';
   Domain:        '.am'
  ),
  (Country:       'Aruba';
   Latitude:      12;
   LatiDeg:       31;
   LatiDirection: 'N';
   Longitude:     69;
   LongDeg:       57;
   LongDirection: 'O';
   Superficie:    193;
   Capital:       'Oranjestad';
   Domain:        '.aw'
  ),
  (Country:       'Australie';
   Latitude:      26;
   LatiDeg:       51;
   LatiDirection: 'S';
   Longitude:     133;
   LongDeg:       16;
   LongDirection: 'E';
   Superficie:    7686850;
   Capital:       'Canberra';
   Domain:        '.au'
  ),
  (Country:       'Autriche';
   Latitude:      47;
   LatiDeg:       41;
   LatiDirection: 'N';
   Longitude:     13;
   LongDeg:       20;
   LongDirection: 'E';
   Superficie:    83858;
   Capital:       'Vienne';
   Domain:        '.at'
  ),
  (Country:       'Azerbaidjan';
   Latitude:      40;
   LatiDeg:       8;
   LatiDirection: 'N';
   Longitude:     47;
   LongDeg:       34;
   LongDirection: 'E';
   Superficie:    86600;
   Capital:       'Bakou';
   Domain:        '.az'
  ),
  (Country:       'Bahamas';
   Latitude:      24;
   LatiDeg:       53;
   LatiDirection: 'N';
   Longitude:     76;
   LongDeg:       42;
   LongDirection: 'O';
   Superficie:    13940;
   Capital:       'Nassau';
   Domain:        '.bs'
  ),
  (Country:       'Bahrein';
   Latitude:      26;
   LatiDeg:       2;
   LatiDirection: 'N';
   Longitude:     50;
   LongDeg:       33;
   LongDirection: 'E';
   Superficie:    665;
   Capital:       'Manama';
   Domain:        '.bh'
  ),
  (Country:       'Bangladesh';
   Latitude:      23;
   LatiDeg:       41;
   LatiDirection: 'N';
   Longitude:     90;
   LongDeg:       21;
   LongDirection: 'E';
   Superficie:    144000;
   Capital:       'Dacca';
   Domain:        '.bd'
  ),
  (Country:       'Barbade';
   Latitude:      13;
   LatiDeg:       11;
   LatiDirection: 'N';
   Longitude:     59;
   LongDeg:       32;
   LongDirection: 'O';
   Superficie:    431;
   Capital:       'Bridgetown';
   Domain:        '.bb'
  ),
  (Country:       'Belgique';
   Latitude:      50;
   LatiDeg:       29;
   LatiDirection: 'N';
   Longitude:     4;
   LongDeg:       28;
   LongDirection: 'E';
   Superficie:    30510;
   Capital:       'Bruxelles';
   Domain:        '.be'
  ),
  (Country:       'Belize';
   Latitude:      17;
   LatiDeg:       11;
   LatiDirection: 'N';
   Longitude:     88;
   LongDeg:       30;
   LongDirection: 'O';
   Superficie:    22966;
   Capital:       'Belmopan';
   Domain:        '.bz'
  ),
  (Country:       'Benin';
   Latitude:      9;
   LatiDeg:       19;
   LatiDirection: 'N';
   Longitude:     2;
   LongDeg:       18;
   LongDirection: 'E';
   Superficie:    112620;
   Capital:       'Porto Novo';
   Domain:        '.bj'
  ),
  (Country:       'Bermudes';
   Latitude:      32;
   LatiDeg:       19;
   LatiDirection: 'N';
   Longitude:     64;
   LongDeg:       46;
   LongDirection: 'O';
   Superficie:    53;
   Capital:       'Hamilton';
   Domain:        '.bm'
  ),
  (Country:       'Bhutan';
   Latitude:      27;
   LatiDeg:       30;
   LatiDirection: 'N';
   Longitude:     90;
   LongDeg:       26;
   LongDirection: 'E';
   Superficie:    47000;
   Capital:       'Thimphou';
   Domain:        '.bt'
  ),
  (Country:       'Bielorussie';
   Latitude:      53;
   LatiDeg:       42;
   LatiDirection: 'N';
   Longitude:     27;
   LongDeg:       58;
   LongDirection: 'E';
   Superficie:    207600;
   Capital:       'Minsk';
   Domain:        '.by'
  ),
  (Country:       'Bolivie';
   Latitude:      16;
   LatiDeg:       17;
   LatiDirection: 'S';
   Longitude:     63;
   LongDeg:       32;
   LongDirection: 'O';
   Superficie:    1098580;
   Capital:       'Sucre';
   Domain:        '.bo'
  ),
  (Country:       'Bonaire';
   Latitude:      12;
   LatiDeg:       9;
   LatiDirection: 'N';
   Longitude:     68;
   LongDeg:       18;
   LongDirection: 'O';
   Superficie:    322;
   Capital:       'Kralendijk';
   Domain:        ''
  ),
  (Country:       'Bosnie-Herzegovine';
   Latitude:      43;
   LatiDeg:       53;
   LatiDirection: 'N';
   Longitude:     17;
   LongDeg:       40;
   LongDirection: 'E';
   Superficie:    51129;
   Capital:       'Sarajevo';
   Domain:        '.ba'
  ),
  (Country:       'Botswana';
   Latitude:      22;
   LatiDeg:       20;
   LatiDirection: 'S';
   Longitude:     24;
   LongDeg:       40;
   LongDirection: 'E';
   Superficie:    600370;
   Capital:       'Gaborone';
   Domain:        '.bw'
  ),
  (Country:       'Bresil';
   Latitude:      14;
   LatiDeg:       14;
   LatiDirection: 'S';
   Longitude:     53;
   LongDeg:       11;
   LongDirection: 'O';
   Superficie:    8511965;
   Capital:       'Brasilia';
   Domain:        '.br'
  ),
  (Country:       'Brunei Darussalam';
   Latitude:      4;
   LatiDeg:       31;
   LatiDirection: 'N';
   Longitude:     114;
   LongDeg:       42;
   LongDirection: 'E';
   Superficie:    5770;
   Capital:       'Bandar Seri Begawan';
   Domain:        '.bn'
  ),
  (Country:       'Bulgarie';
   Latitude:      42;
   LatiDeg:       43;
   LatiDirection: 'N';
   Longitude:     25;
   LongDeg:       29;
   LongDirection: 'E';
   Superficie:    110910;
   Capital:       'Sofia';
   Domain:        '.bg'
  ),
  (Country:       'Burkina Faso';
   Latitude:      12;
   LatiDeg:       14;
   LatiDirection: 'N';
   Longitude:     1;
   LongDeg:       33;
   LongDirection: 'O';
   Superficie:    274200;
   Capital:       'Ouagadougou';
   Domain:        '.bf'
  ),
  (Country:       'Burundi';
   Latitude:      3;
   LatiDeg:       23;
   LatiDirection: 'S';
   Longitude:     29;
   LongDeg:       55;
   LongDirection: 'E';
   Superficie:    27830;
   Capital:       'Bujumbura';
   Domain:        '.bi'
  ),
  (Country:       'Cambodge';
   Latitude:      12;
   LatiDeg:       32;
   LatiDirection: 'N';
   Longitude:     104;
   LongDeg:       59;
   LongDirection: 'E';
   Superficie:    181040;
   Capital:       'Cambodge';
   Domain:        '.kh'
  ),
  (Country:       'Cameroun';
   Latitude:      7;
   LatiDeg:       21;
   LatiDirection: 'N';
   Longitude:     12;
   LongDeg:       20;
   LongDirection: 'E';
   Superficie:    475440;
   Capital:       'Yaound‚';
   Domain:        '.cm'
  ),
  (Country:       'Canada';
   Latitude:      62;
   LatiDeg:       23;
   LatiDirection: 'N';
   Longitude:     96;
   LongDeg:       49;
   LongDirection: 'O';
   Superficie:    9984670;
   Capital:       'Ottawa';
   Domain:        '.ca'
  ),
  (Country:       'Cap-Vert';
   Latitude:      16;
   LatiDeg:       0;
   LatiDirection: 'N';
   Longitude:     24;
   LongDeg:       0;
   LongDirection: 'O';
   Superficie:    4033;
   Capital:       'Praia';
   Domain:        '.cv'
  ),
  (Country:       'Centrafrique';
   Latitude:      6;
   LatiDeg:       36;
   LatiDirection: 'N';
   Longitude:     20;
   LongDeg:       56;
   LongDirection: 'E';
   Superficie:    622984;
   Capital:       'Bangui';
   Domain:        '.cf'
  ),
  (Country:       'Chili';
   Latitude:      36;
   LatiDeg:       42;
   LatiDirection: 'S';
   Longitude:     73;
   LongDeg:       36;
   LongDirection: 'O';
   Superficie:    756950;
   Capital:       'Santiago du Chili';
   Domain:        '.cl'
  ),
  (Country:       'Chine';
   Latitude:      34;
   LatiDeg:       40;
   LatiDirection: 'N';
   Longitude:     104;
   LongDeg:       9;
   LongDirection: 'E';
   Superficie:    9596960;
   Capital:       'P‚kin';
   Domain:        '.cn'
  ),
  (Country:       'Chypre';
   Latitude:      35;
   LatiDeg:       10;
   LatiDirection: 'N';
   Longitude:     33;
   LongDeg:       26;
   LongDirection: 'E';
   Superficie:    9250;
   Capital:       'Nicosie';
   Domain:        '.cy'
  ),
  (Country:       'Colombie';
   Latitude:      4;
   LatiDeg:       34;
   LatiDirection: 'N';
   Longitude:     74;
   LongDeg:       17;
   LongDirection: 'O';
   Superficie:    1138910;
   Capital:       'Bogot ';
   Domain:        '.co'
  ),
  (Country:       'Comores';
   Latitude:      11;
   LatiDeg:       52;
   LatiDirection: 'S';
   Longitude:     43;
   LongDeg:       52;
   LongDirection: 'E';
   Superficie:    2170;
   Capital:       'Moroni';
   Domain:        '.km'
  ),
  (Country:       'Congo-Brazzaville';
   Latitude:      0;
   LatiDeg:       39;
   LatiDirection: 'S';
   Longitude:     14;
   LongDeg:       55;
   LongDirection: 'E';
   Superficie:    342000;
   Capital:       'Brazzaville';
   Domain:        '.cd'
  ),
  (Country:       'Coree du Nord';
   Latitude:      40;
   LatiDeg:       20;
   LatiDirection: 'N';
   Longitude:     127;
   LongDeg:       29;
   LongDirection: 'E';
   Superficie:    120540;
   Capital:       'Pyongyang';
   Domain:        '.kp'
  ),
  (Country:       'Coree du Sud';
   Latitude:      35;
   LatiDeg:       54;
   LatiDirection: 'N';
   Longitude:     127;
   LongDeg:       44;
   LongDirection: 'E';
   Superficie:    98480;
   Capital:       'S‚oul';
   Domain:        '.kr'
  ),
  (Country:       'Costa Rica';
   Latitude:      9;
   LatiDeg:       37;
   LatiDirection: 'N';
   Longitude:     84;
   LongDeg:       15;
   LongDirection: 'O';
   Superficie:    51100;
   Capital:       'San Jos‚';
   Domain:        '.cr'
  ),
  (Country:       'Cote d''Ivoire';
   Latitude:      7;
   LatiDeg:       32;
   LatiDirection: 'N';
   Longitude:     5;
   LongDeg:       32;
   LongDirection: 'O';
   Superficie:    322460;
   Capital:       'Yamoussoukro';
   Domain:        '.ci'
  ),
  (Country:       'Croatie';
   Latitude:      44;
   LatiDeg:       29;
   LatiDirection: 'N';
   Longitude:     16;
   LongDeg:       27;
   LongDirection: 'E';
   Superficie:    56542;
   Capital:       'Zagreb';
   Domain:        '.hr'
  ),
  (Country:       'Cuba';
   Latitude:      21;
   LatiDeg:       31;
   LatiDirection: 'N';
   Longitude:     79;
   LongDeg:       32;
   LongDirection: 'O';
   Superficie:    110860;
   Capital:       'La Havane';
   Domain:        '.cu'
  ),
  (Country:       'Curacao';
   Latitude:      12;
   LatiDeg:       12;
   LatiDirection: 'N';
   Longitude:     68;
   LongDeg:       56;
   LongDirection: 'O';
   Superficie:    444;
   Capital:       'Willemstad';
   Domain:        '.cw'
  ),
  (Country:       'Danemark';
   Latitude:      56;
   LatiDeg:       9;
   LatiDirection: 'N';
   Longitude:     11;
   LongDeg:       37;
   LongDirection: 'E';
   Superficie:    43094;
   Capital:       'Copenhague';
   Domain:        '.dk'
  ),
  (Country:       'Djibouti';
   Latitude:      11;
   LatiDeg:       48;
   LatiDirection: 'N';
   Longitude:     42;
   LongDeg:       35;
   LongDirection: 'E';
   Superficie:    23000;
   Capital:       'Djibouti';
   Domain:        '.dj'
  ),
  (Country:       'Dominique';
   Latitude:      15;
   LatiDeg:       25;
   LatiDirection: 'N';
   Longitude:     61;
   LongDeg:       21;
   LongDirection: 'O';
   Superficie:    754;
   Capital:       'Roseau';
   Domain:        '.dm'
  ),
  (Country:       'Egypte';
   Latitude:      26;
   LatiDeg:       41;
   LatiDirection: 'N';
   Longitude:     30;
   LongDeg:       14;
   LongDirection: 'E';
   Superficie:    1001450;
   Capital:       'Le Caire';
   Domain:        '.eg'
  ),
  (Country:       'Emirats arabes unis';
   Latitude:      24;
   LatiDeg:       21;
   LatiDirection: 'N';
   Longitude:     53;
   LongDeg:       58;
   LongDirection: 'E';
   Superficie:    82880;
   Capital:       'Abu Dhabi';
   Domain:        '.ae'
  ),
  (Country:       'Equateur';
   Latitude:      1;
   LatiDeg:       46;
   LatiDirection: 'S';
   Longitude:     78;
   LongDeg:       7;
   LongDirection: 'O';
   Superficie:    283560;
   Capital:       'Quito';
   Domain:        '.ec'
  ),
  (Country:       'Erythree';
   Latitude:      15;
   LatiDeg:       10;
   LatiDirection: 'N';
   Longitude:     39;
   LongDeg:       47;
   LongDirection: 'E';
   Superficie:    121320;
   Capital:       'Asmara';
   Domain:        '.er'
  ),
  (Country:       'Espagne';
   Latitude:      39;
   LatiDeg:       53;
   LatiDirection: 'N';
   Longitude:     2;
   LongDeg:       29;
   LongDirection: 'O';
   Superficie:    504782;
   Capital:       'Madrid';
   Domain:        '.es'
  ),
  (Country:       'Estonie';
   Latitude:      58;
   LatiDeg:       35;
   LatiDirection: 'N';
   Longitude:     25;
   LongDeg:       1;
   LongDirection: 'E';
   Superficie:    45226;
   Capital:       'Tallinn';
   Domain:        '.ee'
  ),
  (Country:       'Etats-Unis';
   Latitude:      36;
   LatiDeg:       57;
   LatiDirection: 'N';
   Longitude:     95;
   LongDeg:       50;
   LongDirection: 'O';
   Superficie:    9629091;
   Capital:       'Washington';
   Domain:        '.us'
  ),
  (Country:       'Ethiopie';
   Latitude:      9;
   LatiDeg:       8;
   LatiDirection: 'N';
   Longitude:     40;
   LongDeg:       29;
   LongDirection: 'E';
   Superficie:    1127127;
   Capital:       'Addis-Abeba';
   Domain:        '.et'
  ),
  (Country:       'Fidji';
   Latitude:      16;
   LatiDeg:       34;
   LatiDirection: 'S';
   Longitude:     179;
   LongDeg:       21;
   LongDirection: 'E';
   Superficie:    18270;
   Capital:       'Suva';
   Domain:        '.fj'
  ),
  (Country:       'Finlande';
   Latitude:      64;
   LatiDeg:       57;
   LatiDirection: 'N';
   Longitude:     26;
   LongDeg:       4;
   LongDirection: 'E';
   Superficie:    337030;
   Capital:       'Helsinki';
   Domain:        '.fi'
  ),
  (Country:       'France';
   Latitude:      46;
   LatiDeg:       13;
   LatiDirection: 'N';
   Longitude:     2;
   LongDeg:       12;
   LongDirection: 'E';
   Superficie:    643801;
   Capital:       'Paris';
   Domain:        '.fr'
  ),
  (Country:       'Gabon';
   Latitude:      0;
   LatiDeg:       49;
   LatiDirection: 'S';
   Longitude:     11;
   LongDeg:       35;
   LongDirection: 'E';
   Superficie:    267667;
   Capital:       'Libreville';
   Domain:        '.ga'
  ),
  (Country:       'Gambie';
   Latitude:      13;
   LatiDeg:       26;
   LatiDirection: 'N';
   Longitude:     15;
   LongDeg:       18;
   LongDirection: 'O';
   Superficie:    11300;
   Capital:       'Banjul';
   Domain:        '.gm'
  ),
  (Country:       'Georgie';
   Latitude:      42;
   LatiDeg:       19;
   LatiDirection: 'N';
   Longitude:     43;
   LongDeg:       22;
   LongDirection: 'E';
   Superficie:    69700;
   Capital:       'Tbilissi';
   Domain:        '.ge'
  ),
  (Country:       'Georgie du Sud';
   Latitude:      56;
   LatiDeg:       43;
   LatiDirection: 'S';
   Longitude:     32;
   LongDeg:       7;
   LongDirection: 'O';
   Superficie:    3903;
   Capital:       'Grytviken';
   Domain:        '.gs'
  ),
  (Country:       'Ghana';
   Latitude:      7;
   LatiDeg:       57;
   LatiDirection: 'N';
   Longitude:     1;
   LongDeg:       1;
   LongDirection: 'O';
   Superficie:    239460;
   Capital:       'Accra';
   Domain:        '.gh'
  ),
  (Country:       'Gibraltar';
   Latitude:      36;
   LatiDeg:       7;
   LatiDirection: 'N';
   Longitude:     5;
   LongDeg:       21;
   LongDirection: 'O';
   Superficie:    7;
   Capital:       'Gibraltar';
   Domain:        '.gi'
  ),
  (Country:       'Grece';
   Latitude:      38;
   LatiDeg:       16;
   LatiDirection: 'N';
   Longitude:     23;
   LongDeg:       48;
   LongDirection: 'E';
   Superficie:    131940;
   Capital:       'AthŠnes';
   Domain:        '.gr'
  ),
  (Country:       'Grenade';
   Latitude:      12;
   LatiDeg:       9;
   LatiDirection: 'N';
   Longitude:     61;
   LongDeg:       41;
   LongDirection: 'O';
   Superficie:    344;
   Capital:       'Saint-Georges';
   Domain:        '.gd'
  ),
  (Country:       'Groenland';
   Latitude:      71;
   LatiDeg:       42;
   LatiDirection: 'N';
   Longitude:     42;
   LongDeg:       10;
   LongDirection: 'O';
   Superficie:    2166086;
   Capital:       'Nuuk';
   Domain:        '.gl'
  ),
  (Country:       'Guadeloupe';
   Latitude:      16;
   LatiDeg:       11;
   LatiDirection: 'N';
   Longitude:     61;
   LongDeg:       16;
   LongDirection: 'O';
   Superficie:    1780;
   Capital:       'Basse-Terre';
   Domain:        '.gp'
  ),
  (Country:       'Guam';
   Latitude:      13;
   LatiDeg:       26;
   LatiDirection: 'N';
   Longitude:     144;
   LongDeg:       47;
   LongDirection: 'E';
   Superficie:    549;
   Capital:       'Hag†t¤a';
   Domain:        '.gu'
  ),
  (Country:       'Guatemala';
   Latitude:      15;
   LatiDeg:       46;
   LatiDirection: 'N';
   Longitude:     90;
   LongDeg:       13;
   LongDirection: 'O';
   Superficie:    108890;
   Capital:       'Guatemala';
   Domain:        '.gt'
  ),
  (Country:       'Guernesey';
   Latitude:      49;
   LatiDeg:       34;
   LatiDirection: 'N';
   Longitude:     2;
   LongDeg:       25;
   LongDirection: 'O';
   Superficie:    78;
   Capital:       'Saint-Pierre-Port';
   Domain:        '.gg'
  ),
  (Country:       'Guinee';
   Latitude:      9;
   LatiDeg:       56;
   LatiDirection: 'N';
   Longitude:     11;
   LongDeg:       17;
   LongDirection: 'O';
   Superficie:    245857;
   Capital:       'Conakry';
   Domain:        '.gn'
  ),
  (Country:       'Guinee equatoriale';
   Latitude:      1;
   LatiDeg:       38;
   LatiDirection: 'N';
   Longitude:     10;
   LongDeg:       20;
   LongDirection: 'E';
   Superficie:    28051;
   Capital:       'Malabo';
   Domain:        '.gq'
  ),
  (Country:       'Guinee-Bissau';
   Latitude:      11;
   LatiDeg:       48;
   LatiDirection: 'N';
   Longitude:     15;
   LongDeg:       10;
   LongDirection: 'O';
   Superficie:    36120;
   Capital:       'Bissau';
   Domain:        '.gw'
  ),
  (Country:       'Guyana';
   Latitude:      4;
   LatiDeg:       51;
   LatiDirection: 'N';
   Longitude:     58;
   LongDeg:       55;
   LongDirection: 'O';
   Superficie:    214970;
   Capital:       'Georgetown';
   Domain:        '.gy'
  ),
  (Country:       'Guyane';
   Latitude:      3;
   LatiDeg:       57;
   LatiDirection: 'N';
   Longitude:     53;
   LongDeg:       4;
   LongDirection: 'O';
   Superficie:    91000;
   Capital:       'Cayenne';
   Domain:        '.gf'
  ),
  (Country:       'Haiti';
   Latitude:      19;
   LatiDeg:       3;
   LatiDirection: 'N';
   Longitude:     73;
   LongDeg:       2;
   LongDirection: 'O';
   Superficie:    27750;
   Capital:       'Port-au-Prince';
   Domain:        '.ht'
  ),
  (Country:       'Honduras';
   Latitude:      14;
   LatiDeg:       44;
   LatiDirection: 'N';
   Longitude:     86;
   LongDeg:       15;
   LongDirection: 'O';
   Superficie:    112090;
   Capital:       'Tegucigalpa';
   Domain:        '.hn'
  ),
  (Country:       'Hong Kong';
   Latitude:      22;
   LatiDeg:       21;
   LatiDirection: 'N';
   Longitude:     114;
   LongDeg:       8;
   LongDirection: 'E';
   Superficie:    1092;
   Capital:       'Hong Kong';
   Domain:        '.hk'
  ),
  (Country:       'Hongrie';
   Latitude:      47;
   LatiDeg:       9;
   LatiDirection: 'N';
   Longitude:     19;
   LongDeg:       30;
   LongDirection: 'E';
   Superficie:    93030;
   Capital:       'Budapest';
   Domain:        '.hu'
  ),
  (Country:       'Ile Bouvet';
   Latitude:      54;
   LatiDeg:       25;
   LatiDirection: 'S';
   Longitude:     3;
   LongDeg:       24;
   LongDirection: 'E';
   Superficie:    49;
   Capital:       '';
   Domain:        '.bv'
  ),
  (Country:       'Ile Christmas';
   Latitude:      10;
   LatiDeg:       29;
   LatiDirection: 'S';
   Longitude:     105;
   LongDeg:       37;
   LongDirection: 'E';
   Superficie:    135;
   Capital:       'Flying Fish Cove';
   Domain:        '.cx'
  ),
  (Country:       'Ile de Man';
   Latitude:      54;
   LatiDeg:       14;
   LatiDirection: 'N';
   Longitude:     4;
   LongDeg:       33;
   LongDirection: 'O';
   Superficie:    572;
   Capital:       'Douglas';
   Domain:        '.im'
  ),
  (Country:       'Ile Heard';
   Latitude:      53;
   LatiDeg:       3;
   LatiDirection: 'S';
   Longitude:     73;
   LongDeg:       13;
   LongDirection: 'E';
   Superficie:    412;
   Capital:       '';
   Domain:        '.hm'
  ),
  (Country:       'Ile Norfolk';
   Latitude:      29;
   LatiDeg:       1;
   LatiDirection: 'S';
   Longitude:     167;
   LongDeg:       57;
   LongDirection: 'E';
   Superficie:    34;
   Capital:       'Kingston';
   Domain:        '.nf'
  ),
  (Country:       'Iles Aland';
   Latitude:      60;
   LatiDeg:       11;
   LatiDirection: 'N';
   Longitude:     20;
   LongDeg:       9;
   LongDirection: 'E';
   Superficie:    26;
   Capital:       'Mariehamn';
   Domain:        ''
  ),
  (Country:       'Iles Caimans';
   Latitude:      19;
   LatiDeg:       30;
   LatiDirection: 'N';
   Longitude:     80;
   LongDeg:       34;
   LongDirection: 'O';
   Superficie:    262;
   Capital:       'George Town';
   Domain:        '.ky'
  ),
  (Country:       'Iles Cocos';
   Latitude:      12;
   LatiDeg:       8;
   LatiDirection: 'S';
   Longitude:     96;
   LongDeg:       52;
   LongDirection: 'E';
   Superficie:    14;
   Capital:       'West Island';
   Domain:        '.cc'
  ),
  (Country:       'Iles Cook';
   Latitude:      15;
   LatiDeg:       59;
   LatiDirection: 'S';
   Longitude:     159;
   LongDeg:       12;
   LongDirection: 'O';
   Superficie:    240;
   Capital:       'Avarua';
   Domain:        '.ck'
  ),
  (Country:       'Iles Feroe';
   Latitude:      61;
   LatiDeg:       53;
   LatiDirection: 'N';
   Longitude:     6;
   LongDeg:       55;
   LongDirection: 'O';
   Superficie:    1399;
   Capital:       'T¢rshavn';
   Domain:        '.fo'
  ),
  (Country:       'Iles Malouines';
   Latitude:      51;
   LatiDeg:       48;
   LatiDirection: 'S';
   Longitude:     59;
   LongDeg:       31;
   LongDirection: 'O';
   Superficie:    12173;
   Capital:       'Port Stanley';
   Domain:        '.fk'
  ),
  (Country:       'Iles Mariannes du Nord';
   Latitude:      17;
   LatiDeg:       0;
   LatiDirection: 'N';
   Longitude:     145;
   LongDeg:       0;
   LongDirection: 'E';
   Superficie:    477;
   Capital:       'Saipan';
   Domain:        '.mp'
  ),
  (Country:       'Iles Marshall';
   Latitude:      10;
   LatiDeg:       6;
   LatiDirection: 'N';
   Longitude:     168;
   LongDeg:       43;
   LongDirection: 'E';
   Superficie:    181;
   Capital:       'Majuro';
   Domain:        '.mh'
  ),
  (Country:       'Iles mineures';
   Latitude:      13;
   LatiDeg:       54;
   LatiDirection: 'N';
   Longitude:     5;
   LongDeg:       22;
   LongDirection: 'O';
   Superficie:    40;
   Capital:       '';
   Domain:        ''
  ),
  (Country:       'Iles Salomon';
   Latitude:      9;
   LatiDeg:       13;
   LatiDirection: 'S';
   Longitude:     161;
   LongDeg:       14;
   LongDirection: 'E';
   Superficie:    28450;
   Capital:       'Honiara';
   Domain:        '.sb'
  ),
  (Country:       'Iles Turques-et-Caiques';
   Latitude:      21;
   LatiDeg:       0;
   LatiDirection: 'N';
   Longitude:     71;
   LongDeg:       0;
   LongDirection: 'O';
   Superficie:    430;
   Capital:       'Cockburn Town';
   Domain:        '.tc'
  ),
  (Country:       'Iles Vierges';
   Latitude:      18;
   LatiDeg:       0;
   LatiDirection: 'N';
   Longitude:     64;
   LongDeg:       0;
   LongDirection: 'O';
   Superficie:    153;
   Capital:       'Road Town';
   Domain:        '.vg'
  ),
  (Country:       'Iles Vierges des Etats-Unis';
   Latitude:      18;
   LatiDeg:       2;
   LatiDirection: 'N';
   Longitude:     64;
   LongDeg:       48;
   LongDirection: 'O';
   Superficie:    352;
   Capital:       'Charlotte Amalie';
   Domain:        '.vi'
  ),
  (Country:       'Inde';
   Latitude:      21;
   LatiDeg:       7;
   LatiDirection: 'N';
   Longitude:     82;
   LongDeg:       47;
   LongDirection: 'E';
   Superficie:    3287590;
   Capital:       'New Delhi';
   Domain:        '.in'
  ),
  (Country:       'Indonesie';
   Latitude:      2;
   LatiDeg:       31;
   LatiDirection: 'S';
   Longitude:     118;
   LongDeg:       0;
   LongDirection: 'E';
   Superficie:    1919440;
   Capital:       'Jakarta';
   Domain:        '.id'
  ),
  (Country:       'Irak';
   Latitude:      33;
   LatiDeg:       13;
   LatiDirection: 'N';
   Longitude:     43;
   LongDeg:       41;
   LongDirection: 'E';
   Superficie:    437072;
   Capital:       'Bagdad';
   Domain:        '.iq'
  ),
  (Country:       'Iran';
   Latitude:      32;
   LatiDeg:       25;
   LatiDirection: 'N';
   Longitude:     53;
   LongDeg:       40;
   LongDirection: 'E';
   Superficie:    1648000;
   Capital:       'T‚h‚ran';
   Domain:        '.ir'
  ),
  (Country:       'Irlande';
   Latitude:      53;
   LatiDeg:       25;
   LatiDirection: 'N';
   Longitude:     8;
   LongDeg:       14;
   LongDirection: 'O';
   Superficie:    70280;
   Capital:       'Dublin';
   Domain:        '.ie'
  ),
  (Country:       'Islande';
   Latitude:      64;
   LatiDeg:       57;
   LatiDirection: 'N';
   Longitude:     19;
   LongDeg:       1;
   LongDirection: 'O';
   Superficie:    103000;
   Capital:       'Reykjav¡k';
   Domain:        '.is'
  ),
  (Country:       'Israel';
   Latitude:      31;
   LatiDeg:       25;
   LatiDirection: 'N';
   Longitude:     35;
   LongDeg:       4;
   LongDirection: 'E';
   Superficie:    20770;
   Capital:       'J‚rusalem';
   Domain:        '.il'
  ),
  (Country:       'Italie';
   Latitude:      41;
   LatiDeg:       52;
   LatiDirection: 'N';
   Longitude:     12;
   LongDeg:       33;
   LongDirection: 'E';
   Superficie:    301230;
   Capital:       'Rome';
   Domain:        '.it'
  ),
  (Country:       'Jamaique';
   Latitude:      18;
   LatiDeg:       6;
   LatiDirection: 'N';
   Longitude:     77;
   LongDeg:       16;
   LongDirection: 'O';
   Superficie:    10991;
   Capital:       'Kingston';
   Domain:        '.jm'
  ),
  (Country:       'Japon';
   Latitude:      34;
   LatiDeg:       53;
   LatiDirection: 'N';
   Longitude:     134;
   LongDeg:       22;
   LongDirection: 'E';
   Superficie:    377835;
   Capital:       'Tokyo';
   Domain:        '.jp'
  ),
  (Country:       'Jersey';
   Latitude:      49;
   LatiDeg:       13;
   LatiDirection: 'N';
   Longitude:     2;
   LongDeg:       8;
   LongDirection: 'O';
   Superficie:    116;
   Capital:       'Saint Helier';
   Domain:        '.je'
  ),
  (Country:       'Jordanie';
   Latitude:      31;
   LatiDeg:       16;
   LatiDirection: 'N';
   Longitude:     37;
   LongDeg:       7;
   LongDirection: 'E';
   Superficie:    92300;
   Capital:       'Amman';
   Domain:        '.jo'
  ),
  (Country:       'Kazakhstan';
   Latitude:      48;
   LatiDeg:       11;
   LatiDirection: 'N';
   Longitude:     66;
   LongDeg:       54;
   LongDirection: 'E';
   Superficie:    2717300;
   Capital:       'Astana';
   Domain:        '.kz'
  ),
  (Country:       'Kenya';
   Latitude:      0;
   LatiDeg:       10;
   LatiDirection: 'N';
   Longitude:     37;
   LongDeg:       54;
   LongDirection: 'E';
   Superficie:    582650;
   Capital:       'Nairobi';
   Domain:        '.ke'
  ),
  (Country:       'Kirghizistan';
   Latitude:      41;
   LatiDeg:       12;
   LatiDirection: 'N';
   Longitude:     74;
   LongDeg:       46;
   LongDirection: 'E';
   Superficie:    198500;
   Capital:       'Bichkek';
   Domain:        '.kg'
  ),
  (Country:       'Kiribati';
   Latitude:      3;
   LatiDeg:       21;
   LatiDirection: 'S';
   Longitude:     170;
   LongDeg:       19;
   LongDirection: 'O';
   Superficie:    811;
   Capital:       'Tarawa-Sud';
   Domain:        '.ki'
  ),
  (Country:       'Kosovo';
   Latitude:      42;
   LatiDeg:       33;
   LatiDirection: 'N';
   Longitude:     20;
   LongDeg:       53;
   LongDirection: 'E';
   Superficie:    10908;
   Capital:       'Pristina';
   Domain:        '.xk'
  ),
  (Country:       'Koweit';
   Latitude:      29;
   LatiDeg:       18;
   LatiDirection: 'N';
   Longitude:     47;
   LongDeg:       29;
   LongDirection: 'E';
   Superficie:    17820;
   Capital:       'Kowe‹t';
   Domain:        '.kw'
  ),
  (Country:       'Laos';
   Latitude:      18;
   LatiDeg:       12;
   LatiDirection: 'N';
   Longitude:     103;
   LongDeg:       53;
   LongDirection: 'E';
   Superficie:    236800;
   Capital:       'Vientiane';
   Domain:        '.la'
  ),
  (Country:       'Lesotho';
   Latitude:      29;
   LatiDeg:       37;
   LatiDirection: 'S';
   Longitude:     28;
   LongDeg:       14;
   LongDirection: 'E';
   Superficie:    30355;
   Capital:       'Maseru';
   Domain:        '.ls'
  ),
  (Country:       'Lettonie';
   Latitude:      56;
   LatiDeg:       52;
   LatiDirection: 'N';
   Longitude:     24;
   LongDeg:       36;
   LongDirection: 'E';
   Superficie:    64589;
   Capital:       'Riga';
   Domain:        '.lv'
  ),
  (Country:       'Liban';
   Latitude:      33;
   LatiDeg:       52;
   LatiDirection: 'N';
   Longitude:     35;
   LongDeg:       52;
   LongDirection: 'E';
   Superficie:    10400;
   Capital:       'Beyrouth';
   Domain:        '.lb'
  ),
  (Country:       'Liberia';
   Latitude:      6;
   LatiDeg:       27;
   LatiDirection: 'N';
   Longitude:     9;
   LongDeg:       25;
   LongDirection: 'O';
   Superficie:    111370;
   Capital:       'Monrovia';
   Domain:        '.lr'
  ),
  (Country:       'Libye';
   Latitude:      26;
   LatiDeg:       20;
   LatiDirection: 'N';
   Longitude:     17;
   LongDeg:       16;
   LongDirection: 'E';
   Superficie:    1759540;
   Capital:       'Tripoli';
   Domain:        '.ly'
  ),
  (Country:       'Liechtenstein';
   Latitude:      47;
   LatiDeg:       9;
   LatiDirection: 'N';
   Longitude:     9;
   LongDeg:       33;
   LongDirection: 'E';
   Superficie:    160;
   Capital:       'Vaduz';
   Domain:        '.li'
  ),
  (Country:       'Lituanie';
   Latitude:      55;
   LatiDeg:       10;
   LatiDirection: 'N';
   Longitude:     23;
   LongDeg:       54;
   LongDirection: 'E';
   Superficie:    65200;
   Capital:       'Vilnius';
   Domain:        '.lt'
  ),
  (Country:       'Luxembourg';
   Latitude:      49;
   LatiDeg:       48;
   LatiDirection: 'N';
   Longitude:     6;
   LongDeg:       7;
   LongDirection: 'E';
   Superficie:    2586;
   Capital:       'Luxembourg';
   Domain:        '.lu'
  ),
  (Country:       'Macao';
   Latitude:      22;
   LatiDeg:       12;
   LatiDirection: 'N';
   Longitude:     113;
   LongDeg:       32;
   LongDirection: 'E';
   Superficie:    254;
   Capital:       'Macao';
   Domain:        '.mo'
  ),
  (Country:       'Macedoine';
   Latitude:      41;
   LatiDeg:       36;
   LatiDirection: 'N';
   Longitude:     21;
   LongDeg:       45;
   LongDirection: 'E';
   Superficie:    25333;
   Capital:       'Skopje';
   Domain:        '.mk'
  ),
  (Country:       'Madagascar';
   Latitude:      18;
   LatiDeg:       46;
   LatiDirection: 'S';
   Longitude:     46;
   LongDeg:       51;
   LongDirection: 'E';
   Superficie:    587040;
   Capital:       'Antananarivo';
   Domain:        '.mg'
  ),
  (Country:       'Malaisie';
   Latitude:      4;
   LatiDeg:       6;
   LatiDirection: 'N';
   Longitude:     109;
   LongDeg:       27;
   LongDirection: 'E';
   Superficie:    329750;
   Capital:       'Kuala Lumpur';
   Domain:        '.my'
  ),
  (Country:       'Malawi';
   Latitude:      13;
   LatiDeg:       14;
   LatiDirection: 'S';
   Longitude:     34;
   LongDeg:       17;
   LongDirection: 'E';
   Superficie:    118480;
   Capital:       'Lilongwe';
   Domain:        '.mw'
  ),
  (Country:       'Maldives';
   Latitude:      3;
   LatiDeg:       12;
   LatiDirection: 'N';
   Longitude:     73;
   LongDeg:       9;
   LongDirection: 'E';
   Superficie:    300;
   Capital:       'Mal‚';
   Domain:        '.mv'
  ),
  (Country:       'Mali';
   Latitude:      17;
   LatiDeg:       34;
   LatiDirection: 'N';
   Longitude:     3;
   LongDeg:       59;
   LongDirection: 'O';
   Superficie:    1240000;
   Capital:       'Bamako';
   Domain:        '.ml'
  ),
  (Country:       'Malte';
   Latitude:      35;
   LatiDeg:       56;
   LatiDirection: 'N';
   Longitude:     14;
   LongDeg:       22;
   LongDirection: 'E';
   Superficie:    316;
   Capital:       'La Valette';
   Domain:        '.mt'
  ),
  (Country:       'Maroc';
   Latitude:      31;
   LatiDeg:       47;
   LatiDirection: 'N';
   Longitude:     7;
   LongDeg:       4;
   LongDirection: 'O';
   Superficie:    446550;
   Capital:       'Rabat';
   Domain:        '.ma'
  ),
  (Country:       'Martinique';
   Latitude:      14;
   LatiDeg:       38;
   LatiDirection: 'N';
   Longitude:     61;
   LongDeg:       1;
   LongDirection: 'O';
   Superficie:    1100;
   Capital:       'Fort-de-France';
   Domain:        '.mq'
  ),
  (Country:       'Maurice';
   Latitude:      15;
   LatiDeg:       25;
   LatiDirection: 'S';
   Longitude:     60;
   LongDeg:       0;
   LongDirection: 'E';
   Superficie:    2040;
   Capital:       'Port-Louis';
   Domain:        '.mu'
  ),
  (Country:       'Mauritanie';
   Latitude:      21;
   LatiDeg:       0;
   LatiDirection: 'N';
   Longitude:     10;
   LongDeg:       56;
   LongDirection: 'O';
   Superficie:    1030700;
   Capital:       'Nouakchott';
   Domain:        '.mr'
  ),
  (Country:       'Mayotte';
   Latitude:      12;
   LatiDeg:       49;
   LatiDirection: 'S';
   Longitude:     45;
   LongDeg:       9;
   LongDirection: 'E';
   Superficie:    374;
   Capital:       'Mamoudzou';
   Domain:        '.yt'
  ),
  (Country:       'Mexique';
   Latitude:      23;
   LatiDeg:       37;
   LatiDirection: 'N';
   Longitude:     102;
   LongDeg:       34;
   LongDirection: 'O';
   Superficie:    1972550;
   Capital:       'Mexico';
   Domain:        '.mx'
  ),
  (Country:       'Micronesie';
   Latitude:      5;
   LatiDeg:       33;
   LatiDirection: 'N';
   Longitude:     150;
   LongDeg:       11;
   LongDirection: 'E';
   Superficie:    702;
   Capital:       'Palikir';
   Domain:        '.fm'
  ),
  (Country:       'Moldavie';
   Latitude:      46;
   LatiDeg:       58;
   LatiDirection: 'N';
   Longitude:     28;
   LongDeg:       22;
   LongDirection: 'E';
   Superficie:    33843;
   Capital:       'Chisinau';
   Domain:        '.md'
  ),
  (Country:       'Monaco';
   Latitude:      43;
   LatiDeg:       44;
   LatiDirection: 'N';
   Longitude:     7;
   LongDeg:       25;
   LongDirection: 'E';
   Superficie:    2;
   Capital:       'Monaco';
   Domain:        '.mc'
  ),
  (Country:       'Mongolie';
   Latitude:      46;
   LatiDeg:       51;
   LatiDirection: 'N';
   Longitude:     103;
   LongDeg:       50;
   LongDirection: 'E';
   Superficie:    1565000;
   Capital:       'Oulan-Bator';
   Domain:        '.mn'
  ),
  (Country:       'Montenegro';
   Latitude:      42;
   LatiDeg:       42;
   LatiDirection: 'N';
   Longitude:     19;
   LongDeg:       24;
   LongDirection: 'E';
   Superficie:    14026;
   Capital:       'Podgorica';
   Domain:        '.me'
  ),
  (Country:       'Montserrat';
   Latitude:      16;
   LatiDeg:       44;
   LatiDirection: 'N';
   Longitude:     62;
   LongDeg:       11;
   LongDirection: 'O';
   Superficie:    102;
   Capital:       'Plymouth';
   Domain:        '.ms'
  ),
  (Country:       'Mozambique';
   Latitude:      18;
   LatiDeg:       40;
   LatiDirection: 'S';
   Longitude:     35;
   LongDeg:       31;
   LongDirection: 'E';
   Superficie:    801590;
   Capital:       'Maputo';
   Domain:        '.mz'
  ),
  (Country:       'Myanmar';
   Latitude:      19;
   LatiDeg:       9;
   LatiDirection: 'N';
   Longitude:     96;
   LongDeg:       40;
   LongDirection: 'E';
   Superficie:    678500;
   Capital:       'Nay Pyi Taw';
   Domain:        '.mm'
  ),
  (Country:       'Namibie';
   Latitude:      22;
   LatiDeg:       57;
   LatiDirection: 'S';
   Longitude:     18;
   LongDeg:       29;
   LongDirection: 'E';
   Superficie:    825418;
   Capital:       'Windhoek';
   Domain:        '.na'
  ),
  (Country:       'Nauru';
   Latitude:      0;
   LatiDeg:       31;
   LatiDirection: 'S';
   Longitude:     166;
   LongDeg:       55;
   LongDirection: 'E';
   Superficie:    21;
   Capital:       'Yaren';
   Domain:        '.nr'
  ),
  (Country:       'Nepal';
   Latitude:      28;
   LatiDeg:       23;
   LatiDirection: 'N';
   Longitude:     84;
   LongDeg:       7;
   LongDirection: 'E';
   Superficie:    140800;
   Capital:       'Managua';
   Domain:        '.np'
  ),
  (Country:       'Nicaragua';
   Latitude:      12;
   LatiDeg:       52;
   LatiDirection: 'N';
   Longitude:     85;
   LongDeg:       12;
   LongDirection: 'O';
   Superficie:    129494;
   Capital:       'Managua';
   Domain:        '.ni'
  ),
  (Country:       'Niger';
   Latitude:      17;
   LatiDeg:       36;
   LatiDirection: 'N';
   Longitude:     8;
   LongDeg:       4;
   LongDirection: 'E';
   Superficie:    1267000;
   Capital:       'Niamey';
   Domain:        '.ne'
  ),
  (Country:       'Nigeria';
   Latitude:      9;
   LatiDeg:       5;
   LatiDirection: 'N';
   Longitude:     8;
   LongDeg:       40;
   LongDirection: 'E';
   Superficie:    923768;
   Capital:       'Abuja';
   Domain:        '.ng'
  ),
  (Country:       'Nioue';
   Latitude:      19;
   LatiDeg:       3;
   LatiDirection: 'S';
   Longitude:     169;
   LongDeg:       51;
   LongDirection: 'O';
   Superficie:    260;
   Capital:       'Alofi';
   Domain:        '.nu'
  ),
  (Country:       'Norvege';
   Latitude:      64;
   LatiDeg:       34;
   LatiDirection: 'N';
   Longitude:     17;
   LongDeg:       51;
   LongDirection: 'E';
   Superficie:    324220;
   Capital:       'Oslo';
   Domain:        '.no'
  ),
  (Country:       'Nouvelle-Caledonie';
   Latitude:      21;
   LatiDeg:       7;
   LatiDirection: 'S';
   Longitude:     165;
   LongDeg:       50;
   LongDirection: 'E';
   Superficie:    19060;
   Capital:       'Noum‚a';
   Domain:        '.nc'
  ),
  (Country:       'Nouvelle-Zelande';
   Latitude:      41;
   LatiDeg:       0;
   LatiDirection: 'S';
   Longitude:     172;
   LongDeg:       0;
   LongDirection: 'E';
   Superficie:    268680;
   Capital:       'Wellington';
   Domain:        '.nz'
  ),
  (Country:       'Oman';
   Latitude:      21;
   LatiDeg:       31;
   LatiDirection: 'N';
   Longitude:     55;
   LongDeg:       51;
   LongDirection: 'E';
   Superficie:    212460;
   Capital:       'Mascate';
   Domain:        '.om'
  ),
  (Country:       'Ouganda';
   Latitude:      1;
   LatiDeg:       21;
   LatiDirection: 'N';
   Longitude:     32;
   LongDeg:       18;
   LongDirection: 'E';
   Superficie:    236040;
   Capital:       'Kampala';
   Domain:        '.ug'
  ),
  (Country:       'Ouzbekistan';
   Latitude:      41;
   LatiDeg:       22;
   LatiDirection: 'N';
   Longitude:     64;
   LongDeg:       33;
   LongDirection: 'E';
   Superficie:    447400;
   Capital:       'Tachkent';
   Domain:        '.uz'
  ),
  (Country:       'Pakistan';
   Latitude:      30;
   LatiDeg:       26;
   LatiDirection: 'N';
   Longitude:     69;
   LongDeg:       21;
   LongDirection: 'E';
   Superficie:    803940;
   Capital:       'Islamabad';
   Domain:        '.pk'
  ),
  (Country:       'Palaos';
   Latitude:      5;
   LatiDeg:       38;
   LatiDirection: 'N';
   Longitude:     132;
   LongDeg:       55;
   LongDirection: 'E';
   Superficie:    458;
   Capital:       'Melekeok - Palau State Capital';
   Domain:        '.pw'
  ),
  (Country:       'Panama';
   Latitude:      8;
   LatiDeg:       25;
   LatiDirection: 'N';
   Longitude:     80;
   LongDeg:       6;
   LongDirection: 'O';
   Superficie:    78200;
   Capital:       'Panam ';
   Domain:        '.pa'
  ),
  (Country:       'Papouasie-Nouvelle Guinee';
   Latitude:      6;
   LatiDeg:       29;
   LatiDirection: 'S';
   Longitude:     148;
   LongDeg:       24;
   LongDirection: 'E';
   Superficie:    462840;
   Capital:       'Port Moresby';
   Domain:        '.pg'
  ),
  (Country:       'Paraguay';
   Latitude:      23;
   LatiDeg:       27;
   LatiDirection: 'S';
   Longitude:     58;
   LongDeg:       27;
   LongDirection: 'O';
   Superficie:    406750;
   Capital:       'Asunci¢n';
   Domain:        '.py'
  ),
  (Country:       'Pays-Bas';
   Latitude:      52;
   LatiDeg:       7;
   LatiDirection: 'N';
   Longitude:     5;
   LongDeg:       17;
   LongDirection: 'E';
   Superficie:    41526;
   Capital:       'Amsterdam';
   Domain:        '.nl'
  ),
  (Country:       'Perou';
   Latitude:      9;
   LatiDeg:       10;
   LatiDirection: 'S';
   Longitude:     75;
   LongDeg:       0;
   LongDirection: 'O';
   Superficie:    1285220;
   Capital:       'Lima';
   Domain:        '.pe'
  ),
  (Country:       'Philippines';
   Latitude:      12;
   LatiDeg:       52;
   LatiDirection: 'N';
   Longitude:     121;
   LongDeg:       45;
   LongDirection: 'E';
   Superficie:    300000;
   Capital:       'Manille';
   Domain:        '.ph'
  ),
  (Country:       'Pitcairn';
   Latitude:      24;
   LatiDeg:       29;
   LatiDirection: 'S';
   Longitude:     126;
   LongDeg:       33;
   LongDirection: 'O';
   Superficie:    47;
   Capital:       'Adamstown';
   Domain:        '.pn'
  ),
  (Country:       'Pologne';
   Latitude:      51;
   LatiDeg:       55;
   LatiDirection: 'N';
   Longitude:     19;
   LongDeg:       8;
   LongDirection: 'E';
   Superficie:    312685;
   Capital:       'Varsovie';
   Domain:        '.pl'
  ),
  (Country:       'Polynesie Francaise';
   Latitude:      17;
   LatiDeg:       46;
   LatiDirection: 'S';
   Longitude:     143;
   LongDeg:       54;
   LongDirection: 'O';
   Superficie:    4167;
   Capital:       'Papeete';
   Domain:        '.pf'
  ),
  (Country:       'Porto Rico';
   Latitude:      18;
   LatiDeg:       13;
   LatiDirection: 'N';
   Longitude:     66;
   LongDeg:       35;
   LongDirection: 'O';
   Superficie:    9104;
   Capital:       'San Juan';
   Domain:        '.pr'
  ),
  (Country:       'Portugal';
   Latitude:      39;
   LatiDeg:       33;
   LatiDirection: 'N';
   Longitude:     7;
   LongDeg:       50;
   LongDirection: 'O';
   Superficie:    92391;
   Capital:       'Lisbonne';
   Domain:        '.pt'
  ),
  (Country:       'Qatar';
   Latitude:      25;
   LatiDeg:       19;
   LatiDirection: 'N';
   Longitude:     51;
   LongDeg:       11;
   LongDirection: 'E';
   Superficie:    11437;
   Capital:       'Doha';
   Domain:        '.qa'
  ),
  (Country:       'Republique democratique du congo';
   Latitude:      4;
   LatiDeg:       2;
   LatiDirection: 'S';
   Longitude:     21;
   LongDeg:       45;
   LongDirection: 'E';
   Superficie:    2345410;
   Capital:       'Kinshasa';
   Domain:        '.cd'
  ),
  (Country:       'Republique Dominicaine';
   Latitude:      18;
   LatiDeg:       44;
   LatiDirection: 'N';
   Longitude:     70;
   LongDeg:       9;
   LongDirection: 'O';
   Superficie:    48730;
   Capital:       'Santo Domingo';
   Domain:        '.do'
  ),
  (Country:       'Republique Togolaise';
   Latitude:      8;
   LatiDeg:       37;
   LatiDirection: 'N';
   Longitude:     0;
   LongDeg:       49;
   LongDirection: 'E';
   Superficie:    56785;
   Capital:       'Lom‚';
   Domain:        '.tg'
  ),
  (Country:       'Reunion';
   Latitude:      21;
   LatiDeg:       6;
   LatiDirection: 'S';
   Longitude:     55;
   LongDeg:       31;
   LongDirection: 'E';
   Superficie:    2517;
   Capital:       'Saint-Denis';
   Domain:        '.re'
  ),
  (Country:       'Roumanie';
   Latitude:      45;
   LatiDeg:       56;
   LatiDirection: 'N';
   Longitude:     24;
   LongDeg:       58;
   LongDirection: 'E';
   Superficie:    237500;
   Capital:       'Bucarest';
   Domain:        '.ro'
  ),
  (Country:       'Royaume-Uni';
   Latitude:      54;
   LatiDeg:       37;
   LatiDirection: 'N';
   Longitude:     3;
   LongDeg:       25;
   LongDirection: 'O';
   Superficie:    244820;
   Capital:       'Londres';
   Domain:        '.uk'
  ),
  (Country:       'Russie';
   Latitude:      61;
   LatiDeg:       31;
   LatiDirection: 'N';
   Longitude:     105;
   LongDeg:       6;
   LongDirection: 'E';
   Superficie:    17125191;
   Capital:       'Moscou';
   Domain:        '.ru'
  ),
  (Country:       'Rwanda';
   Latitude:      1;
   LatiDeg:       56;
   LatiDirection: 'S';
   Longitude:     29;
   LongDeg:       52;
   LongDirection: 'E';
   Superficie:    26338;
   Capital:       'Kigali';
   Domain:        '.rw'
  ),
  (Country:       'Sahara Occidental';
   Latitude:      24;
   LatiDeg:       13;
   LatiDirection: 'N';
   Longitude:     12;
   LongDeg:       53;
   LongDirection: 'O';
   Superficie:    266000;
   Capital:       'Laƒyoune';
   Domain:        '.eh'
  ),
  (Country:       'Saint-Barthelemy';
   Latitude:      17;
   LatiDeg:       54;
   LatiDirection: 'N';
   Longitude:     62;
   LongDeg:       49;
   LongDirection: 'O';
   Superficie:    21;
   Capital:       'Gustavia';
   Domain:        '.bl'
  ),
  (Country:       'Saint-Christophe-et-Nieves';
   Latitude:      17;
   LatiDeg:       15;
   LatiDirection: 'N';
   Longitude:     62;
   LongDeg:       42;
   LongDirection: 'O';
   Superficie:    261;
   Capital:       'Basseterre';
   Domain:        '.kn'
  ),
  (Country:       'Saint-Marin';
   Latitude:      43;
   LatiDeg:       56;
   LatiDirection: 'N';
   Longitude:     12;
   LongDeg:       27;
   LongDirection: 'E';
   Superficie:    61;
   Capital:       'Saint-Marin';
   Domain:        '.sm'
  ),
  (Country:       'Saint-Martin';
   Latitude:      18;
   LatiDeg:       2;
   LatiDirection: 'N';
   Longitude:     63;
   LongDeg:       4;
   LongDirection: 'O';
   Superficie:    53;
   Capital:       'Philipsburg';
   Domain:        ''
  ),
  (Country:       'Saint-Pierre et Miquelon';
   Latitude:      46;
   LatiDeg:       57;
   LatiDirection: 'N';
   Longitude:     56;
   LongDeg:       20;
   LongDirection: 'O';
   Superficie:    242;
   Capital:       'Saint-Pierre';
   Domain:        '.pm'
  ),
  (Country:       'Saint-Vincent-et-les Grenadines';
   Latitude:      12;
   LatiDeg:       58;
   LatiDirection: 'N';
   Longitude:     61;
   LongDeg:       17;
   LongDirection: 'O';
   Superficie:    389;
   Capital:       'Kingstown';
   Domain:        '.vc'
  ),
  (Country:       'Sainte-Helene';
   Latitude:      11;
   LatiDeg:       57;
   LatiDirection: 'S';
   Longitude:     10;
   LongDeg:       1;
   LongDirection: 'O';
   Superficie:    410;
   Capital:       'Jamestown';
   Domain:        '.sh'
  ),
  (Country:       'Sainte-Lucie';
   Latitude:      13;
   LatiDeg:       54;
   LatiDirection: 'N';
   Longitude:     60;
   LongDeg:       58;
   LongDirection: 'O';
   Superficie:    616;
   Capital:       'Castries';
   Domain:        '.lc'
  ),
  (Country:       'Salvador';
   Latitude:      13;
   LatiDeg:       47;
   LatiDirection: 'N';
   Longitude:     88;
   LongDeg:       54;
   LongDirection: 'O';
   Superficie:    21040;
   Capital:       'San Salvador';
   Domain:        '.sv'
  ),
  (Country:       'Samoa';
   Latitude:      13;
   LatiDeg:       44;
   LatiDirection: 'S';
   Longitude:     172;
   LongDeg:       6;
   LongDirection: 'O';
   Superficie:    2944;
   Capital:       'Apia';
   Domain:        '.ws'
  ),
  (Country:       'Samoa americaines';
   Latitude:      12;
   LatiDeg:       42;
   LatiDirection: 'S';
   Longitude:     170;
   LongDeg:       15;
   LongDirection: 'O';
   Superficie:    199;
   Capital:       'Pago Pago';
   Domain:        '.as'
  ),
  (Country:       'Sao Tome-et-Principe';
   Latitude:      0;
   LatiDeg:       51;
   LatiDirection: 'N';
   Longitude:     6;
   LongDeg:       58;
   LongDirection: 'E';
   Superficie:    1001;
   Capital:       'Sao Tom‚';
   Domain:        '.st'
  ),
  (Country:       'Senegal';
   Latitude:      14;
   LatiDeg:       29;
   LatiDirection: 'N';
   Longitude:     14;
   LongDeg:       26;
   LongDirection: 'O';
   Superficie:    196190;
   Capital:       'Dakar';
   Domain:        '.sn'
  ),
  (Country:       'Serbie';
   Latitude:      44;
   LatiDeg:       12;
   LatiDirection: 'N';
   Longitude:     20;
   LongDeg:       54;
   LongDirection: 'E';
   Superficie:    88361;
   Capital:       'Belgrade';
   Domain:        '.rs'
  ),
  (Country:       'Seychelles';
   Latitude:      7;
   LatiDeg:       1;
   LatiDirection: 'S';
   Longitude:     51;
   LongDeg:       14;
   LongDirection: 'E';
   Superficie:    455;
   Capital:       'Victoria';
   Domain:        '.sc'
  ),
  (Country:       'Sierra Leone';
   Latitude:      8;
   LatiDeg:       27;
   LatiDirection: 'N';
   Longitude:     11;
   LongDeg:       47;
   LongDirection: 'O';
   Superficie:    71740;
   Capital:       'Freetown';
   Domain:        '.sl'
  ),
  (Country:       'Singapour';
   Latitude:      1;
   LatiDeg:       21;
   LatiDirection: 'N';
   Longitude:     103;
   LongDeg:       49;
   LongDirection: 'E';
   Superficie:    692;
   Capital:       'Singapour';
   Domain:        '.sg'
  ),
  (Country:       'Slovaquie';
   Latitude:      48;
   LatiDeg:       39;
   LatiDirection: 'N';
   Longitude:     19;
   LongDeg:       42;
   LongDirection: 'E';
   Superficie:    48845;
   Capital:       'Bratislava';
   Domain:        '.sk'
  ),
  (Country:       'Slovenie';
   Latitude:      46;
   LatiDeg:       8;
   LatiDirection: 'N';
   Longitude:     14;
   LongDeg:       58;
   LongDirection: 'E';
   Superficie:    20273;
   Capital:       'Ljubljana';
   Domain:        '.si'
  ),
  (Country:       'Somalie';
   Latitude:      5;
   LatiDeg:       9;
   LatiDirection: 'N';
   Longitude:     46;
   LongDeg:       11;
   LongDirection: 'E';
   Superficie:    637657;
   Capital:       'Mogadiscio';
   Domain:        '.so'
  ),
  (Country:       'Soudan';
   Latitude:      15;
   LatiDeg:       27;
   LatiDirection: 'N';
   Longitude:     30;
   LongDeg:       13;
   LongDirection: 'E';
   Superficie:    1861484;
   Capital:       'Khartoum';
   Domain:        '.sd'
  ),
  (Country:       'Sri Lanka';
   Latitude:      7;
   LatiDeg:       52;
   LatiDirection: 'N';
   Longitude:     80;
   LongDeg:       46;
   LongDirection: 'E';
   Superficie:    65610;
   Capital:       'Colombo';
   Domain:        '.lk'
  ),
  (Country:       'Sud-Soudan';
   Latitude:      7;
   LatiDeg:       51;
   LatiDirection: 'N';
   Longitude:     30;
   LongDeg:       2;
   LongDirection: 'E';
   Superficie:    644329;
   Capital:       'Djouba';
   Domain:        '.ss'
  ),
  (Country:       'Suede';
   Latitude:      62;
   LatiDeg:       11;
   LatiDirection: 'N';
   Longitude:     17;
   LongDeg:       38;
   LongDirection: 'E';
   Superficie:    449964;
   Capital:       'Stockholm';
   Domain:        '.se'
  ),
  (Country:       'Suisse';
   Latitude:      46;
   LatiDeg:       48;
   LatiDirection: 'N';
   Longitude:     8;
   LongDeg:       13;
   LongDirection: 'E';
   Superficie:    41290;
   Capital:       'Berne';
   Domain:        '.ch'
  ),
  (Country:       'Surinam';
   Latitude:      3;
   LatiDeg:       55;
   LatiDirection: 'N';
   Longitude:     56;
   LongDeg:       1;
   LongDirection: 'O';
   Superficie:    163270;
   Capital:       'Paramaribo';
   Domain:        '.sr'
  ),
  (Country:       'Svalbard et Ile Jan Mayen';
   Latitude:      79;
   LatiDeg:       59;
   LatiDirection: 'N';
   Longitude:     25;
   LongDeg:       29;
   LongDirection: 'E';
   Superficie:    62049;
   Capital:       'Longyearbyen';
   Domain:        '.sj'
  ),
  (Country:       'Swaziland';
   Latitude:      26;
   LatiDeg:       31;
   LatiDirection: 'S';
   Longitude:     31;
   LongDeg:       27;
   LongDirection: 'E';
   Superficie:    17363;
   Capital:       'Mbabane';
   Domain:        '.sz'
  ),
  (Country:       'Syrie';
   Latitude:      34;
   LatiDeg:       48;
   LatiDirection: 'N';
   Longitude:     39;
   LongDeg:       3;
   LongDirection: 'E';
   Superficie:    185180;
   Capital:       'Damas';
   Domain:        '.sy'
  ),
  (Country:       'Tadjikistan';
   Latitude:      38;
   LatiDeg:       51;
   LatiDirection: 'N';
   Longitude:     71;
   LongDeg:       15;
   LongDirection: 'E';
   Superficie:    143100;
   Capital:       'Douchanb‚';
   Domain:        '.tj'
  ),
  (Country:       'Taiwan';
   Latitude:      23;
   LatiDeg:       36;
   LatiDirection: 'N';
   Longitude:     120;
   LongDeg:       46;
   LongDirection: 'E';
   Superficie:    35980;
   Capital:       'Taipei';
   Domain:        '.tw'
  ),
  (Country:       'Tanzanie';
   Latitude:      6;
   LatiDeg:       22;
   LatiDirection: 'S';
   Longitude:     34;
   LongDeg:       53;
   LongDirection: 'E';
   Superficie:    945087;
   Capital:       'Dodoma';
   Domain:        '.tz'
  ),
  (Country:       'Tchad';
   Latitude:      15;
   LatiDeg:       26;
   LatiDirection: 'N';
   Longitude:     18;
   LongDeg:       44;
   LongDirection: 'E';
   Superficie:    1284000;
   Capital:       'Ndjamena';
   Domain:        '.td'
  ),
  (Country:       'Tchequie';
   Latitude:      49;
   LatiDeg:       48;
   LatiDirection: 'N';
   Longitude:     15;
   LongDeg:       28;
   LongDirection: 'E';
   Superficie:    78866;
   Capital:       'Prague';
   Domain:        '.cz'
  ),
  (Country:       'Terres australes francaises';
   Latitude:      43;
   LatiDeg:       45;
   LatiDirection: 'S';
   Longitude:     63;
   LongDeg:       53;
   LongDirection: 'E';
   Superficie:    7829;
   Capital:       'Port-aux-Fran‡ais';
   Domain:        ''
  ),
  (Country:       'Territoire britannique de l''ocean Indien';
   Latitude:      6;
   LatiDeg:       21;
   LatiDirection: 'N';
   Longitude:     71;
   LongDeg:       52;
   LongDirection: 'E';
   Superficie:    60;
   Capital:       '';
   Domain:        '.io'
  ),
  (Country:       'Territoire palestinien';
   Latitude:      31;
   LatiDeg:       52;
   LatiDirection: 'N';
   Longitude:     34;
   LongDeg:       53;
   LongDirection: 'E';
   Superficie:    5970;
   Capital:       '';
   Domain:        ''
  ),
  (Country:       'Thailande';
   Latitude:      13;
   LatiDeg:       2;
   LatiDirection: 'N';
   Longitude:     101;
   LongDeg:       29;
   LongDirection: 'E';
   Superficie:    514000;
   Capital:       'Bangkok';
   Domain:        '.th'
  ),
  (Country:       'Timor Oriental';
   Latitude:      8;
   LatiDeg:       47;
   LatiDirection: 'S';
   Longitude:     125;
   LongDeg:       40;
   LongDirection: 'E';
   Superficie:    15007;
   Capital:       'Dili';
   Domain:        '.tp'
  ),
  (Country:       'Tokelau';
   Latitude:      8;
   LatiDeg:       58;
   LatiDirection: 'S';
   Longitude:     171;
   LongDeg:       51;
   LongDirection: 'O';
   Superficie:    10;
   Capital:       '';
   Domain:        '.tk'
  ),
  (Country:       'Tonga';
   Latitude:      18;
   LatiDeg:       30;
   LatiDirection: 'S';
   Longitude:     174;
   LongDeg:       47;
   LongDirection: 'O';
   Superficie:    748;
   Capital:       'Nuku''alofa';
   Domain:        '.to'
  ),
  (Country:       'Trinidad et Tobago';
   Latitude:      10;
   LatiDeg:       41;
   LatiDirection: 'N';
   Longitude:     61;
   LongDeg:       13;
   LongDirection: 'O';
   Superficie:    5128;
   Capital:       'Port-d''Espagne';
   Domain:        '.tt'
  ),
  (Country:       'Tunisie';
   Latitude:      33;
   LatiDeg:       53;
   LatiDirection: 'N';
   Longitude:     9;
   LongDeg:       33;
   LongDirection: 'E';
   Superficie:    163610;
   Capital:       'Tunis';
   Domain:        '.tn'
  ),
  (Country:       'Turkmenistan';
   Latitude:      38;
   LatiDeg:       58;
   LatiDirection: 'N';
   Longitude:     59;
   LongDeg:       33;
   LongDirection: 'E';
   Superficie:    488100;
   Capital:       'Achgabat';
   Domain:        '.tm'
  ),
  (Country:       'Turquie';
   Latitude:      38;
   LatiDeg:       57;
   LatiDirection: 'N';
   Longitude:     35;
   LongDeg:       15;
   LongDirection: 'E';
   Superficie:    780580;
   Capital:       'Ankara';
   Domain:        '.tr'
  ),
  (Country:       'Tuvalu';
   Latitude:      8;
   LatiDeg:       13;
   LatiDirection: 'S';
   Longitude:     177;
   LongDeg:       57;
   LongDirection: 'E';
   Superficie:    26;
   Capital:       'Funafuti';
   Domain:        '.tv'
  ),
  (Country:       'Ukraine';
   Latitude:      48;
   LatiDeg:       22;
   LatiDirection: 'N';
   Longitude:     31;
   LongDeg:       10;
   LongDirection: 'E';
   Superficie:    603700;
   Capital:       'Kiev';
   Domain:        '.ua'
  ),
  (Country:       'Uruguay';
   Latitude:      32;
   LatiDeg:       31;
   LatiDirection: 'S';
   Longitude:     55;
   LongDeg:       45;
   LongDirection: 'O';
   Superficie:    176220;
   Capital:       'Montevideo';
   Domain:        '.uy'
  ),
  (Country:       'Vanuatu';
   Latitude:      16;
   LatiDeg:       39;
   LatiDirection: 'S';
   Longitude:     168;
   LongDeg:       12;
   LongDirection: 'E';
   Superficie:    12200;
   Capital:       'Port-Vila';
   Domain:        '.vu'
  ),
  (Country:       'Vatican';
   Latitude:      41;
   LatiDeg:       54;
   LatiDirection: 'N';
   Longitude:     12;
   LongDeg:       27;
   LongDirection: 'E';
   Superficie:    1;
   Capital:       'Vatican City';
   Domain:        '.va'
  ),
  (Country:       'Venezuela';
   Latitude:      6;
   LatiDeg:       24;
   LatiDirection: 'N';
   Longitude:     66;
   LongDeg:       34;
   LongDirection: 'O';
   Superficie:    912050;
   Capital:       'Caracas';
   Domain:        '.ve'
  ),
  (Country:       'Vietnam';
   Latitude:      15;
   LatiDeg:       58;
   LatiDirection: 'N';
   Longitude:     105;
   LongDeg:       48;
   LongDirection: 'E';
   Superficie:    329560;
   Capital:       'Hano‹';
   Domain:        '.vn'
  ),
  (Country:       'Wallis-et-Futuna';
   Latitude:      13;
   LatiDeg:       45;
   LatiDirection: 'S';
   Longitude:     177;
   LongDeg:       10;
   LongDirection: 'O';
   Superficie:    274;
   Capital:       'Mata-Utu';
   Domain:        '.wf'
  ),
  (Country:       'Yemen';
   Latitude:      15;
   LatiDeg:       15;
   LatiDirection: 'N';
   Longitude:     48;
   LongDeg:       31;
   LongDirection: 'E';
   Superficie:    527970;
   Capital:       'Sanaa';
   Domain:        '.ye'
  ),
  (Country:       'Zambie';
   Latitude:      13;
   LatiDeg:       9;
   LatiDirection: 'S';
   Longitude:     27;
   LongDeg:       51;
   LongDirection: 'E';
   Superficie:    752614;
   Capital:       'Lusaka';
   Domain:        '.zm'
  ),
  (Country:       'Zimbabwe';
   Latitude:      19;
   LatiDeg:       0;
   LatiDirection: 'S';
   Longitude:     29;
   LongDeg:       8;
   LongDirection: 'E';
   Superficie:    390580;
   Capital:       'Harare';
   Domain:        '.zw'
  )
 );

Var
 I,J:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

BEGIN
  If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('DOMAIN : Cette commande permet de retourner l''extension de nom ',
                    'de domaine d''un pays');
  WriteLn;
  WriteLn('Syntaxe : DOMAIN [pays]');
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
   For J:=Low(Country) to High(Country)do Begin
    If StrToUpper(StrPas(Country[J].Country))=StrToUpper(ParamStr(I))Then Begin
     WriteLn(StrPas(Country[J].Domain));
    End;
   End;
  End;
 End;
END.