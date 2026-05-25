library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity GameOverRenderer is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync, horz_sync : IN std_logic;
        pixel_row, pixel_column : IN std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic_vector(3 downto 0);
        request_back : OUT std_logic;
        enabled : IN std_logic
    );
end entity GameOverRenderer;

architecture Behavioral of GameOverRenderer is

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

    signal gameover_enable : std_logic := '0';
    signal last_mouse_left : std_logic := '0';

    begin

	GAME_OVER : title_display generic map (text_string => "GAME OVER", text_size => 9, SIZE => 4) port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => gameover_enable, 
        text_row => 224,
        text_col_start => 176
    );
    
    process(clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then

            if enabled = '1' then
                if gameover_enable = '1' then
                    red <= "1111";
                    green <= "0000";
                    blue <= "0000";
                else
                    red <= "0000";
                    green <= "0000";
                    blue <= "0000";
                end if;

				if mouse_left = '1' and last_mouse_left = '0' then
					request_back <= '1';
				else
				    request_back <= '0';
							 
				end if; 

            else 
                request_back <= '0';
            end if; 

            last_mouse_left <= mouse_left;

        end if;
    end process;

    end architecture Behavioral;