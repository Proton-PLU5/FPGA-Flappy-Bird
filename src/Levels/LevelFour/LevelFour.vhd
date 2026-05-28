library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity LevelFour is
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
end entity LevelFour;

architecture behavior of LevelFour is
    component BossRenderer is
        generic (
            SCALE_FACTOR : integer := 1
        );
        port (
            clk25Mhz : IN std_logic;
            pixel_row, pixel_column : IN std_logic_vector(9 downto 0);
            red, green, blue : OUT std_logic_vector(3 downto 0);
            vert_sync : IN std_logic;
            enabled : OUT std_logic;
            x_pos : IN std_logic_vector(9 downto 0);
            y_pos : IN std_logic_vector(9 downto 0)
        );
    end component BossRenderer;

    component SpriteRenderer is
        generic (
            SCALE_FACTOR : integer := 1
        );
        port (
            clk : in std_logic;
            pixel_row    : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
            start_x  : in std_logic_vector(10 downto 0);
            start_y  : in std_logic_vector(10 downto 0);
            sprite_id : in integer range 0 to 64;
            red   : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue  : out std_logic_vector(3 downto 0);
            transparent : out std_logic
        );
    end component SpriteRenderer;

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
        port (
            clk, vert_sync, mouse_left  : in std_logic;
            pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
            red, green, blue            : out std_logic_vector(3 downto 0);
            reset                       : in std_logic;
            enabled                     : in std_logic;
            tile_id                     : in integer range 0 to 255;
			transparent : out std_logic
        );
    end component TileRenderer;

    -- BOSS SIGNALS
    signal boss_red, boss_green, boss_blue : std_logic_vector(3 downto 0);
    signal boss_enabled : std_logic;

    -- DEAD BOSS SIGNALS
    signal dead_head_red, dead_head_green, dead_head_blue : std_logic_vector(3 downto 0);
    signal dead_head_transparent : std_logic;
    signal dead_head_enabled, dead_jaw_enabled : std_logic;
    
    signal dead_jaw_red, dead_jaw_green, dead_jaw_blue : std_logic_vector(3 downto 0);
    signal dead_jaw_transparent : std_logic;

    signal dead_head_y : unsigned(9 downto 0) := to_unsigned(144, 10);
    signal dead_head_x : unsigned(9 downto 0) := to_unsigned(240, 10);

    signal dead_jaw_x : unsigned(9 downto 0) := to_unsigned(266, 10);
    signal dead_jaw_y : unsigned(9 downto 0) := to_unsigned(258, 10);
    
    -- X = 320 (Screen Center) - 40 (Half Boss Width) = 280
    -- Y = 240 (Screen Center) - 38 (Half Boss Height) = 202
    signal boss_x_pos : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(240, 10)); 
    signal boss_y_pos : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(144, 10)); 

    -- LASER BEAM SIGNALS
    signal laser_warning1_red, laser_warning1_green, laser_warning1_blue : std_logic_vector(3 downto 0);
    signal laser_warning1_transparent : std_logic;
    signal laser_warning2_red, laser_warning2_green, laser_warning2_blue : std_logic_vector(3 downto 0);
    signal laser_warning2_transparent : std_logic;
    signal laser_warning_enabled : std_logic;
    
    signal laser_warning_counter : integer range 0 to 60 := 0;

    -- CENTER GAP
    constant SPRITE_HEIGHT : integer := 120; 
    
    constant GAP_HALF : integer := 40;  -- Half of 150px
    constant Y_CENTER : integer := 240; -- 480 / 2

    -- Top laser bottom edge = 165 (start_y = 165 - height)
    constant L1_TARGET_INT : integer := Y_CENTER - GAP_HALF - SPRITE_HEIGHT;
    
	-- Bottom laser top edge = 315 (start_y = 315)
    constant L2_TARGET_INT : integer := Y_CENTER + GAP_HALF;
	 
	 
    -- Keep bottom laser fully on-screen at spawn
    constant L2_START_INT  : integer := 480 - SPRITE_HEIGHT;
	 
    -- LASER 1 SIGNALS
    signal laser1_red, laser1_green, laser1_blue : std_logic_vector(3 downto 0);
    signal laser1_transparent : std_logic;
    signal laser1_enabled : std_logic;
    signal laser1_y_pos : unsigned(9 downto 0) := (others => '0');

    -- LASER 2 SIGNALS
    signal laser2_red, laser2_green, laser2_blue : std_logic_vector(3 downto 0);
    signal laser2_transparent : std_logic;
    signal laser2_enabled : std_logic;
    signal laser2_y_pos : unsigned(9 downto 0) := to_unsigned(L2_START_INT, 10);

    -- TARGET CONSTANTS
    constant laser1_target_y : unsigned(9 downto 0) := to_unsigned(L1_TARGET_INT, 10);
    constant laser2_target_y : unsigned(9 downto 0) := to_unsigned(L2_TARGET_INT, 10);

    -- TEXT COMPONENT OUTPUTS (Hardware pixels)
    signal msg_1_pixel, msg_2_pixel, msg_3_pixel : std_logic;
    
    -- TEXT STATE ENABLE SIGNALS (State machine logic)
    signal show_msg_1, show_msg_2, show_msg_3 : std_logic := '0';
    signal text_counter : integer range 0 to 400 := 0;

    type boss_state is (IDLE, WARNING, MOVING, HOLD, VICTORY);
    signal current_state : boss_state := IDLE;
    
    signal cycle_counter : integer range 0 to 1000 := 0; 

    signal background_red, background_green, background_blue : std_logic_vector(3 downto 0);
    signal background_transparent : std_logic;
begin

    BOSS: BossRenderer
    generic map (
        SCALE_FACTOR => 2
    )
    port map (
        clk25Mhz => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => boss_red,
        green => boss_green,
        blue => boss_blue,
        vert_sync => vert_sync,
        enabled => boss_enabled,
        x_pos => boss_x_pos,
        y_pos => boss_y_pos
    );

    DEAD_HEAD : SpriteRenderer 
    generic map ( SCALE_FACTOR => 2 )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & std_logic_vector(dead_head_x),
        start_y => '0' & std_logic_vector(dead_head_y),
        sprite_id => 0,
        red => dead_head_red,
        green => dead_head_green,
        blue => dead_head_blue,
        transparent => dead_head_transparent
    );

    DEAD_JAW : SpriteRenderer 
    generic map ( SCALE_FACTOR => 2 )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & std_logic_vector(dead_jaw_x),
        start_y => '0' & std_logic_vector(dead_jaw_y),
        sprite_id => 1,
        red => dead_jaw_red,
        green => dead_jaw_green,
        blue => dead_jaw_blue,
        transparent => dead_jaw_transparent
    );

    -- LASER WARNING 1 SPRITE
    LASER_WARNING1 : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => std_logic_vector(to_unsigned(0, 11)), 
        start_y => '0' & std_logic_vector(laser1_y_pos),
        sprite_id => 6, 
        red => laser_warning1_red,
        green => laser_warning1_green,
        blue => laser_warning1_blue,
        transparent => laser_warning1_transparent
    );

    -- LASER WARNING 2 SPRITE
    LASER_WARNING2 : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => std_logic_vector(to_unsigned(0, 11)), 
        start_y => '0' & std_logic_vector(laser2_y_pos),
        sprite_id => 6, 
        red => laser_warning2_red,
        green => laser_warning2_green,
        blue => laser_warning2_blue,
        transparent => laser_warning2_transparent
    );

    -- LASER 1 SPRITE
    LASER_ONE : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => std_logic_vector(to_unsigned(0, 11)), 
        start_y => '0' & std_logic_vector(laser1_y_pos),
        sprite_id => 7, 
        red => laser1_red,
        green => laser1_green,
        blue => laser1_blue,
        transparent => laser1_transparent
    );

    -- LASER 2 SPRITE
    LASER_TWO : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => std_logic_vector(to_unsigned(0, 11)), 
        start_y => '0' & std_logic_vector(laser2_y_pos),
        sprite_id => 7, 
        red => laser2_red,
        green => laser2_green,
        blue => laser2_blue,
        transparent => laser2_transparent
    );

    MSG_1 : title_display 
    generic map (
        text_string => "YOU SURVIVED...",
        text_size => 15,
        size => 3
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => msg_1_pixel, 
        text_row => 240,
        text_col_start => 200
    );

    MSG_2 : title_display 
    generic map (
        text_string => "UNEXPECTED.....",
        text_size => 15,
        size => 3
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => msg_2_pixel, 
        text_row => 240,
        text_col_start => 200
    );

    MSG_3 : title_display 
    generic map (
        text_string => "HOWEVER, YOU WONT SURVIVE THIS!",
        text_size => 31,
        size => 3
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => msg_3_pixel, 
        text_row => 240,
        text_col_start => 50
    );

    TILE_RENDERER : TileRenderer port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => mouse_left,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => background_red,
        green => background_green,
        blue => background_blue,
        reset => '0',
        enabled => level_four_enable,
        tile_id => 10,
		transparent => background_transparent
    );
    

    PROCESS (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if level_four_enable = '0' then
                current_state <= IDLE;
                cycle_counter <= 0;
                laser_warning_counter <= 0;
                game_finished <= '0';
                laser1_y_pos <= (others => '0');
                laser2_y_pos <= to_unsigned(L2_START_INT, 10);

                dead_head_y <= to_unsigned(144, 10);
                dead_head_x <= to_unsigned(240, 10);
                dead_jaw_x  <= to_unsigned(266, 10);
                dead_jaw_y  <= to_unsigned(258, 10);

                show_msg_1 <= '0';
                show_msg_2 <= '0';
                show_msg_3 <= '0';
                text_counter <= 0;

                dead_head_enabled <= '0';
                dead_jaw_enabled <= '0';
            elsif paused = '0' then
                case current_state is
                    when IDLE =>
                        laser_warning_enabled <= '0';
                        laser1_enabled <= '0';
                        laser2_enabled <= '0';
                        dead_head_enabled <= '0';
                        dead_jaw_enabled <= '0';

                        -- Text Timing Sequence
                        if text_counter < 120 then
                            show_msg_1 <= '1'; show_msg_2 <= '0'; show_msg_3 <= '0';
                            text_counter <= text_counter + 1;
                        elsif text_counter < 240 then
                            show_msg_1 <= '0'; show_msg_2 <= '1'; show_msg_3 <= '0';
                            text_counter <= text_counter + 1;
                        elsif text_counter < 360 then
                            show_msg_1 <= '0'; show_msg_2 <= '0'; show_msg_3 <= '1';
                            text_counter <= text_counter + 1;
                        else
                            -- All messages done, clear text and begin attack
                            show_msg_1 <= '0'; show_msg_2 <= '0'; show_msg_3 <= '0';
                            current_state <= WARNING;
                            cycle_counter <= 0;
                        end if;

                        dead_head_y <= to_unsigned(144, 10);
                        dead_head_x <= to_unsigned(240, 10); 
                        dead_jaw_x  <= to_unsigned(266, 10);
                        dead_jaw_y  <= to_unsigned(258, 10);
                                                
                    when WARNING =>
                        if cycle_counter >= 300 then 
                            current_state <= MOVING;
                            cycle_counter <= 0;
                            laser_warning_counter <= 0; 
                        else
                            cycle_counter <= cycle_counter + 1;
                            
                            if laser_warning_counter < 30 then
                                laser_warning_enabled <= '1';
                            else
                                laser_warning_enabled <= '0';
                            end if;
                            
                            if laser_warning_counter = 59 then
                                laser_warning_counter <= 0;
                            else
                                laser_warning_counter <= laser_warning_counter + 1;
                            end if;
                        end if;

                    when MOVING =>
                        laser_warning_enabled <= '0';
                        laser1_enabled <= '1';
                        laser2_enabled <= '1';
                        
                        if laser1_y_pos < laser1_target_y then 
                            laser1_y_pos <= laser1_y_pos + 1; 
                        end if;
                        if laser2_y_pos > laser2_target_y then 
                            laser2_y_pos <= laser2_y_pos - 1; 
                        end if;

                        if laser1_y_pos >= laser1_target_y and laser2_y_pos <= laser2_target_y then
                            current_state <= HOLD;
                            cycle_counter <= 0;
                        end if;

                        dead_head_enabled <= '0';
                        dead_jaw_enabled <= '0';
                        
                    when HOLD =>
                        if cycle_counter >= 300 then 
                            current_state <= VICTORY;
                            cycle_counter <= 0;
                        else
                            cycle_counter <= cycle_counter + 1;
                        end if;

                        dead_head_enabled <= '0';
                        dead_jaw_enabled <= '0';
                        
                    when VICTORY =>
                        laser1_enabled <= '0';
                        laser2_enabled <= '0';
                        laser_warning_enabled <= '0';
                        game_finished <= '1'; 
                        
                        dead_head_enabled <= '1';
                        dead_jaw_enabled <= '1';
                        
                        if dead_head_y < 480 then
                            dead_head_y <= dead_head_y + 3;
                            dead_head_x <= dead_head_x - 1; 
                        end if;

                        if dead_jaw_y < 480 then
                            dead_jaw_y <= dead_jaw_y + 3; 
                            dead_jaw_x <= dead_jaw_x + 1; 
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- RENDER COMBINER
    RENDER_LOGIC : process(clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            if level_four_enable = '1' then
                if show_msg_1 = '1' and msg_1_pixel = '1' then
                    red <= (others => '1'); 
                    green <= (others => '1'); 
                    blue <= (others => '1'); -- White
                elsif show_msg_2 = '1' and msg_2_pixel = '1' then
                    red <= (others => '1'); 
                    green <= (others => '1');
                    blue <= (others => '1'); -- White
                elsif show_msg_3 = '1' and msg_3_pixel = '1' then
                    red <= (others => '1'); 
                    green <= (others => '0'); 
                    blue <= (others => '0'); -- Red
                elsif dead_head_enabled = '1' and dead_head_transparent = '0' then
                    red <= dead_head_red; 
                    green <= dead_head_green; 
                    blue <= dead_head_blue;
                elsif dead_jaw_enabled = '1' and dead_jaw_transparent = '0' then
                    red <= dead_jaw_red; 
                    green <= dead_jaw_green; 
                    blue <= dead_jaw_blue;
                elsif laser_warning_enabled = '1' and laser_warning1_transparent = '0' then
                    red <= laser_warning1_red; 
                    green <= laser_warning1_green; 
                    blue <= laser_warning1_blue;
                elsif laser_warning_enabled = '1' and laser_warning2_transparent = '0' then
                    red <= laser_warning2_red; 
                    green <= laser_warning2_green; 
                    blue <= laser_warning2_blue;
                elsif laser1_enabled = '1' and laser1_transparent = '0' then
                    red <= laser1_red; 
                    green <= laser1_green; 
                    blue <= laser1_blue;
                elsif laser2_enabled = '1' and laser2_transparent = '0' then
                    red <= laser2_red; 
                    green <= laser2_green; 
                    blue <= laser2_blue;
                elsif boss_enabled = '1' and current_state /= VICTORY then
                    red <= boss_red; 
                    green <= boss_green; 
                    blue <= boss_blue;
                else
                    red <= background_red; 
                    green <= background_green; 
                    blue <= background_blue;
                end if;
            end if;
        end if;
    end process;

end architecture behavior;