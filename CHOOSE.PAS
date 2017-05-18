{            The rasterbar system was coded by SPAWN/OBSESSiON
            The textbar   system was coded by BUGSY/OBSESSiON


Remember : The menu system is coded VERY FAST and I know part of the code
            sucks, but you forgive me, right ? ;-}

Unit CHOOSE;

Interface

Const
  KeyUp     = Byte ('!');
  KeyDown   = Byte ('"');
  KeyLeft   = Byte ('#');
  KeyRight  = Byte ('¯');
  KeyU1     = Byte ('U');
  KeyU2     = Byte ('u');
  KeyESC    = 27;
  KeyTAB    = 9;
  KeyReturn = 13;
  KeyShTAB  = 15;

  BarColor  = $5;

Procedure RestoreColor;
Procedure SetColor;
Function ActivateMenu( Y,Max,PalNumber,StartPos,TextY : Word; RasterBar : Boolean) : WORD;

Implementation
Uses
  Crt;

Const
  Bar      : Array[1..17] Of Byte = ( $1c,$20,$26,$2a,$2e,$33,$39,$3c,$3c,$39,$33,$2e,$2a,$26,$20,$1c,$1c);
{  Bar2     : Array[1..18] Of Byte = ( $1c,$20,$26,$2a,$2e,$33,$39,$3c,$3c,$3c,$39,$33,$2e,$2a,$26,$20,$1c,$1c);}
  OrgColor : Array[1..2*3] OF Byte = ( 0,40,40, 40,7,7); {Why not get them insted????????}

Var
  Pal1     : Array[1..353*3] Of Byte;

Procedure RestoreColor; ASSEMBLER;
ASM
  cld     {Damn it was hard to find!}
  mov     si,offset OrgColor
  mov     dx,3c8h
  mov     al,3
  out     dx,al
  inc     dx
  mov     cx,6
@l:
  lodsb
  out     dx,al
  loop    @l
END;

Procedure SetColor; ASSEMBLER;
ASM
  cld     {Damn it was hard to find!}
  mov     dx,3c8h
  mov     al,3
  out     dx,al
  inc     dx
  mov     cx,2
@l:
  mov     al,0
  out     dx,al
  out     dx,al
  mov     al,2ah
  out     dx,al
  loop    @l
END;

Function Menu( Y,Max,PalNumber,StartPos : Word ) : WORD; Assembler;
Var
  Direction   : Byte;
  BlockPos    : Byte;
  MoveSize    : Word;

Asm
  cli
  mov           ax,ds
  mov           es,ax

  mov           direction,0
  mov           movesize,0

  mov           ax,StartPos
  mov           blockpos,al
  xor           dx,dx
  mov           bx,16
  mul           bx
  inc           BlockPos

  mov           si,offset Bar
  mov           di,offset pal1
  add           di,Y
  add           di,2
  add           di,ax

  mov           cx,16
  cld
  rep           movsb

  mov           bx,3c9h

@Loop2:
  cli
  mov           cx,353
  mov           si,offset Pal1

  mov           dx,3DAh
@VrtPau1:
  in            al,dx
  test          al,8
  je            @VrtPau1

@Loop1:
  mov           dx,3c8h
  mov           ax,PalNumber
  out           dx,al

  mov	        dx,3DAh
@VRetrace:
  in	        al,dx
  test	        al,1
  jne	        @VRetrace
@HRetrace:
  in	        al,dx
  test	        al,1
  je	        @HRetrace

  mov           dx,3c9h
  xor           bx,bx
  mov           al,byte ptr ds:[si]
  mov           ah,al
  xor           al,0
  jnz           @NotOrgC
  mov           al,0
  mov           bl,al
  mov           bh,02ah
@NotOrgC:
  out           dx,al
  mov           al,bl
  out           dx,al
  mov           al,bh

  out           dx,al

  inc           si
  loop          @Loop1


  cmp           Direction,1  { 2 = Up, 1 = Down, 0 = Nothing}
  jg            @MoveLoopUp
  jb            @TestKey

  cmp           MoveSize,0
  jne           @NotEnd1
  mov           Direction,0

@NotEnd1:
  mov           si,offset Pal1
  mov           ax,max
  inc           al
  cmp           blockpos,al
  jge           @TestKey
  std
  dec           MoveSize
  mov           al,byte ptr ds:[si+350]
  mov           cx,350
  add           si,349
  mov           di,si
  inc           di
  rep           movsb
  mov           si,offset Pal1
  mov           byte ptr ds:[si],al
  jmp           @Loop2

@MoveLoopUp:
  cmp           MoveSize,0
  jne           @NotEnd2
  mov           Direction,0

@NotEnd2:
  cmp           blockpos,0
  je            @TestKey
  cld
  mov           si,offset Pal1
  dec           MoveSize
  mov           al,byte ptr ds:[si]
  mov           cx,350
  mov           di,si
  inc           si
  rep           movsb
  mov           byte ptr ds:[si],al
  jmp           @Loop2

@TestKey:
  mov           ah, 01h
  int           16h
  jz            @Loop2

  mov           ah,6
  mov           dl,0ffh
  int           21h

  mov           cl,al
  cmp           al,0
  jne           @NotExt

  mov           ah,6
  int           21h
  mov           ch,al

  cmp           al, KeyShTAB
  je            @Done

  cmp           cx,4800h      {Up}
  je            @UpKey
  cmp           cx,5000h      {Down}
  je            @DownKey
  cmp           cx,4b00h      {Left}
  je            @LeftKey
  cmp           cx,4d00h      {Right}
  je            @RightKey
  jmp           @Loop2

@LeftKey:
  mov           al, KeyLeft
  jmp           @Done

@RightKey:
  mov           al, KeyRight
  jmp           @Done

@DownKey:
  mov           ax,Max
  cmp           BlockPos,al
  jne           @NotMax
  mov           al, KeyDown
  jmp           @Done

@NotMax:
  mov           MoveSize,15
  mov           Direction,1
  inc           BlockPos
  jmp           @Loop2

@UpKey:
  cmp           BlockPos,1
  jne           @NotMin
  mov           al, KeyUp
  jmp           @Done

@NotMin:
  mov           MoveSize,15
  mov           Direction,2
  dec           BlockPos
  jmp           @Loop2

@NotExt:
  cmp           al,KeyReturn { Return pressed }
  je            @Done

  cmp           al, KeyU1    { u key pressed }
  je            @Done

  cmp           al, KeyU2    { U key pressed }
  je            @Done

  cmp           al,KeyTAB    { TAB key pressed }
  je            @Done

  cmp           al, KeyESC   { ESC key pressed }
  je            @Done

  jmp           @Loop2

@Done:
  mov           ah,BlockPos

@GetOut:
  sti
End;

Procedure DrawBar (XPos, BackColor, NewColor : Word);
Var
  Ct : Byte;
  MemPos : Word;

Begin
  For Ct := 0 To 79 Do Begin
    MemPos := (XPos)*160 + (Ct * 2) + 1;
    If Mem[$b800:MemPos] AND $F0 = BackColor SHL 4 Then
      Mem[$b800:MemPos] := Mem[$b800:MemPos] AND $0F + (NewColor SHL 4);
  End;
End;

Function TextBar ( TopPos,MaxPos,CurrPos,PalNumber : Word ) : WORD;
Var
  Ch   : Char;
  Quit : Boolean;
  RetVal : Word;

Begin
  RetVal := 0;  {BUG BUG BUG}
  Repeat
    Quit := True;
    DrawBar (CurrPos, PalNumber, BarColor);
    While KeyPressed Do ReadKey;
    Repeat Until KeyPressed;
    Ch := ReadKey;
    Case Ch Of
      #27 : RetVal := KeyEsc;
      #13 : RetVal := KeyReturn;
      #09 : RetVal := KeyTab;
      'U' : RetVal := KeyU1;
      'u' : RetVal := KeyU2;
      #00 : Begin
              Ch := Upcase(ReadKey);
              Case Ch Of
                #15 : RetVal := KeyShTab;
                #72 : Begin
                        RetVal := KeyUp;
                        If CurrPos <> TopPos Then Begin
                          Quit := False;
                          DrawBar(CurrPos, BarColor, PalNumber);
                          Dec(CurrPos);
                        End;
                      End;
                #80 : Begin
                        RetVal := KeyDown;
                        If CurrPos <> MaxPos-2 Then Begin
                          Quit := False;
                          DrawBar(CurrPos, BarColor, PalNumber);
                          Inc(CurrPos);
                        End;
                      End;
                #75 : RetVal := KeyLeft;
                #77 : RetVal := KeyRight;
              End;
            End;
    Else
      Quit := False;
    End;
  Until Quit;
  DrawBar(CurrPos, BarColor, PalNumber);
  TextBar := (CurrPos-TopPos) SHL 8 + RetVal;
End;

Function ActivateMenu( Y,Max,PalNumber,StartPos,TextY : Word; RasterBar : Boolean) : Word;
Begin
  If RasterBar Then Begin
    FillChar( Pal1,353*3,0 );
    ActivateMenu := Menu( Y,Max,PalNumber,StartPos );
  End Else
    ActivateMenu := TextBar (TextY,Max+1+TextY,StartPos+TextY,PalNumber) + $0100;
End;

END.