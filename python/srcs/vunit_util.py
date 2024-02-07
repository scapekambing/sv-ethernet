from pathlib import Path

from vunit import VUnitCLI
from vunit.verilog import VUnit

def init(workspace):
    cli = VUnitCLI()
    cli.parser.set_defaults(output_path=workspace)

    vu = VUnit.from_args(args=cli.parse_args())
    lib = vu.add_library("lib")

    return(vu, lib)

def add_source(lib, root, source):
    full_source_path = root / source
    lib.add_source_file(full_source_path)