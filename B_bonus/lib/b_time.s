# b_time.s - return current time (seconds since epoch via sys_time)

.text
.globl b_time
.type b_time, @function

b_time:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx
    
    # sys_time(NULL) - syscall 13 on i386
    movl $13, %eax       # sys_time
    xorl %ebx, %ebx      # NULL (return value in eax)
    int $0x80
    
    # Check for error (negative return)
    testl %eax, %eax
    js .Lerror
    jmp .Lreturn
    
.Lerror:
    xorl %eax, %eax      # return 0 on error
    
.Lreturn:
    popl %ebx
    popl %ebp
    ret
