{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program HOLIDAY;

Type
 TJourFerie=Record
  Pays:String[20];
  Jour:Integer;
  Mois:Integer;
  Nom:String[40];
 End;

Const
 JoursFeries:Array[1..727] of TJourFerie = (
  (Pays:'Afghanistan'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Afghanistan'; Jour: 28; Mois: 4; Nom: 'Jour de la Victoire'),
  (Pays:'Afghanistan'; Jour: 19; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Afghanistan'; Jour: 9; Mois: 9; Nom: 'Jour du Martyr'),
  (Pays:'Afghanistan'; Jour: 15; Mois: 8; Nom: 'Nouvel An islamique'),

  (Pays:'Afrique du Sud'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Afrique du Sud'; Jour: 21; Mois: 3; Nom: 'Journ‚e des Droits de l''Homme'),
  (Pays:'Afrique du Sud'; Jour: 27; Mois: 4; Nom: 'Jour de la Libert‚'),
  (Pays:'Afrique du Sud'; Jour: 16; Mois: 6; Nom: 'Jour de la Jeunesse'),
  (Pays:'Afrique du Sud'; Jour: 24; Mois: 9; Nom: 'Journ‚e du Patrimoine'),

  (Pays:'Albanie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Albanie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Albanie'; Jour: 28; Mois: 11; Nom: 'Ind‚pendance'),
  (Pays:'Albanie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Alg‚rie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Alg‚rie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Alg‚rie'; Jour: 5; Mois: 7; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Alg‚rie'; Jour: 1; Mois: 11; Nom: 'R‚volution Alg‚rienne'),
  (Pays:'Alg‚rie'; Jour: 12; Mois: 1; Nom: 'Nouvel An berbŠre'),

  (Pays:'Allemagne'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Allemagne'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Allemagne'; Jour: 3; Mois: 10; Nom: 'Jour de l''Unit‚ Allemande'),
  (Pays:'Allemagne'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Andorre'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Andorre'; Jour: 14; Mois: 3; Nom: 'Jour de la Constitution'),
  (Pays:'Andorre'; Jour: 8; Mois: 9; Nom: 'Fˆte de la Vierge de Meritxell'),
  (Pays:'Andorre'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'Andorre'; Jour: 26; Mois: 12; Nom: 'Saint-tienne'),

  (Pays:'Angola'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Angola'; Jour: 4; Mois: 2; Nom: 'Jour du D‚but de la Lutte Arm‚e'),
  (Pays:'Angola'; Jour: 4; Mois: 4; Nom: 'Journ‚e de la Paix'),
  (Pays:'Angola'; Jour: 11; Mois: 11; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Angola'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Anguilla'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Anguilla'; Jour: 30; Mois: 5; Nom: 'Jour de la R‚volution'),
  (Pays:'Anguilla'; Jour: 10; Mois: 8; Nom: 'Jour de l''Emancipation'),
  (Pays:'Anguilla'; Jour: 19; Mois: 12; Nom: 'Jour de la Lib‚ration'),
  (Pays:'Anguilla'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Arabie Saoudite'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Arabie Saoudite'; Jour: 23; Mois: 9; Nom: 'Fˆte nationale'),
  (Pays:'Arabie Saoudite'; Jour: 1; Mois: 10; Nom: 'Fˆte de l''A‹d al-Fitr'),
  (Pays:'Arabie Saoudite'; Jour: 10; Mois: 12; Nom: 'Fˆte de l''A‹d al-Adha'),
  (Pays:'Arabie Saoudite'; Jour: 27; Mois: 7; Nom: 'Jour d''Arafat'),

  (Pays:'Argentine'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Argentine'; Jour: 24; Mois: 3; Nom: 'Jour de la M‚moire'),
  (Pays:'Argentine'; Jour: 25; Mois: 5; Nom: 'Jour de la R‚volution'),
  (Pays:'Argentine'; Jour: 9; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Argentine'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Arm‚nie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Arm‚nie'; Jour: 6; Mois: 1; Nom: 'No‰l arm‚nien'),
  (Pays:'Arm‚nie'; Jour: 24; Mois: 4; Nom: 'Jour du g‚nocide arm‚nien'),
  (Pays:'Arm‚nie'; Jour: 9; Mois: 5; Nom: 'Jour de la Victoire'),
  (Pays:'Arm‚nie'; Jour: 21; Mois: 9; Nom: 'Jour de l''Ind‚pendance'),

  (Pays:'Aruba'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Aruba'; Jour: 25; Mois: 1; Nom: 'Fˆte de Betico Croes'),
  (Pays:'Aruba'; Jour: 18; Mois: 3; Nom: 'Jour du Drapeau et de l''Hymne'),
  (Pays:'Aruba'; Jour: 30; Mois: 4; Nom: 'Jour de la Reine'),
  (Pays:'Aruba'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Australie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Australie'; Jour: 26; Mois: 1; Nom: 'Australia Day'),
  (Pays:'Australie'; Jour: 25; Mois: 4; Nom: 'ANZAC Day'),
  (Pays:'Australie'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'Australie'; Jour: 26; Mois: 12; Nom: 'Boxing Day'),

  (Pays:'Autriche'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Autriche'; Jour: 6; Mois: 1; Nom: 'piphanie'),
  (Pays:'Autriche'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Autriche'; Jour: 26; Mois: 10; Nom: 'Fˆte nationale'),
  (Pays:'Autriche'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Azerba‹djan'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Azerba‹djan'; Jour: 8; Mois: 3; Nom: 'Journ‚e de la Femme'),
  (Pays:'Azerba‹djan'; Jour: 20; Mois: 3; Nom: 'Novruz'),
  (Pays:'Azerba‹djan'; Jour: 28; Mois: 5; Nom: 'Jour de la R‚publique'),
  (Pays:'Azerba‹djan'; Jour: 18; Mois: 10; Nom: 'Jour de l''Ind‚pendance'),

  (Pays:'Bahamas'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Bahamas'; Jour: 10; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Bahamas'; Jour: 5; Mois: 8; Nom: 'Jour de l''Emancipation'),
  (Pays:'Bahamas'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'Bahamas'; Jour: 26; Mois: 12; Nom: 'Boxing Day'),

  (Pays:'Bahre‹n'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Bahre‹n'; Jour: 16; Mois: 12; Nom: 'Fˆte nationale'),
  (Pays:'Bahre‹n'; Jour: 1; Mois: 10; Nom: 'A‹d al-Fitr'),
  (Pays:'Bahre‹n'; Jour: 10; Mois: 12; Nom: 'A‹d al-Adha'),
  (Pays:'Bahre‹n'; Jour: 27; Mois: 7; Nom: 'Jour d''Arafat'),

  (Pays:'Bangladesh'; Jour: 21; Mois: 2; Nom: 'Journ‚e de la Langue Maternelle'),
  (Pays:'Bangladesh'; Jour: 26; Mois: 3; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Bangladesh'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Bangladesh'; Jour: 16; Mois: 12; Nom: 'Jour de la Victoire'),
  (Pays:'Bangladesh'; Jour: 10; Mois: 4; Nom: 'Nouvel An Bengali'),

  (Pays:'Barbade'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Barbade'; Jour: 21; Mois: 1; Nom: 'Errol Barrow Day'),
  (Pays:'Barbade'; Jour: 28; Mois: 4; Nom: 'National Heroes Day'),
  (Pays:'Barbade'; Jour: 30; Mois: 11; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Barbade'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Belgique'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Belgique'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Belgique'; Jour: 21; Mois: 7; Nom: 'Fˆte nationale'),
  (Pays:'Belgique'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Belize'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Belize'; Jour: 9; Mois: 3; Nom: 'Baron Bliss Day'),
  (Pays:'Belize'; Jour: 10; Mois: 9; Nom: 'St George''s Caye Day'),
  (Pays:'Belize'; Jour: 21; Mois: 9; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Belize'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'B‚nin'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'B‚nin'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'B‚nin'; Jour: 1; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'B‚nin'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'B‚nin'; Jour: 1; Mois: 11; Nom: 'Toussaint'),

  (Pays:'Bermudes'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Bermudes'; Jour: 24; Mois: 5; Nom: 'Bermuda Day'),
  (Pays:'Bermudes'; Jour: 1; Mois: 8; Nom: 'Emancipation Day'),
  (Pays:'Bermudes'; Jour: 2; Mois: 8; Nom: 'Somers Day'),
  (Pays:'Bermudes'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Bhoutan'; Jour: 1; Mois: 1; Nom: 'Nouvel An gr‚gorien'),
  (Pays:'Bhoutan'; Jour: 21; Mois: 2; Nom: 'Anniversaire du roi'),
  (Pays:'Bhoutan'; Jour: 2; Mois: 5; Nom: 'Anniversaire de Jigme Dorji Wangchuck'),
  (Pays:'Bhoutan'; Jour: 17; Mois: 12; Nom: 'Jour de la Fˆte nationale'),
  (Pays:'Bhoutan'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Bi‚lorussie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Bi‚lorussie'; Jour: 25; Mois: 3; Nom: 'Jour de la Libert‚'),
  (Pays:'Bi‚lorussie'; Jour: 9; Mois: 5; Nom: 'Jour de la Victoire'),
  (Pays:'Bi‚lorussie'; Jour: 7; Mois: 11; Nom: 'R‚volution d''Octobre'),
  (Pays:'Bi‚lorussie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Bolivie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Bolivie'; Jour: 6; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Bolivie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Bolivie'; Jour: 2; Mois: 11; Nom: 'Jour des Morts'),
  (Pays:'Bolivie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Br‚sil';Jour: 1; Mois: 1; Nom:'Jour de l''An'),
  (Pays:'Br‚sil';Jour: 7; Mois: 9; Nom:'Ind‚pendance du Br‚sil'),
  (Pays:'Br‚sil';Jour: 12; Mois: 10; Nom:'Fˆte de Notre-Dame Aparecida'),
  (Pays:'Br‚sil';Jour: 25; Mois: 12; Nom:'No‰l'),

  (Pays:'Brunei'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Brunei'; Jour: 23; Mois: 2; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Brunei'; Jour: 31; Mois: 7; Nom: 'Sultan''s Birthday'),
  (Pays:'Brunei'; Jour: 1; Mois: 10; Nom: 'A‹d al-Fitr'),
  (Pays:'Brunei'; Jour: 10; Mois: 12; Nom: 'A‹d al-Adha'),

  (Pays:'Bulgarie';Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Bulgarie';Jour: 3; Mois: 3; Nom: 'Jour de la Lib‚ration'),
  (Pays:'Bulgarie';Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Bulgarie';Jour: 6; Mois: 9; Nom: 'Jour de l''Unification'),
  (Pays:'Bulgarie';Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Burkina Faso'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Burkina Faso'; Jour: 3; Mois: 1; Nom: 'Jour de la R‚volution'),
  (Pays:'Burkina Faso'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Burkina Faso'; Jour: 5; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Burkina Faso'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Burundi'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Burundi'; Jour: 5; Mois: 2; Nom: 'Unit‚ nationale'),
  (Pays:'Burundi'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Burundi'; Jour: 1; Mois: 7; Nom: 'Ind‚pendance'),
  (Pays:'Burundi'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Cambodge'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Cambodge'; Jour: 7; Mois: 1; Nom: 'Jour de la Victoire'),
  (Pays:'Cambodge'; Jour: 13; Mois: 4; Nom: 'Nouvel An Khmer'),
  (Pays:'Cambodge'; Jour: 24; Mois: 9; Nom: 'Jour de la Constitution'),
  (Pays:'Cambodge'; Jour: 9; Mois: 11; Nom: 'Ind‚pendance'),

  (Pays:'Cameroun'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Cameroun'; Jour: 11; Mois: 2; Nom: 'Fˆte de la Jeunesse'),
  (Pays:'Cameroun'; Jour: 20; Mois: 5; Nom: 'Fˆte Nationale'),
  (Pays:'Cameroun'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Cameroun'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Canada';Jour:1;Mois:1;Nom:'Jour de l''An'),
  (Pays:'Canada';Jour:1;Mois:7;Nom:'Fˆte de la Reine / Fˆte des patriotes'),
  (Pays:'Canada';Jour:25;Mois:12;Nom:'No‰l'),
  (Pays:'Canada';Jour:24;Mois:6;Nom:'Fˆte de la Saint-Jean Baptiste'),
  (Pays:'Canada';Jour:1;Mois:7;Nom:'Fˆte du Canada'),

  (Pays:'Cap-Vert'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Cap-Vert'; Jour: 20; Mois: 1; Nom: 'Journ‚e des H‚ros Nationaux'),
  (Pays:'Cap-Vert'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Cap-Vert'; Jour: 5; Mois: 7; Nom: 'Ind‚pendance'),
  (Pays:'Cap-Vert'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Chili'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Chili'; Jour: 21; Mois: 5; Nom: 'Jour des Forces arm‚es'),
  (Pays:'Chili'; Jour: 18; Mois: 9; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Chili'; Jour: 19; Mois: 9; Nom: 'Jour de l''Arm‚e'),
  (Pays:'Chili'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Chine';Jour:1;Mois:1;Nom:'Jour de l''An'),
  (Pays:'Chine';Jour:1;Mois:5;Nom:'Fˆte du Travail'),
  (Pays:'Chine';Jour:1;Mois:10;Nom:'Fˆte nationale'),

  (Pays:'Chypre'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Chypre'; Jour: 25; Mois: 3; Nom: 'Jour de l''Ind‚pendance grecque'),
  (Pays:'Chypre'; Jour: 1; Mois: 4; Nom: 'Jour de l''EOKA'),
  (Pays:'Chypre'; Jour: 1; Mois: 10; Nom: 'Fˆte de l''Ind‚pendance chypriote'),
  (Pays:'Chypre'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Colombie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Colombie'; Jour: 20; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Colombie'; Jour: 7; Mois: 8; Nom: 'Bataille de Boyac '),
  (Pays:'Colombie'; Jour: 12; Mois: 10; Nom: 'Jour de la Race'),
  (Pays:'Colombie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Comores'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Comores'; Jour: 6; Mois: 7; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Comores'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Comores'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Congo'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Congo'; Jour: 15; Mois: 8; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Congo'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Congo'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Costa Rica'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Costa Rica'; Jour: 11; Mois: 4; Nom: 'Jour de Juan Santamar¡a'),
  (Pays:'Costa Rica'; Jour: 15; Mois: 9; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Costa Rica'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'C“te d''Ivoire'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'C“te d''Ivoire'; Jour: 7; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'C“te d''Ivoire'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'C“te d''Ivoire'; Jour: 15; Mois: 11; Nom: 'Fˆte de la Paix'),
  (Pays:'C“te d''Ivoire'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Croatie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Croatie'; Jour: 30; Mois: 5; Nom: 'Jour de l''tat'),
  (Pays:'Croatie'; Jour: 5; Mois: 8; Nom: 'Jour de la Victoire'),
  (Pays:'Croatie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Cuba'; Jour: 1; Mois: 1; Nom: 'Jour de la Lib‚ration'),
  (Pays:'Cuba'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Cuba'; Jour: 26; Mois: 7; Nom: 'Jour de la R‚volution'),
  (Pays:'Cuba'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Danemark'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Danemark'; Jour: 5; Mois: 6; Nom: 'Jour de la Constitution'),
  (Pays:'Danemark'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Djibouti'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Djibouti'; Jour: 27; Mois: 6; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Djibouti'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Djibouti'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Dominique'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Dominique'; Jour: 3; Mois: 11; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Dominique'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Dominique'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'gypte'; Jour: 7; Mois: 1; Nom: 'No‰l Copte'),
  (Pays:'gypte'; Jour: 25; Mois: 4; Nom: 'Fˆte de la Lib‚ration du Sina‹'),
  (Pays:'gypte'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'gypte'; Jour: 23; Mois: 7; Nom: 'Jour de la R‚volution'),
  (Pays:'gypte'; Jour: 6; Mois: 10; Nom: 'Jour des Forces Arm‚es'),

  (Pays:'mirats Arabes Unis'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'mirats Arabes Unis'; Jour: 2; Mois: 12; Nom: 'Fˆte Nationale'),
  (Pays:'mirats Arabes Unis'; Jour: 30; Mois: 11; Nom: 'Jour de la Comm‚moration'),
  (Pays:'mirats Arabes Unis'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),

  (Pays:'quateur'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'quateur'; Jour: 24; Mois: 5; Nom: 'Bataille de Pichincha'),
  (Pays:'quateur'; Jour: 10; Mois: 8; Nom: 'Premier Cri de l''Ind‚pendance'),
  (Pays:'quateur'; Jour: 9; Mois: 10; Nom: 'Ind‚pendance de Guayaquil'),
  (Pays:'quateur'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'rythr‚e'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'rythr‚e'; Jour: 24; Mois: 5; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'rythr‚e'; Jour: 1; Mois: 9; Nom: 'Jour des Martyrs'),
  (Pays:'rythr‚e'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Espagne'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Espagne'; Jour: 6; Mois: 1; Nom: 'piphanie'),
  (Pays:'Espagne'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Espagne'; Jour: 12; Mois: 10; Nom: 'Fˆte nationale'),
  (Pays:'Espagne'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Estonie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Estonie'; Jour: 24; Mois: 2; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Estonie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Estonie'; Jour: 20; Mois: 8; Nom: 'Jour du R‚tablissement de l''Ind‚pendance'),
  (Pays:'Estonie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'tats-Unis'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'tats-Unis'; Jour: 4; Mois: 7; Nom: 'Independence Day'),
  (Pays:'tats-Unis'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'thiopie'; Jour: 7; Mois: 1; Nom: 'No‰l ‚thiopien (Genna)'),
  (Pays:'thiopie'; Jour: 2; Mois: 3; Nom: 'Victoire d''Adoua'),
  (Pays:'thiopie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'thiopie'; Jour: 11; Mois: 9; Nom: 'Nouvel An ‚thiopien (Enkutatash)'),
  (Pays:'thiopie'; Jour: 27; Mois: 9; Nom: 'Fˆte de la Croix (Meskel)'),

  (Pays:'Finlande'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Finlande'; Jour: 1; Mois: 5; Nom: 'Vappu (Fˆte du Travail)'),
  (Pays:'Finlande'; Jour: 6; Mois: 12; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Finlande'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'Finlande'; Jour: 26; Mois: 12; Nom: 'DeuxiŠme jour de No‰l'),

  (Pays:'France'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'France'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'France'; Jour: 14; Mois: 7; Nom: 'Fˆte nationale'),
  (Pays:'France'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Gabon'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Gabon'; Jour: 17; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Gabon'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Gabon'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Gambie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Gambie'; Jour: 18; Mois: 2; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Gambie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Gambie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'G‚orgie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'G‚orgie'; Jour: 26; Mois: 5; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'G‚orgie'; Jour: 28; Mois: 8; Nom: 'Jour de la Vierge Marie'),
  (Pays:'G‚orgie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Ghana'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Ghana'; Jour: 6; Mois: 3; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Ghana'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Ghana'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Gibraltar'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Gibraltar'; Jour: 10; Mois: 9; Nom: 'Fˆte Nationale'),
  (Pays:'Gibraltar'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'GrŠce'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'GrŠce'; Jour: 25; Mois: 3; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'GrŠce'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'GrŠce'; Jour: 15; Mois: 8; Nom: 'Assomption'),
  (Pays:'GrŠce'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Grenade'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Grenade'; Jour: 7; Mois: 2; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Grenade'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Groenland'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Groenland'; Jour: 21; Mois: 6; Nom: 'Fˆte Nationale'),
  (Pays:'Groenland'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Guadeloupe'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Guadeloupe'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Guadeloupe'; Jour: 27; Mois: 5; Nom: 'Abolition de l''esclavage'),
  (Pays:'Guadeloupe'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Guam'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Guam'; Jour: 21; Mois: 7; Nom: 'Jour de la Lib‚ration'),
  (Pays:'Guam'; Jour: 11; Mois: 11; Nom: 'Jour des V‚t‚rans'),
  (Pays:'Guam'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Guatemala'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Guatemala'; Jour: 15; Mois: 9; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Guatemala'; Jour: 20; Mois: 10; Nom: 'Jour de la R‚volution'),
  (Pays:'Guatemala'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Guin‚e'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Guin‚e'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Guin‚e'; Jour: 2; Mois: 10; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Guin‚e'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Guyane'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Guyane'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Guyane'; Jour: 10; Mois: 6; Nom: 'Abolition de l''esclavage'),
  (Pays:'Guyane'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Ha‹ti'; Jour: 1; Mois: 1; Nom: 'Jour de l''An et Ind‚pendance'),
  (Pays:'Ha‹ti'; Jour: 18; Mois: 5; Nom: 'Jour du Drapeau'),
  (Pays:'Ha‹ti'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Ha‹ti'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Honduras'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Honduras'; Jour: 15; Mois: 9; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Honduras'; Jour: 3; Mois: 10; Nom: 'Jour de Francisco Moraz n'),
  (Pays:'Honduras'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Hongrie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Hongrie'; Jour: 15; Mois: 3; Nom: 'Jour de la R‚volution de 1848'),
  (Pays:'Hongrie'; Jour: 20; Mois: 8; Nom: 'Fˆte nationale'),
  (Pays:'Hongrie'; Jour: 23; Mois: 10; Nom: 'Jour de la R‚volution de 1956'),

  (Pays:'Inde'; Jour: 26; Mois: 1; Nom:'Jour de la R‚publique'),
  (Pays:'Inde'; Jour: 15; Mois: 8; Nom:'Jour de l''Ind‚pendance'),
  (Pays:'Inde'; Jour: 2; Mois: 10; Nom:'Anniversaire de Gandhi'),
  (Pays:'Inde'; Jour: 25; Mois: 12; Nom:'No‰l'),
  (Pays:'Inde'; Jour: 14; Mois: 11; Nom:'Journ‚e des enfants'),

  (Pays:'Indon‚sie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Indon‚sie'; Jour: 17; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Indon‚sie'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'Indon‚sie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),

  (Pays:'Irak'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Irak'; Jour: 6; Mois: 1; Nom: 'Journ‚e de l''Arm‚e'),
  (Pays:'Irak'; Jour: 9; Mois: 4; Nom: 'Jour de la Lib‚ration'),
  (Pays:'Irak'; Jour: 14; Mois: 7; Nom: 'Jour de la R‚publique'),
  (Pays:'Irak'; Jour: 3; Mois: 10; Nom: 'Jour de l''Ind‚pendance'),

  (Pays:'Iran'; Jour: 1; Mois: 1; Nom: 'Jour de l''An chr‚tien'),
  (Pays:'Iran'; Jour: 20; Mois: 3; Nom: 'Nouvel An persan (Nowruz)'),
  (Pays:'Iran'; Jour: 4; Mois: 6; Nom: 'Anniversaire de Khomeini'),
  (Pays:'Iran'; Jour: 9; Mois: 7; Nom: 'Journ‚e de la R‚publique islamique'),
  (Pays:'Iran'; Jour: 22; Mois: 9; Nom: 'Jour de la D‚fense sacr‚e'),

  (Pays:'Irlande'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Irlande'; Jour: 17; Mois: 3; Nom: 'Fˆte de la Saint-Patrick'),
  (Pays:'Irlande'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),

  (Pays:'Islande'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Islande'; Jour: 17; Mois: 6; Nom: 'Fˆte nationale'),
  (Pays:'Islande'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Islande'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Isra‰l'; Jour: 14; Mois: 5; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Isra‰l'; Jour: 9; Mois: 4; Nom: 'Yom HaShoah'),
  (Pays:'Isra‰l'; Jour: 28; Mois: 4; Nom: 'Yom HaZikaron'),
  (Pays:'Isra‰l'; Jour: 25; Mois: 9; Nom: 'Yom Kippour'),

  (Pays:'Italie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Italie'; Jour: 25; Mois: 4; Nom: 'Fˆte de la Lib‚ration'),
  (Pays:'Italie'; Jour: 15; Mois: 8; Nom: 'Assomption'),
  (Pays:'Italie'; Jour: 1; Mois: 11; Nom: 'Toussaint'),
  (Pays:'Italie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Jama‹que'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Jama‹que'; Jour: 6; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Jama‹que'; Jour: 19; Mois: 10; Nom: 'Jour des H‚ros Nationaux'),
  (Pays:'Jama‹que'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Japon'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Japon'; Jour: 11; Mois: 2; Nom: 'Fˆte de la Fondation du Japon'),
  (Pays:'Japon'; Jour: 29; Mois: 4; Nom: 'Jour de Showa'),
  (Pays:'Japon'; Jour: 3; Mois: 5; Nom: 'Jour de la Constitution'),
  (Pays:'Japon'; Jour: 23; Mois: 12; Nom: 'Anniversaire de l''Empereur'),

  (Pays:'Jordanie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Jordanie'; Jour: 25; Mois: 5; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Jordanie'; Jour: 14; Mois: 11; Nom: 'Anniversaire du Roi Hussein'),
  (Pays:'Jordanie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Kazakhstan'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Kazakhstan'; Jour: 8; Mois: 3; Nom: 'Journ‚e Internationale des Femmes'),
  (Pays:'Kazakhstan'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Kazakhstan'; Jour: 16; Mois: 12; Nom: 'Ind‚pendance'),
  (Pays:'Kazakhstan'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Kenya'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Kenya'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Kenya'; Jour: 12; Mois: 12; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Kenya'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'Kenya'; Jour: 26; Mois: 12; Nom: 'Boxing Day'),

  (Pays:'Kirghizistan'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Kirghizistan'; Jour: 23; Mois: 3; Nom: 'Jour de la R‚publique'),
  (Pays:'Kirghizistan'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Kirghizistan'; Jour: 31; Mois: 8; Nom: 'Ind‚pendance'),
  (Pays:'Kirghizistan'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Kiribati'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Kiribati'; Jour: 12; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Kiribati'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Kowe‹t'; Jour: 25; Mois: 2; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Kowe‹t'; Jour: 19; Mois: 3; Nom: 'Jour de l''mir'),
  (Pays:'Kowe‹t'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Kowe‹t'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Laos'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Laos'; Jour: 13; Mois: 4; Nom: 'Nouvel An Lao'),
  (Pays:'Laos'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Laos'; Jour: 2; Mois: 12; Nom: 'R‚publique du Laos'),
  (Pays:'Laos'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Lesotho'; Jour: 4; Mois: 10; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Lesotho'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Lesotho'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'Lesotho'; Jour: 26; Mois: 12; Nom: 'Boxing Day'),

  (Pays:'Lettonie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Lettonie'; Jour: 4; Mois: 5; Nom: 'Fˆte nationale'),
  (Pays:'Lettonie'; Jour: 18; Mois: 11; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Lettonie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Lib‚ria'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Lib‚ria'; Jour: 26; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Lib‚ria'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Liechtenstein'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Liechtenstein'; Jour: 15; Mois: 8; Nom: 'Assomption'),
  (Pays:'Liechtenstein'; Jour: 15; Mois: 11; Nom: 'Jour de la Fˆte Nationale'),
  (Pays:'Liechtenstein'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Lituanie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Lituanie'; Jour: 6; Mois: 7; Nom: 'Jour de l''tat'),
  (Pays:'Lituanie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Lituanie'; Jour: 15; Mois: 8; Nom: 'Assomption'),
  (Pays:'Lituanie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Luxembourg'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Luxembourg'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Luxembourg'; Jour: 23; Mois: 6; Nom: 'Fˆte Nationale'),
  (Pays:'Luxembourg'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Macao'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Macao'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Macao'; Jour: 1; Mois: 10; Nom: 'Fˆte nationale'),
  (Pays:'Macao'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Mac‚doine'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Mac‚doine'; Jour: 24; Mois: 5; Nom: 'Jour de Saint Cyrille et M‚thode'),
  (Pays:'Mac‚doine'; Jour: 2; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Mac‚doine'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Madagascar'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Madagascar'; Jour: 26; Mois: 6; Nom: 'Ind‚pendance'),
  (Pays:'Madagascar'; Jour: 15; Mois: 8; Nom: 'Assomption'),
  (Pays:'Madagascar'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Malaisie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Malaisie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Malaisie'; Jour: 31; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Malaisie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Malawi'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Malawi'; Jour: 6; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Malawi'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Maldives'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Maldives'; Jour: 26; Mois: 7; Nom: 'Ind‚pendance'),
  (Pays:'Maldives'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Mali'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Mali'; Jour: 20; Mois: 1; Nom: 'R‚volution'),
  (Pays:'Mali'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Mali'; Jour: 22; Mois: 9; Nom: 'Ind‚pendance'),
  (Pays:'Mali'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Malte'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Malte'; Jour: 19; Mois: 3; Nom: 'Saint-Joseph'),
  (Pays:'Malte'; Jour: 7; Mois: 6; Nom: 'Fˆte de la R‚publique'),
  (Pays:'Malte'; Jour: 15; Mois: 8; Nom: 'Assomption'),
  (Pays:'Malte'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Maroc'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Maroc'; Jour: 30; Mois: 7; Nom: 'Fˆte du Tr“ne'),
  (Pays:'Maroc'; Jour: 18; Mois: 11; Nom: 'Ind‚pendance'),
  (Pays:'Maroc'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Martinique'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Martinique'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Martinique'; Jour: 14; Mois: 7; Nom: 'Fˆte Nationale'),
  (Pays:'Martinique'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Mauritanie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Mauritanie'; Jour: 28; Mois: 11; Nom: 'Ind‚pendance'),
  (Pays:'Mauritanie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Mexique'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Mexique'; Jour: 5; Mois: 2; Nom: 'Jour de la Constitution'),
  (Pays:'Mexique'; Jour: 16; Mois: 9; Nom: 'Ind‚pendance'),
  (Pays:'Mexique'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Mexique'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Micron‚sie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Micron‚sie'; Jour: 10; Mois: 5; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Micron‚sie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Moldavie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Moldavie'; Jour: 7; Mois: 3; Nom: 'Fˆte de la Femme'),
  (Pays:'Moldavie'; Jour: 9; Mois: 5; Nom: 'Victoire'),
  (Pays:'Moldavie'; Jour: 27; Mois: 8; Nom: 'Ind‚pendance'),
  (Pays:'Moldavie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Monaco'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Monaco'; Jour: 19; Mois: 11; Nom: 'Fˆte nationale'),
  (Pays:'Monaco'; Jour: 8; Mois: 12; Nom: 'Immacul‚e Conception'),
  (Pays:'Monaco'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'Monaco'; Jour: 27; Mois: 1; Nom: 'Sainte D‚vote'),

  (Pays:'Mongolie'; Jour: 1; Mois: 1; Nom: 'Nouvel An'),
  (Pays:'Mongolie'; Jour: 3; Mois: 3; Nom: 'Fˆte des femmes mongoles'),
  (Pays:'Mongolie'; Jour: 1; Mois: 6; Nom: 'Journ‚e de l''enfant'),
  (Pays:'Mongolie'; Jour: 11; Mois: 7; Nom: 'Naadam'),
  (Pays:'Mongolie'; Jour: 26; Mois: 12; Nom: 'Jour de l''Ind‚pendance'),

  (Pays:'Montserrat'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Montserrat'; Jour: 17; Mois: 3; Nom: 'Saint-Patrick'),
  (Pays:'Montserrat'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Montserrat'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Mozambique'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Mozambique'; Jour: 7; Mois: 9; Nom: 'Ind‚pendance'),
  (Pays:'Mozambique'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Myanmar'; Jour: 4; Mois: 1; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Myanmar'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Myanmar'; Jour: 15; Mois: 8; Nom: 'Fˆte de l''Assomption'),
  (Pays:'Myanmar'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Namibie'; Jour: 21; Mois: 3; Nom: 'Journ‚e de l''Ind‚pendance'),
  (Pays:'Namibie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Namibie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Nauru'; Jour: 31; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Nauru'; Jour: 26; Mois: 10; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Nauru'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'N‚pal'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'N‚pal'; Jour: 29; Mois: 5; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'N‚pal'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Nicaragua'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Nicaragua'; Jour: 30; Mois: 5; Nom: 'Fˆte de la MŠre'),
  (Pays:'Nicaragua'; Jour: 19; Mois: 7; Nom: 'R‚volution Sandiniste'),
  (Pays:'Nicaragua'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Niger'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Niger'; Jour: 18; Mois: 12; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Niger'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Nig‚ria'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Nig‚ria'; Jour: 15; Mois: 8; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Nig‚ria'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Niue'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Niue'; Jour: 1; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Niue'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'NorvŠge'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'NorvŠge'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'NorvŠge'; Jour: 17; Mois: 5; Nom: 'Fˆte nationale'),
  (Pays:'NorvŠge'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'NorvŠge'; Jour: 26; Mois: 12; Nom: 'DeuxiŠme jour de No‰l'),

  (Pays:'Nouvelle Cal‚donie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Nouvelle Cal‚donie'; Jour: 14; Mois: 7; Nom: 'Fˆte Nationale'),
  (Pays:'Nouvelle Cal‚donie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Nouvelle Z‚lande'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Nouvelle Z‚lande'; Jour: 6; Mois: 2; Nom: 'Jour de Waitangi'),
  (Pays:'Nouvelle Z‚lande'; Jour: 25; Mois: 4; Nom: 'ANZAC Day'),
  (Pays:'Nouvelle Z‚lande'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Oman'; Jour: 18; Mois: 11; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Oman'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Oman'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Ouzb‚kistan'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Ouzb‚kistan'; Jour: 1; Mois: 9; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Ouzb‚kistan'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Pakistan'; Jour: 14; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Pakistan'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Pakistan'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Palau'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Palau'; Jour: 7; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Palau'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Panama'; Jour: 3; Mois: 11; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Panama'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Panama'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Paraguay'; Jour: 14; Mois: 5; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Paraguay'; Jour: 15; Mois: 8; Nom: 'Fˆte nationale'),
  (Pays:'Paraguay'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Pays-Bas'; Jour: 27; Mois: 4; Nom: 'Jour du Roi'),
  (Pays:'Pays-Bas'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'P‚rou'; Jour: 28; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'P‚rou'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Philippines'; Jour: 12; Mois: 6; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Philippines'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Philippines'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Pitcairn'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Pitcairn'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Pologne'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Pologne'; Jour: 6; Mois: 1; Nom: 'piphanie'),
  (Pays:'Pologne'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Pologne'; Jour: 15; Mois: 8; Nom: 'Assomption'),
  (Pays:'Pologne'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Polyn‚sie fran‡aise'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Polyn‚sie fran‡aise'; Jour: 14; Mois: 7; Nom: 'Fˆte Nationale'),
  (Pays:'Polyn‚sie fran‡aise'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Porto Rico'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Porto Rico'; Jour: 4; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Porto Rico'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Portugal'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Portugal'; Jour: 25; Mois: 4; Nom: 'R‚volution des oillets'),
  (Pays:'Portugal'; Jour: 15; Mois: 8; Nom: 'Assomption'),
  (Pays:'Portugal'; Jour: 1; Mois: 11; Nom: 'Toussaint'),
  (Pays:'Portugal'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Qatar'; Jour: 18; Mois: 12; Nom: 'Jour National'),
  (Pays:'Qatar'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Qatar'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Roumanie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Roumanie'; Jour: 24; Mois: 1; Nom: 'Jour de l''Unit‚ nationale'),
  (Pays:'Roumanie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Roumanie'; Jour: 15; Mois: 8; Nom: 'Assomption'),
  (Pays:'Roumanie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Royaume-Uni'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Royaume-Uni'; Jour: 25; Mois: 12; Nom: 'No‰l'),
  (Pays:'Royaume-Uni'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Royaume-Uni'; Jour: 1; Mois: 8; Nom: 'Fˆte de la Victoire'),
  (Pays:'Royaume-Uni'; Jour: 31; Mois: 8; Nom: 'Fˆte du Premier Lundi d''Ao–t'),

  (Pays:'Russie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Russie'; Jour: 23; Mois: 2; Nom: 'Journ‚e des d‚fenseurs de la patrie'),
  (Pays:'Russie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Russie'; Jour: 9; Mois: 5; Nom: 'Jour de la Victoire'),
  (Pays:'Russie'; Jour: 12; Mois: 6; Nom: 'Jour de la Russie'),
  (Pays:'Russie'; Jour: 4; Mois: 11; Nom: 'Jour de l''Unit‚ nationale'),

  (Pays:'Rwanda'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Rwanda'; Jour: 4; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Rwanda'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Saint-Marin'; Jour: 3; Mois: 9; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Saint-Marin'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Salvador'; Jour: 7; Mois: 9; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Salvador'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'S‚n‚gal'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'S‚n‚gal'; Jour: 4; Mois: 4; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'S‚n‚gal'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Seychelles'; Jour: 18; Mois: 6; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Seychelles'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Sierra Leone'; Jour: 27; Mois: 4; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Sierra Leone'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Singapour'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Singapour'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Singapour'; Jour: 9; Mois: 8; Nom: 'Jour National'),
  (Pays:'Singapour'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Slovaquie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Slovaquie'; Jour: 5; Mois: 7; Nom: 'Jour de la Constitution'),
  (Pays:'Slovaquie'; Jour: 15; Mois: 9; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Slovaquie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Slov‚nie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Slov‚nie'; Jour: 25; Mois: 6; Nom: 'Jour d''tat'),
  (Pays:'Slov‚nie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Somalie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Somalie'; Jour: 1; Mois: 7; Nom: 'Jour de l''Ind‚pendance'),

  (Pays:'Soudan'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Soudan'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Soudan'; Jour: 1; Mois: 9; Nom: 'Jour de l''Ind‚pendance'),

  (Pays:'Sri Lanka'; Jour: 14; Mois: 4; Nom: 'Nouvel An Sri Lankais'),
  (Pays:'Sri Lanka'; Jour: 15; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Sri Lanka'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'SuŠde'; Jour: 1; Mois: 1; Nom:'Jour de l''An'),
  (Pays:'SuŠde'; Jour: 1; Mois: 5; Nom:'Fˆte du Travail'),
  (Pays:'SuŠde'; Jour: 6; Mois: 6; Nom:'Fˆte nationale'),
  (Pays:'SuŠde'; Jour: 24; Mois: 12; Nom:'Veille de No‰l'),
  (Pays:'SuŠde'; Jour: 25; Mois: 12; Nom:'No‰l'),

  (Pays:'Suisse'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Suisse'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Suisse'; Jour: 1; Mois: 8; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Suisse'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Suriname'; Jour: 25; Mois: 11; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Suriname'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Suriname'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),

  (Pays:'Svalbard'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Svalbard'; Jour: 17; Mois: 5; Nom: 'Fˆte Nationale'),
  (Pays:'Svalbard'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Swaziland'; Jour: 25; Mois: 4; Nom: 'Fˆte du Travail'),
  (Pays:'Swaziland'; Jour: 19; Mois: 4; Nom: 'Jour de la Proclamation'),
  (Pays:'Swaziland'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Taiwan'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Taiwan'; Jour: 10; Mois: 10; Nom: 'Jour National'),
  (Pays:'Taiwan'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Tajikistan'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Tajikistan'; Jour: 9; Mois: 9; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Tajikistan'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Tanzanie'; Jour: 26; Mois: 4; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Tanzanie'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Tanzanie'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Tchad'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Tchad'; Jour: 11; Mois: 8; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Tchad'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Tha‹lande'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Tha‹lande'; Jour: 13; Mois: 4; Nom: 'Songkran'),
  (Pays:'Tha‹lande'; Jour: 5; Mois: 5; Nom: 'Jour de la Fˆte du Roi'),
  (Pays:'Tha‹lande'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Togo'; Jour: 27; Mois: 4; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Togo'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Togo'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Tonga'; Jour: 4; Mois: 6; Nom: 'Fˆte du Roi'),
  (Pays:'Tonga'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Tonga'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Trinit‚-et-Tobago'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Trinit‚-et-Tobago'; Jour: 30; Mois: 5; Nom: 'Jour de la Fˆte du Travail'),
  (Pays:'Trinit‚-et-Tobago'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Tunisie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Tunisie'; Jour: 20; Mois: 3; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Tunisie'; Jour: 9; Mois: 4; Nom: 'Fˆte des Martyrs'),
  (Pays:'Tunisie'; Jour: 25; Mois: 7; Nom: 'Fˆte de la R‚publique'),

  (Pays:'Turkm‚nistan'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Turkm‚nistan'; Jour: 27; Mois: 10; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Turkm‚nistan'; Jour: 12; Mois: 5; Nom: 'Fˆte du Printemps'),
  (Pays:'Turkm‚nistan'; Jour: 21; Mois: 3; Nom: 'Nouvel An persan'),

  (Pays:'Turquie'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Turquie'; Jour: 23; Mois: 4; Nom: 'Jour de la Souverainet‚ Nationale et de l''Enfant'),
  (Pays:'Turquie'; Jour: 19; Mois: 5; Nom: 'Jour de la Com‚moration de Atatrk et des Jeunes'),
  (Pays:'Turquie'; Jour: 30; Mois: 8; Nom: 'Jour de la Victoire'),
  (Pays:'Turquie'; Jour: 29; Mois: 10; Nom: 'Jour de la R‚publique'),

  (Pays:'Tuvalu'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Tuvalu'; Jour: 1; Mois: 10; Nom: 'Fˆte Nationale'),

  (Pays:'Uganda'; Jour: 9; Mois: 10; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Uganda'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Uganda'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Ukraine'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Ukraine'; Jour: 8; Mois: 3; Nom: 'Journ‚e internationale des droits des femmes'),
  (Pays:'Ukraine'; Jour: 1; Mois: 5; Nom: 'Fˆte du Travail'),
  (Pays:'Ukraine'; Jour: 24; Mois: 8; Nom: 'Ind‚pendance de l''Ukraine'),
  (Pays:'Ukraine'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Uruguay'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Uruguay'; Jour: 18; Mois: 5; Nom: 'Jour de la Constitution'),
  (Pays:'Uruguay'; Jour: 25; Mois: 8; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Uruguay'; Jour: 2; Mois: 11; Nom: 'Jour des Morts'),

  (Pays:'Vanuatu'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Vanuatu'; Jour: 30; Mois: 7; Nom: 'Fˆte Nationale'),
  (Pays:'Vanuatu'; Jour: 25; Mois: 12; Nom: 'No‰l'),

  (Pays:'Venezuela'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Venezuela'; Jour: 19; Mois: 4; Nom: 'Jour de l''Ind‚pendance'),
  (Pays:'Venezuela'; Jour: 24; Mois: 6; Nom: 'Fˆte de la Bataille de Carabobo'),
  (Pays:'Venezuela'; Jour: 12; Mois: 10; Nom: 'Jour de la R‚sistance indigŠne'),

  (Pays:'Vietnam'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Vietnam'; Jour: 30; Mois: 4; Nom: 'Jour de la Lib‚ration de Sa‹gon'),
  (Pays:'Vietnam'; Jour: 2; Mois: 9; Nom: 'Fˆte de l''Ind‚pendance'),
  (Pays:'Vietnam'; Jour: 10; Mois: 3; Nom: 'Fˆte des Martyrs et des Ancˆtres'),

  (Pays:'Wallis et Futuna'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Wallis et Futuna'; Jour: 29; Mois: 6; Nom: 'Fˆte de l''Ind‚pendance'),

  (Pays:'Western Sahara'; Jour: 28; Mois: 2; Nom: 'Fˆte de la R‚publique Arabe Sahraouie D‚mocratique'),

  (Pays:'Y‚men'; Jour: 1; Mois: 1; Nom: 'Jour de l''An'),
  (Pays:'Y‚men'; Jour: 22; Mois: 5; Nom: 'Jour de l''Unit‚'),

  (Pays:'Yougoslavie'; Jour: 29; Mois: 11; Nom: 'Jour de la R‚volution'),

  (Pays:'Za‹re'; Jour: 30; Mois: 6; Nom: 'Jour de l''Ind‚pendance'),

  (Pays:'Zambie'; Jour: 24; Mois: 10; Nom: 'Jour de l''Ind‚pendance'),

  (Pays:'Zimbabwe'; Jour: 18; Mois: 4; Nom: 'Jour de l''Ind‚pendance')
 );

Var
 I:Integer;

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

Procedure AfficherJoursFeries(Pays:String);
Const
 Mois:Array[1..12] of String[10]=(
  'janvier','f‚vrier','mars','avril','mai','juin','juillet',
  'ao–t','septembre','octobre','novembre','d‚cembre'
  );
Var
 i:Integer;
Begin
 WriteLn('Jour f‚ri‚(s) pour ', Pays, ' :');
 For i:=1 to 15 do Begin
  If StrToUpper(JoursFeries[i].Pays)=StrToUpper(Pays)Then Begin
   Write(JoursFeries[i].Jour);
   If JoursFeries[i].Jour=1 Then Write('er');
   WriteLn(' ', Mois[JoursFeries[i].Mois], ' - ', JoursFeries[i].Nom);
  End;
 End;
End;

BEGIN
  If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('HOLIDAY : Cette commande permet de retourner la liste ',
                    'des jours f‚ri‚s pour le pays sp‚cifi‚.');
  WriteLn;
  WriteLn('Syntaxe : HOLIDAY pays');
 End
  Else
 If ParamCount>0Then Begin
  For I:=1 to ParamCount do Begin
   AfficherJoursFeries(ParamStr(I));
  End;
 End;
END.