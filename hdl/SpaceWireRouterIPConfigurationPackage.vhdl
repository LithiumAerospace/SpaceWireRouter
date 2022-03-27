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

library work;
use work.SpaceWireRouterIPPackage.all;

package SpaceWireRouterIPConfigurationPackage is
--------------------------------------------------------------------------------
-- Port-0 RMAP Logical Address & Key.
--------------------------------------------------------------------------------
    constant cDefaultRMAPKey            : std_logic_vector (7 downto 0) := x"02";
    constant cDefaultRMAPLogicalAddress : std_logic_vector (7 downto 0) := x"FE";
--------------------------------------------------------------------------------

    constant cDeviceIDRevision    : std_logic_vector (31 downto 0) := x"40224950";
    constant cRouterIPRevision    : std_logic_vector (31 downto 0) := x"40220120";
    constant cSpaceWireIPRevision : std_logic_vector (31 downto 0) := x"40220120";
    constant cRMAPIPRevision      : std_logic_vector (31 downto 0) := x"40220120";

    constant cReserve00    : std_logic_vector(1 downto 0) := "00";
    constant cLowAddress00 : std_logic_vector(3 downto 0) := "0000";
    constant cLowAddress04 : std_logic_vector(3 downto 0) := "0001";
    constant cLowAddress08 : std_logic_vector(3 downto 0) := "0010";
    constant cLowAddress0C : std_logic_vector(3 downto 0) := "0011";
    constant cLowAddress10 : std_logic_vector(3 downto 0) := "0100";
    constant cLowAddress14 : std_logic_vector(3 downto 0) := "0101";
    constant cLowAddress18 : std_logic_vector(3 downto 0) := "0110";
    constant cLowAddress1C : std_logic_vector(3 downto 0) := "0111";
    constant cLowAddress20 : std_logic_vector(3 downto 0) := "1000";
    constant cLowAddress24 : std_logic_vector(3 downto 0) := "1001";
    constant cLowAddress28 : std_logic_vector(3 downto 0) := "1010";
    constant cLowAddress2C : std_logic_vector(3 downto 0) := "1011";
    constant cLowAddress30 : std_logic_vector(3 downto 0) := "1100";
    constant cLowAddress34 : std_logic_vector(3 downto 0) := "1101";
    constant cLowAddress38 : std_logic_vector(3 downto 0) := "1110";
    constant cLowAddress3C : std_logic_vector(3 downto 0) := "1111";

    type cPortArray is array (0 to 31) of std_logic_vector(4 downto 0);

    constant cPort : cPortArray := (
            "00000", "00001", "00010", "00011", "00100", "00101", "00110", "00111",
            "01000", "01001", "01010", "01011", "01100", "01101", "01110", "01111",
            "10000", "10001", "10010", "10011", "10100", "10101", "10110", "10111",
            "11000", "11001", "11010", "11011", "11100", "11101", "11110", "11111"
            );

end SpaceWireRouterIPConfigurationPackage;

package body SpaceWireRouterIPConfigurationPackage is


end SpaceWireRouterIPConfigurationPackage;
