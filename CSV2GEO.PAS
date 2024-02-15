{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CSV2GEO;

Uses DOS;

Var
 Source,Target:Text;
 FirstLine,TypeLineString,SeparatorSetted:Boolean;
 Separator:Char;
 FileNameSource,FileNameTarget,CurrLine:String;
 PosLine,PosCells,I,J,CharNumber:Integer;
 Err:Word;
 Cells:Array[0..100,0..3]of String[50];

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function Path2Ext(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Path2Ext:=E;
End;

Function LongitudeToReal(S:String):Real;
Var
 R:Real;
 I:Integer;
 Err:Word;
 Num:String;
Begin
 Num:='';
 For I:=1 to Length(S) do Begin
  If Not(S[I]in['.','0'..'9'])Then Break;
  Num:=Num+S[I];
 End;
 Val(Num,R,Err);
 If UpCase(S[Length(S)])in['O','W']Then R:=-R;
 LongitudeToReal:=R;
End;

Function LongitudeToRealStr(S:String):String;
Var
 R:Real;
 T:String;
Begin
 R:=LongitudeToReal(S);
 If Frac(R)=0.0 Then Begin
  Str(R:0:0,T);
  LongitudeToRealStr:=T;
 End
  Else
 Begin
  Str(R:0:5,T);
  LongitudeToRealStr:=T;
 End;
End;

Function LattitudeToReal(S:String):Real;
Var
 R:Real;
 I:Integer;
 Err:Word;
 Num:String;
Begin
 Num:='';
 For I:=1 to Length(S) do Begin
  If Not(S[I]in['.','0'..'9'])Then Break;
  Num:=Num+S[I];
 End;
 Val(Num,R,Err);
 If UpCase(S[Length(S)])in['S']Then R:=-R;
 LattitudeToReal:=R;
End;

Function LattitudeToRealStr(S:String):String;
Var
 R:Real;
 T:String;
Begin
 R:=LattitudeToReal(S);
 If Frac(R)=0.0 Then Begin
  Str(R:0:0,T);
  LattitudeToRealStr:=T;
 End
  Else
 Begin
  Str(R:0:5,T);
  LattitudeToRealStr:=T;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CSV2GEO : Cette commande permet de convertir un fichier CSV ',
                     'contenant des coordonn‚es g‚ographiques en format ',
                     '®.geojson¯.');
  WriteLn;
  WriteLn('Syntaxe : CSV2GEO [options] source.csv [target.geojson]');
  WriteLn;
  WriteLn(' source.csv       Ce paramŠtre permet d''indiquer le fichier … convertir');
  WriteLn(' target.geojson   Ce paramŠtre permet d''indiquer le fichier geojson');
  WriteLn(' /SEPARATOR:char  Ce paramŠtre permet d''indiquer le caractŠre de s‚paration');
  WriteLn('                  entre les cellules du CSV. Mettre # pour un nombre,');
  WriteLn('                  exemple: /SEPARATOR:#9 pour une tabulation');
 End
  Else
 If ParamCount>0Then Begin
  Separator:=',';
  SeparatorSetted:=False;
  FileNameSource:='';
  FileNameTarget:='';
  For I:=1 to ParamCount do Begin
   If Copy(StrToUpper(ParamStr(I)),1,Length('/SEPARATOR:'))='/SEPARATOR:'Then Begin
    CurrLine:=Copy(StrToUpper(ParamStr(I)),Length('/SEPARATOR:')+1,255);
    If Length(CurrLine)>1 Then Begin
     If CurrLine[1]='#'Then Begin
      Val(Copy(CurrLine,2,255),CharNumber,Err);
      Separator:=Char(CharNumber);
     End;
    End
     Else
    If CurrLine<>''Then Separator:=CurrLine[1];
    SeparatorSetted:=True;
   End
    Else
   If FileNameSource=''Then Begin
    FileNameSource:=ParamStr(I);
    If Not(SeparatorSetted)Then Begin
     If StrToUpper(Path2Ext(FileNameSource))='.TSV'Then Separator:=#9 Else
     If StrToUpper(Path2Ext(FileNameSource))='.DSV'Then Separator:='|';
    End;
   End
    Else
   If FileNameTarget=''Then FileNameTarget:=ParamStr(I)
    Else
   Begin
    WriteLn('ParamŠtre inconnu ',ParamStr(I));
    Halt(3);
   End;
  End;
  {$I-}Assign(Source,FileNameSource);
  Reset(Source);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Impossible d''ouvrir le fichier CSV : ',ParamStr(1));
   Halt(1);
  End;
  FirstLine:=True;
  PosLine:=0;
  FillChar(Cells,SizeOf(Cells),0);
  While Not EOF(Source)do Begin
   ReadLn(Source,CurrLine);
   PosCells:=0;
   For I:=1 to Length(CurrLine)do Begin
    If CurrLine[I]=Separator Then Begin
     If PosCells<3 Then Inc(PosCells);
    End
     Else
    Cells[PosLine,PosCells]:=Cells[PosLine,PosCells]+CurrLine[I];
   End;
   If(FirstLine)Then Begin
    FirstLine:=False;
   End;
   Inc(PosLine);
   If PosLine>=100 Then Break;
  End;
  Close(Source);
  If(FileNameTarget<>'')Then Begin
   {$I-}Assign(Target,FileNameTarget);
   Rewrite(Target);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible de cr‚er le fichier geojson ',ParamStr(2));
    Halt(2);
   End;
   If PosLine=2 Then Begin
    Write(Target,'{"type":"FeatureCollection","features":[{"type":"Feature",',
          '"properties":{"name":"',Cells[1,2],'"},',
          '"geometry":{"type":"Point","coordinates":[',
          LongitudeToRealStr(Cells[1,1]),',',
          LattitudeToRealStr(Cells[1,0]),']}}]}');
   End
    Else
   Begin
    TypeLineString:=True;
    CurrLine:=Cells[1,0];
    For J:=1 to PosLine-1 do Begin
     If CurrLine<>Cells[J,0]Then Begin
      TypeLineString:=False;
      Break;
     End;
    End;
    If Not(TypeLineString)Then Begin
     TypeLineString:=True;
     CurrLine:=Cells[1,1];
     For J:=1 to PosLine-1 do Begin
      If CurrLine<>Cells[J,1]Then Begin
       TypeLineString:=False;
       Break;
      End;
     End;
    End;
    WriteLn(Target,'{');
    WriteLn(Target,' ':4,'"type": "FeatureCollection",');
    WriteLn(Target,' ':4,'"features": [{');
    WriteLn(Target,' ':8,'"type": "Feature",');
    WriteLn(Target,' ':8,'"properties": {');
    WriteLn(Target,' ':12,'"name": [');
    Write(Target,' ':13);
    For J:=1 to PosLine-1 do Begin
     Write(Target,'"',Cells[J,2],'"');
     If J<PosLine-1 Then Begin
      WriteLn(Target,',');
      Write(Target,' ':13);
     End;
    End;
    WriteLn(Target,']');
    WriteLn(Target,' ':8,'},');
    WriteLn(Target,' ':8,'"geometry": {');
    Write(Target,' ':12,'"type": "');
    If(TypeLineString)Then Write(Target,'LineString')
                      Else Write(Target,'Polygon');
    WriteLn(Target,'",');
    WriteLn(Target,' ':12,'"coordinates": [');
    Write(Target,' ':12);
    For J:=1 to PosLine-1 do Begin
     Write(Target,'[',LongitudeToRealStr(Cells[J,1]),',',
                  LattitudeToRealStr(Cells[J,0]),']');
     If J<PosLine-1 Then Begin
      WriteLn(Target,',');
      Write(Target,' ':12);
     End;
    End;
    WriteLn(Target,']');
    WriteLn(Target,' ':8,'}');
    WriteLn(Target,' ':4,'}]');
    WriteLn(Target,'}');
   End;
   Close(Target);
  End
   Else
  Begin
   If PosLine=2 Then Begin
    Write('{"type":"FeatureCollection","features":[{"type":"Feature",',
          '"properties":{"name":"',Cells[1,2],'"},',
          '"geometry":{"type":"Point","coordinates":[',
          LongitudeToRealStr(Cells[1,1]),',',
          LattitudeToRealStr(Cells[1,0]),']}}]}');
   End
    Else
   Begin
    TypeLineString:=True;
    CurrLine:=Cells[1,0];
    For J:=1 to PosLine-1 do Begin
     If CurrLine<>Cells[J,0]Then Begin
      TypeLineString:=False;
      Break;
     End;
    End;
    If Not(TypeLineString)Then Begin
     TypeLineString:=True;
     CurrLine:=Cells[1,1];
     For J:=1 to PosLine-1 do Begin
      If CurrLine<>Cells[J,1]Then Begin
       TypeLineString:=False;
       Break;
      End;
     End;
    End;
    WriteLn('{');
    WriteLn(' ':4,'"type": "FeatureCollection",');
    WriteLn(' ':4,'"features": [{');
    WriteLn(' ':8,'"type": "Feature",');
    WriteLn(' ':8,'"properties": {');
    WriteLn(' ':12,'"name": [');
    Write(' ':13);
    For J:=1 to PosLine-1 do Begin
     Write('"',Cells[J,2],'"');
     If J<PosLine-1 Then Begin
      WriteLn(',');
      Write(' ':13);
     End;
    End;
    WriteLn(']');
    WriteLn(' ':8,'},');
    WriteLn(' ':8,'"geometry": {');
    Write(' ':12,'"type": "');
    If(TypeLineString)Then Write('LineString')
                      Else Write('Polygon');
    WriteLn('",');
    WriteLn(' ':12,'"coordinates": [');
    Write(' ':12);
    For J:=1 to PosLine-1 do Begin
     Write('[',LongitudeToRealStr(Cells[J,1]),',',
               LattitudeToRealStr(Cells[J,0]),']');
     If J<PosLine-1 Then Begin
      WriteLn(',');
      Write(' ':12);
     End;
    End;
    WriteLn(']');
    WriteLn(' ':8,'}');
    WriteLn(' ':4,'}]');
    WriteLn('}');
   End;
  End;
 End;
END.
