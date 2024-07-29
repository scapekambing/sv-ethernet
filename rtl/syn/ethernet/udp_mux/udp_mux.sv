/**
 * @file udp_mux_wrapper.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief Wrapper for udp_mux.v from Alex Forencich
 */

`default_nettype none

module udp_mux_wrapper # (
    parameter int S_COUNT = 2
) (
    input var logic                     clk,
    input var logic                     reset,

    UDP_TX_HEADER_IF.Sink [S_COUNT-1:0] udp_tx_header_if_sink,
    AXIS_IF.Receiver [S_COUNT-1:0]      udp_tx_payload_if_sink,

    UDP_TX_HEADER_IF.Source             udp_tx_header_if_source,
    AXIS_IF.Transmitter                 udp_tx_payload_if_source,

    input var logic                         enable,
    input var logic [$clog2(S_COUNT)-1:0]   select
);
    generate
        for (genvar i = 0; i < S_COUNT; i++) begin
            initial begin
                assert(udp_tx_payload_if_sink[i].TDATA_WIDTH == udp_tx_payload_if_source.TDATA_WIDTH)
                else $error("Assertion in %m failed, TDATA_WIDTH parameters of AXIS_IF interfaces don't match");
            end

            initial begin
                assert(udp_tx_payload_if_sink[i].TID_WIDTH == udp_tx_payload_if_source.TID_WIDTH)
                else $error("Assertion in %m failed, TID_WIDTH parameters of AXIS_IF interfaces don't match");
            end

            initial begin
                assert(udp_tx_payload_if_sink[i].TDEST_WIDTH == udp_tx_payload_if_source.TDEST_WIDTH)
                else $error("Assertion in %m failed, TDEST_WIDTH parameters of AXIS_IF interfaces don't match");
            end

            initial begin
                assert(udp_tx_payload_if_sink[i].TUSER_WIDTH == udp_tx_payload_if_source.TUSER_WIDTH)
                else $error("Assertion in %m failed, TUSER_WIDTH parameters of AXIS_IF interfaces don't match");
            end

            initial begin
                assert(udp_tx_payload_if_sink[i].TKEEP_ENABLE == udp_tx_payload_if_source.TKEEP_ENABLE)
                else $error("Assertion in %m failed, TKEEP_ENABLE parameters of AXIS_IF interfaces don't match");
            end

            initial begin
                assert(udp_tx_payload_if_sink[i].TWAKEUP_ENABLE == udp_tx_payload_if_source.TWAKEUP_ENABLE)
                else $error("Assertion in %m failed, TWAKEUP_ENABLE parameters of AXIS_IF interfaces don't match");
            end
        end
    endgenerate

    var logic [S_COUNT-1:0]            temp_udp_hdr_valid;
    var logic [S_COUNT-1:0]            temp_udp_hdr_ready;
    var logic [S_COUNT*48-1:0]         temp_eth_dest_mac;
    var logic [S_COUNT*48-1:0]         temp_eth_src_mac;
    var logic [S_COUNT*16-1:0]         temp_eth_type;
    var logic [S_COUNT*4-1:0]          temp_ip_version;
    var logic [S_COUNT*4-1:0]          temp_ip_ihl;
    var logic [S_COUNT*6-1:0]          temp_ip_dscp;
    var logic [S_COUNT*2-1:0]          temp_ip_ecn;
    var logic [S_COUNT*16-1:0]         temp_ip_length;
    var logic [S_COUNT*16-1:0]         temp_ip_identification;
    var logic [S_COUNT*3-1:0]          temp_ip_flags;
    var logic [S_COUNT*13-1:0]         temp_ip_fragment_offset;
    var logic [S_COUNT*8-1:0]          temp_ip_ttl;
    var logic [S_COUNT*8-1:0]          temp_ip_protocol;
    var logic [S_COUNT*16-1:0]         temp_ip_header_checksum;
    var logic [S_COUNT*32-1:0]         temp_ip_source_ip;
    var logic [S_COUNT*32-1:0]         temp_ip_dest_ip;
    var logic [S_COUNT*16-1:0]         temp_udp_source_port;
    var logic [S_COUNT*16-1:0]         temp_udp_dest_port;
    var logic [S_COUNT*16-1:0]         temp_udp_length;
    var logic [S_COUNT*16-1:0]         temp_udp_checksum;

    var logic [S_COUNT*DATA_WIDTH-1:0] temp_udp_payload_axis_tdata;
    var logic [S_COUNT*KEEP_WIDTH-1:0] temp_udp_payload_axis_tkeep;
    var logic [S_COUNT-1:0]            temp_udp_payload_axis_tvalid;
    var logic [S_COUNT-1:0]            temp_udp_payload_axis_tready;
    var logic [S_COUNT-1:0]            temp_udp_payload_axis_tlast;
    var logic [S_COUNT*ID_WIDTH-1:0]   temp_udp_payload_axis_tid;
    var logic [S_COUNT*DEST_WIDTH-1:0] temp_udp_payload_axis_tdest;
    var logic [S_COUNT*USER_WIDTH-1:0] temp_udp_payload_axis_tuser;

    generate
        for (genvar i = 0; i < S_COUNT; i++) begin
            always_comb begin
                temp_udp_hdr_valid[i]                   = udp_tx_header_if_sink[i].hdr_valid;
                udp_tx_header_if_sink[i].hdr_ready      = temp_udp_hdr_ready[i];

                temp_eth_dest_mac[48*i+47:48*i]         = udp_tx_header_if_sink[i].eth_dest_mac;
                temp_eth_src_mac[48*i+47:48*i]          = udp_tx_header_if_sink[i].eth_src_mac;
                temp_eth_type[16*i+15:16*i]             = udp_tx_header_if_sink[i].eth_type;

                temp_ip_version[4*i+3:4*i]              = udp_tx_header_if_sink[i].ip_version;
                temp_ip_ihl[4*i+4:4*i]                  = udp_tx_header_if_sink[i].ip_ihl;
                temp_ip_dscp[6*i+5:6*i]                 = udp_tx_header_if_sink[i].ip_dscp;
                temp_ip_ecn[2*i+1:2*i]                  = udp_tx_header_if_sink[i].ip_ecn;
                temp_ip_length[16*i+15:16*i]            = udp_tx_header_if_sink[i].ip_length;
                temp_ip_identification[16*i+15:16*i]    = udp_tx_header_if_sink[i].ip_identification;
                temp_ip_flags[3*i+2:3*i]                = udp_tx_header_if_sink[i].ip_flags;
                temp_ip_fragment_offset[13*i+12:13*i]   = udp_tx_header_if_sink[i].ip_fragment_offset;
                temp_ip_ttl[8*i+7:8*i]                  = udp_tx_header_if_sink[i].ip_ttl;
                temp_ip_protocol[8*i+7:8*i]             = udp_tx_header_if_sink[i].ip_protocol;
                temp_ip_header_checksum[16*i+15:16*i]   = udp_tx_header_if_sink[i].ip_header_checksum;
                temp_ip_source_ip[32*i+31:32*i]         = udp_tx_header_if_sink[i].ip_source_ip;
                temp_ip_dest_ip[32*i+31:32*i]           = udp_tx_header_if_sink[i].ip_dest_ip;

                temp_udp_source_port[16*i+15:16*i]      = udp_tx_header_if_sink[i].source_port;
                temp_udp_dest_port[16*i+15:16*i]        = udp_tx_header_if_sink[i].dest_port;
                temp_udp_length[16*i+15:16*i]           = udp_tx_header_if_sink[i].length;
                temp_udp_checksum[16*i+15:16*i]         = udp_tx_header_if_sink[i].checksum;

                temp_udp_payload_axis_tvalid[i]                                             = udp_tx_payload_if_sink[i].tvalid;
                udp_tx_payload_if_sink[i].tready                                            = temp_udp_payload_axis_tready[i];

                temp_udp_payload_axis_tdata[TDATA_WIDTH*i+(TDATA_WIDTH-1):TDATA_WIDTH*i]    = udp_tx_payload_if_sink[i].tdata;
                temp_udp_payload_axis_tkeep[TKEEP_WIDTH*i+(TKEEP_WIDTH-1):TKEEP_WIDTH*i]    = udp_tx_payload_if_sink[i].tkeep;
                temp_udp_payload_axis_tlast[i]                                              = udp_tx_payload_if_sink[i].tlast;
                temp_udp_payload_axis_tid[TID_WIDTH*i+(TID_WIDTH-1):TID_WIDTH*i]            = udp_tx_payload_if_sink[i].tid;
                temp_udp_payload_axis_tdest[TDEST_WIDTH*i+(TDEST_WIDTH-1):TDEST_WIDTH*i]    = udp_tx_payload_if_sink[i].tdest;
                temp_udp_payload_axis_tuser[TUSER_WIDTH*i+(TUSER_WIDTH-1):TUSER_WIDTH*i]    = udp_tx_payload_if_sink[i].tuser;
            end
        end
    endgenerate

    localparam int TDATA_WIDTH = udp_tx_payload_if_source.TDATA_WIDTH;
    localparam int TID_WIDTH = udp_tx_payload_if_source.TID_WIDTH;
    localparam int TDEST_WIDTH = udp_tx_payload_if_source.TDEST_WIDTH;
    localparam int TUSER_WIDTH = udp_tx_payload_if_source.TUSER_WIDTH;
    localparam int TKEEP_ENABLE = udp_tx_payload_if_source.TKEEP_ENABLE;
    localparam int TKEEP_WIDTH = TDATA_WIDTH / 8;

    udp_mux # (
        .S_COUNT(S_COUNT),
        .DATA_WIDTH(TDATA_WIDTH),
        .KEEP_ENABLE(TKEEP_ENABLE),
        .KEEP_WIDTH(TKEEP_WIDTH),
        .ID_ENABLE(TID_WIDTH > 0),
        .ID_WIDTH(TID_WIDTH),
        .DEST_ENABLE(TDEST_WIDTH > 0),
        .DEST_WIDTH(TDEST_WIDTH),
        .USER_ENABLE(TUSER_WIDTH > 0),
        .USER_WIDTH(TUSER_WIDTH)
    ) udp_mux_inst (
        .clk(clk),
        .rst(reset),
        
        .s_udp_hdr_valid(temp_udp_hdr_valid),
        .s_udp_hdr_ready(temp_udp_hdr_ready),
        .s_eth_dest_mac(temp_eth_dest_mac),
        .s_eth_src_mac(temp_eth_src_mac),
        .s_eth_type(temp_eth_type),
        .s_ip_version(temp_ip_version),
        .s_ip_ihl(temp_ip_ihl),
        .s_ip_dscp(temp_ip_dscp),
        .s_ip_ecn(temp_ip_ecn),
        .s_ip_length(temp_ip_length),
        .s_ip_identification(temp_ip_identification),
        .s_ip_flags(temp_ip_flags),
        .s_ip_fragment_offset(temp_ip_fragment_offset),
        .s_ip_ttl(temp_ip_ttl),
        .s_ip_protocol(temp_ip_protocol),
        .s_ip_header_checksum(temp_ip_header_checksum),
        .s_ip_source_ip(temp_ip_source_ip),
        .s_ip_dest_ip(temp_ip_dest_ip),
        .s_udp_source_port(temp_udp_source_port),
        .s_udp_dest_port(temp_udp_dest_port),
        .s_udp_length(temp_udp_length),
        .s_udp_checksum(temp_udp_checksum),

        .s_udp_payload_axis_tdata(temp_udp_payload_axis_tdata),
        .s_udp_payload_axis_tkeep(temp_udp_payload_axis_tkeep),
        .s_udp_payload_axis_tvalid(temp_udp_payload_axis_tvalid),
        .s_udp_payload_axis_tready(temp_udp_payload_axis_tready),
        .s_udp_payload_axis_tlast(temp_udp_payload_axis_tlast),
        .s_udp_payload_axis_tid(temp_udp_payload_axis_tid),
        .s_udp_payload_axis_tdest(temp_udp_payload_axis_tdest),
        .s_udp_payload_axis_tuser(temp_udp_payload_axis_tuser),

        .m_udp_hdr_valid(udp_tx_header_if_source.hdr_valid),
        .m_udp_hdr_ready(udp_tx_header_if_source.hdr_ready),
        .m_eth_dest_mac(udp_tx_header_if_source.eth_dest_mac),
        .m_eth_src_mac(udp_tx_header_if_source.eth_src_mac),
        .m_eth_type(udp_tx_header_if_source.eth_type),
        .m_ip_version(udp_tx_header_if_source.ip_version),
        .m_ip_ihl(udp_tx_header_if_source.ip_ihl),
        .m_ip_dscp(udp_tx_header_if_source.ip_dscp),
        .m_ip_ecn(udp_tx_header_if_source.ip_ecn),
        .m_ip_length(udp_tx_header_if_source.ip_length),
        .m_ip_identification(udp_tx_header_if_source.ip_identification),
        .m_ip_flags(udp_tx_header_if_source.ip_flags),
        .m_ip_fragment_offset(udp_tx_header_if_source.ip_fragment_offset),
        .m_ip_ttl(udp_tx_header_if_source.ip_ttl),
        .m_ip_protocol(udp_tx_header_if_source.ip_protocol),
        .m_ip_header_checksum(udp_tx_header_if_source.ip_header_checksum),
        .m_ip_source_ip(udp_tx_header_if_source.ip_source_ip),
        .m_ip_dest_ip(udp_tx_header_if_source.ip_dest_ip),
        .m_udp_source_port(udp_tx_header_if_source.source_port),
        .m_udp_dest_port(udp_tx_header_if_source.dest_port),
        .m_udp_length(udp_tx_header_if_source.length),
        .m_udp_checksum(udp_tx_header_if_source.checksum),

        .m_udp_payload_axis_tdata(udp_tx_payload_if_source.tdata),
        .m_udp_payload_axis_tkeep(udp_tx_payload_if_source.tkeep),
        .m_udp_payload_axis_tvalid(udp_tx_payload_if_source.tvalid),
        .m_udp_payload_axis_tready(udp_tx_payload_if_source.tready),
        .m_udp_payload_axis_tlast(udp_tx_payload_if_source.tlast),
        .m_udp_payload_axis_tid(udp_tx_payload_if_source.tid),
        .m_udp_payload_axis_tdest(udp_tx_payload_if_source.tdest),
        .m_udp_payload_axis_tuser(udp_tx_payload_if_source.tuser),

        .enable(enable),
        .select(select)
    );
endmodule

`default_nettype wire