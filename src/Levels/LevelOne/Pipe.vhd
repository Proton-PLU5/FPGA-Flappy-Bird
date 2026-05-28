library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Pipe is 
    generic (
        START_OFFSET : integer := 0
    );
    port (
        clk, vert_sync, mouse_left  : in std_logic;
        pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
        red, green, blue            : out std_logic_vector(3 downto 0);
        height                      : in integer range 0 to 480;
        gap                         : in integer range 0 to 480;
        reset                       : in std_logic;
        end_reached                 : out std_logic;
        x_pos                       : out unsigned(10 downto 0);
        enabled                     : in std_logic;
        follow_enable               : in std_logic;
        follow_x_pos                : in unsigned(10 downto 0);
        render                      : out std_logic
    );
end entity Pipe;

architecture behaviour of Pipe is
    constant BONE_CAP_WIDTH   : integer := 45;
    constant BONE_CAP_HEIGHT  : integer := 25;
    constant BONE_BODY_WIDTH  : integer := 25;
    constant BONE_BODY_HEIGHT : integer := 480;

    constant BONE_CAP_SPRITE_ID  : integer := 11;
    constant BONE_BODY_SPRITE_ID : integer := 10;

    constant SPEED : integer := 2;

    signal pipe_x_pos           : unsigned(10 downto 0) := to_unsigned(640 + START_OFFSET, 11);
    signal pipe_x_pos_effective : unsigned(10 downto 0);

    -- Cap is wider than body; body is centred under cap.
    -- Cap x starts (CAP_WIDTH - BODY_WIDTH)/2 to the left of the body x so it's centered on the body.
    signal cap_x_offset : unsigned(10 downto 0) := to_unsigned((BONE_CAP_WIDTH - BONE_BODY_WIDTH) / 2, 11);

    -- Y boundaries (top-left origin)
    signal pipe_top_y_pos    : unsigned(9 downto 0); -- bottom edge of top pipe (start of gap)
    signal pipe_bottom_y_pos : unsigned(9 downto 0); -- top edge of bottom pipe (end of gap)

    signal top_cap_start_y    : unsigned(10 downto 0);
    signal bottom_cap_start_y    : unsigned(10 downto 0);

    signal render_top_cap  : std_logic;
    signal render_top_body : std_logic;
    signal render_bottom_cap  : std_logic;
    signal render_bottom_body : std_logic;

    signal top_cap_r,  top_cap_g,  top_cap_b  : std_logic_vector(3 downto 0);
    signal top_body_r, top_body_g, top_body_b : std_logic_vector(3 downto 0);
    signal bottom_cap_r,  bottom_cap_g,  bottom_cap_b  : std_logic_vector(3 downto 0);
    signal bottom_body_r, bottom_body_g, bottom_body_b : std_logic_vector(3 downto 0);

    signal top_cap_transp  : std_logic;
    signal top_body_transp : std_logic;
    signal bottom_cap_transp  : std_logic;
    signal bottom_body_transp : std_logic;

    signal is_visible : std_logic := '1';

    component SpriteRenderer is
        port (
            clk          : in  std_logic;
            pixel_row    : in  std_logic_vector(9 downto 0);
            pixel_column : in  std_logic_vector(9 downto 0);
            start_x      : in  std_logic_vector(10 downto 0);
            start_y      : in  std_logic_vector(10 downto 0);
            sprite_id    : in  integer range 0 to 64;
            flip_y       : in  std_logic := '0';
            red          : out std_logic_vector(3 downto 0);
            green        : out std_logic_vector(3 downto 0);
            blue         : out std_logic_vector(3 downto 0);
            transparent  : out std_logic
        );
    end component;

begin

    pipe_top_y_pos    <= to_unsigned(height, 10) - to_unsigned(gap/2, 10);
    pipe_bottom_y_pos <= to_unsigned(height, 10) + to_unsigned(gap/2, 10);

    pipe_x_pos_effective <= follow_x_pos + to_unsigned(START_OFFSET, 11) when follow_enable = '1'
                            else pipe_x_pos;

    -- Top cap sits just above pipe_top_y_pos
    top_cap_start_y <= ('0' & pipe_top_y_pos) - to_unsigned(BONE_CAP_HEIGHT, 11);
    -- Bottom cap sits just below pipe_bottom_y_pos
    bottom_cap_start_y <= '0' & pipe_bottom_y_pos;

    render_top_cap <= '1' when (
        is_visible = '1'
        and unsigned(pixel_column) >= pipe_x_pos_effective - cap_x_offset
        and unsigned(pixel_column) <  pipe_x_pos_effective - cap_x_offset + BONE_CAP_WIDTH
        and unsigned(pixel_row)    >= top_cap_start_y(9 downto 0)
        and unsigned(pixel_row)    <  pipe_top_y_pos
        and top_cap_transp = '0'
    ) else '0';

    render_top_body <= '1' when (
        is_visible = '1'
        and unsigned(pixel_column) >= pipe_x_pos_effective
        and unsigned(pixel_column) <  pipe_x_pos_effective + BONE_BODY_WIDTH
        and unsigned(pixel_row)    <  top_cap_start_y(9 downto 0)  -- above the cap
        and top_body_transp = '0'
    ) else '0';

    render_bottom_cap <= '1' when (
        is_visible = '1'
        and unsigned(pixel_column) >= pipe_x_pos_effective - cap_x_offset
        and unsigned(pixel_column) <  pipe_x_pos_effective - cap_x_offset + BONE_CAP_WIDTH
        and unsigned(pixel_row)    >= pipe_bottom_y_pos
        and unsigned(pixel_row)    <  bottom_cap_start_y(9 downto 0) + BONE_CAP_HEIGHT
        and bottom_cap_transp = '0'
    ) else '0';

    render_bottom_body <= '1' when (
        is_visible = '1'
        and unsigned(pixel_column) >= pipe_x_pos_effective
        and unsigned(pixel_column) <  pipe_x_pos_effective + BONE_BODY_WIDTH
        and unsigned(pixel_row)    >= bottom_cap_start_y(9 downto 0) + BONE_CAP_HEIGHT  -- below the cap
        and bottom_body_transp = '0'
    ) else '0';

    TOP_CAP : SpriteRenderer port map (
        clk          => clk,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        start_x      => std_logic_vector(pipe_x_pos_effective - cap_x_offset),
        start_y      => std_logic_vector(top_cap_start_y),
        sprite_id    => BONE_CAP_SPRITE_ID,
        flip_y       => '1',
        red          => top_cap_r,
        green        => top_cap_g,
        blue         => top_cap_b,
        transparent  => top_cap_transp
    );

    TOP_BODY : SpriteRenderer port map (
        clk          => clk,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        start_x      => std_logic_vector(pipe_x_pos_effective),
        start_y      => (others => '0'),   -- tiling from top of screen
        sprite_id    => BONE_BODY_SPRITE_ID,
        flip_y       => '0',
        red          => top_body_r,
        green        => top_body_g,
        blue         => top_body_b,
        transparent  => top_body_transp
    );

    BOTTOM_CAP : SpriteRenderer port map (
        clk          => clk,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        start_x      => std_logic_vector(pipe_x_pos_effective - cap_x_offset),
        start_y      => std_logic_vector(bottom_cap_start_y),
        sprite_id    => BONE_CAP_SPRITE_ID,
        flip_y       => '0',
        red          => bottom_cap_r,
        green        => bottom_cap_g,
        blue         => bottom_cap_b,
        transparent  => bottom_cap_transp
    );

    BOTTOM_BODY : SpriteRenderer port map (
        clk          => clk,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        start_x      => std_logic_vector(pipe_x_pos_effective),
        start_y      => (others => '0'),
        sprite_id    => BONE_BODY_SPRITE_ID,
        flip_y       => '0',
        red          => bottom_body_r,
        green        => bottom_body_g,
        blue         => bottom_body_b,
        transparent  => bottom_body_transp
    );

    render <= render_top_cap or render_top_body or render_bottom_cap or render_bottom_body;

    red   <= top_cap_r  when render_top_cap  = '1' else
             bottom_cap_r  when render_bottom_cap  = '1' else
             top_body_r when render_top_body = '1' else
             bottom_body_r;

    green <= top_cap_g  when render_top_cap  = '1' else
             bottom_cap_g  when render_bottom_cap  = '1' else
             top_body_g when render_top_body = '1' else
             bottom_body_g;

    blue  <= top_cap_b  when render_top_cap  = '1' else
             bottom_cap_b  when render_bottom_cap  = '1' else
             top_body_b when render_top_body = '1' else
             bottom_body_b;

    x_pos <= pipe_x_pos_effective;

    PIPE_CONTROLLER : process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if reset = '1' or enabled = '0' then
                if follow_enable = '0' then
                    pipe_x_pos <= to_unsigned(640 + START_OFFSET, 11);
                end if;
                end_reached <= '0';
                is_visible  <= '1';

            elsif enabled = '1' then
                if follow_enable = '0' then
                    if (pipe_x_pos_effective + BONE_CAP_WIDTH) <= to_unsigned(SPEED, 11) then
                        end_reached <= '1';
                        is_visible  <= '0';
                    else
                        pipe_x_pos <= pipe_x_pos - to_unsigned(SPEED, 11);
                        end_reached <= '0';
                    end if;
                else
                    end_reached <= '0';
                end if;
            end if;
        end if;
    end process PIPE_CONTROLLER;

end architecture behaviour;