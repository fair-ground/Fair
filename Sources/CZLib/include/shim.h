#ifndef zlib_shim_h 
#define zlib_shim_h

#ifdef __unix__ // not yet working on windows

#import <stdio.h>
#import <zlib.h>

// [zlib] provide 64-bit offset functions if _LARGEFILE64_SOURCE defined
#ifndef _LARGEFILE64_SOURCE
#  define _LARGEFILE64_SOURCE 1
#endif
// [zlib] change the regular functions to 64 bits if _FILE_OFFSET_BITS is 64
#ifndef _FILE_OFFSET_BITS
#  define _FILE_OFFSET_BITS 64
#endif
// [zlib] on systems without large file support, _LFS64_LARGEFILE must also be true
#ifndef _LFS64_LARGEFILE
#  define _LFS64_LARGEFILE 1
#endif

#endif

#endif
