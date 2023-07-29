    // version 1.0 05/22/2022 //
#ifndef MYMAIN_S
#else
    .arch   armv6
    .arm
    .fpu    vfp
    .syntax unified

    // imports
    #include "main.h"
    #include "rdbuf.h"
    #include "setup.h"
    #include "cipher.h"
    .extern fwrite
    .extern stdin
    .extern stdout
    .extern stderr

    .section .rodata
    // do not change these error messages
.Lbdrd:  .string "%s: read failed\n"
.Lbdwr:  .string "%s: write failed\n"

    .text

    //
    // encrypter [-d | -e] -b bookfile
    //
    // int main(int argc, char **argv)
    // int main(r0=argc, r1=argv)

    .global main
    .type   main, %function

    //
    // stack frame layout
    //
    .equ    FP_OFF,     32              // fp offset in main stack frame
    .equ    FPBOOK,     4 + FP_OFF      // FILE * to book file
    .equ    IOBUF,      BUFSZ + FPBOOK  // buffer for input file
    .equ    MODE,       4 + IOBUF       // decrypt or encrypt mode
    .equ    BOOKBUF,    BUFSZ + MODE    // buffer for book file
    .equ    ARGV0,      4 + BOOKBUF     // save argv[0] for error printing
    //
    // add your local variables here if you need them:
    // NOTICE: Adjust PAD so FRMADD + FP_OFF + 4 divides by 8 EVENLY!
    //
    .equ    PAD,       4 + ARGV0        // Stack frame PAD
    .equ    OARG5,     4 + PAD          // output arg5 must be at bottom
    .equ    FRMADD,    OARG5 - FP_OFF   // space in frame for locals+passed args

    // preserved register use
    // r4  cnt
    // r5  *bookbuf
    // r6  *iobuf
    // r7  fpbook
    // r8  stdin/stdout
    // r9  argv0
    // r10 mode flag

main:
    push    {r4-r10, fp, lr}           // push all the usable preserved registers
    add     fp, sp, FP_OFF             // set frame pointer to frame base
    ldr     r3, =FRMADD                // get space needed for locals+passed args
    sub     sp, sp, r3                 // allocate space for locals and passed args 
     
    // save argv[0] in argv0
    // at the entry to main() argc is in r0 and argv is in r1.
    // call int setup(r0=argc, r1=argv, r2=*mode, r3=*FPBOOK)
    // r2 and r3 are output parameters. Put the address of where mode
    // and FPBOOK are located on main()'s stack and put these in r2 and r3
    // so setup can fill them in (passing a pointer to a local variable in r2,r3)
    // if setup fails, put EXIT_FAIL in r0 and then branch to .Lexit
    mov     r9, r1                     // save argv
    ldr     r9, [r9]                   // load argv[0]
    str     r9, [fp, -ARGV0]           // argv0 = *argv

    ldr     r2, =MODE
    sub     r2, fp, r2
    ldr     r3, =FPBOOK
    sub     r3, fp, r3
    bl      setup
    cmp     r0, EXIT_FAIL
    beq     .Lfail
    
    // set up for main loop
    // save the variables you need in the preserved registers as you will be making
    // function calls in the loop body below and r0-r3 will be used for that
    ldr     r5, =BOOKBUF
    sub     r5, fp, r5
    ldr     r6, =IOBUF
    sub     r6, fp, r6  
    ldr     r7, [fp, -FPBOOK]
    ldr     r8, =stdin
    ldr     r8, [r8]
    ldr     r10, [fp, -MODE]

    // this is a loop that runs until rdbuf indicates the EOF on stdin
    // was reached or there was an error.
    // int rdbuf(r0=stdin, r1=fpbook, r2=BUFSZ, r3=iobuf,OARG5=bookbuf)
    // NOTICE that the 5th arg is on the stack so you need to str the 
    // address of bookbuf at offset OARG5 on the stack
    // if r0 on return from rdbuf has a 0 in r0 we are done, branch to .Ldone
    // if return less than 0, error print to stderr .Lbdrd, and go to .Ldone
.Lloop:
    str     r5, [fp, -OARG5]     
    mov     r0, r8
    mov     r1, r7
    mov     r2, BUFSZ
    mov     r3, r6
    bl      rdbuf
    cmp     r0, 0
    beq     .Ldone
    cmp     r0, 0
    blt     .Lerr1

    // check the mode flag and call either encrypt or decrypt
    // int XXcrypt(r0=char *iobuf, r1=char *bookbuf, r2=int cnt)
    // encrypt or decrypt 
    // returns cnt
.Lmode:
    mov     r2, r0
    mov     r0, r6
    ldr     r1, =BOOKBUF
    sub     r1, fp, r1
    cmp     r10, ENCRYPT_MODE
    bne     .Ldecrypt
    bl      encrypt
    b       .Lcont

.Ldecrypt:
    bl      decrypt
        
    // make sure to save cnt so we can check that fwrite wrote cnt characters
    // fwrite returns number of characters it wrote.
    // fwrite(r0=iobuf, r1=1, r2=cnt, r3=*stdout)
    // if cnt characters written go to .Lloop (write is ok)
    // othewise error, print to stderr .Lbdwr and fall through to .Ldone
.Lcont:
    mov     r4, r0
    mov     r2, r0
    mov     r0, r6
    mov     r1, 1
    ldr     r3, =stdout
    ldr     r3, [r3]
    bl      fwrite
    cmp     r0, r4
    beq     .Lloop
    ldr     r0, =stderr
    ldr     r0, [r0]
    ldr     r1, =.Lbdwr
    ldr     r2, [fp, -ARGV0]
    bl      fprintf
    mov     r0, EXIT_FAIL
    b       .Ldone

.Lerr1:
    ldr     r0, =stderr
    ldr     r0, [r0]
    ldr     r1, =.Lbdrd
    ldr     r2, [fp, -ARGV0]
    bl      fprintf
    mov     r0, EXIT_FAIL
    b       .Ldone

.Lfail:
    mov     r0, EXIT_FAIL
    b       .Lexit

.Ldone:
    // normal exit, call fclose of fpbook and fall through
    // to .Lexit
    mov     r0, r7
    bl      fclose

.Lexit:
    sub     sp, fp, FP_OFF
    pop     {r4-r10, fp, lr}
    bx      lr

    .size   main, (. - main)
    .section .note.GNU-stack,"",%progbits
.end
#endif
