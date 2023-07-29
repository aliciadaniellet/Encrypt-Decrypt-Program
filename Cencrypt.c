// version 1.0 11/12/2022
#include <stdio.h>
#include "cipher.h"

#ifdef MYENCRYPT_C
TODO("using Cencrypt.c");

int
encrypt(char *iobuf, char *bookbuf, int cnt)
{

    //loop through each byte in iobuf
    for (int i = 0; i < cnt; i++){
	    unsigned int currbyte = *(iobuf + i);
	    unsigned int reverse = 0;
	    int numbits = 0;
	    //reverse the bits in one byte
	    while (numbits < 8)
	    {
		    reverse <<= 1;
		    reverse = reverse | (currbyte & 1);
		    currbyte >>= 1;
		    numbits++;
	    }
	    //XORing the key
	    unsigned int book = *(bookbuf + i);
	    *(iobuf + i) = reverse ^ book;
    }
    return cnt;
}

#elif defined MYENCRYPT_S
TODO("using encrypt.S");
#else
TODO("using solution encrypt");
#endif
