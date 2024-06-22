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

vunit_util.add_source(lib, RTL_ROOT, "./syn/axil/axil_if/axil_if.sv")
vunit_util.add_source(lib, RTL_ROOT, "./syn/axil/axil_ram_wrapper/axil_ram_wrapper.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/axil/axil_bfm/axil_bfm.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/axil/axil_ram_wrapper/axil_ram_wrapper_tb.sv")
vunit_util.add_source(lib, LIB_ROOT, "./verilog-axi/rtl/axil_ram.v")

# Create testbench
tb = lib.test_bench("axil_ram_wrapper_tb")

tb.add_config("TEST", parameters={
    "PIPELINE_OUTPUT"   : 0,
    "ADDR_WIDTH"        : 16,
    "DATA_WIDTH"        : 32,
    "ADDRESS_1"         : 132,
    "ADDRESS_2"         : 78,
    "DATA_1"            : 88943,
    "DATA_2"            : 1332,
    "USE_RANDOM_WAIT"   : 0
    })

# AXIS config for reference
#tb.add_config("TDATA_WIDTH=64_TDATA=0x25", parameters={
#    "AXIS_TDATA_WIDTH"  : 64,
#    "TDATA"             : 0x25,
#    "TSTRB"             : 1,
#    "TKEEP"             : 1,
#    "AXIS_TID_WIDTH"    : 8,
#    "TID"               : 5,
#    "AXIS_TDEST_WIDTH"  : 8,
#    "TDEST"             : 3,
#    "AXIS_TUSER_WIDTH"  : 3,
#    "TUSER"             : 2
#    })

vu.main()