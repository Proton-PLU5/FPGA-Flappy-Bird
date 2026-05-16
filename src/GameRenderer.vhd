library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Lets use this file to manage Rendering
entity GameRenderer is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync, horz_sync : IN std_logic;
		SW : IN std_logic_vector(9 downto 0);
		KEY : IN std_logic_vector(3 DOWNTO 0);
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic_vector(3 downto 0);
        request_back : OUT std_logic;
        enabled : IN std_logic;
        level_state : IN integer := 0;
        level_one_enable, level_two_enable, level_three_enable, level_four_enable : out std_logic;
    );
end entity GameRenderer;

architecture behavior of GameRenderer is
    component Player is
        port (
            clk, vert_sync, mouse_left	: IN std_logic;
            pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
				KEY : IN std_logic_vector(3 DOWNTO 0);
            red, green, blue : OUT std_logic_vector(3 downto 0);
            enabled : OUT std_logic);
    end component Player;

    component title_display is
        generic (
            text_string : string := "FLAPPY BOSS";
            text_size : integer := 11;
            SIZE : integer := 4
        );

        port (
            clk             : in  std_logic;
            pixel_row       : in  std_logic_vector(9 downto 0);
            pixel_column    : in  std_logic_vector(9 downto 0);
            pixel_on        : out std_logic;
		    text_row        : in integer;
			text_col_start  : in integer
        );
    end component title_display;

    component LevelOne is
        port (
            clk25Mhz : IN std_logic;
            mouse_left : IN std_logic;
            vert_sync : IN std_logic;
            SW : IN std_logic_vector(9 downto 0);
            KEY : IN std_logic_vector(3 DOWNTO 0);
            level_one_enable : IN std_logic;
            pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
            pipe_enabled : OUT std_logic;
            red, green, blue : OUT std_logic_vector(3 downto 0);
        );
    end component LevelOne;
    
    -- Ball Values
    signal ball_enabled : std_logic := '0';
    signal ball_red, ball_green, ball_blue : std_logic_vector(3 downto 0);

    -- Obstacle Values
    signal obstacle_enabled : std_logic := '0';
    signal obstacle_red, obstacle_green, obstacle_blue : std_logic_vector(3 downto 0);

    signal last_key_3_state : std_logic := '1';

    --LSFR
    signal lfsr_out      : std_logic_vector(7 downto 0);

    -- Background Values (Black)
    signal background_red, background_green, background_blue : std_logic_vector(3 downto 0) := "0000";

    signal score_enable : std_logic := '0';
begin

    SCORE_COMPONENT : title_display generic map(
        text_string => " 00 ",
        text_size => 4,
        SIZE => 3
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => score_enable,
        text_row => 50,
        text_col_start => 288
    );
    
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

    LEVEL_ONE_COMPONENT : LevelOne port map (
        clk25Mhz => clk25Mhz,
        mouse_left => mouse_left,
        vert_sync => vert_sync,
        SW => SW,
        KEY => KEY,
        level_one_enable => level_one_enable,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => obstacle_red,
        green => obstacle_green,
        blue => obstacle_blue,
        pipe_enabled => obstacle_enabled
    );

    -- Logic to determine output
    process (clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            if enabled = '1' then
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
                elsif score_enable = '1' then
                    red <= "1111";
                    green <= "0000";
                    blue <= "0000";
                elsif obstacle_enabled = '1' then
                    red <= obstacle_red;
                    green <= obstacle_green;
                    blue <= obstacle_blue;
                else
                    red <= background_red;
                    green <= background_green;
                    blue <= background_blue;
                end if;
            end if;

            -- Go back to title
            if KEY(3) = '0' and last_key_3_state = '1' then
                request_back <= '1';
            else
                request_back <= '0';
            end if;
            last_key_3_state <= KEY(3);
        end if;
    end process;

    LEVEL_SELECT : process (clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            if level_state = 1 then
                level_one_enable <= '1';
            elsif level_state = 2 then
                level_two_enable <= '1';
            elsif level_state = 3 then
                level_three_enable <= '1';
            elsif level_state = 4 then
                level_four_enable <= '1';
            end if;
        end if;
    end process LEVEL_SELECT;
    
end architecture behavior;