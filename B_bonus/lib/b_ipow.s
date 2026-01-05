.text
.globl b_ipow
.type b_ipow, @function
b_ipow:
    pushl %ebp
    movl %esp, %ebp
    movl ARG0, %edi    # base
    movl ARG1, %ecx    # exp
    movl $1, %ebx      # res = 1
.Lloop:
    testl %ecx, %ecx
    jz .Ldone
    testb $1, %cl
    jz .Lskip_mul
    imull %edi, %ebx
.Lskip_mul:
    imull %edi, %edi
    sarl $1, %ecx
    jmp .Lloop
.Ldone:
    movl %ebx, %eax
    movl %ebp, %esp
    popl %ebp
    ret
