# get_ten.s - simple demo function returning 10

.text
.globl get_ten
.type get_ten, @function

get_ten:
    movl $10, %eax
    ret
