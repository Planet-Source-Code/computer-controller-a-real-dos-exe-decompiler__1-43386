VERSION 5.00
Begin VB.Form Form1 
   AutoRedraw      =   -1  'True
   Caption         =   "Form1"
   ClientHeight    =   3195
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   4680
   LinkTopic       =   "Form1"
   ScaleHeight     =   3195
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Computer Controller
'Not All Opcodes Have been Translated

Private Type ExeHeader
     Signature  As String * 2   '2
     Length     As Integer      '4
     Size       As Integer      '6
     Table      As Integer      '8 Number of relocation entries
     CParHeader As Integer      'A  header size in paragraphs
     MinPara    As Integer      'C  Min para required in addition to exe size
     MaxPara    As Integer      'E
     SSInit     As Integer      '10
     SPInit     As Integer      '12
     Checksum   As Integer      '14
     IPReg      As Integer      '16
     CSReg      As Integer      '18
     RelocOffset As Integer     '1A
     Overlay     As Integer     '  Overlay number (normally 0000h = main program)
End Type

Private Type WinExeHdr
    Signature    As String * 2 '0
    LinkVer      As String * 1 'Byte'2
    LinkRev      As String * 1 'Byte'3
    EntryTableOffset As Integer '4
    EntryTableLength As Integer '6
    CRC          As Long '8
    FileTypeTags As Integer 'C
    ADSSegNum     As Integer 'E
    DynamHeapSize As Integer '10
    DSAddedStack  As Integer '12
    IP  As Integer '14
    CS  As Integer '16
    SP  As Integer '18
    SS  As Integer '1A
    SegTableEntryTotal As Integer '1C
    ModRefTable  As Integer '1E
    NonResNameTableBytesTotal As Integer '30
    SegTableOffset As Integer '32
    ResTableOffset As Integer '34
    ResNameTableOffset As Integer '36
    ModRefTableOffset As Integer '38
    ImpNameTableOffset As Integer '40
    NonResNameTableLoc        As Long '42
End Type

Private Type PossibleLocations
    PositionInFile As Long
    StartOfHeader  As Long
    EndOfHeader    As Long
End Type

Dim FileStart As ExeHeader, InterpretStart As Long, AWinExeHdr  As WinExeHdr
Dim BaseData As PossibleLocations, CurrData As PossibleLocations

Dim Byte1 As String * 1, Byte2 As String * 1
Dim IncDec$(0 To 3), RegSet$(0 To 2, 0 To 7), Float$(0 To 7)
Sub Form_load()
IncDec$(0) = "INC"
IncDec$(1) = "DEC"
IncDec$(2) = "PUSH"
IncDec$(3) = "POP"

Print "Filename to open:"
a$ = InputBox("What file should I open?" & vbCrLf & "Reminder - Do not write "".exe"" at the end of the file name")

Open a$ & ".exe" For Binary As #1

Open a$ & ".asm" For Output As #2
filethingya = a$ & ".asm"
Seek 1, 1
Get 1, , FileStart

'Get if windows prog
Seek 1, &H3C + 1
Get 1, , WinHdrLoc&
Seek 1, WinHdrLoc& + 1
Get 1, , AWinExeHdr

FIleType = ExeFileTypeDetermination(FileStart.Signature, AWinExeHdr.Signature)
If FIleType > 1 Then GoTo WinFileOptions
If FIleType = 0 Then GoTo ComFile
'End get
OrdinaryEXE:
InterpretStart = Val("&H" + Hex$(FileStart.CSReg) + "0&") + Val("&H" + Hex$(FileStart.IPReg) + "&") + (FileStart.CParHeader * 16&)
ComFile:
Seek 1, InterpretStart + 1
Do
  Get 1, , Byte1
  Select Case Asc(Byte1)
         Case 0, 1, 2, 3
              ByteOri% = Asc(Byte1)
              Call Trap1("ADD ", ByteOri, 0)
         Case 4
              Get 1, , Byte1
              Print #2, "MOV   AL, " + Hex$(Asc(Byte1))
         Case 5
              Get 1, , integ%
              Print #2, "ADD   AX, " + Hex$(integ)
        Case 6
             Print #2, "PUSH ES"
        Case 7
             Print #2, "POP  ES"
        Case 8, 9, 10, 11
             ByteOri% = Asc(Byte1)
             Call Trap1("OR  ", ByteOri, 8)
        Case 12
             Get 1, , Byte1
             Print #2, "OR  AL, " + Hex$(Asc(Byte1))
        Case 13
             Get 1, , integ%
             Print #2, "OR   AX, " + Hex$(integ)
        Case 14
             Print #2, "PUSH CS"
        Case 15
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case 0
                         Get 1, , Byte1
                    Case Else
             End Select
        Case 22
             Print #2, "PUSH SS"
        Case &H1F
             Print #2, "POP DS"
        Case &H2B
              Get 1, , Byte1
              Select Case Asc(Byte1)
                     Case &HF7
                          Print #2, "SUB SI,DI"
                     Case Else
                     Print #2, "2B " + Hex$(Asc(Byte1))
              End Select
        Case &H33
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &HC0
                         Print #2, "XOR AX, AX"
                    Case &HED
                         Print #2, "XOR BP, BP"
                    Case &HFF
                         Print #2, "XOR DI, DI"
                    Case Else
                         Print #2, "33 " + Hex$(Asc(Byte1))
             End Select
        Case &H36
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &HC7
                         Get 1, , Byte1
                         Select Case Asc(Byte1)
                                Case &H6
                                     Get 1, , integ%
                                     Get 1, , Integ2%
                                     Print #2, "MOV   SS:[" + Hex$(integ%) + "], " + Hex$(Integ2%)
                                Case Else
                                     Print #2, "36 C7 " + Hex$(Asc(Byte1))
                         End Select
                    Case Else
                         Print #2, "36 " + Hex$(Asc(Byte1))
             End Select
        Case &H3C
             Get 1, , Byte1
             Print #2, "CMP  AL, " + Hex$(Asc(Byte1))
        Case &H3D
             Get 1, , integ%
             Print #2, "CMP  AX, " + LongHex(integ, 4)
        'CASE 3E: Too Long and torturous to try to implement currently
        Case &H3F
             Print #2, "AAS"
        Case &H40 To &H5F
             Temp% = Map1D22DX(Asc(Byte1) - &H40, 8)
             Print #2, IncDec$(Map1D22DY(Asc(Byte1) - &H40, Temp%, 8)) + "  " + RegSet$(1, Temp%)
        'CASE &H65 Not Known as a command
        Case &H73
             Get 1, , Byte1
             Print #2, "JNB  " + Hex$(Asc(Byte1)) + ";Relative jump"
         Case &H75
             Get 1, , Byte1
             Print #2, "JNZ  " + Hex$(Asc(Byte1)) + ";Relative jump"
        Case &H77
             Get 1, , Byte1
             Print #2, "JA   " + Hex$(Asc(Byte1)) + ";Relative jump"
        Case &H81
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &HFE
                         Get 1, , integ%
                         Print #2, "CMP SI, " + Hex$(integ%)
                    Case &HC4
                         Get 1, , integ%
                         Print #2, "ADD SP, " + Hex$(integ%)
                    Case Else
                    Print #2, "81 " + Hex$(Asc(Byte1))
             End Select
        Case &H83
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &HC3
                         Get 1, , Byte1
                         Print #2, "ADD BX, " + Hex$(Asc(Byte1)) + ";Signed Byte"
                    Case Else
                         Print #2, "83 " + Hex$(Asc(Byte1))
             End Select
        Case &H89
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &H3E
                         Get 1, , integ%
                         Print #2, "MOV  [" + Hex$(integ%) + "], DI"
                    Case Else
                         Print #2, "89 " + Hex$(Asc(Byte1))
             End Select
        Case &H8B
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &H36
                         Get 1, , integ%
                         Print #2, "MOV SI, [" + Hex$(integ%) + "]"
                    Case &HC8
                         Print #2, "MOV CX, AX"
                    Case &HE3
                         Print #2, "MOV SP, BX"
                    Case &HE8
                         Print #2, "MOV BP, AX"
                    Case Else

                         Print #2, "8B " + Hex$(Asc(Byte1))
             End Select
        Case &H8C
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &HDA
                         Print #2, "MOV  DX, DS"
                    Case &HC8
                         Print #2, "MOV  AX, CS"
                    Case &HC0
                         Print #2, "MOV  AX, ES"
                    Case Else
                         Print #2, "8C " + Hex$(Asc(Byte1))
             End Select
        Case &H8E
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &HD7
                        Print #2, "MOV SS, DI"
                    Case &HC0
                        Print #2, "MOV ES, AX"
                    Case Else
                        Print #2, "8E " + Hex$(Asc(Byte1))
             End Select
        Case &H90
             Print #2, "NOP"
        Case &H98
             Print #2, "CBW"
        Case &HA0
             Get 1, , integ%
             Print #2, "MOV  AL,  [" + LongHex$(integ%, 4) + "]"
        Case &HA1
             Get 1, , integ%
             Print #2, "MOV  AX, [" + LongHex$(integ%, 4) + "]"
        Case &HA2
             Get 1, , integ%
             Print #2, "MOV  [" + LongHex$(integ%, 4) + "], AL"
        Case &HA3
             Get 1, , integ%
             Print #2, "MOV  [" + LongHex$(integ%, 4) + "], AX"
        Case &HB2
             Get 1, , Byte1
             Print #2, "MOV  DL, " + Hex$(Asc(Byte1))
             AX% = Asc("&H" + Hex$(Asc(Byte1)) + LongHex(AX%, 2))
        Case &HB4
             Get 1, , Byte1
             Print #2, "MOV  AH," + Hex$(Asc(Byte1))
             AX% = Asc("&H" + Hex$(Asc(Byte1)) + LongHex(AX%, 2))
        Case &HB6
             Get 1, , Byte1
             Print #2, "MOV  DH, " + Hex$(Asc(Byte1))
             AX% = Asc("&H" + Hex$(Asc(Byte1)) + LongHex(AX%, 2))
        Case &HB7
             Get 1, , Byte1
             Print #2, "MOV  BH, " + Hex$(Asc(Byte1))
             AX% = Asc("&H" + Hex$(Asc(Byte1)) + LongHex(AX%, 2))
        Case &HB8
             Get 1, , integ%
             Print #2, "MOV  AX, " + Hex$(integ%)
             AX% = integ%
        Case &HB9
             Get 1, , integ%
             Print #2, "MOV  CX, " + Hex$(integ%)
             AX% = integ%
        Case &HBA
             Get 1, , integ%
             Print #2, "MOV  DX, " + Hex$(integ%)
             DX% = integ%
        Case &HBB
             Get 1, , integ%
             Print #2, "MOV  BX, " + Hex$(integ%)
             BX% = integ%
        Case &HBC
             Get 1, , integ%
             Print #2, "MOV  SP, " + Hex$(integ%)
             DX% = integ%
        Case &HBD
             Get 1, , integ%
             Print #2, "MOV  BP, " + Hex$(integ%)
             DX% = integ%
        Case &HBE
            Get 1, , integ%
            Print #2, "MOV  SI, " + Hex$(integ%)
            SI% = integ%
        Case &HBF
            Get 1, , integ%
            Print #2, "MOV  DI, " + Hex$(integ%)
            DI% = integ%
        Case &HC7
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &H6
                        Get 1, , integ%
                        Print #2, "MOV   [" + Hex$(integ%);
                        Get 1, , integ%
                        Print #2, "], " + Hex$(integ%)
                    Case Else
                        Print #2, "C7 " + Hex$(Asc(Byte1))
             End Select
        Case &HCD
             Get 1, , Byte1
             Print #2, "INT " + Hex$(Asc(Byte1))
        Case &HCE
             Print #2, "INTO"
        Case &HD1
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &HEB
                         Print #2, "SHR   BX, 1"
                    Case Else
             End Select
        Case &HE9
             Get 1, , integ%
             Print #2, "JMP  " + LongHex(integ%, 4)
        Case &HF2
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &HAE
                         Print #2, "REPNE  SCASB"
                     Case Else
                     Print #2, "F2 " + Hex$(Asc(Byte1))
             End Select
        Case &HF3
             Get 1, , Byte1
             Select Case Asc(Byte1)
                    Case &HA4
                         Print #2, "REPZ MOVSB"
                    Case &HA6
                         Print #2, "REPZ CMPSB"
                    Case Else
                    Print #2, "F3 " + Hex$(Asc(Byte1))
             End Select
        Case &HFA
             Print #2, "CLI"
        Case &HFB
             Print #2, "STI"
        Case &HFC
             Print #2, "CLD"
        Case Else
            Print #2, Hex$(Asc(Byte1))
 End Select
Loop Until EOF(1)
MsgBox "Done. You can see the decompiled asm in file " & filethingya
End
WinFileOptions:
FailedReturn1:
Key$ = InputBox("Windows .EXE File Options" & vbCrLf & "1. Disassemble as if ordinary .EXE File" & vbCrLf & "2. Exit Program")
      Select Case Key$
'        Case "1"
'             GoSub MDS
        Case "1"
             GoTo OrdinaryEXE
        Case "2"
             End
        Case Else
             GoTo FailedReturn1
      End Select
'For some other day
'MDS:
'  Seek #1, AWinExeHdr.NonResNameTableLoc + 1
'  Print Hex$(AWinExeHdr.NonResNameTableLoc)
'  Temp% = 0
'  Print AWinExeHdr.NonResNameTableBytesTotal
'  Do
'    Get #1, , Byte1
'    a$ = Input$(Asc(Byte1), 1)
'    Print Asc(Byte1)
'    Print a$
'    Temp% = Temp% + 1 + Len(a$)
'    If Temp% >= AWinExeHdr.NonResNameTableBytesTotal Then Exit Do
'  Loop
End Sub

Function ExeFileTypeDetermination(EH As String, NH As String)
    Temp% = 0
    If EH = "MZ" Then Temp% = Temp% Or 1
    If NH = "NE" Then Temp% = Temp% Or 2
    If NH = "PE" Then Temp% = Temp% Or 4
    ExeFileTypeDetermination = Temp%
End Function

Function ExtStrip$(Filename$)
    Temp% = InStr(Filename$, ".")
    If Temp% = 0 Then
       ExtStrip$ = Filename$
    Else
      ExtStrip$ = Left$(Filename$, Temp% - 1)
    End If
End Function

Function HEXSignedByte$(Value%)
    If Value And &H80 Then
       HEXSignedByte$ = "- " + Hex$(256 - Value%)
    Else
       HEXSignedByte$ = "+ " + Hex$(Value%)
    End If
End Function

Function LongHex$(Value%, Length%)
    TString$ = Hex$(Value%)
    Temp% = Len(TString$)
    Select Case Temp%
           Case 0
           LongHex$ = String$(Length%, "0")
           Case Is >= Length%
           LongHex$ = Right$(TString$, 3)
           Case Is < Length%
                LongHex$ = String$(Length - Temp%, "0") + TString$
           Case Else
           Print "Error In Subroutine LongHex, Value="; Value%; "Length="; Length%
    End Select
End Function

Function Map1D22DX(Value1D, TotalX)
    Map1D22DX = Value1D Mod TotalX
End Function

Function Map1D22DY(Value1D, X, TotalX)
    Map1D22DY = (Value1D - X) / TotalX
End Function

Private Sub NEHdrNameValue(DStr As WinExeHdr)
    Print "Signature Word:" + DStr.Signature
    Print "Linker Version:"; Asc(DStr.LinkVer); "."; Asc(DStr.LinkRev)
    Print "Entry Table Offset:"; DStr.EntryTableOffset

End Sub

Function SignedByte%(Value%)
    If Value And &H80 Then
       SignedByte1 = 256 - Value%
    Else
       SignedByte1 = Value%
    End If
End Function

Sub Trap1(Inst$, InstVal%, InstBase%)
    RegByte% = (InstVal% - InstBase%) Mod 2
    Get 1, , Byte1
    ByteVal% = Asc(Byte1)
    Select Case ByteVal%
           Case 0 To 5, 7 To 13, 15 To 21, 23 To 29, 31 To 37, 39 To 45, 47 To 53, 55 To 61, 63
                Operand1$ = "[" + RegSet$(2, ByteVal% Mod 8) + "]"
                Operand2$ = RegSet$(RegByte%, Map1D22DY(ByteVal%, ByteVal% Mod 8, 8))
           Case 6, 14, 22, 30, 38, 46, 54, 62
                'These Replace what would have been a [BP] Instruction
                Get 1, , integ%
                Operand1$ = "[" + Hex$(integ%) + "]"
                Operand2$ = RegSet$(RegByte%, Map1D22DY(ByteVal%, ByteVal% Mod 8, 8))
           Case 64 To 127 'The whole thing all over except with BP and a Byte
                Get 1, , Byte2
                Operand1$ = "[" + RegSet$(2, ByteVal% Mod 8) + HEXSignedByte(Asc(Byte2)) + "]"
                Operand2$ = RegSet$(RegByte%, Map1D22DY(ByteVal%, ByteVal% Mod 8, 8) - 8)
           Case 128 To 191 'The whole thing all over except with BP and an Integer
                Get 1, , integ%
                Operand1$ = "[" + RegSet$(2, ByteVal% Mod 8) + " + " + Hex$(integ%) + "]"
                Operand2$ = RegSet$(RegByte%, Map1D22DY(ByteVal%, ByteVal% Mod 8, 8) - 16)
           Case 191 To 255 ' A bunch of selves
                Operand1$ = RegSet$(RegByte%, ByteVal% Mod 8)
                Operand2$ = RegSet$(RegByte%, Map1D22DY(ByteVal%, ByteVal% Mod 8, 8) - 24)
           Case Else
                Operand1$ = " " + Hex$(Asc(Byte1))
    End Select
    
    If Left$(Operand1$, 1) = " " Then
        Print LongHex(InstVal%, 2) + Operand1$
    Else
        If InstVal% - InstBase% > 1 Then
        sdfg = Operand1$
        Operand1$ = Operand2$
        Operand2$ = sdfg
        End If
        Print #2, Inst$ + Operand1$ + ", " + Operand2$
    End If
End Sub

Sub Trap2(Inst$(), InstVal%, InstBase%)
    ByteBase% = (InstVal% - InstBase%) Mod 2
    Get 1, , Byte1
    ByteVal% = Asc(Byte1)
    Select Case ByteVal%
           Case 0 To 5, 7 To 13, 15 To 21, 23 To 29, 31 To 37, 39 To 45, 47 To 53, 55 To 61, 63
                Operand1$ = "[" + RegSet$(3, ByteVal% Mod 8) + "]"
           Case 6, 14, 22, 30, 38, 46, 54, 62
                'These Replace what would have been a [BP] Instruction
                Get 1, , integ%
                Operand1$ = "[" + Hex$(integ%) + "]"
           Case 64 To 127
                Get 1, , Byte2
                Operand1$ = "[" + RegSet$(2, ByteVal% Mod 8) + HEXSignedByte(Asc(Byte2)) + "]"
           Case 128 To 191
                Get 1, , integ%
                Operand1$ = "[" + RegSet$(3, ByteVal% Mod 8) + " + " + Hex$(integ%) + "]"
           Case 191 To 255
                Operand1$ = RegSet$(ByteBase%, ByteVal% Mod 8)
           Case Else
                Operand1$ = " " + Hex$(ByteVal%)
    End Select
    If Left$(Operand1$, 1) = " " Then
        Print LongHex(InstVal%, 2) + Operand1$
    Else
        If InstVal% - InstBase% > 1 Then SWAP Operand1$, Operand2$
        Print #2, "ADD " + Operand1$ + ", " + Operand2$
    End If
End Sub
