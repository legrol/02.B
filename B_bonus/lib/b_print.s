# b_print.s - print string helper (reads ARG0, writes to stdout with newline)
# Returns length written (excluding newline)

.text
.globl b_print
.type b_print, @function

b_print:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    
    # Load string pointer from ARG0
    movl ARG0, %esi
    testl %esi, %esi
    jz .Lnull
    
    # Calculate string length
    xorl %ecx, %ecx      # len = 0
.Llen_loop:
    cmpb $0, (%esi,%ecx)
    je .Llen_done
    incl %ecx
    jmp .Llen_loop
    
.Llen_done:
    # Save length for return value
    movl %ecx, %edi
    
    # Write string: sys_write(1, esi, ecx)
    testl %ecx, %ecx
    jz .Lnewline
    movl $4, %eax        # sys_write
    movl $1, %ebx        # stdout
    movl %esi, %ecx      # buffer
    movl %edi, %edx      # length
    int $0x80
    
.Lnewline:
    # Write newline
    pushl $10            # newline char on stack
    movl $4, %eax
    movl $1, %ebx
    leal (%esp), %ecx
    movl $1, %edx
    int $0x80
    addl $4, %esp
    
    movl %edi, %eax      # return length
    jmp .Lreturn
    
.Lnull:
    xorl %eax, %eax      # return 0
    
.Lreturn:
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret
