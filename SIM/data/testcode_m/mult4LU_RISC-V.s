addi x25, x0, 0 # input's address starting point in dmem
addi x26, x0, 160 # weight's address starting point in dmem
addi x27, x0, 280 # output's address starting point in dmem
addi x12, x0, 3 # total K loop size
addi x13, x0, 4 # total B loop size
addi x22, x0, 0 # K loop index starts with 0
addi x23, x0, 0 # B loop index starts with 0
addi x7, x0, 0 # accumation result initilization
B_CHECK: beq x23, x13, B_END
K_CHECK: beq x22, x12, K_END
ld x4, 0(x25) # copy1
ld x5, 0(x26) 
addi x25, x25, 8 
mul x6, x4, x5 
add x7, x7, x6 
addi x26, x26, 8 
ld x4, 0(x25) # copy2
ld x5, 0(x26) 
addi x25, x25, 8 
mul x6, x4, x5  
add x7, x7, x6  
addi x26, x26, 8 
ld x4, 0(x25) # copy3
ld x5, 0(x26) 
addi x25, x25, 8 
mul x6, x4, x5  
add x7, x7, x6  
addi x26, x26, 8 
ld x4, 0(x25) # copy4
ld x5, 0(x26) 
addi x25, x25, 8 
mul x6, x4, x5  
add x7, x7, x6 
addi x26, x26, 8 
ld x4, 0(x25) # copy5
ld x5, 0(x26) 
addi x25, x25, 8 
mul x6, x4, x5  
add x7, x7, x6  
addi x26, x26, 8 
sd x7, 0(x27) # store the output data
addi x7, x0, 0 # accumation result reset to 0
addi x22, x22, 1 # K loop index +1
addi x25, x25, -40 # input's 64-bit word address -5
addi x27, x27, 8 # output's 64-bit word address +1
jal K_CHECK
K_END: addi x22, x0, 0 # K loop index restarts with 0
addi x23, x23, 1 # B loop index +1
addi x25, x25, 40 # input's 64-bit word address +5
addi x26, x26, -120 # input's 64-bit word address -15
jal B_CHECK
B_END:
