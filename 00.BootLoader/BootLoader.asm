[ORG 0x00]                      ; Start Address of code as 0x00
[BITS 16]                       ; 16 bit Mode

        SECTION .text           ; Define Text Section

        MOV     ax, 0xB800      ; Move to Video Memory Addr
        MOV     ds, ax          ; Copy AX Value into DS Segment Register

        MOV     byte [ 0x00 ], 'M'
        MOV     byte [ 0x01 ], 0x4A

        JMP     $               ; Infinite Loop
        TIMES   510 - ( $ - $$ ) db 0x00 ; Fill 0x00 into 0 ~ 510 Byte

        DB      0x55
        DB      0xAA            ; Fill 511, 512 as 0x55, 0xAA ( means BootSector )