library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity GameRenderer is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync, horz_sync : IN std_logic;
        SW : IN std_logic_vector(9 downto 0);
        KEY : IN std_logic_vector(3 DOWNTO 0);
        pixel_row, pixel_column : IN std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic_vector(3 downto 0);
        training_mode : IN std_logic; 
        request_back : OUT std_logic;
        enabled : IN std_logic;
        training_mode_selected : IN std_logic;
        game_over : OUT std_logic;
        score_out   : OUT integer range 0 to 999;
        powerup_out : OUT integer
    );
end entity GameRenderer;

architecture behavior of GameRenderer is
    component Player is
        port (
            clk, vert_sync, mouse_left : IN std_logic;
            pixel_row, pixel_column : IN std_logic_vector(9 DOWNTO 0);
            KEY : IN std_logic_vector(3 DOWNTO 0);
            red, green, blue : OUT std_logic_vector(3 downto 0);
            enabled : IN std_logic;
            render : OUT std_logic;
            player_y_pos : OUT unsigned(9 downto 0)
        );
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
            pixel_row, pixel_column : IN std_logic_vector(9 DOWNTO 0);
            paused : IN std_logic;
            pipe_1_enabled, pipe_2_enabled : OUT std_logic;
            pipe_1_red, pipe_1_green, pipe_1_blue : OUT std_logic_vector(3 downto 0);
            pipe_2_red, pipe_2_green, pipe_2_blue : OUT std_logic_vector(3 downto 0);
            pipe_1_x_pos : OUT unsigned(10 downto 0);
            pipe_2_x_pos : OUT unsigned(10 downto 0);
            pipe_1_render, pipe_2_render : OUT std_logic        
        );
    end component LevelOne;

    component LevelTwo is
        port (
			  clk25Mhz : IN std_logic;
			  mouse_left : IN std_logic;
			  vert_sync : IN std_logic;
			  SW : IN std_logic_vector(9 downto 0);
			  KEY : IN std_logic_vector(3 DOWNTO 0);
			  level_two_enable : IN std_logic := '0';
			  pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
			  paused : IN std_logic;
			  pipe_1_enabled, pipe_2_enabled : OUT std_logic;
			  pipe_1_red, pipe_1_green, pipe_1_blue : OUT std_logic_vector(3 downto 0);
			  pipe_2_red, pipe_2_green, pipe_2_blue : OUT std_logic_vector(3 downto 0);
			  pipe_1_x_pos : OUT unsigned(10 downto 0);
			  pipe_2_x_pos : OUT unsigned(10 downto 0);
			  powerup_render : OUT std_logic;
			  powerup_red, powerup_green, powerup_blue : OUT std_logic_vector(3 downto 0);
			  powerup_collect : IN std_logic;
			  powerup_count : OUT integer;
			  pipe_1_render, pipe_2_render : OUT std_logic;
			  player_y_pos : IN unsigned(9 downto 0)        
        );
    end component LevelTwo;

    component LevelThree is
        port (
            clk25Mhz : IN std_logic;
            mouse_left : IN std_logic;
            vert_sync : IN std_logic;
            SW : IN std_logic_vector(9 downto 0);
            KEY : IN std_logic_vector(3 DOWNTO 0);
            level_three_enable : IN std_logic := '0';
            pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
            paused : IN std_logic;
            skull_1_enabled, skull_2_enabled, skull_3_enabled, skull_4_enabled, skull_5_enabled : OUT std_logic;
            skull_1_red, skull_1_green, skull_1_blue : OUT std_logic_vector(3 downto 0);
            skull_2_red, skull_2_green, skull_2_blue : OUT std_logic_vector(3 downto 0);
            skull_3_red, skull_3_green, skull_3_blue : OUT std_logic_vector(3 downto 0);
            skull_4_red, skull_4_green, skull_4_blue : OUT std_logic_vector(3 downto 0);
            skull_5_red, skull_5_green, skull_5_blue : OUT std_logic_vector(3 downto 0);
            skull_1_x_pos, skull_2_x_pos, skull_3_x_pos, skull_4_x_pos, skull_5_x_pos : OUT unsigned(10 downto 0);
            powerup_render : OUT std_logic;
            powerup_red, powerup_green, powerup_blue : OUT std_logic_vector(3 downto 0);
            powerup_collect : IN std_logic;
            powerup_count : OUT integer;
            skull_1_render, skull_2_render, skull_3_render, skull_4_render, skull_5_render : OUT std_logic
        );
    end component LevelThree;

    component LevelFour is
        port (
            clk25Mhz : IN std_logic;
            mouse_left : IN std_logic;
            vert_sync : IN std_logic;
            SW : IN std_logic_vector(9 downto 0);
            KEY : IN std_logic_vector(3 DOWNTO 0);
            level_four_enable : IN std_logic;
            pixel_row, pixel_column : IN std_logic_vector(9 downto 0);
            red, green, blue : OUT std_logic_vector(3 downto 0);
            paused : IN std_logic;
            game_finished : OUT std_logic
        );
    end component LevelFour;

    component LivesRenderer is
        port (
            clk, reset: in std_logic;
            pixel_row    : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
            collision_count : in integer range 0 to 3;
            red   : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue  : out std_logic_vector(3 downto 0);
            enabled : out std_logic;
            no_lives_left : out std_logic
        );
    end component LivesRenderer;

    component Cutscene is
    port (
        clk25Mhz : IN std_logic;
        vert_sync : IN std_logic;
        SW : IN std_logic_vector(9 downto 0);
        KEY : IN std_logic_vector(3 DOWNTO 0);
        cutscene_enable : IN std_logic;
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic_vector(3 downto 0);
        cutscene_end : OUT std_logic
    );
    end component Cutscene;
     
    -- Game Logic Values
    signal paused : std_logic := '0';
    signal prev_paused : std_logic := '0';
    signal prev_enabled : std_logic := '0';

    -- Collision values
    signal obstacle_collision_pending : std_logic := '0';
    signal collision_count : integer range 0 to 3 := 0; -- counts number of collisions for life rendering
    signal game_over_s : std_logic := '0'; -- internal signal to track game over state
    signal powerup_collision_pending : std_logic := '0';
    signal powerup_collected : std_logic := '0';

    -- Ball Values
    signal player_render : std_logic := '0';
    signal ball_red, ball_green, ball_blue : std_logic_vector(3 downto 0);
    signal invincibility : integer range 0 to 300 := 0; -- frames of invincibility after pipe collision.
    signal invincibility_flash : std_logic := '0';

    -- Obstacle Values
    signal obstacle_1_enabled : std_logic := '0';
    signal obstacle_1_red, obstacle_1_green, obstacle_1_blue : std_logic_vector(3 downto 0);
    signal obstacle_1_render : std_logic := '0';
    signal obstacle_1_x_pos : unsigned(10 downto 0);
    signal obstacle_1_score_incremented : std_logic := '0';

    signal obstacle_2_enabled : std_logic := '0';
    signal obstacle_2_red, obstacle_2_green, obstacle_2_blue : std_logic_vector(3 downto 0);
    signal obstacle_2_render : std_logic := '0';
    signal obstacle_2_x_pos : unsigned(10 downto 0);
	signal obstacle_2_score_incremented : std_logic := '0';

    signal obstacle_3_enabled : std_logic := '0';
    signal obstacle_3_red, obstacle_3_green, obstacle_3_blue : std_logic_vector(3 downto 0);
    signal obstacle_3_render : std_logic := '0';
    signal obstacle_3_x_pos : unsigned(10 downto 0);
	signal obstacle_3_score_incremented : std_logic := '0';

    signal obstacle_4_enabled : std_logic := '0';
    signal obstacle_4_red, obstacle_4_green, obstacle_4_blue : std_logic_vector(3 downto 0);
    signal obstacle_4_render : std_logic := '0';
    signal obstacle_4_x_pos : unsigned(10 downto 0);
    signal obstacle_4_score_incremented : std_logic := '0';

    signal obstacle_5_enabled : std_logic := '0';
    signal obstacle_5_red, obstacle_5_green, obstacle_5_blue : std_logic_vector(3 downto 0);
    signal obstacle_5_render : std_logic := '0';
    signal obstacle_5_x_pos : unsigned(10 downto 0);
    signal obstacle_5_score_incremented : std_logic := '0';

	 --Powerup signals
	 signal powerup_render : std_logic;
	 signal powerup_red, powerup_green, powerup_blue : std_logic_vector(3 downto 0);
	 signal powerup_collect_s : std_logic := '0';

    -- Level One outputs
    signal level_one_1_enabled, level_one_2_enabled : std_logic;
    signal level_one_1_red, level_one_1_green, level_one_1_blue : std_logic_vector(3 downto 0);
    signal level_one_2_red, level_one_2_green, level_one_2_blue : std_logic_vector(3 downto 0);
    signal level_one_1_x_pos, level_one_2_x_pos : unsigned(10 downto 0);
	signal level_one_1_render, level_one_2_render : std_logic;

    -- Level Two outputs
    signal level_two_1_enabled, level_two_2_enabled : std_logic;
    signal level_two_1_red, level_two_1_green, level_two_1_blue : std_logic_vector(3 downto 0);
    signal level_two_2_red, level_two_2_green, level_two_2_blue : std_logic_vector(3 downto 0);
    signal level_two_1_x_pos, level_two_2_x_pos : unsigned(10 downto 0);
	signal level_two_1_render, level_two_2_render : std_logic;

    -- Level Four outputs
    signal level_four_red, level_four_green, level_four_blue : std_logic_vector(3 downto 0);
    signal level_four_game_finished : std_logic;

    -- Level Three outputs
    signal level_three_1_enabled, level_three_2_enabled, level_three_3_enabled, level_three_4_enabled, level_three_5_enabled : std_logic;
    signal level_three_1_red, level_three_1_green, level_three_1_blue  : std_logic_vector(3 downto 0);
    signal level_three_2_red, level_three_2_green, level_three_2_blue : std_logic_vector(3 downto 0);
    signal level_three_3_red, level_three_3_green, level_three_3_blue : std_logic_vector(3 downto 0);
    signal level_three_4_red, level_three_4_green, level_three_4_blue : std_logic_vector(3 downto 0);
    signal level_three_5_red, level_three_5_green, level_three_5_blue : std_logic_vector(3 downto 0);
    signal level_three_1_x_pos, level_three_2_x_pos, level_three_3_x_pos, level_three_4_x_pos, level_three_5_x_pos : unsigned(10 downto 0);
    signal level_three_1_render, level_three_2_render, level_three_3_render, level_three_4_render, level_three_5_render : std_logic;

    -- Power Up outputs
    signal level_two_powerup_render : std_logic := '0';
    signal level_two_powerup_red, level_two_powerup_green, level_two_powerup_blue : std_logic_vector(3 downto 0);
    signal level_two_powerup_count : integer := 0;

    signal level_three_powerup_render : std_logic := '0';
    signal level_three_powerup_red, level_three_powerup_green, level_three_powerup_blue : std_logic_vector(3 downto 0);
    signal level_three_powerup_count : integer := 0;

    -- Lives Values
    signal lives_red, lives_green, lives_blue : std_logic_vector(3 downto 0);
    signal lives_enabled : std_logic := '0';
    signal lives_reset : std_logic := '0';
    signal no_lives_left : std_logic;

    signal last_key_3_state : std_logic := '1';
    signal last_key_2_state : std_logic := '1';
    signal last_vert_sync : std_logic := '0';

    -- Level Enables (Internal driving signals)
    signal level_state : integer range 1 to 5 := 1;
    signal level_one_enabled, level_two_enabled, level_three_enabled, level_four_enabled, cutscene_enabled : std_logic := '0';

    -- Background Values (Black)
    signal background_red, background_green, background_blue : std_logic_vector(3 downto 0) := "0000";

    -- Score Values
    signal score_enable : std_logic := '0';
    signal score : integer range 0 to 999 := 0;

    -- Cutscene values
    signal cutscene_red, cutscene_green, cutscene_blue : std_logic_vector(3 downto 0);
    signal cutscene_end : std_logic;
    signal cutscene_has_played : std_logic := '0';
    
    -- TEMPORARY: For score changing
    signal mouse_down : std_logic := '0';
	
    signal player_y_pos : unsigned(9 downto 0);
	signal player_enabled : std_logic;

begin
    score_out          <= score; 
    player_enabled <= enabled and (not paused);

    SCORE_COMPONENT : ScoreTextRenderer
	 generic map (
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
        render => player_render,
        enabled => player_enabled,
        player_y_pos => player_y_pos
    );

    LEVEL_ONE_COMPONENT : LevelOne port map (
        clk25Mhz => clk25Mhz,
		mouse_left => mouse_left,
		vert_sync => vert_sync,
        SW => SW,
		KEY => KEY,
		level_one_enable => level_one_enabled,
        pixel_row => pixel_row,
		pixel_column => pixel_column,
        pipe_1_red => level_one_1_red,
		pipe_1_green => level_one_1_green,
		pipe_1_blue => level_one_1_blue,
        pipe_1_enabled => level_one_1_enabled,
        pipe_2_red => level_one_2_red,
		pipe_2_green => level_one_2_green,
		pipe_2_blue => level_one_2_blue,
        pipe_2_enabled => level_one_2_enabled,
		pipe_1_x_pos => level_one_1_x_pos,
		pipe_2_x_pos => level_one_2_x_pos,
        pipe_1_render => level_one_1_render,
        pipe_2_render => level_one_2_render,
        paused => paused
    );

    LEVEL_TWO_COMPONENT : LevelTwo port map (
        clk25Mhz => clk25Mhz,
		mouse_left => mouse_left,
		vert_sync => vert_sync,
        SW => SW,
		KEY => KEY,
		level_two_enable => level_two_enabled,
        pixel_row => pixel_row,
		pixel_column => pixel_column,
        pipe_1_red => level_two_1_red,
		pipe_1_green => level_two_1_green,
		pipe_1_blue => level_two_1_blue,
        pipe_1_enabled => level_two_1_enabled,
        pipe_2_red => level_two_2_red,
		pipe_2_green => level_two_2_green,
		pipe_2_blue => level_two_2_blue,
        pipe_2_enabled => level_two_2_enabled,
		pipe_1_x_pos => level_two_1_x_pos,
		pipe_2_x_pos => level_two_2_x_pos,
        powerup_render => level_two_powerup_render,
        powerup_red => level_two_powerup_red,
 		powerup_green => level_two_powerup_green,
 		powerup_blue => level_two_powerup_blue,
        powerup_collect => powerup_collect_s,
        powerup_count => level_two_powerup_count,
        pipe_1_render => level_two_1_render,
        pipe_2_render => level_two_2_render,
        paused => paused,
        player_y_pos => player_y_pos
    );

    LEVEL_FOUR_COMPONENT : LevelFour port map (
        clk25Mhz => clk25Mhz,
        mouse_left => mouse_left,
        vert_sync => vert_sync,
        SW => SW,
        KEY => KEY,
        level_four_enable => level_four_enabled,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => level_four_red,
        green => level_four_green,
        blue => level_four_blue,
        paused => paused,
        game_finished => level_four_game_finished
    );

    LEVEL_THREE_COMPONENT : LevelThree port map (
        clk25Mhz => clk25Mhz,
        mouse_left => mouse_left,
        vert_sync => vert_sync,
        SW => SW,
        KEY => KEY,
        level_three_enable => level_three_enabled,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        skull_1_red => level_three_1_red,
        skull_1_green => level_three_1_green,
        skull_1_blue => level_three_1_blue,
        skull_1_enabled => level_three_1_enabled,
        skull_1_x_pos => level_three_1_x_pos,
        skull_1_render => level_three_1_render,
        skull_2_red => level_three_2_red,
        skull_2_green => level_three_2_green,
        skull_2_blue => level_three_2_blue,
        skull_2_enabled => level_three_2_enabled,
        skull_2_x_pos => level_three_2_x_pos,
        skull_2_render => level_three_2_render,
        skull_3_red => level_three_3_red,
        skull_3_green => level_three_3_green,
        skull_3_blue => level_three_3_blue,
        skull_3_enabled => level_three_3_enabled,
        skull_3_x_pos => level_three_3_x_pos,
        skull_3_render => level_three_3_render,
        skull_4_red => level_three_4_red,
        skull_4_green => level_three_4_green,
        skull_4_blue => level_three_4_blue,
        skull_4_enabled => level_three_4_enabled,
        skull_4_x_pos => level_three_4_x_pos,
        skull_4_render => level_three_4_render,
        skull_5_red => level_three_5_red,
        skull_5_green => level_three_5_green,
        skull_5_blue => level_three_5_blue,
        skull_5_enabled => level_three_5_enabled,
        skull_5_x_pos => level_three_5_x_pos,
        skull_5_render => level_three_5_render,
        powerup_render => level_three_powerup_render,
        powerup_red => level_three_powerup_red,
 		powerup_green => level_three_powerup_green,
 		powerup_blue => level_three_powerup_blue,
        powerup_collect => powerup_collect_s,
        powerup_count => level_three_powerup_count,
        paused => paused
    );

    CUTSCENE_COMPONENT : Cutscene port map (
        clk25Mhz => clk25Mhz,
        vert_sync => vert_sync,
        SW => SW,
        KEY => KEY,
        cutscene_enable => cutscene_enabled,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => cutscene_red,
        green => cutscene_green,
        blue => cutscene_blue,
        cutscene_end => cutscene_end
    );

    -- Multiplexer
    obstacle_1_enabled  <= level_one_1_enabled when level_state = 1 else
                           level_two_1_enabled when level_state = 2 else
                           level_three_1_enabled when level_state = 3 else '0';
    obstacle_1_red      <= level_one_1_red when level_state = 1 else
                           level_two_1_red when level_state = 2 else 
                           level_three_1_red when level_state = 3 else "0000";
    obstacle_1_green    <= level_one_1_green when level_state = 1 else
                           level_two_1_green when level_state = 2 else
                           level_three_1_green when level_state = 3 else "0000";
    obstacle_1_blue     <= level_one_1_blue when level_state = 1 else
                           level_two_1_blue when level_state = 2 else
                           level_three_1_blue when level_state = 3 else "0000";
    obstacle_1_x_pos    <= level_one_1_x_pos when level_state = 1 else
                           level_two_1_x_pos when level_state = 2 else 
                           level_three_1_x_pos when level_state = 3 else (others => '0');
    obstacle_1_render   <= level_one_1_render when level_state = 1 else
                           level_two_1_render when level_state = 2 else 
                           level_three_1_render when level_state = 3 else '0';

    obstacle_2_enabled  <= level_one_2_enabled when level_state = 1 else
                           level_two_2_enabled when level_state = 2 else 
                           level_three_2_enabled when level_state = 3 else '0';
    obstacle_2_red      <= level_one_2_red when level_state = 1 else
                           level_two_2_red when level_state = 2 else
                           level_three_2_red when level_state = 3 else "0000";
    obstacle_2_green    <= level_one_2_green when level_state = 1 else
                           level_two_2_green when level_state = 2 else 
                           level_three_2_green when level_state = 3 else "0000";
    obstacle_2_blue     <= level_one_2_blue when level_state = 1 else
                           level_two_2_blue when level_state = 2 else 
                           level_three_2_blue when level_state = 3 else "0000";
    obstacle_2_x_pos    <= level_one_2_x_pos when level_state = 1 else
                           level_two_2_x_pos when level_state = 2 else 
                           level_three_2_x_pos when level_state = 3 else (others => '0');
    obstacle_2_render   <= level_one_2_render when level_state = 1 else
                           level_two_2_render when level_state = 2 else 
                           level_three_2_render when level_state = 3 else '0';

    obstacle_3_enabled  <= level_three_3_enabled when level_state = 3 else '0';
    obstacle_3_red      <= level_three_3_red when level_state = 3 else "0000";
    obstacle_3_green    <= level_three_3_green when level_state = 3 else "0000";
    obstacle_3_blue     <= level_three_3_blue when level_state = 3 else "0000";
    obstacle_3_x_pos    <= level_three_3_x_pos when level_state = 3 else (others => '0');
    obstacle_3_render   <= level_three_3_render when level_state = 3 else '0';

    obstacle_4_enabled  <= level_three_4_enabled when level_state = 3 else '0';
    obstacle_4_red      <= level_three_4_red when level_state = 3 else "0000";
    obstacle_4_green    <= level_three_4_green when level_state = 3 else "0000";
    obstacle_4_blue     <= level_three_4_blue when level_state = 3 else "0000";
    obstacle_4_x_pos    <= level_three_4_x_pos when level_state = 3 else (others => '0');
    obstacle_4_render   <= level_three_4_render when level_state = 3 else '0';

    obstacle_5_enabled  <= level_three_5_enabled when level_state = 3 else '0';
    obstacle_5_red      <= level_three_5_red when level_state = 3 else "0000";
    obstacle_5_green    <= level_three_5_green when level_state = 3 else "0000";
    obstacle_5_blue     <= level_three_5_blue when level_state = 3 else "0000";
    obstacle_5_x_pos    <= level_three_5_x_pos when level_state = 3 else (others => '0');
    obstacle_5_render   <= level_three_5_render when level_state = 3 else '0';

    -- Route active level's power-up outputs to renderer
    powerup_render      <= level_two_powerup_render when level_state = 2 else
                           level_three_powerup_render when level_state = 3 else '0';
    powerup_red         <= level_two_powerup_red when level_state = 2 else
                           level_three_powerup_red when level_state = 3 else "0000";
    powerup_green       <= level_two_powerup_green when level_state = 2 else
                           level_three_powerup_green when level_state = 3 else "0000";
    powerup_blue        <= level_two_powerup_blue when level_state = 2 else
                           level_three_powerup_blue when level_state = 3 else "0000";
    powerup_out         <= level_two_powerup_count when level_state = 2 else
                           level_three_powerup_count when level_state = 3 else 0;

    LIVES_COMPONENT : LivesRenderer port map (
        clk => clk25Mhz,
        reset => lives_reset,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        collision_count => collision_count,
        red => lives_red,
        green => lives_green,
        blue => lives_blue,
        enabled => lives_enabled,
        no_lives_left => no_lives_left
    );

    
    GAME_UI : process (clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            if (enabled = '1') then
                if prev_enabled = '0' then
                    -- Initialize key state on enable to avoid immediate back request
                    last_key_3_state <= KEY(3);
                    request_back <= '0';
                else
                    -- Handle return to title screen
                    if KEY(3) = '0' and last_key_3_state = '1' then
                        request_back <= '1';
                        last_key_3_state <= '0';
                    elsif KEY(3) = '1' and last_key_3_state = '0' then
                        request_back <= '0';
                        last_key_3_state <= '1';
                    end if;
                end if;
            else
                -- IMPORTANT: when disabled reset otherwise we can't return to the game!
                request_back <= '0';
                last_key_3_state <= '1';
            end if;

            prev_enabled <= enabled;
        end if;
    end process;

    GAME_LOGIC : process (clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            if enabled = '1' then
                if (SW(0) = '1') then background_red <= "1111"; else background_red <= "0000"; end if;
                if (SW(1) = '1') then background_green <= "1111"; else background_green <= "0000"; end if;
                if (SW(2) = '1') then background_blue <= "1111"; else background_blue <= "0000"; end if;
                
                -- Render priority: Ball > Score > Pipes > Background
                if (cutscene_enabled = '1') then
                    red <= cutscene_red;
                    green <= cutscene_green;
                    blue <= cutscene_blue;
                elsif (player_render = '1' and invincibility_flash = '0') then
                    red <= ball_red;
					green <= ball_green;
					blue <= ball_blue;
                elsif score_enable = '1' then
                    red <= "1111";
					green <= "0000";
					blue <= "0000";
                elsif lives_enabled = '1' then
                    red <= lives_red;
                    green <= lives_green;
                    blue <= lives_blue;
                elsif level_four_enabled = '1' then
                    red <= level_four_red;
                    green <= level_four_green;
                    blue <= level_four_blue;
                elsif obstacle_1_render = '1' then
                    red <= obstacle_1_red;
					green <= obstacle_1_green;
					blue <= obstacle_1_blue;
                elsif obstacle_2_render = '1' then
                    red <= obstacle_2_red;
					green <= obstacle_2_green;
					blue <= obstacle_2_blue;
                elsif obstacle_3_render = '1' then
                    red <= obstacle_3_red;
					green <= obstacle_3_green;
					blue <= obstacle_3_blue;
                elsif obstacle_4_render = '1' then
                    red <= obstacle_4_red;
					green <= obstacle_4_green;
					blue <= obstacle_4_blue;
                elsif obstacle_5_render = '1' then
                    red <= obstacle_5_red;
					green <= obstacle_5_green;
					blue <= obstacle_5_blue;
                elsif powerup_render = '1' then
                    red <= powerup_red;
					green <= powerup_green;
					blue <= powerup_blue;
                else
                    red <= background_red;
					green <= background_green;
					blue <= background_blue;
                end if; 
                
                -- Collision detection is pixel-based: if the player and either pipe
                -- are enabled for the same pixel, latch a collision for the next frame.

                --Obstacles
                if (player_render = '1' and (obstacle_1_render = '1' or
                                            obstacle_2_render = '1' or
                                            obstacle_3_render = '1' or
                                            obstacle_4_render = '1' or
                                            obstacle_5_render = '1')) then
                    obstacle_collision_pending <= '1';
                end if;

                --Powerups
                if (player_render = '1' and powerup_render = '1') then
                    powerup_collision_pending <= '1';
                end if;

                if vert_sync = '1' and last_vert_sync = '0' then
                    if obstacle_collision_pending = '1' and invincibility = 0 then
                        invincibility <= 200; -- gives 5 seconds of invincibility at 60fps
								if no_lives_left = '0' then
									collision_count <= collision_count + 1; -- add to counter of collisions
                                else
                                    collision_count <= 0; -- reset collision count if no lives left
                                    -- GAME OVER CONDITION HERE :)
								end if;
                    elsif invincibility > 0 then
                        invincibility <= invincibility - 1;

                        -- Invincibility flash effect
                        if invincibility mod 5 = 0 then
                            invincibility_flash <= not invincibility_flash;
                        end if;
                    elsif (SW(5) = '0') then
                        invincibility <= 200;
                    else
                        -- reset flash when invincibility runs out
                        invincibility_flash <= '0';
                    end if;

                    powerup_collect_s <= '0';

                    if powerup_collision_pending = '1' then
                        if powerup_collected = '0' then
                            score <= score + 50;
                            powerup_collect_s <= '1'; -- Send signal to despawn powerup
                            powerup_collected <= '1'; -- Set protection gate
                        end if;
                    else
                        powerup_collected <= '0';
                    end if;

                    -- Score increment: one point per pipe pass.
                    if (obstacle_1_x_pos < to_unsigned(50, 11) and obstacle_1_score_incremented = '0') then
                        score <= score + 2;
                        obstacle_1_score_incremented <= '1';
                    elsif (obstacle_1_x_pos >= to_unsigned(50, 11)) then
                        obstacle_1_score_incremented <= '0';
                    end if;

                    if (obstacle_2_x_pos < to_unsigned(50, 11) and obstacle_2_score_incremented = '0') then
                        score <= score + 2;
                        obstacle_2_score_incremented <= '1';
                    elsif (obstacle_2_x_pos >= to_unsigned(50, 11)) then
                        obstacle_2_score_incremented <= '0';
                    end if;

                    if (obstacle_3_x_pos < to_unsigned(50, 11) and obstacle_3_score_incremented = '0') then
                        score <= score + 2;
                        obstacle_3_score_incremented <= '1';
                    elsif (obstacle_3_x_pos >= to_unsigned(50, 11)) then
                        obstacle_3_score_incremented <= '0';
                    end if;

                    if (obstacle_4_x_pos < to_unsigned(50, 11) and obstacle_4_score_incremented = '0') then
                        score <= score + 2;
                        obstacle_4_score_incremented <= '1';
                    elsif (obstacle_4_x_pos >= to_unsigned(50, 11)) then
                        obstacle_4_score_incremented <= '0';
                    end if;

                    if (obstacle_5_x_pos < to_unsigned(50, 11) and obstacle_5_score_incremented = '0') then
                        score <= score + 2;
                        obstacle_5_score_incremented <= '1';
                    elsif (obstacle_5_x_pos >= to_unsigned(50, 11)) then
                        obstacle_5_score_incremented <= '0';
                    end if;

                    obstacle_collision_pending <= '0';
                    powerup_collision_pending <= '0';
                end if;
					 
            else
                --While the game is disabled (on Title Screen), constantly hold the score at 0.
                score <= 0;
                mouse_down <= '0';
                obstacle_collision_pending <= '0';
                powerup_collision_pending <= '0';
                game_over_s <= '0';
            end if;

            last_vert_sync <= vert_sync;
        end if;
        game_over <= game_over_s; 
    end process GAME_LOGIC;

    LEVEL_SELECT : process (clk25Mhz)
        variable manual_level_change : std_logic;
		  variable dip_switch : std_logic_vector(3 downto 0);
    begin
        if rising_edge(clk25Mhz) then
            manual_level_change := '0';

            if (KEY(0) = '0' and prev_paused = '0') then
                paused <= not paused;
                prev_paused <= '1';
            elsif (KEY(0) = '1' and prev_paused = '1') then
                prev_paused <= '0';
            end if;

            if (enabled = '0') then
                level_one_enabled <= '0';
                level_two_enabled <= '0';
                level_three_enabled <= '0';
                level_four_enabled <= '0';
                cutscene_enabled <= '0';
                cutscene_has_played <= '0';
            else

                if cutscene_end = '1' then
                    cutscene_has_played <= '1';
                end if;

                case (level_state) is
                    when 1 =>
                        level_one_enabled <= '1';
                        level_two_enabled <= '0';
                        level_three_enabled <= '0';
                        level_four_enabled <= '0';
                        cutscene_enabled <= '0';
                    when 2 =>
                        level_one_enabled <= '0';
                        level_two_enabled <= '1';
                        level_three_enabled <= '0';
                        level_four_enabled <= '0';
                        cutscene_enabled <= '0';
                    when 3 =>
                        level_one_enabled <= '0';
                        level_two_enabled <= '0';
                        level_three_enabled <= '1';
                        level_four_enabled <= '0';
                        cutscene_enabled <= '0';
                    when 4 =>
                        level_one_enabled <= '0';
                        level_two_enabled <= '0';
                        level_three_enabled <= '0';
                        level_four_enabled <= '1';
                        cutscene_enabled <= '0';
                    when 5 => -- CUTSCENE STATE
                        level_one_enabled <= '0';
                        level_two_enabled <= '0';
                        level_three_enabled <= '0';
                        level_four_enabled <= '0';
                        cutscene_enabled <= '1';
                    when others =>
                        level_one_enabled <= '0';
                        level_two_enabled <= '0';
                        level_three_enabled <= '0';
                        level_four_enabled <= '0';
                        cutscene_enabled <= '0';
                end case;

                -- Manual level selection via switches
                dip_switch := SW(9) & SW(8) & SW(7) & SW(6);
                case (dip_switch) is
                    when "0001" =>
                        level_state <= 1;
                        manual_level_change := '1';
                    when "0011" =>
                        level_state <= 2;
                        manual_level_change := '1';
                    when "0101" =>
                        level_state <= 3;
                        manual_level_change := '1';
                    when "0110" =>
                        level_state <= 4;
                        manual_level_change := '1';
                    when "0111" => 
                        -- Added a debug switch combo for testing the cutscene
                        level_state <= 5;
                        manual_level_change := '1';
                    when others =>
                        manual_level_change := '0';
                end case;

                -- Automated level progression based on score
                if manual_level_change = '0' then
                    if training_mode = '1' then
                        -- In training mode, override to only level one
                        level_state <= 1;
                    else
                        case (score) is
                            when 0 to 10 =>
                                level_state <= 1; -- Level One
                            when 11 to 160 =>
                                -- Intercept Level 2 to play the cutscene first
                                if cutscene_has_played = '0' then
                                    level_state <= 5; -- Play Cutscene
                                else
                                    level_state <= 2; -- Proceed to Level Two
                                end if;
                            when 161 to 310 =>
                                level_state <= 3; -- Level Three
                            when others =>
                                level_state <= 4; -- Level Four
                        end case;
                    end if;
                end if;
            end if;
        end if;
    end process LEVEL_SELECT;
    
end architecture behavior;