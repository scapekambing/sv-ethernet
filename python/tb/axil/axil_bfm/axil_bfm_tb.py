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

vunit_util.add_source(lib, RTL_ROOT, "./syn/axi-lite/axi-lite_if.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/axil_bfm/axil_bfm.sv")
vunit_util.add_source(lib, RTL_ROOT, "./sim/axil_bfm/axil_bfm_tb.sv")

# Create testbench
tb = lib.test_bench("axil_bfm_tb")

AWADDR = [0x55555555]
WDATA = [0xAAAAAAAA]
ARADDR = [0x55555555]
RDATA = [0xAAAAAAAA]

min_int = -2147483648 # 32-bit signed int
max_int = 2147483648 # 32-bit signed int

for i in range(3):
    AWADDR.append(random.randint(min_int, max_int))
    WDATA.append(random.randint(min_int, max_int))
    ARADDR.append(random.randint(min_int, max_int))
    RDATA.append(random.randint(min_int, max_int))

#Override testbench parameters
for i in range(2):
    for j in range(2):
        tb.add_config(
            "AWADDR_0x%X_WDATA_0x%X_ARADDR_0x%X_RDATA_0x%X_RANDOM_%d" % (
                AWADDR[i],
                WDATA[i],
                ARADDR[i],
                RDATA[i],
                j
            ),
            parameters={
                "AWADDR" : AWADDR[i],
                "WDATA" : WDATA[i],
                "ARADDR" : ARADDR[i],
                "RDATA" : RDATA[i],
                "USE_RANDOM_WAIT" : j
            }
        )

# Suppress vopt deprecation error, uncomment if encountering issue
#vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()