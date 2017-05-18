{$A+,B-,D+,E+,F-,G+,I+,L+,N-,O-,P-,Q-,R-,S+,T-,V+,X+,Y+}
{ This is a striped version of the utility unit that the rest of the DumpExe }
{ utilitys use. I could have used copy and paste but I didn't ;-)            }

Unit UnpUtil;

Interface

Uses
  Crt,
  Dos;

Const
  Version        = '2.5';
  VersionHex     = $0240;

  UnpackerText   = 'Unpacker v' + Version + ' ';
  TitleText2     = 'CARDWARE 1998 by ';
  TitleText3     = 'BUGSY/OBSESSiON';
  IntFB          = $fb;

Type
  Str80          = String[80];

Procedure WriteTitleText;
Procedure LastInitText;
Procedure MakeWindow (X1, Y1, Wide, Hight, BackColor, ForColor, TopColor : Byte; TopText : Str80);
Function DumpExeAPIResident : Boolean;
Function DumpExeResident : Boolean;

Implementation

Function DumpExeResident : Boolean; ASSEMBLER;
asm
  xor     ax, ax
  mov     es, ax
  les     di, es:[IntFB*4]
  cmp     di, 0FFFAh
  ja      @NotFound
  cmp     word ptr es:[di+2],'UD' {DUMP}
  jne     @NotFound
  cmp     word ptr es:[di+4],'PM'
  jne     @NotFound
  mov     al, True
  jmp     @GetOut

@NotFound:
  mov     al, False

@GetOut:
end;

Function DumpExeAPIResident : Boolean; ASSEMBLER;
asm
  xor     ax, ax
  mov     es, ax
  les     di, es:[IntFB*4]
  cmp     di, 0FFFAh
  ja      @NotFound
  cmp     word ptr es:[di+2],'PA' {API!}
  jne     @NotFound
  cmp     word ptr es:[di+4],'!I'
  jne     @NotFound
  mov     al, True
  jmp     @GetOut

@NotFound:
  mov     al, False

@GetOut:
end;

Procedure MakeWindow (X1, Y1, Wide, Hight, BackColor, ForColor, TopColor : Byte; TopText : Str80);
Const
  Frame : String[7] = 'Ú¿³ÄÀÙ';

Var
  Ct  ,
  Ct2 : Byte;

Begin
  Window (X1, Y1, X1+Wide, Y1+Hight);
  TextColor (ForColor);
  TextBackground (BackColor);
  Clrscr;
  Window (X1, Y1, X1+Wide+1, Y1+Hight);
  For Ct := 2 To Wide Do Begin
    GotoXY (Ct, 1);        Write (Frame[4]);
    GotoXY (Ct, Hight+1);  Write (Frame[4]);
  End;

  For Ct := 2 To Hight Do Begin
    GotoXY (1, Ct);        Write (Frame[3]);
    GotoXY (Wide+1, Ct);   Write (Frame[3]);
  End;

  GotoXY (1,1);            Write (Frame[1]);
  GotoXY (Wide+1,1);       Write (Frame[2]);
  GotoXY (1,Hight+1);      Write (Frame[5]);
  GotoXY (Wide+1,Hight+1); Write (Frame[6]);

  GotoXY (Wide - ((Wide + Length (TopText)) DIV 2), 1);
  TextColor (TopColor);
  Write (' '+TopText+' ');
  Window (X1+1, Y1+1, X1+Wide-1, Y1+Hight-1);
End;

Procedure WriteTitleText;
Begin
  GotoXY(13, WhereY+1);

  TextBackGround(Red);
  TextColor (White);
  Write ('ÄÅÄÄ');
  NormVideo;
  TextColor (LightBlue);
  Write (' ', UnpackerText);
  Write (TitleText2);
  TextColor (Yellow);
  Write (TitleText3, ' ');
  TextBackGround(Red);
  TextColor (White);
  WriteLn ('ÄÅÄÄ'#10#13);

  NormVideo;
End;

Procedure LastInitText;
Var
  TheY : Byte;

Begin
  WriteLn;
  TheY := WhereY;
  MakeWindow (8, WhereY, 64, 4, LightBlue, White, Yellow+blink, 'How to register');
  TextColor (White     );  Write   ('To register this program, please fill out the form ');
  TextColor (LightGreen);  Write   ('REGISTER.TXT');
  TextColor (White     );  Write   ('and sent it via E-mail to ');
  TextColor (LightGreen);  Write   ('_BUGSY@USA.NET ');
  TextColor (White     );  Write   ('or goto our home page at ');
  TextColor (LightGreen);  Write   ('home.t-online.de/home/enoch ');
  TextColor (White     );  Write   ('or just send me a nice ');
  TextColor (LightGreen);  Write   ('POSTCARD');
  Window(1, 1, 80, 25);
  NormVideo;
  GotoXY (18, TheY + 5);
  TextColor (LightRed);  Write   ('See the file ');
  TextColor (LightBlue); Write   ('DUMPAPI.TXT ');
  TextColor (LightRed);  WriteLn ('for more detailes.');
End;

End.