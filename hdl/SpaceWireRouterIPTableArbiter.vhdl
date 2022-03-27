------------------------------------------------------------------------------
-- The MIT License (MIT)
--
-- Copyright (c) <2013> <Shimafuji Electric Inc., Osaka University, JAXA>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library work;
use work.SpaceWireRouterIPPackage.all;

entity SpaceWireRouterIPTableArbiter is
    port (
        clock   : in  std_logic;
        reset   : in  std_logic;
        request : in  std_logic_vector (cNumberOfInternalPort downto 0);
        granted : out std_logic_vector (cNumberOfInternalPort downto 0)
        );
end SpaceWireRouterIPTableArbiter;

architecture behavioral of SpaceWireRouterIPTableArbiter is

    signal iGranted : std_logic_vector (cNumberOfInternalPort downto 0);

----------------------------------------------------------------------
-- ECSS-E-ST-50-12C 10.2.5 Arbitration
-- Two or more input ports can all be waiting to send data out of the same
-- output port: SpaceWire routing switches shall provide a means of
-- arbitrating between input ports requesting the same a routing table or
-- a register.
-- Packet based (EOP,EEP and TIMEOUT) arbitration schemes is implemented.
----------------------------------------------------------------------
begin
    process (clock, reset)
    begin
        if (reset = '1') then
            iGranted <= (0 => '1', others => '0');
        elsif (clock'event and clock = '1') then

            for i in 0 to cNumberOfInternalPort loop
                if iGranted (i) = '1' and request (i) = '0' then
                    for j in i to cNumberOfInternalPort loop
                        if (request (j) = '1') then
                            iGranted <= (others => '0');
                            iGranted(j) <= '1';
                            exit;
                        end if;
                    end loop;
                    for j in 0 to (i - 1) loop
                        if (request (j) = '1') then
                            iGranted <= (others => '0');
                            iGranted(j) <= '1';
                            exit;
                        end if;
                    end loop;
                end if;
            end loop;
        end if;
    end process;

    granted <= iGranted;

end behavioral;
