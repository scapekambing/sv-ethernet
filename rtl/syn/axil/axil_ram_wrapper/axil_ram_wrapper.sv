/**
 * @file axil_ram_wrapper.sv
 * 
 * @author Mani Magnusson
 * @date   2024
 * 
 * @brief Wrapper for axil_ram.v from Alex Forencich
 */

`default_nettype none

module axil_ram_wrapper # (
    parameter bit PIPELINE_OUTPUT = 1'b0,
    parameter int VALID_ADDRESS_BITS = 16
) (
    input var logic clk,
    input var logic reset,

    AXIL_IF.Slave axil_if
);

//localparam int ADDR_WIDTH = axil_if.ADDR_WIDTH;
//localparam int DATA_WIDTH = axil_if.DATA_WIDTH;
//localparam int STRB_WIDTH = DATA_WIDTH / 8;

initial begin
        assert (VALID_ADDRESS_BITS <= axil_if.ADDR_WIDTH &&
                VALID_ADDRESS_BITS <= axil_if.DATA_WIDTH)
        else $error("Assertion in %m failed, valid address bits can't be larger than interface widths");
    end

axil_ram # (
    .DATA_WIDTH(axil_if.DATA_WIDTH),
    .ADDR_WIDTH(VALID_ADDRESS_BITS),
    .STRB_WIDTH(axil_if.STRB_WIDTH),
    .PIPELINE_OUTPUT(PIPELINE_OUTPUT)
) axil_ram_inst (
    .clk(clk),
    .rst(reset),
    
    .s_axil_awaddr(axil_if.awaddr[VALID_ADDRESS_BITS-1:0]),
    .s_axil_awprot(axil_if.awprot),
    .s_axil_awvalid(axil_if.awvalid),
    .s_axil_awready(axil_if.awready),

    .s_axil_wdata(axil_if.wdata),
    .s_axil_wstrb(axil_if.wstrb),
    .s_axil_wvalid(axil_if.wvalid),
    .s_axil_wready(axil_if.wready),

    .s_axil_bresp(axil_if.bresp),
    .s_axil_bvalid(axil_if.bvalid),
    .s_axil_bready(axil_if.bready),

    .s_axil_araddr(axil_if.araddr[VALID_ADDRESS_BITS-1:0]),
    .s_axil_arprot(axil_if.arprot),
    .s_axil_arvalid(axil_if.arvalid),
    .s_axil_arready(axil_if.arready),
    
    .s_axil_rdata(axil_if.rdata),
    .s_axil_rresp(axil_if.rresp),
    .s_axil_rvalid(axil_if.rvalid),
    .s_axil_rready(axil_if.rready)
);

endmodule

`default_nettype wire