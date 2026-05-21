library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--Placeholder to test level 2; This is just pipe but red
entity OffsetPipe is 
    port (
        clk, vert_sync, mouse_left  : in std_logic;
        pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
        red, green, blue            : out std_logic_vector(3 downto 0);
        height                      : in integer range 0 to 480; -- Height of the centre of the gap in the pipe
        gap                         : in integer range 0 to 480; -- This is the size of the gap in the pipe
        reset                       : in std_logic;
        end_reached                 : out std_logic;
        x_pos                       : out unsigned(10 downto 0);
        enabled                     : in std_logic;
        render                      : out std_logic
    );
end entity OffsetPipe;

architecture behaviour of OffsetPipe is
    signal render_out : std_logic;
    signal pipe_x_pos : unsigned(10 downto 0) := to_unsigned(640, 11); -- Start off-screen right
    signal pipe_top_y_pos : unsigned(9 downto 0);
    signal pipe_bottom_y_pos : unsigned(9 downto 0);
    signal pipe_part_to_render : std_logic; -- '0' for top part, '1' for bottom part
    signal pipe_width : unsigned(9 downto 0) := to_unsigned(25,10);
begin
    -- render_out logic
    render_out <= '1' when (
        (pipe_x_pos <= unsigned(pixel_column) + pipe_width) and (unsigned(pixel_column) <= pipe_x_pos + pipe_width)
        and (
            ((unsigned(pixel_row) <= pipe_top_y_pos) and (pipe_part_to_render = '1')) or
            ((unsigned(pixel_row) >= pipe_bottom_y_pos) and (pipe_part_to_render = '0'))
        )
    ) else '0';

    PIPE_CONTROLLER : process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if enabled = '1' then
                if reset = '1' then
                    end_reached <= '0';

                    -- Reset pipe positions
                    pipe_x_pos <= to_unsigned(640, 11);
                    pipe_top_y_pos <= to_unsigned(height, 10) - to_unsigned(gap/2, 10);
                    pipe_bottom_y_pos <= to_unsigned(height, 10) + to_unsigned(gap/2, 10);
                elsif (pipe_x_pos <= to_unsigned(0, 11)) then
                    end_reached <= '1';
                else
                    pipe_x_pos <= pipe_x_pos - to_unsigned(2, 11);
                    end_reached <= '0';
                    
                    -- The "Jump" logic!
                    if pipe_x_pos <= to_unsigned(50, 11) then
                        pipe_top_y_pos <= pipe_top_y_pos - to_unsigned(40, 10);  -- Push up by 40 pixels
                        pipe_bottom_y_pos <= pipe_bottom_y_pos - to_unsigned(40, 10);  -- Adjust bottom position accordingly
                    end if;
                end if;
            end if;
        end if;
    end process PIPE_CONTROLLER;

    render <= render_out;
    red <= (others => '1');
    green <= (others => '0');
    blue <= (others => '0');
    x_pos <= pipe_x_pos;
end architecture behaviour;