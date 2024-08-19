"""
Run VUnit
"""

from pathlib import Path
import sys
import random

sys.path.append('../../../srcs')
import vunit_util

# NOTE: This assumes the location of the ./rtl and ./workspace directory relative to where this is run from
WORKSPACE = Path(__file__).parent / ".." / ".." / ".." / ".." / "workspace" / "modelsim"
RTL_ROOT = Path(__file__).parent / ".." / ".." / ".." / ".." / "rtl"
LIB_ROOT = Path(__file__).parent / ".." / ".." / ".." / ".." / "lib"

vu, lib = vunit_util.init(WORKSPACE)

vunit_util.add_source(lib, RTL_ROOT, "./syn/axis/axis_adapter_wrapper/axis_adapter_wrapper.sv")
vunit_util.add_source(lib, LIB_ROOT, "./verilog-axis/rtl/axis_adapter.v")

vunit_util.add_source(lib, RTL_ROOT, "./syn/axis/axis_if/axis_if.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/axis/axis_bfm/axis_bfm.sv")

vunit_util.add_source(lib, RTL_ROOT, "./syn/ethernet/udp_tx_header_if/udp_tx_header_if.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/ethernet/udp_header_bfm/udp_tx_header_bfm.sv")

vunit_util.add_source(lib, RTL_ROOT, "./syn/ethernet/udp_rx_header_if/udp_rx_header_if.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/ethernet/udp_header_bfm/udp_rx_header_bfm.sv")

vunit_util.add_source(lib, RTL_ROOT, "./sim/ethernet/udp_axis_master/udp_axis_master_tb.sv")
vunit_util.add_source(lib, RTL_ROOT, "./syn/ethernet/udp_axis_master/udp_axis_master.sv")

# Create testbench
tb = lib.test_bench("udp_axis_master_tb")

tb.add_config("TEST")

vu.main()