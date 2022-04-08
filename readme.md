# H05D3A: Computer architectures

## Design

We implemented a 5 stage single issue RISC-V pipeline. Some of its features are:
<ul>
    <li>2-bit branch prediction</li>
    <li>Branch checks are done in the ID stage</li>
    <li>Load-Use hazard detection</li>
    <li>Use-Branch hazard detection (addi x1, x0, 1; beq x1, x2, ...)</li>
    <li>Forwarding to the ALU from WB and MEM stage</li>
    <li>Forwarding to the branching hardware in the ID stage</li>
    <li>Forwarding copies (load followed by store instruction)</li>
</ul>
    
## Supported Instructions
<ul>
    <li>jal - jump and link</i>
    <li>ld - load double</li>
    <li>sd - store double</li>
    <li>beq - branch equal</li>
    <li>bne - branch not equal</li>
    <li>and</li>
    <li>or</li>
    <li>addi</li>
    <li>add</li>
    <li>mul</li>
    <li>sll - shift left</li>
    <li>srl - shift right</li>
    <li>slt - set less than</li>
</ul>
    
## Mult4 Speedup
    TODO
