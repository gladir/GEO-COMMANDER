{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program TIMEZONE;

Uses
 Dos;

Type
 TTimeZone=Record
  Country:String[30];
  Code2:String[2];
  Code3:String[3];
  MinTZ,MaxTZ:String[9];
 End;

Const
 TimeZones:Array[1..242] of TTimeZone=(
  (Country:'Afghanistan'; Code2: 'AF'; Code3: 'AFG'; MinTZ: 'UTC+04:30'; MaxTZ: 'UTC+04:30'),
  (Country:'Afrique du Sud'; Code2: 'ZA'; Code3: 'ZAF'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Albanie'; Code2: 'AL'; Code3: 'ALB'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'AlgÇrie'; Code2: 'DZ'; Code3: 'DZA'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Allemagne'; Code2: 'DE'; Code3: 'DEU'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Andorre'; Code2: 'AD'; Code3: 'AND'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Angola'; Code2: 'AO'; Code3: 'AGO'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Anguilla'; Code2: 'AI'; Code3: 'AIA'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Antarctique'; Code2: 'AQ'; Code3: 'AQ'; MinTZ: 'UTC-12:00'; MaxTZ: 'UTC+12:00'),
  (Country:'Antigua-et-Barbuda'; Code2: 'AG'; Code3: 'ATG'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Antilles nÇerlandaises'; Code2: 'AN'; Code3: 'ANT'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Arabie Saoudite'; Code2: 'SA'; Code3: 'SAU'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Argentine'; Code2: 'AR'; Code3: 'ARG'; MinTZ: 'UTC-03:00'; MaxTZ: 'UTC-03:00'),
  (Country:'ArmÇnie'; Code2: 'AM'; Code3: 'ARM'; MinTZ: 'UTC+04:00'; MaxTZ: 'UTC+04:00'),
  (Country:'Aruba'; Code2: 'AW'; Code3: 'ABW'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'RÇgion Asie/Pacifique'; Code2: 'AP'; Code3: 'AP'; MinTZ: 'UTC+07:00'; MaxTZ: 'UTC+10:00'),
  (Country:'Australie'; Code2: 'AU'; Code3: 'AUS'; MinTZ: 'UTC+08:00'; MaxTZ: 'UTC+11:00'),
  (Country:'Autriche'; Code2: 'AT'; Code3: 'AUT'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Azerbaãdjan'; Code2: 'AZ'; Code3: 'AZE'; MinTZ: 'UTC+04:00'; MaxTZ: 'UTC+04:00'),
  (Country:'Bahamas'; Code2: 'BS'; Code3: 'BHS'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-05:00'),
  (Country:'Bahreãn'; Code2: 'BH'; Code3: 'BHR'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Bangladesh'; Code2: 'BD'; Code3: 'BGD'; MinTZ: 'UTC+06:00'; MaxTZ: 'UTC+06:00'),
  (Country:'Barbade'; Code2: 'BB'; Code3: 'BRB'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Belgique'; Code2: 'BE'; Code3: 'BEL'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Belize'; Code2: 'BZ'; Code3: 'BLZ'; MinTZ: 'UTC-06:00'; MaxTZ: 'UTC-06:00'),
  (Country:'BÇnin'; Code2: 'BJ'; Code3: 'BEN'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Bermudes'; Code2: 'BM'; Code3: 'BMU'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-03:00'),
  (Country:'Bhoutan'; Code2: 'BT'; Code3: 'BTN'; MinTZ: 'UTC+06:00'; MaxTZ: 'UTC+06:00'),
  (Country:'BiÇlorussie'; Code2: 'BY'; Code3: 'BLR'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Bolivie'; Code2: 'BO'; Code3: 'BOL'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Bosnie et HerzÇgovine'; Code2: 'BA'; Code3: 'BIH'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Bouvet Island'; Code2: 'BV'; Code3: 'BVT'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'BrÇsil'; Code2: 'BR'; Code3: 'BRA'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-02:00'),
  (Country:'Brunei'; Code2: 'BN'; Code3: 'BRN'; MinTZ: 'UTC+08:00'; MaxTZ: 'UTC+08:00'),
  (Country:'Bulgarie'; Code2: 'BG'; Code3: 'BGR'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Burkina-Faso'; Code2: 'BF'; Code3: 'BFA'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Burundi'; Code2: 'BI'; Code3: 'BDI'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Cambodge'; Code2: 'KH'; Code3: 'KHM'; MinTZ: 'UTC+07:00'; MaxTZ: 'UTC+07:00'),
  (Country:'Cameroun'; Code2: 'CM'; Code3: 'CMR'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Canada'; Code2: 'CA'; Code3: 'CAN'; MinTZ: 'UTC-08:00'; MaxTZ: 'UTC-03:30'),
  (Country:'Cap-Vert'; Code2: 'CV'; Code3: 'CPV'; MinTZ: 'UTC-01:00'; MaxTZ: 'UTC-01:00'),
  (Country:'Chili'; Code2: 'CL'; Code3: 'CHL'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-03:00'),
  (Country:'Chine'; Code2: 'CN'; Code3: 'CHN'; MinTZ: 'UTC+08:00'; MaxTZ: 'UTC+08:00'),
  (Country:'Chypre'; Code2: 'CY'; Code3: 'CYP'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Colombie'; Code2: 'CO'; Code3: 'COL'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-05:00'),
  (Country:'Comores'; Code2: 'KM'; Code3: 'COM'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Congo'; Code2: 'CG'; Code3: 'COG'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Congo, RÇpublique dÇmocratique du (Zaãre)'; Code2: 'CD'; Code3: 'COD'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'CorÇe, RÇpublique de'; Code2: 'KR'; Code3: 'KOR'; MinTZ: 'UTC+09:00'; MaxTZ: 'UTC+09:00'),
  (Country:'CorÇe, RÇpublique dÇmocratique populaire de'; Code2: 'KP'; Code3: 'PRK'; MinTZ: 'UTC+09:00'; MaxTZ: 'UTC+09:00'),
  (Country:'Costa Rica'; Code2: 'CR'; Code3: 'CRI'; MinTZ: 'UTC-06:00'; MaxTZ: 'UTC-06:00'),
  (Country:'Cìte D''Ivoire'; Code2: 'CI'; Code3: 'CIV'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Croatie'; Code2: 'HR'; Code3: 'HRV'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Cuba'; Code2: 'CU'; Code3: 'CUB'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Danemark'; Code2: 'DK'; Code3: 'DNK'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC+01:00'),
  (Country:'DÇpendances amÇricaines du Pacifique'; Code2: 'UM'; Code3: 'UM'; MinTZ: 'UTC-10:00'; MaxTZ: 'UTC-10:00'),
  (Country:'Djibouti'; Code2: 'DJ'; Code3: 'DJI'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Dominique (la)'; Code2: 'DM'; Code3: 'DMA'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'êgypte'; Code2: 'EG'; Code3: 'EGY'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'êmirats Arabes Unis'; Code2: 'AE'; Code3: 'ARE'; MinTZ: 'UTC+04:00'; MaxTZ: 'UTC+04:00'),
  (Country:'êquateur'; Code2: 'EC'; Code3: 'ECU'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-05:00'),
  (Country:'êrythrÇe'; Code2: 'ER'; Code3: 'ERI'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Espagne'; Code2: 'ES'; Code3: 'ESP'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Estonie'; Code2: 'EE'; Code3: 'EST'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'êtat de la citÇ du Vatican'; Code2: 'VA'; Code3: 'VAT'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Etats-Unis'; Code2: 'US'; Code3: 'USA'; MinTZ: 'UTC-12:00'; MaxTZ: 'UTC+12:00'),
  (Country:'êthiopie'; Code2: 'ET'; Code3: 'ETH'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Europe'; Code2: 'EU'; Code3: 'EU'; MinTZ: 'UTC-01:00'; MaxTZ: 'UTC+03:00'),
  (Country:'FÇdÇration de Russie'; Code2: 'RU'; Code3: 'RUS'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+12:00'),
  (Country:'Finlande'; Code2: 'FI'; Code3: 'FIN'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'France'; Code2: 'FR'; Code3: 'FRA'; MinTZ: 'UTC-10:00'; MaxTZ: 'UTC+12:00'),
  (Country:'Gabon'; Code2: 'GA'; Code3: 'GAB'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Gambie'; Code2: 'GM'; Code3: 'GMB'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'GÇorgie'; Code2: 'GE'; Code3: 'GEO'; MinTZ: 'UTC+04:00'; MaxTZ: 'UTC+04:00'),
  (Country:'GÇorgie du Sud et Sandwich du Sud (Iles)'; Code2: 'GS'; Code3: 'GS'; MinTZ: 'UTC-02:00'; MaxTZ: 'UTC-02:00'),
  (Country:'Ghana'; Code2: 'GH'; Code3: 'GHA'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Gibraltar'; Code2: 'GI'; Code3: 'GIB'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Gräce'; Code2: 'GR'; Code3: 'GRC'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Grenade'; Code2: 'GD'; Code3: 'GRD'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Groenland'; Code2: 'GL'; Code3: 'GRL'; MinTZ: 'UTC-03:00'; MaxTZ: 'UTC-01:00'),
  (Country:'Guadeloupe'; Code2: 'GP'; Code3: 'GLP'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Guam'; Code2: 'GU'; Code3: 'GUM'; MinTZ: 'UTC+10:00'; MaxTZ: 'UTC+10:00'),
  (Country:'Guatemala'; Code2: 'GT'; Code3: 'GTM'; MinTZ: 'UTC-06:00'; MaxTZ: 'UTC-06:00'),
  (Country:'GuinÇe'; Code2: 'GN'; Code3: 'GIN'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'GuinÇe êquatoriale'; Code2: 'GQ'; Code3: 'GNQ'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'GuinÇe-Bissau'; Code2: 'GW'; Code3: 'GNB'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Guyane'; Code2: 'GY'; Code3: 'GUY'; MinTZ: 'UTC-03:00'; MaxTZ: 'UTC-03:00'),
  (Country:'Guyane franáaise'; Code2: 'GF'; Code3: 'GUF'; MinTZ: 'UTC-03:00'; MaxTZ: 'UTC-03:00'),
  (Country:'Haãti'; Code2: 'HT'; Code3: 'HTI'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-05:00'),
  (Country:'Honduras (le)'; Code2: 'HN'; Code3: 'HND'; MinTZ: 'UTC-06:00'; MaxTZ: 'UTC-06:00'),
  (Country:'Hong Kong'; Code2: 'HK'; Code3: 'HKG'; MinTZ: 'UTC+08:00'; MaxTZ: 'UTC+08:00'),
  (Country:'Hongrie'; Code2: 'HU'; Code3: 'HUN'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Ile Christmas'; Code2: 'CX'; Code3: 'CX'; MinTZ: 'UTC+07:00'; MaxTZ: 'UTC+07:00'),
  (Country:'Ile de Norfolk'; Code2: 'NF'; Code3: 'NFK'; MinTZ: 'UTC+11:00'; MaxTZ: 'UTC+11:00'),
  (Country:'Ile Maurice'; Code2: 'MU'; Code3: 'MUS'; MinTZ: 'UTC+04:00'; MaxTZ: 'UTC+04:00'),
  (Country:'Iles Bouvet'; Code2: 'BW'; Code3: 'BWA'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Iles Caãmans'; Code2: 'KY'; Code3: 'CYM'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-05:00'),
  (Country:'Iles Cocos-Keeling'; Code2: 'CC'; Code3: 'CC'; MinTZ: 'UTC+06:00'; MaxTZ: 'UTC+06:00'),
  (Country:'Iles Cook'; Code2: 'CK'; Code3: 'COK'; MinTZ: 'UTC-10:00'; MaxTZ: 'UTC-10:00'),
  (Country:'Iles FÇroÇ'; Code2: 'FO'; Code3: 'FRO'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Iles Fidji'; Code2: 'FJ'; Code3: 'FJI'; MinTZ: 'UTC+12:00'; MaxTZ: 'UTC+13:00'),
  (Country:'Iles Heard et Iles McDonald'; Code2: 'HM'; Code3: 'HM'; MinTZ: 'UTC+05:00'; MaxTZ: 'UTC+05:00'),
  (Country:'Iles Malouines'; Code2: 'FK'; Code3: 'FLK'; MinTZ: 'UTC-03:00'; MaxTZ: 'UTC-03:00'),
  (Country:'Iles Marshall'; Code2: 'MH'; Code3: 'MHL'; MinTZ: 'UTC+12:00'; MaxTZ: 'UTC+12:00'),
  (Country:'Iles Salomon'; Code2: 'SB'; Code3: 'SLB'; MinTZ: 'UTC+11:00'; MaxTZ: 'UTC+11:00'),
  (Country:'Iles Tokelau'; Code2: 'TK'; Code3: 'TKL'; MinTZ: 'UTC+13:00'; MaxTZ: 'UTC+13:00'),
  (Country:'Iles Turks et Caãcos'; Code2: 'TC'; Code3: 'TCA'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-05:00'),
  (Country:'Iles Vierges amÇricaines'; Code2: 'VI'; Code3: 'VIR'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Iles Vierges britanniques'; Code2: 'VG'; Code3: 'VGB'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Inde'; Code2: 'IN'; Code3: 'IND'; MinTZ: 'UTC+05:30'; MaxTZ: 'UTC+05:30'),
  (Country:'IndonÇsie'; Code2: 'ID'; Code3: 'IDN'; MinTZ: 'UTC+07:00'; MaxTZ: 'UTC+09:00'),
  (Country:'Irak'; Code2: 'IQ'; Code3: 'IRQ'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Iran'; Code2: 'IR'; Code3: 'IRN'; MinTZ: 'UTC+03:30'; MaxTZ: 'UTC+03:30'),
  (Country:'Irlande'; Code2: 'IE'; Code3: 'IRL'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Islande'; Code2: 'IS'; Code3: 'ISL'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Israâl'; Code2: 'IL'; Code3: 'ISR'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Italie'; Code2: 'IT'; Code3: 'ITA'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Jamahiriya arabe libyenne (Lybie)'; Code2: 'LY'; Code3: 'LBY'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Jamaãque'; Code2: 'JM'; Code3: 'JAM'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-05:00'),
  (Country:'Japon'; Code2: 'JP'; Code3: 'JPN'; MinTZ: 'UTC+09:00'; MaxTZ: 'UTC+09:00'),
  (Country:'Jordanie'; Code2: 'JO'; Code3: 'JOR'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Kazakhstan'; Code2: 'KZ'; Code3: 'KAZ'; MinTZ: 'UTC+05:00'; MaxTZ: 'UTC+06:00'),
  (Country:'Kenya'; Code2: 'KE'; Code3: 'KEN'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Kirghizistan'; Code2: 'KG'; Code3: 'KGZ'; MinTZ: 'UTC+06:00'; MaxTZ: 'UTC+06:00'),
  (Country:'Kiribati'; Code2: 'KI'; Code3: 'KIR'; MinTZ: 'UTC+12:00'; MaxTZ: 'UTC+12:00'),
  (Country:'Koweãt'; Code2: 'KW'; Code3: 'KWT'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Laos, RÇpublique DÇmocratique populaire du'; Code2: 'LA'; Code3: 'LAO'; MinTZ: 'UTC+07:00'; MaxTZ: 'UTC+07:00'),
  (Country:'Lesotho'; Code2: 'LS'; Code3: 'LSO'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Lettonie'; Code2: 'LV'; Code3: 'LVA'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'LibÇria'; Code2: 'LR'; Code3: 'LBR'; MinTZ: 'UTC-00:00'; MaxTZ: 'UTC-00:00'),
  (Country:'Liechtenstein'; Code2: 'LI'; Code3: 'LIE'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Lituanie'; Code2: 'LT'; Code3: 'LTU'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Luxembourg'; Code2: 'LU'; Code3: 'LUX'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Macao'; Code2: 'MO'; Code3: 'MAC'; MinTZ: 'UTC+08:00'; MaxTZ: 'UTC+08:00'),
  (Country:'MacÇdoine'; Code2: 'MK'; Code3: 'MKD'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Madagascar'; Code2: 'MG'; Code3: 'MDG'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Malaisie'; Code2: 'MY'; Code3: 'MYS'; MinTZ: 'UTC+08:00'; MaxTZ: 'UTC+08:00'),
  (Country:'Malawi'; Code2: 'MW'; Code3: 'MWI'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Maldives'; Code2: 'MV'; Code3: 'MDV'; MinTZ: 'UTC+05:00'; MaxTZ: 'UTC+05:00'),
  (Country:'Mali'; Code2: 'ML'; Code3: 'MLI'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Malte'; Code2: 'MT'; Code3: 'MLT'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Mariannes du Nord'; Code2: 'MP'; Code3: 'MNP'; MinTZ: 'UTC+10:00'; MaxTZ: 'UTC+10:00'),
  (Country:'Maroc'; Code2: 'MA'; Code3: 'MAR'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Martinique'; Code2: 'MQ'; Code3: 'MTQ'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Mauritanie'; Code2: 'MR'; Code3: 'MRT'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Mayotte'; Code2: 'YT'; Code3: 'YT'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Mexique'; Code2: 'MX'; Code3: 'MEX'; MinTZ: 'UTC-06:00'; MaxTZ: 'UTC-08:00'),
  (Country:'MicronÇsie'; Code2: 'FM'; Code3: 'FSM'; MinTZ: 'UTC+10:00'; MaxTZ: 'UTC+11:00'),
  (Country:'Moldavie'; Code2: 'MD'; Code3: 'MDA'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Monaco'; Code2: 'MC'; Code3: 'MCO'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Mongolie'; Code2: 'MN'; Code3: 'MNG'; MinTZ: 'UTC+08:00'; MaxTZ: 'UTC+08:00'),
  (Country:'Montserrat'; Code2: 'MS'; Code3: 'MSR'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Mozambique'; Code2: 'MZ'; Code3: 'MOZ'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Myanmar (Union de)'; Code2: 'MM'; Code3: 'MMR'; MinTZ: 'UTC+06:30'; MaxTZ: 'UTC+06:30'),
  (Country:'Namibie'; Code2: 'NA'; Code3: 'NAM'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Nauru'; Code2: 'NR'; Code3: 'NRU'; MinTZ: 'UTC+12:00'; MaxTZ: 'UTC+12:00'),
  (Country:'NÇpal'; Code2: 'NP'; Code3: 'NPL'; MinTZ: 'UTC+05:45'; MaxTZ: 'UTC+05:45'),
  (Country:'Nicaragua'; Code2: 'NI'; Code3: 'NIC'; MinTZ: 'UTC-06:00'; MaxTZ: 'UTC-06:00'),
  (Country:'Niger'; Code2: 'NE'; Code3: 'NER'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'NigÇria'; Code2: 'NG'; Code3: 'NGA'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Niue'; Code2: 'NU'; Code3: 'NIU'; MinTZ: 'UTC-11:00'; MaxTZ: 'UTC-11:00'),
  (Country:'Norväge'; Code2: 'NO'; Code3: 'NOR'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Nouvelle CalÇdonie'; Code2: 'NC'; Code3: 'NCL'; MinTZ: 'UTC+11:00'; MaxTZ: 'UTC+11:00'),
  (Country:'Nouvelle ZÇlande'; Code2: 'NZ'; Code3: 'NZL'; MinTZ: 'UTC+12:00'; MaxTZ: 'UTC+13:00'),
  (Country:'Oman'; Code2: 'OM'; Code3: 'OMN'; MinTZ: 'UTC+04:00'; MaxTZ: 'UTC+04:00'),
  (Country:'OuzbÇkistan'; Code2: 'UZ'; Code3: 'UZB'; MinTZ: 'UTC+05:00'; MaxTZ: 'UTC+05:00'),
  (Country:'Pakistan'; Code2: 'PK'; Code3: 'PAK'; MinTZ: 'UTC+05:00'; MaxTZ: 'UTC+05:00'),
  (Country:'Palau'; Code2: 'PW'; Code3: 'PLW'; MinTZ: 'UTC+09:00'; MaxTZ: 'UTC+09:00'),
  (Country:'Territoire Palestinien, OccupÇ'; Code2: 'PS'; Code3: 'PSE'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Panama'; Code2: 'PA'; Code3: 'PAN'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-05:00'),
  (Country:'Papouasie Nouvelle-GuinÇe'; Code2: 'PG'; Code3: 'PNG'; MinTZ: 'UTC+10:00'; MaxTZ: 'UTC+10:00'),
  (Country:'Paraguay'; Code2: 'PY'; Code3: 'PRY'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-03:00'),
  (Country:'Pays-Bas'; Code2: 'NL'; Code3: 'NLD'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'PÇrou'; Code2: 'PE'; Code3: 'PER'; MinTZ: 'UTC-05:00'; MaxTZ: 'UTC-05:00'),
  (Country:'Philippines'; Code2: 'PH'; Code3: 'PHL'; MinTZ: 'UTC+08:00'; MaxTZ: 'UTC+08:00'),
  (Country:'Pitcairn'; Code2: 'PN'; Code3: 'PCN'; MinTZ: 'UTC-08:00'; MaxTZ: 'UTC-08:00'),
  (Country:'Pologne'; Code2: 'PL'; Code3: 'POL'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'PolynÇsie franáaise'; Code2: 'PF'; Code3: 'PYF'; MinTZ: 'UTC-10:00'; MaxTZ: 'UTC-10:00'),
  (Country:'Porto Rico'; Code2: 'PR'; Code3: 'PRI'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Portugal'; Code2: 'PT'; Code3: 'PRT'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Qatar'; Code2: 'QA'; Code3: 'QAT'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'RÇpublique arabe syrienne'; Code2: 'SY'; Code3: 'SYR'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'RÇpublique Centrafricaine'; Code2: 'CF'; Code3: 'CAF'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'RÇpublique Dominicaine'; Code2: 'DO'; Code3: 'DOM'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'RÇpublique tchäque'; Code2: 'CZ'; Code3: 'CZE'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+02:00'),
  (Country:'RÇunion (Ile de la)'; Code2: 'RE'; Code3: 'REU'; MinTZ: 'UTC+04:00'; MaxTZ: 'UTC+04:00'),
  (Country:'Roumanie'; Code2: 'RO'; Code3: 'ROU'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Royaume-Uni'; Code2: 'GB'; Code3: 'GBR'; MinTZ: 'UTC-08:00'; MaxTZ: 'UTC+14:00'),
  (Country:'Russie'; Code2: 'RU'; Code3: 'RUS'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+12:00'),
  (Country:'Rwanda'; Code2: 'RW'; Code3: 'RWA'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Saint-Christopher et Nevis (Iles)'; Code2: 'KN'; Code3: 'KNA'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Saint-Marin'; Code2: 'SM'; Code3: 'SMR'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Saint-Pierre-et-Miquelon'; Code2: 'PM'; Code3: 'SPM'; MinTZ: 'UTC-03:00'; MaxTZ: 'UTC-03:00'),
  (Country:'Saint-Vincent et les Grenadines'; Code2: 'VC'; Code3: 'VCT'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Sainte HÇläne'; Code2: 'SH'; Code3: 'SHN'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Sainte-Lucie'; Code2: 'LC'; Code3: 'LCA'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Salvador'; Code2: 'SV'; Code3: 'SLV'; MinTZ: 'UTC-03:00'; MaxTZ: 'UTC-03:00'),
  (Country:'Samoa'; Code2: 'WS'; Code3: 'WSM'; MinTZ: 'UTC-11:00'; MaxTZ: 'UTC-11:00'),
  (Country:'Samoa amÇricaines'; Code2: 'AS'; Code3: 'ASM'; MinTZ: 'UTC-11:00'; MaxTZ: 'UTC-11:00'),
  (Country:'Sao TomÇ et Prince'; Code2: 'ST'; Code3: 'STP'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'SÇnÇgal'; Code2: 'SN'; Code3: 'SEN'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Seychelles'; Code2: 'SC'; Code3: 'SYC'; MinTZ: 'UTC+04:00'; MaxTZ: 'UTC+04:00'),
  (Country:'Sierra Leone'; Code2: 'SL'; Code3: 'SLE'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Singapour'; Code2: 'SG'; Code3: 'SGP'; MinTZ: 'UTC+08:00'; MaxTZ: 'UTC+08:00'),
  (Country:'Slovaquie'; Code2: 'SK'; Code3: 'SVK'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'SlovÇnie'; Code2: 'SI'; Code3: 'SVN'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Somalie'; Code2: 'SO'; Code3: 'SOM'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Soudan'; Code2: 'SD'; Code3: 'SDN'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Sri Lanka'; Code2: 'LK'; Code3: 'LKA'; MinTZ: 'UTC+05:30'; MaxTZ: 'UTC+05:30'),
  (Country:'Suäde'; Code2: 'SE'; Code3: 'SWE'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Suisse'; Code2: 'CH'; Code3: 'CHE'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Suriname'; Code2: 'SR'; Code3: 'SUR'; MinTZ: 'UTC-03:00'; MaxTZ: 'UTC-03:00'),
  (Country:'Svalbard'; Code2: 'SJ'; Code3: 'SJM'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Swaziland'; Code2: 'SZ'; Code3: 'SWZ'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Taiwan'; Code2: 'TW'; Code3: 'TWN'; MinTZ: 'UTC+08:00'; MaxTZ: 'UTC+08:00'),
  (Country:'Tajikistan'; Code2: 'TJ'; Code3: 'TJK'; MinTZ: 'UTC+05:00'; MaxTZ: 'UTC+05:00'),
  (Country:'Tanzanie'; Code2: 'TZ'; Code3: 'TZA'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Tchad'; Code2: 'TD'; Code3: 'TCD'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Terres Australes franáaises'; Code2: 'TF'; Code3: 'TF'; MinTZ: 'UTC+05:00'; MaxTZ: 'UTC+05:00'),
  (Country:'Territoires Britanniques de l''ocÇan Indien'; Code2: 'IO'; Code3: 'IO'; MinTZ: 'UTC+06:00'; MaxTZ: 'UTC+06:00'),
  (Country:'Thaãlande'; Code2: 'TH'; Code3: 'THA'; MinTZ: 'UTC+07:00'; MaxTZ: 'UTC+07:00'),
  (Country:'Timor oriental'; Code2: 'TP'; Code3: 'TON'; MinTZ: 'UTC+09:00'; MaxTZ: 'UTC+09:00'),
  (Country:'Togo'; Code2: 'TG'; Code3: 'TGO'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'Tonga'; Code2: 'TO'; Code3: 'TUN'; MinTZ: 'UTC+13:00'; MaxTZ: 'UTC+13:00'),
  (Country:'TrinitÇ-et-Tobago'; Code2: 'TT'; Code3: 'TTO'; MinTZ: 'UTC-04:00'; MaxTZ: 'UTC-04:00'),
  (Country:'Tunisie'; Code2: 'TN'; Code3: 'TKM'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'TurkmÇnistan'; Code2: 'TM'; Code3: 'TLS'; MinTZ: 'UTC+05:00'; MaxTZ: 'UTC+05:00'),
  (Country:'Turquie'; Code2: 'TR'; Code3: 'TUR'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Tuvalu (Iles)'; Code2: 'TV'; Code3: 'TUV'; MinTZ: 'UTC+12:00'; MaxTZ: 'UTC+12:00'),
  (Country:'Uganda'; Code2: 'UG'; Code3: 'UGA'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'USA'; Code2: 'US'; Code3: 'USA'; MinTZ: 'UTC-12:00'; MaxTZ: 'UTC+12:00'),
  (Country:'Uruguay'; Code2: 'UY'; Code3: 'URY'; MinTZ: 'UTC-03:00'; MaxTZ: 'UTC-03:00'),
  (Country:'Vanuatu'; Code2: 'VU'; Code3: 'VUT'; MinTZ: 'UTC+11:00'; MaxTZ: 'UTC+11:00'),
  (Country:'Venezuela'; Code2: 'VE'; Code3: 'VEN'; MinTZ: 'UTC-04:30'; MaxTZ: 'UTC-04:30'),
  (Country:'Vietnam'; Code2: 'VN'; Code3: 'VNM'; MinTZ: 'UTC+07:00'; MaxTZ: 'UTC+07:00'),
  (Country:'Wallis et Futuna'; Code2: 'WF'; Code3: 'WLF'; MinTZ: 'UTC+12:00'; MaxTZ: 'UTC+12:00'),
  (Country:'Western Sahara'; Code2: 'EH'; Code3: 'ESH'; MinTZ: 'UTC+00:00'; MaxTZ: 'UTC+00:00'),
  (Country:'YÇmen'; Code2: 'YE'; Code3: 'YEM'; MinTZ: 'UTC+03:00'; MaxTZ: 'UTC+03:00'),
  (Country:'Yougoslavie'; Code2: 'YU'; Code3: 'YUG'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Zaãre'; Code2: 'ZR'; Code3: 'ZR'; MinTZ: 'UTC+01:00'; MaxTZ: 'UTC+01:00'),
  (Country:'Zambie'; Code2: 'ZM'; Code3: 'ZMB'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00'),
  (Country:'Zimbabwe'; Code2: 'ZW'; Code3: 'ZWE'; MinTZ: 'UTC+02:00'; MaxTZ: 'UTC+02:00')

 );

Var
 i:Integer;
 CountryParam:String;
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
  WriteLn('TIMEZONE : Cette commande permet de retourner ',
          'le fuseau horaire du pays spÇcifiÇ');
  WriteLn;
  Writeln('Syntaxe: TIMEZONE <CountryName>');
  WriteLn;
  WriteLn(' CountryName  Ce paramätre permet d''indiquer le nom du pays.');
 End
  Else
 If ParamCount>0Then Begin
  CountryParam:=StrToUpper(ParamStr(1));
  Found:=False;
  For i:=1 to High(TimeZones) do Begin
   If StrToUpper(TimeZones[i].Country)=StrToUpper(CountryParam)Then Begin
    Writeln('Pays : ', TimeZones[i].Country);
    Writeln('Fuseau minimum : ', TimeZones[i].MinTZ);
    Writeln('Fuseau maximum : ', TimeZones[i].MaxTZ);
    Found:=True;
    Break;
   End;
  End;
  If Not(Found)Then Writeln('Pays non trouvÇ');
 End
  Else
 WriteLn('Paramätre requis !');
END.