[ORG 0x00]
[BITS 16]

            SECTION         .text

; Code Parts 
START:
            MOV             ax, 0x1000      ; Transfer Entry Point of Safe mode => Segment Reg value
            MOV             ds, ax          ; Set to DS Seg Regi 
            MOV             es, ax          ; Set to ES Seg Regi 

            CLI                             ; No Interrupt
            LGDT            [ GDTR ]        ; Set GDTR Data structure to Process

            ;; Go to Safe Mode
            ;; Disable Pagign, Disable Cache, Internal FPU, Disable Align Check
            ;; Enable ProtetedMode

            MOV             eax, 0x4000003B ; PG=0, CD=1, NW=0, AM=0, WP=0, NE=1, ET=1, TS=1, EM=0, MP=0, PE=1
            MOV             cr0, eax        ; Set those flags to CR0 Control Register => Into Safe Mode

            ; Change Kernal code Segment as 0x00 Base, Reset EIP Value to 0x00 Base
            ; CS Segment Selector = EIP
            JMP             dword 0x08: ( PROTECTEDMODE - $$ + 0x10000 )


;; GOTO BaseCode
[BITS 32]
PROTECTEDMODE:
            MOV             ax, 0x10        ; Safe mode kernal DS register => AX 
            MOV             ds, ax
            MOV             es, ax
            MOV             fs, ax
            MOV             gs, ax

            ; Create stack (64KB) 0x00000000 ~ 0x0000FFFF 
            MOV             ss, ax
            MOV             esp, 0xFFFE
            MOV             ebp, 0xFFFE

            ; Print successfully change into safe mode 
            PUSH            ( SWITCHSUCCESSSMESSAGE - $$ + 0x10000 )
            PUSH            2
            PUSH            0
            CALL            PRINTMESSAGE
            ADD             esp, 12

            JMP             $

; Function Parts
PRINTMESSAGE:
            PUSH            ebp
            MOV             esp, ebp
            
            PUSH            esi
            PUSH            edi
            PUSH            eax
            PUSH            ecx
            PUSH            edx 

            ; Y Coordinate
            MOV             eax, DWORD [ ebp + 12 ]
            MOV             esi, 160
            MUL             esi
            MOV             edi, eax

            ; X Coordinate 
            MOV             eax, DWORD [ ebp + 8 ]
            MOV             esi, 2
            MUL             esi
            ADD             edi, eax

            ; Print String
            MOV             esi, DWORD [ ebp + 16 ]

.MESSAGELOOP:
            MOV             cl, BYTE [ esi ]
            CMP             cl, 0
            JE              .MESSAGEEND

            MOV             BYTE [ edi + 0xB800 ], cl
            
            ADD             esi, 1
            ADD             edi, 2 

            JMP             .MESSAGELOOP

.MESSAGEEND:
            POP             edx
            POP             ecx
            POP             eax
            POP             edi
            POP             esi
            POP             ebp
            RET

;; Data Parts
ALIGN       8, DB 0             ; Align underneath Datas to 8bit

    dw      0x0000

GDTR:   
    dw      GDTEND - GDT - 1            ; Size of GDT Table
    dd      ( GDT - $$ + 0x10000 )      ; Start Address of GDT Table

GDT:
    NULLDESCRIPTOR:
        dw  0x0000
        dw  0x0000
        db  0x00
        db  0x00
        db  0x00
        db  0x00

    CODEDESCRIPTOR:
        dw  0xFFFF              ; Limit [15:0]
        dw  0x0000              ; Base  [15:0]
        db  0x00                ; Base  [23:16]
        db  0x9A                ; P=1, DPL=0, Code Segment, Execute/Read
        db  0xCF                ; G=1, D=1, L=0, Limit[19:16]
        db  0x00                ; Base [31:24]

    DATADESCRIPTOR:
        dw  0xFFFF
        dw  0x0000
        db  0x00
        db  0x92                ; P=1, DPL=0, Data Segment, Read/Write
        db  0xCF                ; G=1, D=1, L=0, Limit[19:16]
        db  0x00                ; Base [31:24]
GDTEND:

SWITCHSUCCESSSMESSAGE:      db 'Switch to Protected Mode Success', 0

TIMES   512 - ( $ - $$ )    db 0x00