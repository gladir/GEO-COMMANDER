{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
  @description: Clone minimaliste de la commande qgis_process de QGIS

  Moteur d'expressions (extractbyexpression, calculatrice de champs, sous-ensembles...) :
  operateurs QGIS, CASE, tableaux, dictionnaires, dates et intervalles, expressions
  regulieres, hachages, ~300 fonctions (texte, maths, geometrie, agregats, recouvrements,
  variables @...). Limites : expressions et chaines de 255 caracteres maximum.
  Systemes de coordonnees : EPSG:4326/3857, UTM (WGS84, NAD83, NAD27, ETRS89, ED50),
  Lambert, Albers, LAEA, Mercator, projections polaires, MTM, Gauss-Kruger, Lambert-93,
  British National Grid... ou definition "+proj=..." ; option --ellipsoid (geodesie).
  Formats vectoriels : GeoJSON, Shapefile, GeoPackage,
  CSV (WKT ou colonnes X/Y, URI "file://...?xField=..."), GML, KML et KMZ ;
  sources "chemin|layername=...|subset=..." et noms de couches d'un projet
  .qgs/.qgz (--project_path). Formats rasters : GeoTIFF (lecture Deflate, LZW,
  PackBits, predicteurs, tuiles, multibandes ; ecriture non compressee) et
  ESRI ASCII Grid (.asc). PostGIS n'est pas disponible.

  Note : les algorithmes de couches et de rasters allouent de grands blocs de
  memoire (plus de 64 Ko) : utiliser Free Pascal (mode -Mtp possible) ou un
  Turbo Pascal en mode protege.
}

Program QGIS_PROCESS;

Uses Dos;

Const
 VersionStr='1.1';
 EarthRadius=6371008.8;   { Rayon moyen de la Terre (spherique), en metres }
 MercatorRadius=6378137.0;{ Rayon utilise par EPSG:3857 }
 MaxAlgo=134;
 MaxParam=577;
 MaxOut=161;
 MaxArg=30;
 MaxCells=40000000;

Type
 AlgoRec=Record
  Id:String[38];
  Title:String[43];
  Group:String[24];
  Descr:String[120];
 End;
 ParamRec=Record
  A:Byte;
  Name:String[23];
  Typ:String[18];
  Desc:String[146];
  Def:String[12];    { '' = obligatoire, '*' = facultatif }
 End;
 OutRec=Record
  A:Byte;
  Name:String[16];
  Typ:String[18];
  Desc:String[40];
 End;

Const
 Algos:Array[1..MaxAlgo]of AlgoRec=(
  (Id:'native:calculatedistance';Title:'Distance between two points';
   Group:'Vector analysis';
   Descr:'Computes the great-circle distance between two lon/lat points.'),
  (Id:'native:calculatebearing';Title:'Bearing between two points';
   Group:'Vector analysis';
   Descr:'Computes the initial bearing from point 1 to point 2.'),
  (Id:'native:destinationpoint';Title:'Destination point';
   Group:'Vector analysis';
   Descr:'Computes the point reached from a start point, bearing and distance.'),
  (Id:'native:reprojectpoint';Title:'Reproject point';
   Group:'Vector general';
   Descr:'Converts a point between coordinate reference systems.'),
  (Id:'native:layerextent';Title:'Extract layer extent';
   Group:'Vector general';
   Descr:'Computes the bounding box of the geometries of a GeoJSON file.'),
  (Id:'native:pointsonextent';Title:'Extent center';
   Group:'Vector general';
   Descr:'Computes the center and size of a bounding box.'),
  (Id:'native:buffer';Title:'Buffer';
   Group:'Vector geometry';
   Descr:'Buffers the features by a distance in layer units (round caps/joins).'),
  (Id:'native:centroids';Title:'Centroids';
   Group:'Vector geometry';
   Descr:'Creates a point layer with the centroid of each feature.'),
  (Id:'native:clip';Title:'Clip';
   Group:'Vector overlay';
   Descr:'Clips the features of a layer with the polygons of an overlay layer.'),
  (Id:'native:convexhull';Title:'Convex hull';
   Group:'Vector geometry';
   Descr:'Computes the convex hull of each feature.'),
  (Id:'native:extractbyexpression';Title:'Extract by expression';
   Group:'Vector selection';
   Descr:'Extracts the features for which an expression is true.'),
  (Id:'native:reprojectlayer';Title:'Reproject layer';
   Group:'Vector general';
   Descr:'Reprojects a layer between coordinate reference systems.'),
  (Id:'native:polygonstolines';Title:'Polygons to lines';
   Group:'Vector geometry';
   Descr:'Converts the rings of polygon features to line features.'),
  (Id:'native:pixelstopoints';Title:'Raster pixels to points';
   Group:'Raster analysis';
   Descr:'Creates a point for the center of each valid pixel of an ASCII grid.'),
  (Id:'gdal:cliprasterbyextent';Title:'Clip raster by extent';
   Group:'Raster extraction';
   Descr:'Clips an ASCII grid to an extent (xmin,xmax,ymin,ymax), like gdal_translate -projwin.'),
  (Id:'gdal:warpreproject';Title:'Warp (reproject)';
   Group:'Raster projections';
   Descr:'Reprojects an ASCII grid between coordinate reference systems, like gdalwarp.'),
  (Id:'gdal:nearblack';Title:'Near black';
   Group:'Raster analysis';
   Descr:'Sets to black the near-black pixels connected to the edges of an ASCII grid.'),
  (Id:'gdal:offsetcurve';Title:'Offset lines';
   Group:'Vector geoprocessing';
   Descr:'Offsets lines by a distance in layer units (positive = left, negative = right).'),
  (Id:'gdal:ogrinfo';Title:'Vector information';
   Group:'Vector miscellaneous';
   Descr:'Prints information about a GeoJSON layer (count, extent, CRS, fields).'),
  (Id:'gdal:onesidebuffer';Title:'One side buffer';
   Group:'Vector geoprocessing';
   Descr:'Buffers the lines on one side only, in layer units (round joins).'),
  (Id:'gdal:overviews';Title:'Build overviews (pyramids)';
   Group:'Raster miscellaneous';
   Descr:'Builds reduced-resolution copies of an ASCII grid (OUTPUT.ovrN.asc).'),
  (Id:'gdal:pansharp';Title:'Pansharpening';
   Group:'Raster analysis';
   Descr:'Sharpens spectral ASCII grids with a panchromatic grid (Brovey transform).'),
  (Id:'gdal:polygonize';Title:'Polygonize (raster to vector)';
   Group:'Raster conversion';
   Descr:'Converts regions of equal value of an ASCII grid to polygons.'),
  (Id:'gdal:proximity';Title:'Proximity (raster distance)';
   Group:'Raster analysis';
   Descr:'Computes the distance of each pixel to the nearest target pixel.'),
  (Id:'gdal:rastercalculator';Title:'Raster calculator';
   Group:'Raster miscellaneous';
   Descr:'Evaluates a formula on up to six ASCII grids (variables A to F).'),
  (Id:'gdal:rasterize';Title:'Rasterize (vector to raster)';
   Group:'Raster conversion';
   Descr:'Burns the features of a GeoJSON layer into a new ASCII grid.'),
  (Id:'gdal:rasterize_over';Title:'Rasterize (overwrite with attribute)';
   Group:'Raster conversion';
   Descr:'Burns an attribute of a layer into an existing ASCII grid.'),
  (Id:'gdal:rasterize_over_fixed_value';Title:'Rasterize (overwrite with fixed value)';
   Group:'Raster conversion';
   Descr:'Burns a fixed value of a layer into an existing ASCII grid.'),
  (Id:'gdal:retile';Title:'Retile';
   Group:'Raster miscellaneous';
   Descr:'Splits an ASCII grid into tiles (OUTPUT is a directory).'),
  (Id:'gdal:roughness';Title:'Roughness';
   Group:'Raster analysis';
   Descr:'Computes the largest difference between a pixel and its 3x3 neighbours.'),
  (Id:'gdal:sieve';Title:'Sieve';
   Group:'Raster analysis';
   Descr:'Merges the regions smaller than a threshold into their largest neighbour.'),
  (Id:'gdal:slope';Title:'Slope';
   Group:'Raster analysis';
   Descr:'Computes the slope of a digital elevation model (Horn or Zevenbergen-Thorne).'),
  (Id:'gdal:tileindex';Title:'Tile index';
   Group:'Raster miscellaneous';
   Descr:'Creates a polygon layer with the footprint of each input ASCII grid.'),
  (Id:'gdal:translate';Title:'Translate (convert format)';
   Group:'Raster conversion';
   Descr:'Crops (-projwin), resizes (-outsize), sets nodata and converts the data type.'),
  (Id:'gdal:viewshed';Title:'Viewshed';
   Group:'Raster analysis';
   Descr:'Computes the pixels visible from an observer point (line of sight).'),
  (Id:'native:addautoincrementalfield';Title:'Add autoincremental field';
   Group:'Vector table';
   Descr:'Adds an integer field with an incremental value (per group, optionally sorted).'),
  (Id:'native:addfieldtoattributestable';Title:'Add field to attributes table';
   Group:'Vector table';
   Descr:'Adds an empty (null) field to the attributes table.'),
  (Id:'native:adduniquevalueindexfield';Title:'Add unique value index field';
   Group:'Vector table';
   Descr:'Adds a field with a class index (from 0) for each unique value of a field.'),
  (Id:'native:addxyfields';Title:'Add X/Y fields to layer';
   Group:'Vector table';
   Descr:'Adds the x and y fields of a point layer, in a supported CRS.'),
  (Id:'native:affinetransform';Title:'Affine transform';
   Group:'Vector geometry';
   Descr:'Rotates (CCW, degrees), scales then translates the geometries.'),
  (Id:'native:translategeometry';Title:'Translate';
   Group:'Vector geometry';
   Descr:'Moves the geometries by a vector.'),
  (Id:'native:projectpointcartesian';Title:'Project points (Cartesian)';
   Group:'Vector geometry';
   Descr:'Moves points by a distance along a bearing (clockwise from north).'),
  (Id:'native:rotatefeatures';Title:'Rotate';
   Group:'Vector geometry';
   Descr:'Rotates features clockwise around their centroid or a given anchor point.'),
  (Id:'native:deletecolumn';Title:'Drop field(s)';
   Group:'Vector table';
   Descr:'Removes fields from the attributes table.'),
  (Id:'native:dropgeometries';Title:'Drop geometries';
   Group:'Vector general';
   Descr:'Removes the geometry of the features (null geometry).'),
  (Id:'native:extractbyattribute';Title:'Extract by attribute';
   Group:'Vector selection';
   Descr:'Extracts the features whose field satisfies a condition.'),
  (Id:'native:fieldcalculator';Title:'Field calculator';
   Group:'Vector table';
   Descr:'Creates or updates a field from an expression.'),
  (Id:'native:refactorfields';Title:'Refactor fields';
   Group:'Vector table';
   Descr:'Rebuilds the attributes table from name=expression items separated by semicolons.'),
  (Id:'native:orderbyexpression';Title:'Order by expression';
   Group:'Vector general';
   Descr:'Sorts the features by the value of an expression.'),
  (Id:'native:setlayerencoding';Title:'Set layer encoding';
   Group:'Vector general';
   Descr:'No-op: GeoJSON is always UTF-8. OUTPUT is the input file.'),
  (Id:'native:createspatialindex';Title:'Create spatial index';
   Group:'Vector general';
   Descr:'No-op: GeoJSON files do not use a spatial index. OUTPUT is the input file.'),
  (Id:'native:createattributeindex';Title:'Create attribute index';
   Group:'Vector general';
   Descr:'No-op: GeoJSON files do not use attribute indexes. OUTPUT is the input file.'),
  (Id:'native:assignprojection';Title:'Assign projection';
   Group:'Vector general';
   Descr:'Sets the CRS of a layer (EPSG code or +proj string) without changing the coordinates.'),
  (Id:'native:splitfeaturesbycharacter';Title:'Split features by character';
   Group:'Vector table';
   Descr:'Splits each feature into several features by cutting a text field at a character.'),
  (Id:'native:forcerhr';Title:'Force right-hand-rule';
   Group:'Vector geometry';
   Descr:'Orients polygons: exterior rings clockwise, interior rings counter-clockwise.'),
  (Id:'native:dropmzvalues';Title:'Drop M/Z values';
   Group:'Vector geometry';
   Descr:'Removes the Z values of the geometries (GeoJSON has no M values).'),
  (Id:'native:setzvalue';Title:'Set Z value';
   Group:'Vector geometry';
   Descr:'Sets the Z value of all the vertices.'),
  (Id:'native:filterverticesbyz';Title:'Filter vertices by Z value';
   Group:'Vector geometry';
   Descr:'Removes the vertices whose Z value is outside a range.'),
  (Id:'native:multiparttosingleparts';Title:'Multipart to singleparts';
   Group:'Vector geometry';
   Descr:'Splits multipart features into one feature per part.'),
  (Id:'native:singlepartstomultipart';Title:'Singleparts to multipart';
   Group:'Vector geometry';
   Descr:'Merges the features that share a field value into multipart features.'),
  (Id:'native:collect';Title:'Collect geometries';
   Group:'Vector geometry';
   Descr:'Collects the geometries of features that share field values into multipart features.'),
  (Id:'native:explodelines';Title:'Explode lines';
   Group:'Vector geometry';
   Descr:'Splits lines into their individual segments.'),
  (Id:'native:extractvertices';Title:'Extract vertices';
   Group:'Vector geometry';
   Descr:'Creates a point for each vertex (fields: vertex_index, vertex_part, vertex_part_ring, vertex_pos, distance, angle).'),
  (Id:'native:deleteholes';Title:'Delete holes';
   Group:'Vector geometry';
   Descr:'Removes the holes of polygons (all, or those smaller than MIN_AREA).'),
  (Id:'native:densifygeometries';Title:'Densify by count';
   Group:'Vector geometry';
   Descr:'Adds VERTICES equally spaced vertices on every segment.'),
  (Id:'native:simplifygeometries';Title:'Simplify';
   Group:'Vector geometry';
   Descr:'Simplifies lines and polygons (0 Douglas-Peucker, 1 snap to grid, 2 Visvalingam area).'),
  (Id:'native:smoothgeometry';Title:'Smooth';
   Group:'Vector geometry';
   Descr:'Smooths lines and polygons with Chaikin corner cutting.'),
  (Id:'native:linesubstring';Title:'Line substring';
   Group:'Vector geometry';
   Descr:'Extracts the portion of lines between two distances measured from the start.'),
  (Id:'native:splitlinesbylength';Title:'Split lines by maximum length';
   Group:'Vector geometry';
   Descr:'Splits each line into parts of at most LENGTH.'),
  (Id:'native:pointsalonglines';Title:'Points along geometry';
   Group:'Vector geometry';
   Descr:'Creates points at regular intervals along lines (fields: distance, angle).'),
  (Id:'native:createpointsalonglines';Title:'Create points along lines';
   Group:'Vector geometry';
   Descr:'Creates points at regular intervals along lines (fields: distance, angle).'),
  (Id:'native:transect';Title:'Transect';
   Group:'Vector analysis';
   Descr:'Creates transects perpendicular to the lines at each vertex.'),
  (Id:'native:wedgebuffers';Title:'Create wedge buffers';
   Group:'Vector geometry';
   Descr:'Creates wedge-shaped buffers from points (azimuth, width, radii).'),
  (Id:'native:offsetline';Title:'Offset lines';
   Group:'Vector geometry';
   Descr:'Offsets lines by a distance (positive = left, negative = right).'),
  (Id:'native:arrayoffsetlines';Title:'Array of offset (parallel) lines';
   Group:'Vector geometry';
   Descr:'Creates COUNT offset copies of the lines (fields: instance, offset).'),
  (Id:'native:mergevectorlayers';Title:'Merge vector layers';
   Group:'Vector general';
   Descr:'Merges GeoJSON layers (adds the fields layer and path).'),
  (Id:'native:pointonsurface';Title:'Point on surface';
   Group:'Vector geometry';
   Descr:'Creates a point guaranteed to lie on each feature.'),
  (Id:'native:orientedminimumboundingbox';Title:'Oriented minimum bounding box';
   Group:'Vector geometry';
   Descr:'Minimum area rotated rectangle around each feature (fields: area, angle, width, height).'),
  (Id:'native:roundness';Title:'Roundness';
   Group:'Vector geometry';
   Descr:'Adds the roundness (4 pi area / perimeter^2) of each polygon.'),
  (Id:'native:concavehull';Title:'Concave hull';
   Group:'Vector geometry';
   Descr:'Concave hull of all the vertices of a layer (Delaunay based, ALPHA = edge length ratio).'),
  (Id:'native:fixgeometries';Title:'Fix geometries';
   Group:'Vector geometry';
   Descr:'Repairs invalid polygons (even-odd rule).'),
  (Id:'native:snapgeometries';Title:'Snap geometries to layer';
   Group:'Vector geometry';
   Descr:'Snaps the vertices to the vertices (and segments for behaviors 1 and 3) of a reference layer.'),
  (Id:'native:antimeridiansplit';Title:'Geodesic line split at antimeridian';
   Group:'Vector geometry';
   Descr:'Splits lines at the antimeridian (longitudes -180/180).'),
  (Id:'native:geometrybyexpression';Title:'Geometry by expression';
   Group:'Vector geometry';
   Descr:'Replaces the geometry with the result of a geometry expression, e.g. buffer($geometry,5).'),
  (Id:'native:extractbyextent';Title:'Extract/clip by extent';
   Group:'Vector overlay';
   Descr:'Extracts (or clips to) the features that intersect an extent.'),
  (Id:'native:linestopolygons';Title:'Lines to polygons';
   Group:'Vector geometry';
   Descr:'Converts lines to polygons (first part exterior, other parts rings).'),
  (Id:'native:creategrid';Title:'Create grid';
   Group:'Vector creation';
   Descr:'Creates a grid of points, lines, rectangles, diamonds or hexagons.'),
  (Id:'native:exportaddgeometrycolumns';Title:'Add geometry attributes';
   Group:'Vector table';
   Descr:'Adds xcoord/ycoord, length or area/perimeter (0 layer units, 2 spherical on EPSG:4326).'),
  (Id:'native:taperedbuffer';Title:'Tapered buffers';
   Group:'Vector geometry';
   Descr:'Buffers lines with a radius varying linearly from START_WIDTH to END_WIDTH.'),
  (Id:'native:kmeansclustering';Title:'K-means clustering';
   Group:'Vector analysis';
   Descr:'Clusters the features (centroids) with k-means (deterministic initialisation).'),
  (Id:'native:dbscanclustering';Title:'DBSCAN clustering';
   Group:'Vector analysis';
   Descr:'Density based clustering of the features (centroids).'),
  (Id:'native:nearestneighbouranalysis';Title:'Nearest neighbour analysis';
   Group:'Vector analysis';
   Descr:'Statistics of the nearest neighbour distances of a point layer.'),
  (Id:'native:angletonearest';Title:'Align points to features';
   Group:'Vector analysis';
   Descr:'Adds the azimuth of the nearest line segment of a reference layer.'),
  (Id:'native:shortestline';Title:'Shortest line between features';
   Group:'Vector analysis';
   Descr:'Creates the shortest line from each source feature to its nearest destination feature(s).'),
  (Id:'native:distancebuffer';Title:'Buffer';
   Group:'Vector geometry';
   Descr:'Buffers the features by a distance in layer units (alias of native:buffer).'),
  (Id:'native:intersection';Title:'Intersection';
   Group:'Vector overlay';
   Descr:'Extracts the overlapping portions of the layers, with the attributes of both.'),
  (Id:'native:union';Title:'Union';
   Group:'Vector overlay';
   Descr:'Union of two polygon layers (intersections and the parts of each layer outside the other).'),
  (Id:'native:symmetricaldifference';Title:'Symmetrical difference';
   Group:'Vector overlay';
   Descr:'Parts of each layer that are not covered by the other layer.'),
  (Id:'native:difference';Title:'Difference';
   Group:'Vector overlay';
   Descr:'Removes the parts of the input features covered by the overlay polygons.'),
  (Id:'native:dissolve';Title:'Dissolve';
   Group:'Vector geometry';
   Descr:'Merges the geometries sharing field values (polygons are dissolved).'),
  (Id:'native:aggregate';Title:'Aggregate';
   Group:'Vector geometry';
   Descr:'Groups the features (GROUP_BY expression) and computes aggregates: field:function:name;...'),
  (Id:'native:splitwithlines';Title:'Split with lines';
   Group:'Vector overlay';
   Descr:'Splits the lines or polygons with the lines of another layer.'),
  (Id:'native:polygonize';Title:'Polygonize';
   Group:'Vector geometry';
   Descr:'Creates polygons from a network of lines.'),
  (Id:'native:countpointsinpolygon';Title:'Count points in polygon';
   Group:'Vector analysis';
   Descr:'Counts (or sums a weight of) the points inside each polygon.'),
  (Id:'native:extractbylocation';Title:'Extract by location';
   Group:'Vector selection';
   Descr:'Extracts the features that satisfy a spatial predicate with another layer.'),
  (Id:'native:joinattributesbylocation';Title:'Join attributes by location';
   Group:'Vector general';
   Descr:'Copies the attributes of the features that satisfy a spatial predicate.'),
  (Id:'native:joinbylocationsummary';Title:'Join attributes by location (summary)';
   Group:'Vector general';
   Descr:'Summarizes the attributes of the matching features (count, sum, mean...).'),
  (Id:'native:joinattributestable';Title:'Join attributes by field value';
   Group:'Vector general';
   Descr:'Joins the attributes of a table (GeoJSON or CSV) by a common field.'),
  (Id:'native:lineintersections';Title:'Line intersections';
   Group:'Vector overlay';
   Descr:'Creates points where lines of two layers intersect.'),
  (Id:'native:calculatevectoroverlaps';Title:'Overlap analysis';
   Group:'Vector analysis';
   Descr:'Adds, for each overlay layer, the overlapping area (<layer>_area) and percentage (<layer>_pc).'),
  (Id:'native:sumlinelengths';Title:'Sum line lengths';
   Group:'Vector analysis';
   Descr:'Sums the length (and counts) of the lines inside each polygon.'),
  (Id:'native:createconstantrasterlayer';Title:'Create constant raster layer';
   Group:'Raster tools';
   Descr:'Creates an ASCII grid filled with a constant value.'),
  (Id:'native:alignrasters';Title:'Align rasters';
   Group:'Raster tools';
   Descr:'Resamples ASCII grids onto the grid of a reference raster (OUTPUT is a directory).'),
  (Id:'native:fuzzifyrastergaussianmembership';Title:'Fuzzify raster (gaussian membership)';
   Group:'Raster analysis';
   Descr:'Gaussian fuzzy membership: exp(-spread * (x - midpoint)^2).'),
  (Id:'native:rasterlayerstatistics';Title:'Raster layer statistics';
   Group:'Raster analysis';
   Descr:'Computes statistics of the valid pixels of a raster.'),
  (Id:'native:reclassifybytable';Title:'Reclassify by table';
   Group:'Raster analysis';
   Descr:'Reclassifies the pixels with min,max,value triplets.'),
  (Id:'native:rescaleraster';Title:'Rescale raster';
   Group:'Raster analysis';
   Descr:'Linearly rescales the pixel values to a new range.'),
  (Id:'native:slope';Title:'Slope';
   Group:'Raster terrain analysis';
   Descr:'Computes the slope in degrees of a digital elevation model (Horn).'),
  (Id:'native:zonalstatistics';Title:'Zonal statistics';
   Group:'Raster analysis';
   Descr:'Adds statistics of the raster pixels inside each polygon.'),
  (Id:'native:zonalhistogram';Title:'Zonal histogram';
   Group:'Raster analysis';
   Descr:'Adds the pixel count of each raster value inside each polygon.'),
  (Id:'native:rastercalc';Title:'Raster calculator';
   Group:'Raster analysis';
   Descr:'Raster calculator: layers are referenced as "name@1" (name = file name without extension).'),
  (Id:'native:savefeatures';Title:'Save vector features to file';
   Group:'Vector general';
   Descr:'Saves a layer to a GeoJSON (.geojson, .json) or CSV (WKT column) file.'),
  (Id:'native:atlaslayouttomultiplepdf';Title:'Export atlas layout as PDF (multiple files)';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: print layouts do not exist in this clone'),
  (Id:'native:atlaslayouttoimage';Title:'Export atlas layout as image';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: print layouts do not exist in this clone'),
  (Id:'native:atlaslayouttopdf';Title:'Export atlas layout as PDF (single file)';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: print layouts do not exist in this clone'),
  (Id:'native:categorizeusingstyle';Title:'Create categorized renderer from styles';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: styles and renderers do not exist in this clone'),
  (Id:'native:eliminateselectedpolygons';Title:'Eliminate selected polygons';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: there is no feature selection in this clone'),
  (Id:'native:filterverticesbym';Title:'Filter vertices by M value';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: GeoJSON has no M values'),
  (Id:'native:setmvalue';Title:'Set M value';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: GeoJSON has no M values'),
  (Id:'native:package';Title:'Package layers';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: packaging several layers in one GeoPackage is not available'),
  (Id:'native:writevectortiles_mbtiles';Title:'Write vector tiles (MBTiles)';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: MBTiles/vector tile encoding is not available'),
  (Id:'native:writevectortiles_xyz';Title:'Write vector tiles (XYZ)';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: vector tile encoding is not available'),
  (Id:'native:rasterize';Title:'Convert map to raster';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: needs the map renderer (use gdal:rasterize)'),
  (Id:'native:rasterrank';Title:'Raster rank';
   Group:'Not supported';
   Descr:'NOT SUPPORTED: definition of this algorithm not available')
 );

 Params:Array[1..MaxParam]of ParamRec=(
  (A:1;Name:'X1';Typ:'number';Desc:'Longitude of point 1 (degrees)';Def:''),
  (A:1;Name:'Y1';Typ:'number';Desc:'Latitude of point 1 (degrees)';Def:''),
  (A:1;Name:'X2';Typ:'number';Desc:'Longitude of point 2 (degrees)';Def:''),
  (A:1;Name:'Y2';Typ:'number';Desc:'Latitude of point 2 (degrees)';Def:''),
  (A:2;Name:'X1';Typ:'number';Desc:'Longitude of point 1 (degrees)';Def:''),
  (A:2;Name:'Y1';Typ:'number';Desc:'Latitude of point 1 (degrees)';Def:''),
  (A:2;Name:'X2';Typ:'number';Desc:'Longitude of point 2 (degrees)';Def:''),
  (A:2;Name:'Y2';Typ:'number';Desc:'Latitude of point 2 (degrees)';Def:''),
  (A:3;Name:'X';Typ:'number';Desc:'Longitude of start point (degrees)';Def:''),
  (A:3;Name:'Y';Typ:'number';Desc:'Latitude of start point (degrees)';Def:''),
  (A:3;Name:'BEARING';Typ:'number';Desc:'Bearing, clockwise from north (degrees)';Def:''),
  (A:3;Name:'DISTANCE';Typ:'number';Desc:'Distance (meters)';Def:''),
  (A:4;Name:'X';Typ:'number';Desc:'X coordinate of the point';Def:''),
  (A:4;Name:'Y';Typ:'number';Desc:'Y coordinate of the point';Def:''),
  (A:4;Name:'SOURCE_CRS';Typ:'crs';Desc:'Source CRS (EPSG code or +proj string)';Def:'EPSG:4326'),
  (A:4;Name:'TARGET_CRS';Typ:'crs';Desc:'Target CRS (EPSG code or +proj string)';Def:'EPSG:3857'),
  (A:5;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:6;Name:'XMIN';Typ:'number';Desc:'Minimum X';Def:''),
  (A:6;Name:'YMIN';Typ:'number';Desc:'Minimum Y';Def:''),
  (A:6;Name:'XMAX';Typ:'number';Desc:'Maximum X';Def:''),
  (A:6;Name:'YMAX';Typ:'number';Desc:'Maximum Y';Def:''),
  (A:7;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:7;Name:'DISTANCE';Typ:'number';Desc:'Buffer distance in layer units (negative erodes polygons)';Def:''),
  (A:7;Name:'SEGMENTS';Typ:'number';Desc:'Segments used to approximate a quarter circle';Def:'5'),
  (A:7;Name:'END_CAP_STYLE';Typ:'enum';Desc:'End cap style: 0 round, 1 flat, 2 square';Def:'0'),
  (A:7;Name:'JOIN_STYLE';Typ:'enum';Desc:'Join style: 0 round, 1 miter, 2 bevel';Def:'0'),
  (A:7;Name:'MITER_LIMIT';Typ:'number';Desc:'Miter limit (ratio of the miter length to the distance)';Def:'2'),
  (A:7;Name:'DISSOLVE';Typ:'boolean';Desc:'Dissolve the result into one feature';Def:'false'),
  (A:7;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:8;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:8;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:9;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:9;Name:'OVERLAY';Typ:'vector';Desc:'Overlay polygon GeoJSON file';Def:''),
  (A:9;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:10;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:10;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:11;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:11;Name:'EXPRESSION';Typ:'expression';Desc:'Expression, e.g. "pop" > 1000 AND "name" LIKE ''M%''';Def:''),
  (A:11;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Matching features (GeoJSON file)';Def:''),
  (A:11;Name:'FAIL_OUTPUT';Typ:'vectorDestination';Desc:'Non-matching features (GeoJSON file)';Def:'*'),
  (A:12;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:12;Name:'TARGET_CRS';Typ:'crs';Desc:'Target CRS (EPSG code or +proj string)';Def:''),
  (A:12;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:13;Name:'INPUT';Typ:'vector';Desc:'Input polygon GeoJSON file';Def:''),
  (A:13;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:14;Name:'INPUT_RASTER';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:14;Name:'RASTER_BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:14;Name:'FIELD_NAME';Typ:'string';Desc:'Name of the field holding the pixel value';Def:'VALUE'),
  (A:14;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:15;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:15;Name:'EXTENT';Typ:'extent';Desc:'Clipping extent: xmin,xmax,ymin,ymax [EPSG:code]';Def:''),
  (A:15;Name:'NODATA';Typ:'number';Desc:'Nodata value of the output';Def:'*'),
  (A:15;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:16;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:16;Name:'SOURCE_CRS';Typ:'crs';Desc:'Source CRS (EPSG code or +proj string)';Def:'EPSG:4326'),
  (A:16;Name:'TARGET_CRS';Typ:'crs';Desc:'Target CRS (EPSG code or +proj string)';Def:''),
  (A:16;Name:'RESAMPLING';Typ:'enum';Desc:'0 = nearest neighbour, 1 = bilinear';Def:'0'),
  (A:16;Name:'NODATA';Typ:'number';Desc:'Nodata value of the output';Def:'*'),
  (A:16;Name:'TARGET_RESOLUTION';Typ:'number';Desc:'Output pixel size in target CRS units';Def:'*'),
  (A:16;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:17;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:17;Name:'NEAR';Typ:'number';Desc:'Search tolerance around black (0-255)';Def:'15'),
  (A:17;Name:'WHITE';Typ:'boolean';Desc:'Search for near white instead of near black';Def:'false'),
  (A:17;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:18;Name:'INPUT';Typ:'vector';Desc:'Input line GeoJSON file';Def:''),
  (A:18;Name:'DISTANCE';Typ:'number';Desc:'Offset distance in layer units (positive = left)';Def:'10'),
  (A:18;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:19;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:19;Name:'SUMMARY_ONLY';Typ:'boolean';Desc:'Display the summary only (no feature list)';Def:'true'),
  (A:19;Name:'OUTPUT';Typ:'fileDestination';Desc:'Text file receiving the information';Def:'*'),
  (A:20;Name:'INPUT';Typ:'vector';Desc:'Input line GeoJSON file';Def:''),
  (A:20;Name:'DISTANCE';Typ:'number';Desc:'Buffer distance in layer units';Def:'10'),
  (A:20;Name:'BUFFER_SIDE';Typ:'enum';Desc:'0 = left, 1 = right';Def:'0'),
  (A:20;Name:'SEGMENTS';Typ:'number';Desc:'Segments used to approximate a quarter circle';Def:'5'),
  (A:20;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:21;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:21;Name:'LEVELS';Typ:'string';Desc:'Overview levels separated by spaces';Def:'2 4 8 16'),
  (A:21;Name:'RESAMPLING';Typ:'enum';Desc:'0 = nearest neighbour, 1 = average';Def:'0'),
  (A:21;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Base name of the OUTPUT.ovrN.asc files';Def:''),
  (A:22;Name:'SPECTRAL';Typ:'raster';Desc:'Spectral ASCII grids (1 to 4) separated by ;';Def:''),
  (A:22;Name:'PANCHROMATIC';Typ:'raster';Desc:'Panchromatic ASCII grid (.asc)';Def:''),
  (A:22;Name:'RESAMPLING';Typ:'enum';Desc:'0 = nearest neighbour, 1 = bilinear';Def:'1'),
  (A:22;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output (OUTPUT_n.asc when several bands)';Def:''),
  (A:23;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:23;Name:'BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:23;Name:'FIELD';Typ:'string';Desc:'Name of the field receiving the pixel value';Def:'DN'),
  (A:23;Name:'EIGHT_CONNECTEDNESS';Typ:'boolean';Desc:'Use 8-connectedness instead of 4';Def:'false'),
  (A:23;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:24;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:24;Name:'BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:24;Name:'VALUES';Typ:'string';Desc:'Target pixel values (default: all non-zero)';Def:'*'),
  (A:24;Name:'UNITS';Typ:'enum';Desc:'0 = georeferenced units, 1 = pixels';Def:'0'),
  (A:24;Name:'MAX_DISTANCE';Typ:'number';Desc:'Maximum distance (0 = unlimited)';Def:'0'),
  (A:24;Name:'REPLACE';Typ:'number';Desc:'Value given to the target pixels';Def:'*'),
  (A:24;Name:'NODATA';Typ:'number';Desc:'Nodata value of the output';Def:'0'),
  (A:24;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:25;Name:'INPUT_A';Typ:'raster';Desc:'Input ASCII grid A';Def:''),
  (A:25;Name:'INPUT_B';Typ:'raster';Desc:'Input ASCII grid B';Def:'*'),
  (A:25;Name:'INPUT_C';Typ:'raster';Desc:'Input ASCII grid C';Def:'*'),
  (A:25;Name:'INPUT_D';Typ:'raster';Desc:'Input ASCII grid D';Def:'*'),
  (A:25;Name:'INPUT_E';Typ:'raster';Desc:'Input ASCII grid E';Def:'*'),
  (A:25;Name:'INPUT_F';Typ:'raster';Desc:'Input ASCII grid F';Def:'*'),
  (A:25;Name:'FORMULA';Typ:'string';Desc:'Formula, e.g. (A-B)/(A+B) or sqrt(A**2+B**2)';Def:''),
  (A:25;Name:'NO_DATA';Typ:'number';Desc:'Nodata value of the output';Def:'*'),
  (A:25;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:26;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:26;Name:'FIELD';Typ:'string';Desc:'Numeric attribute to burn (default: BURN)';Def:'*'),
  (A:26;Name:'BURN';Typ:'number';Desc:'Fixed value to burn';Def:'0'),
  (A:26;Name:'UNITS';Typ:'enum';Desc:'0 = pixels, 1 = georeferenced units';Def:'0'),
  (A:26;Name:'WIDTH';Typ:'number';Desc:'Width (pixels) or pixel size (georeferenced units)';Def:'0'),
  (A:26;Name:'HEIGHT';Typ:'number';Desc:'Height (pixels) or pixel size (georeferenced units)';Def:'0'),
  (A:26;Name:'EXTENT';Typ:'extent';Desc:'Output extent: xmin,xmax,ymin,ymax (default: layer)';Def:'*'),
  (A:26;Name:'NODATA';Typ:'number';Desc:'Nodata value / background';Def:'0'),
  (A:26;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:27;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:27;Name:'INPUT_RASTER';Typ:'raster';Desc:'Raster to modify (.asc)';Def:''),
  (A:27;Name:'FIELD';Typ:'string';Desc:'Numeric attribute to burn';Def:''),
  (A:27;Name:'ADD';Typ:'boolean';Desc:'Add the values to the existing pixels';Def:'false'),
  (A:27;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output (default: modifies INPUT_RASTER in place)';Def:'*'),
  (A:28;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:28;Name:'INPUT_RASTER';Typ:'raster';Desc:'Raster to modify (.asc)';Def:''),
  (A:28;Name:'BURN';Typ:'number';Desc:'Value to burn';Def:'255'),
  (A:28;Name:'ADD';Typ:'boolean';Desc:'Add the value to the existing pixels';Def:'false'),
  (A:28;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output (default: modifies INPUT_RASTER in place)';Def:'*'),
  (A:29;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:29;Name:'TILE_SIZE_X';Typ:'number';Desc:'Tile width in pixels';Def:'256'),
  (A:29;Name:'TILE_SIZE_Y';Typ:'number';Desc:'Tile height in pixels';Def:'256'),
  (A:29;Name:'OVERLAP';Typ:'number';Desc:'Overlap between tiles in pixels';Def:'0'),
  (A:29;Name:'OUTPUT';Typ:'folderDestination';Desc:'Output directory';Def:''),
  (A:30;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:30;Name:'BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:30;Name:'COMPUTE_EDGES';Typ:'boolean';Desc:'Compute the values at the raster edges';Def:'false'),
  (A:30;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:31;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:31;Name:'THRESHOLD';Typ:'number';Desc:'Minimum region size in pixels';Def:'10'),
  (A:31;Name:'EIGHT_CONNECTEDNESS';Typ:'boolean';Desc:'Use 8-connectedness instead of 4';Def:'false'),
  (A:31;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:32;Name:'INPUT';Typ:'raster';Desc:'Elevation ASCII grid (.asc)';Def:''),
  (A:32;Name:'BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:32;Name:'SCALE';Typ:'number';Desc:'Ratio of vertical to horizontal units';Def:'1'),
  (A:32;Name:'AS_PERCENT';Typ:'boolean';Desc:'Slope as percent instead of degrees';Def:'false'),
  (A:32;Name:'COMPUTE_EDGES';Typ:'boolean';Desc:'Compute the values at the raster edges';Def:'false'),
  (A:32;Name:'ZEVENBERGEN';Typ:'boolean';Desc:'Use Zevenbergen-Thorne instead of Horn';Def:'false'),
  (A:32;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:33;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grids separated by ;';Def:''),
  (A:33;Name:'FIELD_NAME';Typ:'string';Desc:'Field holding the file name';Def:'location'),
  (A:33;Name:'ABSOLUTE_PATH';Typ:'boolean';Desc:'Store absolute paths';Def:'false'),
  (A:33;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:34;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:34;Name:'NODATA';Typ:'number';Desc:'Nodata value of the output';Def:'*'),
  (A:34;Name:'DATA_TYPE';Typ:'enum';Desc:'0 = input, 1 Byte, 2 Int16, 3 UInt16, 4 UInt32, 5 Int32, 6 Float32, 7 Float64';Def:'0'),
  (A:34;Name:'EXTRA';Typ:'string';Desc:'-projwin ulx uly lrx lry, -outsize w h, -a_nodata v';Def:'*'),
  (A:34;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:35;Name:'INPUT';Typ:'raster';Desc:'Elevation ASCII grid (.asc)';Def:''),
  (A:35;Name:'BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:35;Name:'OBSERVER';Typ:'point';Desc:'Observer position: x,y [EPSG:code]';Def:''),
  (A:35;Name:'OBSERVER_HEIGHT';Typ:'number';Desc:'Height of the observer above the ground';Def:'1'),
  (A:35;Name:'TARGET_HEIGHT';Typ:'number';Desc:'Height of the targets above the ground';Def:'0'),
  (A:35;Name:'MAX_DISTANCE';Typ:'number';Desc:'Maximum visibility distance';Def:'10000'),
  (A:35;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid: 255 visible, 0 hidden';Def:''),
  (A:36;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:36;Name:'FIELD_NAME';Typ:'string';Desc:'Name of the new field';Def:'AUTO'),
  (A:36;Name:'START';Typ:'number';Desc:'Initial value';Def:'0'),
  (A:36;Name:'MODULUS';Typ:'number';Desc:'Modulus (0 = none)';Def:'0'),
  (A:36;Name:'GROUP_FIELDS';Typ:'string';Desc:'Group fields separated by commas';Def:'*'),
  (A:36;Name:'SORT_EXPRESSION';Typ:'expression';Desc:'Sort expression';Def:'*'),
  (A:36;Name:'SORT_ASCENDING';Typ:'boolean';Desc:'Sort ascending';Def:'true'),
  (A:36;Name:'SORT_NULLS_FIRST';Typ:'boolean';Desc:'Nulls first';Def:'false'),
  (A:36;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:37;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:37;Name:'FIELD_NAME';Typ:'string';Desc:'Name of the new field';Def:''),
  (A:37;Name:'FIELD_TYPE';Typ:'enum';Desc:'0 integer, 1 decimal, 2 text, 3 date, 6 boolean';Def:'0'),
  (A:37;Name:'FIELD_LENGTH';Typ:'number';Desc:'Field length';Def:'10'),
  (A:37;Name:'FIELD_PRECISION';Typ:'number';Desc:'Field precision';Def:'0'),
  (A:37;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:38;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:38;Name:'FIELD';Typ:'string';Desc:'Field containing the classes';Def:''),
  (A:38;Name:'FIELD_NAME';Typ:'string';Desc:'Name of the index field';Def:'NUM_FIELD'),
  (A:38;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:38;Name:'SUMMARY_OUTPUT';Typ:'vectorDestination';Desc:'Optional summary table (GeoJSON)';Def:'*'),
  (A:39;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:39;Name:'CRS';Typ:'crs';Desc:'CRS of the coordinates (EPSG code or +proj string)';Def:'EPSG:4326'),
  (A:39;Name:'PREFIX';Typ:'string';Desc:'Field prefix';Def:'*'),
  (A:39;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:40;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:40;Name:'DELTA_X';Typ:'number';Desc:'Translation in X';Def:'0'),
  (A:40;Name:'DELTA_Y';Typ:'number';Desc:'Translation in Y';Def:'0'),
  (A:40;Name:'DELTA_Z';Typ:'number';Desc:'Translation in Z (ignored)';Def:'0'),
  (A:40;Name:'DELTA_M';Typ:'number';Desc:'Translation in M (ignored)';Def:'0'),
  (A:40;Name:'SCALE_X';Typ:'number';Desc:'Scale factor in X';Def:'1'),
  (A:40;Name:'SCALE_Y';Typ:'number';Desc:'Scale factor in Y';Def:'1'),
  (A:40;Name:'SCALE_Z';Typ:'number';Desc:'Scale factor in Z (ignored)';Def:'1'),
  (A:40;Name:'SCALE_M';Typ:'number';Desc:'Scale factor in M (ignored)';Def:'1'),
  (A:40;Name:'ROTATION_Z';Typ:'number';Desc:'Rotation around Z (degrees, counter-clockwise)';Def:'0'),
  (A:40;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:41;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:41;Name:'DELTA_X';Typ:'number';Desc:'Translation in X';Def:'0'),
  (A:41;Name:'DELTA_Y';Typ:'number';Desc:'Translation in Y';Def:'0'),
  (A:41;Name:'DELTA_Z';Typ:'number';Desc:'Translation in Z (ignored)';Def:'0'),
  (A:41;Name:'DELTA_M';Typ:'number';Desc:'Translation in M (ignored)';Def:'0'),
  (A:41;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:42;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:42;Name:'BEARING';Typ:'number';Desc:'Bearing in degrees';Def:''),
  (A:42;Name:'DISTANCE';Typ:'number';Desc:'Distance in layer units';Def:''),
  (A:42;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:43;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:43;Name:'ANGLE';Typ:'number';Desc:'Angle in degrees (clockwise)';Def:'0'),
  (A:43;Name:'ANCHOR';Typ:'point';Desc:'Anchor x,y (default: centroid of each feature)';Def:'*'),
  (A:43;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:44;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:44;Name:'COLUMN';Typ:'string';Desc:'Fields to drop, separated by commas';Def:''),
  (A:44;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:45;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:45;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:46;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:46;Name:'FIELD';Typ:'string';Desc:'Field';Def:''),
  (A:46;Name:'OPERATOR';Typ:'enum';Desc:'0 =, 1 !=, 2 >, 3 >=, 4 <, 5 <=, 6 begins with, 7 contains, 8 is null, 9 is not null, 10 does not contain';Def:'0'),
  (A:46;Name:'VALUE';Typ:'string';Desc:'Value';Def:'*'),
  (A:46;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Matching features';Def:''),
  (A:46;Name:'FAIL_OUTPUT';Typ:'vectorDestination';Desc:'Non-matching features';Def:'*'),
  (A:47;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:47;Name:'FIELD_NAME';Typ:'string';Desc:'Field name';Def:''),
  (A:47;Name:'FIELD_TYPE';Typ:'enum';Desc:'0 decimal, 1 integer, 2 text';Def:'0'),
  (A:47;Name:'FIELD_LENGTH';Typ:'number';Desc:'Field length';Def:'10'),
  (A:47;Name:'FIELD_PRECISION';Typ:'number';Desc:'Field precision';Def:'3'),
  (A:47;Name:'FORMULA';Typ:'expression';Desc:'Expression, e.g. "pop" * 2 or $area';Def:''),
  (A:47;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:48;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:48;Name:'FIELDS_MAPPING';Typ:'string';Desc:'name=expression;name=expression;...';Def:''),
  (A:48;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:49;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:49;Name:'EXPRESSION';Typ:'expression';Desc:'Sort expression';Def:''),
  (A:49;Name:'ASCENDING';Typ:'boolean';Desc:'Sort ascending';Def:'true'),
  (A:49;Name:'NULLS_FIRST';Typ:'boolean';Desc:'Nulls first';Def:'false'),
  (A:49;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:50;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:50;Name:'ENCODING';Typ:'string';Desc:'Encoding (ignored)';Def:'UTF-8'),
  (A:51;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:52;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:52;Name:'FIELD';Typ:'string';Desc:'Field (ignored)';Def:'*'),
  (A:53;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:53;Name:'CRS';Typ:'crs';Desc:'CRS to assign (EPSG code or +proj string)';Def:''),
  (A:53;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:54;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:54;Name:'FIELD';Typ:'string';Desc:'Field to split';Def:''),
  (A:54;Name:'CHAR';Typ:'string';Desc:'Separator character';Def:','),
  (A:54;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:55;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:55;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:56;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:56;Name:'DROP_M_VALUES';Typ:'boolean';Desc:'Drop M values (no effect)';Def:'false'),
  (A:56;Name:'DROP_Z_VALUES';Typ:'boolean';Desc:'Drop Z values';Def:'false'),
  (A:56;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:57;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:57;Name:'Z_VALUE';Typ:'number';Desc:'Z value';Def:'0'),
  (A:57;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:58;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:58;Name:'MIN';Typ:'number';Desc:'Minimum Z';Def:''),
  (A:58;Name:'MAX';Typ:'number';Desc:'Maximum Z';Def:''),
  (A:58;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:59;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:59;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:60;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:60;Name:'FIELD';Typ:'string';Desc:'Unique ID field(s), separated by commas';Def:'*'),
  (A:60;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:61;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:61;Name:'FIELD';Typ:'string';Desc:'Unique ID field(s), separated by commas';Def:'*'),
  (A:61;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:62;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:62;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:63;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:63;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:64;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:64;Name:'MIN_AREA';Typ:'number';Desc:'Remove holes smaller than this area (0 = all)';Def:'0'),
  (A:64;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:65;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:65;Name:'VERTICES';Typ:'number';Desc:'Vertices to add to each segment';Def:'1'),
  (A:65;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:66;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:66;Name:'METHOD';Typ:'enum';Desc:'0 distance, 1 snap to grid, 2 area';Def:'0'),
  (A:66;Name:'TOLERANCE';Typ:'number';Desc:'Tolerance (distance, grid size or area)';Def:'1'),
  (A:66;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:67;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:67;Name:'ITERATIONS';Typ:'number';Desc:'Iterations (1 to 10)';Def:'1'),
  (A:67;Name:'OFFSET';Typ:'number';Desc:'Offset (0 to 0.5)';Def:'0.25'),
  (A:67;Name:'MAX_ANGLE';Typ:'number';Desc:'Maximum node angle to smooth (degrees)';Def:'180'),
  (A:67;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:68;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:68;Name:'START_DISTANCE';Typ:'number';Desc:'Start distance';Def:'0'),
  (A:68;Name:'END_DISTANCE';Typ:'number';Desc:'End distance';Def:''),
  (A:68;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:69;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:69;Name:'LENGTH';Typ:'number';Desc:'Maximum length';Def:''),
  (A:69;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:70;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:70;Name:'DISTANCE';Typ:'number';Desc:'Distance between points';Def:''),
  (A:70;Name:'START_OFFSET';Typ:'number';Desc:'Start offset';Def:'0'),
  (A:70;Name:'END_OFFSET';Typ:'number';Desc:'End offset';Def:'0'),
  (A:70;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:71;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:71;Name:'DISTANCE';Typ:'number';Desc:'Distance between points';Def:''),
  (A:71;Name:'START_OFFSET';Typ:'number';Desc:'Start offset';Def:'0'),
  (A:71;Name:'END_OFFSET';Typ:'number';Desc:'End offset';Def:'0'),
  (A:71;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:72;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:72;Name:'LENGTH';Typ:'number';Desc:'Length of the transect (each side)';Def:'5'),
  (A:72;Name:'ANGLE';Typ:'number';Desc:'Angle to the line (degrees)';Def:'90'),
  (A:72;Name:'SIDE';Typ:'enum';Desc:'0 left, 1 right, 2 both';Def:'2'),
  (A:72;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:73;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:73;Name:'AZIMUTH';Typ:'string';Desc:'Azimuth in degrees (number or field name)';Def:'0'),
  (A:73;Name:'WIDTH';Typ:'string';Desc:'Wedge width in degrees (number or field)';Def:'45'),
  (A:73;Name:'OUTER_RADIUS';Typ:'string';Desc:'Outer radius (number or field)';Def:'1'),
  (A:73;Name:'INNER_RADIUS';Typ:'string';Desc:'Inner radius (number or field)';Def:'0'),
  (A:73;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:74;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:74;Name:'DISTANCE';Typ:'number';Desc:'Offset distance';Def:'10'),
  (A:74;Name:'SEGMENTS';Typ:'number';Desc:'Segments per quarter circle';Def:'8'),
  (A:74;Name:'JOIN_STYLE';Typ:'enum';Desc:'Join style: 0 round, 1 miter, 2 bevel';Def:'0'),
  (A:74;Name:'MITER_LIMIT';Typ:'number';Desc:'Miter limit (ratio of the miter length to the distance)';Def:'2'),
  (A:74;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:75;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:75;Name:'COUNT';Typ:'number';Desc:'Number of lines to create';Def:'10'),
  (A:75;Name:'OFFSET';Typ:'number';Desc:'Offset between lines';Def:'1'),
  (A:75;Name:'SEGMENTS';Typ:'number';Desc:'Segments per quarter circle';Def:'8'),
  (A:75;Name:'JOIN_STYLE';Typ:'enum';Desc:'Join style: 0 round, 1 miter, 2 bevel';Def:'0'),
  (A:75;Name:'MITER_LIMIT';Typ:'number';Desc:'Miter limit (ratio of the miter length to the distance)';Def:'2'),
  (A:75;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:76;Name:'LAYERS';Typ:'vector';Desc:'Input GeoJSON files separated by ;';Def:''),
  (A:76;Name:'CRS';Typ:'crs';Desc:'Destination CRS (default: first layer)';Def:'*'),
  (A:76;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:77;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:77;Name:'ALL_PARTS';Typ:'boolean';Desc:'Create a point for each part';Def:'false'),
  (A:77;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:78;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:78;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:79;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:79;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:80;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:80;Name:'ALPHA';Typ:'number';Desc:'Threshold 0 (very concave) to 1 (convex)';Def:'0.3'),
  (A:80;Name:'HOLES';Typ:'boolean';Desc:'Allow holes (no hole is ever created)';Def:'true'),
  (A:80;Name:'NO_MULTIGEOMETRY';Typ:'boolean';Desc:'Avoid multigeometries (unused)';Def:'false'),
  (A:80;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:81;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:81;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:82;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:82;Name:'REFERENCE_LAYER';Typ:'vector';Desc:'Reference GeoJSON file';Def:''),
  (A:82;Name:'TOLERANCE';Typ:'number';Desc:'Snap tolerance';Def:'10'),
  (A:82;Name:'BEHAVIOR';Typ:'enum';Desc:'0 prefer nodes, 1 prefer closest point, 2 nodes only, 3 closest, no extra vertices';Def:'0'),
  (A:82;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:83;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:83;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:84;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:84;Name:'OUTPUT_GEOMETRY';Typ:'enum';Desc:'0 polygon, 1 line, 2 point (unused)';Def:'0'),
  (A:84;Name:'WITH_Z';Typ:'boolean';Desc:'Output has Z (unused)';Def:'false'),
  (A:84;Name:'WITH_M';Typ:'boolean';Desc:'Output has M (unused)';Def:'false'),
  (A:84;Name:'EXPRESSION';Typ:'expression';Desc:'Geometry expression';Def:''),
  (A:84;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:85;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:85;Name:'EXTENT';Typ:'extent';Desc:'Extent xmin,xmax,ymin,ymax';Def:''),
  (A:85;Name:'CLIP';Typ:'boolean';Desc:'Clip the geometries to the extent';Def:'false'),
  (A:85;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:86;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:86;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:87;Name:'TYPE';Typ:'enum';Desc:'0 point, 1 line, 2 rectangle, 3 diamond, 4 hexagon';Def:'2'),
  (A:87;Name:'EXTENT';Typ:'extent';Desc:'Grid extent xmin,xmax,ymin,ymax';Def:''),
  (A:87;Name:'HSPACING';Typ:'number';Desc:'Horizontal spacing (cell width)';Def:'1'),
  (A:87;Name:'VSPACING';Typ:'number';Desc:'Vertical spacing (cell height)';Def:'1'),
  (A:87;Name:'HOVERLAY';Typ:'number';Desc:'Horizontal overlay';Def:'0'),
  (A:87;Name:'VOVERLAY';Typ:'number';Desc:'Vertical overlay';Def:'0'),
  (A:87;Name:'CRS';Typ:'crs';Desc:'CRS of the grid (EPSG code or +proj string)';Def:'EPSG:4326'),
  (A:87;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:88;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:88;Name:'CALC_METHOD';Typ:'enum';Desc:'0 layer CRS, 1 project CRS (layer), 2 ellipsoidal (spherical)';Def:'0'),
  (A:88;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:89;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:89;Name:'START_WIDTH';Typ:'number';Desc:'Radius at the start';Def:'0'),
  (A:89;Name:'END_WIDTH';Typ:'number';Desc:'Radius at the end';Def:'0'),
  (A:89;Name:'SEGMENTS';Typ:'number';Desc:'Segments per quarter circle';Def:'16'),
  (A:89;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:90;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:90;Name:'CLUSTERS';Typ:'number';Desc:'Number of clusters';Def:'5'),
  (A:90;Name:'FIELD_NAME';Typ:'string';Desc:'Cluster field';Def:'CLUSTER_ID'),
  (A:90;Name:'SIZE_FIELD_NAME';Typ:'string';Desc:'Size field';Def:'CLUSTER_SIZE'),
  (A:90;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:91;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:91;Name:'MIN_SIZE';Typ:'number';Desc:'Minimum cluster size';Def:'5'),
  (A:91;Name:'EPS';Typ:'number';Desc:'Maximum distance between clustered points';Def:'1'),
  (A:91;Name:'DBSCAN*';Typ:'boolean';Desc:'Treat border points as noise';Def:'false'),
  (A:91;Name:'FIELD_NAME';Typ:'string';Desc:'Cluster field';Def:'CLUSTER_ID'),
  (A:91;Name:'SIZE_FIELD_NAME';Typ:'string';Desc:'Size field';Def:'CLUSTER_SIZE'),
  (A:91;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:92;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:92;Name:'OUTPUT_HTML_FILE';Typ:'fileDestination';Desc:'Text report file';Def:'*'),
  (A:93;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:93;Name:'REFERENCE_LAYER';Typ:'vector';Desc:'Reference line or polygon GeoJSON file';Def:''),
  (A:93;Name:'MAX_DISTANCE';Typ:'number';Desc:'Maximum distance';Def:'*'),
  (A:93;Name:'FIELD_NAME';Typ:'string';Desc:'Angle field';Def:'ANGLE'),
  (A:93;Name:'APPLY_SYMBOLOGY';Typ:'boolean';Desc:'Rotate the symbols (unused)';Def:'true'),
  (A:93;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:94;Name:'SOURCE';Typ:'vector';Desc:'Source GeoJSON file';Def:''),
  (A:94;Name:'DESTINATION';Typ:'vector';Desc:'Destination GeoJSON file';Def:''),
  (A:94;Name:'METHOD';Typ:'enum';Desc:'0 nearest feature, 1 k nearest';Def:'0'),
  (A:94;Name:'NEIGHBORS';Typ:'number';Desc:'Number of neighbors (method 1)';Def:'1'),
  (A:94;Name:'DISTANCE';Typ:'number';Desc:'Maximum distance';Def:'*'),
  (A:94;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:95;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:95;Name:'DISTANCE';Typ:'number';Desc:'Buffer distance in layer units (negative erodes polygons)';Def:''),
  (A:95;Name:'SEGMENTS';Typ:'number';Desc:'Segments used to approximate a quarter circle';Def:'5'),
  (A:95;Name:'END_CAP_STYLE';Typ:'enum';Desc:'End cap style: 0 round, 1 flat, 2 square';Def:'0'),
  (A:95;Name:'JOIN_STYLE';Typ:'enum';Desc:'Join style: 0 round, 1 miter, 2 bevel';Def:'0'),
  (A:95;Name:'MITER_LIMIT';Typ:'number';Desc:'Miter limit (ratio of the miter length to the distance)';Def:'2'),
  (A:95;Name:'DISSOLVE';Typ:'boolean';Desc:'Dissolve the result into one feature';Def:'false'),
  (A:95;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:96;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:96;Name:'OVERLAY';Typ:'vector';Desc:'Overlay GeoJSON file (polygons)';Def:''),
  (A:96;Name:'INPUT_FIELDS';Typ:'string';Desc:'Input fields to keep (all)';Def:'*'),
  (A:96;Name:'OVERLAY_FIELDS';Typ:'string';Desc:'Overlay fields to keep (all)';Def:'*'),
  (A:96;Name:'OVERLAY_FIELDS_PREFIX';Typ:'string';Desc:'Prefix added to the overlay fields';Def:'*'),
  (A:96;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:97;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:97;Name:'OVERLAY';Typ:'vector';Desc:'Overlay GeoJSON file (polygons)';Def:''),
  (A:97;Name:'OVERLAY_FIELDS_PREFIX';Typ:'string';Desc:'Prefix added to the overlay fields';Def:'*'),
  (A:97;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:98;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:98;Name:'OVERLAY';Typ:'vector';Desc:'Overlay GeoJSON file (polygons)';Def:''),
  (A:98;Name:'OVERLAY_FIELDS_PREFIX';Typ:'string';Desc:'Prefix added to the overlay fields';Def:'*'),
  (A:98;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:99;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:99;Name:'OVERLAY';Typ:'vector';Desc:'Overlay GeoJSON file (polygons)';Def:''),
  (A:99;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:100;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:100;Name:'FIELD';Typ:'string';Desc:'Dissolve field(s), separated by commas';Def:'*'),
  (A:100;Name:'SEPARATE_DISJOINT';Typ:'boolean';Desc:'Keep disjoint parts as separate features';Def:'false'),
  (A:100;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:101;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:101;Name:'GROUP_BY';Typ:'expression';Desc:'Group expression or field (NULL = all)';Def:'NULL'),
  (A:101;Name:'AGGREGATES';Typ:'string';Desc:'field:function:name;... (sum,mean,min,max,count,count_distinct,median,stdev,first_value,last_value,concatenate)';Def:'*'),
  (A:101;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:102;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:102;Name:'LINES';Typ:'vector';Desc:'Splitting lines GeoJSON file';Def:''),
  (A:102;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:103;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:103;Name:'KEEP_FIELDS';Typ:'boolean';Desc:'Keep the line fields (unused)';Def:'false'),
  (A:103;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:104;Name:'POLYGONS';Typ:'vector';Desc:'Polygon GeoJSON file';Def:''),
  (A:104;Name:'POINTS';Typ:'vector';Desc:'Point GeoJSON file';Def:''),
  (A:104;Name:'WEIGHT';Typ:'string';Desc:'Weight field';Def:'*'),
  (A:104;Name:'CLASSFIELD';Typ:'string';Desc:'Class field (distinct values are counted)';Def:'*'),
  (A:104;Name:'FIELD';Typ:'string';Desc:'Count field name';Def:'NUMPOINTS'),
  (A:104;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:105;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:105;Name:'PREDICATE';Typ:'string';Desc:'0 intersect, 1 contain, 2 disjoint, 3 equal, 4 touch, 5 overlap, 6 within, 7 cross (comma list)';Def:'0'),
  (A:105;Name:'INTERSECT';Typ:'vector';Desc:'Comparison GeoJSON file';Def:''),
  (A:105;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:106;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:106;Name:'PREDICATE';Typ:'string';Desc:'0 intersect, 1 contain, 2 disjoint, 3 equal, 4 touch, 5 overlap, 6 within, 7 cross (comma list)';Def:'0'),
  (A:106;Name:'JOIN';Typ:'vector';Desc:'Join GeoJSON file';Def:''),
  (A:106;Name:'JOIN_FIELDS';Typ:'string';Desc:'Fields to copy, separated by commas (all)';Def:'*'),
  (A:106;Name:'METHOD';Typ:'enum';Desc:'0 one-to-many, 1 first match, 2 largest overlap';Def:'0'),
  (A:106;Name:'DISCARD_NONMATCHING';Typ:'boolean';Desc:'Discard the unmatched features';Def:'false'),
  (A:106;Name:'PREFIX';Typ:'string';Desc:'Prefix of the joined fields';Def:'*'),
  (A:106;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:107;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:107;Name:'PREDICATE';Typ:'string';Desc:'0 intersect, 1 contain, 2 disjoint, 3 equal, 4 touch, 5 overlap, 6 within, 7 cross (comma list)';Def:'0'),
  (A:107;Name:'JOIN';Typ:'vector';Desc:'Join GeoJSON file';Def:''),
  (A:107;Name:'JOIN_FIELDS';Typ:'string';Desc:'Fields to summarize (all)';Def:'*'),
  (A:107;Name:'SUMMARIES';Typ:'string';Desc:'0 count,1 unique,2 min,3 max,4 range,5 sum,6 mean,7 median,8 stdev,9 minority,10 majority,11 q1,12 q3,13 iqr,14 empty,15 filled,16-18 length stats';Def:'0'),
  (A:107;Name:'DISCARD_NONMATCHING';Typ:'boolean';Desc:'Discard the unmatched features';Def:'false'),
  (A:107;Name:'PREFIX';Typ:'string';Desc:'Prefix of the new fields';Def:'*'),
  (A:107;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:108;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:108;Name:'FIELD';Typ:'string';Desc:'Field of the input layer';Def:''),
  (A:108;Name:'INPUT_2';Typ:'vector';Desc:'Table GeoJSON or CSV file';Def:''),
  (A:108;Name:'FIELD_2';Typ:'string';Desc:'Field of the table';Def:''),
  (A:108;Name:'FIELDS_TO_COPY';Typ:'string';Desc:'Fields to copy (all)';Def:'*'),
  (A:108;Name:'METHOD';Typ:'enum';Desc:'0 one-to-many, 1 first match';Def:'1'),
  (A:108;Name:'DISCARD_NONMATCHING';Typ:'boolean';Desc:'Discard the unmatched features';Def:'false'),
  (A:108;Name:'PREFIX';Typ:'string';Desc:'Prefix of the joined fields';Def:'*'),
  (A:108;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:109;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:109;Name:'INTERSECT';Typ:'vector';Desc:'Intersect GeoJSON file (lines)';Def:''),
  (A:109;Name:'INPUT_FIELDS';Typ:'string';Desc:'Input fields (all)';Def:'*'),
  (A:109;Name:'INTERSECT_FIELDS';Typ:'string';Desc:'Intersect fields (all)';Def:'*'),
  (A:109;Name:'INPUT_FIELDS_PREFIX';Typ:'string';Desc:'Input fields prefix (unused)';Def:'*'),
  (A:109;Name:'INTERSECT_FIELDS_PREFIX';Typ:'string';Desc:'Prefix added to the intersect fields';Def:'*'),
  (A:109;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:110;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:110;Name:'LAYERS';Typ:'vector';Desc:'Overlay polygon GeoJSON files separated by ;';Def:''),
  (A:110;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:111;Name:'POLYGONS';Typ:'vector';Desc:'Polygon GeoJSON file';Def:''),
  (A:111;Name:'LINES';Typ:'vector';Desc:'Line GeoJSON file';Def:''),
  (A:111;Name:'LEN_FIELD';Typ:'string';Desc:'Length field name';Def:'LENGTH'),
  (A:111;Name:'COUNT_FIELD';Typ:'string';Desc:'Count field name';Def:'COUNT'),
  (A:111;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:112;Name:'EXTENT';Typ:'extent';Desc:'Extent xmin,xmax,ymin,ymax';Def:''),
  (A:112;Name:'TARGET_CRS';Typ:'crs';Desc:'CRS (unused)';Def:'*'),
  (A:112;Name:'PIXEL_SIZE';Typ:'number';Desc:'Pixel size';Def:'1'),
  (A:112;Name:'NUMBER';Typ:'number';Desc:'Constant value';Def:'1'),
  (A:112;Name:'OUTPUT_TYPE';Typ:'enum';Desc:'Output data type (unused)';Def:'5'),
  (A:112;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:113;Name:'REFERENCE_LAYER';Typ:'raster';Desc:'Reference ASCII grid';Def:''),
  (A:113;Name:'LAYERS';Typ:'raster';Desc:'ASCII grids to align separated by ;';Def:''),
  (A:113;Name:'RESAMPLE_METHOD';Typ:'enum';Desc:'0 nearest neighbour, 1 bilinear';Def:'0'),
  (A:113;Name:'OUTPUT';Typ:'folderDestination';Desc:'Output directory';Def:''),
  (A:114;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:114;Name:'BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:114;Name:'FUZZYMIDPOINT';Typ:'number';Desc:'Midpoint';Def:'10'),
  (A:114;Name:'FUZZYSPREAD';Typ:'number';Desc:'Spread';Def:'0.01'),
  (A:114;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:115;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:115;Name:'BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:115;Name:'OUTPUT_HTML_FILE';Typ:'fileDestination';Desc:'Text report file';Def:'*'),
  (A:116;Name:'INPUT_RASTER';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:116;Name:'RASTER_BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:116;Name:'TABLE';Typ:'string';Desc:'min,max,value,min,max,value,...';Def:''),
  (A:116;Name:'NO_DATA';Typ:'number';Desc:'Nodata value of the output';Def:'-9999'),
  (A:116;Name:'RANGE_BOUNDARIES';Typ:'enum';Desc:'0 min<v<=max, 1 min<=v<max, 2 min<=v<=max, 3 min<v<max';Def:'0'),
  (A:116;Name:'NODATA_FOR_MISSING';Typ:'boolean';Desc:'Use nodata for the unclassified pixels';Def:'false'),
  (A:116;Name:'DATA_TYPE';Typ:'enum';Desc:'Output data type (unused)';Def:'5'),
  (A:116;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:117;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:117;Name:'BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:117;Name:'MINIMUM';Typ:'number';Desc:'New minimum';Def:'0'),
  (A:117;Name:'MAXIMUM';Typ:'number';Desc:'New maximum';Def:'255'),
  (A:117;Name:'NODATA';Typ:'number';Desc:'Nodata value of the output';Def:'-9999'),
  (A:117;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:118;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:118;Name:'Z_FACTOR';Typ:'number';Desc:'Vertical exaggeration';Def:'1'),
  (A:118;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:119;Name:'INPUT_RASTER';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:119;Name:'RASTER_BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:119;Name:'INPUT_VECTOR';Typ:'vector';Desc:'Polygon GeoJSON file';Def:''),
  (A:119;Name:'COLUMN_PREFIX';Typ:'string';Desc:'Prefix of the new fields';Def:'_'),
  (A:119;Name:'STATISTICS';Typ:'string';Desc:'0 count,1 sum,2 mean,3 median,4 stdev,5 min,6 max,7 range,8 minority,9 majority,10 variety,11 variance';Def:'0,1,2'),
  (A:119;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:120;Name:'INPUT_RASTER';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:120;Name:'RASTER_BAND';Typ:'number';Desc:'Band number (1 = first band)';Def:'1'),
  (A:120;Name:'INPUT_VECTOR';Typ:'vector';Desc:'Polygon GeoJSON file';Def:''),
  (A:120;Name:'COLUMN_PREFIX';Typ:'string';Desc:'Prefix of the new fields';Def:'HISTO_'),
  (A:120;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:121;Name:'EXPRESSION';Typ:'expression';Desc:'Expression, e.g. "dem@1" * 2 + "slope@1"';Def:''),
  (A:121;Name:'LAYERS';Typ:'raster';Desc:'ASCII grids separated by ;';Def:''),
  (A:121;Name:'CELLSIZE';Typ:'number';Desc:'Output pixel size';Def:'*'),
  (A:121;Name:'EXTENT';Typ:'extent';Desc:'Output extent xmin,xmax,ymin,ymax';Def:'*'),
  (A:121;Name:'CRS';Typ:'crs';Desc:'CRS (unused)';Def:'*'),
  (A:121;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:122;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:122;Name:'OUTPUT';Typ:'fileDestination';Desc:'Output file (.geojson, .json or .csv)';Def:''),
  (A:122;Name:'LAYER_NAME';Typ:'string';Desc:'Layer name (unused)';Def:'*'),
  (A:122;Name:'DATASOURCE_OPTIONS';Typ:'string';Desc:'Options (unused)';Def:'*'),
  (A:122;Name:'LAYER_OPTIONS';Typ:'string';Desc:'Options (unused)';Def:'*'),
  (A:122;Name:'ACTION_ON_EXISTING_FILE';Typ:'enum';Desc:'Action on existing file (unused)';Def:'0'),
  (A:123;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:123;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:124;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:124;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:125;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:125;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:126;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:126;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:127;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:127;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:128;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:128;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:129;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:129;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:130;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:130;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:131;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:131;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:132;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:132;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:133;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:133;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*'),
  (A:134;Name:'INPUT';Typ:'string';Desc:'Input (ignored)';Def:'*'),
  (A:134;Name:'OUTPUT';Typ:'string';Desc:'Output (ignored)';Def:'*')
 );

 Outs:Array[1..MaxOut]of OutRec=(
  (A:1;Name:'DISTANCE';Typ:'number';Desc:'Distance in meters'),
  (A:1;Name:'DISTANCE_KM';Typ:'number';Desc:'Distance in kilometers'),
  (A:2;Name:'BEARING';Typ:'number';Desc:'Initial bearing (0-360 degrees)'),
  (A:2;Name:'FINAL_BEARING';Typ:'number';Desc:'Final bearing (0-360 degrees)'),
  (A:3;Name:'X';Typ:'number';Desc:'Longitude of destination'),
  (A:3;Name:'Y';Typ:'number';Desc:'Latitude of destination'),
  (A:4;Name:'X';Typ:'number';Desc:'Reprojected X'),
  (A:4;Name:'Y';Typ:'number';Desc:'Reprojected Y'),
  (A:5;Name:'XMIN';Typ:'number';Desc:'Minimum X'),
  (A:5;Name:'YMIN';Typ:'number';Desc:'Minimum Y'),
  (A:5;Name:'XMAX';Typ:'number';Desc:'Maximum X'),
  (A:5;Name:'YMAX';Typ:'number';Desc:'Maximum Y'),
  (A:5;Name:'FEATURE_COUNT';Typ:'number';Desc:'Number of features'),
  (A:5;Name:'POINT_COUNT';Typ:'number';Desc:'Number of vertices'),
  (A:6;Name:'CENTER_X';Typ:'number';Desc:'Center X'),
  (A:6;Name:'CENTER_Y';Typ:'number';Desc:'Center Y'),
  (A:6;Name:'WIDTH';Typ:'number';Desc:'Width of the extent'),
  (A:6;Name:'HEIGHT';Typ:'number';Desc:'Height of the extent'),
  (A:7;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:8;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Centroids layer'),
  (A:9;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Clipped layer'),
  (A:10;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Convex hulls layer'),
  (A:11;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Matching features'),
  (A:11;Name:'FAIL_OUTPUT';Typ:'vectorDestination';Desc:'Non-matching features'),
  (A:12;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Reprojected layer'),
  (A:13;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Lines layer'),
  (A:14;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Points layer'),
  (A:15;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Clipped raster'),
  (A:16;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Reprojected raster'),
  (A:17;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Raster without black borders'),
  (A:18;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Offset lines'),
  (A:19;Name:'OUTPUT';Typ:'fileDestination';Desc:'Information (text file)'),
  (A:20;Name:'OUTPUT';Typ:'vectorDestination';Desc:'One side buffer'),
  (A:21;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Overview base name'),
  (A:22;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Sharpened raster'),
  (A:23;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Polygons'),
  (A:24;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Proximity raster'),
  (A:25;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Calculated raster'),
  (A:26;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Rasterized layer'),
  (A:27;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Modified raster'),
  (A:28;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Modified raster'),
  (A:29;Name:'OUTPUT';Typ:'folderDestination';Desc:'Tiles directory'),
  (A:30;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Roughness raster'),
  (A:31;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Sieved raster'),
  (A:32;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Slope raster'),
  (A:33;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Tile index'),
  (A:34;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Translated raster'),
  (A:35;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Viewshed raster'),
  (A:36;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:37;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:38;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:38;Name:'SUMMARY_OUTPUT';Typ:'vectorDestination';Desc:'Summary table'),
  (A:39;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:40;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:41;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:42;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:43;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:44;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:45;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:46;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Matching features'),
  (A:46;Name:'FAIL_OUTPUT';Typ:'vectorDestination';Desc:'Non-matching features'),
  (A:47;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:48;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:49;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:50;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Input layer'),
  (A:51;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Input layer'),
  (A:52;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Input layer'),
  (A:53;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:54;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:55;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:56;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:57;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:58;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:59;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:60;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:61;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:62;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:63;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:64;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:65;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:66;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:67;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:68;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:69;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:70;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:71;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:72;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:73;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:74;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:75;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:76;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:77;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:78;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:79;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:80;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:81;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:82;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:83;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:84;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:85;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:86;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:87;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:88;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:89;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:90;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:91;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:92;Name:'OBSERVED_MD';Typ:'number';Desc:'Observed mean distance'),
  (A:92;Name:'EXPECTED_MD';Typ:'number';Desc:'Expected mean distance'),
  (A:92;Name:'NN_INDEX';Typ:'number';Desc:'Nearest neighbour index'),
  (A:92;Name:'POINT_COUNT';Typ:'number';Desc:'Number of points'),
  (A:92;Name:'Z_SCORE';Typ:'number';Desc:'Z-score'),
  (A:92;Name:'OUTPUT_HTML_FILE';Typ:'fileDestination';Desc:'Text report'),
  (A:93;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:94;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:95;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:96;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:97;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:98;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:99;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:100;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:101;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:102;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:103;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:104;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:105;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:106;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:107;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:108;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:109;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:110;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:111;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:112;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output raster'),
  (A:113;Name:'OUTPUT';Typ:'folderDestination';Desc:'Output directory'),
  (A:114;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output raster'),
  (A:115;Name:'MIN';Typ:'number';Desc:'Minimum'),
  (A:115;Name:'MAX';Typ:'number';Desc:'Maximum'),
  (A:115;Name:'RANGE';Typ:'number';Desc:'Range'),
  (A:115;Name:'SUM';Typ:'number';Desc:'Sum'),
  (A:115;Name:'MEAN';Typ:'number';Desc:'Mean'),
  (A:115;Name:'STD_DEV';Typ:'number';Desc:'Standard deviation'),
  (A:115;Name:'SUM_OF_SQUARES';Typ:'number';Desc:'Sum of squares'),
  (A:115;Name:'OUTPUT_HTML_FILE';Typ:'fileDestination';Desc:'Text report'),
  (A:116;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output raster'),
  (A:117;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output raster'),
  (A:118;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output raster'),
  (A:119;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:120;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer'),
  (A:121;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output raster'),
  (A:122;Name:'OUTPUT';Typ:'fileDestination';Desc:'Saved file'),
  (A:123;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:124;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:125;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:126;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:127;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:128;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:129;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:130;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:131;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:132;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:133;Name:'OUTPUT';Typ:'string';Desc:'Not produced'),
  (A:134;Name:'OUTPUT';Typ:'string';Desc:'Not produced')
 );

Type
 PStr=^String;
 PJ=^TJ;
 TJ=Record
  Kind:Byte;          { 0 null, 1 booleen, 2 nombre, 3 chaine, 4 tableau, 5 objet }
  Key,Val:PStr;
  First,Last,Next:PJ;
 End;
 TPt=Record X,Y:Real;End;
 PPts=^TPtArr;
 TPtArr=Array[0..8000000]of TPt;
 PPath=^TPath;
 TPath=Record
  N:LongInt;
  Pts:PPts;
  Poly:Integer;
  Area:Real;
  Next:PPath;
 End;
 TGeom=Record          { Cls: 0 aucune, 1 points, 2 lignes, 3 polygones }
  Cls:Byte;
  First,Last:PPath;
  Count,NPoly:Integer;
 End;
 TEdge=Record X1,Y1,X2,Y2:Real;End;
 PEdges=^TEdgeArr;
 TEdgeArr=Array[0..8000000]of TEdge;
 PSplit=^TSplit;
 TSplit=Record T,X,Y:Real;Next:PSplit;End;
 PSplitArr=^TSplitArr;
 TSplitArr=Array[0..8000000]of PSplit;
 PLongs=^TLongs;
 TLongs=Array[0..8000000]of LongInt;
 PReals=^TReals;
 TReals=Array[0..8000000]of Real;
 PBools=^TBools;
 TBools=Array[0..8000000]of Boolean;
 PPathArr=Array[0..8000000]of PPath;
 PStrs=^TStrs;
 TStrs=Array[0..8000000]of PStr;
 PBytes=^TBytes;
 TBytes=Array[0..8000000]of Byte;
 TGeomArr=Array[0..1000000]of TGeom;
 TRaster=Record
  NC,NR:LongInt;
  XLL,YLL,Cell,NoData:Real;
  Data:PReals;
 DType:Byte;
 Epsg:LongInt;
 End;
 PGeom=^TGeom;
 PValList=^TValList;
 TVal=Record
  K:Byte;               { 0 nul, 1 nombre, 2 chaine, 3 booleen, 4 geometrie, 5 tableau, 6 dictionnaire,
                          7 date-heure, 8 date, 9 heure, 10 intervalle, 11 entite }
  N:Real;
  S:String;
  G:PGeom;
  L:PValList;           { elements (dictionnaire : cle, valeur, cle, valeur...) }
  F:PJ;
 End;
 PValArr=^TValArr;
 TValArr=Array[0..1000000]of TVal;
 TValList=Record
  Cnt,Cap:LongInt;
  V:PValArr;
 End;

Var
 JsonMode:Boolean;
 Verbose,StdinMode,HelpFlag,SkipPlugins:Boolean;
 DistUnits,AreaUnits,Ellipsoid,ProjectPath,Pos3:String;
 DistFactor,AreaFactor:Real;   { metres par unite, metres carres par unite (0 = non defini) }
 Cmd,AlgoId:String;
 ArgName,ArgVal:Array[1..MaxArg]of String;
 ArgCount:Integer;
 ResName,ResVal:Array[1..MaxArg]of String;
 ResCount:Integer;

{ ------------------------------------------------------------------ }
{ Utilitaires                                                         }
{ ------------------------------------------------------------------ }

Function StrUpper(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do S[I]:=UpCase(S[I]);
 StrUpper:=S;
End;

Function LowerStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do If S[I]in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
 LowerStr:=S;
End;

Function RealToStr(R:Real):String;
Var
 S:String;
Begin
 Str(R:0:6,S);
 RealToStr:=S;
End;

{ Nombre avec 9 decimales au maximum, sans zeros inutiles }
Function NumStr(R:Real):String;
Var
 S:String;
 L:Integer;
Begin
 If Abs(R)<5E-10Then R:=0;
 Str(R:0:9,S);
 If Pos('.',S)>0Then Begin
  L:=Length(S);
  While S[L]='0'do Dec(L);
  If S[L]='.'Then Dec(L);
  S:=Copy(S,1,L);
 End;
 NumStr:=S;
End;

Function IntToStr(L:LongInt):String;
Var
 S:String;
Begin
 Str(L,S);
 IntToStr:=S;
End;

Function MinR(A,B:Real):Real;Begin If A<B Then MinR:=A Else MinR:=B;End;
Function MaxR(A,B:Real):Real;Begin If A>B Then MaxR:=A Else MaxR:=B;End;

Function FloorR(X:Real):Real;
Var
 T:Real;
Begin
 T:=Int(X);
 If(X<T)Then T:=T-1;
 FloorR:=T;
End;

{ Arrondi en entier long, borne pour eviter les debordements }
Function RoundL(X:Real):LongInt;
Begin
 X:=FloorR(X+0.5);
 If X>1E9Then X:=1E9;
 If X<-1E9Then X:=-1E9;
 RoundL:=Trunc(X);
End;

Function FloorL(X:Real):LongInt;
Begin
 X:=FloorR(X);
 If X>1E9Then X:=1E9;
 If X<-1E9Then X:=-1E9;
 FloorL:=Trunc(X);
End;

Function Atan2(Y,X:Real):Real;
Begin
 If X>0Then Atan2:=ArcTan(Y/X) Else
 If X<0Then Begin
  If Y>=0Then Atan2:=ArcTan(Y/X)+Pi
         Else Atan2:=ArcTan(Y/X)-Pi;
 End
  Else
 If Y>0Then Atan2:=Pi/2 Else
 If Y<0Then Atan2:=-Pi/2
       Else Atan2:=0;
End;

Function ArcSin(X:Real):Real;
Begin
 If X>=1Then ArcSin:=Pi/2 Else
 If X<=-1Then ArcSin:=-Pi/2
         Else ArcSin:=ArcTan(X/Sqrt(1-X*X));
End;

Function Deg2Rad(D:Real):Real;Begin Deg2Rad:=D*Pi/180;End;
Function Rad2Deg(R:Real):Real;Begin Rad2Deg:=R*180/Pi;End;

Function NormDeg(D:Real):Real;
Begin
 While D<0do D:=D+360;
 While D>=360do D:=D-360;
 NormDeg:=D;
End;

Function IsNumber(S:String):Boolean;
Var
 R:Real;
 Err:Integer;
Begin
 If S=''Then Begin
  IsNumber:=False;
  Exit;
 End;
 Val(S,R,Err);
 IsNumber:=Err=0;
End;

Function JsonStr(S:String):String;
Var
 I:Integer;
 T:String;
Begin
 T:='"';
 For I:=1 to Length(S)do Begin
  If(S[I]='"')or(S[I]='\')Then T:=T+'\';
  If S[I]=#10Then T:=T+'\n' Else
  If S[I]=#13Then Begin End Else
  If S[I]=#9Then T:=T+'\t'
            Else T:=T+S[I];
 End;
 JsonStr:=T+'"';
End;

Function JsonVal(S:String):String;
Begin
 If IsNumber(S)Then JsonVal:=S Else
 If(S='true')or(S='false')Then JsonVal:=S
                         Else JsonVal:=JsonStr(S);
End;

Procedure Fail(Msg:String);Begin
 If JsonMode Then WriteLn('{"error":',JsonStr(Msg),'}')
             Else WriteLn(Msg);
 Halt(1);
End;

{ Metres par unite de distance (0 si l'unite est inconnue) }
Function DistanceFactor(Name:String):Real;
Var
 I:Integer;
Begin
 Name:=StrUpper(Name);
 For I:=1 to Length(Name)do If Name[I]in['_','-']Then Name[I]:=' ';
 DistanceFactor:=0;
 If(Name='METERS')or(Name='METRES')or(Name='M')Then DistanceFactor:=1 Else
 If(Name='KILOMETERS')or(Name='KILOMETRES')or(Name='KM')Then DistanceFactor:=1000 Else
 If(Name='FEET')or(Name='FT')Then DistanceFactor:=0.3048 Else
 If(Name='YARDS')or(Name='YD')Then DistanceFactor:=0.9144 Else
 If(Name='MILES')or(Name='MI')Then DistanceFactor:=1609.344 Else
 If(Name='NAUTICAL MILES')or(Name='NM')Then DistanceFactor:=1852 Else
 If(Name='CENTIMETERS')or(Name='CENTIMETRES')or(Name='CM')Then DistanceFactor:=0.01 Else
 If(Name='MILLIMETERS')or(Name='MILLIMETRES')or(Name='MM')Then DistanceFactor:=0.001 Else
 If(Name='INCHES')or(Name='IN')Then DistanceFactor:=0.0254;
End;

{ Metres carres par unite d'aire (0 si l'unite est inconnue) }
Function AreaUnitFactor(Name:String):Real;
Var
 I:Integer;
Begin
 Name:=StrUpper(Name);
 For I:=1 to Length(Name)do If Name[I]in['_','-']Then Name[I]:=' ';
 AreaUnitFactor:=0;
 If Name='SQUARE METERS'Then AreaUnitFactor:=1 Else
 If Name='SQUARE KILOMETERS'Then AreaUnitFactor:=1E6 Else
 If Name='SQUARE FEET'Then AreaUnitFactor:=0.09290304 Else
 If Name='SQUARE YARDS'Then AreaUnitFactor:=0.83612736 Else
 If Name='SQUARE MILES'Then AreaUnitFactor:=2589988.110336 Else
 If Name='HECTARES'Then AreaUnitFactor:=10000 Else
 If Name='ACRES'Then AreaUnitFactor:=4046.8564224 Else
 If Name='SQUARE NAUTICAL MILES'Then AreaUnitFactor:=3429904 Else
 If Name='SQUARE CENTIMETERS'Then AreaUnitFactor:=1E-4 Else
 If Name='SQUARE MILLIMETERS'Then AreaUnitFactor:=1E-6 Else
 If Name='SQUARE INCHES'Then AreaUnitFactor:=0.00064516;
End;

Function AllocBlock(Size:LongInt):Pointer;
Var
 P:Pointer;
Begin
 If Size<1Then Size:=1;
 GetMem(P,Size);
 AllocBlock:=P;
End;

{ ------------------------------------------------------------------ }
{ Arbre JSON                                                          }
{ ------------------------------------------------------------------ }

Function MkStr(S:String):PStr;
Var
 P:PStr;
Begin
 GetMem(P,Length(S)+1);
 Move(S,P^,Length(S)+1);
 MkStr:=P;
End;

Function NewJ(K:Byte):PJ;
Var
 P:PJ;
Begin
 New(P);
 P^.Kind:=K;
 P^.Key:=Nil;P^.Val:=Nil;
 P^.First:=Nil;P^.Last:=Nil;P^.Next:=Nil;
 NewJ:=P;
End;

Function JVal(P:PJ):String;
Begin
 If(P=Nil)or(P^.Val=Nil)Then JVal:='' Else JVal:=P^.Val^;
End;

Function JKey(P:PJ):String;
Begin
 If(P=Nil)or(P^.Key=Nil)Then JKey:='' Else JKey:=P^.Key^;
End;

Procedure JAdd(Par,Ch:PJ);Begin
 Ch^.Next:=Nil;
 If Par^.Last=Nil Then Par^.First:=Ch
                  Else Par^.Last^.Next:=Ch;
 Par^.Last:=Ch;
End;

Procedure JAddKV(Par:PJ;Key:String;Ch:PJ);Begin
 Ch^.Key:=MkStr(Key);
 JAdd(Par,Ch);
End;

Function JFind(Obj:PJ;Const Key:String):PJ;
Var
 C:PJ;
Begin
 JFind:=Nil;
 If(Obj=Nil)or(Obj^.Kind<>5)Then Exit;
 C:=Obj^.First;
 While C<>Nil do Begin
  If JKey(C)=Key Then Begin
   JFind:=C;
   Exit;
  End;
  C:=C^.Next;
 End;
End;

Function JNum(R:Real):PJ;
Var
 N:PJ;
Begin
 N:=NewJ(2);
 N^.Val:=MkStr(NumStr(R));
 JNum:=N;
End;

Function JText(S:String):PJ;
Var
 N:PJ;
Begin
 N:=NewJ(3);
 N^.Val:=MkStr(S);
 JText:=N;
End;

Function JClone(P:PJ):PJ;
Var
 N,C:PJ;
Begin
 N:=NewJ(P^.Kind);
 N^.Key:=P^.Key;
 N^.Val:=P^.Val;
 C:=P^.First;
 While C<>Nil do Begin
  JAdd(N,JClone(C));
  C:=C^.Next;
 End;
 JClone:=N;
End;

{ Remplace Old par NewN dans la liste des enfants de Par }
Procedure JReplace(Par,Old,NewN:PJ);
Var
 C:PJ;
Begin
 NewN^.Key:=Old^.Key;
 NewN^.Next:=Old^.Next;
 If Par^.First=Old Then Par^.First:=NewN
  Else
 Begin
  C:=Par^.First;
  While C^.Next<>Old do C:=C^.Next;
  C^.Next:=NewN;
 End;
 If Par^.Last=Old Then Par^.Last:=NewN;
End;

Procedure JRemoveKey(Par:PJ;Key:String);
Var
 C,Prev:PJ;
Begin
 Prev:=Nil;
 C:=Par^.First;
 While C<>Nil do Begin
  If JKey(C)=Key Then Begin
   If Prev=Nil Then Par^.First:=C^.Next Else Prev^.Next:=C^.Next;
   If Par^.Last=C Then Par^.Last:=Prev;
   Exit;
  End;
  Prev:=C;
  C:=C^.Next;
 End;
End;

Var
 PF:Text;
 PCh:Char;
 PBuf:Array[0..16383]of Char;
 ParseName:String;

Procedure NextCh;Begin
 If EOF(PF)Then PCh:=#0
           Else Read(PF,PCh);
End;

Procedure PFail(Msg:String);Begin
 Fail('Error: invalid JSON in '+ParseName+' ('+Msg+')');
End;

Procedure SkipWs;Begin
 While PCh in[' ',#9,#10,#13,#26]do NextCh;
End;

Function ParseStrRaw:String;
Var
 S:String;
Begin
 S:='';
 NextCh;
 While PCh<>'"'do Begin
  If PCh=#0Then PFail('unterminated string');
  If Length(S)>=250Then PFail('string longer than 250 characters');
  If PCh='\'Then Begin
   S:=S+PCh;
   NextCh;
   If PCh=#0Then PFail('unterminated string');
  End;
  S:=S+PCh;
  NextCh;
 End;
 NextCh;
 ParseStrRaw:=S;
End;

Function ParseValue(Depth:Integer):PJ;
Var
 N,C:PJ;
 S,K:String;
 More:Boolean;
Begin
 SkipWs;
 If Depth>200Then PFail('nesting too deep');
 Case PCh of
  '{':Begin
   N:=NewJ(5);
   NextCh;SkipWs;
   If PCh='}'Then NextCh
    Else
   Begin
    Repeat
     SkipWs;
     If PCh<>'"'Then PFail('key expected');
     K:=ParseStrRaw;
     SkipWs;
     If PCh<>':'Then PFail('":" expected');
     NextCh;
     C:=ParseValue(Depth+1);
     JAddKV(N,K,C);
     SkipWs;
     More:=False;
     If PCh=','Then Begin NextCh;More:=True;End;
    Until Not More;
    If PCh<>'}'Then PFail('"}" expected');
    NextCh;
   End;
   ParseValue:=N;
  End;
  '[':Begin
   N:=NewJ(4);
   NextCh;SkipWs;
   If PCh=']'Then NextCh
    Else
   Begin
    Repeat
     C:=ParseValue(Depth+1);
     JAdd(N,C);
     SkipWs;
     More:=False;
     If PCh=','Then Begin NextCh;More:=True;End;
    Until Not More;
    If PCh<>']'Then PFail('"]" expected');
    NextCh;
   End;
   ParseValue:=N;
  End;
  '"':Begin
   N:=NewJ(3);
   N^.Val:=MkStr(ParseStrRaw);
   ParseValue:=N;
  End;
  '-','0'..'9':Begin
   S:='';
   While PCh in['0'..'9','-','+','.','e','E']do Begin
    If Length(S)>=40Then PFail('number too long');
    S:=S+PCh;
    NextCh;
   End;
   N:=NewJ(2);
   N^.Val:=MkStr(S);
   ParseValue:=N;
  End;
  't','f','n':Begin
   S:='';
   While PCh in['a'..'z']do Begin
    If Length(S)>=10Then PFail('unexpected token');
    S:=S+PCh;
    NextCh;
   End;
   If S='true'Then Begin N:=NewJ(1);N^.Val:=MkStr('true');End Else
   If S='false'Then Begin N:=NewJ(1);N^.Val:=MkStr('false');End Else
   If S='null'Then N:=NewJ(0)
              Else PFail('unexpected token '+S);
   ParseValue:=N;
  End;
  Else PFail('unexpected character');
 End;
End;

{ Charge un fichier GeoJSON et le normalise en FeatureCollection }
Function LoadGeoJSON(FileName:String):PJ;
Var
 R,Col,Arr,F:PJ;
 T:String;
Begin
 ParseName:=FileName;
 {$I-}
 Assign(PF,FileName);
 Reset(PF);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to open input file '+FileName);
 SetTextBuf(PF,PBuf);
 NextCh;
 R:=ParseValue(0);
 Close(PF);
 If R^.Kind<>5Then Fail('Error: '+FileName+' is not a GeoJSON object');
 T:=JVal(JFind(R,'type'));
 If T='FeatureCollection'Then Begin
  Arr:=JFind(R,'features');
  If(Arr=Nil)or(Arr^.Kind<>4)Then Fail('Error: '+FileName+' has no features array');
  LoadGeoJSON:=R;
  Exit;
 End;
 Col:=NewJ(5);
 JAddKV(Col,'type',JText('FeatureCollection'));
 Arr:=NewJ(4);
 JAddKV(Col,'features',Arr);
 If T='Feature'Then JAdd(Arr,R)
  Else
 If(T='Point')or(T='MultiPoint')or(T='LineString')or(T='MultiLineString')or
   (T='Polygon')or(T='MultiPolygon')Then Begin
  F:=NewJ(5);
  JAddKV(F,'type',JText('Feature'));
  JAddKV(F,'properties',NewJ(5));
  JAddKV(F,'geometry',R);
  JAdd(Arr,F);
 End
  Else
 Fail('Error: '+FileName+' is not a supported GeoJSON file');
 LoadGeoJSON:=Col;
End;

Procedure WriteJ(Var F:Text;P:PJ);
Var
 C:PJ;
Begin
 Case P^.Kind of
  0:Write(F,'null');
  1,2:Write(F,JVal(P));
  3:Write(F,'"',JVal(P),'"');
  4:Begin
   Write(F,'[');
   C:=P^.First;
   While C<>Nil do Begin
    WriteJ(F,C);
    If C^.Next<>Nil Then Begin
     Write(F,',');
     If JKey(P)='features'Then WriteLn(F);
    End;
    C:=C^.Next;
   End;
   Write(F,']');
  End;
  5:Begin
   Write(F,'{');
   C:=P^.First;
   While C<>Nil do Begin
    Write(F,'"',JKey(C),'":');
    WriteJ(F,C);
    If C^.Next<>Nil Then Write(F,',');
    C:=C^.Next;
   End;
   Write(F,'}');
  End;
 End;
End;

Procedure SaveGeoJSON(FileName:String;Root:PJ);
Var
 F:Text;
Begin
 {$I-}
 Assign(F,FileName);
 Rewrite(F);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to create output file '+FileName);
 WriteJ(F,Root);
 WriteLn(F);
 Close(F);
End;

Function LayerFeatures(Root:PJ):PJ;Begin
 LayerFeatures:=JFind(Root,'features');
End;

{ Remplace la geometrie d'une entite (Nil = geometrie nulle) }
Procedure SetGeom(Feat,G:PJ);
Var
 Old:PJ;
Begin
 If G=Nil Then G:=NewJ(0);
 Old:=JFind(Feat,'geometry');
 If Old=Nil Then JAddKV(Feat,'geometry',G)
            Else JReplace(Feat,Old,G);
End;

{ ------------------------------------------------------------------ }
{ Systemes de coordonnees                                             }
{ ------------------------------------------------------------------ }

{ ------------------------------------------------------------------ }
{ Systemes de coordonnees                                             }
{ ------------------------------------------------------------------ }

Const
 MaxEll=9;
 EllName:Array[1..MaxEll]of String[12]=('WGS84','GRS80','Clarke1866','Intl1924','Bessel1841','Airy1830','Sphere','Krassowsky','Clarke1880');
 EllA:Array[1..MaxEll]of Real=(6378137.0,6378137.0,6378206.4,6378388.0,6377397.155,6377563.396,6371008.8,6378245.0,6378249.145);
 EllRf:Array[1..MaxEll]of Real=(298.257223563,298.257222101,294.9786982,297.0,299.1528128,299.3249646,0,298.3,293.465);
 KGeo=0;KTm=1;KLcc=2;KAea=3;KMerc=4;KLaea=5;KPolar=6;KWeb=7;KEqc=8;
 CustomBase=100000;

Type
 TCrs=Record
  Code:LongInt;
  Kind,Ell:Byte;
  Lon0,Lat0,Lat1,Lat2,K0,X0,Y0,Dx,Dy,Dz,EA,EF,Rx,Ry,Rz,Sc:Real;
  Name:String[48];
  Proj:String[120];
  Z:Array[1..24]of Real;
 End;

Var
 Custom:Array[1..8]of TCrs;
 CustomN:Integer;
 CSlot:Array[1..4]of TCrs;
 CSlotUsed:Array[1..4]of Boolean;
 CSlotNext:Integer;

Function Tan2(X:Real):Real;Begin Tan2:=Sin(X)/Cos(X);End;
Function Sinh(X:Real):Real;Begin Sinh:=(Exp(X)-Exp(-X))/2;End;
Function Cosh(X:Real):Real;Begin Cosh:=(Exp(X)+Exp(-X))/2;End;
Function Asinh(X:Real):Real;Begin
 If X>=0Then Asinh:=Ln(X+Sqrt(X*X+1)) Else Asinh:=-Ln(-X+Sqrt(X*X+1));
End;
Function Atanh(X:Real):Real;Begin Atanh:=0.5*Ln((1+X)/(1-X));End;
Function SgnR(X:Real):Real;Begin If X<0Then SgnR:=-1 Else SgnR:=1;End;

Procedure SetupCrs(Var C:TCrs;Kind,Ell:Byte;Lon0,Lat0,Lat1,Lat2,K0,X0,Y0:Real);Begin
 C.Kind:=Kind;C.Ell:=Ell;C.Lon0:=Lon0;C.Lat0:=Lat0;C.Lat1:=Lat1;C.Lat2:=Lat2;
 C.K0:=K0;C.X0:=X0;C.Y0:=Y0;
End;

Procedure CrsDatum(Var C:TCrs;Dx,Dy,Dz:Real);Begin
 C.Dx:=Dx;C.Dy:=Dy;C.Dz:=Dz;
End;

{ Rotations en secondes d'arc, echelle en ppm (convention vecteur de position) }
Procedure CrsRot(Var C:TCrs;Rx,Ry,Rz,Sc:Real);Begin
 C.Rx:=Rx*Pi/648000;C.Ry:=Ry*Pi/648000;C.Rz:=Rz*Pi/648000;C.Sc:=Sc*1E-6;
End;

Function CrsDefine(Code:LongInt;Var C:TCrs):Boolean;
Var
 Zn:Integer;
 Ok:Boolean;
 Nm:String;
Begin
 Ok:=True;
 FillChar(C,SizeOf(C),0);
 C.Code:=Code;C.K0:=1;
 Nm:='EPSG:'+IntToStr(Code);
 Case Code of
  4326:Begin SetupCrs(C,KGeo,1,0,0,0,0,1,0,0);Nm:='WGS 84';End;
  4269:Begin SetupCrs(C,KGeo,2,0,0,0,0,1,0,0);Nm:='NAD83';End;
  4617:Begin SetupCrs(C,KGeo,2,0,0,0,0,1,0,0);Nm:='NAD83(CSRS)';End;
  4258:Begin SetupCrs(C,KGeo,2,0,0,0,0,1,0,0);Nm:='ETRS89';End;
  4283:Begin SetupCrs(C,KGeo,2,0,0,0,0,1,0,0);Nm:='GDA94';End;
  7844:Begin SetupCrs(C,KGeo,2,0,0,0,0,1,0,0);Nm:='GDA2020';End;
  4674:Begin SetupCrs(C,KGeo,2,0,0,0,0,1,0,0);Nm:='SIRGAS 2000';End;
  4267:Begin SetupCrs(C,KGeo,3,0,0,0,0,1,0,0);CrsDatum(C,-8,160,176);Nm:='NAD27';End;
  4230:Begin SetupCrs(C,KGeo,4,0,0,0,0,1,0,0);CrsDatum(C,-87,-98,-121);Nm:='ED50';End;
  4277:Begin SetupCrs(C,KGeo,6,0,0,0,0,1,0,0);CrsDatum(C,446.448,-125.157,542.06);CrsRot(C,0.1502,0.247,0.8421,-20.4894);Nm:='OSGB36';End;
  4314:Begin SetupCrs(C,KGeo,5,0,0,0,0,1,0,0);CrsDatum(C,598.1,73.7,418.2);CrsRot(C,0.202,0.045,-2.455,6.7);Nm:='DHDN';End;
  3857,900913,3785:Begin SetupCrs(C,KWeb,1,0,0,0,0,1,0,0);C.Code:=3857;Nm:='WGS 84 / Pseudo-Mercator';End;
  3395:Begin SetupCrs(C,KMerc,1,0,0,0,0,1,0,0);Nm:='WGS 84 / World Mercator';End;
  4087,32662:Begin SetupCrs(C,KEqc,1,0,0,0,0,1,0,0);Nm:='WGS 84 / World Equidistant Cylindrical';End;
  27700:Begin SetupCrs(C,KTm,6,-2,49,0,0,0.9996012717,400000,-100000);CrsDatum(C,446.448,-125.157,542.06);CrsRot(C,0.1502,0.247,0.8421,-20.4894);Nm:='OSGB36 / British National Grid';End;
  2154:Begin SetupCrs(C,KLcc,2,3,46.5,49,44,1,700000,6600000);Nm:='RGF93 / Lambert-93';End;
  3035:Begin SetupCrs(C,KLaea,2,10,52,0,0,1,4321000,3210000);Nm:='ETRS89-extended / LAEA Europe';End;
  5070:Begin SetupCrs(C,KAea,2,-96,23,29.5,45.5,1,0,0);Nm:='NAD83 / Conus Albers';End;
  3347:Begin SetupCrs(C,KLcc,2,-91.866666666667,63.390675,49,77,1,6200000,3000000);Nm:='NAD83 / Statistics Canada Lambert';End;
  3978:Begin SetupCrs(C,KLcc,2,-95,49,49,77,1,0,0);Nm:='NAD83 / Canada Atlas Lambert';End;
  32198:Begin SetupCrs(C,KLcc,2,-68.5,44,60,46,1,0,0);Nm:='NAD83 / Quebec Lambert';End;
  3005:Begin SetupCrs(C,KAea,2,-126,45,50,58.5,1,1000000,0);Nm:='NAD83 / BC Albers';End;
  3413:Begin SetupCrs(C,KPolar,1,-45,90,70,0,1,0,0);Nm:='WGS 84 / NSIDC Sea Ice Polar Stereographic North';End;
  3031:Begin SetupCrs(C,KPolar,1,0,-90,-71,0,1,0,0);Nm:='WGS 84 / Antarctic Polar Stereographic';End;
  2193:Begin SetupCrs(C,KTm,2,173,0,0,0,0.9996,1600000,10000000);Nm:='NZGD2000 / New Zealand Transverse Mercator 2000';End;
  3112:Begin SetupCrs(C,KLcc,2,134,0,-18,-36,1,0,0);Nm:='GDA94 / Geoscience Australia Lambert';End;
  31466,31467,31468,31469:Begin
   Zn:=Code-31464;
   SetupCrs(C,KTm,5,Zn*3,0,0,0,1,Zn*1000000.0+500000,0);
   CrsDatum(C,598.1,73.7,418.2);CrsRot(C,0.202,0.045,-2.455,6.7);Nm:='DHDN / 3-degree Gauss-Kruger zone '+IntToStr(Zn);
  End;
  3067:Begin SetupCrs(C,KTm,2,27,0,0,0,0.9996,500000,0);Nm:='ETRS89 / TM35FIN';End;
  3006:Begin SetupCrs(C,KTm,2,15,0,0,0,0.9996,500000,0);Nm:='SWEREF99 TM';End;
  3059:Begin SetupCrs(C,KTm,2,24,0,0,0,0.9996,500000,-6000000);Nm:='LKS92 / Latvia TM';End;
  32181:Begin SetupCrs(C,KTm,2,-53,0,0,0,0.9999,304800,0);Nm:='NAD83 / MTM zone 1';End;
  32182:Begin SetupCrs(C,KTm,2,-56,0,0,0,0.9999,304800,0);Nm:='NAD83 / MTM zone 2';End;
  32183..32190:Begin
   SetupCrs(C,KTm,2,-58.5-3*(Code-32183),0,0,0,0.9999,304800,0);
   Nm:='NAD83 / MTM zone '+IntToStr(Code-32180);
  End;
  32601..32660:Begin Zn:=Code-32600;SetupCrs(C,KTm,1,Zn*6-183,0,0,0,0.9996,500000,0);Nm:='WGS 84 / UTM zone '+IntToStr(Zn)+'N';End;
  32701..32760:Begin Zn:=Code-32700;SetupCrs(C,KTm,1,Zn*6-183,0,0,0,0.9996,500000,10000000);Nm:='WGS 84 / UTM zone '+IntToStr(Zn)+'S';End;
  26901..26923:Begin Zn:=Code-26900;SetupCrs(C,KTm,2,Zn*6-183,0,0,0,0.9996,500000,0);Nm:='NAD83 / UTM zone '+IntToStr(Zn)+'N';End;
  26703..26722:Begin Zn:=Code-26700;SetupCrs(C,KTm,3,Zn*6-183,0,0,0,0.9996,500000,0);CrsDatum(C,-8,160,176);Nm:='NAD27 / UTM zone '+IntToStr(Zn)+'N';End;
  25828..25838:Begin Zn:=Code-25800;SetupCrs(C,KTm,2,Zn*6-183,0,0,0,0.9996,500000,0);Nm:='ETRS89 / UTM zone '+IntToStr(Zn)+'N';End;
  23028..23038:Begin Zn:=Code-23000;SetupCrs(C,KTm,4,Zn*6-183,0,0,0,0.9996,500000,0);CrsDatum(C,-87,-98,-121);Nm:='ED50 / UTM zone '+IntToStr(Zn)+'N';End;
  Else Ok:=False;
 End;
 If Ok Then Begin
  C.Name:=Nm;
  C.EA:=EllA[C.Ell];C.EF:=EllRf[C.Ell];
 End
  Else
 If(Code>CustomBase)and(Code<=CustomBase+CustomN)Then Begin
  C:=Custom[Code-CustomBase];
  Ok:=True;
 End;
 CrsDefine:=Ok;
End;

{ Constantes derivees (dependent du type de projection) }
Procedure CrsPrep(Var C:TCrs);
Var
 A,F,E2,E,N,S,M1,M2,T1,T2,T0,Q0,Qp,B0,Q1,Q2,Ph:Real;

 Function Mm(Lat:Real):Real;Begin Mm:=Cos(Lat)/Sqrt(1-E2*Sqr(Sin(Lat)));End;
 Function Tt(Lat:Real):Real;Begin
  Tt:=Tan2(Pi/4-Lat/2)/Exp(E/2*Ln((1-E*Sin(Lat))/(1+E*Sin(Lat))));
 End;
 Function Qq(Lat:Real):Real;
 Var Sp:Real;
 Begin
  Sp:=Sin(Lat);
  If E<1E-12Then Qq:=2*Sp
   Else Qq:=(1-E2)*(Sp/(1-E2*Sp*Sp)-(1/(2*E))*Ln((1-E*Sp)/(1+E*Sp)));
 End;

Begin
 A:=C.EA;
 If C.EF>0Then F:=1/C.EF Else F:=0;
 E2:=F*(2-F);E:=Sqrt(E2);
 C.Z[1]:=A;C.Z[2]:=E2;C.Z[3]:=E;
 Case C.Kind of
  KTm:Begin
   N:=F/(2-F);
   C.Z[4]:=N;
   C.Z[5]:=A/(1+N)*(1+N*N/4+Sqr(N*N)/64+N*N*N*N*N*N/256);
   C.Z[6]:=N/2-2*N*N/3+5*N*N*N/16+41*Sqr(N*N)/180;
   C.Z[7]:=13*N*N/48-3*N*N*N/5+557*Sqr(N*N)/1440;
   C.Z[8]:=61*N*N*N/240-103*Sqr(N*N)/140;
   C.Z[9]:=49561*Sqr(N*N)/161280;
   C.Z[10]:=N/2-2*N*N/3+37*N*N*N/96-Sqr(N*N)/360;
   C.Z[11]:=N*N/48+N*N*N/15-437*Sqr(N*N)/1440;
   C.Z[12]:=17*N*N*N/480-37*Sqr(N*N)/840;
   C.Z[13]:=4397*Sqr(N*N)/161280;
   C.Z[14]:=2*N-2*N*N/3-2*N*N*N+116*Sqr(N*N)/45;
   C.Z[15]:=7*N*N/3-8*N*N*N/5-227*Sqr(N*N)/45;
   C.Z[16]:=56*N*N*N/15-136*Sqr(N*N)/35;
   C.Z[17]:=4279*Sqr(N*N)/630;
   Ph:=Deg2Rad(C.Lat0);
   S:=Sin(Ph);
   T0:=Sinh(Atanh(S)-(2*Sqrt(N)/(1+N))*Atanh((2*Sqrt(N)/(1+N))*S));
   T1:=ArcTan(T0);
   C.Z[18]:=C.K0*0+C.Z[5]*(T1+C.Z[6]*Sin(2*T1)+C.Z[7]*Sin(4*T1)+C.Z[8]*Sin(6*T1)+C.Z[9]*Sin(8*T1));
  End;
  KLcc:Begin
   T1:=Deg2Rad(C.Lat1);T2:=Deg2Rad(C.Lat2);
   M1:=Mm(T1);M2:=Mm(T2);
   If Abs(C.Lat1-C.Lat2)<1E-9Then N:=Sin(T1)
    Else N:=(Ln(M1)-Ln(M2))/(Ln(Tt(T1))-Ln(Tt(T2)));
   C.Z[4]:=N;
   C.Z[5]:=M1/(N*Exp(N*Ln(Tt(T1))));
   C.Z[6]:=A*C.Z[5]*Exp(N*Ln(Tt(Deg2Rad(C.Lat0))));
  End;
  KAea:Begin
   T1:=Deg2Rad(C.Lat1);T2:=Deg2Rad(C.Lat2);
   M1:=Mm(T1);M2:=Mm(T2);
   Q1:=Qq(T1);Q2:=Qq(T2);
   If Abs(C.Lat1-C.Lat2)<1E-9Then N:=Sin(T1)
    Else N:=(M1*M1-M2*M2)/(Q2-Q1);
   C.Z[4]:=N;
   C.Z[5]:=M1*M1+N*Q1;
   C.Z[6]:=A*Sqrt(C.Z[5]-N*Qq(Deg2Rad(C.Lat0)))/N;
  End;
  KLaea:Begin
   Ph:=Deg2Rad(C.Lat0);
   Qp:=Qq(Pi/2);Q0:=Qq(Ph);
   B0:=ArcSin(Q0/Qp);
   C.Z[4]:=Qp;C.Z[5]:=B0;
   C.Z[6]:=A*Sqrt(Qp/2);
   C.Z[7]:=A*Mm(Ph)/(C.Z[6]*Cos(B0));
  End;
  KPolar:Begin
   Ph:=Abs(Deg2Rad(C.Lat1));
   C.Z[4]:=Tt(Ph);
   C.Z[5]:=Mm(Ph);
  End;
 End;
End;

Function CrsFwd(Var C:TCrs;Lon,Lat:Real;Var X,Y:Real):Boolean;
Var
 A,E,E2,L,P,S,T,Xi,Eta,Rho,N,Th,Q,B,Bb,D,Cb,Sbb,K:Real;
 J:Integer;

 Function Tt(Ph:Real):Real;Begin
  Tt:=Tan2(Pi/4-Ph/2)/Exp(E/2*Ln((1-E*Sin(Ph))/(1+E*Sin(Ph))));
 End;
 Function Qq(Ph:Real):Real;
 Var Sp:Real;
 Begin
  Sp:=Sin(Ph);
  If E<1E-12Then Qq:=2*Sp
   Else Qq:=(1-E2)*(Sp/(1-E2*Sp*Sp)-(1/(2*E))*Ln((1-E*Sp)/(1+E*Sp)));
 End;

Begin
 CrsFwd:=True;
 A:=C.Z[1];E2:=C.Z[2];E:=C.Z[3];
 P:=Deg2Rad(Lat);
 L:=Deg2Rad(Lon-C.Lon0);
 While L>Pi do L:=L-2*Pi;
 While L<-Pi do L:=L+2*Pi;
 Case C.Kind of
  KGeo:Begin X:=Lon;Y:=Lat;End;
  KWeb:Begin
   If Abs(Lat)>=89.9999Then Begin CrsFwd:=False;Exit;End;
   X:=MercatorRadius*Deg2Rad(Lon);
   Y:=MercatorRadius*Ln(Tan2(Pi/4+P/2));
  End;
  KEqc:Begin X:=A*Deg2Rad(Lon-C.Lon0);Y:=A*P;End;
  KMerc:Begin
   If Abs(Lat)>=89.9999Then Begin CrsFwd:=False;Exit;End;
   X:=C.X0+A*C.K0*L;
   Y:=C.Y0+A*C.K0*Ln(Tan2(Pi/4+P/2)*Exp(E/2*Ln((1-E*Sin(P))/(1+E*Sin(P)))));
  End;
  KTm:Begin
   If Abs(L)>Pi/2*0.98Then Begin CrsFwd:=False;Exit;End;
   N:=C.Z[4];
   S:=Sin(P);
   T:=Sinh(Atanh(S)-(2*Sqrt(N)/(1+N))*Atanh((2*Sqrt(N)/(1+N))*S));
   Xi:=Atan2(T,Cos(L));
   Eta:=Atanh(Sin(L)/Sqrt(1+T*T));
   B:=Xi;D:=Eta;
   For J:=1 to 4do Begin
    B:=B+C.Z[5+J]*Sin(2*J*Xi)*Cosh(2*J*Eta);
    D:=D+C.Z[5+J]*Cos(2*J*Xi)*Sinh(2*J*Eta);
   End;
   X:=C.X0+C.K0*C.Z[5]*D;
   Y:=C.Y0+C.K0*(C.Z[5]*B-C.Z[18]);
  End;
  KLcc:Begin
   If Abs(Lat)>=89.9999Then Begin CrsFwd:=False;Exit;End;
   N:=C.Z[4];
   Rho:=A*C.Z[5]*Exp(N*Ln(Tt(P)));
   Th:=N*L;
   X:=C.X0+Rho*Sin(Th);
   Y:=C.Y0+C.Z[6]-Rho*Cos(Th);
  End;
  KAea:Begin
   N:=C.Z[4];
   Rho:=A*Sqrt(C.Z[5]-N*Qq(P))/N;
   Th:=N*L;
   X:=C.X0+Rho*Sin(Th);
   Y:=C.Y0+C.Z[6]-Rho*Cos(Th);
  End;
  KLaea:Begin
   Q:=Qq(P);
   Bb:=ArcSin(Q/C.Z[4]);
   Cb:=Cos(C.Z[5]);Sbb:=Sin(C.Z[5]);
   T:=1+Sbb*Sin(Bb)+Cb*Cos(Bb)*Cos(L);
   If T<1E-12Then Begin CrsFwd:=False;Exit;End;
   K:=C.Z[6]*Sqrt(2/T);
   X:=C.X0+K*C.Z[7]*Cos(Bb)*Sin(L);
   Y:=C.Y0+(K/C.Z[7])*(Cb*Sin(Bb)-Sbb*Cos(Bb)*Cos(L));
  End;
  KPolar:Begin
   If C.Lat1>=0Then Begin
    T:=Tt(P);
    Rho:=A*C.Z[5]*T/C.Z[4];
    X:=C.X0+Rho*Sin(L);
    Y:=C.Y0-Rho*Cos(L);
   End
    Else
   Begin
    T:=Tt(-P);
    Rho:=A*C.Z[5]*T/C.Z[4];
    X:=C.X0+Rho*Sin(L);
    Y:=C.Y0+Rho*Cos(L);
   End;
  End;
 End;
End;

Function CrsInv(Var C:TCrs;X,Y:Real;Var Lon,Lat:Real):Boolean;
Var
 A,E,E2,Xp,Yp,Xi,Eta,Rho,N,T,Ph,Chi,Th,Q,Rq,Cc,Bp,Dd,Sg:Real;
 J,It:Integer;

 Function PhiFromT(T:Real):Real;
 Var Pp:Real;I:Integer;
 Begin
  Pp:=Pi/2-2*ArcTan(T);
  For I:=1 to 12do Pp:=Pi/2-2*ArcTan(T*Exp(E/2*Ln((1-E*Sin(Pp))/(1+E*Sin(Pp)))));
  PhiFromT:=Pp;
 End;

Begin
 CrsInv:=True;
 A:=C.Z[1];E2:=C.Z[2];E:=C.Z[3];
 Case C.Kind of
  KGeo:Begin Lon:=X;Lat:=Y;End;
  KWeb:Begin
   Lon:=Rad2Deg(X/MercatorRadius);
   Lat:=Rad2Deg(2*ArcTan(Exp(Y/MercatorRadius))-Pi/2);
  End;
  KEqc:Begin Lon:=C.Lon0+Rad2Deg(X/A);Lat:=Rad2Deg(Y/A);End;
  KMerc:Begin
   T:=Exp(-(Y-C.Y0)/(A*C.K0));
   Lat:=Rad2Deg(PhiFromT(T));
   Lon:=C.Lon0+Rad2Deg((X-C.X0)/(A*C.K0));
  End;
  KTm:Begin
   Xi:=((Y-C.Y0)/C.K0+C.Z[18])/C.Z[5];
   Eta:=(X-C.X0)/(C.K0*C.Z[5]);
   Xp:=Xi;Yp:=Eta;
   For J:=1 to 4do Begin
    Xp:=Xp-C.Z[9+J]*Sin(2*J*Xi)*Cosh(2*J*Eta);
    Yp:=Yp-C.Z[9+J]*Cos(2*J*Xi)*Sinh(2*J*Eta);
   End;
   Chi:=ArcSin(Sin(Xp)/Cosh(Yp));
   Ph:=Chi;
   For J:=1 to 4do Ph:=Ph+C.Z[13+J]*Sin(2*J*Chi);
   Lat:=Rad2Deg(Ph);
   Lon:=C.Lon0+Rad2Deg(Atan2(Sinh(Yp),Cos(Xp)));
  End;
  KLcc:Begin
   N:=C.Z[4];
   Sg:=SgnR(N);
   Xp:=X-C.X0;Yp:=C.Z[6]-(Y-C.Y0);
   Rho:=Sg*Sqrt(Xp*Xp+Yp*Yp);
   If Rho=0Then Begin Lat:=Sg*90;Lon:=C.Lon0;Exit;End;
   T:=Exp(Ln(Rho/(A*C.Z[5]))/N);
   Th:=Atan2(Sg*Xp,Sg*Yp);
   Lat:=Rad2Deg(PhiFromT(T));
   Lon:=C.Lon0+Rad2Deg(Th/N);
  End;
  KAea:Begin
   N:=C.Z[4];
   Sg:=SgnR(N);
   Xp:=X-C.X0;Yp:=C.Z[6]-(Y-C.Y0);
   Rho:=Sg*Sqrt(Xp*Xp+Yp*Yp);
   Q:=(C.Z[5]-Sqr(Rho*N/A))/N;
   Th:=Atan2(Sg*Xp,Sg*Yp);
   If Abs(Q)>=1.99999999Then Ph:=SgnR(Q)*Pi/2
    Else Begin
     Ph:=ArcSin(Q/2);
     If E>1E-12Then
      For It:=1 to 25do
       Ph:=Ph+Sqr(1-E2*Sqr(Sin(Ph)))/(2*Cos(Ph))*(Q/(1-E2)-Sin(Ph)/(1-E2*Sqr(Sin(Ph)))+(1/(2*E))*Ln((1-E*Sin(Ph))/(1+E*Sin(Ph))));
    End;
   Lat:=Rad2Deg(Ph);
   Lon:=C.Lon0+Rad2Deg(Th/N);
  End;
  KLaea:Begin
   Xp:=X-C.X0;Yp:=Y-C.Y0;
   Dd:=C.Z[7];
   Rho:=Sqrt(Sqr(Xp/Dd)+Sqr(Dd*Yp));
   If Rho<1E-9Then Begin Lat:=C.Lat0;Lon:=C.Lon0;Exit;End;
   If Rho/(2*C.Z[6])>1Then Begin CrsInv:=False;Exit;End;
   Cc:=2*ArcSin(Rho/(2*C.Z[6]));
   Bp:=ArcSin(Cos(Cc)*Sin(C.Z[5])+Dd*Yp*Sin(Cc)*Cos(C.Z[5])/Rho);
   Lon:=C.Lon0+Rad2Deg(Atan2(Xp*Sin(Cc),Dd*Rho*Cos(C.Z[5])*Cos(Cc)-Dd*Dd*Yp*Sin(C.Z[5])*Sin(Cc)));
   Ph:=Bp+(E2/3+31*E2*E2/180+517*E2*E2*E2/5040)*Sin(2*Bp)+(23*E2*E2/360+251*E2*E2*E2/3780)*Sin(4*Bp)+(761*E2*E2*E2/45360)*Sin(6*Bp);
   Lat:=Rad2Deg(Ph);
  End;
  KPolar:Begin
   Xp:=X-C.X0;Yp:=Y-C.Y0;
   Rho:=Sqrt(Xp*Xp+Yp*Yp);
   T:=Rho*C.Z[4]/(A*C.Z[5]);
   Ph:=PhiFromT(T);
   If C.Lat1>=0Then Begin
    Lat:=Rad2Deg(Ph);
    Lon:=C.Lon0+Rad2Deg(Atan2(Xp,-Yp));
   End
    Else
   Begin
    Lat:=-Rad2Deg(Ph);
    Lon:=C.Lon0+Rad2Deg(Atan2(Xp,Yp));
   End;
  End;
 End;
 If(Lon<>Lon)or(Lat<>Lat)Then Begin CrsInv:=False;Exit;End;
 While Lon>180do Lon:=Lon-360;
 While Lon<-180do Lon:=Lon+360;
End;

{ Index d'un systeme en cache (prepare) ; 0 si le code est inconnu }
Function CrsSlot(Code:LongInt):Integer;
Var
 I:Integer;
Begin
 For I:=1 to 4do If CSlotUsed[I]and(CSlot[I].Code=Code)Then Begin CrsSlot:=I;Exit;End;
 Inc(CSlotNext);
 If CSlotNext>4Then CSlotNext:=1;
 If Not CrsDefine(Code,CSlot[CSlotNext])Then Begin
  CSlotUsed[CSlotNext]:=False;
  CrsSlot:=0;
  Exit;
 End;
 CrsPrep(CSlot[CSlotNext]);
 CSlotUsed[CSlotNext]:=True;
 CrsSlot:=CSlotNext;
End;

Function CrsKnown(Code:LongInt):Boolean;
Var
 C:TCrs;
Begin
 CrsKnown:=CrsDefine(Code,C);
End;

Function CrsIsGeographic(Code:LongInt):Boolean;
Var
 C:TCrs;
Begin
 CrsIsGeographic:=CrsDefine(Code,C)and(C.Kind=KGeo);
End;

{ Changement de datum par translation geocentrique : Dir=1 de C vers WGS84, Dir=-1 de WGS84 vers C }
Procedure DatumShift(Var C:TCrs;Dir:Integer;Var Lon,Lat:Real);
Var
 A1,F1,E1,A2,F2,E2,P,L,Nn,X,Y,Z,Pn,Lt,Xs,Rxx,Ryy,Rzz,Xn,Yn,Zn2:Real;
 It:Integer;
Begin
 If Dir=1Then Begin
  A1:=C.EA;F1:=1/C.EF;A2:=EllA[1];F2:=1/EllRf[1];
 End
  Else
 Begin
  A1:=EllA[1];F1:=1/EllRf[1];A2:=C.EA;F2:=1/C.EF;
 End;
 E1:=F1*(2-F1);E2:=F2*(2-F2);
 P:=Deg2Rad(Lat);L:=Deg2Rad(Lon);
 Nn:=A1/Sqrt(1-E1*Sqr(Sin(P)));
 X:=Nn*Cos(P)*Cos(L);
 Y:=Nn*Cos(P)*Sin(L);
 Z:=Nn*(1-E1)*Sin(P);
 Xs:=Dir*C.Sc;Rxx:=Dir*C.Rx;Ryy:=Dir*C.Ry;Rzz:=Dir*C.Rz;
 Xn:=Dir*C.Dx+(1+Xs)*(X-Rzz*Y+Ryy*Z);
 Yn:=Dir*C.Dy+(1+Xs)*(Rzz*X+Y-Rxx*Z);
 Zn2:=Dir*C.Dz+(1+Xs)*(-Ryy*X+Rxx*Y+Z);
 X:=Xn;Y:=Yn;Z:=Zn2;
 L:=Atan2(Y,X);
 Pn:=Sqrt(X*X+Y*Y);
 Lt:=ArcTan(Z/(Pn*(1-E2)));
 For It:=1 to 8do Begin
  Nn:=A2/Sqrt(1-E2*Sqr(Sin(Lt)));
  Lt:=ArcTan((Z+E2*Nn*Sin(Lt))/Pn);
 End;
 Lon:=Rad2Deg(L);Lat:=Rad2Deg(Lt);
End;

Function HasShift(Var C:TCrs):Boolean;Begin
 HasShift:=(C.Dx<>0)or(C.Dy<>0)or(C.Dz<>0)or(C.Sc<>0)or(C.Rx<>0)or(C.Ry<>0)or(C.Rz<>0);
End;

Function TryTransform(Src,Dst:LongInt;Var X,Y:Real):Boolean;
Var
 Si,Di:Integer;
 Lon,Lat:Real;
Begin
 TryTransform:=True;
 If Src=Dst Then Exit;
 If CrsSlot(Src)=0Then Fail('Error: unsupported CRS EPSG:'+IntToStr(Src));
 If CrsSlot(Dst)=0Then Fail('Error: unsupported CRS EPSG:'+IntToStr(Dst));
 Si:=CrsSlot(Src);
 Di:=CrsSlot(Dst);
 If Not CrsInv(CSlot[Si],X,Y,Lon,Lat)Then Begin TryTransform:=False;Exit;End;
 If HasShift(CSlot[Si])Then DatumShift(CSlot[Si],1,Lon,Lat);
 If HasShift(CSlot[Di])Then DatumShift(CSlot[Di],-1,Lon,Lat);
 If Not CrsFwd(CSlot[Di],Lon,Lat,X,Y)Then Begin TryTransform:=False;Exit;End;
End;

{ ---- chaines de definition : EPSG:n, urn, "+proj=..." ---- }

Function NextWord(Var S:String):String;
Var
 P:Integer;
Begin
 While(S<>'')and(S[1]=' ')do Delete(S,1,1);
 P:=Pos(' ',S);
 If P=0Then Begin NextWord:=S;S:='';End
       Else Begin NextWord:=Copy(S,1,P-1);S:=Copy(S,P+1,255);End;
End;

Function RegisterCustom(Var C:TCrs):LongInt;
Var
 I:Integer;
Begin
 For I:=1 to CustomN do
  If Custom[I].Proj=C.Proj Then Begin RegisterCustom:=CustomBase+I;Exit;End;
 If CustomN>=8Then Fail('Error: too many custom coordinate reference systems');
 Inc(CustomN);
 C.Code:=CustomBase+CustomN;
 Custom[CustomN]:=C;
 RegisterCustom:=C.Code;
End;

{ Retrouve un systeme connu (code EPSG) a partir de ses parametres geometriques }
Function SameCrs(Var A,B:TCrs):Boolean;
 Function Eq(X,Y,T:Real):Boolean;Begin Eq:=Abs(X-Y)<=T;End;
Begin
 SameCrs:=False;
 If A.Kind<>B.Kind Then Exit;
 If(Not Eq(A.EA,B.EA,1E-3))or(Not Eq(A.EF,B.EF,1E-7))Then Exit;
 Case A.Kind of
  KGeo:SameCrs:=True;
  KWeb,KEqc:SameCrs:=Eq(A.Lon0,B.Lon0,1E-9);
  KTm:SameCrs:=Eq(A.Lon0,B.Lon0,1E-7)and Eq(A.Lat0,B.Lat0,1E-7)and Eq(A.K0,B.K0,1E-8)and Eq(A.X0,B.X0,1E-3)and Eq(A.Y0,B.Y0,1E-3);
  KMerc:SameCrs:=Eq(A.Lon0,B.Lon0,1E-7)and Eq(A.K0,B.K0,1E-8)and Eq(A.X0,B.X0,1E-3)and Eq(A.Y0,B.Y0,1E-3);
  KLcc,KAea:SameCrs:=Eq(A.Lon0,B.Lon0,1E-6)and Eq(A.Lat0,B.Lat0,1E-6)and Eq(A.Lat1,B.Lat1,1E-6)and Eq(A.Lat2,B.Lat2,1E-6)and Eq(A.X0,B.X0,1E-3)and Eq(A.Y0,B.Y0,1E-3);
  KLaea:SameCrs:=Eq(A.Lon0,B.Lon0,1E-6)and Eq(A.Lat0,B.Lat0,1E-6)and Eq(A.X0,B.X0,1E-3)and Eq(A.Y0,B.Y0,1E-3);
  KPolar:SameCrs:=Eq(A.Lon0,B.Lon0,1E-6)and Eq(A.Lat1,B.Lat1,1E-6)and(A.Lat0*B.Lat0>0)and Eq(A.X0,B.X0,1E-3)and Eq(A.Y0,B.Y0,1E-3);
 End;
End;

Function MatchKnown(Var C:TCrs):LongInt;
Const
 Cand:Array[1..23]of LongInt=(3395,27700,2154,3035,5070,3347,3978,32198,3005,3413,3031,2193,3112,31466,31467,31468,31469,3067,3006,3059,32181,32182,4087);
Var
 T:TCrs;
 I,Zn:Integer;

 Function Try(Code:LongInt):Boolean;Begin
  Try:=CrsDefine(Code,T)and SameCrs(C,T);
 End;

Begin
 MatchKnown:=0;
 For I:=1 to 23do If Try(Cand[I])Then Begin MatchKnown:=Cand[I];Exit;End;
 For Zn:=1 to 60do Begin
  If Try(32600+Zn)Then Begin MatchKnown:=32600+Zn;Exit;End;
  If Try(32700+Zn)Then Begin MatchKnown:=32700+Zn;Exit;End;
 End;
 For Zn:=1 to 23do If Try(26900+Zn)Then Begin MatchKnown:=26900+Zn;Exit;End;
 For Zn:=3 to 22do If Try(26700+Zn)Then Begin MatchKnown:=26700+Zn;Exit;End;
 For Zn:=28 to 38do Begin
  If Try(25800+Zn)Then Begin MatchKnown:=25800+Zn;Exit;End;
  If Try(23000+Zn)Then Begin MatchKnown:=23000+Zn;Exit;End;
 End;
 For Zn:=3 to 10do If Try(32180+Zn)Then Begin MatchKnown:=32180+Zn;Exit;End;
 If Try(4326)Then Begin MatchKnown:=4326;Exit;End;
End;

{ "+proj=utm +zone=33 +datum=WGS84" -> code (0 si non gere) }
Function ParseProj(S:String):LongInt;
Var
 W,K,V,Prj,Datum,Ell:String;
 P,Err,Zn,E:Integer;
 C:TCrs;
 Val1:Real;
 Lon0,Lat0,Lat1,Lat2,K0,X0,Y0,A,B,Rf,Dx,Dy,Dz,Rx0,Ry0,Rz0,Sc0:Real;
 South,HaveA,HaveB,HaveRf:Boolean;
 Orig:String;
Begin
 ParseProj:=0;
 Orig:=S;
 Prj:='';Datum:='';Ell:='';Zn:=0;South:=False;
 Lon0:=0;Lat0:=0;Lat1:=0;Lat2:=0;K0:=1;X0:=0;Y0:=0;A:=0;B:=0;Rf:=0;Dx:=0;Dy:=0;Dz:=0;Rx0:=0;Ry0:=0;Rz0:=0;Sc0:=0;
 HaveA:=False;HaveB:=False;HaveRf:=False;
 While S<>''do Begin
  W:=NextWord(S);
  If W=''Then Continue;
  If W[1]='+'Then Delete(W,1,1);
  P:=Pos('=',W);
  If P=0Then Begin
   If LowerStr(W)='south'Then South:=True;
   Continue;
  End;
  K:=LowerStr(Copy(W,1,P-1));
  V:=Copy(W,P+1,100);
  Val(V,Val1,Err);
  If K='proj'Then Prj:=LowerStr(V) Else
  If K='zone'Then Zn:=Round(Val1) Else
  If K='ellps'Then Ell:=LowerStr(V) Else
  If K='datum'Then Datum:=LowerStr(V) Else
  If K='lon_0'Then Lon0:=Val1 Else
  If K='lat_0'Then Lat0:=Val1 Else
  If K='lat_1'Then Lat1:=Val1 Else
  If K='lat_2'Then Lat2:=Val1 Else
  If K='lat_ts'Then Lat1:=Val1 Else
  If(K='k')or(K='k_0')Then K0:=Val1 Else
  If K='x_0'Then X0:=Val1 Else
  If K='y_0'Then Y0:=Val1 Else
  If K='a'Then Begin A:=Val1;HaveA:=True;End Else
  If K='b'Then Begin B:=Val1;HaveB:=True;End Else
  If K='rf'Then Begin Rf:=Val1;HaveRf:=True;End Else
  If K='towgs84'Then Begin
   P:=Pos(',',V);
   If P>0Then Begin Val(Copy(V,1,P-1),Dx,Err);V:=Copy(V,P+1,100);End;
   P:=Pos(',',V);
   If P>0Then Begin Val(Copy(V,1,P-1),Dy,Err);V:=Copy(V,P+1,100);End;
   P:=Pos(',',V);
   If P>0Then Begin
    Val(Copy(V,1,P-1),Dz,Err);V:=Copy(V,P+1,100);
    P:=Pos(',',V);
    If P>0Then Begin Val(Copy(V,1,P-1),Rx0,Err);V:=Copy(V,P+1,100);End;
    P:=Pos(',',V);
    If P>0Then Begin Val(Copy(V,1,P-1),Ry0,Err);V:=Copy(V,P+1,100);End;
    P:=Pos(',',V);
    If P>0Then Begin Val(Copy(V,1,P-1),Rz0,Err);V:=Copy(V,P+1,100);End;
    Val(V,Sc0,Err);
   End
    Else Val(V,Dz,Err);
  End Else
  If(K='units')and(LowerStr(V)<>'m')Then Fail('Error: only metre-based PROJ definitions are supported') Else
  If(K='to_meter')and(Val1<>1)Then Fail('Error: only metre-based PROJ definitions are supported');
 End;
 FillChar(C,SizeOf(C),0);
 E:=1;
 If Datum='nad83'Then E:=2 Else
 If Datum='nad27'Then Begin E:=3;Dx:=-8;Dy:=160;Dz:=176;End Else
 If Datum='ed50'Then Begin E:=4;Dx:=-87;Dy:=-98;Dz:=-121;End Else
 If Datum='osgb36'Then Begin E:=6;Dx:=375;Dy:=-111;Dz:=431;End Else
 If Datum='etrs89'Then E:=2;
 If Ell='grs80'Then E:=2 Else
 If Ell='clrk66'Then E:=3 Else
 If Ell='intl'Then E:=4 Else
 If Ell='bessel'Then E:=5 Else
 If Ell='airy'Then E:=6 Else
 If Ell='sphere'Then E:=7 Else
 If Ell='krass'Then E:=8 Else
 If Ell='clrk80ign'Then E:=9;
 C.Ell:=E;
 C.EA:=EllA[E];C.EF:=EllRf[E];
 If HaveA Then Begin
  C.Ell:=1;C.EA:=A;
  If HaveRf Then C.EF:=Rf Else
  If HaveB Then Begin
   If Abs(A-B)<1E-9Then C.EF:=0 Else C.EF:=A/(A-B);
  End;
 End;
 If Prj='longlat'Then Begin C.Kind:=KGeo;End Else
 If Prj='latlong'Then Begin C.Kind:=KGeo;End Else
 If Prj='utm'Then Begin
  If(Zn<1)or(Zn>60)Then Fail('Error: invalid UTM zone in "'+Orig+'"');
  C.Kind:=KTm;C.Lon0:=Zn*6-183;C.K0:=0.9996;C.X0:=500000;
  If South Then C.Y0:=10000000;
 End Else
 If(Prj='tmerc')or(Prj='etmerc')Then Begin C.Kind:=KTm;C.Lon0:=Lon0;C.Lat0:=Lat0;C.K0:=K0;C.X0:=X0;C.Y0:=Y0;End Else
 If Prj='lcc'Then Begin
  C.Kind:=KLcc;C.Lon0:=Lon0;C.Lat0:=Lat0;C.Lat1:=Lat1;C.Lat2:=Lat2;
  If Lat2=0Then C.Lat2:=Lat1;
  C.X0:=X0;C.Y0:=Y0;C.K0:=1;
 End Else
 If Prj='aea'Then Begin
  C.Kind:=KAea;C.Lon0:=Lon0;C.Lat0:=Lat0;C.Lat1:=Lat1;C.Lat2:=Lat2;
  If Lat2=0Then C.Lat2:=Lat1;
  C.X0:=X0;C.Y0:=Y0;C.K0:=1;
 End Else
 If Prj='merc'Then Begin
  If(HaveA and HaveB and(Abs(A-B)<1E-6))or(Ell='sphere')Then Begin C.Kind:=KWeb;C.Ell:=1;C.EA:=EllA[1];C.EF:=EllRf[1];End
   Else Begin C.Kind:=KMerc;C.Lon0:=Lon0;C.K0:=K0;C.X0:=X0;C.Y0:=Y0;End;
 End Else
 If Prj='laea'Then Begin C.Kind:=KLaea;C.Lon0:=Lon0;C.Lat0:=Lat0;C.X0:=X0;C.Y0:=Y0;C.K0:=1;End Else
 If Prj='stere'Then Begin
  If Abs(Lat0)<>90Then Fail('Error: only polar stereographic projections are supported');
  C.Kind:=KPolar;C.Lon0:=Lon0;C.Lat0:=Lat0;C.Lat1:=Lat1;
  If Lat1=0Then C.Lat1:=Lat0;
  C.X0:=X0;C.Y0:=Y0;C.K0:=1;
 End Else
 If(Prj='eqc')or(Prj='cea')and False Then Begin C.Kind:=KEqc;C.Lon0:=Lon0;End
  Else
 Begin
  Fail('Error: unsupported projection "'+Prj+'" in "'+Orig+'"');
 End;
 C.Dx:=Dx;C.Dy:=Dy;C.Dz:=Dz;
 CrsRot(C,Rx0,Ry0,Rz0,Sc0);
 Zn:=MatchKnown(C);
 If Zn>0Then Begin ParseProj:=Zn;Exit;End;
 C.Proj:=Copy(Orig,1,120);
 C.Name:='PROJ';
 ParseProj:=RegisterCustom(C);
End;

{ EPSG:n, urn:ogc:def:crs:EPSG::n, OGC:CRS84, +proj=... ; Faux si invalide ou non gere }
Function ParseCrsName(S:String;Var Code:LongInt):Boolean;
Var
 U,T:String;
 I,P,Err:Integer;
 N:LongInt;
Begin
 ParseCrsName:=False;
 Code:=0;
 While(S<>'')and(S[1]=' ')do Delete(S,1,1);
 While(S<>'')and(S[Length(S)]=' ')do Delete(S,Length(S),1);
 U:=StrUpper(S);
 If Pos('+PROJ=',U)>0Then Begin
  Code:=ParseProj(S);
  ParseCrsName:=Code<>0;
  Exit;
 End;
 If(U='OGC:CRS84')or(Pos('CRS84',U)>0)or(U='WGS84')Then Begin Code:=4326;ParseCrsName:=True;Exit;End;
 If(Copy(U,1,5)='EPSG:')or(Copy(U,1,4)='URN:')or(Copy(U,1,5)='http:')Then Begin
  P:=0;
  For I:=Length(U)downto 1do If U[I]in[':','/']Then Begin P:=I;Break;End;
  T:=Copy(U,P+1,12);
 End
  Else
 T:=U;
 Val(T,N,Err);
 If(Err<>0)or(N<=0)Then Exit;
 If Not CrsKnown(N)Then Exit;
 If N=900913Then N:=3857;
 Code:=N;
 ParseCrsName:=True;
End;

Function ParseEpsg(S,What:String):LongInt;
Var
 N:LongInt;
Begin
 If ParseCrsName(S,N)Then Begin ParseEpsg:=N;Exit;End;
 Fail('Error: unsupported '+What+' '+S+' (use EPSG:code for a common projection, or a "+proj=..." definition)');
End;

{ Nom (EPSG:n ou chaine PROJ) a ecrire dans le membre "crs" d'un fichier GeoJSON }
Function CrsLabel(Code:LongInt):String;
Var
 C:TCrs;
Begin
 If(Code>CustomBase)and(CrsDefine(Code,C))Then CrsLabel:=C.Proj
  Else CrsLabel:='urn:ogc:def:crs:EPSG::'+IntToStr(Code);
End;

Function TransformOk(Src,Dst:LongInt;Var X,Y:Real):Boolean;Begin
 TransformOk:=TryTransform(Src,Dst,X,Y);
End;

Procedure TransformPt(Src,Dst:LongInt;Var X,Y:Real);Begin
 If Not TryTransform(Src,Dst,X,Y)Then
  Fail('Error: coordinates out of the domain of the coordinate reference system');
End;

{ Systeme de coordonnees declare dans un fichier GeoJSON (defaut 4326) ; 0 si non gere }
Function SoftCrs(Root:PJ):LongInt;
Var
 C,P:PJ;
 N:LongInt;
Begin
 SoftCrs:=4326;
 C:=JFind(Root,'crs');
 If C=Nil Then Exit;
 P:=JFind(JFind(C,'properties'),'name');
 If ParseCrsName(JVal(P),N)Then SoftCrs:=N
                           Else SoftCrs:=0;
End;

Function LayerCrs(Root:PJ):LongInt;
Var
 C,P:PJ;
 N:LongInt;
Begin
 N:=SoftCrs(Root);
 LayerCrs:=N;
 If N=0Then Begin
  C:=JFind(Root,'crs');
  P:=JFind(JFind(C,'properties'),'name');
  Fail('Error: unsupported layer CRS '+JVal(P));
 End;
End;

Procedure SetLayerCrs(Root:PJ;Epsg:LongInt);
Var
 C,P:PJ;
Begin
 JRemoveKey(Root,'crs');
 If Epsg<>4326Then Begin
  C:=NewJ(5);
  JAddKV(C,'type',JText('name'));
  P:=NewJ(5);
  JAddKV(P,'name',JText(CrsLabel(Epsg)));
  JAddKV(C,'properties',P);
  JAddKV(Root,'crs',C);
 End;
End;

{ Transforme en place tous les couples de coordonnees d'une geometrie }
Procedure TransformCoords(N:PJ;Src,Dst:LongInt);
Var
 C:PJ;
 X,Y:Real;
 E:Integer;
Begin
 If(N=Nil)or(N^.Kind<>4)Then Exit;
 C:=N^.First;
 If C=Nil Then Exit;
 If C^.Kind=2Then Begin
  If C^.Next=Nil Then Fail('Error: invalid coordinates');
  Val(JVal(C),X,E);
  If E<>0Then Fail('Error: invalid coordinate');
  Val(JVal(C^.Next),Y,E);
  If E<>0Then Fail('Error: invalid coordinate');
  TransformPt(Src,Dst,X,Y);
  C^.Val:=MkStr(NumStr(X));
  C^.Next^.Val:=MkStr(NumStr(Y));
 End
  Else
 While C<>Nil do Begin
  TransformCoords(C,Src,Dst);
  C:=C^.Next;
 End;
End;

{ ------------------------------------------------------------------ }
{ Geometries                                                          }
{ ------------------------------------------------------------------ }

Procedure InitGeom(Var G:TGeom);Begin
 G.Cls:=0;G.First:=Nil;G.Last:=Nil;G.Count:=0;G.NPoly:=0;
End;

Function NewPath(Var G:TGeom;N:LongInt;Poly:Integer):PPath;
Var
 P:PPath;
Begin
 New(P);
 If N<1Then N:=1;
 P^.Pts:=AllocBlock(N*SizeOf(TPt));
 P^.N:=N;P^.Poly:=Poly;P^.Area:=0;P^.Next:=Nil;
 If G.Last=Nil Then G.First:=P
               Else G.Last^.Next:=P;
 G.Last:=P;
 Inc(G.Count);
 NewPath:=P;
End;

Procedure LinkPath(Var G:TGeom;P:PPath);Begin
 P^.Next:=Nil;
 If G.Last=Nil Then G.First:=P
               Else G.Last^.Next:=P;
 G.Last:=P;
 Inc(G.Count);
End;

Procedure FreeGeom(Var G:TGeom);
Var
 P,Q:PPath;
Begin
 P:=G.First;
 While P<>Nil do Begin
  Q:=P^.Next;
  FreeMem(P^.Pts,P^.N*SizeOf(TPt));
  Dispose(P);
  P:=Q;
 End;
 InitGeom(G);
End;

Function CopyPath(Var G:TGeom;S:PPath;Poly:Integer):PPath;
Var
 P:PPath;
Begin
 P:=NewPath(G,S^.N,Poly);
 Move(S^.Pts^,P^.Pts^,S^.N*SizeOf(TPt));
 CopyPath:=P;
End;

Function NumOf(P:PJ):Real;
Var
 R:Real;
 E:Integer;
Begin
 Val(JVal(P),R,E);
 If E<>0Then Fail('Error: invalid coordinate');
 NumOf:=R;
End;

Procedure AddPathFrom(Var G:TGeom;Arr:PJ;Poly:Integer);
Var
 N,I:LongInt;
 C:PJ;
 P:PPath;
Begin
 If Arr^.Kind<>4Then Fail('Error: invalid coordinates');
 N:=0;
 C:=Arr^.First;
 While C<>Nil do Begin Inc(N);C:=C^.Next;End;
 P:=NewPath(G,N,Poly);
 P^.N:=N;
 C:=Arr^.First;
 I:=0;
 While C<>Nil do Begin
  If(C^.Kind<>4)or(C^.First=Nil)or(C^.First^.Next=Nil)Then Fail('Error: invalid coordinates');
  P^.Pts^[I].X:=NumOf(C^.First);
  P^.Pts^[I].Y:=NumOf(C^.First^.Next);
  Inc(I);
  C:=C^.Next;
 End;
End;

Procedure AddPointFrom(Var G:TGeom;Co:PJ);
Var
 P:PPath;
Begin
 If(Co^.Kind<>4)or(Co^.First=Nil)or(Co^.First^.Next=Nil)Then Exit;
 P:=NewPath(G,1,0);
 P^.Pts^[0].X:=NumOf(Co^.First);
 P^.Pts^[0].Y:=NumOf(Co^.First^.Next);
End;

{ Aplatit une geometrie GeoJSON en liste de chemins }
Procedure Flatten(Geom:PJ;Var G:TGeom);
Var
 T:String;
 Co,C,R:PJ;
Begin
 InitGeom(G);
 If(Geom=Nil)or(Geom^.Kind<>5)Then Exit;
 T:=JVal(JFind(Geom,'type'));
 If T='GeometryCollection'Then Fail('Error: GeometryCollection is not supported');
 Co:=JFind(Geom,'coordinates');
 If(Co=Nil)or(Co^.Kind<>4)Then Exit;
 If T='Point'Then Begin
  G.Cls:=1;
  AddPointFrom(G,Co);
 End
  Else
 If T='MultiPoint'Then Begin
  G.Cls:=1;
  C:=Co^.First;
  While C<>Nil do Begin AddPointFrom(G,C);C:=C^.Next;End;
 End
  Else
 If T='LineString'Then Begin
  G.Cls:=2;
  AddPathFrom(G,Co,0);
 End
  Else
 If T='MultiLineString'Then Begin
  G.Cls:=2;
  C:=Co^.First;
  While C<>Nil do Begin AddPathFrom(G,C,0);C:=C^.Next;End;
 End
  Else
 If T='Polygon'Then Begin
  G.Cls:=3;
  C:=Co^.First;
  While C<>Nil do Begin AddPathFrom(G,C,0);C:=C^.Next;End;
  G.NPoly:=1;
 End
  Else
 If T='MultiPolygon'Then Begin
  G.Cls:=3;
  R:=Co^.First;
  While R<>Nil do Begin
   C:=R^.First;
   While C<>Nil do Begin AddPathFrom(G,C,G.NPoly);C:=C^.Next;End;
   Inc(G.NPoly);
   R:=R^.Next;
  End;
 End
  Else
 Fail('Error: unsupported geometry type '+T);
End;

Function CoordNode(X,Y:Real):PJ;
Var
 N:PJ;
Begin
 N:=NewJ(4);
 JAdd(N,JNum(X));
 JAdd(N,JNum(Y));
 CoordNode:=N;
End;

Function PathNode(P:PPath;Closed:Boolean):PJ;
Var
 N:PJ;
 I:LongInt;
Begin
 N:=NewJ(4);
 For I:=0 to P^.N-1do JAdd(N,CoordNode(P^.Pts^[I].X,P^.Pts^[I].Y));
 If Closed and((P^.Pts^[0].X<>P^.Pts^[P^.N-1].X)or(P^.Pts^[0].Y<>P^.Pts^[P^.N-1].Y))Then
  JAdd(N,CoordNode(P^.Pts^[0].X,P^.Pts^[0].Y));
 PathNode:=N;
End;

Function GeomNode(T:String;Co:PJ):PJ;
Var
 N:PJ;
Begin
 N:=NewJ(5);
 JAddKV(N,'type',JText(T));
 JAddKV(N,'coordinates',Co);
 GeomNode:=N;
End;

{ Construit Polygon ou MultiPolygon (Nil si vide) }
Function BuildPolygons(Var G:TGeom):PJ;
Var
 P:PPath;
 Last,NP:Integer;
 Multi,Cur:PJ;
Begin
 BuildPolygons:=Nil;
 If G.First=Nil Then Exit;
 Multi:=NewJ(4);
 Cur:=Nil;NP:=0;Last:=-1;
 P:=G.First;
 While P<>Nil do Begin
  If(Cur=Nil)or(P^.Poly<>Last)Then Begin
   Cur:=NewJ(4);
   JAdd(Multi,Cur);
   Inc(NP);
   Last:=P^.Poly;
  End;
  JAdd(Cur,PathNode(P,True));
  P:=P^.Next;
 End;
 If NP=1Then BuildPolygons:=GeomNode('Polygon',Multi^.First)
        Else BuildPolygons:=GeomNode('MultiPolygon',Multi);
End;

Function BuildLines(Var G:TGeom):PJ;
Var
 P:PPath;
 Multi:PJ;
Begin
 BuildLines:=Nil;
 If G.First=Nil Then Exit;
 If G.Count=1Then BuildLines:=GeomNode('LineString',PathNode(G.First,False))
  Else
 Begin
  Multi:=NewJ(4);
  P:=G.First;
  While P<>Nil do Begin
   JAdd(Multi,PathNode(P,False));
   P:=P^.Next;
  End;
  BuildLines:=GeomNode('MultiLineString',Multi);
 End;
End;

Function BuildPoints(Var G:TGeom):PJ;
Var
 P:PPath;
 Multi:PJ;
Begin
 BuildPoints:=Nil;
 If G.First=Nil Then Exit;
 If G.Count=1Then BuildPoints:=GeomNode('Point',CoordNode(G.First^.Pts^[0].X,G.First^.Pts^[0].Y))
  Else
 Begin
  Multi:=NewJ(4);
  P:=G.First;
  While P<>Nil do Begin
   JAdd(Multi,CoordNode(P^.Pts^[0].X,P^.Pts^[0].Y));
   P:=P^.Next;
  End;
  BuildPoints:=GeomNode('MultiPoint',Multi);
 End;
End;

{ Aire signee d'un anneau (positive = sens anti-horaire) }
Function RingArea(P:PPath):Real;
Var
 I,J:LongInt;
 S,Ox,Oy:Real;
Begin
 Ox:=P^.Pts^[0].X;Oy:=P^.Pts^[0].Y;
 S:=0;
 For I:=0 to P^.N-1do Begin
  J:=I+1;
  If J>=P^.N Then J:=0;
  S:=S+(P^.Pts^[I].X-Ox)*(P^.Pts^[J].Y-Oy)-(P^.Pts^[J].X-Ox)*(P^.Pts^[I].Y-Oy);
 End;
 RingArea:=S/2;
End;

{ Etat d'un point par rapport a un anneau : 0 dehors, 1 dedans, 2 sur le bord }
Function PointInRing(P:PPath;X,Y,Tol:Real):Integer;
Var
 I,J:LongInt;
 Xi,Yi,Xj,Yj,Cr,L:Real;
 Inside:Boolean;
Begin
 Inside:=False;
 For I:=0 to P^.N-1do Begin
  J:=I+1;
  If J>=P^.N Then J:=0;
  Xi:=P^.Pts^[I].X;Yi:=P^.Pts^[I].Y;
  Xj:=P^.Pts^[J].X;Yj:=P^.Pts^[J].Y;
  L:=Sqrt(Sqr(Xj-Xi)+Sqr(Yj-Yi));
  If L>0Then Begin
   Cr:=((Xj-Xi)*(Y-Yi)-(X-Xi)*(Yj-Yi))/L;
   If(Abs(Cr)<=Tol)and(X>=MinR(Xi,Xj)-Tol)and(X<=MaxR(Xi,Xj)+Tol)and
     (Y>=MinR(Yi,Yj)-Tol)and(Y<=MaxR(Yi,Yj)+Tol)Then Begin
    PointInRing:=2;
    Exit;
   End;
  End;
  If((Yi>Y)<>(Yj>Y))and(X<(Xj-Xi)*(Y-Yi)/(Yj-Yi)+Xi)Then Inside:=Not Inside;
 End;
 If Inside Then PointInRing:=1 Else PointInRing:=0;
End;

{ ------------------------------------------------------------------ }
{ Tri d'index                                                         }
{ ------------------------------------------------------------------ }

Var
 SB:PEdges;
 SP:PPts;
 SLab:PLongs;
 SAng:PReals;
 SKey,SStrv:PStrs;
 SNum:PReals;
 SKind:PBytes;
 SAsc,SNullFirst,SNoTie:Boolean;
 SMode:Integer;

Function CmpR(A,B:Real):Integer;Begin
 If A<B Then CmpR:=-1 Else
 If A>B Then CmpR:=1
        Else CmpR:=0;
End;

Function CmpIdx(A,B:LongInt):Integer;
Var
 C:Integer;
Begin
 C:=0;
 Case SMode of
  0:Begin
   C:=CmpR(SB^[A].X1,SB^[B].X1);
   If C=0Then C:=CmpR(SB^[A].Y1,SB^[B].Y1);
   If C=0Then C:=CmpR(SB^[A].X2,SB^[B].X2);
   If C=0Then C:=CmpR(SB^[A].Y2,SB^[B].Y2);
  End;
  1:Begin
   C:=CmpR(SP^[A].X,SP^[B].X);
   If C=0Then C:=CmpR(SP^[A].Y,SP^[B].Y);
  End;
  2:Begin
   C:=CmpR(SB^[A].X1,SB^[B].X1);
   If C=0Then C:=CmpR(SB^[A].Y1,SB^[B].Y1);
  End;
  3:C:=CmpR(SB^[A].X1,SB^[B].X1);
  6:Begin
   If SLab^[A]<SLab^[B]Then C:=-1 Else
   If SLab^[A]>SLab^[B]Then C:=1 Else C:=CmpR(SAng^[A],SAng^[B]);
  End;
  7:Begin
   If SKey<>Nil Then Begin
    If SKey^[A]^<SKey^[B]^Then C:=-1 Else
    If SKey^[A]^>SKey^[B]^Then C:=1;
   End;
   If C=0Then Begin
    If(SKind^[A]=0)and(SKind^[B]=0)Then C:=0 Else
    If SKind^[A]=0Then Begin If SNullFirst Then C:=-1 Else C:=1;End Else
    If SKind^[B]=0Then Begin If SNullFirst Then C:=1 Else C:=-1;End
     Else
    Begin
     If(SKind^[A]=1)and(SKind^[B]=1)Then C:=CmpR(SNum^[A],SNum^[B])
      Else
     If SStrv^[A]^<SStrv^[B]^Then C:=-1 Else
     If SStrv^[A]^>SStrv^[B]^Then C:=1 Else C:=0;
     If Not SAsc Then C:=-C;
    End;
   End;
   If(C=0)and Not SNoTie Then Begin
    If A<B Then C:=-1 Else If A>B Then C:=1;
   End;
  End;
  5:Begin
   If SLab^[A]<SLab^[B]Then C:=-1 Else
   If SLab^[A]>SLab^[B]Then C:=1 Else
   If A<B Then C:=-1 Else
   If A>B Then C:=1 Else C:=0;
  End;
  4:Begin
   If SLab^[A]<SLab^[B]Then C:=-1 Else
   If SLab^[A]>SLab^[B]Then C:=1 Else Begin
    C:=CmpR(SB^[A].X1,SB^[B].X1);
    If C=0Then C:=CmpR(SB^[A].Y1,SB^[B].Y1);
   End;
  End;
 End;
 CmpIdx:=C;
End;

Procedure SortIdx(Idx:PLongs;Lo,Hi:LongInt);
Var
 I,J,Pv,T:LongInt;
Begin
 While Lo<Hi do Begin
  Pv:=Idx^[(Lo+Hi)div 2];
  I:=Lo;J:=Hi;
  Repeat
   While CmpIdx(Idx^[I],Pv)<0do Inc(I);
   While CmpIdx(Idx^[J],Pv)>0do Dec(J);
   If I<=J Then Begin
    T:=Idx^[I];Idx^[I]:=Idx^[J];Idx^[J]:=T;
    Inc(I);Dec(J);
   End;
  Until I>J;
  If J-Lo<Hi-I Then Begin
   SortIdx(Idx,Lo,J);
   Lo:=I;
  End
   Else
  Begin
   SortIdx(Idx,I,Hi);
   Hi:=J;
  End;
 End;
End;

{ ------------------------------------------------------------------ }
{ Moteur de superposition de polygones (union, intersection, difference) }
{ Principe : decoupage de toutes les aretes a leurs intersections, puis  }
{ conservation des segments qui separent l'interieur de l'exterieur du   }
{ resultat (regle du nombre d'enroulement non nul), puis reassemblage    }
{ en anneaux.                                                            }
{ ------------------------------------------------------------------ }

Var
 SnapQ,OvEps:Real;
 OvAll,OvBox:PEdges;
 OvSp:PSplitArr;
 OvTot:LongInt;
 KeepOrient:Boolean;   { Vrai : conserve le sens des anneaux fournis }
 ClipOutside:Boolean;  { Vrai : ClipLines/ClipToPolys gardent l'exterieur }
 SlabN:LongInt;
 SlabMin,SlabH:Real;
 SlabStart,SlabEdge:PLongs;
 OvNA:LongInt;

Function Snap(V:Real):Real;Begin
 If SnapQ>0Then Snap:=FloorR(V/SnapQ+0.5)*SnapQ
           Else Snap:=V;
End;

Function EdgeCount(Var G:TGeom):LongInt;
Var
 P:PPath;
 N:LongInt;
Begin
 N:=0;
 P:=G.First;
 While P<>Nil do Begin Inc(N,P^.N);P:=P^.Next;End;
 EdgeCount:=N;
End;

{ Ajoute les aretes des anneaux de G (exterieurs anti-horaires, trous horaires) }
Procedure FillEdges(Var G:TGeom;E:PEdges;Var N:LongInt);
Var
 P:PPath;
 I,J:LongInt;
 Prev:Integer;
 Rev:Boolean;
 A:Real;
 X1,Y1,X2,Y2:Real;
Begin
 Prev:=-1;
 P:=G.First;
 While P<>Nil do Begin
  A:=RingArea(P);
  If KeepOrient Then Rev:=False Else
  If P^.Poly<>Prev Then Rev:=A<0
                   Else Rev:=A>0;
  Prev:=P^.Poly;
  For I:=0 to P^.N-1do Begin
   J:=I+1;
   If J>=P^.N Then J:=0;
   X1:=Snap(P^.Pts^[I].X);Y1:=Snap(P^.Pts^[I].Y);
   X2:=Snap(P^.Pts^[J].X);Y2:=Snap(P^.Pts^[J].Y);
   If Rev Then Begin
    E^[N].X1:=X2;E^[N].Y1:=Y2;E^[N].X2:=X1;E^[N].Y2:=Y1;
   End
    Else
   Begin
    E^[N].X1:=X1;E^[N].Y1:=Y1;E^[N].X2:=X2;E^[N].Y2:=Y2;
   End;
   If(X1<>X2)or(Y1<>Y2)Then Inc(N);
  End;
  P:=P^.Next;
 End;
End;

Function Winding(E:PEdges;N:LongInt;QX,QY:Real):LongInt;
Var
 I,W:LongInt;
 L:Real;
Begin
 W:=0;
 For I:=0 to N-1do With E^[I]do Begin
  If Y1<=QY Then Begin
   If Y2>QY Then Begin
    L:=(X2-X1)*(QY-Y1)-(QX-X1)*(Y2-Y1);
    If L>0Then Inc(W);
   End;
  End
   Else
  If Y2<=QY Then Begin
   L:=(X2-X1)*(QY-Y1)-(QX-X1)*(Y2-Y1);
   If L<0Then Dec(W);
  End;
 End;
 Winding:=W;
End;

Function SlabOf(Y:Real):LongInt;
Var
 K:LongInt;
Begin
 K:=FloorL((Y-SlabMin)/SlabH);
 If K<0Then K:=0;
 If K>=SlabN Then K:=SlabN-1;
 SlabOf:=K;
End;

{ Index des aretes par tranches horizontales, pour accelerer les nombres d'enroulement }
Procedure BuildSlabs(NT:LongInt;MinY,MaxY:Real);
Var
 I,K,S0,S1:LongInt;
 Fill:PLongs;
Begin
 SlabN:=NT div 4+1;
 If SlabN>4096Then SlabN:=4096;
 SlabMin:=MinY;
 SlabH:=(MaxY-MinY)/SlabN;
 If SlabH<=0Then SlabH:=1;
 SlabStart:=AllocBlock((SlabN+2)*SizeOf(LongInt));
 Fill:=AllocBlock((SlabN+2)*SizeOf(LongInt));
 For K:=0 to SlabN+1do Begin SlabStart^[K]:=0;Fill^[K]:=0;End;
 For I:=0 to NT-1do Begin
  S0:=SlabOf(OvBox^[I].Y1);S1:=SlabOf(OvBox^[I].Y2);
  For K:=S0 to S1 do Inc(SlabStart^[K+1]);
 End;
 For K:=1 to SlabN do SlabStart^[K]:=SlabStart^[K]+SlabStart^[K-1];
 SlabEdge:=AllocBlock((SlabStart^[SlabN]+1)*SizeOf(LongInt));
 For I:=0 to NT-1do Begin
  S0:=SlabOf(OvBox^[I].Y1);S1:=SlabOf(OvBox^[I].Y2);
  For K:=S0 to S1 do Begin
   SlabEdge^[SlabStart^[K]+Fill^[K]]:=I;
   Inc(Fill^[K]);
  End;
 End;
 FreeMem(Fill,(SlabN+2)*SizeOf(LongInt));
End;

Procedure WindingAB(QX,QY:Real;Var Wa,Wb:LongInt);
Var
 K,E,S:LongInt;
 L:Real;
 D:LongInt;
Begin
 Wa:=0;Wb:=0;
 S:=SlabOf(QY);
 For K:=SlabStart^[S] to SlabStart^[S+1]-1do Begin
  E:=SlabEdge^[K];
  D:=0;
  With OvAll^[E]do Begin
   If Y1<=QY Then Begin
    If Y2>QY Then Begin
     L:=(X2-X1)*(QY-Y1)-(QX-X1)*(Y2-Y1);
     If L>0Then D:=1;
    End;
   End
    Else
   If Y2<=QY Then Begin
    L:=(X2-X1)*(QY-Y1)-(QX-X1)*(Y2-Y1);
    If L<0Then D:=-1;
   End;
  End;
  If E<OvNA Then Wa:=Wa+D Else Wb:=Wb+D;
 End;
End;

Procedure AddSplit(E:LongInt;T,X,Y:Real);
Var
 S,C,Prev:PSplit;
Begin
 New(S);
 S^.T:=T;S^.X:=X;S^.Y:=Y;
 Prev:=Nil;
 C:=OvSp^[E];
 While(C<>Nil)and(C^.T<T)do Begin Prev:=C;C:=C^.Next;End;
 S^.Next:=C;
 If Prev=Nil Then OvSp^[E]:=S Else Prev^.Next:=S;
 Inc(OvTot);
End;

Procedure ProjSplit(E:LongInt;Px,Py,L,Dx,Dy:Real);
Var
 T,D:Real;
Begin
 D:=Abs((Px-OvAll^[E].X1)*Dy-(Py-OvAll^[E].Y1)*Dx)/L;
 If D>SnapQ*4Then Exit;
 T:=((Px-OvAll^[E].X1)*Dx+(Py-OvAll^[E].Y1)*Dy)/(L*L);
 If(T>1E-12)and(T<1-1E-12)Then AddSplit(E,T,Px,Py);
End;

Procedure NodeEdges(I,J:LongInt);
Var
 Dx1,Dy1,Dx2,Dy2,Den,L1,L2,T,U,Px,Py,Rx,Ry:Real;
Begin
 Dx1:=OvAll^[I].X2-OvAll^[I].X1;Dy1:=OvAll^[I].Y2-OvAll^[I].Y1;
 Dx2:=OvAll^[J].X2-OvAll^[J].X1;Dy2:=OvAll^[J].Y2-OvAll^[J].Y1;
 L1:=Sqrt(Dx1*Dx1+Dy1*Dy1);
 L2:=Sqrt(Dx2*Dx2+Dy2*Dy2);
 Den:=Dx1*Dy2-Dy1*Dx2;
 If Abs(Den)<=1E-12*L1*L2 Then Begin
  { paralleles : on ne decoupe que si elles se recouvrent }
  ProjSplit(I,OvAll^[J].X1,OvAll^[J].Y1,L1,Dx1,Dy1);
  ProjSplit(I,OvAll^[J].X2,OvAll^[J].Y2,L1,Dx1,Dy1);
  ProjSplit(J,OvAll^[I].X1,OvAll^[I].Y1,L2,Dx2,Dy2);
  ProjSplit(J,OvAll^[I].X2,OvAll^[I].Y2,L2,Dx2,Dy2);
 End
  Else
 Begin
  Rx:=OvAll^[J].X1-OvAll^[I].X1;
  Ry:=OvAll^[J].Y1-OvAll^[I].Y1;
  T:=(Rx*Dy2-Ry*Dx2)/Den;
  U:=(Rx*Dy1-Ry*Dx1)/Den;
  If(T<-1E-12)or(T>1+1E-12)or(U<-1E-12)or(U>1+1E-12)Then Exit;
  If T<=1E-12Then Begin Px:=OvAll^[I].X1;Py:=OvAll^[I].Y1;End Else
  If T>=1-1E-12Then Begin Px:=OvAll^[I].X2;Py:=OvAll^[I].Y2;End Else
  If U<=1E-12Then Begin Px:=OvAll^[J].X1;Py:=OvAll^[J].Y1;End Else
  If U>=1-1E-12Then Begin Px:=OvAll^[J].X2;Py:=OvAll^[J].Y2;End
   Else
  Begin
   Px:=Snap(OvAll^[I].X1+T*Dx1);
   Py:=Snap(OvAll^[I].Y1+T*Dy1);
  End;
  If(T>1E-12)and(T<1-1E-12)Then AddSplit(I,T,Px,Py);
  If(U>1E-12)and(U<1-1E-12)Then AddSplit(J,U,Px,Py);
 End;
End;

{ Supprime les sommets alignes d'un anneau ferme (Tol : ecart maximal a la droite) }
Procedure CleanRing(P:PPath;Tol:Real);
Var
 Q:PPts;
 I,N,M:LongInt;
 Ax,Ay,Bx,By,Cx,Cy,L,Cr:Real;
 Again:Boolean;

 Function Redundant(Ia,Ib,Ic:LongInt):Boolean;Begin
  Ax:=Q^[Ia].X;Ay:=Q^[Ia].Y;Bx:=Q^[Ib].X;By:=Q^[Ib].Y;Cx:=Q^[Ic].X;Cy:=Q^[Ic].Y;
  L:=Sqrt(Sqr(Cx-Ax)+Sqr(Cy-Ay));
  If L<=0Then Redundant:=False
   Else
  Begin
   Cr:=Abs((Bx-Ax)*(Cy-Ay)-(By-Ay)*(Cx-Ax))/L;
   Redundant:=(Cr<=Tol)and((Bx-Ax)*(Cx-Bx)+(By-Ay)*(Cy-By)>0);
  End;
 End;

Begin
 If P^.N<5Then Exit;
 N:=P^.N-1;                { sans le point de fermeture }
 Q:=P^.Pts;
 Repeat
  Again:=False;
  M:=0;
  I:=0;
  While I<N do Begin
   If(N>3)and Redundant((I+N-1)mod N,I,(I+1)mod N)Then Begin
    { on retire le sommet I }
    Move(Q^[I+1],Q^[I],(N-I-1)*SizeOf(TPt));
    Dec(N);
    Again:=True;
   End
    Else
   Inc(I);
  End;
 Until Not Again;
 Q^[N]:=Q^[0];
 P^.N:=N+1;
End;

{ Decoupe toutes les aretes de OvAll a leurs intersections et retourne la liste
  des segments elementaires uniques (Sub, ordonnes par Idx[0..NU-1]). }
Procedure NodeAll(NT:LongInt;MinY,MaxY:Real;WithSlabs:Boolean;Var Sub:PEdges;Var NS:LongInt;Var Idx:PLongs;Var NU:LongInt);
Var
 I,J,P,Q:LongInt;
 Tol,Px,Py:Real;
 S,Nx:PSplit;

 Procedure Emit(X1,Y1,X2,Y2:Real);
 Var
  T:Real;
 Begin
  If(X1=X2)and(Y1=Y2)Then Exit;
  If(X1>X2)or((X1=X2)and(Y1>Y2))Then Begin
   T:=X1;X1:=X2;X2:=T;
   T:=Y1;Y1:=Y2;Y2:=T;
  End;
  Sub^[NS].X1:=X1;Sub^[NS].Y1:=Y1;Sub^[NS].X2:=X2;Sub^[NS].Y2:=Y2;
  Inc(NS);
 End;

Begin
 Tol:=SnapQ*4;
 { boites englobantes et decoupage }
 OvBox:=AllocBlock(NT*SizeOf(TEdge));
 OvSp:=AllocBlock(NT*SizeOf(PSplit));
 For I:=0 to NT-1do Begin
  OvBox^[I].X1:=MinR(OvAll^[I].X1,OvAll^[I].X2);
  OvBox^[I].X2:=MaxR(OvAll^[I].X1,OvAll^[I].X2);
  OvBox^[I].Y1:=MinR(OvAll^[I].Y1,OvAll^[I].Y2);
  OvBox^[I].Y2:=MaxR(OvAll^[I].Y1,OvAll^[I].Y2);
  OvSp^[I]:=Nil;
 End;
 OvTot:=0;
 If WithSlabs Then BuildSlabs(NT,MinY,MaxY);
 { balayage selon X : seules les aretes dont les boites se chevauchent sont comparees }
 Idx:=AllocBlock(NT*SizeOf(LongInt));
 For I:=0 to NT-1do Idx^[I]:=I;
 SB:=OvBox;SMode:=3;
 If NT>1Then SortIdx(Idx,0,NT-1);
 For P:=0 to NT-2do Begin
  I:=Idx^[P];
  Q:=P+1;
  While Q<NT do Begin
   J:=Idx^[Q];
   If OvBox^[J].X1>OvBox^[I].X2+Tol Then Q:=NT
    Else
   Begin
    If Not((OvBox^[J].Y1>OvBox^[I].Y2+Tol)or(OvBox^[J].Y2<OvBox^[I].Y1-Tol))Then NodeEdges(I,J);
    Inc(Q);
   End;
  End;
 End;
 FreeMem(Idx,NT*SizeOf(LongInt));
 { segments elementaires }
 Sub:=AllocBlock((NT+OvTot)*SizeOf(TEdge));
 NS:=0;
 For I:=0 to NT-1do Begin
  Px:=OvAll^[I].X1;Py:=OvAll^[I].Y1;
  S:=OvSp^[I];
  While S<>Nil do Begin
   Emit(Px,Py,S^.X,S^.Y);
   Px:=S^.X;Py:=S^.Y;
   Nx:=S^.Next;
   Dispose(S);
   S:=Nx;
  End;
  Emit(Px,Py,OvAll^[I].X2,OvAll^[I].Y2);
 End;
 FreeMem(OvSp,NT*SizeOf(PSplit));
 FreeMem(OvBox,NT*SizeOf(TEdge));
 { elimination des doublons }
 Idx:=AllocBlock(NS*SizeOf(LongInt));
 For I:=0 to NS-1do Idx^[I]:=I;
 SB:=Sub;SMode:=0;
 If NS>1Then SortIdx(Idx,0,NS-1);
 NU:=0;
 For I:=0 to NS-1do Begin
  If(I=0)or(CmpIdx(Idx^[I],Idx^[I-1])<>0)Then Begin
   Idx^[NU]:=Idx^[I];
   Inc(NU);
  End;
 End;
End;

{ Mode 0 : union (nettoyage) de A, 1 : A inter B, 2 : A moins B }
Procedure Overlay(Mode:Integer;Var A,B:TGeom;Var R:TGeom);
Var
 NA,NB,NT,I,J,NS,NU,KN,Cur,Best,P,Q,Lo,Hi,Mid,RN,Cnt:LongInt;
 Wa,Wb:LongInt;
 MinX,MinY,MaxX,MaxY,Ext,Tol:Real;
 Have,InL,InR,Ok:Boolean;
 Sub,Kp:PEdges;
 Idx,Ord:PLongs;
 Used:PBools;
 RB:PPts;
 S,Nx:PSplit;
 Px,Py,Mx,My,Dx,Dy,Len,Ep,Qx,Qy,Ang,BestAng,Ex,Ey,Sx,Sy:Real;
 EG,HG:TGeom;
 Pa,Pb,Hp:PPath;
 HArr:^PPathArr;
 HN:LongInt;
 Owner:Integer;
 BestArea:Real;
 K:Integer;

 Procedure Bounds(Var G:TGeom);
 Var
  Pt:PPath;
  Q:LongInt;
 Begin
  Pt:=G.First;
  While Pt<>Nil do Begin
   For Q:=0 to Pt^.N-1do Begin
    If Not Have Then Begin
     MinX:=Pt^.Pts^[Q].X;MaxX:=MinX;MinY:=Pt^.Pts^[Q].Y;MaxY:=MinY;Have:=True;
    End
     Else
    Begin
     If Pt^.Pts^[Q].X<MinX Then MinX:=Pt^.Pts^[Q].X;
     If Pt^.Pts^[Q].X>MaxX Then MaxX:=Pt^.Pts^[Q].X;
     If Pt^.Pts^[Q].Y<MinY Then MinY:=Pt^.Pts^[Q].Y;
     If Pt^.Pts^[Q].Y>MaxY Then MaxY:=Pt^.Pts^[Q].Y;
    End;
   End;
   Pt:=Pt^.Next;
  End;
 End;

 Function Inside(Wa,Wb:LongInt):Boolean;Begin
  Case Mode of
   0:Inside:=Wa>0;
   1:Inside:=(Wa>0)and(Wb>0);
   Else Inside:=(Wa>0)and(Wb<=0);
  End;
 End;

Begin
 InitGeom(R);
 R.Cls:=3;
 Have:=False;
 Bounds(A);
 If Mode<>0Then Bounds(B);
 If Not Have Then Exit;
 Ext:=MaxR(MaxX-MinX,MaxY-MinY);
 If Ext<=0Then Exit;
 SnapQ:=Ext*1E-9;
 OvEps:=Ext*1E-8;
 Tol:=SnapQ*4;
 NT:=EdgeCount(A);
 If Mode<>0Then NT:=NT+EdgeCount(B);
 If NT<3Then Exit;
 OvAll:=AllocBlock(NT*SizeOf(TEdge));
 NA:=0;
 FillEdges(A,OvAll,NA);
 NT:=NA;
 If Mode<>0Then FillEdges(B,OvAll,NT);
 NB:=NT-NA;
 If NT<3Then Begin
  FreeMem(OvAll,(NT+1)*SizeOf(TEdge));
  Exit;
 End;
 OvNA:=NA;
 NodeAll(NT,MinY,MaxY,True,Sub,NS,Idx,NU);
 { classement : on garde les segments entre l'interieur et l'exterieur }
 Kp:=AllocBlock((NU+1)*SizeOf(TEdge));
 KN:=0;
 For I:=0 to NU-1do Begin
  P:=Idx^[I];
  Dx:=Sub^[P].X2-Sub^[P].X1;
  Dy:=Sub^[P].Y2-Sub^[P].Y1;
  Len:=Sqrt(Dx*Dx+Dy*Dy);
  If Len>0Then Begin
   Mx:=(Sub^[P].X1+Sub^[P].X2)/2;
   My:=(Sub^[P].Y1+Sub^[P].Y2)/2;
   Ep:=OvEps;
   If Ep>0.1*Len Then Ep:=0.1*Len;
   Qx:=Mx-Dy/Len*Ep;Qy:=My+Dx/Len*Ep;
   WindingAB(Qx,Qy,Wa,Wb);
   InL:=Inside(Wa,Wb);
   Qx:=Mx+Dy/Len*Ep;Qy:=My-Dx/Len*Ep;
   WindingAB(Qx,Qy,Wa,Wb);
   InR:=Inside(Wa,Wb);
   If InL<>InR Then Begin
    If InL Then Begin
     Kp^[KN].X1:=Sub^[P].X1;Kp^[KN].Y1:=Sub^[P].Y1;
     Kp^[KN].X2:=Sub^[P].X2;Kp^[KN].Y2:=Sub^[P].Y2;
    End
     Else
    Begin
     Kp^[KN].X1:=Sub^[P].X2;Kp^[KN].Y1:=Sub^[P].Y2;
     Kp^[KN].X2:=Sub^[P].X1;Kp^[KN].Y2:=Sub^[P].Y1;
    End;
    Inc(KN);
   End;
  End;
 End;
 FreeMem(Idx,NS*SizeOf(LongInt));
 FreeMem(SlabEdge,(SlabStart^[SlabN]+1)*SizeOf(LongInt));
 FreeMem(SlabStart,(SlabN+2)*SizeOf(LongInt));
 FreeMem(Sub,(NT+OvTot)*SizeOf(TEdge));
 FreeMem(OvAll,NT*SizeOf(TEdge));
 If KN>0Then Begin
  { reassemblage des anneaux }
  Ord:=AllocBlock(KN*SizeOf(LongInt));
  Used:=AllocBlock(KN*SizeOf(Boolean));
  For I:=0 to KN-1do Begin Ord^[I]:=I;Used^[I]:=False;End;
  SB:=Kp;SMode:=2;
  If KN>1Then SortIdx(Ord,0,KN-1);
  RB:=AllocBlock((KN+2)*SizeOf(TPt));
  InitGeom(EG);InitGeom(HG);
  For I:=0 to KN-1do Begin
   If Not Used^[Ord^[I]]Then Begin
    Cur:=Ord^[I];
    Sx:=Kp^[Cur].X1;Sy:=Kp^[Cur].Y1;
    RN:=0;
    Ok:=False;
    Repeat
     Used^[Cur]:=True;
     RB^[RN].X:=Kp^[Cur].X1;RB^[RN].Y:=Kp^[Cur].Y1;
     Inc(RN);
     Ex:=Kp^[Cur].X2;Ey:=Kp^[Cur].Y2;
     If(Ex=Sx)and(Ey=Sy)Then Ok:=True
      Else
     Begin
      { recherche des segments partant de (Ex,Ey) }
      Lo:=0;Hi:=KN;
      While Lo<Hi do Begin
       Mid:=(Lo+Hi)div 2;
       If(Kp^[Ord^[Mid]].X1<Ex)or((Kp^[Ord^[Mid]].X1=Ex)and(Kp^[Ord^[Mid]].Y1<Ey))Then Lo:=Mid+1
                                                                                  Else Hi:=Mid;
      End;
      Best:=-1;BestAng:=-10;
      Dx:=Ex-Kp^[Cur].X1;Dy:=Ey-Kp^[Cur].Y1;
      While(Lo<KN)and(Kp^[Ord^[Lo]].X1=Ex)and(Kp^[Ord^[Lo]].Y1=Ey)do Begin
       P:=Ord^[Lo];
       If Not Used^[P]Then Begin
        Mx:=Kp^[P].X2-Ex;My:=Kp^[P].Y2-Ey;
        Ang:=Atan2(Dx*My-Dy*Mx,Dx*Mx+Dy*My);
        If Ang>BestAng Then Begin BestAng:=Ang;Best:=P;End;
       End;
       Inc(Lo);
      End;
      If Best<0Then Cur:=-1 Else Cur:=Best;
     End;
    Until Ok or(Cur<0);
    If Ok and(RN>=3)Then Begin
     Pa:=NewPath(EG,RN+1,0);
     { l'anneau est range dans EG puis deplace selon son aire }
     Move(RB^,Pa^.Pts^,RN*SizeOf(TPt));
     Pa^.Pts^[RN]:=Pa^.Pts^[0];
     Pa^.N:=RN+1;
     CleanRing(Pa,SnapQ*2);
     Pa^.Area:=RingArea(Pa);
    End;
   End;
  End;
  FreeMem(RB,(KN+2)*SizeOf(TPt));
  FreeMem(Used,KN*SizeOf(Boolean));
  FreeMem(Ord,KN*SizeOf(LongInt));
  { separation exterieurs / trous }
  Pa:=EG.First;
  EG.First:=Nil;EG.Last:=Nil;EG.Count:=0;
  While Pa<>Nil do Begin
   Pb:=Pa^.Next;
   If Pa^.Area>0Then LinkPath(EG,Pa)
                Else LinkPath(HG,Pa);
   Pa:=Pb;
  End;
  { rattachement des trous au plus petit exterieur qui les contient }
  Hp:=HG.First;
  While Hp<>Nil do Begin
   Hp^.Poly:=-1;
   BestArea:=0;
   K:=0;
   Pa:=EG.First;
   While Pa<>Nil do Begin
    If(Pa^.Area>Abs(Hp^.Area))and((Hp^.Poly<0)or(Pa^.Area<BestArea))Then Begin
     Cnt:=0;
     Owner:=2;
     While(Cnt<Hp^.N-1)and(Owner=2)do Begin
      Owner:=PointInRing(Pa,Hp^.Pts^[Cnt].X,Hp^.Pts^[Cnt].Y,Tol);
      Inc(Cnt);
     End;
     If Owner=1Then Begin
      Hp^.Poly:=K;
      BestArea:=Pa^.Area;
     End;
    End;
    Inc(K);
    Pa:=Pa^.Next;
   End;
   Hp:=Hp^.Next;
  End;
  { sortie : chaque exterieur suivi de ses trous }
  HN:=HG.Count;
  HArr:=AllocBlock((HN+1)*SizeOf(PPath));
  K:=0;
  Hp:=HG.First;
  While Hp<>Nil do Begin HArr^[K]:=Hp;Inc(K);Hp:=Hp^.Next;End;
  K:=0;
  Pa:=EG.First;
  While Pa<>Nil do Begin
   Pb:=Pa^.Next;
   Pa^.Poly:=K;
   LinkPath(R,Pa);
   For I:=0 to HN-1do
    If HArr^[I]^.Poly=K Then LinkPath(R,HArr^[I]);
   Inc(K);
   Pa:=Pb;
  End;
  FreeMem(HArr,(HN+1)*SizeOf(PPath));
  R.NPoly:=K;
  FreeMem(Kp,(NU+1)*SizeOf(TEdge));
 End
  Else
 FreeMem(Kp,(NU+1)*SizeOf(TEdge));
End;

{ ------------------------------------------------------------------ }
{ Traitements vectoriels                                              }
{ ------------------------------------------------------------------ }

Procedure RingToGeom(Var G:TGeom;Const Pts:PPts;N:LongInt;Poly:Integer);
Var
 P:PPath;
Begin
 P:=NewPath(G,N+1,Poly);
 Move(Pts^,P^.Pts^,N*SizeOf(TPt));
 P^.Pts^[N]:=P^.Pts^[0];
 P^.N:=N+1;
End;

{ Ajoute un cercle de rayon D autour de (X,Y) }
Procedure AddCircle(Var G:TGeom;X,Y,D:Real;Seg:Integer;Poly:Integer);
Var
 N,K:LongInt;
 P:PPath;
 A:Real;
Begin
 N:=4*Seg;
 P:=NewPath(G,N+1,Poly);
 For K:=0 to N-1do Begin
  A:=2*Pi*K/N;
  P^.Pts^[K].X:=X+D*Cos(A);
  P^.Pts^[K].Y:=Y+D*Sin(A);
 End;
 P^.Pts^[N]:=P^.Pts^[0];
 P^.N:=N+1;
End;

{ Intersection de deux segments (Faux s'ils ne se coupent pas) }
Function SegCross(Ax,Ay,Bx,By,Cx,Cy,Dx,Dy:Real;Var Ix,Iy:Real):Boolean;
Var
 Rx,Ry,Sx,Sy,Den,T,U:Real;
Begin
 SegCross:=False;
 Rx:=Bx-Ax;Ry:=By-Ay;Sx:=Dx-Cx;Sy:=Dy-Cy;
 Den:=Rx*Sy-Ry*Sx;
 If Abs(Den)<=1E-14*Sqrt(Rx*Rx+Ry*Ry)*Sqrt(Sx*Sx+Sy*Sy)Then Exit;
 T:=((Cx-Ax)*Sy-(Cy-Ay)*Sx)/Den;
 U:=((Cx-Ax)*Ry-(Cy-Ay)*Rx)/Den;
 If(T>=0)and(T<=1)and(U>=0)and(U<=1)Then Begin
  Ix:=Ax+T*Rx;Iy:=Ay+T*Ry;
  SegCross:=True;
 End;
End;

{ Points du joint, au sommet V, de la courbe decalee a droite de A->V->B.
  Trick : en virage interieur sans croisement, la courbe passe par le sommet. }
Var
 BufCap,BufJoin:Integer;     { extremites : 0 ronde, 1 plate, 2 carree ; jointures : 0 ronde, 1 mitre, 2 biseau }
 BufMiter:Real;

Procedure RightJoin(Ax,Ay,Vx,Vy,Bx,By,D:Real;Seg:Integer;Trick:Boolean;Out:PPts;Var ON:LongInt);
Var
 K,Mm:LongInt;
 L0,L1,D0x,D0y,D1x,D1y,N0x,N0y,N1x,N1y,Cr,Dt,A0,A1,Sw,Ix,Iy,Sx,Sy,Ls,Ch,Ux,Uy,H,S0,S1:Real;
 Turn:Boolean;

 Procedure Emit(X,Y:Real);Begin
  Out^[ON].X:=X;Out^[ON].Y:=Y;
  Inc(ON);
 End;

Begin
 L0:=Sqrt(Sqr(Vx-Ax)+Sqr(Vy-Ay));
 L1:=Sqrt(Sqr(Bx-Vx)+Sqr(By-Vy));
 D0x:=(Vx-Ax)/L0;D0y:=(Vy-Ay)/L0;
 D1x:=(Bx-Vx)/L1;D1y:=(By-Vy)/L1;
 N0x:=D0y*D;N0y:=-D0x*D;
 N1x:=D1y*D;N1y:=-D1x*D;
 Cr:=D0x*D1y-D0y*D1x;
 Dt:=D0x*D1x+D0y*D1y;
 If(Cr>1E-12)or((Cr>=-1E-12)and(Dt<0))Then Begin
  Turn:=(Abs(Cr)<=1E-12)and(Dt<0);
  If Turn and(BufCap=1)Then Begin
   { extremite plate }
   Emit(Vx+N0x,Vy+N0y);
   Emit(Vx+N1x,Vy+N1y);
  End Else
  If Turn and(BufCap=2)Then Begin
   { extremite carree }
   Emit(Vx+N0x+D0x*D,Vy+N0y+D0y*D);
   Emit(Vx+N1x+D0x*D,Vy+N1y+D0y*D);
  End Else
  If(Not Turn)and(BufJoin=2)Then Begin
   { biseau }
   Emit(Vx+N0x,Vy+N0y);
   Emit(Vx+N1x,Vy+N1y);
  End Else
  If(Not Turn)and(BufJoin=1)Then Begin
   { mitre, limitee par BufMiter }
   Sx:=N0x+N1x;Sy:=N0y+N1y;
   Ls:=Sqrt(Sx*Sx+Sy*Sy);
   Ch:=Ls/(2*D);
   If(Ls<1E-12)or(Ch<1E-9)Then Begin
    Emit(Vx+N0x,Vy+N0y);
    Emit(Vx+N1x,Vy+N1y);
   End
    Else
   If 1/Ch<=BufMiter Then Emit(Vx+Sx*D/(Ls*Ch),Vy+Sy*D/(Ls*Ch))
    Else
   Begin
    Ux:=Sx/Ls;Uy:=Sy/Ls;
    H:=BufMiter*D;
    S0:=(H-(N0x*Ux+N0y*Uy))/(D0x*Ux+D0y*Uy);
    S1:=((N1x*Ux+N1y*Uy)-H)/(D1x*Ux+D1y*Uy);
    Emit(Vx+N0x,Vy+N0y);
    Emit(Vx+N0x+S0*D0x,Vy+N0y+S0*D0y);
    Emit(Vx+N1x-S1*D1x,Vy+N1y-S1*D1y);
    Emit(Vx+N1x,Vy+N1y);
   End;
  End
   Else
  Begin
   { arc de cercle autour du sommet }
   A0:=Atan2(N0y,N0x);
   A1:=Atan2(N1y,N1x);
   Sw:=A1-A0;
   While Sw<0do Sw:=Sw+2*Pi;
   While Sw>=2*Pi do Sw:=Sw-2*Pi;
   If Turn Then Sw:=Pi;
   Mm:=Trunc(Sw/(Pi/2)*Seg+0.999999);
   If Mm<1Then Mm:=1;
   Emit(Vx+N0x,Vy+N0y);
   For K:=1 to Mm-1do
    Emit(Vx+D*Cos(A0+Sw*K/Mm),Vy+D*Sin(A0+Sw*K/Mm));
   Emit(Vx+N1x,Vy+N1y);
  End;
 End
 Else
 If Cr<-1E-12Then Begin
  { virage interieur : les decalages se croisent }
  If SegCross(Ax+N0x,Ay+N0y,Vx+N0x,Vy+N0y,Vx+N1x,Vy+N1y,Bx+N1x,By+N1y,Ix,Iy)Then
   Emit(Ix,Iy)
  Else Begin
   Emit(Vx+N0x,Vy+N0y);
   If Trick Then Emit(Vx,Vy);
   Emit(Vx+N1x,Vy+N1y);
  End;
 End
  Else
 Emit(Vx+N0x,Vy+N0y);
End;

{ Sommets d'un chemin sans doublons consecutifs (a liberer par l'appelant) }
Function UniquePts(P:PPath;Var M:LongInt):PPts;
Var
 Q:PPts;
 I:LongInt;
Begin
 Q:=AllocBlock(P^.N*SizeOf(TPt));
 M:=0;
 For I:=0 to P^.N-1do
  If(M=0)or(P^.Pts^[I].X<>Q^[M-1].X)or(P^.Pts^[I].Y<>Q^[M-1].Y)Then Begin
   Q^[M]:=P^.Pts^[I];
   Inc(M);
  End;
 UniquePts:=Q;
End;

Procedure ReversePts(Q:PPts;N:LongInt);
Var
 I:LongInt;
 T:TPt;
Begin
 For I:=0 to N div 2-1do Begin
  T:=Q^[I];Q^[I]:=Q^[N-1-I];Q^[N-1-I]:=T;
 End;
End;

{ Courbe de decalage brute d'une ligne : la ligne est parcourue aller puis retour
  et decalee a droite du sens de parcours (joints et extremites arrondis), ce qui
  donne un anneau ferme. Ses auto-intersections sont eliminees ensuite par
  Overlay (enroulement > 0). Un anneau de polygone est traite comme une ligne
  fermee pour obtenir la bande qui entoure sa frontiere. }
Procedure OffsetPath(Var G:TGeom;P:PPath;D:Real;Seg:Integer;Poly:Integer);
Var
 Q,Cyc,Out,Q2:PPts;
 M,I,K,CN,ON,Pass:LongInt;
 Pa:PPath;
 Closed:Boolean;
Begin
 If D<=0Then Exit;
 Q:=UniquePts(P,M);
 If M=1Then Begin
  If BufCap=0Then AddCircle(G,Q^[0].X,Q^[0].Y,D,Seg,Poly) Else
  If BufCap=2Then Begin
   Pa:=NewPath(G,5,Poly);
   Pa^.Pts^[0].X:=Q^[0].X-D;Pa^.Pts^[0].Y:=Q^[0].Y-D;
   Pa^.Pts^[1].X:=Q^[0].X+D;Pa^.Pts^[1].Y:=Q^[0].Y-D;
   Pa^.Pts^[2].X:=Q^[0].X+D;Pa^.Pts^[2].Y:=Q^[0].Y+D;
   Pa^.Pts^[3].X:=Q^[0].X-D;Pa^.Pts^[3].Y:=Q^[0].Y+D;
   Pa^.Pts^[4]:=Pa^.Pts^[0];
  End;
  FreeMem(Q,P^.N*SizeOf(TPt));
  Exit;
 End;
 Closed:=(M>=4)and(Q^[0].X=Q^[M-1].X)and(Q^[0].Y=Q^[M-1].Y);
 If Closed Then Begin
  { anneau ferme : on le coupe au milieu de son premier segment (sommet aligne),
    ce qui evite toute extremite parasite a la jonction }
  Q2:=AllocBlock((M+2)*SizeOf(TPt));
  Q2^[0].X:=(Q^[0].X+Q^[1].X)/2;Q2^[0].Y:=(Q^[0].Y+Q^[1].Y)/2;
  For I:=1 to M-1do Q2^[I]:=Q^[I];
  Q2^[M]:=Q2^[0];
  FreeMem(Q,P^.N*SizeOf(TPt));
  Q:=Q2;
  Inc(M);
  Q2:=Nil;
 End;
 CN:=2*M-2;
 Cyc:=AllocBlock(CN*SizeOf(TPt));
 For I:=0 to M-1do Cyc^[I]:=Q^[I];
 For I:=1 to M-2do Cyc^[M-1+I]:=Q^[M-1-I];
 Out:=AllocBlock((CN*(4*Seg+6)+2)*SizeOf(TPt));
 ON:=0;
 For I:=0 to CN-1do Begin
  K:=(I+CN-1)mod CN;
  RightJoin(Cyc^[K].X,Cyc^[K].Y,Cyc^[I].X,Cyc^[I].Y,Cyc^[(I+1)mod CN].X,Cyc^[(I+1)mod CN].Y,
            D,Seg,True,Out,ON);
 End;
 Pa:=NewPath(G,ON+1,Poly);
 Move(Out^,Pa^.Pts^,ON*SizeOf(TPt));
 Pa^.Pts^[ON]:=Pa^.Pts^[0];
 Pa^.N:=ON+1;
 FreeMem(Out,(CN*(4*Seg+6)+2)*SizeOf(TPt));
 FreeMem(Cyc,CN*SizeOf(TPt));
 FreeMem(Q,P^.N*SizeOf(TPt));
End;

{ Courbe decalee d'une ligne (Dist > 0 : a gauche, Dist < 0 : a droite) }
Procedure OffsetCurve(Var G:TGeom;P:PPath;Dist:Real;Seg:Integer);
Var
 Q,Out:PPts;
 M,I,ON:LongInt;
 D,Dx,Dy,L:Real;
 Pa:PPath;
Begin
 If Dist=0Then Exit;
 Q:=UniquePts(P,M);
 If M<2Then Begin
  FreeMem(Q,P^.N*SizeOf(TPt));
  Exit;
 End;
 D:=Abs(Dist);
 { a gauche = a droite du chemin inverse }
 If Dist>0Then ReversePts(Q,M);
 Out:=AllocBlock((M*(4*Seg+4)+2)*SizeOf(TPt));
 ON:=0;
 For I:=0 to M-1do Begin
  If I=0Then Begin
   Dx:=Q^[1].X-Q^[0].X;Dy:=Q^[1].Y-Q^[0].Y;
   L:=Sqrt(Dx*Dx+Dy*Dy);
   Out^[ON].X:=Q^[0].X+Dy/L*D;Out^[ON].Y:=Q^[0].Y-Dx/L*D;
   Inc(ON);
  End
   Else
  If I=M-1Then Begin
   Dx:=Q^[I].X-Q^[I-1].X;Dy:=Q^[I].Y-Q^[I-1].Y;
   L:=Sqrt(Dx*Dx+Dy*Dy);
   Out^[ON].X:=Q^[I].X+Dy/L*D;Out^[ON].Y:=Q^[I].Y-Dx/L*D;
   Inc(ON);
  End
   Else
  RightJoin(Q^[I-1].X,Q^[I-1].Y,Q^[I].X,Q^[I].Y,Q^[I+1].X,Q^[I+1].Y,D,Seg,False,Out,ON);
 End;
 If Dist>0Then ReversePts(Out,ON);
 Pa:=NewPath(G,ON,0);
 Move(Out^,Pa^.Pts^,ON*SizeOf(TPt));
 Pa^.N:=ON;
 FreeMem(Out,(M*(4*Seg+4)+2)*SizeOf(TPt));
 FreeMem(Q,P^.N*SizeOf(TPt));
End;

{ Pieces (rectangles et secteurs) du tampon d'un seul cote d'une ligne }
Procedure SidePieces(Var G:TGeom;P:PPath;Dist:Real;Right:Boolean;Seg:Integer;Var K:Integer);
Var
 Q:PPts;
 M,I,J,Mm:LongInt;
 Dx,Dy,L,L1,Nx,Ny,N1x,N1y,O1x,O1y,A0,A1,Sw,Cr:Real;
 Pa:PPath;
Begin
 Q:=UniquePts(P,M);
 If M>=2Then Begin
  If Right Then ReversePts(Q,M);
  For I:=0 to M-2do Begin
   Dx:=Q^[I+1].X-Q^[I].X;Dy:=Q^[I+1].Y-Q^[I].Y;
   L:=Sqrt(Dx*Dx+Dy*Dy);
   Nx:=-Dy/L*Dist;Ny:=Dx/L*Dist;
   Pa:=NewPath(G,5,K);
   Inc(K);
   Pa^.Pts^[0]:=Q^[I];
   Pa^.Pts^[1]:=Q^[I+1];
   Pa^.Pts^[2].X:=Q^[I+1].X+Nx;Pa^.Pts^[2].Y:=Q^[I+1].Y+Ny;
   Pa^.Pts^[3].X:=Q^[I].X+Nx;Pa^.Pts^[3].Y:=Q^[I].Y+Ny;
   Pa^.Pts^[4]:=Pa^.Pts^[0];
   { secteur de cercle si le virage est a droite (exterieur du cote gauche) }
   If I<M-2Then Begin
    N1x:=Q^[I+2].X-Q^[I+1].X;
    Cr:=Dx*(Q^[I+2].Y-Q^[I+1].Y)-Dy*N1x;
    If Cr<-1E-12*L Then Begin
     N1y:=Q^[I+2].Y-Q^[I+1].Y;
     L1:=Sqrt(N1x*N1x+N1y*N1y);
     O1x:=Q^[I+1].X-N1y/L1*Dist;O1y:=Q^[I+1].Y+N1x/L1*Dist;
     A0:=Atan2(Ny,Nx);
     A1:=Atan2(N1x/L1*Dist,-N1y/L1*Dist);
     Sw:=A1-A0;
     While Sw>0do Sw:=Sw-2*Pi;
     While Sw<=-2*Pi do Sw:=Sw+2*Pi;
     Mm:=Trunc(-Sw/(Pi/2)*Seg+0.999999);
     If Mm<1Then Mm:=1;
     Pa:=NewPath(G,Mm+3,K);
     Inc(K);
     Pa^.Pts^[0]:=Q^[I+1];
     For J:=0 to Mm do Begin
      Pa^.Pts^[1+J].X:=Q^[I+1].X+Dist*Cos(A1+(A0-A1)*J/Mm);
      Pa^.Pts^[1+J].Y:=Q^[I+1].Y+Dist*Sin(A1+(A0-A1)*J/Mm);
     End;
     { extremites identiques a celles des rectangles voisins }
     Pa^.Pts^[1].X:=O1x;Pa^.Pts^[1].Y:=O1y;
     Pa^.Pts^[Mm+1].X:=Q^[I+1].X+Nx;Pa^.Pts^[Mm+1].Y:=Q^[I+1].Y+Ny;
     Pa^.Pts^[Mm+2]:=Pa^.Pts^[0];
     Pa^.N:=Mm+3;
    End;
   End;
  End;
 End;
 FreeMem(Q,P^.N*SizeOf(TPt));
End;

{ Tampon d'une geometrie aplatie }
Procedure BufferGeom(Var G:TGeom;Dist:Real;Seg:Integer;Var R:TGeom);
Var
 A,B:TGeom;
 P,Q:PPath;
 Prev,K:Integer;
 Ext:Boolean;
 I,J:LongInt;
 Tmp:TPt;
Begin
 InitGeom(R);
 InitGeom(A);InitGeom(B);
 A.Cls:=3;B.Cls:=3;
 K:=0;
 Case G.Cls of
  1:If Dist>0Then Begin
   P:=G.First;
   While P<>Nil do Begin
    OffsetPath(A,P,Dist,Seg,K);
    Inc(K);
    P:=P^.Next;
   End;
  End;
  2:If Dist>0Then Begin
   P:=G.First;
   While P<>Nil do Begin
    OffsetPath(A,P,Dist,Seg,K);
    Inc(K);
    P:=P^.Next;
   End;
  End;
  3:If Dist<>0Then Begin
   { polygone : anneaux orientes (exterieur anti-horaire, trou horaire) }
   Prev:=-1;
   P:=G.First;
   While P<>Nil do Begin
    Ext:=P^.Poly<>Prev;
    Prev:=P^.Poly;
    Q:=CopyPath(A,P,K);
    If(Ext and(RingArea(Q)<0))or((Not Ext)and(RingArea(Q)>0))Then
     For I:=0 to Q^.N div 2-1do Begin
      J:=Q^.N-1-I;
      Tmp:=Q^.Pts^[I];Q^.Pts^[I]:=Q^.Pts^[J];Q^.Pts^[J]:=Tmp;
     End;
    Inc(K);
    P:=P^.Next;
   End;
   { bande de largeur |Dist| autour de la frontiere }
   P:=G.First;
   While P<>Nil do Begin
    If Dist>0Then OffsetPath(A,P,Dist,Seg,K)
             Else OffsetPath(B,P,-Dist,Seg,K);
    Inc(K);
    P:=P^.Next;
   End;
  End;
 End;
 If A.First<>Nil Then Begin
  KeepOrient:=True;
  If(G.Cls=3)and(Dist<0)Then Overlay(2,A,B,R)
                        Else Overlay(0,A,B,R);
  KeepOrient:=False;
 End;
 FreeGeom(A);
 FreeGeom(B);
End;

{ Enveloppe convexe (chaine monotone d'Andrew) }
Procedure HullGeom(Var G:TGeom;Var R:TGeom);
Var
 P:PPath;
 Pts,Srt:PPts;
 Idx,Chain:PLongs;
 N,I,K,T,M,Total:LongInt;
 Pa:PPath;

 Function Cross(O,A,B:LongInt):Real;Begin
  Cross:=(Srt^[A].X-Srt^[O].X)*(Srt^[B].Y-Srt^[O].Y)-(Srt^[A].Y-Srt^[O].Y)*(Srt^[B].X-Srt^[O].X);
 End;

Begin
 InitGeom(R);
 Total:=0;
 P:=G.First;
 While P<>Nil do Begin Inc(Total,P^.N);P:=P^.Next;End;
 If Total=0Then Exit;
 Pts:=AllocBlock(Total*SizeOf(TPt));
 N:=0;
 P:=G.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-1do Begin Pts^[N]:=P^.Pts^[I];Inc(N);End;
  P:=P^.Next;
 End;
 Idx:=AllocBlock(Total*SizeOf(LongInt));
 For I:=0 to Total-1do Idx^[I]:=I;
 SP:=Pts;SMode:=1;
 If Total>1Then SortIdx(Idx,0,Total-1);
 { points tries, sans doublons }
 Srt:=AllocBlock(Total*SizeOf(TPt));
 N:=0;
 For I:=0 to Total-1do
  If(I=0)or(CmpIdx(Idx^[I],Idx^[I-1])<>0)Then Begin
   Srt^[N]:=Pts^[Idx^[I]];
   Inc(N);
  End;
 FreeMem(Idx,Total*SizeOf(LongInt));
 FreeMem(Pts,Total*SizeOf(TPt));
 If N=1Then Begin
  R.Cls:=1;
  Pa:=NewPath(R,1,0);
  Pa^.Pts^[0]:=Srt^[0];
 End
  Else
 Begin
  Chain:=AllocBlock((2*N+2)*SizeOf(LongInt));
  K:=0;
  For I:=0 to N-1do Begin
   While(K>=2)and(Cross(Chain^[K-2],Chain^[K-1],I)<=0)do Dec(K);
   Chain^[K]:=I;Inc(K);
  End;
  T:=K+1;
  For I:=N-2 downto 0do Begin
   While(K>=T)and(Cross(Chain^[K-2],Chain^[K-1],I)<=0)do Dec(K);
   Chain^[K]:=I;Inc(K);
  End;
  M:=K-1;   { le dernier point repete le premier }
  If M<3Then Begin
   R.Cls:=2;
   Pa:=NewPath(R,2,0);
   Pa^.Pts^[0]:=Srt^[0];
   Pa^.Pts^[1]:=Srt^[N-1];
  End
   Else
  Begin
   R.Cls:=3;
   Pa:=NewPath(R,M+1,0);
   For I:=0 to M-1do Pa^.Pts^[I]:=Srt^[Chain^[I]];
   Pa^.Pts^[M]:=Pa^.Pts^[0];
   R.NPoly:=1;
  End;
  FreeMem(Chain,(2*N+2)*SizeOf(LongInt));
 End;
 FreeMem(Srt,Total*SizeOf(TPt));
End;

{ Centroide d'une geometrie aplatie }
Procedure CentroidGeom(Var G:TGeom;Var Cx,Cy:Real;Var Ok:Boolean);
Var
 P:PPath;
 I,J:LongInt;
 Sa,Sx,Sy,A,Ox,Oy,L,Mx,My,N:Real;
 Prev:Integer;
Begin
 Ok:=False;
 If G.First=Nil Then Exit;
 Ox:=G.First^.Pts^[0].X;Oy:=G.First^.Pts^[0].Y;
 Sa:=0;Sx:=0;Sy:=0;
 If G.Cls=3Then Begin
  { le premier anneau d'un polygone est son exterieur (aire positive),
    les suivants sont des trous (aire negative) }
  Prev:=-1;
  P:=G.First;
  While P<>Nil do Begin
   A:=Abs(RingArea(P));
   If P^.Poly=Prev Then A:=-A;
   Prev:=P^.Poly;
   Mx:=0;My:=0;L:=0;
   For I:=0 to P^.N-1do Begin
    J:=I+1;
    If J>=P^.N Then J:=0;
    N:=(P^.Pts^[I].X-Ox)*(P^.Pts^[J].Y-Oy)-(P^.Pts^[J].X-Ox)*(P^.Pts^[I].Y-Oy);
    Mx:=Mx+((P^.Pts^[I].X-Ox)+(P^.Pts^[J].X-Ox))*N;
    My:=My+((P^.Pts^[I].Y-Oy)+(P^.Pts^[J].Y-Oy))*N;
    L:=L+N;
   End;
   If L<>0Then Begin
    Sa:=Sa+A;
    Sx:=Sx+A*Mx/(3*L);
    Sy:=Sy+A*My/(3*L);
   End;
   P:=P^.Next;
  End;
  If Sa<>0Then Begin
   Cx:=Ox+Sx/Sa;Cy:=Oy+Sy/Sa;
   Ok:=True;
   Exit;
  End;
 End;
 If G.Cls=2Then Begin
  { barycentre des segments pondere par leur longueur }
  P:=G.First;
  Sa:=0;Sx:=0;Sy:=0;
  While P<>Nil do Begin
   For I:=0 to P^.N-2do Begin
    L:=Sqrt(Sqr(P^.Pts^[I+1].X-P^.Pts^[I].X)+Sqr(P^.Pts^[I+1].Y-P^.Pts^[I].Y));
    Sa:=Sa+L;
    Sx:=Sx+L*((P^.Pts^[I].X+P^.Pts^[I+1].X)/2-Ox);
    Sy:=Sy+L*((P^.Pts^[I].Y+P^.Pts^[I+1].Y)/2-Oy);
   End;
   P:=P^.Next;
  End;
  If Sa>0Then Begin
   Cx:=Ox+Sx/Sa;Cy:=Oy+Sy/Sa;
   Ok:=True;
   Exit;
  End;
 End;
 { moyenne des sommets (points, ou geometries degenerees) }
 P:=G.First;
 Sx:=0;Sy:=0;Sa:=0;
 While P<>Nil do Begin
  I:=P^.N;
  { un anneau ferme repete son premier sommet }
  If(G.Cls=3)and(I>1)and(P^.Pts^[0].X=P^.Pts^[I-1].X)and(P^.Pts^[0].Y=P^.Pts^[I-1].Y)Then Dec(I);
  For J:=0 to I-1do Begin
   Sx:=Sx+(P^.Pts^[J].X-Ox);
   Sy:=Sy+(P^.Pts^[J].Y-Oy);
   Sa:=Sa+1;
  End;
  P:=P^.Next;
 End;
 If Sa>0Then Begin
  Cx:=Ox+Sx/Sa;Cy:=Oy+Sy/Sa;
  Ok:=True;
 End;
End;

{ Distance d'un point a un segment }
Function DistSeg(Px,Py,X1,Y1,X2,Y2:Real):Real;
Var
 Dx,Dy,L2,T:Real;
Begin
 Dx:=X2-X1;Dy:=Y2-Y1;
 L2:=Dx*Dx+Dy*Dy;
 If L2<=0Then T:=0
  Else
 Begin
  T:=((Px-X1)*Dx+(Py-Y1)*Dy)/L2;
  If T<0Then T:=0;
  If T>1Then T:=1;
 End;
 DistSeg:=Sqrt(Sqr(Px-(X1+T*Dx))+Sqr(Py-(Y1+T*Dy)));
End;

{ Point dans (ou sur le bord) du polygone defini par les aretes orientees E }
Function InsideOrOn(E:PEdges;N:LongInt;X,Y,Tol:Real):Boolean;
Var
 I:LongInt;
Begin
 If Winding(E,N,X,Y)<>0Then Begin
  InsideOrOn:=True;
  Exit;
 End;
 For I:=0 to N-1do
  If DistSeg(X,Y,E^[I].X1,E^[I].Y1,E^[I].X2,E^[I].Y2)<=Tol Then Begin
   InsideOrOn:=True;
   Exit;
  End;
 InsideOrOn:=False;
End;

{ Decoupe les chemins de lignes de G par le polygone (aretes E) }
Procedure ClipLines(Var G:TGeom;E:PEdges;N:LongInt;Tol:Real;Var R:TGeom);
Var
 P:PPath;
 K,I,Cnt,M:LongInt;
 Ts:PReals;
 Ax,Ay,Bx,By,Dx,Dy,Den,Rx,Ry,T,U,L,Tmp,Mx,My:Real;
 Pieces:TGeom;
 Pa,Pc:PPath;
 Buf:PPts;
 BN:LongInt;

 Procedure AddT(V:Real);Begin
  If(V>1E-12)and(V<1-1E-12)Then Begin
   Ts^[Cnt]:=V;Inc(Cnt);
  End;
 End;

Begin
 InitGeom(R);
 R.Cls:=2;
 Ts:=AllocBlock((2*N+4)*SizeOf(Real));
 P:=G.First;
 While P<>Nil do Begin
  InitGeom(Pieces);
  For K:=0 to P^.N-2do Begin
   Ax:=P^.Pts^[K].X;Ay:=P^.Pts^[K].Y;Bx:=P^.Pts^[K+1].X;By:=P^.Pts^[K+1].Y;
   Dx:=Bx-Ax;Dy:=By-Ay;
   L:=Sqrt(Dx*Dx+Dy*Dy);
   If L>0Then Begin
    Cnt:=0;
    Ts^[Cnt]:=0;Inc(Cnt);
    For I:=0 to N-1do Begin
     Rx:=E^[I].X2-E^[I].X1;Ry:=E^[I].Y2-E^[I].Y1;
     Den:=Dx*Ry-Dy*Rx;
     If Abs(Den)<=1E-12*L*Sqrt(Rx*Rx+Ry*Ry)Then Begin
      { paralleles : projection des extremites de l'arete sur le segment }
      If DistSeg(E^[I].X1,E^[I].Y1,Ax,Ay,Bx,By)<=Tol Then AddT(((E^[I].X1-Ax)*Dx+(E^[I].Y1-Ay)*Dy)/(L*L));
      If DistSeg(E^[I].X2,E^[I].Y2,Ax,Ay,Bx,By)<=Tol Then AddT(((E^[I].X2-Ax)*Dx+(E^[I].Y2-Ay)*Dy)/(L*L));
     End
      Else
     Begin
      T:=((E^[I].X1-Ax)*Ry-(E^[I].Y1-Ay)*Rx)/Den;
      U:=((E^[I].X1-Ax)*Dy-(E^[I].Y1-Ay)*Dx)/Den;
      If(T>=0)and(T<=1)and(U>=-1E-12)and(U<=1+1E-12)Then AddT(T);
     End;
    End;
    Ts^[Cnt]:=1;Inc(Cnt);
    { tri par insertion }
    For I:=1 to Cnt-1do Begin
     Tmp:=Ts^[I];
     M:=I-1;
     While(M>=0)and(Ts^[M]>Tmp)do Begin Ts^[M+1]:=Ts^[M];Dec(M);End;
     Ts^[M+1]:=Tmp;
    End;
    For I:=0 to Cnt-2do Begin
     If Ts^[I+1]-Ts^[I]>1E-12Then Begin
      Mx:=Ax+(Ts^[I]+Ts^[I+1])/2*Dx;
      My:=Ay+(Ts^[I]+Ts^[I+1])/2*Dy;
      If InsideOrOn(E,N,Mx,My,Tol)<>ClipOutside Then Begin
       Pa:=NewPath(Pieces,2,0);
       Pa^.Pts^[0].X:=Ax+Ts^[I]*Dx;Pa^.Pts^[0].Y:=Ay+Ts^[I]*Dy;
       Pa^.Pts^[1].X:=Ax+Ts^[I+1]*Dx;Pa^.Pts^[1].Y:=Ay+Ts^[I+1]*Dy;
      End;
     End;
    End;
   End;
  End;
  { fusion des morceaux consecutifs }
  If Pieces.Count>0Then Begin
   Buf:=AllocBlock((2*Pieces.Count+2)*SizeOf(TPt));
   BN:=0;
   Pa:=Pieces.First;
   While Pa<>Nil do Begin
    If(BN>0)and((Buf^[BN-1].X<>Pa^.Pts^[0].X)or(Buf^[BN-1].Y<>Pa^.Pts^[0].Y))Then Begin
     Pc:=NewPath(R,BN,0);
     Move(Buf^,Pc^.Pts^,BN*SizeOf(TPt));
     Pc^.N:=BN;
     BN:=0;
    End;
    If BN=0Then Begin Buf^[0]:=Pa^.Pts^[0];BN:=1;End;
    Buf^[BN]:=Pa^.Pts^[1];Inc(BN);
    Pa:=Pa^.Next;
   End;
   If BN>0Then Begin
    Pc:=NewPath(R,BN,0);
    Move(Buf^,Pc^.Pts^,BN*SizeOf(TPt));
    Pc^.N:=BN;
   End;
   FreeMem(Buf,(2*Pieces.Count+2)*SizeOf(TPt));
  End;
  FreeGeom(Pieces);
  P:=P^.Next;
 End;
 FreeMem(Ts,(2*N+4)*SizeOf(Real));
End;

{ ------------------------------------------------------------------ }
{ Bibliotheque de geometries                                         }
{ ------------------------------------------------------------------ }

Function GeomBBox(Var G:TGeom;Var MinX,MinY,MaxX,MaxY:Real):Boolean;
Var
 P:PPath;
 I:LongInt;
 Have:Boolean;
Begin
 Have:=False;
 MinX:=0;MinY:=0;MaxX:=0;MaxY:=0;
 P:=G.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-1do
   If Not Have Then Begin
    MinX:=P^.Pts^[I].X;MaxX:=MinX;MinY:=P^.Pts^[I].Y;MaxY:=MinY;Have:=True;
   End
    Else
   Begin
    If P^.Pts^[I].X<MinX Then MinX:=P^.Pts^[I].X;
    If P^.Pts^[I].X>MaxX Then MaxX:=P^.Pts^[I].X;
    If P^.Pts^[I].Y<MinY Then MinY:=P^.Pts^[I].Y;
    If P^.Pts^[I].Y>MaxY Then MaxY:=P^.Pts^[I].Y;
   End;
  P:=P^.Next;
 End;
 GeomBBox:=Have;
End;

Procedure GeomCopy(Var S,D:TGeom);
Var
 P:PPath;
Begin
 InitGeom(D);
 D.Cls:=S.Cls;
 D.NPoly:=S.NPoly;
 P:=S.First;
 While P<>Nil do Begin
  CopyPath(D,P,P^.Poly);
  P:=P^.Next;
 End;
End;

{ Ajoute (par copie) les chemins de S a D en renumerotant les polygones }
Procedure GeomAppend(Var D:TGeom;Var S:TGeom);
Var
 P:PPath;
Begin
 If D.Cls=0Then D.Cls:=S.Cls;
 P:=S.First;
 While P<>Nil do Begin
  CopyPath(D,P,P^.Poly+D.NPoly);
  P:=P^.Next;
 End;
 D.NPoly:=D.NPoly+S.NPoly;
End;

Function PathLength(P:PPath):Real;
Var
 I:LongInt;
 L:Real;
Begin
 L:=0;
 For I:=0 to P^.N-2do
  L:=L+Sqrt(Sqr(P^.Pts^[I+1].X-P^.Pts^[I].X)+Sqr(P^.Pts^[I+1].Y-P^.Pts^[I].Y));
 PathLength:=L;
End;

{ Longueur des lignes ou perimetre des polygones }
Function GeomLength(Var G:TGeom):Real;
Var
 P:PPath;
 L:Real;
Begin
 L:=0;
 If G.Cls>=2Then Begin
  P:=G.First;
  While P<>Nil do Begin
   L:=L+PathLength(P);
   If(G.Cls=3)and((P^.Pts^[0].X<>P^.Pts^[P^.N-1].X)or(P^.Pts^[0].Y<>P^.Pts^[P^.N-1].Y))Then
    L:=L+Sqrt(Sqr(P^.Pts^[0].X-P^.Pts^[P^.N-1].X)+Sqr(P^.Pts^[0].Y-P^.Pts^[P^.N-1].Y));
   P:=P^.Next;
  End;
 End;
 GeomLength:=L;
End;

Function GeomArea(Var G:TGeom):Real;
Var
 P:PPath;
 A:Real;
 Prev:Integer;
Begin
 A:=0;
 If G.Cls=3Then Begin
  Prev:=-1;
  P:=G.First;
  While P<>Nil do Begin
   If P^.Poly<>Prev Then A:=A+Abs(RingArea(P))
                    Else A:=A-Abs(RingArea(P));
   Prev:=P^.Poly;
   P:=P^.Next;
  End;
 End;
 GeomArea:=A;
End;

{ Remet les anneaux dans le sens exterieur anti-horaire / trou horaire }
Procedure OrientPolygons(Var G:TGeom);
Var
 P:PPath;
 Prev:Integer;
 A:Real;
Begin
 If G.Cls<>3Then Exit;
 Prev:=-1;
 P:=G.First;
 While P<>Nil do Begin
  A:=RingArea(P);
  If((P^.Poly<>Prev)and(A<0))or((P^.Poly=Prev)and(A>0))Then ReversePts(P^.Pts,P^.N);
  Prev:=P^.Poly;
  P:=P^.Next;
 End;
End;

{ x' = m11 x + m12 y + tx ; y' = m21 x + m22 y + ty }
Procedure AffineGeom(Var G:TGeom;M11,M12,M21,M22,Tx,Ty:Real);
Var
 P:PPath;
 I:LongInt;
 X,Y:Real;
Begin
 P:=G.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-1do Begin
   X:=P^.Pts^[I].X;Y:=P^.Pts^[I].Y;
   P^.Pts^[I].X:=M11*X+M12*Y+Tx;
   P^.Pts^[I].Y:=M21*X+M22*Y+Ty;
  End;
  P:=P^.Next;
 End;
 If M11*M22-M12*M21<0Then OrientPolygons(G);
End;

{ Douglas-Peucker : Keep marque les sommets conserves }
Procedure DPMark(Pts:PPts;Keep:PBools;First,Last:LongInt;Tol:Real);
Var
 Stack:PLongs;
 Sp,I,A,B,Far:LongInt;
 D,Best:Real;
Begin
 Stack:=AllocBlock((2*(Last-First+2))*SizeOf(LongInt));
 Sp:=0;
 Stack^[0]:=First;Stack^[1]:=Last;Sp:=2;
 While Sp>0do Begin
  B:=Stack^[Sp-1];A:=Stack^[Sp-2];
  Dec(Sp,2);
  Best:=-1;Far:=-1;
  For I:=A+1 to B-1do Begin
   D:=DistSeg(Pts^[I].X,Pts^[I].Y,Pts^[A].X,Pts^[A].Y,Pts^[B].X,Pts^[B].Y);
   If D>Best Then Begin Best:=D;Far:=I;End;
  End;
  If(Far>=0)and(Best>Tol)Then Begin
   Keep^[Far]:=True;
   Stack^[Sp]:=A;Stack^[Sp+1]:=Far;Inc(Sp,2);
   Stack^[Sp]:=Far;Stack^[Sp+1]:=B;Inc(Sp,2);
  End;
 End;
 FreeMem(Stack,(2*(Last-First+2))*SizeOf(LongInt));
End;

{ Simplifie un chemin ; retourne Faux si le chemin disparait }
Function SimplifyDP(P:PPath;Tol:Real;Closed:Boolean;Var G:TGeom;Poly:Integer):Boolean;
Var
 Q:PPts;
 Keep:PBools;
 M,I,K,Far,Cnt:LongInt;
 D,Best:Real;
 Pa:PPath;
Begin
 SimplifyDP:=False;
 Q:=UniquePts(P,M);
 If Closed and(M>1)and(Q^[0].X=Q^[M-1].X)and(Q^[0].Y=Q^[M-1].Y)Then Dec(M);
 If M<2Then Begin
  FreeMem(Q,P^.N*SizeOf(TPt));
  Exit;
 End;
 Keep:=AllocBlock(M*SizeOf(Boolean));
 For I:=0 to M-1do Keep^[I]:=False;
 Keep^[0]:=True;
 If Closed Then Begin
  { anneau : coupure au sommet le plus eloigne du premier }
  Best:=-1;Far:=0;
  For I:=1 to M-1do Begin
   D:=Sqr(Q^[I].X-Q^[0].X)+Sqr(Q^[I].Y-Q^[0].Y);
   If D>Best Then Begin Best:=D;Far:=I;End;
  End;
  Keep^[Far]:=True;
  If Far>1Then DPMark(Q,Keep,0,Far,Tol);
  If M-1>Far Then Begin
   { seconde moitie : de Far a M puis retour au premier sommet }
   Q^[M]:=Q^[0];
   DPMark(Q,Keep,Far,M,Tol);
  End;
 End
  Else
 Begin
  Keep^[M-1]:=True;
  DPMark(Q,Keep,0,M-1,Tol);
 End;
 Cnt:=0;
 For I:=0 to M-1do If Keep^[I]Then Inc(Cnt);
 If(Closed and(Cnt<3))or((Not Closed)and(Cnt<2))Then Begin
  FreeMem(Keep,M*SizeOf(Boolean));
  FreeMem(Q,P^.N*SizeOf(TPt));
  Exit;
 End;
 If Closed Then Pa:=NewPath(G,Cnt+1,Poly) Else Pa:=NewPath(G,Cnt,Poly);
 K:=0;
 For I:=0 to M-1do If Keep^[I]Then Begin
  Pa^.Pts^[K]:=Q^[I];
  Inc(K);
 End;
 If Closed Then Begin Pa^.Pts^[K]:=Pa^.Pts^[0];Inc(K);End;
 Pa^.N:=K;
 FreeMem(Keep,M*SizeOf(Boolean));
 FreeMem(Q,P^.N*SizeOf(TPt));
 SimplifyDP:=True;
End;

{ Visvalingam : supprime les sommets dont le triangle est de plus petite aire }
Function SimplifyVW(P:PPath;MinArea:Real;Closed:Boolean;Var G:TGeom;Poly:Integer):Boolean;
Var
 Q:PPts;
 M,I,K,Cnt,Lo,Hi,Best:LongInt;
 Ar,BestA:Real;
 Alive:PBools;
 Pa:PPath;

 Function Prev(I:LongInt):LongInt;
 Var J:LongInt;
 Begin
  J:=I-1;
  While(J>=0)and Not Alive^[J]do Dec(J);
  If(J<0)and Closed Then Begin
   J:=M-1;
   While(J>I)and Not Alive^[J]do Dec(J);
  End;
  Prev:=J;
 End;

 Function Next(I:LongInt):LongInt;
 Var J:LongInt;
 Begin
  J:=I+1;
  While(J<M)and Not Alive^[J]do Inc(J);
  If(J>=M)and Closed Then Begin
   J:=0;
   While(J<I)and Not Alive^[J]do Inc(J);
  End;
  If J>=M Then J:=-1;
  Next:=J;
 End;

Begin
 SimplifyVW:=False;
 Q:=UniquePts(P,M);
 If Closed and(M>1)and(Q^[0].X=Q^[M-1].X)and(Q^[0].Y=Q^[M-1].Y)Then Dec(M);
 If M<2Then Begin
  FreeMem(Q,P^.N*SizeOf(TPt));
  Exit;
 End;
 Alive:=AllocBlock(M*SizeOf(Boolean));
 For I:=0 to M-1do Alive^[I]:=True;
 Cnt:=M;
 Repeat
  Best:=-1;BestA:=1E300;
  For I:=0 to M-1do
   If Alive^[I]Then Begin
    Lo:=Prev(I);Hi:=Next(I);
    If(Lo>=0)and(Hi>=0)and(Lo<>Hi)and((Closed and(Cnt>3))or((Not Closed)and(I>0)and(I<M-1)and(Cnt>2)))Then Begin
     Ar:=Abs((Q^[I].X-Q^[Lo].X)*(Q^[Hi].Y-Q^[Lo].Y)-(Q^[Hi].X-Q^[Lo].X)*(Q^[I].Y-Q^[Lo].Y))/2;
     If Ar<BestA Then Begin BestA:=Ar;Best:=I;End;
    End;
   End;
  If(Best>=0)and(BestA<MinArea)Then Begin
   Alive^[Best]:=False;
   Dec(Cnt);
  End
   Else
  Best:=-1;
 Until Best<0;
 If(Closed and(Cnt<3))or((Not Closed)and(Cnt<2))Then Begin
  FreeMem(Alive,M*SizeOf(Boolean));
  FreeMem(Q,P^.N*SizeOf(TPt));
  Exit;
 End;
 If Closed Then Pa:=NewPath(G,Cnt+1,Poly) Else Pa:=NewPath(G,Cnt,Poly);
 K:=0;
 For I:=0 to M-1do If Alive^[I]Then Begin
  Pa^.Pts^[K]:=Q^[I];
  Inc(K);
 End;
 If Closed Then Begin Pa^.Pts^[K]:=Pa^.Pts^[0];Inc(K);End;
 Pa^.N:=K;
 FreeMem(Alive,M*SizeOf(Boolean));
 FreeMem(Q,P^.N*SizeOf(TPt));
 SimplifyVW:=True;
End;

{ Arrondit les sommets a une grille }
Function SnapGridPath(P:PPath;Cell:Real;Closed:Boolean;Var G:TGeom;Poly:Integer):Boolean;
Var
 I,K,M:LongInt;
 X,Y:Real;
 Pa:PPath;
 Q:PPts;
Begin
 SnapGridPath:=False;
 Q:=AllocBlock(P^.N*SizeOf(TPt)+16);
 M:=0;
 For I:=0 to P^.N-1do Begin
  X:=FloorR(P^.Pts^[I].X/Cell+0.5)*Cell;
  Y:=FloorR(P^.Pts^[I].Y/Cell+0.5)*Cell;
  If(M=0)or(X<>Q^[M-1].X)or(Y<>Q^[M-1].Y)Then Begin
   Q^[M].X:=X;Q^[M].Y:=Y;Inc(M);
  End;
 End;
 If(Closed and(M<4))or((Not Closed)and(M<2))Then Begin
  FreeMem(Q,P^.N*SizeOf(TPt)+16);
  Exit;
 End;
 Pa:=NewPath(G,M,Poly);
 Move(Q^,Pa^.Pts^,M*SizeOf(TPt));
 Pa^.N:=M;
 FreeMem(Q,P^.N*SizeOf(TPt)+16);
 SnapGridPath:=True;
End;

{ Ajoute Cnt sommets regulierement espaces sur chaque segment }
Procedure DensifyPath(P:PPath;Cnt:LongInt;Var G:TGeom;Poly:Integer);
Var
 I,K,N:LongInt;
 Pa:PPath;
 T:Real;
Begin
 N:=(P^.N-1)*(Cnt+1)+1;
 Pa:=NewPath(G,N,Poly);
 K:=0;
 For I:=0 to P^.N-2do Begin
  For N:=0 to Cnt do Begin
   T:=N/(Cnt+1);
   Pa^.Pts^[K].X:=P^.Pts^[I].X+T*(P^.Pts^[I+1].X-P^.Pts^[I].X);
   Pa^.Pts^[K].Y:=P^.Pts^[I].Y+T*(P^.Pts^[I+1].Y-P^.Pts^[I].Y);
   Inc(K);
  End;
 End;
 Pa^.Pts^[K]:=P^.Pts^[P^.N-1];
 Pa^.N:=K+1;
End;

{ Lissage de Chaikin (iterations, decalage 0..0.5, angle maxi des noeuds lisses) }
Procedure SmoothPath(P:PPath;Iter:Integer;Off,MaxAngle:Real;Closed:Boolean;Var G:TGeom;Poly:Integer);
Var
 Cur,Nxt:PPts;
 N,M,I,K,It,J:LongInt;
 Ax,Ay,Bx,By,Cx,Cy,L1,L2,Ang:Real;
 Pa:PPath;
 Smooth:Boolean;
Begin
 Cur:=UniquePts(P,N);
 If Closed and(N>1)and(Cur^[0].X=Cur^[N-1].X)and(Cur^[0].Y=Cur^[N-1].Y)Then Dec(N);
 For It:=1 to Iter do Begin
  Nxt:=AllocBlock((2*N+3)*SizeOf(TPt));
  M:=0;
  If Not Closed Then Begin Nxt^[0]:=Cur^[0];M:=1;End;
  For I:=0 to N-1do Begin
   J:=(I+1)mod N;
   If Closed or(I<N-1)Then Begin
    { sommet I lisse ? (angle interieur entre les segments adjacents) }
    Smooth:=True;
    If Closed or(I>0)Then Begin
     K:=(I+N-1)mod N;
     Ax:=Cur^[K].X-Cur^[I].X;Ay:=Cur^[K].Y-Cur^[I].Y;
     Bx:=Cur^[J].X-Cur^[I].X;By:=Cur^[J].Y-Cur^[I].Y;
     L1:=Sqrt(Ax*Ax+Ay*Ay);L2:=Sqrt(Bx*Bx+By*By);
     If(L1>0)and(L2>0)Then Begin
      Cx:=(Ax*Bx+Ay*By)/(L1*L2);
      If Cx>1Then Cx:=1;
      If Cx<-1Then Cx:=-1;
      Ang:=Rad2Deg(ArcSin(Sqrt(1-Cx*Cx)));
      If Cx<0Then Ang:=180-Ang;
      Smooth:=Ang<=MaxAngle;
     End;
    End;
    If Smooth or(Not(Closed or(I>0)))Then Begin
     If Not Closed and(I=0)and(N>2)Then Begin
      Nxt^[M].X:=Cur^[I].X+(1-Off)*(Cur^[J].X-Cur^[I].X);Nxt^[M].Y:=Cur^[I].Y+(1-Off)*(Cur^[J].Y-Cur^[I].Y);
      Inc(M);
     End
      Else
     If Not Closed and(I=N-2)and(N>2)Then Begin
      Nxt^[M].X:=Cur^[I].X+Off*(Cur^[J].X-Cur^[I].X);Nxt^[M].Y:=Cur^[I].Y+Off*(Cur^[J].Y-Cur^[I].Y);
      Inc(M);
     End
      Else
     Begin
      Nxt^[M].X:=Cur^[I].X+Off*(Cur^[J].X-Cur^[I].X);Nxt^[M].Y:=Cur^[I].Y+Off*(Cur^[J].Y-Cur^[I].Y);
      Inc(M);
      Nxt^[M].X:=Cur^[I].X+(1-Off)*(Cur^[J].X-Cur^[I].X);Nxt^[M].Y:=Cur^[I].Y+(1-Off)*(Cur^[J].Y-Cur^[I].Y);
      Inc(M);
     End;
    End
     Else
    Begin
     Nxt^[M]:=Cur^[I];Inc(M);
    End;
   End;
  End;
  If Not Closed Then Begin Nxt^[M]:=Cur^[N-1];Inc(M);End;
  FreeMem(Cur,0);
  Cur:=Nxt;
  N:=M;
 End;
 If Closed Then Begin
  Pa:=NewPath(G,N+1,Poly);
  Move(Cur^,Pa^.Pts^,N*SizeOf(TPt));
  Pa^.Pts^[N]:=Pa^.Pts^[0];
  Pa^.N:=N+1;
 End
  Else
 Begin
  Pa:=NewPath(G,N,Poly);
  Move(Cur^,Pa^.Pts^,N*SizeOf(TPt));
  Pa^.N:=N;
 End;
End;

{ Point a la distance D le long d'un chemin ; Ang = azimut du segment (degres, horaire depuis le nord) }
Function PointAlong(P:PPath;D:Real;Var X,Y,Ang:Real):Boolean;
Var
 I:LongInt;
 L,Acc:Real;
Begin
 PointAlong:=False;
 If D<0Then Exit;
 Acc:=0;
 For I:=0 to P^.N-2do Begin
  L:=Sqrt(Sqr(P^.Pts^[I+1].X-P^.Pts^[I].X)+Sqr(P^.Pts^[I+1].Y-P^.Pts^[I].Y));
  If(D<=Acc+L)and(L>0)Then Begin
   X:=P^.Pts^[I].X+(D-Acc)/L*(P^.Pts^[I+1].X-P^.Pts^[I].X);
   Y:=P^.Pts^[I].Y+(D-Acc)/L*(P^.Pts^[I+1].Y-P^.Pts^[I].Y);
   Ang:=NormDeg(Rad2Deg(Atan2(P^.Pts^[I+1].X-P^.Pts^[I].X,P^.Pts^[I+1].Y-P^.Pts^[I].Y)));
   PointAlong:=True;
   Exit;
  End;
  Acc:=Acc+L;
 End;
End;

{ Portion d'un chemin entre les distances D1 et D2 }
Function SubLine(P:PPath;D1,D2:Real;Var G:TGeom;Poly:Integer):Boolean;
Var
 Buf:PPts;
 I,N:LongInt;
 L,Acc,X,Y,A,T:Real;
 Pa:PPath;
Begin
 SubLine:=False;
 If D2<=D1 Then Exit;
 Buf:=AllocBlock((P^.N+3)*SizeOf(TPt));
 N:=0;
 Acc:=0;
 For I:=0 to P^.N-2do Begin
  L:=Sqrt(Sqr(P^.Pts^[I+1].X-P^.Pts^[I].X)+Sqr(P^.Pts^[I+1].Y-P^.Pts^[I].Y));
  If L>0Then Begin
   If(D1>=Acc)and(D1<=Acc+L)and(N=0)Then Begin
    T:=(D1-Acc)/L;
    Buf^[N].X:=P^.Pts^[I].X+T*(P^.Pts^[I+1].X-P^.Pts^[I].X);
    Buf^[N].Y:=P^.Pts^[I].Y+T*(P^.Pts^[I+1].Y-P^.Pts^[I].Y);
    Inc(N);
   End;
   If(N>0)and(D2>=Acc)and(D2<=Acc+L)Then Begin
    T:=(D2-Acc)/L;
    Buf^[N].X:=P^.Pts^[I].X+T*(P^.Pts^[I+1].X-P^.Pts^[I].X);
    Buf^[N].Y:=P^.Pts^[I].Y+T*(P^.Pts^[I+1].Y-P^.Pts^[I].Y);
    Inc(N);
    Break;
   End;
   If(N>0)and(Acc+L<D2)Then Begin
    Buf^[N]:=P^.Pts^[I+1];
    Inc(N);
   End;
  End;
  Acc:=Acc+L;
 End;
 If N>=2Then Begin
  Pa:=NewPath(G,N,Poly);
  Move(Buf^,Pa^.Pts^,N*SizeOf(TPt));
  Pa^.N:=N;
  SubLine:=True;
 End;
 FreeMem(Buf,(P^.N+3)*SizeOf(TPt));
End;

{ ---- relations spatiales ---- }

{ Point par rapport a un ensemble de polygones (regle pair/impair) : 0 dehors, 1 dedans, 2 sur le bord }
Function PtInPolys(Var G:TGeom;X,Y,Tol:Real):Integer;
Var
 P:PPath;
 Cnt,S:Integer;
Begin
 Cnt:=0;
 P:=G.First;
 While P<>Nil do Begin
  S:=PointInRing(P,X,Y,Tol);
  If S=2Then Begin PtInPolys:=2;Exit;End;
  If S=1Then Inc(Cnt);
  P:=P^.Next;
 End;
 If Odd(Cnt)Then PtInPolys:=1 Else PtInPolys:=0;
End;

{ Distance d'un point a une geometrie }
Function DistPtGeom(Var G:TGeom;X,Y:Real):Real;
Var
 P:PPath;
 I:LongInt;
 D,Best:Real;
Begin
 Best:=1E300;
 If G.Cls=3Then Begin
  If PtInPolys(G,X,Y,0)>0Then Begin DistPtGeom:=0;Exit;End;
 End;
 P:=G.First;
 While P<>Nil do Begin
  If P^.N=1Then Begin
   D:=Sqrt(Sqr(X-P^.Pts^[0].X)+Sqr(Y-P^.Pts^[0].Y));
   If D<Best Then Best:=D;
  End
   Else
  For I:=0 to P^.N-2do Begin
   D:=DistSeg(X,Y,P^.Pts^[I].X,P^.Pts^[I].Y,P^.Pts^[I+1].X,P^.Pts^[I+1].Y);
   If D<Best Then Best:=D;
  End;
  P:=P^.Next;
 End;
 DistPtGeom:=Best;
End;

{ Point le plus proche de (X,Y) sur le segment A-B }
Procedure ClosestOnSeg(Px,Py,X1,Y1,X2,Y2:Real;Var Cx,Cy:Real);
Var
 Dx,Dy,L2,T:Real;
Begin
 Dx:=X2-X1;Dy:=Y2-Y1;
 L2:=Dx*Dx+Dy*Dy;
 If L2<=0Then T:=0
  Else
 Begin
  T:=((Px-X1)*Dx+(Py-Y1)*Dy)/L2;
  If T<0Then T:=0;
  If T>1Then T:=1;
 End;
 Cx:=X1+T*Dx;Cy:=Y1+T*Dy;
End;

{ Point de G le plus proche de (X,Y) ; retourne la distance }
Function NearestOnGeom(Var G:TGeom;X,Y:Real;Var Cx,Cy:Real):Real;
Var
 P:PPath;
 I:LongInt;
 D,Best,Qx,Qy:Real;
Begin
 Best:=1E300;
 Cx:=X;Cy:=Y;
 If(G.Cls=3)and(PtInPolys(G,X,Y,0)>0)Then Begin NearestOnGeom:=0;Exit;End;
 P:=G.First;
 While P<>Nil do Begin
  If P^.N=1Then Begin
   D:=Sqrt(Sqr(X-P^.Pts^[0].X)+Sqr(Y-P^.Pts^[0].Y));
   If D<Best Then Begin Best:=D;Cx:=P^.Pts^[0].X;Cy:=P^.Pts^[0].Y;End;
  End
   Else
  For I:=0 to P^.N-2do Begin
   ClosestOnSeg(X,Y,P^.Pts^[I].X,P^.Pts^[I].Y,P^.Pts^[I+1].X,P^.Pts^[I+1].Y,Qx,Qy);
   D:=Sqrt(Sqr(X-Qx)+Sqr(Y-Qy));
   If D<Best Then Begin Best:=D;Cx:=Qx;Cy:=Qy;End;
  End;
  P:=P^.Next;
 End;
 NearestOnGeom:=Best;
End;

{ Paire de points la plus proche entre deux geometries ; retourne la distance }
Function NearestPoints(Var A,B:TGeom;Var Ax,Ay,Bx,By:Real):Real;
Var
 P:PPath;
 I:LongInt;
 D,Best,Cx,Cy:Real;
Begin
 Best:=1E300;
 Ax:=0;Ay:=0;Bx:=0;By:=0;
 P:=A.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-1do Begin
   D:=NearestOnGeom(B,P^.Pts^[I].X,P^.Pts^[I].Y,Cx,Cy);
   If D<Best Then Begin Best:=D;Ax:=P^.Pts^[I].X;Ay:=P^.Pts^[I].Y;Bx:=Cx;By:=Cy;End;
  End;
  P:=P^.Next;
 End;
 P:=B.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-1do Begin
   D:=NearestOnGeom(A,P^.Pts^[I].X,P^.Pts^[I].Y,Cx,Cy);
   If D<Best Then Begin Best:=D;Bx:=P^.Pts^[I].X;By:=P^.Pts^[I].Y;Ax:=Cx;Ay:=Cy;End;
  End;
  P:=P^.Next;
 End;
 NearestPoints:=Best;
End;

{ Des segments (de lignes ou d'anneaux) de A et B se coupent-ils ? Cross : coupure franche seulement }
Function SegmentsMeet(Var A,B:TGeom;Cross:Boolean):Boolean;
Var
 P,Q:PPath;
 I,J:LongInt;
 Ix,Iy,Rx,Ry,Sx,Sy,Den,T,U,E:Real;
Begin
 SegmentsMeet:=False;
 If Cross Then E:=1E-12 Else E:=-1E-12;
 P:=A.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-2do Begin
   Q:=B.First;
   While Q<>Nil do Begin
    For J:=0 to Q^.N-2do Begin
     Rx:=P^.Pts^[I+1].X-P^.Pts^[I].X;Ry:=P^.Pts^[I+1].Y-P^.Pts^[I].Y;
     Sx:=Q^.Pts^[J+1].X-Q^.Pts^[J].X;Sy:=Q^.Pts^[J+1].Y-Q^.Pts^[J].Y;
     Den:=Rx*Sy-Ry*Sx;
     If Abs(Den)>1E-14*Sqrt(Rx*Rx+Ry*Ry)*Sqrt(Sx*Sx+Sy*Sy)Then Begin
      T:=((Q^.Pts^[J].X-P^.Pts^[I].X)*Sy-(Q^.Pts^[J].Y-P^.Pts^[I].Y)*Sx)/Den;
      U:=((Q^.Pts^[J].X-P^.Pts^[I].X)*Ry-(Q^.Pts^[J].Y-P^.Pts^[I].Y)*Rx)/Den;
      If(T>=E)and(T<=1-E)and(U>=E)and(U<=1-E)Then Begin
       SegmentsMeet:=True;
       Exit;
      End;
     End
      Else
     If Not Cross Then Begin
      { paralleles : se touchent-ils ? }
      If(DistSeg(Q^.Pts^[J].X,Q^.Pts^[J].Y,P^.Pts^[I].X,P^.Pts^[I].Y,P^.Pts^[I+1].X,P^.Pts^[I+1].Y)<1E-12)or
        (DistSeg(Q^.Pts^[J+1].X,Q^.Pts^[J+1].Y,P^.Pts^[I].X,P^.Pts^[I].Y,P^.Pts^[I+1].X,P^.Pts^[I+1].Y)<1E-12)Then Begin
       SegmentsMeet:=True;
       Exit;
      End;
      If(DistSeg(P^.Pts^[I].X,P^.Pts^[I].Y,Q^.Pts^[J].X,Q^.Pts^[J].Y,Q^.Pts^[J+1].X,Q^.Pts^[J+1].Y)<1E-12)or
        (DistSeg(P^.Pts^[I+1].X,P^.Pts^[I+1].Y,Q^.Pts^[J].X,Q^.Pts^[J].Y,Q^.Pts^[J+1].X,Q^.Pts^[J+1].Y)<1E-12)Then Begin
       SegmentsMeet:=True;
       Exit;
      End;
     End;
    End;
    Q:=Q^.Next;
   End;
  End;
  P:=P^.Next;
 End;
End;

Function BoxesTouch(Var A,B:TGeom):Boolean;
Var
 X1,Y1,X2,Y2,U1,V1,U2,V2:Real;
Begin
 BoxesTouch:=False;
 If Not GeomBBox(A,X1,Y1,X2,Y2)Then Exit;
 If Not GeomBBox(B,U1,V1,U2,V2)Then Exit;
 BoxesTouch:=Not((U1>X2)or(U2<X1)or(V1>Y2)or(V2<Y1));
End;

Function GeomIntersects(Var A,B:TGeom):Boolean;
Var
 P:PPath;
 I:LongInt;
Begin
 GeomIntersects:=False;
 If(A.First=Nil)or(B.First=Nil)Then Exit;
 If Not BoxesTouch(A,B)Then Exit;
 If A.Cls=1Then Begin
  P:=A.First;
  While P<>Nil do Begin
   If DistPtGeom(B,P^.Pts^[0].X,P^.Pts^[0].Y)<=1E-12Then Begin GeomIntersects:=True;Exit;End;
   P:=P^.Next;
  End;
  Exit;
 End;
 If B.Cls=1Then Begin
  P:=B.First;
  While P<>Nil do Begin
   If DistPtGeom(A,P^.Pts^[0].X,P^.Pts^[0].Y)<=1E-12Then Begin GeomIntersects:=True;Exit;End;
   P:=P^.Next;
  End;
  Exit;
 End;
 If SegmentsMeet(A,B,False)Then Begin GeomIntersects:=True;Exit;End;
 { un objet entierement a l'interieur d'un polygone de l'autre }
 If B.Cls=3Then Begin
  P:=A.First;
  While P<>Nil do Begin
   If PtInPolys(B,P^.Pts^[0].X,P^.Pts^[0].Y,1E-12)>0Then Begin GeomIntersects:=True;Exit;End;
   P:=P^.Next;
  End;
 End;
 If A.Cls=3Then Begin
  P:=B.First;
  While P<>Nil do Begin
   If PtInPolys(A,P^.Pts^[0].X,P^.Pts^[0].Y,1E-12)>0Then Begin GeomIntersects:=True;Exit;End;
   P:=P^.Next;
  End;
 End;
End;

{ A contient B (au sens OGC, a la precision numerique pres) }
Function GeomContains(Var A,B:TGeom):Boolean;
Var
 P:PPath;
 I:LongInt;
 S:Integer;
 Inside,Mx,My:Real;
 AnyIn:Boolean;
Begin
 GeomContains:=False;
 If(A.First=Nil)or(B.First=Nil)Then Exit;
 If Not BoxesTouch(A,B)Then Exit;
 AnyIn:=False;
 If A.Cls=3Then Begin
  P:=B.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-1do Begin
    S:=PtInPolys(A,P^.Pts^[I].X,P^.Pts^[I].Y,1E-12);
    If S=0Then Exit;
    If S=1Then AnyIn:=True;
    If(I<P^.N-1)and(P^.N>1)Then Begin
     Mx:=(P^.Pts^[I].X+P^.Pts^[I+1].X)/2;My:=(P^.Pts^[I].Y+P^.Pts^[I+1].Y)/2;
     S:=PtInPolys(A,Mx,My,1E-12);
     If S=0Then Exit;
     If S=1Then AnyIn:=True;
    End;
   End;
   P:=P^.Next;
  End;
  { un trou de A ne doit pas etre a l'interieur de B }
  If B.Cls=3Then Begin
   P:=A.First;
   While P<>Nil do Begin
    If(P<>A.First)and(P^.Poly=A.First^.Poly)Then
     If PtInPolys(B,P^.Pts^[0].X,P^.Pts^[0].Y,1E-12)=1Then Exit;
    P:=P^.Next;
   End;
  End;
  GeomContains:=AnyIn;
  Exit;
 End;
 If A.Cls=2Then Begin
  If B.Cls=3Then Exit;
  P:=B.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-1do Begin
    If DistPtGeom(A,P^.Pts^[I].X,P^.Pts^[I].Y)>1E-12Then Exit;
    If(I<P^.N-1)and(P^.N>1)Then
     If DistPtGeom(A,(P^.Pts^[I].X+P^.Pts^[I+1].X)/2,(P^.Pts^[I].Y+P^.Pts^[I+1].Y)/2)>1E-12Then Exit;
   End;
   P:=P^.Next;
  End;
  GeomContains:=True;
  Exit;
 End;
 { A est un ensemble de points }
 If B.Cls<>1Then Exit;
 P:=B.First;
 While P<>Nil do Begin
  If DistPtGeom(A,P^.Pts^[0].X,P^.Pts^[0].Y)>1E-12Then Exit;
  P:=P^.Next;
 End;
 GeomContains:=True;
End;

{ Aire de l'intersection de deux geometries polygonales }
Function OverlapArea(Var A,B:TGeom):Real;
Var
 R:TGeom;
 X:Real;
Begin
 Overlay(1,A,B,R);
 X:=GeomArea(R);
 FreeGeom(R);
 OverlapArea:=X;
End;

{ Predicats : 0 intersecte, 1 contient, 2 disjoint, 3 egal, 4 touche, 5 chevauche, 6 est a l'interieur, 7 croise }
{ ---- matrice DE-9IM ---- }

Procedure NodeSegments(Var G:TGeom;Var Sub:PEdges;Var NU:LongInt;Var SubCap:LongInt);Forward;

Function GeomDim(Var G:TGeom):Integer;Begin
 GeomDim:=G.Cls-1;
End;

{ Points frontiere (regle mod 2) d'un ensemble de lignes }
Procedure LineBoundary(Var G:TGeom;Var Pts:PPts;Var N:LongInt);
Var
 P:PPath;
 Cnt,I,J,Tot:LongInt;
 Cand:PPts;
Begin
 N:=0;
 Tot:=0;
 P:=G.First;
 While P<>Nil do Begin Inc(Tot,2);P:=P^.Next;End;
 Cand:=AllocBlock((Tot+1)*SizeOf(TPt));
 Pts:=AllocBlock((Tot+1)*SizeOf(TPt));
 Tot:=0;
 P:=G.First;
 While P<>Nil do Begin
  If P^.N>=2Then Begin
   Cand^[Tot]:=P^.Pts^[0];Inc(Tot);
   Cand^[Tot]:=P^.Pts^[P^.N-1];Inc(Tot);
  End;
  P:=P^.Next;
 End;
 For I:=0 to Tot-1do Begin
  Cnt:=0;
  For J:=0 to Tot-1do
   If(Abs(Cand^[I].X-Cand^[J].X)<=1E-12)and(Abs(Cand^[I].Y-Cand^[J].Y)<=1E-12)Then Inc(Cnt);
  If Cnt mod 2=1Then Begin
   Cnt:=0;
   For J:=0 to N-1do
    If(Abs(Pts^[J].X-Cand^[I].X)<=1E-12)and(Abs(Pts^[J].Y-Cand^[I].Y)<=1E-12)Then Inc(Cnt);
   If Cnt=0Then Begin Pts^[N]:=Cand^[I];Inc(N);End;
  End;
 End;
 FreeMem(Cand,(Tot+1)*SizeOf(TPt));
End;

{ Position d'un point par rapport a une geometrie : 0 interieur, 1 frontiere, 2 exterieur }
Function GeomLoc(Var G:TGeom;Bnd:PPts;NB:LongInt;X,Y,Tol:Real):Integer;
Var
 I:LongInt;
 P:PPath;
 S:Integer;
Begin
 GeomLoc:=2;
 Case G.Cls of
  3:Begin
   S:=PtInPolys(G,X,Y,Tol);
   If S=1Then GeomLoc:=0 Else If S=2Then GeomLoc:=1;
  End;
  2:Begin
   For I:=0 to NB-1do
    If(Abs(Bnd^[I].X-X)<=Tol)and(Abs(Bnd^[I].Y-Y)<=Tol)Then Begin GeomLoc:=1;Exit;End;
   If DistPtGeom(G,X,Y)<=Tol Then GeomLoc:=0;
  End;
  1:Begin
   P:=G.First;
   While P<>Nil do Begin
    If(Abs(P^.Pts^[0].X-X)<=Tol)and(Abs(P^.Pts^[0].Y-Y)<=Tol)Then Begin GeomLoc:=0;Exit;End;
    P:=P^.Next;
   End;
  End;
 End;
End;

Function MaxDim(A,B:Integer):Integer;Begin
 If A>B Then MaxDim:=A Else MaxDim:=B;
End;

{ Calcule la matrice DE-9IM (neuf caracteres F, 0, 1, 2) }
Function RelateGeoms(Var A,B:TGeom):String;
Var
 M:Array[0..2,0..2]of Integer;
 C:TGeom;
 P,Q:PPath;
 Sub:PEdges;
 NU,SubCap,I,J,K,NbA,NbB:LongInt;
 BA,BB:PPts;
 MinX,MinY,MaxX,MaxY,X1,Y1,X2,Y2,Ext,Tol,Mx,My,Ar,Ia,Ib:Real;
 La,Lb:Integer;
 S:String;
 Have:Boolean;

 Procedure Upd(Pt,Qt,D:Integer);Begin
  If D>M[Pt,Qt]Then M[Pt,Qt]:=D;
 End;

 Procedure Classify(X,Y:Real;D:Integer);Begin
  Upd(GeomLoc(A,BA,NbA,X,Y,Tol),GeomLoc(B,BB,NbB,X,Y,Tol),D);
 End;

Begin
 For I:=0 to 2do For J:=0 to 2do M[I,J]:=-1;
 M[2,2]:=2;
 If(A.First=Nil)or(B.First=Nil)Then Begin
  { geometrie vide : tout est exterieur }
  If A.First<>Nil Then Begin M[0,2]:=GeomDim(A);If A.Cls>1Then M[1,2]:=A.Cls-2;End;
  If B.First<>Nil Then Begin M[2,0]:=GeomDim(B);If B.Cls>1Then M[2,1]:=B.Cls-2;End;
 End
  Else
 Begin
  Have:=GeomBBox(A,MinX,MinY,MaxX,MaxY);
  If GeomBBox(B,X1,Y1,X2,Y2)Then Begin
   If X1<MinX Then MinX:=X1;If Y1<MinY Then MinY:=Y1;
   If X2>MaxX Then MaxX:=X2;If Y2>MaxY Then MaxY:=Y2;
  End;
  Ext:=MaxR(MaxX-MinX,MaxY-MinY);
  If Ext<=0Then Ext:=1;
  Tol:=Ext*1E-7;
  BA:=Nil;BB:=Nil;NbA:=0;NbB:=0;
  If A.Cls=2Then LineBoundary(A,BA,NbA);
  If B.Cls=2Then LineBoundary(B,BB,NbB);
  { points isoles }
  If A.Cls=1Then Begin
   P:=A.First;
   While P<>Nil do Begin Classify(P^.Pts^[0].X,P^.Pts^[0].Y,0);P:=P^.Next;End;
  End;
  If B.Cls=1Then Begin
   P:=B.First;
   While P<>Nil do Begin Classify(P^.Pts^[0].X,P^.Pts^[0].Y,0);P:=P^.Next;End;
  End;
  { lignes de A et de B ensemble, noeudees }
  If(A.Cls>1)or(B.Cls>1)Then Begin
   InitGeom(C);C.Cls:=2;
   If A.Cls>1Then Begin P:=A.First;While P<>Nil do Begin CopyPath(C,P,0);P:=P^.Next;End;End;
   If B.Cls>1Then Begin P:=B.First;While P<>Nil do Begin CopyPath(C,P,0);P:=P^.Next;End;End;
   NodeSegments(C,Sub,NU,SubCap);
   For I:=0 to NU-1do Begin
    Mx:=(Sub^[I].X1+Sub^[I].X2)/2;My:=(Sub^[I].Y1+Sub^[I].Y2)/2;
    { evite un echantillon qui tombe sur un point isole }
    If(A.Cls=1)or(B.Cls=1)Then Begin
     For K:=1 to 3do Begin
      Ar:=0.5;
      If K=2Then Ar:=0.37;
      If K=3Then Ar:=0.71;
      Mx:=Sub^[I].X1+Ar*(Sub^[I].X2-Sub^[I].X1);My:=Sub^[I].Y1+Ar*(Sub^[I].Y2-Sub^[I].Y1);
      If(GeomLoc(A,BA,NbA,Mx,My,Tol)<>0)or(A.Cls<>1)Then
       If(GeomLoc(B,BB,NbB,Mx,My,Tol)<>0)or(B.Cls<>1)Then Break;
     End;
    End;
    If Sqrt(Sqr(Sub^[I].X2-Sub^[I].X1)+Sqr(Sub^[I].Y2-Sub^[I].Y1))>Tol*20Then Classify(Mx,My,1);
    Classify(Sub^[I].X1,Sub^[I].Y1,0);
    Classify(Sub^[I].X2,Sub^[I].Y2,0);
   End;
   FreeGeom(C);
   If NU>0Then FreeMem(Sub,(NU+1)*SizeOf(TEdge));
  End;
  { entrees de dimension 2 }
  If(A.Cls=3)and(B.Cls=3)Then Begin
   Ia:=OverlapArea(A,B);
   Ar:=GeomArea(A);Ib:=GeomArea(B);
   If Ia>1E-9*MaxR(Ar,Ib)Then M[0,0]:=2;
   If Ar-Ia>1E-9*Ar Then M[0,2]:=2;
   If Ib-Ia>1E-9*Ib Then M[2,0]:=2;
  End Else
  Begin
   If A.Cls=3Then M[0,2]:=2;
   If B.Cls=3Then M[2,0]:=2;
  End;
  If(A.Cls=2)and(B.Cls=1)Then M[0,2]:=1;
  If(A.Cls=1)and(B.Cls=2)Then M[2,0]:=1;
 End;
 S:='';
 For I:=0 to 2do For J:=0 to 2do
  If M[I,J]<0Then S:=S+'F' Else S:=S+Chr(48+M[I,J]);
 RelateGeoms:=S;
End;

{ Compare une matrice a un motif (T, F, *, 0, 1, 2) }
Function RelateMatch(Const M,Pat:String):Boolean;
Var
 I:Integer;
Begin
 RelateMatch:=False;
 If(Length(M)<>9)or(Length(Pat)<>9)Then Exit;
 For I:=1 to 9do Begin
  Case Pat[I]of
   '*':;
   'T','t':If M[I]='F'Then Exit;
   'F','f':If M[I]<>'F'Then Exit;
   Else If M[I]<>Pat[I]Then Exit;
  End;
 End;
 RelateMatch:=True;
End;

{ Predicats nommes calcules sur la matrice }
Function RelatePredicate(Pred:Integer;Var A,B:TGeom):Boolean;
Var
 M:String;
 Da,Db:Integer;
Begin
 RelatePredicate:=False;
 If(A.First=Nil)or(B.First=Nil)Then Exit;
 M:=RelateGeoms(A,B);
 Da:=GeomDim(A);Db:=GeomDim(B);
 Case Pred of
  3:RelatePredicate:=RelateMatch(M,'T*F**FFF*');
  4:If Not((Da=0)and(Db=0))Then
     RelatePredicate:=RelateMatch(M,'FT*******')or RelateMatch(M,'F**T*****')or RelateMatch(M,'F***T****');
  5:If Da=Db Then Begin
     If Da=1Then RelatePredicate:=RelateMatch(M,'1*T***T**')
            Else RelatePredicate:=RelateMatch(M,'T*T***T**');
    End;
  7:Begin
     If Da<Db Then RelatePredicate:=RelateMatch(M,'T*T******') Else
     If Da>Db Then RelatePredicate:=RelateMatch(M,'T*****T**') Else
     If(Da=1)and(Db=1)Then RelatePredicate:=RelateMatch(M,'0********');
    End;
  8:RelatePredicate:=RelateMatch(M,'T*****FF*')or RelateMatch(M,'*T****FF*')or RelateMatch(M,'***T**FF*')or RelateMatch(M,'****T*FF*');
  9:RelatePredicate:=RelateMatch(M,'T*F**F***');
  10:RelatePredicate:=RelateMatch(M,'T*****FF*');
 End;
End;

Procedure ClipToPolys(Var G,B:TGeom;Var R:TGeom);Forward;

Function GeomPredicate(Pred:Integer;Var A,B:TGeom):Boolean;
Var
 LineG,InG,OutG:TGeom;
 Hit:Boolean;
 Ar,Ia,Aa,Ab:Real;
 P:PPath;
 AnyIn,AnyOut:Boolean;
 I:LongInt;
 S:Integer;
 Buf:TGeom;
Begin
 GeomPredicate:=False;
 Case Pred of
  0:GeomPredicate:=GeomIntersects(A,B);
  1:Begin
   GeomPredicate:=GeomContains(A,B);
   If GeomPredicate and Not((A.Cls=3)and(B.Cls=1))Then GeomPredicate:=RelatePredicate(10,A,B)
    Else
   If(Not GeomPredicate)and(A.Cls=3)and(B.Cls=3)Then GeomPredicate:=RelatePredicate(10,A,B);
  End;
  2:GeomPredicate:=Not GeomIntersects(A,B);
  6:Begin
   GeomPredicate:=GeomContains(B,A);
   If GeomPredicate and Not((B.Cls=3)and(A.Cls=1))Then GeomPredicate:=RelatePredicate(9,A,B)
    Else
   If(Not GeomPredicate)and(A.Cls=3)and(B.Cls=3)Then GeomPredicate:=RelatePredicate(9,A,B);
  End;
  3,4,5,7,8:Begin
   If Not GeomIntersects(A,B)Then Exit;
   GeomPredicate:=RelatePredicate(Pred,A,B);
  End;
 End;
End;

{ Convertit une geometrie aplatie en noeud GeoJSON selon sa classe (Nil si vide) }
Function BuildGeom(Var G:TGeom):PJ;Begin
 Case G.Cls of
  1:BuildGeom:=BuildPoints(G);
  2:BuildGeom:=BuildLines(G);
  3:BuildGeom:=BuildPolygons(G);
  Else BuildGeom:=Nil;
 End;
End;

Procedure PointGeom(Var G:TGeom;X,Y:Real);
Var
 P:PPath;
Begin
 InitGeom(G);
 G.Cls:=1;
 P:=NewPath(G,1,0);
 P^.Pts^[0].X:=X;P^.Pts^[0].Y:=Y;
End;

{ Point garanti a l'interieur d'une geometrie }
Procedure PointOnSurface(Var G:TGeom;Var X,Y:Real);
Var
 Cx,Cy,MinX,MinY,MaxX,MaxY,Yy,Best,Xa,Xb,Tmp,X1,Y1,X2,Y2:Real;
 Ok:Boolean;
 Xs:PReals;
 P:PPath;
 Cap,NX,I,K:LongInt;
 Tries:Integer;
Begin
 X:=0;Y:=0;
 If G.First=Nil Then Exit;
 If G.Cls=1Then Begin X:=G.First^.Pts^[0].X;Y:=G.First^.Pts^[0].Y;Exit;End;
 If G.Cls=2Then Begin
  Y1:=PathLength(G.First)/2;
  If PointAlong(G.First,Y1,X,Y,X1)Then Exit;
  X:=G.First^.Pts^[0].X;Y:=G.First^.Pts^[0].Y;
  Exit;
 End;
 CentroidGeom(G,Cx,Cy,Ok);
 If Not GeomBBox(G,MinX,MinY,MaxX,MaxY)Then Exit;
 If Ok and(PtInPolys(G,Cx,Cy,0)=1)Then Begin X:=Cx;Y:=Cy;Exit;End;
 Cap:=0;
 P:=G.First;
 While P<>Nil do Begin Inc(Cap,P^.N);P:=P^.Next;End;
 Xs:=AllocBlock((Cap+2)*SizeOf(Real));
 Best:=-1;
 X:=G.First^.Pts^[0].X;Y:=G.First^.Pts^[0].Y;
 { balayage horizontal a plusieurs hauteurs : on garde l'intervalle le plus long }
 For Tries:=0 to 8do Begin
  If Tries=0Then Yy:=Cy Else Yy:=MinY+(MaxY-MinY)*Tries/9;
  NX:=0;
  P:=G.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-1do Begin
    K:=I+1;
    If K>=P^.N Then K:=0;
    X1:=P^.Pts^[I].X;Y1:=P^.Pts^[I].Y;X2:=P^.Pts^[K].X;Y2:=P^.Pts^[K].Y;
    If(Y1<=Yy)<>(Y2<=Yy)Then Begin
     Xs^[NX]:=X1+(Yy-Y1)*(X2-X1)/(Y2-Y1);
     Inc(NX);
    End;
   End;
   P:=P^.Next;
  End;
  For I:=1 to NX-1do Begin
   Tmp:=Xs^[I];K:=I-1;
   While(K>=0)and(Xs^[K]>Tmp)do Begin Xs^[K+1]:=Xs^[K];Dec(K);End;
   Xs^[K+1]:=Tmp;
  End;
  I:=0;
  While I+1<NX do Begin
   Xa:=Xs^[I];Xb:=Xs^[I+1];
   If Xb-Xa>Best Then Begin Best:=Xb-Xa;X:=(Xa+Xb)/2;Y:=Yy;End;
   Inc(I,2);
  End;
 End;
 FreeMem(Xs,(Cap+2)*SizeOf(Real));
End;

{ Rectangle englobant oriente d'aire minimale ; Ang = azimut du grand cote }
Procedure MinOrientedBox(Var G:TGeom;Var R:TGeom;Var Area,Ang,W,H:Real);
Var
 Hull:TGeom;
 P:PPath;
 I,J,N:LongInt;
 Dx,Dy,L,Ux,Uy,Vx,Vy,MinU,MaxU,MinV,MaxV,U,V,A,BestA,Bu0,Bu1,Bv0,Bv1,Bux,Buy:Real;
 Pa:PPath;
Begin
 InitGeom(R);
 Area:=0;Ang:=0;W:=0;H:=0;
 HullGeom(G,Hull);
 If Hull.Cls<>3Then Begin FreeGeom(Hull);Exit;End;
 P:=Hull.First;
 N:=P^.N-1;
 BestA:=1E300;
 Bux:=1;Buy:=0;Bu0:=0;Bu1:=0;Bv0:=0;Bv1:=0;
 For I:=0 to N-1do Begin
  J:=(I+1)mod N;
  Dx:=P^.Pts^[J].X-P^.Pts^[I].X;Dy:=P^.Pts^[J].Y-P^.Pts^[I].Y;
  L:=Sqrt(Dx*Dx+Dy*Dy);
  If L>0Then Begin
   Ux:=Dx/L;Uy:=Dy/L;Vx:=-Uy;Vy:=Ux;
   MinU:=1E300;MaxU:=-1E300;MinV:=1E300;MaxV:=-1E300;
   For J:=0 to N-1do Begin
    U:=P^.Pts^[J].X*Ux+P^.Pts^[J].Y*Uy;
    V:=P^.Pts^[J].X*Vx+P^.Pts^[J].Y*Vy;
    If U<MinU Then MinU:=U;If U>MaxU Then MaxU:=U;
    If V<MinV Then MinV:=V;If V>MaxV Then MaxV:=V;
   End;
   A:=(MaxU-MinU)*(MaxV-MinV);
   If A<BestA Then Begin
    BestA:=A;Bux:=Ux;Buy:=Uy;Bu0:=MinU;Bu1:=MaxU;Bv0:=MinV;Bv1:=MaxV;
   End;
  End;
 End;
 R.Cls:=3;R.NPoly:=1;
 Pa:=NewPath(R,5,0);
 { sommets du rectangle (anti-horaire) }
 Pa^.Pts^[0].X:=Bu0*Bux-Bv0*Buy;Pa^.Pts^[0].Y:=Bu0*Buy+Bv0*Bux;
 Pa^.Pts^[1].X:=Bu1*Bux-Bv0*Buy;Pa^.Pts^[1].Y:=Bu1*Buy+Bv0*Bux;
 Pa^.Pts^[2].X:=Bu1*Bux-Bv1*Buy;Pa^.Pts^[2].Y:=Bu1*Buy+Bv1*Bux;
 Pa^.Pts^[3].X:=Bu0*Bux-Bv1*Buy;Pa^.Pts^[3].Y:=Bu0*Buy+Bv1*Bux;
 Pa^.Pts^[4]:=Pa^.Pts^[0];
 Area:=BestA;
 W:=Bu1-Bu0;H:=Bv1-Bv0;
 Ang:=NormDeg(Rad2Deg(Atan2(Bux,Buy)));
 If H>W Then Begin
  A:=W;W:=H;H:=A;
  Ang:=NormDeg(Ang+90);
 End;
 Ang:=Ang-180*Int(Ang/180);
 FreeGeom(Hull);
End;

{ Triangulation de Delaunay (Bowyer-Watson), O(n^2). Tri : triplets d'index. }
Procedure Delaunay(Pts:PPts;N:LongInt;Var Tri:PLongs;Var NTri:LongInt);
Var
 X:PPts;
 TA,TB,TC:PLongs;
 Cx,Cy,R2:PReals;
 Nt,Cap,I,J,K,Nb:LongInt;
 MinX,MinY,MaxX,MaxY,D,Mx,My,Ax,Ay,Bx,By,Cx1,Cy1,Dd,Ux,Uy:Real;
 Bad:PBools;
 EA,EB:PLongs;
 Ne:LongInt;
 Dup:Boolean;

 Procedure Circ(T:LongInt);
 Var
  A,B,C:LongInt;
 Begin
  A:=TA^[T];B:=TB^[T];C:=TC^[T];
  Ax:=X^[A].X;Ay:=X^[A].Y;Bx:=X^[B].X;By:=X^[B].Y;Cx1:=X^[C].X;Cy1:=X^[C].Y;
  Dd:=2*(Ax*(By-Cy1)+Bx*(Cy1-Ay)+Cx1*(Ay-By));
  If Dd=0Then Begin
   Cx^[T]:=1E30;Cy^[T]:=1E30;R2^[T]:=1E300;
  End
   Else
  Begin
   Ux:=((Ax*Ax+Ay*Ay)*(By-Cy1)+(Bx*Bx+By*By)*(Cy1-Ay)+(Cx1*Cx1+Cy1*Cy1)*(Ay-By))/Dd;
   Uy:=((Ax*Ax+Ay*Ay)*(Cx1-Bx)+(Bx*Bx+By*By)*(Ax-Cx1)+(Cx1*Cx1+Cy1*Cy1)*(Bx-Ax))/Dd;
   Cx^[T]:=Ux;Cy^[T]:=Uy;
   R2^[T]:=Sqr(Ax-Ux)+Sqr(Ay-Uy);
  End;
 End;

Begin
 Tri:=Nil;NTri:=0;
 If N<3Then Exit;
 X:=AllocBlock((N+3)*SizeOf(TPt));
 For I:=0 to N-1do X^[I]:=Pts^[I];
 MinX:=X^[0].X;MaxX:=MinX;MinY:=X^[0].Y;MaxY:=MinY;
 For I:=1 to N-1do Begin
  If X^[I].X<MinX Then MinX:=X^[I].X;If X^[I].X>MaxX Then MaxX:=X^[I].X;
  If X^[I].Y<MinY Then MinY:=X^[I].Y;If X^[I].Y>MaxY Then MaxY:=X^[I].Y;
 End;
 D:=MaxR(MaxX-MinX,MaxY-MinY);
 If D<=0Then D:=1;
 Mx:=(MinX+MaxX)/2;My:=(MinY+MaxY)/2;
 X^[N].X:=Mx-20*D;X^[N].Y:=My-D;
 X^[N+1].X:=Mx;X^[N+1].Y:=My+20*D;
 X^[N+2].X:=Mx+20*D;X^[N+2].Y:=My-D;
 Cap:=2*N+10;
 TA:=AllocBlock(Cap*SizeOf(LongInt));TB:=AllocBlock(Cap*SizeOf(LongInt));TC:=AllocBlock(Cap*SizeOf(LongInt));
 Cx:=AllocBlock(Cap*SizeOf(Real));Cy:=AllocBlock(Cap*SizeOf(Real));R2:=AllocBlock(Cap*SizeOf(Real));
 Bad:=AllocBlock(Cap*SizeOf(Boolean));
 EA:=AllocBlock(Cap*6*SizeOf(LongInt));EB:=AllocBlock(Cap*6*SizeOf(LongInt));
 Nt:=1;
 TA^[0]:=N;TB^[0]:=N+1;TC^[0]:=N+2;
 Circ(0);
 For I:=0 to N-1do Begin
  { triangles dont le cercle circonscrit contient le point }
  Ne:=0;
  For J:=0 to Nt-1do Begin
   Bad^[J]:=Sqr(X^[I].X-Cx^[J])+Sqr(X^[I].Y-Cy^[J])<R2^[J]*(1-1E-12);
   If Bad^[J]Then Begin
    EA^[Ne]:=TA^[J];EB^[Ne]:=TB^[J];Inc(Ne);
    EA^[Ne]:=TB^[J];EB^[Ne]:=TC^[J];Inc(Ne);
    EA^[Ne]:=TC^[J];EB^[Ne]:=TA^[J];Inc(Ne);
   End;
  End;
  { retrait des triangles mauvais }
  K:=0;
  For J:=0 to Nt-1do
   If Not Bad^[J]Then Begin
    TA^[K]:=TA^[J];TB^[K]:=TB^[J];TC^[K]:=TC^[J];
    Cx^[K]:=Cx^[J];Cy^[K]:=Cy^[J];R2^[K]:=R2^[J];
    Inc(K);
   End;
  Nt:=K;
  { aretes du contour du trou : celles qui n'apparaissent qu'une fois }
  For J:=0 to Ne-1do Begin
   Dup:=False;
   For K:=0 to Ne-1do
    If(K<>J)and(((EA^[J]=EA^[K])and(EB^[J]=EB^[K]))or((EA^[J]=EB^[K])and(EB^[J]=EA^[K])))Then Dup:=True;
   If Not Dup Then Begin
    If Nt>=Cap Then Begin Dup:=True;End
     Else
    Begin
     TA^[Nt]:=EA^[J];TB^[Nt]:=EB^[J];TC^[Nt]:=I;
     Circ(Nt);
     Inc(Nt);
    End;
   End;
  End;
 End;
 { sortie : on retire les triangles qui touchent le super-triangle }
 Tri:=AllocBlock((Nt*3+3)*SizeOf(LongInt));
 NTri:=0;
 For J:=0 to Nt-1do
  If(TA^[J]<N)and(TB^[J]<N)and(TC^[J]<N)Then Begin
   Tri^[3*NTri]:=TA^[J];Tri^[3*NTri+1]:=TB^[J];Tri^[3*NTri+2]:=TC^[J];
   Inc(NTri);
  End;
 FreeMem(EA,Cap*6*SizeOf(LongInt));FreeMem(EB,Cap*6*SizeOf(LongInt));
 FreeMem(Bad,Cap*SizeOf(Boolean));
 FreeMem(R2,Cap*SizeOf(Real));FreeMem(Cy,Cap*SizeOf(Real));FreeMem(Cx,Cap*SizeOf(Real));
 FreeMem(TC,Cap*SizeOf(LongInt));FreeMem(TB,Cap*SizeOf(LongInt));FreeMem(TA,Cap*SizeOf(LongInt));
 FreeMem(X,(N+3)*SizeOf(TPt));
End;

{ Enveloppe concave a partir d'un ensemble de points (Ratio 0 = tres concave, 1 = enveloppe convexe) }
Procedure ConcaveHullPts(Pts:PPts;N:LongInt;Ratio:Real;Var R:TGeom);
Var
 Tri:PLongs;
 NT,I,J,K,E,Best,Bc,Opp:LongInt;
 Alive:PBools;
 Nbr:PLongs;
 LenMax,Thr,Lo,Hi,L,BestL:Real;
 VB:PLongs;
 A,B,C:LongInt;
 T:TGeom;
 Pa:PPath;
 Empty:TGeom;
 Vx1,Vx2:LongInt;

 Function EdgeLen(U,V:LongInt):Real;Begin
  EdgeLen:=Sqrt(Sqr(Pts^[U].X-Pts^[V].X)+Sqr(Pts^[U].Y-Pts^[V].Y));
 End;

 Function TriV(Tt,Ee:LongInt):LongInt;Begin
  TriV:=Tri^[3*Tt+Ee];
 End;

Begin
 InitGeom(R);
 Delaunay(Pts,N,Tri,NT);
 If NT=0Then Exit;
 Alive:=AllocBlock(NT*SizeOf(Boolean));
 Nbr:=AllocBlock(NT*3*SizeOf(LongInt));
 LenMax:=0;
 Lo:=1E300;Hi:=0;
 For I:=0 to NT-1do Begin
  Alive^[I]:=True;
  L:=MaxR(EdgeLen(TriV(I,0),TriV(I,1)),MaxR(EdgeLen(TriV(I,1),TriV(I,2)),EdgeLen(TriV(I,2),TriV(I,0))));
  If L<Lo Then Lo:=L;
  If L>Hi Then Hi:=L;
 End;
 Thr:=Lo+Ratio*(Hi-Lo);
 { voisins : arete e du triangle i = (v[e],v[e+1]) }
 For I:=0 to NT-1do
  For E:=0 to 2do Begin
   Nbr^[3*I+E]:=-1;
   Vx1:=TriV(I,E);Vx2:=TriV(I,(E+1)mod 3);
   For J:=0 to NT-1do
    If J<>I Then
     For K:=0 to 2do
      If(TriV(J,K)=Vx2)and(TriV(J,(K+1)mod 3)=Vx1)Then Nbr^[3*I+E]:=J;
  End;
 VB:=AllocBlock((N+1)*SizeOf(LongInt));
 Repeat
  { nombre d'aretes de bord incidentes a chaque sommet }
  For I:=0 to N-1do VB^[I]:=0;
  For I:=0 to NT-1do
   If Alive^[I]Then
    For E:=0 to 2do
     If(Nbr^[3*I+E]<0)or Not Alive^[Nbr^[3*I+E]]Then Begin
      Inc(VB^[TriV(I,E)]);
      Inc(VB^[TriV(I,(E+1)mod 3)]);
     End;
  Best:=-1;BestL:=Thr;
  For I:=0 to NT-1do
   If Alive^[I]Then Begin
    L:=MaxR(EdgeLen(TriV(I,0),TriV(I,1)),MaxR(EdgeLen(TriV(I,1),TriV(I,2)),EdgeLen(TriV(I,2),TriV(I,0))));
    If L>BestL Then Begin
     Bc:=0;Opp:=-1;
     For E:=0 to 2do
      If(Nbr^[3*I+E]<0)or Not Alive^[Nbr^[3*I+E]]Then Begin
       Inc(Bc);
       Opp:=TriV(I,(E+2)mod 3);
      End;
     If Bc=1Then Begin
      If VB^[Opp]=0Then Begin Best:=I;BestL:=L;End;
     End
      Else
     If Bc=2Then Begin Best:=I;BestL:=L;End;
    End;
   End;
  If Best>=0Then Alive^[Best]:=False;
 Until Best<0;
 FreeMem(VB,(N+1)*SizeOf(LongInt));
 InitGeom(T);
 T.Cls:=3;
 K:=0;
 For I:=0 to NT-1do
  If Alive^[I]Then Begin
   Pa:=NewPath(T,4,K);
   A:=TriV(I,0);B:=TriV(I,1);C:=TriV(I,2);
   Pa^.Pts^[0]:=Pts^[A];Pa^.Pts^[1]:=Pts^[B];Pa^.Pts^[2]:=Pts^[C];Pa^.Pts^[3]:=Pts^[A];
   If RingArea(Pa)<0Then Begin Pa^.Pts^[1]:=Pts^[C];Pa^.Pts^[2]:=Pts^[B];End;
   Inc(K);
  End;
 T.NPoly:=K;
 InitGeom(Empty);
 KeepOrient:=True;
 Overlay(0,T,Empty,R);
 KeepOrient:=False;
 FreeGeom(T);
 FreeMem(Nbr,NT*3*SizeOf(LongInt));
 FreeMem(Alive,NT*SizeOf(Boolean));
 FreeMem(Tri,(NT*3+3)*SizeOf(LongInt));
End;

{ ---- extraction de faces (polygonize) ---- }

{ Ajoute les segments d'une geometrie (lignes ou anneaux) a E }
Procedure FillSegments(Var G:TGeom;E:PEdges;Var N:LongInt);
Var
 P:PPath;
 I:LongInt;
 X1,Y1,X2,Y2:Real;
Begin
 P:=G.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-2do Begin
   X1:=Snap(P^.Pts^[I].X);Y1:=Snap(P^.Pts^[I].Y);X2:=Snap(P^.Pts^[I+1].X);Y2:=Snap(P^.Pts^[I+1].Y);
   If(X1<>X2)or(Y1<>Y2)Then Begin
    E^[N].X1:=X1;E^[N].Y1:=Y1;E^[N].X2:=X2;E^[N].Y2:=Y2;
    Inc(N);
   End;
  End;
  P:=P^.Next;
 End;
End;

{ Rattache les trous (aire negative) a l'exterieur le plus petit qui les contient }
Procedure AssembleRings(Var EG,HG:TGeom;Tol:Real;Var R:TGeom);
Var
 Hp,Pa,Pb:PPath;
 HArr:^PPathArr;
 HN,K,I,Cnt:LongInt;
 Own:Integer;
 BestArea:Real;
 Owner:Integer;
Begin
 Hp:=HG.First;
 While Hp<>Nil do Begin
  Hp^.Poly:=-1;
  BestArea:=0;
  Own:=0;
  Pa:=EG.First;
  While Pa<>Nil do Begin
   If(Pa^.Area>Abs(Hp^.Area))and((Hp^.Poly<0)or(Pa^.Area<BestArea))Then Begin
    Cnt:=0;
    Owner:=2;
    While(Cnt<Hp^.N-1)and(Owner=2)do Begin
     Owner:=PointInRing(Pa,Hp^.Pts^[Cnt].X,Hp^.Pts^[Cnt].Y,Tol);
     Inc(Cnt);
    End;
    If Owner=1Then Begin Hp^.Poly:=Own;BestArea:=Pa^.Area;End;
   End;
   Inc(Own);
   Pa:=Pa^.Next;
  End;
  Hp:=Hp^.Next;
 End;
 HN:=HG.Count;
 HArr:=AllocBlock((HN+1)*SizeOf(PPath));
 K:=0;
 Hp:=HG.First;
 While Hp<>Nil do Begin HArr^[K]:=Hp;Inc(K);Hp:=Hp^.Next;End;
 InitGeom(R);
 R.Cls:=3;
 Own:=0;
 Pa:=EG.First;
 While Pa<>Nil do Begin
  Pb:=Pa^.Next;
  Pa^.Poly:=Own;
  LinkPath(R,Pa);
  For I:=0 to HN-1do
   If HArr^[I]^.Poly=Own Then LinkPath(R,HArr^[I]);
  Inc(Own);
  Pa:=Pb;
 End;
 R.NPoly:=Own;
 FreeMem(HArr,(HN+1)*SizeOf(PPath));
End;

{ Sommets uniques tries (X puis Y) des aretes non supprimees, avec leur degre }
Procedure BuildVerts(U:PEdges;Kill:PBools;NU:LongInt;Var Vs:PPts;Var Deg:PLongs;Var Nv:LongInt);
Var
 Raw:PPts;
 Idx:PLongs;
 I,M,Cnt:LongInt;
Begin
 Raw:=AllocBlock((2*NU+2)*SizeOf(TPt));
 Cnt:=0;
 For I:=0 to NU-1do
  If Not Kill^[I]Then Begin
   Raw^[Cnt].X:=U^[I].X1;Raw^[Cnt].Y:=U^[I].Y1;Inc(Cnt);
   Raw^[Cnt].X:=U^[I].X2;Raw^[Cnt].Y:=U^[I].Y2;Inc(Cnt);
  End;
 Vs:=AllocBlock((Cnt+1)*SizeOf(TPt));
 Deg:=AllocBlock((Cnt+1)*SizeOf(LongInt));
 Nv:=0;
 If Cnt>0Then Begin
  Idx:=AllocBlock(Cnt*SizeOf(LongInt));
  For I:=0 to Cnt-1do Idx^[I]:=I;
  SP:=Raw;SMode:=1;
  If Cnt>1Then SortIdx(Idx,0,Cnt-1);
  M:=0;
  For I:=0 to Cnt-1do Begin
   If(I=0)or(CmpIdx(Idx^[I],Idx^[I-1])<>0)Then Begin
    Vs^[M]:=Raw^[Idx^[I]];Deg^[M]:=0;Inc(M);
   End;
   Inc(Deg^[M-1]);
  End;
  Nv:=M;
  FreeMem(Idx,Cnt*SizeOf(LongInt));
 End;
 FreeMem(Raw,(2*NU+2)*SizeOf(TPt));
End;

Function VertexIndex(Vs:PPts;Nv:LongInt;X,Y:Real):LongInt;
Var
 Lo,Hi,Mid:LongInt;
Begin
 Lo:=0;Hi:=Nv;
 While Lo<Hi do Begin
  Mid:=(Lo+Hi)div 2;
  If(Vs^[Mid].X<X)or((Vs^[Mid].X=X)and(Vs^[Mid].Y<Y))Then Lo:=Mid+1 Else Hi:=Mid;
 End;
 VertexIndex:=Lo;
End;

{ Faces du graphe planaire forme par les aretes U (sans croisement) }
Procedure FacesFromEdges(U:PEdges;NU:LongInt;Tol:Real;Var R:TGeom);
Var
 Kill:PBools;
 Vs:PPts;
 Deg,HOrg,Ord,Pos,GStart,GCnt:PLongs;
 Ang:PReals;
 Used:PBools;
 Nv,I,E,Ne,H,Cur,Q,Pv,RN:LongInt;
 Changed:Boolean;
 Alive:PEdges;
 RB:PPts;
 All,EG,HG:TGeom;
 Pa,Pb:PPath;
Begin
 InitGeom(R);
 R.Cls:=3;
 Kill:=AllocBlock((NU+1)*SizeOf(Boolean));
 For I:=0 to NU-1do Kill^[I]:=False;
 { elimination iterative des impasses (sommets de degre 1) }
 Repeat
  Changed:=False;
  BuildVerts(U,Kill,NU,Vs,Deg,Nv);
  For I:=0 to NU-1do
   If Not Kill^[I]Then
    If(Deg^[VertexIndex(Vs,Nv,U^[I].X1,U^[I].Y1)]<2)or(Deg^[VertexIndex(Vs,Nv,U^[I].X2,U^[I].Y2)]<2)Then Begin
     Kill^[I]:=True;
     Changed:=True;
    End;
  FreeMem(Deg,(Nv+1)*SizeOf(LongInt));
  FreeMem(Vs,(Nv+1)*SizeOf(TPt));
 Until Not Changed;
 Ne:=0;
 For I:=0 to NU-1do If Not Kill^[I]Then Inc(Ne);
 If Ne<3Then Begin
  FreeMem(Kill,(NU+1)*SizeOf(Boolean));
  Exit;
 End;
 Alive:=AllocBlock(Ne*SizeOf(TEdge));
 Ne:=0;
 For I:=0 to NU-1do If Not Kill^[I]Then Begin Alive^[Ne]:=U^[I];Inc(Ne);End;
 FreeMem(Kill,(NU+1)*SizeOf(Boolean));
 Kill:=AllocBlock((Ne+1)*SizeOf(Boolean));
 For I:=0 to Ne-1do Kill^[I]:=False;
 BuildVerts(Alive,Kill,Ne,Vs,Deg,Nv);
 FreeMem(Kill,(Ne+1)*SizeOf(Boolean));
 { demi-aretes : 2k = (X1,Y1)->(X2,Y2), 2k+1 = sens inverse }
 HOrg:=AllocBlock(2*Ne*SizeOf(LongInt));
 Ang:=AllocBlock(2*Ne*SizeOf(Real));
 For E:=0 to Ne-1do Begin
  HOrg^[2*E]:=VertexIndex(Vs,Nv,Alive^[E].X1,Alive^[E].Y1);
  HOrg^[2*E+1]:=VertexIndex(Vs,Nv,Alive^[E].X2,Alive^[E].Y2);
  Ang^[2*E]:=Atan2(Alive^[E].Y2-Alive^[E].Y1,Alive^[E].X2-Alive^[E].X1);
  Ang^[2*E+1]:=Atan2(Alive^[E].Y1-Alive^[E].Y2,Alive^[E].X1-Alive^[E].X2);
 End;
 Ord:=AllocBlock(2*Ne*SizeOf(LongInt));
 For H:=0 to 2*Ne-1do Ord^[H]:=H;
 SLab:=HOrg;SAng:=Ang;SMode:=6;
 SortIdx(Ord,0,2*Ne-1);
 Pos:=AllocBlock(2*Ne*SizeOf(LongInt));
 GStart:=AllocBlock((Nv+1)*SizeOf(LongInt));
 GCnt:=AllocBlock((Nv+1)*SizeOf(LongInt));
 For I:=0 to Nv-1do Begin GStart^[I]:=-1;GCnt^[I]:=0;End;
 For Q:=0 to 2*Ne-1do Begin
  Pos^[Ord^[Q]]:=Q;
  If GStart^[HOrg^[Ord^[Q]]]<0Then GStart^[HOrg^[Ord^[Q]]]:=Q;
  Inc(GCnt^[HOrg^[Ord^[Q]]]);
 End;
 { parcours : apres h, on prend l'arete sortante qui suit le jumeau dans le sens horaire }
 Used:=AllocBlock(2*Ne*SizeOf(Boolean));
 For H:=0 to 2*Ne-1do Used^[H]:=False;
 RB:=AllocBlock((2*Ne+2)*SizeOf(TPt));
 InitGeom(All);
 For H:=0 to 2*Ne-1do
  If Not Used^[H]Then Begin
   Cur:=H;RN:=0;
   Repeat
    Used^[Cur]:=True;
    RB^[RN]:=Vs^[HOrg^[Cur]];Inc(RN);
    Q:=Pos^[Cur xor 1];
    Pv:=HOrg^[Cur xor 1];
    If Q>GStart^[Pv]Then Dec(Q) Else Q:=GStart^[Pv]+GCnt^[Pv]-1;
    Cur:=Ord^[Q];
   Until(Cur=H)or Used^[Cur];
   If(Cur=H)and(RN>=3)Then Begin
    Pa:=NewPath(All,RN+1,0);
    Move(RB^,Pa^.Pts^,RN*SizeOf(TPt));
    Pa^.Pts^[RN]:=Pa^.Pts^[0];
    Pa^.N:=RN+1;
    Pa^.Area:=RingArea(Pa);
   End;
  End;
 { exterieurs (aire > 0) et trous (aire < 0) }
 InitGeom(EG);InitGeom(HG);
 Pa:=All.First;
 While Pa<>Nil do Begin
  Pb:=Pa^.Next;
  If Pa^.Area>0Then LinkPath(EG,Pa)
   Else
  If Pa^.Area<0Then LinkPath(HG,Pa);
  Pa:=Pb;
 End;
 AssembleRings(EG,HG,Tol,R);
 FreeMem(RB,(2*Ne+2)*SizeOf(TPt));
 FreeMem(Used,2*Ne*SizeOf(Boolean));
 FreeMem(GCnt,(Nv+1)*SizeOf(LongInt));
 FreeMem(GStart,(Nv+1)*SizeOf(LongInt));
 FreeMem(Pos,2*Ne*SizeOf(LongInt));
 FreeMem(Ord,2*Ne*SizeOf(LongInt));
 FreeMem(Ang,2*Ne*SizeOf(Real));
 FreeMem(HOrg,2*Ne*SizeOf(LongInt));
 FreeMem(Deg,(Nv+1)*SizeOf(LongInt));
 FreeMem(Vs,(Nv+1)*SizeOf(TPt));
 FreeMem(Alive,Ne*SizeOf(TEdge));
End;

{ Decoupe un reseau de lignes aux intersections puis en extrait les polygones }
Procedure NodeSegments(Var G:TGeom;Var Sub:PEdges;Var NU:LongInt;Var SubCap:LongInt);
Var
 MinX,MinY,MaxX,MaxY,Ext:Real;
 NT,NS:LongInt;
 Idx:PLongs;
 I:LongInt;
 Raw:PEdges;
Begin
 Sub:=Nil;NU:=0;SubCap:=0;
 If Not GeomBBox(G,MinX,MinY,MaxX,MaxY)Then Exit;
 Ext:=MaxR(MaxX-MinX,MaxY-MinY);
 If Ext<=0Then Exit;
 SnapQ:=Ext*1E-9;
 OvEps:=Ext*1E-8;
 NT:=EdgeCount(G);
 OvAll:=AllocBlock(NT*SizeOf(TEdge));
 NS:=0;
 FillSegments(G,OvAll,NS);
 NT:=NS;
 If NT<1Then Begin FreeMem(OvAll,EdgeCount(G)*SizeOf(TEdge));Exit;End;
 OvNA:=NT;
 NodeAll(NT,MinY,MaxY,False,Raw,NS,Idx,NU);
 SubCap:=NT+OvTot;
 { copie ordonnee des segments uniques }
 Sub:=AllocBlock((NU+1)*SizeOf(TEdge));
 For I:=0 to NU-1do Sub^[I]:=Raw^[Idx^[I]];
 FreeMem(Idx,NS*SizeOf(LongInt));
 FreeMem(Raw,SubCap*SizeOf(TEdge));
 FreeMem(OvAll,NT*SizeOf(TEdge));
End;

Procedure PolygonizeLines(Var G:TGeom;Var R:TGeom);
Var
 Sub:PEdges;
 NU,Cap:LongInt;
Begin
 InitGeom(R);
 R.Cls:=3;
 NodeSegments(G,Sub,NU,Cap);
 If NU<3Then Exit;
 FacesFromEdges(Sub,NU,SnapQ*4,R);
 FreeMem(Sub,(NU+1)*SizeOf(TEdge));
End;


{ Utilitaires de couches deplaces avant les formats }
Function Unesc(S:String):String;
Var
 I:Integer;
 T:String;
 V,V2,Code:LongInt;

 Function Hex4(P:Integer):LongInt;
 Var
  H,E:LongInt;
 Begin
  If P+3>Length(S)Then Begin Hex4:=-1;Exit;End;
  Val('$'+Copy(S,P,4),H,E);
  If E<>0Then H:=-1;
  Hex4:=H;
 End;

Begin
 T:='';
 I:=1;
 While I<=Length(S)do Begin
  If(S[I]='\')and(I<Length(S))Then Begin
   Inc(I);
   Case S[I] of
    'n':T:=T+#10;
    't':T:=T+#9;
    'r':T:=T+#13;
    'b':T:=T+#8;
    'f':T:=T+#12;
    'u':Begin
     V:=Hex4(I+1);
     If V<0Then T:=T+'u'
      Else
     Begin
      Inc(I,4);
      If(V>=$D800)and(V<=$DBFF)and(I+6<=Length(S))and(S[I+1]='\')and(S[I+2]='u')Then Begin
       V2:=Hex4(I+3);
       If(V2>=$DC00)and(V2<=$DFFF)Then Begin
        V:=$10000+((V-$D800)shl 10)+(V2-$DC00);
        Inc(I,6);
       End;
      End;
      If V<128Then T:=T+Chr(V) Else
      If V<2048Then T:=T+Chr(192+(V shr 6))+Chr(128+(V and 63)) Else
      If V<65536Then T:=T+Chr(224+(V shr 12))+Chr(128+((V shr 6)and 63))+Chr(128+(V and 63))
      Else T:=T+Chr(240+(V shr 18))+Chr(128+((V shr 12)and 63))+Chr(128+((V shr 6)and 63))+Chr(128+(V and 63));
     End;
    End;
    Else T:=T+S[I];
   End;
  End
   Else
  T:=T+S[I];
  Inc(I);
 End;
 Unesc:=T;
End;

{ Nouvelle couche vide ; le SCR de Src est conserve }
Function NewLayerLike(Src:PJ;Var Arr:PJ):PJ;
Var
 Root,C:PJ;
Begin
 Root:=NewJ(5);
 JAddKV(Root,'type',JText('FeatureCollection'));
 If Src<>Nil Then Begin
  C:=JFind(Src,'crs');
  If C<>Nil Then JAddKV(Root,'crs',JClone(C));
 End;
 Arr:=NewJ(4);
 JAddKV(Root,'features',Arr);
 NewLayerLike:=Root;
End;

Function GetProp(F:PJ;Name:String):PJ;Begin
 GetProp:=JFind(JFind(F,'properties'),Name);
End;

Function NodeText(N:PJ):String;Begin
 If N=Nil Then NodeText:='' Else
 Case N^.Kind of
  3:NodeText:=Unesc(JVal(N));
  1,2:NodeText:=JVal(N);
  Else NodeText:='';
 End;
End;

Procedure FlattenFeature(F:PJ;Var G:TGeom);Begin
 Flatten(JFind(F,'geometry'),G);
End;

Function NewFeature(Props,Geom:PJ):PJ;
Var
 F:PJ;
Begin
 F:=NewJ(5);
 JAddKV(F,'type',JText('Feature'));
 If Props=Nil Then Props:=NewJ(5);
 JAddKV(F,'properties',Props);
 If Geom=Nil Then Geom:=NewJ(0);
 JAddKV(F,'geometry',Geom);
 NewFeature:=F;
End;

{ Entites d'une couche dans un tableau }
Type
 PJArr=^TJArr;
 TJArr=Array[0..8000000]of PJ;

Function FeatureArray(Arr:PJ;Var N:LongInt):PJArr;
Var
 F:PJ;
 P:PJArr;
Begin
 N:=0;
 F:=Arr^.First;
 While F<>Nil do Begin Inc(N);F:=F^.Next;End;
 P:=AllocBlock((N+1)*SizeOf(PJ));
 N:=0;
 F:=Arr^.First;
 While F<>Nil do Begin P^[N]:=F;Inc(N);F:=F^.Next;End;
 FeatureArray:=P;
End;


{ ------------------------------------------------------------------ }
{ Formats de donnees : fichiers binaires, URI, Shapefile             }
{ ------------------------------------------------------------------ }

Procedure ApplySubset(Root:PJ;Expr:String);Forward;

Type
 TBuf=Record
  P:PBytes;
  N,Cap:LongInt;
 End;

{ Fichier complet en memoire (Nil s'il est illisible) ; 8 octets nuls sont ajoutes a la fin }
Function LoadFileBytes(FileName:String;Var Size:LongInt):PBytes;
Var
 F:File;
 Got:LongInt;
 P:PBytes;
Begin
 LoadFileBytes:=Nil;Size:=0;
 Assign(F,FileName);
 {$I-}
 Reset(F,1);
 {$I+}
 If IOResult<>0Then Exit;
 Size:=FileSize(F);
 GetMem(P,Size+8);
 If Size>0Then BlockRead(F,P^,Size,Got);
 Close(F);
 FillChar(P^[Size],8,0);
 LoadFileBytes:=P;
End;

Function FileExists(FileName:String):Boolean;
Var
 F:File;
Begin
 Assign(F,FileName);
 {$I-}
 Reset(F,1);
 {$I+}
 If IOResult=0Then Begin Close(F);FileExists:=True;End
              Else FileExists:=False;
End;

Procedure BufInit(Var B:TBuf);Begin
 B.Cap:=65536;B.N:=0;
 B.P:=AllocBlock(B.Cap);
End;

Procedure BufGrow(Var B:TBuf;Need:LongInt);
Var
 NewCap:LongInt;
 Q:PBytes;
Begin
 If B.N+Need<=B.Cap Then Exit;
 NewCap:=B.Cap;
 While B.N+Need>NewCap do NewCap:=NewCap*2;
 Q:=AllocBlock(NewCap);
 Move(B.P^,Q^,B.N);
 FreeMem(B.P,B.Cap);
 B.P:=Q;B.Cap:=NewCap;
End;

Procedure BufByte(Var B:TBuf;V:Integer);Begin
 BufGrow(B,1);
 B.P^[B.N]:=V and 255;
 Inc(B.N);
End;

Procedure BufLE16(Var B:TBuf;V:LongInt);Begin
 BufByte(B,V);BufByte(B,V shr 8);
End;

Procedure BufLE32(Var B:TBuf;V:LongInt);Begin
 BufByte(B,V);BufByte(B,V shr 8);BufByte(B,V shr 16);BufByte(B,V shr 24);
End;

Procedure BufBE32(Var B:TBuf;V:LongInt);Begin
 BufByte(B,V shr 24);BufByte(B,V shr 16);BufByte(B,V shr 8);BufByte(B,V);
End;

Procedure BufDouble(Var B:TBuf;R:Real);Begin
 BufGrow(B,8);
 Move(R,B.P^[B.N],8);
 Inc(B.N,8);
End;

Procedure BufText(Var B:TBuf;S:String);Begin
 If S=''Then Exit;
 BufGrow(B,Length(S));
 Move(S[1],B.P^[B.N],Length(S));
 Inc(B.N,Length(S));
End;

Procedure BufFill(Var B:TBuf;Cnt,V:Integer);
Var
 I:Integer;
Begin
 For I:=1 to Cnt do BufByte(B,V);
End;

Procedure BufSave(FileName:String;Var B:TBuf);
Var
 F:File;
 Put:LongInt;
Begin
 Assign(F,FileName);
 {$I-}
 Rewrite(F,1);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to create output file '+FileName);
 If B.N>0Then BlockWrite(F,B.P^,B.N,Put);
 Close(F);
End;

Function RdU8(B:PBytes;P:LongInt):LongInt;Begin
 RdU8:=B^[P];
End;

Function RdLE16(B:PBytes;P:LongInt):LongInt;Begin
 RdLE16:=LongInt(B^[P])or(LongInt(B^[P+1])shl 8);
End;

Function RdLE32(B:PBytes;P:LongInt):LongInt;Begin
 RdLE32:=LongInt(B^[P])or(LongInt(B^[P+1])shl 8)or(LongInt(B^[P+2])shl 16)or(LongInt(B^[P+3])shl 24);
End;

Function RdBE32(B:PBytes;P:LongInt):LongInt;Begin
 RdBE32:=LongInt(B^[P+3])or(LongInt(B^[P+2])shl 8)or(LongInt(B^[P+1])shl 16)or(LongInt(B^[P])shl 24);
End;

Function RdDouble(B:PBytes;P:LongInt):Real;
Var
 R:Real;
Begin
 Move(B^[P],R,8);
 RdDouble:=R;
End;

{ Extension en majuscules, avec le point ('' s'il n'y en a pas) }
Function FileExt(S:String):String;
Var
 I:Integer;
Begin
 FileExt:='';
 For I:=Length(S)downto 1do Begin
  If S[I]in['/','\']Then Exit;
  If S[I]='.'Then Begin FileExt:=StrUpper(Copy(S,I,255));Exit;End;
 End;
End;

Function ChangeExt(S,Ext:String):String;
Var
 I:Integer;
Begin
 For I:=Length(S)downto 1do Begin
  If S[I]in['/','\']Then Break;
  If S[I]='.'Then Begin ChangeExt:=Copy(S,1,I-1)+Ext;Exit;End;
 End;
 ChangeExt:=S+Ext;
End;

{ Fichier voisin du meme nom (.dbf, .prj...) : essaie la casse minuscule puis majuscule }
Function SideFile(Path,Ext:String):String;
Begin
 If FileExists(ChangeExt(Path,Ext))Then SideFile:=ChangeExt(Path,Ext) Else
 If FileExists(ChangeExt(Path,StrUpper(Ext)))Then SideFile:=ChangeExt(Path,StrUpper(Ext))
                                              Else SideFile:='';
End;

{ Decoupe une source "chemin|layername=nom|subset=expression" }
Procedure ParseUri(Uri:String;Var Path,LayerName,Subset:String);
Var
 P:Integer;
 Rest,Part,Key:String;
Begin
 Path:=Uri;LayerName:='';Subset:='';
 P:=Pos('|',Uri);
 If P=0Then Exit;
 Path:=Copy(Uri,1,P-1);
 Rest:=Copy(Uri,P+1,255);
 While Rest<>''do Begin
  P:=Pos('|',Rest);
  If P=0Then Begin Part:=Rest;Rest:='';End
        Else Begin Part:=Copy(Rest,1,P-1);Rest:=Copy(Rest,P+1,255);End;
  P:=Pos('=',Part);
  If P>0Then Begin
   Key:=StrUpper(Copy(Part,1,P-1));
   If Key='LAYERNAME'Then LayerName:=Copy(Part,P+1,255) Else
   If Key='SUBSET'Then Begin
    { l'expression peut contenir des "|" : on garde tout le reste }
    Subset:=Copy(Part,P+1,255);
    If Rest<>''Then Subset:=Subset+'|'+Rest;
    Rest:='';
   End;
  End;
 End;
End;

Function JTextEsc(S:String):PJ;
Var
 I:Integer;
 T:String;
Begin
 T:='';
 For I:=1 to Length(S)do Begin
  If Length(T)>=250Then Break;
  Case S[I]of
   '"':T:=T+'\"';
   '\':T:=T+'\\';
   #10:T:=T+'\n';
   #13:T:=T+'\r';
   #9:T:=T+'\t';
   Else If S[I]>=' 'Then T:=T+S[I];
  End;
 End;
 JTextEsc:=JText(T);
End;

Function JBool(B:Boolean):PJ;
Var
 N:PJ;
Begin
 N:=NewJ(1);
 If B Then N^.Val:=MkStr('true') Else N^.Val:=MkStr('false');
 JBool:=N;
End;

{ Ecrit une geometrie aplatie en WKT dans un fichier texte }
Procedure WriteWkt(Var T:Text;Var G:TGeom);
Var
 P:PPath;
 I:LongInt;
 First:Boolean;
 Prev:Integer;
Begin
 If G.First=Nil Then Exit;
 Case G.Cls of
  1:Begin
   If G.Count=1Then Write(T,'POINT (')
               Else Write(T,'MULTIPOINT (');
   P:=G.First;First:=True;
   While P<>Nil do Begin
    If Not First Then Write(T,', ');
    First:=False;
    Write(T,NumStr(P^.Pts^[0].X),' ',NumStr(P^.Pts^[0].Y));
    P:=P^.Next;
   End;
   Write(T,')');
  End;
  2:Begin
   If G.Count=1Then Write(T,'LINESTRING ')Else Write(T,'MULTILINESTRING (');
   P:=G.First;First:=True;
   While P<>Nil do Begin
    If Not First Then Write(T,', ');
    First:=False;
    Write(T,'(');
    For I:=0 to P^.N-1do Begin
     If I>0Then Write(T,', ');
     Write(T,NumStr(P^.Pts^[I].X),' ',NumStr(P^.Pts^[I].Y));
    End;
    Write(T,')');
    P:=P^.Next;
   End;
   If G.Count>1Then Write(T,')');
  End;
  3:Begin
   If G.NPoly=1Then Write(T,'POLYGON (')Else Write(T,'MULTIPOLYGON ((');
   Prev:=-1;
   P:=G.First;
   While P<>Nil do Begin
    If P^.Poly<>Prev Then Begin
     If Prev>=0Then Write(T,'), (');
     Write(T,'(');
    End
     Else
    Write(T,', (');
    For I:=0 to P^.N-1do Begin
     If I>0Then Write(T,', ');
     Write(T,NumStr(P^.Pts^[I].X),' ',NumStr(P^.Pts^[I].Y));
    End;
    Write(T,')');
    Prev:=P^.Poly;
    P:=P^.Next;
   End;
   If G.NPoly=1Then Write(T,')')Else Write(T,'))');
  End;
 End;
End;

{ ---- Shapefile : lecture ---- }

Function ShpCoord(X,Y:Real;HasZ:Boolean;Z:Real):PJ;
Var
 N:PJ;
Begin
 N:=NewJ(4);
 JAdd(N,JNum(X));JAdd(N,JNum(Y));
 If HasZ and(Z>-1E38)Then JAdd(N,JNum(Z));
 ShpCoord:=N;
End;

{ Polygones d'un enregistrement : imbrication paire = exterieur, impaire = trou }
Function ShpPolygon(B:PBytes;P:LongInt):PJ;
Var
 NParts,NPts,I,J,K,S0,S1:LongInt;
 Parts:PLongs;
 G,R,EG,HG:TGeom;
 Pa:PPath;
 Depth:LongInt;
 Q:PPath;
 Tol:Real;
 A:Real;
Begin
 NParts:=RdLE32(B,P+36);
 NPts:=RdLE32(B,P+40);
 Parts:=AllocBlock((NParts+1)*SizeOf(LongInt));
 For I:=0 to NParts-1do Parts^[I]:=RdLE32(B,P+44+4*I);
 InitGeom(G);G.Cls:=3;
 For I:=0 to NParts-1do Begin
  S0:=Parts^[I];
  If I<NParts-1Then S1:=Parts^[I+1] Else S1:=NPts;
  If S1-S0>=3Then Begin
   Pa:=NewPath(G,S1-S0+1,0);
   For J:=S0 to S1-1do Begin
    Pa^.Pts^[J-S0].X:=RdDouble(B,P+44+4*NParts+16*J);
    Pa^.Pts^[J-S0].Y:=RdDouble(B,P+44+4*NParts+16*J+8);
   End;
   If(Pa^.Pts^[0].X<>Pa^.Pts^[S1-S0-1].X)or(Pa^.Pts^[0].Y<>Pa^.Pts^[S1-S0-1].Y)Then Begin
    Pa^.Pts^[S1-S0]:=Pa^.Pts^[0];Pa^.N:=S1-S0+1;
   End
    Else Pa^.N:=S1-S0;
   Pa^.Area:=RingArea(Pa);
  End;
 End;
 If G.First=Nil Then Begin ShpPolygon:=Nil;Exit;End;
 InitGeom(EG);InitGeom(HG);
 { profondeur d'imbrication de chaque anneau }
 Pa:=G.First;
 While Pa<>Nil do Begin
  Depth:=0;
  Q:=G.First;
  While Q<>Nil do Begin
   If Q<>Pa Then Begin
    K:=0;
    I:=2;
    J:=0;
    While(J<Pa^.N-1)and(I=2)do Begin
     I:=PointInRing(Q,Pa^.Pts^[J].X,Pa^.Pts^[J].Y,0);
     Inc(J);
    End;
    If I=1Then Inc(Depth);
   End;
   Q:=Q^.Next;
  End;
  Pa^.Poly:=Depth;
  Pa:=Pa^.Next;
 End;
 { classement : anneaux de profondeur paire = exterieurs (anti-horaires), impaire = trous (horaires) }
 Pa:=G.First;
 G.First:=Nil;G.Last:=Nil;G.Count:=0;
 While Pa<>Nil do Begin
  Q:=Pa^.Next;
  A:=RingArea(Pa);
  If Not Odd(Pa^.Poly)Then Begin
   If A<0Then ReversePts(Pa^.Pts,Pa^.N);
   Pa^.Area:=Abs(A);
   LinkPath(EG,Pa);
  End
   Else
  Begin
   If A>0Then ReversePts(Pa^.Pts,Pa^.N);
   Pa^.Area:=-Abs(A);
   LinkPath(HG,Pa);
  End;
  Pa:=Q;
 End;
 AssembleRings(EG,HG,1E-12,R);
 ShpPolygon:=BuildPolygons(R);
 FreeGeom(R);
 FreeMem(Parts,(NParts+1)*SizeOf(LongInt));
End;

{ Geometrie GeoJSON d'un enregistrement de type Typ dont le contenu commence en P }
Function ShpGeometry(B:PBytes;P:LongInt):PJ;
Var
 Typ,Base,NPts,NParts,I,J,S0,S1,ZOff:LongInt;
 HasZ:Boolean;
 Co,Ln,Multi:PJ;
 Parts:PLongs;
 X,Y,Z:Real;
Begin
 ShpGeometry:=Nil;
 Typ:=RdLE32(B,P);
 HasZ:=Typ in[11,13,15,18];
 Case Typ of
  1,11,21:Begin
   X:=RdDouble(B,P+4);Y:=RdDouble(B,P+12);
   Z:=0;
   If HasZ Then Z:=RdDouble(B,P+20);
   ShpGeometry:=GeomNode('Point',ShpCoord(X,Y,HasZ,Z));
  End;
  8,18,28:Begin
   NPts:=RdLE32(B,P+36);
   Co:=NewJ(4);
   For I:=0 to NPts-1do Begin
    Z:=0;
    If HasZ Then Z:=RdDouble(B,P+40+16*NPts+16+8*I);
    JAdd(Co,ShpCoord(RdDouble(B,P+40+16*I),RdDouble(B,P+48+16*I),HasZ,Z));
   End;
   ShpGeometry:=GeomNode('MultiPoint',Co);
  End;
  3,13,23:Begin
   NParts:=RdLE32(B,P+36);NPts:=RdLE32(B,P+40);
   Parts:=AllocBlock((NParts+1)*SizeOf(LongInt));
   For I:=0 to NParts-1do Parts^[I]:=RdLE32(B,P+44+4*I);
   Base:=P+44+4*NParts;
   ZOff:=Base+16*NPts+16;
   Multi:=NewJ(4);
   For I:=0 to NParts-1do Begin
    S0:=Parts^[I];
    If I<NParts-1Then S1:=Parts^[I+1] Else S1:=NPts;
    Ln:=NewJ(4);
    For J:=S0 to S1-1do Begin
     Z:=0;
     If HasZ Then Z:=RdDouble(B,ZOff+8*J);
     JAdd(Ln,ShpCoord(RdDouble(B,Base+16*J),RdDouble(B,Base+16*J+8),HasZ,Z));
    End;
    JAdd(Multi,Ln);
   End;
   FreeMem(Parts,(NParts+1)*SizeOf(LongInt));
   If NParts=1Then ShpGeometry:=GeomNode('LineString',Multi^.First)
              Else ShpGeometry:=GeomNode('MultiLineString',Multi);
  End;
  5,15,25:ShpGeometry:=ShpPolygon(B,P);
 End;
End;

{ Texte WKT (ex. contenu d'un .prj) : code du systeme (0 inconnu) ; Name : nom du systeme }
Var
 WkU:PBytes;
 WkN:LongInt;

Function WkFind(Const Pat:String;From:LongInt):LongInt;
Var
 I,K:LongInt;
 Ok:Boolean;
Begin
 WkFind:=-1;
 For I:=From to WkN-Length(Pat)do Begin
  Ok:=True;
  For K:=1 to Length(Pat)do If WkU^[I+K-1]<>Ord(Pat[K])Then Begin Ok:=False;Break;End;
  If Ok Then Begin WkFind:=I;Exit;End;
 End;
End;

{ Premier nombre apres la position P }
Function WkNumAfter(P:LongInt;Var V:Real):Boolean;
Var
 S:String;
 Err:Integer;
Begin
 WkNumAfter:=False;
 While(P<WkN)and Not(Chr(WkU^[P])in['0'..'9','-','+','.'])do Inc(P);
 S:='';
 While(P<WkN)and(Chr(WkU^[P])in['0'..'9','-','+','.','E'])and(Length(S)<40)do Begin
  S:=S+Chr(WkU^[P]);
  Inc(P);
 End;
 Val(S,V,Err);
 WkNumAfter:=(S<>'')and(Err=0);
End;

{ PARAMETER["nom",valeur] }
Function WkParam(Const Names:String;Var V:Real):Boolean;
Var
 P,Q,E:LongInt;
 Nm,Rest:String;
 I:Integer;
Begin
 WkParam:=False;
 Rest:=Names;
 While Rest<>''do Begin
  I:=Pos('|',Rest);
  If I=0Then Begin Nm:=Rest;Rest:='';End
        Else Begin Nm:=Copy(Rest,1,I-1);Rest:=Copy(Rest,I+1,255);End;
  P:=0;
  Repeat
   P:=WkFind('PARAMETER["'+Nm+'"',P);
   If P<0Then Break;
   Q:=P+11+Length(Nm);
   If WkNumAfter(Q,V)Then Begin WkParam:=True;Exit;End;
   P:=P+1;
  Until False;
 End;
End;

Function WkHas(Const S:String):Boolean;Begin
 WkHas:=WkFind(S,0)>=0;
End;

Function CrsFromBytes(B:PBytes;N:LongInt;Var Name:String):LongInt;
Var
 I,P,E,LastAuth,LastEnd,Zn,Q:LongInt;
 V,Lon0,Lat0,Lat1,Lat2,K0,X0,Y0,A,Rf,Dx:Real;
 Prj,Pr,Hemi:String;
 Err:Integer;
 Num:String;
 Clean:Boolean;
 Base:LongInt;
 Datum:String;
Begin
 CrsFromBytes:=0;
 Name:='';
 If N<=0Then Exit;
 WkU:=AllocBlock(N+1);
 WkN:=N;
 For I:=0 to N-1do Begin
  If(B^[I]>=97)and(B^[I]<=122)Then WkU^[I]:=B^[I]-32 Else WkU^[I]:=B^[I];
 End;
 { nom : premiere chaine entre guillemets }
 P:=0;
 While(P<N)and(B^[P]<>34)do Inc(P);
 Inc(P);
 While(P<N)and(B^[P]<>34)and(Length(Name)<60)do Begin Name:=Name+Chr(B^[P]);Inc(P);End;
 { derniere autorite EPSG, en fin de texte }
 LastAuth:=0;LastEnd:=-1;
 P:=0;
 Repeat
  P:=WkFind('AUTHORITY["EPSG","',P);
  If P<0Then Break;
  Num:='';
  Q:=P+18;
  While(Q<N)and(Chr(WkU^[Q])in['0'..'9'])do Begin Num:=Num+Chr(WkU^[Q]);Inc(Q);End;
  Val(Num,E,Err);
  If(Err=0)and(Num<>'')Then Begin LastAuth:=E;LastEnd:=Q;End;
  P:=P+1;
 Until False;
 If LastEnd>=0Then Begin
  Clean:=True;
  For I:=LastEnd to N-1do If Not(Chr(WkU^[I])in['"',']',' ',#9,#10,#13,#26])Then Clean:=False;
  If Clean and CrsKnown(LastAuth)Then Begin
   If LastAuth=900913Then LastAuth:=3857;
   CrsFromBytes:=LastAuth;
   FreeMem(WkU,N+1);
   Exit;
  End;
 End;
 If WkHas('MERCATOR_AUXILIARY_SPHERE')or WkHas('WEB_MERCATOR')or WkHas('PSEUDO-MERCATOR')or WkHas('POPULAR VISUALISATION')Then Begin
  CrsFromBytes:=3857;FreeMem(WkU,N+1);Exit;
 End;
 If Not WkHas('PROJCS')Then Begin
  If WkHas('GCS_WGS_1984')or WkHas('"WGS 84"')or WkHas('"WGS84"')or WkHas('"WGS_1984"')Then CrsFromBytes:=4326 Else
  If WkHas('NAD83')or WkHas('NAD_1983')Then CrsFromBytes:=4269 Else
  If WkHas('NAD27')or WkHas('NAD_1927')Then CrsFromBytes:=4267 Else
  If WkHas('ETRS89')or WkHas('ETRS_1989')Then CrsFromBytes:=4258 Else
  If WkHas('GCS_NORTH_AMERICAN_1983')Then CrsFromBytes:=4269 Else
  If WkHas('GCS_NORTH_AMERICAN_1927')Then CrsFromBytes:=4267;
  FreeMem(WkU,N+1);
  Exit;
 End;
 { zones UTM par le nom }
 P:=WkFind('UTM_ZONE_',0);
 If P<0Then P:=WkFind('UTM ZONE ',0);
 If P>=0Then Begin
  Q:=P+9;
  Num:='';
  While(Q<N)and(Chr(WkU^[Q])in['0'..'9'])do Begin Num:=Num+Chr(WkU^[Q]);Inc(Q);End;
  Val(Num,Zn,Err);
  If(Err=0)and(Zn>=1)and(Zn<=60)Then Begin
   Hemi:='N';
   If(Q<N)and(Chr(WkU^[Q])='S')Then Hemi:='S';
   Base:=0;
   If WkHas('NAD_1983')or WkHas('NAD83')Then Base:=26900 Else
   If WkHas('NAD_1927')or WkHas('NAD27')Then Base:=26700 Else
   If WkHas('ETRS')Then Base:=25800 Else
   If WkHas('ED_1950')or WkHas('ED50')Then Base:=23000 Else
   If Hemi='S'Then Base:=32700 Else Base:=32600;
   If CrsKnown(Base+Zn)Then Begin
    CrsFromBytes:=Base+Zn;
    FreeMem(WkU,N+1);
    Exit;
   End;
  End;
 End;
 { projection generique decrite par ses parametres }
 Prj:='';
 P:=WkFind('PROJECTION["',0);
 If P>=0Then Begin
  Q:=P+12;
  While(Q<N)and(WkU^[Q]<>34)and(Length(Prj)<50)do Begin Prj:=Prj+Chr(WkU^[Q]);Inc(Q);End;
 End;
 If(Prj='')or(Not WkHas('UNIT["METER"')and Not WkHas('UNIT["METRE"')and Not WkHas('UNIT["M"'))Then Begin
  FreeMem(WkU,N+1);Exit;
 End;
 Lon0:=0;Lat0:=0;Lat1:=0;Lat2:=0;K0:=1;X0:=0;Y0:=0;
 WkParam('CENTRAL_MERIDIAN|LONGITUDE_OF_CENTER|LONGITUDE_OF_ORIGIN',Lon0);
 WkParam('LATITUDE_OF_ORIGIN|LATITUDE_OF_CENTER',Lat0);
 WkParam('STANDARD_PARALLEL_1',Lat1);
 WkParam('STANDARD_PARALLEL_2',Lat2);
 WkParam('SCALE_FACTOR',K0);
 WkParam('FALSE_EASTING',X0);
 WkParam('FALSE_NORTHING',Y0);
 A:=0;Rf:=0;
 P:=WkFind('SPHEROID["',0);
 If P>=0Then Begin
  Q:=P+10;
  While(Q<N)and(WkU^[Q]<>34)do Inc(Q);
  Inc(Q);
  If WkNumAfter(Q,A)Then Begin
   While(Q<N)and(WkU^[Q]<>44)do Inc(Q);
   Inc(Q);
   While(Q<N)and(Chr(WkU^[Q])in['0'..'9','-','+','.','E'])do Inc(Q);
   If WkNumAfter(Q,Rf)Then Begin End;
  End;
 End;
 FreeMem(WkU,N+1);
 If A<=0Then Exit;
 Pr:='';
 If Prj='TRANSVERSE_MERCATOR'Then Pr:='+proj=tmerc +lat_0='+NumStr(Lat0)+' +lon_0='+NumStr(Lon0)+' +k_0='+NumStr(K0) Else
 If(Prj='LAMBERT_CONFORMAL_CONIC_2SP')or(Prj='LAMBERT_CONFORMAL_CONIC')or(Prj='LAMBERT_CONFORMAL_CONIC_1SP')Then Begin
  If Lat1=0Then Lat1:=Lat0;
  If Lat2=0Then Lat2:=Lat1;
  Pr:='+proj=lcc +lat_0='+NumStr(Lat0)+' +lon_0='+NumStr(Lon0)+' +lat_1='+NumStr(Lat1)+' +lat_2='+NumStr(Lat2);
 End Else
 If(Prj='ALBERS')or(Prj='ALBERS_CONIC_EQUAL_AREA')Then
  Pr:='+proj=aea +lat_0='+NumStr(Lat0)+' +lon_0='+NumStr(Lon0)+' +lat_1='+NumStr(Lat1)+' +lat_2='+NumStr(Lat2) Else
 If Prj='MERCATOR_1SP'Then Pr:='+proj=merc +lon_0='+NumStr(Lon0)+' +k_0='+NumStr(K0) Else
 If Prj='LAMBERT_AZIMUTHAL_EQUAL_AREA'Then Pr:='+proj=laea +lat_0='+NumStr(Lat0)+' +lon_0='+NumStr(Lon0) Else
 If(Prj='POLAR_STEREOGRAPHIC')or(Prj='STEREOGRAPHIC_NORTH_POLE')or(Prj='STEREOGRAPHIC_SOUTH_POLE')Then Begin
  If Lat1=0Then Lat1:=Lat0;
  If Prj='STEREOGRAPHIC_SOUTH_POLE'Then Lat1:=-Abs(Lat1);
  Pr:='+proj=stere +lat_0='+NumStr(SgnR(Lat1)*90)+' +lon_0='+NumStr(Lon0)+' +lat_ts='+NumStr(Lat1);
 End;
 If Pr=''Then Exit;
 Pr:=Pr+' +x_0='+NumStr(X0)+' +y_0='+NumStr(Y0)+' +a='+NumStr(A);
 If Rf>0Then Pr:=Pr+' +rf='+NumStr(Rf)
        Else Pr:=Pr+' +b='+NumStr(A);
 CrsFromBytes:=ParseProj(Pr);
End;

Function CrsFromWkt(W:String;Var Name:String):LongInt;
Var
 B:PBytes;
Begin
 CrsFromWkt:=0;
 Name:='';
 If W=''Then Exit;
 B:=AllocBlock(Length(W)+1);
 Move(W[1],B^,Length(W));
 CrsFromWkt:=CrsFromBytes(B,Length(W),Name);
 FreeMem(B,Length(W)+1);
End;

Function CrsFromFile(FileName:String;Var Name:String):LongInt;
Var
 B:PBytes;
 N:LongInt;
Begin
 CrsFromFile:=0;
 Name:='';
 B:=LoadFileBytes(FileName,N);
 If B=Nil Then Exit;
 CrsFromFile:=CrsFromBytes(B,N,Name);
 FreeMem(B,N+8);
End;

Procedure ApplyCrsFile(Root:PJ;FileName:String);
Var
 Code:LongInt;
 Name:String;
 C,P:PJ;
Begin
 Code:=CrsFromFile(FileName,Name);
 If Code>0Then Begin
  SetLayerCrs(Root,Code);
  Exit;
 End;
 If Name=''Then Exit;
 JRemoveKey(Root,'crs');
 C:=NewJ(5);
 JAddKV(C,'type',JText('name'));
 P:=NewJ(5);
 JAddKV(P,'name',JTextEsc(Name));
 JAddKV(C,'properties',P);
 JAddKV(Root,'crs',C);
End;

Procedure ApplyCrs(Root:PJ;Wkt:String);
Var
 Code:LongInt;
 Name:String;
 C,P:PJ;
Begin
 If Wkt=''Then Exit;
 Code:=CrsFromWkt(Wkt,Name);
 If Code>0Then SetLayerCrs(Root,Code) Else
 Begin
  JRemoveKey(Root,'crs');
  C:=NewJ(5);
  JAddKV(C,'type',JText('name'));
  P:=NewJ(5);
  If Name=''Then Name:='unknown';
  JAddKV(P,'name',JTextEsc(Name));
  JAddKV(C,'properties',P);
  JAddKV(Root,'crs',C);
 End;
End;

Function ReadTextFile(FileName:String):String;
Var
 B:PBytes;
 Size:LongInt;
 S:String;
 I:LongInt;
Begin
 ReadTextFile:='';
 B:=LoadFileBytes(FileName,Size);
 If B=Nil Then Exit;
 S:='';
 For I:=0 to Size-1do Begin
  If Length(S)>=250Then Break;
  If B^[I]>=32Then S:=S+Chr(B^[I]);
 End;
 FreeMem(B,Size+8);
 ReadTextFile:=S;
End;

{ Octets ISO-8859-1 / Windows-1252 convertis en UTF-8 }
Function Latin1ToUtf8(S:String):String;
Var
 I:Integer;
 T:String;
Begin
 T:='';
 For I:=1 to Length(S)do
  If Ord(S[I])<128Then T:=T+S[I]
   Else
  T:=T+Chr($C0 or(Ord(S[I])shr 6))+Chr($80 or(Ord(S[I])and $3F));
 Latin1ToUtf8:=T;
End;

Function LoadShapefile(Path:String):PJ;
Var
 Shp,Dbf:PBytes;
 ShpSize,DbfSize,Cur,Len,Typ,RecNo,NFields,HdrLen,RecLen,NRec,I,J,Off,FLen:LongInt;
 Root,Arr,Pr,Gm,Node:PJ;
 FName:Array[1..128]of String[11];
 FType:Array[1..128]of Char;
 FWidth,FDec:Array[1..128]of Integer;
 DbfName,PrjName,CpgName,Cpg,S,T:String;
 Latin:Boolean;
 Deleted:Boolean;
 R:Real;
 E:Integer;
 Idx:LongInt;
Begin
 If FileExt(Path)=''Then Path:=Path+'.shp';
 Shp:=LoadFileBytes(Path,ShpSize);
 If Shp=Nil Then Fail('Error: unable to open input file '+Path);
 If(ShpSize<100)or(RdBE32(Shp,0)<>9994)Then Fail('Error: '+Path+' is not a shapefile');
 Root:=NewLayerLike(Nil,Arr);
 DbfName:=SideFile(Path,'.dbf');
 Dbf:=Nil;
 NFields:=0;HdrLen:=0;RecLen:=0;NRec:=0;
 If DbfName<>''Then Dbf:=LoadFileBytes(DbfName,DbfSize);
 If Dbf<>Nil Then Begin
  NRec:=RdLE32(Dbf,4);HdrLen:=RdLE16(Dbf,8);RecLen:=RdLE16(Dbf,10);
  NFields:=(HdrLen-33)div 32;
  If NFields>128Then NFields:=128;
  For I:=1 to NFields do Begin
   Off:=32+(I-1)*32;
   T:='';
   J:=0;
   While(J<11)and(Dbf^[Off+J]<>0)do Begin T:=T+Chr(Dbf^[Off+J]);Inc(J);End;
   FName[I]:=T;
   FType[I]:=Chr(Dbf^[Off+11]);
   FWidth[I]:=Dbf^[Off+16];
   FDec[I]:=Dbf^[Off+17];
  End;
 End;
 Latin:=False;
 CpgName:=SideFile(Path,'.cpg');
 If CpgName<>''Then Begin
  Cpg:=StrUpper(ReadTextFile(CpgName));
  Latin:=(Pos('8859',Cpg)>0)or(Pos('1252',Cpg)>0)or(Pos('LATIN',Cpg)>0);
 End;
 Cur:=100;
 RecNo:=0;
 While Cur+8<=ShpSize do Begin
  Len:=RdBE32(Shp,Cur+4)*2;
  Gm:=Nil;
  If(Len>=4)and(Cur+8+Len<=ShpSize)Then Begin
   Typ:=RdLE32(Shp,Cur+8);
   If Typ<>0Then Gm:=ShpGeometry(Shp,Cur+8);
  End;
  Deleted:=False;
  Pr:=NewJ(5);
  If Dbf<>Nil Then Begin
   Off:=HdrLen+RecNo*RecLen;
   If Off+RecLen<=DbfSize Then Begin
    Deleted:=Dbf^[Off]=Ord('*');
    Inc(Off);
    For I:=1 to NFields do Begin
     S:='';
     For J:=0 to FWidth[I]-1do Begin
      If Length(S)<250Then S:=S+Chr(Dbf^[Off+J]);
     End;
     Inc(Off,FWidth[I]);
     While(S<>'')and(S[Length(S)]in[' ',#0])do S:=Copy(S,1,Length(S)-1);
     If FType[I]in['N','F']Then Begin
      While(S<>'')and(S[1]=' ')do S:=Copy(S,2,255);
      Val(S,R,E);
      If(S='')or(E<>0)Then Node:=NewJ(0) Else Node:=JNum(R);
     End
      Else
     If FType[I]='L'Then Begin
      If S<>''Then Begin
       If S[1]in['T','t','Y','y']Then Node:=JBool(True) Else
       If S[1]in['F','f','N','n']Then Node:=JBool(False)
                                 Else Node:=NewJ(0);
      End
       Else
      Node:=NewJ(0);
     End
      Else
     If FType[I]='D'Then Begin
      If Length(S)=8Then Node:=JTextEsc(Copy(S,1,4)+'-'+Copy(S,5,2)+'-'+Copy(S,7,2))
                    Else Node:=NewJ(0);
     End
      Else
     Begin
      If Latin Then S:=Latin1ToUtf8(S);
      Node:=JTextEsc(S);
     End;
     JAddKV(Pr,FName[I],Node);
    End;
   End;
  End;
  If Not Deleted Then JAdd(Arr,NewFeature(Pr,Gm));
  Inc(RecNo);
  Cur:=Cur+8+Len;
 End;
 PrjName:=SideFile(Path,'.prj');
 If PrjName<>''Then ApplyCrsFile(Root,PrjName);
 LoadShapefile:=Root;
End;

{ ---- Shapefile : ecriture ---- }

Const
 PrjWgs84='GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]]';
 PrjMerc1='PROJCS["WGS_1984_Web_Mercator_Auxiliary_Sphere",GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],';
 PrjMerc2='PROJECTION["Mercator_Auxiliary_Sphere"],PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",0.0],PARAMETER["Standard_Parallel_1",0.0],PARAMETER["Auxiliary_Sphere_Type",0.0],UNIT["Meter",1.0]]';

{ Ecrit un fichier texte (deux morceaux, car une chaine Pascal est limitee a 255 caracteres) }
Procedure WriteSmallText(FileName,S:String;S2:String);
Var
 T:Text;
Begin
 {$I-}
 Assign(T,FileName);
 Rewrite(T);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to create output file '+FileName);
 Write(T,S);
 Write(T,S2);
 Close(T);
End;

{ Texte WKT d'un systeme de coordonnees dans un tampon }
Procedure CrsWktBuf(Code:LongInt;Var B:TBuf);
Var
 C:TCrs;
 Nm,Pn,Prm:String;
 Geog:String;
 Known:Boolean;

 Function Pm(N:String;V:Real):String;Begin
  Pm:=',PARAMETER["'+N+'",'+NumStr(V)+']';
 End;

Begin
 If Not CrsDefine(Code,C)Then Fail('Error: unsupported CRS EPSG:'+IntToStr(Code));
 Known:=Code<=CustomBase;
 If C.Ell=1Then Nm:=EllName[1] Else Nm:=EllName[C.Ell];
 If C.Ell=0Then Nm:='Custom';
 Geog:='GEOGCS["GCS_'+Nm+'",DATUM["D_'+Nm+'",SPHEROID["'+Nm+'",'+NumStr(C.EA)+','+NumStr(C.EF)+']';
 If HasShift(C)Then
  Geog:=Geog+',TOWGS84['+NumStr(C.Dx)+','+NumStr(C.Dy)+','+NumStr(C.Dz)+','+NumStr(C.Rx*648000/Pi)+','+NumStr(C.Ry*648000/Pi)+','+NumStr(C.Rz*648000/Pi)+','+NumStr(C.Sc*1E6)+']';
 Geog:=Geog+'],PRIMEM["Greenwich",0],UNIT["Degree",0.0174532925199433]';
 If C.Kind=KGeo Then Begin
  If Known Then Geog:=Geog+',AUTHORITY["EPSG","'+IntToStr(Code)+'"]';
  BufText(B,Geog+']');
  Exit;
 End;
 BufText(B,'PROJCS["'+C.Name+'",'+Geog+'],');
 Pn:='';Prm:='';
 Case C.Kind of
  KTm:Begin Pn:='Transverse_Mercator';Prm:=Pm('latitude_of_origin',C.Lat0)+Pm('central_meridian',C.Lon0)+Pm('scale_factor',C.K0);End;
  KLcc:Begin Pn:='Lambert_Conformal_Conic_2SP';Prm:=Pm('standard_parallel_1',C.Lat1)+Pm('standard_parallel_2',C.Lat2)+Pm('latitude_of_origin',C.Lat0)+Pm('central_meridian',C.Lon0);End;
  KAea:Begin Pn:='Albers_Conic_Equal_Area';Prm:=Pm('standard_parallel_1',C.Lat1)+Pm('standard_parallel_2',C.Lat2)+Pm('latitude_of_center',C.Lat0)+Pm('longitude_of_center',C.Lon0);End;
  KMerc,KWeb:Begin Pn:='Mercator_1SP';Prm:=Pm('central_meridian',C.Lon0)+Pm('scale_factor',C.K0);End;
  KLaea:Begin Pn:='Lambert_Azimuthal_Equal_Area';Prm:=Pm('latitude_of_center',C.Lat0)+Pm('longitude_of_center',C.Lon0);End;
  KPolar:Begin Pn:='Polar_Stereographic';Prm:=Pm('latitude_of_origin',C.Lat1)+Pm('central_meridian',C.Lon0)+Pm('scale_factor',1);End;
  Else Begin Pn:='Equirectangular';Prm:=Pm('central_meridian',C.Lon0);End;
 End;
 BufText(B,'PROJECTION["'+Pn+'"]');
 BufText(B,Prm);
 BufText(B,Pm('false_easting',C.X0)+Pm('false_northing',C.Y0)+',UNIT["Meter",1]');
 If Known Then BufText(B,',AUTHORITY["EPSG","'+IntToStr(Code)+'"]');
 BufText(B,']');
End;

Procedure WritePrj(FileName:String;Code:LongInt);
Var
 B:TBuf;
Begin
 If Code=4326Then Begin WriteSmallText(FileName,PrjWgs84,'');Exit;End;
 If Code=3857Then Begin WriteSmallText(FileName,PrjMerc1,PrjMerc2);Exit;End;
 If Code<=0Then Exit;
 BufInit(B);
 CrsWktBuf(Code,B);
 BufSave(FileName,B);
End;


{ Anneau en sens horaire (exterieur) ou anti-horaire (trou) pour le Shapefile }
Procedure ShpOrientRing(P:PPath;Exterior:Boolean);
Var
 A:Real;
Begin
 A:=RingArea(P);
 If(Exterior and(A>0))or((Not Exterior)and(A<0))Then ReversePts(P^.Pts,P^.N);
End;

Procedure SaveShapefile(Path:String;Root:PJ);
Var
 Arr,F,Pr,C,N:PJ;
 FA:PJArr;
 NF,I,J,K,NFld:LongInt;
 G:TGeom;
 P:PPath;
 Cls,ShpType,Cnt:Integer;
 Shp,Shx,Dbf:TBuf;
 RecStart,Content,NPts,NParts,Prev:LongInt;
 MinX,MinY,MaxX,MaxY,X1,Y1,X2,Y2:Real;
 HaveBox,Multi:Boolean;
 Names:Array[1..128]of String[10];
 Full:Array[1..128]of String;
 Typ:Array[1..128]of Char;
 Width,Dec:Array[1..128]of Integer;
 Found,AllNum,AllInt,AllBool,AnyVal:Boolean;
 S,T,Nm:String;
 Wk:String;
 Crs:LongInt;
Begin
 If FileExt(Path)=''Then Path:=Path+'.shp';
 Arr:=LayerFeatures(Root);
 FA:=FeatureArray(Arr,NF);
 { type de geometrie }
 Cls:=0;Multi:=False;
 For I:=0 to NF-1do Begin
  FlattenFeature(FA^[I],G);
  If G.Cls<>0Then Begin
   If(Cls<>0)and(Cls<>G.Cls)Then Fail('Error: a shapefile cannot store several geometry types');
   Cls:=G.Cls;
   If(G.Cls=1)and(G.Count>1)Then Multi:=True;
  End;
  FreeGeom(G);
 End;
 Case Cls of
  1:If Multi Then ShpType:=8 Else ShpType:=1;
  2:ShpType:=3;
  3:ShpType:=5;
  Else ShpType:=1;
 End;
 BufInit(Shp);BufInit(Shx);
 { en-tetes (completes a la fin) }
 BufBE32(Shp,9994);BufFill(Shp,20,0);BufBE32(Shp,0);BufLE32(Shp,1000);BufLE32(Shp,ShpType);BufFill(Shp,64,0);
 BufBE32(Shx,9994);BufFill(Shx,20,0);BufBE32(Shx,0);BufLE32(Shx,1000);BufLE32(Shx,ShpType);BufFill(Shx,64,0);
 HaveBox:=False;MinX:=0;MinY:=0;MaxX:=0;MaxY:=0;
 For I:=0 to NF-1do Begin
  FlattenFeature(FA^[I],G);
  RecStart:=Shp.N;
  BufBE32(Shp,I+1);
  If G.Cls=0Then Begin
   BufBE32(Shp,2);
   BufLE32(Shp,0);
  End
   Else
  Begin
   GeomBBox(G,X1,Y1,X2,Y2);
   If Not HaveBox Then Begin MinX:=X1;MinY:=Y1;MaxX:=X2;MaxY:=Y2;HaveBox:=True;End
    Else
   Begin
    If X1<MinX Then MinX:=X1;If Y1<MinY Then MinY:=Y1;
    If X2>MaxX Then MaxX:=X2;If Y2>MaxY Then MaxY:=Y2;
   End;
   NPts:=0;NParts:=0;
   P:=G.First;
   While P<>Nil do Begin
    If G.Cls=3Then Begin
     If(P^.Pts^[0].X<>P^.Pts^[P^.N-1].X)or(P^.Pts^[0].Y<>P^.Pts^[P^.N-1].Y)Then NPts:=NPts+P^.N+1
                                                                         Else NPts:=NPts+P^.N;
    End
     Else
    NPts:=NPts+P^.N;
    Inc(NParts);
    P:=P^.Next;
   End;
   If ShpType=1Then Begin
    BufBE32(Shp,10);
    BufLE32(Shp,1);
    BufDouble(Shp,G.First^.Pts^[0].X);BufDouble(Shp,G.First^.Pts^[0].Y);
   End
    Else
   If ShpType=8Then Begin
    BufBE32(Shp,(40+16*NPts)div 2);
    BufLE32(Shp,8);
    BufDouble(Shp,X1);BufDouble(Shp,Y1);BufDouble(Shp,X2);BufDouble(Shp,Y2);
    BufLE32(Shp,NPts);
    P:=G.First;
    While P<>Nil do Begin BufDouble(Shp,P^.Pts^[0].X);BufDouble(Shp,P^.Pts^[0].Y);P:=P^.Next;End;
   End
    Else
   Begin
    BufBE32(Shp,(44+4*NParts+16*NPts)div 2);
    BufLE32(Shp,ShpType);
    BufDouble(Shp,X1);BufDouble(Shp,Y1);BufDouble(Shp,X2);BufDouble(Shp,Y2);
    BufLE32(Shp,NParts);BufLE32(Shp,NPts);
    { index des parties }
    K:=0;
    Prev:=-1;
    P:=G.First;
    While P<>Nil do Begin
     BufLE32(Shp,K);
     If G.Cls=3Then Begin
      If(P^.Pts^[0].X<>P^.Pts^[P^.N-1].X)or(P^.Pts^[0].Y<>P^.Pts^[P^.N-1].Y)Then Inc(K,P^.N+1) Else Inc(K,P^.N);
     End
      Else Inc(K,P^.N);
     P:=P^.Next;
    End;
    Prev:=-1;
    P:=G.First;
    While P<>Nil do Begin
     If G.Cls=3Then Begin
      ShpOrientRing(P,P^.Poly<>Prev);
      Prev:=P^.Poly;
     End;
     For J:=0 to P^.N-1do Begin BufDouble(Shp,P^.Pts^[J].X);BufDouble(Shp,P^.Pts^[J].Y);End;
     If G.Cls=3Then
      If(P^.Pts^[0].X<>P^.Pts^[P^.N-1].X)or(P^.Pts^[0].Y<>P^.Pts^[P^.N-1].Y)Then Begin
       BufDouble(Shp,P^.Pts^[0].X);BufDouble(Shp,P^.Pts^[0].Y);
      End;
     P:=P^.Next;
    End;
   End;
  End;
  BufBE32(Shx,RecStart div 2);
  BufBE32(Shx,(Shp.N-RecStart-8)div 2);
  FreeGeom(G);
 End;
 { longueur et boite dans les en-tetes }
 Shp.P^[24]:=((Shp.N div 2)shr 24)and 255;Shp.P^[25]:=((Shp.N div 2)shr 16)and 255;Shp.P^[26]:=((Shp.N div 2)shr 8)and 255;Shp.P^[27]:=(Shp.N div 2)and 255;
 Shx.P^[24]:=((Shx.N div 2)shr 24)and 255;Shx.P^[25]:=((Shx.N div 2)shr 16)and 255;Shx.P^[26]:=((Shx.N div 2)shr 8)and 255;Shx.P^[27]:=(Shx.N div 2)and 255;
 Move(MinX,Shp.P^[36],8);Move(MinY,Shp.P^[44],8);Move(MaxX,Shp.P^[52],8);Move(MaxY,Shp.P^[60],8);
 Move(MinX,Shx.P^[36],8);Move(MinY,Shx.P^[44],8);Move(MaxX,Shx.P^[52],8);Move(MaxY,Shx.P^[60],8);
 BufSave(Path,Shp);
 BufSave(ChangeExt(Path,'.shx'),Shx);
 { ---- attributs (.dbf) ---- }
 NFld:=0;
 For I:=0 to NF-1do Begin
  Pr:=JFind(FA^[I],'properties');
  If(Pr<>Nil)and(Pr^.Kind=5)Then Begin
   C:=Pr^.First;
   While C<>Nil do Begin
    Found:=False;
    For J:=1 to NFld do If Full[J]=JKey(C)Then Found:=True;
    If(Not Found)and(NFld<128)Then Begin Inc(NFld);Full[NFld]:=JKey(C);End;
    C:=C^.Next;
   End;
  End;
 End;
 For J:=1 to NFld do Begin
  { nom de 10 caracteres au plus, unique }
  Nm:=Copy(Full[J],1,10);
  K:=0;
  Repeat
   Found:=False;
   For I:=1 to J-1do If Names[I]=Nm Then Found:=True;
   If Found Then Begin
    Inc(K);
    Nm:=Copy(Full[J],1,10-Length(IntToStr(K))-1)+'_'+IntToStr(K);
   End;
  Until Not Found;
  Names[J]:=Nm;
  AllNum:=True;AllInt:=True;AllBool:=True;AnyVal:=False;
  Width[J]:=1;Dec[J]:=0;
  For I:=0 to NF-1do Begin
   N:=GetProp(FA^[I],Full[J]);
   If(N<>Nil)and(N^.Kind<>0)Then Begin
    AnyVal:=True;
    If N^.Kind<>1Then AllBool:=False;
    If N^.Kind<>2Then AllNum:=False
     Else
    Begin
     If(Pos('.',JVal(N))>0)or(Pos('e',JVal(N))>0)or(Pos('E',JVal(N))>0)Then Begin
      AllInt:=False;
      K:=Length(JVal(N))-Pos('.',JVal(N));
      If(Pos('.',JVal(N))>0)and(K>Dec[J])Then Dec[J]:=K;
     End;
     If Length(JVal(N))>Width[J]Then Width[J]:=Length(JVal(N));
    End;
    If N^.Kind=3Then Begin
     S:=NodeText(N);
     If Length(S)>Width[J]Then Width[J]:=Length(S);
    End;
   End;
  End;
  If Not AnyVal Then Begin Typ[J]:='C';Width[J]:=1;End Else
  If AllBool Then Begin Typ[J]:='L';Width[J]:=1;End Else
  If AllNum Then Begin
   Typ[J]:='N';
   If AllInt Then Begin Dec[J]:=0;If Width[J]>18Then Width[J]:=18;End
    Else
   Begin If Dec[J]>15Then Dec[J]:=15;Width[J]:=24;End;
  End
   Else
  Begin
   Typ[J]:='C';
   For I:=0 to NF-1do Begin
    N:=GetProp(FA^[I],Full[J]);
    If(N<>Nil)and(N^.Kind=2)and(Length(JVal(N))>Width[J])Then Width[J]:=Length(JVal(N));
   End;
   If Width[J]>254Then Width[J]:=254;
  End;
 End;
 BufInit(Dbf);
 K:=1;
 For J:=1 to NFld do Inc(K,Width[J]);
 BufByte(Dbf,3);BufByte(Dbf,126);BufByte(Dbf,1);BufByte(Dbf,1);
 BufLE32(Dbf,NF);BufLE16(Dbf,33+32*NFld);BufLE16(Dbf,K);BufFill(Dbf,20,0);
 For J:=1 to NFld do Begin
  BufText(Dbf,Names[J]);BufFill(Dbf,11-Length(Names[J]),0);
  BufByte(Dbf,Ord(Typ[J]));BufFill(Dbf,4,0);
  BufByte(Dbf,Width[J]);BufByte(Dbf,Dec[J]);BufFill(Dbf,14,0);
 End;
 BufByte(Dbf,13);
 For I:=0 to NF-1do Begin
  BufByte(Dbf,32);
  For J:=1 to NFld do Begin
   N:=GetProp(FA^[I],Full[J]);
   S:='';
   If(N<>Nil)and(N^.Kind<>0)Then Begin
    Case Typ[J]of
     'N':Begin
      If N^.Kind=2Then Begin
       Val(JVal(N),X1,K);
       If Dec[J]=0Then Str(X1:Width[J]:0,S) Else Str(X1:Width[J]:Dec[J],S);
      End;
     End;
     'L':If JVal(N)='true'Then S:='T' Else S:='F';
     Else S:=NodeText(N);
    End;
   End;
   If Typ[J]='N'Then Begin
    While Length(S)<Width[J]do S:=' '+S;
    If Length(S)>Width[J]Then S:=Copy(S,1,Width[J]);
   End
    Else
   Begin
    If(Typ[J]='L')and(S='')Then S:='?';
    If Length(S)>Width[J]Then S:=Copy(S,1,Width[J]);
    While Length(S)<Width[J]do S:=S+' ';
   End;
   BufText(Dbf,S);
  End;
 End;
 BufByte(Dbf,26);
 BufSave(ChangeExt(Path,'.dbf'),Dbf);
 WriteSmallText(ChangeExt(Path,'.cpg'),'UTF-8','');
 { systeme de coordonnees }
 Crs:=SoftCrs(Root);
 If Crs>0Then WritePrj(ChangeExt(Path,'.prj'),Crs);
End;

{ ------------------------------------------------------------------ }
{ Decompression : Deflate (zlib), LZW TIFF, PackBits                  }
{ ------------------------------------------------------------------ }

Type
 THuff=Record
  Cnt:Array[0..15]of Integer;
  Sym:Array[0..319]of Integer;
 End;
 TLens=Array[0..319]of Integer;

Const
 LBase:Array[0..28]of Integer=(3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258);
 LExt:Array[0..28]of Integer=(0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0);
 DBase:Array[0..29]of Integer=(1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577);
 DExt:Array[0..29]of Integer=(0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13);
 CodeOrder:Array[0..18]of Integer=(16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15);

Var
 InP:PBytes;
 InN,InPos:LongInt;
 BitBuf:LongInt;
 BitCnt:Integer;
 OutP:PBytes;
 OutCap,OutPos:LongInt;
 HuffL,HuffD:THuff;

Procedure BadData;Begin
 Fail('Error: corrupt compressed data');
End;

Function InBits(Need:Integer):LongInt;
Var
 V:LongInt;
Begin
 V:=BitBuf;
 While BitCnt<Need do Begin
  If InPos>=InN Then BadData;
  V:=V or(LongInt(InP^[InPos])shl BitCnt);
  Inc(InPos);
  Inc(BitCnt,8);
 End;
 BitBuf:=V shr Need;
 BitCnt:=BitCnt-Need;
 InBits:=V and((LongInt(1)shl Need)-1);
End;

Function BuildHuff(Var H:THuff;Var L:TLens;N:Integer):Integer;
Var
 I,Len,Left:Integer;
 Offs:Array[0..15]of Integer;
Begin
 For I:=0 to 15do H.Cnt[I]:=0;
 For I:=0 to N-1do Inc(H.Cnt[L[I]]);
 BuildHuff:=0;
 If H.Cnt[0]=N Then Exit;
 Left:=1;
 For Len:=1 to 15do Begin
  Left:=Left*2-H.Cnt[Len];
  If Left<0Then Begin BuildHuff:=Left;Exit;End;
 End;
 Offs[1]:=0;
 For Len:=1 to 14do Offs[Len+1]:=Offs[Len]+H.Cnt[Len];
 For I:=0 to N-1do If L[I]<>0Then Begin
  H.Sym[Offs[L[I]]]:=I;
  Inc(Offs[L[I]]);
 End;
 BuildHuff:=Left;
End;

Function HuffDecode(Var H:THuff):Integer;
Var
 Len,Code,First,Index,Count:Integer;
Begin
 Code:=0;First:=0;Index:=0;
 For Len:=1 to 15do Begin
  Code:=Code or Integer(InBits(1));
  Count:=H.Cnt[Len];
  If Code-Count<First Then Begin
   HuffDecode:=H.Sym[Index+(Code-First)];
   Exit;
  End;
  Index:=Index+Count;
  First:=(First+Count)shl 1;
  Code:=Code shl 1;
 End;
 BadData;
 HuffDecode:=0;
End;

Procedure InflateCodes;
Var
 Sym,Len,Dist:Integer;
Begin
 Repeat
  Sym:=HuffDecode(HuffL);
  If Sym<256Then Begin
   If OutPos>=OutCap Then BadData;
   OutP^[OutPos]:=Sym;
   Inc(OutPos);
  End
   Else
  If Sym>256Then Begin
   Dec(Sym,257);
   If Sym>=29Then BadData;
   Len:=LBase[Sym]+Integer(InBits(LExt[Sym]));
   Sym:=HuffDecode(HuffD);
   If Sym>=30Then BadData;
   Dist:=DBase[Sym]+Integer(InBits(DExt[Sym]));
   If(Dist>OutPos)or(OutPos+Len>OutCap)Then BadData;
   While Len>0do Begin
    OutP^[OutPos]:=OutP^[OutPos-Dist];
    Inc(OutPos);
    Dec(Len);
   End;
  End;
 Until Sym=256;
End;

Procedure InflateFixed;
Var
 L:TLens;
 I:Integer;
Begin
 For I:=0 to 143do L[I]:=8;
 For I:=144 to 255do L[I]:=9;
 For I:=256 to 279do L[I]:=7;
 For I:=280 to 287do L[I]:=8;
 BuildHuff(HuffL,L,288);
 For I:=0 to 29do L[I]:=5;
 BuildHuff(HuffD,L,30);
 InflateCodes;
End;

Procedure InflateDynamic;
Var
 L:TLens;
 NLen,NDist,NCode,I,Sym,Rep,Prev:Integer;
Begin
 NLen:=Integer(InBits(5))+257;
 NDist:=Integer(InBits(5))+1;
 NCode:=Integer(InBits(4))+4;
 If(NLen>286)or(NDist>30)Then BadData;
 For I:=0 to 18do L[I]:=0;
 For I:=0 to NCode-1do L[CodeOrder[I]]:=Integer(InBits(3));
 If BuildHuff(HuffL,L,19)<>0Then BadData;
 I:=0;
 While I<NLen+NDist do Begin
  Sym:=HuffDecode(HuffL);
  If Sym<16Then Begin L[I]:=Sym;Inc(I);End
   Else
  Begin
   Prev:=0;
   If Sym=16Then Begin
    If I=0Then BadData;
    Prev:=L[I-1];
    Rep:=3+Integer(InBits(2));
   End
    Else
   If Sym=17Then Rep:=3+Integer(InBits(3))
            Else Rep:=11+Integer(InBits(7));
   If I+Rep>NLen+NDist Then BadData;
   While Rep>0do Begin L[I]:=Prev;Inc(I);Dec(Rep);End;
  End;
 End;
 If L[256]=0Then BadData;
 Rep:=BuildHuff(HuffL,L,NLen);
 If(Rep<0)or((Rep>0)and(NLen-HuffL.Cnt[0]<>1))Then BadData;
 { les longueurs de distance sont decalees pour une table propre }
 For I:=0 to NDist-1do L[I]:=L[NLen+I];
 Rep:=BuildHuff(HuffD,L,NDist);
 If(Rep<0)or((Rep>0)and(NDist-HuffD.Cnt[0]<>1))Then BadData;
 InflateCodes;
End;

{ Inflate brut (Zlib=True : entete zlib de 2 octets ignore) ; retourne le nombre d'octets produits }
Function Inflate(Src:PBytes;SrcN:LongInt;Dst:PBytes;Cap:LongInt;Zlib:Boolean):LongInt;
Var
 Last,Typ:Integer;
 Len,NLen,I:LongInt;
Begin
 InP:=Src;InN:=SrcN;InPos:=0;BitBuf:=0;BitCnt:=0;
 OutP:=Dst;OutCap:=Cap;OutPos:=0;
 If Zlib Then Begin
  If SrcN<2Then BadData;
  InPos:=2;
 End;
 Repeat
  Last:=Integer(InBits(1));
  Typ:=Integer(InBits(2));
  If Typ=0Then Begin
   BitBuf:=0;BitCnt:=0;
   If InPos+4>InN Then BadData;
   Len:=LongInt(InP^[InPos])or(LongInt(InP^[InPos+1])shl 8);
   NLen:=LongInt(InP^[InPos+2])or(LongInt(InP^[InPos+3])shl 8);
   If Len<>(NLen xor $FFFF)Then BadData;
   Inc(InPos,4);
   If(InPos+Len>InN)or(OutPos+Len>OutCap)Then BadData;
   For I:=0 to Len-1do Begin
    OutP^[OutPos]:=InP^[InPos];
    Inc(OutPos);Inc(InPos);
   End;
  End
   Else
  If Typ=1Then InflateFixed Else
  If Typ=2Then InflateDynamic
          Else BadData;
 Until Last=1;
 Inflate:=OutPos;
End;

Var
 LzPre:Array[0..4095]of Integer;
 LzSuf:Array[0..4095]of Byte;
 LzLen:Array[0..4095]of Integer;
 LzFst:Array[0..4095]of Byte;

Function LzwDecode(Src:PBytes;SrcN:LongInt;Dst:PBytes;Cap:LongInt):LongInt;
Var
 Pos,Op:LongInt;
 Buf:LongInt;
 Cnt,Bits,Code,Old,Next,I,L:Integer;
 Fc:Byte;
Procedure Emit(C:Integer);
Var
 K,Q:LongInt;
Begin
 L:=LzLen[C];
 If Op+L>Cap Then L:=Cap-Op;
 If L<=0Then Exit;
 { ecriture a rebours depuis la fin de la chaine complete }
 Q:=C;
 K:=LzLen[C];
 While K>0do Begin
  If Op+K-1<Cap Then Dst^[Op+K-1]:=LzSuf[Q];
  Q:=LzPre[Q];
  Dec(K);
 End;
 Op:=Op+L;
End;
Begin
 For I:=0 to 255do Begin LzSuf[I]:=I;LzPre[I]:=-1;LzLen[I]:=1;LzFst[I]:=I;End;
 Pos:=0;Op:=0;Buf:=0;Cnt:=0;Bits:=9;Next:=258;Old:=-1;
 While Op<Cap do Begin
  While Cnt<Bits do Begin
   If Pos>=SrcN Then Begin LzwDecode:=Op;Exit;End;
   Buf:=(Buf shl 8)or Src^[Pos];
   Inc(Pos);Inc(Cnt,8);
  End;
  Code:=Integer((Buf shr(Cnt-Bits))and((1 shl Bits)-1));
  Dec(Cnt,Bits);
  Buf:=Buf and((LongInt(1)shl Cnt)-1);
  If Code=257Then Break;
  If Code=256Then Begin
   Next:=258;Bits:=9;Old:=-1;
  End
   Else
  If Old<0Then Begin
   If Code>=256Then BadData;
   Emit(Code);
   Old:=Code;
  End
   Else
  Begin
   If Code>Next Then BadData;
   If Code<Next Then Fc:=LzFst[Code]
                Else Fc:=LzFst[Old];
   If Next<4096Then Begin
    LzPre[Next]:=Old;LzSuf[Next]:=Fc;LzLen[Next]:=LzLen[Old]+1;LzFst[Next]:=LzFst[Old];
    Inc(Next);
   End;
   If Code>=Next Then BadData;
   Emit(Code);
   Old:=Code;
   If Next>=2047Then Bits:=12 Else
   If Next>=1023Then Bits:=11 Else
   If Next>=511Then Bits:=10;
  End;
 End;
 LzwDecode:=Op;
End;

Function PackBitsDecode(Src:PBytes;SrcN:LongInt;Dst:PBytes;Cap:LongInt):LongInt;
Var
 P,Op,N,I:LongInt;
 C:Integer;
Begin
 P:=0;Op:=0;
 While(P<SrcN)and(Op<Cap)do Begin
  C:=Src^[P];Inc(P);
  If C>127Then C:=C-256;
  If C>=0Then Begin
   N:=C+1;
   For I:=1 to N do If(P<SrcN)and(Op<Cap)Then Begin Dst^[Op]:=Src^[P];Inc(Op);Inc(P);End;
  End
   Else
  If C<>-128Then Begin
   N:=1-C;
   If P>=SrcN Then Break;
   For I:=1 to N do If Op<Cap Then Begin Dst^[Op]:=Src^[P];Inc(Op);End;
   Inc(P);
  End;
 End;
 PackBitsDecode:=Op;
End;

{ ------------------------------------------------------------------ }
{ Formats supplementaires : collecteur de geometries, WKT, WKB, XML  }
{ ------------------------------------------------------------------ }

Var
 GcP,GcL,GcA:TGeom;
 GcPoly:Integer;
 TpP:PPts;
 TpN,TpCap:LongInt;

Procedure TpClear;Begin TpN:=0;End;

Procedure TpAdd(X,Y:Real);
Var
 Q:PPts;
Begin
 If TpP=Nil Then Begin TpCap:=256;TpP:=AllocBlock(TpCap*SizeOf(TPt));End;
 If TpN>=TpCap Then Begin
  Q:=AllocBlock(TpCap*2*SizeOf(TPt));
  Move(TpP^,Q^,TpN*SizeOf(TPt));
  FreeMem(TpP,TpCap*SizeOf(TPt));
  TpP:=Q;TpCap:=TpCap*2;
 End;
 TpP^[TpN].X:=X;TpP^[TpN].Y:=Y;
 Inc(TpN);
End;

Procedure GcInit;Begin
 InitGeom(GcP);GcP.Cls:=1;
 InitGeom(GcL);GcL.Cls:=2;
 InitGeom(GcA);GcA.Cls:=3;
 GcPoly:=0;TpN:=0;
End;

Procedure GcPoint(X,Y:Real);
Var
 P:PPath;
Begin
 P:=NewPath(GcP,1,0);
 P^.Pts^[0].X:=X;P^.Pts^[0].Y:=Y;
End;

Procedure GcLine;
Var
 P:PPath;
Begin
 If TpN>=2Then Begin
  P:=NewPath(GcL,TpN,0);
  Move(TpP^,P^.Pts^,TpN*SizeOf(TPt));
 End;
 TpN:=0;
End;

Procedure GcRing;
Var
 P:PPath;
Begin
 If TpN>=3Then Begin
  If(TpP^[0].X<>TpP^[TpN-1].X)or(TpP^[0].Y<>TpP^[TpN-1].Y)Then TpAdd(TpP^[0].X,TpP^[0].Y);
  If TpN>=4Then Begin
   P:=NewPath(GcA,TpN,GcPoly);
   Move(TpP^,P^.Pts^,TpN*SizeOf(TPt));
  End;
 End;
 TpN:=0;
End;

Function GcResult:PJ;
Var
 R:PJ;
Begin
 R:=Nil;
 If GcA.First<>Nil Then R:=BuildGeom(GcA) Else
 If GcL.First<>Nil Then R:=BuildGeom(GcL) Else
 If GcP.First<>Nil Then R:=BuildGeom(GcP);
 FreeGeom(GcA);FreeGeom(GcL);FreeGeom(GcP);
 GcResult:=R;
End;

{ ---- WKT ---- }

Var
 WB:PBytes;
 WP,WE:LongInt;

Procedure WFail;Begin
 Fail('Error: invalid WKT geometry');
End;

Procedure WSkip;Begin
 While(WP<WE)and(WB^[WP]in[9,10,13,32])do Inc(WP);
End;

Function WPeek:Integer;Begin
 WSkip;
 If WP<WE Then WPeek:=WB^[WP]
          Else WPeek:=-1;
End;

Function WCh(C:Char):Boolean;Begin
 WCh:=False;
 WSkip;
 If(WP<WE)and(WB^[WP]=Ord(C))Then Begin
  Inc(WP);
  WCh:=True;
 End;
End;

Procedure WNeed(C:Char);Begin
 If Not WCh(C)Then WFail;
End;

Function WIsNumStart:Boolean;
Var
 C:Integer;
Begin
 C:=WPeek;
 WIsNumStart:=((C>=48)and(C<=57))or(C=43)or(C=45)or(C=46);
End;

Function WWord:String;
Var
 S:String;
 C:Integer;
Begin
 WSkip;
 S:='';
 While WP<WE do Begin
  C:=WB^[WP];
  If(C>=97)and(C<=122)Then C:=C-32;
  If(C<65)or(C>90)Then Break;
  If Length(S)<40Then S:=S+Chr(C);
  Inc(WP);
 End;
 WWord:=S;
End;

Function WNum:Real;
Var
 S:String;
 V:Real;
 E:Integer;
Begin
 WSkip;
 S:='';
 While(WP<WE)and(Chr(WB^[WP])in['0'..'9','+','-','.','e','E'])do Begin
  If Length(S)<60Then S:=S+Chr(WB^[WP]);
  Inc(WP);
 End;
 Val(S,V,E);
 If(S='')or(E<>0)Then WFail;
 WNum:=V;
End;

Procedure WSkipNums;Begin
 While WIsNumStart do WNum;
End;

Procedure WSeq;
Var
 X,Y:Real;
Begin
 WNeed('(');
 TpClear;
 Repeat
  X:=WNum;Y:=WNum;
  WSkipNums;
  TpAdd(X,Y);
 Until Not WCh(',');
 WNeed(')');
End;

Procedure WPoly;Begin
 WNeed('(');
 Inc(GcPoly);
 Repeat
  WSeq;
  GcRing;
 Until Not WCh(',');
 WNeed(')');
End;

Procedure WGeom;
Var
 T,Z:String;
 X,Y:Real;
 C:Integer;
Begin
 T:=WWord;
 If T=''Then WFail;
 C:=WPeek;
 While((C>=65)and(C<=90))or((C>=97)and(C<=122))do Begin
  Z:=WWord;
  If Z='EMPTY'Then Exit;
  C:=WPeek;
 End;
 If T='POINT'Then Begin
  WNeed('(');
  X:=WNum;Y:=WNum;
  WSkipNums;
  WNeed(')');
  GcPoint(X,Y);
 End Else
 If(T='LINESTRING')or(T='LINEARRING')Then Begin
  WSeq;GcLine;
 End Else
 If T='POLYGON'Then WPoly Else
 If T='MULTIPOINT'Then Begin
  WNeed('(');
  Repeat
   If WCh('(')Then Begin
    X:=WNum;Y:=WNum;WSkipNums;
    WNeed(')');
   End
    Else
   Begin X:=WNum;Y:=WNum;WSkipNums;End;
   GcPoint(X,Y);
  Until Not WCh(',');
  WNeed(')');
 End Else
 If T='MULTILINESTRING'Then Begin
  WNeed('(');
  Repeat
   WSeq;GcLine;
  Until Not WCh(',');
  WNeed(')');
 End Else
 If T='MULTIPOLYGON'Then Begin
  WNeed('(');
  Repeat
   WPoly;
  Until Not WCh(',');
  WNeed(')');
 End Else
 If T='GEOMETRYCOLLECTION'Then Begin
  WNeed('(');
  Repeat
   WGeom;
  Until Not WCh(',');
  WNeed(')');
 End
  Else
 Fail('Error: unsupported WKT geometry type '+T);
End;

Function WktToGeom(B:PBytes;S,E:LongInt):PJ;
Begin
 WktToGeom:=Nil;
 WB:=B;WP:=S;WE:=E;
 WSkip;
 If WP>=WE Then Exit;
 If(WE-WP>5)and(UpCase(Chr(WB^[WP]))='S')and(UpCase(Chr(WB^[WP+1]))='R')and(UpCase(Chr(WB^[WP+2]))='I')Then Begin
  While(WP<WE)and(WB^[WP]<>59)do Inc(WP);
  Inc(WP);
 End;
 GcInit;
 WGeom;
 WktToGeom:=GcResult;
End;

{ ---- WKB ---- }

Var
 KB:PBytes;
 KP,KE:LongInt;

Procedure KFail;Begin
 Fail('Error: invalid WKB geometry');
End;

Function KU32(LE:Boolean):LongInt;Begin
 If KP+4>KE Then KFail;
 If LE Then KU32:=RdLE32(KB,KP)
       Else KU32:=RdBE32(KB,KP);
 Inc(KP,4);
End;

Function KDbl(LE:Boolean):Real;
Var
 D:Double;
 B:Array[0..7]of Byte absolute D;
 I:Integer;
Begin
 If KP+8>KE Then KFail;
 If LE Then Move(KB^[KP],D,8)
       Else For I:=0 to 7do B[7-I]:=KB^[KP+I];
 Inc(KP,8);
 KDbl:=D;
End;

Procedure WkbGeom;
Var
 LE:Boolean;
 T,Hi,Base,Dim,I,N,J,Rings,K:LongInt;
 X,Y,Dum:Real;
Begin
 If KP+5>KE Then KFail;
 LE:=KB^[KP]=1;
 Inc(KP);
 If LE Then Begin T:=RdLE32(KB,KP)and $FFFF;Hi:=KB^[KP+3];End
       Else Begin T:=RdBE32(KB,KP)and $FFFF;Hi:=KB^[KP];End;
 Inc(KP,4);
 Dim:=2;
 If(Hi and $80)<>0Then Inc(Dim);
 If(Hi and $40)<>0Then Inc(Dim);
 If(Hi and $20)<>0Then KU32(LE);
 Base:=T mod 1000;
 K:=T div 1000;
 If(K=1)or(K=2)Then Inc(Dim) Else
 If K=3Then Inc(Dim,2);
 Case Base of
  1:Begin
   X:=KDbl(LE);Y:=KDbl(LE);
   For J:=3 to Dim do Dum:=KDbl(LE);
   If(X=X)and(Y=Y)Then GcPoint(X,Y);
  End;
  2:Begin
   N:=KU32(LE);
   If(N<0)or(KP+N*8*Dim>KE)Then KFail;
   TpClear;
   For I:=1 to N do Begin
    X:=KDbl(LE);Y:=KDbl(LE);
    For J:=3 to Dim do Dum:=KDbl(LE);
    TpAdd(X,Y);
   End;
   GcLine;
  End;
  3:Begin
   Rings:=KU32(LE);
   If(Rings<0)or(Rings>KE-KP)Then KFail;
   Inc(GcPoly);
   For K:=1 to Rings do Begin
    N:=KU32(LE);
    If(N<0)or(KP+N*8*Dim>KE)Then KFail;
    TpClear;
    For I:=1 to N do Begin
     X:=KDbl(LE);Y:=KDbl(LE);
     For J:=3 to Dim do Dum:=KDbl(LE);
     TpAdd(X,Y);
    End;
    GcRing;
   End;
  End;
  4,5,6,7:Begin
   N:=KU32(LE);
   If(N<0)or(N>KE-KP)Then KFail;
   For I:=1 to N do WkbGeom;
  End;
  Else Fail('Error: unsupported WKB geometry type '+IntToStr(Base));
 End;
End;

Function WkbToGeom(B:PBytes;S,E:LongInt):PJ;Begin
 KB:=B;KP:=S;KE:=E;
 GcInit;
 WkbGeom;
 WkbToGeom:=GcResult;
End;

{ ---- XML ---- }

Type
 PX=^TX;
 TX=Record
  Name,Orig:PStr;
  TS,TL:LongInt;
  CData:Boolean;
  AtS,AtL:LongInt;
  First,Last,Next,Par:PX;
 End;

Var
 XB:PBytes;
 XN:LongInt;

Function NewX(Par:PX):PX;
Var
 N:PX;
Begin
 New(N);
 N^.Name:=Nil;N^.Orig:=Nil;N^.TS:=0;N^.TL:=0;N^.CData:=False;N^.AtS:=0;N^.AtL:=0;
 N^.First:=Nil;N^.Last:=Nil;N^.Next:=Nil;N^.Par:=Par;
 If Par<>Nil Then Begin
  If Par^.Last=Nil Then Par^.First:=N
                   Else Par^.Last^.Next:=N;
  Par^.Last:=N;
 End;
 NewX:=N;
End;

Function XAt(B:PBytes;N,I:LongInt;Const S:String):Boolean;
Var
 K:Integer;
Begin
 XAt:=False;
 If I+Length(S)>N Then Exit;
 For K:=1 to Length(S)do If B^[I+K-1]<>Ord(S[K])Then Exit;
 XAt:=True;
End;

Function XParse(B:PBytes;N:LongInt):PX;
Var
 Root,Cur,Nd:PX;
 I,J,S,E,Q:LongInt;
 C:Byte;
 Nm,Loc:String;
 SelfClose:Boolean;
 K:LongInt;
Begin
 XB:=B;XN:=N;
 Root:=NewX(Nil);
 Cur:=Root;
 I:=0;
 If(N>=3)and(B^[0]=$EF)and(B^[1]=$BB)and(B^[2]=$BF)Then I:=3;
 While I<N do Begin
  If B^[I]=60Then Begin
   If I+1>=N Then Break;
   C:=B^[I+1];
   If C=63Then Begin
    J:=I+2;
    While(J+1<N)and Not((B^[J]=63)and(B^[J+1]=62))do Inc(J);
    I:=J+2;
   End Else
   If XAt(B,N,I,'<!--')Then Begin
    J:=I+4;
    While(J+2<N)and Not XAt(B,N,J,'-->')do Inc(J);
    I:=J+3;
   End Else
   If XAt(B,N,I,'<![CDATA[')Then Begin
    S:=I+9;J:=S;
    While(J+2<N)and Not XAt(B,N,J,']]>')do Inc(J);
    If J+2>=N Then Begin J:=N;E:=N;End Else E:=J;
    If Cur^.TL=0Then Begin Cur^.TS:=S;Cur^.TL:=E-S;Cur^.CData:=True;End;
    I:=J+3;
   End Else
   If C=33Then Begin
    J:=I+2;
    Q:=0;
    While J<N do Begin
     If B^[J]=91Then Inc(Q) Else
     If B^[J]=93Then Dec(Q) Else
     If(B^[J]=62)and(Q<=0)Then Break;
     Inc(J);
    End;
    I:=J+1;
   End Else
   If C=47Then Begin
    J:=I+2;
    While(J<N)and(B^[J]<>62)do Inc(J);
    If Cur^.Par<>Nil Then Cur:=Cur^.Par;
    I:=J+1;
   End
    Else
   Begin
    J:=I+1;S:=J;
    While(J<N)and Not(B^[J]in[9,10,13,32,47,62])do Inc(J);
    Nm:='';
    For K:=S to J-1do If Length(Nm)<80Then Nm:=Nm+Chr(B^[K]);
    Loc:=Nm;
    For K:=Length(Nm)downto 1do If Nm[K]=':'Then Begin Loc:=Copy(Nm,K+1,80);Break;End;
    Nd:=NewX(Cur);
    Nd^.Name:=MkStr(StrUpper(Loc));
    Nd^.Orig:=MkStr(Loc);
    Nd^.AtS:=J;
    Q:=0;
    While J<N do Begin
     If Q<>0Then Begin
      If B^[J]=Q Then Q:=0;
     End
      Else
     If(B^[J]=34)or(B^[J]=39)Then Q:=B^[J] Else
     If B^[J]=62Then Break;
     Inc(J);
    End;
    Nd^.AtL:=J-Nd^.AtS;
    SelfClose:=(J>I+1)and(B^[J-1]=47);
    If Not SelfClose Then Cur:=Nd;
    I:=J+1;
   End;
  End
   Else
  Begin
   S:=I;
   While(I<N)and(B^[I]<>60)do Inc(I);
   If Cur^.TL=0Then Begin
    E:=I;
    While(S<E)and(B^[S]in[9,10,13,32])do Inc(S);
    While(E>S)and(B^[E-1]in[9,10,13,32])do Dec(E);
    If E>S Then Begin Cur^.TS:=S;Cur^.TL:=E-S;End;
   End;
  End;
 End;
 XParse:=Root;
End;

Function DecodeEnt(S:String):String;
Var
 R,Ent:String;
 I,J,Code:Integer;
 V:LongInt;
 Done:Boolean;
Begin
 R:='';
 I:=1;
 While I<=Length(S)do Begin
  Done:=False;
  If S[I]='&'Then Begin
   J:=I+1;
   While(J<=Length(S))and(J-I<=9)and(S[J]<>';')do Inc(J);
   If(J<=Length(S))and(S[J]=';')Then Begin
    Ent:=Copy(S,I+1,J-I-1);
    If Ent='amp'Then Begin R:=R+'&';Done:=True;End Else
    If Ent='lt'Then Begin R:=R+'<';Done:=True;End Else
    If Ent='gt'Then Begin R:=R+'>';Done:=True;End Else
    If Ent='quot'Then Begin R:=R+'"';Done:=True;End Else
    If Ent='apos'Then Begin R:=R+'''';Done:=True;End Else
    If(Length(Ent)>1)and(Ent[1]='#')Then Begin
     If(Ent[2]='x')or(Ent[2]='X')Then Val('$'+Copy(Ent,3,10),V,Code)
                                 Else Val(Copy(Ent,2,10),V,Code);
     If(Code=0)and(V>0)Then Begin
      If V<128Then R:=R+Chr(V) Else
      If V<2048Then R:=R+Chr(192+(V shr 6))+Chr(128+(V and 63)) Else
      If V<65536Then R:=R+Chr(224+(V shr 12))+Chr(128+((V shr 6)and 63))+Chr(128+(V and 63))
      Else R:=R+Chr(240+(V shr 18))+Chr(128+((V shr 12)and 63))+Chr(128+((V shr 6)and 63))+Chr(128+(V and 63));
      Done:=True;
     End;
    End;
    If Done Then I:=J+1;
   End;
  End;
  If Not Done Then Begin
   R:=R+S[I];
   Inc(I);
  End;
 End;
 DecodeEnt:=R;
End;

Function XText(N:PX):String;
Var
 S:String;
 I,E:LongInt;
Begin
 XText:='';
 If(N=Nil)or(N^.TL=0)Then Exit;
 S:='';
 I:=N^.TS;E:=N^.TS+N^.TL;
 While(I<E)and(Length(S)<250)do Begin
  S:=S+Chr(XB^[I]);
  Inc(I);
 End;
 If N^.CData Then XText:=S
             Else XText:=DecodeEnt(S);
End;

Function XAttr(N:PX;Name:String):String;
Var
 I,E,S,S2:LongInt;
 Q:Byte;
 Nm,V:String;
 K:LongInt;
Begin
 XAttr:='';
 If N=Nil Then Exit;
 I:=N^.AtS;E:=N^.AtS+N^.AtL;
 While I<E do Begin
  While(I<E)and(XB^[I]in[9,10,13,32,47])do Inc(I);
  S:=I;
  While(I<E)and Not(XB^[I]in[61,9,10,13,32])do Inc(I);
  Nm:='';
  For K:=S to I-1do If Length(Nm)<60Then Nm:=Nm+Chr(XB^[K]);
  While(I<E)and(XB^[I]in[9,10,13,32])do Inc(I);
  V:='';
  If(I<E)and(XB^[I]=61)Then Begin
   Inc(I);
   While(I<E)and(XB^[I]in[9,10,13,32])do Inc(I);
   If(I<E)and(XB^[I]in[34,39])Then Begin
    Q:=XB^[I];Inc(I);S2:=I;
    While(I<E)and(XB^[I]<>Q)do Inc(I);
    For K:=S2 to I-1do If Length(V)<250Then V:=V+Chr(XB^[K]);
    Inc(I);
   End;
  End;
  If(Nm=Name)or((Length(Nm)>Length(Name))and(Copy(Nm,Length(Nm)-Length(Name),Length(Name)+1)=':'+Name))Then Begin
   XAttr:=DecodeEnt(V);
   Exit;
  End;
 End;
End;

Function XKid(N:PX;Const Nm:String):PX;
Var
 C:PX;
Begin
 XKid:=Nil;
 If N=Nil Then Exit;
 C:=N^.First;
 While C<>Nil do Begin
  If C^.Name^=Nm Then Begin XKid:=C;Exit;End;
  C:=C^.Next;
 End;
End;

Function XFind(N:PX;Const Nm:String):PX;
Var
 C,R:PX;
Begin
 XFind:=Nil;
 If N=Nil Then Exit;
 C:=N^.First;
 While C<>Nil do Begin
  If C^.Name^=Nm Then Begin XFind:=C;Exit;End;
  R:=XFind(C,Nm);
  If R<>Nil Then Begin XFind:=R;Exit;End;
  C:=C^.Next;
 End;
End;

Function XNumAt(Var I:LongInt;E:LongInt;Var V:Real):Boolean;
Var
 S:String;
 Err:Integer;
Begin
 S:='';
 While(I<E)and(Chr(XB^[I])in['0'..'9','+','-','.','e','E'])do Begin
  If Length(S)<60Then S:=S+Chr(XB^[I]);
  Inc(I);
 End;
 Val(S,V,Err);
 XNumAt:=(S<>'')and(Err=0);
End;

{ Coordonnees : Tuple=True : "x,y[,z] x,y[,z]" ; sinon nombres separes par des blancs, groupes par Dim }
Procedure XCoords(S,E:LongInt;Tuple:Boolean;Dim:Integer;Swap:Boolean);
Var
 I,K:LongInt;
 V,X,Y:Real;
 N:Integer;
 Have:Boolean;
Begin
 I:=S;
 If Tuple Then Begin
  While I<E do Begin
   While(I<E)and(XB^[I]in[9,10,13,32])do Inc(I);
   If I>=E Then Break;
   N:=0;X:=0;Y:=0;
   Repeat
    Have:=XNumAt(I,E,V);
    If Have Then Begin
     If N=0Then X:=V Else
     If N=1Then Y:=V;
     Inc(N);
    End
     Else
    If(I<E)and Not(XB^[I]in[9,10,13,32,44])Then Inc(I);
    If(I<E)and(XB^[I]=44)Then Begin Inc(I);Have:=True;End
                         Else Have:=False;
   Until Not Have;
   If N>=2Then Begin
    If Swap Then TpAdd(Y,X)
            Else TpAdd(X,Y);
   End;
  End;
 End
  Else
 Begin
  K:=0;X:=0;Y:=0;
  While I<E do Begin
   While(I<E)and(XB^[I]in[9,10,13,32,44])do Inc(I);
   If I>=E Then Break;
   If XNumAt(I,E,V)Then Begin
    If K mod Dim=0Then X:=V Else
    If K mod Dim=1Then Begin
     Y:=V;
     If Swap Then TpAdd(Y,X)
             Else TpAdd(X,Y);
    End;
    Inc(K);
   End
    Else
   Inc(I);
  End;
 End;
End;

Var
 XSwap:Boolean;

{ Remplit Tp avec les coordonnees contenues dans N (coordinates, posList ou suite de pos) }
Procedure GmlRing(N:PX);
Var
 C:PX;
 Dim,Code:Integer;
Begin
 TpClear;
 C:=XFind(N,'COORDINATES');
 If C<>Nil Then Begin
  If C^.TL>0Then XCoords(C^.TS,C^.TS+C^.TL,True,2,XSwap);
  Exit;
 End;
 C:=XFind(N,'POSLIST');
 If C<>Nil Then Begin
  Dim:=2;
  Val(XAttr(C,'srsDimension'),Dim,Code);
  If(Code<>0)or(Dim<2)Then Dim:=2;
  If C^.TL>0Then XCoords(C^.TS,C^.TS+C^.TL,False,Dim,XSwap);
  Exit;
 End;
 If XKid(N,'POS')=Nil Then Begin
  C:=XFind(N,'POS');
  If C<>Nil Then N:=C^.Par;
 End;
 C:=N^.First;
 While C<>Nil do Begin
  If(C^.Name^='POS')and(C^.TL>0)Then XCoords(C^.TS,C^.TS+C^.TL,False,2,XSwap);
  C:=C^.Next;
 End;
End;

Procedure GmlGeom(N:PX);
Var
 C:PX;
 Nm,S:String;
 Cd:LongInt;
Begin
 Nm:=N^.Name^;
 S:=XAttr(N,'srsName');
 If S<>''Then Begin
  XSwap:=False;
  If(Pos('urn:ogc:def:crs',S)>0)and ParseCrsName(S,Cd)Then XSwap:=CrsIsGeographic(Cd);
 End;
 If Nm='POINT'Then Begin
  GmlRing(N);
  If TpN>0Then GcPoint(TpP^[0].X,TpP^[0].Y);
  TpN:=0;
 End Else
 If(Nm='LINESTRING')or(Nm='LINEARRING')or(Nm='CURVE')Then Begin
  GmlRing(N);
  GcLine;
 End Else
 If Nm='POLYGON'Then Begin
  Inc(GcPoly);
  C:=N^.First;
  While C<>Nil do Begin
   If(C^.Name^='OUTERBOUNDARYIS')or(C^.Name^='EXTERIOR')Then Begin GmlRing(C);GcRing;End;
   C:=C^.Next;
  End;
  C:=N^.First;
  While C<>Nil do Begin
   If(C^.Name^='INNERBOUNDARYIS')or(C^.Name^='INTERIOR')Then Begin GmlRing(C);GcRing;End;
   C:=C^.Next;
  End;
 End
  Else
 Begin
  C:=N^.First;
  While C<>Nil do Begin
   GmlGeom(C);
   C:=C^.Next;
  End;
 End;
End;

Function IsGeomName(Const Nm:String):Boolean;Begin
 IsGeomName:=(Nm='POINT')or(Nm='LINESTRING')or(Nm='LINEARRING')or(Nm='POLYGON')or(Nm='MULTIPOINT')or
  (Nm='MULTILINESTRING')or(Nm='MULTIPOLYGON')or(Nm='MULTICURVE')or(Nm='MULTISURFACE')or
  (Nm='MULTIGEOMETRY')or(Nm='GEOMETRYCOLLECTION')or(Nm='CURVE');
End;

{ Valeur numerique "simple" : chiffres, signe, point, exposant, sans zero initial inutile }
Function IsPlainNumber(S:String):Boolean;
Var
 I:Integer;
 V:Real;
 E:Integer;
Begin
 IsPlainNumber:=False;
 If S=''Then Exit;
 For I:=1 to Length(S)do If Not(S[I]in['0'..'9','+','-','.','e','E'])Then Exit;
 If(Length(S)>1)and(S[1]='0')and(S[2]in['0'..'9'])Then Exit;
 If(Length(S)>2)and(S[1]='-')and(S[2]='0')and(S[3]in['0'..'9'])Then Exit;
 Val(S,V,E);
 IsPlainNumber:=E=0;
End;

Function PropFromText(S:String):PJ;
Var
 V:Real;
 E:Integer;
Begin
 If IsPlainNumber(S)Then Begin
  Val(S,V,E);
  PropFromText:=JNum(V);
 End
  Else
 PropFromText:=JTextEsc(S);
End;

Function NewCollection:PJ;
Var
 Col:PJ;
Begin
 Col:=NewJ(5);
 JAddKV(Col,'type',JText('FeatureCollection'));
 JAddKV(Col,'features',NewJ(4));
 NewCollection:=Col;
End;

Procedure AddFeature(Col,Props,Geom:PJ);
Var
 F:PJ;
Begin
 F:=NewJ(5);
 JAddKV(F,'type',JText('Feature'));
 JAddKV(F,'properties',Props);
 If Geom=Nil Then Geom:=NewJ(0);
 JAddKV(F,'geometry',Geom);
 JAdd(JFind(Col,'features'),F);
End;

{ ---- GML ---- }

Procedure GmlFeature(Col:PJ;F:PX);
Var
 Props,Geom:PJ;
 C,G:PX;
 V:String;
 Have:Boolean;
Begin
 Props:=NewJ(5);
 Geom:=Nil;
 Have:=False;
 XSwap:=False;
 C:=F^.First;
 While C<>Nil do Begin
  G:=C^.First;
  If(G<>Nil)and IsGeomName(G^.Name^)Then Begin
   If Not Have Then Begin
    GcInit;
    GmlGeom(G);
    Geom:=GcResult;
    Have:=True;
   End;
  End
   Else
  If(G=Nil)and(C^.Name^<>'BOUNDEDBY')Then Begin
   V:=XText(C);
   If(C^.TL>0)Then JAddKV(Props,C^.Orig^,PropFromText(V))
              Else JAddKV(Props,C^.Orig^,NewJ(0));
  End;
  C:=C^.Next;
 End;
 AddFeature(Col,Props,Geom);
End;

Function XFirstAttr(N:PX;Const Nm:String):String;
Var
 C:PX;
 S:String;
Begin
 XFirstAttr:='';
 C:=N^.First;
 While C<>Nil do Begin
  S:=XAttr(C,Nm);
  If S<>''Then Begin XFirstAttr:=S;Exit;End;
  S:=XFirstAttr(C,Nm);
  If S<>''Then Begin XFirstAttr:=S;Exit;End;
  C:=C^.Next;
 End;
End;

Function ReadGml(B:PBytes;N:LongInt):PJ;
Var
 Root,Rt,C,F:PX;
 Col:PJ;
 Sn:String;
 Cd:LongInt;
Begin
 Col:=NewCollection;
 Root:=XParse(B,N);
 Rt:=Root^.First;
 If Rt=Nil Then Fail('Error: invalid GML file');
 C:=Rt^.First;
 While C<>Nil do Begin
  If(C^.Name^='FEATUREMEMBER')or(C^.Name^='MEMBER')Then Begin
   If C^.First<>Nil Then GmlFeature(Col,C^.First);
  End Else
  If C^.Name^='FEATUREMEMBERS'Then Begin
   F:=C^.First;
   While F<>Nil do Begin GmlFeature(Col,F);F:=F^.Next;End;
  End;
  C:=C^.Next;
 End;
 Sn:=XFirstAttr(Rt,'srsName');
 If(Sn<>'')and ParseCrsName(Sn,Cd)and(Cd<>4326)Then SetLayerCrs(Col,Cd);
 ReadGml:=Col;
End;

{ ---- KML ---- }

Procedure KmlPlacemark(Col:PJ;P:PX);
Var
 Props,Geom:PJ;
 C,E,D:PX;
 V,Nm:String;
Begin
 Props:=NewJ(5);
 C:=XKid(P,'NAME');
 If C<>Nil Then JAddKV(Props,'Name',JTextEsc(XText(C)));
 C:=XKid(P,'DESCRIPTION');
 If C<>Nil Then JAddKV(Props,'description',JTextEsc(XText(C)));
 E:=XKid(P,'EXTENDEDDATA');
 If E<>Nil Then Begin
  D:=E^.First;
  While D<>Nil do Begin
   If D^.Name^='DATA'Then Begin
    Nm:=XAttr(D,'name');
    V:=XText(XKid(D,'VALUE'));
    If Nm<>''Then JAddKV(Props,Nm,PropFromText(V));
   End Else
   If D^.Name^='SCHEMADATA'Then Begin
    C:=D^.First;
    While C<>Nil do Begin
     If C^.Name^='SIMPLEDATA'Then Begin
      Nm:=XAttr(C,'name');
      If Nm<>''Then JAddKV(Props,Nm,PropFromText(XText(C)));
     End;
     C:=C^.Next;
    End;
   End;
   D:=D^.Next;
  End;
 End;
 GcInit;
 XSwap:=False;
 C:=P^.First;
 While C<>Nil do Begin
  If IsGeomName(C^.Name^)Then GmlGeom(C);
  C:=C^.Next;
 End;
 Geom:=GcResult;
 AddFeature(Col,Props,Geom);
End;

Procedure KmlWalk(Col:PJ;N:PX);
Var
 C:PX;
Begin
 C:=N^.First;
 While C<>Nil do Begin
  If C^.Name^='PLACEMARK'Then KmlPlacemark(Col,C)
                         Else KmlWalk(Col,C);
  C:=C^.Next;
 End;
End;

Function ReadKml(B:PBytes;N:LongInt):PJ;
Var
 Col:PJ;
 Root:PX;
Begin
 Col:=NewCollection;
 Root:=XParse(B,N);
 If Root^.First=Nil Then Fail('Error: invalid KML file');
 KmlWalk(Col,Root);
 ReadKml:=Col;
End;

{ ---- ZIP (KMZ, QGZ) ---- }

Var
 CrcTab:Array[0..255]of LongInt;
 CrcReady:Boolean;

Function Crc32Of(B:PBytes;N:LongInt):LongInt;
Var
 I,K:Integer;
 C:LongInt;
 J:LongInt;
Begin
 If Not CrcReady Then Begin
  For I:=0 to 255do Begin
   C:=I;
   For K:=1 to 8do
    If(C and 1)<>0Then C:=((C shr 1)and $7FFFFFFF)xor -306674912
                  Else C:=(C shr 1)and $7FFFFFFF;
   CrcTab[I]:=C;
  End;
  CrcReady:=True;
 End;
 C:=-1;
 For J:=0 to N-1do
  C:=CrcTab[(C xor B^[J])and 255]xor((C shr 8)and $FFFFFF);
 Crc32Of:=C xor -1;
End;

{ Extrait la premiere entree dont le nom se termine par Ext (en majuscules) ; Nil si absente }
Function ZipExtract(B:PBytes;N:LongInt;Ext:String;Var Size:LongInt):PBytes;
Var
 P,Cnt,I,Meth,CSize,USize,NLen,XLen,CLen,LOff,Data,E:LongInt;
 Name:String;
 K:LongInt;
 Dst:PBytes;
 Best:LongInt;
Begin
 ZipExtract:=Nil;
 Size:=0;
 P:=N-22;
 While(P>=0)and Not((B^[P]=$50)and(B^[P+1]=$4B)and(B^[P+2]=5)and(B^[P+3]=6))do Dec(P);
 If P<0Then Exit;
 Cnt:=RdLE16(B,P+10);
 E:=RdLE32(B,P+16);
 Best:=-1;
 For I:=1 to Cnt do Begin
  If(E<0)or(E+46>N)or(RdLE32(B,E)<>$02014B50)Then Break;
  NLen:=RdLE16(B,E+28);XLen:=RdLE16(B,E+30);CLen:=RdLE16(B,E+32);
  Name:='';
  For K:=0 to NLen-1do If Length(Name)<250Then Name:=Name+Chr(B^[E+46+K]);
  Name:=StrUpper(Name);
  If(Length(Name)>=Length(Ext))and(Copy(Name,Length(Name)-Length(Ext)+1,Length(Ext))=Ext)Then Begin
   If Best<0Then Best:=E;
   If(Name='DOC.KML')or(Name='DOC.QGS')Then Best:=E;
  End;
  E:=E+46+NLen+XLen+CLen;
 End;
 If Best<0Then Exit;
 E:=Best;
 Meth:=RdLE16(B,E+10);CSize:=RdLE32(B,E+20);USize:=RdLE32(B,E+24);LOff:=RdLE32(B,E+42);
 If(LOff<0)or(LOff+30>N)Then Exit;
 NLen:=RdLE16(B,LOff+26);XLen:=RdLE16(B,LOff+28);
 Data:=LOff+30+NLen+XLen;
 If(Data<0)or(CSize<0)or(USize<0)or(Data+CSize>N)Then Exit;
 Dst:=AllocBlock(USize+16);
 FillChar(Dst^,USize+16,0);
 If Meth=0Then Move(B^[Data],Dst^,USize) Else
 If Meth=8Then Inflate(@B^[Data],CSize,Dst,USize,False)
          Else Fail('Error: unsupported zip compression method');
 Size:=USize;
 ZipExtract:=Dst;
End;

{ Archive ZIP a une seule entree (stockee) }
Procedure ZipSingle(FileName,EntryName:String;Var Data:TBuf);
Var
 Z:TBuf;
 Crc:LongInt;
 I:Integer;
 CdOff,CdLen:LongInt;
Begin
 BufInit(Z);
 Crc:=Crc32Of(Data.P,Data.N);
 BufLE32(Z,$04034B50);BufLE16(Z,20);BufLE16(Z,0);BufLE16(Z,0);BufLE16(Z,0);BufLE16(Z,$21);
 BufLE32(Z,Crc);BufLE32(Z,Data.N);BufLE32(Z,Data.N);
 BufLE16(Z,Length(EntryName));BufLE16(Z,0);
 BufText(Z,EntryName);
 BufGrow(Z,Data.N);
 Move(Data.P^,Z.P^[Z.N],Data.N);
 Inc(Z.N,Data.N);
 CdOff:=Z.N;
 BufLE32(Z,$02014B50);BufLE16(Z,20);BufLE16(Z,20);BufLE16(Z,0);BufLE16(Z,0);BufLE16(Z,0);BufLE16(Z,$21);
 BufLE32(Z,Crc);BufLE32(Z,Data.N);BufLE32(Z,Data.N);
 BufLE16(Z,Length(EntryName));BufLE16(Z,0);BufLE16(Z,0);BufLE16(Z,0);BufLE16(Z,0);
 BufLE32(Z,0);BufLE32(Z,0);
 BufText(Z,EntryName);
 CdLen:=Z.N-CdOff;
 BufLE32(Z,$06054B50);BufLE16(Z,0);BufLE16(Z,0);BufLE16(Z,1);BufLE16(Z,1);
 BufLE32(Z,CdLen);BufLE32(Z,CdOff);BufLE16(Z,0);
 BufSave(FileName,Z);
End;

{ ---- CSV ---- }

Var
 CsvDelim:Integer;
 CsvXName,CsvYName,CsvWName:String;
 CsvCrs:LongInt;

Function CsvField(B:PBytes;N:LongInt;Var P:LongInt;Var S,E:LongInt;Var Quoted,EndRec:Boolean;D:Integer):Boolean;Begin
 CsvField:=False;
 If P>=N Then Exit;
 CsvField:=True;
 Quoted:=False;
 If B^[P]=34Then Begin
  Quoted:=True;
  Inc(P);S:=P;
  Repeat
   While(P<N)and(B^[P]<>34)do Inc(P);
   If(P+1<N)and(B^[P+1]=34)Then Inc(P,2)
                           Else Break;
  Until False;
  E:=P;
  If P<N Then Inc(P);
  While(P<N)and(B^[P]<>D)and(B^[P]<>10)and(B^[P]<>13)do Inc(P);
 End
  Else
 Begin
  S:=P;
  While(P<N)and(B^[P]<>D)and(B^[P]<>10)and(B^[P]<>13)do Inc(P);
  E:=P;
 End;
 EndRec:=True;
 If P>=N Then Exit;
 If B^[P]=D Then Begin
  Inc(P);
  EndRec:=False;
 End
  Else
 If B^[P]=13Then Begin
  Inc(P);
  If(P<N)and(B^[P]=10)Then Inc(P);
 End
  Else
 Inc(P);
End;

Function CsvStr(B:PBytes;S,E:LongInt;Quoted:Boolean):String;
Var
 R:String;
 I:LongInt;
Begin
 R:='';
 I:=S;
 While(I<E)and(Length(R)<255)do Begin
  If Quoted and(B^[I]=34)and(I+1<E)and(B^[I+1]=34)Then Inc(I);
  R:=R+Chr(B^[I]);
  Inc(I);
 End;
 If Not Quoted Then Begin
  While(R<>'')and(R[Length(R)]in[' ',#9])do Delete(R,Length(R),1);
  While(R<>'')and(R[1]in[' ',#9])do Delete(R,1,1);
 End;
 CsvStr:=R;
End;

Function CsvInList(Const S:String;Const L:String):Boolean;Begin
 CsvInList:=Pos(','+LowerStr(S)+',',','+L+',')>0;
End;

Function ReadCsv(B:PBytes;N:LongInt):PJ;
Const
 MaxCol=512;
Var
 Col,Props,Geom:PJ;
 Start,P,I,Ncol,Pass,Rec:LongInt;
 S,E:LongInt;
 Q,EndRec,InQ:Boolean;
 Names:Array[1..MaxCol]of String[60];
 RS,RE:Array[1..MaxCol]of LongInt;
 RQ:Array[1..MaxCol]of Boolean;
 IsNum,AnyVal:Array[1..MaxCol]of Boolean;
 Xc,Yc,Wc,K,Cnt,Delim,C0,C1,C2,C3:LongInt;
 Best:LongInt;
 Txt:String;
 X,Y:Real;
 EX,EY:Integer;
Begin
 Start:=0;
 If(N>=3)and(B^[0]=$EF)and(B^[1]=$BB)and(B^[2]=$BF)Then Start:=3;
 { separateur : celui qui apparait le plus dans la premiere ligne }
 Delim:=CsvDelim;
 If Delim=0Then Begin
  C0:=0;C1:=0;C2:=0;C3:=0;InQ:=False;
  I:=Start;
  While(I<N)and Not((B^[I]=10)and Not InQ)do Begin
   If B^[I]=34Then InQ:=Not InQ Else
   If Not InQ Then Begin
    If B^[I]=44Then Inc(C0) Else
    If B^[I]=59Then Inc(C1) Else
    If B^[I]=9Then Inc(C2) Else
    If B^[I]=124Then Inc(C3);
   End;
   Inc(I);
  End;
  Delim:=44;Best:=C0;
  If C1>Best Then Begin Delim:=59;Best:=C1;End;
  If C2>Best Then Begin Delim:=9;Best:=C2;End;
  If C3>Best Then Begin Delim:=124;Best:=C3;End;
 End;
 { en-tete }
 P:=Start;
 Ncol:=0;
 Repeat
  If Not CsvField(B,N,P,S,E,Q,EndRec,Delim)Then Fail('Error: empty CSV file');
  If Ncol>=MaxCol Then Fail('Error: too many columns in CSV file');
  Inc(Ncol);
  Names[Ncol]:=CsvStr(B,S,E,Q);
  If Names[Ncol]=''Then Names[Ncol]:='field_'+IntToStr(Ncol);
 Until EndRec;
 Xc:=0;Yc:=0;Wc:=0;
 For K:=1 to Ncol do Begin
  If CsvWName<>''Then Begin
   If LowerStr(Names[K])=LowerStr(CsvWName)Then Wc:=K;
  End
   Else
  If(Wc=0)and CsvInList(Names[K],'wkt,geom,geometry,the_geom,wkt_geometry,shape,wkb_geometry')Then Wc:=K;
  If CsvXName<>''Then Begin
   If LowerStr(Names[K])=LowerStr(CsvXName)Then Xc:=K;
  End
   Else
  If(Xc=0)and CsvInList(Names[K],'x,lon,lng,long,longitude,xcoord,x_coord,easting,point_x,xcoordinate')Then Xc:=K;
  If CsvYName<>''Then Begin
   If LowerStr(Names[K])=LowerStr(CsvYName)Then Yc:=K;
  End
   Else
  If(Yc=0)and CsvInList(Names[K],'y,lat,latitude,ycoord,y_coord,northing,point_y,ycoordinate')Then Yc:=K;
 End;
 If(Wc=0)and((Xc=0)or(Yc=0))Then Begin Xc:=0;Yc:=0;End;
 If Wc>0Then Begin Xc:=0;Yc:=0;End;
 For K:=1 to Ncol do Begin IsNum[K]:=True;AnyVal[K]:=False;End;
 { passe 1 : types }
 P:=Start;
 Repeat
  Rec:=P;
  If Not CsvField(B,N,P,S,E,Q,EndRec,Delim)Then Break;
 Until EndRec;
 While P<N do Begin
  K:=0;
  Repeat
   If Not CsvField(B,N,P,S,E,Q,EndRec,Delim)Then Break;
   Inc(K);
   If K<=Ncol Then Begin
    Txt:=CsvStr(B,S,E,Q);
    If Txt<>''Then Begin
     AnyVal[K]:=True;
     If Not IsPlainNumber(Txt)Then IsNum[K]:=False;
    End;
   End;
  Until EndRec;
 End;
 { passe 2 : entites }
 Col:=NewCollection;
 If CsvCrs>0Then SetLayerCrs(Col,CsvCrs);
 P:=Start;
 Repeat
  If Not CsvField(B,N,P,S,E,Q,EndRec,Delim)Then Break;
 Until EndRec;
 While P<N do Begin
  For K:=1 to Ncol do Begin RS[K]:=0;RE[K]:=0;RQ[K]:=False;End;
  K:=0;
  Repeat
   If Not CsvField(B,N,P,S,E,Q,EndRec,Delim)Then Break;
   Inc(K);
   If K<=Ncol Then Begin RS[K]:=S;RE[K]:=E;RQ[K]:=Q;End;
  Until EndRec;
  If(K=1)and(RE[1]=RS[1])Then Continue;
  Props:=NewJ(5);
  Geom:=Nil;
  For K:=1 to Ncol do Begin
   If K=Wc Then Begin
    If RE[K]>RS[K]Then Geom:=WktToGeom(B,RS[K],RE[K]);
   End
    Else
   Begin
    Txt:=CsvStr(B,RS[K],RE[K],RQ[K]);
    If Txt=''Then JAddKV(Props,Names[K],NewJ(0)) Else
    If IsNum[K]and AnyVal[K]Then JAddKV(Props,Names[K],PropFromText(Txt))
                            Else JAddKV(Props,Names[K],JTextEsc(Txt));
   End;
  End;
  If(Xc>0)and(Yc>0)Then Begin
   Val(CsvStr(B,RS[Xc],RE[Xc],RQ[Xc]),X,EX);
   Val(CsvStr(B,RS[Yc],RE[Yc],RQ[Yc]),Y,EY);
   If(EX=0)and(EY=0)Then Begin
    GcInit;
    GcPoint(X,Y);
    Geom:=GcResult;
   End;
  End;
  AddFeature(Col,Props,Geom);
 End;
 ReadCsv:=Col;
End;

{ ---- ecriture CSV / GML / KML ---- }

Procedure BufLn(Var B:TBuf;S:String);Begin
 BufText(B,S);
 BufByte(B,10);
End;

Function XmlEsc(S:String):String;
Var
 I:Integer;
 R:String;
Begin
 R:='';
 For I:=1 to Length(S)do Begin
  If Length(R)>=240Then Break;
  Case S[I]of
   '&':R:=R+'&amp;';
   '<':R:=R+'&lt;';
   '>':R:=R+'&gt;';
   '"':R:=R+'&quot;';
   #0..#8,#11,#12,#14..#31:;
   Else R:=R+S[I];
  End;
 End;
 XmlEsc:=R;
End;

Function XmlName(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do
  If Not(S[I]in['A'..'Z','a'..'z','0'..'9','_','-','.'])Then S[I]:='_';
 If(S='')or Not(S[1]in['A'..'Z','a'..'z','_'])Then S:='_'+S;
 XmlName:=S;
End;

Function PropValText(P:PJ):String;Begin
 PropValText:='';
 If P=Nil Then Exit;
 Case P^.Kind of
  1,2:PropValText:=JVal(P);
  3:PropValText:=Unesc(JVal(P));
 End;
End;

Function BaseNoExt(S:String):String;
Var
 I,E:Integer;
Begin
 E:=Length(S);
 For I:=Length(S)downto 1do Begin
  If S[I]in['/',#92]Then Begin S:=Copy(S,I+1,255);Break;End;
 End;
 For I:=Length(S)downto 1do If S[I]='.'Then Begin S:=Copy(S,1,I-1);Break;End;
 BaseNoExt:=S;
End;

Procedure BufWkt(Var B:TBuf;Var G:TGeom);
Var
 P:PPath;
 I:LongInt;
 First:Boolean;
 Prev:Integer;
Begin
 If G.First=Nil Then Exit;
 Case G.Cls of
  1:Begin
   If G.Count=1Then BufText(B,'POINT (')Else BufText(B,'MULTIPOINT (');
   P:=G.First;First:=True;
   While P<>Nil do Begin
    If Not First Then BufText(B,', ');
    First:=False;
    BufText(B,NumStr(P^.Pts^[0].X)+' '+NumStr(P^.Pts^[0].Y));
    P:=P^.Next;
   End;
   BufText(B,')');
  End;
  2:Begin
   If G.Count=1Then BufText(B,'LINESTRING ')Else BufText(B,'MULTILINESTRING (');
   P:=G.First;First:=True;
   While P<>Nil do Begin
    If Not First Then BufText(B,', ');
    First:=False;
    BufText(B,'(');
    For I:=0 to P^.N-1do Begin
     If I>0Then BufText(B,', ');
     BufText(B,NumStr(P^.Pts^[I].X)+' '+NumStr(P^.Pts^[I].Y));
    End;
    BufText(B,')');
    P:=P^.Next;
   End;
   If G.Count>1Then BufText(B,')');
  End;
  3:Begin
   If G.NPoly=1Then BufText(B,'POLYGON (')Else BufText(B,'MULTIPOLYGON ((');
   Prev:=-1;
   P:=G.First;
   While P<>Nil do Begin
    If P^.Poly<>Prev Then Begin
     If Prev>=0Then BufText(B,'), (');
     BufText(B,'(');
    End
     Else
    BufText(B,', (');
    For I:=0 to P^.N-1do Begin
     If I>0Then BufText(B,', ');
     BufText(B,NumStr(P^.Pts^[I].X)+' '+NumStr(P^.Pts^[I].Y));
    End;
    BufText(B,')');
    Prev:=P^.Poly;
    P:=P^.Next;
   End;
   If G.NPoly=1Then BufText(B,')')Else BufText(B,'))');
  End;
 End;
End;

Function CsvQuote(S:String):String;
Var
 I:Integer;
 R:String;
 Need:Boolean;
Begin
 Need:=(S<>'')and((S[1]=' ')or(S[Length(S)]=' '));
 For I:=1 to Length(S)do If S[I]in[',',';','"',#10,#13,#9]Then Need:=True;
 If Not Need Then Begin CsvQuote:=S;Exit;End;
 R:='"';
 For I:=1 to Length(S)do Begin
  If S[I]='"'Then R:=R+'""' Else R:=R+S[I];
 End;
 CsvQuote:=R+'"';
End;

Procedure SaveCsv(FileName:String;Root:PJ);
Const
 MaxKeys=512;
Var
 B:TBuf;
 Keys:Array[1..MaxKeys]of String[60];
 NK,I,J:Integer;
 Feats,F,Pr,C,V:PJ;
 G:TGeom;
 Found:Boolean;
Begin
 Feats:=JFind(Root,'features');
 NK:=0;
 F:=Feats^.First;
 While F<>Nil do Begin
  Pr:=JFind(F,'properties');
  If(Pr<>Nil)and(Pr^.Kind=5)Then Begin
   C:=Pr^.First;
   While C<>Nil do Begin
    Found:=False;
    For I:=1 to NK do If Keys[I]=JKey(C)Then Found:=True;
    If Not Found Then Begin
     If NK>=MaxKeys Then Fail('Error: too many fields for CSV output');
     Inc(NK);Keys[NK]:=JKey(C);
    End;
    C:=C^.Next;
   End;
  End;
  F:=F^.Next;
 End;
 BufInit(B);
 BufText(B,'WKT');
 For I:=1 to NK do BufText(B,','+CsvQuote(Keys[I]));
 BufByte(B,10);
 F:=Feats^.First;
 While F<>Nil do Begin
  InitGeom(G);
  Flatten(JFind(F,'geometry'),G);
  If G.First<>Nil Then Begin
   BufText(B,'"');
   BufWkt(B,G);
   BufText(B,'"');
  End;
  FreeGeom(G);
  Pr:=JFind(F,'properties');
  For I:=1 to NK do Begin
   BufText(B,',');
   V:=Nil;
   If Pr<>Nil Then V:=JFind(Pr,Keys[I]);
   If V<>Nil Then Begin
    If V^.Kind=3Then BufText(B,CsvQuote(PropValText(V))) Else
    If(V^.Kind=1)or(V^.Kind=2)Then BufText(B,JVal(V));
   End;
  End;
  BufByte(B,10);
  F:=F^.Next;
 End;
 BufSave(FileName,B);
End;

Procedure GmlPath(Var B:TBuf;P:PPath);
Var
 I:LongInt;
Begin
 BufText(B,'<gml:coordinates>');
 For I:=0 to P^.N-1do Begin
  If I>0Then BufText(B,' ');
  BufText(B,NumStr(P^.Pts^[I].X)+','+NumStr(P^.Pts^[I].Y));
 End;
 BufText(B,'</gml:coordinates>');
End;

Procedure GmlPolygon(Var B:TBuf;Var P:PPath;Srs:String);
Var
 Poly:Integer;
 First:Boolean;
Begin
 Poly:=P^.Poly;
 BufText(B,'<gml:Polygon'+Srs+'>');
 First:=True;
 While(P<>Nil)and(P^.Poly=Poly)do Begin
  If First Then BufText(B,'<gml:outerBoundaryIs><gml:LinearRing>')
           Else BufText(B,'<gml:innerBoundaryIs><gml:LinearRing>');
  GmlPath(B,P);
  If First Then BufText(B,'</gml:LinearRing></gml:outerBoundaryIs>')
           Else BufText(B,'</gml:LinearRing></gml:innerBoundaryIs>');
  First:=False;
  P:=P^.Next;
 End;
 BufText(B,'</gml:Polygon>');
End;

Procedure GmlGeometry(Var B:TBuf;Var G:TGeom;Srs:String);
Var
 P:PPath;
Begin
 If G.First=Nil Then Exit;
 P:=G.First;
 Case G.Cls of
  1:Begin
   If G.Count=1Then Begin
    BufText(B,'<gml:Point'+Srs+'>');GmlPath(B,P);BufText(B,'</gml:Point>');
   End
    Else
   Begin
    BufText(B,'<gml:MultiPoint'+Srs+'>');
    While P<>Nil do Begin
     BufText(B,'<gml:pointMember><gml:Point>');GmlPath(B,P);BufText(B,'</gml:Point></gml:pointMember>');
     P:=P^.Next;
    End;
    BufText(B,'</gml:MultiPoint>');
   End;
  End;
  2:Begin
   If G.Count=1Then Begin
    BufText(B,'<gml:LineString'+Srs+'>');GmlPath(B,P);BufText(B,'</gml:LineString>');
   End
    Else
   Begin
    BufText(B,'<gml:MultiLineString'+Srs+'>');
    While P<>Nil do Begin
     BufText(B,'<gml:lineStringMember><gml:LineString>');GmlPath(B,P);BufText(B,'</gml:LineString></gml:lineStringMember>');
     P:=P^.Next;
    End;
    BufText(B,'</gml:MultiLineString>');
   End;
  End;
  3:Begin
   If G.NPoly=1Then GmlPolygon(B,P,Srs)
    Else
   Begin
    BufText(B,'<gml:MultiPolygon'+Srs+'>');
    While P<>Nil do Begin
     BufText(B,'<gml:polygonMember>');
     GmlPolygon(B,P,'');
     BufText(B,'</gml:polygonMember>');
    End;
    BufText(B,'</gml:MultiPolygon>');
   End;
  End;
 End;
End;

Procedure SaveGml(FileName:String;Root:PJ);
Var
 B:TBuf;
 Feats,F,Pr,C:PJ;
 G:TGeom;
 Layer,Srs,V:String;
 N:Integer;
 Crs:LongInt;
 P:PPath;
 I:LongInt;
 X1,Y1,X2,Y2:Real;
 Have:Boolean;
Begin
 Feats:=JFind(Root,'features');
 Layer:=XmlName(BaseNoExt(FileName));
 Crs:=SoftCrs(Root);
 If(Crs=0)or(Crs>CustomBase)Then Srs:='' Else Srs:=' srsName="EPSG:'+IntToStr(Crs)+'"';
 Have:=False;X1:=0;Y1:=0;X2:=0;Y2:=0;
 F:=Feats^.First;
 While F<>Nil do Begin
  InitGeom(G);
  Flatten(JFind(F,'geometry'),G);
  P:=G.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-1do Begin
    If Not Have Then Begin
     X1:=P^.Pts^[I].X;X2:=X1;Y1:=P^.Pts^[I].Y;Y2:=Y1;Have:=True;
    End
     Else
    Begin
     If P^.Pts^[I].X<X1 Then X1:=P^.Pts^[I].X;
     If P^.Pts^[I].X>X2 Then X2:=P^.Pts^[I].X;
     If P^.Pts^[I].Y<Y1 Then Y1:=P^.Pts^[I].Y;
     If P^.Pts^[I].Y>Y2 Then Y2:=P^.Pts^[I].Y;
    End;
   End;
   P:=P^.Next;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 BufInit(B);
 BufLn(B,'<?xml version="1.0" encoding="utf-8" ?>');
 BufLn(B,'<ogr:FeatureCollection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ogr="http://ogr.maptools.org/" xmlns:gml="http://www.opengis.net/gml">');
 If Have Then Begin
  BufLn(B,'  <gml:boundedBy><gml:Box'+Srs+'><gml:coord><gml:X>'+NumStr(X1)+'</gml:X><gml:Y>'+NumStr(Y1)+
   '</gml:Y></gml:coord><gml:coord><gml:X>'+NumStr(X2)+'</gml:X><gml:Y>'+NumStr(Y2)+'</gml:Y></gml:coord></gml:Box></gml:boundedBy>');
 End;
 N:=0;
 F:=Feats^.First;
 While F<>Nil do Begin
  BufText(B,'  <gml:featureMember><ogr:'+Layer+' fid="'+Layer+'.'+IntToStr(N)+'">');
  Inc(N);
  InitGeom(G);
  Flatten(JFind(F,'geometry'),G);
  If G.First<>Nil Then Begin
   BufText(B,'<ogr:geometryProperty>');
   GmlGeometry(B,G,Srs);
   BufText(B,'</ogr:geometryProperty>');
  End;
  FreeGeom(G);
  Pr:=JFind(F,'properties');
  If(Pr<>Nil)and(Pr^.Kind=5)Then Begin
   C:=Pr^.First;
   While C<>Nil do Begin
    If(C^.Kind=1)or(C^.Kind=2)or(C^.Kind=3)Then Begin
     V:=XmlName(JKey(C));
     BufText(B,'<ogr:'+V+'>'+XmlEsc(PropValText(C))+'</ogr:'+V+'>');
    End;
    C:=C^.Next;
   End;
  End;
  BufLn(B,'</ogr:'+Layer+'></gml:featureMember>');
  F:=F^.Next;
 End;
 BufLn(B,'</ogr:FeatureCollection>');
 BufSave(FileName,B);
End;

Procedure KmlPath(Var B:TBuf;P:PPath);
Var
 I:LongInt;
Begin
 BufText(B,'<coordinates>');
 For I:=0 to P^.N-1do Begin
  If I>0Then BufText(B,' ');
  BufText(B,NumStr(P^.Pts^[I].X)+','+NumStr(P^.Pts^[I].Y));
 End;
 BufText(B,'</coordinates>');
End;

Procedure KmlPolygon(Var B:TBuf;Var P:PPath);
Var
 Poly:Integer;
 First:Boolean;
Begin
 Poly:=P^.Poly;
 BufText(B,'<Polygon>');
 First:=True;
 While(P<>Nil)and(P^.Poly=Poly)do Begin
  If First Then BufText(B,'<outerBoundaryIs><LinearRing>')
           Else BufText(B,'<innerBoundaryIs><LinearRing>');
  KmlPath(B,P);
  If First Then BufText(B,'</LinearRing></outerBoundaryIs>')
           Else BufText(B,'</LinearRing></innerBoundaryIs>');
  First:=False;
  P:=P^.Next;
 End;
 BufText(B,'</Polygon>');
End;

Procedure KmlGeometry(Var B:TBuf;Var G:TGeom);
Var
 P:PPath;
Begin
 If G.First=Nil Then Exit;
 P:=G.First;
 If((G.Cls=1)or(G.Cls=2))and(G.Count=1)Then Begin
  If G.Cls=1Then Begin BufText(B,'<Point>');KmlPath(B,P);BufText(B,'</Point>');End
            Else Begin BufText(B,'<LineString>');KmlPath(B,P);BufText(B,'</LineString>');End;
  Exit;
 End;
 If(G.Cls=3)and(G.NPoly=1)Then Begin KmlPolygon(B,P);Exit;End;
 BufText(B,'<MultiGeometry>');
 While P<>Nil do Begin
  Case G.Cls of
   1:Begin BufText(B,'<Point>');KmlPath(B,P);BufText(B,'</Point>');P:=P^.Next;End;
   2:Begin BufText(B,'<LineString>');KmlPath(B,P);BufText(B,'</LineString>');P:=P^.Next;End;
   3:KmlPolygon(B,P);
   Else P:=P^.Next;
  End;
 End;
 BufText(B,'</MultiGeometry>');
End;

{ Ecrit le KML dans un tampon }
Procedure KmlBuild(FileName:String;Root:PJ;Var B:TBuf);
Var
 Feats,F,Pr,C,Gj:PJ;
 G:TGeom;
 Layer,K:String;
 Crs:LongInt;
 HasExt:Boolean;
Begin
 Feats:=JFind(Root,'features');
 Layer:=BaseNoExt(FileName);
 Crs:=SoftCrs(Root);
 If Crs=0Then Fail('Error: KML output needs a layer with a known coordinate reference system');
 BufInit(B);
 BufLn(B,'<?xml version="1.0" encoding="utf-8" ?>');
 BufLn(B,'<kml xmlns="http://www.opengis.net/kml/2.2">');
 BufLn(B,'<Document id="root_doc">');
 BufLn(B,'<Folder><name>'+XmlEsc(Layer)+'</name>');
 F:=Feats^.First;
 While F<>Nil do Begin
  BufText(B,'  <Placemark>');
  Pr:=JFind(F,'properties');
  HasExt:=False;
  If(Pr<>Nil)and(Pr^.Kind=5)Then Begin
   C:=Pr^.First;
   While C<>Nil do Begin
    K:=LowerStr(JKey(C));
    If(K='name')and(C^.Kind in[1,2,3])Then BufText(B,'<name>'+XmlEsc(PropValText(C))+'</name>') Else
    If(K='description')and(C^.Kind in[1,2,3])Then BufText(B,'<description>'+XmlEsc(PropValText(C))+'</description>');
    C:=C^.Next;
   End;
   C:=Pr^.First;
   While C<>Nil do Begin
    K:=LowerStr(JKey(C));
    If(K<>'name')and(K<>'description')and(C^.Kind in[1,2,3])Then Begin
     If Not HasExt Then Begin BufText(B,'<ExtendedData>');HasExt:=True;End;
     BufText(B,'<Data name="'+XmlEsc(JKey(C))+'"><value>'+XmlEsc(PropValText(C))+'</value></Data>');
    End;
    C:=C^.Next;
   End;
   If HasExt Then BufText(B,'</ExtendedData>');
  End;
  Gj:=JFind(F,'geometry');
  If(Gj<>Nil)and(Gj^.Kind=5)Then Begin
   If Crs<>4326Then Begin
    Gj:=JClone(Gj);
    If JFind(Gj,'coordinates')<>Nil Then TransformCoords(JFind(Gj,'coordinates'),Crs,4326);
   End;
   InitGeom(G);
   Flatten(Gj,G);
   KmlGeometry(B,G);
   FreeGeom(G);
  End;
  BufLn(B,'</Placemark>');
  F:=F^.Next;
 End;
 BufLn(B,'</Folder>');
 BufLn(B,'</Document></kml>');
End;

Procedure SaveKml(FileName:String;Root:PJ;Zipped:Boolean);
Var
 B:TBuf;
Begin
 KmlBuild(FileName,Root,B);
 If Zipped Then ZipSingle(FileName,'doc.kml',B)
           Else BufSave(FileName,B);
End;

{ ------------------------------------------------------------------ }
{ GeoPackage (SQLite) : lecture et ecriture                            }
{ ------------------------------------------------------------------ }

Var
 DB:PBytes;
 DBN,SqPS,SqUS:LongInt;
 PayBuf:PBytes;
 PayCap:LongInt;

Function SqBE16(P:LongInt):LongInt;Begin
 If(P<0)or(P+2>DBN)Then Fail('Error: corrupt GeoPackage file');
 SqBE16:=(LongInt(DB^[P])shl 8)or DB^[P+1];
End;

Function SqBE32(P:LongInt):LongInt;Begin
 If(P<0)or(P+4>DBN)Then Fail('Error: corrupt GeoPackage file');
 SqBE32:=RdBE32(DB,P);
End;

Function SqVarint(B:PBytes;Var P:LongInt):Int64;
Var
 I:Integer;
 V:Int64;
 C:Byte;
Begin
 V:=0;
 For I:=0 to 7do Begin
  C:=B^[P];Inc(P);
  V:=(V shl 7)or(C and $7F);
  If C<128Then Begin SqVarint:=V;Exit;End;
 End;
 C:=B^[P];Inc(P);
 V:=(V shl 8)or C;
 SqVarint:=V;
End;

{ Enregistrement courant decode }
Const
 MaxRc=1024;
Var
 RcN:Integer;
 RcTyp:Array[0..MaxRc-1]of LongInt;
 RcPos:Array[0..MaxRc-1]of LongInt;
 RcB:PBytes;
 SqRow:Int64;
 SqMode:Integer;

Procedure RcDecode(B:PBytes;Len:LongInt);
Var
 P,HS,E,T:LongInt;
 H:Int64;
Begin
 RcB:=B;
 RcN:=0;
 P:=0;
 HS:=SqVarint(B,P);
 If(HS<1)or(HS>Len)Then Fail('Error: corrupt GeoPackage record');
 E:=HS;
 While(P<HS)and(RcN<MaxRc)do Begin
  T:=SqVarint(B,P);
  RcTyp[RcN]:=T;
  Inc(RcN);
 End;
 P:=E;
 { positions des valeurs }
 For T:=0 to RcN-1do Begin
  RcPos[T]:=P;
  Case RcTyp[T]of
   1:Inc(P);
   2:Inc(P,2);
   3:Inc(P,3);
   4:Inc(P,4);
   5:Inc(P,6);
   6,7:Inc(P,8);
   Else If RcTyp[T]>=12Then Inc(P,(RcTyp[T]-12)div 2);
  End;
 End;
 If P>Len Then Fail('Error: corrupt GeoPackage record');
End;

Function RcIsNull(I:Integer):Boolean;Begin
 RcIsNull:=(I>=RcN)or(RcTyp[I]=0);
End;

Function RcGetReal(I:Integer):Real;
Var
 P:LongInt;
 V:Int64;
 K:Integer;
 D:Double;
 Bt:Array[0..7]of Byte absolute D;
Begin
 RcGetReal:=0;
 If I>=RcN Then Exit;
 P:=RcPos[I];
 Case RcTyp[I]of
  1:Begin If RcB^[P]>127Then RcGetReal:=RcB^[P]-256 Else RcGetReal:=RcB^[P];End;
  2:Begin
     V:=(LongInt(RcB^[P])shl 8)or RcB^[P+1];
     If V>=32768Then V:=V-65536;
     RcGetReal:=V;
    End;
  3:Begin
     V:=(LongInt(RcB^[P])shl 16)or(LongInt(RcB^[P+1])shl 8)or RcB^[P+2];
     If V>=8388608Then V:=V-16777216;
     RcGetReal:=V;
    End;
  4:RcGetReal:=RdBE32(RcB,P);
  5,6:Begin
     V:=0;
     If RcTyp[I]=5Then Begin
      For K:=0 to 5do V:=(V shl 8)or RcB^[P+K];
      If V>=140737488355328Then V:=V-281474976710656;
     End
      Else
     Begin
      For K:=0 to 7do V:=(V shl 8)or RcB^[P+K];
     End;
     RcGetReal:=V;
    End;
  7:Begin
     For K:=0 to 7do Bt[7-K]:=RcB^[P+K];
     RcGetReal:=D;
    End;
  8:RcGetReal:=0;
  9:RcGetReal:=1;
 End;
End;

Function RcIsNumber(I:Integer):Boolean;Begin
 RcIsNumber:=(I<RcN)and((RcTyp[I]in[1..9]));
End;

Function RcIsText(I:Integer):Boolean;Begin
 RcIsText:=(I<RcN)and(RcTyp[I]>=13)and(Odd(RcTyp[I]));
End;

Function RcIsBlob(I:Integer):Boolean;Begin
 RcIsBlob:=(I<RcN)and(RcTyp[I]>=12)and Not Odd(RcTyp[I]);
End;

Function RcGetStr(I:Integer):String;
Var
 L,K:LongInt;
 S:String;
Begin
 RcGetStr:='';
 If Not RcIsText(I)Then Exit;
 L:=(RcTyp[I]-13)div 2;
 If L>255Then L:=255;
 S:='';
 For K:=0 to L-1do S:=S+Chr(RcB^[RcPos[I]+K]);
 RcGetStr:=S;
End;

Function RcLen(I:Integer):LongInt;Begin
 RcLen:=(RcTyp[I]-12)div 2;
End;

Function RcLenText(I:Integer):LongInt;Begin
 RcLenText:=(RcTyp[I]-13)div 2;
End;

{ ---- parcours des b-arbres de tables ---- }

Type
 SchemaRec=Record
  Kind,Name,Tbl:String[80];
  Root:LongInt;
  Sql:PBytes;
  SqlLen:LongInt;
 End;
 ContRec=Record
  Tbl,Typ,Ident:String[80];
  Srs:LongInt;
 End;

Var
 Sch:Array[1..200]of SchemaRec;
 SchN:Integer;
 Cont:Array[1..200]of ContRec;
 ContN:Integer;
 GcTbl,GcCol,GcType:Array[1..200]of String[80];
 GcSrs:Array[1..200]of LongInt;
 GcN:Integer;
 FeatCol:PJ;
 FeatNames:Array[0..MaxRc-1]of String[60];
 FeatPk:Array[0..MaxRc-1]of Boolean;
 FeatNCols,FeatGeomCol:Integer;

Procedure SqRowFeature;
Var
 I:Integer;
 Props,Geom:PJ;
 P,Fl,Env,L:LongInt;
 Blob:PBytes;
Begin
 Props:=NewJ(5);
 Geom:=Nil;
 For I:=0 to FeatNCols-1do Begin
  If FeatPk[I]Then Continue;
  If I=FeatGeomCol Then Begin
   If RcIsBlob(I)Then Begin
    L:=RcLen(I);
    P:=RcPos[I];
    If(L>=8)and(RcB^[P]=Ord('G'))and(RcB^[P+1]=Ord('P'))Then Begin
     Fl:=RcB^[P+3];
     Case(Fl shr 1)and 7of
      1:Env:=32;
      2,3:Env:=48;
      4:Env:=64;
      Else Env:=0;
     End;
     If(Fl and $10)=0Then Begin
      If 8+Env<L Then Geom:=WkbToGeom(RcB,P+8+Env,P+L);
     End;
    End;
   End;
   Continue;
  End;
  If RcIsNull(I)Then JAddKV(Props,FeatNames[I],NewJ(0)) Else
  If RcIsNumber(I)Then JAddKV(Props,FeatNames[I],JNum(RcGetReal(I))) Else
  If RcIsText(I)Then JAddKV(Props,FeatNames[I],JTextEsc(RcGetStr(I)))
                Else JAddKV(Props,FeatNames[I],NewJ(0));
 End;
 AddFeature(FeatCol,Props,Geom);
End;

Procedure SqCell(CellOff:LongInt);
Var
 P,Local,X,M,K,Rem,Ptr,Take,Pg,L2:LongInt;
 Pay:Int64;
 Rec:PBytes;
 Q:PBytes;
 I:Integer;
 S:String;
Begin
 P:=CellOff;
 Pay:=SqVarint(DB,P);
 SqRow:=SqVarint(DB,P);
 If(Pay<0)or(Pay>DBN)Then Fail('Error: corrupt GeoPackage file');
 X:=SqUS-35;
 If Pay<=X Then Begin
  If P+Pay>DBN Then Fail('Error: corrupt GeoPackage file');
  Rec:=@DB^[P];
 End
  Else
 Begin
  M:=((SqUS-12)*32 div 255)-23;
  K:=M+((Pay-M)mod(SqUS-4));
  If K<=X Then Local:=K Else Local:=M;
  If PayCap<Pay+8Then Begin
   If PayBuf<>Nil Then FreeMem(PayBuf,PayCap);
   PayCap:=Pay+4096;
   PayBuf:=AllocBlock(PayCap);
  End;
  If P+Local+4>DBN Then Fail('Error: corrupt GeoPackage file');
  Move(DB^[P],PayBuf^,Local);
  Ptr:=SqBE32(P+Local);
  Rem:=Pay-Local;
  K:=Local;
  While(Rem>0)and(Ptr>0)do Begin
   Pg:=(Ptr-1)*SqPS;
   If(Pg<0)or(Pg+SqPS>DBN)Then Fail('Error: corrupt GeoPackage file');
   Take:=SqUS-4;
   If Take>Rem Then Take:=Rem;
   Move(DB^[Pg+4],PayBuf^[K],Take);
   Inc(K,Take);Dec(Rem,Take);
   Ptr:=SqBE32(Pg);
  End;
  If Rem>0Then Fail('Error: corrupt GeoPackage overflow chain');
  Rec:=PayBuf;
 End;
 RcDecode(Rec,Pay);
 Case SqMode of
  1:Begin
   If(SchN<200)and(RcN>=5)Then Begin
    Inc(SchN);
    Sch[SchN].Kind:=RcGetStr(0);
    Sch[SchN].Name:=RcGetStr(1);
    Sch[SchN].Tbl:=RcGetStr(2);
    Sch[SchN].Root:=Round(RcGetReal(3));
    Sch[SchN].SqlLen:=0;
    Sch[SchN].Sql:=Nil;
    If RcIsText(4)Then Begin
     L2:=RcLenText(4);
     Sch[SchN].SqlLen:=L2;
     Q:=AllocBlock(L2+1);
     Move(RcB^[RcPos[4]],Q^,L2);
     Sch[SchN].Sql:=Q;
    End;
   End;
  End;
  2:Begin
   If(ContN<200)and(RcN>=10)Then Begin
    Inc(ContN);
    Cont[ContN].Tbl:=RcGetStr(0);
    Cont[ContN].Typ:=RcGetStr(1);
    Cont[ContN].Ident:=RcGetStr(2);
    Cont[ContN].Srs:=Round(RcGetReal(9));
   End;
  End;
  3:Begin
   If(GcN<200)and(RcN>=4)Then Begin
    Inc(GcN);
    GcTbl[GcN]:=RcGetStr(0);
    GcCol[GcN]:=RcGetStr(1);
    GcType[GcN]:=RcGetStr(2);
    GcSrs[GcN]:=Round(RcGetReal(3));
   End;
  End;
  4:SqRowFeature;
 End;
End;

Procedure SqWalk(PageNo:LongInt);
Var
 Off,Hp,Typ,NC,I:LongInt;
Begin
 If(PageNo<1)or(PageNo*SqPS>DBN)Then Fail('Error: corrupt GeoPackage file');
 Off:=(PageNo-1)*SqPS;
 Hp:=Off;
 If PageNo=1Then Hp:=Off+100;
 Typ:=DB^[Hp];
 NC:=SqBE16(Hp+3);
 If Typ=13Then Begin
  For I:=0 to NC-1do SqCell(Off+SqBE16(Hp+8+2*I));
 End Else
 If Typ=5Then Begin
  For I:=0 to NC-1do SqWalk(SqBE32(Off+SqBE16(Hp+12+2*I)));
  SqWalk(SqBE32(Hp+8));
 End
  Else
 Fail('Error: unsupported GeoPackage b-tree page type '+IntToStr(Typ));
End;

Function SqFindRoot(Const Name:String):LongInt;
Var
 I:Integer;
Begin
 SqFindRoot:=0;
 For I:=1 to SchN do
  If(Sch[I].Kind='table')and(LowerStr(Sch[I].Name)=Name)Then Begin SqFindRoot:=Sch[I].Root;Exit;End;
End;

{ Noms de colonnes d'une instruction CREATE TABLE }
Procedure SqColumns(Sql:PBytes;Len:LongInt);
Var
 I,Depth,SegStart:LongInt;
 Q:Integer;
 Started:Boolean;

 Procedure Segment(S,E:LongInt);
 Var
  J,K:LongInt;
  Nm,Ty,Up:String;
  C:Integer;
  Close:Integer;
 Begin
  While(S<E)and(Sql^[S]in[9,10,13,32])do Inc(S);
  If S>=E Then Exit;
  Nm:='';
  C:=Sql^[S];
  If(C=34)or(C=96)or(C=91)Then Begin
   If C=91Then Close:=93 Else Close:=C;
   J:=S+1;
   While(J<E)and(Sql^[J]<>Close)do Begin
    If Length(Nm)<60Then Nm:=Nm+Chr(Sql^[J]);
    Inc(J);
   End;
   Inc(J);
  End
   Else
  Begin
   J:=S;
   While(J<E)and Not(Sql^[J]in[9,10,13,32,40,44])do Begin
    If Length(Nm)<60Then Nm:=Nm+Chr(Sql^[J]);
    Inc(J);
   End;
   Up:=StrUpper(Nm);
   If(Up='PRIMARY')or(Up='UNIQUE')or(Up='CONSTRAINT')or(Up='FOREIGN')or(Up='CHECK')Then Exit;
  End;
  { type et contraintes }
  Ty:='';
  K:=J;
  While K<E do Begin
   If Length(Ty)<200Then Ty:=Ty+UpCase(Chr(Sql^[K]));
   Inc(K);
  End;
  If FeatNCols<MaxRc Then Begin
   FeatNames[FeatNCols]:=Nm;
   FeatPk[FeatNCols]:=(Pos('INTEGER',Copy(Ty,1,12))>0)and(Pos('PRIMARY KEY',Ty)>0);
   Inc(FeatNCols);
  End;
 End;

Begin
 FeatNCols:=0;
 Depth:=0;Q:=0;Started:=False;SegStart:=0;
 I:=0;
 While I<Len do Begin
  If Q<>0Then Begin
   If Sql^[I]=Q Then Q:=0;
  End
   Else
  Case Sql^[I]of
   34,39,96:Q:=Sql^[I];
   40:Begin
     Inc(Depth);
     If(Depth=1)and Not Started Then Begin Started:=True;SegStart:=I+1;End;
    End;
   41:Begin
     Dec(Depth);
     If(Depth=0)and Started Then Begin Segment(SegStart,I);Exit;End;
    End;
   44:If(Depth=1)and Started Then Begin Segment(SegStart,I);SegStart:=I+1;End;
  End;
  Inc(I);
 End;
End;

Function LoadGpkg(FileName,LName:String):PJ;
Var
 B:PBytes;
 N:LongInt;
 I,Pick,GI:Integer;
 Root:LongInt;
 L:String;
 Srs:LongInt;
 C,Pr:PJ;
Begin
 B:=LoadFileBytes(FileName,N);
 If B=Nil Then Fail('Error: unable to open input file '+FileName);
 L:='';
 For I:=0 to 14do If N>I Then L:=L+Chr(B^[I]);
 If(N<100)or(StrUpper(L)<>'SQLITE FORMAT 3')Then Fail('Error: '+FileName+' is not a GeoPackage file');
 DB:=B;DBN:=N;
 SqPS:=SqBE16(16);
 If SqPS=1Then SqPS:=65536;
 SqUS:=SqPS-DB^[20];
 If DB^[56+3]<>1Then Fail('Error: only UTF-8 GeoPackage files are supported');
 If(DBN mod SqPS)<>0Then Fail('Error: corrupt GeoPackage file');
 SchN:=0;ContN:=0;GcN:=0;
 SqMode:=1;
 SqWalk(1);
 Root:=SqFindRoot('gpkg_contents');
 If Root=0Then Fail('Error: '+FileName+' has no gpkg_contents table (not a GeoPackage)');
 SqMode:=2;SqWalk(Root);
 Root:=SqFindRoot('gpkg_geometry_columns');
 If Root<>0Then Begin SqMode:=3;SqWalk(Root);End;
 { choix de la table }
 Pick:=0;
 If LName<>''Then Begin
  For I:=1 to ContN do
   If(Pick=0)and((LowerStr(Cont[I].Tbl)=LowerStr(LName))or(LowerStr(Cont[I].Ident)=LowerStr(LName)))Then Pick:=I;
  If Pick=0Then Fail('Error: layer "'+LName+'" not found in '+FileName);
 End
  Else
 Begin
  For I:=1 to ContN do If(Pick=0)and(Cont[I].Typ='features')Then Pick:=I;
  For I:=1 to ContN do If(Pick=0)and(Cont[I].Typ='attributes')Then Pick:=I;
  If Pick=0Then Fail('Error: no vector layer in '+FileName);
 End;
 L:=Cont[Pick].Tbl;
 Root:=0;
 For I:=1 to SchN do
  If(Sch[I].Kind='table')and(Sch[I].Name=L)Then Begin
   Root:=Sch[I].Root;
   If Sch[I].Sql=Nil Then Fail('Error: table '+L+' has no schema');
   SqColumns(Sch[I].Sql,Sch[I].SqlLen);
  End;
 If Root=0Then Fail('Error: table '+L+' not found in '+FileName);
 FeatGeomCol:=-1;
 Srs:=Cont[Pick].Srs;
 For GI:=1 to GcN do
  If GcTbl[GI]=L Then Begin
   For I:=0 to FeatNCols-1do If FeatNames[I]=GcCol[GI]Then FeatGeomCol:=I;
   Srs:=GcSrs[GI];
  End;
 FeatCol:=NewCollection;
 SqMode:=4;
 SqWalk(Root);
 If(Srs>0)and(Srs<>4326)and CrsKnown(Srs)Then SetLayerCrs(FeatCol,Srs) Else
 If(Srs<>4326)and(Srs>0)Then Begin
  C:=NewJ(5);
  JAddKV(C,'type',JText('name'));
  Pr:=NewJ(5);
  JAddKV(Pr,'name',JText('EPSG:'+IntToStr(Srs)));
  JAddKV(C,'properties',Pr);
  JAddKV(FeatCol,'crs',C);
 End;
 LoadGpkg:=FeatCol;
End;

{ ---- GeoPackage : ecriture ---- }

Var
 SqB:TBuf;
 RcT:Array[0..MaxRc-1]of LongInt;
 WN:Integer;
 WBody:TBuf;

Procedure BufBE16(Var B:TBuf;V:LongInt);Begin
 BufByte(B,V shr 8);BufByte(B,V);
End;

Procedure BufVarint(Var B:TBuf;V:Int64);
Var
 Tmp:Array[0..9]of Byte;
 N,I:Integer;
Begin
 If(V<0)or(V>=72057594037927936)Then Begin
  For I:=0 to 7do BufByte(B,((V shr(8+7*(7-I)))and $7F)or $80);
  BufByte(B,V and $FF);
  Exit;
 End;
 N:=0;
 Repeat
  Tmp[N]:=V and $7F;
  V:=V shr 7;
  Inc(N);
 Until V=0;
 For I:=N-1downto 0do Begin
  If I>0Then BufByte(B,Tmp[I]or $80)
        Else BufByte(B,Tmp[I]);
 End;
End;

Function VarintLen(V:Int64):Integer;
Var
 T:TBuf;
Begin
 BufInit(T);
 BufVarint(T,V);
 VarintLen:=T.N;
 FreeMem(T.P,T.Cap);
End;

Procedure WrClear;Begin
 WN:=0;
 WBody.N:=0;
End;

Procedure WrType(T:LongInt);Begin
 If WN>=MaxRc Then Fail('Error: too many fields');
 RcT[WN]:=T;
 Inc(WN);
End;

Procedure WrNull;Begin WrType(0);End;

Procedure WrInt(V:Int64);Begin
 If V=0Then WrType(8) Else
 If V=1Then WrType(9) Else
 If(V>=-128)and(V<=127)Then Begin WrType(1);BufByte(WBody,V);End Else
 If(V>=-32768)and(V<=32767)Then Begin WrType(2);BufBE16(WBody,V);End Else
 If(V>=-2147483648)and(V<=2147483647)Then Begin WrType(4);BufBE32(WBody,V);End
  Else
 Begin
  WrType(6);
  BufBE32(WBody,V shr 32);
  BufBE32(WBody,V and $FFFFFFFF);
 End;
End;

Procedure WrReal(V:Real);
Var
 D:Double;
 Bt:Array[0..7]of Byte absolute D;
 I:Integer;
Begin
 D:=V;
 WrType(7);
 For I:=7downto 0do BufByte(WBody,Bt[I]);
End;

Procedure WrText(S:String);Begin
 WrType(13+2*Length(S));
 BufText(WBody,S);
End;

Procedure WrTextBuf(Var T:TBuf);Begin
 WrType(13+2*T.N);
 BufGrow(WBody,T.N);
 Move(T.P^,WBody.P^[WBody.N],T.N);
 Inc(WBody.N,T.N);
End;

Procedure WrBlobBuf(Var T:TBuf);Begin
 WrType(12+2*T.N);
 BufGrow(WBody,T.N);
 Move(T.P^,WBody.P^[WBody.N],T.N);
 Inc(WBody.N,T.N);
End;

{ Ajoute l'enregistrement courant a Dest }
Procedure WrFinish(Var Dest:TBuf);
Var
 I,Tot:Integer;
 H:LongInt;
Begin
 Tot:=0;
 For I:=0 to WN-1do Inc(Tot,VarintLen(RcT[I]));
 H:=Tot+1;
 If H>127Then H:=Tot+2;
 BufVarint(Dest,H);
 For I:=0 to WN-1do BufVarint(Dest,RcT[I]);
 BufGrow(Dest,WBody.N);
 Move(WBody.P^,Dest.P^[Dest.N],WBody.N);
 Inc(Dest.N,WBody.N);
End;

Function SqNewPage:LongInt;Begin
 BufGrow(SqB,SqPS);
 FillChar(SqB.P^[SqB.N],SqPS,0);
 Inc(SqB.N,SqPS);
 SqNewPage:=SqB.N div SqPS;
End;

Procedure PutBE16(Off,V:LongInt);Begin
 SqB.P^[Off]:=(V shr 8)and 255;SqB.P^[Off+1]:=V and 255;
End;

Procedure PutBE32(Off,V:LongInt);Begin
 SqB.P^[Off]:=(V shr 24)and 255;SqB.P^[Off+1]:=(V shr 16)and 255;
 SqB.P^[Off+2]:=(V shr 8)and 255;SqB.P^[Off+3]:=V and 255;
End;

{ Construit le b-arbre d'une table : lignes dans Recs (offsets RowOff, longueurs RowLen) ; identifiants Ids (ou i+1) }
Function SqBuildTable(Var Recs:TBuf;RowOff,RowLen:PLongs;Ids:PLongs;NRows:LongInt):LongInt;
Var
 Lv,LvMax:PLongs;
 NLv:LongInt;
 Pg,Off,CE,NC,I,K,Local,X,M,Pay,Cell,OvPg,Rem,Take,Src,Prev:LongInt;
 CellB:TBuf;
 Id:LongInt;
 NextLv,NextMax:PLongs;
 Cnt,G,NG,Gi,Start,Sz,J,Rt:LongInt;

 Procedure FinishLeaf(MaxId:LongInt);Begin
  SqB.P^[Off]:=13;
  PutBE16(Off+3,NC);
  PutBE16(Off+5,CE);
  Lv^[NLv]:=Pg;LvMax^[NLv]:=MaxId;
  Inc(NLv);
 End;

Begin
 Lv:=AllocBlock((NRows+2)*SizeOf(LongInt));
 LvMax:=AllocBlock((NRows+2)*SizeOf(LongInt));
 NLv:=0;
 Pg:=SqNewPage;Off:=(Pg-1)*SqPS;CE:=SqPS;NC:=0;
 BufInit(CellB);
 Prev:=0;
 For I:=0 to NRows-1do Begin
  If Ids<>Nil Then Id:=Ids^[I] Else Id:=I+1;
  Pay:=RowLen^[I];
  Src:=RowOff^[I];
  CellB.N:=0;
  X:=SqPS-35;
  If Pay<=X Then Begin
   BufVarint(CellB,Pay);BufVarint(CellB,Id);
   BufGrow(CellB,Pay);
   Move(Recs.P^[Src],CellB.P^[CellB.N],Pay);
   Inc(CellB.N,Pay);
  End
   Else
  Begin
   M:=((SqPS-12)*32 div 255)-23;
   K:=M+((Pay-M)mod(SqPS-4));
   If K<=X Then Local:=K Else Local:=M;
   BufVarint(CellB,Pay);BufVarint(CellB,Id);
   BufGrow(CellB,Local);
   Move(Recs.P^[Src],CellB.P^[CellB.N],Local);
   Inc(CellB.N,Local);
   { pages de debordement }
   Rem:=Pay-Local;
   Src:=Src+Local;
   OvPg:=0;Prev:=0;
   While Rem>0do Begin
    K:=SqNewPage;
    If OvPg=0Then OvPg:=K Else PutBE32((Prev-1)*SqPS,K);
    Take:=SqPS-4;
    If Take>Rem Then Take:=Rem;
    Move(Recs.P^[Src],SqB.P^[(K-1)*SqPS+4],Take);
    Inc(Src,Take);Dec(Rem,Take);
    Prev:=K;
   End;
   BufBE32(CellB,OvPg);
  End;
  If(NC>0)and(8+2*(NC+1)+(SqPS-CE)+CellB.N>SqPS)Then Begin
   If Ids<>Nil Then FinishLeaf(Ids^[I-1]) Else FinishLeaf(I);
   Pg:=SqNewPage;Off:=(Pg-1)*SqPS;CE:=SqPS;NC:=0;
  End;
  CE:=CE-CellB.N;
  Move(CellB.P^,SqB.P^[Off+CE],CellB.N);
  PutBE16(Off+8+2*NC,CE);
  Inc(NC);
 End;
 If Ids<>Nil Then Begin
  If NRows>0Then FinishLeaf(Ids^[NRows-1])Else FinishLeaf(0);
 End
  Else
 FinishLeaf(NRows);
 FreeMem(CellB.P,CellB.Cap);
 { niveaux interieurs }
 While NLv>1do Begin
  G:=300;
  NG:=(NLv+G-1)div G;
  NextLv:=AllocBlock((NG+2)*SizeOf(LongInt));
  NextMax:=AllocBlock((NG+2)*SizeOf(LongInt));
  Start:=0;
  For Gi:=0 to NG-1do Begin
   Sz:=NLv div NG;
   If Gi<(NLv mod NG)Then Inc(Sz);
   Pg:=SqNewPage;Off:=(Pg-1)*SqPS;
   CE:=SqPS;NC:=0;
   For J:=0 to Sz-2do Begin
    CellB.P:=Nil;
    BufInit(CellB);
    BufBE32(CellB,Lv^[Start+J]);
    BufVarint(CellB,LvMax^[Start+J]);
    CE:=CE-CellB.N;
    Move(CellB.P^,SqB.P^[Off+CE],CellB.N);
    PutBE16(Off+12+2*NC,CE);
    Inc(NC);
    FreeMem(CellB.P,CellB.Cap);
   End;
   SqB.P^[Off]:=5;
   PutBE16(Off+3,NC);
   PutBE16(Off+5,CE);
   PutBE32(Off+8,Lv^[Start+Sz-1]);
   NextLv^[Gi]:=Pg;
   NextMax^[Gi]:=LvMax^[Start+Sz-1];
   Inc(Start,Sz);
  End;
  FreeMem(Lv,(NRows+2)*SizeOf(LongInt));
  FreeMem(LvMax,(NRows+2)*SizeOf(LongInt));
  Lv:=NextLv;LvMax:=NextMax;
  NRows:=NG;
  NLv:=NG;
 End;
 SqBuildTable:=Lv^[0];
End;

Procedure GpbPoints(Var B:TBuf;P:PPath;N:LongInt;Closed:Boolean);
Var
 I:LongInt;
 Add:Integer;
Begin
 Add:=0;
 If Closed and((P^.Pts^[0].X<>P^.Pts^[P^.N-1].X)or(P^.Pts^[0].Y<>P^.Pts^[P^.N-1].Y))Then Add:=1;
 BufLE32(B,N+Add);
 For I:=0 to N-1do Begin
  BufDouble(B,P^.Pts^[I].X);BufDouble(B,P^.Pts^[I].Y);
 End;
 If Add=1Then Begin BufDouble(B,P^.Pts^[0].X);BufDouble(B,P^.Pts^[0].Y);End;
End;

Procedure WkbPolygon(Var B:TBuf;Var P:PPath);
Var
 Poly,Cnt:Integer;
 Q:PPath;
Begin
 Poly:=P^.Poly;
 Cnt:=0;
 Q:=P;
 While(Q<>Nil)and(Q^.Poly=Poly)do Begin Inc(Cnt);Q:=Q^.Next;End;
 BufByte(B,1);BufLE32(B,3);BufLE32(B,Cnt);
 While(P<>Nil)and(P^.Poly=Poly)do Begin
  GpbPoints(B,P,P^.N,True);
  P:=P^.Next;
 End;
End;

Procedure WkbGeometry(Var B:TBuf;Var G:TGeom);
Var
 P:PPath;
 Np:Integer;
Begin
 P:=G.First;
 Case G.Cls of
  1:Begin
   If G.Count=1Then Begin
    BufByte(B,1);BufLE32(B,1);BufDouble(B,P^.Pts^[0].X);BufDouble(B,P^.Pts^[0].Y);
   End
    Else
   Begin
    BufByte(B,1);BufLE32(B,4);BufLE32(B,G.Count);
    While P<>Nil do Begin
     BufByte(B,1);BufLE32(B,1);BufDouble(B,P^.Pts^[0].X);BufDouble(B,P^.Pts^[0].Y);
     P:=P^.Next;
    End;
   End;
  End;
  2:Begin
   If G.Count=1Then Begin
    BufByte(B,1);BufLE32(B,2);GpbPoints(B,P,P^.N,False);
   End
    Else
   Begin
    BufByte(B,1);BufLE32(B,5);BufLE32(B,G.Count);
    While P<>Nil do Begin
     BufByte(B,1);BufLE32(B,2);GpbPoints(B,P,P^.N,False);
     P:=P^.Next;
    End;
   End;
  End;
  3:Begin
   If G.NPoly=1Then WkbPolygon(B,P)
    Else
   Begin
    BufByte(B,1);BufLE32(B,6);BufLE32(B,G.NPoly);
    While P<>Nil do WkbPolygon(B,P);
   End;
  End;
 End;
End;

Procedure SaveGpkg(FileName,LName:String;Root:PJ);
Const
 MaxCols=300;
Var
 Feats,F,Pr,C,V:PJ;
 Cols:Array[1..MaxCols]of String[60];
 ColTyp:Array[1..MaxCols]of Byte;  { 1 entier, 2 reel, 3 texte, 4 booleen }
 NC,J:Integer;
 Crs:LongInt;
 I,NF,K:LongInt;
 G:TGeom;
 P:PPath;
 Recs,Sql,Geo,Tmp,Master:TBuf;
 RowOff,RowLen:PLongs;
 Found:Boolean;
 GT,Tbl,Nm:String;
 X1,Y1,X2,Y2,Fx1,Fy1,Fx2,Fy2:Real;
 Have,FHave:Boolean;
 Cls,Multi,ClsAll:Integer;
 MultiAny,Mixed,AnyGeom:Boolean;
 Pg,RootF,RootSeq,RootSrs,RootCont,RootGc:LongInt;
 Y,Mo,D,Dw,H,Mi,S,S100:Word;
 Fmt:String;
 Ids:PLongs;
 Sr:Real;
 Rid:Array[1..4]of LongInt;
 Wkt1,Wkt2:String;
 MRows:Integer;
 MOff,MLen:Array[1..8]of LongInt;
 CE,Sz:LongInt;
 CTmp:TCrs;

 Function TwoD(V:Integer):String;
 Var S:String;
 Begin
  Str(V,S);
  If Length(S)<2Then S:='0'+S;
  TwoD:=S;
 End;

 Procedure MasterRow(Typ,Name,TblName:String;RootPg:LongInt;Var SqlB:TBuf);
 Begin
  WrClear;
  WrText(Typ);WrText(Name);WrText(TblName);WrInt(RootPg);WrTextBuf(SqlB);
  MOff[MRows+1]:=Master.N;
  WrFinish(Master);
  MLen[MRows+1]:=Master.N-MOff[MRows+1];
  Inc(MRows);
 End;

 Procedure SqlSet(S:String);Begin
  Sql.N:=0;
  BufText(Sql,S);
 End;

Begin
 Feats:=JFind(Root,'features');
 Tbl:=LName;
 If Tbl=''Then Tbl:=BaseNoExt(FileName);
 If Tbl=''Then Tbl:='layer';
 Crs:=SoftCrs(Root);
 If Crs=0Then Crs:=-1;
 { colonnes }
 NC:=0;
 F:=Feats^.First;
 While F<>Nil do Begin
  Pr:=JFind(F,'properties');
  If(Pr<>Nil)and(Pr^.Kind=5)Then Begin
   C:=Pr^.First;
   While C<>Nil do Begin
    I:=0;
    For J:=1 to NC do If Cols[J]=JKey(C)Then I:=J;
    If(I=0)and(C^.Kind in[1,2,3])Then Begin
     If NC>=MaxCols Then Fail('Error: too many fields for GeoPackage output');
     Inc(NC);Cols[NC]:=JKey(C);I:=NC;ColTyp[I]:=0;
    End;
    If I>0Then Begin
     Case C^.Kind of
      1:If ColTyp[I]=0Then ColTyp[I]:=4 Else If ColTyp[I]<>4Then ColTyp[I]:=3;
      2:Begin
         If Pos('.',JVal(C))+Pos('e',JVal(C))+Pos('E',JVal(C))>0Then Begin
          If ColTyp[I]=0Then ColTyp[I]:=2 Else If ColTyp[I]=1Then ColTyp[I]:=2 Else If ColTyp[I]<>2Then ColTyp[I]:=3;
         End
          Else
         Begin
          If ColTyp[I]=0Then ColTyp[I]:=1 Else If(ColTyp[I]<>1)and(ColTyp[I]<>2)Then ColTyp[I]:=3;
         End;
        End;
      3:ColTyp[I]:=3;
     End;
    End;
    C:=C^.Next;
   End;
  End;
  F:=F^.Next;
 End;
 For J:=1 to NC do If ColTyp[J]=0Then ColTyp[J]:=3;
 { lignes }
 BufInit(Recs);BufInit(WBody);BufInit(Geo);BufInit(Tmp);BufInit(Sql);
 NF:=0;
 F:=Feats^.First;
 While F<>Nil do Begin Inc(NF);F:=F^.Next;End;
 RowOff:=AllocBlock((NF+8)*SizeOf(LongInt));
 RowLen:=AllocBlock((NF+8)*SizeOf(LongInt));
 Have:=False;X1:=0;Y1:=0;X2:=0;Y2:=0;
 ClsAll:=0;MultiAny:=False;Mixed:=False;AnyGeom:=False;
 K:=0;
 F:=Feats^.First;
 While F<>Nil do Begin
  InitGeom(G);
  Flatten(JFind(F,'geometry'),G);
  Geo.N:=0;
  WrClear;
  WrNull;                       { fid : alias de rowid }
  If G.First<>Nil Then Begin
   AnyGeom:=True;
   If(ClsAll<>0)and(ClsAll<>G.Cls)Then Mixed:=True;
   ClsAll:=G.Cls;
   If((G.Cls=3)and(G.NPoly>1))or((G.Cls<3)and(G.Count>1))Then MultiAny:=True;
   FHave:=False;Fx1:=0;Fy1:=0;Fx2:=0;Fy2:=0;
   P:=G.First;
   While P<>Nil do Begin
    For I:=0 to P^.N-1do Begin
     If Not FHave Then Begin
      Fx1:=P^.Pts^[I].X;Fx2:=Fx1;Fy1:=P^.Pts^[I].Y;Fy2:=Fy1;FHave:=True;
     End
      Else
     Begin
      If P^.Pts^[I].X<Fx1 Then Fx1:=P^.Pts^[I].X;
      If P^.Pts^[I].X>Fx2 Then Fx2:=P^.Pts^[I].X;
      If P^.Pts^[I].Y<Fy1 Then Fy1:=P^.Pts^[I].Y;
      If P^.Pts^[I].Y>Fy2 Then Fy2:=P^.Pts^[I].Y;
     End;
    End;
    P:=P^.Next;
   End;
   If Not Have Then Begin X1:=Fx1;Y1:=Fy1;X2:=Fx2;Y2:=Fy2;Have:=True;End
   Else Begin
    If Fx1<X1 Then X1:=Fx1;
    If Fy1<Y1 Then Y1:=Fy1;
    If Fx2>X2 Then X2:=Fx2;
    If Fy2>Y2 Then Y2:=Fy2;
   End;
   BufByte(Geo,Ord('G'));BufByte(Geo,Ord('P'));BufByte(Geo,0);BufByte(Geo,3);
   BufLE32(Geo,Crs);
   BufDouble(Geo,Fx1);BufDouble(Geo,Fx2);BufDouble(Geo,Fy1);BufDouble(Geo,Fy2);
   WkbGeometry(Geo,G);
   WrBlobBuf(Geo);
  End
   Else
  WrNull;
  FreeGeom(G);
  Pr:=JFind(F,'properties');
  For J:=1 to NC do Begin
   V:=Nil;
   If Pr<>Nil Then V:=JFind(Pr,Cols[J]);
   If(V=Nil)or Not(V^.Kind in[1,2,3])Then WrNull Else
   Case ColTyp[J]of
    1:Begin
       Val(JVal(V),Sr,I);
       If I=0Then WrInt(Round(Sr))Else WrNull;
      End;
    2:Begin
       If V^.Kind=2Then Begin
        Val(JVal(V),Sr,I);
        If I=0Then WrReal(Sr)Else WrNull;
       End
        Else
       WrNull;
      End;
    4:If JVal(V)='true'Then WrInt(1)Else WrInt(0);
    Else Begin
     Tmp.N:=0;
     BufText(Tmp,PropValText(V));
     WrTextBuf(Tmp);
    End;
   End;
  End;
  RowOff^[K]:=Recs.N;
  WrFinish(Recs);
  RowLen^[K]:=Recs.N-RowOff^[K];
  Inc(K);
  F:=F^.Next;
 End;
 { type de geometrie }
 If Not AnyGeom Or Mixed Then GT:='GEOMETRY' Else
 Case ClsAll of
  1:If MultiAny Then GT:='MULTIPOINT' Else GT:='POINT';
  2:If MultiAny Then GT:='MULTILINESTRING' Else GT:='LINESTRING';
  Else If MultiAny Then GT:='MULTIPOLYGON' Else GT:='POLYGON';
 End;
 { fichier }
 SqPS:=4096;
 BufInit(SqB);
 SqNewPage;                       { page 1 : sqlite_master }
 RootF:=SqBuildTable(Recs,RowOff,RowLen,Nil,NF);
 { sqlite_sequence }
 Recs.N:=0;
 WrClear;WrText(Tbl);WrInt(NF);
 RowOff^[0]:=0;
 WrFinish(Recs);
 RowLen^[0]:=Recs.N;
 RootSeq:=SqBuildTable(Recs,RowOff,RowLen,Nil,1);
 { gpkg_spatial_ref_sys }
 Recs.N:=0;
 Ids:=AllocBlock(6*SizeOf(LongInt));
 Ids^[0]:=-1;Ids^[1]:=0;Ids^[2]:=4326;
 MRows:=3;
 If(Crs>0)and(Crs<>4326)Then Begin Ids^[3]:=Crs;MRows:=4;End;
 If(MRows=4)and(Ids^[3]<4326)Then Begin
  Ids^[3]:=4326;Ids^[2]:=Crs;
 End;
 For J:=0 to MRows-1do Begin
  WrClear;
  Tmp.N:=0;
  Case Ids^[J]of
   -1:Begin WrText('Undefined cartesian SRS');WrNull;WrText('NONE');WrInt(-1);WrText('undefined');WrText('undefined Cartesian coordinate reference system');End;
   0:Begin WrText('Undefined geographic SRS');WrNull;WrText('NONE');WrInt(0);WrText('undefined');WrText('undefined geographic coordinate reference system');End;
   4326:Begin
      WrText('WGS 84 geodetic');WrNull;WrText('EPSG');WrInt(4326);
      Tmp.N:=0;
      BufText(Tmp,'GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],');
      BufText(Tmp,'PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]]');
      WrTextBuf(Tmp);
      WrText('longitude/latitude coordinates in decimal degrees on the WGS 84 spheroid');
     End;
   3857:Begin
      WrText('WGS 84 / Pseudo-Mercator');WrNull;WrText('EPSG');WrInt(3857);
      Tmp.N:=0;
      BufText(Tmp,'PROJCS["WGS 84 / Pseudo-Mercator",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],');
      BufText(Tmp,'PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]],');
      BufText(Tmp,'PROJECTION["Mercator_1SP"],PARAMETER["central_meridian",0],PARAMETER["scale_factor",1],PARAMETER["false_easting",0],PARAMETER["false_northing",0],');
      BufText(Tmp,'UNIT["metre",1,AUTHORITY["EPSG","9001"]],AXIS["Easting",EAST],AXIS["Northing",NORTH],AUTHORITY["EPSG","3857"]]');
      WrTextBuf(Tmp);
      WrText('Web Mercator');
     End;
   Else Begin
      CrsDefine(Ids^[J],CTmp);
      WrText(CTmp.Name);WrNull;
      If Ids^[J]>CustomBase Then Begin WrText('NONE');WrInt(-1);End
                            Else Begin WrText('EPSG');WrInt(Ids^[J]);End;
      CrsWktBuf(Ids^[J],Tmp);
      WrTextBuf(Tmp);
      WrText('');
     End;
  End;
  RowOff^[J]:=Recs.N;
  WrFinish(Recs);
  RowLen^[J]:=Recs.N-RowOff^[J];
 End;
 RootSrs:=SqBuildTable(Recs,RowOff,RowLen,Ids,MRows);
 { gpkg_contents }
 Recs.N:=0;
 GetDate(Y,Mo,D,Dw);GetTime(H,Mi,S,S100);
 Fmt:=IntToStr(Y)+'-'+TwoD(Mo)+'-'+TwoD(D)+'T'+TwoD(H)+':'+TwoD(Mi)+':'+TwoD(S)+'.000Z';
 WrClear;
 WrText(Tbl);WrText('features');WrText(Tbl);WrText('');WrText(Fmt);
 If Have Then Begin WrReal(X1);WrReal(Y1);WrReal(X2);WrReal(Y2);End
         Else Begin WrNull;WrNull;WrNull;WrNull;End;
 WrInt(Crs);
 RowOff^[0]:=0;
 WrFinish(Recs);
 RowLen^[0]:=Recs.N;
 RootCont:=SqBuildTable(Recs,RowOff,RowLen,Nil,1);
 { gpkg_geometry_columns }
 Recs.N:=0;
 WrClear;
 WrText(Tbl);WrText('geom');WrText(GT);WrInt(Crs);WrInt(0);WrInt(0);
 RowOff^[0]:=0;
 WrFinish(Recs);
 RowLen^[0]:=Recs.N;
 RootGc:=SqBuildTable(Recs,RowOff,RowLen,Nil,1);
 { sqlite_master }
 BufInit(Master);
 MRows:=0;
 Fmt:='CREATE TABLE gpkg_spatial_ref_sys (srs_name TEXT NOT NULL, srs_id INTEGER NOT NULL PRIMARY KEY, organization TEXT NOT NULL, organization_coordsys_id INTEGER NOT NULL, definition TEXT NOT NULL, description TEXT)';
 SqlSet(Fmt);
 MasterRow('table','gpkg_spatial_ref_sys','gpkg_spatial_ref_sys',RootSrs,Sql);
 SqlSet('CREATE TABLE gpkg_contents (table_name TEXT NOT NULL, data_type TEXT NOT NULL, identifier TEXT, description TEXT DEFAULT '''', ');
 BufText(Sql,'last_change DATETIME NOT NULL, min_x DOUBLE, min_y DOUBLE, max_x DOUBLE, max_y DOUBLE, srs_id INTEGER)');
 MasterRow('table','gpkg_contents','gpkg_contents',RootCont,Sql);
 SqlSet('CREATE TABLE gpkg_geometry_columns (table_name TEXT NOT NULL, column_name TEXT NOT NULL, geometry_type_name TEXT NOT NULL, srs_id INTEGER NOT NULL, z TINYINT NOT NULL, m TINYINT NOT NULL)');
 MasterRow('table','gpkg_geometry_columns','gpkg_geometry_columns',RootGc,Sql);
 Sql.N:=0;
 BufText(Sql,'CREATE TABLE "'+Tbl+'" (fid INTEGER PRIMARY KEY AUTOINCREMENT, geom '+GT);
 For J:=1 to NC do Begin
  Nm:=Cols[J];
  For I:=1 to Length(Nm)do If Nm[I]='"'Then Nm[I]:='_';
  BufText(Sql,', "'+Nm+'" ');
  Case ColTyp[J]of
   1:BufText(Sql,'INTEGER');
   2:BufText(Sql,'REAL');
   4:BufText(Sql,'BOOLEAN');
   Else BufText(Sql,'TEXT');
  End;
 End;
 BufText(Sql,')');
 MasterRow('table',Tbl,Tbl,RootF,Sql);
 SqlSet('CREATE TABLE sqlite_sequence(name,seq)');
 MasterRow('table','sqlite_sequence','sqlite_sequence',RootSeq,Sql);
 { page 1 : feuille de sqlite_master }
 CE:=SqPS;
 Sz:=0;
 For J:=1 to MRows do Inc(Sz,2+MLen[J]+2+2);
 If 8+2*MRows+Sz>SqPS-100Then Fail('Error: GeoPackage schema too large');
 For J:=1 to MRows do Begin
  Tmp.N:=0;
  BufVarint(Tmp,MLen[J]);BufVarint(Tmp,J);
  BufGrow(Tmp,MLen[J]);
  Move(Master.P^[MOff[J]],Tmp.P^[Tmp.N],MLen[J]);
  Inc(Tmp.N,MLen[J]);
  CE:=CE-Tmp.N;
  Move(Tmp.P^,SqB.P^[CE],Tmp.N);
  PutBE16(100+8+2*(J-1),CE);
 End;
 SqB.P^[100]:=13;
 PutBE16(103,MRows);
 PutBE16(105,CE);
 Fmt:='SQLite format 3';
 For J:=1 to 15do SqB.P^[J-1]:=Ord(Fmt[J]);
 SqB.P^[15]:=0;
 PutBE16(16,SqPS);
 SqB.P^[18]:=1;SqB.P^[19]:=1;SqB.P^[20]:=0;SqB.P^[21]:=64;SqB.P^[22]:=32;SqB.P^[23]:=32;
 PutBE32(24,1);
 PutBE32(28,SqB.N div SqPS);
 PutBE32(40,1);
 PutBE32(44,4);
 PutBE32(56,1);
 PutBE32(60,10200);
 PutBE32(68,$47504B47);
 PutBE32(92,1);
 PutBE32(96,3045000);
 BufSave(FileName,SqB);
End;

{ ---- fichiers de projet QGIS (.qgs / .qgz) : nom de couche -> source ---- }

Function ProjLayer(N:PX;Const Want:String):PX;
Var
 C,R:PX;
Begin
 ProjLayer:=Nil;
 C:=N^.First;
 While C<>Nil do Begin
  If C^.Name^='MAPLAYER'Then Begin
   If(XText(XKid(C,'LAYERNAME'))=Want)or(XText(XKid(C,'ID'))=Want)Then Begin
    ProjLayer:=C;
    Exit;
   End;
  End
   Else
  Begin
   R:=ProjLayer(C,Want);
   If R<>Nil Then Begin ProjLayer:=R;Exit;End;
  End;
  C:=C^.Next;
 End;
End;

Function ResolveProject(Name:String):String;
Var
 Path,LN,Sub,Ds,Dir:String;
 B:PBytes;
 N,Sz,I:LongInt;
 Root:PX;
 M:PX;
 Abs:Boolean;
Begin
 ResolveProject:=Name;
 If ProjectPath=''Then Exit;
 ParseUri(Name,Path,LN,Sub);
 If FileExists(Path)Then Exit;
 B:=LoadFileBytes(ProjectPath,N);
 If B=Nil Then Fail('Error: unable to read project file '+ProjectPath);
 If FileExt(ProjectPath)='.QGZ'Then Begin
  B:=ZipExtract(B,N,'.QGS',Sz);
  If B=Nil Then Fail('Error: no .qgs file in project '+ProjectPath);
  N:=Sz;
 End;
 Root:=XParse(B,N);
 M:=ProjLayer(Root,Path);
 If M=Nil Then Exit;
 Ds:=XText(XKid(M,'DATASOURCE'));
 If Ds=''Then Exit;
 Dir:='';
 For I:=Length(ProjectPath)downto 1do
  If ProjectPath[I]in['/',#92]Then Begin Dir:=Copy(ProjectPath,1,I);Break;End;
 Abs:=(Ds[1]='/')or(Ds[1]=#92)or((Length(Ds)>1)and(Ds[2]=':'))or(Pos('://',Ds)>0)or(Pos('dbname=',Ds)>0);
 If Not Abs Then Begin
  If Copy(Ds,1,2)='./'Then Ds:=Copy(Ds,3,255);
  Ds:=Dir+Ds;
 End;
 ResolveProject:=Ds;
End;

Function HexVal(C:Char):Integer;Begin
 Case UpCase(C)of
  '0'..'9':HexVal:=Ord(C)-48;
  'A'..'F':HexVal:=Ord(UpCase(C))-55;
  Else HexVal:=-1;
 End;
End;

Function UrlDecode(S:String):String;
Var
 R:String;
 I:Integer;
Begin
 R:='';
 I:=1;
 While I<=Length(S)do Begin
  If(S[I]='%')and(I+2<=Length(S))and(HexVal(S[I+1])>=0)and(HexVal(S[I+2])>=0)Then Begin
   R:=R+Chr(HexVal(S[I+1])*16+HexVal(S[I+2]));
   Inc(I,3);
  End
   Else
  Begin
   If S[I]='+'Then R:=R+' ' Else R:=R+S[I];
   Inc(I);
  End;
 End;
 UrlDecode:=R;
End;

{ URI "delimited text" de QGIS : file:///chemin.csv?type=csv&delimiter=;&xField=x&yField=y&crs=EPSG:4326 }
Function ParseDelimUri(Var Path:String):Boolean;
Var
 Q,E:Integer;
 Opts,Part,K,V:String;
Begin
 ParseDelimUri:=False;
 If Copy(LowerStr(Path),1,7)<>'file://'Then Exit;
 Path:=Copy(Path,8,255);
 If(Length(Path)>=3)and(Path[1]='/')and(Path[3]=':')Then Delete(Path,1,1);
 Q:=Pos('?',Path);
 Opts:='';
 If Q>0Then Begin
  Opts:=Copy(Path,Q+1,255);
  Path:=Copy(Path,1,Q-1);
 End;
 While Opts<>''do Begin
  E:=Pos('&',Opts);
  If E=0Then Begin Part:=Opts;Opts:='';End
        Else Begin Part:=Copy(Opts,1,E-1);Opts:=Copy(Opts,E+1,255);End;
  Q:=Pos('=',Part);
  If Q>0Then Begin
   K:=LowerStr(Copy(Part,1,Q-1));
   V:=UrlDecode(Copy(Part,Q+1,255));
   If K='delimiter'Then Begin
    If V=''Then Begin End Else
    If V='\t'Then CsvDelim:=9
             Else CsvDelim:=Ord(V[1]);
   End Else
   If K='xfield'Then CsvXName:=V Else
   If K='yfield'Then CsvYName:=V Else
   If K='wktfield'Then CsvWName:=V Else
   If K='crs'Then Begin
    Begin If ParseCrsName(V,CsvCrs)Then Begin End;End;
   End;
  End;
 End;
 ParseDelimUri:=True;
End;

Var
 BandSel:Integer;
 ExprLayer:PJ;          { couche courante pour les expressions (derniere couche chargee) }
 ExprLayerName:String;

Function LoadWhole(Path:String;Var N:LongInt):PBytes;
Var
 B:PBytes;
Begin
 B:=LoadFileBytes(Path,N);
 If B=Nil Then Fail('Error: unable to open input file '+Path);
 LoadWhole:=B;
End;

{ ---- aiguillage selon le format ---- }

Function LoadLayer(FileName:String):PJ;
Var
 Path,LName,Subset,Ext:String;
 Root:PJ;
 B:PBytes;
 N,Sz:LongInt;
Begin
 FileName:=ResolveProject(FileName);
 ParseUri(FileName,Path,LName,Subset);
 If(Pos('dbname=',Path)>0)or(Copy(StrUpper(Path),1,3)='PG:')or(Copy(StrUpper(Path),1,9)='POSTGRES:')Then
  Fail('Error: PostGIS connections are not available in this clone');
 CsvDelim:=0;CsvXName:='';CsvYName:='';CsvWName:='';CsvCrs:=0;
 ParseDelimUri(Path);
 Ext:=FileExt(Path);
 If Ext='.SHP'Then Root:=LoadShapefile(Path) Else
 If(Ext='.GEOJSON')or(Ext='.JSON')or(Ext='')Then Root:=LoadGeoJSON(Path) Else
 If(Ext='.CSV')or(Ext='.TXT')or(Ext='.TSV')Then Begin
  B:=LoadWhole(Path,N);
  Root:=ReadCsv(B,N);
 End Else
 If(Ext='.GML')or(Ext='.XML')Then Begin
  B:=LoadWhole(Path,N);
  Root:=ReadGml(B,N);
 End Else
 If Ext='.KML'Then Begin
  B:=LoadWhole(Path,N);
  Root:=ReadKml(B,N);
 End Else
 If Ext='.KMZ'Then Begin
  B:=LoadWhole(Path,N);
  B:=ZipExtract(B,N,'.KML',Sz);
  If B=Nil Then Fail('Error: no .kml file in '+Path);
  Root:=ReadKml(B,Sz);
 End Else
 If Ext='.GPKG'Then Root:=LoadGpkg(Path,LName)
  Else
 Fail('Error: unsupported vector format "'+Ext+'" ('+Path+')');
 If Subset<>''Then ApplySubset(Root,Subset);
 ExprLayer:=Root;
 ExprLayerName:=BaseNoExt(Path);
 LoadLayer:=Root;
End;

Procedure SaveLayer(FileName:String;Root:PJ);
Var
 Path,LName,Subset,Ext:String;
Begin
 ParseUri(FileName,Path,LName,Subset);
 Ext:=FileExt(Path);
 If Ext='.SHP'Then SaveShapefile(Path,Root) Else
 If(Ext='.GEOJSON')or(Ext='.JSON')or(Ext='')Then SaveGeoJSON(Path,Root) Else
 If(Ext='.CSV')or(Ext='.TXT')Then SaveCsv(Path,Root) Else
 If(Ext='.GML')or(Ext='.XML')Then SaveGml(Path,Root) Else
 If Ext='.KML'Then SaveKml(Path,Root,False) Else
 If Ext='.KMZ'Then SaveKml(Path,Root,True) Else
 If Ext='.GPKG'Then SaveGpkg(Path,LName,Root)
  Else
 Fail('Error: unsupported output vector format "'+Ext+'" (use .geojson, .shp, .gpkg, .csv, .gml, .kml or .kmz)');
End;

{ ------------------------------------------------------------------ }
{ Moteur d'expressions                                                }
{ ------------------------------------------------------------------ }

Procedure ReadRaster(FileName:String;Var R:TRaster);Forward;

Var
 ExprS:String;
 ExprP:Integer;
 ExprProps:PJ;
 ExprFeat:PJ;
 ExprGeom:TGeom;
 ExprId:LongInt;
 ExprDepth:Integer;
 ExprParent:PJ;

Procedure EFail(Msg:String);Begin
 Fail('Error: invalid expression ('+Msg+') near position '+IntToStr(ExprP));
End;

Procedure ESkip;Begin
 While(ExprP<=Length(ExprS))and(ExprS[ExprP]in[' ',#9,#10,#13])do Inc(ExprP);
End;

Function EKw(Kw:String):Boolean;
Var
 L:Integer;
Begin
 ESkip;
 L:=Length(Kw);
 EKw:=False;
 If StrUpper(Copy(ExprS,ExprP,L))=Kw Then
  If(ExprP+L>Length(ExprS))or Not(UpCase(ExprS[ExprP+L])in['A'..'Z','0'..'9','_'])Then Begin
   Inc(ExprP,L);
   EKw:=True;
  End;
End;

Function EOp(Op:String):Boolean;Begin
 ESkip;
 EOp:=False;
 If Copy(ExprS,ExprP,Length(Op))=Op Then Begin
  Inc(ExprP,Length(Op));
  EOp:=True;
 End;
End;

Function NewV(K:Byte):TVal;
Var V:TVal;
Begin
 V.K:=K;V.N:=0;V.S:='';V.G:=Nil;V.L:=Nil;V.F:=Nil;
 NewV:=V;
End;

Function VNull:TVal;Begin VNull:=NewV(0);End;

Function VNum(R:Real):TVal;
Var V:TVal;
Begin V:=NewV(1);V.N:=R;VNum:=V;End;

Function VStr(S:String):TVal;
Var V:TVal;
Begin V:=NewV(2);V.S:=S;VStr:=V;End;

Function VBool(B:Boolean):TVal;
Var V:TVal;
Begin
 V:=NewV(3);
 If B Then V.N:=1;
 VBool:=V;
End;

{ Types dates : 7 date-heure, 8 date, 9 heure, 10 intervalle ; N en secondes depuis 1970 }
Function VTime(K:Byte;Secs:Real):TVal;
Var V:TVal;
Begin V:=NewV(K);V.N:=Secs;VTime:=V;End;

Function LNew:PValList;
Var L:PValList;
Begin
 New(L);
 L^.Cnt:=0;L^.Cap:=8;
 L^.V:=AllocBlock(8*SizeOf(TVal));
 LNew:=L;
End;

Procedure LAdd(L:PValList;Const V:TVal);
Var
 Q:PValArr;
Begin
 If L^.Cnt>=L^.Cap Then Begin
  Q:=AllocBlock(L^.Cap*2*SizeOf(TVal));
  Move(L^.V^,Q^,L^.Cnt*SizeOf(TVal));
  FreeMem(L^.V,L^.Cap*SizeOf(TVal));
  L^.V:=Q;L^.Cap:=L^.Cap*2;
 End;
 L^.V^[L^.Cnt]:=V;
 Inc(L^.Cnt);
End;

Function VList(L:PValList):TVal;
Var V:TVal;
Begin V:=NewV(5);V.L:=L;VList:=V;End;

Function VMapOf(L:PValList):TVal;
Var V:TVal;
Begin V:=NewV(6);V.L:=L;VMapOf:=V;End;

Function VFeat(F:PJ):TVal;
Var V:TVal;
Begin V:=NewV(11);V.F:=F;VFeat:=V;End;

Function IsNumKind(K:Byte):Boolean;Begin
 IsNumKind:=(K=1)or(K=3);
End;

Function IsTimeKind(K:Byte):Boolean;Begin
 IsTimeKind:=K in[7..10];
End;

{ ---- dates ---- }

Function DaysFromCivil(Y,M,D:LongInt):LongInt;
Var
 Era,Yoe,Doy,Doe:LongInt;
Begin
 If M<=2Then Y:=Y-1;
 If Y>=0Then Era:=Y div 400 Else Era:=(Y-399)div 400;
 Yoe:=Y-Era*400;
 If M>2Then Doy:=(153*(M-3)+2)div 5+D-1
       Else Doy:=(153*(M+9)+2)div 5+D-1;
 Doe:=Yoe*365+Yoe div 4-Yoe div 100+Doy;
 DaysFromCivil:=Era*146097+Doe-719468;
End;

Procedure CivilFromDays(Z:LongInt;Var Y,M,D:LongInt);
Var
 Era,Doe,Yoe,Doy,Mp:LongInt;
Begin
 Z:=Z+719468;
 If Z>=0Then Era:=Z div 146097 Else Era:=(Z-146096)div 146097;
 Doe:=Z-Era*146097;
 Yoe:=(Doe-Doe div 1460+Doe div 36524-Doe div 146096)div 365;
 Y:=Yoe+Era*400;
 Doy:=Doe-(365*Yoe+Yoe div 4-Yoe div 100);
 Mp:=(5*Doy+2)div 153;
 D:=Doy-(153*Mp+2)div 5+1;
 If Mp<10Then M:=Mp+3 Else M:=Mp-9;
 If M<=2Then Inc(Y);
End;

Function FloorDiv(A,B:Real):Real;Begin
 FloorDiv:=Int(A/B);
 If(A/B<0)and(Frac(A/B)<>0)Then FloorDiv:=Int(A/B)-1;
End;

Procedure SplitTime(T:Real;Var Y,Mo,D,H,Mi:LongInt;Var S:Real);
Var
 Days:Real;
 Z:LongInt;
 Rest:Real;
Begin
 Days:=FloorDiv(T,86400);
 Rest:=T-Days*86400;
 Z:=Round(Days);
 CivilFromDays(Z,Y,Mo,D);
 H:=Trunc(Rest/3600);
 Rest:=Rest-H*3600;
 Mi:=Trunc(Rest/60);
 S:=Rest-Mi*60;
End;

Function MakeTime(Y,Mo,D,H,Mi:LongInt;S:Real):Real;
Var
 T:Real;
Begin
 T:=DaysFromCivil(Y,Mo,D);
 T:=T*86400;
 T:=T+(H*3600+Mi*60);
 MakeTime:=T+S;
End;

Function DayOfWeek0(T:Real):Integer;
Var
 Days:LongInt;
Begin
 Days:=Round(FloorDiv(T,86400));
 DayOfWeek0:=((Days+4)mod 7+7)mod 7;
End;

Function IsoWeek(T:Real):Integer;
Var
 Y,Mo,D,H,Mi,Y2,Mo2,D2:LongInt;
 S:Real;
 Days,Wd,Th:LongInt;
Begin
 SplitTime(T,Y,Mo,D,H,Mi,S);
 Days:=DaysFromCivil(Y,Mo,D);
 Wd:=((Days+3)mod 7+7)mod 7;         { 0 = lundi }
 Th:=Days-Wd+3;                      { jeudi de la semaine }
 CivilFromDays(Th,Y2,Mo2,D2);
 IsoWeek:=(Th-DaysFromCivil(Y2,1,1))div 7+1;
End;

Function Num2(V:LongInt):String;
Var S:String;
Begin
 Str(V,S);
 If Length(S)<2Then S:='0'+S;
 Num2:=S;
End;

Function Num4(V:LongInt):String;
Var S:String;
Begin
 Str(V,S);
 While Length(S)<4do S:='0'+S;
 Num4:=S;
End;

Const
 MonthNames:Array[1..12]of String[9]=('January','February','March','April','May','June','July','August','September','October','November','December');
 DayNames:Array[0..6]of String[9]=('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');

Function FormatTime(T:Real;Fmt:String):String;
Var
 Y,Mo,D,H,Mi:LongInt;
 S:Real;
 R,Tk:String;
 I,J:Integer;
 H12:LongInt;

 Function Run(C:Char):Integer;
 Var K:Integer;
 Begin
  K:=0;
  While(I+K<=Length(Fmt))and(Fmt[I+K]=C)do Inc(K);
  Run:=K;
 End;

Begin
 SplitTime(T,Y,Mo,D,H,Mi,S);
 R:='';
 I:=1;
 H12:=H mod 12;
 If H12=0Then H12:=12;
 While I<=Length(Fmt)do Begin
  Case Fmt[I]of
   'y':Begin
    J:=Run('y');
    If J>=4Then R:=R+Num4(Y) Else R:=R+Num2(Y mod 100);
    Inc(I,J);
   End;
   'M':Begin
    J:=Run('M');
    If J=1Then R:=R+IntToStr(Mo) Else
    If J=2Then R:=R+Num2(Mo) Else
    If J=3Then R:=R+Copy(MonthNames[Mo],1,3)
          Else R:=R+MonthNames[Mo];
    Inc(I,J);
   End;
   'd':Begin
    J:=Run('d');
    If J=1Then R:=R+IntToStr(D) Else
    If J=2Then R:=R+Num2(D) Else
    If J=3Then R:=R+Copy(DayNames[DayOfWeek0(T)],1,3)
          Else R:=R+DayNames[DayOfWeek0(T)];
    Inc(I,J);
   End;
   'H':Begin J:=Run('H');If J=1Then R:=R+IntToStr(H) Else R:=R+Num2(H);Inc(I,J);End;
   'h':Begin J:=Run('h');If J=1Then R:=R+IntToStr(H12) Else R:=R+Num2(H12);Inc(I,J);End;
   'm':Begin J:=Run('m');If J=1Then R:=R+IntToStr(Mi) Else R:=R+Num2(Mi);Inc(I,J);End;
   's':Begin J:=Run('s');If J=1Then R:=R+IntToStr(Trunc(S)) Else R:=R+Num2(Trunc(S));Inc(I,J);End;
   'z':Begin
    J:=Run('z');
    Tk:=IntToStr(Round((S-Int(S))*1000));
    While Length(Tk)<3do Tk:='0'+Tk;
    If J=1Then R:=R+IntToStr(Round((S-Int(S))*1000)) Else R:=R+Tk;
    Inc(I,J);
   End;
   'A':Begin
    J:=Run('A');
    If H<12Then R:=R+'AM' Else R:=R+'PM';
    Inc(I,J);
   End;
   'a':Begin
    J:=Run('a');
    If H<12Then R:=R+'am' Else R:=R+'pm';
    Inc(I,J);
   End;
   '''':Begin
    Inc(I);
    While(I<=Length(Fmt))and(Fmt[I]<>'''')do Begin R:=R+Fmt[I];Inc(I);End;
    Inc(I);
   End;
   Else Begin R:=R+Fmt[I];Inc(I);End;
  End;
 End;
 FormatTime:=R;
End;

Function TimeToText(K:Byte;T:Real):String;
Var
 Y,Mo,D,H,Mi:LongInt;
 S:Real;
 St:String;
Begin
 SplitTime(T,Y,Mo,D,H,Mi,S);
 St:=Num2(Trunc(S));
 If Frac(S)>0.0005Then Begin
  St:=St+'.'+Copy(IntToStr(1000+Round(Frac(S)*1000)),2,3);
 End;
 Case K of
  8:TimeToText:=Num4(Y)+'-'+Num2(Mo)+'-'+Num2(D);
  9:TimeToText:=Num2(H)+':'+Num2(Mi)+':'+St;
  Else TimeToText:=Num4(Y)+'-'+Num2(Mo)+'-'+Num2(D)+'T'+Num2(H)+':'+Num2(Mi)+':'+St;
 End;
End;

{ Lit "AAAA-MM-JJ", "AAAA-MM-JJ HH:MM:SS(.fff)", "HH:MM:SS" ; Kind recoit 7, 8 ou 9 }
Function ParseTime(S:String;Var T:Real;Var Kind:Byte):Boolean;
Var
 P,Err:Integer;
 Y,Mo,D,H,Mi:LongInt;
 Sc:Real;
 A,B:String;
 HaveD,HaveT:Boolean;

 Function Part(Var Src:String;Sep:Char;Var V:LongInt):Boolean;
 Var
  Q,E:Integer;
  Tk:String;
 Begin
  Q:=Pos(Sep,Src);
  If Q=0Then Begin Tk:=Src;Src:='';End
        Else Begin Tk:=Copy(Src,1,Q-1);Src:=Copy(Src,Q+1,255);End;
  Val(Tk,V,E);
  Part:=(E=0)and(Tk<>'');
 End;

Begin
 ParseTime:=False;
 While(S<>'')and(S[1]=' ')do Delete(S,1,1);
 While(S<>'')and(S[Length(S)]=' ')do Delete(S,Length(S),1);
 If S=''Then Exit;
 HaveD:=False;HaveT:=False;
 Y:=1970;Mo:=1;D:=1;H:=0;Mi:=0;Sc:=0;
 P:=Pos('T',S);
 If P=0Then P:=Pos(' ',S);
 If P>0Then Begin A:=Copy(S,1,P-1);B:=Copy(S,P+1,255);End
  Else If Pos(':',S)>0Then Begin A:='';B:=S;End
  Else Begin A:=S;B:='';End;
 If A<>''Then Begin
  For P:=1 to Length(A)do If A[P]='/'Then A[P]:='-';
  If Not Part(A,'-',Y)Then Exit;
  If Not Part(A,'-',Mo)Then Exit;
  If Not Part(A,'-',D)Then Exit;
  If(Mo<1)or(Mo>12)or(D<1)or(D>31)Then Exit;
  HaveD:=True;
 End;
 If B<>''Then Begin
  P:=Pos('Z',B);If P>0Then B:=Copy(B,1,P-1);
  P:=Pos('+',B);If P>0Then B:=Copy(B,1,P-1);
  If Not Part(B,':',H)Then Exit;
  If B<>''Then Begin
   If Not Part(B,':',Mi)Then Exit;
   If B<>''Then Begin
    Val(B,Sc,Err);
    If Err<>0Then Exit;
   End;
  End;
  If(H<0)or(H>23)or(Mi<0)or(Mi>59)Then Exit;
  HaveT:=True;
 End;
 If HaveD and HaveT Then Kind:=7 Else
 If HaveD Then Kind:=8 Else
 If HaveT Then Kind:=9
          Else Exit;
 T:=MakeTime(Y,Mo,D,H,Mi,Sc);
 ParseTime:=True;
End;

{ Lit un texte selon un format (yyyy MM dd HH mm ss zzz MMM MMMM AP) }
Function ParseTimeFormat(S,Fmt:String;Var T:Real;Var Kind:Byte):Boolean;
Var
 I,J,P,K,Run:Integer;
 Y,Mo,D,H,Mi,Ms:LongInt;
 Sc:Real;
 HaveD,HaveT,Pm,HasAp:Boolean;
 C:Char;
 Num:String;
 Found:Boolean;

 Function ReadNum(MaxLen:Integer;Var V:LongInt):Boolean;
 Var
  E:Integer;
 Begin
  Num:='';
  While(P<=Length(S))and(S[P]in['0'..'9'])and(Length(Num)<MaxLen)do Begin Num:=Num+S[P];Inc(P);End;
  Val(Num,V,E);
  ReadNum:=(Num<>'')and(E=0);
 End;

Begin
 ParseTimeFormat:=False;
 Y:=1970;Mo:=1;D:=1;H:=0;Mi:=0;Sc:=0;Ms:=0;
 HaveD:=False;HaveT:=False;Pm:=False;HasAp:=False;
 I:=1;P:=1;
 While I<=Length(Fmt)do Begin
  C:=Fmt[I];
  Run:=0;
  While(I+Run<=Length(Fmt))and(Fmt[I+Run]=C)do Inc(Run);
  Case C of
   'y':Begin
    If Run>=4Then Begin If Not ReadNum(4,Y)Then Exit;End
     Else Begin If Not ReadNum(2,Y)Then Exit;If Y<70Then Y:=Y+2000 Else Y:=Y+1900;End;
    HaveD:=True;
   End;
   'M':Begin
    If Run>=3Then Begin
     Found:=False;
     For K:=1 to 12do
      If(Run=3)and(StrUpper(Copy(S,P,3))=StrUpper(Copy(MonthNames[K],1,3)))Then Begin Mo:=K;Inc(P,3);Found:=True;Break;End Else
      If(Run>3)and(StrUpper(Copy(S,P,Length(MonthNames[K])))=StrUpper(MonthNames[K]))Then Begin Mo:=K;Inc(P,Length(MonthNames[K]));Found:=True;Break;End;
     If Not Found Then Exit;
    End
     Else If Not ReadNum(2,Mo)Then Exit;
    HaveD:=True;
   End;
   'd':Begin
    If Run>=3Then Begin
     While(P<=Length(S))and(UpCase(S[P])in['A'..'Z'])do Inc(P);
    End
     Else Begin If Not ReadNum(2,D)Then Exit;HaveD:=True;End;
   End;
   'H','h':Begin If Not ReadNum(2,H)Then Exit;HaveT:=True;End;
   'm':Begin If Not ReadNum(2,Mi)Then Exit;HaveT:=True;End;
   's':Begin If Not ReadNum(2,Ms)Then Exit;Sc:=Ms;HaveT:=True;End;
   'z':Begin If Not ReadNum(3,Ms)Then Exit;Sc:=Sc+Ms/1000;End;
   'A','a':Begin
    HasAp:=True;
    If StrUpper(Copy(S,P,2))='PM'Then Pm:=True Else If StrUpper(Copy(S,P,2))<>'AM'Then Exit;
    Inc(P,2);
    Run:=1;
    If(I<Length(Fmt))and(UpCase(Fmt[I+1])='P')Then Run:=2;
   End;
   '''':Begin
    J:=I+1;
    While(J<=Length(Fmt))and(Fmt[J]<>'''')do Begin
     If(P>Length(S))or(S[P]<>Fmt[J])Then Exit;
     Inc(P);Inc(J);
    End;
    Run:=J-I+1;
   End;
   Else Begin
    If(P>Length(S))or(S[P]<>C)Then Exit;
    Inc(P);
   End;
  End;
  If C in['y','M','d','H','h','m','s','z','A','a','''']Then Inc(I,Run) Else Inc(I);
 End;
 If HasAp Then Begin
  If(H=12)and Not Pm Then H:=0 Else If(H<12)and Pm Then H:=H+12;
 End;
 If(Mo<1)or(Mo>12)or(D<1)or(D>31)or(H>23)or(Mi>59)Then Exit;
 If HaveD and HaveT Then Kind:=7 Else If HaveD Then Kind:=8 Else If HaveT Then Kind:=9 Else Exit;
 T:=MakeTime(Y,Mo,D,H,Mi,Sc);
 ParseTimeFormat:=True;
End;

Function NowSecs:Real;
Var
 Y,Mo,D,Dw,H,Mi,S,S1:Word;
Begin
 GetDate(Y,Mo,D,Dw);
 GetTime(H,Mi,S,S1);
 NowSecs:=MakeTime(Y,Mo,D,H,Mi,S+S1/100);
End;

{ Intervalle depuis "1 day 2 hours" / "3 weeks" }
Function ParseInterval(S:String;Var T:Real):Boolean;
Var
 Rest,W,U:String;
 V:Real;
 Err:Integer;
 Any:Boolean;
Begin
 ParseInterval:=False;
 T:=0;Any:=False;
 Rest:=S;
 While Rest<>''do Begin
  W:=NextWord(Rest);
  If W=''Then Continue;
  Val(W,V,Err);
  If Err<>0Then Exit;
  U:=LowerStr(NextWord(Rest));
  If(U='year')or(U='years')Then T:=T+V*365.25*86400 Else
  If(U='month')or(U='months')Then T:=T+V*30*86400 Else
  If(U='week')or(U='weeks')Then T:=T+V*7*86400 Else
  If(U='day')or(U='days')Then T:=T+V*86400 Else
  If(U='hour')or(U='hours')Then T:=T+V*3600 Else
  If(U='minute')or(U='minutes')or(U='min')Then T:=T+V*60 Else
  If(U='second')or(U='seconds')or(U='sec')Then T:=T+V
   Else Exit;
  Any:=True;
 End;
 ParseInterval:=Any;
End;

{ ---- conversions ---- }

Function ValJson(V:TVal):String;Forward;

Function ToNum(V:TVal;Var R:Real):Boolean;
Var
 E:Integer;
Begin
 ToNum:=False;
 Case V.K of
  1,3,7,8,9,10:Begin R:=V.N;ToNum:=True;End;
  2:Begin
   Val(V.S,R,E);
   ToNum:=(E=0)and(V.S<>'');
  End;
 End;
End;

Function ToStr(V:TVal):String;Begin
 Case V.K of
  1:ToStr:=NumStr(V.N);
  2:ToStr:=V.S;
  3:If V.N<>0Then ToStr:='true' Else ToStr:='false';
  5,6:ToStr:=ValJson(V);
  7,8,9:ToStr:=TimeToText(V.K,V.N);
  10:ToStr:=NumStr(V.N);
  Else ToStr:='';
 End;
End;

Function JsonQuote(S:String):String;
Var
 I:Integer;
 R:String;
Begin
 R:='"';
 For I:=1 to Length(S)do Begin
  If Length(R)>=250Then Break;
  Case S[I]of
   '"':R:=R+'\"';
   '\':R:=R+'\\';
   #10:R:=R+'\n';
   #13:R:=R+'\r';
   #9:R:=R+'\t';
   Else If S[I]>=' 'Then R:=R+S[I];
  End;
 End;
 JsonQuote:=R+'"';
End;

Function ValJson(V:TVal):String;
Var
 I:LongInt;
 R:String;
Begin
 Case V.K of
  0:ValJson:='null';
  1:ValJson:=NumStr(V.N);
  2:ValJson:=JsonQuote(V.S);
  3:If V.N<>0Then ValJson:='true' Else ValJson:='false';
  5:Begin
   R:='[';
   For I:=0 to V.L^.Cnt-1do Begin
    If I>0Then R:=R+',';
    If Length(R)<230Then R:=R+ValJson(V.L^.V^[I]);
   End;
   ValJson:=R+']';
  End;
  6:Begin
   R:='{';
   I:=0;
   While I+1<V.L^.Cnt do Begin
    If I>0Then R:=R+',';
    If Length(R)<230Then R:=R+JsonQuote(ToStr(V.L^.V^[I]))+':'+ValJson(V.L^.V^[I+1]);
    Inc(I,2);
   End;
   ValJson:=R+'}';
  End;
  7,8,9:ValJson:=JsonQuote(TimeToText(V.K,V.N));
  10:ValJson:=NumStr(V.N);
  Else ValJson:='null';
 End;
End;

{ Ordre de deux valeurs (nombres avant le texte) }
Function CmpVal(A,B:TVal):Integer;
Var
 Ra,Rb:Real;
 Sa,Sb:String;
Begin
 If(A.K=0)and(B.K=0)Then Begin CmpVal:=0;Exit;End;
 If A.K=0Then Begin CmpVal:=-1;Exit;End;
 If B.K=0Then Begin CmpVal:=1;Exit;End;
 If(A.K<>2)and(B.K<>2)and ToNum(A,Ra)and ToNum(B,Rb)Then Begin CmpVal:=CmpR(Ra,Rb);Exit;End;
 If(A.K=2)and(B.K=2)Then Begin
  If A.S<B.S Then CmpVal:=-1 Else If A.S>B.S Then CmpVal:=1 Else CmpVal:=0;
  Exit;
 End;
 If ToNum(A,Ra)and ToNum(B,Rb)Then Begin CmpVal:=CmpR(Ra,Rb);Exit;End;
 Sa:=ToStr(A);Sb:=ToStr(B);
 If Sa<Sb Then CmpVal:=-1 Else If Sa>Sb Then CmpVal:=1 Else CmpVal:=0;
End;

Function ValEq(A,B:TVal):Boolean;
Var
 I:LongInt;
Begin
 ValEq:=False;
 If(A.K=5)and(B.K=5)Then Begin
  If A.L^.Cnt<>B.L^.Cnt Then Exit;
  For I:=0 to A.L^.Cnt-1do If Not ValEq(A.L^.V^[I],B.L^.V^[I])Then Exit;
  ValEq:=True;
  Exit;
 End;
 If(A.K=0)or(B.K=0)Then Begin ValEq:=(A.K=0)and(B.K=0);Exit;End;
 ValEq:=CmpVal(A,B)=0;
End;

{ ---- expressions regulieres (retour arriere) ---- }

Function LowerCase1(C:Char):Char;Begin
 If C in['A'..'Z']Then LowerCase1:=Chr(Ord(C)+32) Else LowerCase1:=C;
End;



Const
 MaxRx=300;

Type
 TByteSet=Set of Byte;
 TRxNode=Record
  Typ:Byte;       { 0 nop, 1 car, 2 tout, 3 classe, 4 debut, 5 fin, 6 ouvre, 7 ferme, 8 alternative,
                    9 repetition simple, 10 fin de repetition, 11 limite de mot, 12 non limite, 13 succes,
                    14 repetition de groupe }
  Ch:Byte;
  SetI:Integer;
  Next:Integer;
  A,B:Integer;
  Min,Max:Integer;
  Lazy:Boolean;
  Grp:Integer;
 End;

Var
 Rx:Array[0..MaxRx]of TRxNode;
 RxN:Integer;
 RxSets:Array[0..39]of TByteSet;
 RxSetN:Integer;
 RxPat:String;
 RxPos:Integer;
 RxGroups:Integer;
 RxCapS,RxCapE:Array[0..9]of Integer;
 RxSub:String;
 RxStart:Integer;
 RxCnt,RxLast:Array[0..MaxRx]of Integer;
 RxCache:String;
 RxSteps:LongInt;

Procedure RxFail;Begin
 Fail('Error: invalid regular expression "'+RxPat+'"');
End;

Function RxNew(Typ:Byte):Integer;Begin
 If RxN>=MaxRx Then RxFail;
 Inc(RxN);
 FillChar(Rx[RxN],SizeOf(TRxNode),0);
 Rx[RxN].Typ:=Typ;
 Rx[RxN].Next:=0;
 RxNew:=RxN;
End;

Procedure RxAddEsc(Var S:TByteSet;C:Char);
Var
 I:Integer;
Begin
 Case C of
  'd':For I:=48 to 57do Include(S,I);
  'w':Begin
   For I:=48 to 57do Include(S,I);
   For I:=65 to 90do Include(S,I);
   For I:=97 to 122do Include(S,I);
   Include(S,95);
  End;
  's':Begin Include(S,32);Include(S,9);Include(S,10);Include(S,13);Include(S,11);Include(S,12);End;
 End;
End;

Function RxEscChar(C:Char):Byte;Begin
 Case C of
  'n':RxEscChar:=10;
  't':RxEscChar:=9;
  'r':RxEscChar:=13;
  Else RxEscChar:=Ord(C);
 End;
End;

Procedure RxAlt(Var S,T:Integer);Forward;

Procedure RxAtom(Var S,T:Integer);
Var
 C:Char;
 N,I:Integer;
 Neg:Boolean;
 Cur:TByteSet;
 Lo,Hi:Integer;
 Tmp:TByteSet;
 G,S2,T2,O,Cl:Integer;
 K:Integer;
 Mn,Mx:Integer;
 Lazy:Boolean;
 R,E:Integer;
 Err:Integer;
 Num:String;
Begin
 C:=RxPat[RxPos];
 Inc(RxPos);
 Case C of
  '.':Begin N:=RxNew(2);S:=N;T:=N;End;
  '^':Begin N:=RxNew(4);S:=N;T:=N;End;
  '$':Begin N:=RxNew(5);S:=N;T:=N;End;
  '(':Begin
   G:=-1;
   If(RxPos+1<=Length(RxPat))and(RxPat[RxPos]='?')and(RxPat[RxPos+1]=':')Then Inc(RxPos,2)
    Else Begin
     Inc(RxGroups);
     If RxGroups>9Then RxFail;
     G:=RxGroups;
    End;
   RxAlt(S2,T2);
   If(RxPos>Length(RxPat))or(RxPat[RxPos]<>')')Then RxFail;
   Inc(RxPos);
   If G>=0Then Begin
    O:=RxNew(6);Cl:=RxNew(7);
    Rx[O].Grp:=G;Rx[Cl].Grp:=G;
    Rx[O].Next:=S2;Rx[T2].Next:=Cl;
    S:=O;T:=Cl;
   End
    Else Begin S:=S2;T:=T2;End;
  End;
  '[':Begin
   Cur:=[];
   Neg:=False;
   If(RxPos<=Length(RxPat))and(RxPat[RxPos]='^')Then Begin Neg:=True;Inc(RxPos);End;
   K:=0;
   While True do Begin
    If RxPos>Length(RxPat)Then RxFail;
    C:=RxPat[RxPos];
    If(C=']')and(K>0)Then Begin Inc(RxPos);Break;End;
    Inc(K);
    Inc(RxPos);
    If C='\'Then Begin
     If RxPos>Length(RxPat)Then RxFail;
     C:=RxPat[RxPos];Inc(RxPos);
     If C in['d','w','s']Then Begin RxAddEsc(Cur,C);Continue;End;
     If C in['D','W','S']Then Begin
      Tmp:=[];
      RxAddEsc(Tmp,LowerCase1(C));
      For I:=0 to 255do If Not(I in Tmp)Then Include(Cur,I);
      Continue;
     End;
     Lo:=RxEscChar(C);
    End
     Else Lo:=Ord(C);
    Hi:=Lo;
    If(RxPos+1<=Length(RxPat))and(RxPat[RxPos]='-')and(RxPat[RxPos+1]<>']')Then Begin
     Inc(RxPos);
     C:=RxPat[RxPos];Inc(RxPos);
     If C='\'Then Begin C:=RxPat[RxPos];Inc(RxPos);Hi:=RxEscChar(C);End
             Else Hi:=Ord(C);
    End;
    For I:=Lo to Hi do Include(Cur,I);
   End;
   If Neg Then Begin
    Tmp:=Cur;Cur:=[];
    For I:=0 to 255do If Not(I in Tmp)Then Include(Cur,I);
   End;
   If RxSetN>=39Then RxFail;
   Inc(RxSetN);
   RxSets[RxSetN]:=Cur;
   N:=RxNew(3);Rx[N].SetI:=RxSetN;S:=N;T:=N;
  End;
  '\':Begin
   If RxPos>Length(RxPat)Then RxFail;
   C:=RxPat[RxPos];Inc(RxPos);
   If C in['d','w','s','D','W','S']Then Begin
    Cur:=[];
    If C in['d','w','s']Then RxAddEsc(Cur,C)
     Else Begin
      Tmp:=[];
      RxAddEsc(Tmp,LowerCase1(C));
      For I:=0 to 255do If Not(I in Tmp)Then Include(Cur,I);
     End;
    If RxSetN>=39Then RxFail;
    Inc(RxSetN);
    RxSets[RxSetN]:=Cur;
    N:=RxNew(3);Rx[N].SetI:=RxSetN;
   End Else
   If C='b'Then N:=RxNew(11) Else
   If C='B'Then N:=RxNew(12)
    Else Begin N:=RxNew(1);Rx[N].Ch:=RxEscChar(C);End;
   S:=N;T:=N;
  End;
  '*','+','?':RxFail;
  Else Begin N:=RxNew(1);Rx[N].Ch:=Ord(C);S:=N;T:=N;End;
 End;
 { quantificateur }
 If RxPos<=Length(RxPat)Then Begin
  C:=RxPat[RxPos];
  Mn:=-1;Mx:=-1;
  If C='*'Then Begin Mn:=0;Mx:=32000;Inc(RxPos);End Else
  If C='+'Then Begin Mn:=1;Mx:=32000;Inc(RxPos);End Else
  If C='?'Then Begin Mn:=0;Mx:=1;Inc(RxPos);End Else
  If C='{'Then Begin
   K:=RxPos+1;
   Num:='';
   While(K<=Length(RxPat))and(RxPat[K]in['0'..'9'])do Begin Num:=Num+RxPat[K];Inc(K);End;
   If(Num<>'')and(K<=Length(RxPat))Then Begin
    Val(Num,Mn,Err);
    If RxPat[K]='}'Then Begin Mx:=Mn;RxPos:=K+1;End Else
    If RxPat[K]=','Then Begin
     Inc(K);Num:='';
     While(K<=Length(RxPat))and(RxPat[K]in['0'..'9'])do Begin Num:=Num+RxPat[K];Inc(K);End;
     If(K<=Length(RxPat))and(RxPat[K]='}')Then Begin
      If Num=''Then Mx:=32000 Else Val(Num,Mx,Err);
      RxPos:=K+1;
     End
      Else Mn:=-1;
    End
     Else Mn:=-1;
   End;
  End;
  If Mn>=0Then Begin
   Lazy:=False;
   If(RxPos<=Length(RxPat))and(RxPat[RxPos]='?')Then Begin Lazy:=True;Inc(RxPos);End;
   If Rx[S].Typ in[1,2,3]Then Begin
    If S<>T Then RxFail;
    R:=RxNew(9);
    Rx[R].A:=S;Rx[R].Min:=Mn;Rx[R].Max:=Mx;Rx[R].Lazy:=Lazy;
    S:=R;T:=R;
   End
    Else
   Begin
    R:=RxNew(14);E:=RxNew(10);
    Rx[R].A:=S;Rx[R].Min:=Mn;Rx[R].Max:=Mx;Rx[R].Lazy:=Lazy;
    Rx[E].A:=R;
    Rx[T].Next:=E;
    S:=R;T:=R;
   End;
  End;
 End;
End;

Procedure RxSeq(Var S,T:Integer);
Var
 S1,T1:Integer;
 First:Boolean;
Begin
 First:=True;
 S:=RxNew(0);T:=S;
 While(RxPos<=Length(RxPat))and(RxPat[RxPos]<>'|')and(RxPat[RxPos]<>')')do Begin
  RxAtom(S1,T1);
  Rx[T].Next:=S1;
  T:=T1;
 End;
End;

Procedure RxAlt(Var S,T:Integer);
Var
 S1,T1,J,A1,Prev:Integer;
 Starts:Array[1..16]of Integer;
 Tails:Array[1..16]of Integer;
 N,I:Integer;
Begin
 N:=0;
 Repeat
  RxSeq(S1,T1);
  Inc(N);
  If N>16Then RxFail;
  Starts[N]:=S1;Tails[N]:=T1;
  If(RxPos<=Length(RxPat))and(RxPat[RxPos]='|')Then Begin Inc(RxPos);End
   Else Break;
 Until False;
 If N=1Then Begin S:=Starts[1];T:=Tails[1];Exit;End;
 J:=RxNew(0);
 For I:=1 to N do Rx[Tails[I]].Next:=J;
 Prev:=Starts[N];
 For I:=N-1downto 1do Begin
  A1:=RxNew(8);
  Rx[A1].A:=Starts[I];Rx[A1].B:=Prev;
  Prev:=A1;
 End;
 S:=Prev;T:=J;
End;

Function RxWord(P:Integer):Boolean;Begin
 RxWord:=(P>=1)and(P<=Length(RxSub))and(RxSub[P]in['0'..'9','A'..'Z','a'..'z','_']);
End;

Function RxM(N:Integer;P:Integer):Boolean;Forward;

Function RxTest(R:Integer;P:Integer):Boolean;
Var
 C,Old:Integer;
Begin
 C:=RxCnt[R];
 If C<Rx[R].Min Then Begin RxTest:=RxM(Rx[R].A,P);Exit;End;
 If C>=Rx[R].Max Then Begin RxTest:=RxM(Rx[R].Next,P);Exit;End;
 Old:=RxLast[R];
 If Rx[R].Lazy Then Begin
  If RxM(Rx[R].Next,P)Then Begin RxTest:=True;Exit;End;
  If P=Old Then Begin RxTest:=False;Exit;End;
  RxLast[R]:=P;
  RxTest:=RxM(Rx[R].A,P);
  RxLast[R]:=Old;
 End
  Else
 Begin
  If P<>Old Then Begin
   RxLast[R]:=P;
   If RxM(Rx[R].A,P)Then Begin RxLast[R]:=Old;RxTest:=True;Exit;End;
   RxLast[R]:=Old;
  End;
  RxTest:=RxM(Rx[R].Next,P);
 End;
End;

Function RxOne(N:Integer;P:Integer):Boolean;Begin
 RxOne:=False;
 If P>Length(RxSub)Then Exit;
 Case Rx[N].Typ of
  1:RxOne:=Ord(RxSub[P])=Rx[N].Ch;
  2:RxOne:=RxSub[P]<>#10;
  3:RxOne:=Ord(RxSub[P])in RxSets[Rx[N].SetI];
 End;
End;

Function RxM(N:Integer;P:Integer):Boolean;
Var
 K,J,Mx,OldC,OldL,Old:Integer;
 Res:Boolean;
Begin
 RxM:=False;
 Inc(RxSteps);
 If RxSteps>2000000Then Begin RxM:=False;Exit;End;
 While True do Begin
  If N=0Then Begin RxM:=False;Exit;End;
  Case Rx[N].Typ of
   0:N:=Rx[N].Next;
   13:Begin RxCapE[0]:=P;RxM:=True;Exit;End;
   1,2,3:Begin
    If Not RxOne(N,P)Then Exit;
    Inc(P);N:=Rx[N].Next;
   End;
   4:Begin If P<>1Then Exit;N:=Rx[N].Next;End;
   5:Begin If P<>Length(RxSub)+1Then Exit;N:=Rx[N].Next;End;
   11:Begin
    If RxWord(P-1)=RxWord(P)Then Exit;
    N:=Rx[N].Next;
   End;
   12:Begin
    If RxWord(P-1)<>RxWord(P)Then Exit;
    N:=Rx[N].Next;
   End;
   6:Begin
    Old:=RxCapS[Rx[N].Grp];
    RxCapS[Rx[N].Grp]:=P;
    If RxM(Rx[N].Next,P)Then Begin RxM:=True;Exit;End;
    RxCapS[Rx[N].Grp]:=Old;
    Exit;
   End;
   7:Begin
    Old:=RxCapE[Rx[N].Grp];
    RxCapE[Rx[N].Grp]:=P;
    If RxM(Rx[N].Next,P)Then Begin RxM:=True;Exit;End;
    RxCapE[Rx[N].Grp]:=Old;
    Exit;
   End;
   8:Begin
    If RxM(Rx[N].A,P)Then Begin RxM:=True;Exit;End;
    N:=Rx[N].B;
   End;
   9:Begin
    Mx:=0;
    While(Mx<Rx[N].Max)and RxOne(Rx[N].A,P+Mx)do Inc(Mx);
    If Mx<Rx[N].Min Then Exit;
    If Rx[N].Lazy Then Begin
     For J:=Rx[N].Min to Mx do If RxM(Rx[N].Next,P+J)Then Begin RxM:=True;Exit;End;
    End
     Else
    For J:=Mx downto Rx[N].Min do If RxM(Rx[N].Next,P+J)Then Begin RxM:=True;Exit;End;
    Exit;
   End;
   14:Begin
    OldC:=RxCnt[N];OldL:=RxLast[N];
    RxCnt[N]:=0;RxLast[N]:=-1;
    Res:=RxTest(N,P);
    RxCnt[N]:=OldC;RxLast[N]:=OldL;
    RxM:=Res;
    Exit;
   End;
   10:Begin
    K:=Rx[N].A;
    Inc(RxCnt[K]);
    Res:=RxTest(K,P);
    If Not Res Then Dec(RxCnt[K]);
    RxM:=Res;
    Exit;
   End;
   Else Exit;
  End;
 End;
End;

{ Compile Pat ; le noeud 1 est le debut du motif }
Procedure RxCompile(Pat:String);
Var
 S,T,Fin:Integer;
Begin
 If(Pat=RxCache)and(RxN>0)Then Exit;
 RxPat:=Pat;
 RxPos:=1;RxN:=0;RxSetN:=0;RxGroups:=0;
 RxAlt(S,T);
 If RxPos<=Length(Pat)Then RxFail;
 Fin:=RxNew(13);
 Rx[T].Next:=Fin;
 Rx[0].Next:=S;
 RxCache:=Pat;
End;

{ Cherche a partir de From (base 1) ; RxCapS/E[0..RxGroups] sont renseignes }
Function RxFind(Const Subj:String;From:Integer):Boolean;
Var
 P,I:Integer;
Begin
 RxFind:=False;
 RxSub:=Subj;
 RxSteps:=0;
 For P:=From to Length(Subj)+1do Begin
  For I:=0 to 9do Begin RxCapS[I]:=0;RxCapE[I]:=0;End;
  RxCapS[0]:=P;
  If RxM(Rx[0].Next,P)Then Begin RxFind:=True;Exit;End;
 End;
End;

Function RxGroupText(K:Integer):String;Begin
 If(RxCapS[K]>0)and(RxCapE[K]>=RxCapS[K])Then RxGroupText:=Copy(RxSub,RxCapS[K],RxCapE[K]-RxCapS[K])
                                         Else RxGroupText:='';
End;

{ ---- utilitaires pour les fonctions ---- }

Function Trim1(S:String):String;Begin
 While(S<>'')and(S[1]in[' ',#9,#10,#13])do Delete(S,1,1);
 While(S<>'')and(S[Length(S)]in[' ',#9,#10,#13])do Delete(S,Length(S),1);
 Trim1:=S;
End;

Function Acos(X:Real):Real;Begin
 Acos:=Atan2(Sqrt(MaxR(0,1-X*X)),X);
End;

Function RoundHalf(R:Real):Real;Begin
 If R>=0Then RoundHalf:=FloorR(R+0.5) Else RoundHalf:=-FloorR(-R+0.5);
End;

{ Longueur et extraction en caracteres UTF-8 }
Function U8Len(Const S:String):Integer;
Var
 I,N:Integer;
Begin
 N:=0;
 For I:=1 to Length(S)do If(Ord(S[I])and $C0)<>$80Then Inc(N);
 U8Len:=N;
End;

{ Octet de debut du I-eme caractere (base 1) ; Length(S)+1 si au dela }
Function U8Pos(Const S:String;I:LongInt):Integer;
Var
 K,N:Integer;
Begin
 N:=0;
 For K:=1 to Length(S)do Begin
  If(Ord(S[K])and $C0)<>$80Then Begin
   Inc(N);
   If N=I Then Begin U8Pos:=K;Exit;End;
  End;
 End;
 U8Pos:=Length(S)+1;
End;

Function U8Copy(Const S:String;Start,Len:LongInt):String;
Var
 A,B:Integer;
Begin
 If Start<1Then Start:=1;
 If Len<=0Then Begin U8Copy:='';Exit;End;
 A:=U8Pos(S,Start);
 B:=U8Pos(S,Start+Len);
 U8Copy:=Copy(S,A,B-A);
End;

Function U8Chr(V:LongInt):String;Begin
 If V<128Then U8Chr:=Chr(V) Else
 If V<2048Then U8Chr:=Chr(192+(V shr 6))+Chr(128+(V and 63)) Else
 If V<65536Then U8Chr:=Chr(224+(V shr 12))+Chr(128+((V shr 6)and 63))+Chr(128+(V and 63))
 Else U8Chr:=Chr(240+(V shr 18))+Chr(128+((V shr 12)and 63))+Chr(128+((V shr 6)and 63))+Chr(128+(V and 63));
End;

Function U8Upper(S:String;Up:Boolean):String;
Var
 I:Integer;
 R:String;
Begin
 R:='';
 I:=1;
 While I<=Length(S)do Begin
  If(S[I]=#$C3)and(I<Length(S))Then Begin
   If Up and(Ord(S[I+1])>=$A0)and(Ord(S[I+1])<=$BE)and(Ord(S[I+1])<>$B7)Then R:=R+#$C3+Chr(Ord(S[I+1])-$20) Else
   If(Not Up)and(Ord(S[I+1])>=$80)and(Ord(S[I+1])<=$9E)and(Ord(S[I+1])<>$97)Then R:=R+#$C3+Chr(Ord(S[I+1])+$20)
   Else R:=R+S[I]+S[I+1];
   Inc(I,2);
  End
   Else
  Begin
   If Up and(S[I]in['a'..'z'])Then R:=R+Chr(Ord(S[I])-32) Else
   If(Not Up)and(S[I]in['A'..'Z'])Then R:=R+Chr(Ord(S[I])+32)
   Else R:=R+S[I];
   Inc(I);
  End;
 End;
 U8Upper:=R;
End;

Function Levenshtein(Const A,B:String):Integer;
Var
 D:Array[0..255]of Integer;
 I,J,Prev,Cur,Tmp:Integer;
Begin
 For J:=0 to Length(B)do D[J]:=J;
 For I:=1 to Length(A)do Begin
  Prev:=D[0];
  D[0]:=I;
  For J:=1 to Length(B)do Begin
   Tmp:=D[J];
   If A[I]=B[J]Then Cur:=Prev Else Cur:=Prev+1;
   If D[J]+1<Cur Then Cur:=D[J]+1;
   If D[J-1]+1<Cur Then Cur:=D[J-1]+1;
   D[J]:=Cur;
   Prev:=Tmp;
  End;
 End;
 Levenshtein:=D[Length(B)];
End;

Function Soundex(S:String):String;
Var
 R:String;
 I:Integer;
 C,Last,Cd:Char;

 Function Code(Ch:Char):Char;Begin
  Case Ch of
   'B','F','P','V':Code:='1';
   'C','G','J','K','Q','S','X','Z':Code:='2';
   'D','T':Code:='3';
   'L':Code:='4';
   'M','N':Code:='5';
   'R':Code:='6';
   Else Code:='0';
  End;
 End;

Begin
 R:='';
 Last:='0';
 For I:=1 to Length(S)do Begin
  C:=UpCase(S[I]);
  If Not(C in['A'..'Z'])Then Continue;
  If R=''Then Begin R:=C;Last:=Code(C);End
   Else
  Begin
   Cd:=Code(C);
   If(Cd<>'0')and(Cd<>Last)Then R:=R+Cd;
   If Not(C in['H','W'])Then Last:=Cd;
  End;
  If Length(R)=4Then Break;
 End;
 If R=''Then Begin Soundex:='';Exit;End;
 While Length(R)<4do R:=R+'0';
 Soundex:=R;
End;

{ ---- hachages ---- }

Type
 TWords=Array[0..79]of LongWord;

Function Rol(X:LongWord;N:Integer):LongWord;Begin
 Rol:=(X shl N)or(X shr(32-N));
End;

Function Ror(X:LongWord;N:Integer):LongWord;Begin
 Ror:=(X shr N)or(X shl(32-N));
End;

Function HexOf(W:LongWord):String;
Const
 Hx:String[16]='0123456789abcdef';
Var
 I:Integer;
 R:String;
Begin
 R:='';
 For I:=7downto 0do R:=R+Hx[((W shr(I*4))and 15)+1];
 HexOf:=R;
End;

Function HexLE(W:LongWord):String;
Const
 Hx:String[16]='0123456789abcdef';
Var
 I:Integer;
 R:String;
 B:Integer;
Begin
 R:='';
 For I:=0 to 3do Begin
  B:=(W shr(I*8))and 255;
  R:=R+Hx[(B shr 4)+1]+Hx[(B and 15)+1];
 End;
 HexLE:=R;
End;

{ Message complete avec bourrage (grand ou petit boutiste) }
Procedure PadMessage(Const S:String;Big:Boolean;Var Blocks:PBytes;Var NBlocks:LongInt);
Var
 Total,I:LongInt;
 Bits:Int64;
Begin
 Total:=((Length(S)+8)div 64+1)*64;
 Blocks:=AllocBlock(Total);
 FillChar(Blocks^,Total,0);
 For I:=1 to Length(S)do Blocks^[I-1]:=Ord(S[I]);
 Blocks^[Length(S)]:=$80;
 Bits:=Int64(Length(S))*8;
 For I:=0 to 7do Begin
  If Big Then Blocks^[Total-1-I]:=(Bits shr(8*I))and 255
         Else Blocks^[Total-8+I]:=(Bits shr(8*I))and 255;
 End;
 NBlocks:=Total div 64;
End;

Function Md5Hex(Const S:String):String;
Const
 Sh:Array[0..63]of Byte=(7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22,5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20,
  4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23,6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21);
Var
 K:Array[0..63]of LongWord;
 M:PBytes;
 NB,B,I:LongInt;
 A0,B0,C0,D0,A,Bb,C,D,F,Tmp:LongWord;
 G:Integer;
 W:Array[0..15]of LongWord;
Begin
 For I:=0 to 63do K[I]:=LongWord(Trunc(Abs(Sin(I+1))*4294967296.0));
 PadMessage(S,False,M,NB);
 A0:=$67452301;B0:=$EFCDAB89;C0:=$98BADCFE;D0:=$10325476;
 For B:=0 to NB-1do Begin
  For I:=0 to 15do
   W[I]:=LongWord(M^[B*64+I*4])or(LongWord(M^[B*64+I*4+1])shl 8)or(LongWord(M^[B*64+I*4+2])shl 16)or(LongWord(M^[B*64+I*4+3])shl 24);
  A:=A0;Bb:=B0;C:=C0;D:=D0;
  For I:=0 to 63do Begin
   If I<16Then Begin F:=(Bb and C)or((Not Bb)and D);G:=I;End Else
   If I<32Then Begin F:=(D and Bb)or((Not D)and C);G:=(5*I+1)mod 16;End Else
   If I<48Then Begin F:=Bb xor C xor D;G:=(3*I+5)mod 16;End
          Else Begin F:=C xor(Bb or(Not D));G:=(7*I)mod 16;End;
   Tmp:=D;D:=C;C:=Bb;
   Bb:=Bb+Rol(A+F+K[I]+W[G],Sh[I]);
   A:=Tmp;
  End;
  A0:=A0+A;B0:=B0+Bb;C0:=C0+C;D0:=D0+D;
 End;
 Md5Hex:=HexLE(A0)+HexLE(B0)+HexLE(C0)+HexLE(D0);
End;

Function Sha1Hex(Const S:String):String;
Var
 M:PBytes;
 NB,B,I:LongInt;
 H0,H1,H2,H3,H4,A,Bb,C,D,E,F,K,Tmp:LongWord;
 W:TWords;
Begin
 PadMessage(S,True,M,NB);
 H0:=$67452301;H1:=$EFCDAB89;H2:=$98BADCFE;H3:=$10325476;H4:=$C3D2E1F0;
 For B:=0 to NB-1do Begin
  For I:=0 to 15do
   W[I]:=(LongWord(M^[B*64+I*4])shl 24)or(LongWord(M^[B*64+I*4+1])shl 16)or(LongWord(M^[B*64+I*4+2])shl 8)or LongWord(M^[B*64+I*4+3]);
  For I:=16 to 79do W[I]:=Rol(W[I-3]xor W[I-8]xor W[I-14]xor W[I-16],1);
  A:=H0;Bb:=H1;C:=H2;D:=H3;E:=H4;
  For I:=0 to 79do Begin
   If I<20Then Begin F:=(Bb and C)or((Not Bb)and D);K:=$5A827999;End Else
   If I<40Then Begin F:=Bb xor C xor D;K:=$6ED9EBA1;End Else
   If I<60Then Begin F:=(Bb and C)or(Bb and D)or(C and D);K:=$8F1BBCDC;End
          Else Begin F:=Bb xor C xor D;K:=$CA62C1D6;End;
   Tmp:=Rol(A,5)+F+E+K+W[I];
   E:=D;D:=C;C:=Rol(Bb,30);Bb:=A;A:=Tmp;
  End;
  H0:=H0+A;H1:=H1+Bb;H2:=H2+C;H3:=H3+D;H4:=H4+E;
 End;
 Sha1Hex:=HexOf(H0)+HexOf(H1)+HexOf(H2)+HexOf(H3)+HexOf(H4);
End;

Function Sha256Hex(Const S:String):String;
Var
 K:Array[0..63]of LongWord;
 M:PBytes;
 NB,B,I,N,Cnt:LongInt;
 H:Array[0..7]of LongWord;
 A,Bb,C,D,E,F,G,Hh,T1,T2,S0,S1:LongWord;
 W:TWords;
 P:LongInt;
 IsP:Boolean;
 J:LongInt;
 X:Real;
Begin
 { constantes : racines cubiques / carrees des premiers nombres premiers }
 Cnt:=0;P:=2;
 While Cnt<64do Begin
  IsP:=True;
  For J:=2 to P-1do If(J*J<=P)and(P mod J=0)Then IsP:=False;
  If IsP Then Begin
   X:=Exp(Ln(P)/3);
   K[Cnt]:=LongWord(Trunc((X-Int(X))*4294967296.0));
   If Cnt<8Then Begin X:=Sqrt(P);H[Cnt]:=LongWord(Trunc((X-Int(X))*4294967296.0));End;
   Inc(Cnt);
  End;
  Inc(P);
 End;
 PadMessage(S,True,M,NB);
 For B:=0 to NB-1do Begin
  For I:=0 to 15do
   W[I]:=(LongWord(M^[B*64+I*4])shl 24)or(LongWord(M^[B*64+I*4+1])shl 16)or(LongWord(M^[B*64+I*4+2])shl 8)or LongWord(M^[B*64+I*4+3]);
  For I:=16 to 63do Begin
   S0:=Ror(W[I-15],7)xor Ror(W[I-15],18)xor(W[I-15]shr 3);
   S1:=Ror(W[I-2],17)xor Ror(W[I-2],19)xor(W[I-2]shr 10);
   W[I]:=W[I-16]+S0+W[I-7]+S1;
  End;
  A:=H[0];Bb:=H[1];C:=H[2];D:=H[3];E:=H[4];F:=H[5];G:=H[6];Hh:=H[7];
  For I:=0 to 63do Begin
   S1:=Ror(E,6)xor Ror(E,11)xor Ror(E,25);
   T1:=Hh+S1+((E and F)xor((Not E)and G))+K[I]+W[I];
   S0:=Ror(A,2)xor Ror(A,13)xor Ror(A,22);
   T2:=S0+((A and Bb)xor(A and C)xor(Bb and C));
   Hh:=G;G:=F;F:=E;E:=D+T1;D:=C;C:=Bb;Bb:=A;A:=T1+T2;
  End;
  H[0]:=H[0]+A;H[1]:=H[1]+Bb;H[2]:=H[2]+C;H[3]:=H[3]+D;H[4]:=H[4]+E;H[5]:=H[5]+F;H[6]:=H[6]+G;H[7]:=H[7]+Hh;
 End;
 N:=0;
 Sha256Hex:=HexOf(H[0])+HexOf(H[1])+HexOf(H[2])+HexOf(H[3])+HexOf(H[4])+HexOf(H[5])+HexOf(H[6])+HexOf(H[7]);
End;

{ ---- JSON -> valeurs ---- }

Var
 JsS:String;
 JsP:Integer;

Procedure JsSkip;Begin
 While(JsP<=Length(JsS))and(JsS[JsP]in[' ',#9,#10,#13])do Inc(JsP);
End;

Function JsParse(Depth:Integer):TVal;
Var
 V:TVal;
 L:PValList;
 K,S,Num:String;
 R:Real;
 E,Er:Integer;
 Key:TVal;
Begin
 JsParse:=VNull;
 If Depth>20Then Exit;
 JsSkip;
 If JsP>Length(JsS)Then Exit;
 Case JsS[JsP]of
  '[':Begin
   Inc(JsP);
   L:=LNew;
   JsSkip;
   If(JsP<=Length(JsS))and(JsS[JsP]=']')Then Inc(JsP)
    Else
   Repeat
    LAdd(L,JsParse(Depth+1));
    JsSkip;
    If(JsP<=Length(JsS))and(JsS[JsP]=',')Then Begin Inc(JsP);Continue;End;
    If(JsP<=Length(JsS))and(JsS[JsP]=']')Then Inc(JsP);
    Break;
   Until False;
   JsParse:=VList(L);
  End;
  '{':Begin
   Inc(JsP);
   L:=LNew;
   JsSkip;
   If(JsP<=Length(JsS))and(JsS[JsP]='}')Then Inc(JsP)
    Else
   Repeat
    Key:=JsParse(Depth+1);
    JsSkip;
    If(JsP<=Length(JsS))and(JsS[JsP]=':')Then Inc(JsP);
    LAdd(L,Key);
    LAdd(L,JsParse(Depth+1));
    JsSkip;
    If(JsP<=Length(JsS))and(JsS[JsP]=',')Then Begin Inc(JsP);Continue;End;
    If(JsP<=Length(JsS))and(JsS[JsP]='}')Then Inc(JsP);
    Break;
   Until False;
   JsParse:=VMapOf(L);
  End;
  '"':Begin
   Inc(JsP);
   S:='';
   While(JsP<=Length(JsS))and(JsS[JsP]<>'"')do Begin
    If(JsS[JsP]='\')and(JsP<Length(JsS))Then Begin
     Inc(JsP);
     Case JsS[JsP]of
      'n':S:=S+#10;
      't':S:=S+#9;
      'r':S:=S+#13;
      'u':Begin
       Val('$'+Copy(JsS,JsP+1,4),E,Er);
       If Er=0Then S:=S+U8Chr(E);
       Inc(JsP,4);
      End;
      Else S:=S+JsS[JsP];
     End;
    End
     Else S:=S+JsS[JsP];
    Inc(JsP);
   End;
   Inc(JsP);
   JsParse:=VStr(S);
  End;
  Else Begin
   Num:='';
   While(JsP<=Length(JsS))and Not(JsS[JsP]in[',',']','}',' '])do Begin Num:=Num+JsS[JsP];Inc(JsP);End;
   If Num='true'Then JsParse:=VBool(True) Else
   If Num='false'Then JsParse:=VBool(False) Else
   If Num='null'Then JsParse:=VNull
    Else Begin
     Val(Num,R,E);
     If E=0Then JsParse:=VNum(R);
    End;
  End;
 End;
End;

Function ValFromJson(S:String):TVal;Begin
 JsS:=S;JsP:=1;
 ValFromJson:=JsParse(0);
End;

{ ---- fonctions : mathematiques, chaines, dates, conversions ---- }

Var
 FnOk:Boolean;

Procedure NeedArgs(Const Nm:String;N,Min:Integer);Begin
 If N<Min Then EFail('function '+Nm+' needs at least '+IntToStr(Min)+' argument(s)');
End;

Function NumArg(Var A:Array of TVal;I:Integer;Var R:Real):Boolean;Begin
 NumArg:=False;
 If(I<=High(A))and(A[I].K<>0)and(A[I].K<>4)and(A[I].K<>5)and(A[I].K<>6)Then NumArg:=ToNum(A[I],R);
End;

Function ListOf(Const V:TVal):PValList;Begin
 If V.K=5Then ListOf:=V.L Else ListOf:=Nil;
End;

Function FnMath(Const Nm:String;Var A:Array of TVal;N:Integer):TVal;
Var
 R,R2,R3,R4,R5,W:Real;
 I,J:Integer;
 Ok:Boolean;
 L:PValList;
 Cnt:Integer;
 Best:TVal;
Begin
 FnMath:=VNull;
 FnOk:=True;
 If Nm='ABS'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)Then FnMath:=VNum(Abs(R));End Else
 If Nm='SQRT'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)and(R>=0)Then FnMath:=VNum(Sqrt(R));End Else
 If Nm='SIN'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)Then FnMath:=VNum(Sin(R));End Else
 If Nm='COS'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)Then FnMath:=VNum(Cos(R));End Else
 If Nm='TAN'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)and(Cos(R)<>0)Then FnMath:=VNum(Sin(R)/Cos(R));End Else
 If Nm='ASIN'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)and(Abs(R)<=1)Then FnMath:=VNum(ArcSin(R));End Else
 If Nm='ACOS'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)and(Abs(R)<=1)Then FnMath:=VNum(Acos(R));End Else
 If Nm='ATAN'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)Then FnMath:=VNum(ArcTan(R));End Else
 If Nm='ATAN2'Then Begin NeedArgs(Nm,N,2);If NumArg(A,0,R)and NumArg(A,1,R2)Then FnMath:=VNum(Atan2(R,R2));End Else
 If Nm='EXP'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)and(R<700)Then FnMath:=VNum(Exp(R));End Else
 If Nm='LN'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)and(R>0)Then FnMath:=VNum(Ln(R));End Else
 If Nm='LOG10'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)and(R>0)Then FnMath:=VNum(Ln(R)/Ln(10));End Else
 If Nm='LOG'Then Begin
  NeedArgs(Nm,N,1);
  If N=1Then Begin If NumArg(A,0,R)and(R>0)Then FnMath:=VNum(Ln(R));End
   Else
  If NumArg(A,0,R)and NumArg(A,1,R2)and(R>0)and(R<>1)and(R2>0)Then FnMath:=VNum(Ln(R2)/Ln(R));
 End Else
 If Nm='PI'Then FnMath:=VNum(Pi) Else
 If Nm='DEGREES'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)Then FnMath:=VNum(R*180/Pi);End Else
 If Nm='RADIANS'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)Then FnMath:=VNum(R*Pi/180);End Else
 If Nm='FLOOR'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)Then FnMath:=VNum(FloorR(R));End Else
 If Nm='CEIL'Then Begin NeedArgs(Nm,N,1);If NumArg(A,0,R)Then FnMath:=VNum(-FloorR(-R));End Else
 If Nm='ROUND'Then Begin
  NeedArgs(Nm,N,1);
  If NumArg(A,0,R)Then Begin
   If NumArg(A,1,R2)Then Begin
    W:=1;
    For I:=1 to Abs(Round(R2))do W:=W*10;
    If R2>=0Then FnMath:=VNum(RoundHalf(R*W)/W)
            Else FnMath:=VNum(RoundHalf(R/W)*W);
   End
    Else
   FnMath:=VNum(RoundHalf(R));
  End;
 End Else
 If Nm='POWER'Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,0,R)and NumArg(A,1,R2)Then Begin
   If R>0Then FnMath:=VNum(Exp(R2*Ln(R))) Else
   If(R=0)and(R2>0)Then FnMath:=VNum(0) Else
   If(R<0)and(R2=Int(R2))Then Begin
    W:=Exp(R2*Ln(-R));
    If Odd(Round(Abs(R2)))Then W:=-W;
    FnMath:=VNum(W);
   End Else
   If R2=0Then FnMath:=VNum(1);
  End;
 End Else
 If Nm='CLAMP'Then Begin
  NeedArgs(Nm,N,3);
  If NumArg(A,0,R)and NumArg(A,1,R2)and NumArg(A,2,R3)Then Begin
   If R2<R Then R2:=R;
   If R2>R3 Then R2:=R3;
   FnMath:=VNum(R2);
  End;
 End Else
 If Nm='SCALE_LINEAR'Then Begin
  NeedArgs(Nm,N,5);
  If NumArg(A,0,R)and NumArg(A,1,R2)and NumArg(A,2,R3)and NumArg(A,3,R4)and NumArg(A,4,R5)and(R3<>R2)Then Begin
   If R<=R2 Then FnMath:=VNum(R4) Else
   If R>=R3 Then FnMath:=VNum(R5)
   Else FnMath:=VNum(R4+(R-R2)*(R5-R4)/(R3-R2));
  End;
 End Else
 If Nm='SCALE_EXP'Then Begin
  NeedArgs(Nm,N,6);
  If NumArg(A,0,R)and NumArg(A,1,R2)and NumArg(A,2,R3)and NumArg(A,3,R4)and NumArg(A,4,R5)and NumArg(A,5,W)and(R3<>R2)Then Begin
   If R<=R2 Then FnMath:=VNum(R4) Else
   If R>=R3 Then FnMath:=VNum(R5)
   Else FnMath:=VNum(R4+Exp(W*Ln((R-R2)/(R3-R2)))*(R5-R4));
  End;
 End Else
 If Nm='RAND'Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,0,R)and NumArg(A,1,R2)and(R2>=R)Then FnMath:=VNum(Round(R)+Random(Round(R2)-Round(R)+1));
 End Else
 If Nm='RANDF'Then Begin
  If(N>=2)and NumArg(A,0,R)and NumArg(A,1,R2)Then FnMath:=VNum(R+Random*(R2-R))
   Else FnMath:=VNum(Random);
 End Else
 If(Nm='BITWISE_AND')or(Nm='BITWISE_OR')or(Nm='BITWISE_XOR')or(Nm='BITWISE_SHIFT_LEFT')or(Nm='BITWISE_SHIFT_RIGHT')Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,0,R)and NumArg(A,1,R2)Then Begin
   If Nm='BITWISE_AND'Then FnMath:=VNum(Round(R)and Round(R2)) Else
   If Nm='BITWISE_OR'Then FnMath:=VNum(Round(R)or Round(R2)) Else
   If Nm='BITWISE_XOR'Then FnMath:=VNum(Round(R)xor Round(R2)) Else
   If Nm='BITWISE_SHIFT_LEFT'Then FnMath:=VNum(Round(R)shl Round(R2))
                             Else FnMath:=VNum(Round(R)shr Round(R2));
  End;
 End Else
 If(Nm='MIN')or(Nm='MAX')Then Begin
  Cnt:=0;
  Best:=VNull;
  For I:=0 to N-1do Begin
   If A[I].K=5Then Begin
    L:=A[I].L;
    For J:=0 to L^.Cnt-1do
     If L^.V^[J].K<>0Then Begin
      If(Cnt=0)or((Nm='MIN')and(CmpVal(L^.V^[J],Best)<0))or((Nm='MAX')and(CmpVal(L^.V^[J],Best)>0))Then Best:=L^.V^[J];
      Inc(Cnt);
     End;
   End
    Else
   If(A[I].K<>0)and(A[I].K<>4)Then Begin
    If(Cnt=0)or((Nm='MIN')and(CmpVal(A[I],Best)<0))or((Nm='MAX')and(CmpVal(A[I],Best)>0))Then Best:=A[I];
    Inc(Cnt);
   End;
  End;
  If Cnt>0Then FnMath:=Best;
 End
  Else
 FnOk:=False;
End;

{ ---- chaines ---- }

Function ReplaceAll(S,T,U:String):String;
Var
 Out:String;
 I:Integer;
Begin
 If T=''Then Begin ReplaceAll:=S;Exit;End;
 Out:='';
 I:=1;
 While I<=Length(S)do Begin
  If Copy(S,I,Length(T))=T Then Begin
   Out:=Out+U;
   Inc(I,Length(T));
  End
   Else
  Begin
   Out:=Out+S[I];
   Inc(I);
  End;
 End;
 ReplaceAll:=Out;
End;

Function FormatThousands(R:Real;Places:Integer):String;
Var
 S,Ip,Fp,Out:String;
 Neg:Boolean;
 I,P:Integer;
Begin
 Neg:=R<0;
 If Neg Then R:=-R;
 Str(R:0:Places,S);
 P:=Pos('.',S);
 If P>0Then Begin Ip:=Copy(S,1,P-1);Fp:=Copy(S,P,255);End
       Else Begin Ip:=S;Fp:='';End;
 Out:='';
 For I:=1 to Length(Ip)do Begin
  Out:=Out+Ip[I];
  If((Length(Ip)-I)mod 3=0)and(I<Length(Ip))Then Out:=Out+',';
 End;
 If Neg Then Out:='-'+Out;
 FormatThousands:=Out+Fp;
End;

Function FnString(Const Nm:String;Var A:Array of TVal;N:Integer):TVal;
Var
 R,R2:Real;
 S,T,U,Out:String;
 I,P,K,Cnt:Integer;
 L:LongInt;
 Lst:PValList;
 V:TVal;
 Best,Cur:Integer;
 Subj:String;
Begin
 FnString:=VNull;
 FnOk:=True;
 If(Nm='LOWER')or(Nm='UPPER')Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K<>0Then FnString:=VStr(U8Upper(ToStr(A[0]),Nm='UPPER'));
 End Else
 If Nm='TITLE'Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K<>0Then Begin
   S:=U8Upper(ToStr(A[0]),False);
   Out:='';
   K:=1;
   For I:=1 to Length(S)do Begin
    If K=1Then Out:=Out+U8Upper(S[I],True) Else Out:=Out+S[I];
    If S[I]in[' ',#9,#10]Then K:=1 Else K:=0;
   End;
   FnString:=VStr(Out);
  End;
 End Else
 If(Nm='LENGTH')or(Nm='LEN')Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K=5Then FnString:=VNum(A[0].L^.Cnt) Else
  If A[0].K<>0Then Begin
   If A[0].K=4Then FnString:=VNum(GeomLength(A[0].G^))
              Else FnString:=VNum(U8Len(ToStr(A[0])));
  End;
 End Else
 If Nm='CONCAT'Then Begin
  S:='';
  For I:=0 to N-1do If A[I].K<>0Then S:=S+ToStr(A[I]);
  FnString:=VStr(S);
 End Else
 If Nm='SUBSTR'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and NumArg(A,1,R)Then Begin
   S:=ToStr(A[0]);
   P:=Round(R);
   If P<0Then P:=U8Len(S)+P+1;
   If P<1Then P:=1;
   L:=100000;
   If NumArg(A,2,R2)Then L:=Round(R2);
   FnString:=VStr(U8Copy(S,P,L));
  End;
 End Else
 If(Nm='LEFT')or(Nm='RIGHT')Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and NumArg(A,1,R)Then Begin
   S:=ToStr(A[0]);
   L:=Round(R);
   If L<0Then L:=0;
   If Nm='LEFT'Then FnString:=VStr(U8Copy(S,1,L))
    Else Begin
     If L>U8Len(S)Then L:=U8Len(S);
     FnString:=VStr(U8Copy(S,U8Len(S)-L+1,L));
    End;
  End;
 End Else
 If Nm='REPLACE'Then Begin
  NeedArgs(Nm,N,2);
  If A[0].K=5Then Begin
   Lst:=LNew;
   For I:=0 to A[0].L^.Cnt-1do Begin
    V:=A[0].L^.V^[I];
    If A[1].K=5Then Begin
     For K:=0 to A[1].L^.Cnt-1do
      If ValEq(V,A[1].L^.V^[K])Then Begin
       If(N>2)and(A[2].K=5)and(K<A[2].L^.Cnt)Then V:=A[2].L^.V^[K]
        Else If(N>2)and(A[2].K<>5)Then V:=A[2];
       Break;
      End;
    End;
    LAdd(Lst,V);
   End;
   FnString:=VList(Lst);
  End Else
  If A[0].K<>0Then Begin
   S:=ToStr(A[0]);
   If A[1].K=6Then Begin
    I:=0;
    While I+1<A[1].L^.Cnt do Begin
     S:=ReplaceAll(S,ToStr(A[1].L^.V^[I]),ToStr(A[1].L^.V^[I+1]));
     Inc(I,2);
    End;
   End Else
   If A[1].K=5Then Begin
    For I:=0 to A[1].L^.Cnt-1do Begin
     If(N>2)and(A[2].K=5)Then Begin
      If I<A[2].L^.Cnt Then U:=ToStr(A[2].L^.V^[I]) Else U:='';
     End
      Else If N>2Then U:=ToStr(A[2]) Else U:='';
     S:=ReplaceAll(S,ToStr(A[1].L^.V^[I]),U);
    End;
   End
    Else If N>=3Then S:=ReplaceAll(S,ToStr(A[1]),ToStr(A[2]));
   FnString:=VStr(S);
  End;
 End Else
 If(Nm='TRIM')or(Nm='LTRIM')or(Nm='RTRIM')Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K<>0Then Begin
   S:=ToStr(A[0]);
   If Nm<>'RTRIM'Then While(S<>'')and(S[1]in[' ',#9,#10,#13])do Delete(S,1,1);
   If Nm<>'LTRIM'Then While(S<>'')and(S[Length(S)]in[' ',#9,#10,#13])do Delete(S,Length(S),1);
   FnString:=VStr(S);
  End;
 End Else
 If(Nm='LPAD')or(Nm='RPAD')Then Begin
  NeedArgs(Nm,N,3);
  If(A[0].K<>0)and NumArg(A,1,R)Then Begin
   S:=ToStr(A[0]);
   T:=ToStr(A[2]);
   L:=Round(R);
   If U8Len(S)>=L Then FnString:=VStr(U8Copy(S,1,L))
    Else Begin
     If T=''Then Begin FnString:=VStr(S);Exit;End;
     Out:='';
     K:=L-U8Len(S);
     While U8Len(Out)<K do Out:=Out+T;
     Out:=U8Copy(Out,1,K);
     If Nm='LPAD'Then FnString:=VStr(Out+S) Else FnString:=VStr(S+Out);
    End;
  End;
 End Else
 If Nm='REPEAT'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and NumArg(A,1,R)Then Begin
   S:=ToStr(A[0]);Out:='';
   For I:=1 to Round(R)do If Length(Out)+Length(S)<=255Then Out:=Out+S;
   FnString:=VStr(Out);
  End;
 End Else
 If((Nm='REVERSE')and(A[0].K<>4))or(Nm='ARRAY_REVERSE')Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K=5Then Begin
   Lst:=LNew;
   For I:=A[0].L^.Cnt-1downto 0do LAdd(Lst,A[0].L^.V^[I]);
   FnString:=VList(Lst);
  End Else
  If A[0].K<>0Then Begin
   S:=ToStr(A[0]);Out:='';
   P:=U8Len(S);
   For I:=P downto 1do Out:=Out+U8Copy(S,I,1);
   FnString:=VStr(Out);
  End;
 End Else
 If Nm='STRPOS'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and(A[1].K<>0)Then Begin
   S:=ToStr(A[0]);T:=ToStr(A[1]);
   P:=Pos(T,S);
   If P=0Then FnString:=VNum(0)
         Else FnString:=VNum(U8Len(Copy(S,1,P-1))+1);
  End;
 End Else
 If Nm='CHAR'Then Begin
  NeedArgs(Nm,N,1);
  If NumArg(A,0,R)and(R>=0)Then FnString:=VStr(U8Chr(Round(R)));
 End Else
 If Nm='UNICODE'Then Begin
  NeedArgs(Nm,N,1);
  If(A[0].K<>0)and(ToStr(A[0])<>'')Then Begin
   S:=ToStr(A[0]);
   K:=Ord(S[1]);
   If(K>=$C0)and(Length(S)>=2)Then K:=((K and $1F)shl 6)or(Ord(S[2])and $3F);
   FnString:=VNum(K);
  End;
 End Else
 If Nm='WORDWRAP'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and NumArg(A,1,R)Then Begin
   S:=ToStr(A[0]);
   If N>2Then U:=ToStr(A[2]) Else U:=#10;
   L:=Abs(Round(R));
   Out:='';Cur:=0;
   Subj:=S;
   While Subj<>''do Begin
    P:=Pos(' ',Subj);
    If P=0Then Begin T:=Subj;Subj:='';End
          Else Begin T:=Copy(Subj,1,P-1);Subj:=Copy(Subj,P+1,255);End;
    If(Cur>0)and(Cur+1+U8Len(T)>L)Then Begin Out:=Out+U;Cur:=0;End
     Else If Cur>0Then Begin Out:=Out+' ';Inc(Cur);End;
    Out:=Out+T;Inc(Cur,U8Len(T));
   End;
   FnString:=VStr(Out);
  End;
 End Else
 If Nm='FORMAT'Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K<>0Then Begin
   S:=ToStr(A[0]);
   For I:=N-1downto 1do S:=ReplaceAll(S,'%'+IntToStr(I),ToStr(A[I]));
   FnString:=VStr(S);
  End;
 End Else
 If Nm='FORMAT_NUMBER'Then Begin
  NeedArgs(Nm,N,1);
  If NumArg(A,0,R)Then Begin
   K:=0;
   If NumArg(A,1,R2)Then K:=Round(R2);
   FnString:=VStr(FormatThousands(R,K));
  End;
 End Else
 If Nm='LEVENSHTEIN'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and(A[1].K<>0)Then FnString:=VNum(Levenshtein(ToStr(A[0]),ToStr(A[1])));
 End Else
 If Nm='HAMMING_DISTANCE'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and(A[1].K<>0)Then Begin
   S:=ToStr(A[0]);T:=ToStr(A[1]);
   If Length(S)=Length(T)Then Begin
    K:=0;
    For I:=1 to Length(S)do If S[I]<>T[I]Then Inc(K);
    FnString:=VNum(K);
   End;
  End;
 End Else
 If Nm='LONGEST_COMMON_SUBSTRING'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and(A[1].K<>0)Then Begin
   S:=ToStr(A[0]);T:=ToStr(A[1]);
   Best:=0;P:=0;
   For I:=1 to Length(S)do
    For K:=1 to Length(T)do Begin
     L:=0;
     While(I+L<=Length(S))and(K+L<=Length(T))and(S[I+L]=T[K+L])do Inc(L);
     If L>Best Then Begin Best:=L;P:=I;End;
    End;
   FnString:=VStr(Copy(S,P,Best));
  End;
 End Else
 If Nm='SOUNDEX'Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K<>0Then FnString:=VStr(Soundex(ToStr(A[0])));
 End Else
 If Nm='MD5'Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K<>0Then FnString:=VStr(Md5Hex(ToStr(A[0])));
 End Else
 If Nm='SHA256'Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K<>0Then FnString:=VStr(Sha256Hex(ToStr(A[0])));
 End Else
 If Nm='HASH'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and(A[1].K<>0)Then Begin
   T:=LowerStr(ToStr(A[1]));
   If T='md5'Then FnString:=VStr(Md5Hex(ToStr(A[0]))) Else
   If T='sha1'Then FnString:=VStr(Sha1Hex(ToStr(A[0]))) Else
   If T='sha256'Then FnString:=VStr(Sha256Hex(ToStr(A[0])))
    Else EFail('unsupported hash method '+T);
  End;
 End Else
 If Nm='UUID'Then Begin
  S:='';
  For I:=1 to 32do Begin
   K:=Random(16);
   If I=13Then K:=4;
   If I=17Then K:=8+Random(4);
   S:=S+Copy('0123456789abcdef',K+1,1);
   If(I=8)or(I=12)or(I=16)or(I=20)Then S:=S+'-';
  End;
  FnString:=VStr('{'+S+'}');
 End Else
 If Nm='REGEXP_MATCH'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and(A[1].K<>0)Then Begin
   RxCompile(ToStr(A[1]));
   If RxFind(ToStr(A[0]),1)Then FnString:=VNum(U8Len(Copy(RxSub,1,RxCapS[0]-1))+1)
                           Else FnString:=VNum(0);
  End;
 End Else
 If Nm='REGEXP_MATCHES'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and(A[1].K<>0)Then Begin
   RxCompile(ToStr(A[1]));
   If RxFind(ToStr(A[0]),1)Then Begin
    Lst:=LNew;
    For I:=1 to RxGroups do LAdd(Lst,VStr(RxGroupText(I)));
    FnString:=VList(Lst);
   End
    Else FnString:=VList(LNew);
  End;
 End Else
 If Nm='REGEXP_SUBSTR'Then Begin
  NeedArgs(Nm,N,2);
  If(A[0].K<>0)and(A[1].K<>0)Then Begin
   RxCompile(ToStr(A[1]));
   If RxFind(ToStr(A[0]),1)Then Begin
    If RxGroups>0Then FnString:=VStr(RxGroupText(1))
                 Else FnString:=VStr(RxGroupText(0));
   End
    Else FnString:=VStr('');
  End;
 End Else
 If Nm='REGEXP_REPLACE'Then Begin
  NeedArgs(Nm,N,3);
  If(A[0].K<>0)and(A[1].K<>0)and(A[2].K<>0)Then Begin
   RxCompile(ToStr(A[1]));
   S:=ToStr(A[0]);U:=ToStr(A[2]);
   Out:='';P:=1;
   While(P<=Length(S)+1)and RxFind(S,P)do Begin
    Out:=Out+Copy(S,P,RxCapS[0]-P);
    K:=1;
    While K<=Length(U)do Begin
     If(U[K]='\')and(K<Length(U))and(U[K+1]in['0'..'9'])Then Begin
      Out:=Out+RxGroupText(Ord(U[K+1])-48);
      Inc(K,2);
     End
      Else Begin Out:=Out+U[K];Inc(K);End;
    End;
    If RxCapE[0]=RxCapS[0]Then Begin
     If RxCapS[0]<=Length(S)Then Out:=Out+S[RxCapS[0]];
     P:=RxCapS[0]+1;
    End
     Else P:=RxCapE[0];
   End;
   If P<=Length(S)Then Out:=Out+Copy(S,P,255);
   FnString:=VStr(Out);
  End;
 End Else
 If Nm='STRING_TO_ARRAY'Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K<>0Then Begin
   S:=ToStr(A[0]);
   If N>1Then T:=ToStr(A[1]) Else T:=',';
   Lst:=LNew;
   If T=''Then Begin
    For I:=1 to U8Len(S)do LAdd(Lst,VStr(U8Copy(S,I,1)));
   End
    Else
   Begin
    Repeat
     P:=Pos(T,S);
     If P=0Then Begin LAdd(Lst,VStr(S));Break;End;
     LAdd(Lst,VStr(Copy(S,1,P-1)));
     S:=Copy(S,P+Length(T),255);
    Until False;
   End;
   FnString:=VList(Lst);
  End;
 End
  Else
 FnOk:=False;
End;

{ ---- dates ---- }

Function ToTimeVal(Const V:TVal;Var Out:TVal):Boolean;Forward;
Function ToTimeValFmt(Const V:TVal;Const Fmt:String;Var Out:TVal):Boolean;
Var
 T:Real;
 K:Byte;
Begin
 ToTimeValFmt:=False;
 If V.K=2Then Begin
  If ParseTimeFormat(V.S,Fmt,T,K)Then Begin Out:=VTime(K,T);ToTimeValFmt:=True;End;
 End
  Else
 ToTimeValFmt:=ToTimeVal(V,Out);
End;

Function ToTimeVal(Const V:TVal;Var Out:TVal):Boolean;
Var
 T:Real;
 K:Byte;
Begin
 ToTimeVal:=False;
 If IsTimeKind(V.K)Then Begin Out:=V;ToTimeVal:=True;Exit;End;
 If V.K=2Then Begin
  If ParseTime(V.S,T,K)Then Begin Out:=VTime(K,T);ToTimeVal:=True;End;
 End;
End;

Function FnDate(Const Nm:String;Var A:Array of TVal;N:Integer):TVal;
Var
 R,R2,R3,R4,R5,R6,R7,T:Real;
 Y,Mo,D,H,Mi:LongInt;
 S:Real;
 K:Byte;
 V,Z2:TVal;
 Ok:Boolean;
Begin
 FnDate:=VNull;
 FnOk:=True;
 If Nm='NOW'Then FnDate:=VTime(7,NowSecs) Else
 If(Nm='TO_DATE')or(Nm='TO_DATETIME')or(Nm='TO_TIME')Then Begin
  NeedArgs(Nm,N,1);
  Ok:=False;
  If(N>1)and(A[1].K=2)Then Ok:=ToTimeValFmt(A[0],A[1].S,V) Else Ok:=ToTimeVal(A[0],V);
  If Ok Then Begin
   T:=V.N;
   If Nm='TO_DATE'Then Begin
    If V.K=9Then Exit;
    FnDate:=VTime(8,Int(FloorDiv(T,86400))*86400);
   End Else
   If Nm='TO_DATETIME'Then Begin
    If V.K=9Then Exit;
    FnDate:=VTime(7,T);
   End
    Else
   Begin
    If V.K=8Then FnDate:=VTime(9,0)
            Else FnDate:=VTime(9,T-Int(FloorDiv(T,86400))*86400);
   End;
  End;
 End Else
 If Nm='TO_INTERVAL'Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K=10Then FnDate:=A[0] Else
  If A[0].K=2Then Begin
   If ParseInterval(A[0].S,T)Then FnDate:=VTime(10,T);
  End;
 End Else
 If(Nm='YEAR')or(Nm='MONTH')or(Nm='DAY')or(Nm='HOUR')or(Nm='MINUTE')or(Nm='SECOND')or(Nm='WEEK')Then Begin
  NeedArgs(Nm,N,1);
  If ToTimeVal(A[0],V)Then Begin
   If V.K=10Then Begin
    If Nm='YEAR'Then FnDate:=VNum(V.N/(365.25*86400)) Else
    If Nm='MONTH'Then FnDate:=VNum(V.N/(30*86400)) Else
    If Nm='WEEK'Then FnDate:=VNum(V.N/(7*86400)) Else
    If Nm='DAY'Then FnDate:=VNum(V.N/86400) Else
    If Nm='HOUR'Then FnDate:=VNum(V.N/3600) Else
    If Nm='MINUTE'Then FnDate:=VNum(V.N/60)
                  Else FnDate:=VNum(V.N);
   End
    Else
   Begin
    SplitTime(V.N,Y,Mo,D,H,Mi,S);
    If Nm='YEAR'Then FnDate:=VNum(Y) Else
    If Nm='MONTH'Then FnDate:=VNum(Mo) Else
    If Nm='DAY'Then FnDate:=VNum(D) Else
    If Nm='HOUR'Then FnDate:=VNum(H) Else
    If Nm='MINUTE'Then FnDate:=VNum(Mi) Else
    If Nm='SECOND'Then FnDate:=VNum(S)
                  Else FnDate:=VNum(IsoWeek(V.N));
   End;
  End;
 End Else
 If Nm='DAY_OF_WEEK'Then Begin
  NeedArgs(Nm,N,1);
  If ToTimeVal(A[0],V)and(V.K<>9)and(V.K<>10)Then FnDate:=VNum(DayOfWeek0(V.N));
 End Else
 If Nm='EPOCH'Then Begin
  NeedArgs(Nm,N,1);
  If ToTimeVal(A[0],V)Then FnDate:=VNum(V.N*1000);
 End Else
 If Nm='DATETIME_FROM_EPOCH'Then Begin
  NeedArgs(Nm,N,1);
  If NumArg(A,0,R)Then FnDate:=VTime(7,R/1000);
 End Else
 If Nm='AGE'Then Begin
  NeedArgs(Nm,N,2);
  If ToTimeVal(A[0],V)and ToTimeVal(A[1],Z2)Then FnDate:=VTime(10,V.N-Z2.N);
 End Else
 If Nm='MAKE_DATE'Then Begin
  NeedArgs(Nm,N,3);
  If NumArg(A,0,R)and NumArg(A,1,R2)and NumArg(A,2,R3)Then
   FnDate:=VTime(8,MakeTime(Round(R),Round(R2),Round(R3),0,0,0));
 End Else
 If Nm='MAKE_TIME'Then Begin
  NeedArgs(Nm,N,3);
  If NumArg(A,0,R)and NumArg(A,1,R2)and NumArg(A,2,R3)Then FnDate:=VTime(9,R*3600+R2*60+R3);
 End Else
 If Nm='MAKE_DATETIME'Then Begin
  NeedArgs(Nm,N,6);
  If NumArg(A,0,R)and NumArg(A,1,R2)and NumArg(A,2,R3)and NumArg(A,3,R4)and NumArg(A,4,R5)and NumArg(A,5,R6)Then
   FnDate:=VTime(7,MakeTime(Round(R),Round(R2),Round(R3),Round(R4),Round(R5),R6));
 End Else
 If Nm='MAKE_INTERVAL'Then Begin
  R:=0;R2:=0;R3:=0;R4:=0;R5:=0;R6:=0;R7:=0;
  If N>0Then NumArg(A,0,R);
  If N>1Then NumArg(A,1,R2);
  If N>2Then NumArg(A,2,R3);
  If N>3Then NumArg(A,3,R4);
  If N>4Then NumArg(A,4,R5);
  If N>5Then NumArg(A,5,R6);
  If N>6Then NumArg(A,6,R7);
  FnDate:=VTime(10,R*365.25*86400+R2*30*86400+R3*7*86400+R4*86400+R5*3600+R6*60+R7);
 End Else
 If Nm='FORMAT_DATE'Then Begin
  NeedArgs(Nm,N,2);
  If ToTimeVal(A[0],V)and(A[1].K<>0)Then FnDate:=VStr(FormatTime(V.N,ToStr(A[1])));
 End
  Else
 FnOk:=False;
End;

{ ---- tableaux, dictionnaires, conversions ---- }

Procedure SortVals(V:PValArr;N:LongInt;Asc:Boolean);
Var
 I,J:LongInt;
 T:TVal;
Begin
 For I:=1 to N-1do Begin
  T:=V^[I];
  J:=I-1;
  While(J>=0)and((Asc and(CmpVal(V^[J],T)>0))or((Not Asc)and(CmpVal(V^[J],T)<0)))do Begin
   V^[J+1]:=V^[J];
   Dec(J);
  End;
  V^[J+1]:=T;
 End;
End;

Function ArrIndex(Cnt:LongInt;R:Real;Var I:LongInt):Boolean;Begin
 I:=Round(R);
 If I<0Then I:=Cnt+I;
 ArrIndex:=(I>=0)and(I<Cnt);
End;

Function MapFind(L:PValList;Const Key:String):LongInt;
Var
 I:LongInt;
Begin
 MapFind:=-1;
 I:=0;
 While I+1<L^.Cnt do Begin
  If ToStr(L^.V^[I])=Key Then Begin MapFind:=I;Exit;End;
  Inc(I,2);
 End;
End;

Function FnArray(Const Nm:String;Var A:Array of TVal;N:Integer):TVal;
Var
 R,R2,R3:Real;
 I,K:LongInt;
 L,L2,Lst:PValList;
 V,Best:TVal;
 S,T:String;
 Sum:Real;
 Cnt:LongInt;
 Ok:Boolean;
 Mx:LongInt;
 Seen:Boolean;

 Function ListArg(Idx:Integer):PValList;Begin
  If(Idx<N)and(A[Idx].K=5)Then ListArg:=A[Idx].L Else ListArg:=Nil;
 End;

Begin
 FnArray:=VNull;
 FnOk:=True;
 If Nm='ARRAY'Then Begin
  Lst:=LNew;
  For I:=0 to N-1do LAdd(Lst,A[I]);
  FnArray:=VList(Lst);
 End Else
 If Nm='ARRAY_LENGTH'Then Begin
  NeedArgs(Nm,N,1);
  L:=ListArg(0);
  If L<>Nil Then FnArray:=VNum(L^.Cnt);
 End Else
 If(Nm='ARRAY_APPEND')or(Nm='ARRAY_PREPEND')Then Begin
  NeedArgs(Nm,N,2);
  L:=ListArg(0);
  If L<>Nil Then Begin
   Lst:=LNew;
   If Nm='ARRAY_PREPEND'Then LAdd(Lst,A[1]);
   For I:=0 to L^.Cnt-1do LAdd(Lst,L^.V^[I]);
   If Nm='ARRAY_APPEND'Then LAdd(Lst,A[1]);
   FnArray:=VList(Lst);
  End;
 End Else
 If Nm='ARRAY_CAT'Then Begin
  Lst:=LNew;
  For K:=0 to N-1do Begin
   L:=ListArg(K);
   If L=Nil Then Exit;
   For I:=0 to L^.Cnt-1do LAdd(Lst,L^.V^[I]);
  End;
  FnArray:=VList(Lst);
 End Else
 If(Nm='ARRAY_CONTAINS')or(Nm='ARRAY_FIND')or(Nm='ARRAY_COUNT')Then Begin
  NeedArgs(Nm,N,2);
  L:=ListArg(0);
  If L<>Nil Then Begin
   Cnt:=0;K:=-1;
   For I:=0 to L^.Cnt-1do If ValEq(L^.V^[I],A[1])Then Begin
    Inc(Cnt);
    If K<0Then K:=I;
   End;
   If Nm='ARRAY_CONTAINS'Then FnArray:=VBool(Cnt>0) Else
   If Nm='ARRAY_FIND'Then FnArray:=VNum(K)
                     Else FnArray:=VNum(Cnt);
  End;
 End Else
 If(Nm='ARRAY_CONTAINS_ALL')or(Nm='ARRAY_CONTAINS_ANY')Then Begin
  NeedArgs(Nm,N,2);
  L:=ListArg(0);L2:=ListArg(1);
  If(L<>Nil)and(L2<>Nil)Then Begin
   Ok:=Nm='ARRAY_CONTAINS_ALL';
   For I:=0 to L2^.Cnt-1do Begin
    Seen:=False;
    For K:=0 to L^.Cnt-1do If ValEq(L^.V^[K],L2^.V^[I])Then Seen:=True;
    If Nm='ARRAY_CONTAINS_ALL'Then Begin If Not Seen Then Ok:=False;End
                              Else Begin If Seen Then Ok:=True;End;
   End;
   If(Nm='ARRAY_CONTAINS_ANY')and(L2^.Cnt=0)Then Ok:=False;
   FnArray:=VBool(Ok);
  End;
 End Else
 If Nm='ARRAY_DISTINCT'Then Begin
  NeedArgs(Nm,N,1);
  L:=ListArg(0);
  If L<>Nil Then Begin
   Lst:=LNew;
   For I:=0 to L^.Cnt-1do Begin
    Seen:=False;
    For K:=0 to Lst^.Cnt-1do If ValEq(Lst^.V^[K],L^.V^[I])Then Seen:=True;
    If Not Seen Then LAdd(Lst,L^.V^[I]);
   End;
   FnArray:=VList(Lst);
  End;
 End Else
 If(Nm='ARRAY_FIRST')or(Nm='ARRAY_LAST')Then Begin
  NeedArgs(Nm,N,1);
  L:=ListArg(0);
  If(L<>Nil)and(L^.Cnt>0)Then Begin
   If Nm='ARRAY_FIRST'Then FnArray:=L^.V^[0] Else FnArray:=L^.V^[L^.Cnt-1];
  End;
 End Else
 If Nm='ARRAY_GET'Then Begin
  NeedArgs(Nm,N,2);
  L:=ListArg(0);
  If(L<>Nil)and NumArg(A,1,R)and ArrIndex(L^.Cnt,R,K)Then FnArray:=L^.V^[K];
 End Else
 If Nm='ARRAY_INSERT'Then Begin
  NeedArgs(Nm,N,3);
  L:=ListArg(0);
  If(L<>Nil)and NumArg(A,1,R)Then Begin
   K:=Round(R);
   If K<0Then K:=L^.Cnt+K;
   If(K>=0)and(K<=L^.Cnt)Then Begin
    Lst:=LNew;
    For I:=0 to L^.Cnt-1do Begin
     If I=K Then LAdd(Lst,A[2]);
     LAdd(Lst,L^.V^[I]);
    End;
    If K=L^.Cnt Then LAdd(Lst,A[2]);
    FnArray:=VList(Lst);
   End;
  End;
 End Else
 If Nm='ARRAY_INTERSECT'Then Begin
  NeedArgs(Nm,N,2);
  L:=ListArg(0);L2:=ListArg(1);
  If(L<>Nil)and(L2<>Nil)Then Begin
   Ok:=False;
   For I:=0 to L^.Cnt-1do
    For K:=0 to L2^.Cnt-1do If ValEq(L^.V^[I],L2^.V^[K])Then Ok:=True;
   FnArray:=VBool(Ok);
  End;
 End Else
 If(Nm='ARRAY_SUM')or(Nm='ARRAY_MEAN')or(Nm='ARRAY_MEDIAN')or(Nm='ARRAY_MIN')or(Nm='ARRAY_MAX')or
   (Nm='ARRAY_MAJORITY')or(Nm='ARRAY_MINORITY')Then Begin
  NeedArgs(Nm,N,1);
  L:=ListArg(0);
  If L<>Nil Then Begin
   Lst:=LNew;
   For I:=0 to L^.Cnt-1do If L^.V^[I].K<>0Then LAdd(Lst,L^.V^[I]);
   If Lst^.Cnt=0Then Exit;
   If(Nm='ARRAY_MIN')or(Nm='ARRAY_MAX')Then Begin
    Best:=Lst^.V^[0];
    For I:=1 to Lst^.Cnt-1do
     If((Nm='ARRAY_MIN')and(CmpVal(Lst^.V^[I],Best)<0))or((Nm='ARRAY_MAX')and(CmpVal(Lst^.V^[I],Best)>0))Then Best:=Lst^.V^[I];
    FnArray:=Best;
   End Else
   If(Nm='ARRAY_MAJORITY')or(Nm='ARRAY_MINORITY')Then Begin
    Mx:=-1;
    For I:=0 to Lst^.Cnt-1do Begin
     Cnt:=0;
     For K:=0 to Lst^.Cnt-1do If ValEq(Lst^.V^[I],Lst^.V^[K])Then Inc(Cnt);
     If(Mx<0)or((Nm='ARRAY_MAJORITY')and(Cnt>Mx))or((Nm='ARRAY_MINORITY')and(Cnt<Mx))Then Begin Mx:=Cnt;Best:=Lst^.V^[I];End;
    End;
    FnArray:=Best;
   End
    Else
   Begin
    Sum:=0;
    For I:=0 to Lst^.Cnt-1do Begin
     If Not ToNum(Lst^.V^[I],R)Then Exit;
     Sum:=Sum+R;
    End;
    If Nm='ARRAY_SUM'Then FnArray:=VNum(Sum) Else
    If Nm='ARRAY_MEAN'Then FnArray:=VNum(Sum/Lst^.Cnt)
     Else Begin
      SortVals(Lst^.V,Lst^.Cnt,True);
      If Odd(Lst^.Cnt)Then ToNum(Lst^.V^[Lst^.Cnt div 2],R)
       Else Begin ToNum(Lst^.V^[Lst^.Cnt div 2-1],R);ToNum(Lst^.V^[Lst^.Cnt div 2],R2);R:=(R+R2)/2;End;
      FnArray:=VNum(R);
     End;
   End;
  End;
 End Else
 If Nm='ARRAY_REMOVE_ALL'Then Begin
  NeedArgs(Nm,N,2);
  L:=ListArg(0);
  If L<>Nil Then Begin
   Lst:=LNew;
   For I:=0 to L^.Cnt-1do If Not ValEq(L^.V^[I],A[1])Then LAdd(Lst,L^.V^[I]);
   FnArray:=VList(Lst);
  End;
 End Else
 If Nm='ARRAY_REMOVE_AT'Then Begin
  NeedArgs(Nm,N,2);
  L:=ListArg(0);
  If(L<>Nil)and NumArg(A,1,R)Then Begin
   K:=Round(R);
   If K<0Then K:=L^.Cnt+K;
   Lst:=LNew;
   For I:=0 to L^.Cnt-1do If I<>K Then LAdd(Lst,L^.V^[I]);
   FnArray:=VList(Lst);
  End;
 End Else
 If Nm='ARRAY_REPLACE'Then Begin
  NeedArgs(Nm,N,3);
  L:=ListArg(0);
  If L<>Nil Then Begin
   Lst:=LNew;
   For I:=0 to L^.Cnt-1do Begin
    If ValEq(L^.V^[I],A[1])Then LAdd(Lst,A[2]) Else LAdd(Lst,L^.V^[I]);
   End;
   FnArray:=VList(Lst);
  End;
 End Else
 If Nm='ARRAY_SLICE'Then Begin
  NeedArgs(Nm,N,3);
  L:=ListArg(0);
  If(L<>Nil)and NumArg(A,1,R)and NumArg(A,2,R2)Then Begin
   K:=Round(R);Mx:=Round(R2);
   If K<0Then K:=L^.Cnt+K;
   If Mx<0Then Mx:=L^.Cnt+Mx;
   If K<0Then K:=0;
   If Mx>=L^.Cnt Then Mx:=L^.Cnt-1;
   Lst:=LNew;
   For I:=K to Mx do LAdd(Lst,L^.V^[I]);
   FnArray:=VList(Lst);
  End;
 End Else
 If Nm='ARRAY_SORT'Then Begin
  NeedArgs(Nm,N,1);
  L:=ListArg(0);
  If L<>Nil Then Begin
   Lst:=LNew;
   For I:=0 to L^.Cnt-1do LAdd(Lst,L^.V^[I]);
   Ok:=True;
   If(N>1)and(A[1].K<>0)Then Ok:=A[1].N<>0;
   SortVals(Lst^.V,Lst^.Cnt,Ok);
   FnArray:=VList(Lst);
  End;
 End Else
 If Nm='ARRAY_PRIORITIZE'Then Begin
  NeedArgs(Nm,N,2);
  L:=ListArg(0);L2:=ListArg(1);
  If(L<>Nil)and(L2<>Nil)Then Begin
   Lst:=LNew;
   For K:=0 to L2^.Cnt-1do
    For I:=0 to L^.Cnt-1do If ValEq(L^.V^[I],L2^.V^[K])Then LAdd(Lst,L^.V^[I]);
   For I:=0 to L^.Cnt-1do Begin
    Seen:=False;
    For K:=0 to L2^.Cnt-1do If ValEq(L^.V^[I],L2^.V^[K])Then Seen:=True;
    If Not Seen Then LAdd(Lst,L^.V^[I]);
   End;
   FnArray:=VList(Lst);
  End;
 End Else
 If Nm='ARRAY_TO_STRING'Then Begin
  NeedArgs(Nm,N,1);
  L:=ListArg(0);
  If L<>Nil Then Begin
   If N>1Then T:=ToStr(A[1]) Else T:=',';
   S:='';
   K:=0;
   For I:=0 to L^.Cnt-1do Begin
    If L^.V^[I].K=0Then Begin
     If N>2Then Begin If K>0Then S:=S+T;S:=S+ToStr(A[2]);Inc(K);End;
    End
     Else Begin If K>0Then S:=S+T;S:=S+ToStr(L^.V^[I]);Inc(K);End;
   End;
   FnArray:=VStr(S);
  End;
 End Else
 If Nm='GENERATE_SERIES'Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,0,R)and NumArg(A,1,R2)Then Begin
   R3:=1;
   If N>2Then NumArg(A,2,R3);
   If R3=0Then Exit;
   Lst:=LNew;
   Cnt:=0;
   If R3>0Then Begin
    While(R<=R2+1E-12)and(Cnt<10000)do Begin LAdd(Lst,VNum(R));R:=R+R3;Inc(Cnt);End;
   End
    Else
   While(R>=R2-1E-12)and(Cnt<10000)do Begin LAdd(Lst,VNum(R));R:=R+R3;Inc(Cnt);End;
   FnArray:=VList(Lst);
  End;
 End Else
 { dictionnaires }
 If Nm='MAP'Then Begin
  Lst:=LNew;
  I:=0;
  While I+1<N do Begin
   LAdd(Lst,VStr(ToStr(A[I])));
   LAdd(Lst,A[I+1]);
   Inc(I,2);
  End;
  FnArray:=VMapOf(Lst);
 End Else
 If(Nm='MAP_AKEYS')or(Nm='MAP_AVALS')Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K=6Then Begin
   Lst:=LNew;
   I:=0;
   If Nm='MAP_AVALS'Then Inc(I);
   While I<A[0].L^.Cnt do Begin LAdd(Lst,A[0].L^.V^[I]);Inc(I,2);End;
   FnArray:=VList(Lst);
  End;
 End Else
 If Nm='MAP_CONCAT'Then Begin
  Lst:=LNew;
  For K:=0 to N-1do Begin
   If A[K].K<>6Then Exit;
   I:=0;
   While I+1<A[K].L^.Cnt do Begin
    Mx:=MapFind(Lst,ToStr(A[K].L^.V^[I]));
    If Mx>=0Then Lst^.V^[Mx+1]:=A[K].L^.V^[I+1]
     Else Begin LAdd(Lst,A[K].L^.V^[I]);LAdd(Lst,A[K].L^.V^[I+1]);End;
    Inc(I,2);
   End;
  End;
  FnArray:=VMapOf(Lst);
 End Else
 If Nm='MAP_DELETE'Then Begin
  NeedArgs(Nm,N,2);
  If A[0].K=6Then Begin
   Lst:=LNew;
   S:=ToStr(A[1]);
   I:=0;
   While I+1<A[0].L^.Cnt do Begin
    If ToStr(A[0].L^.V^[I])<>S Then Begin LAdd(Lst,A[0].L^.V^[I]);LAdd(Lst,A[0].L^.V^[I+1]);End;
    Inc(I,2);
   End;
   FnArray:=VMapOf(Lst);
  End;
 End Else
 If Nm='MAP_EXIST'Then Begin
  NeedArgs(Nm,N,2);
  If A[0].K=6Then FnArray:=VBool(MapFind(A[0].L,ToStr(A[1]))>=0);
 End Else
 If Nm='MAP_GET'Then Begin
  NeedArgs(Nm,N,2);
  If A[0].K=6Then Begin
   K:=MapFind(A[0].L,ToStr(A[1]));
   If K>=0Then FnArray:=A[0].L^.V^[K+1];
  End;
 End Else
 If Nm='MAP_INSERT'Then Begin
  NeedArgs(Nm,N,3);
  If A[0].K=6Then Begin
   Lst:=LNew;
   For I:=0 to A[0].L^.Cnt-1do LAdd(Lst,A[0].L^.V^[I]);
   K:=MapFind(Lst,ToStr(A[1]));
   If K>=0Then Lst^.V^[K+1]:=A[2]
    Else Begin LAdd(Lst,VStr(ToStr(A[1])));LAdd(Lst,A[2]);End;
   FnArray:=VMapOf(Lst);
  End;
 End Else
 If(Nm='FROM_JSON')or(Nm='JSON_TO_MAP')Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K=2Then FnArray:=ValFromJson(A[0].S);
 End Else
 If Nm='TO_JSON'Then Begin
  NeedArgs(Nm,N,1);
  FnArray:=VStr(ValJson(A[0]));
 End
  Else
 FnOk:=False;
End;

Function ToBoolVal(Const V:TVal;Var B:Boolean):Boolean;
Var
 S:String;
Begin
 ToBoolVal:=True;
 Case V.K of
  1,3:B:=V.N<>0;
  2:Begin
   S:=LowerStr(V.S);
   If(S='true')or(S='t')or(S='yes')or(S='y')or(S='1')Then B:=True Else
   If(S='false')or(S='f')or(S='no')or(S='n')or(S='0')or(S='')Then B:=False
    Else ToBoolVal:=False;
  End;
  Else ToBoolVal:=False;
 End;
End;

Function FnMisc(Const Nm:String;Var A:Array of TVal;N:Integer):TVal;
Var
 R:Real;
 I:Integer;
 B:Boolean;
 S:String;
Begin
 FnMisc:=VNull;
 FnOk:=True;
 If Nm='TO_STRING'Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K<>0Then FnMisc:=VStr(ToStr(A[0]));
 End Else
 If(Nm='TO_REAL')or(Nm='TO_INT')Then Begin
  NeedArgs(Nm,N,1);
  If(A[0].K<>0)and(A[0].K<>4)and(A[0].K<>5)and(A[0].K<>6)and ToNum(A[0],R)Then Begin
   If Nm='TO_INT'Then R:=Int(R);
   FnMisc:=VNum(R);
  End;
 End Else
 If Nm='TO_BOOL'Then Begin
  NeedArgs(Nm,N,1);
  If ToBoolVal(A[0],B)Then FnMisc:=VBool(B);
 End Else
 If Nm='COALESCE'Then Begin
  For I:=0 to N-1do If A[I].K<>0Then Begin FnMisc:=A[I];Exit;End;
 End Else
 If Nm='NULLIF'Then Begin
  NeedArgs(Nm,N,2);
  If ValEq(A[0],A[1])Then FnMisc:=VNull Else FnMisc:=A[0];
 End Else
 If Nm='IF'Then Begin
  NeedArgs(Nm,N,3);
  If A[0].K<>0Then Begin
   If A[0].N<>0Then FnMisc:=A[1] Else FnMisc:=A[2];
  End
   Else FnMisc:=A[2];
 End Else
 If Nm='ENV'Then Begin
  NeedArgs(Nm,N,1);
  S:=GetEnv(ToStr(A[0]));
  If S<>''Then FnMisc:=VStr(S);
 End
  Else
 FnOk:=False;
End;

{ ---- fonctions de geometrie ---- }

Function VGeom(Var G:TGeom):TVal;
Var
 V:TVal;
Begin
 V:=NewV(4);
 New(V.G);
 GeomCopy(G,V.G^);
 VGeom:=V;
End;

{ Resultat geometrique (nul si vide), libere G }
Function GRes(Var G:TGeom):TVal;Begin
 If G.First=Nil Then GRes:=VNull
                Else GRes:=VGeom(G);
 FreeGeom(G);
End;

Function FirstPt(Var G:TGeom;Var X,Y:Real):Boolean;Begin
 FirstPt:=False;
 If(G.First=Nil)or(G.First^.N<1)Then Exit;
 X:=G.First^.Pts^[0].X;Y:=G.First^.Pts^[0].Y;
 FirstPt:=True;
End;

Function GeomVertexCount(Var G:TGeom):LongInt;
Var
 P:PPath;
 N:LongInt;
Begin
 N:=0;
 P:=G.First;
 While P<>Nil do Begin Inc(N,P^.N);P:=P^.Next;End;
 GeomVertexCount:=N;
End;

Function VertexAt(Var G:TGeom;K:LongInt;Var X,Y:Real):Boolean;
Var
 P:PPath;
Begin
 VertexAt:=False;
 P:=G.First;
 While P<>Nil do Begin
  If K<P^.N Then Begin
   X:=P^.Pts^[K].X;Y:=P^.Pts^[K].Y;
   VertexAt:=True;
   Exit;
  End;
  Dec(K,P^.N);
  P:=P^.Next;
 End;
End;

Function PartCount(Var G:TGeom):LongInt;Begin
 If G.Cls=3Then PartCount:=G.NPoly Else PartCount:=G.Count;
End;

{ Union / intersection / difference / difference symetrique de deux geometries }
Procedure GeomSetOp(Mode:Integer;Var A,B:TGeom;Var R:TGeom);
Var
 T1,T2,Empty:TGeom;
Begin
 InitGeom(R);
 If A.First=Nil Then Begin
  If(Mode=0)or(Mode=3)Then GeomCopy(B,R);
  Exit;
 End;
 If B.First=Nil Then Begin
  If Mode<>1Then GeomCopy(A,R);
  Exit;
 End;
 If(A.Cls=3)and(B.Cls=3)Then Begin
  If Mode=3Then Begin
   Overlay(2,A,B,T1);
   Overlay(2,B,A,T2);
   If T1.First=Nil Then GeomCopy(T2,R) Else
   If T2.First=Nil Then GeomCopy(T1,R)
    Else Begin
     GeomAppend(T1,T2);
     InitGeom(Empty);
     Overlay(0,T1,Empty,R);
    End;
   FreeGeom(T1);FreeGeom(T2);
  End Else
  If Mode=0Then Begin
   GeomCopy(A,T1);
   GeomAppend(T1,B);
   InitGeom(Empty);
   Overlay(0,T1,Empty,R);
   FreeGeom(T1);
  End
   Else
  Overlay(Mode,A,B,R);
  Exit;
 End;
 Case Mode of
  0:If A.Cls=B.Cls Then Begin GeomCopy(A,R);GeomAppend(R,B);End;
  1:If B.Cls=3Then Begin ClipOutside:=False;ClipToPolys(A,B,R);End Else
    If A.Cls=3Then Begin ClipOutside:=False;ClipToPolys(B,A,R);End;
  2:If B.Cls=3Then Begin ClipOutside:=True;ClipToPolys(A,B,R);End
     Else GeomCopy(A,R);
  3:If A.Cls=B.Cls Then Begin GeomCopy(A,R);GeomAppend(R,B);End;
 End;
End;

Const
 GeomFnNames1=',AREA,PERIMETER,LENGTH,NUM_POINTS,NUM_GEOMETRIES,NUM_INTERIOR_RINGS,NUM_RINGS,GEOMETRY_TYPE,IS_EMPTY,IS_CLOSED,IS_VALID,X,Y,X_MIN,X_MAX,Y_MIN,Y_MAX,';
 GeomFnNames2='BOUNDS_WIDTH,BOUNDS_HEIGHT,ENVELOPE,BOUNDS,ORIENTED_BBOX,CENTROID,POINT_ON_SURFACE,CONVEX_HULL,START_POINT,END_POINT,POINT_N,NODES_TO_POINTS,SEGMENTS_TO_LINES,';
 GeomFnNames3='EXTERIOR_RING,INTERIOR_RING_N,GEOMETRY_N,BOUNDARY,REVERSE,TRANSLATE,ROTATE,SCALE,AFFINE_TRANSFORM,BUFFER,SIMPLIFY,SIMPLIFY_VW,SMOOTH,DENSIFY_BY_COUNT,OFFSET_CURVE,EXTEND,';
 GeomFnNames4='LINE_INTERPOLATE_POINT,LINE_INTERPOLATE_ANGLE,LINE_SUBSTRING,LINE_LOCATE_POINT,STRAIGHT_DISTANCE_2D,SINUOSITY,PROJECT,AZIMUTH,ANGLE_AT_VERTEX,DISTANCE,CLOSEST_POINT,SHORTEST_LINE,';
 GeomFnNames5='INTERSECTS,CONTAINS,WITHIN,TOUCHES,CROSSES,OVERLAPS,DISJOINT,EQUALS,INTERSECTION,DIFFERENCE,COMBINE,SYM_DIFFERENCE,UNION,TRANSFORM,GEOM_TO_WKT,RELATE,';

Function IsGeomFn(Const Nm:String):Boolean;
Var
 K:String;
Begin
 K:=','+Nm+',';
 IsGeomFn:=(Pos(K,GeomFnNames1)>0)or(Pos(K,','+GeomFnNames2)>0)or(Pos(K,','+GeomFnNames3)>0)or(Pos(K,','+GeomFnNames4)>0)or(Pos(K,','+GeomFnNames5)>0);
End;

Function FnGeom(Const Nm:String;Var A:Array of TVal;N:Integer):TVal;
Var
 R,R2,R3,R4,R5,R6,Cx,Cy,X1,Y1,X2,Y2,Ang,D,L:Real;
 I,K,Cnt:LongInt;
 Res,Tmp:TGeom;
 P,Q,Px:PPath;
 Ok:Boolean;
 S:String;
 B:TBuf;
 Pjs:PJ;
 Sr,Ds:LongInt;
 Gp:PGeom;
 M:Array[1..6]of Real;
 Poly:Integer;

 Function G0:PGeom;Begin
  If(N>0)and(A[0].K=4)Then G0:=A[0].G Else G0:=Nil;
 End;

 Function G1:PGeom;Begin
  If(N>1)and(A[1].K=4)Then G1:=A[1].G Else G1:=Nil;
 End;

Begin
 FnGeom:=VNull;
 FnOk:=True;
 { constructeurs (sans geometrie en entree) }
 If Nm='MAKE_POINT'Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,0,R)and NumArg(A,1,R2)Then Begin PointGeom(Res,R,R2);FnGeom:=GRes(Res);End;
  Exit;
 End;
 If Nm='GEOM_FROM_WKT'Then Begin
  NeedArgs(Nm,N,1);
  If A[0].K=2Then Begin
   S:=A[0].S;
   If S<>''Then Begin
    Pjs:=WktToGeom(@S[1],0,Length(S));
    If Pjs<>Nil Then Begin Flatten(Pjs,Res);FnGeom:=GRes(Res);End;
   End;
  End;
  Exit;
 End;
 If Nm='GEOM_FROM_GEOJSON'Then Begin
  NeedArgs(Nm,N,1);
  Exit;
 End;
 If Nm='MAKE_CIRCLE'Then Begin
  NeedArgs(Nm,N,2);
  If(G0<>Nil)and FirstPt(G0^,Cx,Cy)and NumArg(A,1,R)Then Begin
   K:=9;
   If NumArg(A,2,R2)Then K:=Round(R2)div 4;
   If K<1Then K:=1;
   InitGeom(Res);Res.Cls:=3;Res.NPoly:=1;
   AddCircle(Res,Cx,Cy,R,K,0);
   FnGeom:=GRes(Res);
  End;
  Exit;
 End;
 If(Nm='MAKE_LINE')or(Nm='MAKE_POLYGON')Then Begin
  NeedArgs(Nm,N,1);
  If Nm='MAKE_LINE'Then Begin
   TpClear;
   For I:=0 to N-1do Begin
    If A[I].K=4Then Begin
     P:=A[I].G^.First;
     While P<>Nil do Begin
      For K:=0 to P^.N-1do TpAdd(P^.Pts^[K].X,P^.Pts^[K].Y);
      P:=P^.Next;
     End;
    End Else
    If A[I].K=5Then Begin
     For K:=0 to A[I].L^.Cnt-1do
      If A[I].L^.V^[K].K=4Then Begin
       P:=A[I].L^.V^[K].G^.First;
       While P<>Nil do Begin
        For Cnt:=0 to P^.N-1do TpAdd(P^.Pts^[Cnt].X,P^.Pts^[Cnt].Y);
        P:=P^.Next;
       End;
      End;
    End;
   End;
   If TpN>=2Then Begin
    InitGeom(Res);Res.Cls:=2;
    P:=NewPath(Res,TpN,0);
    Move(TpP^,P^.Pts^,TpN*SizeOf(TPt));
    FnGeom:=GRes(Res);
   End;
  End
   Else
  Begin
   InitGeom(Res);Res.Cls:=3;Res.NPoly:=1;
   For I:=0 to N-1do Begin
    If(A[I].K=4)and(A[I].G^.First<>Nil)Then Begin
     P:=A[I].G^.First;
     K:=P^.N;
     If K>=3Then Begin
      Px:=NewPath(Res,K+1,0);
      Move(P^.Pts^,Px^.Pts^,K*SizeOf(TPt));
      If(P^.Pts^[0].X<>P^.Pts^[K-1].X)or(P^.Pts^[0].Y<>P^.Pts^[K-1].Y)Then Begin
       Px^.Pts^[K]:=P^.Pts^[0];Px^.N:=K+1;
      End
       Else Px^.N:=K;
     End;
    End;
   End;
   If(Res.First<>Nil)and(Res.First^.N>=4)Then Begin
    OrientPolygons(Res);
    FnGeom:=GRes(Res);
   End
    Else FreeGeom(Res);
  End;
  Exit;
 End;
 If Nm='COLLECT_GEOMETRIES'Then Begin
  InitGeom(Res);
  For I:=0 to N-1do Begin
   If A[I].K=4Then Begin
    If Res.Cls=0Then Begin GeomCopy(A[I].G^,Res);End
     Else If Res.Cls=A[I].G^.Cls Then GeomAppend(Res,A[I].G^);
   End Else
   If A[I].K=5Then
    For K:=0 to A[I].L^.Cnt-1do
     If A[I].L^.V^[K].K=4Then Begin
      If Res.Cls=0Then GeomCopy(A[I].L^.V^[K].G^,Res)
       Else If Res.Cls=A[I].L^.V^[K].G^.Cls Then GeomAppend(Res,A[I].L^.V^[K].G^);
     End;
  End;
  FnGeom:=GRes(Res);
  Exit;
 End;
 If(N=0)or(A[0].K<>4)Then Begin
  FnOk:=(N>0)and(A[0].K=0)and IsGeomFn(Nm);
  Exit;
 End;
 Gp:=A[0].G;
 { fonctions de mesure }
 If Nm='AREA'Then FnGeom:=VNum(GeomArea(Gp^)) Else
 If(Nm='PERIMETER')Then FnGeom:=VNum(GeomLength(Gp^)) Else
 If Nm='LENGTH'Then FnGeom:=VNum(GeomLength(Gp^)) Else
 If Nm='NUM_POINTS'Then FnGeom:=VNum(GeomVertexCount(Gp^)) Else
 If Nm='NUM_GEOMETRIES'Then FnGeom:=VNum(PartCount(Gp^)) Else
 If Nm='NUM_INTERIOR_RINGS'Then Begin
  If Gp^.Cls=3Then Begin
   Cnt:=0;P:=Gp^.First;
   While P<>Nil do Begin Inc(Cnt);P:=P^.Next;End;
   FnGeom:=VNum(Cnt-Gp^.NPoly);
  End;
 End Else
 If Nm='NUM_RINGS'Then Begin
  If Gp^.Cls=3Then FnGeom:=VNum(Gp^.Count);
 End Else
 If Nm='GEOMETRY_TYPE'Then Begin
  Case Gp^.Cls of
   1:FnGeom:=VStr('Point');
   2:FnGeom:=VStr('Line');
   3:FnGeom:=VStr('Polygon');
  End;
 End Else
 If Nm='IS_EMPTY'Then FnGeom:=VBool(Gp^.First=Nil) Else
 If Nm='IS_CLOSED'Then Begin
  If Gp^.Cls=2Then Begin
   Ok:=True;P:=Gp^.First;
   While P<>Nil do Begin
    If(P^.N<2)or(P^.Pts^[0].X<>P^.Pts^[P^.N-1].X)or(P^.Pts^[0].Y<>P^.Pts^[P^.N-1].Y)Then Ok:=False;
    P:=P^.Next;
   End;
   FnGeom:=VBool(Ok);
  End Else If Gp^.Cls=3Then FnGeom:=VBool(True);
 End Else
 If Nm='IS_VALID'Then Begin
  Ok:=True;
  P:=Gp^.First;
  While P<>Nil do Begin
   If Gp^.Cls=3Then Begin
    If(P^.N<4)or(P^.Pts^[0].X<>P^.Pts^[P^.N-1].X)or(P^.Pts^[0].Y<>P^.Pts^[P^.N-1].Y)Then Ok:=False;
   End Else
   If(Gp^.Cls=2)and(P^.N<2)Then Ok:=False;
   P:=P^.Next;
  End;
  FnGeom:=VBool(Ok);
 End Else
 If(Nm='X')or(Nm='Y')Then Begin
  CentroidGeom(Gp^,Cx,Cy,Ok);
  If Ok Then Begin If Nm='X'Then FnGeom:=VNum(Cx) Else FnGeom:=VNum(Cy);End;
 End Else
 If(Nm='X_MIN')or(Nm='X_MAX')or(Nm='Y_MIN')or(Nm='Y_MAX')Then Begin
  If GeomBBox(Gp^,X1,Y1,X2,Y2)Then Begin
   If Nm='X_MIN'Then FnGeom:=VNum(X1) Else If Nm='X_MAX'Then FnGeom:=VNum(X2) Else
   If Nm='Y_MIN'Then FnGeom:=VNum(Y1) Else FnGeom:=VNum(Y2);
  End;
 End Else
 If(Nm='BOUNDS_WIDTH')or(Nm='BOUNDS_HEIGHT')Then Begin
  If GeomBBox(Gp^,X1,Y1,X2,Y2)Then Begin
   If Nm='BOUNDS_WIDTH'Then FnGeom:=VNum(X2-X1) Else FnGeom:=VNum(Y2-Y1);
  End;
 End Else
 If(Nm='ENVELOPE')or(Nm='BOUNDS')Then Begin
  If GeomBBox(Gp^,X1,Y1,X2,Y2)Then Begin
   InitGeom(Res);Res.Cls:=3;Res.NPoly:=1;
   P:=NewPath(Res,5,0);
   P^.Pts^[0].X:=X1;P^.Pts^[0].Y:=Y1;P^.Pts^[1].X:=X2;P^.Pts^[1].Y:=Y1;
   P^.Pts^[2].X:=X2;P^.Pts^[2].Y:=Y2;P^.Pts^[3].X:=X1;P^.Pts^[3].Y:=Y2;
   P^.Pts^[4]:=P^.Pts^[0];
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='ORIENTED_BBOX'Then Begin
  MinOrientedBox(Gp^,Res,D,Ang,R,R2);
  FnGeom:=GRes(Res);
 End Else
 If Nm='CENTROID'Then Begin
  CentroidGeom(Gp^,Cx,Cy,Ok);
  If Ok Then Begin PointGeom(Res,Cx,Cy);FnGeom:=GRes(Res);End;
 End Else
 If Nm='POINT_ON_SURFACE'Then Begin
  If Gp^.First<>Nil Then Begin
   PointOnSurface(Gp^,Cx,Cy);
   PointGeom(Res,Cx,Cy);FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='CONVEX_HULL'Then Begin
  HullGeom(Gp^,Res);
  FnGeom:=GRes(Res);
 End Else
 If Nm='START_POINT'Then Begin
  If FirstPt(Gp^,Cx,Cy)Then Begin PointGeom(Res,Cx,Cy);FnGeom:=GRes(Res);End;
 End Else
 If Nm='END_POINT'Then Begin
  If Gp^.Last<>Nil Then Begin
   P:=Gp^.Last;
   PointGeom(Res,P^.Pts^[P^.N-1].X,P^.Pts^[P^.N-1].Y);
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='POINT_N'Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,1,R)Then Begin
   K:=Round(R);
   If K<0Then K:=GeomVertexCount(Gp^)+K+1;
   If(K>=1)and VertexAt(Gp^,K-1,Cx,Cy)Then Begin PointGeom(Res,Cx,Cy);FnGeom:=GRes(Res);End;
  End;
 End Else
 If Nm='NODES_TO_POINTS'Then Begin
  InitGeom(Res);Res.Cls:=1;
  P:=Gp^.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-1do Begin
    If(Gp^.Cls<>3)or(I<P^.N-1)Then Begin
     Px:=NewPath(Res,1,0);
     Px^.Pts^[0]:=P^.Pts^[I];
    End;
   End;
   P:=P^.Next;
  End;
  FnGeom:=GRes(Res);
 End Else
 If Nm='SEGMENTS_TO_LINES'Then Begin
  InitGeom(Res);Res.Cls:=2;
  P:=Gp^.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-2do Begin
    Px:=NewPath(Res,2,0);
    Px^.Pts^[0]:=P^.Pts^[I];Px^.Pts^[1]:=P^.Pts^[I+1];
   End;
   P:=P^.Next;
  End;
  FnGeom:=GRes(Res);
 End Else
 If(Nm='EXTERIOR_RING')or(Nm='INTERIOR_RING_N')or(Nm='GEOMETRY_N')Then Begin
  If Nm='EXTERIOR_RING'Then Begin K:=1;End Else Begin
   NeedArgs(Nm,N,2);
   If Not NumArg(A,1,R)Then Exit;
   K:=Round(R);
  End;
  If Nm='GEOMETRY_N'Then Begin
   If K<1Then Exit;
   InitGeom(Res);Res.Cls:=Gp^.Cls;
   If Gp^.Cls=3Then Begin
    P:=Gp^.First;Cnt:=0;Poly:=-1;
    While P<>Nil do Begin
     If P^.Poly<>Poly Then Begin Inc(Cnt);Poly:=P^.Poly;End;
     If Cnt=K Then CopyPath(Res,P,0);
     P:=P^.Next;
    End;
    Res.NPoly:=1;
   End
    Else
   Begin
    P:=Gp^.First;Cnt:=0;
    While P<>Nil do Begin
     Inc(Cnt);
     If Cnt=K Then CopyPath(Res,P,0);
     P:=P^.Next;
    End;
   End;
   FnGeom:=GRes(Res);
  End
   Else
  If Gp^.Cls=3Then Begin
   P:=Gp^.First;Cnt:=0;
   While(P<>Nil)and(P^.Poly=Gp^.First^.Poly)do Begin
    If((Nm='EXTERIOR_RING')and(Cnt=0))or((Nm='INTERIOR_RING_N')and(Cnt=K)and(K>=1))Then Begin
     InitGeom(Res);Res.Cls:=2;
     CopyPath(Res,P,0);
     FnGeom:=GRes(Res);
     Exit;
    End;
    Inc(Cnt);
    P:=P^.Next;
   End;
  End;
 End Else
 If Nm='BOUNDARY'Then Begin
  InitGeom(Res);
  If Gp^.Cls=3Then Begin
   Res.Cls:=2;
   P:=Gp^.First;
   While P<>Nil do Begin CopyPath(Res,P,0);P:=P^.Next;End;
  End Else
  If Gp^.Cls=2Then Begin
   Res.Cls:=1;
   P:=Gp^.First;
   While P<>Nil do Begin
    Px:=NewPath(Res,1,0);Px^.Pts^[0]:=P^.Pts^[0];
    Px:=NewPath(Res,1,0);Px^.Pts^[0]:=P^.Pts^[P^.N-1];
    P:=P^.Next;
   End;
  End;
  FnGeom:=GRes(Res);
 End Else
 If Nm='REVERSE'Then Begin
  GeomCopy(Gp^,Res);
  P:=Res.First;
  While P<>Nil do Begin
   For I:=0 to P^.N div 2-1do Begin
    Cx:=P^.Pts^[I].X;Cy:=P^.Pts^[I].Y;
    P^.Pts^[I]:=P^.Pts^[P^.N-1-I];
    P^.Pts^[P^.N-1-I].X:=Cx;P^.Pts^[P^.N-1-I].Y:=Cy;
   End;
   P:=P^.Next;
  End;
  FnGeom:=GRes(Res);
 End Else
 If Nm='TRANSLATE'Then Begin
  NeedArgs(Nm,N,3);
  If NumArg(A,1,R)and NumArg(A,2,R2)Then Begin
   GeomCopy(Gp^,Res);
   AffineGeom(Res,1,0,0,1,R,R2);
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='ROTATE'Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,1,R)Then Begin
   If(G1<>Nil)and FirstPt(G1^,Cx,Cy)Then Begin End
    Else Begin
     If Not GeomBBox(Gp^,X1,Y1,X2,Y2)Then Exit;
     Cx:=(X1+X2)/2;Cy:=(Y1+Y2)/2;
    End;
   If(N>2)and(A[2].K=4)and FirstPt(A[2].G^,Cx,Cy)Then Begin End;
   R:=R*Pi/180;
   GeomCopy(Gp^,Res);
   AffineGeom(Res,Cos(R),Sin(R),-Sin(R),Cos(R),Cx-Cx*Cos(R)-Cy*Sin(R),Cy+Cx*Sin(R)-Cy*Cos(R));
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='SCALE'Then Begin
  NeedArgs(Nm,N,3);
  If NumArg(A,1,R)and NumArg(A,2,R2)Then Begin
   If(N>3)and(A[3].K=4)and FirstPt(A[3].G^,Cx,Cy)Then Begin End
    Else Begin
     If Not GeomBBox(Gp^,X1,Y1,X2,Y2)Then Exit;
     Cx:=(X1+X2)/2;Cy:=(Y1+Y2)/2;
    End;
   GeomCopy(Gp^,Res);
   AffineGeom(Res,R,0,0,R2,Cx-Cx*R,Cy-Cy*R2);
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='AFFINE_TRANSFORM'Then Begin
  NeedArgs(Nm,N,6);
  If NumArg(A,1,R)and NumArg(A,2,R2)and NumArg(A,3,R3)and NumArg(A,4,R4)and NumArg(A,5,R5)Then Begin
   GeomCopy(Gp^,Res);
   R3:=R3*Pi/180;
   AffineGeom(Res,R4*Cos(R3),R5*Sin(R3),-R4*Sin(R3),R5*Cos(R3),R,R2);
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='BUFFER'Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,1,R)Then Begin
   K:=5;
   If NumArg(A,2,R2)Then K:=Round(R2);
   BufCap:=0;BufJoin:=0;BufMiter:=2;
   If(N>3)and(A[3].K=2)Then Begin
    S:=LowerStr(A[3].S);
    If S='flat'Then BufCap:=1 Else If S='square'Then BufCap:=2 Else If S<>'round'Then EFail('end cap must be round, flat or square');
   End;
   If(N>4)and(A[4].K=2)Then Begin
    S:=LowerStr(A[4].S);
    If S='miter'Then BufJoin:=1 Else If S='bevel'Then BufJoin:=2 Else If S<>'round'Then EFail('join must be round, miter or bevel');
   End;
   If NumArg(A,5,R3)Then BufMiter:=R3;
   BufferGeom(Gp^,R,K,Res);
   BufCap:=0;BufJoin:=0;BufMiter:=2;
   FnGeom:=GRes(Res);
  End;
 End Else
 If(Nm='SIMPLIFY')or(Nm='SIMPLIFY_VW')Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,1,R)Then Begin
   InitGeom(Res);Res.Cls:=Gp^.Cls;
   P:=Gp^.First;
   While P<>Nil do Begin
    If Gp^.Cls=1Then CopyPath(Res,P,0)
     Else If Nm='SIMPLIFY'Then Ok:=SimplifyDP(P,R,Gp^.Cls=3,Res,P^.Poly)
     Else Ok:=SimplifyVW(P,R,Gp^.Cls=3,Res,P^.Poly);
    P:=P^.Next;
   End;
   Res.NPoly:=Gp^.NPoly;
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='SMOOTH'Then Begin
  NeedArgs(Nm,N,1);
  K:=1;R2:=0.25;R3:=180;
  If NumArg(A,1,R)Then K:=Round(R);
  If NumArg(A,2,R)Then R2:=R;
  If NumArg(A,4,R)Then R3:=R;
  InitGeom(Res);Res.Cls:=Gp^.Cls;
  P:=Gp^.First;
  While P<>Nil do Begin
   If Gp^.Cls=1Then CopyPath(Res,P,0)
    Else SmoothPath(P,K,R2,R3,Gp^.Cls=3,Res,P^.Poly);
   P:=P^.Next;
  End;
  Res.NPoly:=Gp^.NPoly;
  FnGeom:=GRes(Res);
 End Else
 If Nm='DENSIFY_BY_COUNT'Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,1,R)Then Begin
   InitGeom(Res);Res.Cls:=Gp^.Cls;
   P:=Gp^.First;
   While P<>Nil do Begin
    If Gp^.Cls=1Then CopyPath(Res,P,0) Else DensifyPath(P,Round(R),Res,P^.Poly);
    P:=P^.Next;
   End;
   Res.NPoly:=Gp^.NPoly;
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='OFFSET_CURVE'Then Begin
  NeedArgs(Nm,N,2);
  If(Gp^.Cls=2)and NumArg(A,1,R)Then Begin
   K:=8;
   If NumArg(A,2,R2)Then K:=Round(R2);
   InitGeom(Res);Res.Cls:=2;
   P:=Gp^.First;
   While P<>Nil do Begin OffsetCurve(Res,P,R,K);P:=P^.Next;End;
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='EXTEND'Then Begin
  NeedArgs(Nm,N,3);
  If(Gp^.Cls=2)and NumArg(A,1,R)and NumArg(A,2,R2)Then Begin
   GeomCopy(Gp^,Res);
   P:=Res.First;
   While P<>Nil do Begin
    If P^.N>=2Then Begin
     L:=Sqrt(Sqr(P^.Pts^[1].X-P^.Pts^[0].X)+Sqr(P^.Pts^[1].Y-P^.Pts^[0].Y));
     If L>0Then Begin
      P^.Pts^[0].X:=P^.Pts^[0].X-R*(P^.Pts^[1].X-P^.Pts^[0].X)/L;
      P^.Pts^[0].Y:=P^.Pts^[0].Y-R*(P^.Pts^[1].Y-P^.Pts^[0].Y)/L;
     End;
     K:=P^.N-1;
     L:=Sqrt(Sqr(P^.Pts^[K].X-P^.Pts^[K-1].X)+Sqr(P^.Pts^[K].Y-P^.Pts^[K-1].Y));
     If L>0Then Begin
      P^.Pts^[K].X:=P^.Pts^[K].X+R2*(P^.Pts^[K].X-P^.Pts^[K-1].X)/L;
      P^.Pts^[K].Y:=P^.Pts^[K].Y+R2*(P^.Pts^[K].Y-P^.Pts^[K-1].Y)/L;
     End;
    End;
    P:=P^.Next;
   End;
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='LINE_INTERPOLATE_POINT'Then Begin
  NeedArgs(Nm,N,2);
  If(Gp^.Cls=2)and NumArg(A,1,R)and(Gp^.First<>Nil)Then
   If PointAlong(Gp^.First,R,Cx,Cy,Ang)Then Begin PointGeom(Res,Cx,Cy);FnGeom:=GRes(Res);End;
 End Else
 If Nm='LINE_INTERPOLATE_ANGLE'Then Begin
  NeedArgs(Nm,N,2);
  If(Gp^.Cls=2)and NumArg(A,1,R)and(Gp^.First<>Nil)Then
   If PointAlong(Gp^.First,R,Cx,Cy,Ang)Then FnGeom:=VNum(Ang);
 End Else
 If Nm='LINE_SUBSTRING'Then Begin
  NeedArgs(Nm,N,3);
  If(Gp^.Cls=2)and NumArg(A,1,R)and NumArg(A,2,R2)and(Gp^.First<>Nil)Then Begin
   InitGeom(Res);Res.Cls:=2;
   If SubLine(Gp^.First,R,R2,Res,0)Then FnGeom:=GRes(Res) Else FreeGeom(Res);
  End;
 End Else
 If Nm='LINE_LOCATE_POINT'Then Begin
  NeedArgs(Nm,N,2);
  If(Gp^.Cls=2)and(G1<>Nil)and FirstPt(G1^,Cx,Cy)and(Gp^.First<>Nil)Then Begin
   P:=Gp^.First;
   D:=1E300;L:=0;Ang:=0;
   For I:=0 to P^.N-2do Begin
    ClosestOnSeg(Cx,Cy,P^.Pts^[I].X,P^.Pts^[I].Y,P^.Pts^[I+1].X,P^.Pts^[I+1].Y,X1,Y1);
    R:=Sqrt(Sqr(X1-Cx)+Sqr(Y1-Cy));
    If R<D Then Begin
     D:=R;
     Ang:=L+Sqrt(Sqr(X1-P^.Pts^[I].X)+Sqr(Y1-P^.Pts^[I].Y));
    End;
    L:=L+Sqrt(Sqr(P^.Pts^[I+1].X-P^.Pts^[I].X)+Sqr(P^.Pts^[I+1].Y-P^.Pts^[I].Y));
   End;
   FnGeom:=VNum(Ang);
  End;
 End Else
 If Nm='STRAIGHT_DISTANCE_2D'Then Begin
  If(Gp^.Cls=2)and(Gp^.First<>Nil)Then Begin
   P:=Gp^.First;Q:=Gp^.Last;
   FnGeom:=VNum(Sqrt(Sqr(P^.Pts^[0].X-Q^.Pts^[Q^.N-1].X)+Sqr(P^.Pts^[0].Y-Q^.Pts^[Q^.N-1].Y)));
  End;
 End Else
 If Nm='SINUOSITY'Then Begin
  If(Gp^.Cls=2)and(Gp^.First<>Nil)Then Begin
   P:=Gp^.First;Q:=Gp^.Last;
   D:=Sqrt(Sqr(P^.Pts^[0].X-Q^.Pts^[Q^.N-1].X)+Sqr(P^.Pts^[0].Y-Q^.Pts^[Q^.N-1].Y));
   If D>0Then FnGeom:=VNum(GeomLength(Gp^)/D);
  End;
 End Else
 If Nm='PROJECT'Then Begin
  NeedArgs(Nm,N,3);
  If FirstPt(Gp^,Cx,Cy)and NumArg(A,1,R)and NumArg(A,2,R2)Then Begin
   PointGeom(Res,Cx+R*Sin(R2),Cy+R*Cos(R2));
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='AZIMUTH'Then Begin
  NeedArgs(Nm,N,2);
  If(G1<>Nil)and FirstPt(Gp^,Cx,Cy)and FirstPt(G1^,X2,Y2)Then Begin
   Ang:=Atan2(X2-Cx,Y2-Cy);
   If Ang<0Then Ang:=Ang+2*Pi;
   FnGeom:=VNum(Ang);
  End;
 End Else
 If Nm='ANGLE_AT_VERTEX'Then Begin
  NeedArgs(Nm,N,2);
  If NumArg(A,1,R)Then Begin
   K:=Round(R);
   Cnt:=GeomVertexCount(Gp^);
   If(K>=0)and(K<Cnt)and VertexAt(Gp^,K,Cx,Cy)Then Begin
    Ok:=VertexAt(Gp^,K-1,X1,Y1)and(K>0);
    If VertexAt(Gp^,K+1,X2,Y2)and(K+1<Cnt)Then Begin
     If Ok Then Begin
      R2:=Atan2(Cx-X1,Cy-Y1);R3:=Atan2(X2-Cx,Y2-Cy);
      R4:=R3-R2;
      While R4>Pi do R4:=R4-2*Pi;
      While R4<-Pi do R4:=R4+2*Pi;
      Ang:=R2+R4/2;
     End
      Else Ang:=Atan2(X2-Cx,Y2-Cy);
    End
     Else If Ok Then Ang:=Atan2(Cx-X1,Cy-Y1) Else Exit;
    Ang:=NormDeg(Rad2Deg(Ang));
    FnGeom:=VNum(Ang);
   End;
  End;
 End Else
 If(Nm='DISTANCE')or(Nm='CLOSEST_POINT')or(Nm='SHORTEST_LINE')Then Begin
  NeedArgs(Nm,N,2);
  If(G1<>Nil)and(Gp^.First<>Nil)and(G1^.First<>Nil)Then Begin
   D:=NearestPoints(Gp^,G1^,X1,Y1,X2,Y2);
   If Nm='DISTANCE'Then FnGeom:=VNum(D) Else
   If Nm='CLOSEST_POINT'Then Begin PointGeom(Res,X1,Y1);FnGeom:=GRes(Res);End
    Else Begin
     InitGeom(Res);Res.Cls:=2;
     P:=NewPath(Res,2,0);
     P^.Pts^[0].X:=X1;P^.Pts^[0].Y:=Y1;P^.Pts^[1].X:=X2;P^.Pts^[1].Y:=Y2;
     FnGeom:=GRes(Res);
    End;
  End;
 End Else
 If(Nm='INTERSECTS')or(Nm='CONTAINS')or(Nm='WITHIN')or(Nm='TOUCHES')or(Nm='CROSSES')or(Nm='OVERLAPS')or(Nm='DISJOINT')or(Nm='EQUALS')Then Begin
  NeedArgs(Nm,N,2);
  If(G1<>Nil)Then Begin
   If Nm='INTERSECTS'Then K:=0 Else If Nm='CONTAINS'Then K:=1 Else If Nm='DISJOINT'Then K:=2 Else
   If Nm='EQUALS'Then K:=3 Else If Nm='TOUCHES'Then K:=4 Else If Nm='OVERLAPS'Then K:=5 Else
   If Nm='WITHIN'Then K:=6 Else K:=7;
   If(Gp^.First=Nil)or(G1^.First=Nil)Then FnGeom:=VBool(Nm='DISJOINT')
    Else FnGeom:=VBool(GeomPredicate(K,Gp^,G1^));
  End;
 End Else
 If(Nm='INTERSECTION')or(Nm='DIFFERENCE')or(Nm='COMBINE')or(Nm='SYM_DIFFERENCE')or(Nm='UNION')Then Begin
  NeedArgs(Nm,N,2);
  If G1<>Nil Then Begin
   If Nm='INTERSECTION'Then K:=1 Else If Nm='DIFFERENCE'Then K:=2 Else
   If Nm='SYM_DIFFERENCE'Then K:=3 Else K:=0;
   GeomSetOp(K,Gp^,G1^,Res);
   FnGeom:=GRes(Res);
  End;
 End Else
 If Nm='TRANSFORM'Then Begin
  NeedArgs(Nm,N,3);
  If ParseCrsName(ToStr(A[1]),Sr)and ParseCrsName(ToStr(A[2]),Ds)Then Begin
   GeomCopy(Gp^,Res);
   P:=Res.First;Ok:=True;
   While P<>Nil do Begin
    For I:=0 to P^.N-1do Begin
     Cx:=P^.Pts^[I].X;Cy:=P^.Pts^[I].Y;
     If TryTransform(Sr,Ds,Cx,Cy)Then Begin P^.Pts^[I].X:=Cx;P^.Pts^[I].Y:=Cy;End
                                  Else Ok:=False;
    End;
    P:=P^.Next;
   End;
   If Ok Then FnGeom:=GRes(Res) Else FreeGeom(Res);
  End
   Else EFail('unknown coordinate reference system');
 End Else
 If Nm='RELATE'Then Begin
  NeedArgs(Nm,N,2);
  If G1<>Nil Then Begin
   S:=RelateGeoms(Gp^,G1^);
   If(N>2)and(A[2].K=2)Then FnGeom:=VBool(RelateMatch(S,A[2].S))
                       Else FnGeom:=VStr(S);
  End;
 End Else
 If Nm='GEOM_TO_WKT'Then Begin
  BufInit(B);
  BufWkt(B,Gp^);
  S:='';
  For I:=0 to B.N-1do If Length(S)<255Then S:=S+Chr(B.P^[I]);
  FnGeom:=VStr(S);
  FreeMem(B.P,B.Cap);
 End
  Else
 FnOk:=False;
End;

{ ---- contexte d'evaluation, variables, couches, agregats ---- }

Function EvalOr:TVal;Forward;

Type
 TCtx=Record
  S:String;
  P:Integer;
  Props,Feat,Parent:PJ;
  G:TGeom;
  Id:LongInt;
 End;
 TVarRec=Record
  Name:String[40];
  V:TVal;
 End;

Var
 VarStack:Array[1..32]of TVarRec;
 VarN:Integer;
 LayerCache:Array[1..8]of PJ;
 LayerCacheName:Array[1..8]of String[100];
 LayerCacheN:Integer;

Procedure SaveCtx(Var C:TCtx);Begin
 C.S:=ExprS;C.P:=ExprP;C.Props:=ExprProps;C.Feat:=ExprFeat;C.Parent:=ExprParent;C.G:=ExprGeom;C.Id:=ExprId;
End;

Procedure RestoreCtx(Var C:TCtx);Begin
 ExprS:=C.S;ExprP:=C.P;ExprProps:=C.Props;ExprFeat:=C.Feat;ExprParent:=C.Parent;ExprGeom:=C.G;ExprId:=C.Id;
End;

{ Evalue un texte dans le contexte courant }
Function EvalSub(Const Expr:String):TVal;
Var
 C:TCtx;
 V:TVal;
Begin
 SaveCtx(C);
 Inc(ExprDepth);
 If ExprDepth>40Then EFail('expression nesting too deep');
 ExprS:=Expr;ExprP:=1;
 V:=EvalOr;
 ESkip;
 If ExprP<=Length(ExprS)Then EFail('unexpected token');
 Dec(ExprDepth);
 RestoreCtx(C);
 EvalSub:=V;
End;

{ Evalue un texte sur une autre entite (la courante devient @parent) }
Function EvalSubFeat(Const Expr:String;F:PJ;Id:LongInt):TVal;
Var
 C:TCtx;
 V:TVal;
Begin
 SaveCtx(C);
 Inc(ExprDepth);
 If ExprDepth>40Then EFail('expression nesting too deep');
 ExprParent:=ExprFeat;
 ExprFeat:=F;
 ExprProps:=JFind(F,'properties');
 InitGeom(ExprGeom);
 Flatten(JFind(F,'geometry'),ExprGeom);
 ExprId:=Id;
 ExprS:=Expr;ExprP:=1;
 V:=EvalOr;
 ESkip;
 If ExprP<=Length(ExprS)Then EFail('unexpected token');
 Dec(ExprDepth);
 FreeGeom(ExprGeom);
 RestoreCtx(C);
 EvalSubFeat:=V;
End;

Procedure PushVar(Const Name:String;Const V:TVal);Begin
 If VarN>=32Then EFail('too many nested variables');
 Inc(VarN);
 VarStack[VarN].Name:=StrUpper(Name);
 VarStack[VarN].V:=V;
End;

Function JToVal(N:PJ):TVal;
Var
 R:Real;
 E:Integer;
 L:PValList;
 C:PJ;
Begin
 JToVal:=VNull;
 If N=Nil Then Exit;
 Case N^.Kind of
  1:JToVal:=VBool(JVal(N)='true');
  2:Begin
   Val(JVal(N),R,E);
   If E=0Then JToVal:=VNum(R);
  End;
  3:JToVal:=VStr(Unesc(JVal(N)));
  4:Begin
   L:=LNew;
   C:=N^.First;
   While C<>Nil do Begin LAdd(L,JToVal(C));C:=C^.Next;End;
   JToVal:=VList(L);
  End;
  5:Begin
   L:=LNew;
   C:=N^.First;
   While C<>Nil do Begin LAdd(L,VStr(JKey(C)));LAdd(L,JToVal(C));C:=C^.Next;End;
   JToVal:=VMapOf(L);
  End;
 End;
End;

Function FeatProp(F:PJ;Const Name:String):TVal;Begin
 FeatProp:=VNull;
 If F=Nil Then Exit;
 FeatProp:=JToVal(JFind(JFind(F,'properties'),Name));
End;

Function FeatGeom(F:PJ):TVal;
Var
 G:TGeom;
Begin
 FeatGeom:=VNull;
 If F=Nil Then Exit;
 InitGeom(G);
 Flatten(JFind(F,'geometry'),G);
 If G.First<>Nil Then FeatGeom:=VGeom(G);
 FreeGeom(G);
End;

Function ProjectBase:String;
Var
 I:Integer;
 S:String;
Begin
 S:=ProjectPath;
 For I:=Length(S)downto 1do If S[I]in['/',#92]Then Begin S:=Copy(S,I+1,255);Break;End;
 ProjectBase:=S;
End;

Function ProjectDir:String;
Var
 I:Integer;
Begin
 ProjectDir:='';
 For I:=Length(ProjectPath)downto 1do If ProjectPath[I]in['/',#92]Then Begin ProjectDir:=Copy(ProjectPath,1,I-1);Exit;End;
End;

Function ExprVar(Const Nm:String):TVal;
Var
 I:LongInt;
 S:String;
 F:PJ;
Begin
 ExprVar:=VNull;
 For I:=VarN downto 1do If VarStack[I].Name=Nm Then Begin ExprVar:=VarStack[I].V;Exit;End;
 If Nm='FEATURE'Then ExprVar:=VFeat(ExprFeat) Else
 If Nm='PARENT'Then Begin If ExprParent<>Nil Then ExprVar:=VFeat(ExprParent);End Else
 If Nm='ID'Then ExprVar:=VNum(ExprId) Else
 If Nm='ROW_NUMBER'Then ExprVar:=VNum(ExprId+1) Else
 If Nm='GEOMETRY'Then Begin If ExprGeom.First<>Nil Then ExprVar:=VGeom(ExprGeom);End Else
 If Nm='LAYER_NAME'Then Begin If ExprLayerName<>''Then ExprVar:=VStr(ExprLayerName);End Else
 If Nm='LAYER_ID'Then Begin If ExprLayerName<>''Then ExprVar:=VStr(ExprLayerName);End Else
 If Nm='QGIS_VERSION'Then ExprVar:=VStr('3.34.0-Prizren') Else
 If Nm='QGIS_VERSION_NO'Then ExprVar:=VNum(33400) Else
 If Nm='PROJECT_PATH'Then Begin If ProjectPath<>''Then ExprVar:=VStr(ProjectPath);End Else
 If Nm='PROJECT_FOLDER'Then Begin If ProjectPath<>''Then ExprVar:=VStr(ProjectDir);End Else
 If Nm='PROJECT_FILENAME'Then Begin If ProjectPath<>''Then ExprVar:=VStr(ProjectBase);End Else
 If(Nm='PROJECT_BASENAME')or(Nm='PROJECT_TITLE')Then Begin
  If ProjectPath<>''Then ExprVar:=VStr(BaseNoExt(ProjectPath));
 End Else
 If(Nm='USER_ACCOUNT_NAME')or(Nm='USER_FULL_NAME')Then Begin
  S:=GetEnv('USER');
  If S=''Then S:=GetEnv('USERNAME');
  If Nm='USER_ACCOUNT_NAME'Then ExprVar:=VStr(S) Else ExprVar:=VStr('');
 End Else
 If Nm='QGIS_OS_NAME'Then ExprVar:=VStr('linux') Else
 If Nm='QGIS_PLATFORM'Then ExprVar:=VStr('desktop') Else
 If Nm='LAYER_FEATURE_COUNT'Then Begin
  If ExprLayer<>Nil Then Begin
   I:=0;
   F:=JFind(ExprLayer,'features')^.First;
   While F<>Nil do Begin Inc(I);F:=F^.Next;End;
   ExprVar:=VNum(I);
  End;
 End;
End;

{ Couche designee dans une expression (nom, chemin ou couche courante) }
Function ExprGetLayer(Const Name:String):PJ;
Var
 I:Integer;
 Sv,Ly:PJ;
 Sn:String;
Begin
 If(Name='')or(Name=ExprLayerName)Then Begin
  If ExprLayer=Nil Then EFail('no current layer');
  ExprGetLayer:=ExprLayer;
  Exit;
 End;
 For I:=1 to LayerCacheN do
  If LayerCacheName[I]=Name Then Begin ExprGetLayer:=LayerCache[I];Exit;End;
 Sv:=ExprLayer;Sn:=ExprLayerName;
 Ly:=LoadLayer(Name);
 ExprLayer:=Sv;ExprLayerName:=Sn;
 If LayerCacheN<8Then Begin
  Inc(LayerCacheN);
  LayerCacheName[LayerCacheN]:=Name;
  LayerCache[LayerCacheN]:=Ly;
 End;
 ExprGetLayer:=Ly;
End;

{ ---- agregats ---- }

Function Quartile(V:PValArr;N:LongInt;Upper:Boolean):Real;
Var
 Half,Lo:LongInt;
 A,B:Real;

 Function MedOf(S,Cnt:LongInt):Real;
 Var X,Y:Real;
 Begin
  ToNum(V^[S+Cnt div 2],X);
  If Odd(Cnt)Then MedOf:=X
   Else Begin ToNum(V^[S+Cnt div 2-1],Y);MedOf:=(X+Y)/2;End;
 End;

Begin
 If N=1Then Begin ToNum(V^[0],A);Quartile:=A;Exit;End;
 Half:=N div 2;
 If Upper Then Lo:=N-Half Else Lo:=0;
 Quartile:=MedOf(Lo,Half);
End;

Function AggregateVals(Const Kind:String;L:PValList;Const Concat:String):TVal;
Var
 I,K,Cnt,Mx:LongInt;
 Sum,R,R2,Mean,Sd:Real;
 Nums:PValList;
 S:String;
 Seen:Boolean;
 Best:TVal;
 G:TGeom;
 Res:TGeom;
 T:TGeom;
Begin
 AggregateVals:=VNull;
 If Kind='COUNT'Then Begin
  Cnt:=0;
  For I:=0 to L^.Cnt-1do If L^.V^[I].K<>0Then Inc(Cnt);
  AggregateVals:=VNum(Cnt);
  Exit;
 End;
 If Kind='COUNT_MISSING'Then Begin
  Cnt:=0;
  For I:=0 to L^.Cnt-1do If(L^.V^[I].K=0)or((L^.V^[I].K=2)and(L^.V^[I].S=''))Then Inc(Cnt);
  AggregateVals:=VNum(Cnt);
  Exit;
 End;
 If Kind='COUNT_DISTINCT'Then Begin
  Nums:=LNew;
  For I:=0 to L^.Cnt-1do Begin
   If L^.V^[I].K=0Then Continue;
   Seen:=False;
   For K:=0 to Nums^.Cnt-1do If ValEq(Nums^.V^[K],L^.V^[I])Then Seen:=True;
   If Not Seen Then LAdd(Nums,L^.V^[I]);
  End;
  AggregateVals:=VNum(Nums^.Cnt);
  Exit;
 End;
 If Kind='ARRAY_AGG'Then Begin AggregateVals:=VList(L);Exit;End;
 If(Kind='CONCATENATE')or(Kind='CONCATENATE_UNIQUE')Then Begin
  S:='';
  Nums:=LNew;
  For I:=0 to L^.Cnt-1do Begin
   If L^.V^[I].K=0Then Continue;
   If Kind='CONCATENATE_UNIQUE'Then Begin
    Seen:=False;
    For K:=0 to Nums^.Cnt-1do If ValEq(Nums^.V^[K],L^.V^[I])Then Seen:=True;
    If Seen Then Continue;
    LAdd(Nums,L^.V^[I]);
   End;
   If S<>''Then S:=S+Concat;
   S:=S+ToStr(L^.V^[I]);
  End;
  AggregateVals:=VStr(S);
  Exit;
 End;
 If Kind='COLLECT'Then Begin
  InitGeom(Res);
  For I:=0 to L^.Cnt-1do
   If L^.V^[I].K=4Then Begin
    If Res.Cls=0Then GeomCopy(L^.V^[I].G^,Res)
     Else If Res.Cls=L^.V^[I].G^.Cls Then GeomAppend(Res,L^.V^[I].G^);
   End;
  AggregateVals:=GRes(Res);
  Exit;
 End;
 If(Kind='MIN_LENGTH')or(Kind='MAX_LENGTH')Then Begin
  Cnt:=0;Mx:=0;
  For I:=0 to L^.Cnt-1do If L^.V^[I].K<>0Then Begin
   K:=U8Len(ToStr(L^.V^[I]));
   If(Cnt=0)or((Kind='MIN_LENGTH')and(K<Mx))or((Kind='MAX_LENGTH')and(K>Mx))Then Mx:=K;
   Inc(Cnt);
  End;
  If Cnt>0Then AggregateVals:=VNum(Mx);
  Exit;
 End;
 If(Kind='FIRST_VALUE')Then Begin
  If L^.Cnt>0Then AggregateVals:=L^.V^[0];
  Exit;
 End;
 If(Kind='LAST_VALUE')Then Begin
  If L^.Cnt>0Then AggregateVals:=L^.V^[L^.Cnt-1];
  Exit;
 End;
 { agregats numeriques ou ordonnes }
 Nums:=LNew;
 For I:=0 to L^.Cnt-1do If L^.V^[I].K<>0Then LAdd(Nums,L^.V^[I]);
 If Nums^.Cnt=0Then Exit;
 If(Kind='MIN')or(Kind='MINIMUM')or(Kind='MAX')or(Kind='MAXIMUM')Then Begin
  Best:=Nums^.V^[0];
  For I:=1 to Nums^.Cnt-1do
   If(((Kind='MIN')or(Kind='MINIMUM'))and(CmpVal(Nums^.V^[I],Best)<0))or(((Kind='MAX')or(Kind='MAXIMUM'))and(CmpVal(Nums^.V^[I],Best)>0))Then Best:=Nums^.V^[I];
  AggregateVals:=Best;
  Exit;
 End;
 If(Kind='MAJORITY')or(Kind='MINORITY')Then Begin
  Mx:=-1;
  For I:=0 to Nums^.Cnt-1do Begin
   Cnt:=0;
   For K:=0 to Nums^.Cnt-1do If ValEq(Nums^.V^[I],Nums^.V^[K])Then Inc(Cnt);
   If(Mx<0)or((Kind='MAJORITY')and(Cnt>Mx))or((Kind='MINORITY')and(Cnt<Mx))Then Begin Mx:=Cnt;Best:=Nums^.V^[I];End;
  End;
  AggregateVals:=Best;
  Exit;
 End;
 Sum:=0;
 For I:=0 to Nums^.Cnt-1do Begin
  If Not ToNum(Nums^.V^[I],R)Then Exit;
  Sum:=Sum+R;
 End;
 Mean:=Sum/Nums^.Cnt;
 If Kind='SUM'Then AggregateVals:=VNum(Sum) Else
 If Kind='MEAN'Then AggregateVals:=VNum(Mean) Else
 If(Kind='STDEV')or(Kind='STDEVSAMPLE')Then Begin
  R2:=0;
  For I:=0 to Nums^.Cnt-1do Begin ToNum(Nums^.V^[I],R);R2:=R2+Sqr(R-Mean);End;
  If Kind='STDEV'Then AggregateVals:=VNum(Sqrt(R2/Nums^.Cnt))
   Else If Nums^.Cnt>1Then AggregateVals:=VNum(Sqrt(R2/(Nums^.Cnt-1)));
 End
  Else
 Begin
  SortVals(Nums^.V,Nums^.Cnt,True);
  If Kind='RANGE'Then Begin
   ToNum(Nums^.V^[0],R);ToNum(Nums^.V^[Nums^.Cnt-1],R2);
   AggregateVals:=VNum(R2-R);
  End Else
  If Kind='MEDIAN'Then Begin
   ToNum(Nums^.V^[Nums^.Cnt div 2],R);
   If Not Odd(Nums^.Cnt)Then Begin ToNum(Nums^.V^[Nums^.Cnt div 2-1],R2);R:=(R+R2)/2;End;
   AggregateVals:=VNum(R);
  End Else
  If Kind='Q1'Then AggregateVals:=VNum(Quartile(Nums^.V,Nums^.Cnt,False)) Else
  If Kind='Q3'Then AggregateVals:=VNum(Quartile(Nums^.V,Nums^.Cnt,True)) Else
  If Kind='IQR'Then AggregateVals:=VNum(Quartile(Nums^.V,Nums^.Cnt,True)-Quartile(Nums^.V,Nums^.Cnt,False))
   Else EFail('unknown aggregate '+Kind);
 End;
End;

Function IsAggName(Const Nm:String):Boolean;Begin
 IsAggName:=(Nm='COUNT')or(Nm='SUM')or(Nm='MEAN')or(Nm='MEDIAN')or(Nm='MINIMUM')or(Nm='MAXIMUM')or
  (Nm='COUNT_DISTINCT')or(Nm='COUNT_MISSING')or(Nm='STDEV')or(Nm='RANGE')or(Nm='MINORITY')or(Nm='MAJORITY')or
  (Nm='Q1')or(Nm='Q3')or(Nm='IQR')or(Nm='CONCATENATE')or(Nm='CONCATENATE_UNIQUE')or(Nm='COLLECT')or
  (Nm='ARRAY_AGG')or(Nm='MIN_LENGTH')or(Nm='MAX_LENGTH');
End;

{ Agregat d'une expression sur les entites de la couche Lyr ;
  GroupText : ne garder que les entites de meme groupe que l'entite courante }
Function ExprAggregate(Const Kind:String;Lyr:PJ;Const ExprT,FilterT,GroupT,Concat:String):TVal;
Var
 Arr,F:PJ;
 L:PValList;
 I:LongInt;
 Gv,V:TVal;
 HaveGroup:Boolean;
Begin
 Arr:=JFind(Lyr,'features');
 L:=LNew;
 HaveGroup:=GroupT<>'';
 If HaveGroup Then Gv:=EvalSub(GroupT);
 I:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  V:=VBool(True);
  If FilterT<>''Then V:=EvalSubFeat(FilterT,F,I);
  If(V.K<>0)and(V.N<>0)Then Begin
   If HaveGroup Then Begin
    V:=EvalSubFeat(GroupT,F,I);
    If Not ValEq(V,Gv)Then V:=VBool(False) Else V:=VBool(True);
   End;
   If V.N<>0Then LAdd(L,EvalSubFeat(ExprT,F,I));
  End;
  Inc(I);
  F:=F^.Next;
 End;
 ExprAggregate:=AggregateVals(Kind,L,Concat);
End;

{ Fonctions de recouvrement : Pred 0 intersecte, 1 contient, 2 disjoint, 3 egal, 4 touche, 5 chevauche, 6 est dans, 7 croise, 8 plus proche }
Function ExprOverlay(Pred:Integer;Lyr:PJ;Const ExprT,FilterT:String;Limit:Integer;MaxDist:Real):TVal;
Var
 Arr,F:PJ;
 L:PValList;
 I:LongInt;
 Gf:TGeom;
 V:TVal;
 Hit,Any:Boolean;
 Cur:TGeom;
 Dists:PReals;
 N,K:LongInt;
 D,X1,Y1,X2,Y2:Real;
 Idx:PLongs;
 Tmp:LongInt;
 Fa:PJArr;
Begin
 Arr:=JFind(Lyr,'features');
 L:=LNew;
 Any:=False;
 If ExprGeom.First=Nil Then Begin
  If ExprT=''Then ExprOverlay:=VNull Else ExprOverlay:=VList(L);
  Exit;
 End;
 If Pred=8Then Begin
  Fa:=FeatureArray(Arr,N);
  Dists:=AllocBlock((N+1)*SizeOf(Real));
  Idx:=AllocBlock((N+1)*SizeOf(LongInt));
  K:=0;
  For I:=0 to N-1do Begin
   V:=VBool(True);
   If FilterT<>''Then V:=EvalSubFeat(FilterT,Fa^[I],I);
   If(V.K=0)or(V.N=0)Then Continue;
   InitGeom(Gf);
   Flatten(JFind(Fa^[I],'geometry'),Gf);
   If Gf.First<>Nil Then Begin
    D:=NearestPoints(ExprGeom,Gf,X1,Y1,X2,Y2);
    If(MaxDist<=0)or(D<=MaxDist)Then Begin Dists^[K]:=D;Idx^[K]:=I;Inc(K);End;
   End;
   FreeGeom(Gf);
  End;
  For I:=1 to K-1do Begin
   D:=Dists^[I];Tmp:=Idx^[I];
   N:=I-1;
   While(N>=0)and(Dists^[N]>D)do Begin Dists^[N+1]:=Dists^[N];Idx^[N+1]:=Idx^[N];Dec(N);End;
   Dists^[N+1]:=D;Idx^[N+1]:=Tmp;
  End;
  If K>Limit Then K:=Limit;
  For I:=0 to K-1do Begin
   If ExprT=''Then LAdd(L,VFeat(Fa^[Idx^[I]]))
    Else LAdd(L,EvalSubFeat(ExprT,Fa^[Idx^[I]],Idx^[I]));
  End;
  ExprOverlay:=VList(L);
  Exit;
 End;
 I:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  If(Limit>0)and(L^.Cnt>=Limit)Then Break;
  V:=VBool(True);
  If FilterT<>''Then V:=EvalSubFeat(FilterT,F,I);
  If(V.K<>0)and(V.N<>0)Then Begin
   InitGeom(Gf);
   Flatten(JFind(F,'geometry'),Gf);
   Hit:=False;
   If Gf.First<>Nil Then Begin
    Case Pred of
     0:Hit:=GeomPredicate(0,ExprGeom,Gf);
     1:Hit:=GeomPredicate(1,ExprGeom,Gf);
     2:Hit:=GeomPredicate(2,ExprGeom,Gf);
     3:Hit:=GeomPredicate(3,ExprGeom,Gf);
     4:Hit:=GeomPredicate(4,ExprGeom,Gf);
     5:Hit:=GeomPredicate(5,ExprGeom,Gf);
     6:Hit:=GeomPredicate(6,ExprGeom,Gf);
     7:Hit:=GeomPredicate(7,ExprGeom,Gf);
    End;
   End;
   FreeGeom(Gf);
   If Hit Then Begin
    Any:=True;
    If ExprT=''Then Begin
     If Limit>0Then LAdd(L,VBool(True));
    End
     Else LAdd(L,EvalSubFeat(ExprT,F,I));
    If(ExprT='')and(Limit=0)Then Break;
   End;
  End;
  Inc(I);
  F:=F^.Next;
 End;
 If ExprT=''Then ExprOverlay:=VBool(Any)
            Else ExprOverlay:=VList(L);
End;

{ ---- analyseur / evaluateur ---- }

Function PropVal(Const Name:String):TVal;Begin
 PropVal:=JToVal(JFind(ExprProps,Name));
End;

Function LikeMatch(Const S,Pat:String;I,J:Integer):Boolean;
Begin
 If J>Length(Pat)Then LikeMatch:=I>Length(S)
  Else
 If(Pat[J]='\')and(J<Length(Pat))Then Begin
  If I>Length(S)Then LikeMatch:=False
   Else If S[I]=Pat[J+1]Then LikeMatch:=LikeMatch(S,Pat,I+1,J+2)
   Else LikeMatch:=False;
 End
  Else
 If Pat[J]='%'Then Begin
  LikeMatch:=True;
  While I<=Length(S)+1do Begin
   If LikeMatch(S,Pat,I,J+1)Then Exit;
   Inc(I);
  End;
  LikeMatch:=False;
 End
  Else
 If I>Length(S)Then LikeMatch:=False
  Else
 If(Pat[J]='_')or(Pat[J]=S[I])Then LikeMatch:=LikeMatch(S,Pat,I+1,J+1)
                              Else LikeMatch:=False;
End;

Function DoCompare(Op:Integer;A,B:TVal):TVal;
Var
 C:Integer;
 Ra,Rb:Real;
 Sa,Sb:String;
Begin
 If(A.K=0)or(B.K=0)Then Begin DoCompare:=VNull;Exit;End;
 If(A.K=5)or(B.K=5)or(A.K=6)or(B.K=6)Then Begin
  If Op=1Then DoCompare:=VBool(ValEq(A,B)) Else
  If Op=2Then DoCompare:=VBool(Not ValEq(A,B))
         Else DoCompare:=VNull;
  Exit;
 End;
 If ToNum(A,Ra)and ToNum(B,Rb)and Not((A.K=2)and(B.K=2))Then C:=CmpR(Ra,Rb)
  Else
 Begin
  Sa:=ToStr(A);Sb:=ToStr(B);
  If Sa<Sb Then C:=-1 Else If Sa>Sb Then C:=1 Else C:=0;
 End;
 Case Op of
  1:DoCompare:=VBool(C=0);
  2:DoCompare:=VBool(C<>0);
  3:DoCompare:=VBool(C<0);
  4:DoCompare:=VBool(C>0);
  5:DoCompare:=VBool(C<=0);
  Else DoCompare:=VBool(C>=0);
 End;
End;


Var
 RasCache:TRaster;
 RasName:String;
 RasBand:Integer;
 RasLoaded:Boolean;

Function ExprRaster(Const Name:String;Band:Integer):Boolean;
Var
 Sv:Integer;
Begin
 If RasLoaded and(RasName=Name)and(RasBand=Band)Then Begin ExprRaster:=True;Exit;End;
 Sv:=BandSel;
 BandSel:=Band;
 ReadRaster(Name,RasCache);
 BandSel:=Sv;
 RasName:=Name;RasBand:=Band;RasLoaded:=True;
 ExprRaster:=True;
End;

Function RasNoData(V:Real):Boolean;Begin
 RasNoData:=Abs(V-RasCache.NoData)<=1E-9*MaxR(1,Abs(RasCache.NoData));
End;

Function FnRaster(Const Nm:String;Var A:Array of TVal;N:Integer):TVal;
Var
 R,X,Y,V,Sum,Sq,Mn,Mx:Real;
 Band,Col,Row:LongInt;
 I,Cnt:LongInt;
 Cx,Cy:Real;
 Ok:Boolean;
 St:String;
Begin
 FnRaster:=VNull;
 FnOk:=True;
 If Nm='RASTER_VALUE'Then Begin
  NeedArgs(Nm,N,3);
  If NumArg(A,1,R)and(A[2].K=4)Then Begin
   ExprRaster(ToStr(A[0]),Round(R));
   If FirstPt(A[2].G^,X,Y)Then Begin
    Col:=Trunc(FloorR((X-RasCache.XLL)/RasCache.Cell));
    Row:=Trunc(FloorR((RasCache.YLL+RasCache.NR*RasCache.Cell-Y)/RasCache.Cell));
    If(Col>=0)and(Col<RasCache.NC)and(Row>=0)and(Row<RasCache.NR)Then Begin
     V:=RasCache.Data^[Row*RasCache.NC+Col];
     If Not RasNoData(V)Then FnRaster:=VNum(V);
    End;
   End;
  End;
 End Else
 If Nm='RASTER_STATISTIC'Then Begin
  NeedArgs(Nm,N,3);
  If NumArg(A,1,R)Then Begin
   ExprRaster(ToStr(A[0]),Round(R));
   St:=LowerStr(ToStr(A[2]));
   Cnt:=0;Sum:=0;Sq:=0;Mn:=0;Mx:=0;
   For I:=0 to RasCache.NC*RasCache.NR-1do Begin
    V:=RasCache.Data^[I];
    If Not RasNoData(V)Then Begin
     If Cnt=0Then Begin Mn:=V;Mx:=V;End;
     If V<Mn Then Mn:=V;
     If V>Mx Then Mx:=V;
     Sum:=Sum+V;Sq:=Sq+V*V;Inc(Cnt);
    End;
   End;
   If Cnt>0Then Begin
    If St='min'Then FnRaster:=VNum(Mn) Else
    If St='max'Then FnRaster:=VNum(Mx) Else
    If St='range'Then FnRaster:=VNum(Mx-Mn) Else
    If St='sum'Then FnRaster:=VNum(Sum) Else
    If St='count'Then FnRaster:=VNum(Cnt) Else
    If St='mean'Then FnRaster:=VNum(Sum/Cnt) Else
    If St='stddev'Then FnRaster:=VNum(Sqrt(MaxR(0,Sq/Cnt-Sqr(Sum/Cnt))))
     Else EFail('unknown raster statistic '+St);
   End;
  End;
 End
  Else
 FnOk:=False;
End;

Function CallFunc(Name:String;Var A:Array of TVal;N:Integer):TVal;
Var
 V:TVal;
 R:Real;
 L:PValList;
 Idx:LongInt;
 F:PJ;
 Arr:PJ;
 I:LongInt;
Begin
 { fonctions liees a l'entite ou aux couches (arguments deja evalues) }
 If Name='ATTRIBUTE'Then Begin
  If(N>=2)and(A[0].K=11)Then CallFunc:=FeatProp(A[0].F,ToStr(A[1])) Else
  If N=1Then CallFunc:=FeatProp(ExprFeat,ToStr(A[0]))
   Else CallFunc:=VNull;
  Exit;
 End;
 If Name='ATTRIBUTES'Then Begin
  If N>=1Then F:=A[0].F Else F:=ExprFeat;
  If(F<>Nil)and(A[0].K=11)or(N=0)Then CallFunc:=JToVal(JFind(F,'properties'));
  Exit;
 End;
 If Name='GEOMETRY'Then Begin
  If N=0Then CallFunc:=FeatGeom(ExprFeat) Else
  If A[0].K=11Then CallFunc:=FeatGeom(A[0].F) Else
  If A[0].K=4Then CallFunc:=A[0];
  Exit;
 End;
 If Name='GET_FEATURE'Then Begin
  NeedArgs(Name,N,3);
  Arr:=JFind(ExprGetLayer(ToStr(A[0])),'features');
  F:=Arr^.First;
  CallFunc:=VNull;
  While F<>Nil do Begin
   If ValEq(FeatProp(F,ToStr(A[1])),A[2])Then Begin CallFunc:=VFeat(F);Exit;End;
   F:=F^.Next;
  End;
  Exit;
 End;
 If Name='GET_FEATURE_BY_ID'Then Begin
  NeedArgs(Name,N,2);
  Arr:=JFind(ExprGetLayer(ToStr(A[0])),'features');
  CallFunc:=VNull;
  If NumArg(A,1,R)Then Begin
   I:=0;
   F:=Arr^.First;
   While F<>Nil do Begin
    If I=Round(R)Then Begin CallFunc:=VFeat(F);Exit;End;
    Inc(I);F:=F^.Next;
   End;
  End;
  Exit;
 End;
 If Name='VAR'Then Begin
  NeedArgs(Name,N,1);
  CallFunc:=ExprVar(StrUpper(ToStr(A[0])));
  Exit;
 End;
 If Name='EVAL'Then Begin
  NeedArgs(Name,N,1);
  If A[0].K=2Then CallFunc:=EvalSub(A[0].S) Else CallFunc:=VNull;
  Exit;
 End;
 If Name='IS_FEATURE'Then Begin CallFunc:=VBool((N>0)and(A[0].K=11));Exit;End;
 V:=FnGeom(Name,A,N);
 If FnOk Then Begin CallFunc:=V;Exit;End;
 V:=FnMath(Name,A,N);
 If FnOk Then Begin CallFunc:=V;Exit;End;
 V:=FnString(Name,A,N);
 If FnOk Then Begin CallFunc:=V;Exit;End;
 V:=FnDate(Name,A,N);
 If FnOk Then Begin CallFunc:=V;Exit;End;
 V:=FnArray(Name,A,N);
 If FnOk Then Begin CallFunc:=V;Exit;End;
 V:=FnMisc(Name,A,N);
 If FnOk Then Begin CallFunc:=V;Exit;End;
 V:=FnRaster(Name,A,N);
 If FnOk Then Begin CallFunc:=V;Exit;End;
 EFail('unknown function '+Name);
End;

{ Positions des arguments d'un appel ; ExprP est place apres la parenthese fermante }
Procedure ScanArgs(Var Sp,Ep:Array of Integer;Var Cnt:Integer);
Var
 Depth:Integer;
 Q:Char;
 Start:Integer;
Begin
 Cnt:=0;
 Depth:=0;
 Q:=#0;
 Start:=ExprP;
 While ExprP<=Length(ExprS)do Begin
  If Q<>#0Then Begin
   If ExprS[ExprP]=Q Then Begin
    If(Q='''')and(ExprP<Length(ExprS))and(ExprS[ExprP+1]='''')Then Inc(ExprP)
     Else Q:=#0;
   End;
  End
   Else
  Case ExprS[ExprP]of
   '''','"':Q:=ExprS[ExprP];
   '(','[':Inc(Depth);
   ')',']':Begin
    If(Depth=0)and(ExprS[ExprP]=')')Then Begin
     If(Cnt>0)or(Trim1(Copy(ExprS,Start,ExprP-Start))<>'')Then Begin
      If Cnt>High(Sp)Then EFail('too many arguments');
      Sp[Cnt]:=Start;Ep[Cnt]:=ExprP;Inc(Cnt);
     End;
     Inc(ExprP);
     Exit;
    End;
    Dec(Depth);
   End;
   ',':If Depth=0Then Begin
    If Cnt>High(Sp)Then EFail('too many arguments');
    Sp[Cnt]:=Start;Ep[Cnt]:=ExprP;Inc(Cnt);
    Start:=ExprP+1;
   End;
  End;
  Inc(ExprP);
 End;
 EFail('")" expected');
End;

Function EvalNamedArg(Const Txt:String;Var Nm:String):String;
Var
 P:Integer;
 S:String;
Begin
 { argument nomme "nom:=valeur" }
 S:=Trim1(Txt);
 Nm:='';
 P:=Pos(':=',S);
 If(P>1)and(Pos('''',Copy(S,1,P))=0)and(Pos('(',Copy(S,1,P))=0)Then Begin
  Nm:=StrUpper(Trim1(Copy(S,1,P-1)));
  S:=Trim1(Copy(S,P+2,255));
 End;
 EvalNamedArg:=S;
End;

Function EvalLazy(Name:String;Var Done:Boolean):TVal;
Var
 Sp,Ep:Array[0..11]of Integer;
 Txt:Array[0..11]of String;
 Nm:Array[0..11]of String;
 Cnt,I,Save:Integer;
 V,W,El:TVal;
 L,Lo:PValList;
 K:LongInt;
 Lay:PJ;
 Kind,Concat,GroupT,FilterT,ExprT,Lname:String;
 Lim:Integer;
 MaxD:Real;
 Pred:Integer;
 R:Real;
 Ok:Boolean;
Begin
 Done:=True;
 EvalLazy:=VNull;
 If(Name='WITH_VARIABLE')or(Name='ARRAY_FOREACH')or(Name='ARRAY_FILTER')or(Name='TRY')or(Name='AGGREGATE')or IsAggName(Name)or
   (Name='OVERLAY_INTERSECTS')or(Name='OVERLAY_CONTAINS')or(Name='OVERLAY_WITHIN')or(Name='OVERLAY_TOUCHES')or
   (Name='OVERLAY_CROSSES')or(Name='OVERLAY_EQUALS')or(Name='OVERLAY_DISJOINT')or(Name='OVERLAY_OVERLAPS')or(Name='OVERLAY_NEAREST')Then Begin End
  Else Begin Done:=False;Exit;End;
 Save:=ExprP;
 ScanArgs(Sp,Ep,Cnt);
 For I:=0 to Cnt-1do Txt[I]:=EvalNamedArg(Copy(ExprS,Sp[I],Ep[I]-Sp[I]),Nm[I]);
 If Name='TRY'Then Begin
  If Cnt<1Then EFail('function TRY needs an argument');
  EvalLazy:=EvalSub(Txt[0]);
 End Else
 If Name='WITH_VARIABLE'Then Begin
  If Cnt<3Then EFail('function WITH_VARIABLE needs 3 arguments');
  V:=EvalSub(Txt[0]);
  W:=EvalSub(Txt[1]);
  PushVar(ToStr(V),W);
  EvalLazy:=EvalSub(Txt[2]);
  Dec(VarN);
 End Else
 If(Name='ARRAY_FOREACH')or(Name='ARRAY_FILTER')Then Begin
  If Cnt<2Then EFail('function '+Name+' needs 2 arguments');
  V:=EvalSub(Txt[0]);
  If V.K<>5Then Exit;
  L:=LNew;
  For K:=0 to V.L^.Cnt-1do Begin
   PushVar('ELEMENT',V.L^.V^[K]);
   PushVar('COUNTER',VNum(K));
   W:=EvalSub(Txt[1]);
   Dec(VarN,2);
   If Name='ARRAY_FOREACH'Then LAdd(L,W)
    Else If(W.K<>0)and(W.N<>0)Then LAdd(L,V.L^.V^[K]);
  End;
  EvalLazy:=VList(L);
 End Else
 If Name='AGGREGATE'Then Begin
  If Cnt<3Then EFail('function AGGREGATE needs at least 3 arguments');
  Lname:='';Kind:='';ExprT:='';FilterT:='';Concat:='';
  For I:=0 to Cnt-1do Begin
   If Nm[I]=''Then Begin
    Case I of
     0:Lname:=ToStr(EvalSub(Txt[I]));
     1:Kind:=StrUpper(ToStr(EvalSub(Txt[I])));
     2:ExprT:=Txt[I];
     3:FilterT:=Txt[I];
     4:Concat:=ToStr(EvalSub(Txt[I]));
    End;
   End Else
   If Nm[I]='LAYER'Then Lname:=ToStr(EvalSub(Txt[I])) Else
   If Nm[I]='AGGREGATE'Then Kind:=StrUpper(ToStr(EvalSub(Txt[I]))) Else
   If Nm[I]='EXPRESSION'Then ExprT:=Txt[I] Else
   If Nm[I]='FILTER'Then FilterT:=Txt[I] Else
   If Nm[I]='CONCATENATOR'Then Concat:=ToStr(EvalSub(Txt[I]));
  End;
  EvalLazy:=ExprAggregate(Kind,ExprGetLayer(Lname),ExprT,FilterT,'',Concat);
 End Else
 If IsAggName(Name)Then Begin
  If Cnt<1Then EFail('function '+Name+' needs an expression');
  ExprT:=Txt[0];GroupT:='';FilterT:='';Concat:=',';
  For I:=1 to Cnt-1do Begin
   If Nm[I]='GROUP_BY'Then GroupT:=Txt[I] Else
   If Nm[I]='FILTER'Then FilterT:=Txt[I] Else
   If Nm[I]='CONCATENATOR'Then Concat:=ToStr(EvalSub(Txt[I])) Else
   If Nm[I]=''Then Begin
    If I=1Then GroupT:=Txt[I] Else
    If I=2Then FilterT:=Txt[I] Else
    If I=3Then Concat:=ToStr(EvalSub(Txt[I]));
   End;
  End;
  If StrUpper(GroupT)='NULL'Then GroupT:='';
  If StrUpper(FilterT)='NULL'Then FilterT:='';
  Kind:=Name;
  If ExprLayer=Nil Then EFail('no current layer for '+Name);
  EvalLazy:=ExprAggregate(Kind,ExprLayer,ExprT,FilterT,GroupT,Concat);
 End
  Else
 Begin
  { overlay_xxx(couche, expression, filtre, limite, distance max) }
  If Cnt<1Then EFail('function '+Name+' needs a layer');
  Lname:='';ExprT:='';FilterT:='';Lim:=0;MaxD:=0;
  For I:=0 to Cnt-1do Begin
   If(Nm[I]='')and(I=0)or(Nm[I]='LAYER')Then Lname:=ToStr(EvalSub(Txt[I])) Else
   If(Nm[I]='')and(I=1)or(Nm[I]='EXPRESSION')Then ExprT:=Txt[I] Else
   If(Nm[I]='')and(I=2)or(Nm[I]='FILTER')Then FilterT:=Txt[I] Else
   If(Nm[I]='')and(I=3)or(Nm[I]='LIMIT')Then Begin
    V:=EvalSub(Txt[I]);
    If ToNum(V,R)Then Lim:=Round(R);
   End Else
   If(Nm[I]='')and(I=4)or(Nm[I]='MAX_DISTANCE')Then Begin
    V:=EvalSub(Txt[I]);
    If ToNum(V,R)Then MaxD:=R;
   End;
  End;
  If StrUpper(ExprT)='NULL'Then ExprT:='';
  If StrUpper(FilterT)='NULL'Then FilterT:='';
  If Name='OVERLAY_INTERSECTS'Then Pred:=0 Else If Name='OVERLAY_CONTAINS'Then Pred:=1 Else
  If Name='OVERLAY_DISJOINT'Then Pred:=2 Else If Name='OVERLAY_EQUALS'Then Pred:=3 Else
  If Name='OVERLAY_TOUCHES'Then Pred:=4 Else If Name='OVERLAY_OVERLAPS'Then Pred:=5 Else
  If Name='OVERLAY_WITHIN'Then Pred:=6 Else If Name='OVERLAY_CROSSES'Then Pred:=7 Else Pred:=8;
  If(Pred=8)and(Lim<=0)Then Lim:=1;
  EvalLazy:=ExprOverlay(Pred,ExprGetLayer(Lname),ExprT,FilterT,Lim,MaxD);
  If(ExprT<>'')and(Pred<>8)and(Lim=0)Then Begin End;
 End;
End;

Function EvalAtom:TVal;
Var
 V,Idx:TVal;
 S,Name:String;
 C:Char;
 R:Real;
 E,Err:Integer;
 Start,NA:Integer;
 Args:Array[0..15]of TVal;
 Cx,Cy:Real;
 Ok,Done,Chosen:Boolean;
 L:PValList;
 K:LongInt;
 Cond,Res:TVal;
 Tmp:TGeom;
Begin
 EvalAtom:=VNull;
 ESkip;
 If ExprP>Length(ExprS)Then EFail('unexpected end of expression');
 C:=ExprS[ExprP];
 If C='('Then Begin
  Inc(ExprP);
  V:=EvalOr;
  If Not EOp(')')Then EFail('")" expected');
  EvalAtom:=V;
 End
  Else
 If C='['Then Begin
  Inc(ExprP);
  L:=LNew;
  ESkip;
  If(ExprP<=Length(ExprS))and(ExprS[ExprP]=']')Then Inc(ExprP)
   Else Begin
    Repeat
     LAdd(L,EvalOr);
    Until Not EOp(',');
    If Not EOp(']')Then EFail('"]" expected');
   End;
  EvalAtom:=VList(L);
 End
  Else
 If C in['0'..'9','.']Then Begin
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(ExprS[ExprP]in['0'..'9','.'])do Inc(ExprP);
  If(ExprP<=Length(ExprS))and(ExprS[ExprP]in['e','E'])Then Begin
   Inc(ExprP);
   If(ExprP<=Length(ExprS))and(ExprS[ExprP]in['+','-'])Then Inc(ExprP);
   While(ExprP<=Length(ExprS))and(ExprS[ExprP]in['0'..'9'])do Inc(ExprP);
  End;
  Val(Copy(ExprS,Start,ExprP-Start),R,E);
  If E<>0Then EFail('invalid number');
  EvalAtom:=VNum(R);
 End
  Else
 If C=''''Then Begin
  S:='';
  Inc(ExprP);
  While True do Begin
   If ExprP>Length(ExprS)Then EFail('unterminated string');
   If ExprS[ExprP]=''''Then Begin
    If(ExprP<Length(ExprS))and(ExprS[ExprP+1]='''')Then Begin
     S:=S+'''';
     Inc(ExprP,2);
    End
     Else
    Begin
     Inc(ExprP);
     Break;
    End;
   End
    Else
   If(ExprS[ExprP]='\')and(ExprP<Length(ExprS))and(ExprS[ExprP+1]in['n','t','r','\'])Then Begin
    Case ExprS[ExprP+1]of
     'n':S:=S+#10;
     't':S:=S+#9;
     'r':S:=S+#13;
     Else S:=S+'\';
    End;
    Inc(ExprP,2);
   End
    Else
   Begin
    S:=S+ExprS[ExprP];
    Inc(ExprP);
   End;
  End;
  EvalAtom:=VStr(S);
 End
  Else
 If C='"'Then Begin
  Inc(ExprP);
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(ExprS[ExprP]<>'"')do Inc(ExprP);
  If ExprP>Length(ExprS)Then EFail('unterminated field name');
  Name:=Copy(ExprS,Start,ExprP-Start);
  Inc(ExprP);
  EvalAtom:=PropVal(Name);
 End
  Else
 If C='@'Then Begin
  Inc(ExprP);
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(UpCase(ExprS[ExprP])in['A'..'Z','0'..'9','_'])do Inc(ExprP);
  EvalAtom:=ExprVar(StrUpper(Copy(ExprS,Start,ExprP-Start)));
 End
  Else
 If C='$'Then Begin
  Inc(ExprP);
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(UpCase(ExprS[ExprP])in['A'..'Z','0'..'9','_'])do Inc(ExprP);
  Name:=StrUpper(Copy(ExprS,Start,ExprP-Start));
  If Name='GEOMETRY'Then Begin
   If ExprGeom.First=Nil Then EvalAtom:=VNull Else EvalAtom:=VGeom(ExprGeom);
  End Else
  If Name='CURRENTFEATURE'Then EvalAtom:=VFeat(ExprFeat) Else
  If Name='AREA'Then EvalAtom:=VNum(GeomArea(ExprGeom)) Else
  If Name='LENGTH'Then Begin
   If ExprGeom.Cls=2Then EvalAtom:=VNum(GeomLength(ExprGeom)) Else EvalAtom:=VNull;
  End Else
  If Name='PERIMETER'Then Begin
   If ExprGeom.Cls=3Then EvalAtom:=VNum(GeomLength(ExprGeom)) Else EvalAtom:=VNull;
  End Else
  If Name='ID'Then EvalAtom:=VNum(ExprId) Else
  If(Name='X')or(Name='Y')Then Begin
   CentroidGeom(ExprGeom,Cx,Cy,Ok);
   If Ok Then Begin
    If Name='X'Then EvalAtom:=VNum(Cx) Else EvalAtom:=VNum(Cy);
   End
    Else
   EvalAtom:=VNull;
  End
   Else
  EFail('unknown variable $'+Name);
 End
  Else
 If UpCase(C)in['A'..'Z','_']Then Begin
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(UpCase(ExprS[ExprP])in['A'..'Z','0'..'9','_'])do Inc(ExprP);
  Name:=Copy(ExprS,Start,ExprP-Start);
  If StrUpper(Name)='TRUE'Then EvalAtom:=VBool(True) Else
  If StrUpper(Name)='FALSE'Then EvalAtom:=VBool(False) Else
  If StrUpper(Name)='NULL'Then EvalAtom:=VNull Else
  If StrUpper(Name)='CASE'Then Begin
   Chosen:=False;
   Res:=VNull;
   While EKw('WHEN')do Begin
    Cond:=EvalOr;
    If Not EKw('THEN')Then EFail('THEN expected');
    V:=EvalOr;
    If(Not Chosen)and(Cond.K<>0)and(Cond.N<>0)Then Begin Res:=V;Chosen:=True;End;
   End;
   If EKw('ELSE')Then Begin
    V:=EvalOr;
    If Not Chosen Then Res:=V;
   End;
   If Not EKw('END')Then EFail('END expected');
   EvalAtom:=Res;
  End
   Else
  Begin
   ESkip;
   If(ExprP<=Length(ExprS))and(ExprS[ExprP]='(')Then Begin
    Inc(ExprP);
    Done:=False;
    V:=EvalLazy(StrUpper(Name),Done);
    If Done Then EvalAtom:=V
     Else
    Begin
     NA:=0;
     Args[0]:=VNull;
     ESkip;
     If(ExprP<=Length(ExprS))and(ExprS[ExprP]=')')Then Inc(ExprP)
      Else
     Begin
      Repeat
       If NA>15Then EFail('too many arguments');
       Args[NA]:=EvalOr;
       Inc(NA);
      Until Not EOp(',');
      If Not EOp(')')Then EFail('")" expected');
     End;
     EvalAtom:=CallFunc(StrUpper(Name),Args,NA);
    End;
   End
    Else
   EvalAtom:=PropVal(Name);
  End;
 End
  Else
 EFail('unexpected character "'+C+'"');
 { acces par indice : tableau[i], dictionnaire['cle'] }
End;

Function EvalPrimary:TVal;
Var
 V,Idx,Res:TVal;
 R:Real;
 K:LongInt;
Begin
 V:=EvalAtom;
 While(ExprP<=Length(ExprS))and(ExprS[ExprP]='[')do Begin
  Inc(ExprP);
  Idx:=EvalOr;
  If Not EOp(']')Then EFail('"]" expected');
  Res:=VNull;
  If(V.K=5)and ToNum(Idx,R)and(Idx.K<>2)Then Begin
   K:=Round(R);
   If K<0Then K:=V.L^.Cnt+K;
   If(K>=0)and(K<V.L^.Cnt)Then Res:=V.L^.V^[K];
  End Else
  If V.K=6Then Begin
   K:=MapFind(V.L,ToStr(Idx));
   If K>=0Then Res:=V.L^.V^[K+1];
  End;
  V:=Res;
 End;
 EvalPrimary:=V;
End;


Function PowVals(A,B:Real;Var R:Real):Boolean;Begin
 PowVals:=True;
 If A>0Then R:=Exp(B*Ln(A)) Else
 If(A=0)and(B>0)Then R:=0 Else
 If B=0Then R:=1 Else
 If(A<0)and(B=Int(B))Then Begin
  R:=Exp(B*Ln(-A));
  If Odd(Round(Abs(B)))Then R:=-R;
 End
  Else PowVals:=False;
End;

Function EvalUnary:TVal;
Var
 V:TVal;
 R:Real;
 Neg,Any:Boolean;
Begin
 Neg:=False;Any:=False;
 While True do Begin
  If EOp('-')Then Begin Neg:=Not Neg;Any:=True;End Else
  If EOp('+')Then Any:=True
   Else Break;
 End;
 V:=EvalPrimary;
 If Any and Neg Then Begin
  If V.K=10Then V:=VTime(10,-V.N) Else
  If(V.K in[1,2,3])and ToNum(V,R)Then V:=VNum(-R)
   Else V:=VNull;
 End
  Else
 If Any and(V.K=2)Then Begin
  If ToNum(V,R)Then V:=VNum(R) Else V:=VNull;
 End;
 EvalUnary:=V;
End;

Function EvalPow:TVal;
Var
 Ops:Array[1..8]of TVal;
 N,I:Integer;
 A,B,R:Real;
 V:TVal;
Begin
 N:=1;
 Ops[1]:=EvalUnary;
 While EOp('^')do Begin
  If N>=8Then EFail('too many chained powers');
  Inc(N);
  Ops[N]:=EvalUnary;
 End;
 V:=Ops[N];
 For I:=N-1downto 1do Begin
  If ToNum(Ops[I],A)and ToNum(V,B)and(Ops[I].K in[1,2,3])and(V.K in[1,2,3])and PowVals(A,B,R)Then V:=VNum(R)
   Else V:=VNull;
 End;
 EvalPow:=V;
End;

Function EvalConcat:TVal;
Var
 V,W:TVal;
 Lc:PValList;
 Ix:LongInt;
Begin
 V:=EvalPow;
 While EOp('||')do Begin
  W:=EvalPow;
  If V.K=5Then Begin
   { concatenation de tableaux }
   If W.K=5Then Begin
    Lc:=LNew;
    For Ix:=0 to V.L^.Cnt-1do LAdd(Lc,V.L^.V^[Ix]);
    For Ix:=0 to W.L^.Cnt-1do LAdd(Lc,W.L^.V^[Ix]);
    V:=VList(Lc);
   End
    Else V:=VNull;
  End
   Else
  If(V.K=0)or(W.K=0)Then V:=VNull Else V:=VStr(ToStr(V)+ToStr(W));
 End;
 EvalConcat:=V;
End;

Function EvalMul:TVal;
Var
 V,W:TVal;
 A,B:Real;
 Op:Integer;
Begin
 V:=EvalConcat;
 While True do Begin
  Op:=0;
  ESkip;
  If EOp('//')Then Op:=4 Else
  If EOp('*')Then Op:=1 Else
  If EOp('/')Then Op:=2 Else
  If EOp('%')Then Op:=3;
  If Op=0Then Break;
  W:=EvalConcat;
  If(V.K=10)and(W.K<>10)and(W.K<>0)and(W.K<7)and ToNum(W,B)Then Begin
   If Op=1Then V:=VTime(10,V.N*B) Else
   If(Op=2)and(B<>0)Then V:=VTime(10,V.N/B)
    Else V:=VNull;
  End Else
  If(W.K=10)and(V.K<>10)and(V.K<>0)and(V.K<7)and ToNum(V,A)and(Op=1)Then V:=VTime(10,W.N*A) Else
  If(V.K=10)and(W.K=10)and(Op=2)and(W.N<>0)Then V:=VNum(V.N/W.N) Else
  If ToNum(V,A)and ToNum(W,B)and(V.K<>0)and(W.K<>0)and(V.K<7)and(W.K<7)and(V.K<>4)and(W.K<>4)Then Begin
   Case Op of
    1:V:=VNum(A*B);
    2:If B=0Then V:=VNull Else V:=VNum(A/B);
    3:If B=0Then V:=VNull Else V:=VNum(A-B*FloorR(A/B));
    4:If B=0Then V:=VNull Else V:=VNum(FloorR(A/B));
   End;
  End
   Else
  V:=VNull;
 End;
 EvalMul:=V;
End;

Function EvalAdd:TVal;
Var
 V,W:TVal;
 A,B:Real;
 Op:Char;
 K:Byte;
Begin
 V:=EvalMul;
 Repeat
  ESkip;
  If(ExprP<=Length(ExprS))and((ExprS[ExprP]='+')or(ExprS[ExprP]='-'))Then Begin
   Op:=ExprS[ExprP];
   Inc(ExprP);
   W:=EvalMul;
   If(V.K=0)or(W.K=0)Then V:=VNull Else
   If IsTimeKind(V.K)or IsTimeKind(W.K)Then Begin
    { arithmetique sur les dates et intervalles }
    If(V.K=10)and(W.K=10)Then Begin
     If Op='+'Then V:=VTime(10,V.N+W.N) Else V:=VTime(10,V.N-W.N);
    End Else
    If(V.K in[7,8,9])and(W.K=10)Then Begin
     If Op='+'Then V:=VTime(V.K,V.N+W.N) Else V:=VTime(V.K,V.N-W.N);
    End Else
    If(V.K=10)and(W.K in[7,8,9])and(Op='+')Then V:=VTime(W.K,W.N+V.N) Else
    If(V.K=W.K)and(V.K in[7,8,9])and(Op='-')Then V:=VTime(10,V.N-W.N) Else
    If(V.K in[7,8])and(W.K in[7,8])and(Op='-')Then V:=VTime(10,V.N-W.N)
     Else V:=VNull;
   End Else
   If V.K=5Then Begin
    V:=VNull;
   End Else
   If(Op='+')and(V.K=2)and(W.K=2)and Not(IsPlainNumber(V.S)and IsPlainNumber(W.S))Then V:=VStr(V.S+W.S) Else
   If ToNum(V,A)and ToNum(W,B)and(V.K in[1,2,3])and(W.K in[1,2,3])Then Begin
    If Op='+'Then V:=VNum(A+B) Else V:=VNum(A-B);
   End
    Else V:=VNull;
  End
   Else
  Break;
 Until False;
 EvalAdd:=V;
End;

Function EvalCompare:TVal;
Var
 V,W,X:TVal;
 Op:Integer;
 Neg,Found:Boolean;
 Pat,Sv:String;
Begin
 V:=EvalAdd;
 ESkip;
 Op:=0;
 If EOp('<=')Then Op:=5 Else
 If EOp('>=')Then Op:=6 Else
 If EOp('<>')or EOp('!=')Then Op:=2 Else
 If EOp('==')or EOp('=')Then Op:=1 Else
 If EOp('<')Then Op:=3 Else
 If EOp('>')Then Op:=4;
 If Op>0Then Begin
  W:=EvalAdd;
  V:=DoCompare(Op,V,W);
 End
  Else
 If EOp('~')Then Begin
  W:=EvalAdd;
  If(V.K=0)or(W.K=0)Then V:=VNull
   Else Begin
    RxCompile(ToStr(W));
    V:=VBool(RxFind(ToStr(V),1));
   End;
 End
  Else
 If EKw('IS')Then Begin
  Neg:=EKw('NOT');
  If EKw('NULL')Then V:=VBool((V.K=0)<>Neg)
   Else Begin
    W:=EvalAdd;
    If(V.K=0)or(W.K=0)Then Found:=(V.K=0)and(W.K=0) Else Found:=ValEq(V,W);
    V:=VBool(Found<>Neg);
   End;
 End
  Else
 Begin
  Neg:=False;
  If EKw('NOT')Then Neg:=True;
  If EKw('LIKE')Then Begin
   W:=EvalAdd;
   If(V.K=0)or(W.K=0)Then V:=VNull Else V:=VBool(LikeMatch(ToStr(V),ToStr(W),1,1)<>Neg);
  End Else
  If EKw('ILIKE')Then Begin
   W:=EvalAdd;
   If(V.K=0)or(W.K=0)Then V:=VNull
                     Else V:=VBool(LikeMatch(U8Upper(ToStr(V),True),U8Upper(ToStr(W),True),1,1)<>Neg);
  End Else
  If EKw('IN')Then Begin
   If Not EOp('(')Then EFail('"(" expected');
   Found:=False;
   Repeat
    W:=EvalAdd;
    If W.K=5Then Begin
     { IN (tableau) }
     For Op:=0 to W.L^.Cnt-1do Begin
      X:=DoCompare(1,V,W.L^.V^[Op]);
      If(X.K=3)and(X.N<>0)Then Found:=True;
     End;
    End
     Else
    Begin
     X:=DoCompare(1,V,W);
     If(X.K=3)and(X.N<>0)Then Found:=True;
    End;
   Until Not EOp(',');
   If Not EOp(')')Then EFail('")" expected');
   If V.K=0Then V:=VNull Else V:=VBool(Found<>Neg);
  End
   Else
  If Neg Then EFail('IN, LIKE or ILIKE expected');
 End;
 EvalCompare:=V;
End;

Function EvalNot:TVal;
Var
 V:TVal;
 Cnt:Integer;
Begin
 Cnt:=0;
 While EKw('NOT')do Inc(Cnt);
 V:=EvalCompare;
 While Cnt>0do Begin
  If V.K<>0Then V:=VBool(V.N=0);
  Dec(Cnt);
 End;
 EvalNot:=V;
End;

Function EvalAnd:TVal;
Var
 V,W:TVal;
Begin
 V:=EvalNot;
 While EKw('AND')do Begin
  W:=EvalNot;
  If((V.K<>0)and(V.N=0))or((W.K<>0)and(W.N=0))Then V:=VBool(False) Else
  If(V.K=0)or(W.K=0)Then V:=VNull
                    Else V:=VBool(True);
 End;
 EvalAnd:=V;
End;

Function EvalOr:TVal;
Var
 V,W:TVal;
Begin
 V:=EvalAnd;
 While EKw('OR')do Begin
  W:=EvalAnd;
  If((V.K<>0)and(V.N<>0))or((W.K<>0)and(W.N<>0))Then V:=VBool(True) Else
  If(V.K=0)or(W.K=0)Then V:=VNull
                    Else V:=VBool(False);
 End;
 EvalOr:=V;
End;

{ Evalue une expression sur une entite }
Function EvalOn(Expr:String;F:PJ;Id:LongInt):TVal;
Var
 V:TVal;
Begin
 FreeGeom(ExprGeom);
 Flatten(JFind(F,'geometry'),ExprGeom);
 ExprFeat:=F;
 ExprParent:=Nil;
 ExprId:=Id;
 ExprS:=Expr;
 ExprP:=1;
 ExprProps:=JFind(F,'properties');
 ExprDepth:=0;VarN:=0;
 V:=EvalOr;
 ESkip;
 If ExprP<=Length(ExprS)Then EFail('unexpected token');
 EvalOn:=V;
End;

Function EvalFeature(Expr:String;Props:PJ):Boolean;
Var
 V:TVal;
Begin
 ExprS:=Expr;
 ExprP:=1;
 ExprProps:=Props;
 ExprDepth:=0;VarN:=0;
 V:=EvalOr;
 ESkip;
 If ExprP<=Length(ExprS)Then EFail('unexpected token');
 EvalFeature:=(V.K in[1,3])and(V.N<>0);
End;

{ ------------------------------------------------------------------ }
{ Rasters (ESRI ASCII Grid)                                           }
{ ------------------------------------------------------------------ }

Var
 RF:Text;
 RBuf:Array[0..16383]of Char;
 RTok:String;
 RasterHeaderOnly:Boolean;
 LastEpsg:LongInt;
 RasterBands:Integer;

Function RTokNext:Boolean;
Var
 C:Char;
Begin
 RTok:='';
 RTokNext:=False;
 While Not EOF(RF)do Begin
  Read(RF,C);
  If C in[' ',#9,#10,#13,#26]Then Begin
   If RTok<>''Then Begin RTokNext:=True;Exit;End;
  End
   Else
  Begin
   If Length(RTok)>=250Then Fail('Error: invalid raster token');
   RTok:=RTok+C;
  End;
 End;
 RTokNext:=RTok<>'';
End;

Procedure RNum(Const S:String;Var R:Real);
Var
 E:Integer;
Begin
 Val(S,R,E);
 If E<>0Then Fail('Error: invalid number "'+S+'" in raster');
End;

Procedure AscPrj(FileName:String;Var R:TRaster);
Var
 Pn,Nm:String;
Begin
 R.Epsg:=0;
 Pn:=SideFile(FileName,'.prj');
 If Pn<>''Then R.Epsg:=CrsFromFile(Pn,Nm);
 LastEpsg:=R.Epsg;
End;

Procedure ReadAsc(FileName:String;Var R:TRaster);
Var
 Key:String;
 V,Dx,Dy:Real;
 HaveNC,HaveNR,HaveX,HaveY,HaveC,CenterX,CenterY:Boolean;
 I,Total:LongInt;
 Pending:Boolean;
Begin
 {$I-}
 Assign(RF,FileName);
 Reset(RF);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to open raster file '+FileName);
 SetTextBuf(RF,RBuf);
 R.NoData:=-9999;
 R.DType:=0;R.Epsg:=0;
 R.NC:=0;R.NR:=0;R.XLL:=0;R.YLL:=0;R.Cell:=0;
 Dx:=0;Dy:=0;
 HaveNC:=False;HaveNR:=False;HaveX:=False;HaveY:=False;HaveC:=False;
 CenterX:=False;CenterY:=False;
 Pending:=False;
 While Not Pending and RTokNext do Begin
  Key:=StrUpper(RTok);
  If Key='NCOLS'Then Begin RTokNext;RNum(RTok,V);R.NC:=Round(V);HaveNC:=True;End Else
  If Key='NROWS'Then Begin RTokNext;RNum(RTok,V);R.NR:=Round(V);HaveNR:=True;End Else
  If Key='XLLCORNER'Then Begin RTokNext;RNum(RTok,R.XLL);HaveX:=True;End Else
  If Key='YLLCORNER'Then Begin RTokNext;RNum(RTok,R.YLL);HaveY:=True;End Else
  If Key='XLLCENTER'Then Begin RTokNext;RNum(RTok,R.XLL);HaveX:=True;CenterX:=True;End Else
  If Key='YLLCENTER'Then Begin RTokNext;RNum(RTok,R.YLL);HaveY:=True;CenterY:=True;End Else
  If Key='CELLSIZE'Then Begin RTokNext;RNum(RTok,R.Cell);HaveC:=True;End Else
  If Key='DX'Then Begin RTokNext;RNum(RTok,Dx);End Else
  If Key='DY'Then Begin RTokNext;RNum(RTok,Dy);End Else
  If Key='NODATA_VALUE'Then Begin RTokNext;RNum(RTok,R.NoData);End
   Else
  Pending:=True;
 End;
 If Not(HaveNC and HaveNR and HaveX and HaveY)Then Fail('Error: invalid ASCII grid header in '+FileName);
 If Not HaveC Then Begin
  If(Dx>0)and(Dx=Dy)Then Begin R.Cell:=Dx;HaveC:=True;End;
 End;
 If(Not HaveC)or(R.Cell<=0)Then Fail('Error: invalid or non-square cell size in '+FileName);
 If(R.NC<1)or(R.NR<1)Then Fail('Error: invalid raster size in '+FileName);
 Total:=R.NC*R.NR;
 If Total>MaxCells Then Fail('Error: raster is too large');
 If CenterX Then R.XLL:=R.XLL-R.Cell/2;
 If CenterY Then R.YLL:=R.YLL-R.Cell/2;
 AscPrj(FileName,R);
 If RasterHeaderOnly Then Begin
  Close(RF);
  R.Data:=Nil;
  Exit;
 End;
 R.Data:=AllocBlock(Total*SizeOf(Real));
 For I:=0 to Total-1do Begin
  If I>0Then Begin
   If Not RTokNext Then Fail('Error: raster data truncated in '+FileName);
  End
   Else
  If Not Pending Then Fail('Error: raster has no data in '+FileName);
  RNum(RTok,V);
  R.Data^[I]:=V;
 End;
 Close(RF);
End;

Procedure WriteAsc(FileName:String;Var R:TRaster);
Var
 F:Text;
 I,J:LongInt;
Begin
 {$I-}
 Assign(F,FileName);
 Rewrite(F);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to create output file '+FileName);
 WriteLn(F,'ncols ',R.NC);
 WriteLn(F,'nrows ',R.NR);
 WriteLn(F,'xllcorner ',NumStr(R.XLL));
 WriteLn(F,'yllcorner ',NumStr(R.YLL));
 WriteLn(F,'cellsize ',NumStr(R.Cell));
 WriteLn(F,'NODATA_value ',NumStr(R.NoData));
 For I:=0 to R.NR-1do Begin
  For J:=0 to R.NC-1do Begin
   If J>0Then Write(F,' ');
   Write(F,NumStr(R.Data^[I*R.NC+J]));
  End;
  WriteLn(F);
 End;
 Close(F);
 If(R.Epsg>0)and CrsKnown(R.Epsg)Then WritePrj(ChangeExt(FileName,'.prj'),R.Epsg);
End;

{ ------------------------------------------------------------------ }
{ GeoTIFF                                                             }
{ ------------------------------------------------------------------ }

Var
 TifP:PBytes;
 TifN,IfdPos:LongInt;
 TBig:Boolean;

Function TRd16(P:LongInt):LongInt;Begin
 If(P<0)or(P+2>TifN)Then Fail('Error: corrupt TIFF file');
 If TBig Then TRd16:=(LongInt(TifP^[P])shl 8)or TifP^[P+1]
         Else TRd16:=LongInt(TifP^[P])or(LongInt(TifP^[P+1])shl 8);
End;

Function TRd32(P:LongInt):LongInt;Begin
 If(P<0)or(P+4>TifN)Then Fail('Error: corrupt TIFF file');
 If TBig Then TRd32:=RdBE32(TifP,P)
         Else TRd32:=RdLE32(TifP,P);
End;

Function TRdDouble(P:LongInt):Real;
Var
 D:Double;
 B:Array[0..7]of Byte absolute D;
 I:Integer;
Begin
 If(P<0)or(P+8>TifN)Then Fail('Error: corrupt TIFF file');
 If TBig Then Begin
  For I:=0 to 7do B[7-I]:=TifP^[P+I];
 End
  Else
 Move(TifP^[P],D,8);
 TRdDouble:=D;
End;

Function TypeSize(T:LongInt):LongInt;Begin
 Case T of
  1,2,6,7:TypeSize:=1;
  3,8:TypeSize:=2;
  4,9,11:TypeSize:=4;
  5,10,12:TypeSize:=8;
  Else TypeSize:=1;
 End;
End;

Function TagFind(Tag:LongInt;Var Typ,Cnt,Pos:LongInt):Boolean;
Var
 N,I,E:LongInt;
Begin
 TagFind:=False;
 N:=TRd16(IfdPos);
 For I:=0 to N-1do Begin
  E:=IfdPos+2+I*12;
  If TRd16(E)=Tag Then Begin
   Typ:=TRd16(E+2);
   Cnt:=TRd32(E+4);
   If Cnt*TypeSize(Typ)<=4Then Pos:=E+8
                          Else Pos:=TRd32(E+8);
   If(Pos<0)or(Pos+Cnt*TypeSize(Typ)>TifN)Then Fail('Error: corrupt TIFF file');
   TagFind:=True;
   Exit;
  End;
 End;
End;

Function TagInt(Tag,Idx,Def:LongInt):LongInt;
Var
 Typ,Cnt,Pos:LongInt;
Begin
 TagInt:=Def;
 If Not TagFind(Tag,Typ,Cnt,Pos)Then Exit;
 If Idx>=Cnt Then Exit;
 Case Typ of
  1,6,7:TagInt:=TifP^[Pos+Idx];
  3:TagInt:=TRd16(Pos+2*Idx);
  4:TagInt:=TRd32(Pos+4*Idx);
 End;
End;

Function TagCount(Tag:LongInt):LongInt;
Var
 Typ,Cnt,Pos:LongInt;
Begin
 If TagFind(Tag,Typ,Cnt,Pos)Then TagCount:=Cnt
                            Else TagCount:=0;
End;

Function TagReal(Tag,Idx:LongInt;Var V:Real):Boolean;
Var
 Typ,Cnt,Pos:LongInt;
Begin
 TagReal:=False;
 If Not TagFind(Tag,Typ,Cnt,Pos)Then Exit;
 If(Typ<>12)or(Idx>=Cnt)Then Exit;
 V:=TRdDouble(Pos+8*Idx);
 TagReal:=True;
End;


{ Echantillon d'un tampon decode (ordre natif petit-boutiste) }
Function GetSample(B:PBytes;Off,Bits,Fmt:LongInt):Real;
Var
 L:LongInt;
 S:Single;
 D:Double;
 W:Word;
 Sh:ShortInt;
Begin
 Case Bits of
  8:If Fmt=2Then Begin Sh:=ShortInt(B^[Off]);GetSample:=Sh;End
            Else GetSample:=B^[Off];
  16:Begin
      W:=Word(B^[Off])or(Word(B^[Off+1])shl 8);
      If Fmt=2Then GetSample:=SmallInt(W)
              Else GetSample:=W;
     End;
  32:Begin
      L:=RdLE32(B,Off);
      If Fmt=3Then Begin Move(L,S,4);GetSample:=S;End Else
      If Fmt=2Then GetSample:=L
              Else Begin
       If L<0Then GetSample:=L+4294967296.0
             Else GetSample:=L;
      End;
     End;
  64:Begin Move(B^[Off],D,8);GetSample:=D;End;
  Else GetSample:=0;
 End;
End;

Procedure Swap16(B:PBytes;N:LongInt);
Var
 I:LongInt;
 T:Byte;
Begin
 I:=0;
 While I+1<N do Begin T:=B^[I];B^[I]:=B^[I+1];B^[I+1]:=T;Inc(I,2);End;
End;

Procedure Swap32(B:PBytes;N:LongInt);
Var
 I:LongInt;
 T:Byte;
Begin
 I:=0;
 While I+3<N do Begin
  T:=B^[I];B^[I]:=B^[I+3];B^[I+3]:=T;
  T:=B^[I+1];B^[I+1]:=B^[I+2];B^[I+2]:=T;
  Inc(I,4);
 End;
End;

Procedure Swap64(B:PBytes;N:LongInt);
Var
 I,K:LongInt;
 T:Byte;
Begin
 I:=0;
 While I+7<N do Begin
  For K:=0 to 3do Begin T:=B^[I+K];B^[I+K]:=B^[I+7-K];B^[I+7-K]:=T;End;
  Inc(I,8);
 End;
End;

Function OffTag(Tiled:Boolean):LongInt;Begin
 If Tiled Then OffTag:=324 Else OffTag:=273;
End;

Function CntTag(Tiled:Boolean):LongInt;Begin
 If Tiled Then CntTag:=325 Else CntTag:=279;
End;

{ Predicteur horizontal (2) sur une ligne, ordre natif petit-boutiste }
Procedure DecodeIntPred(P:PBytes;W,S,Bpp:LongInt);
Var
 X,K,O:LongInt;
 A:LongInt;
Begin
 For X:=1 to W-1do For K:=0 to S-1do Begin
  O:=(X*S+K)*Bpp;
  Case Bpp of
   1:P^[O]:=Byte(P^[O]+P^[O-S]);
   2:Begin
      A:=(LongInt(P^[O])or(LongInt(P^[O+1])shl 8))+(LongInt(P^[O-S*2])or(LongInt(P^[O-S*2+1])shl 8));
      P^[O]:=A and 255;P^[O+1]:=(A shr 8)and 255;
     End;
   4:Begin
      A:=RdLE32(P,O)+RdLE32(P,O-S*4);
      P^[O]:=A and 255;P^[O+1]:=(A shr 8)and 255;P^[O+2]:=(A shr 16)and 255;P^[O+3]:=(A shr 24)and 255;
     End;
  End;
 End;
End;

{ Predicteur a virgule flottante (3) sur une ligne de Wc echantillons ; resultat en ordre natif }
Procedure DecodeFloatPred(P:PBytes;Wc,Bps,Stride:LongInt);
Var
 Cc,I,C,B:LongInt;
 T:PBytes;
Begin
 Cc:=Wc*Bps;
 For I:=Stride to Cc-1do P^[I]:=Byte(P^[I]+P^[I-Stride]);
 T:=AllocBlock(Cc);
 Move(P^,T^,Cc);
 For C:=0 to Wc-1do For B:=0 to Bps-1do P^[C*Bps+(Bps-1-B)]:=T^[B*Wc+C];
 FreeMem(T,Cc);
End;

Procedure ReadTiff(FileName:String;Var R:TRaster);
Var
 W,H,Bps,Spp,Comp,Pred,Planar,Fmt,Photo,RowsPS,TW,TH,Chunks,Per,Band,Ci,X0,Y0:LongInt;
 Tiled:Boolean;
 Off,Cn,ChunkW,ChunkH,Need,Got,I,J,Plane,Gx,Gy,Stride,Row,Rw,K,Bpp,Pix,SmpOff:LongInt;
 Raw,DBuf:PBytes;
 Typ,Cnt,Pos,Epsg,Kn,Ky,Kv:LongInt;
 Sx,Sy,Tx,Ty,Ti,Tj,V:Real;
 HaveS,HaveT,PixPoint:Boolean;
 Nd:String;
 Code:Integer;
Begin
 TifP:=LoadFileBytes(FileName,TifN);
 If TifP=Nil Then Fail('Error: unable to open raster file '+FileName);
 If TifN<16Then Fail('Error: invalid TIFF file '+FileName);
 If(TifP^[0]=Ord('I'))and(TifP^[1]=Ord('I'))Then TBig:=False Else
 If(TifP^[0]=Ord('M'))and(TifP^[1]=Ord('M'))Then TBig:=True
  Else Fail('Error: invalid TIFF file '+FileName);
 K:=TRd16(2);
 If K=43Then Fail('Error: BigTIFF is not supported');
 If K<>42Then Fail('Error: invalid TIFF file '+FileName);
 IfdPos:=TRd32(4);
 W:=TagInt(256,0,0);H:=TagInt(257,0,0);
 Bps:=TagInt(258,0,1);Comp:=TagInt(259,0,1);Photo:=TagInt(262,0,1);
 Spp:=TagInt(277,0,1);Planar:=TagInt(284,0,1);Pred:=TagInt(317,0,1);
 Fmt:=TagInt(339,0,1);
 If(W<1)or(H<1)Then Fail('Error: invalid TIFF size in '+FileName);
 If(W*1.0)*H>MaxCells Then Fail('Error: raster is too large');
 If(Bps<>8)and(Bps<>16)and(Bps<>32)and(Bps<>64)Then Fail('Error: unsupported TIFF bit depth '+IntToStr(Bps));
 If(Fmt<1)or(Fmt>3)Then Fmt:=1;
 If(Fmt=3)and(Bps<>32)and(Bps<>64)Then Fail('Error: unsupported TIFF sample format');
 If(Fmt<>3)and(Bps=64)Then Fail('Error: unsupported TIFF sample format');
 If(Comp<>1)and(Comp<>5)and(Comp<>8)and(Comp<>32946)and(Comp<>32773)Then
  Fail('Error: unsupported TIFF compression '+IntToStr(Comp));
 If(Pred<>1)and(Pred<>2)and(Pred<>3)Then Fail('Error: unsupported TIFF predictor');
 If Photo=3Then Fail('Error: palette TIFF files are not supported');
 Band:=BandSel;
 If Band<1Then Band:=1;
 RasterBands:=Spp;
 If Band>Spp Then Fail('Error: band '+IntToStr(Band)+' not found in '+FileName+' ('+IntToStr(Spp)+' bands)');
 Tiled:=TagCount(324)>0;
 If Tiled Then Begin
  TW:=TagInt(322,0,0);TH:=TagInt(323,0,0);
  If(TW<1)or(TH<1)Then Fail('Error: invalid TIFF tile size');
  Per:=((W+TW-1)div TW)*((H+TH-1)div TH);
 End
  Else
 Begin
  RowsPS:=TagInt(278,0,H);
  If(RowsPS<1)or(RowsPS>H)Then RowsPS:=H;
  TW:=W;TH:=RowsPS;
  Per:=(H+RowsPS-1)div RowsPS;
 End;
 If Planar=2Then Chunks:=Per*Spp Else Chunks:=Per;
 { georeferencement }
 R.NC:=W;R.NR:=H;R.XLL:=0;R.YLL:=0;R.Cell:=1;R.NoData:=-9999;R.DType:=0;R.Epsg:=0;
 HaveS:=TagReal(33550,0,Sx)and TagReal(33550,1,Sy);
 HaveT:=TagReal(33922,0,Ti)and TagReal(33922,1,Tj)and TagReal(33922,3,Tx)and TagReal(33922,4,Ty);
 If(Not HaveS)and(TagCount(34264)>=16)Then Begin
  If TagReal(34264,0,Sx)and TagReal(34264,5,Sy)and TagReal(34264,3,Tx)and TagReal(34264,7,Ty)Then Begin
   Sy:=Abs(Sy);Ti:=0;Tj:=0;HaveS:=True;HaveT:=True;
  End;
 End;
 PixPoint:=False;
 Epsg:=0;
 If TagCount(34735)>=4Then Begin
  Pos:=0;
  If TagFind(34735,Typ,Cnt,Pos)Then Begin
   Kn:=TRd16(Pos+6);
   For I:=0 to Kn-1do Begin
    If(8+I*8+8)>Cnt*2Then Break;
    Ky:=TRd16(Pos+8+I*8);
    Kv:=TRd16(Pos+8+I*8+6);
    If TRd16(Pos+8+I*8+2)=0Then Begin
     If(Ky=3072)and(Kv<>32767)and(Kv<>0)Then Epsg:=Kv;
     If(Ky=2048)and(Kv<>32767)and(Kv<>0)and(Epsg=0)Then Epsg:=Kv;
     If(Ky=1025)and(Kv=2)Then PixPoint:=True;
    End;
   End;
  End;
 End;
 If HaveS and HaveT Then Begin
  If(Sx<=0)or(Sy<=0)Then Fail('Error: invalid TIFF pixel size');
  If Abs(Sx-Sy)>1E-6*Sx Then Fail('Error: non-square pixels are not supported in '+FileName);
  R.Cell:=Sx;
  If PixPoint Then Begin Ti:=Ti+0.5;Tj:=Tj+0.5;End;
  R.XLL:=Tx-Ti*Sx;
  R.YLL:=(Ty+Tj*Sy)-H*Sy;
 End;
 If Epsg=4326Then R.Epsg:=4326 Else
 If(Epsg=3857)or(Epsg=900913)or(Epsg=3785)Then R.Epsg:=3857
                                          Else R.Epsg:=Epsg;
 LastEpsg:=R.Epsg;
 If TagFind(42113,Typ,Cnt,Pos)and(Typ=2)Then Begin
  Nd:='';
  For I:=0 to Cnt-1do Begin
   If TifP^[Pos+I]=0Then Break;
   If Length(Nd)<60Then Nd:=Nd+Chr(TifP^[Pos+I]);
  End;
  Val(Nd,V,Code);
  If Code=0Then R.NoData:=V Else
  If StrUpper(Nd)='NAN'Then R.NoData:=-9999;
 End;
 If RasterHeaderOnly Then Begin R.Data:=Nil;Exit;End;
 R.Data:=AllocBlock(W*H*SizeOf(Real));
 For I:=0 to W*H-1do R.Data^[I]:=R.NoData;
 Bpp:=Bps div 8;
 If Planar=2Then Pix:=Bpp Else Pix:=Bpp*Spp;
 Need:=TW*TH*Pix;
 DBuf:=AllocBlock(Need+16);
 For Ci:=0 to Chunks-1do Begin
  If(Planar=2)Then Begin
   Plane:=Ci div Per;
   If Plane<>Band-1Then Continue;
   Cn:=Ci mod Per;
  End
   Else
  Cn:=Ci;
  If Tiled Then Begin
   Gx:=Cn mod((W+TW-1)div TW);
   Gy:=Cn div((W+TW-1)div TW);
   X0:=Gx*TW;Y0:=Gy*TH;
   ChunkW:=TW;ChunkH:=TH;
  End
   Else
  Begin
   X0:=0;Y0:=Cn*TH;
   ChunkW:=TW;
   ChunkH:=TH;
   If Y0+ChunkH>H Then ChunkH:=H-Y0;
  End;
  Off:=TagInt(OffTag(Tiled),Ci,-1);
  Got:=TagInt(CntTag(Tiled),Ci,0);
  If(Off<0)or(Off+Got>TifN)Then Fail('Error: corrupt TIFF strip table');
  Raw:=@TifP^[Off];
  FillChar(DBuf^,Need,0);
  Case Comp of
   1:Begin
      If Got>Need Then Got:=Need;
      Move(Raw^,DBuf^,Got);
     End;
   8,32946:Begin
      Inflate(Raw,Got,DBuf,Need,True);
     End;
   5:LzwDecode(Raw,Got,DBuf,Need);
   32773:PackBitsDecode(Raw,Got,DBuf,Need);
  End;
  { predicteur flottant : se fait avant le changement d'ordre des octets }
  Rw:=ChunkW*Pix;
  If Pred=3Then Begin
   For Row:=0 to ChunkH-1do Begin
    DecodeFloatPred(@DBuf^[Row*Rw],ChunkW*(Pix div Bpp),Bpp,Pix div Bpp);
   End;
  End
   Else
  Begin
   If TBig and(Bpp>1)Then Begin
    Case Bpp of
     2:Swap16(DBuf,Need);
     4:Swap32(DBuf,Need);
     8:Swap64(DBuf,Need);
    End;
   End;
   If Pred=2Then Begin
    For Row:=0 to ChunkH-1do
     DecodeIntPred(@DBuf^[Row*Rw],ChunkW,Pix div Bpp,Bpp);
   End;
  End;
  For J:=0 to ChunkH-1do Begin
   If Y0+J>=H Then Break;
   For I:=0 to ChunkW-1do Begin
    If X0+I>=W Then Break;
    If Planar=2Then SmpOff:=J*Rw+I*Bpp
               Else SmpOff:=J*Rw+I*Pix+(Band-1)*Bpp;
    R.Data^[(Y0+J)*W+X0+I]:=GetSample(DBuf,SmpOff,Bps,Fmt);
   End;
  End;
 End;
 FreeMem(DBuf,Need+16);
End;

Procedure PutSample(Var B:TBuf;V:Real;Dt:Integer);
Var
 L:LongInt;
 S:Single;
 D:Double;
 Lo,Hi:Real;
Begin
 Case Dt of
  1,2,3,4,5:Begin
   Case Dt of
    1:Begin Lo:=0;Hi:=255;End;
    2:Begin Lo:=-32768;Hi:=32767;End;
    3:Begin Lo:=0;Hi:=65535;End;
    4:Begin Lo:=0;Hi:=4294967295.0;End;
    Else Begin Lo:=-2147483648.0;Hi:=2147483647.0;End;
   End;
   If V<Lo Then V:=Lo;
   If V>Hi Then V:=Hi;
   If Dt=4Then Begin
    If V>2147483647.0Then L:=Round(V-4294967296.0)
                     Else L:=Round(V);
   End
    Else L:=Round(V);
   If Dt=1Then BufByte(B,L) Else
   If(Dt=2)or(Dt=3)Then BufLE16(B,L)
                   Else BufLE32(B,L);
  End;
  6:Begin
   If V>3.4028234663852886E38Then V:=3.4028234663852886E38;
   If V<-3.4028234663852886E38Then V:=-3.4028234663852886E38;
   S:=V;
   BufGrow(B,4);Move(S,B.P^[B.N],4);Inc(B.N,4);
  End;
  Else Begin
   D:=V;
   BufGrow(B,8);Move(D,B.P^[B.N],8);Inc(B.N,8);
  End;
 End;
End;

Var
 TwEnt:Array[1..16]of Record
  Tag,Typ:LongInt;
  Cnt,Val:LongInt;
 End;
 TwN:Integer;

Procedure TwAdd(Tag,Typ:LongInt;Cnt,Val:LongInt);Begin
 Inc(TwN);
 TwEnt[TwN].Tag:=Tag;TwEnt[TwN].Typ:=Typ;TwEnt[TwN].Cnt:=Cnt;TwEnt[TwN].Val:=Val;
End;

Procedure WriteTiff(FileName:String;Var R:TRaster);
Var
 B,X:TBuf;
 Dt,Bps,Fmt,Bpp,RowsPS,NStrips,I,J,K,Rows,DataEnd,IfdOff,ExtOff,E:LongInt;
 StripOff,StripLen:Array[0..4095]of LongInt;
 Nd:String;
 Keys:Array[1..3]of Integer;
 Geographic:Boolean;
 OffOff,CntOff,ScaleOff,TieOff,KeyOff,NdOff:LongInt;
Begin
 Dt:=R.DType;
 If(Dt<1)or(Dt>7)Then Dt:=6;
 Case Dt of
  1:Begin Bps:=8;Fmt:=1;End;
  2:Begin Bps:=16;Fmt:=2;End;
  3:Begin Bps:=16;Fmt:=1;End;
  4:Begin Bps:=32;Fmt:=1;End;
  5:Begin Bps:=32;Fmt:=2;End;
  6:Begin Bps:=32;Fmt:=3;End;
  Else Begin Bps:=64;Fmt:=3;End;
 End;
 Bpp:=Bps div 8;
 RowsPS:=8192 div(R.NC*Bpp);
 If RowsPS<1Then RowsPS:=1;
 If RowsPS>R.NR Then RowsPS:=R.NR;
 NStrips:=(R.NR+RowsPS-1)div RowsPS;
 If NStrips>4096Then Begin
  RowsPS:=(R.NR+4095)div 4096;
  NStrips:=(R.NR+RowsPS-1)div RowsPS;
 End;
 BufInit(B);
 BufByte(B,Ord('I'));BufByte(B,Ord('I'));BufLE16(B,42);BufLE32(B,0);
 For I:=0 to NStrips-1do Begin
  Rows:=RowsPS;
  If I*RowsPS+Rows>R.NR Then Rows:=R.NR-I*RowsPS;
  StripOff[I]:=B.N;
  For J:=I*RowsPS to I*RowsPS+Rows-1do
   For K:=0 to R.NC-1do PutSample(B,R.Data^[J*R.NC+K],Dt);
  StripLen[I]:=B.N-StripOff[I];
 End;
 If B.N and 1<>0Then BufByte(B,0);
 DataEnd:=B.N;
 Nd:=NumStr(R.NoData);
 TwN:=0;
 { disposition : IFD, puis donnees externes }
 E:=11+2;   { 256 257 258 259 262 273 277 278 279 339 + 33550 33922 42113 }
 If (R.Epsg>0)and(R.Epsg<=CustomBase)Then Inc(E);
 IfdOff:=DataEnd;
 ExtOff:=IfdOff+2+E*12+4;
 OffOff:=0;CntOff:=0;
 If NStrips>1Then Begin OffOff:=ExtOff;Inc(ExtOff,4*NStrips);CntOff:=ExtOff;Inc(ExtOff,4*NStrips);End;
 ScaleOff:=ExtOff;Inc(ExtOff,24);
 TieOff:=ExtOff;Inc(ExtOff,48);
 KeyOff:=0;
 If (R.Epsg>0)and(R.Epsg<=CustomBase)Then Begin KeyOff:=ExtOff;Inc(ExtOff,8*4);End;
 NdOff:=0;
 If Length(Nd)+1>4Then Begin NdOff:=ExtOff;Inc(ExtOff,Length(Nd)+1);End;
 TwAdd(256,4,1,R.NC);
 TwAdd(257,4,1,R.NR);
 TwAdd(258,3,1,Bps);
 TwAdd(259,3,1,1);
 TwAdd(262,3,1,1);
 If NStrips>1Then TwAdd(273,4,NStrips,OffOff)Else TwAdd(273,4,1,StripOff[0]);
 TwAdd(277,3,1,1);
 TwAdd(278,4,1,RowsPS);
 If NStrips>1Then TwAdd(279,4,NStrips,CntOff)Else TwAdd(279,4,1,StripLen[0]);
 TwAdd(339,3,1,Fmt);
 TwAdd(33550,12,3,ScaleOff);
 TwAdd(33922,12,6,TieOff);
 If (R.Epsg>0)and(R.Epsg<=CustomBase)Then TwAdd(34735,3,16,KeyOff);
 If NdOff>0Then TwAdd(42113,2,Length(Nd)+1,NdOff)
           Else TwAdd(42113,2,Length(Nd)+1,0);
 BufInit(X);
 BufLE16(X,TwN);
 For I:=1 to TwN do Begin
  BufLE16(X,TwEnt[I].Tag);BufLE16(X,TwEnt[I].Typ);BufLE32(X,TwEnt[I].Cnt);
  If(TwEnt[I].Typ=3)and(TwEnt[I].Cnt=1)Then Begin BufLE16(X,TwEnt[I].Val);BufLE16(X,0);End Else
  If TwEnt[I].Tag=42113Then Begin
   If NdOff>0Then BufLE32(X,NdOff)
   Else Begin
    For J:=1 to Length(Nd)do BufByte(X,Ord(Nd[J]));
    BufByte(X,0);
    For J:=Length(Nd)+2 to 4do BufByte(X,0);
   End;
  End
   Else
  BufLE32(X,TwEnt[I].Val);
 End;
 BufLE32(X,0);
 If NStrips>1Then Begin
  For I:=0 to NStrips-1do BufLE32(X,StripOff[I]);
  For I:=0 to NStrips-1do BufLE32(X,StripLen[I]);
 End;
 BufDouble(X,R.Cell);BufDouble(X,R.Cell);BufDouble(X,0);
 BufDouble(X,0);BufDouble(X,0);BufDouble(X,0);
 BufDouble(X,R.XLL);BufDouble(X,R.YLL+R.NR*R.Cell);BufDouble(X,0);
 If (R.Epsg>0)and(R.Epsg<=CustomBase)Then Begin
  Geographic:=(R.Epsg>=4000)and(R.Epsg<5000);
  BufLE16(X,1);BufLE16(X,1);BufLE16(X,0);BufLE16(X,3);
  BufLE16(X,1024);BufLE16(X,0);BufLE16(X,1);
  If Geographic Then BufLE16(X,2)Else BufLE16(X,1);
  BufLE16(X,1025);BufLE16(X,0);BufLE16(X,1);BufLE16(X,1);
  If Geographic Then BufLE16(X,2048)Else BufLE16(X,3072);
  BufLE16(X,0);BufLE16(X,1);BufLE16(X,R.Epsg);
 End;
 If NdOff>0Then Begin
  For J:=1 to Length(Nd)do BufByte(X,Ord(Nd[J]));
  BufByte(X,0);
 End;
 { en-tete : decalage de l'IFD }
 B.P^[4]:=IfdOff and 255;B.P^[5]:=(IfdOff shr 8)and 255;
 B.P^[6]:=(IfdOff shr 16)and 255;B.P^[7]:=(IfdOff shr 24)and 255;
 BufGrow(B,X.N);
 Move(X.P^,B.P^[B.N],X.N);
 Inc(B.N,X.N);
 BufSave(FileName,B);
End;

{ ---- aiguillage ASC / GeoTIFF ---- }

Function RasterIsTiff(FileName:String):Boolean;
Var
 F:File;
 H:Array[0..3]of Byte;
 Got:LongInt;
Begin
 RasterIsTiff:=False;
 Assign(F,FileName);
 {$I-}
 Reset(F,1);
 {$I+}
 If IOResult<>0Then Exit;
 BlockRead(F,H,4,Got);
 Close(F);
 If Got<4Then Exit;
 RasterIsTiff:=((H[0]=Ord('I'))and(H[1]=Ord('I'))and(H[2]=42)and(H[3]=0))or
               ((H[0]=Ord('M'))and(H[1]=Ord('M'))and(H[2]=0)and(H[3]=42))or
               ((H[0]=Ord('I'))and(H[1]=Ord('I'))and(H[2]=43)and(H[3]=0))or
               ((H[0]=Ord('M'))and(H[1]=Ord('M'))and(H[2]=0)and(H[3]=43));
End;

Procedure ReadRaster(FileName:String;Var R:TRaster);
Var
 E:String;
Begin
 FileName:=ResolveProject(FileName);
 E:=FileExt(FileName);
 If(E='.TIF')or(E='.TIFF')or(E='.GTIFF')Then ReadTiff(FileName,R) Else
 If E='.ASC'Then ReadAsc(FileName,R) Else
 If RasterIsTiff(FileName)Then ReadTiff(FileName,R) Else
 If(E='')or(E='.TXT')Then ReadAsc(FileName,R)
  Else Fail('Error: unsupported raster format "'+E+'" (use .tif or .asc)');
End;

Procedure WriteRaster(FileName:String;Var R:TRaster);
Var
 E:String;
Begin
 E:=FileExt(FileName);
 If(E='.TIF')or(E='.TIFF')or(E='.GTIFF')Then WriteTiff(FileName,R) Else
 If(E='.ASC')or(E='')or(E='.TXT')Then WriteAsc(FileName,R)
  Else Fail('Error: unsupported raster output format "'+E+'" (use .tif or .asc)');
End;

Function IsNoData(Var R:TRaster;V:Real):Boolean;Begin
 IsNoData:=Abs(V-R.NoData)<=1E-9*MaxR(1,Abs(R.NoData));
End;

{ ------------------------------------------------------------------ }
{ Aide et liste                                                       }
{ ------------------------------------------------------------------ }

Procedure ShowGeneralHelp;Begin
 WriteLn('QGIS Processing Executor (clone) - ',VersionStr);
 WriteLn;
 WriteLn('Usage: QGIS_PROCESS [--help] [--version] [--json] [--verbose] [--no-python]');
 WriteLn('                    [--skip-loading-plugins] [--distance_units=UNITS] [--area_units=UNITS]');
 WriteLn('                    [--ellipsoid=ELLIPSOID] [--project_path=PATH]');
 WriteLn('                    [command] [algorithm id or command parameters]');
 WriteLn;
 WriteLn('Options:');
 WriteLn('  --help, -h, /?            Display this help (after a command: help of that command)');
 WriteLn('  --version                 Display the version');
 WriteLn('  --json                    Output results in JSON format');
 WriteLn('  --verbose                 Display more messages while an algorithm runs');
 WriteLn('  --no-python               Accepted for compatibility (there is no Python here)');
 WriteLn('  --skip-loading-plugins    Accepted for compatibility');
 WriteLn('  --distance_units=UNITS    Units of the distances in the results (meters, kilometers,');
 WriteLn('                            feet, yards, miles, nautical miles, centimeters, millimeters, inches)');
 WriteLn('  --area_units=UNITS        Units of the areas in the results (square meters, square kilometers,');
 WriteLn('                            square feet, square yards, square miles, hectares, acres, ...)');
 WriteLn('  --ellipsoid=NAME          NONE forces planar measures; any other value uses the sphere');
 WriteLn('  --project_path=PATH       Project file (must exist; its content is not used)');
 WriteLn;
 WriteLn('Available commands:');
 WriteLn('  plugins                   List available (and active) plugins');
 WriteLn('  plugins enable|disable N  Enable or disable the plugin N');
 WriteLn('  list                      List all available processing algorithms');
 WriteLn('  help                      Show help for an algorithm (help ALGORITHM_ID)');
 WriteLn('  run                       Run an algorithm (run ALGORITHM_ID --PARAM=VALUE ...)');
 WriteLn('                            With "-" as the last argument the parameters are read as JSON');
 WriteLn('                            from the standard input: {"inputs":{"NAME":value,...}}');
 WriteLn;
 WriteLn('Vector layers are GeoJSON files, rasters are ESRI ASCII Grid (.asc) files.');
 WriteLn;
 WriteLn('Example: QGIS_PROCESS run native:calculatedistance --X1=-73.57 --Y1=45.50 --X2=2.35 --Y2=48.85');
 WriteLn('Example: QGIS_PROCESS run native:buffer --INPUT=cities.geojson --DISTANCE=0.5 --OUTPUT=out.geojson');
End;

Procedure ShowList;
Var
 I,P,Cnt:Integer;
 Prefix,Name:String;
Begin
 If JsonMode Then Begin
  WriteLn('{"providers":{');
  For P:=1 to 2do Begin
   If P=1Then Begin Prefix:='native:';Name:='QGIS (native c++)';End
         Else Begin Prefix:='gdal:';Name:='GDAL';End;
   Write('"',Copy(Prefix,1,Length(Prefix)-1),'":{"id":"',Copy(Prefix,1,Length(Prefix)-1),
         '","name":',JsonStr(Name),',"algorithms":{');
   Cnt:=0;
   For I:=1 to MaxAlgo do If Copy(Algos[I].Id,1,Length(Prefix))=Prefix Then Begin
    If Cnt>0Then Write(',');
    WriteLn;
    Write(' ',JsonStr(Algos[I].Id),':{"id":',JsonStr(Algos[I].Id),
          ',"name":',JsonStr(Algos[I].Title),'}');
    Inc(Cnt);
   End;
   WriteLn;
   Write('}}');
   If P=1Then WriteLn(',') Else WriteLn;
  End;
  WriteLn('}}');
 End
  Else
 Begin
  WriteLn('Available algorithms');
  For P:=1 to 2do Begin
   If P=1Then Begin Prefix:='native:';Name:='QGIS (native c++)';End
         Else Begin Prefix:='gdal:';Name:='GDAL';End;
   WriteLn;
   WriteLn(Name);
   For I:=1 to MaxAlgo do If Copy(Algos[I].Id,1,Length(Prefix))=Prefix Then
    WriteLn(#9,Algos[I].Id,#9,Algos[I].Title);
  End;
 End;
End;

{ Extensions : seule "processing" existe (integree et toujours active) ; les autres fournisseurs de QGIS
  (GRASS, SAGA, OTB...) sont connus mais indisponibles dans ce clone }
Const
 PluginCount=4;
 PluginNames:Array[1..PluginCount]of String[24]=('processing','grassprovider','processing_saga_nextgen','otbprovider');

Function PluginIndex(Name:String):Integer;
Var
 I:Integer;
Begin
 PluginIndex:=0;
 For I:=1 to PluginCount do If PluginNames[I]=Name Then PluginIndex:=I;
End;

Procedure ShowPlugins;
Var
 I:Integer;
Begin
 If JsonMode Then Begin
  Write('{"plugins":{');
  For I:=1 to PluginCount do Begin
   If I>1Then Write(',');
   If I=1Then Write(JsonStr(PluginNames[I]),':{"loaded":true,"enabled":true,"builtin":true}')
         Else Write(JsonStr(PluginNames[I]),':{"loaded":false,"enabled":false,"available":false}');
  End;
  WriteLn('}}');
 End
  Else
 Begin
  WriteLn('Available plugins');
  WriteLn;
  For I:=1 to PluginCount do
   If I=1Then WriteLn(#9,PluginNames[I],' (enabled, built-in)')
         Else WriteLn(#9,PluginNames[I],' (not available in this clone)');
 End;
End;

{ plugins enable|disable NOM }
Procedure PluginsAction(Action,Name:String);
Var
 I:Integer;
Begin
 Action:=StrUpper(Action);
 If(Action<>'ENABLE')and(Action<>'DISABLE')Then Fail('Error: unknown plugins action "'+Action+'" (use enable or disable)');
 If Name=''Then Fail('Error: missing plugin name');
 I:=PluginIndex(Name);
 If I=0Then Fail('Error: plugin "'+Name+'" not found');
 If I>1Then Fail('Error: plugin "'+Name+'" is not available in this clone');
 If Action='DISABLE'Then Fail('Error: the built-in plugin "processing" cannot be disabled');
 If JsonMode Then WriteLn('{"plugin":"processing","enabled":true}')
             Else WriteLn('Plugin "processing" is already enabled');
End;

Procedure ShowAlgoHelp(A:Integer);
Var
 I:Integer;
 First:Boolean;
Begin
 If JsonMode Then Begin
  WriteLn('{"id":',JsonStr(Algos[A].Id),',"name":',JsonStr(Algos[A].Title),
          ',"group":',JsonStr(Algos[A].Group),
          ',"description":',JsonStr(Algos[A].Descr),',"parameters":{');
  First:=True;
  For I:=1 to MaxParam do If Params[I].A=A Then Begin
   If Not First Then Write(',');
   First:=False;
   Write(JsonStr(Params[I].Name),':{"type":',JsonStr(Params[I].Typ),
         ',"description":',JsonStr(Params[I].Desc),
         ',"default":',JsonStr(Params[I].Def),'}');
  End;
  Write('},"outputs":{');
  First:=True;
  For I:=1 to MaxOut do If Outs[I].A=A Then Begin
   If Not First Then Write(',');
   First:=False;
   Write(JsonStr(Outs[I].Name),':{"type":',JsonStr(Outs[I].Typ),
         ',"description":',JsonStr(Outs[I].Desc),'}');
  End;
  WriteLn('}}');
 End
  Else
 Begin
  WriteLn(Algos[A].Title,' (',Algos[A].Id,')');
  WriteLn;
  WriteLn('----------------');
  WriteLn('Description');
  WriteLn('----------------');
  WriteLn(Algos[A].Descr);
  WriteLn;
  WriteLn('----------------');
  WriteLn('Arguments');
  WriteLn('----------------');
  WriteLn;
  For I:=1 to MaxParam do If Params[I].A=A Then Begin
   WriteLn(Params[I].Name,': ',Params[I].Desc);
   WriteLn(#9,'Argument type:',#9,Params[I].Typ);
   If Params[I].Def='*'Then WriteLn(#9,'Optional') Else
   If Params[I].Def<>''Then WriteLn(#9,'Default value:',#9,Params[I].Def)
                       Else WriteLn(#9,'Required');
   WriteLn;
  End;
  WriteLn('----------------');
  WriteLn('Outputs');
  WriteLn('----------------');
  WriteLn;
  For I:=1 to MaxOut do If Outs[I].A=A Then Begin
   WriteLn(Outs[I].Name,': ',Outs[I].Desc);
   WriteLn(#9,'Output type:',#9,Outs[I].Typ);
   WriteLn;
  End;
 End;
End;

{ ------------------------------------------------------------------ }
{ Arguments                                                           }
{ ------------------------------------------------------------------ }

Function FindAlgo(Id:String):Integer;
Var
 I:Integer;
Begin
 FindAlgo:=0;
 Id:=StrUpper(Id);
 For I:=1 to MaxAlgo do If StrUpper(Algos[I].Id)=Id Then Begin
  FindAlgo:=I;
  Exit;
 End;
End;

{ Retourne la valeur d'un argument (Faux s'il est absent) }
Function GetArg(Name:String;Var Value:String):Boolean;
Var
 I:Integer;
Begin
 GetArg:=False;
 Name:=StrUpper(Name);
 For I:=1 to ArgCount do If ArgName[I]=Name Then Begin
  Value:=ArgVal[I];
  GetArg:=True;
  Exit;
 End;
End;

Function ParamDef(A:Integer;Name:String;Var P:ParamRec):Boolean;
Var
 I:Integer;
Begin
 ParamDef:=False;
 For I:=1 to MaxParam do If(Params[I].A=A)and(Params[I].Name=Name)Then Begin
  P:=Params[I];
  ParamDef:=True;
  Exit;
 End;
End;

{ Valide les arguments puis retourne la valeur finale du parametre }
Var
 TmpKey:Array[1..40]of String;
 TmpPath:Array[1..40]of String;
 TmpCount:Integer;

{ Repertoire temporaire (TMPDIR, TEMP ou TMP, sinon le repertoire courant) }
Function TempDir:String;
Var
 E:String;
Begin
 E:=GetEnv('TMPDIR');
 If E=''Then E:=GetEnv('TEMP');
 If E=''Then E:=GetEnv('TMP');
 If E=''Then E:='.';
 TempDir:=E;
End;

{ Chemin temporaire pour une sortie TEMPORARY_OUTPUT (le meme pour un parametre donne) }
Function TempOutput(A:Integer;Name:String;Var P:ParamRec):String;
Var
 K:Integer;
 Key,Ext,Dir,Path:String;
Begin
 Key:=IntToStr(A)+':'+Name;
 For K:=1 to TmpCount do If TmpKey[K]=Key Then Begin TempOutput:=TmpPath[K];Exit;End;
 If P.Typ='vectorDestination'Then Ext:='.geojson' Else
 If P.Typ='rasterDestination'Then Ext:='.tif' Else
 If P.Typ='folderDestination'Then Ext:=''
                             Else Ext:='.txt';
 Dir:=TempDir;
 If(Dir<>'')and(Dir[Length(Dir)]<>'/')and(Dir[Length(Dir)]<>#92)Then Dir:=Dir+'/';
 Repeat
  Path:=Dir+'qgis_process_'+LowerStr(Name)+'_'+IntToStr(Random(900000)+100000)+Ext;
 Until Not FileExists(Path);
 If P.Typ='folderDestination'Then Begin
  {$I-}
  MkDir(Path);
  If IOResult<>0Then Begin End;
  {$I+}
 End;
 If TmpCount<40Then Begin
  Inc(TmpCount);
  TmpKey[TmpCount]:=Key;
  TmpPath[TmpCount]:=Path;
 End;
 TempOutput:=Path;
End;

Function NeedStr(A:Integer;Name:String):String;
Var
 V:String;
 P:ParamRec;
 Dest,Given:Boolean;
Begin
 If Not ParamDef(A,Name,P)Then Fail('Internal error: unknown parameter '+Name);
 Dest:=(Length(P.Typ)>11)and(Copy(P.Typ,Length(P.Typ)-10,11)='Destination');
 Given:=GetArg(Name,V);
 If Not Given Then Begin
  If(P.Def='')and Dest Then Begin NeedStr:=TempOutput(A,Name,P);Exit;End;
  If P.Def=''Then Fail('Error: missing required parameter '+Name);
  If P.Def='*'Then V:='' Else V:=P.Def;
 End
  Else
 If Dest and((StrUpper(V)='TEMPORARY_OUTPUT')or(StrUpper(Copy(V,1,7))='MEMORY:'))Then V:=TempOutput(A,Name,P);
 NeedStr:=V;
End;

Function HasArg(Name:String):Boolean;
Var
 V:String;
Begin
 HasArg:=GetArg(Name,V)and(V<>'');
End;

Function NeedReal(A:Integer;Name:String):Real;
Var
 V:String;
 R:Real;
 Err:Integer;
Begin
 V:=NeedStr(A,Name);
 Val(V,R,Err);
 If Err<>0Then Fail('Error: invalid value for parameter '+Name+': '+V);
 NeedReal:=R;
End;

Procedure AddRes(Name,Value:String);Begin
 Inc(ResCount);
 ResName[ResCount]:=Name;
 ResVal[ResCount]:=Value;
End;

{ ------------------------------------------------------------------ }
{ Algorithmes                                                         }
{ ------------------------------------------------------------------ }

Function Haversine(X1,Y1,X2,Y2:Real):Real;
Var
 DLat,DLon,A:Real;
Begin
 DLat:=Deg2Rad(Y2-Y1);
 DLon:=Deg2Rad(X2-X1);
 A:=Sqr(Sin(DLat/2))+Cos(Deg2Rad(Y1))*Cos(Deg2Rad(Y2))*Sqr(Sin(DLon/2));
 Haversine:=EarthRadius*2*Atan2(Sqrt(A),Sqrt(1-A));
End;

{ ---- geodesie sur l'ellipsoide (option --ellipsoid) ---- }

Var
 GeoOn,GeoNone:Boolean;
 GeoA,GeoF:Real;

{ Ellipsoide courant pour les mesures : celui demande, sinon la sphere moyenne }
Procedure MeasEll(Var A,F:Real);Begin
 If GeoOn Then Begin A:=GeoA;F:=GeoF;End
          Else Begin A:=EarthRadius;F:=0;End;
End;

Procedure SetEllipsoid(Value:String);
Var
 U,Sa,Sb:String;
 P,Err:Integer;
 A,B:Real;
 K:Integer;
Begin
 U:=StrUpper(Value);
 While(U<>'')and(U[1]=' ')do Delete(U,1,1);
 GeoOn:=False;GeoNone:=False;
 If(U='')Then Exit;
 If U='NONE'Then Begin GeoNone:=True;Exit;End;
 If Copy(U,1,10)='PARAMETER:'Then Begin
  Sa:=Copy(U,11,60);
  P:=Pos(':',Sa);
  If P=0Then Fail('Error: invalid ellipsoid "'+Value+'" (expected PARAMETER:semimajor:semiminor)');
  Sb:=Copy(Sa,P+1,60);Sa:=Copy(Sa,1,P-1);
  Val(Sa,A,Err);
  If(Err<>0)or(A<=0)Then Fail('Error: invalid ellipsoid semi-major axis in "'+Value+'"');
  Val(Sb,B,Err);
  If(Err<>0)or(B<=0)or(B>A)Then Fail('Error: invalid ellipsoid semi-minor axis in "'+Value+'"');
  GeoA:=A;GeoF:=(A-B)/A;GeoOn:=True;
  Exit;
 End;
 K:=0;
 If(U='EPSG:7030')or(U='WGS84')or(U='WGS 84')Then K:=1 Else
 If(U='EPSG:7019')or(U='GRS80')Then K:=2 Else
 If(U='EPSG:7008')or(U='CLARKE1866')Then K:=3 Else
 If(U='EPSG:7022')or(U='INTERNATIONAL1924')Then K:=4 Else
 If(U='EPSG:7004')or(U='BESSEL1841')Then K:=5 Else
 If(U='EPSG:7001')or(U='AIRY1830')Then K:=6 Else
 If(U='EPSG:7024')or(U='KRASSOWSKY')Then K:=8 Else
 If(U='EPSG:7012')or(U='CLARKE1880')Then K:=9 Else
 If(U='EPSG:7035')or(U='SPHERE')Then K:=7;
 If K=0Then Fail('Error: unknown ellipsoid "'+Value+'" (use NONE, EPSG:7030, EPSG:7019, EPSG:7008, EPSG:7022, EPSG:7004, EPSG:7001, EPSG:7024 or PARAMETER:a:b)');
 GeoA:=EllA[K];
 If EllRf[K]>0Then GeoF:=1/EllRf[K] Else GeoF:=0;
 GeoOn:=True;
End;

{ Probleme geodesique inverse (Vincenty) : distance et azimuts en degres ; Faux si pas de convergence }
Function GeoInverse(A,F,Lon1,Lat1,Lon2,Lat2:Real;Var S,Az1,Az2:Real):Boolean;
Var
 B,U1,U2,L,Lam,LamP,SinSig,CosSig,Sig,SinAl,CosSqAl,Cos2SM,C,USq,Ba,Bb,DSig,SinLam,CosLam,SU1,CU1,SU2,CU2,T:Real;
 It:Integer;
Begin
 GeoInverse:=True;
 S:=0;Az1:=0;Az2:=0;
 If(Lon1=Lon2)and(Lat1=Lat2)Then Exit;
 B:=A*(1-F);
 U1:=ArcTan((1-F)*Sin(Deg2Rad(Lat1))/Cos(Deg2Rad(Lat1)+1E-300));
 U2:=ArcTan((1-F)*Sin(Deg2Rad(Lat2))/Cos(Deg2Rad(Lat2)+1E-300));
 If Abs(Lat1)=90Then U1:=SgnR(Lat1)*Pi/2;
 If Abs(Lat2)=90Then U2:=SgnR(Lat2)*Pi/2;
 L:=Deg2Rad(Lon2-Lon1);
 While L>Pi do L:=L-2*Pi;
 While L<-Pi do L:=L+2*Pi;
 Lam:=L;
 SU1:=Sin(U1);CU1:=Cos(U1);SU2:=Sin(U2);CU2:=Cos(U2);
 It:=0;
 Repeat
  SinLam:=Sin(Lam);CosLam:=Cos(Lam);
  SinSig:=Sqrt(Sqr(CU2*SinLam)+Sqr(CU1*SU2-SU1*CU2*CosLam));
  If SinSig=0Then Exit;
  CosSig:=SU1*SU2+CU1*CU2*CosLam;
  Sig:=Atan2(SinSig,CosSig);
  SinAl:=CU1*CU2*SinLam/SinSig;
  CosSqAl:=1-SinAl*SinAl;
  If CosSqAl<>0Then Cos2SM:=CosSig-2*SU1*SU2/CosSqAl Else Cos2SM:=0;
  C:=F/16*CosSqAl*(4+F*(4-3*CosSqAl));
  LamP:=Lam;
  Lam:=L+(1-C)*F*SinAl*(Sig+C*SinSig*(Cos2SM+C*CosSig*(-1+2*Cos2SM*Cos2SM)));
  Inc(It);
 Until(Abs(Lam-LamP)<1E-12)or(It>200);
 If Abs(Lam-LamP)>=1E-9Then Begin GeoInverse:=False;Exit;End;
 USq:=CosSqAl*(A*A-B*B)/(B*B);
 Ba:=1+USq/16384*(4096+USq*(-768+USq*(320-175*USq)));
 Bb:=USq/1024*(256+USq*(-128+USq*(74-47*USq)));
 DSig:=Bb*SinSig*(Cos2SM+Bb/4*(CosSig*(-1+2*Cos2SM*Cos2SM)-Bb/6*Cos2SM*(-3+4*SinSig*SinSig)*(-3+4*Cos2SM*Cos2SM)));
 S:=B*Ba*(Sig-DSig);
 Az1:=Rad2Deg(Atan2(CU2*Sin(Lam),CU1*SU2-SU1*CU2*Cos(Lam)));
 Az2:=Rad2Deg(Atan2(CU1*Sin(Lam),-SU1*CU2+CU1*SU2*Cos(Lam)));
 If Az1<0Then Az1:=Az1+360;
 If Az2<0Then Az2:=Az2+360;
End;

{ Probleme geodesique direct (Vincenty) }
Procedure GeoDirect(A,F,Lon1,Lat1,Az1,S:Real;Var Lon2,Lat2:Real);
Var
 B,U1,Al1,SigmaD,Sig,SigP,SinAl,CosSqAl,USq,Ba,Bb,Cos2SM,SinSig,CosSig,DSig,Tmp,Lam,C,L,SU1,CU1:Real;
 It:Integer;
Begin
 B:=A*(1-F);
 Al1:=Deg2Rad(Az1);
 U1:=ArcTan((1-F)*Sin(Deg2Rad(Lat1))/Cos(Deg2Rad(Lat1)+1E-300));
 SU1:=Sin(U1);CU1:=Cos(U1);
 SigmaD:=Atan2(SU1/CU1,Cos(Al1));
 SinAl:=CU1*Sin(Al1);
 CosSqAl:=1-SinAl*SinAl;
 USq:=CosSqAl*(A*A-B*B)/(B*B);
 Ba:=1+USq/16384*(4096+USq*(-768+USq*(320-175*USq)));
 Bb:=USq/1024*(256+USq*(-128+USq*(74-47*USq)));
 Sig:=S/(B*Ba);
 It:=0;
 Repeat
  Cos2SM:=Cos(2*SigmaD+Sig);
  SinSig:=Sin(Sig);CosSig:=Cos(Sig);
  DSig:=Bb*SinSig*(Cos2SM+Bb/4*(CosSig*(-1+2*Cos2SM*Cos2SM)-Bb/6*Cos2SM*(-3+4*SinSig*SinSig)*(-3+4*Cos2SM*Cos2SM)));
  SigP:=Sig;
  Sig:=S/(B*Ba)+DSig;
  Inc(It);
 Until(Abs(Sig-SigP)<1E-12)or(It>200);
 SinSig:=Sin(Sig);CosSig:=Cos(Sig);
 Cos2SM:=Cos(2*SigmaD+Sig);
 Tmp:=SU1*SinSig-CU1*CosSig*Cos(Al1);
 Lat2:=Rad2Deg(Atan2(SU1*CosSig+CU1*SinSig*Cos(Al1),(1-F)*Sqrt(SinAl*SinAl+Tmp*Tmp)));
 Lam:=Atan2(SinSig*Sin(Al1),CU1*CosSig-SU1*SinSig*Cos(Al1));
 C:=F/16*CosSqAl*(4+F*(4-3*CosSqAl));
 L:=Lam-(1-C)*F*SinAl*(Sig+C*SinSig*(Cos2SM+C*CosSig*(-1+2*Cos2SM*Cos2SM)));
 Lon2:=Lon1+Rad2Deg(L);
 While Lon2>180do Lon2:=Lon2-360;
 While Lon2<-180do Lon2:=Lon2+360;
End;

{ Sinus de la latitude authalique }
Function AuthSin(F,Lat:Real):Real;
Var
 E2,E,Sp,Qp,Q:Real;
Begin
 E2:=F*(2-F);E:=Sqrt(E2);
 Sp:=Sin(Deg2Rad(Lat));
 If E<1E-12Then Begin AuthSin:=Sp;Exit;End;
 Qp:=1-(1-E2)/(2*E)*Ln((1-E)/(1+E));
 Q:=Sp/(1-E2*Sp*Sp)-1/(2*E)*Ln((1-E*Sp)/(1+E*Sp));
 AuthSin:=Q*(1-E2)/Qp;
End;

{ Longueur geodesique d'un trace en metres sur l'ellipsoide de mesure }
Function EllPathLength(P:PPath;A,F:Real):Real;
Var
 I:LongInt;
 L,S,Z1,Z2:Real;
Begin
 L:=0;
 For I:=0 to P^.N-2do Begin
  If GeoInverse(A,F,P^.Pts^[I].X,P^.Pts^[I].Y,P^.Pts^[I+1].X,P^.Pts^[I+1].Y,S,Z1,Z2)Then L:=L+S
   Else L:=L+Haversine(P^.Pts^[I].X,P^.Pts^[I].Y,P^.Pts^[I+1].X,P^.Pts^[I+1].Y)*A/EarthRadius;
 End;
 EllPathLength:=L;
End;

Function EllLength(Var G:TGeom):Real;
Var
 P:PPath;
 A,F,L:Real;
Begin
 MeasEll(A,F);
 L:=0;
 P:=G.First;
 While P<>Nil do Begin
  L:=L+EllPathLength(P,A,F);
  P:=P^.Next;
 End;
 EllLength:=L;
End;

{ Aire sur l'ellipsoide : trapeze en (longitude, sinus de latitude authalique) }
Function EllArea(Var G:TGeom):Real;
Var
 P:PPath;
 I:LongInt;
 A,F,E2,Qp,Rq,S,Tot,Dl:Real;
 Prev:Integer;
Begin
 MeasEll(A,F);
 E2:=F*(2-F);
 If E2<1E-14Then Rq:=A
  Else Rq:=A*Sqrt((1-(1-E2)/(2*Sqrt(E2))*Ln((1-Sqrt(E2))/(1+Sqrt(E2))))/2);
 Tot:=0;Prev:=-1;
 P:=G.First;
 While P<>Nil do Begin
  S:=0;
  For I:=0 to P^.N-2do Begin
   Dl:=Deg2Rad(P^.Pts^[I+1].X-P^.Pts^[I].X);
   While Dl>Pi do Dl:=Dl-2*Pi;
   While Dl<-Pi do Dl:=Dl+2*Pi;
   S:=S+Dl*(2+AuthSin(F,P^.Pts^[I].Y)+AuthSin(F,P^.Pts^[I+1].Y));
  End;
  S:=Abs(S)*Rq*Rq/2;
  If P^.Poly=Prev Then Tot:=Tot-S Else Tot:=Tot+S;
  Prev:=P^.Poly;
  P:=P^.Next;
 End;
 EllArea:=Tot;
End;

Function Bearing(X1,Y1,X2,Y2:Real):Real;
Var
 P1,P2,DL:Real;
Begin
 P1:=Deg2Rad(Y1);
 P2:=Deg2Rad(Y2);
 DL:=Deg2Rad(X2-X1);
 Bearing:=NormDeg(Rad2Deg(Atan2(Sin(DL)*Cos(P2),
                 Cos(P1)*Sin(P2)-Sin(P1)*Cos(P2)*Cos(DL))));
End;

Procedure RunDistance(A:Integer);
Var
 X1,Y1,X2,Y2,D,Az1,Az2:Real;
Begin
 X1:=NeedReal(A,'X1');Y1:=NeedReal(A,'Y1');
 X2:=NeedReal(A,'X2');Y2:=NeedReal(A,'Y2');
 D:=Haversine(X1,Y1,X2,Y2);
 If GeoOn Then
  If Not GeoInverse(GeoA,GeoF,X1,Y1,X2,Y2,D,Az1,Az2)Then D:=Haversine(X1,Y1,X2,Y2)*GeoA/EarthRadius;
 AddRes('DISTANCE',RealToStr(D));
 AddRes('DISTANCE_KM',RealToStr(D/1000));
End;

Procedure RunBearing(A:Integer);
Var
 X1,Y1,X2,Y2,D,Az1,Az2:Real;
Begin
 X1:=NeedReal(A,'X1');Y1:=NeedReal(A,'Y1');
 X2:=NeedReal(A,'X2');Y2:=NeedReal(A,'Y2');
 If GeoOn Then
  If GeoInverse(GeoA,GeoF,X1,Y1,X2,Y2,D,Az1,Az2)Then Begin
   AddRes('BEARING',RealToStr(Az1));
   AddRes('FINAL_BEARING',RealToStr(Az2));
   Exit;
  End;
 AddRes('BEARING',RealToStr(Bearing(X1,Y1,X2,Y2)));
 AddRes('FINAL_BEARING',RealToStr(NormDeg(Bearing(X2,Y2,X1,Y1)+180)));
End;

Procedure RunDestination(A:Integer);
Var
 X,Y,B,D,Delta,P1,P2,L2:Real;
Begin
 X:=NeedReal(A,'X');Y:=NeedReal(A,'Y');
 B:=Deg2Rad(NeedReal(A,'BEARING'));
 D:=NeedReal(A,'DISTANCE');
 If GeoOn Then Begin
  GeoDirect(GeoA,GeoF,X,Y,NeedReal(A,'BEARING'),D,L2,P2);
  AddRes('X',RealToStr(L2));
  AddRes('Y',RealToStr(P2));
  Exit;
 End;
 Delta:=D/EarthRadius;
 P1:=Deg2Rad(Y);
 P2:=ArcSin(Sin(P1)*Cos(Delta)+Cos(P1)*Sin(Delta)*Cos(B));
 L2:=Deg2Rad(X)+Atan2(Sin(B)*Sin(Delta)*Cos(P1),Cos(Delta)-Sin(P1)*Sin(P2));
 L2:=Rad2Deg(L2);
 While L2>180do L2:=L2-360;
 While L2<-180do L2:=L2+360;
 AddRes('X',RealToStr(L2));
 AddRes('Y',RealToStr(Rad2Deg(P2)));
End;

Procedure RunReproject(A:Integer);
Var
 X,Y:Real;
 Src,Dst:LongInt;
Begin
 X:=NeedReal(A,'X');Y:=NeedReal(A,'Y');
 Src:=ParseEpsg(NeedStr(A,'SOURCE_CRS'),'SOURCE_CRS');
 Dst:=ParseEpsg(NeedStr(A,'TARGET_CRS'),'TARGET_CRS');
 TransformPt(Src,Dst,X,Y);
 AddRes('X',RealToStr(X));
 AddRes('Y',RealToStr(Y));
End;

{ Parcourt un fichier GeoJSON et calcule l'etendue de ses coordonnees }
Procedure RunExtent(A:Integer);
Var
 FileName:String;
 Root,Arr,F:PJ;
 G:TGeom;
 P:PPath;
 I:LongInt;
 Features,Points:LongInt;
 MinX,MinY,MaxX,MaxY:Real;
 Have:Boolean;
Begin
 FileName:=NeedStr(A,'INPUT');
 Root:=LoadLayer(FileName);
 Arr:=LayerFeatures(Root);
 Features:=0;Points:=0;Have:=False;
 MinX:=0;MinY:=0;MaxX:=0;MaxY:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  Inc(Features);
  Flatten(JFind(F,'geometry'),G);
  P:=G.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-1do Begin
    Inc(Points);
    If Not Have Then Begin
     MinX:=P^.Pts^[I].X;MaxX:=MinX;MinY:=P^.Pts^[I].Y;MaxY:=MinY;Have:=True;
    End
     Else
    Begin
     If P^.Pts^[I].X<MinX Then MinX:=P^.Pts^[I].X;
     If P^.Pts^[I].X>MaxX Then MaxX:=P^.Pts^[I].X;
     If P^.Pts^[I].Y<MinY Then MinY:=P^.Pts^[I].Y;
     If P^.Pts^[I].Y>MaxY Then MaxY:=P^.Pts^[I].Y;
    End;
   End;
   P:=P^.Next;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 If Not Have Then Fail('Error: no coordinates found in '+FileName);
 AddRes('XMIN',RealToStr(MinX));
 AddRes('YMIN',RealToStr(MinY));
 AddRes('XMAX',RealToStr(MaxX));
 AddRes('YMAX',RealToStr(MaxY));
 AddRes('FEATURE_COUNT',IntToStr(Features));
 AddRes('POINT_COUNT',IntToStr(Points));
End;

Procedure RunCenter(A:Integer);
Var
 X1,Y1,X2,Y2:Real;
Begin
 X1:=NeedReal(A,'XMIN');Y1:=NeedReal(A,'YMIN');
 X2:=NeedReal(A,'XMAX');Y2:=NeedReal(A,'YMAX');
 AddRes('CENTER_X',RealToStr((X1+X2)/2));
 AddRes('CENTER_Y',RealToStr((Y1+Y2)/2));
 AddRes('WIDTH',RealToStr(Abs(X2-X1)));
 AddRes('HEIGHT',RealToStr(Abs(Y2-Y1)));
End;

{ Fusionne toutes les entites d'une couche en une seule (definie plus loin) }
Procedure DissolveAllInto(Root:PJ);Forward;
Function ParamExists(A:Integer;Name:String):Boolean;Forward;
Function NeedBool(A:Integer;Name:String):Boolean;Forward;

Procedure RunBuffer(A:Integer);
Var
 Root,Arr,F,Node:PJ;
 G,R:TGeom;
 Dist:Real;
 Seg:Integer;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Dist:=NeedReal(A,'DISTANCE');
 Seg:=Round(NeedReal(A,'SEGMENTS'));
 If(Seg<1)or(Seg>64)Then Fail('Error: SEGMENTS must be between 1 and 64');
 Out:=NeedStr(A,'OUTPUT');
 BufCap:=Round(NeedReal(A,'END_CAP_STYLE'));
 BufJoin:=Round(NeedReal(A,'JOIN_STYLE'));
 BufMiter:=NeedReal(A,'MITER_LIMIT');
 If(BufCap<0)or(BufCap>2)Then Fail('Error: END_CAP_STYLE must be 0 (round), 1 (flat) or 2 (square)');
 If(BufJoin<0)or(BufJoin>2)Then Fail('Error: JOIN_STYLE must be 0 (round), 1 (miter) or 2 (bevel)');
 If BufMiter<1Then Fail('Error: MITER_LIMIT must be at least 1');
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   If(Dist=0)and(G.Cls=3)Then Node:=JFind(F,'geometry')
    Else
   Begin
    BufferGeom(G,Dist,Seg,R);
    Node:=BuildPolygons(R);
    FreeGeom(R);
   End;
   If Node<>JFind(F,'geometry')Then SetGeom(F,Node);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 BufCap:=0;BufJoin:=0;BufMiter:=2;
 If ParamExists(A,'DISSOLVE')Then
  If NeedBool(A,'DISSOLVE')Then DissolveAllInto(Root);
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunCentroids(A:Integer);
Var
 Root,Arr,F:PJ;
 G:TGeom;
 Cx,Cy:Real;
 Ok:Boolean;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Out:=NeedStr(A,'OUTPUT');
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   CentroidGeom(G,Cx,Cy,Ok);
   If Ok Then SetGeom(F,GeomNode('Point',CoordNode(Cx,Cy)))
         Else SetGeom(F,Nil);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunConvexHull(A:Integer);
Var
 Root,Arr,F,Node:PJ;
 G,R:TGeom;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Out:=NeedStr(A,'OUTPUT');
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   HullGeom(G,R);
   Case R.Cls of
    1:Node:=BuildPoints(R);
    2:Node:=BuildLines(R);
    3:Node:=BuildPolygons(R);
    Else Node:=Nil;
   End;
   SetGeom(F,Node);
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunPolygonsToLines(A:Integer);
Var
 Root,Arr,F:PJ;
 G,R:TGeom;
 P:PPath;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Out:=NeedStr(A,'OUTPUT');
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   If G.Cls<>3Then Fail('Error: the input layer must contain polygons');
   InitGeom(R);
   R.Cls:=2;
   P:=G.First;
   While P<>Nil do Begin
    CopyPath(R,P,0);
    P:=P^.Next;
   End;
   SetGeom(F,BuildLines(R));
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunReprojectLayer(A:Integer);
Var
 Root,Arr,F,Gn:PJ;
 Src,Dst:LongInt;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Dst:=ParseEpsg(NeedStr(A,'TARGET_CRS'),'TARGET_CRS');
 Out:=NeedStr(A,'OUTPUT');
 Src:=LayerCrs(Root);
 Arr:=LayerFeatures(Root);
 If Src<>Dst Then Begin
  F:=Arr^.First;
  While F<>Nil do Begin
   Gn:=JFind(F,'geometry');
   If(Gn<>Nil)and(Gn^.Kind=5)Then TransformCoords(JFind(Gn,'coordinates'),Src,Dst);
   F:=F^.Next;
  End;
 End;
 SetLayerCrs(Root,Dst);
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunExtract(A:Integer);
Var
 Root,Arr,F,FailArr:PJ;
 Expr,Out,OutFail:String;
 WantFail:Boolean;
 FailRoot:PJ;
 Keep:Boolean;
 C:PJ;
 FA:PJArr;
 NFe,I:LongInt;
 KeepA:PBools;
 V:TVal;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Expr:=NeedStr(A,'EXPRESSION');
 Out:=NeedStr(A,'OUTPUT');
 OutFail:=NeedStr(A,'FAIL_OUTPUT');
 WantFail:=OutFail<>'';
 FailRoot:=Nil;FailArr:=Nil;
 If WantFail Then Begin
  FailRoot:=NewJ(5);
  JAddKV(FailRoot,'type',JText('FeatureCollection'));
  C:=JFind(Root,'crs');
  If C<>Nil Then JAddKV(FailRoot,'crs',JClone(C));
  FailArr:=NewJ(4);
  JAddKV(FailRoot,'features',FailArr);
 End;
 Arr:=LayerFeatures(Root);
 FA:=FeatureArray(Arr,NFe);
 KeepA:=AllocBlock((NFe+1)*SizeOf(Boolean));
 For I:=0 to NFe-1do Begin
  V:=EvalOn(Expr,FA^[I],I);
  KeepA^[I]:=(V.K in[1,3])and(V.N<>0);
 End;
 Arr^.First:=Nil;Arr^.Last:=Nil;
 For I:=0 to NFe-1do Begin
  F:=FA^[I];
  F^.Next:=Nil;
  Keep:=KeepA^[I];
  If Keep Then JAdd(Arr,F)
   Else
  If WantFail Then JAdd(FailArr,F);
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
 If WantFail Then Begin
  SaveLayer(OutFail,FailRoot);
  AddRes('FAIL_OUTPUT',OutFail);
 End;
End;

Procedure RunClip(A:Integer);
Var
 Root,Ov,Arr,OvArr,F,Nx:PJ;
 G,R,B,Bf:TGeom;
 Out:String;
 P,Q:PPath;
 MinX,MinY,MaxX,MaxY,Ext,Tol:Real;
 NB,I,N,NPoly,K:LongInt;
 Edges,Boxes:PEdges;
 Keep,Have:Boolean;
 Poly:Integer;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Ov:=LoadLayer(NeedStr(A,'OVERLAY'));
 Out:=NeedStr(A,'OUTPUT');
 { regroupe les polygones de la couche de superposition }
 InitGeom(B);
 B.Cls:=3;
 OvArr:=LayerFeatures(Ov);
 F:=OvArr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   If G.Cls<>3Then Fail('Error: the overlay layer must contain polygons');
   P:=G.First;
   While P<>Nil do Begin
    Q:=P^.Next;
    P^.Poly:=P^.Poly+B.NPoly;
    LinkPath(B,P);
    P:=Q;
   End;
   B.NPoly:=B.NPoly+G.NPoly;
  End;
  F:=F^.Next;
 End;
 If B.First=Nil Then Fail('Error: the overlay layer has no polygon');
 { boite englobante de chaque polygone de superposition }
 NPoly:=B.NPoly;
 Boxes:=AllocBlock(NPoly*SizeOf(TEdge));
 For K:=0 to NPoly-1do Begin Boxes^[K].X1:=1E300;Boxes^[K].Y1:=1E300;Boxes^[K].X2:=-1E300;Boxes^[K].Y2:=-1E300;End;
 P:=B.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-1do Begin
   If P^.Pts^[I].X<Boxes^[P^.Poly].X1 Then Boxes^[P^.Poly].X1:=P^.Pts^[I].X;
   If P^.Pts^[I].X>Boxes^[P^.Poly].X2 Then Boxes^[P^.Poly].X2:=P^.Pts^[I].X;
   If P^.Pts^[I].Y<Boxes^[P^.Poly].Y1 Then Boxes^[P^.Poly].Y1:=P^.Pts^[I].Y;
   If P^.Pts^[I].Y>Boxes^[P^.Poly].Y2 Then Boxes^[P^.Poly].Y2:=P^.Pts^[I].Y;
  End;
  P:=P^.Next;
 End;
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 Arr^.First:=Nil;Arr^.Last:=Nil;
 While F<>Nil do Begin
  Nx:=F^.Next;
  Flatten(JFind(F,'geometry'),G);
  Keep:=False;
  If G.Cls<>0Then Begin
   { boite de l'entite }
   Have:=False;
   MinX:=0;MinY:=0;MaxX:=0;MaxY:=0;
   P:=G.First;
   While P<>Nil do Begin
    For I:=0 to P^.N-1do Begin
     If Not Have Then Begin
      MinX:=P^.Pts^[I].X;MaxX:=MinX;MinY:=P^.Pts^[I].Y;MaxY:=MinY;Have:=True;
     End
      Else
     Begin
      If P^.Pts^[I].X<MinX Then MinX:=P^.Pts^[I].X;
      If P^.Pts^[I].X>MaxX Then MaxX:=P^.Pts^[I].X;
      If P^.Pts^[I].Y<MinY Then MinY:=P^.Pts^[I].Y;
      If P^.Pts^[I].Y>MaxY Then MaxY:=P^.Pts^[I].Y;
     End;
    End;
    P:=P^.Next;
   End;
   { polygones de superposition susceptibles de toucher l'entite }
   InitGeom(Bf);
   Bf.Cls:=3;
   P:=B.First;
   While P<>Nil do Begin
    Poly:=P^.Poly;
    If(Boxes^[Poly].X1<=MaxX)and(Boxes^[Poly].X2>=MinX)and
      (Boxes^[Poly].Y1<=MaxY)and(Boxes^[Poly].Y2>=MinY)Then Begin
     CopyPath(Bf,P,Poly);
    End;
    P:=P^.Next;
   End;
   If Bf.First<>Nil Then Begin
    Q:=Bf.First;
    While Q<>Nil do Begin
     For I:=0 to Q^.N-1do Begin
      If Q^.Pts^[I].X<MinX Then MinX:=Q^.Pts^[I].X;
      If Q^.Pts^[I].X>MaxX Then MaxX:=Q^.Pts^[I].X;
      If Q^.Pts^[I].Y<MinY Then MinY:=Q^.Pts^[I].Y;
      If Q^.Pts^[I].Y>MaxY Then MaxY:=Q^.Pts^[I].Y;
     End;
     Q:=Q^.Next;
    End;
    Ext:=MaxR(MaxX-MinX,MaxY-MinY);
    If Ext<=0Then Ext:=1;
    SnapQ:=Ext*1E-9;
    Tol:=SnapQ*4;
    Case G.Cls of
     3:Begin
      Overlay(1,G,Bf,R);
      If R.First<>Nil Then Begin
       SetGeom(F,BuildPolygons(R));
       Keep:=True;
      End;
      FreeGeom(R);
     End;
     2,1:Begin
      NB:=EdgeCount(Bf);
      Edges:=AllocBlock(NB*SizeOf(TEdge));
      N:=0;
      FillEdges(Bf,Edges,N);
      If G.Cls=2Then Begin
       ClipLines(G,Edges,N,Tol,R);
       If R.First<>Nil Then Begin
        SetGeom(F,BuildLines(R));
        Keep:=True;
       End;
       FreeGeom(R);
      End
       Else
      Begin
       InitGeom(R);
       R.Cls:=1;
       P:=G.First;
       While P<>Nil do Begin
        If InsideOrOn(Edges,N,P^.Pts^[0].X,P^.Pts^[0].Y,Tol)Then CopyPath(R,P,0);
        P:=P^.Next;
       End;
       If R.First<>Nil Then Begin
        SetGeom(F,BuildPoints(R));
        Keep:=True;
       End;
       FreeGeom(R);
      End;
      FreeMem(Edges,NB*SizeOf(TEdge));
     End;
    End;
   End;
   FreeGeom(Bf);
  End;
  If Keep Then JAdd(Arr,F);
  FreeGeom(G);
  F:=Nx;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

{ Ecritures en flux : GeoJSON direct, sinon fichier temporaire converti ensuite }
Function StreamTmp(Out:String):String;
Var
 Ext,Dir:String;
Begin
 Ext:=FileExt(Out);
 If(Ext='.GEOJSON')or(Ext='.JSON')or(Ext='')Then Begin StreamTmp:=Out;Exit;End;
 Dir:=TempDir;
 If(Dir<>'')and(Dir[Length(Dir)]<>'/')and(Dir[Length(Dir)]<>#92)Then Dir:=Dir+'/';
 StreamTmp:=Dir+'qgis_process_stream_'+IntToStr(Random(900000)+100000)+'.geojson';
End;

Procedure StreamDone(Final,Tmp:String);
Var
 Root:PJ;
 F:File;
Begin
 If Final=Tmp Then Exit;
 Root:=LoadGeoJSON(Tmp);
 SaveLayer(Final,Root);
 Assign(F,Tmp);
 {$I-}
 Erase(F);
 {$I+}
 If IOResult<>0Then Begin End;
End;

Procedure RunPixelsToPoints(A:Integer);
Var
 R:TRaster;
 F:Text;
 Out,Fld,Final:String;
 I,J:LongInt;
 First:Boolean;
 V:Real;
Begin
 ReadRaster(NeedStr(A,'INPUT_RASTER'),R);
 { bande choisie dans RunAlgo }
 Fld:=NeedStr(A,'FIELD_NAME');
 Final:=NeedStr(A,'OUTPUT');
 Out:=StreamTmp(Final);
 {$I-}
 Assign(F,Out);
 Rewrite(F);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to create output file '+Out);
 Write(F,'{"type":"FeatureCollection",');
 If(R.Epsg<>0)and(R.Epsg<>4326)and CrsKnown(R.Epsg)Then Write(F,'"crs":{"type":"name","properties":{"name":"',CrsLabel(R.Epsg),'"}},');
 WriteLn(F,'"features":[');
 First:=True;
 For I:=0 to R.NR-1do Begin
  For J:=0 to R.NC-1do Begin
   V:=R.Data^[I*R.NC+J];
   If Not IsNoData(R,V)Then Begin
    If Not First Then WriteLn(F,',');
    First:=False;
    Write(F,'{"type":"Feature","properties":{',JsonStr(Fld),':',NumStr(V),
          '},"geometry":{"type":"Point","coordinates":[',
          NumStr(R.XLL+(J+0.5)*R.Cell),',',NumStr(R.YLL+(R.NR-I-0.5)*R.Cell),']}}');
   End;
  End;
 End;
 WriteLn(F);
 WriteLn(F,']}');
 Close(F);
 StreamDone(Final,Out);
 AddRes('OUTPUT',Final);
End;

Procedure ParseExtent(S:String;Var X1,X2,Y1,Y2:Real);
Var
 P,K:Integer;
 V:Array[1..4]of Real;
 T:String;
Begin
 P:=Pos('[',S);
 If P>0Then S:=Copy(S,1,P-1);
 For K:=1 to 4do Begin
  P:=Pos(',',S);
  If(K<4)and(P=0)Then Fail('Error: EXTENT must be xmin,xmax,ymin,ymax');
  If K<4Then Begin T:=Copy(S,1,P-1);S:=Copy(S,P+1,255);End
        Else T:=S;
  While(T<>'')and(T[1]=' ')do T:=Copy(T,2,255);
  While(T<>'')and(T[Length(T)]=' ')do T:=Copy(T,1,Length(T)-1);
  If Not IsNumber(T)Then Fail('Error: invalid EXTENT value "'+T+'"');
  Val(T,V[K],P);
 End;
 X1:=V[1];X2:=V[2];Y1:=V[3];Y2:=V[4];
 If(X2<=X1)or(Y2<=Y1)Then Fail('Error: invalid EXTENT (max must be greater than min)');
End;

{ ------------------------------------------------------------------ }
{ Utilitaires communs aux nouveaux algorithmes                        }
{ ------------------------------------------------------------------ }

Var
 ListItems:Array[1..40]of String;
 ListCount:Integer;
 InfoLines:Array[1..400]of String;
 InfoCount:Integer;

{ Decoupe S selon les separateurs Seps }
Procedure SplitList(S:String;Seps:String);
Var
 I:Integer;
 T:String;
Begin
 ListCount:=0;
 T:='';
 For I:=1 to Length(S)+1do Begin
  If(I>Length(S))or(Pos(S[I],Seps)>0)Then Begin
   If T<>''Then Begin
    If ListCount>=40Then Fail('Error: too many list items');
    Inc(ListCount);
    ListItems[ListCount]:=T;
   End;
   T:='';
  End
   Else
  T:=T+S[I];
 End;
End;

Function NeedBool(A:Integer;Name:String):Boolean;
Var
 V:String;
Begin
 V:=StrUpper(NeedStr(A,Name));
 If(V='TRUE')or(V='1')or(V='YES')or(V='T')Then NeedBool:=True Else
 If(V='FALSE')or(V='0')or(V='NO')or(V='F')or(V='')Then NeedBool:=False
  Else
 Fail('Error: invalid boolean value for parameter '+Name+': '+V);
End;

Function CeilL(X:Real):LongInt;Begin
 CeilL:=-FloorL(-X);
End;

Procedure CheckBand(A:Integer);Begin
 { bande choisie dans RunAlgo }
End;

Procedure NewRaster(Var R:TRaster;NC,NR:LongInt;XLL,YLL,Cell,Nd:Real);
Var
 I,T:LongInt;
Begin
 If(NC<1)or(NR<1)Then Fail('Error: invalid raster size');
 If(NC*1.0)*NR>MaxCells Then Fail('Error: raster is too large');
 R.NC:=NC;R.NR:=NR;R.XLL:=XLL;R.YLL:=YLL;R.Cell:=Cell;R.NoData:=Nd;R.DType:=0;R.Epsg:=LastEpsg;
 T:=NC*NR;
 R.Data:=AllocBlock(T*SizeOf(Real));
 For I:=0 to T-1do R.Data^[I]:=Nd;
End;

Function RasterTop(Var R:TRaster):Real;Begin
 RasterTop:=R.YLL+R.NR*R.Cell;
End;

{ Echantillonne un raster en (X,Y) : Mode 0 voisin le plus proche, 1 bilineaire }
Function SampleRaster(Var R:TRaster;X,Y:Real;Mode:Integer;Var V:Real):Boolean;
Var
 Col,Row,Fx,Fy,Wx,Wy,Sum,Wt,W:Real;
 Cc,Rr,Q,Cx,Cy:LongInt;
 Z:Real;
Begin
 SampleRaster:=False;
 Col:=(X-R.XLL)/R.Cell;
 Row:=(RasterTop(R)-Y)/R.Cell;
 If(Col<0)or(Col>=R.NC)or(Row<0)or(Row>=R.NR)Then Exit;
 If Mode=0Then Begin
  Z:=R.Data^[FloorL(Row)*R.NC+FloorL(Col)];
  If IsNoData(R,Z)Then Exit;
  V:=Z;
  SampleRaster:=True;
  Exit;
 End;
 Fx:=Col-0.5;Fy:=Row-0.5;
 Cc:=FloorL(Fx);Rr:=FloorL(Fy);
 Wx:=Fx-Cc;Wy:=Fy-Rr;
 Sum:=0;Wt:=0;
 For Q:=0 to 3do Begin
  If Q and 1=0Then W:=1-Wx Else W:=Wx;
  If Q and 2=0Then W:=W*(1-Wy) Else W:=W*Wy;
  Cx:=Cc+(Q and 1);
  Cy:=Rr+(Q shr 1);
  If(Cx>=0)and(Cx<R.NC)and(Cy>=0)and(Cy<R.NR)Then Begin
   Z:=R.Data^[Cy*R.NC+Cx];
   If Not IsNoData(R,Z)Then Begin
    Sum:=Sum+Z*W;
    Wt:=Wt+W;
   End;
  End;
 End;
 If Wt>0Then Begin
  V:=Sum/Wt;
  SampleRaster:=True;
 End;
End;

{ Nom de fichier sans repertoire ni extension }
Function BaseName(S:String):String;
Var
 I:Integer;
Begin
 For I:=Length(S)downto 1do
  If S[I]in['/','\',':']Then Begin
   S:=Copy(S,I+1,255);
   Break;
  End;
 I:=Length(S);
 While(I>0)and(S[I]<>'.')do Dec(I);
 If I>1Then S:=Copy(S,1,I-1);
 BaseName:=S;
End;

{ ------------------------------------------------------------------ }
{ Algorithmes vectoriels                                              }
{ ------------------------------------------------------------------ }

Procedure RunOffsetCurve(A:Integer);
Var
 Root,Arr,F:PJ;
 G,R:TGeom;
 P:PPath;
 Dist:Real;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Dist:=NeedReal(A,'DISTANCE');
 Out:=NeedStr(A,'OUTPUT');
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   If G.Cls<>2Then Fail('Error: the input layer must contain lines');
   InitGeom(R);
   R.Cls:=2;
   P:=G.First;
   While P<>Nil do Begin
    OffsetCurve(R,P,Dist,5);
    P:=P^.Next;
   End;
   SetGeom(F,BuildLines(R));
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunOneSideBuffer(A:Integer);
Var
 Root,Arr,F:PJ;
 G,Pc,B,R:TGeom;
 P:PPath;
 Dist:Real;
 Side,Seg,K:Integer;
 Out:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Dist:=NeedReal(A,'DISTANCE');
 Side:=Round(NeedReal(A,'BUFFER_SIDE'));
 Seg:=Round(NeedReal(A,'SEGMENTS'));
 If(Seg<1)or(Seg>64)Then Fail('Error: SEGMENTS must be between 1 and 64');
 If(Side<>0)and(Side<>1)Then Fail('Error: BUFFER_SIDE must be 0 (left) or 1 (right)');
 Out:=NeedStr(A,'OUTPUT');
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  Flatten(JFind(F,'geometry'),G);
  If G.Cls<>0Then Begin
   If G.Cls<>2Then Fail('Error: the input layer must contain lines');
   InitGeom(Pc);InitGeom(B);
   Pc.Cls:=3;B.Cls:=3;
   K:=0;
   If Dist>0Then Begin
    P:=G.First;
    While P<>Nil do Begin
     SidePieces(Pc,P,Dist,Side=1,Seg,K);
     P:=P^.Next;
    End;
   End;
   InitGeom(R);
   If Pc.First<>Nil Then Begin
    KeepOrient:=True;
    Overlay(0,Pc,B,R);
    KeepOrient:=False;
   End;
   SetGeom(F,BuildPolygons(R));
   FreeGeom(R);FreeGeom(Pc);FreeGeom(B);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure Info(S:String);Begin
 If InfoCount<400Then Begin
  Inc(InfoCount);
  InfoLines[InfoCount]:=S;
 End
  Else
 If InfoCount=400Then Begin
  Inc(InfoCount);
  InfoLines[400]:='... (truncated)';
 End;
End;

Procedure RunOgrInfo(A:Integer);
Var
 FileName,Out,Name,GT:String;
 Root,Arr,F,Pr,V:PJ;
 G:TGeom;
 P:PPath;
 I,J,N,NF,Idx:LongInt;
 Summary,Have:Boolean;
 MinX,MinY,MaxX,MaxY:Real;
 FNames,FTypes:Array[1..64]of String;
 T:Text;
Begin
 FNames[1]:='';
 FileName:=NeedStr(A,'INPUT');
 Summary:=NeedBool(A,'SUMMARY_ONLY');
 Out:=NeedStr(A,'OUTPUT');
 Root:=LoadLayer(FileName);
 Arr:=LayerFeatures(Root);
 InfoCount:=0;
 N:=0;NF:=0;Have:=False;GT:='Unknown';
 MinX:=0;MinY:=0;MaxX:=0;MaxY:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  Inc(N);
  Flatten(JFind(F,'geometry'),G);
  If(G.Cls<>0)Then Begin
   If GT='Unknown'Then GT:=JVal(JFind(JFind(F,'geometry'),'type'));
   P:=G.First;
   While P<>Nil do Begin
    For I:=0 to P^.N-1do
     If Not Have Then Begin
      MinX:=P^.Pts^[I].X;MaxX:=MinX;MinY:=P^.Pts^[I].Y;MaxY:=MinY;Have:=True;
     End
      Else
     Begin
      If P^.Pts^[I].X<MinX Then MinX:=P^.Pts^[I].X;
      If P^.Pts^[I].X>MaxX Then MaxX:=P^.Pts^[I].X;
      If P^.Pts^[I].Y<MinY Then MinY:=P^.Pts^[I].Y;
      If P^.Pts^[I].Y>MaxY Then MaxY:=P^.Pts^[I].Y;
     End;
    P:=P^.Next;
   End;
  End;
  FreeGeom(G);
  Pr:=JFind(F,'properties');
  If(Pr<>Nil)and(Pr^.Kind=5)Then Begin
   V:=Pr^.First;
   While V<>Nil do Begin
    Idx:=0;
    For J:=1 to NF do If FNames[J]=JKey(V)Then Idx:=J;
    If(Idx=0)and(NF<64)Then Begin
     Inc(NF);Idx:=NF;
     FNames[NF]:=JKey(V);
     FTypes[NF]:='';
    End;
    If(Idx>0)and(FTypes[Idx]='')Then Begin
     Case V^.Kind of
      1:FTypes[Idx]:='Boolean';
      2:If(Pos('.',JVal(V))>0)or(Pos('e',JVal(V))>0)or(Pos('E',JVal(V))>0)Then FTypes[Idx]:='Real'
                                                                         Else FTypes[Idx]:='Integer';
      3:FTypes[Idx]:='String';
     End;
    End;
    V:=V^.Next;
   End;
  End;
  F:=F^.Next;
 End;
 Name:=BaseName(FileName);
 Info('INFO: Open of `'+FileName+'''');
 Info('      using driver `GeoJSON'' successful.');
 Info('');
 Info('Layer name: '+Name);
 Info('Geometry: '+GT);
 Info('Feature Count: '+IntToStr(N));
 If Have Then Info('Extent: ('+NumStr(MinX)+', '+NumStr(MinY)+') - ('+NumStr(MaxX)+', '+NumStr(MaxY)+')');
 Begin
  If LayerCrs(Root)>CustomBase Then Info('Layer SRS: '+CrsLabel(LayerCrs(Root)))
   Else Info('Layer SRS: EPSG:'+IntToStr(LayerCrs(Root)));
 End;
 For J:=1 to NF do
  If FTypes[J]<>''Then Info(FNames[J]+': '+FTypes[J])
                  Else Info(FNames[J]+': String');
 If Not Summary Then Begin
  I:=0;
  F:=Arr^.First;
  While F<>Nil do Begin
   Info('');
   Info('OGRFeature('+Name+'):'+IntToStr(I));
   Pr:=JFind(F,'properties');
   If(Pr<>Nil)and(Pr^.Kind=5)Then Begin
    V:=Pr^.First;
    While V<>Nil do Begin
     Info('  '+JKey(V)+' = '+JVal(V));
     V:=V^.Next;
    End;
   End;
   V:=JFind(F,'geometry');
   If(V<>Nil)and(V^.Kind=5)Then Info('  '+JVal(JFind(V,'type')))
                           Else Info('  (null)');
   Inc(I);
   F:=F^.Next;
  End;
 End;
 If Out<>''Then Begin
  {$I-}
  Assign(T,Out);
  Rewrite(T);
  {$I+}
  If IOResult<>0Then Fail('Error: unable to create output file '+Out);
  For I:=1 to InfoCount do WriteLn(T,InfoLines[I]);
  Close(T);
  AddRes('OUTPUT',Out);
 End;
End;

{ ------------------------------------------------------------------ }
{ Rasterisation                                                       }
{ ------------------------------------------------------------------ }

Procedure BurnCell(Var R:TRaster;Col,Row:LongInt;V:Real;AddMode:Boolean);
Var
 K:LongInt;
Begin
 If(Col<0)or(Col>=R.NC)or(Row<0)or(Row>=R.NR)Then Exit;
 K:=Row*R.NC+Col;
 If AddMode Then Begin
  If IsNoData(R,R.Data^[K])Then R.Data^[K]:=V
                           Else R.Data^[K]:=R.Data^[K]+V;
 End
  Else
 R.Data^[K]:=V;
End;

{ Grave les entites d'une couche dans le raster }
Procedure BurnLayer(Var R:TRaster;Root:PJ;Field:String;Fixed:Real;AddMode:Boolean);
Var
 Arr,F,Pr,Fv:PJ;
 G:TGeom;
 P:PPath;
 V,Y,Xa,Xb,Tmp,X1,Y1,X2,Y2,Len,T:Real;
 Xs:PReals;
 NX,I,J,K,Cap,C0,C1,Row,Steps:LongInt;
 E:Integer;
Begin
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 While F<>Nil do Begin
  V:=Fixed;
  If Field<>''Then Begin
   Pr:=JFind(F,'properties');
   Fv:=JFind(Pr,Field);
   If(Fv=Nil)or(Fv^.Kind<>2)Then V:=R.NoData
    Else Val(JVal(Fv),V,E);
  End;
  Flatten(JFind(F,'geometry'),G);
  If(G.Cls<>0)and Not((Field<>'')and IsNoData(R,V)and(Fv=Nil))Then Begin
   Case G.Cls of
    1:Begin
     P:=G.First;
     While P<>Nil do Begin
      BurnCell(R,FloorL((P^.Pts^[0].X-R.XLL)/R.Cell),FloorL((RasterTop(R)-P^.Pts^[0].Y)/R.Cell),V,AddMode);
      P:=P^.Next;
     End;
    End;
    2:Begin
     P:=G.First;
     While P<>Nil do Begin
      If P^.N=1Then
       BurnCell(R,FloorL((P^.Pts^[0].X-R.XLL)/R.Cell),FloorL((RasterTop(R)-P^.Pts^[0].Y)/R.Cell),V,AddMode);
      For I:=0 to P^.N-2do Begin
       X1:=P^.Pts^[I].X;Y1:=P^.Pts^[I].Y;X2:=P^.Pts^[I+1].X;Y2:=P^.Pts^[I+1].Y;
       Len:=Sqrt(Sqr(X2-X1)+Sqr(Y2-Y1));
       Steps:=CeilL(Len/(R.Cell/2))+1;
       For J:=0 to Steps do Begin
        T:=J/Steps;
        BurnCell(R,FloorL((X1+T*(X2-X1)-R.XLL)/R.Cell),FloorL((RasterTop(R)-(Y1+T*(Y2-Y1)))/R.Cell),V,AddMode);
       End;
      End;
      P:=P^.Next;
     End;
    End;
    3:Begin
     { remplissage par balayage, regle pair/impair, centres de pixels }
     Cap:=0;
     P:=G.First;
     While P<>Nil do Begin Inc(Cap,P^.N);P:=P^.Next;End;
     Xs:=AllocBlock((Cap+2)*SizeOf(Real));
     For Row:=0 to R.NR-1do Begin
      Y:=RasterTop(R)-(Row+0.5)*R.Cell;
      NX:=0;
      P:=G.First;
      While P<>Nil do Begin
       For I:=0 to P^.N-1do Begin
        K:=I+1;
        If K>=P^.N Then K:=0;
        X1:=P^.Pts^[I].X;Y1:=P^.Pts^[I].Y;X2:=P^.Pts^[K].X;Y2:=P^.Pts^[K].Y;
        If(Y1<=Y)<>(Y2<=Y)Then Begin
         Xs^[NX]:=X1+(Y-Y1)*(X2-X1)/(Y2-Y1);
         Inc(NX);
        End;
       End;
       P:=P^.Next;
      End;
      { tri par insertion }
      For I:=1 to NX-1do Begin
       Tmp:=Xs^[I];
       K:=I-1;
       While(K>=0)and(Xs^[K]>Tmp)do Begin Xs^[K+1]:=Xs^[K];Dec(K);End;
       Xs^[K+1]:=Tmp;
      End;
      I:=0;
      While I+1<NX do Begin
       Xa:=Xs^[I];Xb:=Xs^[I+1];
       C0:=CeilL((Xa-R.XLL)/R.Cell-0.5);
       C1:=CeilL((Xb-R.XLL)/R.Cell-0.5)-1;
       If C0<0Then C0:=0;
       If C1>=R.NC Then C1:=R.NC-1;
       For J:=C0 to C1 do BurnCell(R,J,Row,V,AddMode);
       Inc(I,2);
      End;
     End;
     FreeMem(Xs,(Cap+2)*SizeOf(Real));
    End;
   End;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
End;

Procedure RunRasterize(A:Integer);
Var
 Root,Arr,F:PJ;
 G:TGeom;
 P:PPath;
 R:TRaster;
 Fld,Out:String;
 Burn,Nd,MinX,MinY,MaxX,MaxY,W,H,Cw,Ch,Cell:Real;
 Units,NC,NR,I:LongInt;
 Have:Boolean;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 Fld:=NeedStr(A,'FIELD');
 Burn:=NeedReal(A,'BURN');
 Units:=Round(NeedReal(A,'UNITS'));
 W:=NeedReal(A,'WIDTH');
 H:=NeedReal(A,'HEIGHT');
 Nd:=NeedReal(A,'NODATA');
 Out:=NeedStr(A,'OUTPUT');
 If(W<=0)or(H<=0)Then Fail('Error: WIDTH and HEIGHT must be greater than 0');
 If HasArg('EXTENT')Then ParseExtent(NeedStr(A,'EXTENT'),MinX,MaxX,MinY,MaxY)
  Else
 Begin
  Have:=False;
  MinX:=0;MaxX:=0;MinY:=0;MaxY:=0;
  Arr:=LayerFeatures(Root);
  F:=Arr^.First;
  While F<>Nil do Begin
   Flatten(JFind(F,'geometry'),G);
   P:=G.First;
   While P<>Nil do Begin
    For I:=0 to P^.N-1do
     If Not Have Then Begin
      MinX:=P^.Pts^[I].X;MaxX:=MinX;MinY:=P^.Pts^[I].Y;MaxY:=MinY;Have:=True;
     End
      Else
     Begin
      If P^.Pts^[I].X<MinX Then MinX:=P^.Pts^[I].X;
      If P^.Pts^[I].X>MaxX Then MaxX:=P^.Pts^[I].X;
      If P^.Pts^[I].Y<MinY Then MinY:=P^.Pts^[I].Y;
      If P^.Pts^[I].Y>MaxY Then MaxY:=P^.Pts^[I].Y;
     End;
    P:=P^.Next;
   End;
   FreeGeom(G);
   F:=F^.Next;
  End;
  If(Not Have)or(MaxX<=MinX)or(MaxY<=MinY)Then Fail('Error: unable to compute the extent, use EXTENT');
 End;
 If Units=0Then Begin
  Cw:=(MaxX-MinX)/W;Ch:=(MaxY-MinY)/H;
  If Abs(Cw-Ch)>1E-6*Cw Then Fail('Error: non-square pixels are not supported');
  Cell:=Cw;
  NC:=Round(W);NR:=Round(H);
 End
  Else
 Begin
  If Abs(W-H)>1E-9*W Then Fail('Error: non-square pixels are not supported');
  Cell:=W;
  NC:=CeilL((MaxX-MinX)/Cell-1E-9);
  NR:=CeilL((MaxY-MinY)/Cell-1E-9);
 End;
 NewRaster(R,NC,NR,MinX,MaxY-NR*Cell,Cell,Nd);
 BurnLayer(R,Root,Fld,Burn,False);
 WriteRaster(Out,R);
 AddRes('OUTPUT',Out);
End;

{ Variantes "rasterize_over" : Mode 0 champ, 1 valeur fixe }
Procedure RunRasterizeOver(A:Integer;Fixed:Boolean);
Var
 Root:PJ;
 R:TRaster;
 Out,InR:String;
Begin
 Root:=LoadLayer(NeedStr(A,'INPUT'));
 InR:=NeedStr(A,'INPUT_RASTER');
 ReadRaster(InR,R);
 Out:=NeedStr(A,'OUTPUT');
 If Out=''Then Out:=InR;   { comme QGIS : le raster est modifie sur place }
 If Fixed Then BurnLayer(R,Root,'',NeedReal(A,'BURN'),NeedBool(A,'ADD'))
          Else BurnLayer(R,Root,NeedStr(A,'FIELD'),0,NeedBool(A,'ADD'));
 WriteRaster(Out,R);
 AddRes('OUTPUT',Out);
End;

{ ------------------------------------------------------------------ }
{ Algorithmes raster                                                  }
{ ------------------------------------------------------------------ }

Procedure RunNearBlack(A:Integer);
Var
 R:TRaster;
 Near,Th,V:Real;
 White:Boolean;
 Stack:PLongs;
 Seen:PBools;
 Sp,N,K,I,J,Nc,Nr:LongInt;
 Out:String;

 Function Hit(Q:LongInt):Boolean;Begin
  Hit:=False;
  If Seen^[Q]Then Exit;
  V:=R.Data^[Q];
  If IsNoData(R,V)Then Exit;
  If White Then Hit:=V>=Th Else Hit:=V<=Th;
 End;

 Procedure Push(Q:LongInt);Begin
  If Hit(Q)Then Begin
   Seen^[Q]:=True;
   Stack^[Sp]:=Q;
   Inc(Sp);
  End;
 End;

Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 Near:=NeedReal(A,'NEAR');
 White:=NeedBool(A,'WHITE');
 Out:=NeedStr(A,'OUTPUT');
 Nc:=R.NC;Nr:=R.NR;
 N:=Nc*Nr;
 Stack:=AllocBlock(N*SizeOf(LongInt));
 Seen:=AllocBlock(N*SizeOf(Boolean));
 For K:=0 to N-1do Seen^[K]:=False;
 If White Then Th:=255-Near Else Th:=Near;
 Sp:=0;
 For J:=0 to Nc-1do Begin Push(J);Push((Nr-1)*Nc+J);End;
 For I:=0 to Nr-1do Begin Push(I*Nc);Push(I*Nc+Nc-1);End;
 While Sp>0do Begin
  Dec(Sp);
  K:=Stack^[Sp];
  If White Then R.Data^[K]:=255 Else R.Data^[K]:=0;
  I:=K div Nc;J:=K mod Nc;
  If I>0Then Push(K-Nc);
  If I<Nr-1Then Push(K+Nc);
  If J>0Then Push(K-1);
  If J<Nc-1Then Push(K+1);
 End;
 WriteRaster(Out,R);
 AddRes('OUTPUT',Out);
End;

Procedure RunOverviews(A:Integer);
Var
 R,O:TRaster;
 Out,Name:String;
 Resamp,L,K,I,J,Ii,Jj,Cnt:LongInt;
 C:Integer;
 Sum,V:Real;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 Resamp:=Round(NeedReal(A,'RESAMPLING'));
 If(Resamp<>0)and(Resamp<>1)Then Fail('Error: RESAMPLING must be 0 (nearest) or 1 (average)');
 SplitList(NeedStr(A,'LEVELS'),' ,;');
 Out:=NeedStr(A,'OUTPUT');
 If ListCount=0Then Fail('Error: LEVELS is empty');
 For K:=1 to ListCount do Begin
  Val(ListItems[K],L,C);
  If(C<>0)or(L<2)Then Fail('Error: invalid overview level '+ListItems[K]);
  NewRaster(O,CeilL(R.NC/L),CeilL(R.NR/L),R.XLL,RasterTop(R)-CeilL(R.NR/L)*R.Cell*L,R.Cell*L,R.NoData);
  For I:=0 to O.NR-1do
   For J:=0 to O.NC-1do Begin
    If Resamp=0Then Begin
     Ii:=I*L+L div 2;Jj:=J*L+L div 2;
     If Ii>=R.NR Then Ii:=R.NR-1;
     If Jj>=R.NC Then Jj:=R.NC-1;
     O.Data^[I*O.NC+J]:=R.Data^[Ii*R.NC+Jj];
    End
     Else
    Begin
     Sum:=0;Cnt:=0;
     For Ii:=I*L to I*L+L-1do
      For Jj:=J*L to J*L+L-1do
       If(Ii<R.NR)and(Jj<R.NC)Then Begin
        V:=R.Data^[Ii*R.NC+Jj];
        If Not IsNoData(R,V)Then Begin Sum:=Sum+V;Inc(Cnt);End;
       End;
     If Cnt>0Then O.Data^[I*O.NC+J]:=Sum/Cnt;
    End;
   End;
  Name:=Out+'.ovr'+IntToStr(L)+'.asc';
  WriteRaster(Name,O);
  AddRes('OVERVIEW_'+IntToStr(L),Name);
 End;
 AddRes('OUTPUT',Out);
End;

Procedure RunPanSharp(A:Integer);
Var
 Ms:Array[1..4]of TRaster;
 O:Array[1..4]of TRaster;
 Pan:TRaster;
 Out,Name:String;
 N,K,I,J,Mode:LongInt;
 X,Y,S,Pv:Real;
 Vals:Array[1..4]of Real;
 Ok:Boolean;
Begin
 SplitList(NeedStr(A,'SPECTRAL'),';');
 N:=ListCount;
 If(N<1)or(N>4)Then Fail('Error: SPECTRAL must list between 1 and 4 rasters separated by ;');
 For K:=1 to N do ReadRaster(ListItems[K],Ms[K]);
 ReadRaster(NeedStr(A,'PANCHROMATIC'),Pan);
 Mode:=Round(NeedReal(A,'RESAMPLING'));
 If(Mode<>0)and(Mode<>1)Then Fail('Error: RESAMPLING must be 0 (nearest) or 1 (bilinear)');
 Out:=NeedStr(A,'OUTPUT');
 For K:=1 to N do
  If(Abs(Ms[K].XLL-Pan.XLL)>Pan.Cell)or(Abs(RasterTop(Ms[K])-RasterTop(Pan))>Pan.Cell)Then
   Fail('Error: the spectral and panchromatic rasters must cover the same area');
 For K:=1 to N do NewRaster(O[K],Pan.NC,Pan.NR,Pan.XLL,Pan.YLL,Pan.Cell,-9999);
 { Brovey : sortie_k = spectral_k * pan / moyenne des bandes spectrales }
 For I:=0 to Pan.NR-1do
  For J:=0 to Pan.NC-1do Begin
   Pv:=Pan.Data^[I*Pan.NC+J];
   If Not IsNoData(Pan,Pv)Then Begin
    X:=Pan.XLL+(J+0.5)*Pan.Cell;
    Y:=RasterTop(Pan)-(I+0.5)*Pan.Cell;
    Ok:=True;
    S:=0;
    For K:=1 to N do
     If SampleRaster(Ms[K],X,Y,Mode,Vals[K])Then S:=S+Vals[K]/N
                                           Else Ok:=False;
    If Ok Then
     For K:=1 to N do
      If S<>0Then O[K].Data^[I*Pan.NC+J]:=Vals[K]*Pv/S
             Else O[K].Data^[I*Pan.NC+J]:=0;
   End;
  End;
 For K:=1 to N do Begin
  If N=1Then Name:=Out
        Else Name:=Out+'_'+IntToStr(K)+'.asc';
  WriteRaster(Name,O[K]);
  If K=1Then AddRes('OUTPUT',Name)
        Else AddRes('OUTPUT_'+IntToStr(K),Name);
 End;
End;

{ Polygonisation : une ou plusieurs regions de valeur identique -> polygone }
Procedure RunPolygonize(A:Integer);
Var
 R:TRaster;
 Lab,Stack,EL,Idx:PLongs;
 LabVal:PReals;
 Edges:PEdges;
 Used:PBools;
 RB:PPts;
 Fld,Out,Final:String;
 Eight:Boolean;
 N,K,I,J,Nl,Sp,L,Cur,Ne,Lo,Hi,Best,Q,RN,Pos,Cnt,Qq,Nr,Nc,Mid:LongInt;
 V,Ang,BestAng,Dx,Dy,Mx,My,Ar,Ox,Oy:Real;
 F:Text;
 G:TGeom;
 Pa,Pb,Hp:PPath;
 EG,HG:TGeom;
 First,Closed:Boolean;
 Feat,Props:PJ;
 Sx,Sy,Ex,Ey:Real;
 Own,Owner:Integer;
 BestArea:Real;
 HArr:^PPathArr;
 HN:LongInt;
 Dr,Dc,Rr,Cc:LongInt;
 NbOk:Boolean;

 Procedure Flood(Seed:LongInt;Lb:LongInt);
 Var
  Kk,Ri,Ci,Dr2,Dc2,R2,C2,Q2:LongInt;
  V0:Real;
 Begin
  V0:=R.Data^[Seed];
  Lab^[Seed]:=Lb;
  Sp:=0;
  Stack^[Sp]:=Seed;Inc(Sp);
  While Sp>0do Begin
   Dec(Sp);
   Kk:=Stack^[Sp];
   Ri:=Kk div Nc;Ci:=Kk mod Nc;
   For Dr2:=-1 to 1do
    For Dc2:=-1 to 1do
     If((Dr2<>0)or(Dc2<>0))and(Eight or(Dr2=0)or(Dc2=0))Then Begin
      R2:=Ri+Dr2;C2:=Ci+Dc2;
      If(R2>=0)and(R2<Nr)and(C2>=0)and(C2<Nc)Then Begin
       Q2:=R2*Nc+C2;
       If(Lab^[Q2]=-1)and(Not IsNoData(R,R.Data^[Q2]))and(R.Data^[Q2]=V0)Then Begin
        Lab^[Q2]:=Lb;
        Stack^[Sp]:=Q2;Inc(Sp);
       End;
      End;
     End;
  End;
 End;

 Function LabAt(Rw,Cl:LongInt):LongInt;Begin
  If(Rw<0)or(Rw>=Nr)or(Cl<0)or(Cl>=Nc)Then LabAt:=-1
                                        Else LabAt:=Lab^[Rw*Nc+Cl];
 End;

 Procedure AddEdge(Lb:LongInt;X1,Y1,X2,Y2:Real);Begin
  Edges^[Ne].X1:=X1;Edges^[Ne].Y1:=Y1;Edges^[Ne].X2:=X2;Edges^[Ne].Y2:=Y2;
  EL^[Ne]:=Lb;
  Inc(Ne);
 End;

Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 CheckBand(A);
 Fld:=NeedStr(A,'FIELD');
 Eight:=NeedBool(A,'EIGHT_CONNECTEDNESS');
 Final:=NeedStr(A,'OUTPUT');
 Out:=StreamTmp(Final);
 Nc:=R.NC;Nr:=R.NR;
 N:=Nc*Nr;
 Lab:=AllocBlock(N*SizeOf(LongInt));
 Stack:=AllocBlock(N*SizeOf(LongInt));
 For K:=0 to N-1do Lab^[K]:=-1;
 LabVal:=AllocBlock((N+1)*SizeOf(Real));
 Nl:=0;
 For K:=0 to N-1do
  If(Lab^[K]=-1)and Not IsNoData(R,R.Data^[K])Then Begin
   LabVal^[Nl]:=R.Data^[K];
   Flood(K,Nl);
   Inc(Nl);
  End;
 { aretes de frontiere, interieur a gauche }
 Edges:=AllocBlock((4*N+1)*SizeOf(TEdge));
 EL:=AllocBlock((4*N+1)*SizeOf(LongInt));
 Ne:=0;
 For I:=0 to Nr-1do
  For J:=0 to Nc-1do Begin
   L:=Lab^[I*Nc+J];
   If L>=0Then Begin
    If LabAt(I+1,J)<>L Then AddEdge(L,J,Nr-I-1,J+1,Nr-I-1);
    If LabAt(I,J+1)<>L Then AddEdge(L,J+1,Nr-I-1,J+1,Nr-I);
    If LabAt(I-1,J)<>L Then AddEdge(L,J+1,Nr-I,J,Nr-I);
    If LabAt(I,J-1)<>L Then AddEdge(L,J,Nr-I,J,Nr-I-1);
   End;
  End;
 Idx:=AllocBlock((Ne+1)*SizeOf(LongInt));
 For K:=0 to Ne-1do Idx^[K]:=K;
 SB:=Edges;SLab:=EL;SMode:=4;
 If Ne>1Then SortIdx(Idx,0,Ne-1);
 Used:=AllocBlock((Ne+1)*SizeOf(Boolean));
 For K:=0 to Ne-1do Used^[K]:=False;
 RB:=AllocBlock((Ne+2)*SizeOf(TPt));
 {$I-}
 Assign(F,Out);
 Rewrite(F);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to create output file '+Out);
 Write(F,'{"type":"FeatureCollection",');
 If(R.Epsg<>0)and(R.Epsg<>4326)and CrsKnown(R.Epsg)Then Write(F,'"crs":{"type":"name","properties":{"name":"',CrsLabel(R.Epsg),'"}},');
 WriteLn(F,'"features":[');
 First:=True;
 Pos:=0;
 While Pos<Ne do Begin
  { plage des aretes de l'etiquette courante }
  L:=EL^[Idx^[Pos]];
  Lo:=Pos;Hi:=Pos;
  While(Hi<Ne)and(EL^[Idx^[Hi]]=L)do Inc(Hi);
  Pos:=Hi;
  InitGeom(EG);InitGeom(HG);
  For Q:=Lo to Hi-1do Begin
   If Not Used^[Idx^[Q]]Then Begin
    Cur:=Idx^[Q];
    Sx:=Edges^[Cur].X1;Sy:=Edges^[Cur].Y1;
    RN:=0;
    Closed:=False;
    Repeat
     Used^[Cur]:=True;
     RB^[RN].X:=Edges^[Cur].X1;RB^[RN].Y:=Edges^[Cur].Y1;
     Inc(RN);
     Ex:=Edges^[Cur].X2;Ey:=Edges^[Cur].Y2;
     If(Ex=Sx)and(Ey=Sy)Then Closed:=True
      Else
     Begin
      Dx:=Ex-Edges^[Cur].X1;Dy:=Ey-Edges^[Cur].Y1;
      Best:=-1;
      If Eight Then BestAng:=10 Else BestAng:=-10;
      { aretes de meme etiquette partant de (Ex,Ey) }
      Qq:=Lo;Mid:=Hi;
      While Qq<Mid do Begin
       J:=(Qq+Mid)div 2;
       If(Edges^[Idx^[J]].X1<Ex)or((Edges^[Idx^[J]].X1=Ex)and(Edges^[Idx^[J]].Y1<Ey))Then Qq:=J+1
                                                                                    Else Mid:=J;
      End;
      While(Qq<Hi)and(Edges^[Idx^[Qq]].X1=Ex)and(Edges^[Idx^[Qq]].Y1=Ey)do Begin
       K:=Idx^[Qq];
       If Not Used^[K]Then Begin
        Mx:=Edges^[K].X2-Ex;My:=Edges^[K].Y2-Ey;
        Ang:=Atan2(Dx*My-Dy*Mx,Dx*Mx+Dy*My);
        If Eight Then Begin
         If Ang<BestAng Then Begin BestAng:=Ang;Best:=K;End;
        End
         Else
        If Ang>BestAng Then Begin BestAng:=Ang;Best:=K;End;
       End;
       Inc(Qq);
      End;
      If Best<0Then Cur:=-1 Else Cur:=Best;
     End;
    Until Closed or(Cur<0);
    If Closed and(RN>=4)Then Begin
     { simplification : on retire les sommets alignes }
     Pa:=NewPath(EG,RN+1,0);
     Cnt:=0;
     For K:=0 to RN-1do Begin
      I:=(K+RN-1)mod RN;J:=(K+1)mod RN;
      If((RB^[K].X-RB^[I].X)*(RB^[J].Y-RB^[K].Y)-(RB^[K].Y-RB^[I].Y)*(RB^[J].X-RB^[K].X))<>0Then Begin
       Pa^.Pts^[Cnt].X:=R.XLL+RB^[K].X*R.Cell;
       Pa^.Pts^[Cnt].Y:=R.YLL+RB^[K].Y*R.Cell;
       Inc(Cnt);
      End;
     End;
     Pa^.Pts^[Cnt]:=Pa^.Pts^[0];
     Pa^.N:=Cnt+1;
     Pa^.Area:=RingArea(Pa);
    End;
   End;
  End;
  { exterieurs (aire > 0) et trous }
  Pa:=EG.First;
  EG.First:=Nil;EG.Last:=Nil;EG.Count:=0;
  While Pa<>Nil do Begin
   Pb:=Pa^.Next;
   If Pa^.Area>0Then LinkPath(EG,Pa) Else LinkPath(HG,Pa);
   Pa:=Pb;
  End;
  Hp:=HG.First;
  While Hp<>Nil do Begin
   Hp^.Poly:=-1;
   BestArea:=0;
   Own:=0;
   Pa:=EG.First;
   While Pa<>Nil do Begin
    If(Pa^.Area>Abs(Hp^.Area))and((Hp^.Poly<0)or(Pa^.Area<BestArea))Then Begin
     Cnt:=0;
     Owner:=2;
     While(Cnt<Hp^.N-1)and(Owner=2)do Begin
      Owner:=PointInRing(Pa,Hp^.Pts^[Cnt].X,Hp^.Pts^[Cnt].Y,R.Cell*1E-6);
      Inc(Cnt);
     End;
     If Owner=1Then Begin
      Hp^.Poly:=Own;
      BestArea:=Pa^.Area;
     End;
    End;
    Inc(Own);
    Pa:=Pa^.Next;
   End;
   Hp:=Hp^.Next;
  End;
  InitGeom(G);
  G.Cls:=3;
  HN:=HG.Count;
  HArr:=AllocBlock((HN+1)*SizeOf(PPath));
  K:=0;
  Hp:=HG.First;
  While Hp<>Nil do Begin HArr^[K]:=Hp;Inc(K);Hp:=Hp^.Next;End;
  Own:=0;
  Pa:=EG.First;
  While Pa<>Nil do Begin
   Pb:=Pa^.Next;
   Pa^.Poly:=Own;
   LinkPath(G,Pa);
   For K:=0 to HN-1do
    If HArr^[K]^.Poly=Own Then LinkPath(G,HArr^[K]);
   Inc(Own);
   Pa:=Pb;
  End;
  FreeMem(HArr,(HN+1)*SizeOf(PPath));
  If G.First<>Nil Then Begin
   Feat:=NewJ(5);
   JAddKV(Feat,'type',JText('Feature'));
   Props:=NewJ(5);
   JAddKV(Props,Fld,JNum(LabVal^[L]));
   JAddKV(Feat,'properties',Props);
   JAddKV(Feat,'geometry',BuildPolygons(G));
   If Not First Then WriteLn(F,',');
   First:=False;
   WriteJ(F,Feat);
  End;
 End;
 WriteLn(F);
 WriteLn(F,']}');
 Close(F);
 StreamDone(Final,Out);
 AddRes('OUTPUT',Final);
End;

{ Transformee de distance euclidienne exacte (Felzenszwalb) }
Procedure Edt1D(F,D:PReals;N:LongInt;V:PLongs;Z:PReals);
Var
 K,Q:LongInt;
 S:Real;
Begin
 K:=0;
 V^[0]:=0;
 Z^[0]:=-1E30;Z^[1]:=1E30;
 For Q:=1 to N-1do Begin
  While True do Begin
   S:=((F^[Q]+Q*1.0*Q)-(F^[V^[K]]+V^[K]*1.0*V^[K]))/(2.0*Q-2.0*V^[K]);
   If(S<=Z^[K])and(K>0)Then Dec(K) Else Break;
  End;
  If S<=Z^[K]Then Begin
   { la parabole precedente est entierement masquee }
   V^[K]:=Q;
  End
   Else
  Begin
   Inc(K);
   V^[K]:=Q;
   Z^[K]:=S;
  End;
  Z^[K+1]:=1E30;
 End;
 K:=0;
 For Q:=0 to N-1do Begin
  While Z^[K+1]<Q do Inc(K);
  D^[Q]:=Sqr(Q-V^[K])+F^[V^[K]];
 End;
End;

Procedure RunProximity(A:Integer);
Var
 R,O:TRaster;
 Targets:Array[1..40]of Real;
 NT,I,J,K,M:LongInt;
 AllNonZero,InPixels,DoReplace:Boolean;
 MaxD,Rep,Nd,V,Dist:Real;
 Fv,Dv,Zv:PReals;
 Vv:PLongs;
 Out:String;
 IsT:Boolean;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 CheckBand(A);
 AllNonZero:=Not HasArg('VALUES');
 NT:=0;
 If Not AllNonZero Then Begin
  SplitList(NeedStr(A,'VALUES'),' ,;');
  For K:=1 to ListCount do Begin
   Inc(NT);
   RNum(ListItems[K],Targets[NT]);
  End;
 End;
 InPixels:=Round(NeedReal(A,'UNITS'))=1;
 MaxD:=NeedReal(A,'MAX_DISTANCE');
 DoReplace:=HasArg('REPLACE');
 Rep:=0;
 If DoReplace Then Rep:=NeedReal(A,'REPLACE');
 Nd:=NeedReal(A,'NODATA');
 Out:=NeedStr(A,'OUTPUT');
 NewRaster(O,R.NC,R.NR,R.XLL,R.YLL,R.Cell,Nd);
 M:=R.NC;
 If R.NR>M Then M:=R.NR;
 Fv:=AllocBlock((M+2)*SizeOf(Real));
 Dv:=AllocBlock((M+2)*SizeOf(Real));
 Zv:=AllocBlock((M+3)*SizeOf(Real));
 Vv:=AllocBlock((M+2)*SizeOf(LongInt));
 { 1e12 : pas de cible }
 For I:=0 to R.NR*R.NC-1do Begin
  V:=R.Data^[I];
  IsT:=False;
  If Not IsNoData(R,V)Then Begin
   If AllNonZero Then IsT:=V<>0
    Else
   For K:=1 to NT do If V=Targets[K]Then IsT:=True;
  End;
  If IsT Then O.Data^[I]:=0 Else O.Data^[I]:=1E12;
 End;
 For J:=0 to R.NC-1do Begin
  For I:=0 to R.NR-1do Fv^[I]:=O.Data^[I*R.NC+J];
  Edt1D(Fv,Dv,R.NR,Vv,Zv);
  For I:=0 to R.NR-1do O.Data^[I*R.NC+J]:=Dv^[I];
 End;
 For I:=0 to R.NR-1do Begin
  For J:=0 to R.NC-1do Fv^[J]:=O.Data^[I*R.NC+J];
  Edt1D(Fv,Dv,R.NC,Vv,Zv);
  For J:=0 to R.NC-1do Begin
   If Dv^[J]>=1E11Then Dist:=-1 Else Dist:=Sqrt(Dv^[J]);
   V:=R.Data^[I*R.NC+J];
   If IsNoData(R,V)Then Dist:=-1;
   If Dist>=0Then Begin
    If Not InPixels Then Dist:=Dist*R.Cell;
    If(MaxD>0)and(Dist>MaxD)Then Dist:=-1;
   End;
   If Dist<0Then O.Data^[I*R.NC+J]:=Nd
    Else
   Begin
    O.Data^[I*R.NC+J]:=Dist;
    If DoReplace and(Dist=0)Then O.Data^[I*R.NC+J]:=Rep;
   End;
  End;
 End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

{ ---- calculatrice raster ---- }
Const
 MaxCode=200;
Var
 CalcS:String;
 CalcP:Integer;
 CalcNames:Array[0..15]of String;
 CalcNN:Integer;
 CodeOp:Array[1..MaxCode]of Byte;
 CodeV:Array[1..MaxCode]of Real;
 CodeN:Integer;

Procedure CFail(Msg:String);Begin
 Fail('Error: invalid formula ('+Msg+') near position '+IntToStr(CalcP));
End;

Procedure CEmit(Op:Byte;V:Real);Begin
 If CodeN>=MaxCode Then CFail('formula too long');
 Inc(CodeN);
 CodeOp[CodeN]:=Op;
 CodeV[CodeN]:=V;
End;

Procedure CSkip;Begin
 While(CalcP<=Length(CalcS))and(CalcS[CalcP]=' ')do Inc(CalcP);
End;

Function COp(S:String):Boolean;Begin
 CSkip;
 COp:=False;
 If Copy(CalcS,CalcP,Length(S))=S Then Begin
  Inc(CalcP,Length(S));
  COp:=True;
 End;
End;

Procedure CExpr;Forward;

Procedure CPrimary;
Var
 Start:Integer;
 Name:String;
 V:Real;
 E:Integer;
 Op:Byte;
 Two:Boolean;
Begin
 CSkip;
 If CalcP>Length(CalcS)Then CFail('unexpected end');
 If CalcS[CalcP]='('Then Begin
  Inc(CalcP);
  CExpr;
  If Not COp(')')Then CFail('")" expected');
 End
  Else
 If CalcS[CalcP]in['0'..'9','.']Then Begin
  Start:=CalcP;
  While(CalcP<=Length(CalcS))and(CalcS[CalcP]in['0'..'9','.'])do Inc(CalcP);
  If(CalcP<=Length(CalcS))and(CalcS[CalcP]in['e','E'])Then Begin
   Inc(CalcP);
   If(CalcP<=Length(CalcS))and(CalcS[CalcP]in['+','-'])Then Inc(CalcP);
   While(CalcP<=Length(CalcS))and(CalcS[CalcP]in['0'..'9'])do Inc(CalcP);
  End;
  Val(Copy(CalcS,Start,CalcP-Start),V,E);
  If E<>0Then CFail('invalid number');
  CEmit(1,V);
 End
  Else
 If CalcS[CalcP]='"'Then Begin
  Inc(CalcP);
  Start:=CalcP;
  While(CalcP<=Length(CalcS))and(CalcS[CalcP]<>'"')do Inc(CalcP);
  If CalcP>Length(CalcS)Then CFail('unterminated layer name');
  Name:=Copy(CalcS,Start,CalcP-Start);
  Inc(CalcP);
  E:=-1;
  For Op:=0 to CalcNN-1do If StrUpper(CalcNames[Op])=StrUpper(Name)Then E:=Op;
  If E<0Then CFail('unknown layer '+Name);
  CEmit(2,E);
 End
  Else
 If UpCase(CalcS[CalcP])in['A'..'Z']Then Begin
  Start:=CalcP;
  While(CalcP<=Length(CalcS))and(UpCase(CalcS[CalcP])in['A'..'Z','0'..'9','_'])do Inc(CalcP);
  Name:=StrUpper(Copy(CalcS,Start,CalcP-Start));
  CSkip;
  If(CalcP<=Length(CalcS))and(CalcS[CalcP]='(')Then Begin
   Inc(CalcP);
   Two:=False;
   Op:=0;
   If Name='SQRT'Then Op:=20 Else If Name='ABS'Then Op:=21 Else
   If Name='SIN'Then Op:=22 Else If Name='COS'Then Op:=23 Else
   If Name='TAN'Then Op:=24 Else If Name='EXP'Then Op:=25 Else
   If(Name='LOG')or(Name='LN')Then Op:=26 Else If Name='LOG10'Then Op:=27 Else
   If Name='FLOOR'Then Op:=28 Else If Name='CEIL'Then Op:=29 Else
   If Name='ROUND'Then Op:=30 Else If(Name='MAXIMUM')or(Name='MAX')Then Begin Op:=31;Two:=True;End Else
   If(Name='MINIMUM')or(Name='MIN')Then Begin Op:=32;Two:=True;End Else
   If Name='ATAN'Then Op:=33
    Else
   CFail('unknown function '+Name);
   CExpr;
   If Two Then Begin
    If Not COp(',')Then CFail('"," expected');
    CExpr;
   End;
   If Not COp(')')Then CFail('")" expected');
   CEmit(Op,0);
  End
   Else
  Begin
   If(Length(Name)<>1)or(Name[1]>'F')Then CFail('unknown variable '+Name);
   CEmit(2,Ord(Name[1])-Ord('A'));
  End;
 End
  Else
 CFail('unexpected character "'+CalcS[CalcP]+'"');
End;

Procedure CUnary;Forward;

Procedure CPow;Begin
 CPrimary;
 If COp('**')or COp('^')Then Begin
  CUnary;
  CEmit(7,0);
 End;
End;

Procedure CUnary;Begin
 If COp('-')Then Begin
  CUnary;
  CEmit(8,0);
 End
  Else
 CPow;
End;

Procedure CMul;
Var
 Op:Byte;
Begin
 CUnary;
 While True do Begin
  CSkip;
  If(CalcP<=Length(CalcS))and(CalcS[CalcP]='*')and(Copy(CalcS,CalcP,2)<>'**')Then Op:=5 Else
  If(CalcP<=Length(CalcS))and(CalcS[CalcP]='/')Then Op:=6
                                               Else Break;
  Inc(CalcP);
  CUnary;
  CEmit(Op,0);
 End;
End;

Procedure CAdd;
Var
 Op:Byte;
Begin
 CMul;
 While True do Begin
  If COp('+')Then Op:=3 Else
  If COp('-')Then Op:=4 Else Break;
  CMul;
  CEmit(Op,0);
 End;
End;

Procedure CExpr;
Var
 Op:Byte;
Begin
 CAdd;
 Op:=0;
 If COp('<=')Then Op:=11 Else If COp('>=')Then Op:=12 Else
 If COp('==')Then Op:=13 Else If COp('!=')Then Op:=14 Else
 If COp('<')Then Op:=9 Else If COp('>')Then Op:=10;
 If Op>0Then Begin
  CAdd;
  CEmit(Op,0);
 End;
End;

{ Evalue le code compile ; Faux si le resultat n'est pas un nombre fini }
Function CEval(Var Vars:Array of Real;Var Res:Real):Boolean;
Var
 St:Array[1..64]of Real;
 Sp,I:Integer;
 X,Y:Real;
Begin
 Sp:=0;
 CEval:=False;
 For I:=1 to CodeN do Begin
  Case CodeOp[I]of
   1:Begin Inc(Sp);St[Sp]:=CodeV[I];End;
   2:Begin Inc(Sp);St[Sp]:=Vars[Round(CodeV[I])];End;
   8:St[Sp]:=-St[Sp];
   20..30,33:Begin
    X:=St[Sp];
    Case CodeOp[I]of
     20:If X<0Then Exit Else X:=Sqrt(X);
     21:X:=Abs(X);
     22:X:=Sin(X);
     23:X:=Cos(X);
     24:If Cos(X)=0Then Exit Else X:=Sin(X)/Cos(X);
     25:If X>700Then Exit Else X:=Exp(X);
     26:If X<=0Then Exit Else X:=Ln(X);
     27:If X<=0Then Exit Else X:=Ln(X)/Ln(10);
     28:X:=FloorR(X);
     29:X:=-FloorR(-X);
     30:X:=FloorR(X+0.5);
     33:X:=ArcTan(X);
    End;
    St[Sp]:=X;
   End;
   Else Begin
    Y:=St[Sp];Dec(Sp);
    X:=St[Sp];
    Case CodeOp[I]of
     3:X:=X+Y;
     4:X:=X-Y;
     5:X:=X*Y;
     6:If Y=0Then Exit Else X:=X/Y;
     7:Begin
      If X=0Then Begin
       If Y<0Then Exit Else If Y=0Then X:=1 Else X:=0;
      End
       Else
      If X<0Then Begin
       If Y<>Int(Y)Then Exit;
       X:=Exp(Y*Ln(-X));
       If Odd(Round(Y))Then X:=-X;
      End
       Else
      X:=Exp(Y*Ln(X));
     End;
     9:If X<Y Then X:=1 Else X:=0;
     10:If X>Y Then X:=1 Else X:=0;
     11:If X<=Y Then X:=1 Else X:=0;
     12:If X>=Y Then X:=1 Else X:=0;
     13:If X=Y Then X:=1 Else X:=0;
     14:If X<>Y Then X:=1 Else X:=0;
     31:If Y>X Then X:=Y;
     32:If Y<X Then X:=Y;
    End;
    St[Sp]:=X;
   End;
  End;
 End;
 Res:=St[1];
 CEval:=Abs(Res)<1E300;
End;

Procedure RunRasterCalc(A:Integer);
Var
 Rs:Array[0..5]of TRaster;
 Have:Array[0..5]of Boolean;
 Names:String;
 O:TRaster;
 Vars:Array[0..5]of Real;
 I,K,N:LongInt;
 Out:String;
 Nd,V:Real;
 Ok:Boolean;
Begin
 Names:='ABCDEF';
 For K:=0 to 5do Begin
  Have[K]:=(K=0)or HasArg('INPUT_'+Names[K+1]);
  If Have[K]Then ReadRaster(NeedStr(A,'INPUT_'+Names[K+1]),Rs[K]);
  Vars[K]:=0;
 End;
 For K:=1 to 5do
  If Have[K]Then
   If(Rs[K].NC<>Rs[0].NC)or(Rs[K].NR<>Rs[0].NR)Then
    Fail('Error: all input rasters must have the same size');
 CalcS:=NeedStr(A,'FORMULA');
 CalcP:=1;CodeN:=0;
 CExpr;
 CSkip;
 If CalcP<=Length(CalcS)Then CFail('unexpected token');
 { variables utilisees mais non fournies }
 For I:=1 to CodeN do
  If CodeOp[I]=2Then
   If Not Have[Round(CodeV[I])]Then Fail('Error: the formula uses '+Names[Round(CodeV[I])+1]+' but INPUT_'+Names[Round(CodeV[I])+1]+' is not set');
 Out:=NeedStr(A,'OUTPUT');
 Nd:=Rs[0].NoData;
 If HasArg('NO_DATA')Then Nd:=NeedReal(A,'NO_DATA');
 NewRaster(O,Rs[0].NC,Rs[0].NR,Rs[0].XLL,Rs[0].YLL,Rs[0].Cell,Nd);
 N:=Rs[0].NC*Rs[0].NR;
 For I:=0 to N-1do Begin
  Ok:=True;
  For K:=0 to 5do
   If Have[K]Then Begin
    Vars[K]:=Rs[K].Data^[I];
    If IsNoData(Rs[K],Vars[K])Then Ok:=False;
   End;
  If Ok and CEval(Vars,V)Then O.Data^[I]:=V;
 End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

Procedure RunRetile(A:Integer);
Var
 R,O:TRaster;
 Dir,Base,Name:String;
 Tx,Ty,Ov,I,J,Ti,Tj,R0,C0,Nr,Nc,Count:LongInt;
Begin
 SplitList(NeedStr(A,'INPUT'),';');
 If ListCount<>1Then Fail('Error: exactly one input raster is supported');
 Base:=BaseName(ListItems[1]);
 ReadRaster(ListItems[1],R);
 Tx:=Round(NeedReal(A,'TILE_SIZE_X'));
 Ty:=Round(NeedReal(A,'TILE_SIZE_Y'));
 Ov:=Round(NeedReal(A,'OVERLAP'));
 If(Tx<1)or(Ty<1)or(Ov<0)or(Ov>=Tx)or(Ov>=Ty)Then Fail('Error: invalid tile size or overlap');
 Dir:=NeedStr(A,'OUTPUT');
 If Dir=''Then Fail('Error: OUTPUT must be a directory');
 If(Dir[Length(Dir)]='/')or(Dir[Length(Dir)]='\')Then Dir:=Copy(Dir,1,Length(Dir)-1);
 {$I-}
 MkDir(Dir);
 If IOResult<>0Then Begin End;
 {$I+}
 Count:=0;
 Ti:=0;
 R0:=0;
 While R0<R.NR do Begin
  Tj:=0;
  C0:=0;
  While C0<R.NC do Begin
   Nr:=Ty;
   If R0+Nr>R.NR Then Nr:=R.NR-R0;
   Nc:=Tx;
   If C0+Nc>R.NC Then Nc:=R.NC-C0;
   NewRaster(O,Nc,Nr,R.XLL+C0*R.Cell,RasterTop(R)-(R0+Nr)*R.Cell,R.Cell,R.NoData);
   For I:=0 to Nr-1do
    For J:=0 to Nc-1do O.Data^[I*Nc+J]:=R.Data^[(R0+I)*R.NC+C0+J];
   Name:=Dir+'/'+Base+'_'+IntToStr(Ti+1)+'_'+IntToStr(Tj+1)+'.asc';
   WriteRaster(Name,O);
   Inc(Count);
   Inc(Tj);
   C0:=C0+Tx-Ov;
  End;
  Inc(Ti);
  R0:=R0+Ty-Ov;
 End;
 AddRes('OUTPUT',Dir);
 AddRes('TILE_COUNT',IntToStr(Count));
End;

{ Voisinage 3x3 : valeur en (I+Di,J+Dj), le centre remplace les valeurs absentes }
Function Nb(Var R:TRaster;I,J,Di,Dj:LongInt):Real;
Var
 Ri,Cj:LongInt;
 V:Real;
Begin
 Ri:=I+Di;Cj:=J+Dj;
 If(Ri<0)or(Ri>=R.NR)or(Cj<0)or(Cj>=R.NC)Then Nb:=R.Data^[I*R.NC+J]
  Else
 Begin
  V:=R.Data^[Ri*R.NC+Cj];
  If IsNoData(R,V)Then V:=R.Data^[I*R.NC+J];
  Nb:=V;
 End;
End;

Procedure RunRoughness(A:Integer);
Var
 R,O:TRaster;
 Edges:Boolean;
 I,J,Di,Dj:LongInt;
 Mn,Mx,V:Real;
 Out:String;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 CheckBand(A);
 Edges:=NeedBool(A,'COMPUTE_EDGES');
 Out:=NeedStr(A,'OUTPUT');
 NewRaster(O,R.NC,R.NR,R.XLL,R.YLL,R.Cell,-9999);
 For I:=0 to R.NR-1do
  For J:=0 to R.NC-1do
   If Not IsNoData(R,R.Data^[I*R.NC+J])Then
    If Edges or((I>0)and(J>0)and(I<R.NR-1)and(J<R.NC-1))Then Begin
     Mn:=R.Data^[I*R.NC+J];Mx:=Mn;
     For Di:=-1 to 1do
      For Dj:=-1 to 1do Begin
       V:=Nb(R,I,J,Di,Dj);
       If V<Mn Then Mn:=V;
       If V>Mx Then Mx:=V;
      End;
     O.Data^[I*R.NC+J]:=Mx-Mn;
    End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

Procedure RunSlope(A:Integer);
Var
 R,O:TRaster;
 Edges,Percent,Zev:Boolean;
 I,J:LongInt;
 Sc,Dzdx,Dzdy,S:Real;
 Z:Array[1..9]of Real;
 Out:String;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 CheckBand(A);
 Sc:=NeedReal(A,'SCALE');
 If Sc<=0Then Fail('Error: SCALE must be greater than 0');
 Percent:=NeedBool(A,'AS_PERCENT');
 Edges:=NeedBool(A,'COMPUTE_EDGES');
 Zev:=NeedBool(A,'ZEVENBERGEN');
 Out:=NeedStr(A,'OUTPUT');
 NewRaster(O,R.NC,R.NR,R.XLL,R.YLL,R.Cell,-9999);
 For I:=0 to R.NR-1do
  For J:=0 to R.NC-1do
   If Not IsNoData(R,R.Data^[I*R.NC+J])Then
    If Edges or((I>0)and(J>0)and(I<R.NR-1)and(J<R.NC-1))Then Begin
     { Z[1..9] : a b c / d e f / g h i }
     Z[1]:=Nb(R,I,J,-1,-1);Z[2]:=Nb(R,I,J,-1,0);Z[3]:=Nb(R,I,J,-1,1);
     Z[4]:=Nb(R,I,J,0,-1);Z[5]:=Nb(R,I,J,0,0);Z[6]:=Nb(R,I,J,0,1);
     Z[7]:=Nb(R,I,J,1,-1);Z[8]:=Nb(R,I,J,1,0);Z[9]:=Nb(R,I,J,1,1);
     If Zev Then Begin
      Dzdx:=(Z[6]-Z[4])/(2*R.Cell);
      Dzdy:=(Z[8]-Z[2])/(2*R.Cell);
     End
      Else
     Begin
      Dzdx:=((Z[3]+2*Z[6]+Z[9])-(Z[1]+2*Z[4]+Z[7]))/(8*R.Cell);
      Dzdy:=((Z[7]+2*Z[8]+Z[9])-(Z[1]+2*Z[2]+Z[3]))/(8*R.Cell);
     End;
     S:=Sqrt(Dzdx*Dzdx+Dzdy*Dzdy)/Sc;
     If Percent Then O.Data^[I*R.NC+J]:=100*S
                Else O.Data^[I*R.NC+J]:=Rad2Deg(ArcTan(S));
    End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

Procedure RunSieve(A:Integer);
Var
 R:TRaster;
 Lab,Stack,Size,Ord:PLongs;
 LabVal:PReals;
 N,K,I,J,Nl,Sp,Thr,L,Pass,BestL,BestSz,Q,Dr,Dc,R2,C2,Oi:LongInt;
 Eight,Changed:Boolean;
 Out:String;
 V0:Real;
 Nrr,Ncc:LongInt;

 Procedure Flood(Seed,Lb:LongInt);
 Var
  Kk,Ri,Ci,D1,D2,Rr,Cc,Qq:LongInt;
 Begin
  V0:=R.Data^[Seed];
  Lab^[Seed]:=Lb;
  Sp:=0;
  Stack^[Sp]:=Seed;Inc(Sp);
  While Sp>0do Begin
   Dec(Sp);
   Kk:=Stack^[Sp];
   Ri:=Kk div Ncc;Ci:=Kk mod Ncc;
   For D1:=-1 to 1do
    For D2:=-1 to 1do
     If((D1<>0)or(D2<>0))and(Eight or(D1=0)or(D2=0))Then Begin
      Rr:=Ri+D1;Cc:=Ci+D2;
      If(Rr>=0)and(Rr<Nrr)and(Cc>=0)and(Cc<Ncc)Then Begin
       Qq:=Rr*Ncc+Cc;
       If(Lab^[Qq]=-1)and(Not IsNoData(R,R.Data^[Qq]))and(R.Data^[Qq]=V0)Then Begin
        Lab^[Qq]:=Lb;
        Stack^[Sp]:=Qq;Inc(Sp);
       End;
      End;
     End;
  End;
 End;

Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 Thr:=Round(NeedReal(A,'THRESHOLD'));
 Eight:=NeedBool(A,'EIGHT_CONNECTEDNESS');
 Out:=NeedStr(A,'OUTPUT');
 If Thr<1Then Fail('Error: THRESHOLD must be at least 1');
 Nrr:=R.NR;Ncc:=R.NC;
 N:=Nrr*Ncc;
 Lab:=AllocBlock(N*SizeOf(LongInt));
 Stack:=AllocBlock(N*SizeOf(LongInt));
 Size:=AllocBlock((N+1)*SizeOf(LongInt));
 LabVal:=AllocBlock((N+1)*SizeOf(Real));
 For Pass:=1 to 100do Begin
  For K:=0 to N-1do Lab^[K]:=-1;
  Nl:=0;
  For K:=0 to N-1do
   If(Lab^[K]=-1)and Not IsNoData(R,R.Data^[K])Then Begin
    LabVal^[Nl]:=R.Data^[K];
    Flood(K,Nl);
    Inc(Nl);
   End;
  For L:=0 to Nl-1do Size^[L]:=0;
  For K:=0 to N-1do If Lab^[K]>=0Then Inc(Size^[Lab^[K]]);
  Changed:=False;
  { chaque petite region (la plus petite d'abord) est fusionnee avec son plus grand voisin }
  Ord:=AllocBlock((Nl+1)*SizeOf(LongInt));
  For L:=0 to Nl-1do Ord^[L]:=L;
  SLab:=Size;SMode:=5;
  If Nl>1Then SortIdx(Ord,0,Nl-1);
  For Oi:=0 to Nl-1do Begin
   L:=Ord^[Oi];
   If Size^[L]<Thr Then Begin
    BestL:=-1;BestSz:=0;
    For K:=0 to N-1do
     If Lab^[K]=L Then Begin
      I:=K div Ncc;J:=K mod Ncc;
      For Dr:=-1 to 1do
       For Dc:=-1 to 1do
        If((Dr<>0)or(Dc<>0))and(Eight or(Dr=0)or(Dc=0))Then Begin
         R2:=I+Dr;C2:=J+Dc;
         If(R2>=0)and(R2<Nrr)and(C2>=0)and(C2<Ncc)Then Begin
          Q:=Lab^[R2*Ncc+C2];
          If(Q>=0)and(Q<>L)and(Size^[Q]>BestSz)Then Begin BestSz:=Size^[Q];BestL:=Q;End;
         End;
        End;
     End;
    If BestL>=0Then Begin
     For K:=0 to N-1do If Lab^[K]=L Then Begin
      R.Data^[K]:=LabVal^[BestL];
      Lab^[K]:=BestL;
     End;
     Size^[BestL]:=Size^[BestL]+Size^[L];
     Size^[L]:=N+1;   { region fusionnee : ne sera plus traitee }
     Changed:=True;
    End;
   End;
  End;
  FreeMem(Ord,(Nl+1)*SizeOf(LongInt));
  If Not Changed Then Break;
 End;
 WriteRaster(Out,R);
 AddRes('OUTPUT',Out);
End;

Procedure RunTileIndex(A:Integer);
Var
 R:TRaster;
 Root,Arr,F,Props,Gm,Ring,Poly:PJ;
 Fld,Out,Path,Dir:String;
 K:Integer;
 Absolute:Boolean;
 X1,Y1,X2,Y2:Real;
Begin
 SplitList(NeedStr(A,'INPUT'),';');
 If ListCount=0Then Fail('Error: INPUT is empty');
 Fld:=NeedStr(A,'FIELD_NAME');
 Absolute:=NeedBool(A,'ABSOLUTE_PATH');
 Out:=NeedStr(A,'OUTPUT');
 Root:=NewJ(5);
 JAddKV(Root,'type',JText('FeatureCollection'));
 Arr:=NewJ(4);
 JAddKV(Root,'features',Arr);
 RasterHeaderOnly:=True;
 For K:=1 to ListCount do Begin
  ReadRaster(ListItems[K],R);
  X1:=R.XLL;Y1:=R.YLL;X2:=R.XLL+R.NC*R.Cell;Y2:=R.YLL+R.NR*R.Cell;
  Path:=ListItems[K];
  If Absolute and Not((Path[1]in['/','\'])or((Length(Path)>1)and(Path[2]=':')))Then Begin
   GetDir(0,Dir);
   Path:=Dir+'/'+Path;
  End;
  F:=NewJ(5);
  JAddKV(F,'type',JText('Feature'));
  Props:=NewJ(5);
  JAddKV(Props,Fld,JText(Path));
  JAddKV(F,'properties',Props);
  Poly:=NewJ(4);
  Ring:=NewJ(4);
  JAdd(Ring,CoordNode(X1,Y1));JAdd(Ring,CoordNode(X2,Y1));
  JAdd(Ring,CoordNode(X2,Y2));JAdd(Ring,CoordNode(X1,Y2));
  JAdd(Ring,CoordNode(X1,Y1));
  JAdd(Poly,Ring);
  Gm:=GeomNode('Polygon',Poly);
  JAddKV(F,'geometry',Gm);
  JAdd(Arr,F);
 End;
 RasterHeaderOnly:=False;
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

{ Recadrage a des limites georeferencees (comme gdal_translate -projwin) }
Procedure CropRaster(Var R:TRaster;X1,X2,Y1,Y2:Real;Var O:TRaster);
Var
 YTop:Real;
 C0,C1,R0,R1,I,J:LongInt;
Begin
 YTop:=RasterTop(R);
 C0:=RoundL((X1-R.XLL)/R.Cell);
 C1:=RoundL((X2-R.XLL)/R.Cell);
 R0:=RoundL((YTop-Y2)/R.Cell);
 R1:=RoundL((YTop-Y1)/R.Cell);
 If C0<0Then C0:=0;
 If R0<0Then R0:=0;
 If C1>R.NC Then C1:=R.NC;
 If R1>R.NR Then R1:=R.NR;
 If(C1<=C0)or(R1<=R0)Then Fail('Error: the extent does not intersect the raster');
 NewRaster(O,C1-C0,R1-R0,R.XLL+C0*R.Cell,YTop-R1*R.Cell,R.Cell,R.NoData);
 For I:=0 to O.NR-1do
  For J:=0 to O.NC-1do O.Data^[I*O.NC+J]:=R.Data^[(I+R0)*R.NC+J+C0];
End;

Procedure ParsePoint(S:String;Var X,Y:Real);
Var
 P:Integer;
 T:String;
Begin
 P:=Pos('[',S);
 If P>0Then S:=Copy(S,1,P-1);
 P:=Pos(',',S);
 If P=0Then Fail('Error: invalid point, expected x,y [EPSG:code]');
 T:=Copy(S,1,P-1);
 While(T<>'')and(T[1]=' ')do T:=Copy(T,2,255);
 If Not IsNumber(T)Then Fail('Error: invalid point coordinate "'+T+'"');
 Val(T,X,P);
 T:=Copy(S,Pos(',',S)+1,255);
 While(T<>'')and(T[1]=' ')do T:=Copy(T,2,255);
 While(T<>'')and(T[Length(T)]=' ')do T:=Copy(T,1,Length(T)-1);
 If Not IsNumber(T)Then Fail('Error: invalid point coordinate "'+T+'"');
 Val(T,Y,P);
End;

Procedure RunTranslate(A:Integer);
Var
 R,O,T:TRaster;
 Out,Tok:String;
 Dtype,K,I,J,W,H,Si,Sj:LongInt;
 X1,X2,Y1,Y2,Nd,V,Lo,Hi,Cw,Ch,Pc:Real;
 HaveNd,HaveWin,HaveSize:Boolean;
 Sv:Single;
 Code:Integer;
 Pct:Boolean;
Begin
 SplitList(NeedStr(A,'EXTRA'),' ');
 For K:=1 to ListCount-1do If ListItems[K]='-b'Then Begin
  Val(ListItems[K+1],BandSel,I);
  If I<>0Then Fail('Error: invalid band number "'+ListItems[K+1]+'"');
 End;
 ReadRaster(NeedStr(A,'INPUT'),R);
 Dtype:=Round(NeedReal(A,'DATA_TYPE'));
 If(Dtype<0)or(Dtype>7)Then Fail('Error: DATA_TYPE must be between 0 and 7');
 Out:=NeedStr(A,'OUTPUT');
 Nd:=R.NoData;
 HaveNd:=HasArg('NODATA');
 If HaveNd Then Nd:=NeedReal(A,'NODATA');
 HaveWin:=False;HaveSize:=False;
 X1:=0;X2:=0;Y1:=0;Y2:=0;W:=0;H:=0;Pct:=False;Pc:=0;
 SplitList(NeedStr(A,'EXTRA'),' ');
 K:=1;
 While K<=ListCount do Begin
  Tok:=ListItems[K];
  If Tok='-projwin'Then Begin
   If K+4>ListCount Then Fail('Error: -projwin needs ulx uly lrx lry');
   RNum(ListItems[K+1],X1);RNum(ListItems[K+2],Y2);
   RNum(ListItems[K+3],X2);RNum(ListItems[K+4],Y1);
   HaveWin:=True;
   Inc(K,5);
  End
   Else
  If Tok='-outsize'Then Begin
   If K+2>ListCount Then Fail('Error: -outsize needs width height');
   If(ListItems[K+1][Length(ListItems[K+1])]='%')Then Begin
    Pct:=True;
    RNum(Copy(ListItems[K+1],1,Length(ListItems[K+1])-1),Pc);
   End
    Else
   Begin
    Val(ListItems[K+1],W,Code);
    If Code<>0Then Fail('Error: invalid -outsize value');
    Val(ListItems[K+2],H,Code);
    If Code<>0Then Fail('Error: invalid -outsize value');
   End;
   HaveSize:=True;
   Inc(K,3);
  End
   Else
  If Tok='-a_nodata'Then Begin
   If K+1>ListCount Then Fail('Error: -a_nodata needs a value');
   RNum(ListItems[K+1],Nd);
   HaveNd:=True;
   Inc(K,2);
  End
   Else
  If Tok='-b'Then Begin
   If K+1>ListCount Then Fail('Error: -b needs a band number');
   Inc(K,2);
  End
   Else
  Fail('Error: unsupported option in EXTRA: '+Tok);
 End;
 If HaveWin Then Begin
  If(X2<=X1)or(Y2<=Y1)Then Fail('Error: invalid -projwin');
  CropRaster(R,X1,X2,Y1,Y2,T);
  R:=T;
 End;
 If HaveSize Then Begin
  If Pct Then Begin
   W:=RoundL(R.NC*Pc/100);
   H:=RoundL(R.NR*Pc/100);
  End
   Else
  Begin
   If(W=0)and(H>0)Then W:=RoundL(R.NC*H/R.NR);
   If(H=0)and(W>0)Then H:=RoundL(R.NR*W/R.NC);
  End;
  If(W<1)or(H<1)Then Fail('Error: invalid -outsize');
  Cw:=R.Cell*R.NC/W;Ch:=R.Cell*R.NR/H;
  If Abs(Cw-Ch)>1E-6*Cw Then Fail('Error: non-square pixels are not supported');
  NewRaster(O,W,H,R.XLL,RasterTop(R)-H*Cw,Cw,R.NoData);
  For I:=0 to H-1do
   For J:=0 to W-1do Begin
    Si:=FloorL((I+0.5)*R.NR/H);
    Sj:=FloorL((J+0.5)*R.NC/W);
    If Si>=R.NR Then Si:=R.NR-1;
    If Sj>=R.NC Then Sj:=R.NC-1;
    O.Data^[I*W+J]:=R.Data^[Si*R.NC+Sj];
   End;
  R:=O;
 End;
 { valeur de nodata et type de donnees }
 If HaveNd Then Begin
  For I:=0 to R.NR*R.NC-1do
   If IsNoData(R,R.Data^[I])Then R.Data^[I]:=Nd;
  R.NoData:=Nd;
 End;
 If Dtype>=1Then Begin
  Lo:=0;Hi:=0;
  Case Dtype of
   1:Begin Lo:=0;Hi:=255;End;
   2:Begin Lo:=-32768;Hi:=32767;End;
   3:Begin Lo:=0;Hi:=65535;End;
   4:Begin Lo:=0;Hi:=4294967295.0;End;
   5:Begin Lo:=-2147483648.0;Hi:=2147483647.0;End;
  End;
  For I:=0 to R.NR*R.NC-1do Begin
   V:=R.Data^[I];
   If Not IsNoData(R,V)Then Begin
    If Dtype<=5Then Begin
     V:=FloorR(V+0.5);
     If V<Lo Then V:=Lo;
     If V>Hi Then V:=Hi;
    End
     Else
    If Dtype=6Then Begin Sv:=V;V:=Sv;End;
    R.Data^[I]:=V;
   End;
  End;
 End;
 If Dtype>=1Then R.DType:=Dtype;
 WriteRaster(Out,R);
 AddRes('OUTPUT',Out);
End;

Procedure RunViewshed(A:Integer);
Var
 R,O:TRaster;
 ObsX,ObsY,H0,Ht,MaxD,Z0,Z,Zt,D,Slope,MaxS,Dist:Real;
 Oc,Orow,Rad,Ri,Ci,Dr,Dc,Steps,S,Rr,Cc,I:LongInt;
 Vis:Boolean;
 Out:String;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 CheckBand(A);
 ParsePoint(NeedStr(A,'OBSERVER'),ObsX,ObsY);
 H0:=NeedReal(A,'OBSERVER_HEIGHT');
 Ht:=NeedReal(A,'TARGET_HEIGHT');
 MaxD:=NeedReal(A,'MAX_DISTANCE');
 If MaxD<=0Then Fail('Error: MAX_DISTANCE must be greater than 0');
 Out:=NeedStr(A,'OUTPUT');
 Oc:=FloorL((ObsX-R.XLL)/R.Cell);
 Orow:=FloorL((RasterTop(R)-ObsY)/R.Cell);
 If(Oc<0)or(Oc>=R.NC)or(Orow<0)or(Orow>=R.NR)Then Fail('Error: the observer is outside the raster');
 If IsNoData(R,R.Data^[Orow*R.NC+Oc])Then Fail('Error: the observer is on a nodata pixel');
 Z0:=R.Data^[Orow*R.NC+Oc]+H0;
 NewRaster(O,R.NC,R.NR,R.XLL,R.YLL,R.Cell,-9999);
 For I:=0 to R.NR*R.NC-1do O.Data^[I]:=0;
 Rad:=CeilL(MaxD/R.Cell);
 For Ri:=Orow-Rad to Orow+Rad do
  For Ci:=Oc-Rad to Oc+Rad do
   If(Ri>=0)and(Ri<R.NR)and(Ci>=0)and(Ci<R.NC)Then Begin
    Dr:=Ri-Orow;Dc:=Ci-Oc;
    Dist:=Sqrt(Dr*1.0*Dr+Dc*1.0*Dc)*R.Cell;
    If Dist<=MaxD Then Begin
     Zt:=R.Data^[Ri*R.NC+Ci];
     If Not IsNoData(R,Zt)Then Begin
      If Dist=0Then Vis:=True
       Else
      Begin
       MaxS:=-1E30;
       Steps:=Abs(Dr);
       If Abs(Dc)>Steps Then Steps:=Abs(Dc);
       For S:=1 to Steps-1do Begin
        Rr:=Orow+RoundL(Dr*S/Steps);
        Cc:=Oc+RoundL(Dc*S/Steps);
        Z:=R.Data^[Rr*R.NC+Cc];
        If Not IsNoData(R,Z)Then Begin
         D:=Sqrt((Rr-Orow)*1.0*(Rr-Orow)+(Cc-Oc)*1.0*(Cc-Oc))*R.Cell;
         Slope:=(Z-Z0)/D;
         If Slope>MaxS Then MaxS:=Slope;
        End;
       End;
       Vis:=(Zt+Ht-Z0)/Dist>=MaxS;
      End;
      If Vis Then O.Data^[Ri*R.NC+Ci]:=255;
     End;
    End;
   End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;


Procedure RunClipRaster(A:Integer);
Var
 R,O:TRaster;
 X1,X2,Y1,Y2,NewNd,V:Real;
 I:LongInt;
 Out:String;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 ParseExtent(NeedStr(A,'EXTENT'),X1,X2,Y1,Y2);
 Out:=NeedStr(A,'OUTPUT');
 NewNd:=R.NoData;
 If HasArg('NODATA')Then NewNd:=NeedReal(A,'NODATA');
 CropRaster(R,X1,X2,Y1,Y2,O);
 For I:=0 to O.NR*O.NC-1do Begin
  V:=O.Data^[I];
  If IsNoData(O,V)Then O.Data^[I]:=NewNd;
 End;
 O.NoData:=NewNd;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

Procedure RunWarp(A:Integer);
Var
 R,O:TRaster;
 Resamp:Integer;
 Src,Dst:LongInt;
 Out:String;
 NewNd,MinX,MinY,MaxX,MaxY,X,Y,Res,W,H,YTop,Col,Row,Fx,Fy,Wx,Wy,Wt,Sum,V:Real;
 K,I,J,Q,Cc,Rr,Cx,Cy:LongInt;
 Ok:Boolean;
 Have:Boolean;

 Procedure Upd(Px,Py:Real);Begin
  Ok:=TryTransform(Src,Dst,Px,Py);
  If Ok Then Begin
   If Not Have Then Begin MinX:=Px;MaxX:=Px;MinY:=Py;MaxY:=Py;Have:=True;End
    Else
   Begin
    If Px<MinX Then MinX:=Px;
    If Px>MaxX Then MaxX:=Px;
    If Py<MinY Then MinY:=Py;
    If Py>MaxY Then MaxY:=Py;
   End;
  End;
 End;


Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 Src:=ParseEpsg(NeedStr(A,'SOURCE_CRS'),'SOURCE_CRS');
 If Not HasArg('SOURCE_CRS')and(R.Epsg>0)and CrsKnown(R.Epsg)Then Src:=R.Epsg;
 Dst:=ParseEpsg(NeedStr(A,'TARGET_CRS'),'TARGET_CRS');
 Resamp:=Round(NeedReal(A,'RESAMPLING'));
 If(Resamp<>0)and(Resamp<>1)Then Fail('Error: RESAMPLING must be 0 (nearest) or 1 (bilinear)');
 Out:=NeedStr(A,'OUTPUT');
 NewNd:=R.NoData;
 If HasArg('NODATA')Then NewNd:=NeedReal(A,'NODATA');
 YTop:=R.YLL+R.NR*R.Cell;
 { etendue de sortie : transformation du contour du raster source }
 Have:=False;
 MinX:=0;MaxX:=0;MinY:=0;MaxY:=0;
 For K:=0 to 40do Begin
  X:=R.XLL+(R.NC*R.Cell)*K/40;
  Upd(X,R.YLL);
  Upd(X,YTop);
  Y:=R.YLL+(R.NR*R.Cell)*K/40;
  Upd(R.XLL,Y);
  Upd(R.XLL+R.NC*R.Cell,Y);
 End;
 If Not Have Then Fail('Error: the raster cannot be reprojected');
 W:=MaxX-MinX;H:=MaxY-MinY;
 If HasArg('TARGET_RESOLUTION')Then Res:=NeedReal(A,'TARGET_RESOLUTION')
  Else
 If Src=Dst Then Res:=R.Cell
  Else
 Res:=Sqrt(W*W+H*H)/Sqrt(Sqr(R.NC*1.0)+Sqr(R.NR*1.0));
 If Res<=0Then Fail('Error: invalid target resolution');
 O.NC:=RoundL(W/Res);
 O.DType:=0;O.Epsg:=Dst;
 O.NR:=RoundL(H/Res);
 If O.NC<1Then O.NC:=1;
 If O.NR<1Then O.NR:=1;
 If O.NC*O.NR>MaxCells Then Fail('Error: output raster is too large');
 O.XLL:=MinX;
 O.Cell:=Res;
 O.YLL:=MaxY-O.NR*Res;
 O.NoData:=NewNd;
 O.Data:=AllocBlock(O.NC*O.NR*SizeOf(Real));
 For I:=0 to O.NR-1do Begin
  For J:=0 to O.NC-1do Begin
   X:=O.XLL+(J+0.5)*Res;
   Y:=MaxY-(I+0.5)*Res;
   V:=NewNd;
   If TryTransform(Dst,Src,X,Y)Then Begin
    Col:=(X-R.XLL)/R.Cell;
    Row:=(YTop-Y)/R.Cell;
    If(Col>=0)and(Col<R.NC)and(Row>=0)and(Row<R.NR)Then Begin
     If Resamp=0Then Begin
      V:=R.Data^[FloorL(Row)*R.NC+FloorL(Col)];
      If IsNoData(R,V)Then V:=NewNd;
     End
      Else
     Begin
      Fx:=Col-0.5;Fy:=Row-0.5;
      Cc:=FloorL(Fx);Rr:=FloorL(Fy);
      Wx:=Fx-Cc;Wy:=Fy-Rr;
      Sum:=0;Wt:=0;
      For Q:=0 to 3do Begin
       If Q and 1=0Then Fx:=1-Wx Else Fx:=Wx;
       If Q and 2=0Then Fy:=1-Wy Else Fy:=Wy;
       Cx:=Cc+(Q and 1);
       Cy:=Rr+(Q shr 1);
       If(Cx>=0)and(Cx<R.NC)and(Cy>=0)and(Cy<R.NR)Then Begin
        V:=R.Data^[Cy*R.NC+Cx];
        If Not IsNoData(R,V)Then Begin
         Sum:=Sum+V*Fx*Fy;
         Wt:=Wt+Fx*Fy;
        End;
       End;
      End;
      If Wt>0Then V:=Sum/Wt Else V:=NewNd;
     End;
    End;
   End;
   O.Data^[I*O.NC+J]:=V;
  End;
 End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

{ ------------------------------------------------------------------ }
{ Utilitaires de couches et d'attributs                              }
{ ------------------------------------------------------------------ }

{ Objet properties d'une entite (cree s'il manque ou s'il est nul) }
Function PropsOf(F:PJ):PJ;
Var
 Pr:PJ;
Begin
 Pr:=JFind(F,'properties');
 If(Pr=Nil)or(Pr^.Kind<>5)Then Begin
  If Pr=Nil Then Begin
   Pr:=NewJ(5);
   JAddKV(F,'properties',Pr);
  End
   Else
  Begin
   Pr:=NewJ(5);
   JReplace(F,JFind(F,'properties'),Pr);
  End;
 End;
 PropsOf:=Pr;
End;

Procedure PutProp(F:PJ;Name:String;V:PJ);
Var
 Pr,Old:PJ;
Begin
 Pr:=PropsOf(F);
 Old:=JFind(Pr,Name);
 If Old=Nil Then JAddKV(Pr,Name,V)
            Else JReplace(Pr,Old,V);
End;

Function PropText(F:PJ;Name:String):String;Begin
 PropText:=NodeText(GetProp(F,Name));
End;

Function PropReal(F:PJ;Name:String;Var R:Real):Boolean;
Var
 N:PJ;
 E:Integer;
Begin
 PropReal:=False;
 N:=GetProp(F,Name);
 If(N=Nil)or Not(N^.Kind in[2,3])Then Exit;
 Val(JVal(N),R,E);
 PropReal:=(E=0)and(JVal(N)<>'');
End;

Function PropsClone(F:PJ):PJ;
Var
 Pr:PJ;
Begin
 Pr:=JFind(F,'properties');
 If(Pr=Nil)or(Pr^.Kind<>5)Then PropsClone:=NewJ(5)
                          Else PropsClone:=JClone(Pr);
End;

{ Copie les proprietes de Src vers Dst avec un prefixe ; Skip : liste de noms a ignorer (separes par ;) }
Procedure CopyProps(Src,Dst:PJ;Prefix:String);
Var
 Pr,C:PJ;
Begin
 Pr:=JFind(Src,'properties');
 If(Pr=Nil)or(Pr^.Kind<>5)Then Exit;
 C:=Pr^.First;
 While C<>Nil do Begin
  PutProp(Dst,Prefix+JKey(C),JClone(C));
  C:=C^.Next;
 End;
End;

Function ValToJ(V:TVal):PJ;
Var
 N:PJ;
 I:LongInt;
Begin
 Case V.K of
  1:ValToJ:=JNum(V.N);
  2:ValToJ:=JTextEsc(V.S);
  3:ValToJ:=JBool(V.N<>0);
  5:Begin
   N:=NewJ(4);
   For I:=0 to V.L^.Cnt-1do JAdd(N,ValToJ(V.L^.V^[I]));
   ValToJ:=N;
  End;
  6:Begin
   N:=NewJ(5);
   I:=0;
   While I+1<V.L^.Cnt do Begin
    JAddKV(N,ToStr(V.L^.V^[I]),ValToJ(V.L^.V^[I+1]));
    Inc(I,2);
   End;
   ValToJ:=N;
  End;
  7,8,9:ValToJ:=JTextEsc(ToStr(V));
  10:ValToJ:=JNum(V.N);
  Else ValToJ:=NewJ(0);
 End;
End;

{ Remet les entites dans Arr selon l'ordre Ord }
Procedure RebuildArray(Arr:PJ;FA:PJArr;Ord:PLongs;N:LongInt);
Var
 I:LongInt;
Begin
 Arr^.First:=Nil;Arr^.Last:=Nil;
 For I:=0 to N-1do JAdd(Arr,FA^[Ord^[I]]);
End;

{ Tri des entites : cle de groupe (texte), puis valeur de l'expression }
Procedure SortFeatures(FA:PJArr;N:LongInt;Expr,GroupFields:String;Asc,NullsFirst:Boolean;Ord:PLongs);
Var
 Keys,Strs:PStrs;
 Nums:PReals;
 Kinds:PBytes;
 I,K:LongInt;
 V:TVal;
 Key:String;
Begin
 Keys:=AllocBlock((N+1)*SizeOf(PStr));
 Strs:=AllocBlock((N+1)*SizeOf(PStr));
 Nums:=AllocBlock((N+1)*SizeOf(Real));
 Kinds:=AllocBlock((N+1)*SizeOf(Byte));
 SplitList(GroupFields,';,');
 For I:=0 to N-1do Begin
  Key:='';
  For K:=1 to ListCount do Key:=Key+#1+PropText(FA^[I],ListItems[K]);
  Keys^[I]:=MkStr(Key);
  Kinds^[I]:=0;Nums^[I]:=0;Strs^[I]:=MkStr('');
  If Expr<>''Then Begin
   V:=EvalOn(Expr,FA^[I],I);
   Case V.K of
    1:Begin Kinds^[I]:=1;Nums^[I]:=V.N;End;
    2,3:Begin Kinds^[I]:=2;Strs^[I]:=MkStr(ToStr(V));End;
   End;
  End;
  Ord^[I]:=I;
 End;
 SKey:=Keys;SStrv:=Strs;SNum:=Nums;SKind:=Kinds;SAsc:=Asc;SNullFirst:=NullsFirst;SNoTie:=False;
 SMode:=7;
 If N>1Then SortIdx(Ord,0,N-1);
End;

Procedure LoadIn(A:Integer;Name:String;Var Root,Arr:PJ);Begin
 Root:=LoadLayer(NeedStr(A,Name));
 Arr:=LayerFeatures(Root);
End;

{ Ecrit la couche et enregistre le resultat }
Procedure SaveOut(A:Integer;Name:String;Root:PJ);
Var
 Out:String;
Begin
 Out:=NeedStr(A,Name);
 SaveLayer(Out,Root);
 AddRes(Name,Out);
End;

{ ------------------------------------------------------------------ }
{ Algorithmes : attributs                                             }
{ ------------------------------------------------------------------ }

Procedure RunAutoIncremental(A:Integer);
Var
 Root,Arr:PJ;
 FA:PJArr;
 Ord:PLongs;
 N,I,Cnt,Start,Md:LongInt;
 Fld,PrevKey:String;
 Grp:String;
 Vals:PLongs;
 V:LongInt;
 Keys:PStrs;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Fld:=NeedStr(A,'FIELD_NAME');
 Start:=Round(NeedReal(A,'START'));
 Md:=Round(NeedReal(A,'MODULUS'));
 Grp:=NeedStr(A,'GROUP_FIELDS');
 FA:=FeatureArray(Arr,N);
 Ord:=AllocBlock((N+1)*SizeOf(LongInt));
 SortFeatures(FA,N,NeedStr(A,'SORT_EXPRESSION'),Grp,NeedBool(A,'SORT_ASCENDING'),NeedBool(A,'SORT_NULLS_FIRST'),Ord);
 Keys:=SKey;
 Vals:=AllocBlock((N+1)*SizeOf(LongInt));
 Cnt:=0;
 For I:=0 to N-1do Begin
  If(I>0)and(Keys^[Ord^[I]]^<>Keys^[Ord^[I-1]]^)Then Cnt:=0;
  V:=Start+Cnt;
  If Md>0Then V:=Start+(Cnt mod Md);
  Vals^[Ord^[I]]:=V;
  Inc(Cnt);
 End;
 For I:=0 to N-1do PutProp(FA^[I],Fld,JNum(Vals^[I]));
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunAddField(A:Integer);
Var
 Root,Arr,F:PJ;
 Fld:String;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Fld:=NeedStr(A,'FIELD_NAME');
 F:=Arr^.First;
 While F<>Nil do Begin
  PutProp(F,Fld,NewJ(0));
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunUniqueIndex(A:Integer);
Var
 Root,Arr,Sum,SumArr,F:PJ;
 FA:PJArr;
 Ord:PLongs;
 N,I,K,Idx:LongInt;
 Fld,Outf,Prev,Cur,SumFile:String;
 Strs:PStrs;
 Nums:PReals;
 Kinds:PBytes;
 AllNum:Boolean;
 R:Real;
 Idxs:PLongs;
 Counts:PLongs;
 Cnt:LongInt;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Fld:=NeedStr(A,'FIELD');
 Outf:=NeedStr(A,'FIELD_NAME');
 SumFile:=NeedStr(A,'SUMMARY_OUTPUT');
 FA:=FeatureArray(Arr,N);
 Ord:=AllocBlock((N+1)*SizeOf(LongInt));
 Strs:=AllocBlock((N+1)*SizeOf(PStr));
 Nums:=AllocBlock((N+1)*SizeOf(Real));
 Kinds:=AllocBlock((N+1)*SizeOf(Byte));
 AllNum:=True;
 For I:=0 to N-1do Begin
  Cur:=PropText(FA^[I],Fld);
  Strs^[I]:=MkStr(Cur);
  Ord^[I]:=I;
  Kinds^[I]:=2;
  If PropReal(FA^[I],Fld,R)Then Begin Nums^[I]:=R;Kinds^[I]:=1;End
   Else
  If Cur<>''Then AllNum:=False;
  If(GetProp(FA^[I],Fld)=Nil)or(GetProp(FA^[I],Fld)^.Kind=0)Then Kinds^[I]:=0;
 End;
 If Not AllNum Then
  For I:=0 to N-1do If Kinds^[I]=1Then Kinds^[I]:=2;
 SKey:=Nil;SStrv:=Strs;SNum:=Nums;SKind:=Kinds;SAsc:=True;SNullFirst:=True;SNoTie:=True;
 SMode:=7;
 If N>1Then SortIdx(Ord,0,N-1);
 Idxs:=AllocBlock((N+1)*SizeOf(LongInt));
 Counts:=AllocBlock((N+1)*SizeOf(LongInt));
 Idx:=-1;
 For I:=0 to N-1do Begin
  K:=Ord^[I];
  If(I=0)or(CmpIdx(Ord^[I],Ord^[I-1])<>0)Then Begin
   Inc(Idx);
   Counts^[Idx]:=0;
  End;
  Idxs^[K]:=Idx;
  Inc(Counts^[Idx]);
 End;
 For I:=0 to N-1do PutProp(FA^[I],Outf,JNum(Idxs^[I]));
 SaveOut(A,'OUTPUT',Root);
 If SumFile<>''Then Begin
  Sum:=NewLayerLike(Nil,SumArr);
  Idx:=-1;
  For I:=0 to N-1do
   If(I=0)or(CmpIdx(Ord^[I],Ord^[I-1])<>0)Then Begin
    Inc(Idx);
    F:=NewFeature(Nil,Nil);
    PutProp(F,Fld,JTextEsc(Strs^[Ord^[I]]^));
    PutProp(F,Outf,JNum(Idx));
    PutProp(F,'count',JNum(Counts^[Idx]));
    JAdd(SumArr,F);
   End;
  SaveLayer(SumFile,Sum);
  AddRes('SUMMARY_OUTPUT',SumFile);
 End;
End;

Procedure RunAddXY(A:Integer);
Var
 Root,Arr,F:PJ;
 G:TGeom;
 Dst,Src:LongInt;
 Pre:String;
 X,Y:Real;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Dst:=ParseEpsg(NeedStr(A,'CRS'),'CRS');
 Src:=LayerCrs(Root);
 Pre:=NeedStr(A,'PREFIX');
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls=1Then Begin
   X:=G.First^.Pts^[0].X;Y:=G.First^.Pts^[0].Y;
   TransformPt(Src,Dst,X,Y);
   PutProp(F,Pre+'x',JNum(X));
   PutProp(F,Pre+'y',JNum(Y));
  End
   Else
  If G.Cls<>0Then Fail('Error: the input layer must contain points')
   Else
  Begin
   PutProp(F,Pre+'x',NewJ(0));
   PutProp(F,Pre+'y',NewJ(0));
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunDeleteColumn(A:Integer);
Var
 Root,Arr,F,Pr:PJ;
 K:Integer;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 SplitList(NeedStr(A,'COLUMN'),';,');
 F:=Arr^.First;
 While F<>Nil do Begin
  Pr:=JFind(F,'properties');
  If(Pr<>Nil)and(Pr^.Kind=5)Then
   For K:=1 to ListCount do JRemoveKey(Pr,ListItems[K]);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunDropGeometries(A:Integer);
Var
 Root,Arr,F:PJ;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 F:=Arr^.First;
 While F<>Nil do Begin
  SetGeom(F,Nil);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunExtractByAttribute(A:Integer);
Var
 Root,Arr,F,Nx,FailRoot,FailArr:PJ;
 Fld,Val0,Cur,OutFail:String;
 Op,E:Integer;
 Hit,WantFail,NumCmp:Boolean;
 Rv,Rc:Real;
 N:PJ;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Fld:=NeedStr(A,'FIELD');
 Op:=Round(NeedReal(A,'OPERATOR'));
 Val0:=NeedStr(A,'VALUE');
 OutFail:=NeedStr(A,'FAIL_OUTPUT');
 WantFail:=OutFail<>'';
 FailRoot:=NewLayerLike(Root,FailArr);
 NumCmp:=IsNumber(Val0);
 Val(Val0,Rv,E);
 F:=Arr^.First;
 Arr^.First:=Nil;Arr^.Last:=Nil;
 While F<>Nil do Begin
  Nx:=F^.Next;
  N:=GetProp(F,Fld);
  Cur:=NodeText(N);
  Hit:=False;
  If Op=8Then Hit:=(N=Nil)or(N^.Kind=0) Else
  If Op=9Then Hit:=(N<>Nil)and(N^.Kind<>0) Else
  If(N<>Nil)and(N^.Kind<>0)Then Begin
   If(Op>=0)and(Op<=5)Then Begin
    If NumCmp and PropReal(F,Fld,Rc)Then Begin
     Case Op of
      0:Hit:=Rc=Rv;
      1:Hit:=Rc<>Rv;
      2:Hit:=Rc>Rv;
      3:Hit:=Rc>=Rv;
      4:Hit:=Rc<Rv;
      5:Hit:=Rc<=Rv;
     End;
    End
     Else
    Case Op of
     0:Hit:=Cur=Val0;
     1:Hit:=Cur<>Val0;
     2:Hit:=Cur>Val0;
     3:Hit:=Cur>=Val0;
     4:Hit:=Cur<Val0;
     5:Hit:=Cur<=Val0;
    End;
   End
    Else
   If Op=6Then Hit:=Copy(Cur,1,Length(Val0))=Val0 Else
   If Op=7Then Hit:=Pos(Val0,Cur)>0 Else
   If Op=10Then Hit:=Pos(Val0,Cur)=0
    Else
   Fail('Error: OPERATOR must be between 0 and 10');
  End;
  If Hit Then JAdd(Arr,F)
   Else
  If WantFail Then JAdd(FailArr,F);
  F:=Nx;
 End;
 SaveOut(A,'OUTPUT',Root);
 If WantFail Then Begin
  SaveLayer(OutFail,FailRoot);
  AddRes('FAIL_OUTPUT',OutFail);
 End;
End;

{ Convertit une valeur selon FIELD_TYPE : 0 reel, 1 entier, 2 texte }
Function CastValue(V:TVal;Typ:Integer):PJ;
Var
 R:Real;
Begin
 CastValue:=NewJ(0);
 If(V.K=0)or(V.K=4)or(V.K=11)Then Exit;
 If(V.K=5)or(V.K=6)Then Begin
  If Typ=2Then CastValue:=ValToJ(V);
  Exit;
 End;
 Case Typ of
  0:If ToNum(V,R)Then CastValue:=JNum(R);
  1:If ToNum(V,R)Then CastValue:=JNum(Int(R));
  Else CastValue:=JTextEsc(ToStr(V));
 End;
End;

Procedure RunFieldCalculator(A:Integer);
Var
 Root,Arr,F:PJ;
 Fld,Expr:String;
 Typ,I:LongInt;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Fld:=NeedStr(A,'FIELD_NAME');
 Typ:=Round(NeedReal(A,'FIELD_TYPE'));
 Expr:=NeedStr(A,'FORMULA');
 I:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  PutProp(F,Fld,CastValue(EvalOn(Expr,F,I),Typ));
  Inc(I);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

{ Decoupe une chaine en elements separes par Sep, hors guillemets }
Procedure SplitQuoted(S:String;Sep:Char);
Var
 I:Integer;
 T:String;
 Q:Char;
Begin
 ListCount:=0;
 T:='';
 Q:=#0;
 For I:=1 to Length(S)+1do Begin
  If I>Length(S)Then Begin
   If T<>''Then Begin Inc(ListCount);ListItems[ListCount]:=T;End;
  End
   Else
  Begin
   If Q<>#0Then Begin
    If S[I]=Q Then Q:=#0;
    T:=T+S[I];
   End
    Else
   If(S[I]='''')or(S[I]='"')Then Begin Q:=S[I];T:=T+S[I];End
    Else
   If S[I]=Sep Then Begin
    If T<>''Then Begin
     If ListCount>=40Then Fail('Error: too many list items');
     Inc(ListCount);ListItems[ListCount]:=T;
    End;
    T:='';
   End
    Else
   T:=T+S[I];
  End;
 End;
End;

Procedure RunRefactorFields(A:Integer);
Var
 Root,Arr,F,NewP:PJ;
 Names,Exprs:Array[1..40]of String;
 N,K,P,I:Integer;
 Items:Array[1..40]of String;
 Idx:LongInt;
 V:TVal;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 SplitQuoted(NeedStr(A,'FIELDS_MAPPING'),';');
 N:=ListCount;
 For K:=1 to N do Items[K]:=ListItems[K];
 For K:=1 to N do Begin
  P:=Pos('=',Items[K]);
  If P=0Then Fail('Error: FIELDS_MAPPING items must look like name=expression');
  Names[K]:=Copy(Items[K],1,P-1);
  Exprs[K]:=Copy(Items[K],P+1,255);
 End;
 Idx:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  NewP:=NewJ(5);
  For K:=1 to N do Begin
   V:=EvalOn(Exprs[K],F,Idx);
   JAddKV(NewP,Names[K],ValToJ(V));
  End;
  JReplace(F,PropsOf(F),NewP);
  Inc(Idx);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunOrderByExpression(A:Integer);
Var
 Root,Arr:PJ;
 FA:PJArr;
 Ord:PLongs;
 N:LongInt;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 FA:=FeatureArray(Arr,N);
 Ord:=AllocBlock((N+1)*SizeOf(LongInt));
 SortFeatures(FA,N,NeedStr(A,'EXPRESSION'),'',NeedBool(A,'ASCENDING'),NeedBool(A,'NULLS_FIRST'),Ord);
 RebuildArray(Arr,FA,Ord,N);
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunNoOp(A:Integer);
Var
 Src:String;
Begin
 Src:=NeedStr(A,'INPUT');
 LoadLayer(Src);   { verifie que le fichier est lisible }
 AddRes('OUTPUT',Src);
End;

Procedure RunAssignProjection(A:Integer);
Var
 Root,Arr:PJ;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 SetLayerCrs(Root,ParseEpsg(NeedStr(A,'CRS'),'CRS'));
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunSplitByChar(A:Integer);
Var
 Root,Arr,F,Nx,Out,OutArr,C:PJ;
 Fld,Ch,S,T:String;
 P:Integer;
 First:Boolean;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Fld:=NeedStr(A,'FIELD');
 Ch:=NeedStr(A,'CHAR');
 If Length(Ch)<>1Then Fail('Error: CHAR must be a single character');
 Out:=NewLayerLike(Root,OutArr);
 F:=Arr^.First;
 While F<>Nil do Begin
  S:=PropText(F,Fld);
  First:=True;
  Repeat
   P:=Pos(Ch,S);
   If P>0Then Begin T:=Copy(S,1,P-1);S:=Copy(S,P+1,255);End
         Else Begin T:=S;S:='';End;
   C:=NewFeature(PropsClone(F),JClone(JFind(F,'geometry')));
   PutProp(C,Fld,JTextEsc(T));
   JAdd(OutArr,C);
   First:=False;
  Until P=0;
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

{ ------------------------------------------------------------------ }
{ Algorithmes : transformations simples de geometries                 }
{ ------------------------------------------------------------------ }

{ Applique un traitement a chaque geometrie : Mode 0 translation, 1 affine, 2 projection cartesienne }
Procedure MapGeometries(A:Integer;Mode:Integer);
Var
 Root,Arr,F:PJ;
 G:TGeom;
 Dx,Dy,Sx,Sy,Ang,Ca,Sa,Ax,Ay,Cx,Cy,Br,Dist:Real;
 Ok,UseAnchor:Boolean;
 Aa:String;
 I:LongInt;
 P:PPath;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 UseAnchor:=False;
 Dx:=0;Dy:=0;Sx:=1;Sy:=1;Ang:=0;Ax:=0;Ay:=0;Br:=0;Dist:=0;
 Case Mode of
  0:Begin Dx:=NeedReal(A,'DELTA_X');Dy:=NeedReal(A,'DELTA_Y');End;
  1:Begin
   Dx:=NeedReal(A,'DELTA_X');Dy:=NeedReal(A,'DELTA_Y');
   Sx:=NeedReal(A,'SCALE_X');Sy:=NeedReal(A,'SCALE_Y');
   Ang:=NeedReal(A,'ROTATION_Z');
  End;
  2:Begin Br:=Deg2Rad(NeedReal(A,'BEARING'));Dist:=NeedReal(A,'DISTANCE');End;
  3:Begin
   Ang:=NeedReal(A,'ANGLE');
   If HasArg('ANCHOR')Then Begin
    ParsePoint(NeedStr(A,'ANCHOR'),Ax,Ay);
    UseAnchor:=True;
   End;
  End;
 End;
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   Case Mode of
    0:AffineGeom(G,1,0,0,1,Dx,Dy);
    1:Begin
     { rotation, puis mise a l'echelle, puis translation }
     Ca:=Cos(Deg2Rad(Ang));Sa:=Sin(Deg2Rad(Ang));
     AffineGeom(G,Sx*Ca,-Sx*Sa,Sy*Sa,Sy*Ca,Dx,Dy);
    End;
    2:Begin
     If G.Cls<>1Then Fail('Error: the input layer must contain points');
     AffineGeom(G,1,0,0,1,Dist*Sin(Br),Dist*Cos(Br));
    End;
    3:Begin
     If Not UseAnchor Then Begin
      CentroidGeom(G,Cx,Cy,Ok);
      If Not Ok Then Begin Cx:=0;Cy:=0;End;
     End
      Else
     Begin Cx:=Ax;Cy:=Ay;End;
     { rotation horaire (comme l'azimut), autour de l'ancre }
     Ca:=Cos(Deg2Rad(-Ang));Sa:=Sin(Deg2Rad(-Ang));
     AffineGeom(G,Ca,-Sa,Sa,Ca,Cx-Ca*Cx+Sa*Cy,Cy-Sa*Cx-Ca*Cy);
    End;
   End;
   SetGeom(F,BuildGeom(G));
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

{ Orientation : Mode 0 regle de la main droite (exterieur horaire) }
Procedure RunForceRHR(A:Integer);
Var
 Root,Arr,F:PJ;
 G:TGeom;
 P:PPath;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls=3Then Begin
   OrientPolygons(G);
   P:=G.First;
   While P<>Nil do Begin ReversePts(P^.Pts,P^.N);P:=P^.Next;End;
   SetGeom(F,BuildGeom(G));
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

{ Valeurs Z : mode 0 supprimer Z, 1 fixer Z, 2 filtrer par Z }
Procedure ZWalk(N:PJ;Mode:Integer;Z,Lo,Hi:Real);
Var
 C,Prev,Nx:PJ;
 R:Real;
 E:Integer;
Begin
 If(N=Nil)or(N^.Kind<>4)Then Exit;
 C:=N^.First;
 If C=Nil Then Exit;
 If C^.Kind=2Then Begin
  { une position }
  Case Mode of
   0:Begin If C^.Next<>Nil Then C^.Next^.Next:=Nil;N^.Last:=C^.Next;End;
   1:Begin
    If(C^.Next<>Nil)and(C^.Next^.Next<>Nil)Then JReplace(N,C^.Next^.Next,JNum(Z))
     Else
    If C^.Next<>Nil Then JAdd(N,JNum(Z));
   End;
  End;
  Exit;
 End;
 If(Mode=2)and(C^.Kind=4)and(C^.First<>Nil)and(C^.First^.Kind=2)Then Begin
  { liste de positions : filtrage }
  Prev:=Nil;
  While C<>Nil do Begin
   Nx:=C^.Next;
   R:=0;
   E:=1;
   If(C^.First<>Nil)and(C^.First^.Next<>Nil)and(C^.First^.Next^.Next<>Nil)Then Val(JVal(C^.First^.Next^.Next),R,E);
   If(E<>0)or(R<Lo)or(R>Hi)Then Begin
    If Prev=Nil Then N^.First:=Nx Else Prev^.Next:=Nx;
    If N^.Last=C Then N^.Last:=Prev;
   End
    Else
   Prev:=C;
   C:=Nx;
  End;
  Exit;
 End;
 While C<>Nil do Begin
  ZWalk(C,Mode,Z,Lo,Hi);
  C:=C^.Next;
 End;
End;

Procedure RunZValues(A:Integer;Mode:Integer);
Var
 Root,Arr,F,Gn:PJ;
 Z,Lo,Hi:Real;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Z:=0;Lo:=0;Hi:=0;
 Case Mode of
  0:If NeedBool(A,'DROP_M_VALUES')and Not NeedBool(A,'DROP_Z_VALUES')Then
     Begin End;
  1:Z:=NeedReal(A,'Z_VALUE');
  2:Begin Lo:=NeedReal(A,'MIN');Hi:=NeedReal(A,'MAX');End;
 End;
 If(Mode=0)and Not NeedBool(A,'DROP_Z_VALUES')Then Begin
  { rien a supprimer : GeoJSON ne porte pas de valeurs M }
  SaveOut(A,'OUTPUT',Root);
  Exit;
 End;
 F:=Arr^.First;
 While F<>Nil do Begin
  Gn:=JFind(F,'geometry');
  If(Gn<>Nil)and(Gn^.Kind=5)Then ZWalk(JFind(Gn,'coordinates'),Mode,Z,Lo,Hi);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;


{ ------------------------------------------------------------------ }
{ Algorithmes : geometries (parties, sommets, simplification...)     }
{ ------------------------------------------------------------------ }

{ Prend la partie suivante d'une geometrie (point, ligne ou polygone avec ses trous) }
Function TakePart(Var G:TGeom;Var P:PPath;Var Part:TGeom):Boolean;
Var
 Poly:Integer;
Begin
 InitGeom(Part);
 TakePart:=False;
 If P=Nil Then Exit;
 Part.Cls:=G.Cls;
 If G.Cls=3Then Begin
  Poly:=P^.Poly;
  Part.NPoly:=1;
  While(P<>Nil)and(P^.Poly=Poly)do Begin
   CopyPath(Part,P,0);
   P:=P^.Next;
  End;
 End
  Else
 Begin
  CopyPath(Part,P,0);
  P:=P^.Next;
 End;
 TakePart:=True;
End;

Procedure RunMultiToSingle(A:Integer);
Var
 Root,Arr,F,Out,OutArr:PJ;
 G,Part:TGeom;
 P:PPath;
 N:Integer;
 Pieces:LongInt;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Out:=NewLayerLike(Root,OutArr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls=0Then JAdd(OutArr,NewFeature(PropsClone(F),Nil))
   Else
  Begin
   P:=G.First;
   While TakePart(G,P,Part)do Begin
    JAdd(OutArr,NewFeature(PropsClone(F),BuildGeom(Part)));
    FreeGeom(Part);
   End;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

{ Regroupe les geometries par valeurs de champs (FIELD, liste separee par des virgules) }
Procedure RunCollect(A:Integer);
Var
 Root,Arr,F,Out,OutArr,Fe:PJ;
 FA:PJArr;
 N,I,J,K,Ng:LongInt;
 Keys:PStrs;
 Grp:PLongs;
 Key:String;
 GA:^TGeomArr;
 G:TGeom;
 Found:Boolean;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 SplitList(NeedStr(A,'FIELD'),';,');
 FA:=FeatureArray(Arr,N);
 Keys:=AllocBlock((N+1)*SizeOf(PStr));
 Grp:=AllocBlock((N+1)*SizeOf(LongInt));
 GA:=AllocBlock((N+1)*SizeOf(TGeom));
 Ng:=0;
 For I:=0 to N-1do Begin
  Key:='';
  For K:=1 to ListCount do Key:=Key+#1+PropText(FA^[I],ListItems[K]);
  Found:=False;
  For J:=0 to Ng-1do
   If Keys^[J]^=Key Then Begin Found:=True;Grp^[I]:=J;Break;End;
  If Not Found Then Begin
   Keys^[Ng]:=MkStr(Key);
   Grp^[I]:=Ng;
   InitGeom(GA^[Ng]);
   Inc(Ng);
  End;
  FlattenFeature(FA^[I],G);
  If G.Cls<>0Then Begin
   If(GA^[Grp^[I]].Cls<>0)and(GA^[Grp^[I]].Cls<>G.Cls)Then Fail('Error: cannot collect geometries of different types');
   GeomAppend(GA^[Grp^[I]],G);
  End;
  FreeGeom(G);
 End;
 Out:=NewLayerLike(Root,OutArr);
 For J:=0 to Ng-1do Begin
  Fe:=Nil;
  For I:=0 to N-1do If Grp^[I]=J Then Begin Fe:=FA^[I];Break;End;
  JAdd(OutArr,NewFeature(PropsClone(Fe),BuildGeom(GA^[J])));
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunExplodeLines(A:Integer);
Var
 Root,Arr,F,Out,OutArr:PJ;
 G,S:TGeom;
 P,Q:PPath;
 I:LongInt;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Out:=NewLayerLike(Root,OutArr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If(G.Cls<>0)and(G.Cls<>2)Then Fail('Error: the input layer must contain lines');
  P:=G.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-2do Begin
    InitGeom(S);
    S.Cls:=2;
    Q:=NewPath(S,2,0);
    Q^.Pts^[0]:=P^.Pts^[I];Q^.Pts^[1]:=P^.Pts^[I+1];
    JAdd(OutArr,NewFeature(PropsClone(F),BuildLines(S)));
    FreeGeom(S);
   End;
   P:=P^.Next;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunExtractVertices(A:Integer);
Var
 Root,Arr,F,Out,OutArr,Nf:PJ;
 G,S:TGeom;
 P:PPath;
 I,Part,Ring,Idx,Prev:LongInt;
 Acc,Ang,A1,A2,Dx,Dy:Real;
 Closed:Boolean;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Out:=NewLayerLike(Root,OutArr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  Idx:=0;Part:=-1;Ring:=0;Prev:=-1;
  P:=G.First;
  While P<>Nil do Begin
   If G.Cls=3Then Begin
    If P^.Poly<>Prev Then Begin Inc(Part);Ring:=0;End Else Inc(Ring);
    Prev:=P^.Poly;
   End
    Else
   Begin Inc(Part);Ring:=0;End;
   Acc:=0;
   For I:=0 to P^.N-1do Begin
    If I>0Then Acc:=Acc+Sqrt(Sqr(P^.Pts^[I].X-P^.Pts^[I-1].X)+Sqr(P^.Pts^[I].Y-P^.Pts^[I-1].Y));
    { azimut moyen des segments voisins }
    A1:=-1;A2:=-1;
    If I>0Then A1:=NormDeg(Rad2Deg(Atan2(P^.Pts^[I].X-P^.Pts^[I-1].X,P^.Pts^[I].Y-P^.Pts^[I-1].Y)));
    If I<P^.N-1Then A2:=NormDeg(Rad2Deg(Atan2(P^.Pts^[I+1].X-P^.Pts^[I].X,P^.Pts^[I+1].Y-P^.Pts^[I].Y)));
    If(A1<0)and(A2<0)Then Ang:=0 Else
    If A1<0Then Ang:=A2 Else
    If A2<0Then Ang:=A1
     Else
    Begin
     Dx:=Sin(Deg2Rad(A1))+Sin(Deg2Rad(A2));Dy:=Cos(Deg2Rad(A1))+Cos(Deg2Rad(A2));
     Ang:=NormDeg(Rad2Deg(Atan2(Dx,Dy)));
    End;
    PointGeom(S,P^.Pts^[I].X,P^.Pts^[I].Y);
    Nf:=NewFeature(PropsClone(F),BuildPoints(S));
    PutProp(Nf,'vertex_index',JNum(Idx));
    PutProp(Nf,'vertex_part',JNum(Part));
    PutProp(Nf,'vertex_part_ring',JNum(Ring));
    PutProp(Nf,'vertex_pos',JNum(I));
    PutProp(Nf,'distance',JNum(Acc));
    PutProp(Nf,'angle',JNum(Ang));
    JAdd(OutArr,Nf);
    FreeGeom(S);
    Inc(Idx);
   End;
   P:=P^.Next;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunDeleteHoles(A:Integer);
Var
 Root,Arr,F:PJ;
 G,R:TGeom;
 P:PPath;
 MinA:Real;
 Prev:Integer;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 MinA:=NeedReal(A,'MIN_AREA');
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls=3Then Begin
   InitGeom(R);
   R.Cls:=3;R.NPoly:=G.NPoly;
   Prev:=-1;
   P:=G.First;
   While P<>Nil do Begin
    If(P^.Poly<>Prev)or((MinA>0)and(Abs(RingArea(P))>=MinA))Then CopyPath(R,P,P^.Poly);
    Prev:=P^.Poly;
    P:=P^.Next;
   End;
   SetGeom(F,BuildPolygons(R));
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

{ Traitement chemin par chemin : Mode 0 densifier, 1 simplifier, 2 lisser }
Procedure RunPathOp(A:Integer;Mode:Integer);
Var
 Root,Arr,F:PJ;
 G,R:TGeom;
 P:PPath;
 Cnt,Method,Iter:LongInt;
 Tol,Off,MaxAng:Real;
 Closed,Ok:Boolean;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Cnt:=0;Method:=0;Tol:=0;Off:=0.25;MaxAng:=180;Iter:=1;
 Case Mode of
  0:Begin Cnt:=Round(NeedReal(A,'VERTICES'));If Cnt<1Then Fail('Error: VERTICES must be at least 1');End;
  1:Begin Method:=Round(NeedReal(A,'METHOD'));Tol:=NeedReal(A,'TOLERANCE');If(Method<0)or(Method>2)Then Fail('Error: METHOD must be 0, 1 or 2');End;
  2:Begin
   Iter:=Round(NeedReal(A,'ITERATIONS'));Off:=NeedReal(A,'OFFSET');MaxAng:=NeedReal(A,'MAX_ANGLE');
   If(Iter<1)or(Iter>10)Then Fail('Error: ITERATIONS must be between 1 and 10');
   If(Off<=0)or(Off>=0.5)Then Fail('Error: OFFSET must be between 0 and 0.5');
  End;
 End;
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls>=2Then Begin
   InitGeom(R);
   R.Cls:=G.Cls;R.NPoly:=G.NPoly;
   Closed:=G.Cls=3;
   P:=G.First;
   While P<>Nil do Begin
    Case Mode of
     0:DensifyPath(P,Cnt,R,P^.Poly);
     1:Case Method of
        0:Ok:=SimplifyDP(P,Tol,Closed,R,P^.Poly);
        1:Ok:=SnapGridPath(P,Tol,Closed,R,P^.Poly);
        2:Ok:=SimplifyVW(P,Tol,Closed,R,P^.Poly);
       End;
     2:SmoothPath(P,Iter,Off,MaxAng,Closed,R,P^.Poly);
    End;
    P:=P^.Next;
   End;
   If Closed and(R.Count>0)Then Begin
    { un polygone dont l'exterieur disparait perd aussi ses trous }
    If R.First^.Poly<>0Then Begin End;
   End;
   SetGeom(F,BuildGeom(R));
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunLineSubstring(A:Integer);
Var
 Root,Arr,F:PJ;
 G,R:TGeom;
 P:PPath;
 D1,D2:Real;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 D1:=NeedReal(A,'START_DISTANCE');
 D2:=NeedReal(A,'END_DISTANCE');
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   If G.Cls<>2Then Fail('Error: the input layer must contain lines');
   InitGeom(R);R.Cls:=2;
   P:=G.First;
   While P<>Nil do Begin
    If Not SubLine(P,D1,MinR(D2,PathLength(P)),R,0)Then Begin End;
    P:=P^.Next;
   End;
   SetGeom(F,BuildLines(R));
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunSplitLinesByLength(A:Integer);
Var
 Root,Arr,F:PJ;
 G,R:TGeom;
 P:PPath;
 Len,L,D:Real;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Len:=NeedReal(A,'LENGTH');
 If Len<=0Then Fail('Error: LENGTH must be greater than 0');
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   If G.Cls<>2Then Fail('Error: the input layer must contain lines');
   InitGeom(R);R.Cls:=2;
   P:=G.First;
   While P<>Nil do Begin
    L:=PathLength(P);
    D:=0;
    While D<L-1E-12do Begin
     If Not SubLine(P,D,MinR(D+Len,L),R,0)Then Begin End;
     D:=D+Len;
    End;
    P:=P^.Next;
   End;
   SetGeom(F,BuildLines(R));
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunPointsAlongLines(A:Integer);
Var
 Root,Arr,F,Out,OutArr,Nf:PJ;
 G,S,B:TGeom;
 P:PPath;
 Dist,St,En,L,D,X,Y,Ang:Real;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Dist:=NeedReal(A,'DISTANCE');
 St:=NeedReal(A,'START_OFFSET');
 En:=NeedReal(A,'END_OFFSET');
 If Dist<=0Then Fail('Error: DISTANCE must be greater than 0');
 Out:=NewLayerLike(Root,OutArr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<2Then Begin
   If G.Cls<>0Then Fail('Error: the input layer must contain lines or polygons');
  End
   Else
  Begin
   P:=G.First;
   While P<>Nil do Begin
    L:=PathLength(P);
    D:=St;
    While D<=L-En+1E-12do Begin
     If PointAlong(P,D,X,Y,Ang)Then Begin
      PointGeom(S,X,Y);
      Nf:=NewFeature(PropsClone(F),BuildPoints(S));
      PutProp(Nf,'distance',JNum(D));
      PutProp(Nf,'angle',JNum(Ang));
      JAdd(OutArr,Nf);
      FreeGeom(S);
     End;
     D:=D+Dist;
    End;
    P:=P^.Next;
   End;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunTransect(A:Integer);
Var
 Root,Arr,F,Out,OutArr,Nf:PJ;
 G,S:TGeom;
 P:PPath;
 Len,Ang,Az,X,Y,Ax,Ay:Real;
 Side,I,K,Fid,Tid:LongInt;
 Pa:PPath;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Len:=NeedReal(A,'LENGTH');
 Ang:=NeedReal(A,'ANGLE');
 Side:=Round(NeedReal(A,'SIDE'));
 If(Side<0)or(Side>2)Then Fail('Error: SIDE must be 0 (left), 1 (right) or 2 (both)');
 Out:=NewLayerLike(Root,OutArr);
 Fid:=0;Tid:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   If G.Cls<>2Then Fail('Error: the input layer must contain lines');
   P:=G.First;
   While P<>Nil do Begin
    For I:=0 to P^.N-1do Begin
     If I<P^.N-1Then K:=I Else K:=I-1;
     If K>=0Then Begin
      Az:=NormDeg(Rad2Deg(Atan2(P^.Pts^[K+1].X-P^.Pts^[K].X,P^.Pts^[K+1].Y-P^.Pts^[K].Y)));
      InitGeom(S);
      S.Cls:=2;
      Pa:=NewPath(S,2,0);
      Pa^.Pts^[0]:=P^.Pts^[I];
      Pa^.Pts^[1]:=P^.Pts^[I];
      If Side=0Then Begin
       Pa^.Pts^[1].X:=P^.Pts^[I].X+Len*Sin(Deg2Rad(Az-Ang));
       Pa^.Pts^[1].Y:=P^.Pts^[I].Y+Len*Cos(Deg2Rad(Az-Ang));
      End
       Else
      If Side=1Then Begin
       Pa^.Pts^[1].X:=P^.Pts^[I].X+Len*Sin(Deg2Rad(Az+Ang));
       Pa^.Pts^[1].Y:=P^.Pts^[I].Y+Len*Cos(Deg2Rad(Az+Ang));
      End
       Else
      Begin
       Pa^.Pts^[0].X:=P^.Pts^[I].X+Len*Sin(Deg2Rad(Az-Ang));
       Pa^.Pts^[0].Y:=P^.Pts^[I].Y+Len*Cos(Deg2Rad(Az-Ang));
       Pa^.Pts^[1].X:=P^.Pts^[I].X+Len*Sin(Deg2Rad(Az+Ang));
       Pa^.Pts^[1].Y:=P^.Pts^[I].Y+Len*Cos(Deg2Rad(Az+Ang));
      End;
      Nf:=NewFeature(PropsClone(F),BuildLines(S));
      PutProp(Nf,'TR_FID',JNum(Fid));
      PutProp(Nf,'TR_ID',JNum(Tid));
      PutProp(Nf,'TR_SEGMENT',JNum(K));
      PutProp(Nf,'TR_ANGLE',JNum(Az));
      PutProp(Nf,'TR_LENGTH',JNum(Len));
      PutProp(Nf,'TR_ORIENT',JNum(Side));
      JAdd(OutArr,Nf);
      FreeGeom(S);
      Inc(Tid);
     End;
    End;
    P:=P^.Next;
   End;
  End;
  FreeGeom(G);
  Inc(Fid);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

{ Valeur numerique d'un parametre qui est soit un nombre, soit un nom de champ }
Function NumOrField(A:Integer;Name:String;F:PJ):Real;
Var
 S:String;
 R:Real;
 E:Integer;
Begin
 S:=NeedStr(A,Name);
 Val(S,R,E);
 If E=0Then Begin NumOrField:=R;Exit;End;
 If PropReal(F,S,R)Then NumOrField:=R
  Else
 Fail('Error: parameter '+Name+' is neither a number nor a numeric field');
End;

Procedure RunWedgeBuffers(A:Integer);
Var
 Root,Arr,F:PJ;
 G,R:TGeom;
 Pa:PPath;
 Az,W,Ro,Ri,A0,A1,X,Y:Real;
 Steps,I,N:LongInt;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   If G.Cls<>1Then Fail('Error: the input layer must contain points');
   Az:=NumOrField(A,'AZIMUTH',F);
   W:=NumOrField(A,'WIDTH',F);
   Ro:=NumOrField(A,'OUTER_RADIUS',F);
   Ri:=NumOrField(A,'INNER_RADIUS',F);
   X:=G.First^.Pts^[0].X;Y:=G.First^.Pts^[0].Y;
   A0:=Az-W/2;A1:=Az+W/2;
   If W>=360Then Begin A0:=0;A1:=360;End;
   Steps:=CeilL(Abs(A1-A0)/5);
   If Steps<1Then Steps:=1;
   InitGeom(R);R.Cls:=3;R.NPoly:=1;
   If Ri>0Then N:=2*(Steps+1) Else N:=Steps+3;
   Pa:=NewPath(R,N+1,0);
   N:=0;
   If Ri<=0Then Begin Pa^.Pts^[N].X:=X;Pa^.Pts^[N].Y:=Y;Inc(N);End;
   For I:=0 to Steps do Begin
    Pa^.Pts^[N].X:=X+Ro*Sin(Deg2Rad(A0+(A1-A0)*I/Steps));
    Pa^.Pts^[N].Y:=Y+Ro*Cos(Deg2Rad(A0+(A1-A0)*I/Steps));
    Inc(N);
   End;
   If Ri>0Then
    For I:=Steps downto 0do Begin
     Pa^.Pts^[N].X:=X+Ri*Sin(Deg2Rad(A0+(A1-A0)*I/Steps));
     Pa^.Pts^[N].Y:=Y+Ri*Cos(Deg2Rad(A0+(A1-A0)*I/Steps));
     Inc(N);
    End;
   Pa^.Pts^[N]:=Pa^.Pts^[0];
   Pa^.N:=N+1;
   OrientPolygons(R);
   SetGeom(F,BuildPolygons(R));
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

{ Mode 0 : offsetline (une seule courbe), 1 : arrayoffsetlines (plusieurs) }
Procedure RunOffsetLine(A:Integer;Mode:Integer);
Var
 Root,Arr,F,Out,OutArr,Nf:PJ;
 G,R:TGeom;
 P:PPath;
 Dist:Real;
 Seg,Cnt,I:LongInt;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Dist:=0;
 If Mode=0Then Dist:=NeedReal(A,'DISTANCE');
 Seg:=Round(NeedReal(A,'SEGMENTS'));
 If(Seg<1)or(Seg>64)Then Fail('Error: SEGMENTS must be between 1 and 64');
 If Mode=1Then Begin
  Cnt:=Round(NeedReal(A,'COUNT'));
  If Cnt<1Then Fail('Error: COUNT must be at least 1');
  Dist:=NeedReal(A,'OFFSET');
 End
  Else
 Cnt:=1;
 Out:=NewLayerLike(Root,OutArr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   If G.Cls<>2Then Fail('Error: the input layer must contain lines');
   For I:=1 to Cnt do Begin
    InitGeom(R);R.Cls:=2;
    P:=G.First;
    While P<>Nil do Begin
     If Mode=0Then OffsetCurve(R,P,Dist,Seg) Else OffsetCurve(R,P,Dist*I,Seg);
     P:=P^.Next;
    End;
    Nf:=NewFeature(PropsClone(F),BuildLines(R));
    If Mode=1Then Begin
     PutProp(Nf,'instance',JNum(I));
     PutProp(Nf,'offset',JNum(Dist*I));
    End;
    JAdd(OutArr,Nf);
    FreeGeom(R);
   End;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunMergeLayers(A:Integer);
Var
 Layers:Array[1..16]of PJ;
 Names:Array[1..40]of String;
 NL,K,I,NFld:Integer;
 Fields:Array[1..64]of String;
 Out,OutArr,F,Pr,C,Np:PJ;
 Paths:Array[1..16]of String;
 Dst,Src:LongInt;
 Gn:PJ;
 Found:Boolean;
Begin
 SplitList(NeedStr(A,'LAYERS'),';');
 NL:=ListCount;
 If NL<1Then Fail('Error: LAYERS is empty');
 For K:=1 to NL do Begin
  If K>16Then Fail('Error: at most 16 layers can be merged');
  Paths[K]:=ListItems[K];
  Layers[K]:=LoadLayer(Paths[K]);
 End;
 If HasArg('CRS')Then Dst:=ParseEpsg(NeedStr(A,'CRS'),'CRS') Else Dst:=LayerCrs(Layers[1]);
 { liste des champs (union) }
 NFld:=0;
 For K:=1 to NL do Begin
  F:=LayerFeatures(Layers[K])^.First;
  While F<>Nil do Begin
   Pr:=JFind(F,'properties');
   If(Pr<>Nil)and(Pr^.Kind=5)Then Begin
    C:=Pr^.First;
    While C<>Nil do Begin
     Found:=False;
     For I:=1 to NFld do If Fields[I]=JKey(C)Then Found:=True;
     If(Not Found)and(NFld<64)Then Begin Inc(NFld);Fields[NFld]:=JKey(C);End;
     C:=C^.Next;
    End;
   End;
   F:=F^.Next;
  End;
 End;
 Out:=NewLayerLike(Nil,OutArr);
 SetLayerCrs(Out,Dst);
 For K:=1 to NL do Begin
  Src:=LayerCrs(Layers[K]);
  F:=LayerFeatures(Layers[K])^.First;
  While F<>Nil do Begin
   Np:=NewJ(5);
   For I:=1 to NFld do Begin
    C:=GetProp(F,Fields[I]);
    If C=Nil Then JAddKV(Np,Fields[I],NewJ(0)) Else JAddKV(Np,Fields[I],JClone(C));
   End;
   JAddKV(Np,'layer',JTextEsc(BaseName(Paths[K])));
   JAddKV(Np,'path',JTextEsc(Paths[K]));
   Gn:=JClone(JFind(F,'geometry'));
   If(Src<>Dst)and(Gn<>Nil)and(Gn^.Kind=5)Then TransformCoords(JFind(Gn,'coordinates'),Src,Dst);
   JAdd(OutArr,NewFeature(Np,Gn));
   F:=F^.Next;
  End;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunPointOnSurface(A:Integer);
Var
 Root,Arr,F,Out,OutArr:PJ;
 G,Part,S:TGeom;
 P:PPath;
 X,Y:Real;
 AllParts:Boolean;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 AllParts:=NeedBool(A,'ALL_PARTS');
 Out:=NewLayerLike(Root,OutArr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls=0Then JAdd(OutArr,NewFeature(PropsClone(F),Nil))
   Else
  If AllParts Then Begin
   P:=G.First;
   While TakePart(G,P,Part)do Begin
    PointOnSurface(Part,X,Y);
    PointGeom(S,X,Y);
    JAdd(OutArr,NewFeature(PropsClone(F),BuildPoints(S)));
    FreeGeom(S);FreeGeom(Part);
   End;
  End
   Else
  Begin
   PointOnSurface(G,X,Y);
   PointGeom(S,X,Y);
   JAdd(OutArr,NewFeature(PropsClone(F),BuildPoints(S)));
   FreeGeom(S);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunOrientedBox(A:Integer);
Var
 Root,Arr,F,Nf:PJ;
 G,R:TGeom;
 Ar,An,W,H:Real;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   MinOrientedBox(G,R,Ar,An,W,H);
   If R.First<>Nil Then Begin
    SetGeom(F,BuildPolygons(R));
    PutProp(F,'area',JNum(Ar));
    PutProp(F,'angle',JNum(An));
    PutProp(F,'width',JNum(W));
    PutProp(F,'height',JNum(H));
   End
    Else
   SetGeom(F,Nil);
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunRoundness(A:Integer);
Var
 Root,Arr,F:PJ;
 G:TGeom;
 Ar,Pe:Real;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls=3Then Begin
   Ar:=GeomArea(G);Pe:=GeomLength(G);
   If Pe>0Then PutProp(F,'roundness',JNum(4*Pi*Ar/(Pe*Pe)))
          Else PutProp(F,'roundness',NewJ(0));
  End
   Else
  Begin
   If G.Cls<>0Then Fail('Error: the input layer must contain polygons');
   PutProp(F,'roundness',NewJ(0));
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

{ Sommets de toutes les entites, tries et sans doublons }
Function CollectVertices(Arr:PJ;Var N:LongInt):PPts;
Var
 F:PJ;
 G:TGeom;
 P:PPath;
 Raw,Res:PPts;
 Idx:PLongs;
 Cnt,I,M:LongInt;
Begin
 Cnt:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  P:=G.First;
  While P<>Nil do Begin Inc(Cnt,P^.N);P:=P^.Next;End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 Raw:=AllocBlock((Cnt+1)*SizeOf(TPt));
 Cnt:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  P:=G.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-1do Begin Raw^[Cnt]:=P^.Pts^[I];Inc(Cnt);End;
   P:=P^.Next;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 Idx:=AllocBlock((Cnt+1)*SizeOf(LongInt));
 For I:=0 to Cnt-1do Idx^[I]:=I;
 SP:=Raw;SMode:=1;
 If Cnt>1Then SortIdx(Idx,0,Cnt-1);
 Res:=AllocBlock((Cnt+1)*SizeOf(TPt));
 M:=0;
 For I:=0 to Cnt-1do
  If(I=0)or(CmpIdx(Idx^[I],Idx^[I-1])<>0)Then Begin
   Res^[M]:=Raw^[Idx^[I]];
   Inc(M);
  End;
 N:=M;
 CollectVertices:=Res;
End;

Procedure RunConcaveHull(A:Integer);
Var
 Root,Arr,Out,OutArr:PJ;
 Pts:PPts;
 N:LongInt;
 R:TGeom;
 Ratio:Real;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Ratio:=NeedReal(A,'ALPHA');
 If(Ratio<0)or(Ratio>1)Then Fail('Error: ALPHA must be between 0 and 1');
 Pts:=CollectVertices(Arr,N);
 If N<3Then Fail('Error: at least 3 distinct points are required');
 ConcaveHullPts(Pts,N,Ratio,R);
 Out:=NewLayerLike(Root,OutArr);
 JAdd(OutArr,NewFeature(Nil,BuildPolygons(R)));
 FreeGeom(R);
 SaveOut(A,'OUTPUT',Out);
End;

{ Rend valides les polygones (regle pair/impair sur le reseau des anneaux) }
Procedure RunFixGeometries(A:Integer);
Var
 Root,Arr,F:PJ;
 G,L,Faces,R:TGeom;
 P,Q:PPath;
 X,Y:Real;
 K:Integer;
 Face:TGeom;
 Empty:TGeom;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls=3Then Begin
   InitGeom(L);L.Cls:=2;
   P:=G.First;
   While P<>Nil do Begin CopyPath(L,P,0);P:=P^.Next;End;
   PolygonizeLines(L,Faces);
   InitGeom(R);R.Cls:=3;
   K:=0;
   P:=Faces.First;
   While P<>Nil do Begin
    { chaque face : on garde celles dont un point interieur a un nombre impair d'anneaux autour }
    Q:=P;
    InitGeom(Face);Face.Cls:=3;Face.NPoly:=1;
    CopyPath(Face,Q,0);
    P:=P^.Next;
    While(P<>Nil)and(P^.Poly=Q^.Poly)do Begin CopyPath(Face,P,0);P:=P^.Next;End;
    PointOnSurface(Face,X,Y);
    If PtInPolys(G,X,Y,0)=1Then Begin
     GeomAppend(R,Face);
    End;
    FreeGeom(Face);
   End;
   If R.First<>Nil Then Begin
    InitGeom(Empty);
    KeepOrient:=True;
    FreeGeom(L);
    Overlay(0,R,Empty,L);
    KeepOrient:=False;
    SetGeom(F,BuildPolygons(L));
   End
    Else
   SetGeom(F,Nil);
   FreeGeom(R);FreeGeom(L);FreeGeom(Faces);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunSnapGeometries(A:Integer);
Var
 Root,Arr,Ref,RefArr,F,Rf:PJ;
 G,Rg:TGeom;
 P,Q:PPath;
 Tol,D,Best,Bx,By,Cx,Cy:Real;
 Behav:Integer;
 I,J:LongInt;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Ref:=LoadLayer(NeedStr(A,'REFERENCE_LAYER'));
 RefArr:=LayerFeatures(Ref);
 Tol:=NeedReal(A,'TOLERANCE');
 Behav:=Round(NeedReal(A,'BEHAVIOR'));
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   P:=G.First;
   While P<>Nil do Begin
    For I:=0 to P^.N-1do Begin
     Best:=Tol;Bx:=P^.Pts^[I].X;By:=P^.Pts^[I].Y;
     Rf:=RefArr^.First;
     While Rf<>Nil do Begin
      FlattenFeature(Rf,Rg);
      Q:=Rg.First;
      While Q<>Nil do Begin
       For J:=0 to Q^.N-1do Begin
        D:=Sqrt(Sqr(P^.Pts^[I].X-Q^.Pts^[J].X)+Sqr(P^.Pts^[I].Y-Q^.Pts^[J].Y));
        If D<Best Then Begin Best:=D;Bx:=Q^.Pts^[J].X;By:=Q^.Pts^[J].Y;End;
       End;
       Q:=Q^.Next;
      End;
      { comportements 1 et 3 : le point le plus proche (sommet ou segment) }
      If(Behav=1)or(Behav=3)Then Begin
       D:=NearestOnGeom(Rg,P^.Pts^[I].X,P^.Pts^[I].Y,Cx,Cy);
       If(D<Best)and(Rg.Cls>=2)Then Begin Best:=D;Bx:=Cx;By:=Cy;End;
      End;
      FreeGeom(Rg);
      Rf:=Rf^.Next;
     End;
     P^.Pts^[I].X:=Bx;P^.Pts^[I].Y:=By;
    End;
    P:=P^.Next;
   End;
   SetGeom(F,BuildGeom(G));
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

{ Decoupe aux limites de l'antimeridien (lignes) : les parties sont ramenees entre -180 et 180 }
Procedure RunAntimeridian(A:Integer);
Var
 Root,Arr,F:PJ;
 G,R:TGeom;
 P,Pa:PPath;
 Unw:PPts;
 Buf:PPts;
 I,N,BN,W0,W1,M,Cur,Wn:LongInt;
 Off,X0,Y0,X1,Y1,T,Xb,Yb:Real;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   If G.Cls<>2Then Fail('Error: the input layer must contain lines');
   InitGeom(R);R.Cls:=2;
   P:=G.First;
   While P<>Nil do Begin
    N:=P^.N;
    Unw:=AllocBlock((N+1)*SizeOf(TPt));
    Buf:=AllocBlock((N*3+8)*SizeOf(TPt));
    { longitudes continues (sans saut de 360 degres) }
    Off:=0;
    For I:=0 to N-1do Begin
     If I>0Then Begin
      If P^.Pts^[I].X+Off-Unw^[I-1].X>180Then Off:=Off-360 Else
      If P^.Pts^[I].X+Off-Unw^[I-1].X<-180Then Off:=Off+360;
     End;
     Unw^[I].X:=P^.Pts^[I].X+Off;Unw^[I].Y:=P^.Pts^[I].Y;
    End;
    { monde courant : floor((x+180)/360) ; coupure aux multiples impairs de 180 }
    BN:=0;
    Cur:=FloorL((Unw^[0].X+180)/360);
    Buf^[0].X:=Unw^[0].X-360*Cur;Buf^[0].Y:=Unw^[0].Y;BN:=1;
    For I:=1 to N-1do Begin
     X0:=Unw^[I-1].X;Y0:=Unw^[I-1].Y;X1:=Unw^[I].X;Y1:=Unw^[I].Y;
     W1:=FloorL((X1+180)/360);
     While Cur<>W1 do Begin
      { passage de la frontiere entre les mondes Cur et Cur+/-1 }
      If W1>Cur Then Xb:=180+360*Cur Else Xb:=-180+360*Cur;
      If X1<>X0 Then T:=(Xb-X0)/(X1-X0) Else T:=0;
      Yb:=Y0+T*(Y1-Y0);
      Buf^[BN].X:=Xb-360*Cur;Buf^[BN].Y:=Yb;Inc(BN);
      Pa:=NewPath(R,BN,0);
      Move(Buf^,Pa^.Pts^,BN*SizeOf(TPt));
      Pa^.N:=BN;
      If W1>Cur Then Inc(Cur) Else Dec(Cur);
      Buf^[0].X:=Xb-360*Cur;
      Buf^[0].Y:=Yb;BN:=1;
      X0:=Xb;Y0:=Yb;
     End;
     Buf^[BN].X:=X1-360*Cur;Buf^[BN].Y:=Y1;Inc(BN);
    End;
    If BN>=2Then Begin
     Pa:=NewPath(R,BN,0);
     Move(Buf^,Pa^.Pts^,BN*SizeOf(TPt));
     Pa^.N:=BN;
    End;
    FreeMem(Buf,(N*3+8)*SizeOf(TPt));
    FreeMem(Unw,(N+1)*SizeOf(TPt));
    P:=P^.Next;
   End;
   SetGeom(F,BuildLines(R));
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunGeometryByExpression(A:Integer);
Var
 Root,Arr,F:PJ;
 Expr:String;
 V:TVal;
 I:LongInt;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Expr:=NeedStr(A,'EXPRESSION');
 I:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  V:=EvalOn(Expr,F,I);
  If V.K=4Then SetGeom(F,BuildGeom(V.G^))
          Else SetGeom(F,Nil);
  Inc(I);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

{ Decoupe une geometrie aplatie par des polygones (extent, overlay...) }
Procedure ClipToPolys(Var G,B:TGeom;Var R:TGeom);
Var
 Edges:PEdges;
 NB,N:LongInt;
 MinX,MinY,MaxX,MaxY,Ext,Tol:Real;
 P:PPath;
Begin
 InitGeom(R);
 If(G.First=Nil)or(B.First=Nil)Then Exit;
 If G.Cls=3Then Begin
  If ClipOutside Then Overlay(2,G,B,R) Else Overlay(1,G,B,R);
  Exit;
 End;
 GeomBBox(B,MinX,MinY,MaxX,MaxY);
 Ext:=MaxR(MaxX-MinX,MaxY-MinY);
 If Ext<=0Then Ext:=1;
 SnapQ:=Ext*1E-9;
 Tol:=SnapQ*4;
 NB:=EdgeCount(B);
 Edges:=AllocBlock((NB+1)*SizeOf(TEdge));
 N:=0;
 FillEdges(B,Edges,N);
 If G.Cls=2Then ClipLines(G,Edges,N,Tol,R)
  Else
 Begin
  R.Cls:=1;
  P:=G.First;
  While P<>Nil do Begin
   If InsideOrOn(Edges,N,P^.Pts^[0].X,P^.Pts^[0].Y,Tol)<>ClipOutside Then CopyPath(R,P,0);
   P:=P^.Next;
  End;
 End;
 FreeMem(Edges,(NB+1)*SizeOf(TEdge));
End;

Procedure RectGeom(Var G:TGeom;X1,Y1,X2,Y2:Real);
Var
 P:PPath;
Begin
 InitGeom(G);
 G.Cls:=3;G.NPoly:=1;
 P:=NewPath(G,5,0);
 P^.Pts^[0].X:=X1;P^.Pts^[0].Y:=Y1;P^.Pts^[1].X:=X2;P^.Pts^[1].Y:=Y1;
 P^.Pts^[2].X:=X2;P^.Pts^[2].Y:=Y2;P^.Pts^[3].X:=X1;P^.Pts^[3].Y:=Y2;
 P^.Pts^[4]:=P^.Pts^[0];
End;

Procedure RunExtractByExtent(A:Integer);
Var
 Root,Arr,F,Nx:PJ;
 X1,X2,Y1,Y2:Real;
 Box,G,R:TGeom;
 Clip,Keep:Boolean;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 ParseExtent(NeedStr(A,'EXTENT'),X1,X2,Y1,Y2);
 Clip:=NeedBool(A,'CLIP');
 RectGeom(Box,X1,Y1,X2,Y2);
 F:=Arr^.First;
 Arr^.First:=Nil;Arr^.Last:=Nil;
 While F<>Nil do Begin
  Nx:=F^.Next;
  FlattenFeature(F,G);
  Keep:=False;
  If G.Cls<>0Then Begin
   If Clip Then Begin
    ClipToPolys(G,Box,R);
    If R.First<>Nil Then Begin SetGeom(F,BuildGeom(R));Keep:=True;End;
    FreeGeom(R);
   End
    Else
   Keep:=GeomIntersects(G,Box);
  End;
  If Keep Then JAdd(Arr,F);
  FreeGeom(G);
  F:=Nx;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunLinesToPolygons(A:Integer);
Var
 Root,Arr,F:PJ;
 G,R:TGeom;
 P,Q:PPath;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   If G.Cls<>2Then Fail('Error: the input layer must contain lines');
   InitGeom(R);R.Cls:=3;R.NPoly:=1;
   P:=G.First;
   While P<>Nil do Begin
    If P^.N>=3Then Begin
     If(P^.Pts^[0].X=P^.Pts^[P^.N-1].X)and(P^.Pts^[0].Y=P^.Pts^[P^.N-1].Y)Then CopyPath(R,P,0)
      Else
     Begin
      { fermeture de l'anneau }
      Q:=NewPath(R,P^.N+1,0);
      Move(P^.Pts^,Q^.Pts^,P^.N*SizeOf(TPt));
      Q^.Pts^[P^.N]:=P^.Pts^[0];
      Q^.N:=P^.N+1;
     End;
    End;
    P:=P^.Next;
   End;
   OrientPolygons(R);
   SetGeom(F,BuildPolygons(R));
   FreeGeom(R);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunCreateGrid(A:Integer);
Var
 Out,OutArr,Nf:PJ;
 Typ,Ho,Vo:Integer;
 Dst:LongInt;
 X1,X2,Y1,Y2,H,V,Hov,Vov,X,Y,Sx,Sy,Cx,Cy:Real;
 Id,R,C,Rows,Cols:LongInt;
 G:TGeom;
 P:PPath;
 K:Integer;

 Procedure AddCell(L,T,Rr,B:Real;Ri,Ci:LongInt;WithIdx:Boolean);Begin
  Nf:=NewFeature(Nil,BuildGeom(G));
  PutProp(Nf,'id',JNum(Id));
  PutProp(Nf,'left',JNum(L));PutProp(Nf,'top',JNum(T));
  PutProp(Nf,'right',JNum(Rr));PutProp(Nf,'bottom',JNum(B));
  If WithIdx Then Begin
   PutProp(Nf,'row_index',JNum(Ri));
   PutProp(Nf,'col_index',JNum(Ci));
  End;
  JAdd(OutArr,Nf);
  Inc(Id);
 End;

Begin
 Typ:=Round(NeedReal(A,'TYPE'));
 If(Typ<0)or(Typ>4)Then Fail('Error: TYPE must be between 0 and 4');
 ParseExtent(NeedStr(A,'EXTENT'),X1,X2,Y1,Y2);
 H:=NeedReal(A,'HSPACING');V:=NeedReal(A,'VSPACING');
 Hov:=NeedReal(A,'HOVERLAY');Vov:=NeedReal(A,'VOVERLAY');
 If(H<=0)or(V<=0)Then Fail('Error: HSPACING and VSPACING must be greater than 0');
 If(Hov<0)or(Vov<0)or(Hov>=H)or(Vov>=V)Then Fail('Error: invalid overlay');
 Dst:=ParseEpsg(NeedStr(A,'CRS'),'CRS');
 Sx:=H-Hov;Sy:=V-Vov;
 If(((X2-X1)/Sx+1)*((Y2-Y1)/Sy+1))*2>1000000Then Fail('Error: the grid would have too many cells');
 Out:=NewLayerLike(Nil,OutArr);
 SetLayerCrs(Out,Dst);
 Id:=1;
 Case Typ of
  0:Begin
   InitGeom(G);
   R:=0;Y:=Y2;
   While Y>=Y1-1E-9do Begin
    C:=0;X:=X1;
    While X<=X2+1E-9do Begin
     PointGeom(G,X,Y);
     AddCell(X,Y,X,Y,R,C,False);
     FreeGeom(G);
     Inc(C);X:=X1+C*Sx;
    End;
    Inc(R);Y:=Y2-R*Sy;
   End;
  End;
  1:Begin
   R:=0;Y:=Y2;
   While Y>=Y1-1E-9do Begin
    InitGeom(G);G.Cls:=2;
    P:=NewPath(G,2,0);
    P^.Pts^[0].X:=X1;P^.Pts^[0].Y:=Y;P^.Pts^[1].X:=X2;P^.Pts^[1].Y:=Y;
    AddCell(X1,Y,X2,Y,R,0,False);
    FreeGeom(G);
    Inc(R);Y:=Y2-R*Sy;
   End;
   C:=0;X:=X1;
   While X<=X2+1E-9do Begin
    InitGeom(G);G.Cls:=2;
    P:=NewPath(G,2,0);
    P^.Pts^[0].X:=X;P^.Pts^[0].Y:=Y2;P^.Pts^[1].X:=X;P^.Pts^[1].Y:=Y1;
    AddCell(X,Y2,X,Y1,0,C,False);
    FreeGeom(G);
    Inc(C);X:=X1+C*Sx;
   End;
  End;
  2:Begin
   R:=0;Y:=Y2;
   While Y-V>=Y1-1E-9do Begin
    C:=0;X:=X1;
    While X+H<=X2+1E-9do Begin
     RectGeom(G,X,Y-V,X+H,Y);
     AddCell(X,Y,X+H,Y-V,R,C,True);
     FreeGeom(G);
     Inc(C);X:=X1+C*Sx;
    End;
    Inc(R);Y:=Y2-R*Sy;
   End;
  End;
  3:Begin
   { losanges : rangees decalees d'une demi-largeur }
   R:=0;
   Repeat
    Cy:=Y2-V/2-R*V/2;
    C:=0;
    Repeat
     Cx:=X1+H/2+C*H+(R mod 2)*H/2;
     If(Cx+H/2<=X2+1E-9)and(Cy-V/2>=Y1-1E-9)Then Begin
      InitGeom(G);G.Cls:=3;G.NPoly:=1;
      P:=NewPath(G,5,0);
      P^.Pts^[0].X:=Cx;P^.Pts^[0].Y:=Cy-V/2;P^.Pts^[1].X:=Cx+H/2;P^.Pts^[1].Y:=Cy;
      P^.Pts^[2].X:=Cx;P^.Pts^[2].Y:=Cy+V/2;P^.Pts^[3].X:=Cx-H/2;P^.Pts^[3].Y:=Cy;
      P^.Pts^[4]:=P^.Pts^[0];
      AddCell(Cx-H/2,Cy+V/2,Cx+H/2,Cy-V/2,R,C,True);
      FreeGeom(G);
     End;
     Inc(C);
    Until Cx+H/2>X2+H;
    Inc(R);
   Until Cy-V/2<Y1-V;
  End;
  4:Begin
   { hexagones a sommet plat : largeur H, hauteur V, colonnes decalees }
   C:=0;
   Repeat
    Cx:=X1+H/2+C*H*0.75;
    R:=0;
    Repeat
     Cy:=Y2-V/2-R*V-(C mod 2)*V/2;
     If(Cx+H/2<=X2+1E-9)and(Cy-V/2>=Y1-1E-9)Then Begin
      InitGeom(G);G.Cls:=3;G.NPoly:=1;
      P:=NewPath(G,7,0);
      P^.Pts^[0].X:=Cx+H/2;P^.Pts^[0].Y:=Cy;
      P^.Pts^[1].X:=Cx+H/4;P^.Pts^[1].Y:=Cy+V/2;
      P^.Pts^[2].X:=Cx-H/4;P^.Pts^[2].Y:=Cy+V/2;
      P^.Pts^[3].X:=Cx-H/2;P^.Pts^[3].Y:=Cy;
      P^.Pts^[4].X:=Cx-H/4;P^.Pts^[4].Y:=Cy-V/2;
      P^.Pts^[5].X:=Cx+H/4;P^.Pts^[5].Y:=Cy-V/2;
      P^.Pts^[6]:=P^.Pts^[0];
      AddCell(Cx-H/2,Cy+V/2,Cx+H/2,Cy-V/2,R,C,True);
      FreeGeom(G);
     End;
     Inc(R);
    Until Cy-V/2<Y1-V;
    Inc(C);
   Until Cx-H/2>X2;
  End;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

{ Rayon de la Terre pour les calculs spheriques (CALC_METHOD = 2) }
Function SphereArea(Var G:TGeom):Real;
Var
 P:PPath;
 I:LongInt;
 S,Tot:Real;
 Prev:Integer;
Begin
 Tot:=0;
 Prev:=-1;
 P:=G.First;
 While P<>Nil do Begin
  S:=0;
  For I:=0 to P^.N-2do
   S:=S+Deg2Rad(P^.Pts^[I+1].X-P^.Pts^[I].X)*(2+Sin(Deg2Rad(P^.Pts^[I].Y))+Sin(Deg2Rad(P^.Pts^[I+1].Y)));
  S:=Abs(S)*Sqr(EarthRadius)/2;
  If P^.Poly=Prev Then Tot:=Tot-S Else Tot:=Tot+S;
  Prev:=P^.Poly;
  P:=P^.Next;
 End;
 SphereArea:=Tot;
End;

Function SphereLength(Var G:TGeom):Real;
Var
 P:PPath;
 I:LongInt;
 L:Real;
Begin
 L:=0;
 P:=G.First;
 While P<>Nil do Begin
  For I:=0 to P^.N-2do
   L:=L+Haversine(P^.Pts^[I].X,P^.Pts^[I].Y,P^.Pts^[I+1].X,P^.Pts^[I+1].Y);
  P:=P^.Next;
 End;
 SphereLength:=L;
End;

Procedure RunAddGeometryColumns(A:Integer);
Var
 Root,Arr,F:PJ;
 G:TGeom;
 Method:Integer;
 I:LongInt;
 Sph,Metric,Proj:Boolean;
 Lf,Af,Xt,Yt:Real;
 X,Y:Real;
 Ok:Boolean;
 LCrs:LongInt;
 Gg:TGeom;
 P,Q:PPath;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Method:=Round(NeedReal(A,'CALC_METHOD'));
 LCrs:=LayerCrs(Root);
 Sph:=(Method=2)and Not GeoNone;
 Proj:=Not CrsIsGeographic(LCrs);
 Metric:=Sph or Proj;
 Lf:=1;Af:=1;
 If Metric Then Begin
  If DistFactor>0Then Lf:=1/DistFactor;
  If AreaFactor>0Then Af:=1/AreaFactor;
 End;
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  Gg:=G;
  If Sph and Proj Then Begin
   { vertices ramenes en longitude/latitude avant le calcul ellipsoidal }
   InitGeom(Gg);
   Gg.Cls:=G.Cls;Gg.NPoly:=G.NPoly;
   P:=G.First;
   While P<>Nil do Begin
    Q:=CopyPath(Gg,P,P^.Poly);
    For I:=0 to Q^.N-1do Begin
     Xt:=Q^.Pts^[I].X;Yt:=Q^.Pts^[I].Y;
     If TryTransform(LCrs,4326,Xt,Yt)Then Begin Q^.Pts^[I].X:=Xt;Q^.Pts^[I].Y:=Yt;End;
    End;
    P:=P^.Next;
   End;
  End;
  Case G.Cls of
   1:Begin
    CentroidGeom(G,X,Y,Ok);
    PutProp(F,'xcoord',JNum(X));
    PutProp(F,'ycoord',JNum(Y));
   End;
   2:Begin
    If Sph Then Begin
     If GeoOn Then PutProp(F,'length',JNum(EllLength(Gg)*Lf))
              Else PutProp(F,'length',JNum(SphereLength(Gg)*Lf));
    End
     Else PutProp(F,'length',JNum(GeomLength(G)*Lf));
   End;
   3:Begin
    If Sph Then Begin
     If GeoOn Then Begin
      PutProp(F,'area',JNum(EllArea(Gg)*Af));
      PutProp(F,'perimeter',JNum(EllLength(Gg)*Lf));
     End
      Else
     Begin
      PutProp(F,'area',JNum(SphereArea(Gg)*Af));
      PutProp(F,'perimeter',JNum(SphereLength(Gg)*Lf));
     End;
    End
     Else
    Begin
     PutProp(F,'area',JNum(GeomArea(G)*Af));
     PutProp(F,'perimeter',JNum(GeomLength(G)*Lf));
    End;
   End;
  End;
  If Sph and Proj Then FreeGeom(Gg);
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunTaperedBuffer(A:Integer);
Var
 Root,Arr,F:PJ;
 G,Pc,B,R,Cir:TGeom;
 P,Pa:PPath;
 R0,R1,L,Acc,Ra,Rb,Seg2:Real;
 Seg,K,I,J,N:LongInt;
 Empty:TGeom;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 R0:=NeedReal(A,'START_WIDTH');R1:=NeedReal(A,'END_WIDTH');
 Seg:=Round(NeedReal(A,'SEGMENTS'));
 If(Seg<1)or(Seg>64)Then Fail('Error: SEGMENTS must be between 1 and 64');
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   If G.Cls<>2Then Fail('Error: the input layer must contain lines');
   InitGeom(Pc);Pc.Cls:=3;
   InitGeom(Empty);
   K:=0;
   P:=G.First;
   While P<>Nil do Begin
    L:=PathLength(P);
    Acc:=0;
    For I:=0 to P^.N-2do Begin
     If L>0Then Begin
      Ra:=R0+(R1-R0)*Acc/L;
      Acc:=Acc+Sqrt(Sqr(P^.Pts^[I+1].X-P^.Pts^[I].X)+Sqr(P^.Pts^[I+1].Y-P^.Pts^[I].Y));
      Rb:=R0+(R1-R0)*Acc/L;
     End
      Else
     Begin Ra:=R0;Rb:=R0;End;
     { enveloppe convexe des deux cercles }
     InitGeom(Cir);Cir.Cls:=1;
     N:=4*Seg;
     For J:=0 to N-1do Begin
      Pa:=NewPath(Cir,1,0);
      Pa^.Pts^[0].X:=P^.Pts^[I].X+Ra*Cos(2*Pi*J/N);Pa^.Pts^[0].Y:=P^.Pts^[I].Y+Ra*Sin(2*Pi*J/N);
      Pa:=NewPath(Cir,1,0);
      Pa^.Pts^[0].X:=P^.Pts^[I+1].X+Rb*Cos(2*Pi*J/N);Pa^.Pts^[0].Y:=P^.Pts^[I+1].Y+Rb*Sin(2*Pi*J/N);
     End;
     HullGeom(Cir,R);
     If R.Cls=3Then Begin
      CopyPath(Pc,R.First,K);
      Inc(K);
     End;
     FreeGeom(R);FreeGeom(Cir);
    End;
    P:=P^.Next;
   End;
   Pc.NPoly:=K;
   If Pc.First<>Nil Then Begin
    KeepOrient:=True;
    Overlay(0,Pc,Empty,R);
    KeepOrient:=False;
    SetGeom(F,BuildPolygons(R));
    FreeGeom(R);
   End
    Else
   SetGeom(F,Nil);
   FreeGeom(Pc);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

{ Centroides des entites dans deux tableaux (valeurs reelles) }
Procedure FeatureCentroids(Arr:PJ;Var N:LongInt;Var Xs,Ys:PReals;Var Have:PBools);
Var
 F:PJ;
 G:TGeom;
 I:LongInt;
 Ok:Boolean;
Begin
 N:=0;
 F:=Arr^.First;
 While F<>Nil do Begin Inc(N);F:=F^.Next;End;
 Xs:=AllocBlock((N+1)*SizeOf(Real));Ys:=AllocBlock((N+1)*SizeOf(Real));Have:=AllocBlock((N+1)*SizeOf(Boolean));
 I:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  CentroidGeom(G,Xs^[I],Ys^[I],Ok);
  Have^[I]:=Ok;
  FreeGeom(G);
  Inc(I);
  F:=F^.Next;
 End;
End;

Procedure RunKMeans(A:Integer);
Var
 Root,Arr,F:PJ;
 N,I,J,K,Ks,It:LongInt;
 Xs,Ys,Cx,Cy,Dm:PReals;
 Have:PBools;
 Lab,Cnt:PLongs;
 Best,D,Mx,My:Real;
 Fld,SFld:String;
 Changed:Boolean;
 BestJ:LongInt;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Ks:=Round(NeedReal(A,'CLUSTERS'));
 Fld:=NeedStr(A,'FIELD_NAME');
 SFld:=NeedStr(A,'SIZE_FIELD_NAME');
 FeatureCentroids(Arr,N,Xs,Ys,Have);
 If(Ks<1)or(Ks>N)Then Fail('Error: CLUSTERS must be between 1 and the number of features');
 Cx:=AllocBlock((Ks+1)*SizeOf(Real));Cy:=AllocBlock((Ks+1)*SizeOf(Real));
 Dm:=AllocBlock((N+1)*SizeOf(Real));
 Lab:=AllocBlock((N+1)*SizeOf(LongInt));Cnt:=AllocBlock((Ks+1)*SizeOf(LongInt));
 { initialisation deterministe : premier point, puis le plus eloigne des centres choisis }
 Cx^[0]:=Xs^[0];Cy^[0]:=Ys^[0];
 For I:=0 to N-1do Dm^[I]:=Sqr(Xs^[I]-Cx^[0])+Sqr(Ys^[I]-Cy^[0]);
 For J:=1 to Ks-1do Begin
  Best:=-1;BestJ:=0;
  For I:=0 to N-1do If Dm^[I]>Best Then Begin Best:=Dm^[I];BestJ:=I;End;
  Cx^[J]:=Xs^[BestJ];Cy^[J]:=Ys^[BestJ];
  For I:=0 to N-1do Begin
   D:=Sqr(Xs^[I]-Cx^[J])+Sqr(Ys^[I]-Cy^[J]);
   If D<Dm^[I]Then Dm^[I]:=D;
  End;
 End;
 For It:=1 to 100do Begin
  Changed:=False;
  For I:=0 to N-1do Begin
   Best:=1E300;BestJ:=0;
   For J:=0 to Ks-1do Begin
    D:=Sqr(Xs^[I]-Cx^[J])+Sqr(Ys^[I]-Cy^[J]);
    If D<Best Then Begin Best:=D;BestJ:=J;End;
   End;
   If(It=1)or(Lab^[I]<>BestJ)Then Changed:=True;
   Lab^[I]:=BestJ;
  End;
  For J:=0 to Ks-1do Begin
   Mx:=0;My:=0;Cnt^[J]:=0;
   For I:=0 to N-1do If Lab^[I]=J Then Begin Mx:=Mx+Xs^[I];My:=My+Ys^[I];Inc(Cnt^[J]);End;
   If Cnt^[J]>0Then Begin Cx^[J]:=Mx/Cnt^[J];Cy^[J]:=My/Cnt^[J];End;
  End;
  If Not Changed Then Break;
 End;
 For J:=0 to Ks-1do Cnt^[J]:=0;
 For I:=0 to N-1do Inc(Cnt^[Lab^[I]]);
 I:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  PutProp(F,Fld,JNum(Lab^[I]));
  PutProp(F,SFld,JNum(Cnt^[Lab^[I]]));
  Inc(I);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunDbscan(A:Integer);
Var
 Root,Arr,F:PJ;
 N,I,J,K,Cl,Sp,MinSz,M:LongInt;
 Xs,Ys:PReals;
 Have:PBools;
 Lab,Stack,Nb,Cnt,Core:PLongs;
 Eps:Real;
 Star:Boolean;
 Fld,SFld:String;
 IsCore:PBools;

 Function Neighbours(P:LongInt;Buf:PLongs):LongInt;
 Var
  Q,C:LongInt;
 Begin
  C:=0;
  For Q:=0 to N-1do
   If Sqr(Xs^[P]-Xs^[Q])+Sqr(Ys^[P]-Ys^[Q])<=Eps*Eps Then Begin Buf^[C]:=Q;Inc(C);End;
  Neighbours:=C;
 End;

Begin
 LoadIn(A,'INPUT',Root,Arr);
 MinSz:=Round(NeedReal(A,'MIN_SIZE'));
 Eps:=NeedReal(A,'EPS');
 Star:=NeedBool(A,'DBSCAN*');
 Fld:=NeedStr(A,'FIELD_NAME');
 SFld:=NeedStr(A,'SIZE_FIELD_NAME');
 FeatureCentroids(Arr,N,Xs,Ys,Have);
 Lab:=AllocBlock((N+1)*SizeOf(LongInt));
 Stack:=AllocBlock((N+2)*SizeOf(LongInt));
 Nb:=AllocBlock((N+1)*SizeOf(LongInt));
 Cnt:=AllocBlock((N+2)*SizeOf(LongInt));
 IsCore:=AllocBlock((N+1)*SizeOf(Boolean));
 For I:=0 to N-1do Begin Lab^[I]:=-2;IsCore^[I]:=Neighbours(I,Nb)>=MinSz;End;
 Cl:=0;
 For I:=0 to N-1do
  If(Lab^[I]=-2)Then Begin
   If Not IsCore^[I]Then Lab^[I]:=-1
    Else
   Begin
    Lab^[I]:=Cl;
    Sp:=0;
    Stack^[Sp]:=I;Inc(Sp);
    While Sp>0do Begin
     Dec(Sp);
     K:=Stack^[Sp];
     If IsCore^[K]Then Begin
      M:=Neighbours(K,Nb);
      For J:=0 to M-1do
       If(Lab^[Nb^[J]]=-2)or(Lab^[Nb^[J]]=-1)Then Begin
        If IsCore^[Nb^[J]]Then Begin
         Lab^[Nb^[J]]:=Cl;
         Stack^[Sp]:=Nb^[J];Inc(Sp);
        End
         Else
        If Not Star Then Lab^[Nb^[J]]:=Cl
         Else
        Lab^[Nb^[J]]:=-1;
       End;
     End;
    End;
    Inc(Cl);
   End;
  End;
 For J:=0 to Cl-1do Cnt^[J]:=0;
 For I:=0 to N-1do If Lab^[I]>=0Then Inc(Cnt^[Lab^[I]]);
 I:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  If Lab^[I]>=0Then Begin
   PutProp(F,Fld,JNum(Lab^[I]));
   PutProp(F,SFld,JNum(Cnt^[Lab^[I]]));
  End
   Else
  Begin
   PutProp(F,Fld,NewJ(0));
   PutProp(F,SFld,NewJ(0));
  End;
  Inc(I);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunNearestNeighbour(A:Integer);
Var
 Root,Arr:PJ;
 N,I,J:LongInt;
 Xs,Ys:PReals;
 Have:PBools;
 D,Best,Sum,MinX,MaxX,MinY,MaxY,Area,Obs,Expd,Se:Real;
 T:Text;
 Out:String;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 FeatureCentroids(Arr,N,Xs,Ys,Have);
 If N<2Then Fail('Error: at least 2 points are required');
 Sum:=0;
 MinX:=Xs^[0];MaxX:=MinX;MinY:=Ys^[0];MaxY:=MinY;
 For I:=0 to N-1do Begin
  Best:=1E300;
  For J:=0 to N-1do
   If J<>I Then Begin
    D:=Sqrt(Sqr(Xs^[I]-Xs^[J])+Sqr(Ys^[I]-Ys^[J]));
    If D<Best Then Best:=D;
   End;
  Sum:=Sum+Best;
  If Xs^[I]<MinX Then MinX:=Xs^[I];If Xs^[I]>MaxX Then MaxX:=Xs^[I];
  If Ys^[I]<MinY Then MinY:=Ys^[I];If Ys^[I]>MaxY Then MaxY:=Ys^[I];
 End;
 Obs:=Sum/N;
 Area:=(MaxX-MinX)*(MaxY-MinY);
 If Area<=0Then Fail('Error: the points are aligned, the extent has no area');
 Expd:=0.5/Sqrt(N/Area);
 Se:=0.26136/Sqrt(N*N/Area);
 AddRes('OBSERVED_MD',RealToStr(Obs));
 AddRes('EXPECTED_MD',RealToStr(Expd));
 AddRes('NN_INDEX',RealToStr(Obs/Expd));
 AddRes('POINT_COUNT',IntToStr(N));
 AddRes('Z_SCORE',RealToStr((Obs-Expd)/Se));
 Out:=NeedStr(A,'OUTPUT_HTML_FILE');
 If Out<>''Then Begin
  {$I-}
  Assign(T,Out);
  Rewrite(T);
  {$I+}
  If IOResult<>0Then Fail('Error: unable to create output file '+Out);
  WriteLn(T,'Observed mean distance: ',RealToStr(Obs));
  WriteLn(T,'Expected mean distance: ',RealToStr(Expd));
  WriteLn(T,'Nearest neighbour index: ',RealToStr(Obs/Expd));
  WriteLn(T,'Number of points: ',N);
  WriteLn(T,'Z-score: ',RealToStr((Obs-Expd)/Se));
  Close(T);
  AddRes('OUTPUT_HTML_FILE',Out);
 End;
End;

Procedure RunAngleToNearest(A:Integer);
Var
 Root,Arr,Ref,RefArr,F,Rf:PJ;
 G,Rg:TGeom;
 P:PPath;
 X,Y,Qx,Qy,D,Best,Az,MaxD:Real;
 I:LongInt;
 Ok,HaveMax:Boolean;
 Fld:String;
 BestAz:Real;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Ref:=LoadLayer(NeedStr(A,'REFERENCE_LAYER'));
 RefArr:=LayerFeatures(Ref);
 Fld:=NeedStr(A,'FIELD_NAME');
 HaveMax:=HasArg('MAX_DISTANCE');
 MaxD:=0;
 If HaveMax Then MaxD:=NeedReal(A,'MAX_DISTANCE');
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  CentroidGeom(G,X,Y,Ok);
  If Ok Then Begin
   Best:=1E300;BestAz:=0;
   Rf:=RefArr^.First;
   While Rf<>Nil do Begin
    FlattenFeature(Rf,Rg);
    If Rg.Cls>=2Then Begin
     P:=Rg.First;
     While P<>Nil do Begin
      For I:=0 to P^.N-2do Begin
       If(P^.Pts^[I].X<>P^.Pts^[I+1].X)or(P^.Pts^[I].Y<>P^.Pts^[I+1].Y)Then Begin
        ClosestOnSeg(X,Y,P^.Pts^[I].X,P^.Pts^[I].Y,P^.Pts^[I+1].X,P^.Pts^[I+1].Y,Qx,Qy);
        D:=Sqrt(Sqr(X-Qx)+Sqr(Y-Qy));
        If D<Best Then Begin
         Best:=D;
         BestAz:=NormDeg(Rad2Deg(Atan2(P^.Pts^[I+1].X-P^.Pts^[I].X,P^.Pts^[I+1].Y-P^.Pts^[I].Y)));
        End;
       End;
      End;
      P:=P^.Next;
     End;
    End;
    FreeGeom(Rg);
    Rf:=Rf^.Next;
   End;
   If(Best<1E299)and((Not HaveMax)or(Best<=MaxD))Then PutProp(F,Fld,JNum(BestAz))
                                                   Else PutProp(F,Fld,NewJ(0));
  End
   Else
  PutProp(F,Fld,NewJ(0));
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Root);
End;

Procedure RunShortestLine(A:Integer);
Var
 Src,SArr,Dst,DArr,F,Df,Out,OutArr,Nf:PJ;
 G,H,L:TGeom;
 P:PPath;
 K,Cnt,I,J,Pick:LongInt;
 Ds:PReals;
 Dx1,Dy1,Dx2,Dy2,D,MaxD:Real;
 HaveMax:Boolean;
 Ax,Ay,Bx,By,Prev:Real;
 DA:PJArr;
 Nd:LongInt;
 Used:PBools;
 Best:Real;
 BestI:LongInt;
Begin
 Src:=LoadLayer(NeedStr(A,'SOURCE'));SArr:=LayerFeatures(Src);
 Dst:=LoadLayer(NeedStr(A,'DESTINATION'));DArr:=LayerFeatures(Dst);
 K:=Round(NeedReal(A,'NEIGHBORS'));
 If Round(NeedReal(A,'METHOD'))=0Then K:=1;
 If K<1Then Fail('Error: NEIGHBORS must be at least 1');
 HaveMax:=HasArg('DISTANCE');
 MaxD:=0;
 If HaveMax Then MaxD:=NeedReal(A,'DISTANCE');
 DA:=FeatureArray(DArr,Nd);
 Ds:=AllocBlock((Nd+1)*SizeOf(Real));
 Used:=AllocBlock((Nd+1)*SizeOf(Boolean));
 Out:=NewLayerLike(Src,OutArr);
 F:=SArr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   For I:=0 to Nd-1do Begin
    FlattenFeature(DA^[I],H);
    If H.Cls=0Then Ds^[I]:=1E300 Else Ds^[I]:=NearestPoints(G,H,Ax,Ay,Bx,By);
    FreeGeom(H);
    Used^[I]:=False;
   End;
   For J:=1 to K do Begin
    Best:=1E300;BestI:=-1;
    For I:=0 to Nd-1do If(Not Used^[I])and(Ds^[I]<Best)Then Begin Best:=Ds^[I];BestI:=I;End;
    If(BestI>=0)and((Not HaveMax)or(Best<=MaxD))Then Begin
     Used^[BestI]:=True;
     FlattenFeature(DA^[BestI],H);
     NearestPoints(G,H,Ax,Ay,Bx,By);
     InitGeom(L);L.Cls:=2;
     P:=NewPath(L,2,0);
     P^.Pts^[0].X:=Ax;P^.Pts^[0].Y:=Ay;P^.Pts^[1].X:=Bx;P^.Pts^[1].Y:=By;
     Nf:=NewFeature(PropsClone(F),BuildLines(L));
     PutProp(Nf,'distance',JNum(Best));
     PutProp(Nf,'feature_x',JNum(Ax));PutProp(Nf,'feature_y',JNum(Ay));
     PutProp(Nf,'nearest_x',JNum(Bx));PutProp(Nf,'nearest_y',JNum(By));
     JAdd(OutArr,Nf);
     FreeGeom(L);FreeGeom(H);
    End;
   End;
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

{ ------------------------------------------------------------------ }
{ Algorithmes : superposition et analyses spatiales                   }
{ ------------------------------------------------------------------ }

Type
 TNameList=Record
  N:Integer;
  Names:Array[1..64]of String;
 End;
 TCache=Record
  N:LongInt;
  FA:PJArr;
  G:^TGeomArr;
  B:PEdges;
 End;

Function ParamExists(A:Integer;Name:String):Boolean;
Var
 P:ParamRec;
Begin
 ParamExists:=ParamDef(A,Name,P);
End;

{ Geometries et boites englobantes d'une couche }
Procedure BuildCache(Arr:PJ;Var C:TCache);
Var
 I:LongInt;
Begin
 C.FA:=FeatureArray(Arr,C.N);
 C.G:=AllocBlock((C.N+1)*SizeOf(TGeom));
 C.B:=AllocBlock((C.N+1)*SizeOf(TEdge));
 For I:=0 to C.N-1do Begin
  FlattenFeature(C.FA^[I],C.G^[I]);
  If Not GeomBBox(C.G^[I],C.B^[I].X1,C.B^[I].Y1,C.B^[I].X2,C.B^[I].Y2)Then Begin
   C.B^[I].X1:=1;C.B^[I].X2:=0;C.B^[I].Y1:=1;C.B^[I].Y2:=0;
  End;
 End;
End;

Function BoxHit(Var A:TCache;I:LongInt;Var B:TCache;J:LongInt):Boolean;Begin
 BoxHit:=False;
 If(A.B^[I].X1>A.B^[I].X2)or(B.B^[J].X1>B.B^[J].X2)Then Exit;
 BoxHit:=Not((B.B^[J].X1>A.B^[I].X2)or(B.B^[J].X2<A.B^[I].X1)or(B.B^[J].Y1>A.B^[I].Y2)or(B.B^[J].Y2<A.B^[I].Y1));
End;

Procedure CollectFields(Arr:PJ;Var L:TNameList);
Var
 F,C,Pr:PJ;
 I:Integer;
 Found:Boolean;
Begin
 L.N:=0;
 F:=Arr^.First;
 While F<>Nil do Begin
  Pr:=JFind(F,'properties');
  If(Pr<>Nil)and(Pr^.Kind=5)Then Begin
   C:=Pr^.First;
   While C<>Nil do Begin
    Found:=False;
    For I:=1 to L.N do If L.Names[I]=JKey(C)Then Found:=True;
    If(Not Found)and(L.N<64)Then Begin Inc(L.N);L.Names[L.N]:=JKey(C);End;
    C:=C^.Next;
   End;
  End;
  F:=F^.Next;
 End;
End;

Function InList(Var L:TNameList;Name:String):Boolean;
Var
 I:Integer;
Begin
 InList:=False;
 For I:=1 to L.N do If L.Names[I]=Name Then InList:=True;
End;

{ Attributs de F1 puis de F2 (valeurs nulles si l'entite manque) ; les noms de F2 recoivent Prefix }
Function JoinProps(F1:PJ;Var L1:TNameList;F2:PJ;Var L2:TNameList;Prefix:String):PJ;
Var
 Np,N:PJ;
 I:Integer;
 Nm:String;
Begin
 Np:=NewJ(5);
 For I:=1 to L1.N do Begin
  N:=Nil;
  If F1<>Nil Then N:=GetProp(F1,L1.Names[I]);
  If N=Nil Then JAddKV(Np,L1.Names[I],NewJ(0)) Else JAddKV(Np,L1.Names[I],JClone(N));
 End;
 For I:=1 to L2.N do Begin
  Nm:=Prefix+L2.Names[I];
  If(Prefix='')and InList(L1,Nm)Then Nm:=Nm+'_2';
  N:=Nil;
  If F2<>Nil Then N:=GetProp(F2,L2.Names[I]);
  If N=Nil Then JAddKV(Np,Nm,NewJ(0)) Else JAddKV(Np,Nm,JClone(N));
 End;
 JoinProps:=Np;
End;

{ Table (GeoJSON ou CSV) sous forme de couche sans geometrie }
Function LoadTable(FileName:String):PJ;
Var
 T:Text;
 Line,Cell:String;
 Hdr:Array[1..64]of String;
 NH,K,I:Integer;
 Root,Arr,F,Pr:PJ;
 Q:Boolean;
 Cells:Array[1..64]of String;
 NC:Integer;
 Up:String;
 Buf:Array[0..4095]of Char;

 Procedure Parse(S:String);
 Var
  J:Integer;
 Begin
  NC:=0;
  Cell:='';Q:=False;
  J:=1;
  While J<=Length(S)+1do Begin
   If J>Length(S)Then Begin
    If NC<64Then Begin Inc(NC);Cells[NC]:=Cell;End;
   End
    Else
   If Q Then Begin
    If S[J]='"'Then Begin
     If(J<Length(S))and(S[J+1]='"')Then Begin Cell:=Cell+'"';Inc(J);End
                                    Else Q:=False;
    End
     Else
    Cell:=Cell+S[J];
   End
    Else
   If S[J]='"'Then Q:=True
    Else
   If S[J]=','Then Begin
    If NC<64Then Begin Inc(NC);Cells[NC]:=Cell;End;
    Cell:='';
   End
    Else
   If S[J]<>#13Then Cell:=Cell+S[J];
   Inc(J);
  End;
 End;

Begin
 Up:=StrUpper(FileName);
 If(Length(Up)<4)or(Copy(Up,Length(Up)-3,4)<>'.CSV')Then Begin
  LoadTable:=LoadLayer(FileName);
  Exit;
 End;
 {$I-}
 Assign(T,FileName);
 Reset(T);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to open input file '+FileName);
 SetTextBuf(T,Buf);
 Root:=NewLayerLike(Nil,Arr);
 NH:=0;
 If Not EOF(T)Then Begin
  ReadLn(T,Line);
  Parse(Line);
  NH:=NC;
  For I:=1 to NH do Hdr[I]:=Cells[I];
 End;
 While Not EOF(T)do Begin
  ReadLn(T,Line);
  If Line<>''Then Begin
   Parse(Line);
   Pr:=NewJ(5);
   For I:=1 to NH do Begin
    If I>NC Then JAddKV(Pr,Hdr[I],NewJ(0))
     Else
    If IsNumber(Cells[I])Then JAddKV(Pr,Hdr[I],JNum(0))
     Else
    JAddKV(Pr,Hdr[I],JTextEsc(Cells[I]));
    If(I<=NC)and IsNumber(Cells[I])Then Begin
     { valeur numerique : on conserve le texte d'origine }
     JFind(Pr,Hdr[I])^.Val:=MkStr(Cells[I]);
    End;
   End;
   JAdd(Arr,NewFeature(Pr,Nil));
  End;
 End;
 Close(T);
 LoadTable:=Root;
End;

{ ---- intersection / difference / union / difference symetrique ---- }

{ Mode 0 intersection, 1 union, 2 difference symetrique }
Procedure RunOverlayLayers(A:Integer;Mode:Integer);
Var
 InR,InA,OvR,OvA,Out,OutArr:PJ;
 CI,CO:TCache;
 LI,LO:TNameList;
 I,J:LongInt;
 R,Bf:TGeom;
 Pref:String;

 Procedure Emit(Var Rg:TGeom;F1,F2:PJ);Begin
  If Rg.First<>Nil Then JAdd(OutArr,NewFeature(JoinProps(F1,LI,F2,LO,Pref),BuildGeom(Rg)));
 End;

 { parties de la couche X non couvertes par les polygones de la couche Y }
 Procedure OnlyIn(Var X,Y:TCache;FromInput:Boolean);
 Var
  K,L:LongInt;
 Begin
  For K:=0 to X.N-1do
   If X.G^[K].Cls<>0Then Begin
    InitGeom(Bf);Bf.Cls:=3;
    For L:=0 to Y.N-1do
     If(Y.G^[L].Cls=3)and BoxHit(X,K,Y,L)Then GeomAppend(Bf,Y.G^[L]);
    If Bf.First=Nil Then GeomCopy(X.G^[K],R)
     Else
    Begin
     ClipOutside:=True;
     ClipToPolys(X.G^[K],Bf,R);
     ClipOutside:=False;
    End;
    If FromInput Then Emit(R,X.FA^[K],Nil) Else Emit(R,Nil,X.FA^[K]);
    FreeGeom(R);FreeGeom(Bf);
   End;
 End;

Begin
 LoadIn(A,'INPUT',InR,InA);
 LoadIn(A,'OVERLAY',OvR,OvA);
 Pref:=NeedStr(A,'OVERLAY_FIELDS_PREFIX');
 CollectFields(InA,LI);CollectFields(OvA,LO);
 BuildCache(InA,CI);BuildCache(OvA,CO);
 Out:=NewLayerLike(InR,OutArr);
 If Mode<>2Then
  For I:=0 to CI.N-1do
   If CI.G^[I].Cls<>0Then
    For J:=0 to CO.N-1do
     If(CO.G^[J].Cls=3)and BoxHit(CI,I,CO,J)Then Begin
      ClipOutside:=False;
      ClipToPolys(CI.G^[I],CO.G^[J],R);
      Emit(R,CI.FA^[I],CO.FA^[J]);
      FreeGeom(R);
     End;
 If Mode>=1Then Begin
  OnlyIn(CI,CO,True);
  OnlyIn(CO,CI,False);
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunDifference(A:Integer);
Var
 InR,InA,OvR,OvA:PJ;
 CI,CO:TCache;
 I,L:LongInt;
 Bf,R:TGeom;
 F,Nx:PJ;
Begin
 LoadIn(A,'INPUT',InR,InA);
 LoadIn(A,'OVERLAY',OvR,OvA);
 BuildCache(InA,CI);BuildCache(OvA,CO);
 InA^.First:=Nil;InA^.Last:=Nil;
 For I:=0 to CI.N-1do Begin
  If CI.G^[I].Cls<>0Then Begin
   InitGeom(Bf);Bf.Cls:=3;
   For L:=0 to CO.N-1do
    If(CO.G^[L].Cls=3)and BoxHit(CI,I,CO,L)Then GeomAppend(Bf,CO.G^[L]);
   If Bf.First=Nil Then GeomCopy(CI.G^[I],R)
    Else
   If CI.G^[I].Cls=3Then Overlay(2,CI.G^[I],Bf,R)
    Else
   Begin
    ClipOutside:=True;
    ClipToPolys(CI.G^[I],Bf,R);
    ClipOutside:=False;
   End;
   If R.First<>Nil Then Begin
    SetGeom(CI.FA^[I],BuildGeom(R));
    JAdd(InA,CI.FA^[I]);
   End;
   FreeGeom(R);FreeGeom(Bf);
  End;
 End;
 SaveOut(A,'OUTPUT',InR);
End;

{ ---- dissolve / agregats ---- }

{ Regroupe les entites par cle ; retourne le groupe de chaque entite et le nombre de groupes }
Function GroupFeatures(FA:PJArr;N:LongInt;Fields:String;Var Ng:LongInt):PLongs;
Var
 Grp:PLongs;
 Keys:PStrs;
 I,J,K:LongInt;
 Key:String;
 Found:Boolean;
Begin
 SplitList(Fields,';,');
 Grp:=AllocBlock((N+1)*SizeOf(LongInt));
 Keys:=AllocBlock((N+1)*SizeOf(PStr));
 Ng:=0;
 For I:=0 to N-1do Begin
  Key:='';
  For K:=1 to ListCount do Key:=Key+#1+PropText(FA^[I],ListItems[K]);
  Found:=False;
  For J:=0 to Ng-1do If Keys^[J]^=Key Then Begin Found:=True;Grp^[I]:=J;Break;End;
  If Not Found Then Begin Keys^[Ng]:=MkStr(Key);Grp^[I]:=Ng;Inc(Ng);End;
 End;
 GroupFeatures:=Grp;
End;

{ Fusionne les geometries d'un groupe : polygones dissous, autres types regroupes }
Procedure DissolveGeoms(Var Src:TGeom;Var R:TGeom);
Var
 Empty:TGeom;
Begin
 If Src.Cls=3Then Begin
  InitGeom(Empty);
  Overlay(0,Src,Empty,R);
 End
  Else
 GeomCopy(Src,R);
End;

Procedure DissolveAllInto(Root:PJ);
Var
 Arr,Fe,Nf:PJ;
 FA:PJArr;
 N,I:LongInt;
 G,All,R:TGeom;
Begin
 Arr:=LayerFeatures(Root);
 FA:=FeatureArray(Arr,N);
 If N=0Then Exit;
 InitGeom(All);
 For I:=0 to N-1do Begin
  FlattenFeature(FA^[I],G);
  If G.Cls<>0Then GeomAppend(All,G);
  FreeGeom(G);
 End;
 DissolveGeoms(All,R);
 Nf:=NewFeature(PropsClone(FA^[0]),BuildGeom(R));
 Arr^.First:=Nil;Arr^.Last:=Nil;
 JAdd(Arr,Nf);
 FreeGeom(R);FreeGeom(All);
End;

Procedure RunDissolve(A:Integer);
Var
 Root,Arr,Out,OutArr,Fe,Nf:PJ;
 FA:PJArr;
 N,I,J,Ng:LongInt;
 Grp:PLongs;
 GA:^TGeomArr;
 G,R,Part:TGeom;
 P:PPath;
 Sep:Boolean;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Sep:=NeedBool(A,'SEPARATE_DISJOINT');
 FA:=FeatureArray(Arr,N);
 Grp:=GroupFeatures(FA,N,NeedStr(A,'FIELD'),Ng);
 GA:=AllocBlock((Ng+1)*SizeOf(TGeom));
 For J:=0 to Ng-1do InitGeom(GA^[J]);
 For I:=0 to N-1do Begin
  FlattenFeature(FA^[I],G);
  If G.Cls<>0Then Begin
   If(GA^[Grp^[I]].Cls<>0)and(GA^[Grp^[I]].Cls<>G.Cls)Then Fail('Error: cannot dissolve geometries of different types');
   GeomAppend(GA^[Grp^[I]],G);
  End;
  FreeGeom(G);
 End;
 Out:=NewLayerLike(Root,OutArr);
 For J:=0 to Ng-1do Begin
  Fe:=Nil;
  For I:=0 to N-1do If Grp^[I]=J Then Begin Fe:=FA^[I];Break;End;
  DissolveGeoms(GA^[J],R);
  If Sep and(R.Cls=3)Then Begin
   P:=R.First;
   While TakePart(R,P,Part)do Begin
    JAdd(OutArr,NewFeature(PropsClone(Fe),BuildGeom(Part)));
    FreeGeom(Part);
   End;
  End
   Else
  JAdd(OutArr,NewFeature(PropsClone(Fe),BuildGeom(R)));
  FreeGeom(R);
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunAggregate(A:Integer);
Var
 Root,Arr,Out,OutArr,Nf,Pr:PJ;
 FA:PJArr;
 N,I,J,K,Ng,Cnt,M:LongInt;
 Grp:PLongs;
 GA:^TGeomArr;
 G,R:TGeom;
 Items:Array[1..40]of String;
 NI:Integer;
 Fld,Fn,Nm,Tmp,Concat:String;
 P1,P2:Integer;
 Vals:PReals;
 Sum,Mn,Mx,V,Mean,Sd:Real;
 Keys:PStrs;
 Expr:String;
 T:TVal;
 Seen:Array[1..200]of String;
 NS,Q:Integer;
 First,Last:PJ;
 Fe:PJ;
 Found:Boolean;
 Ord:PLongs;

 Function Median(Cnt:LongInt):Real;
 Var
  X,Y:LongInt;
  Tm:Real;
 Begin
  For X:=1 to Cnt-1do Begin
   Tm:=Vals^[X];Y:=X-1;
   While(Y>=0)and(Vals^[Y]>Tm)do Begin Vals^[Y+1]:=Vals^[Y];Dec(Y);End;
   Vals^[Y+1]:=Tm;
  End;
  If Odd(Cnt)Then Median:=Vals^[Cnt div 2] Else Median:=(Vals^[Cnt div 2-1]+Vals^[Cnt div 2])/2;
 End;

Begin
 LoadIn(A,'INPUT',Root,Arr);
 Expr:=NeedStr(A,'GROUP_BY');
 FA:=FeatureArray(Arr,N);
 Keys:=AllocBlock((N+1)*SizeOf(PStr));
 Grp:=AllocBlock((N+1)*SizeOf(LongInt));
 Ng:=0;
 For I:=0 to N-1do Begin
  If(Expr='')or(StrUpper(Expr)='NULL')Then Tmp:=''
   Else Begin T:=EvalOn(Expr,FA^[I],I);Tmp:=ToStr(T);End;
  Found:=False;
  For J:=0 to Ng-1do If Keys^[J]^=Tmp Then Begin Found:=True;Grp^[I]:=J;Break;End;
  If Not Found Then Begin Keys^[Ng]:=MkStr(Tmp);Grp^[I]:=Ng;Inc(Ng);End;
 End;
 SplitQuoted(NeedStr(A,'AGGREGATES'),';');
 NI:=ListCount;
 For K:=1 to NI do Items[K]:=ListItems[K];
 GA:=AllocBlock((Ng+1)*SizeOf(TGeom));
 For J:=0 to Ng-1do InitGeom(GA^[J]);
 For I:=0 to N-1do Begin
  FlattenFeature(FA^[I],G);
  If G.Cls<>0Then Begin
   If(GA^[Grp^[I]].Cls<>0)and(GA^[Grp^[I]].Cls<>G.Cls)Then Fail('Error: cannot aggregate geometries of different types');
   GeomAppend(GA^[Grp^[I]],G);
  End;
  FreeGeom(G);
 End;
 Vals:=AllocBlock((N+1)*SizeOf(Real));
 Out:=NewLayerLike(Root,OutArr);
 For J:=0 to Ng-1do Begin
  Pr:=NewJ(5);
  For K:=1 to NI do Begin
   P1:=Pos(':',Items[K]);
   If P1=0Then Fail('Error: AGGREGATES items must look like field:function:name');
   Fld:=Copy(Items[K],1,P1-1);
   If(Length(Fld)>=2)and(Fld[1]='"')and(Fld[Length(Fld)]='"')Then Fld:=Copy(Fld,2,Length(Fld)-2);
   Tmp:=Copy(Items[K],P1+1,255);
   P2:=Pos(':',Tmp);
   If P2=0Then Begin Fn:=StrUpper(Tmp);Nm:=Fld;End
          Else Begin Fn:=StrUpper(Copy(Tmp,1,P2-1));Nm:=Copy(Tmp,P2+1,255);End;
   Cnt:=0;Sum:=0;M:=0;Concat:='';NS:=0;First:=Nil;Last:=Nil;Mn:=1E300;Mx:=-1E300;
   For I:=0 to N-1do
    If Grp^[I]=J Then Begin
     Fe:=GetProp(FA^[I],Fld);
     If First=Nil Then First:=Fe;
     Last:=Fe;
     If(Fe<>Nil)and(Fe^.Kind<>0)Then Begin
      Inc(Cnt);
      If PropReal(FA^[I],Fld,V)Then Begin
       Vals^[M]:=V;Inc(M);Sum:=Sum+V;
       If V<Mn Then Mn:=V;
       If V>Mx Then Mx:=V;
      End;
      Tmp:=PropText(FA^[I],Fld);
      Found:=False;
      For Q:=1 to NS do If Seen[Q]=Tmp Then Found:=True;
      If(Not Found)and(NS<200)Then Begin Inc(NS);Seen[NS]:=Tmp;End;
      If Concat<>''Then Concat:=Concat+',';
      If Length(Concat)<200Then Concat:=Concat+Tmp;
     End;
    End;
   If Fn='COUNT'Then JAddKV(Pr,Nm,JNum(Cnt)) Else
   If Fn='COUNT_DISTINCT'Then JAddKV(Pr,Nm,JNum(NS)) Else
   If Fn='FIRST_VALUE'Then Begin
    If First=Nil Then JAddKV(Pr,Nm,NewJ(0)) Else JAddKV(Pr,Nm,JClone(First));
   End Else
   If Fn='LAST_VALUE'Then Begin
    If Last=Nil Then JAddKV(Pr,Nm,NewJ(0)) Else JAddKV(Pr,Nm,JClone(Last));
   End Else
   If Fn='CONCATENATE'Then JAddKV(Pr,Nm,JTextEsc(Concat)) Else
   If M=0Then JAddKV(Pr,Nm,NewJ(0)) Else
   If Fn='SUM'Then JAddKV(Pr,Nm,JNum(Sum)) Else
   If Fn='MEAN'Then JAddKV(Pr,Nm,JNum(Sum/M)) Else
   If Fn='MIN'Then JAddKV(Pr,Nm,JNum(Mn)) Else
   If Fn='MAX'Then JAddKV(Pr,Nm,JNum(Mx)) Else
   If Fn='RANGE'Then JAddKV(Pr,Nm,JNum(Mx-Mn)) Else
   If Fn='MEDIAN'Then JAddKV(Pr,Nm,JNum(Median(M))) Else
   If(Fn='STDEV')or(Fn='STDEV_SAMP')or(Fn='STDEV_POP')Then Begin
    Mean:=Sum/M;Sd:=0;
    For I:=0 to M-1do Sd:=Sd+Sqr(Vals^[I]-Mean);
    If Fn='STDEV_POP'Then JAddKV(Pr,Nm,JNum(Sqrt(Sd/M)))
     Else
    If M>1Then JAddKV(Pr,Nm,JNum(Sqrt(Sd/(M-1)))) Else JAddKV(Pr,Nm,NewJ(0));
   End
    Else
   Fail('Error: unknown aggregate function '+Fn);
  End;
  DissolveGeoms(GA^[J],R);
  JAdd(OutArr,NewFeature(Pr,BuildGeom(R)));
  FreeGeom(R);
 End;
 SaveOut(A,'OUTPUT',Out);
End;

{ ---- decoupage par des lignes, polygonize ---- }

Procedure SplitLineByLines(Var G,Lines:TGeom;Var R:TGeom);
Var
 P,Q:PPath;
 I,J,K,N,M,Cnt:LongInt;
 Ts:PReals;
 Ax,Ay,Bx,By,Dx,Dy,Rx,Ry,Den,T,U,Tmp:Real;
 Buf:PPts;
 Pa:PPath;
 Cap:LongInt;
Begin
 InitGeom(R);R.Cls:=2;
 Cap:=EdgeCount(Lines)+4;
 Ts:=AllocBlock(Cap*SizeOf(Real));
 P:=G.First;
 While P<>Nil do Begin
  Buf:=AllocBlock((P^.N*3+8)*SizeOf(TPt));
  Cnt:=0;
  Buf^[0]:=P^.Pts^[0];Cnt:=1;
  For I:=0 to P^.N-2do Begin
   Ax:=P^.Pts^[I].X;Ay:=P^.Pts^[I].Y;Bx:=P^.Pts^[I+1].X;By:=P^.Pts^[I+1].Y;
   Dx:=Bx-Ax;Dy:=By-Ay;
   N:=0;
   Q:=Lines.First;
   While Q<>Nil do Begin
    For J:=0 to Q^.N-2do Begin
     Rx:=Q^.Pts^[J+1].X-Q^.Pts^[J].X;Ry:=Q^.Pts^[J+1].Y-Q^.Pts^[J].Y;
     Den:=Dx*Ry-Dy*Rx;
     If Abs(Den)>1E-14*Sqrt(Dx*Dx+Dy*Dy)*Sqrt(Rx*Rx+Ry*Ry)Then Begin
      T:=((Q^.Pts^[J].X-Ax)*Ry-(Q^.Pts^[J].Y-Ay)*Rx)/Den;
      U:=((Q^.Pts^[J].X-Ax)*Dy-(Q^.Pts^[J].Y-Ay)*Dx)/Den;
      If(T>1E-12)and(T<1-1E-12)and(U>=0)and(U<=1)and(N<Cap)Then Begin Ts^[N]:=T;Inc(N);End;
     End;
    End;
    Q:=Q^.Next;
   End;
   For K:=1 to N-1do Begin
    Tmp:=Ts^[K];M:=K-1;
    While(M>=0)and(Ts^[M]>Tmp)do Begin Ts^[M+1]:=Ts^[M];Dec(M);End;
    Ts^[M+1]:=Tmp;
   End;
   For K:=0 to N-1do Begin
    Buf^[Cnt].X:=Ax+Ts^[K]*Dx;Buf^[Cnt].Y:=Ay+Ts^[K]*Dy;Inc(Cnt);
    Pa:=NewPath(R,Cnt,0);
    Move(Buf^,Pa^.Pts^,Cnt*SizeOf(TPt));
    Pa^.N:=Cnt;
    Buf^[0]:=Buf^[Cnt-1];Cnt:=1;
   End;
   Buf^[Cnt]:=P^.Pts^[I+1];Inc(Cnt);
  End;
  If Cnt>=2Then Begin
   Pa:=NewPath(R,Cnt,0);
   Move(Buf^,Pa^.Pts^,Cnt*SizeOf(TPt));
   Pa^.N:=Cnt;
  End;
  FreeMem(Buf,(P^.N*3+8)*SizeOf(TPt));
  P:=P^.Next;
 End;
 FreeMem(Ts,Cap*SizeOf(Real));
End;

Procedure RunSplitWithLines(A:Integer);
Var
 InR,InA,LnR,LnA,Out,OutArr:PJ;
 CI,CL:TCache;
 I,J:LongInt;
 G,L,Faces,Face,R:TGeom;
 P:PPath;
 X,Y:Real;
 Part:TGeom;
Begin
 LoadIn(A,'INPUT',InR,InA);
 LoadIn(A,'LINES',LnR,LnA);
 BuildCache(InA,CI);BuildCache(LnA,CL);
 Out:=NewLayerLike(InR,OutArr);
 For I:=0 to CI.N-1do Begin
  If CI.G^[I].Cls=0Then JAdd(OutArr,NewFeature(PropsClone(CI.FA^[I]),Nil))
   Else
  Begin
   InitGeom(L);L.Cls:=2;
   For J:=0 to CL.N-1do
    If(CL.G^[J].Cls=2)and BoxHit(CI,I,CL,J)Then GeomAppend(L,CL.G^[J]);
   If CI.G^[I].Cls=2Then Begin
    SplitLineByLines(CI.G^[I],L,R);
    JAdd(OutArr,NewFeature(PropsClone(CI.FA^[I]),BuildLines(R)));
    FreeGeom(R);
   End
    Else
   If(CI.G^[I].Cls=3)and(L.First<>Nil)Then Begin
    P:=CI.G^[I].First;
    While P<>Nil do Begin CopyPath(L,P,0);P:=P^.Next;End;
    PolygonizeLines(L,Faces);
    P:=Faces.First;
    While TakePart(Faces,P,Face)do Begin
     PointOnSurface(Face,X,Y);
     If PtInPolys(CI.G^[I],X,Y,0)=1Then
      JAdd(OutArr,NewFeature(PropsClone(CI.FA^[I]),BuildPolygons(Face)));
     FreeGeom(Face);
    End;
    FreeGeom(Faces);
   End
    Else
   JAdd(OutArr,NewFeature(PropsClone(CI.FA^[I]),BuildGeom(CI.G^[I])));
   FreeGeom(L);
  End;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunPolygonizeLines(A:Integer);
Var
 Root,Arr,Out,OutArr,F:PJ;
 G,L,Faces,Face:TGeom;
 P:PPath;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 InitGeom(L);L.Cls:=2;
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  If G.Cls<>0Then Begin
   If G.Cls<>2Then Fail('Error: the input layer must contain lines');
   GeomAppend(L,G);
  End;
  FreeGeom(G);
  F:=F^.Next;
 End;
 Out:=NewLayerLike(Root,OutArr);
 PolygonizeLines(L,Faces);
 P:=Faces.First;
 While TakePart(Faces,P,Face)do Begin
  JAdd(OutArr,NewFeature(Nil,BuildPolygons(Face)));
  FreeGeom(Face);
 End;
 SaveOut(A,'OUTPUT',Out);
End;

{ ---- comptages et jointures spatiales ---- }

Procedure RunCountPoints(A:Integer);
Var
 PoR,PoA,PtR,PtA:PJ;
 CP,CT:TCache;
 I,J,K:LongInt;
 Cnt,W:Real;
 Fld,Cls,Wf:String;
 Seen:Array[1..500]of String;
 NS,Q:Integer;
 P:PPath;
 Found:Boolean;
Begin
 LoadIn(A,'POLYGONS',PoR,PoA);
 LoadIn(A,'POINTS',PtR,PtA);
 Fld:=NeedStr(A,'FIELD');
 Cls:=NeedStr(A,'CLASSFIELD');
 Wf:=NeedStr(A,'WEIGHT');
 BuildCache(PoA,CP);BuildCache(PtA,CT);
 For I:=0 to CP.N-1do Begin
  Cnt:=0;NS:=0;
  If CP.G^[I].Cls=3Then
   For J:=0 to CT.N-1do
    If(CT.G^[J].Cls=1)and BoxHit(CP,I,CT,J)Then Begin
     P:=CT.G^[J].First;
     While P<>Nil do Begin
      If PtInPolys(CP.G^[I],P^.Pts^[0].X,P^.Pts^[0].Y,SnapQ)=1Then Begin
       If Cls<>''Then Begin
        Found:=False;
        For Q:=1 to NS do If Seen[Q]=PropText(CT.FA^[J],Cls)Then Found:=True;
        If(Not Found)and(NS<500)Then Begin Inc(NS);Seen[NS]:=PropText(CT.FA^[J],Cls);Cnt:=Cnt+1;End;
       End
        Else
       If Wf<>''Then Begin
        If PropReal(CT.FA^[J],Wf,W)Then Cnt:=Cnt+W;
       End
        Else
       Cnt:=Cnt+1;
      End;
      P:=P^.Next;
     End;
    End;
  PutProp(CP.FA^[I],Fld,JNum(Cnt));
 End;
 SaveOut(A,'OUTPUT',PoR);
End;

{ Predicats : liste d'entiers dans Preds ; Vrai si un predicat est satisfait }
Function MatchAny(Var Preds:Array of Integer;NP:Integer;Var A,B:TGeom):Boolean;
Var
 K:Integer;
Begin
 MatchAny:=False;
 For K:=0 to NP-1do
  If GeomPredicate(Preds[K],A,B)Then Begin MatchAny:=True;Exit;End;
End;

Procedure ParsePredicates(S:String;Var Preds:Array of Integer;Var NP:Integer);
Var
 K,E:Integer;
 V:Integer;
Begin
 SplitList(S,';, ');
 NP:=0;
 For K:=1 to ListCount do Begin
  Val(ListItems[K],V,E);
  If(E<>0)or(V<0)or(V>7)Then Fail('Error: PREDICATE values must be between 0 and 7');
  If NP<=High(Preds)Then Begin Preds[NP]:=V;Inc(NP);End;
 End;
 If NP=0Then Fail('Error: PREDICATE is empty');
End;

Function HasPred(Var Preds:Array of Integer;NP,V:Integer):Boolean;
Var
 K:Integer;
Begin
 HasPred:=False;
 For K:=0 to NP-1do If Preds[K]=V Then HasPred:=True;
End;

Procedure RunExtractByLocation(A:Integer);
Var
 InR,InA,OvR,OvA:PJ;
 CI,CO:TCache;
 Preds:Array[0..7]of Integer;
 NP:Integer;
 I,J:LongInt;
 Hit:Boolean;
Begin
 LoadIn(A,'INPUT',InR,InA);
 LoadIn(A,'INTERSECT',OvR,OvA);
 ParsePredicates(NeedStr(A,'PREDICATE'),Preds,NP);
 BuildCache(InA,CI);BuildCache(OvA,CO);
 InA^.First:=Nil;InA^.Last:=Nil;
 For I:=0 to CI.N-1do Begin
  Hit:=False;
  For J:=0 to CO.N-1do Begin
   If(CI.G^[I].Cls<>0)and(CO.G^[J].Cls<>0)Then Begin
    { le predicat "disjoint" ne depend pas des boites }
    If(BoxHit(CI,I,CO,J)or HasPred(Preds,NP,2))and MatchAny(Preds,NP,CI.G^[I],CO.G^[J])Then Begin Hit:=True;Break;End;
   End;
  End;
  If Hit Then JAdd(InA,CI.FA^[I]);
 End;
 SaveOut(A,'OUTPUT',InR);
End;

{ Champs de la couche jointe a copier (JOIN_FIELDS : liste ou vide = tous) }
Procedure SelectFields(Spec:String;Var All,Sel:TNameList);
Var
 K:Integer;
Begin
 Sel.N:=0;
 If Spec=''Then Begin Sel:=All;Exit;End;
 SplitList(Spec,';,');
 For K:=1 to ListCount do
  If InList(All,ListItems[K])Then Begin
   Inc(Sel.N);
   Sel.Names[Sel.N]:=ListItems[K];
  End
   Else
  Fail('Error: unknown field '+ListItems[K]);
End;

{ Mode 0 : joinattributesbylocation, 1 : joinbylocationsummary }
Procedure RunJoinByLocation(A:Integer;Summary:Boolean);
Var
 InR,InA,JnR,JnA,Out,OutArr,Nf,Npj,Fe:PJ;
 CI,CJ:TCache;
 LI,LJ,LS:TNameList;
 Preds:Array[0..7]of Integer;
 NP,Method,Ns,K,S:Integer;
 Sums:Array[0..19]of Integer;
 I,J,Cnt,Best:LongInt;
 Discard:Boolean;
 Pref:String;
 Matches:PLongs;
 Ov,BestOv:Real;
 R:TGeom;
 Vals:PReals;
 M,Q,X,Y:LongInt;
 V,Sum,Mn,Mx,Mean,Sd,Tm:Real;
 Nm,Suffix,Tmp:String;
 Seen:Array[1..100]of String;
 NS2:Integer;
 Found:Boolean;
 Cn:LongInt;
 LenMin,LenMax,LenSum:Real;
 Empty,Filled:LongInt;
 Cp:String;

 Function Quant(Cnt:LongInt;Fr:Real):Real;
 Var
  Pos,Fl:Real;
  Lo:LongInt;
 Begin
  Pos:=(Cnt-1)*Fr;
  Lo:=Trunc(Pos);
  If Lo>=Cnt-1Then Quant:=Vals^[Cnt-1]
              Else Quant:=Vals^[Lo]+(Pos-Lo)*(Vals^[Lo+1]-Vals^[Lo]);
 End;

Begin
 LoadIn(A,'INPUT',InR,InA);
 LoadIn(A,'JOIN',JnR,JnA);
 ParsePredicates(NeedStr(A,'PREDICATE'),Preds,NP);
 Discard:=NeedBool(A,'DISCARD_NONMATCHING');
 Pref:=NeedStr(A,'PREFIX');
 CollectFields(InA,LI);CollectFields(JnA,LJ);
 SelectFields(NeedStr(A,'JOIN_FIELDS'),LJ,LS);
 BuildCache(InA,CI);BuildCache(JnA,CJ);
 Method:=0;Ns:=0;
 If Summary Then Begin
  SplitList(NeedStr(A,'SUMMARIES'),';, ');
  For K:=1 to ListCount do Begin
   Val(ListItems[K],Sums[Ns],S);
   If(S<>0)or(Sums[Ns]<0)or(Sums[Ns]>18)Then Fail('Error: SUMMARIES values must be between 0 and 18');
   Inc(Ns);
  End;
  If Ns=0Then Fail('Error: SUMMARIES is empty');
 End
  Else
 Method:=Round(NeedReal(A,'METHOD'));
 Matches:=AllocBlock((CJ.N+1)*SizeOf(LongInt));
 Vals:=AllocBlock((CJ.N+1)*SizeOf(Real));
 Out:=NewLayerLike(InR,OutArr);
 For I:=0 to CI.N-1do Begin
  Cnt:=0;
  If CI.G^[I].Cls<>0Then
   For J:=0 to CJ.N-1do
    If CJ.G^[J].Cls<>0Then
     If(BoxHit(CI,I,CJ,J)or HasPred(Preds,NP,2))and MatchAny(Preds,NP,CI.G^[I],CJ.G^[J])Then Begin
      Matches^[Cnt]:=J;Inc(Cnt);
     End;
  If Cnt=0Then Begin
   If Not Discard Then Begin
    If Summary Then Begin
     Npj:=PropsClone(CI.FA^[I]);
     For K:=1 to LS.N do
      For S:=0 to Ns-1do Begin
       Case Sums[S]of
        0:Suffix:='count';1:Suffix:='unique';2:Suffix:='min';3:Suffix:='max';4:Suffix:='range';5:Suffix:='sum';
        6:Suffix:='mean';7:Suffix:='median';8:Suffix:='stdev';9:Suffix:='minority';10:Suffix:='majority';
        11:Suffix:='q1';12:Suffix:='q3';13:Suffix:='iqr';14:Suffix:='empty';15:Suffix:='filled';
        16:Suffix:='min_length';17:Suffix:='max_length';Else Suffix:='mean_length';
       End;
       JAddKV(Npj,Pref+LS.Names[K]+'_'+Suffix,NewJ(0));
      End;
     JAdd(OutArr,NewFeature(Npj,JClone(JFind(CI.FA^[I],'geometry'))));
    End
     Else
    JAdd(OutArr,NewFeature(JoinProps(CI.FA^[I],LI,Nil,LS,Pref),JClone(JFind(CI.FA^[I],'geometry'))));
   End;
  End
   Else
  If Summary Then Begin
   Npj:=PropsClone(CI.FA^[I]);
   For K:=1 to LS.N do Begin
    M:=0;Sum:=0;Mn:=1E300;Mx:=-1E300;NS2:=0;Empty:=0;Filled:=0;LenMin:=1E300;LenMax:=-1;LenSum:=0;Cn:=0;
    For Q:=0 to Cnt-1do Begin
     Fe:=GetProp(CJ.FA^[Matches^[Q]],LS.Names[K]);
     If(Fe=Nil)or(Fe^.Kind=0)or((Fe^.Kind=3)and(NodeText(Fe)=''))Then Inc(Empty) Else Inc(Filled);
     If(Fe<>Nil)and(Fe^.Kind<>0)Then Begin
      Inc(Cn);
      Tmp:=NodeText(Fe);
      If Length(Tmp)<LenMin Then LenMin:=Length(Tmp);
      If Length(Tmp)>LenMax Then LenMax:=Length(Tmp);
      LenSum:=LenSum+Length(Tmp);
      If PropReal(CJ.FA^[Matches^[Q]],LS.Names[K],V)Then Begin
       Vals^[M]:=V;Inc(M);Sum:=Sum+V;
       If V<Mn Then Mn:=V;
       If V>Mx Then Mx:=V;
      End;
      Found:=False;
      For X:=1 to NS2 do If Seen[X]=Tmp Then Found:=True;
      If(Not Found)and(NS2<100)Then Begin Inc(NS2);Seen[NS2]:=Tmp;End;
     End;
    End;
    { tri des valeurs numeriques pour les quantiles }
    For X:=1 to M-1do Begin
     Tm:=Vals^[X];Y:=X-1;
     While(Y>=0)and(Vals^[Y]>Tm)do Begin Vals^[Y+1]:=Vals^[Y];Dec(Y);End;
     Vals^[Y+1]:=Tm;
    End;
    For S:=0 to Ns-1do Begin
     Case Sums[S]of
      0:Suffix:='count';1:Suffix:='unique';2:Suffix:='min';3:Suffix:='max';4:Suffix:='range';5:Suffix:='sum';
      6:Suffix:='mean';7:Suffix:='median';8:Suffix:='stdev';9:Suffix:='minority';10:Suffix:='majority';
      11:Suffix:='q1';12:Suffix:='q3';13:Suffix:='iqr';14:Suffix:='empty';15:Suffix:='filled';
      16:Suffix:='min_length';17:Suffix:='max_length';Else Suffix:='mean_length';
     End;
     Nm:=Pref+LS.Names[K]+'_'+Suffix;
     Case Sums[S]of
      0:JAddKV(Npj,Nm,JNum(Cn));
      1:JAddKV(Npj,Nm,JNum(NS2));
      14:JAddKV(Npj,Nm,JNum(Empty));
      15:JAddKV(Npj,Nm,JNum(Filled));
      16:If Cn>0Then JAddKV(Npj,Nm,JNum(LenMin)) Else JAddKV(Npj,Nm,NewJ(0));
      17:If Cn>0Then JAddKV(Npj,Nm,JNum(LenMax)) Else JAddKV(Npj,Nm,NewJ(0));
      18:If Cn>0Then JAddKV(Npj,Nm,JNum(LenSum/Cn)) Else JAddKV(Npj,Nm,NewJ(0));
      Else
      If M=0Then JAddKV(Npj,Nm,NewJ(0))
       Else
      Case Sums[S]of
       2:JAddKV(Npj,Nm,JNum(Mn));
       3:JAddKV(Npj,Nm,JNum(Mx));
       4:JAddKV(Npj,Nm,JNum(Mx-Mn));
       5:JAddKV(Npj,Nm,JNum(Sum));
       6:JAddKV(Npj,Nm,JNum(Sum/M));
       7:JAddKV(Npj,Nm,JNum(Quant(M,0.5)));
       8:Begin
        Mean:=Sum/M;Sd:=0;
        For X:=0 to M-1do Sd:=Sd+Sqr(Vals^[X]-Mean);
        If M>1Then JAddKV(Npj,Nm,JNum(Sqrt(Sd/(M-1)))) Else JAddKV(Npj,Nm,NewJ(0));
       End;
       9,10:Begin
        { valeur la moins / la plus frequente }
        Mean:=Vals^[0];Best:=0;Y:=0;
        X:=0;
        While X<M do Begin
         Y:=X;
         While(Y<M)and(Vals^[Y]=Vals^[X])do Inc(Y);
         If(X=0)or((Sums[S]=10)and(Y-X>Best))or((Sums[S]=9)and(Y-X<Best))Then Begin Best:=Y-X;Mean:=Vals^[X];End;
         X:=Y;
        End;
        JAddKV(Npj,Nm,JNum(Mean));
       End;
       11:JAddKV(Npj,Nm,JNum(Quant(M,0.25)));
       12:JAddKV(Npj,Nm,JNum(Quant(M,0.75)));
       13:JAddKV(Npj,Nm,JNum(Quant(M,0.75)-Quant(M,0.25)));
      End;
     End;
    End;
   End;
   JAdd(OutArr,NewFeature(Npj,JClone(JFind(CI.FA^[I],'geometry'))));
  End
   Else
  Begin
   If Method=2Then Begin
    { plus grand recouvrement }
    Best:=Matches^[0];BestOv:=-1;
    If CI.G^[I].Cls=3Then
     For Q:=0 to Cnt-1do Begin
      If CJ.G^[Matches^[Q]].Cls=3Then Ov:=OverlapArea(CI.G^[I],CJ.G^[Matches^[Q]]) Else Ov:=0;
      If Ov>BestOv Then Begin BestOv:=Ov;Best:=Matches^[Q];End;
     End
      Else
     If CI.G^[I].Cls=2Then
      For Q:=0 to Cnt-1do Begin
       If CJ.G^[Matches^[Q]].Cls=3Then Begin
        ClipOutside:=False;
        ClipToPolys(CI.G^[I],CJ.G^[Matches^[Q]],R);
        Ov:=GeomLength(R);FreeGeom(R);
       End
        Else
       Ov:=0;
       If Ov>BestOv Then Begin BestOv:=Ov;Best:=Matches^[Q];End;
      End;
    JAdd(OutArr,NewFeature(JoinProps(CI.FA^[I],LI,CJ.FA^[Best],LS,Pref),JClone(JFind(CI.FA^[I],'geometry'))));
   End
    Else
   Begin
    If Method=1Then Cn:=1 Else Cn:=Cnt;
    For Q:=0 to Cn-1do
     JAdd(OutArr,NewFeature(JoinProps(CI.FA^[I],LI,CJ.FA^[Matches^[Q]],LS,Pref),JClone(JFind(CI.FA^[I],'geometry'))));
   End;
  End;
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunJoinAttributesTable(A:Integer);
Var
 InR,InA,TbR,TbA,Out,OutArr:PJ;
 LI,LT,LS:TNameList;
 FA,FB:PJArr;
 NA,NB,I,J,Cnt:LongInt;
 F1,F2,Key:String;
 Method:Integer;
 Discard:Boolean;
 Pref:String;
 Match:PLongs;
 Ok:Boolean;
Begin
 LoadIn(A,'INPUT',InR,InA);
 TbR:=LoadTable(NeedStr(A,'INPUT_2'));
 TbA:=LayerFeatures(TbR);
 F1:=NeedStr(A,'FIELD');F2:=NeedStr(A,'FIELD_2');
 Method:=Round(NeedReal(A,'METHOD'));
 Discard:=NeedBool(A,'DISCARD_NONMATCHING');
 Pref:=NeedStr(A,'PREFIX');
 CollectFields(InA,LI);CollectFields(TbA,LT);
 SelectFields(NeedStr(A,'FIELDS_TO_COPY'),LT,LS);
 FA:=FeatureArray(InA,NA);FB:=FeatureArray(TbA,NB);
 Match:=AllocBlock((NB+1)*SizeOf(LongInt));
 Out:=NewLayerLike(InR,OutArr);
 For I:=0 to NA-1do Begin
  Key:=PropText(FA^[I],F1);
  Cnt:=0;
  If(GetProp(FA^[I],F1)<>Nil)and(GetProp(FA^[I],F1)^.Kind<>0)Then
   For J:=0 to NB-1do
    If(GetProp(FB^[J],F2)<>Nil)and(GetProp(FB^[J],F2)^.Kind<>0)and(PropText(FB^[J],F2)=Key)Then Begin
     Match^[Cnt]:=J;Inc(Cnt);
    End;
  If Cnt=0Then Begin
   If Not Discard Then JAdd(OutArr,NewFeature(JoinProps(FA^[I],LI,Nil,LS,Pref),JClone(JFind(FA^[I],'geometry'))));
  End
   Else
  If Method=1Then
   JAdd(OutArr,NewFeature(JoinProps(FA^[I],LI,FB^[Match^[0]],LS,Pref),JClone(JFind(FA^[I],'geometry'))))
   Else
  For J:=0 to Cnt-1do
   JAdd(OutArr,NewFeature(JoinProps(FA^[I],LI,FB^[Match^[J]],LS,Pref),JClone(JFind(FA^[I],'geometry'))));
 End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunLineIntersections(A:Integer);
Var
 InR,InA,LnR,LnA,Out,OutArr,Nf:PJ;
 CI,CL:TCache;
 LI,LL:TNameList;
 I,J,K,M:LongInt;
 P,Q:PPath;
 Pref:String;
 Rx,Ry,Sx,Sy,Den,T,U,X,Y:Real;
 PrevX:Array[1..64]of Real;
 PrevY:Array[1..64]of Real;
 NPrev:Integer;
 Dup:Boolean;
 S:TGeom;
 W:Integer;
Begin
 LoadIn(A,'INPUT',InR,InA);
 LoadIn(A,'INTERSECT',LnR,LnA);
 Pref:=NeedStr(A,'INTERSECT_FIELDS_PREFIX');
 CollectFields(InA,LI);CollectFields(LnA,LL);
 BuildCache(InA,CI);BuildCache(LnA,CL);
 Out:=NewLayerLike(InR,OutArr);
 For I:=0 to CI.N-1do
  If CI.G^[I].Cls=2Then
   For J:=0 to CL.N-1do
    If(CL.G^[J].Cls=2)and BoxHit(CI,I,CL,J)Then Begin
     NPrev:=0;
     P:=CI.G^[I].First;
     While P<>Nil do Begin
      For K:=0 to P^.N-2do Begin
       Q:=CL.G^[J].First;
       While Q<>Nil do Begin
        For M:=0 to Q^.N-2do Begin
         Rx:=P^.Pts^[K+1].X-P^.Pts^[K].X;Ry:=P^.Pts^[K+1].Y-P^.Pts^[K].Y;
         Sx:=Q^.Pts^[M+1].X-Q^.Pts^[M].X;Sy:=Q^.Pts^[M+1].Y-Q^.Pts^[M].Y;
         Den:=Rx*Sy-Ry*Sx;
         If Abs(Den)>1E-14*Sqrt(Rx*Rx+Ry*Ry)*Sqrt(Sx*Sx+Sy*Sy)Then Begin
          T:=((Q^.Pts^[M].X-P^.Pts^[K].X)*Sy-(Q^.Pts^[M].Y-P^.Pts^[K].Y)*Sx)/Den;
          U:=((Q^.Pts^[M].X-P^.Pts^[K].X)*Ry-(Q^.Pts^[M].Y-P^.Pts^[K].Y)*Rx)/Den;
          If(T>=0)and(T<=1)and(U>=0)and(U<=1)Then Begin
           X:=P^.Pts^[K].X+T*Rx;Y:=P^.Pts^[K].Y+T*Ry;
           Dup:=False;
           For W:=1 to NPrev do If(Abs(PrevX[W]-X)<1E-9)and(Abs(PrevY[W]-Y)<1E-9)Then Dup:=True;
           If Not Dup Then Begin
            If NPrev<64Then Begin Inc(NPrev);PrevX[NPrev]:=X;PrevY[NPrev]:=Y;End;
            PointGeom(S,X,Y);
            JAdd(OutArr,NewFeature(JoinProps(CI.FA^[I],LI,CL.FA^[J],LL,Pref),BuildPoints(S)));
            FreeGeom(S);
           End;
          End;
         End;
        End;
        Q:=Q^.Next;
       End;
      End;
      P:=P^.Next;
     End;
    End;
 SaveOut(A,'OUTPUT',Out);
End;

Procedure RunVectorOverlaps(A:Integer);
Var
 InR,InA:PJ;
 Layers:Array[1..8]of TCache;
 Names:Array[1..8]of String;
 NL,K:Integer;
 CI:TCache;
 I,J:LongInt;
 Bf,R:TGeom;
 Ar,Ov:Real;
 LR,LA:PJ;
Begin
 LoadIn(A,'INPUT',InR,InA);
 SplitList(NeedStr(A,'LAYERS'),';');
 NL:=ListCount;
 If(NL<1)or(NL>8)Then Fail('Error: LAYERS must list between 1 and 8 files separated by ;');
 For K:=1 to NL do Begin
  Names[K]:=BaseName(ListItems[K]);
  LR:=LoadLayer(ListItems[K]);
  BuildCache(LayerFeatures(LR),Layers[K]);
 End;
 BuildCache(InA,CI);
 For I:=0 to CI.N-1do Begin
  If CI.G^[I].Cls<>3Then Fail('Error: the input layer must contain polygons');
  Ar:=GeomArea(CI.G^[I]);
  For K:=1 to NL do Begin
   InitGeom(Bf);Bf.Cls:=3;
   For J:=0 to Layers[K].N-1do
    If(Layers[K].G^[J].Cls=3)and BoxHit(CI,I,Layers[K],J)Then GeomAppend(Bf,Layers[K].G^[J]);
   Ov:=0;
   If Bf.First<>Nil Then Begin
    Overlay(1,CI.G^[I],Bf,R);
    Ov:=GeomArea(R);
    FreeGeom(R);
   End;
   FreeGeom(Bf);
   PutProp(CI.FA^[I],Names[K]+'_area',JNum(Ov));
   If Ar>0Then PutProp(CI.FA^[I],Names[K]+'_pc',JNum(100*Ov/Ar))
          Else PutProp(CI.FA^[I],Names[K]+'_pc',NewJ(0));
  End;
 End;
 SaveOut(A,'OUTPUT',InR);
End;

Procedure RunSumLineLengths(A:Integer);
Var
 PoR,PoA,LnR,LnA:PJ;
 CP,CL:TCache;
 I,J:LongInt;
 R:TGeom;
 Len,Cnt:Real;
Begin
 LoadIn(A,'POLYGONS',PoR,PoA);
 LoadIn(A,'LINES',LnR,LnA);
 BuildCache(PoA,CP);BuildCache(LnA,CL);
 For I:=0 to CP.N-1do Begin
  Len:=0;Cnt:=0;
  If CP.G^[I].Cls=3Then
   For J:=0 to CL.N-1do
    If(CL.G^[J].Cls=2)and BoxHit(CP,I,CL,J)Then Begin
     ClipOutside:=False;
     ClipToPolys(CL.G^[J],CP.G^[I],R);
     If R.First<>Nil Then Begin Len:=Len+GeomLength(R);Cnt:=Cnt+1;End;
     FreeGeom(R);
    End;
  PutProp(CP.FA^[I],NeedStr(A,'LEN_FIELD'),JNum(Len));
  PutProp(CP.FA^[I],NeedStr(A,'COUNT_FIELD'),JNum(Cnt));
 End;
 SaveOut(A,'OUTPUT',PoR);
End;

{ ------------------------------------------------------------------ }
{ Algorithmes : rasters natifs, export, algorithmes non pris en charge }
{ ------------------------------------------------------------------ }

Procedure RunCreateConstantRaster(A:Integer);
Var
 O:TRaster;
 X1,X2,Y1,Y2,Ps,V:Real;
 Nc,Nr,I:LongInt;
 Out:String;
Begin
 ParseExtent(NeedStr(A,'EXTENT'),X1,X2,Y1,Y2);
 Ps:=NeedReal(A,'PIXEL_SIZE');
 V:=NeedReal(A,'NUMBER');
 Out:=NeedStr(A,'OUTPUT');
 If Ps<=0Then Fail('Error: PIXEL_SIZE must be greater than 0');
 Nc:=CeilL((X2-X1)/Ps-1E-9);
 Nr:=CeilL((Y2-Y1)/Ps-1E-9);
 NewRaster(O,Nc,Nr,X1,Y2-Nr*Ps,Ps,-9999);
 For I:=0 to Nc*Nr-1do O.Data^[I]:=V;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

Procedure RunAlignRasters(A:Integer);
Var
 Ref,R,O:TRaster;
 Dir,Name:String;
 Mode,K,I,J:LongInt;
 X,Y,V:Real;
Begin
 ReadRaster(NeedStr(A,'REFERENCE_LAYER'),Ref);
 Mode:=Round(NeedReal(A,'RESAMPLE_METHOD'));
 If(Mode<>0)and(Mode<>1)Then Fail('Error: RESAMPLE_METHOD must be 0 (nearest) or 1 (bilinear)');
 SplitList(NeedStr(A,'LAYERS'),';');
 Dir:=NeedStr(A,'OUTPUT');
 If Dir=''Then Fail('Error: OUTPUT must be a directory');
 If(Dir[Length(Dir)]='/')or(Dir[Length(Dir)]='\')Then Dir:=Copy(Dir,1,Length(Dir)-1);
 {$I-}
 MkDir(Dir);
 If IOResult<>0Then Begin End;
 {$I+}
 For K:=1 to ListCount do Begin
  ReadRaster(ListItems[K],R);
  NewRaster(O,Ref.NC,Ref.NR,Ref.XLL,Ref.YLL,Ref.Cell,R.NoData);
  For I:=0 to Ref.NR-1do
   For J:=0 to Ref.NC-1do Begin
    X:=Ref.XLL+(J+0.5)*Ref.Cell;
    Y:=RasterTop(Ref)-(I+0.5)*Ref.Cell;
    If SampleRaster(R,X,Y,Mode,V)Then O.Data^[I*Ref.NC+J]:=V;
   End;
  Name:=Dir+'/'+BaseName(ListItems[K])+'.asc';
  WriteRaster(Name,O);
  AddRes('OUTPUT_'+IntToStr(K),Name);
 End;
 AddRes('OUTPUT',Dir);
End;

Procedure RunFuzzify(A:Integer);
Var
 R,O:TRaster;
 Mid,Spread,V:Real;
 I:LongInt;
 Out:String;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 CheckBand(A);
 Mid:=NeedReal(A,'FUZZYMIDPOINT');
 Spread:=NeedReal(A,'FUZZYSPREAD');
 Out:=NeedStr(A,'OUTPUT');
 NewRaster(O,R.NC,R.NR,R.XLL,R.YLL,R.Cell,-9999);
 For I:=0 to R.NC*R.NR-1do Begin
  V:=R.Data^[I];
  If Not IsNoData(R,V)Then O.Data^[I]:=Exp(-Spread*Sqr(V-Mid));
 End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

Procedure RunRasterStatistics(A:Integer);
Var
 R:TRaster;
 I,N:LongInt;
 V,Sum,Sq,Mn,Mx,Mean,Sd:Real;
 T:Text;
 Out:String;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 CheckBand(A);
 N:=0;Sum:=0;Sq:=0;Mn:=1E300;Mx:=-1E300;
 For I:=0 to R.NC*R.NR-1do Begin
  V:=R.Data^[I];
  If Not IsNoData(R,V)Then Begin
   Inc(N);Sum:=Sum+V;Sq:=Sq+V*V;
   If V<Mn Then Mn:=V;
   If V>Mx Then Mx:=V;
  End;
 End;
 If N=0Then Fail('Error: the raster has no valid pixel');
 Mean:=Sum/N;
 Sd:=Sqrt(MaxR(0,Sq/N-Mean*Mean));
 AddRes('MIN',RealToStr(Mn));
 AddRes('MAX',RealToStr(Mx));
 AddRes('RANGE',RealToStr(Mx-Mn));
 AddRes('SUM',RealToStr(Sum));
 AddRes('MEAN',RealToStr(Mean));
 AddRes('STD_DEV',RealToStr(Sd));
 AddRes('SUM_OF_SQUARES',RealToStr(Sq));
 Out:=NeedStr(A,'OUTPUT_HTML_FILE');
 If Out<>''Then Begin
  {$I-}
  Assign(T,Out);
  Rewrite(T);
  {$I+}
  If IOResult<>0Then Fail('Error: unable to create output file '+Out);
  WriteLn(T,'Minimum: ',RealToStr(Mn));
  WriteLn(T,'Maximum: ',RealToStr(Mx));
  WriteLn(T,'Range: ',RealToStr(Mx-Mn));
  WriteLn(T,'Sum: ',RealToStr(Sum));
  WriteLn(T,'Mean value: ',RealToStr(Mean));
  WriteLn(T,'Standard deviation: ',RealToStr(Sd));
  WriteLn(T,'Sum of the squares: ',RealToStr(Sq));
  Close(T);
  AddRes('OUTPUT_HTML_FILE',Out);
 End;
End;

Procedure RunReclassify(A:Integer);
Var
 R,O:TRaster;
 Mins,Maxs,Vals:Array[1..60]of Real;
 NR2,K,Bnd,I:LongInt;
 Nd,V,Out2:Real;
 MissingNd,Hit:Boolean;
 Out:String;
Begin
 ReadRaster(NeedStr(A,'INPUT_RASTER'),R);
 { bande choisie dans RunAlgo }
 SplitList(NeedStr(A,'TABLE'),';, ');
 If(ListCount=0)or(ListCount mod 3<>0)Then Fail('Error: TABLE must contain min,max,value triplets');
 NR2:=ListCount div 3;
 If NR2>60Then Fail('Error: at most 60 classes');
 For K:=1 to NR2 do Begin
  RNum(ListItems[3*K-2],Mins[K]);RNum(ListItems[3*K-1],Maxs[K]);RNum(ListItems[3*K],Vals[K]);
 End;
 Nd:=NeedReal(A,'NO_DATA');
 Bnd:=Round(NeedReal(A,'RANGE_BOUNDARIES'));
 If(Bnd<0)or(Bnd>3)Then Fail('Error: RANGE_BOUNDARIES must be between 0 and 3');
 MissingNd:=NeedBool(A,'NODATA_FOR_MISSING');
 Out:=NeedStr(A,'OUTPUT');
 NewRaster(O,R.NC,R.NR,R.XLL,R.YLL,R.Cell,Nd);
 For I:=0 to R.NC*R.NR-1do Begin
  V:=R.Data^[I];
  If IsNoData(R,V)Then O.Data^[I]:=Nd
   Else
  Begin
   Hit:=False;
   For K:=1 to NR2 do
    If Not Hit Then Begin
     Case Bnd of
      0:Hit:=(V>Mins[K])and(V<=Maxs[K]);
      1:Hit:=(V>=Mins[K])and(V<Maxs[K]);
      2:Hit:=(V>=Mins[K])and(V<=Maxs[K]);
      3:Hit:=(V>Mins[K])and(V<Maxs[K]);
     End;
     If Hit Then O.Data^[I]:=Vals[K];
    End;
   If Not Hit Then Begin
    If MissingNd Then O.Data^[I]:=Nd Else O.Data^[I]:=V;
   End;
  End;
 End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

Procedure RunRescale(A:Integer);
Var
 R,O:TRaster;
 Mn,Mx,V,NMin,NMax,Nd:Real;
 I:LongInt;
 Have:Boolean;
 Out:String;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 CheckBand(A);
 NMin:=NeedReal(A,'MINIMUM');NMax:=NeedReal(A,'MAXIMUM');
 Nd:=NeedReal(A,'NODATA');
 Out:=NeedStr(A,'OUTPUT');
 Have:=False;Mn:=0;Mx:=0;
 For I:=0 to R.NC*R.NR-1do Begin
  V:=R.Data^[I];
  If Not IsNoData(R,V)Then
   If Not Have Then Begin Mn:=V;Mx:=V;Have:=True;End
    Else
   Begin If V<Mn Then Mn:=V;If V>Mx Then Mx:=V;End;
 End;
 NewRaster(O,R.NC,R.NR,R.XLL,R.YLL,R.Cell,Nd);
 For I:=0 to R.NC*R.NR-1do Begin
  V:=R.Data^[I];
  If Not IsNoData(R,V)Then
   If Mx>Mn Then O.Data^[I]:=NMin+(V-Mn)/(Mx-Mn)*(NMax-NMin)
            Else O.Data^[I]:=NMin;
 End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

Procedure RunNativeSlope(A:Integer);
Var
 R,O:TRaster;
 I,J:LongInt;
 Z:Array[1..9]of Real;
 Zf,Dx,Dy:Real;
 Out:String;
Begin
 ReadRaster(NeedStr(A,'INPUT'),R);
 Zf:=NeedReal(A,'Z_FACTOR');
 Out:=NeedStr(A,'OUTPUT');
 NewRaster(O,R.NC,R.NR,R.XLL,R.YLL,R.Cell,-9999);
 For I:=0 to R.NR-1do
  For J:=0 to R.NC-1do
   If Not IsNoData(R,R.Data^[I*R.NC+J])Then Begin
    Z[1]:=Nb(R,I,J,-1,-1);Z[2]:=Nb(R,I,J,-1,0);Z[3]:=Nb(R,I,J,-1,1);
    Z[4]:=Nb(R,I,J,0,-1);Z[5]:=Nb(R,I,J,0,0);Z[6]:=Nb(R,I,J,0,1);
    Z[7]:=Nb(R,I,J,1,-1);Z[8]:=Nb(R,I,J,1,0);Z[9]:=Nb(R,I,J,1,1);
    Dx:=((Z[3]+2*Z[6]+Z[9])-(Z[1]+2*Z[4]+Z[7]))/(8*R.Cell);
    Dy:=((Z[7]+2*Z[8]+Z[9])-(Z[1]+2*Z[2]+Z[3]))/(8*R.Cell);
    O.Data^[I*R.NC+J]:=Rad2Deg(ArcTan(Zf*Sqrt(Dx*Dx+Dy*Dy)));
   End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

{ Valeurs des pixels (centres) a l'interieur d'un polygone ; Vals doit pouvoir contenir NC*NR valeurs }
Procedure ZonalValues(Var R:TRaster;Var G:TGeom;Vals:PReals;Var N:LongInt);
Var
 P:PPath;
 Xs:PReals;
 Cap,NX,I,J,K,Row,C0,C1,R0,R1:LongInt;
 X1,Y1,X2,Y2,Y,Tmp,MinX,MinY,MaxX,MaxY:Real;
 V:Real;
Begin
 N:=0;
 If G.Cls<>3Then Exit;
 If Not GeomBBox(G,MinX,MinY,MaxX,MaxY)Then Exit;
 Cap:=0;
 P:=G.First;
 While P<>Nil do Begin Inc(Cap,P^.N);P:=P^.Next;End;
 Xs:=AllocBlock((Cap+2)*SizeOf(Real));
 R0:=FloorL((RasterTop(R)-MaxY)/R.Cell);
 R1:=CeilL((RasterTop(R)-MinY)/R.Cell);
 If R0<0Then R0:=0;
 If R1>R.NR-1Then R1:=R.NR-1;
 For Row:=R0 to R1 do Begin
  Y:=RasterTop(R)-(Row+0.5)*R.Cell;
  NX:=0;
  P:=G.First;
  While P<>Nil do Begin
   For I:=0 to P^.N-1do Begin
    K:=I+1;
    If K>=P^.N Then K:=0;
    X1:=P^.Pts^[I].X;Y1:=P^.Pts^[I].Y;X2:=P^.Pts^[K].X;Y2:=P^.Pts^[K].Y;
    If(Y1<=Y)<>(Y2<=Y)Then Begin Xs^[NX]:=X1+(Y-Y1)*(X2-X1)/(Y2-Y1);Inc(NX);End;
   End;
   P:=P^.Next;
  End;
  For I:=1 to NX-1do Begin
   Tmp:=Xs^[I];K:=I-1;
   While(K>=0)and(Xs^[K]>Tmp)do Begin Xs^[K+1]:=Xs^[K];Dec(K);End;
   Xs^[K+1]:=Tmp;
  End;
  I:=0;
  While I+1<NX do Begin
   C0:=CeilL((Xs^[I]-R.XLL)/R.Cell-0.5);
   C1:=CeilL((Xs^[I+1]-R.XLL)/R.Cell-0.5)-1;
   If C0<0Then C0:=0;
   If C1>=R.NC Then C1:=R.NC-1;
   For J:=C0 to C1 do Begin
    V:=R.Data^[Row*R.NC+J];
    If Not IsNoData(R,V)Then Begin Vals^[N]:=V;Inc(N);End;
   End;
   Inc(I,2);
  End;
 End;
 FreeMem(Xs,(Cap+2)*SizeOf(Real));
End;

Procedure SortReals(V:PReals;N:LongInt);
Var
 I,J:LongInt;
 T:Real;
Begin
 For I:=1 to N-1do Begin
  T:=V^[I];J:=I-1;
  While(J>=0)and(V^[J]>T)do Begin V^[J+1]:=V^[J];Dec(J);End;
  V^[J+1]:=T;
 End;
End;

Procedure RunZonalStatistics(A:Integer);
Var
 R:TRaster;
 VR,VA,F:PJ;
 G:TGeom;
 Vals:PReals;
 Stats:Array[0..11]of Integer;
 NS,K,S,E:Integer;
 N,I,J,Y:LongInt;
 Pref,Nm:String;
 Sum,Mean,Sd,Mn,Mx,Best:Real;
 Cnt,BestCnt,Variety:LongInt;
 Idx:LongInt;
Begin
 ReadRaster(NeedStr(A,'INPUT_RASTER'),R);
 { bande choisie dans RunAlgo }
 LoadIn(A,'INPUT_VECTOR',VR,VA);
 Pref:=NeedStr(A,'COLUMN_PREFIX');
 SplitList(NeedStr(A,'STATISTICS'),';, ');
 NS:=0;
 For K:=1 to ListCount do Begin
  Val(ListItems[K],Stats[NS],E);
  If(E<>0)or(Stats[NS]<0)or(Stats[NS]>11)Then Fail('Error: STATISTICS values must be between 0 and 11');
  Inc(NS);
 End;
 If NS=0Then Fail('Error: STATISTICS is empty');
 Vals:=AllocBlock((R.NC*R.NR+1)*SizeOf(Real));
 F:=VA^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  ZonalValues(R,G,Vals,N);
  FreeGeom(G);
  Sum:=0;
  For I:=0 to N-1do Sum:=Sum+Vals^[I];
  If N>0Then Begin
   Mean:=Sum/N;Sd:=0;
   For I:=0 to N-1do Sd:=Sd+Sqr(Vals^[I]-Mean);
   SortReals(Vals,N);
  End;
  For S:=0 to NS-1do Begin
   Case Stats[S]of
    0:Nm:='count';1:Nm:='sum';2:Nm:='mean';3:Nm:='median';4:Nm:='stdev';5:Nm:='min';
    6:Nm:='max';7:Nm:='range';8:Nm:='minority';9:Nm:='majority';10:Nm:='variety';Else Nm:='variance';
   End;
   Nm:=Pref+Nm;
   If Stats[S]=0Then PutProp(F,Nm,JNum(N))
    Else
   If N=0Then PutProp(F,Nm,NewJ(0))
    Else
   Case Stats[S]of
    1:PutProp(F,Nm,JNum(Sum));
    2:PutProp(F,Nm,JNum(Mean));
    3:If Odd(N)Then PutProp(F,Nm,JNum(Vals^[N div 2])) Else PutProp(F,Nm,JNum((Vals^[N div 2-1]+Vals^[N div 2])/2));
    4:PutProp(F,Nm,JNum(Sqrt(Sd/N)));
    5:PutProp(F,Nm,JNum(Vals^[0]));
    6:PutProp(F,Nm,JNum(Vals^[N-1]));
    7:PutProp(F,Nm,JNum(Vals^[N-1]-Vals^[0]));
    11:PutProp(F,Nm,JNum(Sd/N));
    8,9,10:Begin
     Best:=Vals^[0];BestCnt:=0;Variety:=0;
     I:=0;
     While I<N do Begin
      J:=I;
      While(J<N)and(Vals^[J]=Vals^[I])do Inc(J);
      Cnt:=J-I;
      Inc(Variety);
      If(BestCnt=0)or((Stats[S]=9)and(Cnt>BestCnt))or((Stats[S]=8)and(Cnt<BestCnt))Then Begin BestCnt:=Cnt;Best:=Vals^[I];End;
      I:=J;
     End;
     If Stats[S]=10Then PutProp(F,Nm,JNum(Variety)) Else PutProp(F,Nm,JNum(Best));
    End;
   End;
  End;
  F:=F^.Next;
 End;
 SaveOut(A,'OUTPUT',VR);
End;

Procedure RunZonalHistogram(A:Integer);
Var
 R:TRaster;
 VR,VA,F:PJ;
 G:TGeom;
 Vals:PReals;
 Uniq:Array[1..200]of Real;
 NU,K:Integer;
 N,I,J,Cnt:LongInt;
 Pref:String;
 V:Real;
 Pass:Integer;
 Found:Boolean;
Begin
 ReadRaster(NeedStr(A,'INPUT_RASTER'),R);
 { bande choisie dans RunAlgo }
 LoadIn(A,'INPUT_VECTOR',VR,VA);
 Pref:=NeedStr(A,'COLUMN_PREFIX');
 Vals:=AllocBlock((R.NC*R.NR+1)*SizeOf(Real));
 NU:=0;
 For Pass:=1 to 2do Begin
  F:=VA^.First;
  While F<>Nil do Begin
   FlattenFeature(F,G);
   ZonalValues(R,G,Vals,N);
   FreeGeom(G);
   If Pass=1Then Begin
    For I:=0 to N-1do Begin
     Found:=False;
     For K:=1 to NU do If Uniq[K]=Vals^[I]Then Found:=True;
     If Not Found Then Begin
      If NU>=200Then Fail('Error: too many distinct values in the raster zones');
      Inc(NU);Uniq[NU]:=Vals^[I];
     End;
    End;
   End
    Else
   For K:=1 to NU do Begin
    Cnt:=0;
    For I:=0 to N-1do If Vals^[I]=Uniq[K]Then Inc(Cnt);
    PutProp(F,Pref+NumStr(Uniq[K]),JNum(Cnt));
   End;
   F:=F^.Next;
  End;
 End;
 SaveOut(A,'OUTPUT',VR);
End;

{ Calculatrice raster native : couches referencees par "nom@1" }
Procedure RunRasterCalcExpr(A:Integer);
Var
 Rs:Array[0..15]of TRaster;
 O:TRaster;
 NL,K:Integer;
 Vars:Array[0..15]of Real;
 X1,X2,Y1,Y2,Cell,X,Y,V:Real;
 I,J,Nc,Nr:LongInt;
 Out:String;
 Ok:Boolean;
Begin
 SplitList(NeedStr(A,'LAYERS'),';');
 NL:=ListCount;
 If(NL<1)or(NL>16)Then Fail('Error: LAYERS must list between 1 and 16 rasters separated by ;');
 For K:=0 to NL-1do Begin
  ReadRaster(ListItems[K+1],Rs[K]);
  CalcNames[K]:=BaseName(ListItems[K+1])+'@1';
 End;
 CalcNN:=NL;
 CalcS:=NeedStr(A,'EXPRESSION');
 CalcP:=1;CodeN:=0;
 CExpr;
 CSkip;
 If CalcP<=Length(CalcS)Then CFail('unexpected token');
 Out:=NeedStr(A,'OUTPUT');
 X1:=Rs[0].XLL;Y2:=RasterTop(Rs[0]);X2:=Rs[0].XLL+Rs[0].NC*Rs[0].Cell;Y1:=Rs[0].YLL;
 Cell:=Rs[0].Cell;
 If HasArg('EXTENT')Then ParseExtent(NeedStr(A,'EXTENT'),X1,X2,Y1,Y2);
 If HasArg('CELLSIZE')Then Cell:=NeedReal(A,'CELLSIZE');
 If Cell<=0Then Fail('Error: CELLSIZE must be greater than 0');
 Nc:=CeilL((X2-X1)/Cell-1E-9);Nr:=CeilL((Y2-Y1)/Cell-1E-9);
 NewRaster(O,Nc,Nr,X1,Y2-Nr*Cell,Cell,-9999);
 For I:=0 to Nr-1do
  For J:=0 to Nc-1do Begin
   X:=X1+(J+0.5)*Cell;Y:=Y2-(I+0.5)*Cell;
   Ok:=True;
   For K:=0 to NL-1do
    If Not SampleRaster(Rs[K],X,Y,0,Vars[K])Then Ok:=False;
   If Ok and CEval(Vars,V)Then O.Data^[I*Nc+J]:=V;
  End;
 WriteRaster(Out,O);
 AddRes('OUTPUT',Out);
End;

{ ---- export ---- }

Procedure RunSaveFeatures(A:Integer);
Var
 Root,Arr,F:PJ;
 Out,Up,Cell:String;
 L:TNameList;
 T:Text;
 I:Integer;
 G:TGeom;
 N:PJ;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Out:=NeedStr(A,'OUTPUT');
 Up:=StrUpper(Out);
 If(Copy(Up,Length(Up)-3,4)='.CSV')Then Begin
  CollectFields(Arr,L);
  {$I-}
  Assign(T,Out);
  Rewrite(T);
  {$I+}
  If IOResult<>0Then Fail('Error: unable to create output file '+Out);
  For I:=1 to L.N do Write(T,L.Names[I],',');
  WriteLn(T,'WKT');
  F:=Arr^.First;
  While F<>Nil do Begin
   For I:=1 to L.N do Begin
    N:=GetProp(F,L.Names[I]);
    Cell:=NodeText(N);
    If(Pos(',',Cell)>0)or(Pos('"',Cell)>0)Then Begin
     Write(T,'"');
     Write(T,Cell);
     Write(T,'"');
    End
     Else
    Write(T,Cell);
    Write(T,',');
   End;
   FlattenFeature(F,G);
   Write(T,'"');
   WriteWkt(T,G);
   Write(T,'"');
   FreeGeom(G);
   WriteLn(T);
   F:=F^.Next;
  End;
  Close(T);
 End
  Else
 SaveLayer(Out,Root);
 AddRes('OUTPUT',Out);
End;

Procedure RunUnsupported(A:Integer);Begin
 Fail('Error: '+Algos[A].Id+' is not supported by this clone ('+Algos[A].Descr+')');
End;

{ Filtre les entites d'une couche avec une expression (option subset= d'une source) }
Procedure ApplySubset(Root:PJ;Expr:String);
Var
 Arr,F,Nx:PJ;
 V:TVal;
 I:LongInt;
Begin
 Arr:=LayerFeatures(Root);
 F:=Arr^.First;
 Arr^.First:=Nil;Arr^.Last:=Nil;
 I:=0;
 While F<>Nil do Begin
  Nx:=F^.Next;
  V:=EvalOn(Expr,F,I);
  If(V.K in[1,3])and(V.N<>0)Then JAdd(Arr,F);
  Inc(I);
  F:=Nx;
 End;
End;

Procedure RunAlgo(A:Integer);
Var
 I,J:Integer;
 P:ParamRec;
 Tmp:String;
Begin
 { Verifie les parametres avant de lancer l'algorithme : aucun parametre inconnu,
   tous les parametres obligatoires presents }
 For I:=1 to ArgCount do
  If Not ParamDef(A,ArgName[I],P)Then
   Fail('Error: unknown parameter '+ArgName[I]);
 For I:=1 to MaxParam do
  If(Params[I].A=A)and(Params[I].Def='')and Not GetArg(Params[I].Name,Tmp)and
    Not((Length(Params[I].Typ)>11)and(Copy(Params[I].Typ,Length(Params[I].Typ)-10,11)='Destination'))Then
   Fail('Error: missing required parameter '+Params[I].Name);
 ResCount:=0;
 If Not JsonMode Then Begin
  WriteLn('QGIS Processing Executor (clone) - ',VersionStr);
  WriteLn('Running ',Algos[A].Id,' [',Algos[A].Title,']');
  WriteLn;
  WriteLn('----------------');
  WriteLn('Inputs');
  WriteLn('----------------');
  WriteLn;
  For I:=1 to ArgCount do WriteLn(ArgName[I],':',#9,ArgVal[I]);
  If DistUnits<>''Then WriteLn('distance_units:',#9,DistUnits);
  If AreaUnits<>''Then WriteLn('area_units:',#9,AreaUnits);
  If Ellipsoid<>''Then WriteLn('ellipsoid:',#9,Ellipsoid);
  If ProjectPath<>''Then WriteLn('project_path:',#9,ProjectPath);
  WriteLn;
  If Verbose Then WriteLn('Algorithm ',Algos[A].Id,' starting...');
 End;
 BandSel:=1;
 If GetArg('BAND',Tmp)or GetArg('RASTER_BAND',Tmp)Then Begin
  Val(Tmp,BandSel,I);
  If(I<>0)or(BandSel<1)Then Fail('Error: invalid band number "'+Tmp+'"');
 End;
 Case A of
  1:RunDistance(A);
  2:RunBearing(A);
  3:RunDestination(A);
  4:RunReproject(A);
  5:RunExtent(A);
  6:RunCenter(A);
  7:RunBuffer(A);
  8:RunCentroids(A);
  9:RunClip(A);
  10:RunConvexHull(A);
  11:RunExtract(A);
  12:RunReprojectLayer(A);
  13:RunPolygonsToLines(A);
  14:RunPixelsToPoints(A);
  15:RunClipRaster(A);
  16:RunWarp(A);
  17:RunNearBlack(A);
  18:RunOffsetCurve(A);
  19:RunOgrInfo(A);
  20:RunOneSideBuffer(A);
  21:RunOverviews(A);
  22:RunPanSharp(A);
  23:RunPolygonize(A);
  24:RunProximity(A);
  25:RunRasterCalc(A);
  26:RunRasterize(A);
  27:RunRasterizeOver(A,False);
  28:RunRasterizeOver(A,True);
  29:RunRetile(A);
  30:RunRoughness(A);
  31:RunSieve(A);
  32:RunSlope(A);
  33:RunTileIndex(A);
  34:RunTranslate(A);
  35:RunViewshed(A);
  36:RunAutoIncremental(A);
  37:RunAddField(A);
  38:RunUniqueIndex(A);
  39:RunAddXY(A);
  40:MapGeometries(A,1);
  41:MapGeometries(A,0);
  42:MapGeometries(A,2);
  43:MapGeometries(A,3);
  44:RunDeleteColumn(A);
  45:RunDropGeometries(A);
  46:RunExtractByAttribute(A);
  47:RunFieldCalculator(A);
  48:RunRefactorFields(A);
  49:RunOrderByExpression(A);
  50:RunNoOp(A);
  51:RunNoOp(A);
  52:RunNoOp(A);
  53:RunAssignProjection(A);
  54:RunSplitByChar(A);
  55:RunForceRHR(A);
  56:RunZValues(A,0);
  57:RunZValues(A,1);
  58:RunZValues(A,2);
  59:RunMultiToSingle(A);
  60:RunCollect(A);
  61:RunCollect(A);
  62:RunExplodeLines(A);
  63:RunExtractVertices(A);
  64:RunDeleteHoles(A);
  65:RunPathOp(A,0);
  66:RunPathOp(A,1);
  67:RunPathOp(A,2);
  68:RunLineSubstring(A);
  69:RunSplitLinesByLength(A);
  70:RunPointsAlongLines(A);
  71:RunPointsAlongLines(A);
  72:RunTransect(A);
  73:RunWedgeBuffers(A);
  74:RunOffsetLine(A,0);
  75:RunOffsetLine(A,1);
  76:RunMergeLayers(A);
  77:RunPointOnSurface(A);
  78:RunOrientedBox(A);
  79:RunRoundness(A);
  80:RunConcaveHull(A);
  81:RunFixGeometries(A);
  82:RunSnapGeometries(A);
  83:RunAntimeridian(A);
  84:RunGeometryByExpression(A);
  85:RunExtractByExtent(A);
  86:RunLinesToPolygons(A);
  87:RunCreateGrid(A);
  88:RunAddGeometryColumns(A);
  89:RunTaperedBuffer(A);
  90:RunKMeans(A);
  91:RunDbscan(A);
  92:RunNearestNeighbour(A);
  93:RunAngleToNearest(A);
  94:RunShortestLine(A);
  95:RunBuffer(A);
  96:RunOverlayLayers(A,0);
  97:RunOverlayLayers(A,1);
  98:RunOverlayLayers(A,2);
  99:RunDifference(A);
  100:RunDissolve(A);
  101:RunAggregate(A);
  102:RunSplitWithLines(A);
  103:RunPolygonizeLines(A);
  104:RunCountPoints(A);
  105:RunExtractByLocation(A);
  106:RunJoinByLocation(A,False);
  107:RunJoinByLocation(A,True);
  108:RunJoinAttributesTable(A);
  109:RunLineIntersections(A);
  110:RunVectorOverlaps(A);
  111:RunSumLineLengths(A);
  112:RunCreateConstantRaster(A);
  113:RunAlignRasters(A);
  114:RunFuzzify(A);
  115:RunRasterStatistics(A);
  116:RunReclassify(A);
  117:RunRescale(A);
  118:RunNativeSlope(A);
  119:RunZonalStatistics(A);
  120:RunZonalHistogram(A);
  121:RunRasterCalcExpr(A);
  122:RunSaveFeatures(A);
  123:RunUnsupported(A);
  124:RunUnsupported(A);
  125:RunUnsupported(A);
  126:RunUnsupported(A);
  127:RunUnsupported(A);
  128:RunUnsupported(A);
  129:RunUnsupported(A);
  130:RunUnsupported(A);
  131:RunUnsupported(A);
  132:RunUnsupported(A);
  133:RunUnsupported(A);
  134:RunUnsupported(A);
 End;
 If JsonMode Then Begin
  WriteLn('{"algorithm_details":{"id":',JsonStr(Algos[A].Id),
          ',"name":',JsonStr(Algos[A].Title),'},"inputs":{');
  For I:=1 to ArgCount do Begin
   Write(' ',JsonStr(ArgName[I]),':',JsonVal(ArgVal[I]));
   If I<ArgCount Then WriteLn(',') Else WriteLn;
  End;
  Write('}');
  If DistUnits<>''Then Write(',"distance_units":',JsonStr(DistUnits));
  If AreaUnits<>''Then Write(',"area_units":',JsonStr(AreaUnits));
  If Ellipsoid<>''Then Write(',"ellipsoid":',JsonStr(Ellipsoid));
  If ProjectPath<>''Then Write(',"project_path":',JsonStr(ProjectPath));
  WriteLn(',"results":{');
  For J:=1 to ResCount do Begin
   Write(' ',JsonStr(ResName[J]),':',JsonVal(ResVal[J]));
   If J<ResCount Then WriteLn(',') Else WriteLn;
  End;
  WriteLn('}}');
 End
  Else
 Begin
  WriteLn('0...10...20...30...40...50...60...70...80...90...100 - done.');
  WriteLn;
  WriteLn('----------------');
  WriteLn('Results');
  WriteLn('----------------');
  WriteLn;
  For J:=1 to ResCount do WriteLn(ResName[J],':',#9,ResVal[J]);
  If Verbose Then Begin
   WriteLn;
   WriteLn('Algorithm ',Algos[A].Id,' finished (',ResCount,' result(s)).');
  End;
 End;
End;

{ Option globale (--distance_units, --area_units, --ellipsoid, --project_path) ; Faux si ce n'en est pas une }
Function SetGlobalOption(Name,Value:String):Boolean;
Var
 T:Text;
Begin
 SetGlobalOption:=True;
 Name:=StrUpper(Name);
 If Name='DISTANCE_UNITS'Then Begin
  DistFactor:=DistanceFactor(Value);
  If DistFactor<=0Then Fail('Error: unknown distance unit "'+Value+'"');
  DistUnits:=Value;
 End Else
 If Name='AREA_UNITS'Then Begin
  AreaFactor:=AreaUnitFactor(Value);
  If AreaFactor<=0Then Fail('Error: unknown area unit "'+Value+'"');
  AreaUnits:=Value;
 End Else
 If Name='ELLIPSOID'Then Begin Ellipsoid:=Value;SetEllipsoid(Value);End Else
 If Name='PROJECT_PATH'Then Begin
  {$I-}
  Assign(T,Value);
  Reset(T);
  {$I+}
  If IOResult<>0Then Fail('Error: project file "'+Value+'" not found');
  Close(T);
  ProjectPath:=Value;
 End
  Else
 SetGlobalOption:=False;
End;

{ Ajoute un parametre ; Append : une valeur deja presente est completee (liste separee par ;), sinon remplacee }
Procedure AddArg(Name,Value:String;Append:Boolean);
Var
 K:Integer;
Begin
 Name:=StrUpper(Name);
 For K:=1 to ArgCount do
  If ArgName[K]=Name Then Begin
   If Append Then Begin
    If Length(ArgVal[K])+Length(Value)+1>255Then Fail('Error: the value of '+Name+' is longer than 255 characters');
    ArgVal[K]:=ArgVal[K]+';'+Value;
   End
    Else
   ArgVal[K]:=Value;
   Exit;
  End;
 Inc(ArgCount);
 If ArgCount>MaxArg Then Fail('Error: too many parameters');
 ArgName[ArgCount]:=Name;
 ArgVal[ArgCount]:=Value;
End;

{ Valeur texte d'un noeud JSON de parametre (les tableaux deviennent des listes separees par ;) }
Function JArgValue(N:PJ;Name:String):String;
Var
 C:PJ;
 S,T:String;
Begin
 Case N^.Kind of
  1,2:S:=JVal(N);
  3:S:=Unesc(JVal(N));
  4:Begin
   S:='';
   C:=N^.First;
   While C<>Nil do Begin
    T:=JArgValue(C,Name);
    If S<>''Then S:=S+';';
    S:=S+T;
    C:=C^.Next;
   End;
  End;
  Else Begin
   Fail('Error: the value of '+Name+' must be a string, a number, a boolean or a list');
   S:='';
  End;
 End;
 If Length(S)>255Then Fail('Error: the value of '+Name+' is longer than 255 characters');
 JArgValue:=S;
End;

(* Lit les parametres au format JSON sur l'entree standard :
   {"inputs":{...},"distance_units":"...","area_units":"...","ellipsoid":"...","project_path":"..."} *)
Procedure ReadStdinInputs;
Var
 Root,Inp,C:PJ;
Begin
 ParseName:='standard input';
 Assign(PF,'');
 Reset(PF);
 SetTextBuf(PF,PBuf);
 NextCh;
 Root:=ParseValue(0);
 If Root^.Kind<>5Then Fail('Error: the JSON read from the standard input must be an object');
 Inp:=JFind(Root,'inputs');
 If(Inp=Nil)or(Inp^.Kind<>5)Then Fail('Error: the JSON read from the standard input must have an "inputs" object');
 C:=Inp^.First;
 While C<>Nil do Begin
  If C^.Kind<>0Then AddArg(JKey(C),JArgValue(C,JKey(C)),False);
  C:=C^.Next;
 End;
 C:=Root^.First;
 While C<>Nil do Begin
  If(JKey(C)<>'inputs')and(C^.Kind in[1,2,3])Then
   If Not SetGlobalOption(JKey(C),JArgValue(C,JKey(C)))Then Fail('Error: unknown key "'+JKey(C)+'" in the JSON read from the standard input');
  C:=C^.Next;
 End;
End;

Procedure ShowCommandHelp(C:String);Begin
 C:=StrUpper(C);
 If C='LIST'Then Begin
  WriteLn('Usage: QGIS_PROCESS list');
  WriteLn;
  WriteLn('Lists all the available algorithms, grouped by provider (native, gdal).');
  WriteLn('With --json the result is {"providers":{...}}.');
 End Else
 If C='PLUGINS'Then Begin
  WriteLn('Usage: QGIS_PROCESS plugins');
  WriteLn('       QGIS_PROCESS plugins enable PLUGIN_NAME');
  WriteLn('       QGIS_PROCESS plugins disable PLUGIN_NAME');
  WriteLn;
  WriteLn('Lists the available plugins, or enables/disables one of them.');
  WriteLn('Only the built-in "processing" plugin is available in this clone.');
 End Else
 If C='HELP'Then Begin
  WriteLn('Usage: QGIS_PROCESS help ALGORITHM_ID');
  WriteLn;
  WriteLn('Describes an algorithm: its description, parameters (with types, defaults and');
  WriteLn('whether they are required) and outputs. With --json the result is a JSON object.');
 End
  Else
 Begin
  WriteLn('Usage: QGIS_PROCESS run ALGORITHM_ID [--PARAMETER=VALUE ...]');
  WriteLn('       QGIS_PROCESS run ALGORITHM_ID -');
  WriteLn;
  WriteLn('Runs an algorithm. Parameters are given as --NAME=VALUE (repeat a parameter to build a');
  WriteLn('list, or separate the items with ;). With "-" the parameters are read as JSON from the');
  WriteLn('standard input, for example:');
  WriteLn('  echo {"inputs":{"X1":0,"Y1":0,"X2":3,"Y2":4}} | QGIS_PROCESS --json run native:calculatedistance -');
  WriteLn('Values are limited to 255 characters. Use "help ALGORITHM_ID" to list the parameters.');
 End;
End;

{ Analyse la ligne de commande : options, commande, algorithme et parametres }
Procedure ParseArgs;
Var
 I,P:Integer;
 S,Name:String;
 N:Integer;
Begin
 JsonMode:=False;Verbose:=False;StdinMode:=False;HelpFlag:=False;SkipPlugins:=False;
 BufMiter:=2;
 DistUnits:='';AreaUnits:='';Ellipsoid:='';ProjectPath:='';Pos3:='';
 DistFactor:=0;AreaFactor:=0;
 Cmd:='';AlgoId:='';
 ArgCount:=0;
 N:=0;
 For I:=1 to ParamCount do Begin
  S:=ParamStr(I);
  If StrUpper(S)='--JSON'Then JsonMode:=True Else
  If StrUpper(S)='--VERBOSE'Then Verbose:=True Else
  If StrUpper(S)='--NO-PYTHON'Then Begin End Else
  If StrUpper(S)='--SKIP-LOADING-PLUGINS'Then SkipPlugins:=True Else
  If(S='/?')or(S='-h')or(S='/h')or(S='/H')or(StrUpper(S)='--HELP')Then Begin
   If Cmd=''Then Cmd:='--help' Else HelpFlag:=True;
  End
   Else
  If StrUpper(S)='--VERSION'Then Begin
   If Cmd=''Then Cmd:='--version';
  End
   Else
  Begin
   P:=Pos('=',S);
   Name:='';
   If P>0Then Begin
    Name:=Copy(S,1,P-1);
    While(Name<>'')and(Name[1]in['-','/'])do Name:=Copy(Name,2,255);
   End;
   If(P>0)and SetGlobalOption(Name,Copy(S,P+1,255))Then Begin End
    Else
   If(P>0)and(N>0)Then AddArg(Name,Copy(S,P+1,255),True)
    Else
   Begin
    Inc(N);
    If N=1Then Cmd:=S Else
    If N=2Then AlgoId:=S Else
    If N=3Then Begin
     Pos3:=S;
     If S='-'Then StdinMode:=True;
    End
     Else
    Fail('Error: unexpected argument '+S);
   End;
  End;
 End;
End;

Var
 A:Integer;
 Up:String;
 Hh,Mm,Ss,Cs:Word;
BEGIN
 GetTime(Hh,Mm,Ss,Cs);
 RandSeed:=((LongInt(Hh)*60+Mm)*60+Ss)*100+Cs;
 TmpCount:=0;
 ParseArgs;
 If(Cmd='')or(Cmd='--help')Then ShowGeneralHelp Else
 If Cmd='--version'Then Begin
  If JsonMode Then WriteLn('{"version":"',VersionStr,'"}')
              Else WriteLn('QGIS_PROCESS clone ',VersionStr);
 End
  Else
 If HelpFlag and((StrUpper(Cmd)='LIST')or(StrUpper(Cmd)='PLUGINS')or(StrUpper(Cmd)='HELP')or(StrUpper(Cmd)='RUN'))Then
  ShowCommandHelp(Cmd)
  Else
 If StrUpper(Cmd)='LIST'Then ShowList Else
 If StrUpper(Cmd)='PLUGINS'Then Begin
  If AlgoId=''Then ShowPlugins Else PluginsAction(AlgoId,Pos3);
 End
  Else
 If(StrUpper(Cmd)='HELP')or(StrUpper(Cmd)='RUN')Then Begin
  If AlgoId=''Then Fail('Error: missing algorithm id');
  Up:=StrUpper(AlgoId);
  If(Copy(Up,Length(Up)-6,7)='.MODEL3')or(Copy(Up,Length(Up)-2,3)='.PY')Then
   Fail('Error: model files and Python scripts are not supported by this clone');
  A:=FindAlgo(AlgoId);
  If A=0Then Fail('Error: algorithm "'+AlgoId+'" not found');
  If StrUpper(Cmd)='HELP'Then ShowAlgoHelp(A)
   Else
  Begin
   If(Pos3<>'')and Not StdinMode Then Fail('Error: unexpected argument '+Pos3);
   If StdinMode Then ReadStdinInputs;
   RunAlgo(A);
  End;
 End
  Else
 Fail('Error: unknown command "'+Cmd+'"');
END.
