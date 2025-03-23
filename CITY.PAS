{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CITY;

Type
 CityRec=Record
  Nom:String[50];
  Longitude:Real;
  Latitude:Real;
  Population:LongInt;
  AnneeFondation:Integer;
  Densite:Real;
  Superficie: Real;  { en kmý }
  Country:String[30];
 End;

Const
  Villes:Array[1..163] of CityRec=(
    (Nom: 'Alma'; Longitude: -71.6528; Latitude: 48.5404;
     Population: 31200; AnneeFondation: 1861; Densite: 74.3;
     Superficie: 420.8; Country: 'Canada'),
    (Nom: 'Ahmedabad'; Longitude: 72.5714; Latitude: 23.0225;
     Population: 8550000; AnneeFondation: 1411; Densite: 11000.0;
     Superficie: 464.2; Country: 'Inde'),
    (Nom: 'Alexandrie'; Longitude: 29.9187; Latitude: 31.2001;
     Population: 5500000; AnneeFondation: -331; Densite: 4700.0;
     Superficie: 1180.0; Country: 'gypte'),
    (Nom: 'Amsterdam'; Longitude: 4.8952; Latitude: 52.3702;
     Population: 821752; AnneeFondation: 1275; Densite: 5066;
     Superficie: 219.3; Country: 'Pays-Bas'),
    (Nom: 'Atlanta'; Longitude: -84.3880; Latitude: 33.7490;
     Population: 498000; AnneeFondation: 1837; Densite: 1460.0;
     Superficie: 347.1; Country: 'tats-Unis'),
    (Nom: 'Augsbourg'; Longitude: 10.8978; Latitude: 48.3668;
     Population: 299637; AnneeFondation: -15; Densite: 1900;
     Superficie: 146.9; Country: 'Allemagne'),
    (Nom: 'Austin'; Longitude: -97.7431; Latitude: 30.2672;
     Population: 950715; AnneeFondation: 1839; Densite: 1345.0;
     Superficie: 437.0; Country: 'USA'),
    (Nom: 'Bagdad'; Longitude: 44.3661; Latitude: 33.3152;
     Population: 8400000; AnneeFondation: 762; Densite: 6200.0;
     Superficie: 204.2; Country: 'Irak'),
    (Nom: 'Bogota'; Longitude: -74.0721; Latitude: 4.7110;
     Population: 8184000; AnneeFondation: 1538; Densite: 4200.0;
     Superficie: 1775.0; Country: 'Colombie'),
    (Nom: 'Baie-Comeau'; Longitude: -68.1538; Latitude: 49.2167;
     Population: 22950; AnneeFondation: 1936; Densite: 9.3;
     Superficie: 246.7; Country: 'Canada'),
    (Nom: 'Bangalore'; Longitude: 77.5946; Latitude: 12.9716;
     Population: 8443675; AnneeFondation: 1537; Densite: 11000.0;
     Superficie: 709.0; Country: 'Inde'),
    (Nom: 'Bangkok'; Longitude: 100.5167; Latitude: 13.7563;
     Population: 8305210; AnneeFondation: 1782; Densite: 5700.0;
     Superficie: 1569.0; Country: 'Thailand'),
    (Nom: 'Barcelone'; Longitude: 2.1734; Latitude: 41.3851;
     Population: 1664182; AnneeFondation: -15; Densite: 15980.0;
     Superficie: 101.9; Country: 'Espagne'),
    (Nom: 'Beijing'; Longitude: 116.4074; Latitude: 39.9042;
     Population: 21540000; AnneeFondation: 1045; Densite: 1200.0;
     Superficie: 16410.0; Country: 'Chine'),
    (Nom: 'Belo Horizonte'; Longitude: -43.9352; Latitude: -19.9167;
     Population: 2500000; AnneeFondation: 1897; Densite: 7200.0;
     Superficie: 331.4; Country: 'Br‚sil'),
    (Nom: 'Berlin'; Longitude: 13.4050; Latitude: 52.5200;
     Population: 3645000; AnneeFondation: 1237; Densite: 4000.0;
     Superficie: 891.8; Country: 'Allemagne'),
    (Nom: 'Berne'; Longitude: 7.4474; Latitude: 46.9481;
     Population: 134800; AnneeFondation: 1191; Densite: 2500;
     Superficie: 51.62; Country: 'Suisse'),
    (Nom: 'Bologne'; Longitude: 11.3428; Latitude: 44.4949;
     Population: 391686; AnneeFondation: -534; Densite: 2727;
     Superficie: 140.9; Country: 'Italie'),
    (Nom: 'Bordeaux'; Longitude: -0.5792; Latitude: 44.8378;
     Population: 257068; AnneeFondation: -300; Densite: 4950;
     Superficie: 49.36; Country: 'France'),
    (Nom: 'Boston'; Longitude: -71.0589; Latitude: 42.3601;
     Population: 692600; AnneeFondation: 1630; Densite: 5398.0;
     Superficie: 125.4; Country: 'Etats-Unis'),
    (Nom: 'Botosani'; Longitude: 26.6750; Latitude: 47.7486;
     Population: 102000; AnneeFondation: 1439; Densite: 1500;
     Superficie: 41.36; Country: 'Roumanie'),
    (Nom: 'Bruxelles'; Longitude: 4.3517; Latitude: 50.8503;
     Population: 186916; AnneeFondation: 979; Densite: 7300;
     Superficie: 32.61; Country: 'Belgique'),
    (Nom: 'Bucarest'; Longitude: 26.1025; Latitude: 44.4268;
     Population: 1836000; AnneeFondation: 1459; Densite: 8300;
     Superficie: 228.0; Country: 'Roumanie'),
    (Nom: 'Budapest'; Longitude: 19.0402; Latitude: 47.4979;
     Population: 1756000; AnneeFondation: 1873; Densite: 3315;
     Superficie: 525.2; Country: 'Hongrie'),
    (Nom: 'Buenos Aires'; Longitude: -58.4438; Latitude: -34.6037;
     Population: 2890151; AnneeFondation: 1536; Densite: 2100.0;
     Superficie: 203.0; Country: 'Argentine'),
    (Nom: 'Caire'; Longitude: 31.2357; Latitude: 30.0444;
     Population: 9500000; AnneeFondation: 969; Densite: 4000.0;
     Superficie: 606; Country: 'Egypte'),
    (Nom: 'Cairo'; Longitude: 31.2357; Latitude: 30.0444;
     Population: 9500000; AnneeFondation: 969; Densite: 4000.0;
     Superficie: 606; Country: 'Egypte'),
    (Nom: 'Calcutta'; Longitude: 88.3639; Latitude: 22.5726;
     Population: 4486679; AnneeFondation: 1690; Densite: 24500.0;
     Superficie: 185.0; Country: 'Inde'),
    (Nom: 'Canton'; Longitude: 113.2644; Latitude: 23.1291;
     Population: 18676605; AnneeFondation: -214; Densite: 2100.0;
     Superficie: 7434.4; Country: 'Chine'),
    (Nom: 'Cape Town'; Longitude: 18.4232; Latitude: -33.9249;
     Population: 433688; AnneeFondation: 1652; Densite: 1900.0;
     Superficie: 400.3; Country: 'Afrique du Sud'),
    (Nom: 'Chengdu'; Longitude: 104.0665; Latitude: 30.5728;
     Population: 16330000; AnneeFondation: -311; Densite: 1800.0;
     Superficie: 14390.0; Country: 'Chine'),
    (Nom: 'Chongqing'; Longitude: 106.5516; Latitude: 29.5630;
     Population: 32000000; AnneeFondation: -316; Densite: 420.0;
     Superficie: 82403.0; Country: 'Chine'),
    (Nom: 'Chibougamau'; Longitude: -74.3667; Latitude: 49.7833;
     Population: 7500; AnneeFondation: 1952; Densite: 2.8;
     Superficie: 226.6; Country: 'Canada'),
    (Nom: 'Chicago'; Longitude: -87.6298; Latitude: 41.8781;
     Population: 2716000; AnneeFondation: 1833; Densite: 4633.0;
     Superficie: 606.1; Country: 'tats-Unis'),
    (Nom: 'Cologne'; Longitude: 6.9603; Latitude: 50.9375;
     Population: 1086000; AnneeFondation: -38; Densite: 2700;
     Superficie: 405.2; Country: 'Allemagne'),
    (Nom: 'Craiova'; Longitude: 23.7949; Latitude: 44.3302;
     Population: 269506; AnneeFondation: 1400; Densite: 4000;
     Superficie: 81.41; Country: 'Roumanie'),
    (Nom: 'Dacca'; Longitude: 90.4125; Latitude: 23.8103;
     Population: 8906000; AnneeFondation: 1608; Densite: 23400.0;
     Superficie: 306.4; Country: 'Bangladesh'),
    (Nom: 'Dalian'; Longitude: 121.6147; Latitude: 38.9140;
     Population: 6900000; AnneeFondation: 1899; Densite: 900.0;
     Superficie: 12573.0; Country: 'Chine'),
    (Nom: 'Dallas'; Longitude: -96.7970; Latitude: 32.7767;
     Population: 1340000; AnneeFondation: 1841; Densite: 3805.0;
     Superficie: 997.0; Country: 'USA'),
    (Nom: 'Dar es Salam'; Longitude: 39.2083; Latitude: -6.7924;
     Population: 7800000; AnneeFondation: 1865; Densite: 3100.0;
     Superficie: 1593.0; Country: 'Tanzanie'),
    (Nom: 'Delhi'; Longitude: 77.1025; Latitude: 28.7041;
     Population: 31870000; AnneeFondation: -3000; Densite: 11320.0;
     Superficie: 1484.0; Country: 'Inde'),
    (Nom: 'Dongguan'; Longitude: 113.7463; Latitude: 23.0462;
     Population: 8460000; AnneeFondation: 1985; Densite: 3900.0;
     Superficie: 2465.0; Country: 'Chine'),
    (Nom: 'Dorohoi'; Longitude: 26.4000; Latitude: 47.9500;
     Population: 24809; AnneeFondation: 1407; Densite: 1300;
     Superficie: 24.97; Country: 'Roumanie'),
    (Nom: 'Dubai'; Longitude: 55.2708; Latitude: 25.276987;
     Population: 3331420; AnneeFondation: 1833; Densite: 6400.0;
     Superficie: 411.4; Country: 'UAE'),
    (Nom: 'Edmonton'; Longitude: -113.4909; Latitude: 53.5461;
     Population: 932546; AnneeFondation: 1795; Densite: 1320.0;
     Superficie: 684.4; Country: 'Canada'),
    (Nom: 'Florence'; Longitude: 11.2558; Latitude: 43.7696;
     Population: 382258; AnneeFondation: -59; Densite: 3700;
     Superficie: 102.4; Country: 'Italie'),
    (Nom: 'Foshan'; Longitude: 113.1214; Latitude: 23.0215;
     Population: 9500000; AnneeFondation: 1308; Densite: 3800.0;
     Superficie: 3797.7; Country: 'Chine'),
    (Nom: 'Fukuoka'; Longitude: 130.4017; Latitude: 33.5895;
     Population: 1600000; AnneeFondation: 1601; Densite: 4500.0;
     Superficie: 343.4; Country: 'Japon'),
    (Nom: 'Gasp‚'; Longitude: -64.4822; Latitude: 48.8222;
     Population: 15000; AnneeFondation: 1534; Densite: 4.5;
     Superficie: 370.8; Country: 'Canada'),
    (Nom: 'Gatineau'; Longitude: -75.7103; Latitude: 45.4763;
     Population: 276245; AnneeFondation: 1800; Densite: 750.0;
     Superficie: 342.6; Country: 'Canada'),
    (Nom: 'Gˆnes'; Longitude: 8.9463; Latitude: 44.4056;
     Population: 555939; AnneeFondation: -500; Densite: 2381;
     Superficie: 240.3; Country: 'Italie'),
    (Nom: 'Guadalajara'; Longitude: -103.3496; Latitude: 20.6597;
     Population: 1500000; AnneeFondation: 1542; Densite: 8400.0;
     Superficie: 187.9; Country: 'Mexique'),
    (Nom: 'Hambourg'; Longitude: 9.9937; Latitude: 53.5511;
     Population: 1852000; AnneeFondation: 808; Densite: 2400;
     Superficie: 755.3; Country: 'Allemagne'),
    (Nom: 'Hangzhou'; Longitude: 120.1551; Latitude: 30.2741;
     Population: 12360000; AnneeFondation: -221; Densite: 1200.0;
     Superficie: 16853.0; Country: 'Chine'),
    (Nom: 'Hanovre'; Longitude: 9.7332; Latitude: 52.3759;
     Population: 535932; AnneeFondation: 1150; Densite: 2600;
     Superficie: 204.1; Country: 'Allemagne'),
    (Nom: 'Harbin'; Longitude: 126.6424; Latitude: 45.7568;
     Population: 10800000; AnneeFondation: 1898; Densite: 850.0;
     Superficie: 53100.0; Country: 'Chine'),
    (Nom: 'Havre-Saint-Pierre'; Longitude: -63.7594; Latitude: 50.2313;
     Population: 1200; AnneeFondation: 1857; Densite: 4.9;
     Superficie: 244.0; Country: 'Canada'),
    (Nom: 'H“ Chi Minh-Ville'; Longitude: 106.6297; Latitude: 10.7769;
     Population: 9000000; AnneeFondation: 1698; Densite: 4300.0;
     Superficie: 2095.0; Country: 'Viˆt Nam'),
    (Nom: 'Hong Kong'; Longitude: 114.1694; Latitude: 22.3193;
     Population: 7451000; AnneeFondation: 1842; Densite: 6500.0;
     Superficie: 1106.0; Country: 'Chine'),
    (Nom: 'Houston'; Longitude: -95.3698; Latitude: 29.7604;
     Population: 2328000; AnneeFondation: 1836; Densite: 1374.0;
     Superficie: 1625.2; Country: 'USA'),
    (Nom: 'Hyderabad'; Longitude: 78.4867; Latitude: 17.3850;
     Population: 10100000; AnneeFondation: 1591; Densite: 18600.0;
     Superficie: 650.0; Country: 'Inde'),
    (Nom: 'Istanbul'; Longitude: 28.9784; Latitude: 41.0082;
     Population: 15029231; AnneeFondation: 660; Densite: 3000.0;
     Superficie: 5343; Country: 'Turquie'),
    (Nom: 'Jakarta'; Longitude: 106.8456; Latitude: -6.2088;
     Population: 10300000; AnneeFondation: 1527; Densite: 12000.0;
     Superficie: 662.0; Country: 'Indon‚sie'),
    (Nom: 'J‚rusalem'; Longitude: 35.2137; Latitude: 31.7683;
     Population: 936425; AnneeFondation: -3000; Densite: 7500.0;
     Superficie: 125.1; Country: 'Isra‰l'),
    (Nom: 'Jinan'; Longitude: 117.1201; Latitude: 36.6512;
     Population: 9000000; AnneeFondation: -300; Densite: 1200.0;
     Superficie: 8177.0; Country: 'Chine'),
    (Nom: 'Johannesbourg'; Longitude: 28.0473; Latitude: -26.2041;
     Population: 5730000; AnneeFondation: 1886; Densite: 3000.0;
     Superficie: 1644.0; Country: 'Afrique du Sud'),
    (Nom: 'Karachi'; Longitude: 67.0099; Latitude: 24.8607;
     Population: 15400000; AnneeFondation: 1729; Densite: 24600.0;
     Superficie: 591.0; Country: 'Pakistan'),
    (Nom: 'Khartoum'; Longitude: 32.5324; Latitude: 15.5007;
     Population: 5200000; AnneeFondation: 1821; Densite: 1500.0;
     Superficie: 809.0; Country: 'Soudan'),
    (Nom: 'Kiev'; Longitude: 30.5234; Latitude: 50.4501;
     Population: 2962180; AnneeFondation: 482; Densite: 3684;
     Superficie: 839.0; Country: 'Ukraine'),
    (Nom: 'Kinshasa'; Longitude: 15.3120; Latitude: -4.4419;
     Population: 11150000; AnneeFondation: 1881; Densite: 1834.0;
     Superficie: 996.0; Country: 'Democratic Republic of the Congo'),
    (Nom: 'Kolkata'; Longitude: 88.3639; Latitude: 22.5726;
     Population: 4486679; AnneeFondation: 1690; Densite: 24500.0;
     Superficie: 185.0; Country: 'India'),
    (Nom: 'Kuala Lumpur'; Longitude: 101.6869; Latitude: 3.1390;
     Population: 8300000; AnneeFondation: 1857; Densite: 7700.0;
     Superficie: 243.0; Country: 'Malaisie'),
    (Nom: 'Kyoto'; Longitude: 135.7681; Latitude: 35.0116;
     Population: 1465000; AnneeFondation: 794; Densite: 1800.0;
     Superficie: 827.8; Country: 'Japon'),
    (Nom: 'Lagos'; Longitude: 3.3792; Latitude: 6.5244;
     Population: 14500000; AnneeFondation: 1865; Densite: 9800.0;
     Superficie: 1130.0; Country: 'Nigeria'),
    (Nom: 'Luanda'; Longitude: 13.2343; Latitude: -8.8383;
     Population: 8900000; AnneeFondation: 1576; Densite: 7000.0;
     Superficie: 1180.0; Country: 'Angola'),
    (Nom: 'Lahore'; Longitude: 74.3587; Latitude: 31.5204;
     Population: 13200000; AnneeFondation: -1000; Densite: 6300.0;
     Superficie: 2225.0; Country: 'Pakistan'),
    (Nom: 'Laval'; Longitude: -73.7333; Latitude: 45.5833;
     Population: 422993; AnneeFondation: 1965; Densite: 2533.2;
     Superficie: 242.8; Country: 'Canada'),
    (Nom: 'Lima'; Longitude: -77.0428; Latitude: -12.0464;
     Population: 8900000; AnneeFondation: 1535; Densite: 2780.0;
     Superficie: 267.0; Country: 'P‚rou'),
    (Nom: 'London'; Longitude: -0.1278; Latitude: 51.5074;
     Population: 8982000; AnneeFondation: 43; Densite: 5500.0;
     Superficie: 1572.0; Country: 'Royaume-Uni'),
    (Nom: 'Londres'; Longitude: -0.1278; Latitude: 51.5074;
     Population: 8982000; AnneeFondation: 43; Densite: 5500.0;
     Superficie: 1572.0; Country: 'Royaume-Uni'),
    (Nom: 'Los Angeles'; Longitude: -118.2437; Latitude: 34.0522;
     Population: 3980400; AnneeFondation: 1781; Densite: 3053.0;
     Superficie: 1213.9; Country: 'tats-Unis'),
    (Nom: 'Luxembourg'; Longitude: 6.1319; Latitude: 49.6117;
     Population: 132778; AnneeFondation: 963; Densite: 2500;
     Superficie: 51.46; Country: 'Luxembourg'),
    (Nom: 'Lyon'; Longitude: 4.8357; Latitude: 45.764;
     Population: 522969; AnneeFondation: -43; Densite: 10700;
     Superficie: 47.87; Country: 'France'),
    (Nom: 'Madras'; Longitude: 80.2785; Latitude: 13.0827;
     Population: 11324000; AnneeFondation: 1639; Densite: 26500.0;
     Superficie: 426.0; Country: 'Inde'),
    (Nom: 'Madrid'; Longitude: -3.7038; Latitude: 40.4168;
     Population: 3245000; AnneeFondation: 852; Densite: 5200.0;
     Superficie: 604.3; Country: 'Espagne'),
    (Nom: 'Manille'; Longitude: 120.9842; Latitude: 14.5995;
     Population: 13923452; AnneeFondation: 1571; Densite: 46500.0;
     Superficie: 619.6; Country: 'Philippines'),
    (Nom: 'Marseille'; Longitude: 5.3698; Latitude: 43.2965;
     Population: 870321; AnneeFondation: -600; Densite: 3616.0;
     Superficie: 240.6; Country: 'France'),
    (Nom: 'Mexico'; Longitude: -99.1332; Latitude: 19.4326;
     Population: 8918653; AnneeFondation: 1325; Densite: 6100.0;
     Superficie: 1485.0; Country: 'Mexique'),
    (Nom: 'Milan'; Longitude: 9.1905; Latitude: 45.4642;
     Population: 1378689; AnneeFondation: -400; Densite: 7600.0;
     Superficie: 181.8; Country: 'Italie'),
    (Nom: 'Miami'; Longitude: -80.1918; Latitude: 25.7617;
     Population: 470000; AnneeFondation: 1896; Densite: 4900.0;
     Superficie: 143.1; Country: 'tats-Unis'),
    (Nom: 'Monaco'; Longitude: 7.4246; Latitude: 43.7384;
     Population: 39242; AnneeFondation: 1297; Densite: 19000;
     Superficie: 2.02; Country: 'Monaco'),
    (Nom: 'Montreal'; Longitude: -73.5673; Latitude: 45.5017;
     Population: 1704694; AnneeFondation: 1642; Densite: 2200.0;
     Superficie: 365.0; Country: 'Canada'),
    (Nom: 'Moscou'; Longitude: 37.6173; Latitude: 55.7558;
     Population: 11920000; AnneeFondation: 1147; Densite: 5000.0;
     Superficie: 2511.0; Country: 'Russie'),
    (Nom: 'Moscow'; Longitude: 37.6173; Latitude: 55.7558;
     Population: 11920000; AnneeFondation: 1147; Densite: 5000.0;
     Superficie: 2511.0; Country: 'Russie'),
    (Nom: 'Munich'; Longitude: 11.5820; Latitude: 48.1351;
     Population: 1472000; AnneeFondation: 1158; Densite: 4800.0;
     Superficie: 310.7; Country: 'Allemagne'),
    (Nom: 'Minsk'; Longitude: 27.5615; Latitude: 53.9006;
     Population: 2017484; AnneeFondation: 1067; Densite: 5600;
     Superficie: 409.5; Country: 'Bi‚lorussie'),
    (Nom: 'Nagasaki'; Longitude: 129.8777; Latitude: 32.7503;
     Population: 407624; AnneeFondation: 1571; Densite: 1080.0;
     Superficie: 405.9; Country: 'Japon'),
    (Nom: 'Nagoya'; Longitude: 136.9066; Latitude: 35.1815;
     Population: 2296000; AnneeFondation: 1610; Densite: 6900.0;
     Superficie: 326.4; Country: 'Japon'),
    (Nom: 'Nankin'; Longitude: 118.7969; Latitude: 32.0603;
     Population: 8800000; AnneeFondation: -495; Densite: 1100.0;
     Superficie: 6587.0; Country: 'Chine'),
    (Nom: 'Nantes'; Longitude: -1.5536; Latitude: 47.2184;
     Population: 320732; AnneeFondation: -50; Densite: 4900;
     Superficie: 65.19; Country:'France'),
    (Nom: 'New Delhi'; Longitude: 77.1025; Latitude: 28.6139;
     Population: 2499980; AnneeFondation: 1911; Densite: 12000.0;
     Superficie: 42.7; Country: 'Inde'),
    (Nom: 'New York'; Longitude: -74.0060; Latitude: 40.7128;
     Population: 8419600; AnneeFondation: 1624; Densite: 10417.0;
     Superficie: 789.4; Country: 'tats-Unis'),
    (Nom: 'Nuremberg'; Longitude: 11.0767; Latitude: 49.4521;
     Population: 518370; AnneeFondation: 1050; Densite: 2700;
     Superficie: 186.4; Country: 'Allemagne'),
    (Nom: 'Osaka'; Longitude: 135.5023; Latitude: 34.6937;
     Population: 2691000; AnneeFondation: 1889; Densite: 12000.0;
     Superficie: 225.2; Country: 'Japon'),
    (Nom: 'Ottawa'; Longitude: -75.6972; Latitude: 45.4215;
     Population: 934243; AnneeFondation: 1855; Densite: 331.7;
     Superficie: 2778.0; Country: 'Canada'),
    (Nom: 'Paris'; Longitude: 2.3522; Latitude: 48.8566;
     Population: 2148000; AnneeFondation: 3; Densite: 20510.0;
     Superficie: 105.4; Country: 'France'),
    (Nom: 'Phoenix'; Longitude: -112.0740; Latitude: 33.4484;
     Population: 1690000; AnneeFondation: 1867; Densite: 1195.0;
     Superficie: 1340.6; Country: 'tats-Unis'),
    (Nom: 'Philadelphia'; Longitude: -75.1652; Latitude: 39.9526;
     Population: 1584200; AnneeFondation: 1682; Densite: 4524.0;
     Superficie: 347.5; Country: 'tats-Unis'),
    (Nom: 'Prypiat'; Longitude: 30.0560; Latitude: 51.3890;
     Population: 0; AnneeFondation: 1970; Densite: 0;
     Superficie: 8.42; Country: 'Ukraine'),
    (Nom: 'Pune'; Longitude: 73.8567; Latitude: 18.5204;
     Population: 7200000; AnneeFondation: 937; Densite: 6900.0;
     Superficie: 484.0; Country: 'Inde'),
    (Nom: 'Qingdao'; Longitude: 120.3826; Latitude: 36.0671;
     Population: 9200000; AnneeFondation: 1891; Densite: 1200.0;
     Superficie: 11293.0; Country: 'Chine'),
    (Nom: 'Rangoun'; Longitude: 96.1583; Latitude: 16.8409;
     Population: 5200000; AnneeFondation: 1755; Densite: 6200.0;
     Superficie: 598.8; Country: 'Birmanie'),
    (Nom: 'Rennes'; Longitude: -1.6778; Latitude: 48.1173;
     Population: 220488; AnneeFondation: -50; Densite: 4371;
     Superficie: 50.39; Country: 'France'),
    (Nom: 'Riga'; Longitude: 24.1052; Latitude: 56.9496;
     Population: 615978; AnneeFondation: 1201; Densite: 2200;
     Superficie: 307.17; Country: 'Lettonie'),
    (Nom: 'Rimouski'; Longitude: -68.5190; Latitude: 48.4482;
     Population: 49000; AnneeFondation: 1696; Densite: 89.5;
     Superficie: 243.3; Country: 'Canada'),
    (Nom: 'Rio de Janeiro'; Longitude: -43.1729; Latitude: -22.9068;
     Population: 6748000; AnneeFondation: 1565; Densite: 5400.0;
     Superficie: 1255.0; Country: 'Br‚sil'),
    (Nom: 'Riyad'; Longitude: 46.6753; Latitude: 24.7136;
     Population: 7700000; AnneeFondation: 1744; Densite: 4700.0;
     Superficie: 1600.0; Country: 'Arabie saoudite'),
    (Nom: 'Riyadh'; Longitude: 46.7200; Latitude: 24.7137;
     Population: 7000000; AnneeFondation: 1745; Densite: 340.0;
     Superficie: 1425.0; Country: 'Arabie saoudite'),
    (Nom: 'Rome'; Longitude: 12.4964; Latitude: 41.9028;
     Population: 2872800; AnneeFondation: -753; Densite: 2300.0;
     Superficie: 1285.3; Country: 'Italie'),
    (Nom: 'Saguenay'; Longitude: -71.2093; Latitude: 48.4088;
     Population: 146000; AnneeFondation: 2002; Densite: 62.5;
     Superficie: 1135.0; Country: 'Canada'),
    (Nom: 'Saint-Malo'; Longitude: -2.026; Latitude: 48.6493;
     Population: 46097; AnneeFondation: 100; Densite: 1205;
     Superficie: 36.58; Country: 'France'),
    (Nom: 'Saint-P‚tersbourg'; Longitude: 30.3351; Latitude: 59.9343;
     Population: 5384000; AnneeFondation: 1703; Densite: 3600.0;
     Superficie: 1439.0; Country: 'Russie'),
    (Nom: 'San Antonio'; Longitude: -98.4936; Latitude: 29.4241;
     Population: 1547253; AnneeFondation: 1718; Densite: 1152.0;
     Superficie: 1214.0; Country: 'tats-Unis'),
    (Nom: 'San Diego'; Longitude: -117.1611; Latitude: 32.7157;
     Population: 1423851; AnneeFondation: 1769; Densite: 1445.0;
     Superficie: 964.5; Country: 'tats-Unis'),
    (Nom: 'San Francisco'; Longitude: -122.4194; Latitude: 37.7749;
     Population: 870887; AnneeFondation: 1776; Densite: 6800.0;
     Superficie: 121.4; Country: 'tats-Unis'),
    (Nom: 'San Jose'; Longitude: -121.8863; Latitude: 37.3382;
     Population: 1026908; AnneeFondation: 1777; Densite: 1630.0;
     Superficie: 467.4; Country: 'tats-Unis'),
    (Nom: 'Sao Paulo'; Longitude: -46.6339; Latitude: -23.5505;
     Population: 12300000; AnneeFondation: 1554; Densite: 7100.0;
     Superficie: 1521.1; Country: 'Br‚sil'),
    (Nom: 'Santiago'; Longitude: -70.6483; Latitude: -33.4489;
     Population: 6600000; AnneeFondation: 1541; Densite: 8500.0;
     Superficie: 641.0; Country: 'Chili'),
    (Nom: 'Sarajevo'; Longitude: 18.4131; Latitude: 43.8563;
     Population: 275524; AnneeFondation: 1461; Densite: 2300;
     Superficie: 141.5; Country: 'Bosnie-Herz‚govine'),
    (Nom: 'Schefferville'; Longitude: -71.3200; Latitude: 54.8667;
     Population: 800; AnneeFondation: 1950; Densite: 4.2;
     Superficie: 191.8; Country: 'Canada'),
    (Nom: 'S‚oul'; Longitude: 126.9780; Latitude: 37.5665;
     Population: 9700000; AnneeFondation: -18; Densite: 16000.0;
     Superficie: 605.2; Country: 'Cor‚e du Sud'),
    (Nom: 'Sept-Iles'; Longitude: -66.3833; Latitude: 50.2000;
     Population: 25000; AnneeFondation: 1857; Densite: 7.6;
     Superficie: 328.5; Country: 'Canada'),
    (Nom: 'Shanghai'; Longitude: 121.4737; Latitude: 31.2304;
     Population: 24280000; AnneeFondation: 1291; Densite: 3800.0;
     Superficie: 6340.5; Country: 'Chine'),
    (Nom: 'Shenyang'; Longitude: 123.4315; Latitude: 41.8057;
     Population: 9000000; AnneeFondation: -300; Densite: 1200.0;
     Superficie: 12948.0; Country: 'Chine'),
    (Nom: 'Shenzhen'; Longitude: 114.0579; Latitude: 22.5431;
     Population: 13000000; AnneeFondation: 1979; Densite: 8500.0;
     Superficie: 1996.0; Country: 'Chine'),
    (Nom: 'Sibiu'; Longitude: 24.1459; Latitude: 45.7928;
     Population: 147245; AnneeFondation: 1191; Densite: 1400;
     Superficie: 121.0; Country: 'Roumanie'),
    (Nom: 'Sienne'; Longitude: 11.3308; Latitude: 43.3186;
     Population: 53906; AnneeFondation: -300; Densite: 480;
     Superficie: 118.7; Country: 'Italie'),
    (Nom: 'Singapour'; Longitude: 103.8198; Latitude: 1.3521;
     Population: 5800000; AnneeFondation: 1819; Densite: 8290.0;
     Superficie: 721.5; Country: 'Singapour'),
    (Nom: 'Sovata'; Longitude: 25.0667; Latitude: 46.6000;
     Population: 10138; AnneeFondation: 1578; Densite: 200;
     Superficie: 47.17; Country: 'Roumanie'),
    (Nom: 'Suceava'; Longitude: 26.2528; Latitude: 47.6513;
     Population: 92221; AnneeFondation: 1388; Densite: 1600;
     Superficie: 52.1; Country: 'Roumanie'),
    (Nom: 'Surat'; Longitude: 72.8311; Latitude: 21.1702;
     Population: 7600000; AnneeFondation: 1516; Densite: 13600.0;
     Superficie: 326.5; Country: 'Inde'),
    (Nom: 'Suzhou'; Longitude: 120.5853; Latitude: 31.2989;
     Population: 10700000; AnneeFondation: -514; Densite: 1300.0;
     Superficie: 8657.0; Country: 'Chine'),
    (Nom: 'Sydney'; Longitude: 151.2093; Latitude: -33.8688;
     Population: 5312163; AnneeFondation: 1788; Densite: 4000.0;
     Superficie: 1687; Country: 'Australie'),
    (Nom: 'Tallinn'; Longitude: 24.7536; Latitude: 59.4370;
     Population: 444369; AnneeFondation: 1248; Densite: 2660;
     Superficie: 159.3; Country: 'Estonie'),
    (Nom: 'Tampere'; Longitude: 23.7608; Latitude: 61.4982;
     Population: 249060; AnneeFondation: 1779; Densite: 419;
     Superficie: 689.6; Country: 'Finlande'),
    (Nom: 'T‚h‚ran'; Longitude: 51.3890; Latitude: 35.6892;
     Population: 9153000; AnneeFondation: -600; Densite: 11500.0;
     Superficie: 730.0; Country: 'Iran'),
    (Nom: 'Tianjin'; Longitude: 117.2000; Latitude: 39.1333;
     Population: 13866009; AnneeFondation: 1404; Densite: 1280.0;
     Superficie: 11760.0; Country: 'Chine'),
    (Nom: 'Tirana'; Longitude: 19.8189; Latitude: 41.3275;
     Population: 557422; AnneeFondation: 1614; Densite: 5200;
     Superficie: 41.8; Country: 'Albanie'),
    (Nom: 'Tokyo'; Longitude: 139.6917; Latitude: 35.6895;
     Population: 13929286; AnneeFondation: 1603; Densite: 6190.0;
     Superficie: 2191; Country: 'Japon'),
    (Nom: 'Toronto'; Longitude: -79.3832; Latitude: 43.6532;
     Population: 2731571; AnneeFondation: 1793; Densite: 4200.0;
     Superficie: 630.2; Country: 'Canada'),
    (Nom: 'Toulouse'; Longitude: 1.4442; Latitude: 43.6047;
     Population: 498003; AnneeFondation: -200; Densite: 4117;
     Superficie: 118.3; Country: 'France'),
    (Nom: 'Tours'; Longitude: 0.6848; Latitude: 47.3941;
     Population: 137087; AnneeFondation: -1; Densite: 4350;
     Superficie: 34.67; Country: 'France'),
    (Nom: 'Trois-RiviŠres'; Longitude: -72.5500; Latitude: 46.3400;
     Population: 134413; AnneeFondation: 1634; Densite: 762.4;
     Superficie: 176.2; Country: 'Canada'),
    (Nom: 'Vancouver'; Longitude: -123.1216; Latitude: 49.2827;
     Population: 631490; AnneeFondation: 1886; Densite: 5179.4;
     Superficie: 114.0; Country: 'Canada'),
    (Nom: 'Varsovie'; Longitude: 21.0122; Latitude: 52.2298;
     Population: 1793579; AnneeFondation: 1200; Densite: 3300;
     Superficie: 517.2; Country: 'Pologne'),
    (Nom: 'Vaslui'; Longitude: 27.7333; Latitude: 46.6333;
     Population: 55207; AnneeFondation: 1375; Densite: 1300;
     Superficie: 81.0; Country: 'Roumanie'),
    (Nom: 'Venise'; Longitude: 12.3155; Latitude: 45.4408;
     Population: 258685; AnneeFondation: 421; Densite: 653;
     Superficie: 414.6; Country: 'Italie'),
    (Nom: 'Vilnius'; Longitude: 25.2797; Latitude: 54.6872;
     Population: 592389; AnneeFondation: 1323; Densite: 1400;
     Superficie: 401.0; Country: 'Lituanie'),
    (Nom: 'Vlora'; Longitude: 19.4897; Latitude: 40.4661;
     Population: 130827; AnneeFondation: -6; Densite: 1800;
     Superficie: 647.9; Country: 'Albanie'),
    (Nom: 'Washington'; Longitude: -77.0369; Latitude: 38.9072;
     Population: 705749; AnneeFondation: 1790; Densite: 4000.0;
     Superficie: 177.0; Country: 'tats-Unis'),
    (Nom: 'Winnipeg'; Longitude: -97.1384; Latitude: 49.8951;
     Population: 749607; AnneeFondation: 1873; Densite: 1485.0;
     Superficie: 464.1; Country: 'Canada'),
    (Nom: 'Wuhan'; Longitude: 114.3055; Latitude: 30.5928;
     Population: 12300000; AnneeFondation: -500; Densite: 1400.0;
     Superficie: 8494.0; Country: 'Chine'),
    (Nom: 'Xi''an'; Longitude: 108.9398; Latitude: 34.3416;
     Population: 8900000; AnneeFondation: -202; Densite: 1900.0;
     Superficie: 10108.0; Country: 'Chine')





  );

var
  VilleNom: string;
  Found: Boolean;
  i: Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I]in['','‚','Š','ˆ',#232,#233,#234]Then S[I]:='E'Else
  If S[I]in['Œ',#238]Then S[I]:='I'Else
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CITY : Cette commande permet de retourner ',
          'les informations sur la ville sp‚cifi‚');
  WriteLn;
  Writeln('Syntaxe: CITY nom');
  WriteLn;
  WriteLn(' nom  Ce paramŠtre permet d''indiquer le nom de la ville.');
 End
  Else
 If ParamCount>0Then Begin
  VilleNom:=ParamStr(1);
  Found:=False;
  For i:=1 to High(Villes) do Begin
   If StrToUpper(Villes[i].Nom)=StrToUpper(VilleNom)Then Begin
    Found := True;
    WriteLn('Nom: ', Villes[i].Nom);
    WriteLn('Longitude: ', Villes[i].Longitude:0:4);
    WriteLn('Latitude: ', Villes[i].Latitude:0:4);
    WriteLn('Population: ', Villes[i].Population);
    If Villes[i].AnneeFondation > 0 Then
     WriteLn('Ann‚e de fondation: ', Villes[i].AnneeFondation);
    WriteLn('Densit‚: ', Villes[i].Densite:0:2, ' habitants/kmý');
    WriteLn('Superficie: ', Villes[i].Superficie:0:2, ' kmý');
    Break;
    End;
  End;
  If Not Found Then WriteLn('Ville non trouv‚e.');
 End;
END.
