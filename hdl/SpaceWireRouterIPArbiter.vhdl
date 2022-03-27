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

------- switch --------
--
--      0 1 2 3 4 5 6
--    0 x - - - - - -
--    1 - x - - - - -
--    2 - - x - - - -
--    3 o - - x - - -
--    4 - - - - x - -
--    5 - - - - - x -
--    6 - - - - - - x
--  o : rx0=>tx3
--  x :loopback

entity SpaceWireRouterIPArbiter is
  port (
      clock              : in  std_logic;
      reset              : in  std_logic;
      destinationOfPort  : in  bit8XPortArray;
      requestOfPort      : in  std_logic_vector (cNumberOfInternalPort - 1 downto 0);
      grantedToPort      : out std_logic_vector (cNumberOfInternalPort - 1 downto 0);
      routingSwitch      : out std_logic_vector ((cNumberOfInternalPort**2)-1 downto 0)
      );
end SpaceWireRouterIPArbiter;

architecture behavioral of SpaceWireRouterIPArbiter is

    signal iRoutingSwitch   : std_logic_vector ((cNumberOfInternalPort**2)-1 downto 0);
    signal iOccupiedPort    : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
--
    signal iRequesterToPort : portXPortArray;
--
    signal iGrantedToPort   : std_logic_vector (cNumberOfInternalPort - 1 downto 0);

    signal iGrantedTemp     : portXPortArray;

    component SpaceWireRouterIPRoundArbiter is
        port (
            clock    : in  std_logic;
            reset    : in  std_logic;
            occupied : in  std_logic;
            request  : in  std_logic_vector (cNumberOfInternalPort - 1 downto 0);
            granted  : out std_logic_vector (cNumberOfInternalPort - 1 downto 0)
            );
    end component;

begin

----------------------------------------------------------------------
-- ECSS-E-ST-50-12C 10.2.5 Arbitration
-- Two or more input ports can all be waiting to send data out of the same
-- output port: SpaceWire routing switches shall provide a means of
-- arbitrating between input ports requesting the same output port.
-- Packet based (EOP,EEP and TIMEOUT) arbitration schemes is implemented.
----------------------------------------------------------------------

    grantedToPort <= iGrantedToPort;

----------------------------------------------------------------------
-- Route occupation signal, the source Port number, Destination Port.
----------------------------------------------------------------------

    occupied_gen : for i in 0 to cNumberOfInternalPort - 1 generate
        iOccupiedPort(i) <= or iRoutingSwitch(((i+1)*cNumberOfInternalPort) - 1 downto i*cNumberOfInternalPort);
    end generate;

----------------------------------------------------------------------
-- Source port number which request port as the destination port.
----------------------------------------------------------------------

    request_gen : for i in 0 to cNumberOfInternalPort - 1 generate
        request_gen2 : for j in 0 to cNumberOfInternalPort - 1 generate
            iRequesterToPort(j)(i) <= '1' when requestOfPort(i) = '1' and destinationOfPort(i) = std_logic_vector(to_unsigned(j, 8)) else '0';
        end generate;
    end generate;

    arbiter_gen : for i in 0 to cNumberOfInternalPort - 1 generate
        arbiter : SpaceWireRouterIPRoundArbiter port map (
            clock    => clock,
            reset    => reset,
            occupied => iOccupiedPort (i),
            request  => iRequesterToPort (i),
            granted  => iRoutingSwitch (((i+1)*cNumberOfInternalPort) - 1 downto i*cNumberOfInternalPort)
        );
    end generate;

----------------------------------------------------------------------
-- Connection enable signal, the source Port,  Destination Port number0 to 6.
----------------------------------------------------------------------

    granted_gen : for i in 0 to cNumberOfInternalPort - 1 generate
        granted_gen2 : for j in 0 to cNumberOfInternalPort - 1 generate
            iGrantedTemp(i)(j) <= iRoutingSwitch(i+(j*cNumberOfInternalPort));
        end generate;
        iGrantedToPort(i) <= or iGrantedTemp(i);
    end generate;

    routingSwitch <= iRoutingSwitch;

end behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library work;
use work.SpaceWireRouterIPPackage.all;

entity SpaceWireRouterIPRoundArbiter is
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        occupied : in  std_logic;
        request  : in  std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        granted  : out std_logic_vector (cNumberOfInternalPort - 1 downto 0)
        );
end SpaceWireRouterIPRoundArbiter;

architecture behavioral of SpaceWireRouterIPRoundArbiter is
    signal iGranted     : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal iLastGranted : std_logic_vector (4 downto 0) := "00000";
    signal iRequest     : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal ioccupied    : std_logic;
begin

    granted <= iGranted;
    iRequest  <= request;
    ioccupied <= occupied;

    process (clock, reset)
    begin
        if (reset = '1') then
            iGranted     <= (others => '0');
            iLastGranted <= (others => '0');

        elsif (clock'event and clock = '1') then
            if ioccupied = '0' then
                for i in 0 to cNumberOfInternalPort - 1 loop
                    if (iLastGranted = std_logic_vector(to_unsigned(i, 5))) then
                        for j in 0 to cNumberOfInternalPort - 1 loop
                            if iRequest((j + i + 1) mod cNumberOfInternalPort) = '1' then
                                iGranted     <= (others => '0');
                                iGranted((j + i + 1) mod cNumberOfInternalPort)  <= '1';
                                iLastGranted <= std_logic_vector(to_unsigned((j + i + 1) mod cNumberOfInternalPort, 5));
                            end if;
                        end loop;
                    end if;
                end loop;
            end if;

            for i in 0 to cNumberOfInternalPort - 1 loop
                if (irequest(i) = '0' and iGranted (i) = '1') then iGranted (i) <= '0'; end if;
            end loop;
        end if;

    end process;

end behavioral;
