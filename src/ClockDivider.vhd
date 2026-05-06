library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Turn 50Mhz to 25Mhz for the VGA Sync
entity ClockDivider is
    port (
        Clk_in : in std_logic;
        Clk_out : out std_logic
    );
end ClockDivider;

architecture behavior of ClockDivider is
    signal clk_reg : std_logic := '0';
begin
    process(Clk_in)
    begin
        if rising_edge(Clk_in) then
            clk_reg <= not clk_reg;
        end if;
    end process;

    Clk_out <= clk_reg;
end architecture behavior;