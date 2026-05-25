LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;


entity LivesRenderer is
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
end entity LivesRenderer;

architecture behavior of LivesRenderer is

    component SpriteRenderer is
        port (
            clk : in std_logic;
            pixel_row    : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
			   start_x  : in std_logic_vector(10 downto 0);
			   start_y  : in std_logic_vector(10 downto 0);
			   sprite_id : in integer range 0 to 7;
            red   : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue  : out std_logic_vector(3 downto 0);
            transparent : out std_logic
        );
    end component;

    signal start_x1 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(10, 10); 
    signal start_y1 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(10, 10);
    signal sprite_id1 : integer := 3;
    signal transparent : std_logic;

    signal start_x2 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(50, 10);
    signal start_y2 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(10, 10);
    signal sprite_id2 : integer := 3;
    
    signal start_x3 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(90, 10);
    signal start_y3 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(10, 10);
    signal sprite_id3 : integer := 3;

    signal render1 : std_logic;
    signal render2 : std_logic;
    signal render3 : std_logic;

    signal red1, green1, blue1 : std_logic_vector(3 downto 0);
    signal red2, green2, blue2 : std_logic_vector(3 downto 0);
    signal red3, green3, blue3 : std_logic_vector(3 downto 0);

    signal transparent1, transparent2, transparent3 : std_logic;


begin

    LIFE1_COMPONENT : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & start_x1,
        start_y => '0' & start_y1,
        sprite_id => sprite_id1,
        red => red1,
        green => green1,
        blue => blue1,
        transparent => transparent1
    );

    LIFE2_COMPONENT : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & start_x2,
        start_y => '0' & start_y2,
        sprite_id => sprite_id2,
        red => red2,
        green => green2,
        blue => blue2,
        transparent => transparent2
    );
    
    LIFE3_COMPONENT : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & start_x3,
        start_y => '0' & start_y3,
        sprite_id => sprite_id3,
        red => red3,
        green => green3,
        blue => blue3,
        transparent => transparent3
    );

    render1 <= '1' when (
        ('0' & pixel_column >= '0' & start_x1) and
        ('0' & pixel_column <  '0' & start_x1 + CONV_STD_LOGIC_VECTOR(32,10)) and
        ('0' & pixel_row    >= '0' & start_y1) and
        ('0' & pixel_row    <  '0' & start_y1 + CONV_STD_LOGIC_VECTOR(32,10)) -- LIFE1 render bounds
    ) else '0';

    render2 <= '1' when (
        ('0' & pixel_column >= '0' & start_x2) and
        ('0' & pixel_column <  '0' & start_x2 + CONV_STD_LOGIC_VECTOR(32,10)) and
        ('0' & pixel_row    >= '0' & start_y2) and
        ('0' & pixel_row    <  '0' & start_y2 + CONV_STD_LOGIC_VECTOR(32,10)) -- LIFE2 render bounds
    ) else '0';

    render3 <= '1' when (
        ('0' & pixel_column >= '0' & start_x3) and
        ('0' & pixel_column <  '0' & start_x3 + CONV_STD_LOGIC_VECTOR(32,10)) and
        ('0' & pixel_row    >= '0' & start_y3) and
        ('0' & pixel_row    <  '0' & start_y3 + CONV_STD_LOGIC_VECTOR(32,10)) -- LIFE3 render bounds
    ) else '0';
    
    red <= red1 when render1 = '1' else
           red2 when render2 = '1' else
           red3 when render3 = '1' else
           (others => '0');
    green <= green1 when render1 = '1' else
             green2 when render2 = '1' else
             green3 when render3 = '1' else
             (others => '0');
    blue <= blue1 when render1 = '1' else
            blue2 when render2 = '1' else
            blue3 when render3 = '1' else
            (others => '0');

    COLLISION: process(clk)
    begin 
        if rising_edge(clk) then

            if (collision_count = 0 or reset = '1') then
                sprite_id1 <= 3; -- full heart
                sprite_id2 <= 3; 
                sprite_id3 <= 3;
                no_lives_left <= '0';
            elsif (collision_count = 1) then
                sprite_id3 <= 4; -- empty heart
            elsif (collision_count = 2) then
                sprite_id2 <= 4;
            elsif (collision_count = 3) then
                sprite_id1 <= 4;
                no_lives_left <= '1';
            end if;

        end if;
    end process;

    enabled <= (render1 and not transparent1) or (render2 and not transparent2) or (render3 and not transparent3);

end architecture;