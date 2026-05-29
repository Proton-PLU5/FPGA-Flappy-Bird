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
        red, green, blue : OUT std_logic_vector(3 downto 0);
        selected_mode : OUT integer range 0 to 2; -- 0 for training, 1 for play, 2 for settings
        proceed : OUT std_logic;
        enabled : IN std_logic
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

    component TileRenderer is
        generic (
            TILE_ID : integer range 0 to 255 := 0
        );
        port (
            clk, vert_sync, mouse_left  : in std_logic;
            pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
            red, green, blue            : out std_logic_vector(3 downto 0);
            reset                       : in std_logic;
            enabled                     : in std_logic;
            offset                      : in  UNSIGNED(5 downto 0);
			transparent : out std_logic
        );
    end component TileRenderer;

    signal main_title_enable : std_logic;
    signal sub_title_enable : std_logic;
    signal training_text_enable : std_logic;
    signal play_text_enable : std_logic;
    signal settings_text_enable : std_logic;
    signal selected_text_enable : std_logic;

    signal selected_text_row : integer := 260;
    signal selected_option : integer range 0 to 2 := 0; -- 0 for training, 1 for play, 2 for settings
    signal last_key_1_state : std_logic := '1';
    signal last_key_3_state : std_logic := '1';

    -- Background tile
    signal background_red, background_green, background_blue : std_logic_vector(3 downto 0);
begin
    
    MAIN_TITLE : title_display port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => main_title_enable, 
        text_row => 100,
        text_col_start => 144
    );
	 
	SUB_TITLE : title_display generic map (text_string => "RETURN OF THE SKELEKING", text_size => 23, SIZE => 3) port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => sub_title_enable, 
        text_row => 150,
        text_col_start => 136
    );
	 
	TRAINING_MODE_TEXT : title_display generic map (text_string => "TRAINING MODE", text_size => 13, size => 2) port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => training_text_enable,
        text_row => 260,
        text_col_start => 268
	);

    PLAY_MODE_TEXT : title_display generic map (text_string => "PLAY MODE", text_size => 9, size => 2) port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => play_text_enable,
        text_row => 300,
        text_col_start => 284
	);

    SETTINGS_MODE_TEXT : title_display generic map (text_string => "SETTINGS MODE", text_size => 13, size => 2) port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => settings_text_enable,
        text_row => 340,
        text_col_start => 268
	);

    SELECTED_TEXT : title_display
    generic map (
        text_string => ">",
        text_size   => 1,
        SIZE        => 2
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => selected_text_enable,
        text_row => selected_text_row,
        text_col_start => 252
    );

    TILE_RENDERER : TileRenderer
    generic map (
        TILE_ID => 5
    )
    port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => mouse_left,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => background_red,
        green => background_green,
        blue => background_blue,
        reset => '0',
        enabled => enabled,
        offset => to_unsigned(0, 6),
        transparent => open
    );
			

    -- Logic to determine output
    process(clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            if enabled = '1' then
                -- navigation button using KEY1 
                if KEY(1) = '0' and last_key_1_state = '1' then
                    case selected_option is
                        when 0 =>
                            selected_option <= 1;
                            selected_text_row <= 300;
                        when 1 =>
                            selected_option <= 2;
                            selected_text_row <= 340;
                        when others =>
                            selected_option <= 0;
                            selected_text_row <= 260;
                    end case;

                    last_key_1_state <= '0';
                elsif KEY(1) = '1' and last_key_1_state = '0' then
                    last_key_1_state <= '1';
                end if;

                -- start button
                if KEY(3) = '0' and last_key_3_state = '1' then
                    if selected_option = 1 or selected_option = 0 then
                        proceed <= '1';
                    else
                        proceed <= '0';
                    end if;
                    last_key_3_state <= '0';
                elsif KEY(3) = '1' and last_key_3_state = '0' then
                    proceed <= '0';
                    last_key_3_state <= '1';
                end if;

                -- color logic can stay here (it will be updated each clock)
                if (sub_title_enable = '1' or training_text_enable = '1'
                    or play_text_enable = '1' or settings_text_enable = '1'
                    or selected_text_enable = '1') then
                    red   <= "1111";
                    green <= "1111";
                    blue  <= "1111";
                elsif main_title_enable = '1' then
                    red   <= "1111";
                    green <= "0000";
                    blue  <= "0000";
                else
                    red   <= background_red;
                    green <= background_green;
                    blue  <= background_blue;
                end if;
            else
                -- if enable is off, reset the proceed signal.
                -- IMPORTANT! If we don't do this, then we can never return to the title!!
                proceed <= '0';
            end if;
        end if;
    end process;
    
    selected_mode <= selected_option;
end architecture behaviour;