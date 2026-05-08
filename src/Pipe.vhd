LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;

entity Pipe is 
    port (
        clk, vert_sync, mouse_left	: IN std_logic;
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
		red, green, blue : OUT std_logic_vector(3 downto 0);
        enabled : OUT std_logic
    );
end entity Pipe;

architecture behaviour of Pipe is
    
begin
    
    
    
end architecture behaviour;