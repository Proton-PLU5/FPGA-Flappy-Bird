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
        level_state : IN integer := 1;
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

    component ScoreTextRenderer is
        generic (
            SIZE : integer := 4
        );

        port (
            clk : in std_logic;
            score : in integer;
            pixel_row : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
            pixel_on : out std_logic;
            text_row : in integer;
            text_col_start : in integer
        );
    end component ScoreTextRenderer;

    component LevelOne is
        port (
            clk25Mhz : IN std_logic;
            mouse_left : IN std_logic;
            vert_sync : IN std_logic;
            SW : IN std_logic_vector(9 downto 0);
            KEY : IN std_logic_vector(3 DOWNTO 0);
            level_one_enable : IN std_logic;
            pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
            pipe_1_enabled, pipe_2_enabled : OUT std_logic;
            pipe_1_red, pipe_1_green, pipe_1_blue : OUT std_logic_vector(3 downto 0);
            pipe_2_red, pipe_2_green, pipe_2_blue : OUT std_logic_vector(3 downto 0);
            pipe_x_pos : OUT unsigned(10 downto 0);
        );
    end component LevelOne;
    
    -- Collision values
    signal collided_pipe : std_logic := '0';

    -- Ball Values
    signal ball_enabled : std_logic := '0';
    signal ball_red, ball_green, ball_blue : std_logic_vector(3 downto 0);

    -- Obstacle Values
    signal obstacle_1_enabled : std_logic := '0';
    signal obstacle_1_red, obstacle_1_green, obstacle_1_blue : std_logic_vector(3 downto 0);
    signal obstacle_2_enabled : std_logic := '0';
    signal obstacle_2_red, obstacle_2_green, obstacle_2_blue : std_logic_vector(3 downto 0);
    signal obstacle_x_pos : unsigned(10 downto 0);

    signal last_key_3_state : std_logic := '1';

    --LSFR
    signal lfsr_out      : std_logic_vector(7 downto 0);

    -- Background Values (Black)
    signal background_red, background_green, background_blue : std_logic_vector(3 downto 0) := "0000";

    signal score_enable : std_logic := '0';

    signal score : integer range 0 to 999 := 0;
    signal score_incremented : std_logic := '0';
begin

    SCORE_COMPONENT : ScoreTextRenderer generic map (
        SIZE => 3
    )
    port map (
        clk => clk25Mhz,
        score => score,
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
        pipe_1_red => obstacle_1_red,
        pipe_1_green => obstacle_1_green,
        pipe_1_blue => obstacle_1_blue,
        pipe_1_enabled => obstacle_1_enabled,
        pipe_2_red => obstacle_2_red,
        pipe_2_green => obstacle_2_green,
        pipe_2_blue => obstacle_2_blue,
        pipe_2_enabled => obstacle_2_enabled,
        pipe_x_pos => obstacle_x_pos
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
                elsif obstacle_1_enabled = '1' then
                    red <= obstacle_1_red;
                    green <= obstacle_1_green;
                    blue <= obstacle_1_blue;
                elsif obstacle_2_enabled = '1' then
                    red <= obstacle_2_red;
                    green <= obstacle_2_green;
                    blue <= obstacle_2_blue;
                else
                    red <= background_red;
                    green <= background_green;
                    blue <= background_blue;
                end if;

                -- TODO:
                -- Collision pipe with player

                if (ball_enabled = '1' and obstacle_1_enabled = '1' and collided_pipe = '0')  then -- don't allow score reset if already colliding
                    score <= 0; 
                    collided_pipe <= '1';
                elsif (ball_enabled = '1' and obstacle_1_enabled = '1' and collided_pipe = '1') then
                    collided_pipe <= '1';
                elsif (ball_enabled = '1' and obstacle_1_enabled = '0') then
                    collided_pipe <= '0'; 
                end if;


                -- Score increment (one point per pipe pass):
                if (obstacle_x_pos < to_unsigned(50, 11) and score_incremented = '0') then
                    score <= score + 1;
                    score_incremented <= '1';
                elsif (obstacle_x_pos >= to_unsigned(50, 11)) then
                    score_incremented <= '0';
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
                level_two_enable <= '0';
                level_three_enable <= '0';
                level_four_enable <= '0';
            elsif level_state = 2 then
                level_one_enable <= '0';
                level_two_enable <= '1';
                level_three_enable <= '0';
                level_four_enable <= '0';
            elsif level_state = 3 then
                level_one_enable <= '0';
                level_two_enable <= '0';
                level_three_enable <= '1';
                level_four_enable <= '0';
            elsif level_state = 4 then
                level_one_enable <= '0';
                level_two_enable <= '0';
                level_three_enable <= '0';
                level_four_enable <= '1';
            end if;
        end if;
    end process LEVEL_SELECT;
    
end architecture behavior;