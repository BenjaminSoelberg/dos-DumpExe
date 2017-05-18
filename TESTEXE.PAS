{$A+,B-,D+,E-,F-,G+,I-,L+,N-,O-,P-,Q-,R-,S+,T-,V+,X+,Y+}
{$M 16384,0,0}
Program TextExe;

Uses
  Crt,
  ExeUtil;

Const
  OrgSize = 9328;
  PakSize = 6829;

Var
  F : File;

Begin
  Clrscr;
  Assign (F, ParamStr(0));
  Reset (F, 1);
  WriteTitleText(3);

  TextColor(White);
  WriteLn;
  WriteLn ('File size');
  WriteLn ('컴컴컴컴컴컴컴�');
  WriteLn ('Original : ', OrgSize);
  WriteLn ('Packed   : ', PakSize);
  WriteLn ('This one : ', FileSize(F));
  WriteLn;
  TextColor(Green);
  Write ('So what you can see is : ');
  TextColor(LightRed);
  If FileSize (F) > PakSize Then
  Begin
    WriteLn ('I''m NOT packed any more!');
    WriteLn;
    If FileSize (F) > OrgSize Then Begin
      TextColor (Cyan);
      WriteLn ('But my file size is greater than the original one. This is because I have');
      WriteLn ('some ''dead code'' in me, which usually is parts of the unpacker function.');
    End
  End
  Else
    WriteLn ('I''m still packed !');
  LastInitText;
  Close (F);
End.
