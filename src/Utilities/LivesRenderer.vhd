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

    signal start_x1 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(10, 10); 
    signal start_y1 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(10, 10);
    signal start_x2 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(50, 10);
    signal start_y2 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(10, 10);
    
    signal start_x3 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(90, 10);
    signal start_y3 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(10, 10);

    signal render1 : std_logic;
    signal render2 : std_logic;
    signal render3 : std_logic;

    signal red1_full, green1_full, blue1_full : std_logic_vector(3 downto 0);
    signal red1_empty, green1_empty, blue1_empty : std_logic_vector(3 downto 0);
    signal red2_full, green2_full, blue2_full : std_logic_vector(3 downto 0);
    signal red2_empty, green2_empty, blue2_empty : std_logic_vector(3 downto 0);
    signal red3_full, green3_full, blue3_full : std_logic_vector(3 downto 0);
    signal red3_empty, green3_empty, blue3_empty : std_logic_vector(3 downto 0);

    signal transparent1, transparent2, transparent3 : std_logic;
    signal t1_full, t1_empty : std_logic;
    signal t2_full, t2_empty : std_logic;
    signal t3_full, t3_empty : std_logic;

    signal life1_full, life2_full, life3_full : std_logic;


begin

    LIFE_1_FULL : SpriteRenderer
    generic map (
        SPRITE_ID => 3
    )
    port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & start_x1,
        start_y => '0' & start_y1,
        flip_y => '0',
        red => red1_full,
        green => green1_full,
        blue => blue1_full,
        transparent => t1_full
    );

    LIFE_1_EMPTY : SpriteRenderer
    generic map (
        SPRITE_ID => 4
    )
    port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & start_x1,
        start_y => '0' & start_y1,
        flip_y => '0',
        red => red1_empty,
        green => green1_empty,
        blue => blue1_empty,
        transparent => t1_empty
    );

    LIFE_2_FULL : SpriteRenderer
    generic map (
        SPRITE_ID => 3
    )
    port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & start_x2,
        start_y => '0' & start_y2,
        flip_y => '0',
        red => red2_full,
        green => green2_full,
        blue => blue2_full,
        transparent => t2_full
    );

    LIFE_2_EMPTY : SpriteRenderer
    generic map (
        SPRITE_ID => 4
    )
    port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & start_x2,
        start_y => '0' & start_y2,
        flip_y => '0',
        red => red2_empty,
        green => green2_empty,
        blue => blue2_empty,
        transparent => t2_empty
    );

    LIFE_3_FULL : SpriteRenderer
    generic map (
        SPRITE_ID => 3
    )
    port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & start_x3,
        start_y => '0' & start_y3,
        flip_y => '0',
        red => red3_full,
        green => green3_full,
        blue => blue3_full,
        transparent => t3_full
    );

    LIFE_3_EMPTY : SpriteRenderer
    generic map (
        SPRITE_ID => 4
    )
    port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & start_x3,
        start_y => '0' & start_y3,
        flip_y => '0',
        red => red3_empty,
        green => green3_empty,
        blue => blue3_empty,
        transparent => t3_empty
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
  
        life1_full <= '1' when collision_count <= 2 else '0';
        life2_full <= '1' when collision_count <= 1 else '0';
        life3_full <= '1' when collision_count = 0 else '0';

        red <= red1_full when (render1 = '1' and life1_full = '1') else
            red1_empty when render1 = '1' else
            red2_full when (render2 = '1' and life2_full = '1') else
            red2_empty when render2 = '1' else
            red3_full when (render3 = '1' and life3_full = '1') else
            red3_empty when render3 = '1' else
           (others => '0');
        green <= green1_full when (render1 = '1' and life1_full = '1') else
              green1_empty when render1 = '1' else
              green2_full when (render2 = '1' and life2_full = '1') else
              green2_empty when render2 = '1' else
              green3_full when (render3 = '1' and life3_full = '1') else
              green3_empty when render3 = '1' else
             (others => '0');
        blue <= blue1_full when (render1 = '1' and life1_full = '1') else
             blue1_empty when render1 = '1' else
             blue2_full when (render2 = '1' and life2_full = '1') else
             blue2_empty when render2 = '1' else
             blue3_full when (render3 = '1' and life3_full = '1') else
             blue3_empty when render3 = '1' else
            (others => '0');

    COLLISION: process(clk)
    begin 
        if rising_edge(clk) then

            if (collision_count = 0 or reset = '1') then
                no_lives_left <= '0';
            elsif (collision_count = 3) then
                no_lives_left <= '1';
            end if;

        end if;
    end process;

    transparent1 <= t1_full when life1_full = '1' else t1_empty;
    transparent2 <= t2_full when life2_full = '1' else t2_empty;
    transparent3 <= t3_full when life3_full = '1' else t3_empty;

    enabled <= (render1 and not transparent1) or (render2 and not transparent2) or (render3 and not transparent3);

end architecture;