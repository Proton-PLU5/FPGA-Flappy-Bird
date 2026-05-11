library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Lets use this file to manage Rendering
entity TitleRenderer is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync, horz_sync : IN std_logic;
		  SW : IN std_logic_vector(9 downto 0);
		  KEY : IN std_logic_vector(3 DOWNTO 0);
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic_vector(3 downto 0)
    );
end entity TitleRenderer;

architecture behaviour of TitleRenderer is
    component title_display is
	 
			generic (
				text_string : string := "FLAPPY BOSS";
				text_size : integer := 11;
				SIZE : integer := 4
			);

        port (
            clk          : in  std_logic;
            pixel_row    : in  std_logic_vector(9 downto 0);
            pixel_column : in  std_logic_vector(9 downto 0);
            pixel_on     : out std_logic;
				text_row : in integer;
				text_col_start : in integer
        );
    end component title_display;

    signal main_title_enable : std_logic;
	 signal sub_title_enable : std_logic;
begin
    
    MAIN_TITLE : title_display port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => main_title_enable, -- Just use the red channel for the title
		  text_row => 100,
		  text_col_start => 144
    );
	 
	 SUB_TITLE : title_display generic map (text_string => "RETURN OF THE SKELEKING", text_size => 6, SIZE => 3) port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => sub_title_enable, -- Just use the red channel for the title
		  text_row => 200,
		  text_col_start => 136
    );

    -- Logic to determine output
    process (clk25Mhz)
    begin
        if (main_title_enable = '1' OR sub_title_enable = '1') then
            red <= "1111";
            green <= "1111";
            blue <= "1111";
        else
            red <= "0000";
            green <= "0000";
            blue <= "0000";
        end if;
    end process;
end architecture behaviour;