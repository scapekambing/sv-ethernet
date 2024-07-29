`timescale 1ns / 1ps
`default_nettype none

module top #(
    /* PARAMETERS */
) (
    input var logic clk,
    input var logic reset_n,

    input var logic [3:0]   sw,
    input var logic [3:0]   btn,
    input var logic         led0_r,
    input var logic         led0_g,
    input var logic         led0_b,
    input var logic         led1_r,
    input var logic         led1_g,
    input var logic         led1_b,
    input var logic         led2_r,
    input var logic         led2_g,
    input var logic         led2_b,
    input var logic         led3_r,
    input var logic         led3_g,
    input var logic         led3_b,
    input var logic         led4,
    input var logic         led5,
    input var logic         led6,
    input var logic         led7,

    output var logic        phy_ref_clk,
    input var logic         phy_rx_clk,
    input var logic [3:0]   phy_rxd,
    input var logic         phy_rx_dv,
    input var logic         phy_rx_er,
    input var logic         phy_tx_clk,
    output var logic [3:0]  phy_txd,
    output var logic        phy_tx_en,
    input var logic         phy_col,
    input var logic         phy_crs,
    output var logic        phy_reset_n,

    input var logic         uart_rxd,
    output var logic        uart_txd,

    input var logic [3:0]   sw
);
    var logic clk_ibufg;

    var logic clk_mmcm_out;
    var logic clk_int;
    var logic rst_int;

    var logic mmcm_rst = ~reset_n;
    var logic mmcm_locked;
    var logic mmcm_clkfb;

    IBUFG clk_ibufg_inst(
        .I(clk),
        .O(clk_ibufg)
    );

    var logic clk_25mhz_mmcm_out;
    var logic clk_25mhz_int;

    /* MMCM Instance
     * 100 MHz input, 125 & 25 MHz output
     * PFD range: 10 MHz to 550 MHz
     * VCO range: 600 MHz to 1200 MHz
     * M = 10, D = 1 set Fvco = 1000 MHz (1 GHz, in range)
     * Divide by 8 to get 125 MHz
     * Divide by 40 to get 25 MHz
    */
    MMCME2_BASE # (
        .BANDWIDTH("OPTIMIZED"),
        .CLKOUT0_DIVIDE_F(8),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0),
        .CLKOUT1_DIVIDE(40),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0),
        .CLKOUT2_DIVIDE(1),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE(0),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE(0),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT4_PHASE(0),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT5_PHASE(0),
        .CLKOUT6_DIVIDE(1),
        .CLKOUT6_DUTY_CYCLE(0.5),
        .CLKOUT6_PHASE(0),
        .CLKFBOUT_MULT_F(10),
        .CLKFBOUT_PHASE(0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .CLKIN1_PERIOD(10.0),
        .STARTUP_WAIT("FALSE"),
        .CLKOUT4_CASCADE("FALSE")
    ) clk_mmcm_inst (
        .CLKIN1(clk_ibufg),
        .CLKFBIN(mmcm_clkfb),
        .RST(mmcm_rst),
        .PWRDWN('0),
        .CLKOUT0(clk_mmcm_out),
        .CLKOUT0B(),
        .CLKOUT1(clk_25mhz_mmcm_out),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUT(mmcm_clkfb),
        .CLKFBOUTB(),
        .LOCKED(mmcm_locked)
    );

    BUFG clk_bufg_inst (
        .I(clk_mmcm_out),
        .O(clk_int)
    );

    BUFG clk_25mhz_bufg_inst (
        .I(clk_25mhz_mmcm_out),
        .O(clk_25mhz_int)
    );

    var logic phy_rx_clk_mmcm_locked;
    var logic phy_rx_clk_mmcm_clkfb;

    var logic phy_rx_clk_mmcm_out;
    var logic phy_rx_clk_int;
    
    /* MMCM Instance
     * 25 MHz input, 25 MHz output
     * PFD range: 10 MHz to 550 MHz
     * VCO range: 600 MHz to 1200 MHz
     * M = 30, D = 1 set Fvco = 750 MHz (in range)
     * Divide by 30 to get 25 MHz
    */
    MMCME2_BASE # (
        .BANDWIDTH("OPTIMIZED"),
        .CLKOUT0_DIVIDE_F(30),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0),
        .CLKOUT1_DIVIDE(1),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0),
        .CLKOUT2_DIVIDE(1),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE(0),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE(0),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT4_PHASE(0),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT5_PHASE(0),
        .CLKOUT6_DIVIDE(1),
        .CLKOUT6_DUTY_CYCLE(0.5),
        .CLKOUT6_PHASE(0),
        .CLKFBOUT_MULT_F(30),
        .CLKFBOUT_PHASE(0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .CLKIN1_PERIOD(40.0),
        .STARTUP_WAIT("FALSE"),
        .CLKOUT4_CASCADE("FALSE")
    ) phy_rx_clk_mmcm_inst (
        .CLKIN1(phy_rx_clk),
        .CLKFBIN(phy_rx_clk_mmcm_clkfb),
        .RST(mmcm_rst),
        .PWRDWN('0),
        .CLKOUT0(phy_rx_clk_int), //phy_rx_clk_mmcm_out
        .CLKOUT0B(),
        .CLKOUT1(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUT(phy_rx_clk_mmcm_clkfb),
        .CLKFBOUTB(),
        .LOCKED(phy_rx_clk_mmcm_locked)
    );

    //BUFG phy_rx_clk_bufg_inst (
    //    .I(phy_rx_clk_mmcm_out),
    //    .O(phy_rx_clk_int)
    //);

    // Sync reset originates from the verilog-axis library in the ethernet library
    sync_reset # (
        .N(4)
    ) sync_reset_inst (
        .clk(clk_int),
        .rst(~mmcm_locked),
        .out(rst_int)
    );

    assign phy_ref_clk = clk_25mhz_int;
    assign phy_reset_n = !rst_int;

    MII_IF mii_if();
    assign mii_if.tx_clk = phy_tx_clk;
    assign phy_txd = mii_if.txd;
    assign phy_tx_en = mii_if.tx_en;
    assign mii_if.rx_clk = phy_rx_clk_int;
    assign mii_if.rxd = phy_rxd;
    assign mii_if.rx_dv = phy_rx_dv;
    assign mii_if.rx_er = phy_rx_er;
    assign mii_if.crs = phy_crs;
    assign mii_if.col = phy_col;

    AXIL_IF axil_if();

    eth_top # (
        .TARGET("XILINX")
    ) eth_inst (
        .clk(clk_int),
        .reset(rst_int),

        .mii_if(mii_if.MAC),

        .axil_if(axil_if.Master),

        .local_mac(48'h02_00_00_00_00_00),
        .local_ip({8'd192, 8'd168, 8'd1, 8'd128}),
        .gateway_ip({8'd192, 8'd168, 8'd1, 8'd1}),
        .subnet_mask({8'd255, 8'd255, 8'd255, 8'd0}),
        .clear_arp_cache(0),
        
        .screamer_enable(sw[3]),

        .udp_payload_selection(sw[1:0])
    );

    axil_ram_wrapper # (
        // Using default
    ) axil_ram_wrapper_inst (
        .clk(clk_int),
        .reset(rst_int),

        .axil_if(axil_if.Slave)
    );

    always_ff @ (posedge clk_int)
        led4 <= sw[0];
        led5 <= sw[1];
        led6 <= sw[2];
        led7 <= sw[3];


endmodule