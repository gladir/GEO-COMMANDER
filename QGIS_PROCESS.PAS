{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
  @description: Clone minimaliste de la commande qgis_process de QGIS

  Les couches vectorielles sont des fichiers GeoJSON (EPSG:4326 ou EPSG:3857),
  les rasters sont des fichiers ESRI ASCII Grid (.asc).

  Note : les algorithmes de couches et de rasters allouent de grands blocs de
  memoire (plus de 64 Ko) : utiliser Free Pascal (mode -Mtp possible) ou un
  Turbo Pascal en mode protege.
}

Program QGIS_PROCESS;

Const
 VersionStr='1.1';
 EarthRadius=6371008.8;   { Rayon moyen de la Terre (spherique), en metres }
 MercatorRadius=6378137.0;{ Rayon utilise par EPSG:3857 }
 MaxAlgo=94;
 MaxParam=402;
 MaxOut=114;
 MaxArg=30;
 MaxCells=40000000;

Type
 AlgoRec=Record
  Id:String[33];
  Title:String[40];
  Group:String[24];
  Descr:String[120];
 End;
 ParamRec=Record
  A:Byte;
  Name:String[20];
  Typ:String[18];
  Desc:String[105];
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
   Descr:'Converts a point between EPSG:4326 and EPSG:3857.'),
  (Id:'native:layerextent';Title:'Extract layer extent';
   Group:'Vector general';
   Descr:'Computes the bounding box of the geometries of a GeoJSON file.'),
  (Id:'native:pointsonextent';Title:'Extent center';
   Group:'Vector general';
   Descr:'Computes the center and size of a bounding box.'),
  (Id:'native:buffer';Title:'Buffer';
   Group:'Vector geometry';
   Descr:'Buffers the features by a distance in layer units (round caps/joins, dissolved result).'),
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
   Descr:'Reprojects a layer between EPSG:4326 and EPSG:3857.'),
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
   Descr:'Reprojects an ASCII grid between EPSG:4326 and EPSG:3857, like gdalwarp.'),
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
   Descr:'Adds the x and y fields of a point layer, in EPSG:4326 or EPSG:3857.'),
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
   Descr:'Sets the CRS of a layer (EPSG:4326 or EPSG:3857) without changing the coordinates.'),
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
   Descr:'Creates the shortest line from each source feature to its nearest destination feature(s).')
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
  (A:4;Name:'SOURCE_CRS';Typ:'crs';Desc:'Source CRS (EPSG:4326 or EPSG:3857)';Def:'EPSG:4326'),
  (A:4;Name:'TARGET_CRS';Typ:'crs';Desc:'Target CRS (EPSG:4326 or EPSG:3857)';Def:'EPSG:3857'),
  (A:5;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:6;Name:'XMIN';Typ:'number';Desc:'Minimum X';Def:''),
  (A:6;Name:'YMIN';Typ:'number';Desc:'Minimum Y';Def:''),
  (A:6;Name:'XMAX';Typ:'number';Desc:'Maximum X';Def:''),
  (A:6;Name:'YMAX';Typ:'number';Desc:'Maximum Y';Def:''),
  (A:7;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:7;Name:'DISTANCE';Typ:'number';Desc:'Buffer distance in layer units (negative erodes polygons)';Def:''),
  (A:7;Name:'SEGMENTS';Typ:'number';Desc:'Segments used to approximate a quarter circle';Def:'5'),
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
  (A:12;Name:'TARGET_CRS';Typ:'crs';Desc:'Target CRS (EPSG:4326 or EPSG:3857)';Def:''),
  (A:12;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:13;Name:'INPUT';Typ:'vector';Desc:'Input polygon GeoJSON file';Def:''),
  (A:13;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:14;Name:'INPUT_RASTER';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:14;Name:'RASTER_BAND';Typ:'number';Desc:'Band number (only 1 is available)';Def:'1'),
  (A:14;Name:'FIELD_NAME';Typ:'string';Desc:'Name of the field holding the pixel value';Def:'VALUE'),
  (A:14;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:15;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:15;Name:'EXTENT';Typ:'extent';Desc:'Clipping extent: xmin,xmax,ymin,ymax [EPSG:code]';Def:''),
  (A:15;Name:'NODATA';Typ:'number';Desc:'Nodata value of the output';Def:'*'),
  (A:15;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:16;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:16;Name:'SOURCE_CRS';Typ:'crs';Desc:'Source CRS (EPSG:4326 or EPSG:3857)';Def:'EPSG:4326'),
  (A:16;Name:'TARGET_CRS';Typ:'crs';Desc:'Target CRS (EPSG:4326 or EPSG:3857)';Def:''),
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
  (A:23;Name:'BAND';Typ:'number';Desc:'Band number (only 1 is available)';Def:'1'),
  (A:23;Name:'FIELD';Typ:'string';Desc:'Name of the field receiving the pixel value';Def:'DN'),
  (A:23;Name:'EIGHT_CONNECTEDNESS';Typ:'boolean';Desc:'Use 8-connectedness instead of 4';Def:'false'),
  (A:23;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:24;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:24;Name:'BAND';Typ:'number';Desc:'Band number (only 1 is available)';Def:'1'),
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
  (A:30;Name:'BAND';Typ:'number';Desc:'Band number (only 1 is available)';Def:'1'),
  (A:30;Name:'COMPUTE_EDGES';Typ:'boolean';Desc:'Compute the values at the raster edges';Def:'false'),
  (A:30;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:31;Name:'INPUT';Typ:'raster';Desc:'Input ASCII grid (.asc)';Def:''),
  (A:31;Name:'THRESHOLD';Typ:'number';Desc:'Minimum region size in pixels';Def:'10'),
  (A:31;Name:'EIGHT_CONNECTEDNESS';Typ:'boolean';Desc:'Use 8-connectedness instead of 4';Def:'false'),
  (A:31;Name:'OUTPUT';Typ:'rasterDestination';Desc:'Output ASCII grid (.asc)';Def:''),
  (A:32;Name:'INPUT';Typ:'raster';Desc:'Elevation ASCII grid (.asc)';Def:''),
  (A:32;Name:'BAND';Typ:'number';Desc:'Band number (only 1 is available)';Def:'1'),
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
  (A:35;Name:'BAND';Typ:'number';Desc:'Band number (only 1 is available)';Def:'1'),
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
  (A:39;Name:'CRS';Typ:'crs';Desc:'CRS of the coordinates (EPSG:4326 or EPSG:3857)';Def:'EPSG:4326'),
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
  (A:53;Name:'CRS';Typ:'crs';Desc:'CRS to assign (EPSG:4326 or EPSG:3857)';Def:''),
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
  (A:74;Name:'JOIN_STYLE';Typ:'enum';Desc:'Join style (only round is supported)';Def:'0'),
  (A:74;Name:'MITER_LIMIT';Typ:'number';Desc:'Miter limit (unused)';Def:'2'),
  (A:74;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:''),
  (A:75;Name:'INPUT';Typ:'vector';Desc:'Input GeoJSON file';Def:''),
  (A:75;Name:'COUNT';Typ:'number';Desc:'Number of lines to create';Def:'10'),
  (A:75;Name:'OFFSET';Typ:'number';Desc:'Offset between lines';Def:'1'),
  (A:75;Name:'SEGMENTS';Typ:'number';Desc:'Segments per quarter circle';Def:'8'),
  (A:75;Name:'JOIN_STYLE';Typ:'enum';Desc:'Join style (only round is supported)';Def:'0'),
  (A:75;Name:'MITER_LIMIT';Typ:'number';Desc:'Miter limit (unused)';Def:'2'),
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
  (A:87;Name:'CRS';Typ:'crs';Desc:'CRS of the grid (EPSG:4326 or EPSG:3857)';Def:'EPSG:4326'),
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
  (A:94;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output GeoJSON file';Def:'')
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
  (A:7;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Buffered layer'),
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
  (A:94;Name:'OUTPUT';Typ:'vectorDestination';Desc:'Output layer')
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
 End;
 PGeom=^TGeom;
 TVal=Record
  K:Byte;               { 0 nul, 1 nombre, 2 chaine, 3 booleen, 4 geometrie }
  N:Real;
  S:String;
  G:PGeom;
 End;

Var
 JsonMode:Boolean;
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
 If IsNumber(S)Then JsonVal:=S
               Else JsonVal:=JsonStr(S);
End;

Procedure Fail(Msg:String);Begin
 If JsonMode Then WriteLn('{"error":',JsonStr(Msg),'}')
             Else WriteLn(Msg);
 Halt(1);
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
Function LoadLayer(FileName:String):PJ;
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
  LoadLayer:=R;
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
 LoadLayer:=Col;
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

Procedure SaveLayer(FileName:String;Root:PJ);
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

Function ParseEpsg(S,What:String):Integer;
Var
 U:String;
 N,Err:Integer;
Begin
 U:=StrUpper(S);
 If Copy(U,1,5)='EPSG:'Then Begin
  Val(Copy(U,6,10),N,Err);
  If(Err=0)and((N=4326)or(N=3857))Then Begin
   ParseEpsg:=N;
   Exit;
  End;
 End;
 Fail('Error: unsupported '+What+' '+S+' (only EPSG:4326 and EPSG:3857 are supported)');
End;

{ Transforme un point entre EPSG:4326 et EPSG:3857 (Faux si hors domaine) }
Function TryTransform(Src,Dst:Integer;Var X,Y:Real):Boolean;
Var
 A:Real;
Begin
 TryTransform:=True;
 If Src=Dst Then Exit;
 If Src=4326Then Begin
  If Abs(Y)>=89.9999Then Begin TryTransform:=False;Exit;End;
  A:=Pi/4+Deg2Rad(Y)/2;
  Y:=MercatorRadius*Ln(Sin(A)/Cos(A));
  X:=MercatorRadius*Deg2Rad(X);
 End
  Else
 Begin
  X:=Rad2Deg(X/MercatorRadius);
  Y:=Rad2Deg(2*ArcTan(Exp(Y/MercatorRadius))-Pi/2);
 End;
End;

Procedure TransformPt(Src,Dst:Integer;Var X,Y:Real);Begin
 If Not TryTransform(Src,Dst,X,Y)Then
  Fail('Error: latitude out of range for EPSG:3857');
End;

{ Systeme de coordonnees declare dans un fichier GeoJSON (defaut 4326) }
Function LayerCrs(Root:PJ):Integer;
Var
 C,P:PJ;
 S:String;
Begin
 LayerCrs:=4326;
 C:=JFind(Root,'crs');
 If C=Nil Then Exit;
 P:=JFind(JFind(C,'properties'),'name');
 S:=StrUpper(JVal(P));
 If Pos('3857',S)>0Then LayerCrs:=3857 Else
 If(Pos('4326',S)>0)or(Pos('CRS84',S)>0)Then LayerCrs:=4326
  Else
 Fail('Error: unsupported layer CRS '+JVal(P)+' (only EPSG:4326 and EPSG:3857 are supported)');
End;

Procedure SetLayerCrs(Root:PJ;Epsg:Integer);
Var
 C,P:PJ;
Begin
 JRemoveKey(Root,'crs');
 If Epsg=3857Then Begin
  C:=NewJ(5);
  JAddKV(C,'type',JText('name'));
  P:=NewJ(5);
  JAddKV(P,'name',JText('urn:ogc:def:crs:EPSG::3857'));
  JAddKV(C,'properties',P);
  JAddKV(Root,'crs',C);
 End;
End;

{ Transforme en place tous les couples de coordonnees d'une geometrie }
Procedure TransformCoords(N:PJ;Src,Dst:Integer);
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
Procedure RightJoin(Ax,Ay,Vx,Vy,Bx,By,D:Real;Seg:Integer;Trick:Boolean;Out:PPts;Var ON:LongInt);
Var
 K,Mm:LongInt;
 L0,L1,D0x,D0y,D1x,D1y,N0x,N0y,N1x,N1y,Cr,Dt,A0,A1,Sw,Ix,Iy:Real;

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
  { virage exterieur (ou demi-tour) : arc de cercle autour du sommet }
  A0:=Atan2(N0y,N0x);
  A1:=Atan2(N1y,N1x);
  Sw:=A1-A0;
  While Sw<0do Sw:=Sw+2*Pi;
  While Sw>=2*Pi do Sw:=Sw-2*Pi;
  If(Abs(Cr)<=1E-12)and(Dt<0)Then Sw:=Pi;
  Mm:=Trunc(Sw/(Pi/2)*Seg+0.999999);
  If Mm<1Then Mm:=1;
  Emit(Vx+N0x,Vy+N0y);
  For K:=1 to Mm-1do
   Emit(Vx+D*Cos(A0+Sw*K/Mm),Vy+D*Sin(A0+Sw*K/Mm));
  Emit(Vx+N1x,Vy+N1y);
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
 Q,Cyc,Out:PPts;
 M,I,K,CN,ON:LongInt;
 Pa:PPath;
Begin
 If D<=0Then Exit;
 Q:=UniquePts(P,M);
 If M=1Then Begin
  AddCircle(G,Q^[0].X,Q^[0].Y,D,Seg,Poly);
  FreeMem(Q,P^.N*SizeOf(TPt));
  Exit;
 End;
 CN:=2*M-2;
 Cyc:=AllocBlock(CN*SizeOf(TPt));
 For I:=0 to M-1do Cyc^[I]:=Q^[I];
 For I:=1 to M-2do Cyc^[M-1+I]:=Q^[M-1-I];
 Out:=AllocBlock((CN*(4*Seg+4)+2)*SizeOf(TPt));
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
 FreeMem(Out,(CN*(4*Seg+4)+2)*SizeOf(TPt));
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
    AddCircle(A,P^.Pts^[0].X,P^.Pts^[0].Y,Dist,Seg,K);
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
      If InsideOrOn(E,N,Mx,My,Tol)Then Begin
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
Function GeomPredicate(Pred:Integer;Var A,B:TGeom):Boolean;
Var
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
  1:GeomPredicate:=GeomContains(A,B);
  2:GeomPredicate:=Not GeomIntersects(A,B);
  6:GeomPredicate:=GeomContains(B,A);
  3:Begin
   If A.Cls<>B.Cls Then Exit;
   If A.Cls=3Then Begin
    Aa:=GeomArea(A);Ab:=GeomArea(B);
    Ia:=OverlapArea(A,B);
    GeomPredicate:=(Abs(Aa-Ia)<=1E-9*MaxR(Aa,1E-300))and(Abs(Ab-Ia)<=1E-9*MaxR(Ab,1E-300));
   End
    Else
   GeomPredicate:=GeomContains(A,B)and GeomContains(B,A);
  End;
  4:Begin
   If Not GeomIntersects(A,B)Then Exit;
   If(A.Cls=3)and(B.Cls=3)Then GeomPredicate:=OverlapArea(A,B)<=1E-9*MaxR(GeomArea(A),GeomArea(B))
    Else
   If(A.Cls=3)or(B.Cls=3)Then Begin
    { ligne ou point contre un polygone : aucun point strictement interieur }
    If A.Cls=3Then Begin Buf:=A;P:=B.First;End Else Begin Buf:=B;P:=A.First;End;
    Hit:=True;
    While P<>Nil do Begin
     For I:=0 to P^.N-1do Begin
      If PtInPolys(Buf,P^.Pts^[I].X,P^.Pts^[I].Y,1E-12)=1Then Hit:=False;
      If(I<P^.N-1)and(P^.N>1)Then
       If PtInPolys(Buf,(P^.Pts^[I].X+P^.Pts^[I+1].X)/2,(P^.Pts^[I].Y+P^.Pts^[I+1].Y)/2,1E-12)=1Then Hit:=False;
     End;
     P:=P^.Next;
    End;
    GeomPredicate:=Hit;
   End
    Else
   If(A.Cls=2)and(B.Cls=2)Then GeomPredicate:=Not SegmentsMeet(A,B,True)
    Else
   GeomPredicate:=False;
  End;
  5:Begin
   If A.Cls<>B.Cls Then Exit;
   If Not GeomIntersects(A,B)Then Exit;
   If A.Cls=3Then Begin
    Ia:=OverlapArea(A,B);
    GeomPredicate:=(Ia>1E-9*MaxR(GeomArea(A),GeomArea(B)))and Not GeomContains(A,B)and Not GeomContains(B,A);
   End
    Else
   If A.Cls=2Then GeomPredicate:=Not GeomContains(A,B)and Not GeomContains(B,A)and Not SegmentsMeet(A,B,True)
    Else
   GeomPredicate:=False;
  End;
  7:Begin
   If(A.Cls=2)and(B.Cls=2)Then GeomPredicate:=SegmentsMeet(A,B,True)
    Else
   If((A.Cls=2)and(B.Cls=3))or((A.Cls=3)and(B.Cls=2))Then Begin
    If A.Cls=2Then Begin Buf:=B;P:=A.First;End Else Begin Buf:=A;P:=B.First;End;
    AnyIn:=False;AnyOut:=False;
    While P<>Nil do Begin
     For I:=0 to P^.N-1do Begin
      S:=PtInPolys(Buf,P^.Pts^[I].X,P^.Pts^[I].Y,1E-12);
      If S=1Then AnyIn:=True;
      If S=0Then AnyOut:=True;
     End;
     P:=P^.Next;
    End;
    GeomPredicate:=AnyIn and AnyOut;
   End;
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


{ ------------------------------------------------------------------ }
{ Expressions (native:extractbyexpression)                            }
{ ------------------------------------------------------------------ }

Var
 ExprS:String;
 ExprP:Integer;
 ExprProps:PJ;
 ExprGeom:TGeom;
 ExprId:LongInt;

Procedure EFail(Msg:String);Begin
 Fail('Error: invalid expression ('+Msg+') near position '+IntToStr(ExprP));
End;

Function VNull:TVal;
Var V:TVal;
Begin V.K:=0;V.N:=0;V.G:=Nil;V.S:='';VNull:=V;End;

Function VNum(R:Real):TVal;
Var V:TVal;
Begin V.K:=1;V.N:=R;V.G:=Nil;V.S:='';VNum:=V;End;

Function VStr(S:String):TVal;
Var V:TVal;
Begin V.K:=2;V.N:=0;V.G:=Nil;V.S:=S;VStr:=V;End;

Function VBool(B:Boolean):TVal;
Var V:TVal;
Begin
 V.K:=3;V.S:='';V.G:=Nil;
 If B Then V.N:=1 Else V.N:=0;
 VBool:=V;
End;

Function ToNum(V:TVal;Var R:Real):Boolean;
Var
 E:Integer;
Begin
 ToNum:=False;
 Case V.K of
  1,3:Begin R:=V.N;ToNum:=True;End;
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
  Else ToStr:='';
 End;
End;

Function Unesc(S:String):String;
Var
 I:Integer;
 T:String;
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
    Else T:=T+S[I];
   End;
  End
   Else
  T:=T+S[I];
  Inc(I);
 End;
 Unesc:=T;
End;

Function PropVal(Name:String):TVal;
Var
 N:PJ;
 R:Real;
 E:Integer;
Begin
 PropVal:=VNull;
 N:=JFind(ExprProps,Name);
 If N=Nil Then Exit;
 Case N^.Kind of
  1:PropVal:=VBool(JVal(N)='true');
  2:Begin
   Val(JVal(N),R,E);
   If E=0Then PropVal:=VNum(R);
  End;
  3:PropVal:=VStr(Unesc(JVal(N)));
 End;
End;

Procedure ESkip;Begin
 While(ExprP<=Length(ExprS))and(ExprS[ExprP]in[' ',#9])do Inc(ExprP);
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

Function LikeMatch(Const S,Pat:String;I,J:Integer):Boolean;
Begin
 If J>Length(Pat)Then LikeMatch:=I>Length(S)
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

Function EvalOr:TVal;Forward;

Function VGeom(Var G:TGeom):TVal;
Var
 V:TVal;
Begin
 V.K:=4;V.N:=0;V.S:='';
 New(V.G);
 GeomCopy(G,V.G^);
 VGeom:=V;
End;

Function NumArg(Var A:Array of TVal;I:Integer;Var R:Real):Boolean;Begin
 NumArg:=False;
 If(I<=High(A))and(A[I].K<>0)and(A[I].K<>4)Then NumArg:=ToNum(A[I],R);
End;

Function CallFunc(Name:String;Var A:Array of TVal;N:Integer):TVal;
Var
 R,R2,Cx,Cy,W:Real;
 S,T,Out:String;
 I,P,L:Integer;
 Res:TGeom;
 Ok:Boolean;
 Px:PPath;
Begin
 CallFunc:=VNull;
 If(Name='LOWER')or(Name='UPPER')Then Begin
  If A[0].K=0Then Exit;
  S:=ToStr(A[0]);
  If Name='UPPER'Then S:=StrUpper(S)
   Else
  For I:=1 to Length(S)do If S[I]in['A'..'Z']Then S[I]:=Chr(Ord(S[I])+32);
  CallFunc:=VStr(S);
 End Else
 If(Name='LENGTH')or(Name='LEN')Then Begin
  If A[0].K=0Then Exit;
  If A[0].K=4Then CallFunc:=VNum(GeomLength(A[0].G^))
             Else CallFunc:=VNum(Length(ToStr(A[0])));
 End Else
 If Name='CONCAT'Then Begin
  S:='';
  For I:=0 to N-1do If A[I].K<>0Then S:=S+ToStr(A[I]);
  CallFunc:=VStr(S);
 End Else
 If Name='SUBSTR'Then Begin
  If(A[0].K=0)or Not NumArg(A,1,R)Then Exit;
  S:=ToStr(A[0]);
  P:=Round(R);
  If P<1Then P:=1;
  L:=255;
  If NumArg(A,2,R2)Then L:=Round(R2);
  CallFunc:=VStr(Copy(S,P,L));
 End Else
 If Name='REPLACE'Then Begin
  If(A[0].K=0)or(N<3)Then Exit;
  S:=ToStr(A[0]);T:=ToStr(A[1]);
  Out:='';
  I:=1;
  While I<=Length(S)do Begin
   If(T<>'')and(Copy(S,I,Length(T))=T)Then Begin
    Out:=Out+ToStr(A[2]);
    Inc(I,Length(T));
   End
    Else
   Begin
    Out:=Out+S[I];
    Inc(I);
   End;
  End;
  CallFunc:=VStr(Out);
 End Else
 If Name='TRIM'Then Begin
  If A[0].K=0Then Exit;
  S:=ToStr(A[0]);
  While(S<>'')and(S[1]=' ')do S:=Copy(S,2,255);
  While(S<>'')and(S[Length(S)]=' ')do S:=Copy(S,1,Length(S)-1);
  CallFunc:=VStr(S);
 End Else
 If(Name='LEFT')or(Name='RIGHT')Then Begin
  If(A[0].K=0)or Not NumArg(A,1,R)Then Exit;
  S:=ToStr(A[0]);
  L:=Round(R);
  If L<0Then L:=0;
  If L>Length(S)Then L:=Length(S);
  If Name='LEFT'Then CallFunc:=VStr(Copy(S,1,L))
                Else CallFunc:=VStr(Copy(S,Length(S)-L+1,L));
 End Else
 If Name='TO_STRING'Then Begin
  If A[0].K<>0Then CallFunc:=VStr(ToStr(A[0]));
 End Else
 If(Name='TO_REAL')or(Name='TO_INT')Then Begin
  If(A[0].K<>0)and(A[0].K<>4)and ToNum(A[0],R)Then Begin
   If Name='TO_INT'Then R:=Int(R);
   CallFunc:=VNum(R);
  End;
 End Else
 If Name='ABS'Then Begin
  If NumArg(A,0,R)Then CallFunc:=VNum(Abs(R));
 End Else
 If Name='SQRT'Then Begin
  If NumArg(A,0,R)and(R>=0)Then CallFunc:=VNum(Sqrt(R));
 End Else
 If Name='ROUND'Then Begin
  If NumArg(A,0,R)Then Begin
   If NumArg(A,1,R2)Then Begin
    W:=1;
    For I:=1 to Round(R2)do W:=W*10;
    CallFunc:=VNum(FloorR(R*W+0.5)/W);
   End
    Else
   CallFunc:=VNum(FloorR(R+0.5));
  End;
 End Else
 If Name='FLOOR'Then Begin If NumArg(A,0,R)Then CallFunc:=VNum(FloorR(R));End Else
 If Name='CEIL'Then Begin If NumArg(A,0,R)Then CallFunc:=VNum(-FloorR(-R));End Else
 If Name='SIN'Then Begin If NumArg(A,0,R)Then CallFunc:=VNum(Sin(R));End Else
 If Name='COS'Then Begin If NumArg(A,0,R)Then CallFunc:=VNum(Cos(R));End Else
 If Name='TAN'Then Begin If NumArg(A,0,R)and(Cos(R)<>0)Then CallFunc:=VNum(Sin(R)/Cos(R));End Else
 If Name='ATAN'Then Begin If NumArg(A,0,R)Then CallFunc:=VNum(ArcTan(R));End Else
 If Name='EXP'Then Begin If NumArg(A,0,R)and(R<700)Then CallFunc:=VNum(Exp(R));End Else
 If(Name='LN')or(Name='LOG')Then Begin If NumArg(A,0,R)and(R>0)Then CallFunc:=VNum(Ln(R));End Else
 If Name='LOG10'Then Begin If NumArg(A,0,R)and(R>0)Then CallFunc:=VNum(Ln(R)/Ln(10));End Else
 If Name='PI'Then CallFunc:=VNum(Pi) Else
 If Name='POWER'Then Begin
  If NumArg(A,0,R)and NumArg(A,1,R2)Then Begin
   If R>0Then CallFunc:=VNum(Exp(R2*Ln(R))) Else
   If(R=0)and(R2>0)Then CallFunc:=VNum(0);
  End;
 End Else
 If(Name='MIN')or(Name='MAX')Then Begin
  Ok:=False;R:=0;
  For I:=0 to N-1do
   If NumArg(A,I,R2)Then Begin
    If Not Ok or((Name='MIN')and(R2<R))or((Name='MAX')and(R2>R))Then R:=R2;
    Ok:=True;
   End;
  If Ok Then CallFunc:=VNum(R);
 End Else
 If Name='COALESCE'Then Begin
  For I:=0 to N-1do
   If A[I].K<>0Then Begin CallFunc:=A[I];Exit;End;
 End Else
 If Name='IF'Then Begin
  If(N>=3)and(A[0].K<>0)Then
   If A[0].N<>0Then CallFunc:=A[1] Else CallFunc:=A[2];
 End Else
 If Name='MAKE_POINT'Then Begin
  If NumArg(A,0,R)and NumArg(A,1,R2)Then Begin
   PointGeom(Res,R,R2);
   CallFunc:=VGeom(Res);
   FreeGeom(Res);
  End;
 End Else
 If A[0].K=4Then Begin
  { fonctions de geometrie }
  If Name='AREA'Then CallFunc:=VNum(GeomArea(A[0].G^)) Else
  If Name='PERIMETER'Then CallFunc:=VNum(GeomLength(A[0].G^)) Else
  If Name='NUM_POINTS'Then Begin
   R:=0;
   Px:=A[0].G^.First;
   While Px<>Nil do Begin R:=R+Px^.N;Px:=Px^.Next;End;
   CallFunc:=VNum(R);
  End Else
  If(Name='X')or(Name='Y')Then Begin
   CentroidGeom(A[0].G^,Cx,Cy,Ok);
   If Ok Then Begin
    If Name='X'Then CallFunc:=VNum(Cx) Else CallFunc:=VNum(Cy);
   End;
  End Else
  If Name='CENTROID'Then Begin
   CentroidGeom(A[0].G^,Cx,Cy,Ok);
   If Ok Then Begin PointGeom(Res,Cx,Cy);CallFunc:=VGeom(Res);FreeGeom(Res);End;
  End Else
  If Name='POINT_ON_SURFACE'Then Begin
   PointOnSurface(A[0].G^,Cx,Cy);
   PointGeom(Res,Cx,Cy);CallFunc:=VGeom(Res);FreeGeom(Res);
  End Else
  If Name='CONVEX_HULL'Then Begin
   HullGeom(A[0].G^,Res);
   If Res.Cls<>0Then CallFunc:=VGeom(Res);
   FreeGeom(Res);
  End Else
  If Name='ENVELOPE'Then Begin
   If GeomBBox(A[0].G^,Cx,Cy,R,R2)Then Begin
    InitGeom(Res);Res.Cls:=3;Res.NPoly:=1;
    Px:=NewPath(Res,5,0);
    Px^.Pts^[0].X:=Cx;Px^.Pts^[0].Y:=Cy;Px^.Pts^[1].X:=R;Px^.Pts^[1].Y:=Cy;
    Px^.Pts^[2].X:=R;Px^.Pts^[2].Y:=R2;Px^.Pts^[3].X:=Cx;Px^.Pts^[3].Y:=R2;
    Px^.Pts^[4]:=Px^.Pts^[0];
    CallFunc:=VGeom(Res);FreeGeom(Res);
   End;
  End Else
  If Name='TRANSLATE'Then Begin
   If NumArg(A,1,R)and NumArg(A,2,R2)Then Begin
    GeomCopy(A[0].G^,Res);
    AffineGeom(Res,1,0,0,1,R,R2);
    CallFunc:=VGeom(Res);FreeGeom(Res);
   End;
  End Else
  If Name='BUFFER'Then Begin
   If NumArg(A,1,R)Then Begin
    L:=5;
    If NumArg(A,2,R2)Then L:=Round(R2);
    BufferGeom(A[0].G^,R,L,Res);
    If Res.First<>Nil Then CallFunc:=VGeom(Res);
    FreeGeom(Res);
   End;
  End Else
  If Name='SIMPLIFY'Then Begin
   If NumArg(A,1,R)Then Begin
    InitGeom(Res);Res.Cls:=A[0].G^.Cls;
    Px:=A[0].G^.First;
    While Px<>Nil do Begin
     If A[0].G^.Cls=1Then CopyPath(Res,Px,0)
      Else
     Ok:=SimplifyDP(Px,R,A[0].G^.Cls=3,Res,Px^.Poly);
     Px:=Px^.Next;
    End;
    Res.NPoly:=A[0].G^.NPoly;
    If Res.First<>Nil Then CallFunc:=VGeom(Res);
    FreeGeom(Res);
   End;
  End;
 End
  Else
 EFail('unknown function '+Name);
End;

Function EvalPrimary:TVal;
Var
 V:TVal;
 S,Name:String;
 C:Char;
 R:Real;
 E:Integer;
 Start,NA:Integer;
 Args:Array[0..5]of TVal;
 Cx,Cy:Real;
 Ok:Boolean;
Begin
 EvalPrimary:=VNull;
 ESkip;
 If ExprP>Length(ExprS)Then EFail('unexpected end of expression');
 C:=ExprS[ExprP];
 If C='('Then Begin
  Inc(ExprP);
  V:=EvalOr;
  If Not EOp(')')Then EFail('")" expected');
  EvalPrimary:=V;
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
  EvalPrimary:=VNum(R);
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
   Begin
    S:=S+ExprS[ExprP];
    Inc(ExprP);
   End;
  End;
  EvalPrimary:=VStr(S);
 End
  Else
 If C='"'Then Begin
  Inc(ExprP);
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(ExprS[ExprP]<>'"')do Inc(ExprP);
  If ExprP>Length(ExprS)Then EFail('unterminated field name');
  Name:=Copy(ExprS,Start,ExprP-Start);
  Inc(ExprP);
  EvalPrimary:=PropVal(Name);
 End
  Else
 If C='$'Then Begin
  Inc(ExprP);
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(UpCase(ExprS[ExprP])in['A'..'Z','0'..'9','_'])do Inc(ExprP);
  Name:=StrUpper(Copy(ExprS,Start,ExprP-Start));
  If Name='GEOMETRY'Then Begin
   If ExprGeom.First=Nil Then EvalPrimary:=VNull Else EvalPrimary:=VGeom(ExprGeom);
  End Else
  If Name='AREA'Then EvalPrimary:=VNum(GeomArea(ExprGeom)) Else
  If Name='LENGTH'Then Begin
   If ExprGeom.Cls=2Then EvalPrimary:=VNum(GeomLength(ExprGeom)) Else EvalPrimary:=VNull;
  End Else
  If Name='PERIMETER'Then Begin
   If ExprGeom.Cls=3Then EvalPrimary:=VNum(GeomLength(ExprGeom)) Else EvalPrimary:=VNull;
  End Else
  If Name='ID'Then EvalPrimary:=VNum(ExprId) Else
  If(Name='X')or(Name='Y')Then Begin
   CentroidGeom(ExprGeom,Cx,Cy,Ok);
   If Ok Then Begin
    If Name='X'Then EvalPrimary:=VNum(Cx) Else EvalPrimary:=VNum(Cy);
   End
    Else
   EvalPrimary:=VNull;
  End
   Else
  EFail('unknown variable $'+Name);
 End
  Else
 If UpCase(C)in['A'..'Z','_']Then Begin
  Start:=ExprP;
  While(ExprP<=Length(ExprS))and(UpCase(ExprS[ExprP])in['A'..'Z','0'..'9','_'])do Inc(ExprP);
  Name:=Copy(ExprS,Start,ExprP-Start);
  If StrUpper(Name)='TRUE'Then EvalPrimary:=VBool(True) Else
  If StrUpper(Name)='FALSE'Then EvalPrimary:=VBool(False) Else
  If StrUpper(Name)='NULL'Then EvalPrimary:=VNull
   Else
  Begin
   ESkip;
   If(ExprP<=Length(ExprS))and(ExprS[ExprP]='(')Then Begin
    Inc(ExprP);
    NA:=0;
    Args[0]:=VNull;
    ESkip;
    If(ExprP<=Length(ExprS))and(ExprS[ExprP]=')')Then Inc(ExprP)
     Else
    Begin
     Repeat
      If NA>5Then EFail('too many arguments');
      Args[NA]:=EvalOr;
      Inc(NA);
     Until Not EOp(',');
     If Not EOp(')')Then EFail('")" expected');
    End;
    EvalPrimary:=CallFunc(StrUpper(Name),Args,NA);
   End
    Else
   EvalPrimary:=PropVal(Name);
  End;
 End
  Else
 EFail('unexpected character "'+C+'"');
End;

Function EvalUnary:TVal;
Var
 V:TVal;
 R:Real;
Begin
 EvalUnary:=VNull;
 If EOp('-')Then Begin
  V:=EvalUnary;
  If ToNum(V,R)and(V.K<>0)Then EvalUnary:=VNum(-R) Else EvalUnary:=VNull;
 End
  Else
 EvalUnary:=EvalPrimary;
End;

Function EvalMul:TVal;
Var
 V,W:TVal;
 A,B:Real;
 Op:Char;
Begin
 V:=EvalUnary;
 While(EOp('*')or EOp('/')or EOp('%'))do Begin
  Op:=ExprS[ExprP-1];
  W:=EvalUnary;
  If ToNum(V,A)and ToNum(W,B)and(V.K<>0)and(W.K<>0)Then Begin
   If Op='*'Then V:=VNum(A*B) Else
   If B=0Then V:=VNull Else
   If Op='/'Then V:=VNum(A/B)
            Else V:=VNum(A-B*Int(A/B));
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
Begin
 V:=EvalMul;
 Repeat
  ESkip;
  If EOp('||')Then Begin
   W:=EvalMul;
   If(V.K=0)or(W.K=0)Then V:=VNull Else V:=VStr(ToStr(V)+ToStr(W));
  End
   Else
  If EOp('+')or EOp('-')Then Begin
   Op:=ExprS[ExprP-1];
   W:=EvalMul;
   If ToNum(V,A)and ToNum(W,B)and(V.K<>0)and(W.K<>0)Then Begin
    If Op='+'Then V:=VNum(A+B) Else V:=VNum(A-B);
   End
    Else
   V:=VNull;
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
 If EKw('IS')Then Begin
  Neg:=EKw('NOT');
  If Not EKw('NULL')Then EFail('NULL expected');
  V:=VBool((V.K=0)<>Neg);
 End
  Else
 If EKw('LIKE')Then Begin
  W:=EvalAdd;
  If(V.K=0)or(W.K=0)Then V:=VNull Else V:=VBool(LikeMatch(ToStr(V),ToStr(W),1,1));
 End
  Else
 If EKw('ILIKE')Then Begin
  W:=EvalAdd;
  If(V.K=0)or(W.K=0)Then V:=VNull
                    Else V:=VBool(LikeMatch(StrUpper(ToStr(V)),StrUpper(ToStr(W)),1,1));
 End
  Else
 Begin
  Neg:=False;
  Found:=False;
  If EKw('NOT')Then Begin
   Neg:=True;
   If Not EKw('IN')Then EFail('IN expected');
   Found:=True;
  End
   Else
  If EKw('IN')Then Found:=True;
  If Found Then Begin
   If Not EOp('(')Then EFail('"(" expected');
   Found:=False;
   Repeat
    W:=EvalAdd;
    X:=DoCompare(1,V,W);
    If(X.K=3)and(X.N<>0)Then Found:=True;
   Until Not EOp(',');
   If Not EOp(')')Then EFail('")" expected');
   If V.K=0Then V:=VNull Else V:=VBool(Found<>Neg);
  End;
 End;
 EvalCompare:=V;
End;

Function EvalNot:TVal;
Var
 V:TVal;
Begin
 EvalNot:=VNull;
 If EKw('NOT')Then Begin
  V:=EvalNot;
  If V.K=0Then EvalNot:=V Else EvalNot:=VBool(V.N=0);
 End
  Else
 EvalNot:=EvalCompare;
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

Function EvalFeature(Expr:String;Props:PJ):Boolean;
Var
 V:TVal;
Begin
 ExprS:=Expr;
 ExprP:=1;
 ExprProps:=Props;
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

Procedure ReadRaster(FileName:String;Var R:TRaster);
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

Procedure WriteRaster(FileName:String;Var R:TRaster);
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
 WriteLn('Usage: QGIS_PROCESS [--help] [--version] [--json] [command] [algorithm id] [parameters]');
 WriteLn;
 WriteLn('Options:');
 WriteLn('  --help, -h, /?   Display this help');
 WriteLn('  --version        Display the version');
 WriteLn('  --json           Output results in JSON format');
 WriteLn;
 WriteLn('Available commands:');
 WriteLn('  plugins          List available (and active) plugins');
 WriteLn('  list             List all available processing algorithms');
 WriteLn('  help             Show help for an algorithm (help ALGORITHM_ID)');
 WriteLn('  run              Run an algorithm (run ALGORITHM_ID --PARAM=VALUE ...)');
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

Procedure ShowPlugins;Begin
 If JsonMode Then WriteLn('{"plugins":{}}')
  Else
 Begin
  WriteLn('Available plugins');
  WriteLn;
  WriteLn('(none)');
 End;
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
Function NeedStr(A:Integer;Name:String):String;
Var
 V:String;
 P:ParamRec;
Begin
 If Not ParamDef(A,Name,P)Then Fail('Internal error: unknown parameter '+Name);
 If Not GetArg(Name,V)Then Begin
  If P.Def=''Then Fail('Error: missing required parameter '+Name);
  If P.Def='*'Then V:='' Else V:=P.Def;
 End;
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
 X1,Y1,X2,Y2,D:Real;
Begin
 X1:=NeedReal(A,'X1');Y1:=NeedReal(A,'Y1');
 X2:=NeedReal(A,'X2');Y2:=NeedReal(A,'Y2');
 D:=Haversine(X1,Y1,X2,Y2);
 AddRes('DISTANCE',RealToStr(D));
 AddRes('DISTANCE_KM',RealToStr(D/1000));
End;

Procedure RunBearing(A:Integer);
Var
 X1,Y1,X2,Y2:Real;
Begin
 X1:=NeedReal(A,'X1');Y1:=NeedReal(A,'Y1');
 X2:=NeedReal(A,'X2');Y2:=NeedReal(A,'Y2');
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
 Src,Dst:Integer;
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
 Src,Dst:Integer;
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
 Root,Arr,F,Nx,FailArr:PJ;
 Expr,Out,OutFail:String;
 WantFail:Boolean;
 FailRoot:PJ;
 Props:PJ;
 Keep:Boolean;
 C:PJ;
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
 F:=Arr^.First;
 Arr^.First:=Nil;Arr^.Last:=Nil;
 While F<>Nil do Begin
  Nx:=F^.Next;
  Props:=JFind(F,'properties');
  Keep:=EvalFeature(Expr,Props);
  If Keep Then JAdd(Arr,F)
   Else
  If WantFail Then JAdd(FailArr,F);
  F:=Nx;
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

Procedure RunPixelsToPoints(A:Integer);
Var
 R:TRaster;
 F:Text;
 Out,Fld:String;
 I,J:LongInt;
 First:Boolean;
 V:Real;
Begin
 ReadRaster(NeedStr(A,'INPUT_RASTER'),R);
 If Round(NeedReal(A,'RASTER_BAND'))<>1Then Fail('Error: only band 1 is available');
 Fld:=NeedStr(A,'FIELD_NAME');
 Out:=NeedStr(A,'OUTPUT');
 {$I-}
 Assign(F,Out);
 Rewrite(F);
 {$I+}
 If IOResult<>0Then Fail('Error: unable to create output file '+Out);
 WriteLn(F,'{"type":"FeatureCollection","features":[');
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
 AddRes('OUTPUT',Out);
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
 If Round(NeedReal(A,'BAND'))<>1Then Fail('Error: only band 1 is available');
End;

Procedure NewRaster(Var R:TRaster;NC,NR:LongInt;XLL,YLL,Cell,Nd:Real);
Var
 I,T:LongInt;
Begin
 If(NC<1)or(NR<1)Then Fail('Error: invalid raster size');
 If(NC*1.0)*NR>MaxCells Then Fail('Error: raster is too large');
 R.NC:=NC;R.NR:=NR;R.XLL:=XLL;R.YLL:=YLL;R.Cell:=Cell;R.NoData:=Nd;
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
 Info('Layer SRS: EPSG:'+IntToStr(LayerCrs(Root)));
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
 Fld,Out:String;
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
 Out:=NeedStr(A,'OUTPUT');
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
 WriteLn(F,'{"type":"FeatureCollection","features":[');
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
 AddRes('OUTPUT',Out);
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
   If(K+1>ListCount)or(ListItems[K+1]<>'1')Then Fail('Error: only band 1 is available');
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
 Src,Dst,Resamp:Integer;
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

Function JTextEsc(S:String):PJ;
Var
 I:Integer;
 T:String;
Begin
 T:='';
 For I:=1 to Length(S)do Begin
  If Length(T)>=248Then Break;
  Case S[I]of
   '"':T:=T+'\"';
   '\':T:=T+'\\';
   #10:T:=T+'\n';
   #13:T:=T+'\r';
   #9:T:=T+'\t';
   Else T:=T+S[I];
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

Procedure FlattenFeature(F:PJ;Var G:TGeom);Begin
 Flatten(JFind(F,'geometry'),G);
End;

Function ValToJ(V:TVal):PJ;Begin
 Case V.K of
  1:ValToJ:=JNum(V.N);
  2:ValToJ:=JTextEsc(V.S);
  3:ValToJ:=JBool(V.N<>0);
  Else ValToJ:=NewJ(0);
 End;
End;

{ Evalue une expression sur une entite }
Function EvalOn(Expr:String;F:PJ;Id:LongInt):TVal;
Var
 V:TVal;
Begin
 FreeGeom(ExprGeom);
 Flatten(JFind(F,'geometry'),ExprGeom);
 ExprId:=Id;
 ExprS:=Expr;
 ExprP:=1;
 ExprProps:=JFind(F,'properties');
 V:=EvalOr;
 ESkip;
 If ExprP<=Length(ExprS)Then EFail('unexpected token');
 EvalOn:=V;
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
 Dst,Src:Integer;
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
 If(V.K=0)or(V.K=4)Then Exit;
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
 Dst,Src:Integer;
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
  Overlay(1,G,B,R);
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
   If InsideOrOn(Edges,N,P^.Pts^[0].X,P^.Pts^[0].Y,Tol)Then CopyPath(R,P,0);
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
 Typ,Ho,Vo,Dst:Integer;
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
 Sph:Boolean;
 X,Y:Real;
 Ok:Boolean;
Begin
 LoadIn(A,'INPUT',Root,Arr);
 Method:=Round(NeedReal(A,'CALC_METHOD'));
 Sph:=(Method=2)and(LayerCrs(Root)=4326);
 F:=Arr^.First;
 While F<>Nil do Begin
  FlattenFeature(F,G);
  Case G.Cls of
   1:Begin
    CentroidGeom(G,X,Y,Ok);
    PutProp(F,'xcoord',JNum(X));
    PutProp(F,'ycoord',JNum(Y));
   End;
   2:Begin
    If Sph Then PutProp(F,'length',JNum(SphereLength(G)))
           Else PutProp(F,'length',JNum(GeomLength(G)));
   End;
   3:Begin
    If Sph Then Begin
     PutProp(F,'area',JNum(SphereArea(G)));
     PutProp(F,'perimeter',JNum(SphereLength(G)));
    End
     Else
    Begin
     PutProp(F,'area',JNum(GeomArea(G)));
     PutProp(F,'perimeter',JNum(GeomLength(G)));
    End;
   End;
  End;
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

Procedure RunAlgo(A:Integer);
Var
 I,J:Integer;
 P:ParamRec;
Begin
 { Verifie qu'aucun parametre inconnu n'a ete passe }
 For I:=1 to ArgCount do
  If Not ParamDef(A,ArgName[I],P)Then
   If Not((ArgName[I]='DISTANCE_UNITS')or(ArgName[I]='AREA_UNITS')or
          (ArgName[I]='ELLIPSOID')or(ArgName[I]='PROJECT_PATH'))Then
    Fail('Error: unknown parameter '+ArgName[I]);
 ResCount:=0;
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
 End;
 If JsonMode Then Begin
  WriteLn('{"algorithm_details":{"id":',JsonStr(Algos[A].Id),
          ',"name":',JsonStr(Algos[A].Title),'},"inputs":{');
  For I:=1 to ArgCount do Begin
   Write(' ',JsonStr(ArgName[I]),':',JsonVal(ArgVal[I]));
   If I<ArgCount Then WriteLn(',') Else WriteLn;
  End;
  WriteLn('},"results":{');
  For J:=1 to ResCount do Begin
   Write(' ',JsonStr(ResName[J]),':',JsonVal(ResVal[J]));
   If J<ResCount Then WriteLn(',') Else WriteLn;
  End;
  WriteLn('}}');
 End
  Else
 Begin
  WriteLn('QGIS Processing Executor (clone) - ',VersionStr);
  WriteLn('Running ',Algos[A].Id,' [',Algos[A].Title,']');
  WriteLn;
  WriteLn('----------------');
  WriteLn('Inputs');
  WriteLn('----------------');
  WriteLn;
  For I:=1 to ArgCount do WriteLn(ArgName[I],':',#9,ArgVal[I]);
  WriteLn;
  WriteLn('----------------');
  WriteLn('Results');
  WriteLn('----------------');
  WriteLn;
  For J:=1 to ResCount do WriteLn(ResName[J],':',#9,ResVal[J]);
 End;
End;

{ Analyse la ligne de commande : options, commande, algorithme et parametres }
Procedure ParseArgs;
Var
 I,P:Integer;
 S,Name:String;
 N:Integer;
Begin
 JsonMode:=False;
 Cmd:='';AlgoId:='';
 ArgCount:=0;
 N:=0;
 For I:=1 to ParamCount do Begin
  S:=ParamStr(I);
  If StrUpper(S)='--JSON'Then JsonMode:=True Else
  If(StrUpper(S)='--NO-PYTHON')or(StrUpper(S)='--VERBOSE')Then Begin End Else
  If(S='/?')or(S='-h')or(S='/h')or(S='/H')or(StrUpper(S)='--HELP')Then Begin
   If Cmd=''Then Cmd:='--help';
  End
   Else
  If StrUpper(S)='--VERSION'Then Begin
   If Cmd=''Then Cmd:='--version';
  End
   Else
  Begin
   P:=Pos('=',S);
   If(P>0)and(N>0)Then Begin
    Name:=Copy(S,1,P-1);
    While(Name<>'')and(Name[1]in['-','/'])do Name:=Copy(Name,2,255);
    Inc(ArgCount);
    If ArgCount>MaxArg Then Fail('Error: too many parameters');
    ArgName[ArgCount]:=StrUpper(Name);
    ArgVal[ArgCount]:=Copy(S,P+1,255);
   End
    Else
   Begin
    Inc(N);
    If N=1Then Cmd:=S Else
    If N=2Then AlgoId:=S
          Else Fail('Error: unexpected argument '+S);
   End;
  End;
 End;
End;

Var
 A:Integer;
BEGIN
 ParseArgs;
 If(Cmd='')or(Cmd='--help')Then ShowGeneralHelp Else
 If Cmd='--version'Then Begin
  If JsonMode Then WriteLn('{"version":"',VersionStr,'"}')
              Else WriteLn('QGIS_PROCESS clone ',VersionStr);
 End
  Else
 If StrUpper(Cmd)='LIST'Then ShowList Else
 If StrUpper(Cmd)='PLUGINS'Then ShowPlugins Else
 If(StrUpper(Cmd)='HELP')or(StrUpper(Cmd)='RUN')Then Begin
  If AlgoId=''Then Fail('Error: missing algorithm id');
  A:=FindAlgo(AlgoId);
  If A=0Then Fail('Error: algorithm "'+AlgoId+'" not found');
  If StrUpper(Cmd)='HELP'Then ShowAlgoHelp(A)
                         Else RunAlgo(A);
 End
  Else
 Fail('Error: unknown command "'+Cmd+'"');
END.
