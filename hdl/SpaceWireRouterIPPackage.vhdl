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
use IEEE.numeric_std.all;

library work;
use work.SpaceWireCODECIPPackage.all;

package SpaceWireRouterIPPackage is

    constant cNumberOfInternalPort             : integer range 0 to 32          := 32;
    constant cNumberOfExternalPort             : std_logic_vector (4 downto 0)  := std_logic_vector(to_unsigned(cNumberOfInternalPort - 1, 5));
    constant cRunStateTransmitClockDivideValue : std_logic_vector (5 downto 0)  := "001001";  -- transmitClock frequency / (cRunStateTransmitClockDivideValue + 1) = TransmitRate.
    constant cTransmitTimeCodeEnable           : std_logic_vector (cNumberOfInternalPort - 1 downto 0) := (0 => '0', others => '1');  -- enable time-code forwarding.
    constant cRMAPCRCRevision                  : std_logic                      := '1';        -- (0:Rev.e, 1:Rev.f).
    constant cWatchdogTimerEnable              : std_logic                      := '0';        -- enable port occupetion timeout.
    constant cUseDevice                        : integer range 0 to 2           := 2;          -- 1 = Xilinx, 0 = Altera, 2 = Mock
    constant cPortBit                          : std_logic_vector (31 downto 0) := x"0000007F";
--
    type statisticalInformationArray is array (cNumberOfInternalPort - 1 downto 0) of bit32X8Array;
    type bit32X9Array                is array (cNumberOfInternalPort + 1 downto 0) of std_logic_vector (31 downto 0); -- ports + user + control register
    type bit8X9Array                 is array (cNumberOfInternalPort + 1 downto 0) of std_logic_vector (7 downto 0);
    type bit4X9Array                 is array (cNumberOfInternalPort + 1 downto 0) of std_logic_vector (3 downto 0);
    type bit8XPortArray              is array (cNumberOfInternalPort - 1 downto 0) of std_logic_vector(7 downto 0);
    type unsigned16xPort             is array (cNumberOfInternalPort - 1 downto 0) of unsigned(15 downto 0);
    type bit16xPortArray             is array (cNumberOfInternalPort - 1 downto 0) of std_logic_vector(15 downto 0);
    type unsigned6xPortArray         is array (cNumberOfInternalPort - 1 downto 0) of unsigned(5 downto 0);
    type portXPortArray              is array (cNumberOfInternalPort - 1 downto 0) of std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    type bit9XPortArray              is array (cNumberOfInternalPort - 1 downto 0) of std_logic_vector (8 downto 0);

    function select7x1 (
        selectBit   : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        selectArray : std_logic_vector (cNumberOfInternalPort - 1 downto 0)
        ) return std_logic;

--
    function select7x1xVector8 (
        selectVector : in std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        selectArray  : in bit8XPortArray
        ) return std_logic_vector;

--
    function select7x1xVector9 (
        selectVector : in std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        selectArray  : in bit9XPortArray
        ) return std_logic_vector;


end SpaceWireRouterIPPackage;

package body SpaceWireRouterIPPackage is

    function select7x1 (
        selectBit   : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        selectArray : std_logic_vector (cNumberOfInternalPort - 1 downto 0)) return std_logic is
    begin
        for i in 0 to cNumberOfInternalPort - 1 loop
            if selectBit (i) = '1' then
                return selectArray (i);
            end if;
        end loop;

        return '0';
    end select7x1;


    function select7x1xVector8 (
        selectVector : in std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        selectArray  : in bit8XPortArray) return std_logic_vector is
    begin
        for i in 0 to cNumberOfInternalPort - 1 loop
            if selectVector (i) = '1' then
                return selectArray (i);
            end if;
        end loop;

        return "00000000";
    end select7x1xVector8;


    function select7x1xVector9 (
        selectVector : in std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        selectArray  : in bit9XPortArray) return std_logic_vector is
    begin
        for i in 0 to cNumberOfInternalPort - 1 loop
            if selectVector (i) = '1' then
                return selectArray (i);
            end if;
        end loop;

        return "000000000";
    end select7x1xVector9;

end SpaceWireRouterIPPackage;
