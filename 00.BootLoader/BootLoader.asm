[ORG 0x00]                      ; Start Address of code as 0x00
[BITS 16]                       ; 16 bit Mode

        SECTION .text           ; Define Text Section

        JMP     0x07C0:START    ; Copy 0x07C0 in CS Segment Register / Move to Start Label

START:
        MOV     ax, 0x07C0
        MOV     ds, ax

        MOV     ax, 0xB800      ; Move to Video Memory Addr
        MOV     es, ax          ; Copy AX Value into DS Segment Register

        MOV     si, 0           ; Initial SI ( String Index ) Register

.SCREENCLEARLOOP:
        MOV     BYTE [ es:si ], 0
        MOV     BYTE [ es:si + 1 ], 0x07

        ADD     si, 2

        CMP     si, 80 * 25 * 2

        JL      .SCREENCLEARLOOP

        MOV     si, 0           ; Initial SI ( Source Index ) Register
        MOV     di, 0           ; Initial DI ( Destination Index ) Register

.MESSAGELOOP:
        MOV     cl, BYTE [ si + MESSAGE1 ]

        CMP     cl, 0
        JE      .MESSAGEEND

        MOV     BYTE [ es:di ], cl

        ADD     si, 1
        ADD     di, 2

        JMP     .MESSAGELOOP
.MESSAGEEND:
        JMP     $

MESSAGE1:       db      'Operatig System Boot Loader Start', 0

        TIMES   510 - ( $ - $$ ) db 0x00 ; Fill 0x00 into 0 ~ 510 Byte

        DB      0x55
        DB      0xAA            ; Fill 511, 512 as 0x55, 0xAA ( means BootSector )