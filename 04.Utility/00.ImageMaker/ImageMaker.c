//
// Created by 배주웅 on 2020/11/03.
//
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <io.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <error.h>

#define BYTESOFSECTOR 512

// Define functions
int AdjustInSectorSize( int iFd, int iSourceSize );
void WriteKernelInformation( int iTargetFd, int iKernelSectorCount );
int CopyFile( int iSourceFd, int iTargetFd );

// Main function
int main(int argc, char *argv[]) {
    int iSourceFd;
    int iTargetFd;
    int iBootLoaderSize;
    int iKernel32SectorCount;
    int iSourceSize;

    // Check command-line option
    if (argc < 3) {
        fprintf(stderr, "[Error] imagemaker BootLoader_Image Kernel_Image");
        exit(-1);
    }

    // Create Disk.img file
    if ( iTargetFd = open("Disk.img", O_RDWR | O_CREAT | O_TRUNC | O_BINARY, S_IREAD | S_IWRITE)) == -1){
        fprint(stderr, "[Error] Disk.img open fail.\n");
        exit(-1);
    }

    // BootLoader file => Disk Image File
    printf("[Info] Copy boot loader to image file\n");
    if((iSourceFd = open(argv[1], O_RDONLY | O_BINARY)) == -1 ) {
        fprintf(stderr, "[Error] %s oepn fail\n", argv[1]);
        exit(-1);
    }
    
    iSourceSize = CopyFile(iSourceFd, iTargetFd);
    close(iSourceFd);
    
    // Fit File size as 512 ~> Fill extra part to 0x00
    iBootLoaderSize = AdjustInSectorSize(iTargetFd, iSourceSize);
    printf("[Info] %s size = [%d] and sector count [%d]\n", argv[1], iSourceSize, iBootLoaderSize);
    
    // 32bit Kernel File => Disk Image File
    printf("[Info] Copy protected mode kernel to image file\n");
    if((iSourceFd = open(argv[2], O_RDONLY | O_BINARY)) == -1) {
        fprintf(stderr, "[Error] %s open fail\n", argv[2]);
        exit(-1);
    }
    
    iSourceSize = CopyFile(iSourceFd, iTargetFd);
    close(iSourceFd);
    
    // Fit File size as 512 ~> Fill extra part to 0x00
    iKernel32SectorCount = AdjustInSectorSize(iTargetFd, iSourceSize);
    printf("[Info] %s size = [%d] and sector count = [%d]\n",
           argv[2], iSourceSize, iKernel32SectorCount);
    
    // Update kernel information into Disk image
    printf("[Info] Start to write kernel information\n");
    
    // Write Kernel information. Start at 5th byte of bootsector
    WriteKernelInformation(iTargetFd, iKernel32SectorCount);
    printf("[Info] Image file create complete\n");
    
    close(iTargetFd);
    return 0;
}

// Fill next 512th bit into 0x00
int AdjustInSectorSize(int iFd, int iSourceSize) {
    int i;
    int iAdjustSizeToSector;
    char cCh;
    int iSectorCount;
    
    iAdjustSizeToSector = iSourceSize % BYTESOFSECTOR;
    cCh = 0x00;
    
    if(iAdjustSizeToSector != 0) {
        iAdjustSizeToSector = 512 - iAdjustSizeToSector;
        
        printf("[Info] File size [%lu] and fill [%u] byte\n", iSourceSize, iAdjustSizeToSector);
        
        for (i=0; i< iAdjustSizeToSector; i++) {
            write(iFd, &cCh, 1);
        }
    } else {
        printf("[Info] File size aligned 512 byte\n");
    }
    
    iSectorCount = (iSectorCount + iAdjustSizeToSector) / BYTESOFSECTOR;
    return iSectorCount;
}

// Insert Kernel Information to Bootloader
void WriteKernelInformation(int iTargetFd, int iKernelSectorCount) {
    unsigned short usData;
    long lPosition;
    
    // 5 byte offset of file means kernels sector
    lPosition = lseek(iTargetFd, (off_t)5, SEEK_SET);
    if(lPosition == -1) {
        fprintf(stderr, "lseek fail. Return value = %d, errno = %d, %d\n", lPosition, errno, SEEK_SET);
        exit(-1);
    }
    
    usData = ( unsigned short ) iKernelSectorCount;
    write(iTargetFd, &usData, 2);
    
    printf("[Info] Total sector count except boot loader [%d]\n", iKernelSectorCount);
}

// Copy Source FD => Target FD, return size of it;
int CopyFile(int iSourceFd, int iTargetFd) {
    int iSourceFileSize;
    int iRead;
    int iWrite;
    int vcBuffer[BYTESOFSECTOR];
    
    iSourceFileSize = 0;
    while(1) {
        iRead = read(iSourceFd, vcBuffer, sizeof(vcBuffer));
        iWrite = write(iTargetFd, vcBuffer, iRead);
        
        if(iRead != iWrite) {
            fprintf(stderr, "[Error] iRead != iWrite.. \n");
            exit(-1);
        }
        iSourceFileSize += iRead;
        
        if(iRead != sizeof(vcBuffer)) break;
    }
    
    return iSourceFileSize;
}
