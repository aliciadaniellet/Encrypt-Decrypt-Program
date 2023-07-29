// version 1.0 11/12/2022
#include <stdio.h>
#include "cipher.h"

#ifdef MYDECRYPT_C
TODO("using Cdecrypt.c");

int
decrypt(char *iobuf, char *bookbuf, int cnt)
{

    //loop through each byte in iobuf
    for (int i = 0; i < cnt; i++) {
	    unsigned int currbyte = *(iobuf + i);
	    unsigned int book = *(bookbuf + i);
	    currbyte = currbyte ^ book;
	    unsigned int reverse = 0;
	    int numbits = 0;
	    //reverse the bits in one byte
	    while (numbits < 8) {
		    reverse <<= 1;
		    reverse = reverse | (currbyte & 1);
		    currbyte >>= 1;
		    numbits++;
	    }
	    *(iobuf + i) = reverse;
    }
    return cnt;
}

#elif defined MYDECRYPT_S
TODO("using decrypt.S");
#else
TODO("using solution decrypt");
#endif
