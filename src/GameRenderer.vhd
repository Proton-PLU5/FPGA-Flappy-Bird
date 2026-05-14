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
        enabled : IN std_logic
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

    component Pipe is 
        port (
            clk, vert_sync, mouse_left : in std_logic;
            pixel_row, pixel_column    : in std_logic_vector(9 downto 0);
            red, green, blue           : out std_logic_vector(3 downto 0);
            height                     : in integer range 0 to 480; -- Height of the centre of the gap in the pipe
            gap                        : in integer range 0 to 480; -- This is the size of the gap in the pipe
            reset                      : in std_logic;
            end_reached                : out std_logic;
            enabled                    : out std_logic;
            x_pos                      : out unsigned(10 downto 0)
        );
    end component Pipe;

	component LFSR is
        port (
        clk : IN std_logic;
        reset : IN std_logic;
        enable : IN std_logic;
        random_out : OUT std_logic_vector(7 downto 0)
    );
    end component LFSR;
    
    -- Ball Values
    signal ball_enabled : std_logic := '0';
    signal ball_red, ball_green, ball_blue : std_logic_vector(3 downto 0);

    -- Pipe Values
    signal pipe_enabled : std_logic := '0';
    signal pipe_end_reached : std_logic;
    signal pipe_x_pos : unsigned(10 downto 0);
    signal pipe_red, pipe_green, pipe_blue : std_logic_vector(3 downto 0);
    signal pipe_reset : std_logic := '0';
    signal pipe_height   : integer range 0 to 480 := 240;

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

    PIPE_COMPONENT : Pipe port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => mouse_left,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => pipe_red,
        green => pipe_green,
        blue => pipe_blue,
        height => pipe_height,
        gap => 100,
        reset => pipe_reset,
        end_reached => pipe_end_reached,
        enabled => pipe_enabled,
        x_pos => pipe_x_pos
    );

    LFSR_COMPONENT : LFSR port map (
        clk        => clk25Mhz,
        reset      => '0',
        enable     => '1',
        random_out => lfsr_out
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
                elsif pipe_enabled = '1' then
                    red <= pipe_red;
                    green <= pipe_green;
                    blue <= pipe_blue;
                else
                    red <= background_red;
                    green <= background_green;
                    blue <= background_blue;
                end if;

                -- Score increment (one point per pipe pass):
                if (pipe_x_pos < to_unsigned(50, 11) and score_incremented = '0') then
                    score <= score + 1;
                    score_incremented <= '1';
                elsif (pipe_x_pos >= to_unsigned(50, 11)) then
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

    PIPE_HEIGHT_RANDOMISER : process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            pipe_reset <= '0';
            if pipe_end_reached = '1' then
                pipe_height <= to_integer(unsigned(lfsr_out)) * 280 / 256 + 100;
                pipe_reset <= '1';
            end if;
        end if;
    end process PIPE_HEIGHT_RANDOMISER;
    
end architecture behavior;