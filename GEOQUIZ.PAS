{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/geo-commander)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program GeoQuiz;

Uses Crt,Strings;

Var
 TmpQuestion:String;
 QuestionList:Array[1..255]of Byte;
 I,NumQuestion,P,Good,Bad:Integer;
 Choix:Char;
 ChoixValid:Boolean;

Type
 QuestionRec=Record
  Question:PChar;
  AnswerA,AnswerB,AnswerC,AnswerD:PChar;
  Response:Char;
 End;

Const
 Questions:Array[1..11] of QuestionRec=(
  (Question:'Quel est le pays avec la plus grande superficie au monde';
   AnswerA:'Canada';
   AnswerB:'Chine';
   AnswerC:'Russie';
   AnswerD:'Etats-Unis';
   Response:'C'),
  (Question:'Quel est la capitale de la France';
   AnswerA:'Berlin';
   AnswerB:'Londres';
   AnswerC:'Montr‚al';
   AnswerD:'Paris';
   Response:'D'),
  (Question:'Quel est la capitale de l''Allemagne';
   AnswerA:'Munich';
   AnswerB:'Berlin';
   AnswerC:'Amsterdam';
   AnswerD:'Paris';
   Response:'B'),
  (Question:'Quel est la capitale des Pays-Bas';
   AnswerA:'Munich';
   AnswerB:'Berlin';
   AnswerC:'Amsterdam';
   AnswerD:'Paris';
   Response:'C'),
  (Question:'Quel est la capitale du Canada';
   AnswerA:'Montr‚al';
   AnswerB:'Toronto';
   AnswerC:'Vancouver';
   AnswerD:'Ottawa';
   Response:'D'),
  (Question:'Quel est le pays le plus peupl‚ au monde';
   AnswerA:'Chine';
   AnswerB:'Russie';
   AnswerC:'tats-Unis';
   AnswerD:'Inde';
   Response:'A'),
  (Question:'Quel est la capitale de la Chine';
   AnswerA:'Shanghai';
   AnswerB:'Hong Kong';
   AnswerC:'P‚kin / Beijing';
   AnswerD:'S‚oul';
   Response:'C'),
  (Question:'Quel est le plus long fleuve au monde';
   AnswerA:'Amazone';
   AnswerB:'Nil';
   AnswerC:'Yang-Ts‚-Kiang';
   AnswerD:'Mississippi';
   Response:'A'),
  (Question:'Quel est la capitale de la Russie';
   AnswerA:'Saint-P‚tersbourg';
   AnswerB:'Moscou';
   AnswerC:'Novgorod';
   AnswerD:'Kiev';
   Response:'B'),
  (Question:'Quel est la capitale de l''Espagne';
   AnswerA:'Madrid';
   AnswerB:'Bercelone';
   AnswerC:'S‚ville';
   AnswerD:'M‚rida';
   Response:'A'),
  (Question:'Quel est la capitale du Portugal';
   AnswerA:'Faro';
   AnswerB:'Lisbonne';
   AnswerC:'Beja';
   AnswerD:'Fatima';
   Response:'B')
 );

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('MATHQUIZ - Cette commande permet de passer un QUIZ de math‚matique');
  WriteLn;
  WriteLn('Syntaxe : MATHQUIZ');
 End
  Else
 Begin
  Randomize;
  NumQuestion:=10;
  Good:=0;
  Bad:=0;
  FillChar(QuestionList,SizeOf(QuestionList),0);
  TmpQuestion[0]:=Chr(High(Questions));
  For I:=1 to 255 do Begin
   TmpQuestion[I]:=Chr(I);
  End;
  For I:=1 to NumQuestion do Begin
   P:=1+Random(Length(TmpQuestion));
   QuestionList[I]:=Byte(TmpQuestion[P]);
   Delete(TmpQuestion,P,1);
  End;
  For I:=1 to NumQuestion do Begin
   ClrScr;
   TextColor(White);
   WriteLn(' ':30,'QUIZ de g‚ographie');
   WriteLn;
   WriteLn('Question (',I,'/',NumQuestion,')');
   TextColor(LightGreen);
   WriteLn('Bonne r‚ponse : ',Good);
   TextColor(LightRed);
   WriteLn('Mauvaise r‚ponse : ',Bad);
   WriteLn;
   TextColor(7);
   WriteLn(StrPas(Questions[QuestionList[I]].Question),' ?');
   WriteLn;
   WriteLn('A) ',StrPas(Questions[QuestionList[I]].AnswerA));
   WriteLn('B) ',StrPas(Questions[QuestionList[I]].AnswerB));
   WriteLn('C) ',StrPas(Questions[QuestionList[I]].AnswerC));
   WriteLn('D) ',StrPas(Questions[QuestionList[I]].AnswerD));
   WriteLn;
   Write('Votre choix : ');
   Repeat
    Choix:=ReadKey;
    ChoixValid:=True;
    Case Choix of
     'A','a':If Questions[QuestionList[I]].Response='A'Then Inc(Good)
                                                       Else Inc(Bad);
     'B','b':If Questions[QuestionList[I]].Response='B'Then Inc(Good)
                                                       Else Inc(Bad);
     'C','c':If Questions[QuestionList[I]].Response='C'Then Inc(Good)
                                                       Else Inc(Bad);
     'D','d':If Questions[QuestionList[I]].Response='D'Then Inc(Good)
                                                       Else Inc(Bad);
     #27:Begin
      TextColor(LightRed);
      WriteLn('Test abandonn‚');
      Halt;
     End;
     Else ChoixValid:=False;
    End;
   Until ChoixValid;
   WriteLn(Choix);
   WriteLn;
  End;
  If Trunc((Good/NumQuestion)*100)>60 Then Begin
   TextColor(LightGreen);
   WriteLn('VOUS AVEZ REUSSIS LE QUIZ !');
   WriteLn('FELICITATION !');
  End
   Else
  Begin
   TextColor(LightRed);
   WriteLn('VOUS AVEZ ECHOUER LE QUIZ !');
  End;
  WriteLn('Vous avez obtenu une note de ',Trunc((Good/NumQuestion)*100),'% !');
  WriteLn('Bonne r‚ponse : ',Good);
  WriteLn('Mauvaise r‚ponse : ',Bad);
 End;
END.
