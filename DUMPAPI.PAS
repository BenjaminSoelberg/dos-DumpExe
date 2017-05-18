{$A+,B-,D+,E-,F-,G+,I-,L+,N-,O-,P-,Q-,R-,S-,T-,V-,X+,Y+}
{$M 2048,0,0}

Program DumpExeAPI;

Uses
  Crt    ,
  Dos    ,
  ExeUtil;

Const
  Kb4Size        = $0100;

  NoError        = 0;
  IsError        = 1;

Var
  DataSeg        : Word;
  OrgIntFB       : Procedure;
  ExeInfo        : Array [1..2] Of ExeInfoRecType;
  Reg            : Registers;
  RetAX,
  RetBX,
  RetCX,
  RetDX,
  RetSI,
  RetDI,
  RetBP,
  RetDS,
  RetES         : Word;

Procedure IntFBHand; Forward;

Procedure LastLine;
Begin
  GotoXY(1, WhereY-1);
  Write('                 See the file ');
  TextColor(LightBlue);
  Write('DUMPAPI.TXT');
  TextColor(LightRed);
  WriteLn(' for more detailes.');
End;

Procedure DeleteTSR; FAR;
Begin
  SetIntVec (IntFB, @OrgIntFB);

  asm
    mov     ah, 49h
    mov     es, word ptr PrefixSeg
    int     21h
  end;
End;

Function SnapShotMem : Byte;
Const
  BuffSizeInP : Word = $1000;
  MemFileName = 'SNAPSHOT.MEM';

Var
  Ct          : Byte;
  Written     : Word;
  OutFile     : File;

Begin
  Assign (OutFile, MemFileName);
  ReWrite (OutFile, 1);
  If IOResult <> 0 Then
  Begin
    SnapShotMem := IsError;
    Exit;
  End;

  For Ct := 0 To $0F Do Begin
    BlockWrite (OutFile, Ptr (Ct*$1000, 0)^, $0001, Written);
    BlockWrite (OutFile, Ptr (Ct*$1000, 1)^, $FFFF, Written);
    If Written <> $FFFF Then Begin
      SnapShotMem := IsError;
      Exit;
    End;
  End;
  Close (OutFile);
  FlushDiskCache;
  SnapShotMem := NoError;
End;

Function DumpMem (FileNr : Byte) : Byte;
Const
  BuffSize    = $1000;
  BuffSizeInP = $100;

Var
  Ct          ,
  BuffCt      : LongInt;
  Written     : Integer;
  Error       : Boolean;
  OutFile     : File;

Begin
  Assign (OutFile, ExeInfo[FileNr].Name);
  ReWrite (OutFile, 1);
  If IOResult <> 0 Then
  Begin
    DumpMem := IsError;
    Exit;
  End;
  Ct     := 0;
  Error  := False;
  BuffCt := ExeInfo[FileNr].PSP + $10;

  BlockWrite (OutFile, DumpID, SizeOf(DumpID), Written);
  BlockWrite (OutFile, ExeInfo[FileNr], SizeOf (ExeInfoRecType), Written);
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
  End;
  Close (OutFile);
  FlushDiskCache;
  DumpMem := Byte (Error);
End;

Function AutodetectName (FileNr : Byte) : Byte;
Var
  Ct     : Byte;
  PSP    : Word;
  Name   : String[8];

Begin
  AutodetectName := IsError;
  PSP := ExeInfo[FileNr].PSP;
  Dec (PSP);
  If MemW[PSP:1] <> PSP + 1 Then Exit;
  Ct := 0;
  Name := '';
  While Mem[PSP:8+Ct] <> 0 Do Begin
    Name := Name + Char(Mem[PSP:8+Ct]);
    Inc (Ct);
  End;
  If Name = '' Then Exit;

  ExeInfo[FileNr].Name := Name + '.' + Char (FileNr + 48);
  AutodetectName := NoError;
End;

Function AutodetectSize (Ct : Byte) : Byte;
Begin
  AutodetectSize := NoError;
  Case Ct Of
    1 : ExeInfo[1].Size := LongInt (MemW [ExeInfo[1].PSP:2] - (ExeInfo[1].PSP + $10)) * $10;
    2 : Begin
          If ExeInfo[1].SS < ExeInfo[1].PSP + $10 Then Begin
            AutodetectSize := IsError;
            Exit;
          End;
          ExeInfo[1].Size := LongInt (ExeInfo[1].SS - (ExeInfo[1].PSP + $10)) * $10;
        End;
  Else
    AutodetectSize := IsError;
  End;
  ExeInfo[2].Size := ExeInfo[1].Size;
End;

Procedure DoFunctions;
Var
  Ct,
  RetVal : Byte;

Begin
  RetVal := NoError;
  Case Hi(RetAX) Of
    $00 : Begin
            RetBX := VersionHex;
          End;
    $01 : Begin
            asm
              mov    ax, 3500h + IntFB
              int    21h
              mov    RetES, es
              mov    RetDI, bx
            end;
            SetIntVec(IntFB, @OrgIntFB);
          End;
    $02 : SetIntVec(IntFB, @IntFBHand);
    $03 : Begin
            ExeInfo[Byte(RetAX)].CS  := MemW[RetDS:RetSI+0];
            ExeInfo[Byte(RetAX)].IP  := MemW[RetDS:RetSI+2];
            ExeInfo[Byte(RetAX)].SS  := MemW[RetDS:RetSI+4];
            ExeInfo[Byte(RetAX)].SP  := MemW[RetDS:RetSI+6];
            ExeInfo[Byte(RetAX)].PSP := MemW[RetDS:RetSI+8];
          End;
    $04 : RetVal := AutodetectSize(Byte(RetBX));
    $05 : Begin
            ExeInfo[1].Size := RetBX SHL 4;
            ExeInfo[2].Size := RetBX SHL 4;
          End;
    $06 : RetVal := DumpMem(Byte(RetAX));
    $07 : RetVal := SnapShotMem;
    $FF : DeleteTSR;
  Else
    RetVal := IsError;
  End;
  Byte(RetAX) := RetVal;
End;

Procedure IntFBHand; ASSEMBLER;
asm
  jmp     @JumpOver
  db 'API!'
@JumpOver:
  push    ds
  mov     ds, word ptr @DataSeg

  mov     RetAX, ax
  mov     RetBX, bx
  mov     RetCX, cx
  mov     RetDX, dx
  mov     RetSI, si
  mov     RetDI, di
  mov     RetBP, bp
  pop     word ptr RetDS
  mov     RetES, es

  call    DoFunctions

  mov     ax, RetAX
  mov     bx, RetBX
  mov     cx, RetCX
  mov     dx, RetDX
  mov     si, RetSI
  mov     di, RetDI
  mov     bp, RetBP
  mov     es, RetES
  mov     ds, RetDS

  iret

@DataSeg: dw SEG DataSeg
End;

Procedure WriteFailedWithError(Err : Byte; ErrText : Str80 );
Begin
  TextColor (LightRed);
  WriteLn ('FAILED');
  TextColor (White);
  WriteLn (ErrText);
  Halt(Err);
End;

Procedure Init;
Begin
  ExeInfo[1].Name := '#NoName#.1';
  ExeInfo[2].Name := '#NoName#.2';

  Clrscr;
  WriteTitleText(5);
  TextColor (White);
  Write ('þ DumpExe not resident ');
  If DumpExeResident Then
    WriteFailedWithError(99, 'Please uninstall DumpExe before running DumpExe API.');
  WriteLn ('OK');

  If DumpExeAPIResident Then Begin
    Write ('þ DumpExe API now uninstalled ');
    asm
      mov ah, 0ffh
     {int 0fbh}
      db  0cdh
      db  IntFB
    end;
    WriteLn ('OK');
    LastInitText;
    LastLine;
    Halt;
  End;

  Write ('þ DESQView not resident ');
  If DVInstalled Then
    WriteFailedWithError(98,'Can''t run under DESQView, sorry.');
  WriteLn ('OK');

  TextColor (White);
  Write ('þ Testing processor type ');
  If Test8086 = 0 Then
    WriteFailedWithError(2,'Sorry, but you need a 80286 or better cpu to run this program.');
  WriteLn ('OK');

  Write ('þ Dos version 5.0+ ');
  If Byte(DosVersion) < 5 Then
    WriteFailedWithError(3,'Sorry, but you need dos 5.0 or above to run this program.');
  WriteLn ('OK');

  Reg.ah := $49;
  Reg.es := MemW [PrefixSeg:$2C];
  Intr ($21, Reg); {Free Env}

  SetIntVec ($1B, SaveInt1B); {Restore ctrl-break handler}
  GetIntVec (IntFB, @OrgIntFB);
  SetIntVec (IntFB, @IntFBHand);

  WriteLn ('þ Program now resident OK');
  LastInitText;
  LastLine;
  Keep (0);
End;

Begin
  Init;
End.
