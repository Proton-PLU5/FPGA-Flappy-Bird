library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Lets use this file to manage Rendering
entity Renderer is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync, horz_sync : IN std_logic;
		  SW : IN std_logic_vector(9 downto 0);
		  KEY : IN std_logic_vector(3 DOWNTO 0);
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic_vector(3 downto 0)
    );
end entity Renderer;

architecture behavior of Renderer is
    component Player is
        port (
            clk, vert_sync, mouse_left	: IN std_logic;
            pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
				KEY : IN std_logic_vector(3 DOWNTO 0);
            red, green, blue : OUT std_logic_vector(3 downto 0);
            enabled : OUT std_logic);
    end component Player;

    -- Ball Values
    signal ball_enabled : std_logic := '0';
    signal ball_red, ball_green, ball_blue : std_logic_vector(3 downto 0);

    -- Background Values (Black)
    signal background_red, background_green, background_blue : std_logic_vector(3 downto 0) := "0000";
begin
    
    PLAYER_COMPONENT : Player port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => mouse_left,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
		  KEY => KEY,
        red => ball_red,
        green => ball_green,
        blue => ball_blue,
        enabled => ball_enabled
    );

    -- Logic to determine output
    process (clk25Mhz)
    begin
		  if (SW(0) = '1') then
		      background_red <= "1111";
		  else 
				background_red <= "0000";
		  end if;
		  if (SW(1) = '1') then
		      background_green <= "1111";
		  else 
				background_green <= "0000";
		  end if;
		  if (SW(2) = '1') then
		      background_blue <= "1111";
		  else 
				background_blue <= "0000";
		  end if;
        if (ball_enabled = '1') then
            red <= ball_red;
            green <= ball_green;
            blue <= ball_blue;
        else
            red <= background_red;
            green <= background_green;
            blue <= background_blue;
        end if;
    end process;
    
end architecture behavior;