module full_adder (
    input a,
    input b,
    input carry_in,
    output sum,
    output carry_out
);
    // Insert your RTL here to calculate the sum and carry out bits
    // Remove these assign statements once you write your own RTL
    assign {carry_out, sum} = a + b + carry_in;
endmodule
