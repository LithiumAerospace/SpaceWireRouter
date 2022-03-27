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

library work;
use work.SpaceWireRouterIPConfigurationPackage.all;
use work.SpaceWireRouterIPPackage.all;
use work.SpaceWireCODECIPPackage.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity SpaceWireRouterIPRouterControlRegister is
    port (
        -- Clock & Reset
        clock                       : in  std_logic;
        reset                       : in  std_logic;
        transmitClock               : in  std_logic;
        receiveClock                : in  std_logic;
        -- Bus i/f
        writeData                   : in  std_logic_vector (31 downto 0);
        readData                    : out std_logic_vector (31 downto 0);
        acknowledge                 : out std_logic;
        address                     : in  std_logic_vector (31 downto 0);
        strobe                      : in  std_logic;
        cycle                       : in  std_logic;
        writeEnable                 : in  std_logic;
        dataByteEnable              : in  std_logic_vector (3 downto 0);
        requestPort                 : in  std_logic_vector (7 downto 0);
        -- switch info
        linkUp                      : in  std_logic_vector (cNumberOfInternalPort - 1 downto 0);
        -- Link Status/Control
        linkControl                 : out bit16xPortArray;
        linkStatus                  : in  bit8XPortArray;
        errorStatus                 : in  bit8XPortArray;
        linkReset                   : out std_logic_vector (cNumberOfInternalPort - 1 downto 0);
--
        creditCount                 : in  unsigned6xPortArray;
        outstandingCount            : in  unsigned6xPortArray;
        timeOutCount                : in  unsigned16xPort;
--
        dropCount                   : in  unsigned16xPort;
        dropCouterClear             : out std_logic;
--
        timeOutEnable               : out std_logic;
        timeOutCountValue           : out std_logic_vector (19 downto 0);
--
        receiveTimeCode             : in  std_logic_vector (7 downto 0);
        transmitTimeCodeEnable      : out std_logic_vector (cNumberOfInternalPort - 1 downto 0);
--
        port0TargetLogicalAddress   : out std_logic_vector (7 downto 0);
        port0RMAPKey                : out std_logic_vector (7 downto 0);
        port0CRCRevision            : out std_logic;
--
        autoTimeCodeValue           : in  std_logic_vector(7 downto 0);
        autoTimeCodeCycleTime       : out std_logic_vector(31 downto 0);
--
        statisticalInformation      : in  statisticalInformationArray;
        statisticalInformationClear : out std_logic
        );
end SpaceWireRouterIPRouterControlRegister;


architecture behavioral of SpaceWireRouterIPRouterControlRegister is

    type BusStateMachine is (
        busStateIdle,
        busStateRead0,
        busStateRead1,
        busStateWrite0,
        busStateWrite1,
        busStateWait0,
        busStateWait1
        );


    signal iBusState                                   : BusStateMachine;
--
    signal iDataInBuffer                               : std_logic_vector (31 downto 0);
    signal iDataOutBuffer                              : std_logic_vector (31 downto 0);
    signal iAcknowledgeOut                             : std_logic;
--
    --Select Signal.
    signal iLowAddress00                               : std_logic;
    signal iLowAddress04                               : std_logic;
    signal iLowAddress08                               : std_logic;
    signal iLowAddress0C                               : std_logic;
    signal iLowAddress10                               : std_logic;
    signal iLowAddress14                               : std_logic;
    signal iLowAddress18                               : std_logic;
    signal iLowAddress1C                               : std_logic;
    signal iLowAddress20                               : std_logic;
    signal iLowAddress24                               : std_logic;
    signal iLowAddress28                               : std_logic;
    signal iLowAddress2C                               : std_logic;
    signal iLowAddress30                               : std_logic;
    signal iLowAddress34                               : std_logic;
    signal iLowAddress38                               : std_logic;
    signal iLowAddress3C                               : std_logic;
--
    signal iSelectStatisticalInformation               : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
--
    signal iSelectIDRegister                           : std_logic;
    signal iSelectRouterRegister                       : std_logic;
--
    --Register.
    signal iLinkControlRegister                        : bit16xPortArray;
    signal iSoftWareLinkReset                          : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
--
    signal errorStatusRegister                         : bit8XPortArray;
--
    signal iErrorStatusClear                           : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal iRouterIDRegister                           : std_logic_vector (31 downto 0) := (others => '0');
    signal iTimeCodeEnableRegister                     : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal iTimeOutEnableRegister                      : std_logic;
    signal iTimeOutCountValueRegister                  : std_logic_vector (19 downto 0);
--
    signal iPort0RMAPKeyRegister                       : std_logic_vector (7 downto 0);
    signal iPort0TargetLogicalAddressRegister          : std_logic_vector (7 downto 0);
    signal iPort0CRCRevisionRegister                   : std_logic;  -- 0:Rev.E, 1:Rev.F
--
    signal iAutoTimeCodeCycleTimeRegister              : std_logic_vector (31 downto 0);
    signal iStatisticalInformationReceiveClearRegister : std_logic;

    component SpaceWireRouterIPLatchedPulse8 is
        port (
            clock          : in  std_logic;
            transmitClock  : in  std_logic;
            receiveClock   : in  std_logic;
            reset          : in  std_logic;
            asynchronousIn : in  std_logic_vector (7 downto 0);
            latchedOut     : out std_logic_vector (7 downto 0);
            latchClear     : in  std_logic
            );
    end component;

    component SpaceWireRouterIPLongPulse is
        port (
            clock        : in  std_logic;
            reset        : in  std_logic;
            pulseIn      : in  std_logic;
            longPulseOut : out std_logic
            );
    end component;


    component SpaceWireRouterIPRouterRoutingTable32x256 is
        port (
            clock          : in  std_logic;
            reset          : in  std_logic;
            strobe         : in  std_logic;
            writeEnable    : in  std_logic;
            dataByteEnable : in  std_logic_vector (3 downto 0);
            address        : in  std_logic_vector (7 downto 0);
            writeData      : in  std_logic_vector (31 downto 0);
            readData       : out std_logic_vector (31 downto 0);
            acknowledge    : out std_logic
            );
    end component;

    signal iSelectRoutingTable     : std_logic;
    signal iRoutingTableStrobe     : std_logic;
    signal routingTableReadData    : std_logic_vector (31 downto 0);
    signal routingTableAcknowledge : std_logic;
--
    signal iAcknowledge            : std_logic;
    signal iReadData               : std_logic_vector (31 downto 0);
    signal iDropCouterClear        : std_logic;
    signal iStatisticalBuffer1     : std_logic_vector (31 downto 0);
    signal iStatisticalBuffer2     : std_logic_vector (31 downto 0);
    signal iSelectOldIDRegister    : std_logic;


begin

    acknowledge                 <= iAcknowledge;
    readData                    <= iReadData;
    dropCouterClear             <= iDropCouterClear;
    autoTimeCodeCycleTime       <= iAutoTimeCodeCycleTimeRegister;
    statisticalInformationClear <= iStatisticalInformationReceiveClearRegister;


----------------------------------------------------------------------
-- Decoding address and output the select signal of the applicable register.
----------------------------------------------------------------------
    -- Higher 8bit.
    iSelectRoutingTable <= '1' when (address (13 downto 2) > "000000011111" and address (13 downto 2) < "000100000000") else '0';

    iSelectIDRegister              <= '1' when address (13 downto 8) = "00" & x"8"               else '0';
    iSelectOldIDRegister           <= '1' when address (13 downto 8) = "00" & x"4"               else '0';
    iSelectRouterRegister          <= '1' when address (13 downto 8) = "00" & x"9"               else '0';
--
    select_gen : for i in 1 to (cNumberOfInternalPort - 1) generate
      iSelectStatisticalInformation (i) <= '1' when address (13 downto 8) = "1" & cPort(i) else '0';
    end generate;

------------------------------------------------------------------------------------------------------------
    -- Lower 8bit.
    iLowAddress00                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress00 else '0';
    iLowAddress04                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress04 else '0';
    iLowAddress08                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress08 else '0';
    iLowAddress0C                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress0C else '0';
    iLowAddress10                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress10 else '0';
    iLowAddress14                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress14 else '0';
    iLowAddress18                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress18 else '0';
    iLowAddress1C                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress1C else '0';
    iLowAddress20                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress20 else '0';
    iLowAddress24                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress24 else '0';
    iLowAddress28                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress28 else '0';
    iLowAddress2C                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress2C else '0';
    iLowAddress30                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress30 else '0';
    iLowAddress34                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress34 else '0';
    iLowAddress38                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress38 else '0';
    iLowAddress3C                  <= '1' when address (7 downto 2) = cReserve00 & cLowAddress3C else '0';


    timeOutEnable     <= iTimeOutEnableRegister;
    timeOutCountValue <= iTimeOutCountValueRegister;

    errorStatus_gen : for i in 1 to (cNumberOfInternalPort - 1) generate
        errorStatus_item : SpaceWireRouterIPLatchedPulse8 port map (
            clock          => clock,
            transmitClock  => transmitClock,
            receiveClock   => receiveClock,
            reset          => reset,
            asynchronousIn => errorStatus(i),
            latchedOut     => errorStatusRegister(i),
            latchClear     => iErrorStatusClear(i)
            );
    end generate;

    transmitTimeCodeEnable <= iTimeCodeEnableRegister;

----------------------------------------------------------------------
-- The state machine which access(Read,Write) to the register.
----------------------------------------------------------------------
    process (clock, reset)
    begin
        if (reset = '1') then
            iBusState                                   <= busStateIdle;
            iAcknowledgeOut                             <= '0';
            iDataOutBuffer                              <= (others => '0');
            iDataInBuffer                               <= (others => '0');
            iStatisticalBuffer1                         <= (others => '0');
            iStatisticalBuffer2                         <= (others => '0');

            reset_gen : for i in 1 to cNumberOfInternalPort - 1 loop
              iLinkControlRegister(i)                       <= "00" & cRunStateTransmitClockDivideValue & x"05";
            end loop;

            iSoftWareLinkReset                          <= (others => '0');
            iErrorStatusClear                           <= (others => '0');
            iTimeOutCountValueRegister                  <= (others => '0');
            iTimeOutEnableRegister                      <= cWatchdogTimerEnable;
            iTimeCodeEnableRegister                     <= cTransmitTimeCodeEnable;
            iPort0RMAPKeyRegister                       <= cDefaultRMAPKey;
            iPort0TargetLogicalAddressRegister          <= cDefaultRMAPLogicalAddress;
            iPort0CRCRevisionRegister                   <= cRMAPCRCRevision;
            iDropCouterClear                            <= '0';
            iAutoTimeCodeCycleTimeRegister              <= x"00000000";
            iStatisticalInformationReceiveClearRegister <= '0';

        elsif (clock'event and clock = '1') then
            case iBusState is

                when busStateIdle =>
                    if (iSelectRoutingTable = '0' and cycle = '1' and strobe = '1') then
                        if (writeEnable = '1') then
                            iDataInBuffer <= writeData;
                            iBusState     <= busStateWrite0;
                        else
                            iBusState <= busStateRead0;
                        end if;
                    end if;

                    ----------------------------------------------------------------------
                    --Read Register Select.
                    ----------------------------------------------------------------------
                when busStateRead0 =>

                    for i in 1 to cNumberOfInternalPort - 1 loop
                        if (iSelectStatisticalInformation(i) = '1' and iLowAddress00 = '1') then
                            -- Port-1 Link Control/Status Register.
                            iStatisticalBuffer1 <= iLinkControlRegister(i) & errorStatusRegister(i) & linkStatus(i);
                            iErrorStatusClear(i)  <= '1';

                        elsif (iSelectStatisticalInformation(i) = '1' and iLowAddress04 = '1') then
                            -- Port-1 Link Status Register2.
                            iStatisticalBuffer1 <= x"0000" & "00" & std_logic_vector(outstandingCount(i)) & "00" & std_logic_vector(creditCount(i));

                        elsif (iSelectStatisticalInformation(i) = '1' and iLowAddress08 = '1') then
                            -- Port-1 Link Status Register3.
                            iStatisticalBuffer1 (15 downto 0)  <= std_logic_vector(timeOutCount(i));
                            iStatisticalBuffer1 (31 downto 16) <= std_logic_vector(dropCount(i));

                        elsif (iSelectStatisticalInformation(i) = '1' and iLowAddress0C = '1') then
                            -- port1 statisticalInformation Receive EOP Register.
                            iStatisticalBuffer1 <= std_logic_vector(statisticalInformation(i)(1));
                        elsif (iSelectStatisticalInformation(i) = '1' and iLowAddress10 = '1') then
                            -- port1 statisticalInformation Transmit EOP Register.
                            iStatisticalBuffer1 <= std_logic_vector(statisticalInformation(i)(0));
                        elsif (iSelectStatisticalInformation(i) = '1' and iLowAddress14 = '1') then
                            -- port1 statisticalInformation Receive EEP Register.
                            iStatisticalBuffer1 <= std_logic_vector(statisticalInformation(i)(3));
                        elsif (iSelectStatisticalInformation(i) = '1' and iLowAddress18 = '1') then
                            -- port1 statisticalInformation Transmit EEP Register.
                            iStatisticalBuffer1 <= std_logic_vector(statisticalInformation(i)(2));
                        elsif (iSelectStatisticalInformation(i) = '1' and iLowAddress1C = '1') then
                            -- port1 statisticalInformation Receive Byte Register.
                            iStatisticalBuffer1 <= std_logic_vector(statisticalInformation(i)(5));
                        elsif (iSelectStatisticalInformation(i) = '1' and iLowAddress20 = '1') then
                            -- port1 statisticalInformation Transmit Byte Register.
                            iStatisticalBuffer1 <= std_logic_vector(statisticalInformation(i)(4));
                        elsif (iSelectStatisticalInformation(i) = '1' and iLowAddress24 = '1') then
                            -- port1 statisticalInformation LinkUp Register.
                            iStatisticalBuffer1 <= std_logic_vector(statisticalInformation(i)(6));
                        elsif (iSelectStatisticalInformation(i) = '1' and iLowAddress28 = '1') then
                            -- port1 statisticalInformation LinkDown Register.
                            iStatisticalBuffer1 <= std_logic_vector(statisticalInformation(i)(7));
                        end if;
                    end loop;

--**************************************************************************************

                    if (iSelectStatisticalInformation(0) = '1' and iLowAddress08 = '1') then
                        -- Port-0 Link Status Register3.
                        iDataOutBuffer (15 downto 0)  <= std_logic_vector(timeOutCount(0));
                        iDataOutBuffer (31 downto 16) <= std_logic_vector(dropCount(0));

--**************************************************************************************

                    elsif (iSelectRouterRegister = '1' and iLowAddress08 = '1') then  --0908
                        -- SpaceWire Port Link-ON Register.
                        iDataOutBuffer <= x"000000" & "0" & linkUp (6 downto 1) & '0';

                    elsif (iSelectRouterRegister = '1' and iLowAddress0C = '1') then  --090C
                        -- Port-0 RMAP Logical Address & Key.
                        iDataOutBuffer <= iPort0CRCRevisionRegister & "000000000000000" & iPort0TargetLogicalAddressRegister & iPort0RMAPKeyRegister;

                    elsif (iSelectRouterRegister = '1' and iLowAddress10 = '1') then  --0910
                        -- Router Configration Register.
                        iDataOutBuffer (7 downto 0)  <= requestPort;
                        iDataOutBuffer (31 downto 8) <= (others => '0');

                    elsif (iSelectRouterRegister = '1' and iLowAddress14 = '1') then  --0914
                        -- Router Port Register.
                        iDataOutBuffer <= cPortBit;

                    elsif (iSelectRouterRegister = '1' and iLowAddress18 = '1') then  --0918
                        -- Router Time-Out Register.
                        iDataOutBuffer (0)            <= iTimeOutEnableRegister;
                        iDataOutBuffer (11 downto 1)  <= (others => '0');
                        iDataOutBuffer (31 downto 12) <= iTimeOutCountValueRegister;

                    elsif (iSelectRouterRegister = '1' and iLowAddress20 = '1') then  --0920
                        -- Router Time-Code Register.
                        iDataOutBuffer <= x"000000" & receiveTimeCode;

                    elsif (iSelectRouterRegister = '1' and iLowAddress24 = '1') then  --0924
                        -- Router Time-Code Enable Register.
                        iDataOutBuffer <= x"000000" & "0" & iTimeCodeEnableRegister;

                    elsif (iSelectRouterRegister = '1' and iLowAddress30 = '1') then  --0930
                        -- AutoTimeCodeCycleTimeRegister.
                        iDataOutBuffer <= x"000000" & autoTimeCodeValue;

                    elsif (iSelectRouterRegister = '1' and iLowAddress34 = '1') then  --934
                        -- AutoTimeCodeValueRegister.
                        iDataOutBuffer <= iAutoTimeCodeCycleTimeRegister;

--**************************************************************************************


                    elsif ((iSelectIDRegister = '1' and iLowAddress00 = '1') or (iSelectOldIDRegister = '1' and iLowAddress30 = '1')) then
                        -- DeviceIDRevision Register.
                        iDataOutBuffer <= cDeviceIDRevision;

                    elsif ((iSelectIDRegister = '1' and iLowAddress04 = '1') or (iSelectOldIDRegister = '1' and iLowAddress34 = '1')) then
                        -- RouterIPRevision Register.
                        iDataOutBuffer <= cRouterIPRevision;

                    elsif ((iSelectIDRegister = '1' and iLowAddress08 = '1') or (iSelectOldIDRegister = '1' and iLowAddress38 = '1')) then
                        -- SpaceWireIPRevision Register.
                        iDataOutBuffer <= cSpaceWireIPRevision;

                    elsif ((iSelectIDRegister = '1' and iLowAddress0C = '1') or (iSelectOldIDRegister = '1' and iLowAddress3C = '1')) then
                        -- RMAPIPRevision Register.
                        iDataOutBuffer <= cRMAPIPRevision;

--**************************************************************************************

                    else
                        iDataOutBuffer <= (others => '0');
                    end if;

                    iAcknowledgeOut <= '1';
                    iBusState       <= busStateRead1;

                    ----------------------------------------------------------------------
                    -- Read Register END.
                    ----------------------------------------------------------------------
                when busStateRead1 =>
                    iAcknowledgeOut    <= '0';
                    iErrorStatusClear  <= (others => '0');
                    iBusState          <= busStatewait0;

                    ----------------------------------------------------------------------
                    -- Write Register Select.
                    ----------------------------------------------------------------------
                when busStateWrite0 =>
                    for i in 1 to cNumberOfInternalPort - 1 loop
                        if (iSelectStatisticalInformation(i) = '1' and iLowAddress00 = '1') then
                            -- Port-1 Link Control/Status Register.
                            if (dataByteEnable (2) = '1') then
                                iLinkControlRegister(i) (0) <= iDataInBuffer (16);
                                iLinkControlRegister(i) (1) <= iDataInBuffer (17);
                                iLinkControlRegister(i) (2) <= iDataInBuffer (18);
                                iSoftWareLinkReset(i)      <= iDataInBuffer (19);
                            end if;
                            if (dataByteEnable (3) = '1') then
                                iLinkControlRegister(i) (13 downto 8) <= iDataInBuffer (29 downto 24);
                            end if;
                        end if;
                    end loop;

--**************************************************************************************

                    if (iSelectRouterRegister = '1' and iLowAddress00 = '1') then  --0900
                        -- LinkStatus3ClearRegister.
                        if (dataByteEnable (0) = '1') then
                            iDropCouterClear <= iDataInBuffer (0);
                        end if;

                    elsif (iSelectRouterRegister = '1' and iLowAddress04 = '1') then
                        --StatisticalInformationReceiveClearRegister.
                        if (dataByteEnable (0) = '1') then
                            iStatisticalInformationReceiveClearRegister <= iDataInBuffer (0);
                        end if;

                    elsif (iSelectRouterRegister = '1' and iLowAddress0C = '1') then  --090C
                        -- Port-0 RMAP Logical Address & Key.
                        if (dataByteEnable (0) = '1') then
                            iPort0RMAPKeyRegister <= iDataInBuffer (7 downto 0);
                        end if;
                        if (dataByteEnable (1) = '1') then
                            iPort0TargetLogicalAddressRegister <= iDataInBuffer (15 downto 8);
                        end if;
                        if (dataByteEnable (3) = '1') then
                            iPort0CRCRevisionRegister <= iDataInBuffer (31);
                        end if;

                    elsif (iSelectRouterRegister = '1' and iLowAddress18 = '1') then  --0918
                        -- TimeOutConfigurationRegister.
                        if (dataByteEnable (0) = '1') then
                            iTimeOutEnableRegister <= iDataInBuffer (0);
                        end if;
                        if (dataByteEnable (1) = '1') then
                            iTimeOutCountValueRegister (3 downto 0) <= iDataInBuffer (15 downto 12);
                        end if;
                        if (dataByteEnable (2) = '1') then
                            iTimeOutCountValueRegister (11 downto 4) <= iDataInBuffer (23 downto 16);
                        end if;
                        if (dataByteEnable (3) = '1') then
                            iTimeOutCountValueRegister (19 downto 12) <= iDataInBuffer (31 downto 24);
                        end if;

                    elsif (iSelectRouterRegister = '1' and iLowAddress24 = '1') then  --0924
                        -- TransmitTimeCodeEnableRegister.
                        if (dataByteEnable (0) = '1') then
                            iTimeCodeEnableRegister (6 downto 1) <= iDataInBuffer (6 downto 1);
                        end if;

                    elsif (iSelectRouterRegister = '1' and iLowAddress34 = '1') then
                        -- AutoTimeCodeValueRegister.
                        if (dataByteEnable (0) = '1') then
                            iAutoTimeCodeCycleTimeRegister(7 downto 0) <= iDataInBuffer (7 downto 0);
                        end if;
                        if (dataByteEnable (1) = '1') then
                            iAutoTimeCodeCycleTimeRegister(15 downto 8) <= iDataInBuffer (15 downto 8);
                        end if;
                        if (dataByteEnable (2) = '1') then
                            iAutoTimeCodeCycleTimeRegister(23 downto 16) <= iDataInBuffer (23 downto 16);
                        end if;
                        if (dataByteEnable (3) = '1') then
                            iAutoTimeCodeCycleTimeRegister(31 downto 24) <= iDataInBuffer (31 downto 24);
                        end if;
                    end if;

                    iAcknowledgeOut <= '1';
                    iBusState       <= busStateWrite1;

                    ----------------------------------------------------------------------
                    -- Write Register END.
                    ----------------------------------------------------------------------
                when busStateWrite1 =>
                    iSoftWareLinkReset                          <= (others => '0');
                    iDropCouterClear                            <= '0';
                    iStatisticalInformationReceiveClearRegister <= '0';
                    iAcknowledgeOut                             <= '0';
                    iBusState                                   <= busStatewait0;

                    ----------------------------------------------------------------------
                    -- Write Register Wait.
                    ----------------------------------------------------------------------
                when busStatewait0 =>
                    iBusState <= busStatewait1;
                when busStatewait1 =>
                    iBusState <= busStateIdle;
                when others => null;
            end case;
        end if;
    end process;




    iRoutingTableStrobe <= cycle and strobe and iSelectRoutingTable;
    iAcknowledge        <= routingTableAcknowledge or iAcknowledgeOut;

    iReadData <= routingTableReadData when iSelectRoutingTable = '1' else
                 iStatisticalBuffer1 when or iSelectStatisticalInformation else
                 iDataOutBuffer;


--------------------------------------------------------------------------------
--  Routing Table.
--------------------------------------------------------------------------------
    routerRoutingTable : SpaceWireRouterIPRouterRoutingTable32x256
        port map (
            clock          => clock,
            reset          => reset,
            strobe         => iRoutingTableStrobe,
            writeEnable    => writeEnable,
            dataByteEnable => dataByteEnable,
            address        => address (9 downto 2),
            writeData      => writeData,
            readData       => routingTableReadData,
            acknowledge    => routingTableAcknowledge
            );
--------------------------------------------------------------------------------
-- longen link reset signal.
--------------------------------------------------------------------------------
    long_gen : for i in 1 to cNumberOfInternalPort - 1 generate
        longPulse : SpaceWireRouterIPLongPulse port map (
            clock => clock, reset => reset, pulseIn => iSoftWareLinkReset(i), longPulseOut => linkReset(i)
            );
    end generate;

    linkControl               <= iLinkControlRegister;
    port0RMAPKey              <= iPort0RMAPKeyRegister;
    port0TargetLogicalAddress <= iPort0TargetLogicalAddressRegister;
    port0CRCRevision          <= iPort0CRCRevisionRegister;

end behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity SpaceWireRouterIPLongPulse is
    port (
        clock        : in  std_logic;
        reset        : in  std_logic;
        pulseIn      : in  std_logic;
        longPulseOut : out std_logic
        );
end SpaceWireRouterIPLongPulse;

architecture behavioral of SpaceWireRouterIPLongPulse is

    signal iClockCount   : unsigned (7 downto 0);
    signal iLongPulseOut : std_logic;

begin

----------------------------------------------------------------------
-- Convert synchronized One Shot Pulse into LongPulse.
----------------------------------------------------------------------
    process (clock, reset)
    begin
        if (reset = '1') then
            iClockCount   <= (others => '0');
            iLongPulseOut <= '0';
        elsif (clock'event and clock = '1') then
            if (pulseIn = '1') then
                iLongPulseOut <= '1';
            end if;
            if (iClockCount = x"ff") then
                iClockCount   <= (others => '0');
                iLongPulseOut <= '0';
            elsif (iLongPulseOut = '1') then
                iClockCount <= iClockCount + 1;
            end if;
        end if;
    end process;

    longPulseOut <= iLongPulseOut;

end behavioral;
