#include "Types.h"

void kPrintString(int xCoord, int yCoord, const char* pcString);

void Main( void ) {
    kPrintString(0, 3, "C Language Kernal Started");
    while (TRUE);
}

void kPrintString(int xCoord, int yCoord, const char* pcString) {
    CHARACTER* pstScreen = ( CHARACTER* ) 0xB8000;
    int i;

    pstScreen += ( yCoord * 80 ) + xCoord;
    for (i=0; pcString[i] != 0; i++) {
        pstScreen[i].bCharacter = pcString[i];
    }
}

