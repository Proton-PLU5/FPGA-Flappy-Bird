library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity WinRenderer is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        KEY : IN std_logic_vector(3 DOWNTO 0);
        vert_sync, horz_sync : IN std_logic;
        pixel_row, pixel_column : IN std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic_vector(3 downto 0);
        request_back : OUT std_logic;
        enabled : IN std_logic
    );
end entity WinRenderer;

architecture Behavioral of WinRenderer is

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

    signal win_enable : std_logic := '0';
    signal tooltip_enable : std_logic := '0';
    signal last_key_3_state : std_logic := '1';

    begin

	YOU_WIN : title_display generic map (text_string => "YOU WIN", text_size => 7, SIZE => 4) port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => win_enable, 
        text_row => 224,
        text_col_start => 208
    );

    TOOL_TIP : title_display generic map (text_string => "KEY 0 TO RETURN", text_size => 15, SIZE => 2) port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => tooltip_enable, 
        text_row => 300,
        text_col_start => 256
    );
    
    process(clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then

            if enabled = '1' then
                if win_enable = '1' then
                    red <= "1111";
                    green <= "1111";
                    blue <= "0000";
                elsif tooltip_enable = '1' then
                    red <= "1111";
                    green <= "1111";
                    blue <= "1111";
                else
                    red <= "0000";
                    green <= "0000";
                    blue <= "0000";
                end if;

				if KEY(3) = '0' and last_key_3_state = '1' then
					request_back <= '1';
				else
				    request_back <= '0';
							 
				end if; 

            else 
                request_back <= '0';
            end if; 

            last_key_3_state <= KEY(3);

        end if;
    end process;

    end architecture Behavioral;