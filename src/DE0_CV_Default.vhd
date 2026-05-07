library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE0_CV_Default is
    port (
        CLOCK_50 : in std_logic;
		  VGA_G, VGA_B, VGA_R : out std_logic_vector(3 downto 0);
		  VGA_HS : out std_logic;
		  VGA_VS : out std_logic
    );
end DE0_CV_Default;

architecture behavior of DE0_CV_Default is
    
    component VGA_SYNC
        port(
            clock_25Mhz, red, green, blue : IN STD_LOGIC;
			red_out, green_out, blue_out, horiz_sync_out, vert_sync_out	: OUT STD_LOGIC;
			pixel_row, pixel_column: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
    end component;

    component ClockDivider
        port (
            Clk_in : in std_logic;
            Clk_out : out std_logic
        );
    end component;

    signal Clk25Mhz : std_logic;
	 signal red_out, blue_out, green_out : std_logic := '0';

begin

    Clock_Divider : ClockDivider
        port map (
            Clk_in => CLOCK_50,
            Clk_out => Clk25Mhz
        );

    VGA : VGA_SYNC
        -- Display white color to check if it works lol
        port map (
            clock_25Mhz => Clk25Mhz,
            red => '1', 
            green => '1',
            blue => '1',
            red_out => red_out,
            green_out => green_out,
            blue_out => blue_out,
            horiz_sync_out => VGA_HS,
            vert_sync_out => VGA_VS,
            pixel_row => open,
            pixel_column => open
        );
    
	 VGA_R <= (others => red_out);
	 VGA_G <= (others => red_out);
	 VGA_B <= (others => red_out);
	 
end architecture behavior;