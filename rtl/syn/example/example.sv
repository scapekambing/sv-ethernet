`timescale 1ns / 1ps
`default_nettype none

module example # (
    parameter bit INVERTER = 0
) (
    input  var logic in,
    output var logic out
);
    always_comb begin
        if (INVERTER) begin
            out = !in;
        end else begin
            out = in;
        end
    end
endmodule

`default_nettype wire