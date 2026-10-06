{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
  @description: CCT - Coordinate Conversion and Transformation
  Pipeline subset: unitconvert, axisswap, affine, helmert (3/7 params),
  cart, NTv2 horizontal grids, GTX vertical grids, UTM, Mercator,
  Transverse Mercator, longlat and noop.
}
Program Cct;

Const
 PI = 3.14159265358979323846;
 DEG = PI / 180.0;
 ARCSEC = DEG / 3600.0;
 MaxSteps = 16;
 MaxTokens = 32;

Type
 TOp = (opNone, opUnitConvert, opAxisSwap, opAffine, opHelmert,
   opCart, opUTM, opMerc, opTMerc, opLongLat,
  opHGridShift, opVGridShift, opGeogOffset, opVertOffset, opNoop,
  opLAEA, opAEQD, opStere, opOrtho, opGnom,
  opXYZGridShift, opDeformation);
 TStep = Record
  Op : TOp;
  Inverse, OmitForward, OmitInverse : Boolean;
  XYInRad, XYOutRad, ZInFeet, ZOutFeet : Boolean;
  HasXYIn, HasXYOut, HasZIn, HasZOut : Boolean;
  Zone : Integer;
  South : Boolean;
  A, F, K0, Lat0, Lon0, X0, Y0 : Real;
  SphereRadius : Real;
  HasSphereRadius : Boolean;
  DX, DY, DZ, DLat, DLon, DH, SlopeLat, SlopeLon, RX, RY, RZ, Scale : Real;
  RateX, RateY, RateZ, RateRX, RateRY, RateRZ, RateScale : Real;
  Epoch : Real;
  HasEpoch : Boolean;
  GridName : String[255];
  GridMultiplier : Real;
  HasGridMultiplier : Boolean;
  GridOptional : Boolean;
  HasGridParam : Boolean;
  GridRefOutput : Boolean;
  DeltaTime : Real;
  HasDeltaTime : Boolean;
  Order : String[16];
  Affine : Array[1..4] Of Real;
 End;
 TNTRecord = Packed Record
  Key : Array[1..8] Of Char;
  Value : Array[1..8] Of Char;
 End;
 TNTNode = Packed Record
  LatShift, LonShift, LatAccuracy, LonAccuracy : Single;
 End;
 TGTXHeader = Packed Record
  LatOrigin, LonOrigin, LatStep, LonStep : Double;
  Rows, Cols : LongInt;
 End;
 TTiffGrid = Record
  BigEndian, Tiled : Boolean;
  LongitudeWest, AngleDegrees : Boolean;
  HasNoData : Boolean;
  NoData : Real;
  GridType : String[48];
  Width, Height, Samples, Bits, SampleFormat, Compression, Planar : LongInt;
  RowsPerStrip, TileWidth, TileHeight : LongInt;
  BlockOffsetsPos, BlockCountsPos, BlockCount : LongInt;
  IFDNext : LongInt;
  LonOrigin, LatOrigin, LonStep, LatStep : Real;
  Valid : Boolean;
 End;
 TGTiffGrid = Record
  BigEndian : Boolean;
  Width, Height, Samples, Bits, SampleFormat, Compression, Planar : LongInt;
  RowsPerStrip, StripOffsetsPos, StripCountsPos, StripOffsetsCount : LongInt;
  DataOffset, IFDNext : LongInt;
  LonOrigin, LatOrigin, LonStep, LatStep : Real;
  Valid : Boolean;
 End;
 TTokens = Array[1..MaxTokens] Of String[255];

Var
 Steps : Array[1..MaxSteps] Of TStep;
 GlobalParams : Array[1..16] Of String[255];
 GlobalParamCount : Integer;
 StepCount, Decimals : Integer;
 Cols : Array[1..4] Of Integer;
 ColCount : Integer;
 ZConstant, TConstant : Real;
 HaveZConstant, HaveTConstant, InverseAll, Verbose, VeryVerbose : Boolean;
 InputName, OutputName, ErrorText : String;
 InputFile, OutputFile : Text;
 OwnInput, OwnOutput : Boolean;

Function UpperString(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do S[I] := UpCase(S[I]);
 UpperString := S;
End;

Function LowerString(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do If S[I] In ['A'..'Z'] Then S[I] := Chr(Ord(S[I]) + 32);
 LowerString := S;
End;

Function ParseReal(S : String; Var V : Real) : Boolean;
Var Err : Integer;
Begin Val(S, V, Err); ParseReal := Err = 0; End;

Function PowerR(A, B : Real) : Real;
Begin
 If A > 0.0 Then PowerR := Exp(B * Ln(A))
 Else If (A = 0.0) And (B > 0.0) Then PowerR := 0.0
 Else PowerR := 0.0;
End;

Function TanR(X : Real) : Real; Begin TanR := Sin(X) / Cos(X); End;
Function D2R(X : Real) : Real; Begin D2R := X * DEG; End;
Function R2D(X : Real) : Real; Begin R2D := X / DEG; End;

Function Atan2R(Y, X : Real) : Real;
Var A : Real;
Begin
 If X > 0 Then A := ArcTan(Y / X)
 Else If X < 0 Then Begin
  A := ArcTan(Y / X);
  If Y >= 0 Then A := A + PI Else A := A - PI;
 End Else If Y > 0 Then A := PI / 2
 Else If Y < 0 Then A := -PI / 2 Else A := 0;
 Atan2R := A;
End;

Function ArcSinR(X : Real) : Real;
Var V : Real;
Begin
 V:=1-X*X; If V<0 Then V:=0;
 ArcSinR:=Atan2R(X,Sqrt(V));
End;

Function AuthalicRadius(A, Flattening : Real) : Real;
Var E2, E, Qp : Real;
Begin
 E2:=Flattening*(2-Flattening);
 If E2<=0 Then AuthalicRadius:=A
 Else Begin
  E:=Sqrt(E2);
  Qp:=1+(1-E2)*(0.5*Ln((1+E)/(1-E))/E);
  AuthalicRadius:=A*Sqrt(Qp/2);
 End;
End;

Function AuthalicQ(Phi, E2 : Real) : Real;
Var E, SinPhi : Real;
Begin
 If E2<=0 Then Begin AuthalicQ:=2*Sin(Phi); Exit; End;
 E:=Sqrt(E2); SinPhi:=Sin(Phi);
 AuthalicQ:=(1-E2)*(SinPhi/(1-E2*SinPhi*SinPhi)-
  Ln((1-E*SinPhi)/(1+E*SinPhi))/(2*E));
End;

Function AuthalicLatitude(Phi, A, Flattening : Real) : Real;
Var E2, QP, S : Real;
Begin
 E2:=Flattening*(2-Flattening);
 QP:=AuthalicQ(PI/2,E2); S:=AuthalicQ(Phi,E2)/QP;
 If S>1 Then S:=1 Else If S< -1 Then S:=-1;
 AuthalicLatitude:=ArcSinR(S);
End;

Function GeodeticLatitude(Beta, A, Flattening : Real) : Real;
Var E2, QP, Lo, Hi, Mid, QTarget : Real;
 I : Integer;
Begin
 E2:=Flattening*(2-Flattening);
 If E2<=0 Then Begin GeodeticLatitude:=Beta; Exit; End;
 QP:=AuthalicQ(PI/2,E2); QTarget:=Sin(Beta)*QP;
 Lo:=-PI/2; Hi:=PI/2;
 For I:=1 To 48 Do Begin
  Mid:=(Lo+Hi)/2;
  If AuthalicQ(Mid,E2)<QTarget Then Lo:=Mid Else Hi:=Mid;
 End;
 GeodeticLatitude:=(Lo+Hi)/2;
End;

Function SwapLong(V : LongInt) : LongInt;
Var B : Array[1..4] Of Byte; T : Byte;
Begin
 Move(V,B,4); T:=B[1]; B[1]:=B[4]; B[4]:=T; T:=B[2]; B[2]:=B[3]; B[3]:=T;
 Move(B,V,4); SwapLong:=V;
End;

Function SwapSingle(V : Single) : Single;
Var B : Array[1..4] Of Byte; T : Byte;
Begin
 Move(V,B,4); T:=B[1]; B[1]:=B[4]; B[4]:=T; T:=B[2]; B[2]:=B[3]; B[3]:=T;
 Move(B,V,4); SwapSingle:=V;
End;

Function SwapDouble(V : Double) : Double;
Var B : Array[1..8] Of Byte; I : Integer; T : Byte;
Begin
 Move(V,B,8);
 For I:=1 To 4 Do Begin T:=B[I]; B[I]:=B[9-I]; B[9-I]:=T; End;
 Move(B,V,8); SwapDouble:=V;
End;

Function TIFFU16(Var F : File; Posn : LongInt; BigEndian : Boolean) : Word;
Var B : Array[1..2] Of Byte; N : Word;
Begin
 Seek(F,Posn); BlockRead(F,B,2,N);
 If N<>2 Then Begin TIFFU16:=0; Exit; End;
 If BigEndian Then TIFFU16:=Word(B[1])*256+B[2]
 Else TIFFU16:=Word(B[2])*256+B[1];
End;

Function TIFFU32(Var F : File; Posn : LongInt; BigEndian : Boolean) : LongInt;
Var B : Array[1..4] Of Byte; N : Word;
Begin
 Seek(F,Posn); BlockRead(F,B,4,N);
 If N<>4 Then Begin TIFFU32:=0; Exit; End;
 If BigEndian Then TIFFU32:=LongInt(B[1])*16777216+LongInt(B[2])*65536+LongInt(B[3])*256+B[4]
 Else TIFFU32:=LongInt(B[4])*16777216+LongInt(B[3])*65536+LongInt(B[2])*256+B[1];
End;

Function TIFFDouble(Var F : File; Posn : LongInt; BigEndian : Boolean) : Real;
Var V : Double; N : Word;
Begin
 Seek(F,Posn); BlockRead(F,V,8,N); If N<>8 Then Begin TIFFDouble:=0; Exit; End;
 If BigEndian Then V:=SwapDouble(V);
 TIFFDouble:=V;
End;

Function TIFFSingle(Var F : File; Posn : LongInt; BigEndian : Boolean) : Real;
Var V : Single; N : Word;
Begin
 Seek(F,Posn); BlockRead(F,V,4,N); If N<>4 Then Begin TIFFSingle:=0; Exit; End;
 If BigEndian Then V:=SwapSingle(V);
 TIFFSingle:=V;
End;

Function TIFFFindTag(Var F : File; IFDPos : LongInt; Tag : Word;
                     BigEndian : Boolean; Var EntryPos : LongInt;
                     Var FieldType : Word; Var Count, Value : LongInt) : Boolean;
Var I, N, EntryCount : LongInt;
Begin
 TIFFFindTag:=False; EntryPos:=0;
 EntryCount:=TIFFU16(F,IFDPos,BigEndian);
 For I:=0 To EntryCount-1 Do Begin
  N:=IFDPos+2+I*12;
  If TIFFU16(F,N,BigEndian)=Tag Then Begin
   EntryPos:=N; FieldType:=TIFFU16(F,N+2,BigEndian);
   Count:=TIFFU32(F,N+4,BigEndian); Value:=TIFFU32(F,N+8,BigEndian);
   TIFFFindTag:=True; Exit;
  End;
 End;
End;

Function TIFFTagInteger(Var F : File; IFDPos : LongInt; Tag : Word;
                        BigEndian : Boolean; DefaultValue : LongInt) : LongInt;
Var EntryPos, Count, Value : LongInt; FieldType : Word;
Begin
 If Not TIFFFindTag(F,IFDPos,Tag,BigEndian,EntryPos,FieldType,Count,Value) Then Begin
  TIFFTagInteger:=DefaultValue; Exit;
 End;
 If Count=1 Then Begin
  If FieldType=3 Then TIFFTagInteger:=TIFFU16(F,EntryPos+8,BigEndian)
  Else TIFFTagInteger:=Value;
 End Else If FieldType=3 Then Begin
  If Count<=2 Then TIFFTagInteger:=TIFFU16(F,EntryPos+8,BigEndian)
  Else TIFFTagInteger:=TIFFU16(F,Value,BigEndian);
 End
 Else TIFFTagInteger:=TIFFU32(F,Value,BigEndian);
End;

Function TIFFTagArrayValue(Var F : File; EntryPos : LongInt; BigEndian : Boolean;
                           Index : LongInt) : LongInt;
Var FieldType : Word; Count, Value : LongInt;
Begin
 FieldType:=TIFFU16(F,EntryPos+2,BigEndian);
 Count:=TIFFU32(F,EntryPos+4,BigEndian); Value:=TIFFU32(F,EntryPos+8,BigEndian);
 If (Index<0) Or (Index>=Count) Then Begin TIFFTagArrayValue:=0; Exit; End;
 If Count=1 Then Begin
  If FieldType=3 Then TIFFTagArrayValue:=TIFFU16(F,EntryPos+8,BigEndian)
  Else TIFFTagArrayValue:=Value;
 End Else If FieldType=3 Then Begin
  If Count<=2 Then TIFFTagArrayValue:=TIFFU16(F,EntryPos+8+Index*2,BigEndian)
  Else TIFFTagArrayValue:=TIFFU16(F,Value+Index*2,BigEndian);
 End
 Else TIFFTagArrayValue:=TIFFU32(F,Value+Index*4,BigEndian);
End;

Function TIFFTagDouble(Var F : File; EntryPos : LongInt; BigEndian : Boolean;
                       Index : LongInt) : Real;
Var Value, Count : LongInt;
Begin
 Count:=TIFFU32(F,EntryPos+4,BigEndian); Value:=TIFFU32(F,EntryPos+8,BigEndian);
 If (Index<0) Or (Index>=Count) Then TIFFTagDouble:=0
 Else If Count=1 Then TIFFTagDouble:=TIFFDouble(F,EntryPos+8,BigEndian)
 Else TIFFTagDouble:=TIFFDouble(F,Value+Index*8,BigEndian);
End;

Function TIFFParseGrid(Var F : File; IFDPos : LongInt; BigEndian : Boolean;
                Var G : TTiffGrid) : Boolean;
Var EntryPos, Count, Value, NextPos : LongInt; WType : Word;
 ScaleEntry, TieEntry, BitsEntry : LongInt;
 MetaEntry, MetaCount, MetaOffset, MI : LongInt;
 MetaText : String[255]; Ch : Char; NRead : Word;
 InlineValue : Boolean;
 NoDataText : String[32]; NoDataEntry, NI : LongInt;
Begin
 FillChar(G,SizeOf(G),0); G.BigEndian:=BigEndian; G.Valid:=False;
 G.Width:=TIFFTagInteger(F,IFDPos,256,BigEndian,0);
 G.Height:=TIFFTagInteger(F,IFDPos,257,BigEndian,0);
 G.Compression:=TIFFTagInteger(F,IFDPos,259,BigEndian,1);
 G.Samples:=TIFFTagInteger(F,IFDPos,277,BigEndian,1);
 G.RowsPerStrip:=TIFFTagInteger(F,IFDPos,278,BigEndian,G.Height);
 G.Planar:=TIFFTagInteger(F,IFDPos,284,BigEndian,1);
 G.SampleFormat:=TIFFTagInteger(F,IFDPos,339,BigEndian,1);
 G.LongitudeWest:=False; G.AngleDegrees:=False;
 G.HasNoData:=False; G.NoData:=0;
 G.GridType:='';
 BitsEntry:=0;
 If TIFFFindTag(F,IFDPos,258,BigEndian,EntryPos,WType,Count,Value) Then BitsEntry:=EntryPos;
 If BitsEntry<>0 Then G.Bits:=TIFFTagArrayValue(F,BitsEntry,BigEndian,0) Else G.Bits:=1;
 If TIFFFindTag(F,IFDPos,324,BigEndian,EntryPos,WType,Count,Value) Then Begin
  G.Tiled:=True; G.BlockOffsetsPos:=EntryPos;
  G.TileWidth:=TIFFTagInteger(F,IFDPos,322,BigEndian,0);
  G.TileHeight:=TIFFTagInteger(F,IFDPos,323,BigEndian,0);
  G.BlockCount:=Count;
  If TIFFFindTag(F,IFDPos,325,BigEndian,EntryPos,WType,Count,Value) Then G.BlockCountsPos:=EntryPos;
 End Else If TIFFFindTag(F,IFDPos,273,BigEndian,EntryPos,WType,Count,Value) Then Begin
  G.Tiled:=False; G.BlockOffsetsPos:=EntryPos; G.BlockCount:=Count;
  If TIFFFindTag(F,IFDPos,279,BigEndian,EntryPos,WType,Count,Value) Then G.BlockCountsPos:=EntryPos;
 End Else G.BlockCount:=0;
 If TIFFFindTag(F,IFDPos,33550,BigEndian,ScaleEntry,WType,Count,Value) And
   TIFFFindTag(F,IFDPos,33922,BigEndian,TieEntry,WType,Count,Value) Then Begin
  G.LonStep:=TIFFTagDouble(F,ScaleEntry,BigEndian,0);
  G.LatStep:=TIFFTagDouble(F,ScaleEntry,BigEndian,1);
  G.LonOrigin:=TIFFTagDouble(F,TieEntry,BigEndian,3);
  G.LatOrigin:=TIFFTagDouble(F,TieEntry,BigEndian,4);
 End;
 MetaText:='';
 If TIFFFindTag(F,IFDPos,42112,BigEndian,MetaEntry,WType,MetaCount,MetaOffset) Then Begin
  InlineValue:=MetaCount<=4;
  If Not InlineValue Then MetaOffset:=TIFFU32(F,MetaEntry+8,BigEndian)
  Else MetaOffset:=MetaEntry+8;
  If MetaCount>255 Then MetaCount:=255;
  For MI:=0 To MetaCount-1 Do Begin
   Seek(F,MetaOffset+MI); BlockRead(F,Ch,1,NRead);
   If NRead=1 Then MetaText:=MetaText+Ch;
  End;
  If (Pos('positive_value',MetaText)>0) And (Pos('west',LowerString(MetaText))>0) Then G.LongitudeWest:=True;
  If Pos('degree',LowerString(MetaText))>0 Then G.AngleDegrees:=True;
  MI:=Pos('name="TYPE">',MetaText);
  If MI>0 Then Begin
   MI:=MI+Length('name="TYPE">');
   While (MI<=Length(MetaText)) And (MetaText[MI]<>'<') And (Length(G.GridType)<48) Do Begin
    G.GridType:=G.GridType+MetaText[MI]; Inc(MI);
   End;
   G.GridType:=UpperString(G.GridType);
  End;
 End;
 If TIFFFindTag(F,IFDPos,42113,BigEndian,NoDataEntry,WType,MetaCount,MetaOffset) Then Begin
  If MetaCount<=4 Then MetaOffset:=NoDataEntry+8
  Else MetaOffset:=TIFFU32(F,NoDataEntry+8,BigEndian);
  NoDataText:='';
  If MetaCount>31 Then MetaCount:=31;
  For NI:=0 To MetaCount-1 Do Begin
   Seek(F,MetaOffset+NI); BlockRead(F,Ch,1,NRead);
   If (NRead=1) And (Ch<>#0) Then NoDataText:=NoDataText+Ch;
  End;
  G.HasNoData:=ParseReal(NoDataText,G.NoData);
 End;
 NextPos:=2+TIFFU16(F,IFDPos,BigEndian)*12;
 G.IFDNext:=TIFFU32(F,IFDPos+NextPos,BigEndian);
 G.Valid:=(G.Width>1) And (G.Height>1) And (G.Samples>0) And
  (G.Bits=32) And (G.SampleFormat=3) And (G.Compression=1) And
  ((G.Planar=1) Or (G.Planar=2)) And (G.LonStep>0) And (G.LatStep>0) And
  (G.BlockCount>0);
 If G.Tiled Then G.Valid:=G.Valid And (G.TileWidth>0) And (G.TileHeight>0)
 Else G.Valid:=G.Valid And (G.RowsPerStrip>0);
 TIFFParseGrid:=G.Valid;
End;

Function TIFFPixel(Var F : File; G : TTiffGrid; Col,Row,Band : LongInt;
             Var V : Real) : Boolean;
Var Block, BlocksPerPlane, Across, LocalCol, LocalRow : LongInt;
 DataPos, BytePos : LongInt;
Begin
 TIFFPixel:=False;
 If (Col<0) Or (Col>=G.Width) Or (Row<0) Or (Row>=G.Height) Or
   (Band<0) Or (Band>=G.Samples) Then Exit;
 If G.Tiled Then Begin
  Across:=(G.Width+G.TileWidth-1) Div G.TileWidth;
  Block:=(Row Div G.TileHeight)*Across+(Col Div G.TileWidth);
  LocalCol:=Col Mod G.TileWidth; LocalRow:=Row Mod G.TileHeight;
  BlocksPerPlane:=Across*((G.Height+G.TileHeight-1) Div G.TileHeight);
  If G.Planar=2 Then Block:=Band*BlocksPerPlane+Block;
  DataPos:=TIFFTagArrayValue(F,G.BlockOffsetsPos,G.BigEndian,Block);
  If G.Planar=2 Then BytePos:=(LocalRow*G.TileWidth+LocalCol)*4
  Else BytePos:=((LocalRow*G.TileWidth+LocalCol)*G.Samples+Band)*4;
 End Else Begin
  BlocksPerPlane:=(G.Height+G.RowsPerStrip-1) Div G.RowsPerStrip;
  Block:=Row Div G.RowsPerStrip; LocalRow:=Row Mod G.RowsPerStrip;
  If G.Planar=2 Then Block:=Band*BlocksPerPlane+Block;
  DataPos:=TIFFTagArrayValue(F,G.BlockOffsetsPos,G.BigEndian,Block);
  If G.Planar=2 Then BytePos:=(LocalRow*G.Width+Col)*4
  Else BytePos:=(LocalRow*G.Width*G.Samples+Col*G.Samples+Band)*4;
 End;
 V:=TIFFSingle(F,DataPos+BytePos,G.BigEndian);
 If G.HasNoData And (Abs(V-G.NoData)<1.0E-20) Then Exit;
 TIFFPixel:=True;
End;

Function ReadGTG(FileName : String; LonDeg,LatDeg : Real; Band : Integer;
                 ExpectedType : String;
            Var Value : Real; Var AngleDegrees,LongitudeWest : Boolean) : Boolean;
Var F : File; B0,B1,B2,B3 : Real; N : Word;
 Marker : Array[1..2] Of Char;
 BigEndian : Boolean; IFDPos,BestIFD,Magic : LongInt;
 G,BestG : TTiffGrid; ColF,RowF,FX,FY,Resolution : Real;
 C0,R0,ErrCode : LongInt; SampleOK : Boolean;
Begin
 ReadGTG:=False; Value:=0; AngleDegrees:=False; LongitudeWest:=False;
 Assign(F,FileName); {$I-} Reset(F,1); ErrCode:=IOResult; {$I+}
 If ErrCode<>0 Then Exit;
 BlockRead(F,Marker,2,N);
 If N<>2 Then Begin Close(F); Exit; End;
 If (Marker[1]='I') And (Marker[2]='I') Then BigEndian:=False
 Else If (Marker[1]='M') And (Marker[2]='M') Then BigEndian:=True
 Else Begin Close(F); Exit; End;
 Magic:=TIFFU16(F,2,BigEndian);
 If Magic<>42 Then Begin Close(F); Exit; End;
 IFDPos:=TIFFU32(F,4,BigEndian); BestIFD:=0; Resolution:=1.0E30;
 While IFDPos<>0 Do Begin
  If TIFFParseGrid(F,IFDPos,BigEndian,G) Then Begin
   ColF:=(LonDeg-G.LonOrigin)/G.LonStep;
   RowF:=(G.LatOrigin-LatDeg)/G.LatStep;
   If (ColF>=0) And (ColF<=G.Width-1) And
      (RowF>=0) And (RowF<=G.Height-1) And
      (Band>=1) And (Band<=G.Samples) Then
    If G.LonStep*G.LatStep<Resolution Then Begin
     Resolution:=G.LonStep*G.LatStep; BestIFD:=IFDPos; BestG:=G;
    End;
  End;
  IFDPos:=G.IFDNext;
 End;
 If BestIFD=0 Then Begin Close(F); Exit; End;
 If (ExpectedType<>'') And (BestG.GridType<>UpperString(ExpectedType)) Then Begin Close(F); Exit; End;
 AngleDegrees:=BestG.AngleDegrees; LongitudeWest:=BestG.LongitudeWest;
 ColF:=(LonDeg-BestG.LonOrigin)/BestG.LonStep;
 RowF:=(BestG.LatOrigin-LatDeg)/BestG.LatStep;
 C0:=Trunc(ColF); R0:=Trunc(RowF);
 If C0>=BestG.Width-1 Then Begin C0:=BestG.Width-2; ColF:=BestG.Width-1; End;
 If R0>=BestG.Height-1 Then Begin R0:=BestG.Height-2; RowF:=BestG.Height-1; End;
 If (C0<0) Or (R0<0) Then Begin Close(F); Exit; End;
 FX:=ColF-C0; FY:=RowF-R0;
 SampleOK:=TIFFPixel(F,BestG,C0,R0,Band-1,B0) And
  TIFFPixel(F,BestG,C0+1,R0,Band-1,B1) And
  TIFFPixel(F,BestG,C0,R0+1,Band-1,B2) And
  TIFFPixel(F,BestG,C0+1,R0+1,Band-1,B3);
 Close(F);
 If Not SampleOK Then Exit;
 Value:=B0*(1-FX)*(1-FY)+B1*FX*(1-FY)+B2*(1-FX)*FY+B3*FX*FY;
 ReadGTG:=True;
End;

Function NextGridName(Var List : String; Var OptionalGrid : Boolean) : String; Forward;

Function FindGTG(GridList : String; LonDeg,LatDeg : Real; Band : Integer;
                 ExpectedType : String;
                 Var Value : Real; Var AngleDegrees,LongitudeWest : Boolean) : Boolean;
Var Name : String; OptionalGrid,Found : Boolean;
Begin
 FindGTG:=False;
 While GridList<>'' Do Begin
  Name:=NextGridName(GridList,OptionalGrid);
  If (Name<>'') And (UpperString(Name)<>'NULL') Then Begin
  Found:=ReadGTG(Name,LonDeg,LatDeg,Band,ExpectedType,Value,AngleDegrees,LongitudeWest);
   If Found Then Begin FindGTG:=True; Exit; End;
  End;
 End;
End;

Function NTKey(R : TNTRecord) : String;
Var I : Integer; S : String;
Begin
 S:=''; For I:=1 To 8 Do If R.Key[I]<>#0 Then S:=S+R.Key[I];
 While (S<>'') And (S[Length(S)]=' ') Do Delete(S,Length(S),1);
 NTKey:=S;
End;

Function NTInt(R : TNTRecord; BigEndian : Boolean) : LongInt;
Var V : LongInt;
Begin Move(R.Value[1],V,4); If BigEndian Then V:=SwapLong(V); NTInt:=V; End;

Function NTDouble(R : TNTRecord; BigEndian : Boolean) : Real;
Var V : Double;
Begin Move(R.Value[1],V,8); If BigEndian Then V:=SwapDouble(V); NTDouble:=V; End;

Function NTFloat(V : Single; BigEndian : Boolean) : Real;
Begin If BigEndian Then V:=SwapSingle(V); NTFloat:=V; End;

Function ReadNTv2Shift(FileName : String; LonRad, LatRad : Real;
                       Var DLonDeg, DLatDeg : Real) : Boolean;
Var
 F : File; R : TNTRecord; N00,N10,N01,N11 : TNTNode;
 N, I, NumOverview, NumSub, GSCount, BestRows, BestCols : LongInt;
 DataPos, BestPos, PosNow : LongInt;
 SouthLat, NorthLat, EastLong, WestLong, LatInc, LonInc : Real;
 BestSouth, BestEast, BestLatInc, BestLonInc, LonDeg, LatDeg : Real;
 ColF, RowF, FX, FY, V : Real; C0,R0 : LongInt;
 BigEndian, HeaderOK, HS,HN,HE,HW,HI,HO : Boolean;
 Key : String;
Begin
 ReadNTv2Shift:=False; DLonDeg:=0; DLatDeg:=0;
 BestLatInc:=1.0E30; BestPos:=-1;
 Assign(F,FileName);
 {$I-} Reset(F,1); I:=IOResult; {$I+}
 If I<>0 Then Exit;
 BlockRead(F,R,SizeOf(R),N); If N<>SizeOf(R) Then Begin Close(F); Exit; End;
 If NTKey(R)<>'NUM_OREC' Then Begin Close(F); Exit; End;
 NumOverview:=NTInt(R,False); BigEndian:=False;
 If NumOverview<>11 Then Begin
  If SwapLong(NumOverview)=11 Then Begin BigEndian:=True; NumOverview:=11; End;
 End;
 If NumOverview<>11 Then Begin Close(F); Exit; End;
 Seek(F,0);
 BlockRead(F,R,SizeOf(R),N); If N<>SizeOf(R) Then Begin Close(F); Exit; End;
 BlockRead(F,R,SizeOf(R),N); If N<>SizeOf(R) Then Begin Close(F); Exit; End;
 NumSub:=NTInt(R,BigEndian);
 If (NumSub<11) Or (NumSub>32) Then Begin Close(F); Exit; End;
 DataPos:=NumOverview*SizeOf(TNTRecord);
 Seek(F,DataPos);
 While Not EOF(F) Do Begin
  SouthLat:=0; NorthLat:=0; EastLong:=0; WestLong:=0;
  LatInc:=0; LonInc:=0; GSCount:=0;
  HS:=False; HN:=False; HE:=False; HW:=False; HI:=False; HO:=False; HeaderOK:=True;
  For I:=1 To NumSub Do Begin
  BlockRead(F,R,SizeOf(R),N); If N<>SizeOf(R) Then Begin HeaderOK:=False; Break; End;
   Key:=NTKey(R);
   If Key='S_LAT' Then Begin SouthLat:=NTDouble(R,BigEndian); HS:=True; End Else
   If Key='N_LAT' Then Begin NorthLat:=NTDouble(R,BigEndian); HN:=True; End Else
   If Key='E_LONG' Then Begin EastLong:=NTDouble(R,BigEndian); HE:=True; End Else
   If Key='W_LONG' Then Begin WestLong:=NTDouble(R,BigEndian); HW:=True; End Else
   If Key='LAT_INC' Then Begin LatInc:=NTDouble(R,BigEndian); HI:=True; End Else
   If Key='LONG_INC' Then Begin LonInc:=NTDouble(R,BigEndian); HO:=True; End Else
   If Key='GS_COUNT' Then GSCount:=NTInt(R,BigEndian);
  End;
  If Not HeaderOK Then Break;
  PosNow:=FilePos(F);
  LatDeg:=R2D(LatRad); LonDeg:=R2D(LonRad);
  If HS And HN And HE And HW And HI And HO And (GSCount>0) And
     (LatInc>0) And (LonInc>0) And (LatDeg*3600>=SouthLat) And
     (LatDeg*3600<=NorthLat) And (LonDeg*3600>=-WestLong) And
     (LonDeg*3600<=-EastLong) Then Begin
   If LatInc<BestLatInc Then Begin
    BestLatInc:=LatInc; BestLonInc:=LonInc; BestSouth:=SouthLat; BestEast:=-EastLong;
    BestCols:=Trunc((WestLong-EastLong)/LonInc+0.5)+1;
    BestRows:=Trunc((NorthLat-SouthLat)/LatInc+0.5)+1;
    BestPos:=PosNow;
   End;
  End;
  Seek(F,PosNow+GSCount*SizeOf(TNTNode));
 End;
 If BestPos<0 Then Begin Close(F); Exit; End;
 ColF:=(BestEast-LonDeg*3600)/BestLonInc;
 RowF:=(LatDeg*3600-BestSouth)/BestLatInc;
 C0:=Trunc(ColF); R0:=Trunc(RowF);
 If C0>=BestCols-1 Then Begin C0:=BestCols-2; ColF:=BestCols-1; End;
 If R0>=BestRows-1 Then Begin R0:=BestRows-2; RowF:=BestRows-1; End;
 If (C0<0) Or (R0<0) Or (BestCols<2) Or (BestRows<2) Then Begin Close(F); Exit; End;
 FX:=ColF-C0; FY:=RowF-R0;
 Seek(F,BestPos+(R0*BestCols+C0)*SizeOf(TNTNode)); BlockRead(F,N00,SizeOf(N00),N);
 Seek(F,BestPos+(R0*BestCols+C0+1)*SizeOf(TNTNode)); BlockRead(F,N10,SizeOf(N10),N);
 Seek(F,BestPos+((R0+1)*BestCols+C0)*SizeOf(TNTNode)); BlockRead(F,N01,SizeOf(N01),N);
 Seek(F,BestPos+((R0+1)*BestCols+C0+1)*SizeOf(TNTNode)); BlockRead(F,N11,SizeOf(N11),N);
 Close(F);
 V:=NTFloat(N00.LonShift,BigEndian)*(1-FX)*(1-FY)+NTFloat(N10.LonShift,BigEndian)*FX*(1-FY)+NTFloat(N01.LonShift,BigEndian)*(1-FX)*FY+NTFloat(N11.LonShift,BigEndian)*FX*FY;
 DLonDeg:=-V/3600.0;
 V:=NTFloat(N00.LatShift,BigEndian)*(1-FX)*(1-FY)+NTFloat(N10.LatShift,BigEndian)*FX*(1-FY)+NTFloat(N01.LatShift,BigEndian)*(1-FX)*FY+NTFloat(N11.LatShift,BigEndian)*FX*FY;
 DLatDeg:=V/3600.0;
 ReadNTv2Shift:=True;
End;

Function ReadGTX(FileName : String; LonRad,LatRad : Real;
                 Var Offset : Real) : Boolean;
Var F : File; H : TGTXHeader; N : Word; I : Integer;
 Lat0,Lon0,DLat,DLon,RowF,ColF,FX,FY : Real;
 V00,V10,V01,V11 : Single;
 R0,C0 : LongInt; BigEndian : Boolean;
Begin
 ReadGTX:=False; Offset:=0;
 Assign(F,FileName); {$I-} Reset(F,1); I:=IOResult; {$I+}
 If I<>0 Then Exit;
 BlockRead(F,H,SizeOf(H),N); If N<>SizeOf(H) Then Begin Close(F); Exit; End;
 BigEndian:=True;
 H.LatOrigin:=SwapDouble(H.LatOrigin); H.LonOrigin:=SwapDouble(H.LonOrigin);
 H.LatStep:=SwapDouble(H.LatStep); H.LonStep:=SwapDouble(H.LonStep);
 H.Rows:=SwapLong(H.Rows); H.Cols:=SwapLong(H.Cols);
 If (H.Rows<2) Or (H.Cols<2) Or (H.LatStep<=0) Or (H.LonStep<=0) Then Begin Close(F); Exit; End;
 Lat0:=H.LatOrigin; Lon0:=H.LonOrigin; DLat:=H.LatStep; DLon:=H.LonStep;
 ColF:=(R2D(LonRad)-Lon0)/DLon; RowF:=(Lat0+((H.Rows-1)*DLat)-R2D(LatRad))/DLat;
 C0:=Trunc(ColF); R0:=Trunc(RowF);
 If (C0<0) Or (C0>=H.Cols-1) Or (R0<0) Or (R0>=H.Rows-1) Then Begin Close(F); Exit; End;
 FX:=ColF-C0; FY:=RowF-R0;
 Seek(F,40+(R0*H.Cols+C0)*4); BlockRead(F,V00,4,N);
 Seek(F,40+(R0*H.Cols+C0+1)*4); BlockRead(F,V10,4,N);
 Seek(F,40+((R0+1)*H.Cols+C0)*4); BlockRead(F,V01,4,N);
 Seek(F,40+((R0+1)*H.Cols+C0+1)*4); BlockRead(F,V11,4,N);
 Close(F);
 If BigEndian Then Begin V00:=SwapSingle(V00); V10:=SwapSingle(V10); V01:=SwapSingle(V01); V11:=SwapSingle(V11); End;
 Offset:=V00*(1-FX)*(1-FY)+V10*FX*(1-FY)+V01*(1-FX)*FY+V11*FX*FY;
 If Abs(Offset+88.8888)<0.0001 Then Begin Offset:=0; Exit; End;
 ReadGTX:=True;
End;

Function NextGridName(Var List : String; Var OptionalGrid : Boolean) : String;
Var I : Integer; S : String;
Begin
 I:=Pos(',',List);
 If I=0 Then Begin S:=List; List:=''; End
 Else Begin S:=Copy(List,1,I-1); Delete(List,1,I); End;
 OptionalGrid:=(S<>'') And (S[1]='@');
 If OptionalGrid Then Delete(S,1,1);
 NextGridName:=S;
End;

Function FindNTv2Shift(GridList : String; LonRad,LatRad : Real;
                       Var DLonDeg,DLatDeg : Real) : Boolean;
Var Name : String; OptionalGrid, Found, Degrees, PositiveWest : Boolean;
 VLat, VLon : Real;
Begin
 FindNTv2Shift:=False;
 While GridList<>'' Do Begin
  Name:=NextGridName(GridList,OptionalGrid);
  If (Name<>'') And (UpperString(Name)<>'NULL') Then Begin
     If (Pos('.TIF',UpperString(Name))>0) Then Begin
      Found:=ReadGTG(Name,R2D(LonRad),R2D(LatRad),1,'HORIZONTAL_OFFSET',VLat,Degrees,PositiveWest) And
        ReadGTG(Name,R2D(LonRad),R2D(LatRad),2,'HORIZONTAL_OFFSET',VLon,Degrees,PositiveWest);
      If Found Then Begin
       If Not Degrees Then Begin VLat:=VLat/3600; VLon:=VLon/3600; End;
       If PositiveWest Then VLon:=-VLon;
       DLatDeg:=VLat; DLonDeg:=VLon;
      End;
     End Else Begin
      Found:=ReadNTv2Shift(Name,LonRad,LatRad,DLonDeg,DLatDeg);
      If Found Then DLonDeg:=-DLonDeg;
     End;
   If Found Then Begin FindNTv2Shift:=True; Exit; End;
  End;
 End;
End;

Function FindGTX(GridList : String; LonRad,LatRad : Real; Var Offset : Real) : Boolean;
Var Name : String; OptionalGrid, Found, Degrees, PositiveWest : Boolean;
Begin
 FindGTX:=False;
 While GridList<>'' Do Begin
  Name:=NextGridName(GridList,OptionalGrid);
  If (Name<>'') And (UpperString(Name)<>'NULL') Then Begin
  If Pos('.TIF',UpperString(Name))>0 Then Begin
   Found:=ReadGTG(Name,R2D(LonRad),R2D(LatRad),1,'VERTICAL_OFFSET_GEOGRAPHIC_TO_VERTICAL',Offset,Degrees,PositiveWest);
   If Not Found Then Found:=ReadGTG(Name,R2D(LonRad),R2D(LatRad),1,'VERTICAL_OFFSET_VERTICAL_TO_VERTICAL',Offset,Degrees,PositiveWest);
  End Else Found:=ReadGTX(Name,LonRad,LatRad,Offset);
   If Found Then Begin FindGTX:=True; Exit; End;
  End;
 End;
End;

Function FindGTGTriple(GridList : String; LonDeg,LatDeg : Real;
                       ExpectedType : String; Var V1,V2,V3 : Real) : Boolean;
Var Name : String; OptionalGrid,Found,Degrees,West : Boolean;
Begin
 FindGTGTriple:=False;
 While GridList<>'' Do Begin
  Name:=NextGridName(GridList,OptionalGrid);
  If (Name<>'') And (UpperString(Name)<>'NULL') Then Begin
  Found:=ReadGTG(Name,LonDeg,LatDeg,1,ExpectedType,V1,Degrees,West) And
   ReadGTG(Name,LonDeg,LatDeg,2,ExpectedType,V2,Degrees,West) And
   ReadGTG(Name,LonDeg,LatDeg,3,ExpectedType,V3,Degrees,West);
   If Found Then Begin FindGTGTriple:=True; Exit; End;
  End;
 End;
End;

Procedure XYZToGeodetic(X, Y, Z, A, F : Real; Var Lon, Lat, H : Real); Forward;

Function ReadXYZGridOffset(Var S : TStep; X,Y,Z : Real;
                           Var DX,DY,DZ : Real) : Boolean;
Var Lon,Lat,H,V1,V2,V3 : Real; OK : Boolean;
Begin
 XYZToGeodetic(X,Y,Z,S.A,S.F,Lon,Lat,H);
 OK:=FindGTGTriple(S.GridName,R2D(Lon),R2D(Lat),'GEOCENTRIC_TRANSLATION',V1,V2,V3);
 ReadXYZGridOffset:=OK;
 If OK Then Begin DX:=V1; DY:=V2; DZ:=V3; End;
End;

Function ReadVelocity(Var S : TStep; X,Y,Z : Real;
                      Var VX,VY,VZ : Real) : Boolean;
Var Lon,Lat,H,E,N,U : Real; OK : Boolean;
Begin
 XYZToGeodetic(X,Y,Z,S.A,S.F,Lon,Lat,H);
 OK:=FindGTGTriple(S.GridName,R2D(Lon),R2D(Lat),'VELOCITY',E,N,U);
 ReadVelocity:=OK;
 If OK Then Begin
  { GTG VELOCITY samples use local east/north/up, normally mm per year. }
  E:=E*0.001; N:=N*0.001; U:=U*0.001;
  VX:=-Sin(Lat)*Cos(Lon)*N-Sin(Lon)*E+Cos(Lat)*Cos(Lon)*U;
  VY:=-Sin(Lat)*Sin(Lon)*N+Cos(Lon)*E+Cos(Lat)*Sin(Lon)*U;
  VZ:=Cos(Lat)*N+Sin(Lat)*U;
 End;
End;

Procedure InitStep(Var S : TStep);
Var I : Integer;
Begin
 S.Op := opNone; S.Inverse := False; S.OmitForward := False; S.OmitInverse := False;
 S.XYInRad := False; S.XYOutRad := False; S.ZInFeet := False; S.ZOutFeet := False;
 S.HasXYIn := False; S.HasXYOut := False; S.HasZIn := False; S.HasZOut := False;
 S.Zone := 0; S.South := False; S.A := 6378137.0; S.F := 1.0 / 298.257223563;
 S.K0 := 1.0; S.Lat0 := 0.0; S.Lon0 := 0.0; S.X0 := 0.0; S.Y0 := 0.0;
 S.SphereRadius := 6371007.1809; S.HasSphereRadius := False;
 S.DX := 0.0; S.DY := 0.0; S.DZ := 0.0; S.DLat := 0.0; S.DLon := 0.0; S.DH := 0.0;
 S.SlopeLat := 0.0; S.SlopeLon := 0.0;
 S.RX := 0.0; S.RY := 0.0; S.RZ := 0.0;
 S.Scale := 0.0; S.RateX := 0.0; S.RateY := 0.0; S.RateZ := 0.0;
 S.RateRX := 0.0; S.RateRY := 0.0; S.RateRZ := 0.0; S.RateScale := 0.0;
 S.Epoch := 0.0; S.HasEpoch := False; S.DeltaTime:=0; S.HasDeltaTime:=False;
 S.GridRefOutput:=False; S.Order := '1,2';
 S.GridName := ''; S.GridMultiplier := -1.0; S.HasGridMultiplier:=False; S.GridOptional := False;
 S.HasGridParam := False;
 For I := 1 To 4 Do S.Affine[I] := 0.0;
 S.Affine[1] := 1.0; S.Affine[4] := 1.0;
End;

Function GetParam(Arg, Key : String) : String;
Begin
 If Copy(Arg, 1, Length(Key)) = Key Then
  GetParam := Copy(Arg, Length(Key) + 1, Length(Arg) - Length(Key))
 Else GetParam := '';
End;

Procedure ParseStepParam(Var S : TStep; Arg : String);
Var V, U : String; R : Real; Err : Integer;
Begin
 V := GetParam(Arg, '+proj=');
 If V <> '' Then Begin
  U := LowerString(V);
  If U = 'unitconvert' Then S.Op := opUnitConvert Else
  If U = 'axisswap' Then S.Op := opAxisSwap Else
  If U = 'affine' Then S.Op := opAffine Else
  If U = 'helmert' Then S.Op := opHelmert Else
  If U = 'cart' Then S.Op := opCart Else
  If (U = 'hgridshift') Or (U = 'nadgrids') Then S.Op := opHGridShift Else
  If (U = 'vgridshift') Or (U = 'geoidgrids') Then S.Op := opVGridShift Else
  If U = 'geogoffset' Then S.Op := opGeogOffset Else
  If U = 'vertoffset' Then S.Op := opVertOffset Else
  If U = 'noop' Then S.Op := opNoop Else
  If U = 'xyzgridshift' Then S.Op := opXYZGridShift Else
  If U = 'deformation' Then S.Op := opDeformation Else
  If (U = 'laea') Or (U = 'lambert_azimuthal_equal_area') Then S.Op := opLAEA Else
  If (U = 'aeqd') Or (U = 'azimuthal_equidistant') Then S.Op := opAEQD Else
  If (U = 'stere') Or (U = 'stereographic') Then S.Op := opStere Else
  If (U = 'ortho') Or (U = 'orthographic') Then S.Op := opOrtho Else
  If (U = 'gnom') Or (U = 'gnomonic') Then S.Op := opGnom Else
  If U = 'utm' Then S.Op := opUTM Else
  If U = 'merc' Then S.Op := opMerc Else
  If U = 'tmerc' Then S.Op := opTMerc Else
  If (U = 'longlat') Or (U = 'latlong') Then S.Op := opLongLat;
 End;
 If Arg = '+inv' Then S.Inverse := Not S.Inverse;
 If Arg = '+omit_fwd' Then S.OmitForward := True;
 If Arg = '+omit_inv' Then S.OmitInverse := True;
 If Arg = '+south' Then S.South := True;
 V := GetParam(Arg, '+zone='); If (V <> '') Then Begin Val(V, S.Zone, Err); If Err <> 0 Then S.Zone := 0; End;
 V := GetParam(Arg, '+ellps=');
 If V = 'GRS80' Then Begin S.A := 6378137.0; S.F := 1.0 / 298.257222101; End
 Else If V = 'clrk66' Then Begin S.A := 6378206.4; S.F := 1.0 / 294.978698214; End;
 V := GetParam(Arg, '+datum=');
 If V = 'WGS84' Then Begin S.A := 6378137.0; S.F := 1.0 / 298.257223563; End;
 V := GetParam(Arg, '+a='); If (V <> '') And ParseReal(V, R) Then S.A := R;
 V := GetParam(Arg, '+R='); If (V <> '') And ParseReal(V, R) Then Begin S.SphereRadius := R; S.HasSphereRadius := True; End;
 V := GetParam(Arg, '+f='); If (V <> '') And ParseReal(V, R) Then S.F := R;
 V := GetParam(Arg, '+rf='); If (V <> '') And ParseReal(V, R) And (R <> 0) Then S.F := 1.0 / R;
 V := GetParam(Arg, '+k_0='); If (V <> '') And ParseReal(V, R) Then S.K0 := R;
 V := GetParam(Arg, '+k='); If (V <> '') And ParseReal(V, R) Then S.K0 := R;
 V := GetParam(Arg, '+lat_0='); If (V <> '') And ParseReal(V, R) Then S.Lat0 := R;
 V := GetParam(Arg, '+lon_0='); If (V <> '') And ParseReal(V, R) Then S.Lon0 := R;
 V := GetParam(Arg, '+x_0='); If (V <> '') And ParseReal(V, R) Then S.X0 := R;
 V := GetParam(Arg, '+y_0='); If (V <> '') And ParseReal(V, R) Then S.Y0 := R;
 V := GetParam(Arg, '+x='); If (V <> '') And ParseReal(V, R) Then S.DX := R;
 V := GetParam(Arg, '+y='); If (V <> '') And ParseReal(V, R) Then S.DY := R;
 V := GetParam(Arg, '+z='); If (V <> '') And ParseReal(V, R) Then S.DZ := R;
 V := GetParam(Arg, '+dlon='); If (V <> '') And ParseReal(V, R) Then S.DLon := R;
 V := GetParam(Arg, '+dlat='); If (V <> '') And ParseReal(V, R) Then S.DLat := R;
 V := GetParam(Arg, '+dh='); If (V <> '') And ParseReal(V, R) Then S.DH := R;
 V := GetParam(Arg, '+slope_lat='); If (V <> '') And ParseReal(V, R) Then S.SlopeLat := R;
 V := GetParam(Arg, '+slope_lon='); If (V <> '') And ParseReal(V, R) Then S.SlopeLon := R;
 V := GetParam(Arg, '+rx='); If (V <> '') And ParseReal(V, R) Then S.RX := R;
 V := GetParam(Arg, '+ry='); If (V <> '') And ParseReal(V, R) Then S.RY := R;
 V := GetParam(Arg, '+rz='); If (V <> '') And ParseReal(V, R) Then S.RZ := R;
 V := GetParam(Arg, '+s='); If (V <> '') And ParseReal(V, R) Then S.Scale := R;
 V := GetParam(Arg, '+dx='); If (V <> '') And ParseReal(V, R) Then S.RateX := R;
 V := GetParam(Arg, '+dy='); If (V <> '') And ParseReal(V, R) Then S.RateY := R;
 V := GetParam(Arg, '+dz='); If (V <> '') And ParseReal(V, R) Then S.RateZ := R;
 V := GetParam(Arg, '+drx='); If (V <> '') And ParseReal(V, R) Then S.RateRX := R;
 V := GetParam(Arg, '+dry='); If (V <> '') And ParseReal(V, R) Then S.RateRY := R;
 V := GetParam(Arg, '+drz='); If (V <> '') And ParseReal(V, R) Then S.RateRZ := R;
 V := GetParam(Arg, '+ds='); If (V <> '') And ParseReal(V, R) Then S.RateScale := R;
 V := GetParam(Arg, '+t_epoch='); If (V <> '') And ParseReal(V, R) Then Begin S.Epoch := R; S.HasEpoch := True; End;
 V := GetParam(Arg, '+dt='); If (V <> '') And ParseReal(V, R) Then Begin S.DeltaTime:=R; S.HasDeltaTime:=True; End;
 V := GetParam(Arg, '+grid_ref='); If V='output_crs' Then S.GridRefOutput:=True;
 V := GetParam(Arg, '+grids='); If V = '' Then V := GetParam(Arg, '+nadgrids=');
 If V = '' Then V := GetParam(Arg, '+geoidgrids=');
 If V <> '' Then Begin
  S.HasGridParam := True;
  S.GridName := V;
  S.GridOptional := V[1] = '@';
  If (UpperString(V) = 'NULL') Or (UpperString(V) = '@NULL') Then S.GridName := '';
 End;
 V := GetParam(Arg, '+multiplier='); If (V <> '') And ParseReal(V,R) Then Begin S.GridMultiplier := R; S.HasGridMultiplier:=True; End;
 V := GetParam(Arg, '+convention='); If V <> '' Then S.Order := V;
 V := GetParam(Arg, '+xy_in='); If V <> '' Then Begin S.HasXYIn := True; S.XYInRad := V = 'rad'; End;
 V := GetParam(Arg, '+xy_out='); If V <> '' Then Begin S.HasXYOut := True; S.XYOutRad := V = 'rad'; End;
 V := GetParam(Arg, '+z_in='); If V <> '' Then Begin S.HasZIn := True; S.ZInFeet := V = 'ft'; End;
 V := GetParam(Arg, '+z_out='); If V <> '' Then Begin S.HasZOut := True; S.ZOutFeet := V = 'ft'; End;
 V := GetParam(Arg, '+order='); If V <> '' Then S.Order := V;
 V := GetParam(Arg, '+s11='); If (V <> '') And ParseReal(V, R) Then S.Affine[1] := R;
 V := GetParam(Arg, '+s12='); If (V <> '') And ParseReal(V, R) Then S.Affine[2] := R;
 V := GetParam(Arg, '+s21='); If (V <> '') And ParseReal(V, R) Then S.Affine[3] := R;
 V := GetParam(Arg, '+s22='); If (V <> '') And ParseReal(V, R) Then S.Affine[4] := R;
 V := GetParam(Arg, '+xoff='); If (V <> '') And ParseReal(V, R) Then S.DX := R;
 V := GetParam(Arg, '+yoff='); If (V <> '') And ParseReal(V, R) Then S.DY := R;
 V := GetParam(Arg, '+zoff='); If (V <> '') And ParseReal(V, R) Then S.DZ := R;
End;

Procedure ShowHelp;
Begin
 WriteLn('CCT - Cette commande permet d''effectuer des transformations de coordonn'+#130+'es ',
         'et pipelines autonomes.');
 WriteLn;
 WriteLn('Syntaxe: CCT [options] +proj=pipeline +step +proj=... [fichier]');
 WriteLn;
 WriteLn('Options: -c colonnes -d n -z valeur -t valeur -I -o fichier -v -vv -V -h');
 WriteLn('Coordonnees traitees: X Y [Z [T]]. Operations: unitconvert, axisswap, affine,');
 WriteLn('helmert, cart, geogoffset, vertoffset, hgridshift (NTv2 .gsb),');
 WriteLn('vgridshift (GTX/GTG), xyzgridshift et deformation (GTG VELOCITY),');
 WriteLn('laea, aeqd, stere, ortho, gnom,');
 WriteLn('utm, merc, tmerc, longlat, noop.');
 WriteLn('Les listes prioritaires +grids= sont acceptees pour NTv2, GTX et GTG.');
 WriteLn('GTG: GeoTIFF classic non compresse Float32, strips/tuiles;');
 WriteLn('prise en charge HORIZONTAL_OFFSET, offsets verticaux, translations XYZ');
 WriteLn('et VELOCITY ENU en mm/an. BigTIFF/compression et DEFORMATION_MODEL');
 WriteLn('multi-composants ne sont pas pris en charge.');
 WriteLn('Les projections azimutales sont calculees sur une sphere authalique;');
 WriteLn('+R permet de choisir un rayon spherique explicite.');
End;

Procedure ParseColumns(S : String);
Var I, N, StartPos, Err : Integer;
Begin
 ColCount := 0; StartPos := 1;
 For I := 1 To Length(S) + 1 Do
  If (I > Length(S)) Or (S[I] = ',') Then Begin
   If ColCount < 4 Then Begin
    Inc(ColCount); Val(Copy(S, StartPos, I - StartPos), N, Err);
    If Err = 0 Then Cols[ColCount] := N Else Cols[ColCount] := ColCount;
   End;
   StartPos := I + 1;
  End;
 If ColCount < 2 Then Begin ColCount := 2; Cols[1] := 1; Cols[2] := 2; End;
End;

Procedure ParseTokens(Line : String; Var T : TTokens; Var Count : Integer);
Var I, N : Integer; S : String;
Begin
 Count := 0; I := 1;
 While (I <= Length(Line)) And (Count < MaxTokens) Do Begin
  While (I <= Length(Line)) And (Line[I] In [' ', #9]) Do Inc(I);
  If I <= Length(Line) Then Begin
   N := I;
   While (I <= Length(Line)) And Not (Line[I] In [' ', #9]) Do Inc(I);
   Inc(Count); S := Copy(Line, N, I - N); T[Count] := S;
  End;
 End;
End;

Function GeodeticToXYZ(Lon, Lat, H, A, F : Real; Var X, Y, Z : Real) : Boolean;
Var E2, N : Real;
Begin
 E2 := F * (2.0 - F);
 N := A / Sqrt(1.0 - E2 * Sqr(Sin(Lat)));
 X := (N + H) * Cos(Lat) * Cos(Lon);
 Y := (N + H) * Cos(Lat) * Sin(Lon);
 Z := (N * (1.0 - E2) + H) * Sin(Lat);
 GeodeticToXYZ := True;
End;

Procedure XYZToGeodetic(X, Y, Z, A, F : Real; Var Lon, Lat, H : Real);
Var E2, P, Phi, N : Real; I : Integer;
Begin
 E2 := F * (2.0 - F); P := Sqrt(X * X + Y * Y);
 Lon := Atan2R(Y, X);
 If P < 0.0000001 Then Begin Lat := PI / 2; H := Abs(Z) - A * Sqrt(1-E2); End
 Else Begin
  Phi := ArcTan(Z / (P * (1.0-E2)));
  For I := 1 To 8 Do Begin
   N := A / Sqrt(1.0-E2*Sqr(Sin(Phi)));
   Phi := ArcTan((Z + E2*N*Sin(Phi)) / P);
  End;
  N := A / Sqrt(1.0-E2*Sqr(Sin(Phi)));
  Lat := Phi; H := P / Cos(Phi) - N;
 End;
End;

Function ApplyProjection(Var S : TStep; X, Y, Z, T : Real;
                         Backward : Boolean; Var OX, OY, OZ, OT : Real) : Boolean;
Var Lon, Lat, Lam, Phi, E2, EP2, N, TT, CC, AA, M, M0, K, XMet, YMet, E1, Mu, P1 : Real;
 Phi0, CosC, CAng, SinC, Radius, Denom : Real;
 I : Integer;
Begin
 ApplyProjection := True; OX := X; OY := Y; OZ := Z; OT := T;
 E2 := S.F * (2.0-S.F); EP2 := E2/(1.0-E2);
 If Backward Then Begin
  If S.Op = opLongLat Then Begin OX := X; OY := Y; Exit; End;
  If S.Op = opMerc Then Begin
   XMet := X-S.X0; YMet := Y-S.Y0; Lam := D2R(S.Lon0)+XMet/S.A;
   Phi := PI/2-2*ArcTan(Exp(-YMet/S.A));
  For I := 1 To 8 Do Phi := PI/2-2*ArcTan(Exp(-YMet/S.A)*PowerR((1-Sqrt(E2)*Sin(Phi))/(1+Sqrt(E2)*Sin(Phi)),Sqrt(E2)/2));
   OX := Lam; OY := Phi; Exit;
  End;
  If (S.Op = opUTM) Or (S.Op = opTMerc) Then Begin
   If S.Op = opUTM Then Begin S.Lon0 := (S.Zone-1)*6-180+3; S.K0 := 0.9996; S.X0 := 500000; If S.South Then S.Y0 := 10000000; End;
   XMet := X-S.X0; YMet := Y-S.Y0;
   M := YMet/S.K0;
   Mu := M/(S.A*(1-E2/4-3*Sqr(E2)/64-5*E2*E2*E2/256));
   E1 := (1-Sqrt(1-E2))/(1+Sqrt(1-E2));
   P1 := Mu+(3*E1/2-27*PowerR(E1,3)/32)*Sin(2*Mu)+(21*Sqr(E1)/16-55*PowerR(E1,4)/32)*Sin(4*Mu)+151*PowerR(E1,3)/96*Sin(6*Mu)+1097*PowerR(E1,4)/512*Sin(8*Mu);
   N := S.A/Sqrt(1-E2*Sqr(Sin(P1))); TT := Sqr(TanR(P1)); CC := EP2*Sqr(Cos(P1));
   K := S.A*(1-E2)/PowerR(1-E2*Sqr(Sin(P1)),1.5); AA := XMet/(N*S.K0);
   OY := P1-(N*TanR(P1)/K)*(Sqr(AA)/2-(5+3*TT+10*CC-4*Sqr(CC)-9*EP2)*PowerR(AA,4)/24+(61+90*TT+298*CC+45*Sqr(TT)-252*EP2-3*Sqr(CC))*PowerR(AA,6)/720);
   OX := D2R(S.Lon0)+(AA-(1+2*TT+CC)*PowerR(AA,3)/6+(5-2*CC+28*TT-3*Sqr(CC)+8*EP2+24*Sqr(TT))*PowerR(AA,5)/120)/Cos(P1);
   Exit;
  End;
  If (S.Op=opLAEA) Or (S.Op=opAEQD) Or (S.Op=opStere) Or
     (S.Op=opOrtho) Or (S.Op=opGnom) Then Begin
   Radius:=S.SphereRadius;
   If Not S.HasSphereRadius Then Radius:=AuthalicRadius(S.A,S.F);
   Radius:=Radius*S.K0;
   XMet:=(X-S.X0)/Radius; YMet:=(Y-S.Y0)/Radius;
  K:=Sqrt(XMet*XMet+YMet*YMet); Phi0:=AuthalicLatitude(D2R(S.Lat0),S.A,S.F);
  If K<1.0E-14 Then Begin OX:=D2R(S.Lon0); OY:=D2R(S.Lat0); Exit; End;
   If S.Op=opLAEA Then Begin
    If K>2.0 Then Begin ApplyProjection:=False; Exit; End;
    CAng:=2*ArcSinR(K/2);
  End Else If S.Op=opAEQD Then Begin
   If K>PI Then Begin ApplyProjection:=False; Exit; End;
   CAng:=K;
  End
   Else If S.Op=opStere Then CAng:=2*ArcTan(K/2)
   Else If S.Op=opOrtho Then Begin If K>1 Then Begin ApplyProjection:=False; Exit; End; CAng:=ArcSinR(K); End
   Else CAng:=ArcTan(K);
   SinC:=Sin(CAng); CosC:=Cos(CAng);
    Denom:=CosC*Sin(Phi0)+YMet*SinC*Cos(Phi0)/K;
    If Denom>1 Then Denom:=1 Else If Denom< -1 Then Denom:=-1;
    OY:=GeodeticLatitude(ArcSinR(Denom),S.A,S.F);
   OX:=D2R(S.Lon0)+Atan2R(XMet*SinC,K*Cos(Phi0)*CosC-YMet*Sin(Phi0)*SinC);
   Exit;
  End;
 End Else Begin
  If S.Op = opLongLat Then Begin OX := X; OY := Y; Exit; End;
  If S.Op = opMerc Then Begin
   If Abs(Y) >= PI/2 Then Begin ApplyProjection := False; Exit; End;
   OX := S.X0+S.A*(X-D2R(S.Lon0));
  OY := S.Y0+S.A*Ln(TanR(PI/4+Y/2)*PowerR((1-Sqrt(E2)*Sin(Y))/(1+Sqrt(E2)*Sin(Y)),Sqrt(E2)/2));
   Exit;
  End;
  If (S.Op = opUTM) Or (S.Op = opTMerc) Then Begin
   If S.Op = opUTM Then Begin S.Lon0 := (S.Zone-1)*6-180+3; S.K0 := 0.9996; S.X0 := 500000; If S.South Then S.Y0 := 10000000; End;
   Lon := X; Lat := Y; Lam := Lon-D2R(S.Lon0); Phi := Lat;
   N := S.A/Sqrt(1-E2*Sqr(Sin(Phi))); TT := Sqr(TanR(Phi)); CC := EP2*Sqr(Cos(Phi)); AA := Cos(Phi)*Lam;
   M := S.A*((1-E2/4-3*Sqr(E2)/64-5*PowerR(E2,3)/256)*Phi-(3*E2/8+3*Sqr(E2)/32+45*PowerR(E2,3)/1024)*Sin(2*Phi)+(15*Sqr(E2)/256+45*PowerR(E2,3)/1024)*Sin(4*Phi)-35*PowerR(E2,3)/3072*Sin(6*Phi));
   M0 := S.A*((1-E2/4-3*Sqr(E2)/64-5*PowerR(E2,3)/256)*D2R(S.Lat0)-(3*E2/8+3*Sqr(E2)/32+45*PowerR(E2,3)/1024)*Sin(2*D2R(S.Lat0))+(15*Sqr(E2)/256+45*PowerR(E2,3)/1024)*Sin(4*D2R(S.Lat0))-35*PowerR(E2,3)/3072*Sin(6*D2R(S.Lat0)));
   OX := S.X0+S.K0*N*(AA+(1-TT+CC)*PowerR(AA,3)/6+(5-18*TT+Sqr(TT)+72*CC-58*EP2)*PowerR(AA,5)/120);
   OY := S.Y0+S.K0*(M-M0+N*TanR(Phi)*(Sqr(AA)/2+(5-TT+9*CC+4*Sqr(CC))*PowerR(AA,4)/24+(61-58*TT+Sqr(TT)+600*CC-330*EP2)*PowerR(AA,6)/720));
   Exit;
  End;
  If (S.Op=opLAEA) Or (S.Op=opAEQD) Or (S.Op=opStere) Or
     (S.Op=opOrtho) Or (S.Op=opGnom) Then Begin
   If Abs(Y)>PI/2 Then Begin ApplyProjection:=False; Exit; End;
   Radius:=S.SphereRadius;
   If Not S.HasSphereRadius Then Radius:=AuthalicRadius(S.A,S.F);
   Radius:=Radius*S.K0;
  Phi:=AuthalicLatitude(Y,S.A,S.F);
  Phi0:=AuthalicLatitude(D2R(S.Lat0),S.A,S.F); Lam:=X-D2R(S.Lon0);
  CosC:=Sin(Phi0)*Sin(Phi)+Cos(Phi0)*Cos(Phi)*Cos(Lam);
   If S.Op=opLAEA Then Begin
    Denom:=1+CosC; If Denom<=1.0E-14 Then Begin ApplyProjection:=False; Exit; End;
    K:=Sqrt(2/Denom);
   End Else If S.Op=opAEQD Then Begin
    Denom:=1-CosC*CosC; If Denom<0 Then Denom:=0;
    CAng:=Atan2R(Sqrt(Denom),CosC);
    If Denom<1.0E-20 Then K:=1 Else K:=CAng/Sqrt(Denom);
   End Else If S.Op=opStere Then Begin
    Denom:=1+CosC; If Denom<=1.0E-14 Then Begin ApplyProjection:=False; Exit; End;
    K:=2/Denom;
   End Else If S.Op=opOrtho Then Begin
    If CosC<0 Then Begin ApplyProjection:=False; Exit; End; K:=1;
   End Else Begin
    If CosC<=0 Then Begin ApplyProjection:=False; Exit; End; K:=1/CosC;
   End;
  OX:=S.X0+Radius*K*Cos(Phi)*Sin(Lam);
  OY:=S.Y0+Radius*K*(Cos(Phi0)*Sin(Phi)-Sin(Phi0)*Cos(Phi)*Cos(Lam));
   Exit;
  End;
 End;
 ApplyProjection := False;
End;

Procedure ApplyStep(Var S : TStep; Var X, Y, Z, T : Real; Backward : Boolean; Var OK : Boolean);
Var A, B, C, D, F, M, Det, RX, RY, RZ, Scale, DX, DY, DZ : Real;
 E2, Rho, Nu, VerticalOffset : Real;
 TX, TY, TZ, TT : Real;
 ShiftLon, ShiftLat, SourceLon, SourceLat, Offset : Real;
 GX,GY,GZ,BaseX,BaseY,BaseZ,VX,VY,VZ,Delta,Mult : Real;
 I : Integer; GridOK : Boolean;
Begin
 OK := True;
 If S.Op = opNoop Then Exit;
 If S.Op = opUnitConvert Then Begin
  If Backward Then Begin
   If S.HasXYOut And (Not S.XYOutRad) Then Begin X := X*DEG; Y := Y*DEG; End;
   If S.HasXYIn And (Not S.XYInRad) Then Begin X := X/DEG; Y := Y/DEG; End;
  If S.HasZOut And S.ZOutFeet Then Z := Z*0.3048;
  If S.HasZIn And S.ZInFeet Then Z := Z/0.3048;
  End Else Begin
   If S.HasXYIn And (Not S.XYInRad) Then Begin X := X*DEG; Y := Y*DEG; End;
   If S.HasXYOut And (Not S.XYOutRad) Then Begin X := X/DEG; Y := Y/DEG; End;
   If S.HasZIn And S.ZInFeet Then Z := Z*0.3048;
   If S.HasZOut And S.ZOutFeet Then Z := Z/0.3048;
  End;
  Exit;
 End;
 If S.Op = opAxisSwap Then Begin
  If Backward Then Begin
   A := X; B := Y;
   If Pos('2,1', S.Order) > 0 Then Begin X := B; Y := A; End;
  End Else If Pos('2,1', S.Order) > 0 Then Begin A := X; X := Y; Y := A; End;
  Exit;
 End;
 If S.Op = opAffine Then Begin
  A := S.Affine[1]; B := S.Affine[2]; C := S.Affine[3]; D := S.Affine[4];
  Det := A*D-B*C;
  If Abs(Det) < 1.0E-20 Then Begin OK := False; Exit; End;
  If Backward Then Begin
   M := X-S.DX; F := Y-S.DY;
   X := (D*M-B*F)/Det; Y := (A*F-C*M)/Det;
  End Else Begin M := X; F := Y; X := A*M+B*F+S.DX; Y := C*M+D*F+S.DY; End;
  If Backward Then Z := Z-S.DZ Else Z := Z+S.DZ;
  Exit;
 End;
 If S.Op = opHelmert Then Begin
  DX := S.DX; DY := S.DY; DZ := S.DZ;
  RX := S.RX*ARCSEC; RY := S.RY*ARCSEC; RZ := S.RZ*ARCSEC; Scale := 1.0+S.Scale*1E-6;
  If S.HasEpoch Then Begin
   M := T-S.Epoch;
   DX := DX+S.RateX*M; DY := DY+S.RateY*M; DZ := DZ+S.RateZ*M;
   RX := RX+S.RateRX*M*ARCSEC; RY := RY+S.RateRY*M*ARCSEC; RZ := RZ+S.RateRZ*M*ARCSEC;
   Scale := Scale+(S.RateScale*M)*1E-6;
  End;
  If S.Order = 'coordinate_frame' Then Begin RX := -RX; RY := -RY; RZ := -RZ; End;
  A := X; B := Y; C := Z;
  If Backward Then Begin
    X := (A-DX-RZ*B+RY*C)/Scale;
    Y := (B-DY+RZ*A-RX*C)/Scale;
    Z := (C-DZ-RY*A+RX*B)/Scale;
  End Else Begin
    X := DX+Scale*(A-RZ*B+RY*C);
    Y := DY+Scale*(RZ*A-RX*C+B);
    Z := DZ+Scale*(-RY*A+RX*B+C);
  End;
  Exit;
 End;
 If S.Op = opGeogOffset Then Begin
  If Backward Then Begin
   X:=X-S.DLon*ARCSEC; Y:=Y-S.DLat*ARCSEC; Z:=Z-S.DH;
  End Else Begin
   X:=X+S.DLon*ARCSEC; Y:=Y+S.DLat*ARCSEC; Z:=Z+S.DH;
  End;
  Exit;
 End;
 If S.Op = opVertOffset Then Begin
  E2:=S.F*(2-S.F);
  Nu:=S.A/Sqrt(1-E2*Sqr(Sin(D2R(S.Lat0))));
  Rho:=S.A*(1-E2)/PowerR(1-E2*Sqr(Sin(D2R(S.Lat0))),1.5);
  VerticalOffset:=S.DH+S.SlopeLat*ARCSEC*Rho*(Y-D2R(S.Lat0))+
   S.SlopeLon*ARCSEC*Nu*(X-D2R(S.Lon0))*Cos(Y);
  If Backward Then Z:=Z-VerticalOffset Else Z:=Z+VerticalOffset;
  Exit;
 End;
 If S.Op = opHGridShift Then Begin
  If S.GridName = '' Then Exit;
  If Not Backward Then Begin
  GridOK := FindNTv2Shift(S.GridName,X,Y,ShiftLon,ShiftLat);
  If GridOK Then Begin X:=X+ShiftLon*DEG; Y:=Y+ShiftLat*DEG; End;
  End Else Begin
   SourceLon:=X; SourceLat:=Y; GridOK:=True;
   For I:=1 To 8 Do Begin
   If Not FindNTv2Shift(S.GridName,SourceLon,SourceLat,ShiftLon,ShiftLat) Then Begin GridOK:=False; Break; End;
    SourceLon:=X-ShiftLon*DEG; SourceLat:=Y-ShiftLat*DEG;
   End;
   If GridOK Then Begin X:=SourceLon; Y:=SourceLat; End;
  End;
  If Not GridOK And S.GridOptional Then GridOK:=True;
  OK:=GridOK;
  Exit;
 End;
 If S.Op = opVGridShift Then Begin
  If S.GridName = '' Then Exit;
  GridOK:=FindGTX(S.GridName,X,Y,Offset);
  If GridOK Then Begin
   If Backward Then Z:=Z-Offset*S.GridMultiplier
   Else Z:=Z+Offset*S.GridMultiplier;
  End;
  If Not GridOK And S.GridOptional Then GridOK:=True;
  OK:=GridOK;
  Exit;
 End;
 If S.Op = opXYZGridShift Then Begin
  If S.GridName='' Then Exit;
  If S.HasGridMultiplier Then Mult:=S.GridMultiplier Else Mult:=1.0;
  BaseX:=X; BaseY:=Y; BaseZ:=Z; GridOK:=True;
  If (Not Backward) And (Not S.GridRefOutput) Then Begin
   GridOK:=ReadXYZGridOffset(S,X,Y,Z,GX,GY,GZ);
   If GridOK Then Begin X:=X+Mult*GX; Y:=Y+Mult*GY; Z:=Z+Mult*GZ; End;
  End Else If Backward And S.GridRefOutput Then Begin
   GridOK:=ReadXYZGridOffset(S,X,Y,Z,GX,GY,GZ);
   If GridOK Then Begin X:=X-Mult*GX; Y:=Y-Mult*GY; Z:=Z-Mult*GZ; End;
  End Else Begin
   If Backward Then Begin GX:=BaseX; GY:=BaseY; GZ:=BaseZ; End
   Else Begin GX:=BaseX; GY:=BaseY; GZ:=BaseZ; End;
   For I:=1 To 8 Do Begin
    GridOK:=ReadXYZGridOffset(S,GX,GY,GZ,DX,DY,DZ);
    If Not GridOK Then Break;
    If Backward Then Begin GX:=BaseX-Mult*DX; GY:=BaseY-Mult*DY; GZ:=BaseZ-Mult*DZ; End
    Else Begin GX:=BaseX+Mult*DX; GY:=BaseY+Mult*DY; GZ:=BaseZ+Mult*DZ; End;
   End;
   If GridOK Then Begin X:=GX; Y:=GY; Z:=GZ; End;
  End;
  If Not GridOK And S.GridOptional Then GridOK:=True;
  OK:=GridOK; Exit;
 End;
 If S.Op = opDeformation Then Begin
  If S.GridName='' Then Begin OK:=False; Exit; End;
  If S.HasDeltaTime Then Delta:=S.DeltaTime
  Else If S.HasEpoch Then Delta:=T-S.Epoch
  Else Begin OK:=False; Exit; End;
  If Backward Then Delta:=-Delta;
  BaseX:=X; BaseY:=Y; BaseZ:=Z; GX:=X; GY:=Y; GZ:=Z; GridOK:=True;
  For I:=1 To 8 Do Begin
   GridOK:=ReadVelocity(S,GX,GY,GZ,VX,VY,VZ);
   If Not GridOK Then Break;
   If Backward Then Begin GX:=BaseX+Delta*VX; GY:=BaseY+Delta*VY; GZ:=BaseZ+Delta*VZ; End
   Else Begin GX:=BaseX+Delta*VX; GY:=BaseY+Delta*VY; GZ:=BaseZ+Delta*VZ; End;
  End;
  If GridOK Then Begin X:=GX; Y:=GY; Z:=GZ; End;
  If Not GridOK And S.GridOptional Then GridOK:=True;
  OK:=GridOK; Exit;
 End;
 If S.Op = opCart Then Begin
  If Backward Then XYZToGeodetic(X,Y,Z,S.A,S.F,X,Y,Z)
  Else GeodeticToXYZ(X,Y,Z,S.A,S.F,X,Y,Z);
  Exit;
 End;
 If (S.Op = opUTM) Or (S.Op = opMerc) Or (S.Op = opTMerc) Or (S.Op = opLongLat) Or
   (S.Op=opLAEA) Or (S.Op=opAEQD) Or (S.Op=opStere) Or
   (S.Op=opOrtho) Or (S.Op=opGnom) Then Begin
  If Not ApplyProjection(S,X,Y,Z,T,Backward,TX,TY,TZ,TT) Then OK := False
  Else Begin X := TX; Y := TY; Z := TZ; T := TT; End;
  Exit;
 End;
 OK := False;
End;

Procedure ProcessPipeline(Var X, Y, Z, T : Real; Var OK : Boolean);
Var I, Idx : Integer; Backward : Boolean;
Begin
 OK := True;
 For I := 1 To StepCount Do Begin
  Idx := I; If InverseAll Then Idx := StepCount-I+1;
    Backward := (Steps[Idx].Inverse And (Not InverseAll)) Or
            ((Not Steps[Idx].Inverse) And InverseAll);
  If (Not Backward And Steps[Idx].OmitForward) Or
      (Backward And Steps[Idx].OmitInverse) Then Begin End
    Else Begin
    ApplyStep(Steps[Idx], X, Y, Z, T, Backward, OK);
    If Not OK Then Exit;
    End;
 End;
End;

Procedure WriteFormatted(Var F : Text; Value : Real);
Var S : String;
Begin
 Str(Value:0:Decimals,S); Write(F,S);
End;

Procedure ProcessInput;
Var Line, TrimLine : String; Tokens : TTokens; N, I, C : Integer;
 MinRequired : Integer;
 X, Y, Z, T, V : Real; OK, HasToken, CoordsOK : Boolean;
Begin
 While Not EOF(InputFile) Do Begin
  ReadLn(InputFile,Line);
  TrimLine:=Line;
  While (TrimLine<>'') And (TrimLine[1] In [' ',#9]) Do Delete(TrimLine,1,1);
  If (TrimLine='') Or (TrimLine[1]='#') Then WriteLn(OutputFile,Line)
  Else Begin
   ParseTokens(Line,Tokens,N);
  MinRequired := Cols[1]; If Cols[2] > MinRequired Then MinRequired := Cols[2];
  If N < MinRequired Then WriteLn(OutputFile,ErrorText)
   Else Begin
    X:=0; Y:=0; Z:=0; T:=0;
    Val(Tokens[Cols[1]],X,I); HasToken:=I=0;
    Val(Tokens[Cols[2]],Y,I); HasToken:=HasToken And (I=0);
    CoordsOK:=HasToken;
    If (ColCount>=3) And (N>=Cols[3]) Then Begin Val(Tokens[Cols[3]],Z,I); CoordsOK:=CoordsOK And (I=0); End;
    If (ColCount>=4) And (N>=Cols[4]) Then Begin Val(Tokens[Cols[4]],T,I); CoordsOK:=CoordsOK And (I=0); End;
    If HaveZConstant And ((ColCount<3) Or (N<Cols[3])) Then Z:=ZConstant;
    If HaveTConstant And ((ColCount<4) Or (N<Cols[4])) Then T:=TConstant;
    If Not CoordsOK Then WriteLn(OutputFile,ErrorText)
    Else Begin
     ProcessPipeline(X,Y,Z,T,OK);
     If Not OK Then WriteLn(OutputFile,ErrorText)
     Else Begin
      For C := 1 To N Do Begin
       If C>1 Then Write(OutputFile,' ');
       V:=0; HasToken:=False;
       For I:=1 To ColCount Do If C=Cols[I] Then Begin
        Case I Of 1:V:=X; 2:V:=Y; 3:V:=Z; 4:V:=T; End;
        HasToken:=True;
       End;
       If HasToken Then WriteFormatted(OutputFile,V) Else Write(OutputFile,Tokens[C]);
      End;
      If HaveZConstant And ((ColCount<3) Or (N<Cols[3])) Then Begin Write(OutputFile,' '); WriteFormatted(OutputFile,Z); End;
      If HaveTConstant And ((ColCount<4) Or (N<Cols[4])) Then Begin Write(OutputFile,' '); WriteFormatted(OutputFile,T); End;
      WriteLn(OutputFile);
     End;
    End;
   End;
  End;
 End;
End;

Procedure ParseColumnList(S : String);
Var I, N, Err, StartPos : Integer;
Begin
 ColCount:=0; StartPos:=1;
 For I:=1 To Length(S)+1 Do If (I>Length(S)) Or (S[I]=',') Then Begin
  If ColCount<4 Then Begin
   Inc(ColCount); Val(Copy(S,StartPos,I-StartPos),N,Err);
   If (Err<>0) Or (N<1) Or (N>MaxTokens) Then Begin
    WriteLn('Erreur: colonne invalide pour -c.'); Halt(1);
   End;
   Cols[ColCount]:=N;
  End;
  StartPos:=I+1;
 End;
 If ColCount<2 Then Begin ColCount:=2; Cols[1]:=1; Cols[2]:=2; End;
End;

Var I, J, CurrentStep, Err : Integer; Arg : String;
BEGIN
 Decimals:=6; ZConstant:=0; TConstant:=0; HaveZConstant:=False; HaveTConstant:=False;
 InverseAll:=False; Verbose:=False; VeryVerbose:=False; ErrorText:='*';
 InputName:=''; OutputName:=''; OwnInput:=False; OwnOutput:=False;
 ColCount:=4; Cols[1]:=1; Cols[2]:=2; Cols[3]:=3; Cols[4]:=4; StepCount:=0; CurrentStep:=0;
 GlobalParamCount:=0;
 For I:=1 To 16 Do GlobalParams[I]:='';
 For I:=1 To MaxSteps Do InitStep(Steps[I]);
 I:=1;
 While I<=ParamCount Do Begin
  Arg:=ParamStr(I);
  If (Arg='-h') Or (Arg='--help') Or (Arg='/?') Then Begin ShowHelp; Halt(0); End Else
  If Arg='-V' Then Begin WriteLn('CCT Pascal 1.0'); Halt(0); End Else
  If Arg='-I' Then InverseAll:=True Else
  If Arg='-v' Then Verbose:=True Else If Arg='-vv' Then Begin Verbose:=True; VeryVerbose:=True; End Else
  If Arg='-d' Then Begin
   Inc(I); If I>ParamCount Then Begin WriteLn('Erreur: -d attend un entier.'); Halt(1); End;
   Val(ParamStr(I),Decimals,Err);
   If (Err<>0) Or (Decimals<0) Or (Decimals>15) Then Begin WriteLn('Erreur: precision -d invalide (0..15).'); Halt(1); End;
  End Else
  If Copy(Arg,1,2)='-d' Then Begin
   Val(Copy(Arg,3,Length(Arg)-2),Decimals,Err);
   If (Err<>0) Or (Decimals<0) Or (Decimals>15) Then Begin WriteLn('Erreur: precision -d invalide (0..15).'); Halt(1); End;
  End Else
  If Arg='-c' Then Begin Inc(I); If I>ParamCount Then Halt(1); ParseColumnList(ParamStr(I)); End Else
  If Arg='-z' Then Begin
   Inc(I); If I>ParamCount Then Begin WriteLn('Erreur: valeur manquante apres -z.'); Halt(1); End;
   HaveZConstant:=ParseReal(ParamStr(I),ZConstant);
   If Not HaveZConstant Then Begin WriteLn('Erreur: -z attend une valeur numerique.'); Halt(1); End;
  End Else
  If Arg='-t' Then Begin
   Inc(I); If I>ParamCount Then Begin WriteLn('Erreur: valeur manquante apres -t.'); Halt(1); End;
   HaveTConstant:=ParseReal(ParamStr(I),TConstant);
   If Not HaveTConstant Then Begin WriteLn('Erreur: -t attend une valeur numerique.'); Halt(1); End;
  End Else
  If Arg='-o' Then Begin Inc(I); If I>ParamCount Then Halt(1); OutputName:=ParamStr(I); End Else
  If Copy(Arg,1,2)='-o' Then OutputName:=Copy(Arg,3,Length(Arg)-2) Else
  If Arg='+proj=pipeline' Then Begin End Else
  If Arg='+step' Then Begin
   If StepCount>=MaxSteps Then Begin WriteLn('Erreur: trop d''etapes.'); Halt(1); End;
   Inc(StepCount); CurrentStep:=StepCount; InitStep(Steps[CurrentStep]);
    For J:=1 To GlobalParamCount Do ParseStepParam(Steps[CurrentStep],GlobalParams[J]);
    End Else If Copy(Arg,1,1)='+' Then Begin
    If (StepCount=0) And
      ((Copy(Arg,1,9)='+grids=') Or (Copy(Arg,1,10)='+nadgrids=') Or
       (Copy(Arg,1,12)='+geoidgrids=')) Then Begin
     If GlobalParamCount<16 Then Begin Inc(GlobalParamCount); GlobalParams[GlobalParamCount]:=Arg; End;
    End Else If StepCount=0 Then Begin
     If GlobalParamCount<16 Then Begin Inc(GlobalParamCount); GlobalParams[GlobalParamCount]:=Arg; End;
    End Else ParseStepParam(Steps[CurrentStep],Arg);
  End Else If Arg<>'' Then Begin
   If InputName<>'' Then Begin WriteLn('Erreur: un seul fichier d''entree est accepte.'); Halt(1); End;
   InputName:=Arg;
  End;
  Inc(I);
 End;
 If StepCount=0 Then Begin WriteLn('Erreur: operation +proj absente.'); ShowHelp; Halt(1); End;
 For I:=1 To StepCount Do Begin
  If Steps[I].Op=opNone Then Begin WriteLn('Erreur: operation de pipeline inconnue a l''etape ',I); Halt(1); End;
  If ((Steps[I].Op=opHGridShift) Or (Steps[I].Op=opVGridShift) Or
      (Steps[I].Op=opXYZGridShift) Or (Steps[I].Op=opDeformation)) And
     (Not Steps[I].HasGridParam) Then Begin
   WriteLn('Erreur: l''etape de grille ',I,' exige +grids=<fichier>.'); Halt(1);
  End;
 End;
 If Verbose Then Begin
  WriteLn('Etapes: ',StepCount);
  If VeryVerbose Then For I:=1 To StepCount Do WriteLn('  ',I,': ',Ord(Steps[I].Op),' inverse=',Steps[I].Inverse);
 End;
 Assign(InputFile,InputName);
 If InputName='' Then InputFile:=Input;
 If InputName<>'' Then Begin {$I-} Reset(InputFile); Err:=IOResult; {$I+} If Err<>0 Then Begin WriteLn('Erreur: fichier introuvable: ',InputName); Halt(1); End; OwnInput:=True; End;
 Assign(OutputFile,OutputName);
 If OutputName='' Then OutputFile:=Output
 Else Begin
  If (InputName<>'') And (UpperString(InputName)=UpperString(OutputName)) Then Begin
   WriteLn('Erreur: les fichiers d''entree et de sortie doivent etre differents.'); Halt(1);
  End;
  {$I-} Rewrite(OutputFile); Err:=IOResult; {$I+}
  If Err<>0 Then Begin WriteLn('Erreur: impossible de creer ',OutputName); Halt(1); End;
  OwnOutput:=True;
 End;
 ProcessInput;
 If OwnInput Then Close(InputFile);
 If OwnOutput Then Close(OutputFile);
END.
