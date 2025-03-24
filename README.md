# GEO-COMMANDER
GEO Commander - Ensemble de commande ecrit en Pascal d'aide à la géographie.

![image](https://user-images.githubusercontent.com/11842176/171527776-3fb9d57b-57e4-4c16-8e4d-32694a13d419.png)

<h2>Liste des fichiers</h3>

Voici la liste des différents fichiers proposés dans GEO Commander :

<table>
  <tr>
    <th>Nom</th>
    <th>Description</th>
  </tr>
  <tr>
      <td><b>CAPITAL.PAS</b></td>
      <td>Cette commande permet de retourner la capitale d'un pays.</td>
  </tr>
  <tr>
      <td><b>CONTINEN.PAS</b></td>
      <td>Cette commande permet de retourner le continent d'un pays.</td>
  </tr>
  <tr>
      <td><b>COUNTRY.PAS</b></td>
      <td>Cette commande permet de retourner les informations d'un pays.</td>
  </tr>
  <tr>
      <td><b>CSV2GEO.PAS</b></td>
      <td>Cette commande permet de convertir un fichier CSV contenant des coordonnées géographiques en format «.geojson».</td>
 </tr>
  <tr>
      <td><b>DOMAIN.PAS</b></td>
      <td>Cette commande permet de retourner l'extension d'un nom de domaine d'un pays.</td>
  </tr>
  <tr>
      <td><b>FINDCITY.PAS</b></td>
      <td>Cette commande permet de detecter les villes mentionnées dans un texte.</td>
  </tr>
  <tr>
      <td><b>FINDCTRY.PAS</b></td>
    <td>Cette commande permet de detecter les pays mentionnées dans un texte.</td>
  </tr>
  <tr>
      <td><b>GEODELTA.PAS</b></td>
      <td>Cette commande permet de demander la distance entre deux villes, soit par coordonnée géographique, soit par son nom s'il est répertorié.</td>
  </tr>
  <tr>
      <td><b>GEOQUIZ.PAS</b></td>
      <td>Cette commande permet de passer un QUIZ de géographie.</td>  
 </tr> 
<tr>
	<td><b>HOLIDAY.PAS</b></td>
	<td>Cette commande permet dte retourner la liste des jours fériés pour le pays spécifié.</td>
</tr>
  <tr>
      <td><b>KM2MILES.PAS</b></td>
      <td>Cette commande permet de convertir des Km en miles.</td>
  </tr>
  <tr>
      <td><b>MILES2KM.PAS</b></td>
      <td>Cette commande permet de convertir des miles en Km.</td>
  </tr>
  <tr>
	<td><b>MOUNTAIN.PAS</b></td>
	  <td>Cette commande permet de retourner les informations sur la montagne spécifié.</td>
  </tr>
  <tr>
      <td><b>PARIS2G.PAS</b></td>
      <td>Cette commande permet de convertir le méridien de Paris en méridien de Greenwich.</td>
  </tr>
  <tr>
      <td><b>POPUL.PAS</b></td>
      <td>Cette commande permet de demander la population d'un pays.</td>
  </tr>
  <tr>
      <td><b>SIZE.PAS</b></td>
      <td>Cette commande permet de retourner la taille d'un pays en Km<sup>2</sup>.</td>
  </tr>
<tr>
	<td><b>TIMEZONE.PAS</b></td>
	<td>Cette commande permet de retourner le fuseau horaire du pays spécifié.</td>
</tr>
	<tr>
		<td><b>TRIANGLE.PAS</b></td>
		<td>Cette commande permet la triangulation d'une position en utilisant un algorithme de trilatération géographique.</td>
	</tr>
<tr>
	<td><b>URL2CTRY.PAS</b></td>
	<td>Cette commande permet de retourner le nom de d'un pays associé à un URL.</td>
</tr>
  <tr>
      <td><b>WATER.PAS</b></td>
      <td>Cette commande permet de retourner les informations d'une superficie d'eau (océan, mer, lac, golfe, baie,...).</td>
  </tr>
 </table>

<h2>Compilation</h2>
	
Les fichiers Pascal n'ont aucune dépendances, il suffit de télécharger le fichier désiré et de le compiler avec Free Pascal avec la syntaxe de commande  :

<pre><b>fpc</b> <i>LEFICHIER.PAS</i></pre>
	
Sinon, vous pouvez également le compiler avec le Turbo Pascal à l'aide de la syntaxe de commande suivante :	

<pre><b>tpc</b> <i>LEFICHIER.PAS</i></pre>
	
Par exemple, si vous voulez compiler GEODELTA.PAS, vous devrez tapez la commande suivante :

<pre><b>fpc</b> GEODELTA.PAS</pre>

<h2>Licence</h2>
<ul>
 <li>Le code source est publié sous la licence <a href="https://github.com/gladir/GEO-COMMANDER/blob/main/LICENSE">MIT</a>.</li>
 <li>Le paquet original est publié sous la licence <a href="https://github.com/gladir/GEO-COMMANDER/blob/main/LICENSE">MIT</a>.</li>
</ul>
