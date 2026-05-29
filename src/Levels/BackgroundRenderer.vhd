LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;



entity BackgroundRenderer is
    port (
        clk25Mhz : IN std_logic;
        vert_sync, horz_sync : IN std_logic;
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic_vector(3 downto 0);
        paused : IN std_logic;
        enabled : OUT std_logic
    );
end entity BackgroundRenderer;

architecture Behavioral of BackgroundRenderer is

    component TileRenderer is
        generic (
            TILE_ID : integer range 0 to 255 := 0
        );
        port (
            clk, vert_sync, mouse_left  : in std_logic;
            pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
            red, green, blue            : out std_logic_vector(3 downto 0);
            reset                       : in std_logic;
            enabled                     : in std_logic;
            offset                      : in  UNSIGNED(5 downto 0);
			transparent : out std_logic
        );
    end component TileRenderer;

    signal top_red, top_green, top_blue : std_logic_vector(3 downto 0);
    signal middle_red, middle_green, middle_blue : std_logic_vector(3 downto 0);
    signal down_red, down_green, down_blue : std_logic_vector(3 downto 0);
    signal middle_transparent, down_transparent : std_logic;
    signal top_transparent: std_logic;

    signal render1, render2, render3 : std_logic := '0';

    signal start_y1 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(0, 10);

    signal start_y2 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(64, 10);

    signal start_y3 : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(416, 10);

    signal offset : unsigned(5 downto 0) := (others => '0');

    -- Background size
    constant SPRITE_WIDTH  : integer := 1138;
begin 

    render1 <= '1' when (('0' & pixel_row  >= '0' & start_y1) and
        ('0' & pixel_row < '0' & start_y1 + CONV_STD_LOGIC_VECTOR(64,10)) 
    ) else '0';

    render2 <= '1' when (
        ('0' & pixel_row  >= '0' & start_y2) and
        ('0' & pixel_row  <  '0' & CONV_STD_LOGIC_VECTOR(416,10)) 
    ) else '0';

    render3 <= '1' when (
        ('0' & pixel_row    >= '0' & start_y3) and
        ('0' & pixel_row    <  '0' & CONV_STD_LOGIC_VECTOR(480,10)) 
    ) else '0';

    TOP_BAR : TileRenderer
    generic map (
        TILE_ID => 5
    )
    port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => '0',
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => top_red,
        green => top_green,
        blue => top_blue,
        reset => '0',
        enabled => render1,
        transparent => top_transparent,
		  offset => offset
	 );
    
    MIDDLE : TileRenderer
    generic map (
        TILE_ID => 14
    )
    port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => '0',
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => middle_red,
        green => middle_green,
        blue => middle_blue,
        reset => '0',
        enabled => render2,
        transparent => middle_transparent,
		  offset => offset
    );
    
    BOTTOM_BAR : TileRenderer
    generic map (
        TILE_ID => 5
    )
    port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => '0',
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => down_red,
        green => down_green,
        blue => down_blue,
        reset => '0',
        enabled => render3,
        transparent => down_transparent,
		  offset => offset
    );

    process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if (paused = '0') then
                offset <= offset + 1;
            end if;
        end if;
    end process;

    red <= top_red when render1 = '1' else
           middle_red when render2 = '1' else
           down_red when render3 = '1' else
           (others => '0');
    green <= top_green when render1 = '1' else
             middle_green when render2 = '1' else
             down_green when render3 = '1' else
             (others => '0');
    blue <= top_blue when render1 = '1' else
            middle_blue when render2 = '1' else
            down_blue when render3 = '1' else
            (others => '0');
    
    enabled <= render1 or render2 or render3;

end architecture Behavioral;


