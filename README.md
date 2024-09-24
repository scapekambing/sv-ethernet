# SystemVerilog Ethernet Components
## Introduction
A collection of Ethernet components consisting of wrappers of [verilog-ethernet](https://github.com/alexforencich/verilog-ethernet), test infrastructure and custom modules and interfaces. All test benches utilise [VUnit](https://github.com/VUnit/vunit) and Modelsim.

## Testing
To run the testbench open the `python` directory and run the python file relevant for each testbench using for example `python udp_axis_master_tb.py`. To run with a gui use `python udp_axis_master_tb.py -g`. If you wish to run specific tests within each testbench you append the command with the test name.
