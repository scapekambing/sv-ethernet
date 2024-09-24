/**
 * @file eth_axis_rx_wrapper.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief Wrapper for eth_axis_rx.v from Alex Forencich
 */

`default_nettype none

module eth_axis_rx_wrapper # (
    parameter int DATA_WIDTH = 8,
    parameter bit KEEP_ENABLE = (DATA_WIDTH > 8)
) ( 
    input var logic         clk,
    input var logic         reset,

    AXIS_IF.Slave           mii_axis_if,
    
    ETH_HEADER_IF.Master    eth_rx_header_if,
    AXIS_IF.Master          eth_rx_payload_if,

    output var logic        busy,
    output var logic        error_header_early_termination
);
    initial begin
        assert (mii_axis_if.TDATA_WIDTH == 8)
        else $error("Assertion in %m failed, mii_axis_if TDATA_WIDTH should be 8");
    end

    initial begin
        assert (mii_axis_if.TID_WIDTH == 0)
        else $error("Assertion in %m failed, mii_axis_if TID_WIDTH should be 0");
    end

    initial begin
        assert (mii_axis_if.TDEST_WIDTH == 0)
        else $error("Assertion in %m failed, mii_axis_if TDEST_WIDTH should be 0");
    end

    initial begin
        assert (mii_axis_if.TUSER_WIDTH == 1)
        else $error("Assertion in %m failed, mii_axis_if TUSER_WIDTH should be 1");
    end

    initial begin
        assert (mii_axis_if.TKEEP_ENABLE == KEEP_ENABLE)
        else $error("Assertion in %m failed, mii_axis_if TKEEP_ENABLE should be same as KEEP_ENABLE parameter");
    end

    initial begin
        assert (mii_axis_if.TWAKEUP_ENABLE == 0)
        else $error("Assertion in %m failed, mii_axis_if TWAKEUP_ENABLE should be 0");
    end

    initial begin
        assert (eth_payload_out_if.TDATA_WIDTH == 8)
        else $error("Assertion in %m failed, eth_payload_out_if TDATA_WIDTH should be 8");
    end

    initial begin
        assert (eth_payload_out_if.TID_WIDTH == 0)
        else $error("Assertion in %m failed, eth_payload_out_if TID_WIDTH should be 0");
    end

    initial begin
        assert (eth_payload_out_if.TDEST_WIDTH == 0)
        else $error("Assertion in %m failed, eth_payload_out_if TDEST_WIDTH should be 0");
    end

    initial begin
        assert (eth_payload_out_if.TUSER_WIDTH == 1)
        else $error("Assertion in %m failed, eth_payload_out_if TUSER_WIDTH should be 1");
    end

    initial begin
        assert (eth_payload_out_if.TKEEP_ENABLE == KEEP_ENABLE)
        else $error("Assertion in %m failed, eth_payload_out_if TKEEP_ENABLE should be same as KEEP_ENABLE parameter");
    end

    initial begin
        assert (eth_payload_out_if.TWAKEUP_ENABLE == 0)
        else $error("Assertion in %m failed,eth_payload_outs_if TWAKEUP_ENABLE should be 0");
    end

    eth_axis_rx # (
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(DATA_WIDTH / 8)
    ) eth_axis_rx_inst (
        .clk(clk),
        .rst(reset),

        .s_axis_tdata(mii_axis_if.tdata),
        .s_axis_tkeep(mii_axis_if.tkeep),
        .s_axis_tvalid(mii_axis_if.tvalid),
        .s_axis_tready(mii_axis_if.tready),
        .s_axis_tlast(mii_axis_if.tlast),
        .s_axis_tuser(mii_axis_if.tuser),

        .m_eth_hdr_valid(eth_header_out_if.valid),
        .m_eth_hdr_ready(eth_header_out_if.ready),
        .m_eth_dest_mac(eth_header_out_if.dest_mac),
        .m_eth_src_mac(eth_header_out_if.src_mac),
        .m_eth_type(eth_header_out_if.eth_type),

        .m_eth_payload_axis_tdata(eth_payload_out_if.tdata),
        .m_eth_payload_axis_tkeep(eth_payload_out_if.tkeep),
        .m_eth_payload_axis_tvalid(eth_payload_out_if.tvalid),
        .m_eth_payload_axis_tready(eth_payload_out_if.tready),
        .m_eth_payload_axis_tlast(eth_payload_out_if.tlast),
        .m_eth_payload_axis_tuser(eth_payload_out_if.tuser),

        .busy(busy),
        .error_header_early_termination(error_header_early_termination)
    );

endmodule

`default_nettype wire