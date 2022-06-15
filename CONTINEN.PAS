{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CONTINEN;

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
  Code2:String[2];
  Code3:String[3];
  Currency:String[3];
  Continent:(None,Antarctique,Afrique,Amerique,Asie,Europe,Oceanie);
 End;

Const
 _Country:Array[0..248]of CountryGeoRecord=(
  (Country:       'Afghanistan';
   Latitude:      33;
   LatiDeg:       55;
   LatiDirection: 'N';
   Longitude:     67;
   LongDeg:       40;
   LongDirection: 'E';
   Superficie:    647500;
   Capital:       'Kaboul';
   Code2:         'AF';
   Code3:         'AFG';
   Currency:      'AFN';
   Continent:     Asie
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
   Code2:         'ZA';
   Code3:         'ZAF';
   Currency:      'ZAR';
   Continent:     Afrique
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
   Code2:         'AL';
   Code3:         'ALB';
   Currency:      'ALL';
   Continent:     Europe
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
   Code2:         'DZ';
   Code3:         'DZA';
   Currency:      'DZD';
   Continent:     Afrique
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
   Code2:         'DE';
   Code3:         'DEU';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'AD';
   Code3:         'AND';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'AO';
   Code3:         'AGO';
   Currency:      'AOA';
   Continent:     Afrique
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
   Code2:         'AI';
   Code3:         'AIA';
   Currency:      'XCD';
   Continent:     Amerique
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
   Code2:         'AQ';
   Code3:         'ATA';
   Currency:      '';
   Continent:     Antarctique
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
   Code2:         'AG';
   Code3:         'ATG';
   Currency:      'XCD';
   Continent:     Amerique
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
   Code2:         'SA';
   Code3:         'SAU';
   Currency:      'SAR';
   Continent:     Asie
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
   Code2:         'AR';
   Code3:         'ARG';
   Currency:      'ARS';
   Continent:     Amerique
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
   Code2:         'AM';
   Code3:         'ARM';
   Currency:      'AMD';
   Continent:     Asie
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
   Code2:         'AW';
   Code3:         'ABW';
   Currency:      'AWG';
   Continent:     Amerique
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
   Code2:         'AU';
   Code3:         'AUS';
   Currency:      'AUD';
   Continent:     Oceanie
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
   Code2:         'AT';
   Code3:         'AUT';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'AZ';
   Code3:         'AZE';
   Currency:      'AZN';
   Continent:     Asie
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
   Code2:         'BS';
   Code3:         'BHS';
   Currency:      'BSD';
   Continent:     Amerique
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
   Code2:         'BH';
   Code3:         'BHR';
   Currency:      'BHD';
   Continent:     Asie
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
   Code2:         'BD';
   Code3:         'BGD';
   Currency:      'BDT';
   Continent:     Asie
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
   Code2:         'BB';
   Code3:         'BRB';
   Currency:      'BBD';
   Continent:     Amerique
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
   Code2:         'BE';
   Code3:         'BEL';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'BZ';
   Code3:         'BLZ';
   Currency:      'BZD';
   Continent:     Amerique
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
   Code2:         'BJ';
   Code3:         'BEN';
   Currency:      'XOF';
   Continent:     Afrique
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
   Code2:         'BM';
   Code3:         'BMU';
   Currency:      'BMD';
   Continent:     Amerique
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
   Code2:         'BT';
   Code3:         'BTN';
   Currency:      'BTN';
   Continent:     Asie
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
   Code2:         'BY';
   Code3:         'BLR';
   Currency:      'BYR';
   Continent:     Europe
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
   Code2:         'BO';
   Code3:         'BOL';
   Currency:      'BOB';
   Continent:     Amerique
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
   Code2:         'BQ';
   Code3:         'BES';
   Currency:      'USD';
   Continent:     Amerique
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
   Code2:         'BA';
   Code3:         'BIH';
   Currency:      'BAM';
   Continent:     Europe
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
   Code2:         'BW';
   Code3:         'BWA';
   Currency:      'BWP';
   Continent:     Afrique
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
   Code2:         'BR';
   Code3:         'BRA';
   Currency:      'BRL';
   Continent:     Amerique
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
   Code2:         'BN';
   Code3:         'BRN';
   Currency:      'BND';
   Continent:     Asie
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
   Code2:         'BG';
   Code3:         'BGR';
   Currency:      'BGN';
   Continent:     Europe
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
   Code2:         'BF';
   Code3:         'BFA';
   Currency:      'XOF';
   Continent:     Afrique
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
   Code2:         'BI';
   Code3:         'BDI';
   Currency:      'BIF';
   Continent:     Afrique
  ),
  (Country:       'Cambodge';
   Latitude:      12;
   LatiDeg:       32;
   LatiDirection: 'N';
   Longitude:     104;
   LongDeg:       59;
   LongDirection: 'E';
   Superficie:    181040;
   Capital:       'Phnom Penh';
   Code2:         'KH';
   Code3:         'KHM';
   Currency:      'KHR';
   Continent:     Asie
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
   Code2:         'CM';
   Code3:         'CMR';
   Currency:      'XAF';
   Continent:     Afrique
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
   Code2:         'CA';
   Code3:         'CAN';
   Currency:      'CAD';
   Continent:     Amerique
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
   Code2:         'CV';
   Code3:         'CPV';
   Currency:      'CVE';
   Continent:     Afrique
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
   Code2:         'CF';
   Code3:         'CAF';
   Currency:      'XAF';
   Continent:     Afrique
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
   Code2:         'CL';
   Code3:         'CHL';
   Currency:      'CLP';
   Continent:     Amerique
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
   Code2:         'CN';
   Code3:         'CHN';
   Currency:      'CNY';
   Continent:     Asie
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
   Code2:         'CY';
   Code3:         'CYP';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'CO';
   Code3:         'COL';
   Currency:      'COP';
   Continent:     Amerique
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
   Code2:         'KM';
   Code3:         'COM';
   Currency:      'KMF';
   Continent:     Afrique
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
   Code2:         'CG';
   Code3:         'COG';
   Currency:      'XAF';
   Continent:     Afrique
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
   Code2:         'KP';
   Code3:         'PRK';
   Currency:      'KPW';
   Continent:     Asie
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
   Code2:         'KR';
   Code3:         'KOR';
   Currency:      'KRW';
   Continent:     Asie
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
   Code2:         'CR';
   Code3:         'CRI';
   Currency:      'CRC';
   Continent:     Amerique
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
   Code2:         'CI';
   Code3:         'CIV';
   Currency:      'XOF';
   Continent:     Afrique
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
   Code2:         'HR';
   Code3:         'HRV';
   Currency:      'HRK';
   Continent:     Europe
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
   Code2:         'CU';
   Code3:         'CUB';
   Currency:      'CUP';
   Continent:     Amerique
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
   Code2:         'CW';
   Code3:         'CUW';
   Currency:      'ANG';
   Continent:     Amerique
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
   Code2:         'DK';
   Code3:         'DNK';
   Currency:      'DKK';
   Continent:     Europe
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
   Code2:         'DJ';
   Code3:         'DJI';
   Currency:      'DJF';
   Continent:     Afrique
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
   Code2:         'DM';
   Code3:         'DMA';
   Currency:      'XCD';
   Continent:     Amerique
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
   Code2:         'EG';
   Code3:         'EGY';
   Currency:      'EGP';
   Continent:     Afrique
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
   Code2:         'AE';
   Code3:         'ARE';
   Currency:      'AED';
   Continent:     Asie
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
   Code2:         'EC';
   Code3:         'ECU';
   Currency:      'USD';
   Continent:     Amerique
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
   Code2:         'ER';
   Code3:         'ERI';
   Currency:      'ERN';
   Continent:     Afrique
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
   Code2:         'ES';
   Code3:         'ESP';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'EE';
   Code3:         'EST';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'US';
   Code3:         'USA';
   Currency:      'USD';
   Continent:     Amerique
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
   Code2:         'ET';
   Code3:         'ETH';
   Currency:      'ETB';
   Continent:     Afrique
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
   Code2:         'FJ';
   Code3:         'FJI';
   Currency:      'FJD';
   Continent:     Oceanie
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
   Code2:         'FI';
   Code3:         'FIN';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'FR';
   Code3:         'FRA';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'GA';
   Code3:         'GAB';
   Currency:      'XAF';
   Continent:     Afrique
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
   Code2:         'GM';
   Code3:         'GMB';
   Currency:      'GMD';
   Continent:     Afrique;
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
   Code2:         'GE';
   Code3:         'GEO';
   Currency:      'GEL';
   Continent:     Asie
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
   Code2:         'GS';
   Code3:         'SGS';
   Currency:      'GBP';
   Continent:     Antarctique
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
   Code2:         'GH';
   Code3:         'GHA';
   Currency:      'GHS';
   Continent:     Afrique
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
   Code2:         'GI';
   Code3:         'GIB';
   Currency:      'GIP';
   Continent:     Europe
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
   Code2:         'GR';
   Code3:         'GRC';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'GD';
   Code3:         'GRD';
   Currency:      'XCD';
   Continent:     Amerique
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
   Code2:         'GL';
   Code3:         'GRL';
   Currency:      'DKK';
   Continent:     Amerique
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
   Code2:         'GP';
   Code3:         'GLP';
   Currency:      'EUR';
   Continent:     Amerique
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
   Code2:         'GU';
   Code3:         'GUM';
   Currency:      'USD';
   Continent:     Oceanie
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
   Code2:         'GT';
   Code3:         'GTM';
   Currency:      'GTQ';
   Continent:     Amerique
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
   Code2:         'GG';
   Code3:         'GGY';
   Currency:      'GBP';
   Continent:     Europe
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
   Code2:         'GN';
   Code3:         'GIN';
   Currency:      'GNF';
   Continent:     Afrique
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
   Code2:         'GQ';
   Code3:         'GNQ';
   Currency:      'XAF';
   Continent:     Afrique
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
   Code2:         'GW';
   Code3:         'GNB';
   Currency:      'XOF';
   Continent:     Afrique
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
   Code2:         'GY';
   Code3:         'GUY';
   Currency:      'GYD';
   Continent:     Amerique
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
   Code2:         'GF';
   Code3:         'GUF';
   Currency:      'EUR';
   Continent:     Amerique
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
   Code2:         'HT';
   Code3:         'HTI';
   Currency:      'HTG';
   Continent:     Amerique
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
   Code2:         'HN';
   Code3:         'HND';
   Currency:      'HNL';
   Continent:     Amerique
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
   Code2:         'HK';
   Code3:         'HKG';
   Currency:      'HKD';
   Continent:     Asie
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
   Code2:         'HU';
   Code3:         'HUN';
   Currency:      'HUF';
   Continent:     Europe
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
   Code2:         'BV';
   Code3:         'BVT';
   Currency:      'NOK';
   Continent:     Antarctique
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
   Code2:         'CX';
   Code3:         'CXR';
   Currency:      'AUD';
   Continent:     Asie
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
   Code2:         'IM';
   Code3:         'IMN';
   Currency:      'GBP';
   Continent:     Europe
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
   Code2:         'HM';
   Code3:         'HMD';
   Currency:      'AUD';
   Continent:     Antarctique
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
   Code2:         'NF';
   Code3:         'NFK';
   Currency:      'AUD';
   Continent:     Oceanie
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
   Code2:         'AX';
   Code3:         'ALA';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'KY';
   Code3:         'CYM';
   Currency:      'KYD';
   Continent:     Amerique
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
   Code2:         'CC';
   Code3:         'CCK';
   Currency:      'AUD';
   Continent:     Asie
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
   Code2:         'CK';
   Code3:         'COK';
   Currency:      'NZD';
   Continent:     Oceanie
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
   Code2:         'FO';
   Code3:         'FRO';
   Currency:      'DKK';
   Continent:     Europe
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
   Code2:         'FK';
   Code3:         'FLK';
   Currency:      'FKP';
   Continent:     Amerique
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
   Code2:         'MP';
   Code3:         'MNP';
   Currency:      'USD';
   Continent:     Oceanie
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
   Code2:         'MH';
   Code3:         'MHL';
   Currency:      'USD';
   Continent:     Oceanie
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
   Code2:         'UM';
   Code3:         'UMI';
   Currency:      'USD';
   Continent:     Oceanie
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
   Code2:         'SB';
   Code3:         'SLB';
   Currency:      'SBD';
   Continent:     Oceanie
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
   Code2:         'TC';
   Code3:         'TCA';
   Currency:      'USD';
   Continent:     Amerique
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
   Code2:         'VG';
   Code3:         'VGB';
   Currency:      'USD';
   Continent:     Amerique
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
   Code2:         'VI';
   Code3:         'VIR';
   Currency:      'USD';
   Continent:     Amerique
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
   Code2:         'IN';
   Code3:         'IND';
   Currency:      'INR';
   Continent:     Asie
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
   Code2:         'ID';
   Code3:         'IDN';
   Currency:      'IDR';
   Continent:     Asie
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
   Code2:         'IQ';
   Code3:         'IRQ';
   Currency:      'IQD';
   Continent:     Asie
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
   Code2:         'IR';
   Code3:         'IRN';
   Currency:      'IRR';
   Continent:     Asie
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
   Code2:         'IE';
   Code3:         'IRL';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'IS';
   Code3:         'ISL';
   Currency:      'ISK';
   Continent:     Europe
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
   Code2:         'IL';
   Code3:         'ISR';
   Currency:      'ILS';
   Continent:     Asie
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
   Code2:         'IT';
   Code3:         'ITA';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'JM';
   Code3:         'JAM';
   Currency:      'JMD';
   Continent:     Amerique
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
   Code2:         'JP';
   Code3:         'JPN';
   Currency:      'JPY';
   Continent:     Asie
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
   Code2:         'JE';
   Code3:         'JEY';
   Currency:      'GPB';
   Continent:     Europe
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
   Code2:         'JO';
   Code3:         'JOR';
   Currency:      'JOD';
   Continent:     Asie
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
   Code2:         'KZ';
   Code3:         'KAZ';
   Currency:      'KZT';
   Continent:     Asie
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
   Code2:         'KE';
   Code3:         'KEN';
   Currency:      'KES';
   Continent:     Afrique
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
   Code2:         'KG';
   Code3:         'KGZ';
   Currency:      'KGS';
   Continent:     Asie
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
   Code2:         'KI';
   Code3:         'KIR';
   Currency:      'AUD';
   Continent:     Oceanie
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
   Code2:         'XK';
   Code3:         'XKX';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'KW';
   Code3:         'KWT';
   Currency:      'KWD';
   Continent:     Asie
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
   Code2:         'LA';
   Code3:         'LAO';
   Currency:      'LAK';
   Continent:     Asie
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
   Code2:         'LS';
   Code3:         'LSO';
   Currency:      'LSL';
   Continent:     Afrique
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
   Code2:         'LV';
   Code3:         'LVA';
   Currency:      'LVL';
   Continent:     Europe
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
   Code2:         'LB';
   Code3:         'LBN';
   Currency:      'LBP';
   Continent:     Asie
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
   Code2:         'LR';
   Code3:         'LBR';
   Currency:      'LRB';
   Continent:     Afrique
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
   Code2:         'LY';
   Code3:         'LBY';
   Currency:      'LYD';
   Continent:     Afrique
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
   Code2:         'LI';
   Code3:         'LIE';
   Currency:      'CHF';
   Continent:     Europe
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
   Code2:         'LT';
   Code3:         'LTU';
   Currency:      'LTL';
   Continent:     Europe
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
   Code2:         'LU';
   Code3:         'LUX';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'MO';
   Code3:         'MAC';
   Currency:      'MOP';
   Continent:     Asie
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
   Code2:         'MK';
   Code3:         'MKD';
   Currency:      'MKD';
   Continent:     Europe
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
   Code2:         'MG';
   Code3:         'MDG';
   Currency:      'MGA';
   Continent:     Afrique
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
   Code2:         'MY';
   Code3:         'MYS';
   Currency:      'MYR';
   Continent:     Asie
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
   Code2:         'MW';
   Code3:         'MWI';
   Currency:      'MWK';
   Continent:     Afrique
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
   Code2:         'MV';
   Code3:         'MDV';
   Currency:      'MVR';
   Continent:     Asie
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
   Code2:         'ML';
   Code3:         'MLI';
   Currency:      'XOF';
   Continent:     Afrique
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
   Code2:         'MT';
   Code3:         'MLT';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'MA';
   Code3:         'MAR';
   Currency:      'MAD';
   Continent:     Afrique
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
   Code2:         'MQ';
   Code3:         'MTQ';
   Currency:      'EUR';
   Continent:     Amerique
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
   Code2:         'MU';
   Code3:         'MUS';
   Currency:      'MUR';
   Continent:     Afrique
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
   Code2:         'MR';
   Code3:         'MRT';
   Currency:      'MRO';
   Continent:     Afrique
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
   Code2:         'YT';
   Code3:         'MYT';
   Currency:      'EUR';
   Continent:     Afrique
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
   Code2:         'MX';
   Code3:         'MEX';
   Currency:      'MXN';
   Continent:     Amerique
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
   Code2:         'FM';
   Code3:         'FSM';
   Currency:      'USD';
   Continent:     Oceanie
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
   Code2:         'MD';
   Code3:         'MDA';
   Currency:      'MDL';
   Continent:     Europe
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
   Code2:         'MC';
   Code3:         'MCO';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'MN';
   Code3:         'MNG';
   Currency:      'MNT';
   Continent:     Asie
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
   Code2:         'ME';
   Code3:         'MNE';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'MS';
   Code3:         'MSR';
   Currency:      'XCD';
   Continent:     Amerique
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
   Code2:         'MZ';
   Code3:         'MOZ';
   Currency:      'MZN';
   Continent:     Afrique
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
   Code2:         'MM';
   Code3:         'MMR';
   Currency:      'MMK';
   Continent:     Asie
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
   Code2:         'NA';
   Code3:         'NAM';
   Currency:      'NAD';
   Continent:     Afrique
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
   Code2:         'NR';
   Code3:         'NRU';
   Currency:      'AUD';
   Continent:     Oceanie
  ),
  (Country:       'Nepal';
   Latitude:      28;
   LatiDeg:       23;
   LatiDirection: 'N';
   Longitude:     84;
   LongDeg:       7;
   LongDirection: 'E';
   Superficie:    140800;
   Capital:       'Katmandou';
   Code2:         'NP';
   Code3:         'NPL';
   Currency:      'NPR';
   Continent:     Asie
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
   Code2:         'NI';
   Code3:         'NIC';
   Currency:      'NIO';
   Continent:     Amerique
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
   Code2:         'NE';
   Code3:         'NER';
   Currency:      'XOR';
   Continent:     Afrique
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
   Code2:         'NG';
   Code3:         'NGA';
   Currency:      'NGN';
   Continent:     Afrique
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
   Code2:         'NU';
   Code3:         'NIU';
   Currency:      'NZD';
   Continent:     Oceanie
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
   Code2:         'NO';
   Code3:         'NOR';
   Currency:      'NOK';
   Continent:     Europe
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
   Code2:         'NC';
   Code3:         'NCL';
   Currency:      'XPF';
   Continent:     Oceanie
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
   Code2:         'NZ';
   Code3:         'NZL';
   Currency:      'NZD';
   Continent:     Oceanie
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
   Code2:         'OM';
   Code3:         'OMN';
   Currency:      'OMR';
   Continent:     Asie
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
   Code2:         'UG';
   Code3:         'UGA';
   Currency:      'UGX';
   Continent:     Afrique
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
   Code2:         'UZ';
   Code3:         'UZB';
   Currency:      'UZS';
   Continent:     Asie
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
   Code2:         'PK';
   Code3:         'PAK';
   Currency:      'PKR';
   Continent:     Asie
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
   Code2:         'PW';
   Code3:         'PLW';
   Currency:      'USD';
   Continent:     Oceanie
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
   Code2:         'PA';
   Code3:         'PAN';
   Currency:      'PAB';
   Continent:     Amerique
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
   Code2:         'PG';
   Code3:         'PNG';
   Currency:      'PGK';
   Continent:     Oceanie
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
   Code2:         'PY';
   Code3:         'PRY';
   Currency:      'PYG';
   Continent:     Amerique
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
   Code2:         'NL';
   Code3:         'NLD';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'PE';
   Code3:         'PER';
   Currency:      'PEN';
   Continent:     Amerique
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
   Code2:         'PH';
   Code3:         'PHL';
   Currency:      'PHP';
   Continent:     Asie
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
   Code2:         'PN';
   Code3:         'PCN';
   Currency:      'NZD';
   Continent:     Oceanie
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
   Code2:         'PL';
   Code3:         'POL';
   Currency:      'PLN';
   Continent:     Europe
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
   Code2:         'PF';
   Code3:         'PYF';
   Currency:      'XPF';
   Continent:     Oceanie
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
   Code2:         'PR';
   Code3:         'PRI';
   Currency:      'USD';
   Continent:     Amerique
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
   Code2:         'PT';
   Code3:         'PRT';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'QA';
   Code3:         'QAT';
   Currency:      'QAR';
   Continent:     Asie
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
   Code2:         'CD';
   Code3:         'COD';
   Currency:      'CDF';
   Continent:     Afrique
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
   Code2:         'DO';
   Code3:         'DOM';
   Currency:      'DOP';
   Continent:     Amerique
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
   Code2:         'TG';
   Code3:         'TGO';
   Currency:      'XOF';
   Continent:     Afrique
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
   Code2:         'RE';
   Code3:         'REU';
   Currency:      'EUR';
   Continent:     Afrique
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
   Code2:         'RO';
   Code3:         'ROU';
   Currency:      'RON';
   Continent:     Europe
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
   Code2:         'GB';
   Code3:         'GBR';
   Currency:      'GBP';
   Continent:     Europe
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
   Code2:         'RU';
   Code3:         'RUS';
   Currency:      'RUB';
   Continent:     Europe
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
   Code2:         'RW';
   Code3:         'RWA';
   Currency:      'RWF';
   Continent:     Afrique
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
   Code2:         'EH';
   Code3:         'ESH';
   Currency:      'MAD';
   Continent:     Afrique
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
   Code2:         'BL';
   Code3:         'BLM';
   Currency:      'EUR';
   Continent:     Amerique
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
   Code2:         'KN';
   Code3:         'KNA';
   Currency:      'XCD';
   Continent:     Amerique
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
   Code2:         'SM';
   Code3:         'SMR';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'MF';
   Code3:         'MAF';
   Currency:      'ANG';
   Continent:     Amerique
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
   Code2:         'PM';
   Code3:         'SPM';
   Currency:      'EUR';
   Continent:     Amerique
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
   Code2:         'VC';
   Code3:         'VCT';
   Currency:      'XCD';
   Continent:     Amerique
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
   Code2:         'SH';
   Code3:         'SHN';
   Currency:      'SHP';
   Continent:     Afrique
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
   Code2:         'LC';
   Code3:         'LCA';
   Currency:      'XCD';
   Continent:     Amerique
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
   Code2:         'SV';
   Code3:         'SLV';
   Currency:      'USD';
   Continent:     Amerique
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
   Code2:         'WS';
   Code3:         'WSM';
   Currency:      'WST';
   Continent:     Oceanie
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
   Code2:         'AS';
   Code3:         'ASM';
   Currency:      'USD';
   Continent:     Oceanie
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
   Code2:         'ST';
   Code3:         'STP';
   Currency:      'STD';
   Continent:     Afrique
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
   Code2:         'SN';
   Code3:         'SEN';
   Currency:      'XOF';
   Continent:     Afrique
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
   Code2:         'RS';
   Code3:         'SRB';
   Currency:      'RSD';
   Continent:     Europe
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
   Code2:         'SC';
   Code3:         'SYC';
   Currency:      'SCR';
   Continent:     Afrique
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
   Code2:         'SL';
   Code3:         'SLE';
   Currency:      'SLL';
   Continent:     Afrique
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
   Code2:         'SG';
   Code3:         'SGP';
   Currency:      'SGD';
   Continent:     Asie
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
   Code2:         'SK';
   Code3:         'SVK';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'SI';
   Code3:         'SVN';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'SO';
   Code3:         'SOM';
   Currency:      'SOS';
   Continent:     Afrique
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
   Code2:         'SD';
   Code3:         'SDN';
   Currency:      'SDG';
   Continent:     Afrique
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
   Code2:         'LK';
   Code3:         'LKA';
   Currency:      'LKR';
   Continent:     Asie
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
   Code2:         'SS';
   Code3:         'SSD';
   Currency:      'SSP';
   Continent:     Afrique
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
   Code2:         'SE';
   Code3:         'SWE';
   Currency:      'SEK';
   Continent:     Europe
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
   Code2:         'CH';
   Code3:         'CHE';
   Currency:      'CHF';
   Continent:     Europe
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
   Code2:         'SR';
   Code3:         'SUR';
   Currency:      'SRD';
   Continent:     Amerique
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
   Code2:         'SJ';
   Code3:         'SJM';
   Currency:      'NOK';
   Continent:     Europe
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
   Code2:         'SZ';
   Code3:         'SWZ';
   Currency:      'SZL';
   Continent:     Afrique
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
   Code2:         'SY';
   Code3:         'SYR';
   Currency:      'SYP';
   Continent:     Asie
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
   Code2:         'TJ';
   Code3:         'TJK';
   Currency:      'TJS';
   Continent:     Asie
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
   Code2:         'TW';
   Code3:         'TWN';
   Currency:      'TWD';
   Continent:     Asie
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
   Code2:         'TZ';
   Code3:         'TZA';
   Currency:      'TZS';
   Continent:     Afrique
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
   Code2:         'TD';
   Code3:         'TCD';
   Currency:      'XAF';
   Continent:     Afrique
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
   Code2:         'CZ';
   Code3:         'CZE';
   Currency:      'CZK';
   Continent:     Europe
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
   Code2:         'TF';
   Code3:         'ATF';
   Currency:      'EUR';
   Continent:     Antarctique
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
   Code2:         'IO';
   Code3:         'IOT';
   Currency:      'USD';
   Continent:     Asie
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
   Code2:         'PS';
   Code3:         'PSE';
   Currency:      'ILS';
   Continent:     Asie
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
   Code2:         'TH';
   Code3:         'THA';
   Currency:      'THB';
   Continent:     Asie
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
   Code2:         'TL';
   Code3:         'TLS';
   Currency:      'USD';
   Continent:     Oceanie
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
   Code2:         'TK';
   Code3:         'TKL';
   Currency:      'NZD';
   Continent:     Oceanie
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
   Code2:         'TO';
   Code3:         'TON';
   Currency:      'TOP';
   Continent:     Oceanie
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
   Code2:         'TT';
   Code3:         'TTO';
   Currency:      'TTD';
   Continent:     Amerique
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
   Code2:         'TN';
   Code3:         'TUN';
   Currency:      'TND';
   Continent:     Afrique
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
   Code2:         'TM';
   Code3:         'TKM';
   Currency:      'TMT';
   Continent:     Asie
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
   Code2:         'TR';
   Code3:         'TUR';
   Currency:      'TRY';
   Continent:     Asie
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
   Code2:         'TV';
   Code3:         'TUV';
   Currency:      'AUD';
   Continent:     Oceanie
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
   Code2:         'UA';
   Code3:         'UKR';
   Currency:      'UAH';
   Continent:     Europe
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
   Code2:         'UY';
   Code3:         'URY';
   Currency:      'UYU';
   Continent:     Amerique
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
   Code2:         'VU';
   Code3:         'VUT';
   Currency:      'VUV';
   Continent:     Oceanie
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
   Code2:         'VA';
   Code3:         'VAT';
   Currency:      'EUR';
   Continent:     Europe
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
   Code2:         'VE';
   Code3:         'VEN';
   Currency:      'VEF';
   Continent:     Amerique
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
   Code2:         'VN';
   Code3:         'VNM';
   Currency:      'VND';
   Continent:     Asie
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
   Code2:         'WF';
   Code3:         'WLF';
   Currency:      'XPF';
   Continent:     Oceanie
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
   Code2:         'YE';
   Code3:         'YEM';
   Currency:      'YER';
   Continent:     Asie
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
   Code2:         'ZM';
   Code3:         'ZMB';
   Currency:      'ZMW';
   Continent:     Afrique
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
   Code2:         'ZW';
   Code3:         'ZWE';
   Currency:      'ZWL';
   Continent:     Afrique
  )
 );

Var
 I,J,K:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

BEGIN
  If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CONTINEN : Cette commande permet de retourner le continent d''un pays');
  WriteLn;
  WriteLn('Syntaxe : CONTINEN [pays]');
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
   For J:=Low(_Country) to High(_Country)do Begin
    If StrToUpper(StrPas(_Country[J].Country))=StrToUpper(ParamStr(I))Then Begin
     WriteLn(PadRight('Nom du pays : ',32),StrPas(_Country[J].Country));
     WriteLn(PadRight('Code a deux lettres du pays : ',32),_Country[J].Code2);
     WriteLn(PadRight('Code a trois lettres du pays : ',32),_Country[J].Code3);
     Write(PadRight('Nom du continent : ',32));
     Case _Country[J].Continent of
      Afrique:WriteLn('Afrique');
      Antarctique:Write('Antarctique');
      Asie:WriteLn('Asie');
      Amerique:WriteLn('Amerique');
      Europe:WriteLn('Europe');
      Oceanie:WriteLn('Oceanie');
     End;
    End;
   End;
  End;
 End;
END.
