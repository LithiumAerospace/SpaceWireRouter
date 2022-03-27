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

entity SpaceWireRouterIPTimeCodeControl is
    port (
        clock                 : in  std_logic;
        reset                 : in  std_logic;
        -- switch info.
        linkUp                : in  std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        receiveTimeCode       : out std_logic_vector (7 downto 0);
        -- spacewire timecode.
        portTimeCodeEnable    : in  std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        portTickIn            : out std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        portTimeCodeIn        : out bit8XPortArray;
        portTickOut           : in  std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        portTimeCodeOut       : in  bit8XPortArray;
--
        autoTimeCodeValue     : out std_logic_vector(7 downto 0);
        autoTimeCodeCycleTime : in  std_logic_vector(31 downto 0)
        );
end SpaceWireRouterIPTimeCodeControl;


architecture behavioral of SpaceWireRouterIPTimeCodeControl is

    constant cInitializeTimeCode     : std_logic_vector (5 downto 0) := (others => '0');
    constant cInitializeControlFlags : std_logic_vector (1 downto 0) := "00";
--
    signal   iTimeCodeOut            : std_logic_vector (5 downto 0);
    signal   iTimeCodeOutPlus1       : std_logic_vector (5 downto 0);
    signal   iReceiveControlFlags    : std_logic_vector (1 downto 0);
    signal   iTickOut                : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
--
    signal   iReceiveTimeCode        : std_logic_vector (7 downto 0);
--
    signal   iPortTickIn             : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal   iPortTimeCodeIn         : bit8XPortArray;
    signal   iCycleCounter           : std_logic_vector (31 downto 0);
    signal   iAutoTickIn             : std_logic;
    signal   iAutoTimeCodeIn         : std_logic_vector (5 downto 0);

begin

    receiveTimeCode <= iReceiveTimeCode;

    portTickIn <= iPortTickIn;

    portTimeCodeIn <= iPortTimeCodeIn;

    tickin : for i in 1 to cNumberOfInternalPort - 1 generate
        iPortTickIn (i)     <= iTickOut (i)                        when (portTimeCodeEnable (i) = '1' and linkUp (i) = '1') else '0';
        iPortTimeCodeIn (i) <= iReceiveControlFlags & iTimeCodeOut when (autoTimeCodeCycleTime = x"00000000")            else "00" & iAutoTimeCodeIn;
    end generate;

    iReceiveTimeCode <= iReceiveControlFlags & iTimeCodeOut;

----------------------------------------------------------------------
-- ECSS-E-ST-50-12C 8.12 System time distribution (normative)
-- ECSS-E-ST-50-12C 7.3 Control characters and control codes
-- TimeCode Host
-- Occur TimeCode and tick signal which is asserted periodically set value
-- in AutoTimeCodeValueRegister.
-- This TimeCode,tick signal is sending to all output ports of the router.
-- TimeCode Target
-- Check The new time is one more than the time-counter's previous time-value.
-- If the Time-Code is valid, send Tick signal.
-- The TimeCode send out from all port.
----------------------------------------------------------------------
    process (clock, reset)
    begin
        if (reset = '1') then
            iTimeCodeOut         <= cInitializeTimeCode;
            iTimeCodeOutPlus1    <= std_logic_vector(unsigned(cInitializeTimeCode) + 1);
            iReceiveControlFlags <= "00";
            iTickOut             <= (others => '0');

        elsif (clock'event and clock = '1') then
            ----------------------------------------------------------------------
            -- TimeCode Host.
            ----------------------------------------------------------------------
            if (autoTimeCodeCycleTime /= x"00000000") then
                if (iAutoTickIn = '1') then
                    iTickOut <= (others => '1');
                else
                    iTickOut <= (others => '0');
                end if;
            else
                ----------------------------------------------------------------------
                -- TimeCode Target
                -- Port1 TimeCode Receive.
                ----------------------------------------------------------------------
                if or portTickOut then
                    for i in 1 to cNumberOfInternalPort - 1 loop
                        if (portTickOut (i) = '1') then
                            if (portTimeCodeOut (i)(5 downto 0) = iTimeCodeOutPlus1) then
                                iTickOut    <= (others => '1');
                                iTickOut(i) <= '0';
                            end if;
                            iTimeCodeOut         <= portTimeCodeOut (i)(5 downto 0);
                            iTimeCodeOutPlus1    <= std_logic_vector(unsigned(portTimeCodeOut (i)(5 downto 0)) + 1);
                            iReceiveControlFlags <= portTimeCodeOut (i)(7 downto 6);
                        end if;
                    end loop;

                else
                    iTickOut <= (others => '0');

                end if;
            end if;
        end if;
    end process;

    autoTimeCodeValue <= "00" & iAutoTimeCodeIn;

----------------------------------------------------------------------
-- TimeCode Host.
-- Send TimeCode periodically in set value.
----------------------------------------------------------------------
    process (clock, reset)
    begin
        if (reset = '1') then
            iAutoTimeCodeIn <= (others => '0');
            iCycleCounter   <= (others => '0');
            iAutoTickIn     <= '0';

        elsif (clock'event and clock = '1') then
            if (autoTimeCodeCycleTime /= x"00000000") then

                if (iCycleCounter > autoTimeCodeCycleTime) then
                    iCycleCounter   <= (others => '0');
                    iAutoTickIn     <= '1';
                    iAutoTimeCodeIn <= std_logic_vector(unsigned(iAutoTimeCodeIn) + 1);
                else
                    iCycleCounter <= std_logic_vector(unsigned(iCycleCounter) + 1);
                    iAutoTickIn   <= '0';
                end if;
            else
                iAutoTickIn   <= '0';
                iCycleCounter <= (others => '0');
            end if;
        end if;
    end process;
-------------------------------------------------------------

end behavioral;
