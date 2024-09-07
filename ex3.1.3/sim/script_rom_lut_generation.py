import sys
import math
import re

# function for reading F, M, N directly from the constants file
def read_file(file_name):
    try:
        with open(file_name, 'r') as file:
            content = file.read()
            matches = re.findall(r'(\bN_WRF\b|\bM_WRF\b|\bF_WRF\b)\s*:\s*integer\s*:=\s*(\d+);', content)
            N, M, F = None, None, None
            for match in matches:
                if match[0] == 'N_WRF':
                    N = int(match[1])
                elif match[0] == 'M_WRF':
                    M = int(match[1])
                elif match[0] == 'F_WRF':
                    F = int(match[1])
            return N, M, F
    except FileNotFoundError:
        print("The specified file does not exist.")
    except Exception as e:
        print("An error occurred:", e)

# filename -> file name
# F -> number of windows 
# N -> number of registers per block
# M -> number of global registers
def generate_LUT(filename, F, N, M):
    WIDTHaddr = math.ceil(math.log(3*N + M, 2))
    WIDTHout = math.ceil(math.log(3*N*F + M, 2))

    content = f"""library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use WORK.constants.all;

entity LUT_ROM is
	generic (
		N : integer := N_WRF;
		F : integer := F_WRF;
		M : integer := M_WRF
	);
	port(
		Clk : in std_logic;
		addr1, addr2 : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0); -- address 
		en   : in std_logic_vector(F-1 downto 0); -- ROM Enable, for additiona
		dout1, dout2 : out std_logic_vector(integer(ceil(log2(real(2*N*F + M) + real(1))))-1 downto 0)
	);
end entity;

architecture beh of LUT_ROM is 
begin
"""
##########################################################################
# starting architecture definition
##########################################################################

    for out_val_port in range(1, 3):
        content += f"\n\n    -- Output port #{out_val_port}"
        content += f"\n    process(Clk, addr{out_val_port}, en)\n        variable en_addr : std_logic_vector({F}+{WIDTHaddr}-1 downto 0);\n    begin\n        en_addr := en & addr"f"{out_val_port};\n        if (rising_edge(Clk)) then \n"
        content += f"            case (en_addr) is"
        # Adding LUT content based on #windows, #registers per block and #global registers
        en_val = int(2**(F-1))
        out_val = 0
        addr_val = 0
        out_val_globals = 2*N*F
        for i in range(F):
            content += f"\n        -- block #{i+1}\n"
            content += f"\n        -- 3*N registers for IN/LOC/OUT registers\n"
            for j in range(3*N):
                if j == 2*N and i == F-1:
                    out_val = 0

                content += f"                when "f"\"{en_val:0{F}b}"""f"{j:0{WIDTHaddr}b}\""" =>\n            "f"        dout{out_val_port} <= \"{out_val:0{WIDTHout}b}\";\n"
                out_val += 1
            
            content += f"\n    -- M global registers\n"
            out_val_globals = 2*N*F
            for k in range(M):
                content += f"                when "f"\"{en_val:0{F}b}"""f"{k+3*N:0{WIDTHaddr}b}\""" =>\n            "f"        dout{out_val_port} <= "f"\"{out_val_globals:0{WIDTHout}b}\";\n"
                out_val_globals += 1
            en_val = int(en_val/2)
            out_val -= N
        
        content += f"\n    -- If enable not active the default output it 0\n"
        content += f"                when others =>\n            "f"        dout{out_val_port} <= (others => '0');\n"
        content += f"            end case;\n        end if;\n"
        content += f"    end process;"



##########################################################################
# end of the architecture
##########################################################################
    content += """
end architecture;

configuration CFG_LUT_ROM_ARCHBEH of LUT_ROM is
    for beh
    end for; 
end configuration;"""

    #  writing into the generated file the content generated 
    with open(filename, "w") as file:
        file.write(content)


# check on the number of parameters
if len(sys.argv) != 1:
    print("Usage: python generate_vhdl.py") # error message
    sys.exit(1)

# getting parameters
filename = "LUT_ROM.vhd"
source_filename = "constants.vhd"

N, M, F = read_file(source_filename) # read N, F, M from constants.vhd file

# function call
generate_LUT(filename, F, N, M) # generation of the LUT
