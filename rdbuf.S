#ifndef MYRDBUF_S
#else
// version 1.0 10/12/2022 //
    .arch   armv6
    .arm
    .fpu    vfp
    .syntax unified

    // global constants
    #include "cipher.h"

    .extern fread
    .extern feof
    .extern ferror
    .text

    // int rdbuf(r0=FILE *in, r1=FILE *fpbook, r2=int cnt, r3=char *iobuf, 
    //            on the stack at ARG5 offset=char *bookbuf)
    // returns number of bytes read EXIT_FAIL otherwise
    // you can change or remove any comments in this file

    .type   rdbuf, %function
    .global rdbuf
    .equ    ARG5,  4 
    .equ    FP_OFF, 28
 
rdbuf:
    push    {r4-r9, fp, lr}
    add     fp, sp, FP_OFF

    // save the register args (r0-r3) into preserved registers
    // as there are many function call
    mov     r4, r0  // in
    mov     r5, r1  // fpbook
    mov     r6, r2  // cnt
    mov     r7, r3  // iobuf
    
    // check for end of file feof(in)
    // if r0 is not zero at EOF, set r0 to 0 and return
    bl      feof
    cmp     r0, 0
    bne     .Lsuccess

    // otherwise check for read errors
    // check for error ferror(in)
    // if r0 is zero, no errors, do the reads
    // if r0 is not zero, set r0 to EXIT_FAIL and return
    mov     r0, r4
    bl      ferror
    cmp     r0, 0
    bne     .Lfail
    
    // bytes = fread(r0=iobuf, r1=1, r2=cnt, r3=in)
    // save bytes so we can check that we read same bytes from bookfile
    // if r0 <= 0 return with r0 = 0
    mov     r0, r7
    mov     r1, 1
    mov     r2, r6
    mov     r3, r4
    bl      fread
    cmp     r0, 0
    ble     .Lsuccess
    mov     r8, r0   

    // r0 = fread(r0=bookbuf, r1=1, r2=bytes, r3=fpbook)
    // the pointer to bookbuf is passed on the stack so
    // you need to do a ldr from ARG5 offset to get the address
    // to pass to the fread
    // if r0 on the return from fread is not equal to bytes 
    // return in r0 from stdin (into iobuf) return EXIT fail
    // otherwise set r0 = bytes and return
    ldr     r0, [fp, ARG5]
    mov     r1, 1
    mov     r2, r8
    mov     r3, r5
    bl      fread
    cmp     r0, r8
    bne     .Lfail
    mov     r0, r8
    b       .Ldone

.Lsuccess:
    mov     r0, 0
    b      .Ldone

.Lfail:
    mov     r0, EXIT_FAIL

.Ldone:
    sub     sp, fp, FP_OFF
    pop     {r4-r9, fp, lr}
    bx      lr

    .size   rdbuf, (. - rdbuf)
    .section .note.GNU-stack,"",%progbits
.end
#endif
