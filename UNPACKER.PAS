{$A+,B-,D+,E+,F-,G+,I-,L+,N-,O-,P-,Q-,R-,S-,T-,V+,X+,Y+}
{$M 8192,0,0}  {BP 7.0 compiler options}
Program Unpacker;

{PKUnlite by BUGSY/OBSESSiON 18-09-1997, Just to show how DumpExe API works. }

Uses
  Crt,
  Dos,
  UnpUtil;

Const
  RetFFound    = 0;
  LoadError    = 1;
  FreeError    = 2;
  EndOfProgram = 3;
  VersionError = 4;
  SizeError    = 5;
  DumpError    = 6;

Type
  LoadAndExecType = Record
    Environment ,
    OfsParam    ,
    SegParam    : Word;
    FCB         : Array [1..4] Of Word;
    _SP         ,
    _SS         ,
    _IP         ,
    _CS         : Word;
  End;

  DumpExeRegsType = Record
    _cs         ,
    _ip         ,
    _ss         ,
    _sp         ,
    _psp        : Word;
  End;
  Str80         = String[80];

Var
  OldSS       ,
  OldSP       ,
  FileError   ,
  ChildePSP   : Word;
  ExecName    ,
  Parameter   : String;
  LoadAndExec : LoadAndExecType;
  DumpExeRegs : DumpExeRegsType;
  DumpNo      : Byte;
  Dump1Seg    : Word;
  Locked      : Boolean;

Procedure Error (Err : Byte);
Begin
  If Err <> 255 Then Write ('Error (',Err,') : ');
  TextColor(LightGreen);
  Case Err Of
    1   : WriteLn ('Invalid function number.');
    2   : WriteLn ('File not found.');
    3   : WriteLn ('Path not found.');
    4   : WriteLn ('Too many open files.');
    5   : WriteLn ('File access denied.');
    6   : WriteLn ('Invalid file handle.');
    8   : WriteLn ('Not enough memory');
    10  : WriteLn ('Invalid environment');
    11  : WriteLn ('Invalid format');
    12  : WriteLn ('Invalid file access code.');
    15  : WriteLn ('Invalid drive number.');
    16  : WriteLn ('Cannot remove current directory.');
    17  : WriteLn ('Cannot rename across drives.');
    18  : WriteLn ('No more files.');
    100 : WriteLn ('Disk read error.');
    101 : WriteLn ('Disk write error.');
    102 : WriteLn ('File not assigned.');
    103 : WriteLn ('File not open.');
    104 : WriteLn ('File not open for input.');
    105 : WriteLn ('File not open for output.');
    106 : WriteLn ('Invalid numeric format.');
    150 : WriteLn ('Disk is write-protected.');
    151 : WriteLn ('Bad drive request struct length.');
    152 : WriteLn ('Drive not ready.');
    154 : WriteLn ('CRC error in data.');
    156 : WriteLn ('Disk seek error.');
    157 : WriteLn ('Unknown media type.');
    158 : WriteLn ('Sector Not Found.');
    159 : WriteLn ('Printer out of paper.');
    160 : WriteLn ('Device write fault.');
    161 : WriteLn ('Device read fault.');
    162 : WriteLn ('Hardware failure.');
    200 : WriteLn ('Division by zero.');
    201 : WriteLn ('Range check error.');
    202 : WriteLn ('Stack overflow error.');
    203 : WriteLn ('Heap overflow error.');
    204 : WriteLn ('Invalid pointer operation.');
    205 : WriteLn ('Floating point overflow.');
    206 : WriteLn ('Floating point underflow.');
    207 : WriteLn ('Invalid floating point operation.');
    208 : WriteLn ('Overlay manager not installed.');
    209 : WriteLn ('Overlay file read error.');
    210 : WriteLn ('Object not initialized.');
    211 : WriteLn ('Call to abstract method.');
    212 : WriteLn ('Stream registration error.');
    213 : WriteLn ('Collection index out of range.');
    214 : WriteLn ('Collection overflow error.');
    215 : WriteLn ('Arithmetic overflow error.');
    216 : WriteLn ('General Protection fault.');
    246 : WriteLn ('Infile is not packed with PKLite.');
    247 : WriteLn ('Infile is NOT an EXE.');
    248 : WriteLn ('Can''t read from infile.');
    249 : WriteLn ('There was an error writeing the dump.');
    250 : WriteLn ('Can''t autodetect the size by ''stack''.');
    251 : WriteLn ('Invalid DumpExe API version. Version 2.4 expected !');
    252 : WriteLn ('Program could not be unpacked.');
    253 : WriteLn ('Can''t free memory.');
    255 : Begin
            WriteLn ('USAGE : UNPACKER.EXE infile.ext');
            TextColor(White);
            WriteLn;
            WriteLn ('Unpacker is ONLY ment as an example on how to use the DumpExe API.');
            WriteLn ('It can currently unpack PKLite 2.01 for dos. Please take a look at');
            WriteLn ('the source code for further information on how to use the DumpExe API.');
            WriteLn;
          End;
  Else
    WriteLn ('No error text defined, sorry ...');                 {hmmmmm....}
  End;
  LastInitText;
  Halt (Err);
End;

Function TraceFile : Byte;
label NewInt01Hand;
Var
  Ct       : Byte;
  OldInt01 : Procedure;

Begin
  GetIntVec ($01, @OldInt01);
  ExecName := ParamStr(1);
  ExecName[Length (ExecName)+1] := #0;
  Parameter[0] := #$00;
  Parameter[1] := #$0D;

  With LoadAndExec Do Begin
    Environment := $0000;
    OfsParam := ofs (Parameter);
    SegParam := seg (Parameter);
    For Ct := 1 To 4 Do FCB[Ct] := $FFFF;
  End;
  SwapVectors;
  FileError := 0;
  Locked := False;
  asm
    push     bp
    mov      byte ptr @retfcount, 0

    xor      ah, ah                                  {Get DumpExe API version}
   {int      0fbh}
    db       0cdh
    db       IntFB
    cmp      bx, 0240h
    je       @VersionOK
    mov      @result, VersionError
    jmp      @GetOut

@APIAddress:                                       {Emulate an interrupt call}
             pushf
             db 9ah  {call xxxx:xxxx}
@APIOfs:     dw 0
@APISeg:     dw 0
             ret

@VersionOK:
    mov      ah, 01h
   {int      0fbh}
    db       0cdh       {Get DumpExe API Address & secure DumpExe API session}
    db       IntFB
    mov      word ptr @APISeg, es
    mov      word ptr @APIOfs, di
    mov      Locked, True

    push     ds
    mov      ax, 2501h
    push     cs
    pop      ds
    mov      dx, offset @NewInt01Hand
    int      21h
    pop      ds

    mov      dx, offset ExecName + 1
    push     ds
    pop      es
    mov      bx, offset LoadAndExec
    mov      ax, 4B01h
    int      21h

    mov      FileError, ax
    mov      @result, LoadError
    jc       @GetOut

    mov      ah, 62h
    int      21h
    mov      ChildePSP, bx

    mov      OldSS, ss
    mov      OldSP, sp

    mov      al, 1
    pushf
    mov      bp, sp
    or       ss:[bp+1], al
    popf

    cli
    mov      ss, LoadAndExec._SS
    mov      sp, LoadAndExec._SP
    sti

    push     LoadAndExec._CS
    push     LoadAndExec._IP

    mov      es, ChildePSP
    mov      word ptr es:[000ch], cs
    mov      word ptr es:[000ah], offset @EndOfProg
    mov      ds, LoadAndExec._CS

    cld
    xor      ax, ax
    mov      bx, ax
    mov      cx, ax
    mov      dx, ax
    mov      si, ax
    mov      di, ax
    mov      bp, ax

    {set trap flag and retf}
    retf

@retfcount: db 0

@NewInt01Hand:
{    int 02                          {Used to trigger softice (use bpint 02)}
    pusha
    push     es

    mov      bp, sp

    cmp      byte ptr @retfcount, 3
    je       @RetFFound

    mov      al, 3
    or       ss:[bp+10h+2+5], al        {set trap and interruptflag on return}

    les      di, ss:[bp+10h+2]

    cmp      byte ptr es:[di], 0cbh                              {retf opcode}
    jne      @NextIns

    inc      byte ptr @retfcount

@NextIns:
    pop      es
    popa
    iret

@EndOfProg:
    mov      bl, EndOfProgram
    jmp      @StopTrace

@RetFFound:
    mov      bl, RetFFound
    jmp      @StopTrace

@StopTrace:
    mov      ax, SEG OldSS
    mov      ds, ax

    cmp      bl, RetFFound
    jne      @RetFNotFound

    les      di, ss:[bp+10h+2h]
    mov      DumpExeRegs._cs, es
    mov      DumpExeRegs._ip, di
    mov      DumpExeRegs._ss, ss
    mov      DumpExeRegs._sp, sp
    add      DumpExeRegs._sp, 10h+2h+6h

@RetFNotFound:
    cli
    mov      ss, OldSS
    mov      sp, OldSP
    sti

    pop      bp
    push     bp
    mov      @result, bl

    mov      ah, 50h                                         {Set PSP segment}
    mov      bx, PrefixSeg
    int      21h

    pop      bp
    push     bp
    cmp      @result, EndOfProgram
    je       @GetOut

    mov      es, ChildePSP
    mov      DumpExeRegs._psp, es

    push     es
    mov      es, es:[2ch]             {Free environment of the loaded program}
    mov      ah, 49h
    int      21h
    pop      es

    mov      ah, 03h                              {Fill DumpExe API registers}
    mov      al, DumpNo
    mov      si, Offset DumpExeRegs
    call     @APIAddress

    cmp      DumpNo, 1
    jne      @NoAutoSizeError

    mov      ah, 04h               {Autodetect size (by stack) for BOTH dumps}
    mov      al, DumpNo
    mov      bl, 02h
    call     @APIAddress

    cmp      al, 0
    je       @NoAutoSizeError

    mov      @Result, SizeError
    jmp      @GetOut

@NoAutoSizeError:
    mov      ah, 06h
    mov      al, DumpNo
    call     @APIAddress
    cmp      al, 0
    je       @NoDumpError

    mov      @Result, DumpError
    jmp      @GetOut

@NoDumpError:
    cmp      DumpNo, 1
    jne      @SecondDump
    mov      word ptr Dump1Seg, es
    mov      ah, 4ah
    mov      bx, 100h
    int      21h
    jmp      @GetOut

@FreeFirstDump:
    cmp      Dump1Seg, 0
    je       @GetOut
    mov      es, Dump1Seg
    mov      Dump1Seg, 0

@SecondDump:
    mov      ah, 49h                       {Free memory of the loaded program}
    int      21h
    jnc      @FreeFirstDump
    pop      bp
    push     bp
    mov      @result, FreeError

@GetOut:
    pop      bp

    cmp      Locked, True
    jne      @NotLocked

    mov      ah, 02h                              {Unlock DumpExe API session}
    call     @APIAddress
    mov      Locked, False

@NotLocked:
  end;
  SwapVectors;
  SetIntVec ($01, @OldInt01);
End;

Procedure WriteFailed;
Begin
  TextColor (LightRed);
  WriteLn ('FAILED');
  TextColor (White);
End;

Procedure WriteIfError(RetVal : Byte);
Begin
  If RetVal = RetFFound Then Begin
    WriteLn('OK');
    Exit;
  End;
  WriteFailed;
  Case RetVal Of
    LoadError    : Error(FileError);
    FreeError    : Error(253);
    EndOfProgram : Error(252);
    VersionError : Error(251);
    SizeError    : Error(250);
    DumpError    : Error(249);
  Else
    Error(0);
  End;
End;

Procedure WriteFailedWithError(Err : Byte; ErrText : Str80 );
Begin
  WriteFailed;
  WriteLn (ErrText);
  LastInitText;
  Halt(Err);
End;

Procedure Init;
Var
  InFile : File;
  Buff : Array[1..32] Of Char;
  Res, Ct : Integer;

Begin
  DumpNo := 1;
  Clrscr;
  WriteTitleText;
  TextColor (White);
  If ParamCount <> 1 Then Error (255);
  Write ('þ DumpExe API is resident ');
  If NOT DumpExeAPIResident Then
    WriteFailedWithError(3,'Please start DUMPAPI.EXE before using UNPACKER.EXE');
  WriteLn ('OK');
  WriteLn;

  Assign(InFile, ParamStr(1));
  Reset (InFile,1);
  Res := IOresult;
  If Res <> 0 Then Error (Res);
  BlockRead(InFile, Buff,SizeOf(Buff), Ct);
  Close(InFile);
  If Ct <> SizeOf(Buff) Then Error(248);
  If NOT (((Buff[1] = 'M') AND (Buff[2] = 'Z')) OR {Test if file is an EXE}
          ((Buff[1] = 'Z') AND (Buff[2] = 'M'))) Then Error (247);
  If ((Buff[31] <> 'P') OR (Buff[32] <> 'K')) Then Error (246); {PKLited ?}
End;

Procedure UnpackFile;
Begin
  WriteLn ('Unpacking file : ', ParamStr(1));
  WriteLn;

  Write('Making first dump ');
  WriteIfError(TraceFile);

  Inc(DumpNo);

  Write('Making second dump ');
  WriteIfError(TraceFile);
  WriteLn;
  WriteLn ('Use MAKEEXE.EXE to create an unpacked exefile.');
  LastInitText;
End;

Begin
  Init;
  UnpackFile;
End.

