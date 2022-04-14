addi x25, x0, 0 # main pipe line instructions
addi x27, x0, 280 
addi x21, x0, 0 
addi x12, x0, 3 
addi x23, x0, 0 
C_CHECK: ld x4, 0(x25) 
ld x5, 0(x26) 
addi x26, x26, 8 
mul x6, x4, x5 
add x7, x7, x6 
bne x21, x11, C_CHECK
sd x7, 0(x27) 
addi x7, x0, 0 
addi x27, x27, 8 
bne x22, x12, C_CHECK
addi x23, x23, 1
addi x22, x0, 0
bne x23, x13, C_CHECK