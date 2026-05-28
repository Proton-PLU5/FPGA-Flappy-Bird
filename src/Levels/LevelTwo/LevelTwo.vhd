library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Placeholder to test level 2; This is just level one but with red pipes
entity LevelTwo is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync : IN std_logic;
		  SW : IN std_logic_vector(9 downto 0);
		  KEY : IN std_logic_vector(3 DOWNTO 0);
        level_two_enable : IN std_logic := '0';
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        paused : IN std_logic;
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
end entity LevelTwo;

architecture behavior of LevelTwo is
    component OffsetPipe is 
        generic (
            START_OFFSET : integer := 0
        );
        port (
            clk, vert_sync, mouse_left  : in std_logic;
            pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
            red, green, blue            : out std_logic_vector(3 downto 0);
            height                      : in integer range 0 to 480; -- Height of the centre of the gap in the pipe
            gap                         : in integer range 0 to 480; -- This is the size of the gap in the pipe
            reset                       : in std_logic;
            end_reached                 : out std_logic;
            x_pos                       : out unsigned(10 downto 0);
            enabled                     : in std_logic;
            render                      : out std_logic;
            part_to_render              : in std_logic;
            player_y_pos                : in unsigned(9 downto 0)
        );
    end component OffsetPipe;
	 
    component PowerUp is
        port (
            clk, vert_sync, mouse_left : in std_logic;
            pixel_row, pixel_column : in std_logic_vector(9 downto 0);
            red, green, blue : out std_logic_vector(3 downto 0);
            reset : in std_logic;
            collect : in std_logic;
            collect_count : out integer;
            render : out std_logic;
            x_pos : out unsigned(10 downto 0);
            y_pos : out unsigned(9 downto 0);
            enable : in std_logic
        );
    end component PowerUp;

	component LFSR is
        port (
        clk : IN std_logic;
        reset : IN std_logic;
        enable : IN std_logic;
        random_out : OUT std_logic_vector(7 downto 0)
    );
    end component LFSR;

    -- Pipe 1 Values
    signal pipe_1_enabled_s : std_logic := '0';
    signal pipe_1_end_reached : std_logic;
    signal pipe_1_x_pos_s : unsigned(10 downto 0);
    signal pipe_1_red_s, pipe_1_green_s, pipe_1_blue_s : std_logic_vector(3 downto 0);
    signal pipe_1_reset : std_logic := '0';
    signal pipe_1_height   : integer range 0 to 480 := 240;
    signal pipe_1_part_to_render : std_logic := '0'; 
    
    -- Pipe 2 Values
    signal pipe_2_enabled_s : std_logic := '0';
    signal pipe_2_end_reached : std_logic;
    signal pipe_2_x_pos_s : unsigned(10 downto 0);
    signal pipe_2_red_s, pipe_2_green_s, pipe_2_blue_s : std_logic_vector(3 downto 0);
    signal pipe_2_reset : std_logic := '0';
    signal pipe_2_height   : integer range 0 to 480 := 240;
    signal pipe_2_part_to_render : std_logic := '0'; 
    signal pipe_2_waiting : std_logic := '0';

    signal powerup_enabled_s : std_logic := '0';
    signal powerup_render_s : std_logic := '0';
    signal powerup_red_s, powerup_green_s, powerup_blue_s : std_logic_vector(3 downto 0);
    signal powerup_reset : std_logic := '0';
    signal powerup_x_pos_s : unsigned(10 downto 0);
    signal powerup_y_pos_s : unsigned(9 downto 0);

    signal last_key_3_state : std_logic := '1';

    signal pipe_1_render_s : std_logic;
    signal pipe_2_render_s : std_logic;

    --LSFR
    signal lfsr_out      : std_logic_vector(7 downto 0);

    signal start_rendering_pipe_2 : std_logic := '0';

    -- Clock domain crossing edge trackers
    signal pipe_1_end_q : std_logic := '0';
    signal pipe_2_end_q : std_logic := '0';

begin
    pipe_1_enabled_s <= level_two_enable and not paused;
    pipe_2_enabled_s <= level_two_enable and not paused and start_rendering_pipe_2;
    powerup_enabled_s <= level_two_enable and not paused;

    PIPE_COMPONENT : OffsetPipe
        generic map ( START_OFFSET => 0 )
        port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => mouse_left,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => pipe_1_red_s,
        green => pipe_1_green_s,
        blue => pipe_1_blue_s,
        height => pipe_1_height,
        gap => 100,
        reset => pipe_1_reset,
        end_reached => pipe_1_end_reached,
        enabled => pipe_1_enabled_s,
        x_pos => pipe_1_x_pos_s,
        render => pipe_1_render_s,
        part_to_render => pipe_1_part_to_render,
        player_y_pos => player_y_pos
    );

    PIPE2_COMPONENT : OffsetPipe
        generic map ( START_OFFSET => 0 )
        port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => mouse_left,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => pipe_2_red_s,
        green => pipe_2_green_s,
        blue => pipe_2_blue_s,
        height => pipe_2_height,
        gap => 150,
        reset => pipe_2_reset,
        end_reached => pipe_2_end_reached,
        enabled => pipe_2_enabled_s,
        x_pos => pipe_2_x_pos_s,
        render => pipe_2_render_s,
        part_to_render => pipe_2_part_to_render,
        player_y_pos => player_y_pos
    );

    LFSR_COMPONENT : LFSR port map (
        clk        => clk25Mhz,
        reset      => '0',
        enable     => '1',
        random_out => lfsr_out
    );

    POWERUP_COMPONENT : PowerUp port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => mouse_left,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => powerup_red_s,
        green => powerup_green_s,
        blue => powerup_blue_s,
        reset => powerup_reset,
        collect => powerup_collect,
        collect_count => powerup_count,
        render => powerup_render_s,
        x_pos => powerup_x_pos_s,
        y_pos => powerup_y_pos_s,
        enable => powerup_enabled_s
    );

    CLOCK_PROCESS : process(clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            if (level_two_enable = '1') then
                
                -- Update history tracking filters every cycle
                pipe_1_end_q <= pipe_1_end_reached;
                pipe_2_end_q <= pipe_2_end_reached;
                
                -- STAGGER TRIGGER: Same as Level One
                if (pipe_1_x_pos_s < to_unsigned(320, 11)) then
                    start_rendering_pipe_2 <= '1';
                end if;

                -------------------------------------------------
                -- PIPE 1 HANDSHAKE (CDC PROTECTED)
                -------------------------------------------------
                if pipe_1_end_reached = '1' then
                    pipe_1_reset <= '1'; -- Hold reset high so slow vert_sync domain catches it
                    
                    -- ONLY sample the LFSR on the very first 25MHz cycle it hits the wall!
                    if pipe_1_end_q = '0' then 
                        pipe_1_height <= to_integer(unsigned('0' & lfsr_out(7 downto 1))) + 160;
                        pipe_1_part_to_render <= lfsr_out(7); 
                    end if;
                else
                    pipe_1_reset <= '0';
                end if;

                -------------------------------------------------
                -- PIPE 2 HANDSHAKE (CDC PROTECTED)
                -------------------------------------------------
                if pipe_2_end_reached = '1' then
                    pipe_2_reset <= '1'; -- Hold reset high so slow vert_sync domain catches it
                    
                    -- ONLY sample the LFSR on the very first 25MHz cycle it hits the wall!
                    if pipe_2_end_q = '0' then 
                        pipe_2_height <= to_integer(unsigned('0' & lfsr_out(7 downto 1))) + 160;
                        pipe_2_part_to_render <= not lfsr_out(7); 
                    end if;
                else
                    pipe_2_reset <= '0';
                end if;

            else
                -- SYSTEM RESET (Level disabled or Title Screen)
                pipe_1_reset <= '1'; 
                pipe_2_reset <= '1';
                pipe_1_end_q <= '0';
                pipe_2_end_q <= '0';
                start_rendering_pipe_2 <= '0';
            end if;
        end if;
    end process;

    pipe_1_red <= pipe_1_red_s;
    pipe_1_green <= pipe_1_green_s;
    pipe_1_blue <= pipe_1_blue_s;
    pipe_2_red <= pipe_2_red_s;
    pipe_2_green <= pipe_2_green_s;
    pipe_2_blue <= pipe_2_blue_s;
    pipe_1_x_pos <= pipe_1_x_pos_s;
    pipe_2_x_pos <= pipe_2_x_pos_s;
    powerup_render <= powerup_render_s;
    powerup_red <= powerup_red_s;
    powerup_green <= powerup_green_s;
    powerup_blue <= powerup_blue_s;
    pipe_1_render <= pipe_1_render_s;
    pipe_2_render <= pipe_2_render_s;
end architecture behavior;