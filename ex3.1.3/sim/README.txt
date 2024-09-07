In order to simulate the windowed register file using our script follow these steps:
1. Launch questaSim
2. Within the QuestaSim's console run "source simulation_windowedRegisterFile.scr" to compile and simulate the register file

Attention!
If you decide to change the size of the windowed register file (N, M, F) you must change also the values in the constants.vhd file, and not only in the testbench for example. This is due to the fact that in our design we use a LUT for the address translation (from virtual to physical). However the design of this LUT is done automatically by a python script that reads by its own the N, M and F values from the constants.vhd file. Therefore modify also the constants values (only the numeric value, not the variable name or something else!).
