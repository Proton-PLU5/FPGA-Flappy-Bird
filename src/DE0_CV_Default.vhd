LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_SIGNED.all;

entity DE0_CV_Default is
    port (
        CLOCK_50 : in std_logic;
        SW : in std_logic_vector(9 downto 0);
        KEY : IN std_logic_vector(3 DOWNTO 0);
        VGA_G, VGA_B, VGA_R : out std_logic_vector(3 downto 0);
        VGA_HS : out std_logic;
        VGA_VS : out std_logic;
        PS2_DAT, PS2_CLK : INOUT std_logic;
        HEX0, HEX1, HEX2 : OUT std_logic_vector(6 downto 0)
    );
end DE0_CV_Default;

architecture behavior of DE0_CV_Default is
    
    component VGA_SYNC
        PORT(    clock_25Mhz : IN    STD_LOGIC;
            red, green, blue: IN    STD_LOGIC_VECTOR(3 downto 0);
            red_out, green_out, blue_out : OUT STD_LOGIC_VECTOR(3 downto 0);
            horiz_sync_out, vert_sync_out    : OUT    STD_LOGIC;
            pixel_row, pixel_column: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
    end component;

    component PLL is
        port (
            refclk   : in  std_logic;
            rst      : in  std_logic;
            outclk_0 : out std_logic;
            locked   : out std_logic
        );
    end component;

    component MOUSE IS
        PORT( clock_25Mhz, reset         : IN std_logic;
            mouse_data                    : INOUT std_logic;
            mouse_clk                     : INOUT std_logic;
            left_button, right_button    : OUT std_logic;
            mouse_cursor_row             : OUT std_logic_vector(9 DOWNTO 0); 
            mouse_cursor_column         : OUT std_logic_vector(9 DOWNTO 0));            
    end component MOUSE;

    component Renderer is
        port (
            clk25Mhz : IN std_logic;
            mouse_left : IN std_logic;
            vert_sync, horz_sync : IN std_logic;
            SW : in std_logic_vector(9 downto 0);
            KEY : IN std_logic_vector(3 DOWNTO 0);
            pixel_row, pixel_column    : IN std_logic_vector(9 DOWNTO 0);
            red, green, blue : OUT std_logic_vector(3 downto 0)
        );
    end component Renderer;
    
    component BCD_to_SevenSeg is
         port (BCD_digit : in std_logic_vector(3 downto 0);
               SevenSeg_out : out std_logic_vector(6 downto 0));
    end component;

  signal Clk25Mhz : std_logic;
  signal text_on : std_logic;

    signal red_out, blue_out, green_out : std_logic_vector(3 downto 0) := (others => '0');
    signal pixel_row, pixel_column : std_logic_vector(9 downto 0);
    signal red : std_logic_vector(3 downto 0);
    signal green : std_logic_vector(3 downto 0);
    signal blue : std_logic_vector(3 downto 0);
    
    signal ball_red, ball_green, ball_blue : std_logic;
        
    signal vert_sync_out : std_logic;
    signal horz_sync_out : std_logic;
        
    signal count : integer range 0 to 999 := 0;
    signal ones : std_logic_vector(3 downto 0);
    signal tens : std_logic_vector(3 downto 0);
    signal hundreds : std_logic_vector(3 downto 0);
    
    signal left_button : std_logic;
    signal mouse_down : std_Logic := '0';

    signal pll_locked : std_logic;

begin
  
    PLL_COMPONENT : PLL port map (
        refclk => CLOCK_50,
        rst => '0',
        outclk_0 => Clk25Mhz,
        locked => pll_locked
	);
    
    MOUSE_COMPONENT : MOUSE port map (
        clock_25Mhz => clk25Mhz,
        reset => '0',
        mouse_data => PS2_DAT,
        mouse_clk => PS2_CLK,
        left_button => left_button,
        right_button => open,
        mouse_cursor_row => open,
        mouse_cursor_column => open
    );

     VGA : VGA_SYNC port map (
        clock_25Mhz => Clk25Mhz,
        red => red, 
        green => green,
        blue => blue,
        red_out => red_out,
        green_out => green_out,
        blue_out => blue_out,
        horiz_sync_out => horz_sync_out,
        vert_sync_out => vert_sync_out,
        pixel_row => pixel_row,
        pixel_column => pixel_column
    );
    
    ONES_COVERTER: BCD_to_SevenSeg port map (
        BCD_digit => ones,
        SevenSeg_out => HEX0
    );
    TENS_COVERTER: BCD_to_SevenSeg port map (
        BCD_digit => tens,
        SevenSeg_out => HEX1
    );
    HUNDREDS_COVERTER: BCD_to_SevenSeg port map (
        BCD_digit => hundreds,
        SevenSeg_out => HEX2
    );
          
    RENDERER_COMPONENT : Renderer port map (
        clk25Mhz => Clk25Mhz,
        mouse_left => left_button, -- Passed into Parent Renderer
        vert_sync => vert_sync_out,
        horz_sync => horz_sync_out,
        SW => SW,
        KEY => KEY,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => red,
        green => green,
        blue => blue
    );
  
    -- Debounced click process to step score tracking manually on your 7-Segments
    process (CLOCK_50)
    begin
         if rising_edge(CLOCK_50) then
            if (left_button = '1' and mouse_down = '0') then
                if count = 999 then
                    count <= 0;
                else
                    count <= count + 1;
                end if;
                mouse_down <= '1';
            elsif (left_button = '0') then
                mouse_down <= '0';
            end if;
         end if;
    end process;

    VGA_R <= red_out;
    VGA_G <= green_out;
    VGA_B <= blue_out;
    VGA_VS <= vert_sync_out;
    VGA_HS <= horz_sync_out;
    ones <= CONV_STD_LOGIC_VECTOR(count mod 10, 4);
    tens <= CONV_STD_LOGIC_VECTOR((count / 10) mod 10, 4);
    hundreds <= CONV_STD_LOGIC_VECTOR(count / 100, 4);
end architecture behavior;