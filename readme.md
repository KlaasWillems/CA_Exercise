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
    TODO    
## Mult4 Speedup
    TODO
