module structural_adder (
    input [13:0] a,
    input [13:0] b,
    output [14:0] sum
);
    wire [13:0] carry_out;
    full_adder adder0(
        .a        (a[0]),
        .b        (b[0]),
        .carry_in (1'b0),
        .sum      (sum[0]),
        .carry_out(carry_out[0])
    );
    genvar i;
    generate
        for(i=1; i<14; i=i+1) begin:adder
            full_adder adder(.a(a[i]), .b(b[i]), .carry_in(carry_out[i-1]), .sum(sum[i]), .carry_out(carry_out[i]));
        end 
    endgenerate
    assign sum[14] = carry_out[13];
endmodule