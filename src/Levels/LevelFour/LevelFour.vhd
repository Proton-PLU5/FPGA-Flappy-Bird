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
        level_one_enable : IN std_logic;
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        paused : IN std_logic;
        pipe_1_enabled, pipe_2_enabled : OUT std_logic;
        pipe_1_red, pipe_1_green, pipe_1_blue : OUT std_logic_vector(3 downto 0);
        pipe_2_red, pipe_2_green, pipe_2_blue : OUT std_logic_vector(3 downto 0);
        pipe_1_x_pos : OUT unsigned(10 downto 0);
        pipe_2_x_pos : OUT unsigned(10 downto 0);
        pipe_1_render, pipe_2_render : OUT std_logic
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

    signal boss_red, boss_green, boss_blue : std_logic_vector(3 downto 0);
    signal boss_enabled : std_logic;

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
    
    

end architecture behavior;