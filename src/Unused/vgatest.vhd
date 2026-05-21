
library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY VGATEST IS
END ENTITY VGATEST;

architecture a of VGATEST is
	signal clk : std_logic  := '0';
	signal red_out : std_logic  := '0';
	signal blue_out : std_logic  := '0';
	signal green_out : std_logic  := '0';
	signal hs : std_logic  := '0';
	signal vs : std_logic  := '0';
	signal pr : STD_LOGIC_VECTOR(9 DOWNTO 0);
	signal pc : STD_LOGIC_VECTOR(9 DOWNTO 0);

	COMPONENT VGA_SYNC IS
		PORT(	clock_25Mhz, red, green, blue : IN STD_LOGIC;
			red_out, green_out, blue_out, horiz_sync_out, vert_sync_out : OUT STD_LOGIC;
			pixel_row, pixel_column: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
	END COMPONENT VGA_SYNC;

	
begin
	a: vga_sync port map(
	clock_25Mhz => clk,
	red => '1',
	green => '1',
	blue => '1',		
	red_out => red_out,
	green_out => green_out,
	blue_out => blue_out,
	horiz_sync_out => hs,
	vert_sync_out => vs,
	pixel_row => pr,
	pixel_column => pc
	);	
	
DUT: process
	begin
		clk <= '0';
		wait for 10 ns;
		clk<= '1';
		wait for 10 ns;
	end process;

end architecture;