{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program POPUL;

{$E+,N+}

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
  Population1951:LongInt;
  Population1956:LongInt;
  Population1961:LongInt;
  Population1966:LongInt;
  Population1971:LongInt;
  Population1975:LongInt;
  Population1979:LongInt;
  Population1985:LongInt;
  Population1990:LongInt;
  Population1995:LongInt;
  Population2000:LongInt;
  Population2005:LongInt;
  Population2010:LongInt;
  Population2015:LongInt;
  Population2022:LongInt;
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
   Population1951:7796496;
   Population1956:8335282;
   Population1961:9083895;
   Population1966:10066477;
   Population1971:11325792;
   Population1975:12552197;
   Population1979:13376417;
   Population1985:12070161;
   Population1990:12142825;
   Population1995:17597448;
   Population2000:20477066;
   Population2005:25194293;
   Population2010:28793408;
   Population2015:33896489;
   Population2022:40846424

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
   Population1951:13776390;
   Population1956:15382808;
   Population1961:17313930;
   Population1966:19638617;
   Population1971:22369971;
   Population1975:24876503;
   Population1979:28480000;
   Population1985:32263673;
   Population1990:36368859;
   Population1995:41003493;
   Population2000:44654851;
   Population2005:47588523;
   Population2010:50850031;
   Population2015:54968738;
   Population2022:49000000
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
   Population1951:1275432;
   Population1956:1439660;
   Population1961:1661213;
   Population1966:1922218;
   Population1971:2176657;
   Population1975:2385510;
   Population1979:2670000;
   Population1985:2937176;
   Population1990:3272107;
   Population1995:3129582;
   Population2000:3125991;
   Population2005:3095777;
   Population2010:2960434;
   Population2015:2893392;
   Population2022:2877275

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
   Population1951:8948377;
   Population1956:9890846;
   Population1961:11198244;
   Population1966:12728199;
   Population1971:14670296;
   Population1975:16380247;
   Population1979:18377275;
   Population1985:22100287;
   Population1990:25435214;
   Population1995:28488018;
   Population2000:30833966;
   Population2005:32922817;
   Population2010:35658311;
   Population2015:39329159;
   Population2022:45137119
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
   Population1951:70134503;
   Population1956:71694905;
   Population1961:73673265;
   Population1966:76541110;
   Population1971:78685025;
   Population1975:78882698;
   Population1979:78505323;
   Population1985:77686980;
   Population1990:78858760;
   Population1995:80987047;
   Population2000:81395439;
   Population2005:81624427;
   Population2010:80863181;
   Population2015:81620276;
   Population2022:83756658
  ),
  (Country:      'Andorre';
   Latitude:      42;
   LatiDeg:       32;
   LatiDirection: 'N';
   Longitude:     1;
   LongDeg:       35;
   LongDirection: 'E';
   Superficie:    468;
   Capital:       'Andorre-la-Vieille';
   Population1951:6448;
   Population1956:9610;
   Population1961:13898;
   Population1966:19099;
   Population1971:24928;
   Population1975:30115;
   Population1979:34289;
   Population1985:43657;
   Population1990:53488;
   Population1995:63273;
   Population2000:64882;
   Population2005:77571;
   Population2010:84457;
   Population2015:78598;
   Population2022:77718
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
   Population1951:4582568;
   Population1956:5092347;
   Population1961:5493509;
   Population1966:5775983;
   Population1971:5966420;
   Population1975:6893887;
   Population1979:7925542;
   Population1985:9789802;
   Population1990:11653202;
   Population1995:13726293;
   Population2000:16132618;
   Population2005:19098647;
   Population2010:22938721;
   Population2015:27416950;
   Population2022:13068161
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
   Population1951:5220;
   Population1956:5814;
   Population1961:6055;
   Population1966:6397;
   Population1971:6814;
   Population1975:7131;
   Population1979:7291;
   Population1985:7237;
   Population1990:8739;
   Population1995:9765;
   Population2000:11114;
   Population2005:12337;
   Population2010:13343;
   Population2015:14197;
   Population2022:15594
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
   Population1951:0;
   Population1956:0;
   Population1961:0;
   Population1966:0;
   Population1971:0;
   Population1975:0;
   Population1979:0;
   Population1985:0;
   Population1990:0;
   Population1995:0;
   Population2000:0;
   Population2005:0;
   Population2010:0;
   Population2015:0;
   Population2022:0
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
   Population1951:46032;
   Population1956:50058;
   Population1961:54572;
   Population1966:59310;
   Population1971:64270;
   Population1975:62888;
   Population1979:61993;
   Population1985:61785;
   Population1990:62272;
   Population1995:67943;
   Population2000:75344;
   Population2005:80909;
   Population2010:87392;
   Population2015:93071;
   Population2022:99532
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
   Population1951:3160394;
   Population1956:3606095;
   Population1961:4153237;
   Population1966:4930198;
   Population1971:5969595;
   Population1975:7238509;
   Population1979:8894405;
   Population1985:12771794;
   Population1990:15952370;
   Population1995:18428376;
   Population2000:20430468;
   Population2005:23477239;
   Population2010:27029137;
   Population2015:31320432;
   Population2022:25731776
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
   Population1951:17215592;
   Population1956:18961847;
   Population1961:20650904;
   Population1966:22328212;
   Population1971:24071622;
   Population1975:25665698;
   Population1979:27267728;
   Population1985:29978660;
   Population1990:32385326;
   Population1995:34617167;
   Population2000:36670110;
   Population2005:38694095;
   Population2010:40690966;
   Population2015:42858262;
   Population2022:41343201
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
   Population1951:1367803;
   Population1956:1592209;
   Population1961:1908085;
   Population1966:2243943;
   Population1971:2556649;
   Population1975:2803493;
   Population1979:3023475;
   Population1985:3310971;
   Population1990:3537325;
   Population1995:3250234;
   Population2000:3079255;
   Population2005:2990909;
   Population2010:2882660;
   Population2015:2919035;
   Population2022:2968000
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
   Population1951:38161;
   Population1956:44833;
   Population1961:54826;
   Population1966:57531;
   Population1971:59258;
   Population1975:60591;
   Population1979:60036;
   Population1985:62926;
   Population1990:61597;
   Population1995:78529;
   Population2000:89943;
   Population2005:99391;
   Population2010:101559;
   Population2015:104060;
   Population2022:107493
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
   Population1951:8288694;
   Population1956:9269304;
   Population1961:10344790;
   Population1966:11454446;
   Population1971:12914067;
   Population1975:13690121;
   Population1979:14331875;
   Population1985:15544402;
   Population1990:16838308;
   Population1995:17896604;
   Population2000:18890366;
   Population2005:20030327;
   Population2010:21954429;
   Population2015:23765844;
   Population2022:26152604
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
   Population1951:6933873;
   Population1956:6960553;
   Population1961:7091122;
   Population1966:7328890;
   Population1971:7533429;
   Population1975:7632035;
   Population1979:7622782;
   Population1985:7611116;
   Population1990:7705413;
   Population1995:7968840;
   Population2000:8060246;
   Population2005:8235384;
   Population2010:8391455;
   Population2015:8647197;
   Population2022:9045673
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
   Population1951:2957839;
   Population1956:3380296;
   Population1961:3963416;
   Population1966:4657594;
   Population1971:5232704;
   Population1975:5626991;
   Population1979:6006174;
   Population1985:6612461;
   Population1990:7185294;
   Population1995:7729938;
   Population2000:8088622;
   Population2005:8494143;
   Population2010:8978868;
   Population2015:9564660;
   Population2022:10375843
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
   Population1951:79543;
   Population1956:90271;
   Population1961:112348;
   Population1966:143246;
   Population1971:171654;
   Population1975:187016;
   Population1979:203755;
   Population1985:232265;
   Population1990:254001;
   Population1995:278032;
   Population2000:296065;
   Population2005:321895;
   Population2010:352290;
   Population2015:372427;
   Population2022:402825
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
   Population1951:116225;
   Population1956:136436;
   Population1961:165186;
   Population1966:189626;
   Population1971:216491;
   Population1975:259284;
   Population1979:333215;
   Population1985:413381;
   Population1990:488565;
   Population1995:556702;
   Population2000:650652;
   Population2005:859745;
   Population2010:1213199;
   Population2015:1354110;
   Population2022:1730827
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
   Population1951:38303871;
   Population1956:42602921;
   Population1961:48693715;
   Population1966:56278667;
   Population1971:64887399;
   Population1975:69409707;
   Population1979:86650000;
   Population1985:85046395;
   Population1990:101943904;
   Population1995:113963804;
   Population2000:126430502;
   Population2005:138019388;
   Population2010:146756897;
   Population2015:155393982;
   Population2022:156118464
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
   Population1951:213376;
   Population1956:227772;
   Population1961:231355;
   Population1966:235752;
   Population1971:239499;
   Population1975:245407;
   Population1979:254996;
   Population1985:255880;
   Population1990:260451;
   Population1995:265428;
   Population2000:270986;
   Population2005:275806;
   Population2010:281623;
   Population2015:285078;
   Population2022:289096
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
   Population1951:8659024;
   Population1956:8914992;
   Population1961:9196626;
   Population1966:9466538;
   Population1971:9647879;
   Population1975:9759403;
   Population1979:9845664;
   Population1985:9911515;
   Population1990:9993468;
   Population1995:10171231;
   Population2000:10268677;
   Population2005:10513776;
   Population2010:10899658;
   Population2015:11254852;
   Population2022:10403000
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
   Population1951:70087;
   Population1956:81007;
   Population1961:93395;
   Population1966:107747;
   Population1971:123500;
   Population1975:132293;
   Population1979:151600;
   Population1985:162648;
   Population1990:185529;
   Population1995:204342;
   Population2000:243167;
   Population2005:280187;
   Population2010:318592;
   Population2015:357177;
   Population2022:314522
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
   Population1951:2256862;
   Population1956:2313375;
   Population1961:2448882;
   Population1966:2657465;
   Population1971:2944720;
   Population1975:3226610;
   Population1979:3470000;
   Population1985:4218161;
   Population1990:4899906;
   Population1995:5810670;
   Population2000:6765575;
   Population2005:7867067;
   Population2010:9073030;
   Population2015:10432589;
   Population2022:12614586
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
   Population1951:37530;
   Population1956:41124;
   Population1961:45446;
   Population1966:49753;
   Population1971:52862;
   Population1975:55143;
   Population1979:56962;
   Population1985:59389;
   Population1990:61438;
   Population1995:63271;
   Population2000:64861;
   Population2005:66208;
   Population2010:65530;
   Population2015:63865;
   Population2022:63134
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:699847
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
   Population1951:7721719;
   Population1956:7777178;
   Population1961:8164939;
   Population1966:8546784;
   Population1971:8950593;
   Population1975:9220886;
   Population1979:9473400;
   Population1985:9869304;
   Population1990:10137679;
   Population1995:10092817;
   Population2000:9897893;
   Population2005:9589131;
   Population2010:9426816;
   Population2015:9435615;
   Population2022:9452369
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
   Population1951:3103264;
   Population1956:3361167;
   Population1961:3693253;
   Population1966:4081035;
   Population1971:4533280;
   Population1975:4947302;
   Population1979:5404162;
   Population1985:6117308;
   Population1990:6793569;
   Population1995:7545202;
   Population2000:8338108;
   Population2005:9151343;
   Population2010:9967367;
   Population2015:10788795;
   Population2022:11958512
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:18012
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
   Population1951:2686177;
   Population1956:2964945;
   Population1961:3257393;
   Population1966:3561341;
   Population1971:3783095;
   Population1975:3963840;
   Population1979:4119744;
   Population1985:4371521;
   Population1990:4485438;
   Population1995:3882346;
   Population2000:3747286;
   Population2005:3764768;
   Population2010:3720586;
   Population2015:3455517;
   Population2022:3282300
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
   Population1951:418319;
   Population1956:467315;
   Population1961:507751;
   Population1966:566026;
   Population1971:637109;
   Population1975:728133;
   Population1979:848904;
   Population1985:1050669;
   Population1990:1265794;
   Population1995:1451761;
   Population2000:1626887;
   Population2005:1782443;
   Population2010:1970439;
   Population2015:2104799;
   Population2022:2029307
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
   Population1951:54797276;
   Population1956:63449792;
   Population1961:73254049;
   Population1966:84544564;
   Population1971:96307835;
   Population1975:105971516;
   Population1979:116511116;
   Population1985:133840705;
   Population1990:147676758;
   Population1995:160736935;
   Population2000:173561260;
   Population2005:185075508;
   Population2010:194807580;
   Population2015:203624771;
   Population2022:215681045
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
   Population1951:49483;
   Population1956:65096;
   Population1961:83649;
   Population1966:104852;
   Population1971:132626;
   Population1975:158379;
   Population1979:184425;
   Population1985:221334;
   Population1990:255115;
   Population1995:293313;
   Population2000:329709;
   Population2005:362296;
   Population2010:386287;
   Population2015:412367;
   Population2022:395027
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
   Population1951:7281009;
   Population1956:7593515;
   Population1961:7919818;
   Population1966:8253773;
   Population1971:8533500;
   Population1975:8718941;
   Population1979:8840722;
   Population1985:8972157;
   Population1990:8869273;
   Population1995:8426671;
   Population2000:8032289;
   Population2005:7715560;
   Population2010:7449061;
   Population2015:7222505;
   Population2022:6875874
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
   Population1951:4304639;
   Population1956:4546208;
   Population1961:4862203;
   Population1966:5215952;
   Population1971:5674391;
   Population1975:6097770;
   Population1979:6601817;
   Population1985:7630382;
   Population1990:8696376;
   Population1995:9954355;
   Population2000:11446212;
   Population2005:13227864;
   Population2010:15375062;
   Population2015:17850478;
   Population2022:21840865
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
   Population1951:2334896;
   Population1956:2561162;
   Population1961:2825406;
   Population1966:3132750;
   Population1971:3504744;
   Population1975:3673877;
   Population1979:4000671;
   Population1985:4686497;
   Population1990:5373556;
   Population1995:5943366;
   Population2000:6323307;
   Population2005:7249231;
   Population2010:8537776;
   Population2015:10003465;
   Population2022:12504404
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
   Population1951:4485625;
   Population1956:5111322;
   Population1961:5798289;
   Population1966:6526597;
   Population1971:7068696;
   Population1975:7528858;
   Population1979:6863062;
   Population1985:7582466;
   Population1990:8834632;
   Population1995:10488413;
   Population2000:12021587;
   Population2005:13170765;
   Population2010:14203803;
   Population2015:15398985;
   Population2022:17146712
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
   Population1951:4345809;
   Population1956:4750433;
   Population1961:5231412;
   Population1966:5842266;
   Population1971:6605405;
   Population1975:7350008;
   Population1979:8250000;
   Population1985:9915614;
   Population1990:11604402;
   Population1995:13416997;
   Population2000:15314368;
   Population2005:17498313;
   Population2010:20067845;
   Population2015:22992648;
   Population2022:27543748
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
   Population1951:13907342;
   Population1956:15895454;
   Population1961:18042273;
   Population1966:19803263;
   Population1971:21550330;
   Population1975:22903869;
   Population1979:24032491;
   Population1985:25596079;
   Population1990:27361897;
   Population1995:29013690;
   Population2000:30446226;
   Population2005:31991335;
   Population2010:33948479;
   Population2015:35846992;
   Population2022:33679000
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
   Population1951:182106;
   Population1956:197306;
   Population1961:203560;
   Population1966:234572;
   Population1971:269985;
   Population1975:270234;
   Population1979:277970;
   Population1985:308927;
   Population1990:334594;
   Population1995:381389;
   Population2000:424338;
   Population2005:459853;
   Population2010:489680;
   Population2015:521535;
   Population2022:508659
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
   Population1951:1334253;
   Population1956:1409957;
   Population1961:1513963;
   Population1966:1656499;
   Population1971:1825958;
   Population1975:1941516;
   Population1979:2114438;
   Population1985:2510538;
   Population1990:2776488;
   Population1995:3179200;
   Population2000:3599445;
   Population2005:3999454;
   Population2010:4362396;
   Population2015:4478790;
   Population2022:4976146
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
   Population1951:6664588;
   Population1956:7401681;
   Population1961:8219098;
   Population1966:9071898;
   Population1971:9863581;
   Population1975:10511228;
   Population1979:10920000;
   Population1985:12168424;
   Population1990:13167575;
   Population1995:14274487;
   Population2000:15253066;
   Population2005:16099532;
   Population2010:16975082;
   Population2015:17865027;
   Population2022:16746491
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
   Population1951:562227845;
   Population1956:616827315;
   Population1961:665723712;
   Population1966:733391706;
   Population1971:838267499;
   Population1975:917425602;
   Population1979:979226061;
   Population1985:1066952246;
   Population1990:1167696672;
   Population1995:1235515079;
   Population2000:1286057488;
   Population2005:1326962119;
   Population2010:1365021409;
   Population2015:1403181303;
   Population2022:1451432510
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
   Population1951:497227;
   Population1956:534795;
   Population1961:574682;
   Population1966:583160;
   Population1971:617269;
   Population1975:646068;
   Population1979:620000;
   Population1985:700729;
   Population1990:758893;
   Population1995:846323;
   Population2000:934716;
   Population2005:1019104;
   Population2010:1105413;
   Population2015:1156678;
   Population2022:1229262
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
   Population1951:12140063;
   Population1956:13985926;
   Population1961:16314862;
   Population1966:19004767;
   Population1971:21744177;
   Population1975:23804112;
   Population1979:26360000;
   Population1985:29643760;
   Population1990:32782684;
   Population1995:36092930;
   Population2000:39316439;
   Population2005:42364192;
   Population2010:44988319;
   Population2015:47246459;
   Population2022:51610539
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
   Population1951:161318;
   Population1956:177434;
   Population1961:192648;
   Population1966:209470;
   Population1971:232369;
   Population1975:253725;
   Population1979:292084;
   Population1985:350437;
   Population1990:405667;
   Population1995:468891;
   Population2000:535642;
   Population2005:604487;
   Population2010:681541;
   Population2015:768487;
   Population2022:902348
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
   Population1951:834927;
   Population1956:920760;
   Population1961:1030789;
   Population1966:1171215;
   Population1971:1346553;
   Population1975:1514540;
   Population1979:1702299;
   Population1985:2025887;
   Population1990:2325212;
   Population1995:2670247;
   Population2000:3083169;
   Population2005:3567083;
   Population2010:4210096;
   Population2015:4797019;
   Population2022:3039126
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
   Population1951:10397750;
   Population1956:10187010;
   Population1961:11545883;
   Population1966:12707540;
   Population1971:14611595;
   Population1975:16114733;
   Population1979:17490000;
   Population1985:18734864;
   Population1990:20144637;
   Population1995:21721308;
   Population2000:21988550;
   Population2005:23819158;
   Population2010:24489085;
   Population2015:25121330;
   Population2022:22912177
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
   Population1951:19333005;
   Population1956:21872899;
   Population1961:25709874;
   Population1966:29236838;
   Population1971:32525894;
   Population1975:35082228;
   Population1979:37253879;
   Population1985:40552406;
   Population1990:42706564;
   Population1995:45058237;
   Population2000:47199084;
   Population2005:48598105;
   Population2010:49447358;
   Population2015:50716380;
   Population2022:51744647
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
   Population1951:959026;
   Population1956:1130289;
   Population1961:1356194;
   Population1966:1619170;
   Population1971:1871934;
   Population1975:2068427;
   Population1979:2295954;
   Population1985:2700767;
   Population1990:3079556;
   Population1995:3502533;
   Population2000:3924109;
   Population2005:4255578;
   Population2010:4549288;
   Population2015:4821813;
   Population2022:5185498
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
   Population1951:2660627;
   Population1956:3048550;
   Population1961:3568079;
   Population1966:4305928;
   Population1971:5216334;
   Population1975:6268048;
   Population1979:7519477;
   Population1985:9725748;
   Population1990:11715399;
   Population1995:13969507;
   Population2000:16244770;
   Population2005:18164081;
   Population2010:20297993;
   Population2015:22939287;
   Population2022:27314589
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
   Population1951:3868405;
   Population1956:4047690;
   Population1961:4207695;
   Population1966:4339962;
   Population1971:4431010;
   Population1975:4492764;
   Population1979:4565806;
   Population1985:4704867;
   Population1990:4778482;
   Population1995:4637113;
   Population2000:4442183;
   Population2005:4380948;
   Population2010:4334658;
   Population2015:4244103;
   Population2022:4088367
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
   Population1951:5985599;
   Population1956:6596076;
   Population1961:7216837;
   Population1966:8037476;
   Population1971:8790950;
   Population1975:9384208;
   Population1979:9757722;
   Population1985:10065053;
   Population1990:10550859;
   Population1995:10863558;
   Population2000:11105662;
   Population2005:11256024;
   Population2010:11226268;
   Population2015:11315916;
   Population2022:11362685
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
   Population1951:102392;
   Population1956:118108;
   Population1961:127668;
   Population1966:134772;
   Population1971:144552;
   Population1975:149976;
   Population1979:148606;
   Population1985:150281;
   Population1990:147044;
   Population1995:144501;
   Population2000:133219;
   Population2005:129430;
   Population2010:147292;
   Population2015:159147;
   Population2022:165642
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
   Population1951:4288766;
   Population1956:4454640;
   Population1961:4597698;
   Population1966:4778619;
   Population1971:4946624;
   Population1975:5052160;
   Population1979:5114239;
   Population1985:5115145;
   Population1990:5135784;
   Population1995:5222109;
   Population2000:5331535;
   Population2005:5412305;
   Population2010:5540736;
   Population2015:5676548;
   Population2022:5830884
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
   Population1951:62662;
   Population1956:70549;
   Population1961:86089;
   Population1966:118958;
   Population1971:164557;
   Population1975:214757;
   Population1979:320000;
   Population1985:415894;
   Population1990:577233;
   Population1995:626407;
   Population2000:708823;
   Population2005:777471;
   Population2010:834058;
   Population2015:906415;
   Population2022:1007062
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
   Population1951:51403;
   Population1956:55053;
   Population1961:60532;
   Population1966:65677;
   Population1971:71328;
   Population1975:71952;
   Population1979:74623;
   Population1985:73524;
   Population1990:70571;
   Population1995:71075;
   Population2000:69739;
   Population2005:70484;
   Population2010:70863;
   Population2015:71133;
   Population2022:72206
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
   Population1951:20702335;
   Population1956:23544061;
   Population1961:27002579;
   Population1966:30838617;
   Population1971:34916158;
   Population1975:38132095;
   Population1979:41775654;
   Population1985:48618986;
   Population1990:55467110;
   Population1995:61720003;
   Population2000:68177172;
   Population2005:74853379;
   Population2010:81954701;
   Population2015:91441901;
   Population2022:105838455
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
   Population1951:68521;
   Population1956:80607;
   Population1961:96643;
   Population1966:154959;
   Population1971:256164;
   Population1975:508208;
   Population1979:884021;
   Population1985:1330364;
   Population1990:1777479;
   Population1995:2355234;
   Population2000:3050507;
   Population2005:4330535;
   Population2010:8236283;
   Population2015:9238739;
   Population2022:10206508
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
   Population1951:3515993;
   Population1956:4011274;
   Population1961:4609453;
   Population1966:5322340;
   Population1971:6159130;
   Population1975:6899586;
   Population1979:7684044;
   Population1985:8955696;
   Population1990:10112383;
   Population1995:11332618;
   Population2000:12562269;
   Population2005:13712057;
   Population2010:14893736;
   Population2015:16082996;
   Population2022:18058218
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
   Population1951:828725;
   Population1956:909350;
   Population1961:1020559;
   Population1966:1163658;
   Population1971:1329212;
   Population1975:1484882;
   Population1979:1660545;
   Population1985:1975357;
   Population1990:2245010;
   Population1995:2211273;
   Population2000:2265063;
   Population2005:2773670;
   Population2010:3145386;
   Population2015:3327260;
   Population2022:3676489
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
   Population1951:28145293;
   Population1956:29169896;
   Population1961:30567376;
   Population1966:32320368;
   Population1971:34077183;
   Population1975:35679478;
   Population1979:37215029;
   Population1985:38660890;
   Population1990:39160885;
   Population1995:39724269;
   Population2000:40640620;
   Population2005:43666652;
   Population2010:46758716;
   Population2015:46724487;
   Population2022:46552504
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
   Population1951:1107168;
   Population1956:1164692;
   Population1961:1223718;
   Population1966:1297755;
   Population1971:1366806;
   Population1975:1416307;
   Population1979:1459386;
   Population1985:1516845;
   Population1990:1567587;
   Population1995:1444959;
   Population2000:1401435;
   Population2005:1359577;
   Population2010:1334105;
   Population2015:1315798;
   Population2022:1318284
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
   Population1951:159846829;
   Population1956:173203422;
   Population1961:188156919;
   Population1966:200823605;
   Population1971:210456397;
   Population1975:218106155;
   Population1979:226290010;
   Population1985:239387553;
   Population1990:250932899;
   Population1995:263714483;
   Population2000:280138172;
   Population2005:293684931;
   Population2010:307670629;
   Population2015:319784928;
   Population2022:335028178
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
   Population1951:18298894;
   Population1956:20148645;
   Population1961:22413375;
   Population1966:25329915;
   Population1971:28835291;
   Population1975:32217003;
   Population1979:30420000;
   Population1985:40018497;
   Population1990:47086725;
   Population1995:56122122;
   Population2000:65289050;
   Population2005:75301567;
   Population2010:86446830;
   Population2015:99476124;
   Population2022:119346275
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
   Population1951:292652;
   Population1956:340512;
   Population1961:400419;
   Population1966:470231;
   Population1971:526137;
   Population1975:571068;
   Population1979:615534;
   Population1985:706170;
   Population1990:726605;
   Population1995:770558;
   Population2000:808669;
   Population2005:819750;
   Population2010:856751;
   Population2015:867548;
   Population2022:906377
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
   Population1951:4029563;
   Population1956:4260445;
   Population1961:4451314;
   Population1966:4574911;
   Population1971:4620938;
   Population1975:4708845;
   Population1979:4764852;
   Population1985:4899803;
   Population1990:4986748;
   Population1995:5108141;
   Population2000:5181970;
   Population2005:5250623;
   Population2010:5354122;
   Population2015:5471350;
   Population2022:5591854
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
   Population1951:41933345;
   Population1956:43611273;
   Population1961:45972501;
   Population1966:48991591;
   Population1971:50964883;
   Population1975:52524047;
   Population1979:53530972;
   Population1985:55111193;
   Population1990:56536661;
   Population1995:57695387;
   Population2000:58860585;
   Population2005:60910787;
   Population2010:62712593;
   Population2015:64324439;
   Population2022:65790152
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
   Population1951:474851;
   Population1956:485480;
   Population1961:503378;
   Population1966:538278;
   Population1971:595009;
   Population1975:641191;
   Population1979:700502;
   Population1985:816202;
   Population1990:936709;
   Population1995:1071215;
   Population2000:1213789;
   Population2005:1372320;
   Population2010:1596762;
   Population2015:1916008;
   Population2022:2299110
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
   Population1951:307006;
   Population1956:332907;
   Population1961:368773;
   Population1966:410410;
   Population1971:471311;
   Population1975:531686;
   Population1979:606738;
   Population1985:740863;
   Population1990:935777;
   Population1995:1111539;
   Population2000:1297524;
   Population2005:1520329;
   Population2010:1766955;
   Population2015:2055203;
   Population2022:2539001
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
   Population1951:3541562;
   Population1956:3738588;
   Population1961:4042687;
   Population1966:4409491;
   Population1971:4735935;
   Population1975:4860859;
   Population1979:4970678;
   Population1985:5187744;
   Population1990:5411185;
   Population1995:5036192;
   Population2000:4409160;
   Population2005:4217920;
   Population2010:4109209;
   Population2015:4029699;
   Population2022:3896588
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:30
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
   Population1951:5088663;
   Population1956:5814424;
   Population1961:6742636;
   Population1966:7841270;
   Population1971:8855347;
   Population1975:9868495;
   Population1979:10698675;
   Population1985:12596191;
   Population1990:14565067;
   Population1995:16789727;
   Population2000:19046884;
   Population2005:21545717;
   Population2010:24477780;
   Population2015:27539409;
   Population2022:32235099
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
   Population1951:22161;
   Population1956:22805;
   Population1961:23616;
   Population1966:26357;
   Population1971:28806;
   Population1975:29975;
   Population1979:30198;
   Population1985:29217;
   Population1990:29168;
   Population1995:28647;
   Population2000:30805;
   Population2005:33077;
   Population2010:33574;
   Population2015:33734;
   Population2022:33882
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
   Population1951:7706169;
   Population1956:8041208;
   Population1961:8293984;
   Population1966:8471992;
   Population1971:8690438;
   Population1975:8967059;
   Population1979:9452754;
   Population1985:9942570;
   Population1990:10191144;
   Population1995:10695634;
   Population2000:11055149;
   Population2005:11229855;
   Population2010:10923160;
   Population2015:10680427;
   Population2022:10364074
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
   Population1951:76664;
   Population1956:81994;
   Population1961:90631;
   Population1966:94786;
   Population1971:94343;
   Population1975:92839;
   Population1979:88851;
   Population1985:99219;
   Population1990:96628;
   Population1995:99819;
   Population2000:102634;
   Population2005:104503;
   Population2010:106009;
   Population2015:109254;
   Population2022:113178
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
   Population1951:23231;
   Population1956:26289;
   Population1961:31858;
   Population1966:38792;
   Population1971:46641;
   Population1975:49405;
   Population1979:49904;
   Population1985:52860;
   Population1990:55447;
   Population1995:55813;
   Population2000:56115;
   Population2005:56909;
   Population2010:56683;
   Population2015:56380;
   Population2022:56772
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
   Population1951:211684;
   Population1956:239968;
   Population1961:278268;
   Population1966:302482;
   Population1971:323038;
   Population1975:327962;
   Population1979:334760;
   Population1985:340601;
   Population1990:385228;
   Population1995:402409;
   Population2000:421544;
   Population2005:404472;
   Population2010:405761;
   Population2015:400778;
   Population2022:404115
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
   Population1951:59958;
   Population1956:62953;
   Population1961:67404;
   Population1966:75727;
   Population1971:84810;
   Population1975:92373;
   Population1979:100742;
   Population1985:115275;
   Population1990:129015;
   Population1995:144194;
   Population2000:154643;
   Population2005:158251;
   Population2010:159336;
   Population2015:161432;
   Population2022:172335
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
   Population1951:3164042;
   Population1956:3681071;
   Population1961:4273957;
   Population1966:4942030;
   Population1971:5701788;
   Population1975:6351893;
   Population1979:7050000;
   Population1985:8142288;
   Population1990:9158019;
   Population1995:10291365;
   Population2000:11519696;
   Population2005:12947706;
   Population2010:14474627;
   Population2015:16089184;
   Population2022:18492953
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:65228
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
   Population1951:3033638;
   Population1956:3254202;
   Population1961:3523354;
   Population1966:3836239;
   Population1971:4189112;
   Population1975:4457915;
   Population1979:4742760;
   Population1985:5399136;
   Population1990:6260640;
   Population1995:7176150;
   Population2000:8148248;
   Population2005:9018413;
   Population2010:10079255;
   Population2015:11292688;
   Population2022:13662711
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
   Population1951:228244;
   Population1956:241009;
   Population1961:257076;
   Population1966:279931;
   Population1971:301398;
   Population1975:260744;
   Population1979:240838;
   Population1985:341920;
   Population1990:412956;
   Population1995:488006;
   Population2000:594039;
   Population2005:733372;
   Population2010:922787;
   Population2015:1145614;
   Population2022:1462408
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
   Population1951:539962;
   Population1956:580255;
   Population1961:619474;
   Population1966:654434;
   Population1971:711703;
   Population1975:761861;
   Population1979:773442;
   Population1985:861805;
   Population1990:964612;
   Population1995:1077690;
   Population2000:1189285;
   Population2005:1329341;
   Population2010:1503420;
   Population2015:1715004;
   Population2022:2039724
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
   Population1951:412669;
   Population1956:491487;
   Population1961:580615;
   Population1966:658243;
   Population1971:709343;
   Population1975:741879;
   Population1979:773218;
   Population1985:772808;
   Population1990:744434;
   Population1995:760107;
   Population2000:748189;
   Population2005:745948;
   Population2010:748581;
   Population2015:765419;
   Population2022:790353
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
   Population1951:25866;
   Population1956:28762;
   Population1961:32578;
   Population1966:39766;
   Population1971:48782;
   Population1975:55379;
   Population1979:63115;
   Population1985:84021;
   Population1990:113045;
   Population1995:135310;
   Population2000:160004;
   Population2005:199171;
   Population2010:230291;
   Population2015:257920;
   Population2022:311343
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
   Population1951:3248058;
   Population1956:3547371;
   Population1961:3904370;
   Population1966:4300369;
   Population1971:4717039;
   Population1975:5049512;
   Population1979:5462581;
   Population1985:6266566;
   Population1990:6968411;
   Population1995:7673998;
   Population2000:8391831;
   Population2005:9121795;
   Population2010:9874304;
   Population2015:10622876;
   Population2022:11646533
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
   Population1951:1567812;
   Population1956:1796587;
   Population1961:2067759;
   Population1966:2380688;
   Population1971:2757723;
   Population1975:3106635;
   Population1979:3512828;
   Population1985:4218535;
   Population1990:4885577;
   Population1995:5629647;
   Population2000:6486310;
   Population2005:7371691;
   Population2010:8234809;
   Population2015:9034888;
   Population2022:10116198
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
   Population1951:2016216;
   Population1956:2531933;
   Population1961:3094707;
   Population1966:3506860;
   Population1971:3881525;
   Population1975:4161866;
   Population1979:4677024;
   Population1985:5247754;
   Population1990:5687445;
   Population1995:6042274;
   Population2000:6564624;
   Population2005:6757174;
   Population2010:6945654;
   Population2015:7160541;
   Population2022:7590298
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
   Population1951:9409750;
   Population1956:9852176;
   Population1961:10015854;
   Population1966:10189171;
   Population1971:10382263;
   Population1975:10506651;
   Population1979:10714586;
   Population1985:10591324;
   Population1990:10389274;
   Population1995:10353413;
   Population2000:10234879;
   Population2005:10100094;
   Population2010:9943278;
   Population2015:9791347;
   Population2022:9610451
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
   Population1951:0;
   Population1956:0;
   Population1961:0;
   Population1966:0;
   Population1971:0;
   Population1975:0;
   Population1979:0;
   Population1985:0;
   Population1990:0;
   Population1995:0;
   Population2000:0;
   Population2005:0;
   Population2010:0;
   Population2015:0;
   Population2022:0
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:3210;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:1500
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
   Population1951:55238;
   Population1956:51904;
   Population1961:48364;
   Population1966:50602;
   Population1971:55895;
   Population1975:59081;
   Population1979:62646;
   Population1985:64046;
   Population1990:69782;
   Population1995:71899;
   Population2000:76472;
   Population2005:79907;
   Population2010:84619;
   Population2015:83359;
   Population2022:86381
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:0
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:1828
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:26711
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
   Population1951:6343;
   Population1956:6791;
   Population1961:7948;
   Population1966:8407;
   Population1971:9367;
   Population1975:11864;
   Population1979:15086;
   Population1985:19064;
   Population1990:24673;
   Population1995:31348;
   Population2000:41369;
   Population2005:48586;
   Population2010:56002;
   Population2015:61288;
   Population2022:68358
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:700;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:628
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
   Population1951:15242;
   Population1956:16532;
   Population1961:18297;
   Population1966:19113;
   Population1971:21350;
   Population1975:20456;
   Population1979:18169;
   Population1985:17533;
   Population1990:18111;
   Population1995:19093;
   Population2000:17988;
   Population2005:18982;
   Population2010:18496;
   Population2015:17633;
   Population2022:16450
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
   Population1951:31521;
   Population1956:32670;
   Population1961:34851;
   Population1966:37065;
   Population1971:39234;
   Population1975:41071;
   Population1979:42742;
   Population1985:45113;
   Population1990:47218;
   Population1995:45736;
   Population2000:46584;
   Population2005:47666;
   Population2010:47808;
   Population2015:48010;
   Population2022:49191
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:2638
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
   Population1951:7038;
   Population1956:8179;
   Population1961:10113;
   Population1966:11183;
   Population1971:13213;
   Population1975:14796;
   Population1979:15405;
   Population1985:27121;
   Population1990:44656;
   Population1995:45619;
   Population2000:56548;
   Population2005:56891;
   Population2010:54082;
   Population2015:55542;
   Population2022:52882
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:65859
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:0
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:210000;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:559198
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
   Population1951:5022;
   Population1956:5314;
   Population1961:5846;
   Population1966:5798;
   Population1971:5906;
   Population1975:6722;
   Population1979:7494;
   Population1985:9767;
   Population1990:11835;
   Population1995:15813;
   Population2000:19623;
   Population2005:27451;
   Population2010:32298;
   Population2015:35677;
   Population2022:41184
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
   Population1951:7469;
   Population1956:7703;
   Population1961:8109;
   Population1966:8930;
   Population1971:9922;
   Population1975:10625;
   Population1979:11134;
   Population1985:13637;
   Population1990:17181;
   Population1995:19188;
   Population2000:20170;
   Population2005:22721;
   Population2010:27419;
   Population2015:29067;
   Population2022:31195
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
   Population1951:27084;
   Population1956:29766;
   Population1961:34438;
   Population1966:51750;
   Population1971:66761;
   Population1975:84489;
   Population1979:96128;
   Population1985:105031;
   Population1990:103805;
   Population1995:107018;
   Population2000:108703;
   Population2005:107949;
   Population2010:106250;
   Population2015:105028;
   Population2022:104465
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
   Population1951:379375943;
   Population1956:413682370;
   Population1961:455132295;
   Population1966:504420603;
   Population1971:561581011;
   Population1975:616011516;
   Population1979:675311262;
   Population1985:775668739;
   Population1990:864379976;
   Population1995:954837498;
   Population2000:1047367445;
   Population2005:1138690612;
   Population2010:1226071724;
   Population2015:1302936381;
   Population2022:1408044253
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
   Population1951:70201750;
   Population1956:78228303;
   Population1961:88934378;
   Population1966:101657582;
   Population1971:116349349;
   Population1975:129064855;
   Population1979:142329711;
   Population1985:163267118;
   Population1990:179824441;
   Population1995:195438255;
   Population2000:210072416;
   Population2005:224799911;
   Population2010:240240597;
   Population2015:256769044;
   Population2022:279081380
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
   Population1951:5811096;
   Population1956:6575041;
   Population1961:7383314;
   Population1966:8514610;
   Population1971:10088304;
   Population1975:11499851;
   Population1979:13061530;
   Population1985:15374603;
   Population1990:17208771;
   Population1995:19846852;
   Population2000:23151725;
   Population2005:26620559;
   Population2010:29360727;
   Population2015:34996877;
   Population2022:42438321
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
   Population1951:17319600;
   Population1956:19539812;
   Population1961:22195997;
   Population1966:25292374;
   Population1971:28900882;
   Population1975:32262003;
   Population1979:36604223;
   Population1985:46417698;
   Population1990:55600455;
   Population1995:61020135;
   Population2000:65214383;
   Population2005:69360145;
   Population2010:73347119;
   Population2015:77983207;
   Population2022:85582863
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
   Population1951:2912643;
   Population1956:2864046;
   Population1961:2789946;
   Population1966:2829207;
   Population1971:2926408;
   Population1975:3111384;
   Population1979:3318278;
   Population1985:3504810;
   Population1990:3510200;
   Population1995:3580149;
   Population2000:3757425;
   Population2005:4100016;
   Population2010:4524697;
   Population2015:4639741;
   Population2022:4940395
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
   Population1951:143809;
   Population1956:159429;
   Population1961:177398;
   Population1966:193664;
   Population1971:205770;
   Population1975:216834;
   Population1979:225133;
   Population1985:240214;
   Population1990:253745;
   Population1995:266394;
   Population2000:279161;
   Population2005:293055;
   Population2010:318217;
   Population2015:329421;
   Population2022:344949
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
   Population1951:1302011;
   Population1956:1729888;
   Population1961:2102908;
   Population1966:2524800;
   Population1971:2857236;
   Population1975:3249128;
   Population1979:3590614;
   Population1985:4002393;
   Population1990:4391435;
   Population1995:5189151;
   Population2000:5885777;
   Population2005:6463537;
   Population2010:7268884;
   Population2015:7916867;
   Population2022:8875661
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
   Population1951:46805981;
   Population1956:48467959;
   Population1961:49877508;
   Population1966:51871582;
   Population1971:53705443;
   Population1975:55112801;
   Population1979:56910000;
   Population1985:56900256;
   Population1990:57038552;
   Population1995:57193814;
   Population2000:56674003;
   Population2005:58116183;
   Population2010:59216330;
   Population2015:60494749;
   Population2022:60591668
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
   Population1951:1420125;
   Population1956:1550101;
   Population1961:1639888;
   Population1966:1768614;
   Population1971:1890077;
   Population1975:2013288;
   Population1979:2119454;
   Population1985:2321058;
   Population1990:2411750;
   Population1995:2521475;
   Population2000:2643748;
   Population2005:2732570;
   Population2010:2803212;
   Population2015:2883146;
   Population2022:2977016
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
   Population1951:83565397;
   Population1956:89513911;
   Population1961:94120809;
   Population1966:99026263;
   Population1971:105684337;
   Population1975:111723742;
   Population1979:115870000;
   Population1985:121539229;
   Population1990:124283716;
   Population1995:126210590;
   Population2000:127425657;
   Population2005:128265650;
   Population2010:128548720;
   Population2015:128076130;
   Population2022:126368572
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:90812
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
   Population1951:509085;
   Population1956:705714;
   Population1961:953711;
   Population1966:1220717;
   Population1971:1765615;
   Population1975:2037065;
   Population1979:2270794;
   Population1985:2842731;
   Population1990:3483295;
   Population1995:4500333;
   Population2000:5077372;
   Population2005:5673702;
   Population2010:7078913;
   Population2015:9094127;
   Population2022:10781873
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
   Population1951:6757728;
   Population1956:8121583;
   Population1961:10143698;
   Population1966:11988437;
   Population1971:13144055;
   Population1975:13960842;
   Population1979:14572133;
   Population1985:15575251;
   Population1990:16355599;
   Population1995:15930039;
   Population2000:14971381;
   Population2005:15327037;
   Population2010:16148504;
   Population2015:17438422;
   Population2022:19247393
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
   Population1951:6160112;
   Population1956:7092008;
   Population1961:8249946;
   Population1966:9692128;
   Population1971:11508912;
   Population1975:13328668;
   Population1979:15504010;
   Population1985:19514743;
   Population1990:23333075;
   Population1995:27362763;
   Population2000:31534026;
   Population2005:36134149;
   Population2010:41470880;
   Population2015:47294043;
   Population2022:56031570
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
   Population1951:1752886;
   Population1956:1925763;
   Population1961:2206221;
   Population1966:2611593;
   Population1971:3005095;
   Population1975:3260631;
   Population1979:3510136;
   Population1985:3953377;
   Population1990:4342621;
   Population1995:4542646;
   Population2000:4891079;
   Population2005:5057317;
   Population2010:5378863;
   Population2015:5902294;
   Population2022:6687835
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
   Population1951:33335;
   Population1956:36999;
   Population1961:41719;
   Population1966:46933;
   Population1971:51564;
   Population1975:54727;
   Population1979:58045;
   Population1985:63372;
   Population1990:71628;
   Population1995:77196;
   Population2000:83691;
   Population2005:91416;
   Population2010:101937;
   Population2015:110163;
   Population2022:122881
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
   Population1951:-1;
   Population1956:-1;
   Population1961:966000;
   Population1966:1106000;
   Population1971:1247000;
   Population1975:1369000;
   Population1979:1491000;
   Population1985:1682000;
   Population1990:1862000;
   Population1995:2029000;
   Population2000:1700000;
   Population2005:1705780;
   Population2010:1775680;
   Population2015:1804944;
   Population2022:1768942
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
   Population1951:155577;
   Population1956:186918;
   Population1961:284933;
   Population1966:497811;
   Population1971:771764;
   Population1975:991995;
   Population1979:1270000;
   Population1985:1694056;
   Population1990:2094079;
   Population1995:1632386;
   Population2000:1998638;
   Population2005:2235633;
   Population2010:2907165;
   Population2015:3763858;
   Population2022:4654903
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
   Population1951:1703231;
   Population1956:1912953;
   Population1961:2145819;
   Population1966:2411124;
   Population1971:2725650;
   Population1975:3021522;
   Population1979:3188243;
   Population1985:3637519;
   Population1990:4199150;
   Population1995:4791612;
   Population2000:5279761;
   Population2005:5707305;
   Population2010:6199308;
   Population2015:6690878;
   Population2022:7464289
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
   Population1951:710798;
   Population1956:773405;
   Population1961:845142;
   Population1966:932133;
   Population1971:1040872;
   Population1975:1145838;
   Population1979:1284094;
   Population1985:1508058;
   Population1990:1685313;
   Population1995:1880114;
   Population2000:2026304;
   Population2005:2000994;
   Population2010:1992877;
   Population2015:2051293;
   Population2022:2185368
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
   Population1951:1930312;
   Population1956:2013187;
   Population1961:2143737;
   Population1966:2279305;
   Population1971:2388285;
   Population1975:2461980;
   Population1979:2507164;
   Population1985:2572509;
   Population1990:2664197;
   Population1995:2525910;
   Population2000:2396054;
   Population2005:2265348;
   Population2010:2131713;
   Population2015:2009351;
   Population2022:1851848
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
   Population1951:1346519;
   Population1956:1558221;
   Population1961:1835019;
   Population1966:2114677;
   Population1971:2325974;
   Population1975:2556419;
   Population1979:2594031;
   Population1985:2645081;
   Population1990:2765050;
   Population1995:3466383;
   Population2000:3795528;
   Population2005:4634601;
   Population2010:4883620;
   Population2015:6397980;
   Population2022:7677569
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
   Population1951:936897;
   Population1956:1021305;
   Population1961:1130577;
   Population1966:1259398;
   Population1971:1418883;
   Population1975:1578553;
   Population1979:1767804;
   Population1985:2128852;
   Population1990:2091048;
   Population1995:2015813;
   Population2000:2774484;
   Population2005:3177223;
   Population2010:3823307;
   Population2015:4416332;
   Population2022:5258865
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
   Population1951:1133823;
   Population1956:1262472;
   Population1961:1473450;
   Population1966:1768787;
   Population1971:2181223;
   Population1975:2591460;
   Population1979:3038396;
   Population1985:3810769;
   Population1990:4383242;
   Population1995:4902219;
   Population2000:5317131;
   Population2005:5754753;
   Population2010:6166089;
   Population2015:6390408;
   Population2022:6830087
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
   Population1951:13849;
   Population1956:14972;
   Population1961:16699;
   Population1966:18903;
   Population1971:21500;
   Population1975:23212;
   Population1979:25218;
   Population1985:27158;
   Population1990:28621;
   Population1995:30651;
   Population2000:32976;
   Population2005:34582;
   Population2010:35861;
   Population2015:37343;
   Population2022:38577
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
   Population1951:2568521;
   Population1956:2640256;
   Population1961:2788554;
   Population1966:2984629;
   Population1971:3153471;
   Population1975:3283892;
   Population1979:3300000;
   Population1985:3548063;
   Population1990:3689351;
   Population1995:3637783;
   Population2000:3515441;
   Population2005:3362545;
   Population2010:3145369;
   Population2015:2951522;
   Population2022:2652289
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
   Population1951:296806;
   Population1956:306105;
   Population1961:316023;
   Population1966:331301;
   Population1971:340963;
   Population1975:352598;
   Population1979:361946;
   Population1985:366344;
   Population1990:379763;
   Population1995:405313;
   Population2000:433698;
   Population2005:454860;
   Population2010:502260;
   Population2015:560677;
   Population2022:648538
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
   Population1951:198498;
   Population1956:186228;
   Population1961:169141;
   Population1966:208247;
   Population1971:247479;
   Population1975:242949;
   Population1979:235309;
   Population1985:277750;
   Population1990:338345;
   Population1995:381693;
   Population2000:423106;
   Population2005:477278;
   Population2010:532357;
   Population2015:596200;
   Population2022:669514
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
   Population1951:1272578;
   Population1956:1402591;
   Population1961:1498236;
   Population1966:1605221;
   Population1971:1730244;
   Population1975:1793780;
   Population1979:1890307;
   Population1985:1978004;
   Population1990:1996538;
   Population1995:1982492;
   Population2000:2029636;
   Population2005:2058675;
   Population2010:2069891;
   Population2015:2078564;
   Population2022:2089882
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
   Population1951:4126317;
   Population1956:4595341;
   Population1961:5161975;
   Population1966:5844517;
   Population1971:6667825;
   Population1975:7451767;
   Population1979:8350930;
   Population1985:9923342;
   Population1990:11435006;
   Population1995:13272654;
   Population2000:15525988;
   Population2005:18072050;
   Population2010:20862771;
   Population2015:23914636;
   Population2022:28876295
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
   Population1951:6191228;
   Population1956:7142860;
   Population1961:8288156;
   Population1966:9659403;
   Population1971:10934344;
   Population1975:12017842;
   Population1979:13292820;
   Population1985:15397283;
   Population1990:17781451;
   Population1995:20234652;
   Population2000:22929229;
   Population2005:25442686;
   Population2010:27973477;
   Population2015:30070447;
   Population2022:33140178
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
   Population1951:2983068;
   Population1956:3306595;
   Population1961:3704230;
   Population1966:4187882;
   Population1971:4766952;
   Population1975:5310551;
   Population1979:5986909;
   Population1985:7117690;
   Population1990:9241385;
   Population1995:9795462;
   Population2000:11002342;
   Population2005:12465225;
   Population2010:14335576;
   Population2015:16519300;
   Population2022:20053121
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
   Population1951:73970;
   Population1956:80612;
   Population1961:91111;
   Population1966:103929;
   Population1971:117510;
   Population1975:134278;
   Population1979:151044;
   Population1985:186222;
   Population1990:219858;
   Population1995:251386;
   Population2000:276475;
   Population2005:315469;
   Population2010:359611;
   Population2015:445048;
   Population2022:555074
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
   Population1951:4733942;
   Population1956:5003916;
   Population1961:5293239;
   Population1966:5602456;
   Population1971:5997175;
   Population1975:6425782;
   Population1979:6894265;
   Population1985:7763936;
   Population1990:8374046;
   Population1995:9461307;
   Population2000:10795522;
   Population2005:12573964;
   Population2010:14817312;
   Population2015:17188566;
   Population2022:21159041
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
   Population1951:312107;
   Population1956:313358;
   Population1961:313699;
   Population1966:322469;
   Population1971:320455;
   Population1975:321901;
   Population1979:328059;
   Population1985:344688;
   Population1990:360489;
   Population1995:375336;
   Population2000:392146;
   Population2005:403747;
   Population2010:412919;
   Population2015:431888;
   Population2022:443779
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
   Population1951:9115756;
   Population1956:10678873;
   Population1961:12521130;
   Population1966:14414258;
   Population1971:16179230;
   Population1975:17606234;
   Population1979:19290236;
   Population1985:22252916;
   Population1990:24583399;
   Population1995:26791048;
   Population2000:28625512;
   Population2005:30286778;
   Population2010:32137938;
   Population2015:34429920;
   Population2022:37701643
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
   Population1951:223217;
   Population1956:249186;
   Population1961:285080;
   Population1966:313164;
   Population1971:325676;
   Population1975:327954;
   Population1979:325111;
   Population1985:338039;
   Population1990:356911;
   Population1995:367501;
   Population2000:385281;
   Population2005:396653;
   Population2010:395606;
   Population2015:379802;
   Population2022:376071
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
   Population1951:499897;
   Population1956:579348;
   Population1961:669616;
   Population1966:761488;
   Population1971:833077;
   Population1975:885344;
   Population1979:945260;
   Population1985:1011667;
   Population1990:1050769;
   Population1995:1121471;
   Population2000:1180385;
   Population2005:1218865;
   Population2010:1245991;
   Population2015:1258413;
   Population2022:1280936
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
   Population1951:659183;
   Population1956:748579;
   Population1961:863085;
   Population1966:1001124;
   Population1971:1164361;
   Population1975:1311385;
   Population1979:1474778;
   Population1985:1755588;
   Population1990:2008340;
   Population1995:2284814;
   Population2000:2596088;
   Population2005:2982071;
   Population2010:3444218;
   Population2015:3989073;
   Population2022:4818970
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
   Population1951:15437;
   Population1956:19448;
   Population1961:24633;
   Population1966:31157;
   Population1971:37747;
   Population1975:44614;
   Population1979:51730;
   Population1985:70173;
   Population1990:92265;
   Population1995:120351;
   Population2000:147645;
   Population2005:175248;
   Population2010:205631;
   Population2015:236861;
   Population2022:284743
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
   Population1951:28350569;
   Population1956:32855633;
   Population1961:38373863;
   Population1966:44827541;
   Population1971:52291470;
   Population1975:58794124;
   Population1979:65316085;
   Population1985:75174761;
   Population1990:83162502;
   Population1995:90916036;
   Population2000:98196200;
   Population2005:105266191;
   Population2010:113285118;
   Population2015:121112871;
   Population2022:131790986
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
   Population1951:32707;
   Population1956:38476;
   Population1961:45230;
   Population1966:53216;
   Population1971:61755;
   Population1975:62792;
   Population1979:69365;
   Population1985:84427;
   Population1990:95192;
   Population1995:106789;
   Population2000:107586;
   Population2005:106377;
   Population2010:102943;
   Population2015:108171;
   Population2022:114790
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
   Population1951:2361320;
   Population1956:2664197;
   Population1961:3040967;
   Population1966:3365052;
   Population1971:3621270;
   Population1975:3818585;
   Population1979:3959659;
   Population1985:4196254;
   Population1990:4356789;
   Population1995:4349621;
   Population2000:4214184;
   Population2005:4163593;
   Population2010:4091756;
   Population2015:4072045;
   Population2022:4032368
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
   Population1951:19689;
   Population1956:19921;
   Population1961:22638;
   Population1966:23296;
   Population1971:23605;
   Population1975:25018;
   Population1979:26242;
   Population1985:28675;
   Population1990:29372;
   Population1995:30585;
   Population2000:31993;
   Population2005:33672;
   Population2010:35418;
   Population2015:37523;
   Population2022:39010
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
   Population1951:786923;
   Population1956:863678;
   Population1961:968957;
   Population1966:1123676;
   Population1971:1298088;
   Population1975:1459203;
   Population1979:1625274;
   Population1985:1896698;
   Population1990:2162749;
   Population1995:2289318;
   Population2000:2386880;
   Population2005:2511535;
   Population2010:2697037;
   Population2015:2969512;
   Population2022:3365892
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
   Population1951:397831;
   Population1956:448585;
   Population1961:492817;
   Population1966:533868;
   Population1971:521255;
   Population1975:550444;
   Population1979:572527;
   Population1985:611743;
   Population1990:615104;
   Population1995:620249;
   Population2000:614102;
   Population2005:615768;
   Population2010:623612;
   Population2015:626805;
   Population2022:629570
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
   Population1951:13828;
   Population1956:14023;
   Population1961:11842;
   Population1966:11708;
   Population1971:11528;
   Population1975:11563;
   Population1979:13292;
   Population1985:10855;
   Population1990:10619;
   Population1995:10103;
   Population2000:5307;
   Population2005:4773;
   Population2010:4893;
   Population2015:4959;
   Population2022:5039
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
   Population1951:6009627;
   Population1956:6570371;
   Population1961:7264140;
   Population1966:8133335;
   Population1971:9128564;
   Population1975:10037151;
   Population1979:11192539;
   Population1985:12700780;
   Population1990:12897366;
   Population1995:15217863;
   Population2000:17479329;
   Population2005:20204635;
   Population2010:23215760;
   Population2015:26667203;
   Population2022:32560330
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:53414374
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
   Population1951:519210;
   Population1956:573968;
   Population1961:641768;
   Population1966:725802;
   Population1971:830016;
   Population1975:935515;
   Population1979:1024805;
   Population1985:1180363;
   Population1990:1409648;
   Population1995:1609994;
   Population2000:1779306;
   Population2005:1923152;
   Population2010:2100113;
   Population2015:2294334;
   Population2022:2633918
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
   Population1951:3448;
   Population1956:3854;
   Population1961:4503;
   Population1966:5963;
   Population1971:6611;
   Population1975:7120;
   Population1979:7566;
   Population1985:8417;
   Population1990:9391;
   Population1995:10562;
   Population2000:10392;
   Population2005:9877;
   Population2010:9977;
   Population2015:10332;
   Population2022:10931
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
   Population1951:8574203;
   Population1956:9395591;
   Population1961:10186827;
   Population1966:11073541;
   Population1971:12200331;
   Population1975:13277002;
   Population1979:14513646;
   Population1985:16669467;
   Population1990:18677143;
   Population1995:21310686;
   Population2000:23726713;
   Population2005:25583255;
   Population2010:26948902;
   Population2015:26960956;
   Population2022:29561409
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
   Population1951:1313672;
   Population1956:1533168;
   Population1961:1801685;
   Population1966:2100437;
   Population1971:2444241;
   Population1975:2764489;
   Population1979:3125017;
   Population1985:3689036;
   Population1990:4128568;
   Population1995:4605980;
   Population2000:5030389;
   Population2005:5402114;
   Population2010:5785121;
   Population2015:6183315;
   Population2022:6739574
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
   Population1951:2599240;
   Population1956:2996517;
   Population1961:3437949;
   Population1966:3971511;
   Population1971:4574838;
   Population1975:5113460;
   Population1979:5736392;
   Population1985:6818460;
   Population1990:7904429;
   Population1995:9330626;
   Population2000:11131839;
   Population2005:13377243;
   Population2010:16156130;
   Population2015:19624052;
   Population2022:25693114
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
   Population1951:38144265;
   Population1956:41460393;
   Population1961:45604817;
   Population1966:50677424;
   Population1971:56644968;
   Population1975:62532702;
   Population1979:70325114;
   Population1985:82514454;
   Population1990:94010210;
   Population1995:106631929;
   Population2000:120780216;
   Population2005:137107284;
   Population2010:156431242;
   Population2015:178790641;
   Population2022:214568727
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:4100;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:2166
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
   Population1951:3283158;
   Population1956:3446012;
   Population1961:3596941;
   Population1966:3739528;
   Population1971:3890782;
   Population1975:3996972;
   Population1979:4066087;
   Population1985:4145749;
   Population1990:4236788;
   Population1995:4354410;
   Population2000:4486761;
   Population2005:4615425;
   Population2010:4856605;
   Population2015:5171285;
   Population2022:5537764
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
   Population1951:64539;
   Population1956:68611;
   Population1961:79330;
   Population1966:92451;
   Population1971:107591;
   Population1975:127977;
   Population1979:141526;
   Population1985:154878;
   Population1990:168573;
   Population1995:190851;
   Population2000:215035;
   Population2005:234676;
   Population2010:251820;
   Population2015:269411;
   Population2022:291664
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
   Population1951:1928134;
   Population1956:2160053;
   Population1961:2398543;
   Population1966:2647033;
   Population1971:2844819;
   Population1975:3062565;
   Population1979:3132156;
   Population1985:3255738;
   Population1990:3379718;
   Population1995:3649318;
   Population2000:3838672;
   Population2005:4108113;
   Population2010:4346891;
   Population2015:4591218;
   Population2022:4871874
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
   Population1951:459357;
   Population1956:500884;
   Population1961:558367;
   Population1966:633576;
   Population1971:736508;
   Population1975:862160;
   Population1979:1062570;
   Population1985:1465016;
   Population1990:1776948;
   Population1995:2176571;
   Population2000:2261471;
   Population2005:2478659;
   Population2010:2959490;
   Population2015:4148285;
   Population2022:5915132
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
   Population1951:5233572;
   Population1956:5966280;
   Population1961:6876349;
   Population1966:8125888;
   Population1971:9539825;
   Population1975:10596385;
   Population1979:11893314;
   Population1985:14323072;
   Population1990:17061148;
   Population1995:20105895;
   Population2000:23303189;
   Population2005:27256493;
   Population2010:31923810;
   Population2015:37573888;
   Population2022:47992685
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
   Population1951:6367904;
   Population1956:7389431;
   Population1961:8671140;
   Population1966:10306703;
   Population1971:12264882;
   Population1975:13675797;
   Population1979:15268802;
   Population1985:17839994;
   Population1990:20160207;
   Population1995:22565487;
   Population2000:24591981;
   Population2005:26254139;
   Population2010:28292540;
   Population2015:30680043;
   Population2022:34227696
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
   Population1951:37769478;
   Population1956:40881012;
   Population1961:45531384;
   Population1966:51594595;
   Population1971:58944815;
   Population1975:65869288;
   Population1979:74388906;
   Population1985:90714844;
   Population1990:106093280;
   Population1995:122083830;
   Population2000:140494265;
   Population2005:158499309;
   Population2010:177491150;
   Population2015:197382922;
   Population2022:228037618
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
   Population1951:7462;
   Population1956:8454;
   Population1961:9909;
   Population1966:11092;
   Population1971:11928;
   Population1975:12861;
   Population1979:12319;
   Population1985:13363;
   Population1990:14885;
   Population1995:16948;
   Population2000:18939;
   Population2005:19822;
   Population2010:18121;
   Population2015:17645;
   Population2022:18179
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
   Population1951:870591;
   Population1956:995138;
   Population1961:1150203;
   Population1966:1334424;
   Population1971:1541370;
   Population1975:1722288;
   Population1979:1908057;
   Population1985:2194966;
   Population1990:2445397;
   Population1995:2712120;
   Population2000:3000927;
   Population2005:3300039;
   Population2010:3611214;
   Population2015:3935177;
   Population2022:4422004
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
   Population1951:2006719;
   Population1956:2100343;
   Population1961:2276624;
   Population1966:2512781;
   Population1971:2816600;
   Population1975:3101813;
   Population1979:3433730;
   Population1985:4028918;
   Population1990:4561867;
   Population1995:5126862;
   Population2000:5782237;
   Population2005:6425153;
   Population2010:7228324;
   Population2015:8027914;
   Population2022:9244308
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
   Population1951:1492704;
   Population1956:1695391;
   Population1961:1929479;
   Population1966:2201761;
   Population1971:2505568;
   Population1975:2757803;
   Population1979:3054552;
   Population1985:3624172;
   Population1990:4168361;
   Population1995:4721922;
   Population2000:5270066;
   Population2005:5777710;
   Population2010:6206339;
   Population2015:6644502;
   Population2022:7279504
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
   Population1951:10105312;
   Population1956:10781162;
   Population1961:11528254;
   Population1966:12326902;
   Population1971:13075538;
   Population1975:13623356;
   Population1979:14026671;
   Population1985:14476043;
   Population1990:14917448;
   Population1995:15418892;
   Population2000:15881104;
   Population2005:16327497;
   Population2010:16654885;
   Population2015:16915693;
   Population2022:17235780
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
   Population1951:7877783;
   Population1956:8979268;
   Population1961:10302013;
   Population1966:11879967;
   Population1971:13649625;
   Population1975:15222578;
   Population1979:16900189;
   Population1985:19548171;
   Population1990:21844692;
   Population1995:24077127;
   Population2000:26270162;
   Population2005:27746177;
   Population2010:28911137;
   Population2015:30282119;
   Population2022:33611856
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
   Population1951:18916280;
   Population1956:22568612;
   Population1961:26719059;
   Population1966:31391007;
   Population1971:36330933;
   Population1975:40719687;
   Population1979:45464266;
   Population1985:53557395;
   Population1990:61124356;
   Population1995:68989055;
   Population2000:77163393;
   Population2005:85525037;
   Population2010:93196853;
   Population2015:101319747;
   Population2022:112321991
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:46
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
   Population1951:25055396;
   Population1956:27521260;
   Population1961:29816552;
   Population1966:31502121;
   Population1971:32765857;
   Population1975:33829429;
   Population1979:35048858;
   Population1985:37000014;
   Population1990:37896905;
   Population1995:38424340;
   Population2000:38562253;
   Population2005:38384129;
   Population2010:38340763;
   Population2015:38062351;
   Population2022:37881467
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
   Population1951:61175;
   Population1956:69646;
   Population1961:79403;
   Population1966:95094;
   Population1971:112454;
   Population1975:129092;
   Population1979:146522;
   Population1985:174656;
   Population1990:197834;
   Population1995:216146;
   Population2000:238461;
   Population2005:257399;
   Population2010:265857;
   Population2015:272422;
   Population2022:286113
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
   Population1951:2205710;
   Population1956:2201317;
   Population1961:2314476;
   Population1966:2522675;
   Population1971:2649074;
   Population1975:2820992;
   Population1979:3021422;
   Population1985:3248294;
   Population1990:3388393;
   Population1995:3552375;
   Population2000:3664368;
   Population2005:3636903;
   Population2010:3588118;
   Population2015:3417293;
   Population2022:2888644
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
   Population1951:8417862;
   Population1956:8654635;
   Population1961:8857418;
   Population1966:8838330;
   Population1971:8675867;
   Population1975:9106652;
   Population1979:9607123;
   Population1985:9925242;
   Population1990:9893109;
   Population1995:10068367;
   Population2000:10275925;
   Population2005:10489864;
   Population2010:10600028;
   Population2015:10393080;
   Population2022:10119870
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
   Population1951:26262;
   Population1956:36744;
   Population1961:49422;
   Population1966:76766;
   Population1971:114508;
   Population1975:159013;
   Population1979:198614;
   Population1985:356201;
   Population1990:469041;
   Population1995:510272;
   Population2000:581537;
   Population2005:809832;
   Population2010:1756464;
   Population2015:2512893;
   Population2022:3131360
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
   Population1951:12307292;
   Population1956:13674825;
   Population1961:15444578;
   Population1966:17617990;
   Population1971:20289820;
   Population1975:22595411;
   Population1979:25312899;
   Population1985:29503572;
   Population1990:34043110;
   Population1995:40920044;
   Population2000:46515964;
   Population2005:53934438;
   Population2010:63514905;
   Population2015:75016168;
   Population2022:93852092
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
   Population1951:2401946;
   Population1956:2829480;
   Population1961:3350713;
   Population1966:3939283;
   Population1971:4563986;
   Population1975:5079946;
   Population1979:5606242;
   Population1985:6398539;
   Population1990:7066241;
   Population1995:7752030;
   Population2000:8407652;
   Population2005:9036358;
   Population2010:9636413;
   Population2015:10223907;
   Population2022:11061761
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
   Population1951:1410591;
   Population1956:1482325;
   Population1961:1589085;
   Population1966:1741594;
   Population1971:2150883;
   Population1975:2383757;
   Population1979:2609766;
   Population1985:3197379;
   Population1990:3726832;
   Population1995:4173888;
   Population2000:4852824;
   Population2005:5540298;
   Population2010:6336959;
   Population2015:7231340;
   Population2022:8623451
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:776948
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
   Population1951:16375615;
   Population1956:17605948;
   Population1961:18697761;
   Population1966:19481787;
   Population1971:20667198;
   Population1975:21558907;
   Population1979:22375138;
   Population1985:23027969;
   Population1990:23477878;
   Population1995:23039660;
   Population2000:22217333;
   Population2005:21496928;
   Population2010:20554245;
   Population2015:19980100;
   Population2022:18996642
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
   Population1951:50608915;
   Population1956:51165448;
   Population1961:52550647;
   Population1966:54406209;
   Population1971:55661714;
   Population1975:56122440;
   Population1979:56205495;
   Population1985:56373560;
   Population1990:57054991;
   Population1995:57848611;
   Population2000:58820149;
   Population2005:60082063;
   Population2010:63146804;
   Population2015:65643395;
   Population2022:68562151
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
   Population1951:103557863;
   Population1956:112259732;
   Population1961:120644095;
   Population1966:126964220;
   Population1971:130492490;
   Population1975:133421734;
   Population1979:136703220;
   Population1985:142452072;
   Population1990:147200488;
   Population1995:148287956;
   Population2000:146659006;
   Population2005:143874708;
   Population2010:143403715;
   Population2015:144826264;
   Population2022:146023195
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
   Population1951:2218921;
   Population1956:2568804;
   Population1961:2967212;
   Population1966:3278959;
   Population1971:3814858;
   Population1975:4298691;
   Population1979:4896524;
   Population1985:6025868;
   Population1990:7282982;
   Population1995:5885962;
   Population2000:7718645;
   Population2005:8761024;
   Population2010:9912108;
   Population2015:11227521;
   Population2022:13412558
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
   Population1951:14918;
   Population1956:21980;
   Population1961:34253;
   Population1966:53822;
   Population1971:76623;
   Population1975:72599;
   Population1979:128086;
   Population1985:179865;
   Population1990:213694;
   Population1995:251481;
   Population2000:305360;
   Population2005:427245;
   Population2010:477182;
   Population2015:520644;
   Population2022:616540
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:8450
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
   Population1951:46092;
   Population1956:48873;
   Population1961:51197;
   Population1966:48776;
   Population1971:44682;
   Population1975:44296;
   Population1979:43576;
   Population1985:42035;
   Population1990:40307;
   Population1995:41849;
   Population2000:43854;
   Population2005:46590;
   Population2010:48807;
   Population2015:50992;
   Population2022:53889
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
   Population1951:12850;
   Population1956:13931;
   Population1961:15640;
   Population1966:17715;
   Population1971:19309;
   Population1975:19746;
   Population1979:20944;
   Population1985:22671;
   Population1990:23980;
   Population1995:25758;
   Population2000:27301;
   Population2005:29135;
   Population2010:31025;
   Population2015:33107;
   Population2022:34612
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
   Population1951:1577;
   Population1956:2161;
   Population1961:2956;
   Population1966:4679;
   Population1971:7115;
   Population1975:9269;
   Population1979:11866;
   Population1985:18329;
   Population1990:28053;
   Population1995:31058;
   Population2000:32443;
   Population2005:33389;
   Population2010:33910;
   Population2015:39424;
   Population2022:45331
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
   Population1951:4588;
   Population1956:4775;
   Population1961:4995;
   Population1966:5196;
   Population1971:5597;
   Population1975:5969;
   Population1979:6130;
   Population1985:6010;
   Population1990:6356;
   Population1995:6402;
   Population2000:6311;
   Population2005:6115;
   Population2010:6352;
   Population2015:6032;
   Population2022:7012
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
   Population1951:67540;
   Population1956:74333;
   Population1961:81574;
   Population1966:86462;
   Population1971:91000;
   Population1975:95146;
   Population1979:99172;
   Population1985:104142;
   Population1990:107282;
   Population1995:108051;
   Population2000:107775;
   Population2005:108569;
   Population2010:108276;
   Population2015:109003;
   Population2022:110831
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
   Population1951:5267;
   Population1956:5349;
   Population1961:5352;
   Population1966:5345;
   Population1971:5747;
   Population1975:6185;
   Population1979:6490;
   Population1985:6809;
   Population1990:6684;
   Population1995:6274;
   Population2000:6089;
   Population2005:5421;
   Population2010:5159;
   Population2015:5804;
   Population2022:6112
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
   Population1951:83302;
   Population1956:86731;
   Population1961:90212;
   Population1966:96936;
   Population1971:104635;
   Population1975:109017;
   Population1979:115280;
   Population1985:125279;
   Population1990:136912;
   Population1995:145983;
   Population2000:155867;
   Population2005:162621;
   Population2010:173165;
   Population2015:178722;
   Population2022:186301
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
   Population1951:2218996;
   Population1956:2462222;
   Population1961:2806790;
   Population1966:3248013;
   Population1971:3721962;
   Population1975:4107860;
   Population1979:4469250;
   Population1985:4904192;
   Population1990:5235626;
   Population1995:5595533;
   Population2000:5866500;
   Population2005:6038079;
   Population2010:6170885;
   Population2015:6310246;
   Population2022:6507545
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
   Population1951:83273;
   Population1956:95489;
   Population1961:110384;
   Population1966:128878;
   Population1971:144286;
   Population1975:150777;
   Population1979:154366;
   Population1985:159622;
   Population1990:162370;
   Population1995:169375;
   Population2000:174032;
   Population2005:179164;
   Population2010:185254;
   Population2015:192870;
   Population2022:200768
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
   Population1951:19115;
   Population1956:19730;
   Population1961:20368;
   Population1966:24077;
   Population1971:27675;
   Population1975:29822;
   Population1979:31554;
   Population1985:38740;
   Population1990:46628;
   Population1995:52633;
   Population2000:57435;
   Population2005:59620;
   Population2010:56377;
   Population2015:55799;
   Population2022:56600
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
   Population1951:59605;
   Population1956:59293;
   Population1961:64447;
   Population1966:65533;
   Population1971:75464;
   Population1975:82149;
   Population1979:92163;
   Population1985:103885;
   Population1990:117774;
   Population1995:130562;
   Population2000:141120;
   Population2005:155619;
   Population2010:178143;
   Population2015:197598;
   Population2022:226575
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
   Population1951:2516234;
   Population1956:2845204;
   Population1961:3251382;
   Population1966:3736568;
   Population1971:4323054;
   Population1975:4864062;
   Population1979:5373421;
   Population1985:6375171;
   Population1990:7415824;
   Population1995:8576552;
   Population2000:9683850;
   Population2005:10951255;
   Population2010:12508027;
   Population2015:14378254;
   Population2022:17559867
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
   Population1951:6793269;
   Population1956:7272126;
   Population1961:7585278;
   Population1966:7862165;
   Population1971:8154209;
   Population1975:8457046;
   Population1979:8788345;
   Population1985:9223407;
   Population1990:9484498;
   Population1995:9872981;
   Population2000:9533963;
   Population2005:9218030;
   Population2010:9007174;
   Population2015:8887442;
   Population2022:8673649
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
   Population1951:36617;
   Population1956:39180;
   Population1961:42039;
   Population1966:47331;
   Population1971:53048;
   Population1975:58846;
   Population1979:64487;
   Population1985:69589;
   Population1990:70332;
   Population1995:76053;
   Population2000:80454;
   Population2005:88025;
   Population2010:91032;
   Population2015:94601;
   Population2022:99449
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
   Population1951:2052929;
   Population1956:2179794;
   Population1961:2335147;
   Population1966:2530081;
   Population1971:2772030;
   Population1975:3005891;
   Population1979:3277472;
   Population1985:3756810;
   Population1990:4287367;
   Population1995:4306843;
   Population2000:4523806;
   Population2005:5540682;
   Population2010:6344773;
   Population2015:7095167;
   Population2022:8249189
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
   Population1951:1045134;
   Population1956:1338994;
   Population1961:1661599;
   Population1966:1898720;
   Population1971:2091780;
   Population1975:2243186;
   Population1979:2357126;
   Population1985:2675267;
   Population1990:2975434;
   Population1995:3471286;
   Population2000:3992009;
   Population2005:4221811;
   Population2010:5049568;
   Population2015:5559159;
   Population2022:6058739
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
   Population1951:3474055;
   Population1956:3851265;
   Population1961:4168379;
   Population1966:4400966;
   Population1971:4557353;
   Population1975:4729014;
   Population1979:4927697;
   Population1985:5152358;
   Population1990:5277719;
   Population1995:5369234;
   Population2000:5398462;
   Population2005:5399166;
   Population2010:5402734;
   Population2015:5432234;
   Population2022:5466088
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
   Population1951:1477396;
   Population1956:1533532;
   Population1961:1591632;
   Population1966:1633080;
   Population1971:1675557;
   Population1975:1734364;
   Population1979:1805454;
   Population1985:1935302;
   Population1990:2003641;
   Population1995:1993209;
   Population2000:1987668;
   Population2005:1992622;
   Population2010:2038611;
   Population2015:2069359;
   Population2022:2084868
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
   Population1951:2286057;
   Population1956:2516416;
   Population1961:2785285;
   Population1966:3106368;
   Population1971:3458577;
   Population1975:3757652;
   Population1979:5636018;
   Population1985:6631810;
   Population1990:7179553;
   Population1995:7432609;
   Population2000:8713793;
   Population2005:10289855;
   Population2010:11882129;
   Population2015:13611923;
   Population2022:16419535
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
   Population1951:5809840;
   Population1956:6641367;
   Population1961:7657911;
   Population1966:8910090;
   Population1971:10452979;
   Population1975:11940232;
   Population1979:13758387;
   Population1985:16936338;
   Population1990:19814880;
   Population1995:23719711;
   Population2000:26952537;
   Population2005:30584873;
   Population2010:34167525;
   Population2015:38444105;
   Population2022:45225449
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
   Population1951:8040327;
   Population1956:8879150;
   Population1961:9994032;
   Population1966:11246854;
   Population1971:12617861;
   Population1975:13629577;
   Population1979:14662327;
   Population1985:16063328;
   Population1990:17217161;
   Population1995:18169306;
   Population2000:18720762;
   Population2005:19466719;
   Population2010:20193191;
   Population2015:20848759;
   Population2022:21583818
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
   Population1951:2492017;
   Population1956:2639114;
   Population1961:2869381;
   Population1966:3166524;
   Population1971:3535290;
   Population1975:3893254;
   Population1979:4312886;
   Population1985:5159124;
   Population1990:5502023;
   Population1995:5114755;
   Population2000:6067365;
   Population2005:7375968;
   Population2010:9326820;
   Population2015:10635930;
   Population2022:12054642
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
   Population1951:7041830;
   Population1956:7283813;
   Population1961:7506555;
   Population1966:7777642;
   Population1971:8075522;
   Population1975:8185747;
   Population1979:8288802;
   Population1985:8349118;
   Population1990:8541008;
   Population1995:8817485;
   Population2000:8877397;
   Population2005:9014837;
   Population2010:9351938;
   Population2015:9728842;
   Population2022:10235622
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
   Population1951:4695224;
   Population1956:4984732;
   Population1961:5329622;
   Population1966:5856517;
   Population1971:6177114;
   Population1975:6329580;
   Population1979:6294414;
   Population1985:6415945;
   Population1990:6625345;
   Population1995:6967198;
   Population2000:7129476;
   Population2005:7355532;
   Population2010:7761677;
   Population2015:8251762;
   Population2022:8824554
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
   Population1951:218754;
   Population1956:252611;
   Population1961:291925;
   Population1966:333585;
   Population1971:368583;
   Population1975:360440;
   Population1979:358467;
   Population1985:366695;
   Population1990:401159;
   Population1995:438503;
   Population2000:468177;
   Population2005:496594;
   Population2010:526144;
   Population2015:556231;
   Population2022:594997
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:2550
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:1354051
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
   Population1951:3456278;
   Population1956:3972112;
   Population1961:4648313;
   Population1966:5463932;
   Population1971:6461607;
   Population1975:7410486;
   Population1979:8482246;
   Population1985:10472302;
   Population1990:12264806;
   Population1995:14149612;
   Population2000:16213504;
   Population2005:18096694;
   Population2010:21284851;
   Population2015:18351130;
   Population2022:16513372
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
   Population1951:1558471;
   Population1956:1820978;
   Population1961:2123390;
   Population1966:2531596;
   Population1971:2975635;
   Population1975:3343906;
   Population1979:3741870;
   Population1985:4468268;
   Population1990:5217392;
   Population1995:5722339;
   Population2000:6168261;
   Population2005:6726376;
   Population2010:7446743;
   Population2015:8354250;
   Population2022:9857502
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
   Population1951:7767853;
   Population1956:9348982;
   Population1961:11068525;
   Population1966:13113325;
   Population1971:15097723;
   Population1975:16321452;
   Population1979:17476390;
   Population1985:19171030;
   Population1990:20373342;
   Population1995:21282335;
   Population2000:21902931;
   Population2005:22638531;
   Population2010:23146390;
   Population2015:23524994;
   Population2022:23893107
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
   Population1951:7748130;
   Population1956:8853001;
   Population1961:10200633;
   Population1966:11811580;
   Population1971:13755385;
   Population1975:15639120;
   Population1979:17706721;
   Population1985:21310467;
   Population1990:24811051;
   Population1995:29224408;
   Population2000:33092941;
   Population2005:37919444;
   Population2010:43715411;
   Population2015:50727856;
   Population2022:62649363
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
   Population1951:2523271;
   Population1956:2760765;
   Population1961:3031226;
   Population1966:3341140;
   Population1971:3685238;
   Population1975:4044607;
   Population1979:4380369;
   Population1985:5027047;
   Population1990:5869368;
   Population1995:6896550;
   Population2000:8205418;
   Population2005:9917183;
   Population2010:11757749;
   Population2015:13889105;
   Population2022:17274363
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
   Population1951:8955240;
   Population1956:9391066;
   Population1961:9614483;
   Population1966:9816259;
   Population1971:9832562;
   Population1975:10038875;
   Population1979:10288649;
   Population1985:10335848;
   Population1990:10338397;
   Population1995:10359566;
   Population2000:10297842;
   Population2005:10248881;
   Population2010:10512533;
   Population2015:10596289;
   Population2022:10713922
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:140
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:4000
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:-1;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:3800000
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
   Population1951:20989180;
   Population1956:24052188;
   Population1961:27814096;
   Population1966:32309864;
   Population1971:37428336;
   Population1975:41793727;
   Population1979:45911479;
   Population1985:51564716;
   Population1990:56168413;
   Population1995:59173706;
   Population2000:62627391;
   Population2005:65207476;
   Population2010:67032282;
   Population2015:68577767;
   Population2022:70239885
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
   Population1951:416735;
   Population1956:442350;
   Population1961:478728;
   Population1966:524542;
   Population1971:578464;
   Population1975:626913;
   Population1979:606174;
   Population1985:649516;
   Population1990:728353;
   Population1995:836148;
   Population2000:878783;
   Population2005:983605;
   Population2010:1083981;
   Population2015:1185404;
   Population2022:1365995
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:1600;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:1466
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
   Population1951:48272;
   Population1956:55847;
   Population1961:62656;
   Population1966:75571;
   Population1971:84923;
   Population1975:87956;
   Population1979:91807;
   Population1985:93845;
   Population1990:94959;
   Population1995:95856;
   Population2000:97720;
   Population2005:100564;
   Population2010:103939;
   Population2015:100901;
   Population2022:105991
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
   Population1951:652244;
   Population1956:751404;
   Population1961:856463;
   Population1966:915511;
   Population1971:950598;
   Population1975:1003766;
   Population1979:1061164;
   Population1985:1162752;
   Population1990:1217023;
   Population1995:1251883;
   Population2000:1265552;
   Population2005:1293332;
   Population2010:1324562;
   Population2015:1366367;
   Population2022:1410604
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
   Population1951:3651111;
   Population1956:3966328;
   Population1961:4208434;
   Population1966:4594850;
   Population1971:5120510;
   Population1975:5594463;
   Population1979:6136076;
   Population1985:7233226;
   Population1990:8152109;
   Population1995:9047305;
   Population2000:9661226;
   Population2005:10064875;
   Population2010:10580918;
   Population2015:11122053;
   Population2022:12022316
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
   Population1951:1221497;
   Population1956:1385929;
   Population1961:1631035;
   Population1966:1922615;
   Population1971:2227327;
   Population1975:2491656;
   Population1979:2770649;
   Population1985:3205439;
   Population1990:3635326;
   Population1995:4161854;
   Population2000:4491267;
   Population2005:4729235;
   Population2010:5047908;
   Population2015:5516210;
   Population2022:6140280
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
   Population1951:21682031;
   Population1956:24580045;
   Population1961:27812396;
   Population1966:31348310;
   Population1971:35301919;
   Population1975:38827491;
   Population1979:42520934;
   Population1985:48628234;
   Population1990:53460937;
   Population1995:58029121;
   Population2000:62766397;
   Population2005:67460863;
   Population2010:71828332;
   Population2015:77884681;
   Population2022:86735919
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
   Population1951:4730;
   Population1956:5106;
   Population1961:5326;
   Population1966:5412;
   Population1971:5755;
   Population1975:5984;
   Population1979:7189;
   Population1985:8161;
   Population1990:8849;
   Population1995:9279;
   Population2000:9368;
   Population2005:9935;
   Population2010:10467;
   Population2015:11037;
   Population2022:11889
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
   Population1951:37558718;
   Population1956:40289727;
   Population1961:42937726;
   Population1966:45476495;
   Population1971:47263358;
   Population1975:48605388;
   Population1979:49636574;
   Population1985:50834925;
   Population1990:51442887;
   Population1995:51024774;
   Population2000:49062167;
   Population2005:47052789;
   Population2010:45880779;
   Population2015:45015803;
   Population2022:43544250
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
   Population1951:2250014;
   Population1956:2388615;
   Population1961:2555301;
   Population1966:2708820;
   Population1971:2814076;
   Population1975:2827158;
   Population1979:2885786;
   Population1985:3001964;
   Population1990:3099187;
   Population1995:3212807;
   Population2000:3313902;
   Population2005:3321644;
   Population2010:3354514;
   Population2015:3406274;
   Population2022:3491105
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
   Population1951:48313;
   Population1956:55743;
   Population1961:64703;
   Population1966:75339;
   Population1971:86704;
   Population1975:98331;
   Population1979:110983;
   Population1985:128536;
   Population1990:144704;
   Population1995:166161;
   Population2000:183122;
   Population2005:206724;
   Population2010:233255;
   Population2015:267538;
   Population2022:317436
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
   Population1951:-1;
   Population1956:-1;
   Population1961:-1;
   Population1966:-1;
   Population1971:-1;
   Population1975:-1;
   Population1979:738;
   Population1985:-1;
   Population1990:-1;
   Population1995:-1;
   Population2000:-1;
   Population2005:-1;
   Population2010:-1;
   Population2015:-1;
   Population2022:921
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
   Population1951:5605298;
   Population1956:6879171;
   Population1961:8291772;
   Population1966:9858794;
   Population1971:11572611;
   Population1975:13004764;
   Population1979:14569669;
   Population1985:17099928;
   Population1990:19401485;
   Population1995:21704696;
   Population2000:23967379;
   Population2005:26216311;
   Population2010:28237157;
   Population2015:30062560;
   Population2022:29281455
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
   Population1951:25089495;
   Population1956:28562697;
   Population1961:33172173;
   Population1966:38413013;
   Population1971:43948852;
   Population1975:48192231;
   Population1979:52531884;
   Population1985:60210364;
   Population1990:67275455;
   Population1995:74286016;
   Population2000:79475530;
   Population2005:83450904;
   Population2010:87533550;
   Population2015:92199424;
   Population2022:99085517
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
   Population1951:7064;
   Population1956:7722;
   Population1961:8213;
   Population1966:8742;
   Population1971:8873;
   Population1975:9223;
   Population1979:10534;
   Population1985:13458;
   Population1990:13801;
   Population1995:14102;
   Population2000:14639;
   Population2005:15016;
   Population2010:12877;
   Population2015:12300;
   Population2022:11421
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
   Population1951:4689440;
   Population1956:4998812;
   Population1961:5354512;
   Population1966:5772357;
   Population1971:6242272;
   Population1975:6707987;
   Population1979:7542983;
   Population1985:9394100;
   Population1990:11451726;
   Population1995:14607995;
   Population2000:17166447;
   Population2005:19826087;
   Population2010:22838283;
   Population2015:26163456;
   Population2022:31031323
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
   Population1951:2339761;
   Population1956:2684637;
   Population1961:3117939;
   Population1966:3626668;
   Population1971:4249720;
   Population1975:4861674;
   Population1979:5562974;
   Population1985:6813258;
   Population1990:7929414;
   Population1995:8984109;
   Population2000:10279005;
   Population2005:11704698;
   Population2010:13412170;
   Population2015:15641552;
   Population2022:19244849
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
   Population1951:2789901;
   Population1956:3265570;
   Population1961:3841386;
   Population1966:4547884;
   Population1971:5383916;
   Population1975:6190335;
   Population1979:7045789;
   Population1985:8721169;
   Population1990:10294275;
   Population1995:11336849;
   Population2000:11852263;
   Population2005:12048537;
   Population2010:12613048;
   Population2015:13701613;
   Population2022:15412353
  )
 );

Var
 Option:Set Of (_Graph);
 OutputFormat:(_Text,_CSV,_HTML,_Json,_Pascal,_SQL,_XML);
 I,J,K,L:Integer;
 Data:Array[0..14]of LongInt;
 MinValue,MaxValue,Intervalle,Value:LongInt;
 Total:Comp;
 CurrParam:String;

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
  WriteLn('POPUL : Cette commande permet de retourner la population d''un pays');
  WriteLn;
  WriteLn('Syntaxe : POPUL [pays|annee] [/GRAPH] [/FORMAT:HTML]');
  WriteLn;
  WriteLn(' annee         Ce parametre permet d''indiquer la population mondiale d''une annee');
  WriteLn(' pays          Ce parametre permet d''indiquer la population d''un pays');
  WriteLn(' /GRAPH        Ce parametre permet d''afficher le graphique de population');
  WriteLn(' /FORMAT:HTML  Ce paramŠtre permet de demander un format de sortie HTML');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('POPUL 1.01 - Pascal pour GEO-COMMANDER');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('Ecrit par Sylvain Maltais');
 End
  Else
 If ParamCount>0Then Begin
  Option:=[];
  OutputFormat:=_Text;
  For I:=1 to ParamCount do Begin
   CurrParam:=ParamStr(I);
   If StrToUpper(CurrParam)='/GRAPH'Then Include(Option,_Graph) Else
   If(StrToUpper(Copy(CurrParam,1,8))='/FORMAT:')Then Begin
    If StrToUpper(Copy(CurrParam,9,255))='CSV'Then OutputFormat:=_CSV Else
    If StrToUpper(Copy(CurrParam,9,255))='HTML'Then OutputFormat:=_HTML Else
    If StrToUpper(Copy(CurrParam,9,255))='JSON'Then OutputFormat:=_Json Else
    If StrToUpper(Copy(CurrParam,9,255))='PASCAL'Then OutputFormat:=_Pascal Else
    If StrToUpper(Copy(CurrParam,9,255))='SQL'Then OutputFormat:=_SQL Else
    If StrToUpper(Copy(CurrParam,9,255))='XML'Then OutputFormat:=_XML;
   End;
  End;
  For I:=1 to ParamCount do Begin
   If ParamStr(I)='1951'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population1951<>-1Then Total:=Total+_Country[J].Population1951;
    End;
    WriteLn('La population mondiale en 1951 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='1956'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population1956<>-1Then Total:=Total+_Country[J].Population1956;
    End;
    WriteLn('La population mondiale en 1956 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='1961'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population1961<>-1Then Total:=Total+_Country[J].Population1961;
    End;
    WriteLn('La population mondiale en 1961 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='1966'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population1966<>-1Then Total:=Total+_Country[J].Population1966;
    End;
    WriteLn('La population mondiale en 1966 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='1971'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population1971<>-1Then Total:=Total+_Country[J].Population1971;
    End;
    WriteLn('La population mondiale en 1971 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='1975'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population1975<>-1Then Total:=Total+_Country[J].Population1975;
    End;
    WriteLn('La population mondiale en 1975 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='1979'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population1979<>-1Then Total:=Total+_Country[J].Population1979;
    End;
    WriteLn('La population mondiale en 1979 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='1985'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population1985<>-1Then Total:=Total+_Country[J].Population1985;
    End;
    WriteLn('La population mondiale en 1985 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='1990'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population1990<>-1Then Total:=Total+_Country[J].Population1990;
    End;
    WriteLn('La population mondiale en 1990 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='1995'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population1995<>-1Then Total:=Total+_Country[J].Population1995;
    End;
    WriteLn('La population mondiale en 1995 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='2000'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population2000<>-1Then Total:=Total+_Country[J].Population2000;
    End;
    WriteLn('La population mondiale en 2000 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='2005'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population2005<>-1Then Total:=Total+_Country[J].Population2005;
    End;
    WriteLn('La population mondiale en 2005 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='2010'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population2010<>-1Then Total:=Total+_Country[J].Population2010;
    End;
    WriteLn('La population mondiale en 2010 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='2015'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population2015<>-1Then Total:=Total+_Country[J].Population2015;
    End;
    WriteLn('La population mondiale en 2015 est de ',Total:1:0);
   End
    Else
   If ParamStr(I)='2022'Then Begin
    Total:=0;
    For J:=Low(_Country) to High(_Country)do Begin
     If _Country[J].Population2022<>-1Then Total:=Total+_Country[J].Population2022;
    End;
    WriteLn('La population mondiale en 2022 est de ',Total:1:0);
   End
    Else
   For J:=Low(_Country) to High(_Country)do Begin
    If StrToUpper(ParamStr(I))='/GRAPH'Then Begin
    End
     Else
    If StrToUpper(StrPas(_Country[J].Country))=StrToUpper(ParamStr(I))Then Begin
     If(_Graph in Option)Then Begin
      Data[0]:=_Country[J].Population1951;
      Data[1]:=_Country[J].Population1956;
      Data[2]:=_Country[J].Population1961;
      Data[3]:=_Country[J].Population1966;
      Data[4]:=_Country[J].Population1971;
      Data[5]:=_Country[J].Population1975;
      Data[6]:=_Country[J].Population1979;
      Data[7]:=_Country[J].Population1985;
      Data[8]:=_Country[J].Population1990;
      Data[9]:=_Country[J].Population1995;
      Data[10]:=_Country[J].Population2000;
      Data[11]:=_Country[J].Population2005;
      Data[12]:=_Country[J].Population2010;
      Data[13]:=_Country[J].Population2015;
      Data[14]:=_Country[J].Population2022;
      MinValue:=0;
      MaxValue:=0;
      For K:=Low(Data) to High(Data) do Begin
       If Data[K]>MaxValue Then MaxValue:=Data[K];
       If Data[K]<MinValue Then MinValue:=Data[K];
      End;
      Intervalle:=(MaxValue-MinValue) div 16;
      For L:=0 to 16 do Begin
       For K:=Low(Data) to High(Data) do Begin
        Value:=Data[K] div Intervalle;
        If Value>=16-L Then Write('  *  ')
                       Else Write(' ':5);
       End;
       Case L of
        0:Write(MaxValue div 1000000);
        1:Write('mill');
        2:Write('ions');
        14:Write(MinValue div 1000000);
        15:Write('mill');
        16:Write('ion');
       End;
       WriteLn;
      End;
      Write('1951 1956 1961 1966 1971 1975 1979 1985 1990 1995 2000 2005 2010 2015 2022');
     End
      Else
     If(OutputFormat=_HTML)Then Begin
      WriteLn('<table>');
      If _Country[j].population1951<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 1951</td><td>',_Country[j].Population1951,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population1956<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 1956</td><td>',_Country[j].Population1956,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population1961<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 1961</td><td>',_Country[j].Population1961,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].population1966<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 1966</td><td>',_Country[j].Population1966,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population1971<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 1971</td><td>',_Country[j].Population1971,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population1975<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 1975</td><td>',_Country[j].Population1975,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population1979<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 1979</td><td>',_Country[j].Population1979,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population1985<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 1985</td><td>',_Country[j].Population1985,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population1990<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 1990</td><td>',_Country[j].Population1990,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population1995<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 1995</td><td>',_Country[j].Population1995,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population2000<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 2000</td><td>',_Country[j].Population2000,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population2005<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 2005</td><td>',_Country[j].Population2005,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population2010<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 2010</td><td>',_Country[j].Population2010,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
      If _Country[j].Population2015<>-1Then Begin
       WriteLn(#9'<tr>');
       WriteLn(#9#9'<td>Population en 2015</td><td>',_Country[j].Population2015,' personnes</td>');
       WriteLn(#9'</tr>');
      End;
       WriteLn(#9'<tr>');
      WriteLn(#9#9'<td>Population en 2022</td><td>',_Country[j].Population2022,' personnes</td>');
      WriteLn(#9'</tr>');
      WriteLn('</table>');
     End
      Else
     Begin
      WriteLn('Nom du pays : ',StrPas(_Country[J].Country));
      WriteLn('Superficie  : ',_Country[J].Superficie,' kmý');
      If _Country[j].Population1951<>-1Then Begin
       WriteLn('Population en 1951 : ',_Country[j].Population1951,' personnes');
      End;
      If _Country[j].Population1956<>-1Then Begin
       WriteLn('Population en 1956 : ',_Country[j].Population1956,' personnes');
      End;
      If _Country[j].Population1961<>-1Then Begin
       WriteLn('Population en 1961 : ',_Country[j].Population1961,' personnes');
      End;
      If _Country[j].Population1966<>-1Then Begin
       WriteLn('Population en 1966 : ',_Country[j].Population1966,' personnes');
      end;
      If _Country[j].population1971<>-1Then Begin
       WriteLn('Population en 1971 : ',_Country[j].Population1971,' personnes');
      End;
      If _Country[j].population1975<>-1Then Begin
       WriteLn('Population en 1975 : ',_Country[j].Population1975,' personnes');
      End;
      If _Country[j].population1979<>-1Then Begin
       Writeln('Population en 1979 : ',_Country[j].Population1979,' personnes');
      End;
      If _Country[j].Population1985<>-1Then Begin
       Writeln('Population en 1985 : ',_Country[j].Population1985,' personnes');
      End;
      If _Country[j].Population1990<>-1Then Begin
       WriteLn('Population en 1990 : ',_Country[j].Population1990,' personnes');
      End;
      If _Country[j].Population1995<>-1Then Begin
       WriteLn('Population en 1995 : ',_Country[j].Population1995,' personnes');
      End;
      If _Country[j].Population2000<>-1Then Begin
       WriteLn('Population en 2000 : ',_Country[j].Population2000,' personnes');
      End;
      If _Country[j].Population2005<>-1Then Begin
       Writeln('Population en 2005 : ',_Country[j].Population2005,' personnes');
      End;
      If _Country[j].Population2010<>-1Then Begin
       WriteLn('Population en 2010 : ',_Country[j].Population2010,' personnes');
      End;
      If _Country[j].Population2015<>-1Then Begin
       WriteLn('Population en 2015 : ',_Country[j].Population2015,' personnes');
      End;
      WriteLn('Population en 2022 : ',_Country[j].Population2022,' personnes');
     End;
    End;
   End;
  End;
 End
  Else
 Begin
  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population1951<>-1Then Total:=Total+_Country[J].Population1951;
  End;
  WriteLn('La population mondiale en 1951 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population1956<>-1Then Total:=Total+_Country[J].Population1956;
  End;
  WriteLn('La population mondiale en 1956 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population1961<>-1Then Total:=Total+_Country[J].Population1961;
  End;
  WriteLn('La population mondiale en 1961 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population1966<>-1Then Total:=Total+_Country[J].Population1966;
  End;
  WriteLn('La population mondiale en 1966 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population1971<>-1Then Total:=Total+_Country[J].Population1971;
  End;
  WriteLn('La population mondiale en 1971 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population1975<>-1Then Total:=Total+_Country[J].Population1975;
  End;
  WriteLn('La population mondiale en 1975 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population1979<>-1Then Total:=Total+_Country[J].Population1979;
  End;
  WriteLn('La population mondiale en 1979 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population1985<>-1Then Total:=Total+_Country[J].Population1985;
  End;
  WriteLn('La population mondiale en 1985 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population1990<>-1Then Total:=Total+_Country[J].Population1990;
  End;
  WriteLn('La population mondiale en 1990 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population1995<>-1Then Total:=Total+_Country[J].Population1995;
  End;
  WriteLn('La population mondiale en 1995 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population2000<>-1Then Total:=Total+_Country[J].Population2000;
  End;
  WriteLn('La population mondiale en 2000 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population2005<>-1Then Total:=Total+_Country[J].Population2005;
  End;
  WriteLn('La population mondiale en 2005 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population2010<>-1Then Total:=Total+_Country[J].Population2010;
  End;
  WriteLn('La population mondiale en 2010 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population2015<>-1Then Total:=Total+_Country[J].Population2015;
  End;
  WriteLn('La population mondiale en 2015 est de ',Total/1000000000:1:1,' milliards d''habitants');

  Total:=0;
  For J:=Low(_Country) to High(_Country)do Begin
   If _Country[J].Population2022<>-1Then Total:=Total+_Country[J].Population2022;
  End;
  WriteLn('La population mondiale en 2022 est de ',Total/1000000000:1:1,' milliards d''habitants');

 End;
END.
