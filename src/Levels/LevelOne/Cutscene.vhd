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
    component SpriteSheetRenderer is
        generic (
            SCALE_FACTOR : integer := 1;
            FRAME_WIDTH  : integer := 32;
            FRAME_HEIGHT : integer := 32
        );
        port (
            clk          : in std_logic;
            pixel_row    : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
            start_x      : in std_logic_vector(10 downto 0);
            start_y      : in std_logic_vector(10 downto 0);
            frame_index  : in integer range 0 to 31; -- Which frame in the sheet to show
            sprite_id    : in integer range 0 to 64;
            red, green, blue : out std_logic_vector(3 downto 0);
            transparent  : out std_logic
        );
    end component;

    component SpriteRenderer is
        generic (
            SCALE_FACTOR : integer := 1
        );
        port (
            clk : in std_logic;
            pixel_row : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
			start_x  : in std_logic_vector(10 downto 0);
			start_y  : in std_logic_vector(10 downto 0);
			sprite_id : in integer range 0 to 64;
            red : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue : out std_logic_vector(3 downto 0);
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
    signal boss_enabled : std_logic := '1';
    signal boss_transparent : std_logic;
    signal boss_frame_index : integer range 0 to 31 := 0;

    -- Background signals
    signal background_red, background_green, background_blue : std_logic_vector(3 downto 0);
    signal background_transparent : std_logic;

    signal text_enabled : std_logic := '0';

    signal frame_counter : integer := 0; -- Counts frames for animation timing
begin

    CUTSCENE_SPRITE : SpriteSheetRenderer 
    generic map (
        SCALE_FACTOR => 2, -- Adjust as needed
        FRAME_WIDTH => 80, -- Adjust based on your sprite sheet
        FRAME_HEIGHT => 96
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => CONV_STD_LOGIC_VECTOR(240, 11), -- X position of the boss
        start_y => CONV_STD_LOGIC_VECTOR(144, 11), -- Y position
        frame_index => boss_frame_index,
        sprite_id => 0, -- Your cutscene sprite
        red => boss_red,
        green => boss_green,
        blue => boss_blue,
        transparent => boss_transparent
    );
    
    BACKGROUND_SPRITE : SpriteRenderer
    generic map (
        SCALE_FACTOR => 1
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => (others => '0'), -- Background starts at (0,0)
        start_y => (others => '0'),
        sprite_id => 10, -- Your background sprite
        red => background_red,
        green => background_green,
        blue => background_blue,
        transparent => background_transparent
    );

    MSG_ONE : title_display
    generic map (
        text_string => "SKELETRON HAS AWAKENED!",
        text_size => 23,
        SIZE => 4
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        pixel_on => text_enabled,
        text_row => 300,
        text_col_start => 30
    );

    LOGIC_PROCESS : process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if (cutscene_enable = '1') then 
                frame_counter <= frame_counter + 1;
                if frame_counter >= 10 then -- Adjust timing as needed
                    if (boss_frame_index = 31) then
                        cutscene_end <= '1'; -- Signal that cutscene is done after last frame
                    else 
                        cutscene_end <= '0';
                        frame_counter <= 0;
                        boss_frame_index <= boss_frame_index + 1;
                    end if;    
                end if;
            else
                cutscene_end <= '0';
                frame_counter <= 0;
                boss_frame_index <= 0; -- Reset animation
            end if;
        end if;
    end process;

    RENDER_PROCESS : process (clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            if (boss_enabled = '1' and boss_transparent = '0') then
                red <= boss_red;
                green <= boss_green;
                blue <= boss_blue;
            elsif (text_enabled = '1') then
                red <= "1111"; -- White text
                green <= "1111";
                blue <= "1111";
            else
                red <= background_red;
                green <= background_green;
                blue <= background_blue;
            end if;
        end if;
    end process;
end architecture;