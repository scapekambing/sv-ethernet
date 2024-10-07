/**
 * @file eth_axis_tx_wrapper.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief Wrapper for eth_axis_tx.v from Alex Forencich
 */

`default_nettype none

module eth_axis_tx_wrapper # (
    parameter int DATA_WIDTH = 8,
    parameter bit KEEP_ENABLE = (DATA_WIDTH > 8)
) ( 
    input var logic     clk,
    input var logic     reset,

    AXIS_IF.Master      mii_axis_if,
    
    ETH_HEADER_IF.Slave eth_tx_header_if,
    AXIS_IF.Slave       eth_tx_payload_if,

    output var logic    busy
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
        assert (eth_tx_payload_if.TDATA_WIDTH == 8)
        else $error("Assertion in %m failed, eth_tx_payload_if TDATA_WIDTH should be 8");
    end

    initial begin
        assert (eth_tx_payload_if.TID_WIDTH == 0)
        else $error("Assertion in %m failed, eth_tx_payload_if TID_WIDTH should be 0");
    end

    initial begin
        assert (eth_tx_payload_if.TDEST_WIDTH == 0)
        else $error("Assertion in %m failed, eth_tx_payload_if TDEST_WIDTH should be 0");
    end

    initial begin
        assert (eth_tx_payload_if.TUSER_WIDTH == 1)
        else $error("Assertion in %m failed, eth_tx_payload_if TUSER_WIDTH should be 1");
    end

    initial begin
        assert (eth_tx_payload_if.TKEEP_ENABLE == KEEP_ENABLE)
        else $error("Assertion in %m failed, eth_tx_payload_if TKEEP_ENABLE should be same as KEEP_ENABLE parameter");
    end

    initial begin
        assert (eth_tx_payload_if.TWAKEUP_ENABLE == 0)
        else $error("Assertion in %m failed,eth_payload_ins_if TWAKEUP_ENABLE should be 0");
    end

    eth_axis_tx # (
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(DATA_WIDTH / 8)
    ) eth_axis_tx_inst (
        .clk(clk),
        .rst(reset),

        .m_axis_tdata(mii_axis_if.tdata),
        .m_axis_tkeep(mii_axis_if.tkeep),
        .m_axis_tvalid(mii_axis_if.tvalid),
        .m_axis_tready(mii_axis_if.tready),
        .m_axis_tlast(mii_axis_if.tlast),
        .m_axis_tuser(mii_axis_if.tuser),

        .s_eth_hdr_valid(eth_tx_header_if.valid),
        .s_eth_hdr_ready(eth_tx_header_if.ready),
        .s_eth_dest_mac(eth_tx_header_if.dest_mac),
        .s_eth_src_mac(eth_tx_header_if.src_mac),
        .s_eth_type(eth_tx_header_if.eth_type),

        .s_eth_payload_axis_tdata(eth_tx_payload_if.tdata),
        .s_eth_payload_axis_tkeep(eth_tx_payload_if.tkeep),
        .s_eth_payload_axis_tvalid(eth_tx_payload_if.tvalid),
        .s_eth_payload_axis_tready(eth_tx_payload_if.tready),
        .s_eth_payload_axis_tlast(eth_tx_payload_if.tlast),
        .s_eth_payload_axis_tuser(eth_tx_payload_if.tuser),

        .busy(busy)
    );

endmodule

`default_nettype wire