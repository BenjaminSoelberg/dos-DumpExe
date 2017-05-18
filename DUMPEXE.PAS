{$A+,B-,D+,E-,F-,G+,I-,L+,N-,O-,P-,Q-,R-,S-,T-,V-,X+,Y+}
{$M 4096,0,0}

Program DumpExe;

Uses
  Crt    ,
  Dos    ,
  Choose ,
  ExeUtil;

Const
  {DEBUG PART START}
  Debug          : Boolean = BOOLEAN(0);           {SET TO FALSE AT RELEASE!}
  UseInt09       = BOOLEAN(1);                     {SET TO TRUE  AT RELEASE!}
  UseIntFB       = BOOLEAN(1);                     {SET TO TRUE  AT RELEASE!}
  UseInt32       = BOOLEAN(1);                     {SET TO TRUE  AT RELEASE!}

  DoRestoreOnSwap= False;
  {DEBUG PART END}

  DoAllocMem     : Boolean = False;
  MenuColor      : Byte = White; {Changed in 2.3}
  MaxMenu        = 6;
  MinMenu        = 1;
  StatusLine     = 19;
  Kb4Size        = $0100;
  ScrBuffSize    = 4000;
  AllocText      : String[18] = 'Allocate 4Kb       ';
  DeAllocText    : String[18] = 'Release 4Kb        ';
  HotKey         : String[34] = 'Hotkey = Left Shift + Right Shift.';
  MyMaxX         : Byte = 80;
  MyMaxY         : Byte = 25;
  ConfigIDType   : Word = Ord ('E') * $100 + Ord ('D');
  OnOffAuto      : Array[0..2] Of String[4] = ('OFF ','ON  ','AUTO');
  PSPLevel       : Array[0..3] Of String[6] = ('NONE  ','SOFT  ','MEDIUM','HARD  ');
  RegStr         : Array [0..4] Of String[3] = ('CS','IP','SS','SP','ES');

Type
  ExeHeaderRecType = Record
    ExeSign        ,
    ByteOnLastPage ,
    FileSizeDIV512 ,
    NumberOfRel    ,
    HeaderSizeInP  ,
    MinMemInP      ,
    MaxMemInP      ,
    SS             ,
    SP             ,
    ChkSum         , {Used to place config}
    IP             ,
    CS             ,
    RelocTabel     ,
    Overlay        : Word;
  End;

  ConfigType = Record
    ConfigID        : Word;
    Version         : Word;
    Rasterbar       : Byte;
    FastMode        : Boolean;
    StackSize       ,
    SoftICESIVal    ,
    SoftICEDIVal    : Word;
    Int09           ,
{    IntFB           ,}
    Int32           ,
    PSPValLevel     : Byte;
  End;

Var
  TempX          ,
  TempY          ,
  MenuWin        ,
  CMenuWin       : Byte; {Global because it hold the last used menus}
  Kb4Seg         ,
  Blocks         ,
  DosStackSize   ,
  ScrBuffSeg     ,
  NewDosStackSeg ,
  OldStackSeg    ,
  OldStackPtr    ,
  StackSeg       ,
  StackPtr       : Word;
  OrgInt09       ,
  OrgIntFB       ,
  OrgInt32       : Procedure;
  ExeInfo        : Array [1..2] Of ExeInfoRecType;
  HotkeyPressed  ,
  NowInExeMenu   : Boolean;
  Reg            : Registers;
  ScrPtr         : Array[0..3999] Of Byte ABSOLUTE $B800:$0000;
  DosStackPtr    : Pointer;
  Config         : ConfigType;
  CfgName        : String;
  CfgFile        : File Of ConfigType;
  OrgCfgInt32    : Byte;
  DumpExeFile    : File Of ExeHeaderRecType;
  DumpExeHeader  : ExeHeaderRecType;
  SICE_CS        ,
  SICE_IP        ,
  SICE_SS        ,
  SICE_SP        ,
  SICE_PSP       : Word;

Function TestVectores : Boolean; forward;
Procedure WaitSL (InStr : Str80); forward;

Function RasterBar : Boolean;
Begin
  If Config.RasterBar = 2 Then Rasterbar := NOT Boolean((SystemInfo AND _WinStd) OR (SystemInfo AND _WinEnh))
  Else Rasterbar := Boolean(Config.RasterBar);
End;

Function AutoFillFromTurboDebugger (FileNr : Byte) : Boolean;
Const
  IndexY : Array [0..4] Of Byte = (11,12,10,7,9); {cs, ip, ss, sp, psp«}

Var
  Ct      ,
  Ct2     ,
  CtX     ,
  CtY     : Word;
  AddX    : Byte;
  TempStr : String[4];
  TempExeInfo : ExeInfoRecType;

Begin
  FillChar (TempExeInfo, SizeOf(TempExeInfo), 0);
  AutoFillFromTurboDebugger := False;
  AddX := 0;
  For Ct := 0 To MyMaxX * (MyMaxY - 19) Do
    If ScrPtr[Ct*2] = 209 Then Begin                {Ñ}
      Ct := Ct + MyMaxX;
      If (ScrPtr[(Ct+1)*2] = Ord('e')) AND (ScrPtr[(Ct+2)*2] = Ord('a')) AND (ScrPtr[(Ct+3)*2] = Ord('x')) Then AddX:= 9;
      If (ScrPtr[(Ct+3)*2] = Ord('a')) AND (ScrPtr[(Ct+4)*2] = Ord('x')) Then AddX := 6;
      If AddX <> 0 Then Begin
        AutoFillFromTurboDebugger := True;
        Ct := Ct + AddX;
        For CtY := 0 To 4 Do Begin
          TempStr := '0000';
          For CtX := 0 To 3 Do
            TempStr[CtX+1] := Chr(ScrPtr[(Ct+CtX+(IndexY[CtY]*MyMaxX))*2]);
          For Ct2 := 1 To Length (TempStr) Do
            If Pos (TempStr[Ct2], HexStr) = 0 Then Begin
              WaitSL ('Error reading register ' + RegStr[Ct2] + ', aborting !');
              AutoFillFromTurboDebugger := False;
              Exit;
            End;
          Case CtY Of
            0 : TempExeInfo.CS  := H2D (TempStr);
            1 : TempExeInfo.IP  := H2D (TempStr);
            2 : TempExeInfo.SS  := H2D (TempStr);
            3 : TempExeInfo.SP  := H2D (TempStr);
            4 : TempExeInfo.PSP := H2D (TempStr);
          End;
        End;
        ExeInfo[FileNr].CS  := TempExeInfo.CS;
        ExeInfo[FileNr].IP  := TempExeInfo.IP;
        ExeInfo[FileNr].SS  := TempExeInfo.SS;
        ExeInfo[FileNr].SP  := TempExeInfo.SP;
        ExeInfo[FileNr].PSP := TempExeInfo.PSP;
        Break;
      End Else
        AutoFillFromTurboDebugger := False;
    End;
  IF Ct = (MyMaxX * (MyMaxY - 19)) Then
    AutoFillFromTurboDebugger := False;
End;

{Procedure SendSoftICECmd (Dest : Word; Reg : Str2);
Begin
  SoftICEStr := 'EW ' + d2h(SEG(TempX),4) + ':' + d2h(Dest,4) + ' ' + Reg + #$0d#0;
  asm
    mov   ax, 0911h
    mov   si, config.SoftICESIVal
    mov   di, config.SoftICEDIVal
    mov   dx, offset SoftICEStr + 1
    int   03
  end;
End;}

Function AutoFillFromSoftIce (FileNr : Byte) : Boolean;
Begin
{  SendSoftICECmd(Ofs(ExeInfo[FileNr].CS ), 'CS');
  SendSoftICECmd(Ofs(ExeInfo[FileNr].IP ), 'IP');
  SendSoftICECmd(Ofs(ExeInfo[FileNr].SS ), 'SS');
  SendSoftICECmd(Ofs(ExeInfo[FileNr].SP ), 'SP');
  SendSoftICECmd(Ofs(ExeInfo[FileNr].PSP), 'ES');}
  ExeInfo[FileNr].CS  := SICE_CS;
  ExeInfo[FileNr].IP  := SICE_IP;
  ExeInfo[FileNr].SS  := SICE_SS;
  ExeInfo[FileNr].SP  := SICE_SP;
  ExeInfo[FileNr].PSP := SICE_PSP;
  AutoFillFromSoftIce := True;
{  WaitSL('SoftICE support not implemented yet, sorry.');}
End;

Function AutoFillFromGameTools (FileNr : Byte) : Boolean;
Var
  Ct      : Word;
  TempStr : String;

Begin
  TempStr := '';
  For Ct := 0 To 80 * 3 Do TempStr := TempStr + Char(ScrPtr[Ct*2]); {Damn i'm good}
  If Pos('GAMETOOLS', TempStr) <> 0 Then Begin
    ExeInfo[FileNr].CS  := H2D (Copy (TempStr, Pos('CS', TempStr) + 3, 4));
    ExeInfo[FileNr].IP  := H2D (Copy (TempStr, Pos('IP', TempStr) + 3, 4));
    ExeInfo[FileNr].SS  := H2D (Copy (TempStr, Pos('SS', TempStr) + 3, 4));
    ExeInfo[FileNr].SP  := H2D (Copy (TempStr, Pos('SP', TempStr) + 3, 4));
    ExeInfo[FileNr].PSP := H2D (Copy (TempStr, Pos('ES', TempStr) + 3, 4));
    AutoFillFromGameTools := True;
  End Else
    AutoFillFromGameTools := False;
End;

Procedure SwapScr (SwapToOrg : Boolean);
Var
  Ct       : Word;
  XByte    : Byte;
  TempOldX ,
  TempOldY : Byte;

Begin
  TempOldX := WhereX;
  TempOldY := WhereY;
  If SwapToOrg Then
    Window (1,1,80,25)
  Else
    Window (WinMinX, WinMinY, WinMaxX, WinMaxY);
  For Ct := 0 To ScrBuffSize - 1 Do Begin
    XByte := Mem [$B800:Ct];
    Mem [$B800:Ct] := Mem[ScrBuffSeg:Ct];
    Mem[ScrBuffSeg:Ct] := XByte;
  End;
  GotoXY (TempX, TempY);
  TempX := TempOldX;
  TempY := TempOldY;
End;

Procedure MyPushScr;
Var
  Ct : Word;

Begin
  TempX := WhereX;
  TempY := WhereY;
  For Ct := 0 To ScrBuffSize - 1 Do
    Mem[ScrBuffSeg:Ct] := Mem [$B800:Ct];
End;

Procedure MyPopScr;
Var
  Ct : Word;

Begin
  For Ct := 0 To ScrBuffSize - 1 Do
    Mem [$B800:Ct] := Mem[ScrBuffSeg:Ct];
  window (1,1,80,25);
  GotoXY (TempX, TempY);
End;

Procedure CenterText (InStr : Str80; LF : Boolean);
Begin
  GotoXY (59 - ((59 + Length(InStr)) DIV 2), WhereY);
  If LF Then
    WriteLn (InStr)
  Else
    Write (InStr);
End;

Procedure CenterTextLeftAndRight (InStr : Str80; LF : Boolean);
Begin
  TextBackground (3);
  GotoXY (30 - ((30 + Length(InStr)) DIV 2), WhereY);
  Write (InStr);
  TextBackground (4);
  GotoXY (60 - ((30 + Length(InStr)) DIV 2), WhereY);
  If LF Then
    WriteLn (InStr)
  Else
    Write (InStr);
End;

Procedure CenterTextLeftOrRight (InStr : Str29; LR : Boolean);
Begin
  TextBackground (3+byte(LR));
  GotoXY (((Byte (LR)+1)*30)-Byte(LR) - ((27 + Length(InStr)) DIV 2), WhereY);
  WriteLn (InStr);
End;

Procedure WriteSL (InStr : Str80);
Begin
  TextColor (White);
  TextBackground (Blue);
  GotoXY (1, StatusLine);
  CenterText (InStr, False);
End;

Procedure ClearSL;
Var
  Ct : Byte;

Begin
  GotoXY (1, StatusLine);
  For Ct := 1 To 58 Do
    Write (' ');
End;

Procedure WaitSL (InStr : Str80);
Begin
  WriteSL (InStr);
  ReadKey;
  While Keypressed Do ReadKey;
  ClearSL;
End;

Procedure UpdateMemAvail;
Var
  Ct      ,
  MemFree : Word;

Begin
  asm
    mov  ah, 48h
    mov  bx, 0ffffh
    int  21h
    mov  MemFree, bx
  End;

  TextColor (LightBlue);
  TextBackground (Blue);
  GotoXY (32, StatusLine-1);
  For Ct := 1 To 28 Do
    Write ('Ä');

  TextColor (MenuColor);
  GotoXY (32, StatusLine-1);
  Write (' Free ', LongInt (MemFree) * $10 DIV $400, ' kb, Slack ',Blocks*4,' kb ');
End;

Function IsPSPOk (FileNr : Byte) : Boolean;
Var
  Ct       ,
  ResCt    : Byte;
  TempPSP  : Word;

Begin
  ResCt     := 0;
  {Check for INT 20h}
  TempPSP := ExeInfo[FileNr].PSP;
  Inc (ResCt, Byte(MemW [TempPSP:0] = $20CD));

  {Check env.filename ok}
  asm
    xor     ax, ax
    mov     es, TempPSP
    mov     es,es:[002Ch]
    xor     di, di
    cld
    mov     cx, 02000h

@FindNextZero:
    cmp     al, es:[di]
    je      @NameStartFound
    repnz   scasb
    cmp     cx, 0
    je      @NoInc
    jmp     @FindNextZero

@NameStartFound:
    mov     cx, 256
    add     di, 3
    mov     al, '.'
    rep     scasb
    cmp     cx, 0
    je      @NoInc
    inc     ResCt
@NoInc:
  end;

  For Ct := $80 To $FF Do
    If MemW[TempPSP:Ct] = $0d Then Begin
      Inc (ResCt);
      Break;
    End;

  IsPSPOK := ResCt >= Config.PSPValLevel;
End;

Function PSPOk (FileNr : Byte) : Boolean;
Begin
  If NOT IsPSPOk (FileNr) Then
  Begin
    WaitSL ('The PSP-segment is not valid !');
    PSPOk := False;
  End
  Else
    PSPOk := True
End;

Function Prompt (InStr : Str80; Legal : Str10) : Byte;
Var
  Ch : Char;
  Ct : Byte;

Begin
  ShowCursor;
  WriteSL (InStr);
  Repeat
    Ch := UpCase (ReadKey);
  Until Pos (Ch, Legal) <> 0;
  Prompt := Pos (Ch, Legal) - 1;
  ClearSL;
  HideCursor;
End;

Procedure AllocMem;
Var
  ErrorNr : Byte;

Begin
  If ExeInfo[1].PSP = 0 Then Begin
    WaitSL ('PSP not set for file 1 (PSP = 0000)');
    Exit;
  End;

  If NOT IsPSPOk(1) Then
    If Prompt ('The PSP for file 1 is not valid, allocate anyway [Y/N] ','YN') <> 0 Then
      Exit;
  ErrorNr := 0;
  asm
    push es
    mov  cx, sp

@OneMoreBlock:
{    cmp  sp, 0
    je   @StackError}
    cmp  sp, 1
    jbe   @StackError
    mov  ah, 48h
    mov  bx, Kb4Size
    int  21h
    jc   @AllocError
    jmp  @NoError

@AllocError:
    mov  ErrorNr, 1
    jmp  @ReleaseIt

@StackError:
    mov  ErrorNr, 2
    jmp  @ReleaseIt

@ReleaseError:
    mov  ErrorNr, 3
    jmp  @done

@NoError:
    push ax
    cmp  ax, ExeInfo.ExeInfoRecType.PSP
    jb   @OneMoreBlock

    pop  ax
    mov  Kb4Seg, ax

@ReleaseIt:
    mov  bx, cx
    sub  bx, sp
    mov  Blocks, bx

@MoreRelease:
    cmp  cx, sp
    je   @Done
    mov  ah, 49h
    pop  es
    int  21h

    jmp @MoreRelease
@Done:
    pop  es
  End;
  Case ErrorNr Of
    1 : Begin
          WaitSL ('Can''t allocate necessary memory ! (USE EATMEM.EXE)');
          Blocks := 0;
        End;
    2 : Begin
          WaitSL ('Out of stack. Allocate more stack in config menu !');
          Blocks := 0;
        End;
    3 : Begin
          WaitSL ('Can''t release memory !');
          Blocks := 0;
        End;
  End;
  UpdateMemAvail;
End;

Procedure DeAllocMem (UpdateMemText : Boolean);
Begin
  asm
    push es
    mov  ah, 49h
    mov  bx, Kb4Seg
    mov  es, bx
    int  21h
    jc   @Error

    mov  Kb4Seg, 0

    mov  Blocks, 0
@Error:
    pop  es
  End;
  If UpdateMemText Then UpdateMemAvail;
End;

Procedure DeleteTSR;
Begin
  If UseInt09 Then SetIntVec (Config.Int09, @OrgInt09);  {Restore used vectores}
  If UseIntFB Then SetIntVec (IntFB       , @OrgIntFB);
{  If UseInt32 Then SetIntVec (Config.Int32, @OrgInt32); BUG BUG BUG}
  If UseInt32 Then SetIntVec (OrgCfgInt32, @OrgInt32);

  If (Kb4Seg <> 0) Then DeAllocMem (False);
  asm
    mov     ah, 49h
    mov     es, word ptr NewDosStackSeg
    int     21h

    mov     ah, 49h
    mov     es, word ptr ScrBuffSeg
    int     21h

    mov     ah, 49h
    mov     es, word ptr PrefixSeg
    int     21h
  end;
End;

Procedure UpdateExeInfo;
Var
  Ct : Byte;
  TheSize : Str13;

  Procedure FastModeOrNot (Text1, Text2 : Str80; DoIt : Boolean);
  Begin
    GotoXY(((ct-1)*30)+1,WhereY);
    If DoIt AND Config.FastMode AND (Ct = 2) Then Begin
      TextColor(LightGray);
      WriteLn(Text1,Text2);
    End Else Begin
      TextColor(Yellow);
      Write(Text1);
      TextColor(LightCyan);
      WriteLn (Text2);
    End;
 End;

Begin
  For Ct := 1 To 2 Do
  Begin
    GotoXY (((Ct-1)*30)+1,2);
    With ExeInfo[Ct] Do
    Begin
      TextBackground (Ct + 2);
      Str(Size, TheSize);
      TheSize := ' (' + TheSize + ')      ';
      FastModeOrNot(' CS   : ',D2H(LongInt(CS),  4), True);
      FastModeOrNot(' IP   : ',D2H(LongInt(IP),  4), True);
      FastModeOrNot(' SS   : ',D2H(LongInt(SS),  4), True);
      FastModeOrNot(' SP   : ',D2H(LongInt(SP),  4), True);
      FastModeOrNot(' PSP  : ',D2H(LongInt(PSP), 4), False);
      FastModeOrNot(' Size : ',D2H(LongInt(Size),5) + TheSize, True);
      FastModeOrNot(' Name : ', Name, True);
    End;
  End;
End;

Procedure Make3Windows;
Var
  Ct  ,
  Ct2 : Byte;

Begin
  For Ct := 2 To 17 Do
  Begin
    If Ct = 9 Then
      Inc (Ct);
    If Ct = 13 Then
      Inc (Ct);
    TextBackground (3);
    GotoXY (1, Ct);
    For Ct2 := 1 To 29 Do
      Write (' ');

    TextBackground (4);
    GotoXY (31, Ct);
    For Ct2 := 1 To 29 Do
      Write (' ');
  End;

  TextColor (MenuColor);
  GotoXY (1, 10);

  CenterTextLeftAndRight ('Dump exe-code   ', True);
  CenterTextLeftAndRight ('Autodetect name ', True);
  CenterTextLeftAndRight ('Autodetect size ', True);
  WriteLn;
  CenterTextLeftOrRight ('Configuration      ', False);
  CenterTextLeftOrRight ('Memory snapshot    ', False);
  CenterTextLeftOrRight ('Reset menu         ', False);
  CenterTextLeftOrRight ('Uninstall          ', False);

  GotoXY (30, 14);
  CenterTextLeftOrRight ('User screen       ', True);
  If Kb4Seg = 0 Then
    CenterTextLeftOrRight (AllocText, True)
  Else
    CenterTextLeftOrRight (DeAllocText, True);
  CenterTextLeftOrRight ('Auto config file 2', True);
  CenterTextLeftOrRight ('Fill from debugger', True);
End;

Procedure ResetAll;
Var
  Ct : Byte;

Begin
  For Ct := 1 To 2 Do
    With ExeInfo[Ct] Do
    Begin
      CS   := 0;
      IP   := 0;
      SS   := 0;
      SP   := 0;
      PSP  := 0;
      If Debug Then PSP := PrefixSeg;
      Size := 0;
      Name := '#NoName#.' + Chr (Ct+48);
    End;
  If Kb4Seg <> 0 Then DeAllocMem (False);
End;

Procedure DrawBackGround;
Const
  BackGnd : Array[0..17] Of Char = ('C',#09,'a',#09,'r',#09,'d',#09,'w',#15,'a',#15,'r',#15,'e',#15,' ',#09);

Var
  Ct      : Word;
  CharPos : Byte;

Begin
  CharPos := 0;
  For Ct := 0 To 3999 Do Begin
    Mem [$0b800:Ct] := Byte(BackGnd[CharPos]);
    If CharPos = SizeOf (BackGnd)-1 Then CharPos := 0
    Else Inc (CharPos);
  End;
End;

Procedure MakeShadow (X,Y,X1,Y1 : Byte);
Var
  Ct : Word;
Begin
  For Ct := Y To Y+Y1 Do Begin
    Mem[$0b800:Ct*160+(2*(X+X1))+1] := DarkGray;
    Mem[$0b800:Ct*160+(2*(X+X1))+3] := DarkGray;
  End;
  For Ct := X To X+X1 Do Begin
    Mem[$0b800:((Y+Y1)*160)+(Ct*2)+1] := DarkGray;
  End;
  TextColor (White);
End;

Procedure DrawMenu;
Var
  Ct : word;

Begin
  Ct := 0; Clrscr;
  DrawBackGround;
  MakeWindow (10,2,60,21, Blue, LightBlue, LightGreen, DumpTitleText + TitleText2 + TitleText3);
  MakeShadow (10,2,60,21);
  CenterText (GetInfoText, True);

  MyWindow (11, 4, 69, 23);
  GotoXY (1, 20);
  TextColor (LightCyan);
  CenterText (' Hotkey : (U)ser screen', False);
  TextColor (White);
  GotoXY (29, WhereY);
  Write ('U');
  MyWindow (11, 4, 69, 22);

  TextColor (LightBlue);
  For Ct := 1 To 59 Do
    Write ('Ä');
  GotoXY (30, WhereY-1);
  Write ('Â');

  For Ct := 2 To 17 Do
  Begin
    GotoXY (30, Ct);
    WriteLn ('³');
  End;
  For Ct := 1 To 59 Do
    Write ('Ä');
  GotoXY (30, WhereY-1);
  WriteLn ('Á');

  GotoXY (1, WhereY-6);
  For Ct := 1 To 59 Do
    Write ('Ä');
  GotoXY (30, WhereY-1);
  WriteLn ('Å');

  GotoXY (1, WhereY-5);
  For Ct := 1 To 59 Do
    Write ('Ä');
  GotoXY (30, WhereY-1);
  WriteLn ('Å');
  TextColor (MenuColor);
  GotoXY (10, 1);
  WriteLn (' First file ');
  GotoXY (40, 1);
  WriteLn (' Second file ');
  GotoXY (30, WhereY-1);

  Make3Windows;
  UpDateExeInfo;
  UpdateMemAvail;
  TextColor(White);
  ClearSL;
  TextColor (Blue);
End;

Procedure SnapShotMem;
Const
  BuffSizeInP : Word = $1000;
  MemFileName = 'SNAPSHOT.MEM';

Var
  ProcessStr  : String[3];
  Ct          : Byte;
  Written     : Word;
  OutFile     : File;

Begin
  If FileExist (MemFileName) Then
    If Prompt (MemFileName + ' exist, overwrite [Y/N] ? ', #27 + 'YN') <> 1 Then
      Exit;
  Assign (OutFile, MemFileName);
  ReWrite (OutFile, 1);
  If IOResult <> 0 Then
  Begin
    WaitSL ('Can''t make file !');
    Exit;
  End;

  ProcessStr := '';
  For Ct := 0 To $0F Do Begin
    BlockWrite (OutFile, Ptr (Ct*$1000, 0)^, $0001, Written);
    BlockWrite (OutFile, Ptr (Ct*$1000, 1)^, $FFFF, Written);
    If Written <> $FFFF Then Begin
      WaitSL ('Can''t write file, disk full ?');
      Break;
    End;
    Str ((Ct + 1) * 100 DIV $10, ProcessStr);
    WriteSL ('Written : ' + ProcessStr +'%');
  End;
  ClearSL;
  Close (OutFile);
  FlushDiskCache;
End;

Procedure DumpMem (FileNr : Byte);
Const
  BuffSize    = $1000;
  BuffSizeInP = $100;

Var
  ProcessStr  : String[3];
  Ct          ,
  BuffCt      : LongInt;
  Written     : Integer;
  Error       : Boolean;
  OutFile     : File;

Begin
  If NOT IsPSPOk(FileNr) Then
    If Prompt ('The PSP-segment is not valid, dump anyway [Y/N] ? ', #27 + 'YN') <> 1 Then
      Exit;
  If ExeInfo[FileNr].Size = 0 Then
  Begin
    WaitSL ('No size given !');
    Exit;
  End;
  If FileExist (ExeInfo[FileNr].Name) Then
    If Prompt ('Output file exist, overwrite [Y/N] ? ', #27 + 'YN') <> 1 Then
      Exit;
  Assign (OutFile, ExeInfo[FileNr].Name);
  ReWrite (OutFile, 1);
  If IOResult <> 0 Then
  Begin
    WaitSL ('Can''t make file !');
    Exit;
  End;
  Ct     := 0;
  Error  := False;
  BuffCt := ExeInfo[FileNr].PSP + $10;

  BlockWrite (OutFile, DumpID, SizeOf(DumpID), Written);
  BlockWrite (OutFile, ExeInfo[FileNr], SizeOf (ExeInfoRecType), Written);
  ProcessStr := '';
  While (Ct <> ExeInfo[FileNr].Size) AND (Error = False) Do
  Begin
    If ExeInfo[FileNr].Size - Ct >= BuffSize Then
    Begin
      BlockWrite (OutFile, Ptr (BuffCt, 0)^, BuffSize, Written);
      Ct := Ct + BuffSize;
      BuffCt := BuffCt + BuffSizeInP;
      If Written <> BuffSize Then Error := True;
    End Else Begin
      BlockWrite (OutFile, Ptr (BuffCt, 0)^, ExeInfo[FileNr].Size - Ct, Written);
      Ct := Ct + Written;
      If ExeInfo[FileNr].Size <> Ct Then Error := True;
    End;
    Str (Round (Ct / ExeInfo[FileNr].Size * 100), ProcessStr);
    WriteSL ('Written : ' + ProcessStr +'%');
  End;
  ClearSL;
  If Error Then WaitSL ('Can''t write file, disk full ?');
  Close (OutFile);
  FlushDiskCache;
End;

Procedure AutodetectName (FileNr : Byte);
Var
  Ct     : Byte;
  PSP    : Word;
  Name   : String[8];

Begin
  If NOT PSPOk (FileNr) Then
    Exit;
  PSP := ExeInfo[FileNr].PSP;
  Dec (PSP);
  If MemW[PSP:1] <> PSP + 1 Then
  Begin
    WaitSL ('Can''t find name !');
    Exit;
  End;
  Ct := 0;
  Name := '';
  While Mem[PSP:8+Ct] <> 0 Do
  Begin
    Name := Name + Char(Mem[PSP:8+Ct]);
    Inc (Ct);
  End;
  If Name <> '' Then Begin
    ExeInfo[FileNr].Name := Name + '.' + Char (FileNr + 48) + '             ';
    If Config.FastMode AND (FileNr = 1) Then
    ExeInfo[2].Name := Name + '.2             ';
  End Else
    WaitSL ('Can''t find name !');
  UpdateExeInfo;
End;

Procedure AutodetectSize (FileNr : Byte);
Var
  Ct     : Byte;
  PSP    : Word;

Begin
  If NOT PSPOk (FileNr) Then
    Exit;
  Ct := Prompt ('Autodetect size by PSP or Stack, [P/S] ? ', #27 + 'PS');
  Case Ct Of
    0 : Exit;
    1 : ExeInfo[FileNr].Size := LongInt (MemW [ExeInfo[FileNr].PSP:2] - (ExeInfo[FileNr].PSP + $10)) * $10;
    2 : Begin
          If ExeInfo[FileNr].SS < ExeInfo[FileNr].PSP + $10 Then
            WaitSL ('The stack segment is invalid (less than PSP + 10h).')
          Else
            ExeInfo[FileNr].Size := LongInt (ExeInfo[FileNr].SS - (ExeInfo[FileNr].PSP + $10)) * $10;
        End;
  End;
  If Config.FastMode AND (FileNr = 1) Then ExeInfo[2].Size := ExeInfo[1].Size;
  UpDateExeInfo;
End;

Procedure Alloc_DeAllocMem;
Var
  OldSeg : Word;

Begin
  OldSeg := Kb4Seg;

  If Kb4Seg = 0 Then
  Begin
    AllocMem;
    If Kb4Seg <> 0 Then
    Begin
      TextBackground (4);
      TextColor (MenuColor);
      GotoXY (1, 15);
      CenterTextLeftOrRight (DeAllocText, True);
      WaitSL ('Memory allocated at segment ' + D2H (Kb4Seg, 4) + 'h');
    End;
  End
  Else
  Begin
    DeAllocMem (True);
    TextBackground (4);
    TextColor (MenuColor);
    GotoXY (1, 15);
    CenterTextLeftOrRight (AllocText, True);
    If Kb4Seg <> 0 Then Begin
      WaitSL ('Can''t deallocate memory !');
      Kb4Seg := 0;
    End Else
      WaitSL ('Memory at segment ' + D2H (OldSeg, 4) + 'h released');
  End;
End;

Procedure AutoEditFile2;
Var
  OldPSP   : Word;

Begin
  If Kb4Seg = 0 Then
  Begin
    WaitSL ('No memory allocated !');
    Exit;
  End;
  OldPSP := ExeInfo[2].PSP;
  ExeInfo[2].PSP := Kb4Seg + Kb4Size + 1;
  If NOT PSPOk (2) Then
  Begin
    WaitSL ('Can''t auto-config file 2, sorry !');
    ExeInfo[2].PSP := OldPSP;
    Exit;
  End;

  ExeInfo[2].CS   := ExeInfo[1].CS  + Kb4Size + 1;
  ExeInfo[2].IP   := ExeInfo[1].IP;
  ExeInfo[2].SS   := ExeInfo[1].SS  + Kb4Size + 1;
  ExeInfo[2].SP   := ExeInfo[1].SP;
  ExeInfo[2].PSP  := ExeInfo[1].PSP + Kb4Size + 1;
  ExeInfo[2].Size := ExeInfo[1].Size;
  ExeInfo[2].Name := Copy (ExeInfo[1].Name, 1, Pos ('.',ExeInfo[1].Name)-1) + '.2';
  UpdateExeInfo;
End;

Procedure SwapScrIn;
Begin
  SwapScr (True);
  RestoreColor;
  If DoRestoreOnSwap Then Begin
    RestoreCursor;
    ShowMouse;
  End;
End;

Procedure SwapScrOut;
Begin
  If DoRestoreOnSwap Then Begin
    HideMouse;
    HideCursor;
  End;
  SetColor;
  SwapScr (False);
End;

Procedure SwapScreen;
Begin
  SwapScrIn;
  ReadKey;
  While Keypressed Do ReadKey;
  SwapScrOut;
End;

Procedure AutoFillFromDebugger;
Var
  Part       ,
  Choice     ,
  DebuggerCt : Byte;
  TempBool   : Boolean;
  TempStr    : String[80];
  TempStrAsk : String[10];

Begin
  If Debug Then Begin
    DebuggerInfo := 0;
    DebuggerInfo := DebuggerInfo OR _TurboDebugger;
    DebuggerInfo := DebuggerInfo OR _SoftIce;
    DebuggerInfo := DebuggerInfo OR _GameTools;
  End;

  If DebuggerInfo AND _NoDebugger = _NoDebugger Then Begin
    WaitSL ('No debugger found, sorry!');
    Exit;
  End;

  Part := Prompt ('Fill registers into first or second file [1/2] ? ',#27 + '12');
  If Part = 0 Then Exit;

  TempStr := 'Get regs from ';
  TempStrAsk := '';

  If DebuggerInfo AND _TurboDebugger = _TurboDebugger Then Begin
    TempStr := TempStr + '(T)urbo Debugger, ';
    TempStrAsk := TempStrAsk + 'T';
  End;
  If DebuggerInfo AND _SoftIce       = _SoftIce       Then Begin
    TempStr := TempStr + '(S)oft-Ice, ';
    TempStrAsk := TempStrAsk + 'S';
  End;
  If DebuggerInfo AND _GameTools     = _GameTools     Then Begin
    TempStr := TempStr + '(G)ameTools, ';
    TempStrAsk := TempStrAsk + 'G';
  End;
  TempStr := Copy (TempStr, 1, Length(TempStr) - 2) + ' ?';
  If Length(TempStrAsk) > 1 Then Begin
    Choice := Prompt (TempStr, #27 + TempStrAsk);
    If Choice = 0 Then Exit;
  End Else
    Choice := 1;
  TempBool := True; {Just for debug purpose, don't remove!}
  SwapScrIn;
  Case TempStrAsk[Choice] Of
    'T' : TempBool := AutoFillFromTurboDebugger (Part);
    'S' : TempBool := AutoFillFromSoftIce (Part);
    'G' : TempBool := AutoFillFromGameTools (Part);
  End;
  SwapScrOut;
  UpdateExeInfo;
  If NOT TempBool Then WaitSL ('Reading registers from debugger not succesfull.');
End;

Procedure SetSoftICEValues;
Begin
  SoftIceSIVal := Config.SoftIceSIVal;
  SoftIceDIVal := Config.SoftIceDIVal;
End;

Function SaveOptions : Boolean;
Begin
  SaveOptions := False;
  Assign(CfgFile, CfgName);
  ReWrite(CfgFile);
  If IOResult <> 0 Then Exit;
  Write(CfgFile, Config);
  If IOResult <> 0 Then Exit;
  Close(CfgFile);
  SaveOptions := True;
  SetSoftICEValues;

  Assign(DumpExeFile, Copy(CfgName,1,Length(CfgName)-3) + 'EXE');
  Reset(DumpExeFile);
  If IOResult <> 0 Then Exit;
  Read (DumpExeFile, DumpExeHeader);
  If IOResult <> 0 Then Exit;
  With DumpExeHeader Do Begin
    MinMemInP := MinMemInP - (SP DIV $10) + (Config.StackSize DIV $10);
    MaxMemInP := MinMemInP;
    SP := Config.StackSize;
  End;
  Reset(DumpExeFile);
  If IOResult <> 0 Then Exit;
  Write(DumpExeFile, DumpExeHeader);
  If IOResult <> 0 Then Exit;
  Close(DumpExeFile);

  FlushDiskCache;
End;

Function RestoreOptions : Boolean;
Begin
  RestoreOptions := False;
  Assign(CfgFile, CfgName);
  Reset(CfgFile);
  If IOResult <> 0 Then Exit;
  Read(CfgFile, Config);
  If IOResult <> 0 Then Exit;
  Close(CfgFile);
  If Config.ConfigID <> ConfigIDType Then Exit;
  If Config.Version <> VersionHex Then Exit;
  SetSoftICEValues;
  RestoreOptions := True;
End;

Function GetHexAndCheckForFile2 (MenuPoint : Word) : Str4;
Var
  X   ,
  Num : Byte;
  Diff : Word;

Begin
  Num := MenuWin-2;
  X   := 9+((MenuWin-3)*30);
  If Config.FastMode AND (MenuWin = 4) Then MenuPoint := 5;
  Case MenuPoint Of
    1 : ExeInfo[Num].CS := H2D (PromptHex (X, 2, MenuWin, D2H (ExeInfo[Num].CS,4)));
    2 : ExeInfo[Num].IP := H2D (PromptHex (X, 3, MenuWin, D2H (ExeInfo[Num].IP,4)));
    3 : ExeInfo[Num].SS := H2D (PromptHex (X, 4, MenuWin, D2H (ExeInfo[Num].SS,4)));
    4 : ExeInfo[Num].SP := H2D (PromptHex (X, 5, MenuWin, D2H (ExeInfo[Num].SP,4)));
    5 : Begin
          ExeInfo[Num].PSP := H2D (PromptHex (X, 6, MenuWin,D2H(ExeInfo[Num].PSP,4)));
          PSPOk(Num);
          If Config.FastMode AND (MenuWin = 4) Then Begin
            If ExeInfo[1].PSP > ExeInfo[2].PSP Then Diff := ExeInfo[1].PSP - ExeInfo[2].PSP
            Else Diff := ExeInfo[2].PSP - ExeInfo[1].PSP;

            ExeInfo[2].CS := ExeInfo[1].CS + Diff;
            ExeInfo[2].IP := ExeInfo[1].IP;
            ExeInfo[2].SS := ExeInfo[1].SS + Diff;
            ExeInfo[2].SP := ExeInfo[1].SP;
{            UpdateExeInfo;}
          End;
        End;
    6 : Begin
          ExeInfo[Num].Size := H2D(PromptHex(X,7,MenuWin,D2H(ExeInfo[Num].Size,5)));
          If Config.FastMode AND (Num = 1) Then
            ExeInfo[2].Size := ExeInfo[1].Size;
{          UpdateExeInfo;    }
        End;
    End;
  UpdateExeInfo;
End;

Procedure ResetConfigMenu;
Begin
  With Config Do Begin
    ConfigID      := ConfigIDType;
    Version       := VersionHex;
    Rasterbar     := 2;
    FastMode      := True;
    StackSize     := $1000;
    SoftICESIVal  := $4647;
    SoftICEDIVal  := $4A4D;
    Int09         := $09;
{    IntFB         := $FB;}
{    Int32         := $4C;}
    Int32         := $32;
    PSPValLevel   := 2;
  End;
End;

Procedure UpdateConfigMenu;
  Procedure MakeLine;
  Var
    Ct : Byte;
  Begin
    TextColor (LightBlue);
    For Ct := 1 To 35 Do
      Write ('Ä');
    TextColor(White);
    WriteLn;
  End;

Begin
  With Config Do Begin
    GotoXY(1,1);
    TextColor(White); Write(' Rasterbar                : '); TextColor(LightCyan); WriteLn(OnOffAuto[Rasterbar]);
    TextColor(White); Write(' Fast mode                : '); TextColor(LightCyan); WriteLn(OnOffAuto[Byte(FastMode)]);
    TextColor(White); Write(' PSP validation level     : '); TextColor(LightCyan); WriteLn(PSPLevel[PSPValLevel]);
    TextColor(White); Write(' SoftICE SI value         : '); TextColor(LightCyan); WriteLn(d2h(SoftICESIVal,4),'h');
    TextColor(White); Write(' SoftICE DI value         : '); TextColor(LightCyan); WriteLn(d2h(SoftICEDIVal,4),'h');
    MakeLine;
    TextColor(White); Write(' Activate via interrupt   : '); TextColor(LightCyan); WriteLn(d2h(Int32,2),'h');
    TextColor(White); Write(' DumpExe stack size       : '); TextColor(LightCyan); WriteLn(d2h(StackSize,4),'h');
    MakeLine;
    TextColor(White); WriteLn('      Reset to default values');
{    TextColor(White); WriteLn('        Save configuration');}
    MakeLine;
  End;
End;

Procedure HandleConfigMenu;
  Procedure WaitSL (InStr : Str80);
  Var
    Ct : Byte;

  Begin
    MyWindow (13, 4, 69, 23);
    TextColor (White);
    TextBackground (3);
    GotoXY (1, 15);
    CenterText (InStr, False);
    ReadKey;
    While Keypressed Do ReadKey;
    GotoXY (13, 15);
    For Ct := 1 To 33 Do Write (' ');
    MyWindow (24, 7, 59, 18);
  End;

Const
  MDat : Array [1..3,1..5] Of Word = ( (108-16,5,3,0,6 ),
                                       (205-16,2,3,0,12),
                                       (253-16,1,3,0,15) );
Var
  MenuPoint : Word;
  Quit      : Boolean;
  TempWord  : Word;
  TempByte  : Byte;

Begin
  DrawBackGround;
  MakeWindow (23,6,36,13, Blue, LightBlue, LightGreen, 'DumpExe Configuration');
  MakeShadow (23,6,36,13);
  MyWindow (24, 7, 58, 18);
  TextBackground (3);
  Clrscr;
  MyWindow (24, 7, 59, 18);
  Quit := False;
  Repeat
    UpdateConfigMenu;
    MenuPoint := ActivateMenu(MDat [CMenuWin,1], MDat [CMenuWin,2],
                              MDat [CMenuWin,3], MDat [CMenuWin,4],
                              MDat [CMenuWin,5], Rasterbar);
    MDat [CMenuWin, 4] := (MenuPoint SHR 8) - 1;      {Save old position}
    Case (MenuPoint AND $00FF) Of
      KeyEsc  : Quit := True;
      KeyUp   : If CMenuWin <> 1 Then Dec(CMenuWin);
      KeyDown : If CMenuWin <> 3 Then Inc(CMenuWin);
    End;

    If (MenuPoint AND $00FF) = KeyReturn Then Begin   {Enter}
      Case CMenuWin Of
        1 : Case ((MenuPoint AND $FF00) SHR 8) Of
              1 : Begin
                    Inc(Config.Rasterbar);
                    If Config.Rasterbar = 3 Then Config.Rasterbar := 0;
                  End;
              2 : Config.FastMode  := NOT Config.FastMode;
              3 : Begin
                    Inc (Config.PSPValLevel);
                    If Config.PSPValLevel = 4 Then Config.PSPValLevel := 0;
                  End;
              4 : Config.SoftICESIVal := H2D (PromptHex (29, 4, 3, D2H (Config.SoftICESIVal,4)));
              5 : Config.SoftICEDIVal := H2D (PromptHex (29, 5, 3, D2H (Config.SoftICEDIVal,4)));
            End;
        2 : Case ((MenuPoint AND $FF00) SHR 8) Of
              1 : Begin
                    TempByte := H2D (PromptHex (29, 7, 3, D2H (Config.Int32,2)));
                    If (TempByte = $09) OR (TempByte = $16) OR (TempByte = $21) OR
                       (TempByte = $FB)
                    Then
                      WaitSL('Can''t use Int ' + d2h(TempByte, 2)+ 'h')
                    Else Config.Int32 := TempByte;
                  End;
              2 : Begin
                    TempWord := H2D (PromptHex (29, 8, 3, D2H (Config.StackSize,4))) AND $FFF0;
                    If TempWord < $1000 Then WaitSL ('DumpExe NEED at least 1000h stack')
                    Else Config.StackSize := TempWord;
                  End;
            End;
        3 : Case ((MenuPoint AND $FF00) SHR 8) Of
              1 : ResetConfigMenu;
            End;
       End;
       If CMenuWin = 2 Then WaitSL('To apply changes, reload DUMPEXE.');
     End;
  Until Quit;
  If NOT SaveOptions Then WaitSL('Can''t write configuration.');
  SetSoftICEValues;
  DrawMenu;
End;

Procedure Menu;
Const
  MDat : Array [MinMenu..MaxMenu+1,1..5] Of Word = ( (253,4,3,0,16), (253,4,4,0,16),
                                                     ( 60,6,3,0, 4), ( 60,6,4,0, 4),
                                                     (189,3,3,0,12), (189,3,4,0,12),
                                                     (124,1,4,0, 8) );
(*+-----+-----+
  |  3  |  4  |
  +-----+-----+
  |  5  |  6  |
  +-----+-----+
  |  1  |  2  |
  +-----------+*)
Var
  Ch          : Char;
  Quit        : Boolean;
  Uninstall   : Boolean;
  MenuPoint   : Word;
  TempMenuWin : Byte;

Begin
  Quit           := False;
  Uninstall      := False;

  SaveCursor;
  HideCursor;
  HideMouse;
  MyPushScr;
  SetColor;     {HOW ABOUT SAVING ALL COLORS... NAA NEXT VERSION (9.99) !!!!}

  Clrscr;
  FlushDiskCache;
  DrawMenu;
  Repeat
    While Keypressed Do ReadKey;
    If Config.FastMode AND (MenuWin = 4) Then MenuWin := MaxMenu + 1;

    If DoAllocMem Then Begin
      Quit      := True;
      MenuWin   := 2;
      MenuPoint := $0200+KeyReturn;
    End Else
      MenuPoint := ActivateMenu(MDat [MenuWin,1], MDat [MenuWin,2],
                                MDat [MenuWin,3], MDat [MenuWin,4],
                                MDat [MenuWin,5], Rasterbar);

    If Config.FastMode AND (MenuWin = MaxMenu+1) Then MenuWin := 4;

    TextColor (White);
    MDat [MenuWin, 4] := (MenuPoint SHR 8) - 1;      {Save old position}

    Case (MenuPoint AND $00FF) Of
      KeyEsc   : Quit := True;
      KeyUp    : Begin
                   TempMenuWin := MenuWin;
                   Case menuWin OF
                     1 : TempMenuWin := 5;
                     2 : TempMenuWin := 6;
                     5 : TempMenuWin := 3;
                     6 : TempMenuWin := 4;
                   End;
                   If MenuWin <> TempMenuWin Then Begin
                     MenuWin := TempMenuWin;
                     MDat [MenuWin, 4] := MDat [MenuWin, 2] - 1;
                   End;
                 End;
      KeyDown  : Begin
                   TempMenuWin := MenuWin;
                   Case menuWin OF
                     3 : TempMenuWin := 5;
                     4 : TempMenuWin := 6;
                     5 : TempMenuWin := 1;
                     6 : TempMenuWin := 2;
                   End;
                   If MenuWin <> TempMenuWin Then Begin
                     MenuWin := TempMenuWin;
                     MDat [MenuWin, 4] := 0;
                   End;
                 End;
      KeyLeft  : If MenuWin MOD 2 = 0 Then Begin
                   Dec (MenuWin);
                   If Config.FastMode AND (MenuWin = 3) Then
                    Else
                     MDat[MenuWin, 4] := MDat[MenuWin+1, 4];
                 End;
      KeyRight : If MenuWin MOD 2 = 1 Then Begin
                   Inc (MenuWin);
                   MDat[MenuWin, 4] := MDat[MenuWin-1, 4];
                 End;
      KeyShTab : If MenuWin = MinMenu Then
                   MenuWin := MaxMenu
                 Else
                   Dec (MenuWin);
      KeyTab   : If MenuWin = MaxMenu Then
                   MenuWin := MinMenu
                 Else
                   Inc (MenuWin);
      KeyU1    ,
      KeyU2    : SwapScreen;
    End;

    If (MenuPoint AND $00FF) = KeyReturn Then    {Enter}
      Case MenuWin Of
        1 : Case (MenuPoint SHR 8) Of
              1  : HandleConfigMenu;
              2  : SnapShotMem;
              3  : Begin
                     ResetAll;
                     DrawMenu;
                   End;
              4  : If NOT TestVectores Then
                     WaitSL ('Can''t uninstall, vectores hooked by another program !')
                   Else
                     If Prompt ('Do you wish to uninstall this program [Y/N] ? ',#27 + 'YN') = 1 Then
                       Uninstall := True;
              27 : Quit := True;
            End;
        2 : Case (MenuPoint SHR 8) Of
              1  : SwapScreen;
              2  : Alloc_DeAllocMem;
              3  : AutoEditFile2;
              4  : AutoFillFromDebugger;
            End;
        3,
        4 : GetHexAndCheckForFile2 (MenuPoint SHR 8);

        5,
        6 : Case (MenuPoint SHR 8) Of
              1 : DumpMem (MenuWin - 4);
              2 : AutodetectName (MenuWin - 4);
              3 : AutodetectSize (MenuWin - 4);
            End;
      End;
  Until Quit OR Uninstall;

  While Keypressed Do ReadKey;

  RestoreWindow;
  MyPopScr;
  RestoreColor;
  RestoreCursor;
  ShowMouse;
  If Uninstall Then DeleteTSR;
End;

Procedure Int32Hand; ASSEMBLER;
asm
  push    ds
  mov     ds, word ptr @DataSeg
  cmp     byte ptr NowInExeMenu, False
  je      @NotInExeMenu

  pop     ds
  iret

@NotInExeMenu:
  mov     byte ptr NowInExeMenu, True
  push    ax
  push    bp
  mov     bp, sp

  mov     ax, [bp+8]
  mov     word ptr SICE_CS, ax

  mov     ax, [bp+6]
  mov     word ptr SICE_IP, ax

  mov     ax, ss
  mov     word ptr SICE_SS, ax

  mov     ax, sp
  add     ax, 0ch
  mov     word ptr SICE_SP, ax

  mov     ax, es
  mov     word ptr SICE_PSP, ax

  pop     bp
  pop     ax

  mov     OldStackSeg, ss
  mov     OldStackPtr, sp
  mov     ss, StackSeg             {No need to make cli}
  mov     sp, StackPtr


  pusha
  push    es

  cld
  mov     cx, word ptr DosStackSize         {cx = size }
  mov     es, word ptr NewDosStackSeg
  xor     di, di
  lds     si, dword ptr DosStackPtr
  cmp     byte ptr [si], 1                  {Critical condition}
  jae     @GetOutOfInt
  rep     movsb

  mov     ds, word ptr @DataSeg
  sti
  call    menu
  cli

  cld
  mov     cx, word ptr DosStackSize         {cx = size }
  les     di, dword ptr DosStackPtr
  mov     ds, word ptr NewDosStackSeg
  xor     si, si
  rep     movsb

@GetOutOfInt:
  pop     es
  popa

  mov     ds, word ptr @DataSeg
  mov     ss, OldStackSeg
  mov     sp, OldStackPtr
  mov     byte ptr NowInExeMenu, False
  pop     ds
  iret

@DataSeg: dw SEG TempX
End;

Procedure IntFBHand; ASSEMBLER;
asm
  jmp    @ModifyeCode
  db     'DUMP'

@ModifyeCode:
  jmp     @InitVars        {Will be overwritten by "nop" after first call}
  nop

  push    ds
  mov     ds, word ptr @DataSeg
  pusha
  mov     DoAllocMem, TRUE

  {I'm setting the PSP segment in the beleve that TD wouldn't free the block.
   I might be TOTALLY wrong, but hey it's 2.45 am                            }

  mov     ah, 51h
  int     21h
  push    bx

  mov     ah, 50h
  mov     bx, PrefixSeg
  int     21h

@IntCode:
  int     00h           {Will be changed after first call}

@ToHere:
  mov     ah, 50h
  pop     bx
  int     21h

  mov     DoAllocMem, FALSE
  popa
  pop     ds
  iret

@InitVars:
  mov     word ptr @ModifyeCode, 9090h    { OH OH OH HOW LAME I AM :)    }
  mov     byte ptr @ModifyeCode+2, 90h    { AND THIS REALLY IS CRAP CODE }

  mov     al, Config.Int32
  mov     byte ptr @IntCode+1, al
  ret


@DataSeg: dw SEG TempX
end;

Procedure Int09Hand; ASSEMBLER;
asm
@ModifyeCode:
  jmp     @InitVars        {Will be overwritten by "nop" after first call}
  nop

  push    ds
  mov     ds, word ptr @DataSeg

  cmp     byte ptr NowInExeMenu, False
  je      @NotInExeMenu

  pop     ds
  jmp     dword ptr @LocalOrgInt09

@NotInExeMenu:
  mov     byte ptr NowInExeMenu, True
  mov     OldStackSeg, ss
  mov     OldStackPtr, sp
  mov     ss, StackSeg             {No need to make cli}
  mov     sp, StackPtr

  pusha
  push    es

  pushf
  call    dword ptr @LocalOrgInt09

  xor     ax, ax
  mov     es, ax
  mov     al, es:byte ptr [0471h]  {control-break address}
  cmp     al, 0ffh
  je      @GetOutOfInt

  mov     al, es:byte ptr [0417h]  {shift status  address}
  and     al, 3                    {Shift + shift mask}
  cmp     al, 3
  jne     @GetOutOfInt

  cld
  mov     cx, word ptr DosStackSize         {cx = size }
  mov     es, word ptr NewDosStackSeg
  xor     di, di
  lds     si, dword ptr DosStackPtr
  cmp     byte ptr [si], 1                  {Critical condition}
  jae     @GetOutOfInt
  rep     movsb

  mov     ds, word ptr @DataSeg
  sti
  call    menu
  cli

  cld
  mov     cx, word ptr DosStackSize         {cx = size }
  les     di, dword ptr DosStackPtr
  mov     ds, word ptr NewDosStackSeg
  xor     si, si
  rep     movsb

@GetOutOfInt:
  pop     es
  popa

  mov     ds, word ptr @DataSeg
  mov     ss, OldStackSeg
  mov     sp, OldStackPtr
  mov     byte ptr NowInExeMenu, False
  pop     ds
  iret

@InitVars:
  mov     al, Config.Int09
  mov     ah, 35h
  int     21h
  mov     word ptr @LocalOrgInt09, bx
  mov     word ptr @LocalOrgInt09+2, es

  mov     word ptr @ModifyeCode, 9090h  { OH OH OH HOW LAME I AM :)    }
  mov     byte ptr @ModifyeCode+2, 90h    { AND THIS REALLY IS CRAP CODE }

  ret

@LocalOrgInt09: dd 0
@DataSeg:       dw SEG TempX
End;

Function TestVectores : Boolean;
Var
  TestVec09 ,
  TestVecFB ,
  TestVec4C : Pointer;

Begin
  TestVec09 := Addr(Int09Hand);
  TestVecFB := Addr(IntFBHand);
  TestVec4C := Addr(Int32Hand);
  If UseInt09 Then GetIntVec (Config.Int09, TestVec09);
  If UseIntFB Then GetIntVec (IntFB       , TestVecFB);
  If UseInt32 Then GetIntVec (OrgCfgInt32 , TestVec4C);
  TestVectores := (TestVec09 = Addr(Int09Hand)) AND {damn this is smart !}
                  (TestVecFB = Addr(IntFBHand)) AND
                  (TestVec4C = Addr(Int32Hand));
End;

Procedure TryToGoResident;
Var
  Ct : Word;
  Ch : Char;

Begin
  ResetAll;
  WriteLn ('þ Program now resident OK');
  WriteLn ('þ ', Hotkey);

  If NOT Debug Then LastInitText;
  If Debug AND DoRestoreOnSwap Then ShowMouse;

  asm
    mov  StackSeg, ss
    mov  StackPtr, sp
  end;

  If Debug Then Begin
    StackPtr := StackPtr - $200;        {stack used by in this 'if'}
    TextColor (LightGreen);
    WriteLn ('You are running under Borland Pascal IDE, and therefor running in debug mode.');
    WriteLn ('Press hotkey to start DUMPEXE or ESC to exit program.');
    TextColor (White);
    Repeat
      Ch := ReadKey;
      Write (Ch);
{      If Ch = #9 Then asm int 0fbh end;
      If Ch = #13 Then asm int 04Ch end;}
    Until Ch = #27;
    DeleteTSR;
  End Else
    Keep (0);
End;

Procedure WriteFailed;
Begin
  TextColor (LightRed);
  WriteLn ('FAILED');
  TextColor (White);
End;

Procedure WriteFailedWithError(Err : Byte; ErrText : Str80 );
Begin
  WriteFailed;
  WriteLn (ErrText);
  Halt(Err);
End;

Procedure CaptureInt(UseInt : Boolean; GetInt : Byte; Var OrgPtr : Pointer; NewPtr : Pointer);
Begin
  If UseInt Then Begin
    GetIntVec (GetInt, OrgPtr);
    SetIntVec (GetInt, NewPtr);
    Write (d2h(GetInt,2),'h ');
  End;
End;

Procedure Init;
Var
  Regs : Registers;

Begin
  Clrscr;
  MenuWin        := 3;
  CMenuWin       := 1;
  Blocks         := 0;
  Kb4Seg         := 0;
  HotkeyPressed  := False;
  NowInExeMenu   := False;
  CfgName        := Copy(ParamStr(0),1,Length(ParamStr(0))-3) + 'CFG';

  ResetConfigMenu;
  WriteTitleText(1);
  TextColor (White);
  Write ('þ DumpExe API not resident ');
  If DumpExeAPIResident Then
    WriteFailedWithError(97,'Please uninstall DumpExe API before running DumpExe.');
  WriteLn ('OK');

  Write ('þ DumpExe not resident ');
  If DumpExeResident Then
    WriteFailedWithError(99,'Program already resident. '+ HotKey);
  WriteLn ('OK');

  Write ('þ DESQView not resident ');
  If DVInstalled Then
    WriteFailedWithError(98,'Can''t run under DESQView, sorry.');
  WriteLn ('OK');

  Regs.ax := $fb42;
  Regs.bx := $1001;
  Intr ($2f, Regs);
  If (Regs.bx = 0) OR (ParamStr(1) = '/d') Then Debug := True;

  If Debug Then Begin
    TextColor (LightRed);
    WriteLn ('þ DEBUG SWITCH ON ! ');
    TextColor (White);
  End;

  TextColor (White);
  Write ('þ Testing processor type ');
  If Test8086 = 0 Then
    WriteFailedWithError(2,'Sorry, but you need a 80286 or better cpu to run this program.');
  WriteLn ('OK');

  Write ('þ Dos version 5.0+ ');

  If Byte(DosVersion) < 5 Then
    WriteFailedWithError(3,'Sorry, but you need dos 5.0 or above to run this program.');

  WriteLn ('OK');

  Write ('þ Restoring options ');
  If NOT RestoreOptions Then Begin
    WriteFailed;
    ResetConfigMenu;
    Write ('þ Saving default options ');
    If NOT SaveOptions Then
      WriteFailed
    Else
      WriteLn ('OK');
  End Else
    WriteLn ('OK');
  OrgCfgInt32 := Config.Int32;

  Write ('þ Init handlers ');
  If UseInt09 Then Int09Hand;            {Init the int 09h handler}
  If UseIntFB Then IntFBHand;            {Init the int FBh handler}
  WriteLn ('OK');

  Write ('þ Allocate screen buffer ');
  ScrBuffSeg := AllocateMemInUMB ((ScrBuffSize + $0f) DIV $10);
  If ScrBuffSeg = 0 Then
    WriteFailedWithError(4, 'Can''t allocate '+d2h(ScrBuffSize, 4)+'h bytes of memory.');

  If ScrBuffSeg >= $A000 Then WriteLn ('OK (in UMB)')
  Else WriteLn ('OK (below 640kb)');

  Write ('þ Allocate Dos stack ');
  asm
    push    ds
    mov     ax, 5d06h                       { get dos-stack ptr }
    int     21h
    push    ds
    pop     es
    pop     ds
    mov     word ptr DosStackSize,  cx
    mov     word ptr DosStackPtr,   si
    mov     word ptr DosStackPtr+2, es

    add     cx, 000fh
    shr     cx, 4
    push    cx
    call    AllocateMemInUMB            {ax = 0 if error else seg of mem}
    mov     word ptr NewDosStackSeg, ax
  end;
  If NewDosStackSeg = 0 Then
    WriteFailedWithError(4, 'Can''t allocate '+d2h(DosStackSize, 4)+'h bytes of memory.');

  If NewDosStackSeg >= $A000 Then WriteLn ('OK (in UMB)')
  Else WriteLn ('OK (below 640kb)');

  Write ('þ Mouse present ');
  If MousePresent Then WriteLn ('YES') Else WriteLn ('NO');

  Reg.ah := $49;
  Reg.es := MemW [PrefixSeg:$2C];
  Intr ($21, Reg); {Free Env}

  SetIntVec ($1B, SaveInt1B);   {Restore ctr-break handler}

  Write ('þ Capturing interrupts ');
  CaptureInt(UseInt09, Config.Int09, @OrgInt09, @Int09Hand);
  CaptureInt(UseIntFB, IntFB       , @OrgIntFB, @IntFBHand);
  CaptureInt(UseInt32, Config.Int32, @OrgInt32, @Int32Hand);
  WriteLn;
End;

Begin
  Init;
  TryToGoResident;
End.
