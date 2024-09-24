/**
 * @file udp_tx_header_bfm.sv
 * 
 * @author Mani Magnusson
 * @date   2024
 * 
 * @brief UDP TX Header (logic to PHY) bus functional model
 */

`timescale 1ns / 1ps
`default_nettype none

package udp_tx_header_bfm;
class UDP_TX_HEADER_SLAVE_BFM # ();
    typedef virtual UDP_TX_HEADER_IF v_udp_tx_header_if_t;

    v_udp_tx_header_if_t udp_tx_header_if;

    function new(v_udp_tx_header_if_t udp_tx_header_if_in);
        this.udp_tx_header_if = udp_tx_header_if_in;
    endfunction

    task automatic reset_task();
        this.udp_tx_header_if.hdr_ready = 1'b0;
    endtask

    task automatic transfer(
        ref var logic clk,

        // IP part
        output var logic [5:0] ip_dscp,
        output var logic [1:0] ip_ecn,
        output var logic [7:0] ip_ttl,
        output var logic [31:0] ip_source_ip,
        output var logic [31:0] ip_dest_ip,

        // UDP specific part
        output var logic [15:0] source_port,
        output var logic [15:0] dest_port,
        output var logic [15:0] length,
        output var logic [15:0] checksum
    );
        this.udp_tx_header_if.hdr_ready = 1'b1;

        do begin
            @ (posedge clk);
        end while (this.udp_tx_header_if.hdr_valid === 1'b0);

        ip_dscp = this.udp_tx_header_if.ip_dscp;
        ip_ecn = this.udp_tx_header_if.ip_ecn;
        ip_ttl = this.udp_tx_header_if.ip_ttl;
        ip_source_ip = this.udp_tx_header_if.ip_source_ip;
        ip_dest_ip = this.udp_tx_header_if.ip_dest_ip;

        source_port = this.udp_tx_header_if.source_port;
        dest_port = this.udp_tx_header_if.dest_port;
        length = this.udp_tx_header_if.length;
        checksum = this.udp_tx_header_if.checksum;

        this.udp_tx_header_if.hdr_ready = 1'b0;
    endtask
endclass

class UDP_TX_HEADER_MASTER_BFM # ();
    typedef virtual UDP_TX_HEADER_IF v_udp_tx_header_if_t;

    v_udp_tx_header_if_t udp_tx_header_if;

    function new(v_udp_tx_header_if_t udp_tx_header_if_in);
        this.udp_tx_header_if = udp_tx_header_if_in;
    endfunction

    task automatic reset_task();
        this.udp_tx_header_if.hdr_valid = 1'b0;

        this.udp_tx_header_if.ip_dscp = '0;
        this.udp_tx_header_if.ip_ecn = '0;
        this.udp_tx_header_if.ip_ttl = '0;
        this.udp_tx_header_if.ip_source_ip = '0;
        this.udp_tx_header_if.ip_dest_ip = '0;

        this.udp_tx_header_if.source_port = '0;
        this.udp_tx_header_if.dest_port = '0;
        this.udp_tx_header_if.length = '0;
        this.udp_tx_header_if.checksum = '0;
    endtask

    task automatic transfer(
        ref var logic clk,

        // IP part
        input var logic [5:0] ip_dscp,
        input var logic [1:0] ip_ecn,
        input var logic [7:0] ip_ttl,
        input var logic [31:0] ip_source_ip,
        input var logic [31:0] ip_dest_ip,

        // UDP specific part
        input var logic [15:0] source_port,
        input var logic [15:0] dest_port,
        input var logic [15:0] length,
        input var logic [15:0] checksum
    );
        this.udp_tx_header_if.ip_dscp = ip_dscp;
        this.udp_tx_header_if.ip_ecn = ip_ecn;
        this.udp_tx_header_if.ip_ttl = ip_ttl;
        this.udp_tx_header_if.ip_source_ip = ip_source_ip;
        this.udp_tx_header_if.ip_dest_ip = ip_dest_ip;

        this.udp_tx_header_if.source_port = source_port;
        this.udp_tx_header_if.dest_port = dest_port;
        this.udp_tx_header_if.length = length;
        this.udp_tx_header_if.checksum = checksum;

        this.udp_tx_header_if.hdr_valid = 1'b1;

        do begin
            @ (posedge clk);
        end while (this.udp_tx_header_if.hdr_ready === 1'b0);

        this.udp_tx_header_if.hdr_valid = 1'b0;

        this.udp_tx_header_if.ip_dscp = '0;
        this.udp_tx_header_if.ip_ecn = '0;
        this.udp_tx_header_if.ip_ttl = '0;
        this.udp_tx_header_if.ip_source_ip = '0;
        this.udp_tx_header_if.ip_dest_ip = '0;

        this.udp_tx_header_if.source_port = '0;
        this.udp_tx_header_if.dest_port = '0;
        this.udp_tx_header_if.length = '0;
        this.udp_tx_header_if.checksum = '0;
    endtask
endclass
endpackage

`default_nettype wire