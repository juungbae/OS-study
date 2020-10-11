[ORG 0x00]                      ; Start Address of code as 0x00
[BITS 16]                       ; 16 bit Mode

        SECTION .text           ; Define Text Section

        JMP     0x07C0:START    ; Copy 0x07C0 in CS Segment Register / Move to Start Label

TOTALSECTORCOUNT: dw 1          ; Size of Operating System without bootloader

START:
        MOV     ax, 0x07C0      ; Set bootloader's start address to Segment Register Value
        MOV     ds, ax                
        MOV     ax, 0xB800      ; Move to Video Memory Addr
        MOV     es, ax          ; Copy AX Value into DS Segment Register

        ; Create Stack On area 0x0000:0000 ~ 0x0000:FFFF
        MOV     ax, 0x0000      ; start address of stack segment into segment register value
        MOV     ss, ax          ; Stack Segment register
        MOV     sp, 0xFFFE      ; Stack Pointer register
        MOV     bp, 0xFFFE      ; Stack base register

        MOV     si, 0           ; Initial SI ( String Index ) Register

.SCREENCLEARLOOP:
        MOV     BYTE [ es:si ], 0
        MOV     BYTE [ es:si + 1 ], 0x07

        ADD     si, 2

        CMP     si, 80 * 25 * 2

        JL      .SCREENCLEARLOOP

; Print Start message
        PUSH    BOOTLOADERSTARTMESSAGE
        PUSH    0                       ; Y coordinate
        PUSH    0                       ; X coordinate 
        CALL    PRINTMESSAGE            ; Call PrintMessage Function
        ADD     sp, 6                   ; Remove Add parameters

; Print OS Loading Message
        PUSH    IMAGELOADINGMESSAGE    
        PUSH    1                       ; Y coordinate
        PUSH    0                       ; X coordinate
        CALL    PRINTMESSAGE            
        ADD     sp, 6

; Start Disk Reset
RESETDISK:                              ; Call BIOS Reset Function    
        MOV     ax, 0                   ; Service Number 0
        MOV     dl, 0                   ; Drive Number 0 (Floppy)
        INT     0x13                    ; Whats it?
        JC      HANDLEDISKERROR         ; If error occured, move to Error Handler

; Read Sector from Disk (ES:BX)
        MOV     si, 0x1000              ; Change Address (0x10000) to Segment Register Value
        MOV     es, si
        MOV     bx, 0x0000              ; 0x1000:0000

        MOV     di, word [ TOTALSECTORCOUNT ]  ; Set Sector number of OS Image to copy

; Read Disk
READDATA:  
        ; Check read all sector
        CMP     di, 0                   ; Compare between left sectors to read and 0
        JE      READEND                 ; if Sectors number == 0 => End
        SUB     di, 0x1                 ; left sectors - 1

        ; Call Bios Read Function
        MOV     ah, 0x02                ; BIOS Service No.2 ( Read Sector )
        MOV     al, 0x1                 ; Read One sector
        MOV     ch, byte [ TRACKNUMBER ]  ; Set track to read
        MOV     cl, byte [ SECTORNUMBER ] ; Set Sector to read
        MOV     dh, byte [ HEADNUMBER ] ; Set head to read
        MOV     dl, 0x00                ; Set drive number ( floppy = 0 )
        INT     0x13                    
        JC      HANDLEDISKERROR 


;; Calculate Address to copy, track,, head, sector address
        ADD     si, 0x0020              ; 512 ( bytes we read )
        MOV     es, si                  ; + 512 ( 1 Sector )

        MOV     al, byte [ SECTORNUMBER ]
        ADD     al, 0x01
        MOV     byte [ SECTORNUMBER ], al 
        CMP     al, 19
        JL      READDATA 

        XOR     byte [ HEADNUMBER ], 0x01
        MOV     byte [ SECTORNUMBER ], 0x01

        CMP     byte [ HEADNUMBER ], 0x00
        JNE     READDATA

        ADD     byte [ TRACKNUMBER ], 0x01
        JMP     READDATA

READEND:
        push    IMAGELOADCOMPLETEMESSAGE
        push    1                       ; Y coordinate
        push    20                      ; X coordinate 
        call    PRINTMESSAGE
        add     sp, 6

        ; Execute loaded Virtual OS
        JMP     0x1000:0x0000

;; Function code sector
HANDLEDISKERROR:
        PUSH    DISKERRORMESSAGE        ; Add Error message into stack
        PUSH    1                       ; Y coordinate
        PUSH    0                       ; X coordinate
        call    PRINTMESSAGE            ; call PRINTMESSAGE function

        JMP     $

;; Print message
; parameters: x coord, y coord, message

PRINTMESSAGE:
        PUSH    bp                      ; Add base point register into stack
        MOV     bp, sp                  ; Set Base-point register as Point register
                                        ; Access parameter using BP 

        PUSH    es                      ; Insert ES ~ DX into stack
        PUSH    si
        PUSH    di
        PUSH    ax
        PUSH    cx
        PUSH    dx

        ; Set Video mode
        MOV     ax, 0xB800
        MOV     es, ax

        ; Calculate Line address using y coord
        MOV     ax, word [ bp + 6 ]         ; args 2 ( Y coord )
        MOV     si, 160                 ; Bytes of One line
        MUL     si                      ; if mul has one operand, it means ax *= operand
        MOV     di, ax                  ; Set Y address

        ; Calculate x coord
        MOV     ax, word [ bp + 4 ]         ; args 1 ( X coord )
        MOV     si, 2                     
        MUL     si
        ADD     di, ax

        ; Set target string address
        MOV     si, word [ bp + 8 ]

.MESSAGELOOP:
        MOV     cl, byte [ si ]           ; Copy one byte into cl register ( low of CX )

        CMP     cl, 0                   
        JE      .MESSAGEEND             ; End loop if message is end

        MOV     byte[ es:di ], cl         ; if loop not end, print character on 0xB8000:di
        
        ADD     si, 1                   ; Move character index + 1
        ADD     di, 2                   ; Move Video memory index + 2

        JMP     .MESSAGELOOP

.MESSAGEEND:
        POP     dx                      ; Make register back                       
        POP     cx
        POP     ax
        POP     di
        POP     si
        POP     es
        POP     bp
        RET

;; Data Area 

; Messages
BOOTLOADERSTARTMESSAGE:         db 'Operatig System Boot Loader Start', 0
DISKERRORMESSAGE:               db 'Disk Error Occured', 0
IMAGELOADINGMESSAGE:            db 'OS Image Loading...', 0
IMAGELOADCOMPLETEMESSAGE:       db 'Image Load Complete', 0

; Variable use for read disk
SECTORNUMBER:                   db 0x02         ; Sector Number where Image starts  
HEADNUMBER:                     db 0x00         ; Head number where Image starts
TRACKNUMBER:                    db 0x00         ; Track number where Image Starts


;; Fill Other data as 0, Except Last 2 bytes

        TIMES   510 - ( $ - $$ ) db 0x00 ; Fill 0x00 into 0 ~ 510 Byte

        DB      0x55
        DB      0xAA            ; Fill 511, 512 as 0x55, 0xAA ( means BootSector )
