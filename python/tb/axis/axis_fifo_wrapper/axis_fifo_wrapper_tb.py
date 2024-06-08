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

vunit_util.add_source(lib, RTL_ROOT, "./syn/axis/axis_if/axis_if.sv")
vunit_util.add_source(lib, RTL_ROOT, "./syn/axis/axis_fifo_wrapper/axis_fifo_wrapper.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/axis/axis_bfm/axis_bfm.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/axis/axis_fifo_wrapper_tb/axis_fifo_wrapper_tb.sv")
vunit_util.add_source(lib, LIB_ROOT, "./verilog-axis/rtl/axis_fifo.v")

# Create testbench
tb = lib.test_bench("axis_fifo_wrapper_tb")

tb.add_config("TDATA=0x08", parameters={"TDATA" : 8})

vu.main()