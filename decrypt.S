#ifndef MYDECRYPT_S
#else
// version 1.0 11/12/2022
    .arch armv6
    .arm
    .fpu vfp
    .syntax unified

    #include "cipher.h"

    .text     // start of text segment

    //////////////////////////////////////////////////
    // int decrypt(char *iobuf, char *bookbuf, int cnt)
    // decrypts iobuf using bookbuf; result in iobuf
    //////////////////////////////////////////////////
    .global decrypt
    .type   decrypt, %function
    .equ    FP_OFF, 28

decrypt:
    push    {r4-r9, fp, lr}
    add     fp, sp, FP_OFF
    // do not alter anything above this line
    // r0 contains char *iobuf
    // r1 contains char *bookbuf
    // r2 contains cnt
    // r3 is ok to use
    // r4-r9 preserved registers are ok to use

    cmp     r2, 0               // if buffer empty we are done
    ble     .Ldone
    mov	    r3, 0               
    #define BITS     8          // num of bits in a byte
    #define INCR     1          // for increment
    #define ZERO     0          // starting value for registers

.Lloop:
    cmp     r3, r2              
    bge     .Ldone               
    ldrb    r4, [r0, r3]        
    ldrb    r8, [r1, r3]        
    eor     r4, r4, r8          
    mov     r5, ZERO               
    mov     r6, ZERO               

.Lwhile:
    lsl     r5, r5, INCR           
    and     r7, r4, INCR          
    orr     r5, r5, r7          
    lsr     r4, r4, INCR          
    add     r6, r6, INCR          
    cmp     r6, BITS            
    blt     .Lwhile             

.Lloopend:
    strb    r5, [r0, r3]        
    add     r3, r3, INCR          
    b       .Lloop              

    // do not alter anything below this line
.Ldone:
    mov     r0, r2              // return cnt processed
    sub     sp, fp, FP_OFF
    pop     {r4-r9, fp, lr}
    bx      lr

    .size decrypt, (. - decrypt)
    .section .note.GNU-stack,"",%progbits
.end
#endif
