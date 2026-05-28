library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

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
            frame_index  : in integer range 0 to 15; -- Which frame in the sheet to show
            sprite_id    : in integer range 0 to 64;
            red, green, blue : out std_logic_vector(3 downto 0);
            transparent  : out std_logic
        );
    end component;

    signal boss_red, boss_green, boss_blue : std_logic_vector(3 downto 0);
    signal boss_enabled : std_logic := '1';
    signal boss_transparent : std_logic;
    signal boss_frame_index : integer range 0 to 32 := 0;

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
        start_x => (others => '0'),
        start_y => (others => '0'),
        frame_index => boss_frame_index,
        sprite_id => 0, -- Your cutscene sprite
        red => boss_red,
        green => boss_green,
        blue => boss_blue,
        transparent => boss_transparent
    );

    process (vert_sync)
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
            end if;
        end if;
    end process;

    red   <= boss_red   when boss_enabled = '1' and boss_transparent = '0' else (others => '0');
	green <= boss_green when boss_enabled = '1' and boss_transparent = '0' else (others => '0');
	blue  <= boss_blue  when boss_enabled = '1' and boss_transparent = '0' else (others => '0');
end architecture;