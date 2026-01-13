# print.s - print integer followed by newline
# Takes one argument on stack, returns the same value
# Note: This version uses a syscall-only approach (no libc)

.text
.globl print
.type print, @function

print:
    pushl %ebp
    movl %esp, %ebp
    subl $16, %esp       # local buffer for digits
    pushl %ebx
    pushl %esi
    pushl %edi
    
    movl 8(%ebp), %ebx   # get argument
    movl %ebx, %edi      # save for return
    
    # Convert integer to string (backwards into buffer)
    leal -1(%ebp), %esi  # point to end of buffer
    movl $10, %ecx       # divisor
    
    # Handle zero special case
    testl %ebx, %ebx
    jnz .Lconvert
    movb $'0', (%esi)
    decl %esi
    jmp .Lwrite
    
.Lconvert:
    # Handle negative numbers
    movl %ebx, %eax
    testl %eax, %eax
    jns .Lpositive
    negl %eax
    movl %eax, %ebx
    
.Lpositive:
    movl %ebx, %eax
    
.Ldigit_loop:
    testl %eax, %eax
    jz .Lcheck_sign
    xorl %edx, %edx
    divl %ecx            # eax = quot, edx = rem
    addb $'0', %dl
    movb %dl, (%esi)
    decl %esi
    jmp .Ldigit_loop
    
.Lcheck_sign:
    # Add minus if negative
    testl 8(%ebp), %ebx
    jns .Lwrite
    movb $'-', (%esi)
    decl %esi
    
.Lwrite:
    incl %esi            # adjust back to first digit
    # Calculate length
    leal -1(%ebp), %ecx
    subl %esi, %ecx
    incl %ecx
    
    # sys_write(1, esi, ecx)
    movl $4, %eax
    movl $1, %ebx
    movl %esi, %ecx
    movl %ecx, %edx      # length already in ecx
    leal -1(%ebp), %ecx
    subl %esi, %ecx
    incl %ecx
    movl %ecx, %edx
    movl %esi, %ecx
    int $0x80
    
    # Write newline
    pushl $10
    movl $4, %eax
    movl $1, %ebx
    leal (%esp), %ecx
    movl $1, %edx
    int $0x80
    addl $4, %esp
    
    movl %edi, %eax      # return original value
    
    popl %edi
    popl %esi
    popl %ebx
    movl %ebp, %esp
    popl %ebp
    ret
