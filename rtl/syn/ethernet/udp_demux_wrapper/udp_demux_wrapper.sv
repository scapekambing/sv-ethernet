/**
 * @file udp_demux_wrapper.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief Wrapper for udp_demux.v from Alex Forencich
 */

`default_nettype none

module udp_demux_wrapper # (
    parameter int M_COUNT = 2
) (
    input var logic                         clk,
    input var logic                         reset,

    UDP_RX_HEADER_IF.Source [M_COUNT-1:0]   udp_rx_header_if_source,
    AXIS_IF.Transmitter [M_COUNT-1:0]       udp_rx_payload_if_source,

    UDP_RX_HEADER_IF.Sink                   udp_rx_header_if_sink,
    AXIS_IF.Receiver                        udp_rx_payload_if_sink,

    input var logic                         enable,
    input var logic                         drop,
    input var logic [$clog2(M_COUNT)-1:0]   select
);
    generate
        for (genvar i = 0; i < M_COUNT; i++) begin
            initial begin
                assert(udp_rx_payload_if_source[i].TDATA_WIDTH == udp_rx_payload_if_sink.TDATA_WIDTH)
                else $error("Assertion in %m failed, TDATA_WIDTH parameters of AXIS_IF interfaces don't match");
            end

            initial begin
                assert(udp_rx_payload_if_source[i].TID_WIDTH == udp_rx_payload_if_sink.TID_WIDTH)
                else $error("Assertion in %m failed, TID_WIDTH parameters of AXIS_IF interfaces don't match");
            end

            initial begin
                assert(udp_rx_payload_if_source[i].TDEST_WIDTH == udp_rx_payload_if_sink.TDEST_WIDTH)
                else $error("Assertion in %m failed, TDEST_WIDTH parameters of AXIS_IF interfaces don't match");
            end

            initial begin
                assert(udp_rx_payload_if_source[i].TUSER_WIDTH == udp_rx_payload_if_sink.TUSER_WIDTH)
                else $error("Assertion in %m failed, TUSER_WIDTH parameters of AXIS_IF interfaces don't match");
            end

            initial begin
                assert(udp_rx_payload_if_source[i].TKEEP_ENABLE == udp_rx_payload_if_sink.TKEEP_ENABLE)
                else $error("Assertion in %m failed, TKEEP_ENABLE parameters of AXIS_IF interfaces don't match");
            end

            initial begin
                assert(udp_rx_payload_if_source[i].TWAKEUP_ENABLE == udp_rx_payload_if_sink.TWAKEUP_ENABLE)
                else $error("Assertion in %m failed, TWAKEUP_ENABLE parameters of AXIS_IF interfaces don't match");
            end
        end
    endgenerate

    var logic [M_COUNT-1:0]            temp_udp_hdr_valid;
    var logic [M_COUNT-1:0]            temp_udp_hdr_ready;
    var logic [M_COUNT*48-1:0]         temp_eth_dest_mac;
    var logic [M_COUNT*48-1:0]         temp_eth_src_mac;
    var logic [M_COUNT*16-1:0]         temp_eth_type;
    var logic [M_COUNT*4-1:0]          temp_ip_version;
    var logic [M_COUNT*4-1:0]          temp_ip_ihl;
    var logic [M_COUNT*6-1:0]          temp_ip_dscp;
    var logic [M_COUNT*2-1:0]          temp_ip_ecn;
    var logic [M_COUNT*16-1:0]         temp_ip_length;
    var logic [M_COUNT*16-1:0]         temp_ip_identification;
    var logic [M_COUNT*3-1:0]          temp_ip_flags;
    var logic [M_COUNT*13-1:0]         temp_ip_fragment_offset;
    var logic [M_COUNT*8-1:0]          temp_ip_ttl;
    var logic [M_COUNT*8-1:0]          temp_ip_protocol;
    var logic [M_COUNT*16-1:0]         temp_ip_header_checksum;
    var logic [M_COUNT*32-1:0]         temp_ip_source_ip;
    var logic [M_COUNT*32-1:0]         temp_ip_dest_ip;
    var logic [M_COUNT*16-1:0]         temp_udp_source_port;
    var logic [M_COUNT*16-1:0]         temp_udp_dest_port;
    var logic [M_COUNT*16-1:0]         temp_udp_length;
    var logic [M_COUNT*16-1:0]         temp_udp_checksum;

    var logic [M_COUNT*DATA_WIDTH-1:0] temp_udp_payload_axis_tdata;
    var logic [M_COUNT*KEEP_WIDTH-1:0] temp_udp_payload_axis_tkeep;
    var logic [M_COUNT-1:0]            temp_udp_payload_axis_tvalid;
    var logic [M_COUNT-1:0]            temp_udp_payload_axis_tready;
    var logic [M_COUNT-1:0]            temp_udp_payload_axis_tlast;
    var logic [M_COUNT*ID_WIDTH-1:0]   temp_udp_payload_axis_tid;
    var logic [M_COUNT*DEST_WIDTH-1:0] temp_udp_payload_axis_tdest;
    var logic [M_COUNT*USER_WIDTH-1:0] temp_udp_payload_axis_tuser;

    generate
        for (genvar i = 0; i < M_COUNT; i++) begin
            always_comb begin
                udp_rx_header_if_source[i].hdr_valid            = temp_udp_hdr_valid[i];
                temp_udp_hdr_ready[i]                           = udp_rx_header_if_source[i].hdr_ready;

                udp_rx_header_if_source[i].eth_dest_mac         = temp_eth_dest_mac[48*i+47:48*i];
                udp_rx_header_if_source[i].eth_src_mac          = temp_eth_src_mac[48*i+47:48*i];
                udp_rx_header_if_source[i].eth_type             = temp_eth_type[16*i+15:16*i];

                udp_rx_header_if_source[i].ip_version           = temp_ip_version[4*i+3:4*i];
                udp_rx_header_if_source[i].ip_ihl               = temp_ip_ihl[4*i+4:4*i];
                udp_rx_header_if_source[i].ip_dscp              = temp_ip_dscp[6*i+5:6*i];
                udp_rx_header_if_source[i].ip_ecn               = temp_ip_ecn[2*i+1:2*i];
                udp_rx_header_if_source[i].ip_length            = temp_ip_length[16*i+15:16*i];
                udp_rx_header_if_source[i].ip_identification    = temp_ip_identification[16*i+15:16*i];
                udp_rx_header_if_source[i].ip_flags             = temp_ip_flags[3*i+2:3*i];
                udp_rx_header_if_source[i].ip_fragment_offset   = temp_ip_fragment_offset[13*i+12:13*i];
                udp_rx_header_if_source[i].ip_ttl               = temp_ip_ttl[8*i+7:8*i];
                udp_rx_header_if_source[i].ip_protocol          = temp_ip_protocol[8*i+7:8*i];
                udp_rx_header_if_source[i].ip_header_checksum   = temp_ip_header_checksum[16*i+15:16*i];
                udp_rx_header_if_source[i].ip_source_ip         = temp_ip_source_ip[32*i+31:32*i];
                udp_rx_header_if_source[i].ip_dest_ip           = temp_ip_dest_ip[32*i+31:32*i];

                udp_rx_header_if_source[i].source_port          = temp_udp_source_port[16*i+15:16*i];
                udp_rx_header_if_source[i].dest_port            = temp_udp_dest_port[16*i+15:16*i];
                udp_rx_header_if_source[i].length               = temp_udp_length[16*i+15:16*i];
                udp_rx_header_if_source[i].checksum             = temp_udp_checksum[16*i+15:16*i];
                
                udp_rx_payload_if_source[i].tvalid  = temp_udp_payload_axis_tvalid[i];
                temp_udp_payload_axis_tready[i]     = udp_rx_payload_if_source[i].tready;

                udp_rx_payload_if_source[i].tdata   = temp_udp_payload_axis_tdata[TDATA_WIDTH*i+(TDATA_WIDTH-1):TDATA_WIDTH*i];
                udp_rx_payload_if_source[i].tkeep   = temp_udp_payload_axis_tkeep[TKEEP_WIDTH*i+(TKEEP_WIDTH-1):TKEEP_WIDTH*i];
                udp_rx_payload_if_source[i].tlast   = temp_udp_payload_axis_tlast[i];
                udp_rx_payload_if_source[i].tid     = temp_udp_payload_axis_tid[TID_WIDTH*i+(TID_WIDTH-1):TID_WIDTH*i];
                udp_rx_payload_if_source[i].tdest   = temp_udp_payload_axis_tdest[TDEST_WIDTH*i+(TDEST_WIDTH-1):TDEST_WIDTH*i];
                udp_rx_payload_if_source[i].tuser   = temp_udp_payload_axis_tuser[TUSER_WIDTH*i+(TUSER_WIDTH-1):TUSER_WIDTH*i];
            end
        end
    endgenerate

    localparam int TDATA_WIDTH = udp_rx_payload_if_sink.TDATA_WIDTH;
    localparam int TID_WIDTH = udp_rx_payload_if_sink.TID_WIDTH;
    localparam int TDEST_WIDTH = udp_rx_payload_if_sink.TDEST_WIDTH;
    localparam int TUSER_WIDTH = udp_rx_payload_if_sink.TUSER_WIDTH;
    localparam int TKEEP_ENABLE = udp_rx_payload_if_sink.TKEEP_ENABLE;
    localparam int TKEEP_WIDTH = TDATA_WIDTH / 8;

    udp_demux # (
        .M_COUNT(M_COUNT),
        .DATA_WIDTH(TDATA_WIDTH),
        .KEEP_ENABLE(TKEEP_ENABLE),
        .KEEP_WIDTH(TKEEP_WIDTH),
        .ID_ENABLE(TID_WIDTH > 0),
        .ID_WIDTH(TID_WIDTH),
        .DEST_ENABLE(TDEST_WIDTH > 0),
        .DEST_WIDTH(TDEST_WIDTH),
        .USER_ENABLE(TUSER_WIDTH > 0),
        .USER_WIDTH(TUSER_WIDTH)
    ) udp_demux_inst (
        .clk(clk),
        .rst(reset),
        
        .m_udp_hdr_valid(temp_udp_hdr_valid),
        .m_udp_hdr_ready(temp_udp_hdr_ready),
        .m_eth_dest_mac(temp_eth_dest_mac),
        .m_eth_src_mac(temp_eth_src_mac),
        .m_eth_type(temp_eth_type),
        .m_ip_version(temp_ip_version),
        .m_ip_ihl(temp_ip_ihl),
        .m_ip_dscp(temp_ip_dscp),
        .m_ip_ecn(temp_ip_ecn),
        .m_ip_length(temp_ip_length),
        .m_ip_identification(temp_ip_identification),
        .m_ip_flags(temp_ip_flags),
        .m_ip_fragment_offset(temp_ip_fragment_offset),
        .m_ip_ttl(temp_ip_ttl),
        .m_ip_protocol(temp_ip_protocol),
        .m_ip_header_checksum(temp_ip_header_checksum),
        .m_ip_source_ip(temp_ip_source_ip),
        .m_ip_dest_ip(temp_ip_dest_ip),
        .m_udp_source_port(temp_udp_source_port),
        .m_udp_dest_port(temp_udp_dest_port),
        .m_udp_length(temp_udp_length),
        .m_udp_checksum(temp_udp_checksum),

        .m_udp_payload_axis_tdata(temp_udp_payload_axis_tdata),
        .m_udp_payload_axis_tkeep(temp_udp_payload_axis_tkeep),
        .m_udp_payload_axis_tvalid(temp_udp_payload_axis_tvalid),
        .m_udp_payload_axis_tready(temp_udp_payload_axis_tready),
        .m_udp_payload_axis_tlast(temp_udp_payload_axis_tlast),
        .m_udp_payload_axis_tid(temp_udp_payload_axis_tid),
        .m_udp_payload_axis_tdest(temp_udp_payload_axis_tdest),
        .m_udp_payload_axis_tuser(temp_udp_payload_axis_tuser),

        .s_udp_hdr_valid(udp_rx_header_if_sink.hdr_valid),
        .s_udp_hdr_ready(udp_rx_header_if_sink.hdr_ready),
        .s_eth_dest_mac(udp_rx_header_if_sink.eth_dest_mac),
        .s_eth_src_mac(udp_rx_header_if_sink.eth_src_mac),
        .s_eth_type(udp_rx_header_if_sink.eth_type),
        .s_ip_version(udp_rx_header_if_sink.ip_version),
        .s_ip_ihl(udp_rx_header_if_sink.ip_ihl),
        .s_ip_dscp(udp_rx_header_if_sink.ip_dscp),
        .s_ip_ecn(udp_rx_header_if_sink.ip_ecn),
        .s_ip_length(udp_rx_header_if_sink.ip_length),
        .s_ip_identification(udp_rx_header_if_sink.ip_identification),
        .s_ip_flags(udp_rx_header_if_sink.ip_flags),
        .s_ip_fragment_offset(udp_rx_header_if_sink.ip_fragment_offset),
        .s_ip_ttl(udp_rx_header_if_sink.ip_ttl),
        .s_ip_protocol(udp_rx_header_if_sink.ip_protocol),
        .s_ip_header_checksum(udp_rx_header_if_sink.ip_header_checksum),
        .s_ip_source_ip(udp_rx_header_if_sink.ip_source_ip),
        .s_ip_dest_ip(udp_rx_header_if_sink.ip_dest_ip),
        .s_udp_source_port(udp_rx_header_if_sink.source_port),
        .s_udp_dest_port(udp_rx_header_if_sink.dest_port),
        .s_udp_length(udp_rx_header_if_sink.length),
        .s_udp_checksum(udp_rx_header_if_sink.checksum),

        .s_udp_payload_axis_tdata(udp_rx_payload_if_sink.tdata),
        .s_udp_payload_axis_tkeep(udp_rx_payload_if_sink.tkeep),
        .s_udp_payload_axis_tvalid(udp_rx_payload_if_sink.tvalid),
        .s_udp_payload_axis_tready(udp_rx_payload_if_sink.tready),
        .s_udp_payload_axis_tlast(udp_rx_payload_if_sink.tlast),
        .s_udp_payload_axis_tid(udp_rx_payload_if_sink.tid),
        .s_udp_payload_axis_tdest(udp_rx_payload_if_sink.tdest),
        .s_udp_payload_axis_tuser(udp_rx_payload_if_sink.tuser),

        .enable(enable),
        .drop(drop),
        .select(select)
    );
endmodule

`default_nettype wire