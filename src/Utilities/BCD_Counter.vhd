library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BCD_Counter is
    port (Clk, Reset, Enable, Direction : in std_logic;
        Q_Out : out std_logic_vector(3 downto 0));
end entity BCD_Counter;

architecture behavior of BCD_Counter is

begin
    process (Clk) is
        variable count : integer range 0 to 9 := 0;
    begin
        if (Clk'event and Clk = '1') then
            if (Reset = '1') then
                case (Direction) is
                    when '0' =>
                        count := 0;
                    when others =>
                        count := 9;
                end case;
            elsif (Enable = '1') then
                case (Direction) is
                    when '0' =>
                        if (count = 9) then
                            count := 0;
                        else
                            count := count + 1;
                        end if;
                    when others =>
                        if (count = 0) then
                            count := 9;
                        else
                            count := count - 1;
                        end if;
                end case;
            end if;
        end if;

        Q_Out <= std_logic_vector(to_unsigned(count, 4));
    end process;
end architecture behavior;