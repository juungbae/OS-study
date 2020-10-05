[ORG 0x00]
[BITS 16]

        SECTION     .text

        JMP         0x1000:START

SECTORCOUNT:    dw  0x0000
TOTALSECTORCOUNT    equ 1024    ; All sector of VirtualOS 
                                ; Maximum 1152 Sector (0x90000 byte)

START:
        MOV     ax, cs
        MOV     ds, ax
        MOV     ax, 0xB800

        MOV     es, ax

        %assign i   0
        %rep TOTALSECTORCOUNT
            %assign i   i + 1

            MOV ax, 2       ; Means 1 word ( 2 byte )

            MUL word [ SECTORCOUNT ]    ; Sector * 2
            MOV si, ax

            MOV byte [ es:si + ( 160 * 2 ) ], '0' + ( i % 10 )
            ADD word [ SECTORCOUNT ], 1 ; + One sector

            %if i == TOTALSECTORCOUNT
                JMP $
            %else 
                JMP ( 0x1000 + i * 0x20 ): 0x0000
            %endif

            TIMES ( 512 - ( $ - $$ ) % 512 )    db 0x00

        %endrep

