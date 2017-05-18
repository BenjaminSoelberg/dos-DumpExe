{$A+,B-,D+,E-,F-,G+,I+,L+,N-,O-,P-,Q-,R-,S+,T-,V+,X+,Y+}
{$M 1024,0,0}

Uses
  Crt,
  ExeUtil;

Procedure DoIt;
Begin
  TextColor(White);
  Write ('þ DumpExe API not resident ');
  If DumpExeAPIResident Then Begin
    TextColor(LightRed);
    WriteLn ('FAILED');
    TextColor(White);
    WriteLn('Error (1) : DumpExe API resident.');
    Exit;
  End;
  WriteLn ('OK');

  Write ('þ DumpExe resident ');
  If NOT DumpExeResident Then Begin
    TextColor(LightRed);
    WriteLn ('FAILED');
    TextColor(White);
    WriteLn('Error (2) : DumpExe not resident.');
    Exit;
  End;
  WriteLn ('OK');

  Write ('þ Starting DUMPEXE ');
  asm
   {int    0fbh}
    db  0cdh
    db  IntFB
  end;
  WriteLn('OK');
End;

Begin
  Clrscr;
  WriteTitleText(4);
  DoIt;
  LastInitText;
  NormVideo;
End.