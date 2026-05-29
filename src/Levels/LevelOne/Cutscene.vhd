library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Cutscene is
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
end entity Cutscene;

architecture behavior of Cutscene is
    component SpriteRenderer is
        generic (
            SCALE_FACTOR : integer := 1;
            SPRITE_ID : integer range 0 to 64 := 0
        );
        port (
            clk : in std_logic;
            pixel_row    : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
            start_x  : in std_logic_vector(10 downto 0);
            start_y  : in std_logic_vector(10 downto 0);
            flip_y  : in std_logic := '0';
            red   : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue  : out std_logic_vector(3 downto 0);
            transparent : out std_logic
        );
    end component;

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
    

    signal boss_red, boss_green, boss_blue : std_logic_vector(3 downto 0);
    signal boss_transparent : std_logic;
    signal boss_red16, boss_green16, boss_blue16 : std_logic_vector(3 downto 0);
    signal boss_red17, boss_green17, boss_blue17 : std_logic_vector(3 downto 0);
    signal boss_transparent16, boss_transparent17 : std_logic;
    signal boss_frame_index : integer range 16 to 17 := 16;

    -- Background signals
    signal background_red, background_green, background_blue : std_logic_vector(3 downto 0);
    signal background_transparent : std_logic;

    signal text_enabled : std_logic := '1';

    signal frame_counter : integer range 0 to 101 := 0; -- Counts frames for animation timing
begin

    BOSS_16 : SpriteRenderer
    generic map (
        SCALE_FACTOR => 2,
        SPRITE_ID => 16
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => CONV_STD_LOGIC_VECTOR(240, 11), -- X position of the boss sprite
        start_y => CONV_STD_LOGIC_VECTOR(144, 11), -- Y position of the boss sprite
        flip_y => '0',
        red => boss_red16,
        green => boss_green16,
        blue => boss_blue16,
        transparent => boss_transparent16
    );

    BOSS_17 : SpriteRenderer
    generic map (
        SCALE_FACTOR => 2,
        SPRITE_ID => 17
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => CONV_STD_LOGIC_VECTOR(240, 11), -- X position of the boss sprite
        start_y => CONV_STD_LOGIC_VECTOR(144, 11), -- Y position of the boss sprite
        flip_y => '0',
        red => boss_red17,
        green => boss_green17,
        blue => boss_blue17,
        transparent => boss_transparent17
    );

    boss_red <= boss_red17 when boss_frame_index = 17 else boss_red16;
    boss_green <= boss_green17 when boss_frame_index = 17 else boss_green16;
    boss_blue <= boss_blue17 when boss_frame_index = 17 else boss_blue16;
    boss_transparent <= boss_transparent17 when boss_frame_index = 17 else boss_transparent16;

    MSG_ONE : title_display
    generic map (
        text_string => "SKELEKING HAS AWAKENED",
        text_size => 22,
        SIZE => 3
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => text_enabled,
        text_row => 300,
        text_col_start => 144
    );

    LOGIC_PROCESS : process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if (cutscene_enable = '1') then 
                if (frame_counter >= 50) then
                    if (frame_counter >= 100) then
                        cutscene_end <= '1';
                        boss_frame_index <= 17;
                    else
                        boss_frame_index <= 17;
                        frame_counter <= frame_counter + 1;
                    end if;
                else
                    boss_frame_index <= 16;
                    frame_counter <= frame_counter + 1;
                end if;
            else
                cutscene_end <= '0';
                frame_counter <= 0;
            end if;
        end if;
    end process;

    RENDER_PROCESS : process (clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            if (text_enabled = '1') then
                red <= "1111"; -- White text
                green <= "1111";
                blue <= "1111";
            elsif (boss_transparent = '0') then
                red <= boss_red;
                green <= boss_green;
                blue <= boss_blue;
            else
                red <= "0000"; -- Black background
                green <= "0000";
                blue <= "0000";
            end if;
        end if;
    end process;
end architecture;