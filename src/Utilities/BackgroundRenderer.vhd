library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

LIBRARY altera_mf;
USE altera_mf.all;

entity BackgroundRenderer is
    port (
        clk          : in std_logic;
        pixel_row    : in std_logic_vector(9 downto 0);
        pixel_column : in std_logic_vector(9 downto 0);
        bg_id        : in integer range 0 to 3; -- Switch between up to 4 backgrounds
        red          : out std_logic_vector(3 downto 0);
        green        : out std_logic_vector(3 downto 0);
        blue         : out std_logic_vector(3 downto 0)
    );
end entity BackgroundRenderer;

architecture behavior of BackgroundRenderer is

    -- altsyncram configuration for a 12-bit wide ROM
    component altsyncram
        generic (
            clock_enable_input_a   : STRING;
            clock_enable_output_a  : STRING;
            init_file              : STRING;
            intended_device_family : STRING;
            lpm_hint               : STRING;
            lpm_type               : STRING;
            numwords_a             : NATURAL;
            operation_mode         : STRING;
            outdata_aclr_a         : STRING;
            outdata_reg_a          : STRING;
            widthad_a              : NATURAL;
            width_a                : NATURAL;
            width_byteena_a        : NATURAL
        );
        port (
            clock0    : in std_logic;
            address_a : in std_logic_vector(18 downto 0); -- Adjust width based on total memory depth
            q_a       : out std_logic_vector(11 downto 0)
        );
    end component;

    -- Constants for a 320x240 image
    constant BG_WIDTH  : integer := 320;
    constant PIXELS_PER_BG : integer := 76800; -- 320 * 240

    signal rom_address : std_logic_vector(18 downto 0);
    signal rom_data    : std_logic_vector(11 downto 0);

    signal local_x     : integer range 0 to 511;
    signal local_y     : integer range 0 to 255;
    signal base_offset : integer;

begin

    -- Instantiate the Block RAM ROM
    BG_ROM : altsyncram
    generic map (
        clock_enable_input_a   => "BYPASS",
        clock_enable_output_a  => "BYPASS",
        init_file              => "backgrounds.mif", -- Ensure this file is added to your Quartus project
        intended_device_family => "Cyclone V",
        lpm_hint               => "ENABLE_RUNTIME_MOD=NO",
        lpm_type               => "altsyncram",
        numwords_a             => 307200, -- Maximum depth for 4 backgrounds (4 * 76800). Adjust if less.
        operation_mode         => "ROM",
        outdata_aclr_a         => "NONE",
        outdata_reg_a          => "UNREGISTERED",
        widthad_a              => 19,     -- 2^19 = 524288, large enough for our address
        width_a                => 12,
        width_byteena_a        => 1
    )
    port map (
        clock0    => clk,
        address_a => rom_address,
        q_a       => rom_data
    );

    -- Divide pixel coordinates by 2 to achieve 2x scaling (640x480 screen -> 320x240 image)
    local_x <= to_integer(unsigned(pixel_column(9 downto 1))); 
    local_y <= to_integer(unsigned(pixel_row(9 downto 1)));    

    -- Calculate memory address: Offset by which background is chosen, plus row * width + column
    base_offset <= bg_id * PIXELS_PER_BG;
    
    -- Assign address to ROM
    rom_address <= std_logic_vector(to_unsigned(base_offset + (local_y * BG_WIDTH) + local_x, 19));

    -- Map ROM output data to RGB ports
    -- Note: Data read from ROM has a 1-clock-cycle delay.
    process(clk)
    begin
        if rising_edge(clk) then
            red   <= rom_data(11 downto 8);
            green <= rom_data(7 downto 4);
            blue  <= rom_data(3 downto 0);
        end if;
    end process;

end architecture behavior;