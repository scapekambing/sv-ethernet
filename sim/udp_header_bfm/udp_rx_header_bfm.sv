/**
 * @file udp_rx_header_bfm.sv
 * 
 * @author Mani Magnusson
 * @date   2024
 * 
 * @brief UDP RX Header (PHY to logic) bus functional model
 */

`timescale 1ns / 1ps
`default_nettype none

package udp_rx_header_bfm;
class UDP_RX_HEADER_SLAVE_BFM # ();
    typedef virtual UDP_RX_HEADER_IF v_udp_rx_header_if_t;

    v_udp_rx_header_if_t udp_rx_header_if;

    function new(v_udp_rx_header_if_t udp_rx_header_if_in);
        this.udp_rx_header_if = udp_rx_header_if_in;
    endfunction

    task automatic reset_task();
        this.udp_rx_header_if.hdr_ready = 1'b0;
    endtask

    task automatic transfer(
        ref var logic               clk,

        output var logic [47:0]     eth_dest_mac,
        output var logic [47:0]     eth_src_mac,
        output var logic [15:0]     eth_type,

        output var logic [3:0]      ip_version,
        output var logic [3:0]      ip_ihl,
        output var logic [5:0]      ip_dscp,
        output var logic [1:0]      ip_ecn,
        output var logic [15:0]     ip_length,
        output var logic [15:0]     ip_identification,
        output var logic [2:0]      ip_flags,
        output var logic [12:0]     ip_fragment_offset,
        output var logic [7:0]      ip_ttl,
        output var logic [7:0]      ip_protocol,
        output var logic [15:0]     ip_header_checksum,
        output var logic [31:0]     ip_source_ip,
        output var logic [31:0]     ip_dest_ip,

        output var logic [15:0]     source_port,
        output var logic [15:0]     dest_port,
        output var logic [15:0]     length,
        output var logic [15:0]     checksum
    );
        this.udp_rx_header_if.hdr_ready = 1'b1;

        do begin
            @ (posedge clk);
        end while (this.udp_rx_header_if.hdr_valid === 1'b0);

        eth_dest_mac        = this.udp_rx_header_if.eth_dest_mac;
        eth_src_mac         = this.udp_rx_header_if.eth_src_mac;
        eth_type            = this.udp_rx_header_if.eth_type;

        ip_version          = this.udp_rx_header_if.ip_version;
        ip_ihl              = this.udp_rx_header_if.ip_ihl;
        ip_dscp             = this.udp_rx_header_if.ip_dscp;
        ip_ecn              = this.udp_rx_header_if.ip_ecn;
        ip_length           = this.udp_rx_header_if.ip_length;
        ip_identification   = this.udp_rx_header_if.ip_identification;
        ip_flags            = this.udp_rx_header_if.ip_flags;
        ip_fragment_offset  = this.udp_rx_header_if.ip_fragment_offset;
        ip_ttl              = this.udp_rx_header_if.ip_ttl;
        ip_protocol         = this.udp_rx_header_if.ip_protocol;
        ip_header_checksum  = this.udp_rx_header_if.ip_header_checksum;
        ip_source_ip        = this.udp_rx_header_if.ip_source_ip;
        ip_dest_ip          = this.udp_rx_header_if.ip_dest_ip;

        source_port         = this.udp_rx_header_if.source_port;
        dest_port           = this.udp_rx_header_if.dest_port;
        length              = this.udp_rx_header_if.length;
        checksum            = this.udp_rx_header_if.checksum;

        this.udp_rx_header_if.hdr_ready = 1'b0;
    endtask

    task automatic simple_transfer(
        ref var logic           clk,

        output var logic [15:0] source_port,
        output var logic [15:0] dest_port,
        output var logic [15:0] length,
        output var logic [15:0] checksum
    );
        logic [47:0]    eth_dest_mac;
        logic [47:0]    eth_src_mac;
        logic [15:0]    eth_type;

        logic [3:0]     ip_version;
        logic [3:0]     ip_ihl;
        logic [5:0]     ip_dscp;
        logic [1:0]     ip_ecn;
        logic [15:0]    ip_length;
        logic [15:0]    ip_identification;
        logic [2:0]     ip_flags;
        logic [12:0]    ip_fragment_offset;
        logic [7:0]     ip_ttl;
        logic [7:0]     ip_protocol;
        logic [15:0]    ip_header_checksum;
        logic [31:0]    ip_source_ip;
        logic [31:0]    ip_dest_ip;

        transfer(
            clk,
            eth_dest_mac,
            eth_src_mac,
            eth_type,
            ip_version,
            ip_ihl,
            ip_dscp,
            ip_ecn,
            ip_length,
            ip_identification,
            ip_flags,
            ip_fragment_offset,
            ip_ttl,
            ip_protocol,
            ip_header_checksum,
            ip_source_ip,
            ip_dest_ip,
            source_port,
            dest_port,
            length,
            checksum
        );
    endtask
endclass

class UDP_RX_HEADER_MASTER_BFM # ();
    typedef virtual UDP_RX_HEADER_IF v_udp_rx_header_if_t;

    v_udp_rx_header_if_t udp_rx_header_if;

    function new(v_udp_rx_header_if_t udp_rx_header_if_in);
        this.udp_rx_header_if = udp_rx_header_if_in;
    endfunction

    task automatic reset_task();
        this.udp_rx_header_if.hdr_valid             = 1'b0;

        this.udp_rx_header_if.eth_dest_mac          = '0;
        this.udp_rx_header_if.eth_src_mac           = '0;
        this.udp_rx_header_if.eth_type              = '0;
        
        this.udp_rx_header_if.ip_version            = '0;
        this.udp_rx_header_if.ip_ihl                = '0;
        this.udp_rx_header_if.ip_dscp               = '0;
        this.udp_rx_header_if.ip_ecn                = '0;
        this.udp_rx_header_if.length                = '0;
        this.udp_rx_header_if.ip_identification     = '0;
        this.udp_rx_header_if.ip_flags              = '0;
        this.udp_rx_header_if.ip_fragment_offset    = '0;
        this.udp_rx_header_if.ip_ttl                = '0;
        this.udp_rx_header_if.ip_protocol           = '0;
        this.udp_rx_header_if.ip_header_checksum    = '0;
        this.udp_rx_header_if.ip_source_ip          = '0;
        this.udp_rx_header_if.ip_dest_ip            = '0;

        this.udp_rx_header_if.source_port           = '0;
        this.udp_rx_header_if.dest_port             = '0;
        this.udp_rx_header_if.length                = '0;
        this.udp_rx_header_if.checksum              = '0;
    endtask

    task automatic transfer(
        ref var logic           clk,

        input var logic [47:0]  eth_dest_mac,
        input var logic [47:0]  eth_src_mac,
        input var logic [15:0]  eth_type,

        input var logic [3:0]   ip_version,
        input var logic [3:0]   ip_ihl,
        input var logic [5:0]   ip_dscp,
        input var logic [1:0]   ip_ecn,
        input var logic [15:0]  ip_length,
        input var logic [15:0]  ip_identification,
        input var logic [2:0]   ip_flags,
        input var logic [12:0]  ip_fragment_offset,
        input var logic [7:0]   ip_ttl,
        input var logic [7:0]   ip_protocol,
        input var logic [15:0]  ip_header_checksum,
        input var logic [31:0]  ip_source_ip,
        input var logic [31:0]  ip_dest_ip,

        input var logic [15:0]  source_port,
        input var logic [15:0]  dest_port,
        input var logic [15:0]  length,
        input var logic [15:0]  checksum
    );
        this.udp_rx_header_if.eth_dest_mac          = eth_dest_mac;
        this.udp_rx_header_if.eth_src_mac           = eth_src_mac;
        this.udp_rx_header_if.eth_type              = eth_type;

        this.udp_rx_header_if.ip_version            = ip_version;
        this.udp_rx_header_if.ip_ihl                = ip_ihl;
        this.udp_rx_header_if.ip_dscp               = ip_dscp;
        this.udp_rx_header_if.ip_ecn                = ip_ecn;
        this.udp_rx_header_if.ip_length             = ip_length;
        this.udp_rx_header_if.ip_identification     = ip_identification;
        this.udp_rx_header_if.ip_flags              = ip_flags;
        this.udp_rx_header_if.ip_fragment_offset    = ip_fragment_offset;
        this.udp_rx_header_if.ip_ttl                = ip_ttl;
        this.udp_rx_header_if.ip_protocol           = ip_protocol;
        this.udp_rx_header_if.ip_header_checksum    = ip_header_checksum;
        this.udp_rx_header_if.ip_source_ip          = ip_source_ip;
        this.udp_rx_header_if.ip_dest_ip            = ip_dest_ip;

        this.udp_rx_header_if.source_port           = source_port;
        this.udp_rx_header_if.dest_port             = dest_port;
        this.udp_rx_header_if.length                = length;
        this.udp_rx_header_if.checksum              = checksum;

        this.udp_rx_header_if.hdr_valid = 1'b1;

        do begin
            @ (posedge clk);
        end while (this.udp_rx_header_if.hdr_ready === 1'b0);

        this.udp_rx_header_if.hdr_valid = 1'b0;

        this.udp_rx_header_if.eth_dest_mac          = '0;
        this.udp_rx_header_if.eth_src_mac           = '0;
        this.udp_rx_header_if.eth_type              = '0;

        this.udp_rx_header_if.ip_version            = '0;
        this.udp_rx_header_if.ip_ihl                = '0;
        this.udp_rx_header_if.ip_dscp               = '0;
        this.udp_rx_header_if.ip_ecn                = '0;
        this.udp_rx_header_if.ip_length             = '0;
        this.udp_rx_header_if.ip_identification     = '0;
        this.udp_rx_header_if.ip_flags              = '0;
        this.udp_rx_header_if.ip_fragment_offset    = '0;
        this.udp_rx_header_if.ip_ttl                = '0;
        this.udp_rx_header_if.ip_protocol           = '0;
        this.udp_rx_header_if.ip_header_checksum    = '0;
        this.udp_rx_header_if.ip_source_ip          = '0;
        this.udp_rx_header_if.ip_dest_ip            = '0;

        this.udp_rx_header_if.source_port           = '0;
        this.udp_rx_header_if.dest_port             = '0;
        this.udp_rx_header_if.length                = '0;
        this.udp_rx_header_if.checksum              = '0;
    endtask

    task automatic simple_transfer(
        ref var logic           clk,

        input var logic [15:0]  source_port,
        input var logic [15:0]  dest_port,
        input var logic [15:0]  length,
        input var logic [15:0]  checksum
    );
        logic [47:0]  eth_dest_mac = 0;
        logic [47:0]  eth_src_mac = 0;
        logic [15:0]  eth_type = 0;

        logic [3:0]   ip_version = 0;
        logic [3:0]   ip_ihl = 0;
        logic [5:0]   ip_dscp = 0;
        logic [1:0]   ip_ecn = 0;
        logic [15:0]  ip_length = 0;
        logic [15:0]  ip_identification = 0;
        logic [2:0]   ip_flags = 0;
        logic [12:0]  ip_fragment_offset = 0;
        logic [7:0]   ip_ttl = 64;
        logic [7:0]   ip_protocol = 0;
        logic [15:0]  ip_header_checksum = 0;
        logic [31:0]  ip_source_ip = {8'd192, 8'd168, 8'd1, 8'd152};
        logic [31:0]  ip_dest_ip = {8'd192, 8'd168, 8'd1, 8'd111};

        transfer(
            clk,
            eth_dest_mac,
            eth_src_mac,
            eth_type,
            ip_version,
            ip_ihl,
            ip_dscp,
            ip_ecn,
            ip_length,
            ip_identification,
            ip_flags,
            ip_fragment_offset,
            ip_ttl,
            ip_protocol,
            ip_header_checksum,
            ip_source_ip,
            ip_dest_ip,
            source_port,
            dest_port,
            length,
            checksum
        );
    endtask
endclass
endpackage

`default_nettype wire