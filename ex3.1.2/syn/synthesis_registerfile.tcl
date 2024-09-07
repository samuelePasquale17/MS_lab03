analyze -library WORK -format vhdl {constants.vhd}
analyze -library WORK -format vhdl {registerfile.vhd}
elaborate registerfile -architecture ARCHBEH -parameters N=32 -parameters M=5 -library work
compile -exact_map
report_timing > reportTimingRF32bit.txt
report_area > reportAreaRF32bit.txt
create_clock -name "CLK" -period 2 Clk
report_clock
compile
report_area > reportAreaRF32bitOptimized.txt
report_timing > reportTimingRF32bitOptimized.txt
set_max_delay 2 -from [all_inputs] -to [all_outputs]
compile
report_timing > reportTimingRF32bitOptimized2.txt
