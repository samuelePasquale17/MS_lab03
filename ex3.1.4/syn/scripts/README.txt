This folder contains the scripts that may be needed to run the synthesis of the WRF.
In order to synthetize the windowed register file follow these steps:
0. Copy all the VHDL netlist of the WRF in the working directory (which must constains also the scripts file needed in the next steps below)
1. Open the terminal and run "source generation_LUT_ROM.scr" for the generation of the LUT with the proper size read from the constants.vhd file
2. Open Design Vision
3. Within the Design Vision's console run "source synthesis_WRF.tlc"
