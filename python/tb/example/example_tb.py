"""
Run VUnit
"""

from pathlib import Path
import sys

sys.path.append('../../srcs')
import vunit_util

# NOTE: This assumes the location of the ./rtl and ./workspace directory relative to where this is run from
WORKSPACE = Path(__file__).parent / ".." / ".." / ".." / "workspace" / "modelsim"
RTL_ROOT = Path(__file__).parent / ".." / ".." / ".." / "rtl"

# Create source list, add here for more sources
sources = [
    RTL_ROOT / "./syn/example/example.sv",
    RTL_ROOT / "./sim/example/example_tb.sv",
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("example_tb")

# Override testbench parameters
for INVERTER in [0, 1]:
    tb.add_config(
        "INVERTER_%d" % (
            INVERTER
        ),
        parameters={
            "INVERTER" : INVERTER
        }
    )

# Suppress vopt deprecation error, uncomment if encountering issue
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()