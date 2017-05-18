{$A+,B-,D+,E+,F-,G+,I+,L+,N-,O-,P-,Q-,R-,S+,T-,V+,X+,Y+}

Unit ExeUtil;

Interface

Uses
  Crt,
  Dos;

Const
  Version        = '2.5';
  VersionHex     = $0240;

  _NoSystem      = 0;    {:-)}
  _Dos           = 2;
  _WinStd        = 4;
  _WinEnh        = 8;
  _OS2           = 16;
  _8086          = 32;
  _80286         = 64;
  _80386         = 128;
  _RealMode      = 256;
  _V86Mode       = 512;

  _NoDebugger    = 1;
  _TurboDebugger = 2;
  _SoftIce       = 4;
  _GameTools     = 8;
  HexStr         : String[16] = '0123456789ABCDEF';
  MousePresent   : Boolean = False;
  SoftIceSIVal   : Word = $4647;
  SoftIceDIVal   : Word = $4A4D;

  DumpTitleText  = 'DumpExe v'+ Version + ' ';
  MakeTitleText  = 'MakeExe v'+ Version + ' ';
  TestTitleText  = 'TestExe v'+ Version + ' ';
  EatTitleText   = 'EatMem v' + Version + ' ';
  DumpAPIText    = 'DumpExe API v' + Version + ' ';
  TitleText2     = 'CARDWARE 1998 by ';
  TitleText3     = 'BUGSY/OBSESSiON';
  DumpID         : Word = Ord ('D') + (Ord ('E') * $100 );
  IntFB          = $fb;

Type
  Str2           = String[2];
  Str4           = String[4];
  Str8           = String[8];
  Str10          = String[10];
  Str12          = String[12];
  Str13          = String[13];
  Str80          = String[80];
  Str20          = String[20];
  Str29          = String[29];
  ExeInfoRecType = Record
    CS           ,
    IP           ,
    SS           ,
    SP           ,
    PSP          : Word;
    Size         : LongInt;
    Name         : Str13;
  End;

Var
  WinMinX      ,
  WinMinY      ,
  WinMaxX      ,
  WinMaxY      : Byte;
  SystemInfo   ,
  DebuggerInfo : Word;

Procedure HideMouse;
Procedure ShowMouse;
{Procedure PopScr (ScrName : Str13);
Procedure PushScr (ScrName : Str13);}
Procedure ShowCursor;
Procedure HideCursor;
Procedure SaveCursor;
Procedure RestoreCursor;
Procedure RestoreWindow;
Procedure ShowTestColor;
Procedure MakeWindow (X1, Y1, Wide, Hight, BackColor, ForColor, TopColor : Byte; TopText : Str80);
Procedure MyWindow (X1, Y1, X2, Y2 : Byte);
Procedure FlushDiskCache;
{Procedure BlinkLEDs; ASSEMBLER; {destroys DS and ES !!}
Procedure FreeMemory (MemPtr : Word);
Procedure WriteTitleText (TextType : Byte);
Procedure LastInitText;

Function H2D (HexNr : Str10) : LongInt;
Function FileExist (FileName : Str12) : Boolean;
Function SizeOfFile (FileName : Str12) : LongInt;
Function D2H (DecNr : LongInt; Size : Word) : Str8;
Function PromptHex (X, Y, BkCol : Byte; OutStr : Str13) : Str13;
Function GetSystemInfo : Word;
Function GetDebuggerInfo : Byte;
Function GetInfoText : Str80;
Function AllocateMemInUMB (MemSizeInP : Word) : Word;
Function DVInstalled : Boolean;
Function DumpExeAPIResident : Boolean;
Function DumpExeResident : Boolean;

Implementation

Const
  OS2_ID          = $4010;
  WIN_ID          = $160a;

Var
  OrgX, OrgY    : Byte;
  SavedCursor   : Word;
  Reg           : Registers;

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
Function DVInstalled : Boolean; ASSEMBLER;
Asm
  xor    bx, bx
  mov    cx, 4445h
  mov    dx, 5351h
  mov    ax, 2B01h
  int    21h
  xor    ax, ax
  test   bx, bx
  je     @DVNotFound
  inc    al
@DVNotFound:
End;

Function AllocateMemInUMB (MemSizeInP : Word) : Word; ASSEMBLER;
Asm
  mov    ax, 5800h              {Get memory allocation strategy}
  int    21h
  push   ax
                                {Set memory allocation strategy}
  mov    ax, 5801h              {To UMB first fit then Base first fit}
  mov    bx, 0080h
  int    21h

  mov    ax, 5802h              {Get UMB link}
  int    21h
  push   ax

  mov    ax, 5803h              {Set UMB link}
  mov    bx, 0001h              {On}
  int    21h

  mov    ah, 48h                {Allocate memory}
  mov    bx, word ptr MemSizeInP
  int    21h
  jnc    @NoError

  xor    ax, ax

@NoError:
  mov    MemSizeInP, ax         {Reuse of variable on stack}
  mov    ax, 5803h              {Restore UMB link}
  pop    bx
  xor    bh, bh
  int    21h

  mov    ax, 5801h              {Restore memory allocation strategy}
  pop    bx
  int    21h
  mov    ax, MemSizeInP         {Reuse of variable on stack}
End;

Procedure FreeMemory (MemPtr : Word); ASSEMBLER;
Asm
  mov    ah, 48h
  mov    es, word ptr MemPtr
  int    21h
End;
(*
Procedure BlinkLEDs; ASSEMBLER;  {destroys DS and ES !!}
asm
  push    0
  pop     ds
  push    cs
  pop     es

  sti
  mov     al, byte ptr [0417h]
  and     al, 01110000b
  push    ax                      {save original LED state}
  cld
  mov     cx, 3
@NextBlink:
  or      byte ptr [0417h], 01110000b {turn LED's on}
  call    @Wait                       {wait 2 ticks}
  and     byte ptr [0417h], 10001111b {turn LED's on}
  call    @Wait                       {wait 2 ticks}
  loop    @NextBlink
  pop     ax                          {restore LED state}
  or      byte ptr [0417h], al
  call    @Wait                       {commit LED state to keybd}

  cli
  ret

@Wait:
  mov     ah, 01h                     {commit LED state to keybd}
  int     16h
  mov     al, 2
@NeedMoreTime:
  mov     ah, [046ch]
@WaitOneTick:
  cmp     ah, [046ch]
  je      @WaitOneTick
  dec     al
  jnz     @NeedMoreTime                {wait 2 (or more) ticks}
  ret
End;
*)
Procedure FlushSmartdrv; ASSEMBLER;
Asm
  push  bp              {Bugsy you jerk, ALWAYS REMEMBER TO SAVE BP !!!(FUCK ME)}

  mov   ax, 4a10h       {Smartdrv flush disk cache} {Works for PC-cache too}
  mov   bx, 0001h
  int   2fh

  pop   bp
End;

Function SmartDriveExist : Boolean; ASSEMBLER;
Asm
  push  bp              {Bugsy you jerk, ALWAYS REMEMBER TO SAVE BP !!!(FUCK ME)}

  mov   ax, 4a10h       {Smartdrv installation check} {Works for PC-cache too}
  xor   bx, bx
  int   2fh
  cmp   ax, 0BABEh
  je    @SmartFound
  xor   ax, ax
@SmartFound:            {Since BEh is TRUE in a boolean way we just return it}

  pop   bp
End;

Procedure FlushDiskCache;
Begin
  If SmartDriveExist Then FlushSmartdrv;
End;

Function GetSystemInfo : Word;
Var
  TempAX   : Word;
  TempCX   : Word;
  TempWord : Word;

Begin
  TempWord := 0;

  asm
    mov   ax, OS2_ID
    int   2fh
    mov   TempAX, ax
  end;
  If TempAX <> OS2_ID Then                       {ax <> 4010 if installed }
    TempWord := TempWord + _OS2;

  asm
    mov   ax, WIN_ID
    int   2fh
    mov   TempAX, ax
    mov   TempCX, cx
  end;
  If TempAX = 0 Then
    Case TempCX Of
      2 : TempWord := TempWord + _WinStd;
      3 : TempWord := TempWord + _WinEnh;
    End;

  If TempWord = _NoSystem Then
    TempWord := TempWord + _Dos;


  Case Test8086 of
    0 : TempWord := TempWord + _8086;
    1 : TempWord := TempWord + _80286;
    2 : TempWord := TempWord + _80386;
  End;
  If Test8086 >= 1 Then
  asm
    smsw  ax
    and   al, 1
    cmp   al, True
    jne   @RealMode
    add   TempWord, _V86Mode
    jmp   @GetOut
@RealMode:
    add   TempWord, _RealMode
@GetOut:
  end;

  GetSystemInfo := TempWord;
End;

Function GetDebuggerInfo : Byte;
Var
  Ct       : Byte;
  IntPtr   : Pointer;
  TempByte : Byte;

Begin
  TempByte := 0;

  For Ct := 0 to 255 Do Begin
    GetIntVec (Ct, IntPtr);
    If IntPtr = Ptr($00AB,$CDEF) Then Begin
      TempByte := TempByte OR _GameTools;
      Break;
    End;
  End;

  {test for soft-ice}
  asm
    push   es
    xor    ax, ax
    mov    es, ax
    push   es:word ptr [000Ch]
    push   es:word ptr [000Eh]
    mov    ax, Offset @IRetOpCode
    mov    es:[000Ch], ax
    mov    ax, cs
    mov    es:[000Eh], ax
    xor    ax, ax
    mov    si, SoftIceSIVal
    mov    di, SoftIceDIVal
    int    03h
    pop    es:word ptr [000Eh]
    pop    es:word ptr [000Ch]
    cmp    si, SoftIceSIVal
    je     @GetOut
    or     TempByte, _SoftIce
    jmp    @GetOut
@IRetOpcode:
    iret
@GetOut:
    pop    es
  End;

  {test for td}
  asm
    xor    ax, ax
    mov    es, ax
    cmp    word ptr es:[0feh * 4 + 2], 0a000h
    jnb    @NoTurboDebugger                     {test if vector is valid}
    cmp    word ptr es:[0feh * 4], 0004h
    jb     @NoTurboDebugger                     {test if vector is valid}

    les    bx, es:[0feh * 4]
    cmp    es:word ptr [bx-04], 07324h
    jne    @NoTurboDebugger                     {test if td is installed}
    cmp    es:word ptr [bx-02], 0FEEDh
    jne    @NoTurboDebugger                     {test if td is installed}
    or     TempByte, _TurboDebugger

@NoTurboDebugger:
    xor    ax, ax
    mov    es, ax
    les    bx, es:[03h * 4]
    cmp    es:word ptr [bx], 0B050h
    jne    @NoTurboDebugger286                  {test if td is installed}
    or     TempByte, _TurboDebugger

@NoTurboDebugger286:
    mov    ax, 0FB43h
    mov    bx, 0100h
    int    2fh
    cmp    bx, 0FB43h
    jne    @NoTurboDebugger386
    or     TempByte, _TurboDebugger

@NoTurboDebugger386:
    xor    ax, ax
    mov    es, ax
    les    bx, es:[01bh * 4]
    cmp    word ptr es:[bx], 0EACFh
    jne    @NoTurboDebugger500
    or     TempByte, _TurboDebugger
@NoTurboDebugger500:
  end;

  If TempByte = 0 Then TempByte := _NoDebugger;
  GetDebuggerInfo := TempByte;
End;

Function GetInfoText : Str80;
Var
  TempStr : Str80;

Begin
  TempStr := '';
  SystemInfo := GetSystemInfo;
  DebuggerInfo := GetDebuggerInfo;

  If SystemInfo   AND _Dos           = _Dos           Then TempStr := TempStr + 'Dos, ';
  If SystemInfo   AND _WinStd        = _WinStd        Then TempStr := TempStr + 'Win Std, ';
  If SystemInfo   AND _WinEnh        = _WinEnh        Then TempStr := TempStr + 'Win Enh, ';
  If SystemInfo   AND _OS2           = _OS2           Then TempStr := TempStr + 'OS/2, ';
  If SystemInfo   AND _8086          = _8086          Then TempStr := TempStr + '8086, ';
  If SystemInfo   AND _80286         = _80286         Then TempStr := TempStr + '80286, ';
  If SystemInfo   AND _80386         = _80386         Then TempStr := TempStr + 'ò80386, ';
  If SystemInfo   AND _RealMode      = _RealMode      Then TempStr := TempStr + 'Real mode, ';
  If SystemInfo   AND _V86Mode       = _V86Mode       Then TempStr := TempStr + 'V86 mode, ';
  If DebuggerInfo AND _NoDebugger    = _NoDebugger    Then TempStr := TempStr + 'No debugger, ';
  If DebuggerInfo AND _TurboDebugger = _TurboDebugger Then TempStr := TempStr + 'Turbo Debugger, ';
  If DebuggerInfo AND _SoftIce       = _SoftIce       Then TempStr := TempStr + 'Soft-Ice, ';
  If DebuggerInfo AND _GameTools     = _GameTools     Then TempStr := TempStr + 'GameTools, ';

  GetInfoText := Copy (TempStr, 1,Length (TempStr)-2) {Cut ', '}
End;

Procedure MyWindow (X1, Y1, X2, Y2 : Byte);
Begin
  Window (X1, Y1, X2, Y2);
  WinMinX := X1;
  WinMinY := Y1;
  WinMaxX := X2;
  WinMaxY := Y2;
End;

Procedure HideMouse;
Begin
  If NOT MousePresent Then Exit;
  asm
    mov     ax, 0002h
    int     33h
  end;
End;

Procedure ShowMouse;
Begin
  If NOT MousePresent Then Exit;
  asm
    mov     ax, 0001h
    int     33h
  end;
End;

Procedure ShowTestColor;
Var
  Ct : Byte;
Begin
  For Ct := 0 to 15 Do Begin
    TextColor(Ct);
    Write ('* ');
  End
End;

Procedure ShowCursor;
Begin
  Reg.ah := 1;
  Reg.cx := $0607;
  Intr ($10, reg);
End;

Procedure HideCursor;
Begin
  Reg.ah := 1;
  Reg.cx := $2000;
  Intr ($10, reg);
End;

Procedure SaveCursor;
Begin
  Reg.ah := 3;
  Reg.bh := 0;
  Intr ($10, reg);
  SavedCursor := Reg.cx;
End;

Procedure RestoreCursor;
Begin
  Reg.ah := 1;
  Reg.cx := SavedCursor;
  Intr ($10, reg);
End;

Function D2H (DecNr : LongInt; Size : Word) : Str8;
Var
  Ct      : Byte;
  TempStr : Str8;

Begin
  Asm
    lea  si, DecNr
    lea  di, TempStr
    mov  bx, Offset HexStr + 1
    mov  ax, size
    mov  ss:[di], al
    add  di, ax
    mov  cx, ax

@NextChar:
    xor  ax, ax
    mov  al, ss:[si]

    mov  ah, al
    and  al, 0Fh
    xlat
    mov  ss:[di], al
    dec  di
    dec  cx
    jz   @Done

    mov  al, ah
    shr  al, 01h
    shr  al, 01h
    shr  al, 01h
    shr  al, 01h
    xlat
    mov  ss:[di], al
    dec  di
    dec  cx
    jz   @Done

    inc  si
    jmp  @NextChar
@Done:
  End;
  D2H := TempStr;
End;

Function H2D (HexNr : Str10) : LongInt;
Var
  Ct        : Byte;
  TempLInt  : LongInt;

Begin
  TempLInt := 0;
  For Ct := 0 To Length (HexNr) - 1 Do
    TempLInt := TempLInt + (LongInt (Pos (HexNr[ Length (HexNr) - Ct ], HexStr) - 1) SHL (Ct * 4));
  H2D := TempLInt;
End;

Function PromptHex (X, Y, BkCol : Byte; OutStr : Str13) : Str13;
Var
  Ct        : Byte;
  Ch        : Char;
  OldOutStr : Str13;

Begin
  TextColor (LightCyan);
  TextBackground (BkCol);
  GotoXY (X, Y);
  Write (OutStr);
  GotoXY (X, Y);
  ShowCursor;
  OldOutStr := OutStr;
  Ct := 1;
  Repeat
    Ch := UpCase(ReadKey);
    Case Ch Of
      '0'..'9' ,
      'A'..'F' : Begin
                   OutStr[Ct] := Ch;
                   Write (Ch);
                   If Ct = Length (OutStr)Then
                     GotoXY (WhereX-1, WhereY)
                   Else
                     Inc (Ct);
                 End;
      #00 : Begin
              Ch := UpCase(ReadKey);
              Case Ch Of
                #75 : If Ct <> 1 Then Begin
                        Dec (Ct);
                        GotoXY (WhereX-1, WhereY);
                      End;
                #77 : If Ct <> Length (OutStr)Then Begin
                        Inc (Ct);
                        GotoXY (WhereX+1, WhereY);
                      End;
              End;
            End;
    End;
  Until (Ch = #27) OR (Ch = #13);
  If Ch = #27 Then Begin
    PromptHex := OldOutStr;
    GotoXY (X, Y);
    Write (OldOutStr);
  End Else PromptHex := OutStr;
  HideCursor;
End;

Procedure TestDosError;
Var
  Ct : Byte;

Begin
  If IOResult <> 0 Then
  Begin
    Sound (1000);
    Delay (15);
    Sound (2000);
    Delay (15);
    NoSound;
  End;
End;
(*
Procedure PushScr (ScrName : Str13);
Var
  SFile : File;

Begin
  {$I-}
  OrgX := WhereX;
  OrgY := WhereY;
  Assign(SFile, ScrName);
  Rewrite(SFile, 1);
  TestDosError;
  BlockWrite (SFile, PTR($B800,0)^, 4000);
  TestDosError;
  Close (SFile);
  TestDosError;
  FlushDiskCache;
  {$I+}
End;

Procedure PopScr (ScrName : Str13);
Var
  SFile : File;

Begin
  {$I-}
  Assign(SFile, ScrName);
  Reset(SFile, 1);
  TestDosError;
  BlockRead (SFile, PTR ($B800,0)^, 4000);
  TestDosError;
  Close (SFile);
  TestDosError;
  Erase (SFile);
  TestDosError;
  GotoXY (OrgX, OrgY);
  FlushDiskCache;
  {$I+}
End;
*)
Procedure MakeWindow (X1, Y1, Wide, Hight, BackColor, ForColor, TopColor : Byte; TopText : Str80);
Const
{  Frame2 : String[7] = 'É»ºÍÈ¼';}
  Frame : String[7] = 'Ú¿³ÄÀÙ';

Var
  Ct  ,
  Ct2 : Byte;

Begin
  MyWindow (X1, Y1, X1+Wide, Y1+Hight);
  TextColor (ForColor);
  TextBackground (BackColor);
  Clrscr;
  MyWindow (X1, Y1, X1+Wide+1, Y1+Hight);
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
  MyWindow (X1+1, Y1+1, X1+Wide-1, Y1+Hight-1);
End;

Procedure RestoreWindow;
Begin
  MyWindow (1, 1, 80, 25);
  NormVideo;
End;

Function FileExist (FileName : Str12) : Boolean;
Var
  DirInfo : SearchRec;

Begin
  FindFirst (FileName, Archive, DirInfo);
  If DosError = 0 Then FileExist := True
  Else FileExist := False;
End;

Function SizeOfFile (FileName : Str12) : LongInt;
Var
  DirInfo : SearchRec;

Begin
  FindFirst (FileName, Archive, DirInfo);
  SizeOfFile := DirInfo.Size;
End;

Procedure WriteTitleText (TextType : Byte);
Begin
  GotoXY(13, WhereY+1);

  TextBackGround(Red);
  TextColor (White);
  Write ('ÄÅÄÄ');
  NormVideo;
  TextColor (LightBlue);
  Case TextType Of
    1 : Write (' ', DumpTitleText);
    2 : Write (' ', MakeTitleText);
    3 : Write (' ', TestTitleText);
    4 : Write (' ', EatTitleText);
    5 : Write (' ', DumpAPIText);
  End;
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
  TextColor (LightBlue); Write   ('DUMPEXE.TXT ');
  TextColor (LightRed);  WriteLn ('for more detailes.');
End;

Begin
  asm
    xor      ax, ax
    int      33h
    cmp      ax, 0ffffh
    jne      @NoMouse
    mov      MousePresent, True
@NoMouse:
  end;
End.