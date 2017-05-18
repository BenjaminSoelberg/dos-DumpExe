<pre>
 ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
 █                                                                            █
 █                      "*"   DumpExe version 2.5   "*"                       █
 █                                                                            █
 █                  by ▄─▄ ▄   ▄─▄ ▄─▄ ▄─▄ ▄─▄ ▄ ▄─▄ ▄─▄                      █
 █                     █ █ █─▄ ▀─▄ █─  ▀─▄ ▀─▄ ▄ █ █ █ █                      █
 █                     █ █ █ █ ▄ █ █   ▄ █ ▄ █ █ █ █ █ █                      █
 █                     ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀ ▀▀▀ ▀ ▀ 1998                 █
 █                                                                            █
 █────────────────────────────────────────────────────────────────────────────█
 █ Handle  Real name         Age Profession E-Mail address   Group activity   █
 █────────────────────────────────────────────────────────────────────────────█
 █ Bugsy   Benjamin Petersen  25 Programmer _bugsy@usa.net   Coder, organizer █
 █ Hendrix Patrick Enoch      22 Study Math _hendrix@usa.net Coder, unpackers █
 █ Spawn   Michael Skovslund  24 Programmer _spawn@usa.net   Coder, gfx       █
 █ Icicle  Henrik Eiriksson   25 Study IFA  _icicle@usa.net  Music, art       █
 █────────────────────────────────────────────────────────────────────────────█
 █                                                                            █
 █  PLEASE CHECK OUT OUR INTERNET HOMEPAGE AT : home.t-online.de/home/enoch   █
 █                                                                            █
 ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

INDEX
  History                        (New information, please take a look)
  Introduction
  Disclaimer
  Keyboard layout
  Program documentation
  Configuration
  SoftICE user notice            (New information, please take a look)
  GameTools user notice
  EatMem utility
  How to unpack an exefile
  How to get in touch with us    (New information, please take a look)
  Distribution sites
  Greetings                      (New information, please take a look)


■ History

  Version   Release Note

      1.0   Never released to the public, only for our beta-testers (Darkman)

      1.1   First public release

      1.2   Now with SoftICE debugger support. Activate via INT FCh

      2.0   Autodump from TD, S-ICE and GAMETOOLS. Detects a lot of things.
            Uses UMB. Added Total Memory Dump feature, Show User Screen. Now it
            swaps dos-stack so DumpExe can be activated at any time (re-entrant)

      2.1   Fixed a bug in dos version check. (Damn)

      2.2   Added support for overlay as requested by José Navarro Martínez
            Fixed minor bugs in DumpExe. Added mail registration form
            Added a utility called EATMEM that allocates 4 KB from within DOS.
            Removed the WORD version of this doc file (Did anybody use it ?).

      2.3   Added a configuration file. Added "Fastmode" in file 2.
            Now you can choose between a rasterbar and a textmode bar.
            Added the auto-fill from SoftICE as promised in v2.0, phew.
            The PSP validation function have now 3 ways to demind if PSP
            is valid. Added userdefined SoftICE/DumpExe interrupt. Now the
            user can change the stacksize that DumpExe uses. Changed some
            colors. Added a function that alows the user to specifye SoftICE
            backdoor values. Added support for Turbo Debugger 4.x and 5.0.
            SoftICE is now, by default, activated via INT 4C

      2.5   DumpExe under SoftICE is now, by default, activated via INT 32.
            Fixed a bug in MakeExe that caused it to be ONE relocation short.
            Added an API interface to DumpExe, so you can make unpackers
            yourself without to much trouble. Added an unpacker (UNPACKER.EXE)
            and the source code for it to show how DumpExe API works. It can
            unpack PKLite'ed files. Added suport for SoftICE version 3, under
            windows 95

      2.5   Now with Pentium safe code with Borland patch for runtime error 200

■ Introduction

  This program is able to unpack ANY packed exefile. Many other programs,
  such as cup, up, tron, unp and vgacbust give you the same ability. But those
  programs can only expand/unpack files packed with known exepackers. By
  using the OBSESSiON DumpExe toolpack, you can unpack any of those exefiles
  that the above utilities give up on. Of course this can't be done by inserting
  a quarter (kr.) into the crypt-o-mate. We have to do a little more than this.
  This is where you, the OBSESSiON DumpExe toolpack, and your debugger come
  into the picture.

  All you have to do is this :
    Load the exeprogram into your favourite debugger (eg. TD, S-ice, GameTools)
    Debug the program until first original (unpacked) instruction
    Dump the code/data, using the DumpExe program, via the FILE 1 option
    Terminate the loaded program
    Allocate a 4 Kb memory block via the DumpExe program (or use EATMEM.EXE)
    Reload the program, and ensure that the entry point is different
    Debug the program until first original (unpacked) instruction
    Dump the code/data, using the DumpExe program, via the FILE 2 option
    Terminate the loaded program
    Deallocate the 4 Kb memory block via the DumpExe program (or use EATMEM.EXE)
    Run MAKEEXE with the needed parameters.
      Example : MAKEEXE.EXE ORIGINAL.EXE NEWFILE.EXE

    And 'puf', your done.

  To technically understand how this can be done, please refer to selection :
  "How to unpack an exefile".

  If this sounds easy, exit your doc reader now, if not, keep on reading. 8-)

■ Disclaimer

  This software has been tested and found to work properly. OBSESSiON have no
  responsbility whatsoever for any damages caused by use, or misuse of this
  software.

  IF YOU DISAGREE WITH ANY OF THOSE TERMS, PLEASE REMOVE THIS SOFTWARE NOW.

  If you, after a 24 hour test period, still wish to continue using this
  software, you NEED to send us a postcard with your name and address or
  register at our homepage at HTTP://home.t-online.de/home/enoch. The reason is
  that it's the ONLY way I can explain to my wife why I have invested MORE than
  300 hours developing this software. This is the only way I can see that
  someone is really using this software. If I don't receive anything by mail,
  I won't update the program any more.

  This means :
    IF NOT (ReceivedAnyPostCardOrEMail) THEN
      HALT (Programmer)
    ELSE
      ReleaseNextVersion

■ Keyboard layout

  Left shift + right shift : Activate the resident part of DumpExe
  TAB                      : Jump to next menu block
  Shift TAB                : Jump to previous menu block
  Arrow up/down            : Next/previous menu selection/block
  Arrow left/right         : Next/previous digit or menu block
  ESC                      : Terminate DumpExe or return to previous state
  Enter                    : Confirm selection/input

■ Program documentation

  Install DumpExe into memory by starting the file DumpExe.EXE. The program
  will now go resident (TSR) in memory. This means that it can be envoked at
  any time and within any dos program (such as a debugger).If UMB is available,
  the 'DOS stack' and 'Screen swap data' will be placed here. To activate
  DumpExe, please press "LEFT SHIFT" and "RIGHT SHIFT" at the same time (also
  called the hotkey). A menu like the one shown below, should appear. To return
  to interrupted program, press "ESC".

  NOTICE : In versions 1.2 you couldn't start DumpExe by pressing the
           hotkey within the dos command line (InDOS). This has now been
           fixed by using the technique called 'DOS stack switching'.

               FIG 1. The main picture of DumpExe

  ┌────── DumpExe v2.5 CARDWARE 1998 by BUGSY/OBSESSiON ──[1]─┐
  │          Dos, ≥80386, V86 mode, Turbo Debugger        [2] │
  │───────── First file ────[3]─┬───────── Second file ───[4]─│
  │ CS   : 0000                 │ CS   : 0000                 │
  │ IP   : 0000                 │ IP   : 0000                 │
  │ SS   : 0000                 │ SS   : 0000                 │
  │ SP   : 0000                 │ SP   : 0000                 │
  │ PSP  : 0000                 │ PSP  : 0000                 │
  │ Size : 00000 (0)            │ Size : 00000 (0)            │
  │ Name : #NoName#.1           │ Name : #NoName#.2           │
  │─────────────────────────[5]─┼─────────────────────────[6]─│
  │      Dump exe-code          │      Dump exe-code          │
  │      Autodetect name        │      Autodetect name        │
  │      Autodetect size        │      Autodetect size        │
  │─────────────────────────[7]─┼─────────────────────────[8]─│
  │      Configuration          │      User screen            │
  │      Memory snapshot        │      Allocate 4Kb           │
  │      Reset menu             │      Auto config file 2     │
  │      Uninstall              │      Fill from debugger     │
  │─────────────────────────────┴─ Free 99 kb, Slack 0 kb [9]─│
  │                                                      [10] │
  └───────────────── Hotkey : (U)ser screen ──────────────────┘

  Overview
    [1] Copyright text.
    [2] Information on the operating system and found debuggers.
    [3] Data for first memory dump, set by the user.
    [4] -"-  for second memory dump.
    [5] Menu concerning first memory dump.
    [6] -"-  for second memory dump.
    [7] General purpose menu, concerning global use of DumpExe.
    [8] Utility menu with functions, helps you get the job done faster.
    [9] Information about the current memory status.
   [10] Shows status messages from DumpExe and serves as an input prompt.

  Explenation
    [1] Copyright text.
          Tells who made this brilliant program.

    [2] Information on the operating system and found debuggers.
          Shows if current session is a DOS, WINDOWS or OS/2 session.
          Also shows which debuggers have been found active at the present
          moment.

          Can show a mixture of the following text strings :
            [8086, 80286, ≥80386],
            [Real mode, V86 mode],
            [Dos, Win Std, Win Enh, OS/2],
            [No debugger, Turbo Debugger, SoftICE, GameTools]

          Example : Dos, ≥80386, Real mode, SoftICE, GameTools

          As you can see, it is possible to have more than one debugger loaded
          at the same time. This can be usefull when combining Turbo Debugger
          and GameTools.

    [3] Data for first memory dump, set by the user.
          This subwindow is used to enter information about the program you
          want to unpack. You have to fill out ALL fields to get a working
          copy of the unpacked program.

            CS   : Current code segment
            IP   : Current instruction pointer
            SS   : Current stack segment
            SP   : Current stack pointer
            PSP  : Current program prefix segment, usually the same as ES
            Size : Size of program in bytes
            Name : Name of dump file

          To change a value, move the selector to the decided item and press
          "ENTER". Enter the new value and press "ENTER" again.
          REMARK : All numbers are shown and entered in hexadecimal values.
                   The filename can not be entered manuelly.

    [4] -"- for second memory dump. ([3])

    [5] Menu concerning first memory dump.
          It is used for dumping the code/data block entered in [3] or [4].

          Menu items available are :

            Dump exe-code   : Select this one to dump selected code/data block.

            Autodetect name : Let DumpExe autodetect the name of the program
                              its processing, and use it as the dump filename.

            Autodetect size : Let DumpExe autodetect the size of the code/data
                              block. There are two ways to autodetect this
                              size. It can be done by Stack or by PSP. The
                              most common way is 'By Stack', because this
                              usually gives a smaller, and more accurate image
                              of the original unpacked exefile.

    [6] -"- for second memory dump. ([5])

    [7] General purpose menu, concerning the global use of DumpExe.

        Menu items available are :

            Configuration   : Use it to configure how DumpExe reacts in
                              different situations. See "Configuration"

            Memory snapshot : Takes a snapshot of the first megabyte of memory,
                              and puts it in a file in the current directory;
                              called SNAPSHOT.MEM. Use it for whatever you may
                              like.

            Reset menu      : Sets all items to their initial value. Use it if
                              something, somehow goes bananas.

            Uninstall       : Removes the DumpExe software from the memory.
                              Use it if you want to remove the DumpExe from
                              memory.

    [8] Utility menu with functions that helps you get the job done faster.

          Menu items available are :

            User screen        : Shows the screen as it was before DumpExe was
                                 started. Use this function instead of pressing
                                 "ESC" and then the hotkey. This function can
                                 also be called by pressing "U" while in view
                                 mode.

            (De)Allocate 4Kb   : Used to allocate/deallocate a block of 0100h
                                 paragraphs (4 Kb). This should be done after
                                 the first dump and termination, and before you
                                 reload the program. Please take a look at the
                                 tutorial later in this document.

                                 NOTICE : This function can ONLY be used within
                                          Turbo Debugger and GameTools. So if
                                          you are using SoftICE, please use
                                          the utility called EATMEM.EXE instead.

            Auto-Config        : Adds 0101h to all segment registers in [2] and
                                 store them in [3]. It is useful after
                                 preparing for second dump. This works only on
                                 9 out 10 packed files. Please notice that CS
                                 in [3] matches the one shown by the debugger.
                                 If not, enter all values manually. You only
                                 have to use this function if
                                 "Fill from debugger" fails.

            Fill from debugger : Read the register shown by the debugger and
                                 automatically place the values into first or
                                 second dumpfile. This is a VERY useful
                                 function, since it gives you the ability to
                                 unpack the exefile FAST.

    [9] Information about the current memory status.

          Free  : Amount of free basememory, in Kb.
          Slack : Number of memory fragments in Kb, after allocating 4 Kb.

   [10] Status messages from DumpExe and input prompt.
        This line serves as an error message and input scratch.

        Here are some of the error messages that can appear :

          No size given.
            You have to enter how much memory the program needs to dump.

          No memory allocated.
            You are trying to auto-config file 2, and you haven't used
            "allocate 4KB". You must manually enter the data required to dump

          Can't auto-config file 2, sorry.
            You have to manually, enter the data required to dump a program.
            Or you could use the function : "Fill from debugger"

          The PSP-segment is not valid.
            You are using a function that requires a valid PSP segment,
            entered in [3] or [4].

          The PSP-segment for file 1 is not valid.
            See the above.

          Can't find name.
            DumpExe is not able to find the name of the program you want
            to dump. The program is using a standard name instead.

          Can't uninstall, vector hooked by another program.
            You have loaded another program after DumpExe. Unfortunately the
            two programs have both hooked onto the same interrupt. Unload the
            other program first and try again.

          Can't allocate necessary memory.
            Boot your machine with fewer drivers, and try again. If this
            doesn't help, you are f.....

          Out of stack.
            Your memory is fragmented too much. By default DumpExe has a 4 Kb
            stack and in this case it doesn't seem to be enough. Make it bigger
            in the config

          Can't release memory.
            This error is most likely caused by the program you are about to
            dump, or the stack of this program has been destroyed. Dump the
            code and boot your PC. (the dumpfile should be okay, I hope...)

          Can't make file.
            Oops, a disk error. Check your harddisk with "chkdsk /f" or
            "scandisk"

          Can't write file, disk full ?.
            Free some disk space, and try again.

          Can't deallocate memory.
            The MCB (memory control block) has been destroyed. Dump the code
            and don't think more about it. (again, the dumpfile should be okay,
            I hope...)

■ Configuration

  Below is a picture of the configuration menu :

  ┌────── DumpExe Configuration ──[1]─┐
  │ Rasterbar                : AUTO   │
  │ Fast mode                : ON     │
  │ PSP validation level     : MEDIUM │
  │ SoftICE SI value         : 4647h  │
  │ SoftICE DI value         : 4A4Dh  │
  │───────────────────────────────[2]─│
  │ Activate via interrupt   : 32h    │
  │ DumpExe stack size       : 1000h  │
  │───────────────────────────────[3]─│
  │      Reset to default values      │
  │───────────────────────────────[4]─│
  │                                   │
  └───────────────────────────────────┘

  With this menu you can control how DumpExe reacts in different situations.
  When you change a value, it will be saved to the binary file DumpExe.CFG.
  If you change values in [1] it will affect the behavior of DumpExe instantly,
  and if you change the values in [2], you have to reload DumpExe in order to
  let them affect DumpExe.

  Overview
    [1] User parameters
    [2] System parameters
    [3] Reset the configuration to default values.
    [4] Shows status messages from DumpExe.

  Explenation
    [1] User parameters

          Menu items available are :

            Rasterbar              : When you activate this selection,
                                     you switch between a rasterbar, and a
                                     textmodebar. The difference between them
                                     are that rasterbar looks nice, but are
                                     slow and uses alot of processor time.
                                     Textmodebar look ugly, but are fast and
                                     uses almost no processor time. You can
                                     cycle between OFF/ON/AUTO. In automode
                                     DumpExe will determine if it should use
                                     a raster- or textmodebar. It chooses
                                     rasterbar in dos mode and textmodebar
                                     while running under windows.

            Fast mode              : Fast mode is for people in a hurry. The
                                     registeres in File 2 follows File 1. Well
                                     at least IP, SP, size and name does. When
                                     you enter the PSP in File 2, DumpExe will
                                     calculate the rest of the values for you.
                                     "Fast mode" can be set to ON or OFF. If
                                     you choose OFF mode, DumpExe reacts like
                                     it did in previous versions, and you have
                                     to enter all informations by yourself (or
                                     use the "Fill from debugger" selection).

            PSP validation level   : When DumpExe is detecting the name or the
                                     the size of the program you are unpacking,
                                     it uses the programs PSP. So in order to
                                     do that, it need to know if the PSP is
                                     valid or not. DumpExe performs 3 checks to
                                     do that. When you activate this selection
                                     it cycles between NONE/SOFT/MEDIUM/HARD.
                                     In NONE mode no check is performed. In
                                     SOFT mode, one out of three PSP checks must
                                     be true. In MEDIUM mode, two out of three
                                     PSP checks must be true. In HARD mode three
                                     out of three PSP checks must be true, in
                                     order to continue calculations. Some
                                     packers change part of the static PSP data
                                     to confuse unpackers, and therefor we
                                     advice you to use MEDIUM or SOFT mode.

            SoftICE SI value       : When DumpExe trys to detect SoftICE, it
                                     needs the so called backdoor values. These
                                     values are always the same if you are
                                     using the original version from Nu-Mega.
                                     But if you are using a patched version,
                                     DumpExe cannot demind if SoftICE is
                                     installed or not without the new backdoor
                                     values. So if you are using a patched
                                     version, enter the values here and in
                                     selection below.

            SoftICE DI value       : See "SoftICE SI value"

    [2] System parameters

          Menu items available are :

            Activate via interrupt : Since SoftICE for Windows doesn't support
                                     all interrupts (using the GENINT command)
                                     you have the ability to choose one for
                                     yourself. Please be sure that the
                                     interrupt you have chosen isn't used.
                                     Just to be clear : You cannot choose
                                     INT 09h, 21h or FBh, and guess why not !
                                     So if you are using SoftICE for windows
                                     choose one below 5Fh.

            DumpExe stack size     : When you allocate a 4 kb memory block
                                     DumpExe uses a lot of stack, and if you
                                     get the error message "Out of stack",
                                     try to increase this value by 800h. But
                                     it is my guess that you will NEVER see
                                     this error message, well at least I havn't

    [3] Reset configuration to default values.
          Resets the values in the configuration to there default values,
          nothing more, nothing less.

    [4] Shows status messages from DumpExe.
          Read the above line ;-)

■ SoftICE user notice

  NOTICE : In DumpExe version 2.3, Int 4ch was used to activate DumpExe,
           please use Int 32h. If this doesn't work try another value ;-)
           This is ONLY for SoftIce version 3 (under Win95) !
           If you are using SoftIce for DOS, Int FCh and Int 4Ch are also ok.

  If you are using SoftICE, the hotkey is disabled. This is because SoftICE
  runs in protected mode and uses its own interrupt vector table. To activate
  DumpExe, enter the following sequence at the SoftICE command line prompt :

    BPX CS:IP      : So we can return after INT 032h has terminated
    GENINT 32      : Start the exe-dumper
    GENINT 32      : Start the exe-dumper again (if you need it)
    BC 0           : Clear the breakpoint set by BPX. The number (in this case
                     0) is the name of the breakpoint label.

  Don't start DumpExe unless you are are at the very first instruction of
  the unpacked exefile because your current location might be in the keyboard
  handler or equal.

  NOTICE : You cannot use the DumpExe menu called 'Allocate 4Kb' within
           SoftICE. This function can ONLY be used within Turbo Debugger
           and GameTools. Please use the utility called EATMEM.EXE insted.
           (Look at selection 'EatMem utility' later)

  NOTICE : In version 2.2 and below the SoftICE/DumpExe interrupt was FCh,
           but since SoftICE for Windows can't handle interrupts above 5Fh
           we changed the default value. But if you have any problem using
           32h please send me a mail and choose an other in the Configuration
           menu.

■ GameTools user notice

  DumpExe only support GameTools version 3.40 properly.

  If you are using GameTools, be SURE to load DumpExe BEFORE you load
  GameTools. If you don't, you can't activate DumpExe within GameTools.

■ EatMem utility

  EatMem is a program that from within dos allows you to allocate
  a 4 KB memory block.

  When you start EATMEM.EXE the first time it starts DumpExe (if resident) and
  allocates a 4 KB memory block. The next time you start EATMEM.EXE it will
  free the 4 KB memory block.

  Use this utility if you can't allocate a 4 KB memory block within DumpExe.
  So insted of using the menu (in DumpExe) 'Allocate 4 KB', just return to dos,
  and run EATMEM.EXE. When you are finished with the second dump, just run
  EATMEM.EXE again, or release the 4 KB memory block via DumpExe.

■ How to unpack an exefile

  The file named TESTEXE.EXE is a packed exefile. It is used to illustrate
  how to use this tool, and nothing more. The file is packed with pklite
  version 2.01 using normal compression.

  I will use Turbo Debugger for this example, because if you know how to use
  the ultimate debugger SoftICE, you probably don't need this introduction
  anyway, do you ?

  If you don't know anything about using a debugger, I advise you to consult
  your debuggers manual.

  Try to execute the tutorial program TESTEXE.EXE and look at the text it
  displays. The program will tell you if it's packed or not.

  REMEMBER : Start DumpExe.EXE before proceeding with the next step.

  Start debugging TESTEXE.EXE by writing : TD.EXE TESTEXE.EXE

  The picture shown, by TD (Turbo Debugger), should look something like
  this :

  ╔═[■]═CPU 80486═══════════════════════════════════════╤═══════1═[][]═╗
  ║  cs:010050             push   ax                     ax 0000   │c=0║
  ║  cs:0101 B83106         mov    ax,0631              ■  bx 0000   │z=0║
  ║  cs:0104 BA8501         mov    dx,0185              ▒  cx 0000   │s=0║
  ║  cs:0107 054C84         add    ax,844C              ▒  dx 0000   │o=0║
  ║  cs:010A 3B060200       cmp    ax,[0002]            ▒  si 0000   │p=0║
  ║  cs:010E 722A           jb     013A                 ▒  di 0000   │a=0║
  ║  cs:0110 B409           mov    ah,09                ▒  bp 0000   │i=1║
  ║  cs:0112 BA1C01         mov    dx,011C              ▒  sp 0200   │d=0║
  ║  cs:0115 CD21           int    21                   ▒  ds 843C   │   ║
  ║  cs:0117 B8014C         mov    ax,4C01              ▒  es 843C   │   ║
  ║  cs:011A CD21           int    21                   ▒  ss 85F7   │   ║
  ║  cs:011C 4E             dec    si                   ▒  cs 843C   │   ║
  ║  cs:011D 6F             outsw                       ▒  ip 0100   │   ║
  ║  cs:011E 7420           je     0140                 ▒            │   ║
  ║  cs:0120 656E           outsb  gs:                              │   ║
  ╟■▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒┼────────────┴───╢
  ║  ds:0000 CD 20 A7 8A 00 9A C0 00 ═ ºè Ü└            │  ss:0208 2020  ║
  ║  ds:0008 00 00 E4 01 32 4B AE 01   Σ2K«           │  ss:0206 2020  ║
  ║  ds:0010 32 4B 80 02 8D 45 FB 36 2KÇìE√6           │  ss:0204 2020  ║
  ║  ds:0018 01 01 01 00 02 FF FF FF                │  ss:0202 2020  ║
  ║  ds:0020 FF FF FF FF FF FF FF FF                    │  ss:02003130  ║
  ╚═════════════════════════════════════════════════════╧═══════════════─┘
  NOTICE : Due to the nature of the PC-memory, the segment registers
           (CS, DS, ES, SS) might show different values than the one
           shown.

  Start executing the code until cs:0153, by pressing "F4" at location cs:0153,
  shown below. (Press "PAGEDOWN" 2 or 3 times)

  ╔═[■]═CPU 80486═══════════════════════════════════════╤═══════1═[][]═╗
  ║  cs:0147 B9C500         mov    cx,00C5                ax 8A44   │c=0║
  ║  cs:014A 33FF           xor    di,di                ■  bx 0000   │z=1║
  ║  cs:014C 57             push   di                   ▒  cx 0000   │s=0║
  ║  cs:014D BE5401         mov    si,0154              ▒  dx 0185   │o=0║
  ║  cs:0150 FC             cld                         ▒  si 02DE   │p=1║
  ║  cs:0151 F3A5           rep movsw                   ▒  di 018A   │a=0║
  ║  cs:0153CB             retf                        ▒  bp 0000   │i=1║
  ║  cs:0154 FD             std                         ▒  sp 01FA   │d=0║
  ║  cs:0155 8CDB           mov    bx,ds                ▒  ds 843C   │   ║
  ║  cs:0157 53             push   bx                   ▒  es 8A44   │   ║
  ║  cs:0158 83C32E         add    bx,002E              ▒  ss 8A5D   │   ║
  ║  cs:015B 90             nop                         ▒  cs 843C   │   ║
  ║  cs:015C 03DA           add    bx,dx                ▒  ip 0153   │   ║
  ║  cs:015E 8CCD           mov    bp,cs                ▒            │   ║
  ║  cs:0160 8BC2           mov    ax,dx                            │   ║
  ╟■▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒┼────────────┴───╢
  ║  ds:0000 CD 20 A7 8A 00 9A C0 00 ═ ºè Ü└            │  ss:0202 0004  ║
  ║  ds:0008 00 00 E4 01 32 4B AE 01   Σ2K«           │  ss:0200 0000  ║
  ║  ds:0010 32 4B 80 02 8D 45 FB 36 2KÇìE√6           │  ss:01FE 0000  ║
  ║  ds:0018 01 01 01 00 02 FF FF FF                │  ss:01FC 8A44  ║
  ║  ds:0020 FF FF FF FF FF FF FF FF                    │  ss:01FA0000  ║
  ╚═════════════════════════════════════════════════════╧═══════════════─┘

  The unpacker has copied itself to a location, which is just after the
  (not yet) unpacked code location. Singlestep one instruction ("F7"), and
  you'll hopefully see this :

  ╔═[■]═CPU 80486═══════════════════════════════════════╤═══════1═[][]═╗
  ║  cs:0000FD             std                           ax 8A44   │c=0║
  ║  cs:0001 8CDB           mov    bx,ds                ■  bx 0000   │z=1║
  ║  cs:0003 53             push   bx                   ▒  cx 0000   │s=0║
  ║  cs:0004 83C32E         add    bx,002E              ▒  dx 0185   │o=0║
  ║  cs:0007 90             nop                         ▒  si 02DE   │p=1║
  ║  cs:0008 03DA           add    bx,dx                ▒  di 018A   │a=0║
  ║  cs:000A 8CCD           mov    bp,cs                ▒  bp 0000   │i=1║
  ║  cs:000C 8BC2           mov    ax,dx                ▒  sp 01FE   │d=0║
  ║  cs:000E 80E40F         and    ah,0F                ▒  ds 843C   │   ║
  ║  cs:0011 B104           mov    cl,04                ▒  es 8A44   │   ║
  ║  cs:0013 8BF2           mov    si,dx                ▒  ss 8A5D   │   ║
  ║  cs:0015 D3E6           shl    si,cl                ▒  cs 8A44   │   ║
  ║  cs:0017 8BCE           mov    cx,si                ▒  ip 0000   │   ║
  ║  cs:0019 D1E9           shr    cx,1                 ▒            │   ║
  ║  cs:001B 4E             dec    si                               │   ║
  ╟■▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒┼────────────┴───╢
  ║  ds:0000 CD 20 A7 8A 00 9A C0 00 ═ ºè Ü└            │  ss:0206 0002  ║
  ║  ds:0008 00 00 E4 01 32 4B AE 01   Σ2K«           │  ss:0204 0003  ║
  ║  ds:0010 32 4B 80 02 8D 45 FB 36 2KÇìE√6           │  ss:0202 0004  ║
  ║  ds:0018 01 01 01 00 02 FF FF FF                │  ss:0200 0000  ║
  ║  ds:0020 FF FF FF FF FF FF FF FF                    │  ss:01FE0000  ║
  ╚═════════════════════════════════════════════════════╧═══════════════─┘

  Press "F4" at location cs:0161 (the retf instruction), found by pressing
  "PageDown" 13 - 14 times; and then "F7". That's it. You have now unpacked
  the TESTEXE program. If you have done it right, TD shows something like this :

  ╔═[■]═CPU 80486═══════════════════════════════════════╤═══════1═[][]═╗
  ║  cs:01179A00005985     call   8559:0000              ax 0000   │c=0║
  ║  cs:011C 9A0D00F784     call   84F7:000D            ■  bx 0000   │z=1║
  ║  cs:0121 9A97077B84     call   847B:0797            ▒  cx 0000   │s=0║
  ║  cs:0126 55             push   bp                   ▒  dx 0000   │o=0║
  ║  cs:0127 89E5           mov    bp,sp                ▒  si 0000   │p=1║
  ║  cs:0129 B80001         mov    ax,0100              ▒  di 0000   │a=0║
  ║  cs:012C 9ACD025985     call   8559:02CD            ▒  bp 0000   │i=1║
  ║  cs:0131 81EC0001       sub    sp,0100              ▒  sp 4000   │d=0║
  ║  cs:0135 9ACC01F784     call   84F7:01CC            ▒  ds 843C   │   ║
  ║  cs:013A BFB800         mov    di,00B8              ▒  es 843C   │   ║
  ║  cs:013D 1E             push   ds                   ▒  ss 868D   │   ║
  ║  cs:013E 57             push   di                   ▒  cs 844C   │   ║
  ║  cs:013F 8DBE00FF       lea    di,[bp-0100]         ▒  ip 0117   │   ║
  ║  cs:0143 16             push   ss                   ▒            │   ║
  ║  cs:0144 57             push   di                               │   ║
  ╟■▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒┼────────────┴───╢
  ║  ds:0000 CD 20 A7 8A 00 9A C0 00 ═ ºè Ü└            │  ss:4008 0000  ║
  ║  ds:0008 00 00 E4 01 32 4B AE 01   Σ2K«           │  ss:4006 0001  ║
  ║  ds:0010 32 4B 80 02 8D 45 FB 36 2KÇìE√6           │  ss:4004 0002  ║
  ║  ds:0018 01 01 01 00 02 FF FF FF                │  ss:4002 0001  ║
  ║  ds:0020 FF FF FF FF FF FF FF FF                    │  ss:40000002  ║
  ╚═════════════════════════════════════════════════════╧═══════════════─┘

  As you can see there are three far calls. These are direct calls. This means
  that it will make a call to a certain location in memory. If we dump the
  memory used by TESTEXE, we'll have an image of the program. But this is not
  enough to make a new exefile. This is because an exefile is not just an image
  of the memory, unlike COM files. We need a second dump from a different
  memory location. This is because of the direct calls. By comparing the two
  dumps, we can find the relocations (direct calls) needed to build a new
  exefile. Information like min/max memory usage is taken from the original
  exefiles header, but let's get on with the tutorial.

  There are serval ways to enter the values of SP, DS, ES, SS, CS and IP into
  DumpExe. Since we are using one of the supported debuggers, we can use
  the "Fill from debugger" function. This function takes register values, shown
  by the debugger, and automatically puts them into DumpExe. Start DumpExe
  by pressing the hotkey, and then "ENTER" at the "Fill from debugger"
  function. Answer "1" to whatever the values should be places in first or
  second dump file. Another way is to remember the values of SP, DS, ES, SS,
  CS and IP before pressing the hotkey, and enter the values at their
  corresponding locations in [2]. If you decide to do so, you will probably
  notice that there is no field for ES. This is because the initial value of
  ES, points to the PSP, so write the value of ES in the PSP field instead.

  It's now time to tell DumpExe the size of the memory block we want to dump.
  Use TAB until you get to [4]. Press "ENTER" at "Autodetect size". There are
  two ways of getting the size of the program. One is by using the stack, the
  other is by using PSP. 99 % of all cases, you should use "by stack". Press
  "S", and the size will be put into size field. If DumpExe somehow fails to
  calculate the right value, you have the option of entering a size that you
  decide. Press "ENTER" at "Autodetect name", and the name of the executeable
  file will be put into the name field. The last thing we have to do is to
  dump the program to a file. This is done by pressing "ENTER" at
  "Dump exe-code". DumpExe will probably do it so fast that you won't notice
  the "process message" that appears.

  Below is a picture of DumpExe after the first dump. Again, remember that
  values vary from dump to dump.

  ┌────── DumpExe v2.5 CARDWARE 1998 by BUGSY/OBSESSiON ──────┐
  │     Dos, ≥80386, Real mode, Turbo Debugger, Soft-Ice      │
  │───────── First file ────────┬───────── Second file ───────│
  │ CS   : 844C                 │ CS   : 0000                 │
  │ IP   : 0117                 │ IP   : 0000                 │
  │ SS   : 868D                 │ SS   : 0000                 │
  │ SP   : 4000                 │ SP   : 0000                 │
  │ PSP  : 843C                 │ PSP  : 0000                 │
  │ Size : 02410 (9232)         │ Size : 02410 (9232)         │
  │ Name : TESTEXE.1            │ Name : TESTEXE.2            │
  │─────────────────────────────┼─────────────────────────────│
  │      Dump exe-code          │      Dump exe-code          │
  │      Autodetect name        │      Autodetect name        │
  │      Autodetect size        │      Autodetect size        │
  │─────────────────────────────┼─────────────────────────────│
  │      Configuration          │      User screen            │
  │      Memory snapshot        │      Allocate 4Kb           │
  │      Reset menu             │      Auto config file 2     │
  │      Uninstall              │      Fill from debugger     │
  │─────────────────────────────┴─ Free 75 kb, Slack 0 kb ────│
  │                                                           │
  └───────────────── Hotkey : (U)ser screen───────────────────┘

  Press "ESC" (in DumpExe) and then "F9" in TD. The program has now terminated,
  and it's time to allocate a 4KB memory block.

  Start DumpExe again, and press enter at "Allocate 4Kb". The menu item will
  change to "Deallocate 4Kb". Press "ESC", and reload the program by pressing
  "CTRL F2". Start debugging like you did the first time. When you have reached
  the first instruction of the original code, enter all the information, like CS,
  SS.... in [3]. Autodetect size and name. Dump the code, and we are almost
  done. Again terminate your program, by pressing "F9" in TD. Start DumpExe
  again, and press "ENTER" at 'Deallocate 4Kb'. Exit your debugger.

  Run the MAKEEXE program with parameters : TESTEXE.EXE UNPACKED.EXE

  or like this : MAKEEXE.EXE TEXTEXE.EXE UNPACKED.EXE

  The MAKEEXE program compares the two memory dump and builds a new exefile
  out of the information found there and in the original exefiles header.

  After MAKEEXE has built the new exefile, the screen should look like this :

  ┌─────────────────────────────────────────────────────────┐
  │ ─┼── MakeExe v2.5 CARDWARE 1998 by BUGSY/OBSESSiON ─┼── │
  │                                                         │
  │                                                         │
  │Unpacking TESTEXE.EXE into UNPACKED.EXE                  │
  │                                                         │
  │■ Read dump info                                         │
  │■ Read exe info                                          │
  │■ Create new file                                        │
  │■ Create tempfile                                        │
  │■ Write relocations                                      │
  │■ Write zero data                                        │
  │■ Write code                                             │
  │■ Write new header                                       │
  │■ Number of relocations 00C2h                            │
  │                                                         │
  │All done!                                                │
  │                                                         │
  └─────────────────────────────────────────────────────────┘

  Try to execute UNPACKED.EXE (it is now unpacked) and see how it reacts.

  I think this would be enough for you to continue on your own.

■ How to get in touch with us

  If you have any questions about the use of these programs, feel free to
  contact us.

  You can get in touch with us by :

  Writing a letter to	: Benjamin Petersen
                          Skovburren 271
                          4700 Naestved
                          Denmark

  E-Mail us at		: _bugsy@usa.net

  World Wide Web (WWW)	: http://home.t-online.de/home/enoch

■ Distribution sites

  BBS Name : Final Fantasy BBS
  Contact  : Mr. Zenix Yang (Mr. Yang Shiuh-Phong)
  Address  : 11F-2, No. 107-3,
             Chung-Yung Road,
             Taichung, Taiwan,
             Republica Of China
  BBS/Fax  : +886 4 - 383 1006
  Voice    : +886 4 - 384 8298
  Email    : zenix@ms10.hinet.net

  BBS Name : SelF Destruction BBS
  Contact  : BloOD aNGeL
  Address  : France
  BBS      : +33.01-69893603 (near Paris) (remove the zero after +33 ??)
  Email    : bloodang@club-internet.fr

  You can always find the newest version at :
    www.simtel.net/pub/simtelnet/msdos/execomp/dmpexe??.zip
  or
    ftp.simtel.net/pub/simtelnet/msdos/execomp/dmpexe??.zip

  Where ?? is the version number without the dot. Eg. dmpexe23.zip

■ Greetings

  Our greetings goes to (A-Z order) :

  Ache
  Akhmad F. S.
  Alexey Timofeev
  alfonso
  Alif
  Anders
  Andi Jahja
  Andre Yoube
  Andrea Laforgia
  Andrew Bali
  Andrew Nagy
  arturo  villaviscencio
  Asperity-Ant
  BADBOY
  Barry
  bAUDbANDiT^KlF^HidEOUT bbS
  benchen
  Benny
  Bill Borwell
  Bob Vandersteen
  Bulent Eren
  Bunter
  CALiGO
  Carlos Miguel Viales Sol≤rzano
  Chaotic/SDS/HIT/N*P
  Che Ming
  Chi@n
  Chou Yu
  CHRIS VALLINGA
  Cinogen hellord
  Cox
  Daniel Fazekas
  Dariush Safari
  DaRk sTAlKeR 97 [UCf]
  David Bourgeois
  David Lightman
  Denid
  Dennis Misener
  DiGiTaL NiNJa
  Djuro Relic
  Dogan ozdemir
  Dr.Crow-Bar
  Dubravko
  Eddie Hulsey
  eMX
  Ernest Herrera
  Eugene
  Figge
  Franz
  Fred Bosick
  G-MaN
  G-RoM [CRaCKeR/CoDeR]
  GENLOG
  George Master
  Geraldo Figueiredo
  H.P.J. Kwakernaak
  Hackerjack! [PC]
  Hades Wu
  Hajlamász Zsolt
  Hakan Olofsson
  Heiko Laternicht
  Helge Ruddat
  Hendrix
  Horst Hackenbruch
  Ingo Fischer
  Jakub Dzierzbicki
  James Thompson
  Jan Wolters
  Jason
  Jason Sun
  JauMing Tseng
  Javier Kohen
  Jean-Stephane PERRI
  Jestrz
  JFL
  Jonas Hunziker
  Jonathan Gijsen
  Jong Tain
  jose navarro martinez
  Jung-ho Ryu
  K K KONG
  Ken Lin
  Kevin Tseng
  Kyle Mitchell
  Lam Man Leong
  Lam Tony
  LiBaTiOn
  Lord Caligo
  LordByte
  Luigi Cerasoli
  Luis Manuel P M Bento
  LuZiFeR
  M. Blanchet
  Maarten Schroeders
  Mad Scientist
  madmax!
  MaNaGeR
  Marcelo Alvarez
  Mariusz Kowalczyk aka -KoVi-
  Mark Curtis
  Mark M Janecki
  Matt Crump
  Matthias Walther
  MaX
  Mega Warrior [hAcx'97]
  merjan
  Michael Pedersen
  Michele Minorello
  Michi Frech
  mihran ekmekci
  Mike
  Ming Lei Wu
  MR WiCKED
  MS!
  Murilo Rodrigues
  Niels  de Wit
  Norberto
  Olaf Wolna
  Oliver Bartosik
  Orion / Twist
  Pasquale Abagnale
  Patrick Enoch
  Paul Simpson
  PengQing
  Philippe Ahles
  Ralf Liebold
  Random [uCf]
  Raniero Bonelli
  Raymond Yeung
  Razvan Irimia
  Richard Noordhof
  Rothen Roland
  Russell Davis
  Salvatore Meschini
  Sascha Burghause
  Scootchie McGoo
  Seth Tenenbaum
  Staven Sanders
  Steve Tolliver
  Stewart Moss
  Sune Marcher
  sUPERhENRY [pHC]
  Sven Meinhardt
  Tae- jin Bang
  TBD/FeR
  Terry Fry
  TeSdT
  Thassana Suksawat
  The Poltergeist
  tHEpHARAo^mSH [cRACKER]
  Thilo-Alexander Ginkel
  Thorben Sandner
  Thorsten Nicolay
  Tobias Sager
  Tom Liberman
  Tommy Kurniawan
  V Engineering
  VeGeTTa
  willem kloosterhuis
  William Lee
  Wilson Wen
  X Logic
  YOUNG SUNG KIM
  Zenix Yang
  zeph
  Zielu
  zLANz
  Zozo

Have fun, and remember there are still some people who DON'T take money
for making _good_ programs.

[BUGSY/OBSESSiON]
</pre>
