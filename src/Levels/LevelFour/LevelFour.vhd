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
        port (
            clk25Mhz : IN std_logic;
            pixel_row, pixel_column : IN std_logic_vector(9 downto 0);
            red, green, blue : OUT std_logic_vector(3 downto 0);
            vert_sync : IN std_logic;
            enabled : OUT std_logic
        );
    end component BossRenderer;

    component SpriteRenderer is
        port (
            clk : in std_logic;
            pixel_row    : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
            start_x  : in std_logic_vector(9 downto 0);
            start_y  : in std_logic_vector(9 downto 0);
            sprite_id : in integer;
            red   : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue  : out std_logic_vector(3 downto 0);
            transparent : out std_logic
        );
    end component SpriteRenderer;

    signal boss_red, boss_green, boss_blue : std_logic_vector(3 downto 0);
    signal boss_enabled : std_logic;

    --------- LASER BEAM SIGNALS ---------
    -- LASER WARNING SIGNALS (shared)
    signal laser_warning1_red, laser_warning1_green, laser_warning1_blue : std_logic_vector(3 downto 0);
    signal laser_warning1_transparent : std_logic;
    signal laser_warning2_red, laser_warning2_green, laser_warning2_blue : std_logic_vector(3 downto 0);
    signal laser_warning2_transparent : std_logic;
    signal laser_warning_enabled : std_logic;
    signal laser_warning_counter : integer range 0 to 100 := 0;

    -- LASER 1 SIGNALS
    signal laser1_red, laser1_green, laser1_blue : std_logic_vector(3 downto 0);
    signal laser1_transparent : std_logic;
    signal laser1_enabled : std_logic;
    signal laser1_y_pos : unsigned(9 downto 0) := (others => '0');

    -- LASER 2 SIGNALS
    signal laser2_red, laser2_green, laser2_blue : std_logic_vector(3 downto 0);
    signal laser2_transparent : std_logic;
    signal laser2_enabled : std_logic;
    signal laser2_y_pos : unsigned(9 downto 0) := to_unsigned(479, 10);

    constant laser1_target_y : unsigned(9 downto 0) := to_unsigned(140, 10);
    constant laser2_target_y : unsigned(9 downto 0) := to_unsigned(340, 10);

    type boss_state is (IDLE, WARNING, MOVING, HOLD, VICTORY);
    signal current_state : boss_state := IDLE;
    signal cycle_counter : integer range 0 to 500 := 0;
begin
    Boss: BossRenderer port map (
        clk25Mhz => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => boss_red,
        green => boss_green,
        blue => boss_blue,
        vert_sync => vert_sync,
        enabled => boss_enabled
    );

    -- LASER WARNING 1 SPRITE
    LASER_WARNING1 : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => CONV_STD_LOGIC_VECTOR(300, 10),
        start_y => std_logic_vector(laser1_y_pos),
        sprite_id => 6, -- LASER_BEAM_WARNING
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
        start_x => CONV_STD_LOGIC_VECTOR(400, 10),
        start_y => std_logic_vector(laser2_y_pos),
        sprite_id => 6, -- LASER_BEAM_WARNING
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
        start_x => CONV_STD_LOGIC_VECTOR(300, 10),
        start_y => std_logic_vector(laser1_y_pos),
        sprite_id => 7, -- LASER_BEAM
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
        start_x => CONV_STD_LOGIC_VECTOR(400, 10),
        start_y => std_logic_vector(laser2_y_pos),
        sprite_id => 7, -- LASER_BEAM
        red => laser2_red,
        green => laser2_green,
        blue => laser2_blue,
        transparent => laser2_transparent
    );
    

    PROCESS (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if level_four_enable = '0' then
                current_state <= IDLE;
                cycle_counter <= 0;
                game_finished <= '0';
                laser1_y_pos <= (others => '0');
                laser2_y_pos <= to_unsigned(479, 10);
                
            elsif not paused then
                case current_state is
                    
                    when IDLE =>
                        laser_warning_enabled <= '0';
                        laser1_enabled <= '0';
                        laser2_enabled <= '0';
                        -- Start attack after a short delay
                        if cycle_counter > 60 then 
                            current_state <= WARNING;
                            cycle_counter <= 0;
                        else
                            cycle_counter <= cycle_counter + 1;
                        end if;

                    when WARNING =>
                        laser_warning_enabled <= '1';
                        if cycle_counter > 120 then -- 2 second warning
                            current_state <= MOVING;
                            cycle_counter <= 0;
                        else
                            cycle_counter <= cycle_counter + 1;
                        end if;

                    when MOVING =>
                        laser_warning_enabled <= '0';
                        laser1_enabled <= '1';
                        laser2_enabled <= '1';
                        
                        -- Move lasers toward targets
                        if laser1_y_pos < laser1_target_y then 
                            laser1_y_pos <= laser1_y_pos + 2; 
                        end if;
                        if laser2_y_pos > laser2_target_y then 
                            laser2_y_pos <= laser2_y_pos - 2; 
                        end if;

                        -- Transition when both reach center
                        if laser1_y_pos >= laser1_target_y and laser2_y_pos <= laser2_target_y then
                            current_state <= HOLD;
                            cycle_counter <= 0;
                        end if;

                    when HOLD =>
                        -- Keep them visible and stationary
                        if cycle_counter > 180 then -- Stay for 3 seconds
                            current_state <= VICTORY;
                            cycle_counter <= 0;
                        else
                            cycle_counter <= cycle_counter + 1;
                        end if;

                    when VICTORY =>
                        -- HIDE EVERYTHING
                        laser1_enabled <= '0';
                        laser2_enabled <= '0';
                        laser_warning_enabled <= '0';
                        game_finished <= '1'; -- Trigger the win state
                        
                end case;
            end if;
        end if;
    end process;

    -- RENDER COMBINER
    RENDER_LOGIC : process(clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            if level_four_enable = '1' then
                if laser_warning_enabled = '1' and laser_warning1_transparent = '0' then
                    red <= laser_warning1_red; green <= laser_warning1_green; blue <= laser_warning1_blue;
                elsif laser_warning_enabled = '1' and laser_warning2_transparent = '0' then
                    red <= laser_warning2_red; green <= laser_warning2_green; blue <= laser_warning2_blue;
                elsif laser1_enabled = '1' and laser1_transparent = '0' then
                    red <= laser1_red; green <= laser1_green; blue <= laser1_blue;
                elsif laser2_enabled = '1' and laser2_transparent = '0' then
                    red <= laser2_red; green <= laser2_green; blue <= laser2_blue;
                elsif boss_enabled = '1' then
                    red <= boss_red; green <= boss_green; blue <= boss_blue;
                else
                    red <= (others => '0'); green <= (others => '0'); blue <= (others => '0');
                end if;
            end if;
        end if;
    end process;

end architecture behavior;