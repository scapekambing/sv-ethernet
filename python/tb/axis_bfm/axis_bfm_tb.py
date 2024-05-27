"""
Run VUnit
"""

from pathlib import Path
import sys
import random

sys.path.append('../../srcs')
import vunit_util

# NOTE: This assumes the location of the ./rtl and ./workspace directory relative to where this is run from
WORKSPACE = Path(__file__).parent / ".." / ".." / ".." / "workspace" / "modelsim"
RTL_ROOT = Path(__file__).parent / ".." / ".." / ".." / "rtl"

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)

vunit_util.add_source(lib, RTL_ROOT, "./syn/axi-stream/axi-stream_if/axi-stream_if.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/axis_bfm/axis_bfm.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/axis_bfm/axis_bfm_tb.sv")

# Create testbench
tb = lib.test_bench("axis_bfm_tb")

TDATA = []

max_int = [] # Array to store maximum unsigned int values

for i in range(8):
    max_int.append(int(8 * pow(2, i) - 1))


for i in range(3):
    TDATA.append(random.randint(0, max_int[0]))

# Override testbench parameters
for i in range(2):
    for j in range(2):
        tb.add_config(
            "TDATA_0x%X_RANDOM_%d" % (
                TDATA[i],
                j
            ),
            parameters={
                "TDATA" : TDATA[i],
                "USE_RANDOM_WAIT" : j
            }
        )

# Suppress vopt deprecation error, uncomment if encountering issue
#vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()