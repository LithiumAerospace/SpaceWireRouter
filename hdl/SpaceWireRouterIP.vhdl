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
use work.SpaceWireRouterIPPackage.all;
use work.SpaceWireCODECIPPackage.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity SpaceWireRouterIP is
    port (
        clock                       : in  std_logic;
        transmitClock               : in  std_logic;
        receiveClock                : in  std_logic;
        reset                       : in  std_logic;
        -- SpaceWire Signals.
        spaceWireDataIn             : in  std_logic_vector(cNumberofInternalPort - 1 downto 0);
        spaceWireStrobeIn           : in  std_logic_vector(cNumberofInternalPort - 1 downto 0);
        spaceWireDataOut            : out std_logic_vector(cNumberofInternalPort - 1 downto 0);
        spaceWireStrobeOut          : out std_logic_vector(cNumberofInternalPort - 1 downto 0);
        --
        statisticalInformationPort  : out statisticalInformationArray;
        --
        oneShotStatusPort           : out bit8XPortArray;
        --
        busMasterUserAddressIn      : in  std_logic_vector (31 downto 0);
        busMasterUserDataOut        : out std_logic_vector (31 downto 0);
        busMasterUserDataIn         : in  std_logic_vector (31 downto 0);
        busMasterUserWriteEnableIn  : in  std_logic;
        busMasterUserByteEnableIn   : in  std_logic_vector (3 downto 0);
        busMasterUserStrobeIn       : in  std_logic;
        busMasterUserRequestIn      : in  std_logic;
        busMasterUserAcknowledgeOut : out std_logic
        );
end SpaceWireRouterIP;


architecture behavioral of SpaceWireRouterIP is

--------------------------------------------------------------------------------
-- SpaceWire Physical Port.
--------------------------------------------------------------------------------
    component SpaceWireRouterIPSpaceWirePort is
        generic (
            gNumberofInternalPort : std_logic_vector (7 downto 0);
            gNumberOfExternalPort : std_logic_vector (4 downto 0)
            );
        port (
            -- Clock & Reset.
            clock                       : in  std_logic;
            transmitClock               : in  std_logic;
            receiveClock                : in  std_logic;
            reset                       : in  std_logic;
            -- switch info.
            linkUp                      : in  std_logic_vector (cNumberOfInternalPort - 1 downto 0);
            timeOutEnable               : in  std_logic;
            timeOutCountValue           : in  std_logic_vector (19 downto 0);
            timeOutEEPOut               : out std_logic;
            timeOutEEPIn                : in  std_logic;
            packetDropped               : out std_logic;
            -- switch out port.
            requestOut                  : out std_logic;
            destinationPortOut          : out std_logic_vector (7 downto 0);
            sourcePorOut                : out std_logic_vector (7 downto 0);
            grantedIn                   : in  std_logic;
            dataOut                     : out std_logic_vector (8 downto 0);
            strobeOut                   : out std_logic;
            readyIn                     : in  std_logic;
            -- switch in port.
            requestIn                   : in  std_logic;
            dataIn                      : in  std_logic_vector (8 downto 0);
            strobeIn                    : in  std_logic;
            readyOut                    : out std_logic;
            -- routing table read i/f.
            busMasterAddressOut         : out std_logic_vector (31 downto 0);
            busMasterDataIn             : in  std_logic_vector (31 downto 0);
            busMasterDataOut            : out std_logic_vector (31 downto 0);
            busMasterWriteEnableOut     : out std_logic;
            busMasterByteEnableOut      : out std_logic_vector (3 downto 0);
            busMasterStrobeOut          : out std_logic;
            busMasterRequestOut         : out std_logic;
            busMasterAcknowledgeIn      : in  std_logic;
            -- SpaceWire timecode.
            tickIn                      : in  std_logic;
            timeCodeIn                  : in  std_logic_vector (7 downto 0);
            tickOut                     : out std_logic;
            timeCodeOut                 : out std_logic_vector (7 downto 0);
            -- SpaceWire link status/control.
            linkStart                   : in  std_logic;
            linkDisable                 : in  std_logic;
            autoStart                   : in  std_logic;
            linkReset                   : in  std_logic;
            linkStatus                  : out std_logic_vector (15 downto 0);
            errorStatus                 : out std_logic_vector (7 downto 0);
            transmitClockDivide         : in  unsigned (5 downto 0);
            creditCount                 : out unsigned (5 downto 0);
            outstandingCount            : out unsigned (5 downto 0);
            -- SpaceWire Data-Strobe.
            spaceWireDataOut            : out std_logic;
            spaceWireStrobeOut          : out std_logic;
            spaceWireDataIn             : in  std_logic;
            spaceWireStrobeIn           : in  std_logic;
            -- Statistics.
            statisticalInformationClear : in  std_logic;
            statisticalInformation      : out bit32X8Array
            );
    end component;


--------------------------------------------------------------------------------
-- Internal Configuration Port.
--------------------------------------------------------------------------------
    component SpaceWireRouterIPRMAPPort is
        generic (
            gPortNumber           : std_logic_vector (7 downto 0);
            gNumberOfExternalPort : std_logic_vector (4 downto 0)
            );
        port (
            clock                   : in  std_logic;
            reset                   : in  std_logic;
            linkUp                  : in  std_logic_vector (cNumberOfInternalPort - 1 downto 0);
--
            timeOutEnable           : in  std_logic;
            timeOutCountValue       : in  std_logic_vector (19 downto 0);
            timeOutEEPOut           : out std_logic;
            timeOutEEPIn            : in  std_logic;
            packetDropped           : out std_logic;
--
            PortRequest             : out std_logic;
            destinationPortOut      : out std_logic_vector (7 downto 0);
            sorcePortOut            : out std_logic_vector (7 downto 0);
            grantedIn               : in  std_logic;
            dataOut                 : out std_logic_vector (8 downto 0);
            strobeOut               : out std_logic;
            readyIn                 : in  std_logic;
--
            requestIn               : in  std_logic;
            sourcePortIn            : in  std_logic_vector (7 downto 0);
            dataIn                  : in  std_logic_vector (8 downto 0);
            strobeIn                : in  std_logic;
            readyOut                : out std_logic;
--
            logicalAddress          : in  std_logic_vector (7 downto 0);
            rmapKey                 : in  std_logic_vector (7 downto 0);
            crcRevision             : in  std_logic;
--
            busMasterOriginalPort   : out std_logic_vector (7 downto 0);
            busMasterAddressOut     : out std_logic_vector (31 downto 0);
            busMasterDataIn         : in  std_logic_vector (31 downto 0);
            busMasterDataOut        : out std_logic_vector (31 downto 0);
            busMasterWriteEnableOut : out std_logic;
            busMasterByteEnableOut  : out std_logic_vector (3 downto 0);
            busMasterStrobeOut      : out std_logic;
            busMasterRequestOut     : out std_logic;
            busMasterAcknowledgeIn  : in  std_logic
            );
    end component;

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
    component SpaceWireRouterIPStatisticsCounter is
        port (
            clock                 : in  std_logic;
            reset                 : in  std_logic;
            allCounterClear       : in  std_logic;
--
            watchdogTimeOut        : in  std_logic_vector (cNumberofInternalPort - 1 downto 0);
            packetDropped          : in  std_logic_vector (cNumberofInternalPort - 1 downto 0);
            watchdogTimeOutCount   : out unsigned16xPort;
            dropCount              : out unsigned16xPort
            );
    end component;


    signal packetDropped     : std_logic_vector (cNumberofInternalPort - 1 downto 0);
    signal timeOutCount      : unsigned16xPort;
    signal packetDropCount   : unsigned16xPort;

--------------------------------------------------------------------------------
-- Synchronized CreditCount/OutstandingCount.
--------------------------------------------------------------------------------
    component SpaceWireRouterIPCreditCount is
        port (
            clock                       : in  std_logic;
            transmitClock               : in  std_logic;
            reset                       : in  std_logic;
            creditCount                 : in  unsigned (5 downto 0);
            outstndingCount             : in  unsigned (5 downto 0);
            creditCountSynchronized     : out unsigned (5 downto 0);
            outstndingCountSynchronized : out unsigned (5 downto 0)
            );
    end component;


--------------------------------------------------------------------------------
-- Crossbar Switch.
--------------------------------------------------------------------------------
    component SpaceWireRouterIPArbiter is
        port (
            clock              : in  std_logic;
            reset              : in  std_logic;
            destinationOfPort  : in  bit8XPortArray;
            requestOfPort      : in  std_logic_vector (cNumberOfInternalPort - 1 downto 0);
            grantedToPort      : out std_logic_vector (cNumberOfInternalPort - 1 downto 0);
            routingSwitch      : out std_logic_vector ((cNumberOfInternalPort**2) - 1 downto 0)
            );
    end component;

    signal iSelectDestinationPort            : portXPortArray;
    signal iSwitchPortNumber                 : portXPortArray;
--
    signal requestOut                        : std_logic_vector (cNumberofInternalPort - 1 downto 0);
    signal destinationPort                   : bit8XPortArray;
    signal sorcePortrOut                     : bit8XPortArray;
    signal granted                           : std_logic_vector (cNumberofInternalPort - 1 downto 0);
    signal iReadyIn                          : std_logic_vector (cNumberofInternalPort - 1 downto 0);
    signal dataOut                           : bit9XPortArray;
    signal strobeOut                         : std_logic_vector (cNumberofInternalPort - 1 downto 0);
    signal iRequestIn                        : std_logic_vector (cNumberofInternalPort - 1 downto 0);
    signal iSorcePortIn                      : bit8XPortArray;
    signal iDataIn                           : bit9XPortArray;
    signal iStrobeIn                         : std_logic_vector (cNumberofInternalPort - 1 downto 0);
    signal readyOut                          : std_logic_vector (cNumberofInternalPort - 1 downto 0);
--
    signal iTimeOutEEPIn                     : std_logic_vector (cNumberofInternalPort - 1 downto 0);
    signal timeOutEEPOut                     : std_logic_vector (cNumberofInternalPort - 1 downto 0);
--
    signal routingSwitch                     : std_logic_vector ((cNumberofInternalPort**2 - 1) downto 0);
--
    signal routerTimeCode                    : std_logic_vector (7 downto 0);
    signal transmitTimeCodeEnable            : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
--
    signal portTickIn                        : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal portTimeCodeIn                    : bit8XPortArray;
    signal portTickOut                       : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal portTimeCodeOut                   : bit8XPortArray;
--
    signal portLinkReset                     : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal portLinkStatus                    : bit16xPortArray;
    signal portLinkStatus2                   : bit8XPortArray;
    signal portErrorStatus                   : bit8XPortArray;
    signal portLinkControl                   : bit16xPortArray;
--
    signal portCreditCount                   : unsigned6xPortArray;
    signal portOutstandingCount              : unsigned6xPortArray;
    signal portCreditCountSynchronized       : unsigned6xPortArray;
    signal portOutstandingCountSynchronized  : unsigned6xPortArray;
--
    signal timeOutEnable                     : std_logic;
    signal timeOutCountValue                 : std_logic_vector (19 downto 0);
--
    signal busMasterAddressOut               : bit32X9Array;
    signal busMasterDataOut                  : bit32X9Array;
    signal busMasterByteEnableOut            : bit4X9Array;
    signal busMasterWriteEnableOut           : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal busMasterRequestOut               : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal busMasterGranted                  : std_logic_vector (cNumberOfInternalPort     downto 0);
    signal busMasterAcknowledgeIn            : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal busMasterStrobeOut                : std_logic_vector (cNumberOfInternalPort - 1 downto 0);
    signal busMasterOriginalPortOut          : bit8X9Array;
--
    signal iBusSlaveCycleIn                  : std_logic;
    signal iBusSlaveStrobeIn                 : std_logic;
    signal iBusSlaveAddressIn                : std_logic_vector (31 downto 0);
    signal busSlaveDataOut                   : std_logic_vector (31 downto 0);
    signal iBusSlaveDataIn                   : std_logic_vector (31 downto 0);
    signal iBusSlaveAcknowledgeOut           : std_logic;
    signal iBusSlaveWriteEnableIn            : std_logic;
    signal iBusSlaveByteEnableIn             : std_logic_vector (3 downto 0);
    signal iBusSlaveOriginalPortIn           : std_logic_vector (7 downto 0);
--
    signal port0LogicalAddress               : std_logic_vector (7 downto 0);
    signal port0RMAPKey                      : std_logic_vector (7 downto 0);
    signal port0CRCRevision                  : std_logic;
--
    signal autoTimeCodeValue                 : std_logic_vector(7 downto 0);
    signal autoTimeCodeCycleTime             : std_logic_vector(31 downto 0);
--
    signal statisticalInformation            : statisticalInformationArray;
    signal statisticalInformationClear       : std_logic;
--
    signal dropCouterClear                   : std_logic;
    signal iBusMasterUserAcknowledgeOut      : std_logic;
--
    signal ibusMasterDataOut                 : std_logic_vector (31 downto 0);

--------------------------------------------------------------------------------
-- Router Link Control, Status Registers and Routing Table.
--------------------------------------------------------------------------------
    component SpaceWireRouterIPRouterControlRegister is
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
    end component;


--------------------------------------------------------------------------------
-- Bus arbiter.
--------------------------------------------------------------------------------

    component SpaceWireRouterIPTableArbiter is
        port (
            clock   : in  std_logic;
            reset   : in  std_logic;
            request : in  std_logic_vector (cNumberofInternalPort downto 0);
            granted : out std_logic_vector (cNumberofInternalPort downto 0)
            );
    end component;

    signal iLinkUp : std_logic_vector (cNumberOfInternalPort - 1 downto 0);

--------------------------------------------------------------------------------
-- Forwarding TimeCode logic.
--------------------------------------------------------------------------------

    component SpaceWireRouterIPTimeCodeControl is
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
    end component;

begin

    oneShotStatus : for i in 1 to cNumberOfInternalPort - 1 generate
      oneShotStatusPort(i) <= portLinkStatus(i)(15 downto 8);
    end generate;

--------------------------------------------------------------------------------
-- Crossbar Switch.
--------------------------------------------------------------------------------
    arbiter : SpaceWireRouterIPArbiter
        port map (
            clock              => clock,
            reset              => reset,
            destinationOfPort  => destinationPort,
            requestOfPort      => requestOut,
            grantedToPort      => granted,
            routingSwitch      => routingSwitch
            );

----------------------------------------------------------------------
-- The destination PortNo regarding the source PortNo.
----------------------------------------------------------------------

    switchdest_gen : for i in 0 to cNumberOfInternalPort - 1 generate
        switchdest_gen2 : for j in 0 to cNumberOfInternalPort - 1 generate
            iSelectDestinationPort(i)(j) <= routingSwitch(i+(cNumberOfInternalPort*j));
        end generate;
    end generate;

----------------------------------------------------------------------
-- The source to the destination PortNo PortNo.
----------------------------------------------------------------------

    swicthport_gen : for i in 0 to cNumberOfInternalPort - 1 generate
        iSwitchPortNumber (i) <= routingSwitch (((i+1)*cNumberOfInternalPort) - 1 downto i*cNumberOfInternalPort);
    end generate;

    spx : for i in 0 to cNumberofInternalPort - 1 generate
    begin
        iReadyIn (i) <= select7x1(iSelectDestinationPort (i), readyOut);
        iRequestIn (i) <= select7x1(iSwitchPortNumber (i), requestOut);
        iSorcePortIn (i) <= select7x1xVector8(iSwitchPortNumber (i), sorcePortrOut);
        iDataIn (i) <= select7x1xVector9(iSwitchPortNumber (i), dataOut);
        iStrobeIn (i) <= select7x1(iSwitchPortNumber (i), strobeOut);
        iTimeOutEEPIn (i) <= select7x1(iSwitchPortNumber (i), timeOutEEPOut);
    end generate spx;

----------------------------------------------------------------------
-- SpaceWirePort LinkUP Signal.
----------------------------------------------------------------------
    process(clock)
    begin
        if(clock'event and clock = '1') then
            iLinkUp (0) <= '1';
            for i in 1 to cNumberOfInternalPort - 1 loop
                iLinkUp (i) <= '1' when portLinkStatus(i)(5 downto 0) = "111111" else '0';
            end loop;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Internal Configuration Port.
--------------------------------------------------------------------------------
    port00 : SpaceWireRouterIPRMAPPort
        generic map (gPortNumber => x"00", gNumberOfExternalPort => cNumberOfExternalPort)
        port map (
            clock                   => clock,
            reset                   => reset,
            linkUp                  => iLinkUp,
--
            timeOutEnable           => timeOutEnable,
            timeOutCountValue       => timeOutCountValue,
            timeOutEEPOut           => timeOutEEPOut (0),
            timeOutEEPIn            => iTimeOutEEPIn (0),
            packetDropped           => packetDropped (0),
--
            PortRequest             => requestOut (0),
            destinationPortOut      => destinationPort (0),
            sorcePortOut            => sorcePortrOut (0),
            grantedIn               => granted (0),
            readyIn                 => iReadyIn (0),
            dataOut                 => dataOut (0),
            strobeOut               => strobeOut (0),
--
            requestIn               => iRequestIn (0),
            sourcePortIn            => iSorcePortIn (0),
            readyOut                => readyOut (0),
            dataIn                  => iDataIn (0),
            strobeIn                => iStrobeIn (0),
--
            logicalAddress          => port0LogicalAddress,
            rmapKey                 => port0RMAPKey ,
            crcRevision             => port0CRCRevision,
--
            busMasterOriginalPort   => busMasterOriginalPortOut (0),
            busMasterRequestOut     => busMasterRequestOut (0),
            busMasterStrobeOut      => busMasterStrobeOut (0),
            busMasterAddressOut     => busMasterAddressOut (0),
            busMasterByteEnableOut  => busMasterByteEnableOut (0),
            busMasterWriteEnableOut => busMasterWriteEnableOut (0),
            busMasterDataIn         => busSlaveDataOut,
            busMasterDataOut        => busMasterDataOut (0),
            busMasterAcknowledgeIn  => busMasterAcknowledgeIn (0)
            );


--------------------------------------------------------------------------------
-- SpaceWire Physical Port.
--------------------------------------------------------------------------------

    port_gen: for i in 1 to cNumberOfInternalPort - 1 generate
      portx : SpaceWireRouterIPSpaceWirePort
        generic map (gNumberOfInternalPort => std_logic_vector(to_unsigned(i, 8)), gNumberOfExternalPort => cNumberOfExternalPort)
        port map (
            clock                       => clock,
            transmitClock               => transmitClock,
            receiveClock                => receiveClock,
            reset                       => reset,
--
            linkUp                      => iLinkUp,
--
            timeOutEnable               => timeOutEnable,
            timeOutCountValue           => timeOutCountValue,
            timeOutEEPOut               => timeOutEEPOut (i),
            timeOutEEPIn                => iTimeOutEEPIn (i),
            packetDropped               => packetDropped (i),
--
            requestOut                  => requestOut (i),
            destinationPortOut          => destinationPort (i),
            sourcePorOut                => sorcePortrOut (i),
            grantedIn                   => granted (i),
            readyIn                     => iReadyIn (i),
            dataOut                     => dataOut (i),
            strobeOut                   => strobeOut (i),
--
            requestIn                   => iRequestIn (i),
            readyOut                    => readyOut (i),
            dataIn                      => iDataIn (i),
            strobeIn                    => iStrobeIn (i),
--
            busMasterRequestOut         => busMasterRequestOut (i),
            busMasterStrobeOut          => busMasterStrobeOut (i),
            busMasterAddressOut         => busMasterAddressOut (i),
            busMasterByteEnableOut      => busMasterByteEnableOut (i),
            busMasterWriteEnableOut     => busMasterWriteEnableOut (i),
            busMasterDataIn             => busSlaveDataOut,
            busMasterDataOut            => busMasterDataOut (i),
            busMasterAcknowledgeIn      => busMasterAcknowledgeIn (i),
--
            tickIn                      => portTickIn (i),
            timeCodeIn                  => portTimeCodeIn (i),
            tickOut                     => portTickOut (i),
            timeCodeOut                 => portTimeCodeOut (i),
--
            linkStart                   => portLinkControl (i)(0),
            linkDisable                 => portLinkControl (i)(1),
            autoStart                   => portLinkControl (i)(2),
            linkReset                   => portLinkReset (i),
            transmitClockDivide         => unsigned(portLinkControl (i)(13 downto 8)),
            linkStatus                  => portLinkStatus (i),
            errorStatus                 => portErrorStatus (i),
            creditCount                 => portCreditCount (i),
            outstandingCount            => portOutstandingCount (i),
--
            spaceWireDataOut            => spaceWireDataOut (i),
            spaceWireStrobeOut          => spaceWireStrobeOut (i),
            spaceWireDataIn             => spaceWireDataIn (i),
            spaceWireStrobeIn           => spaceWireStrobeIn (i),
--
            statisticalInformationClear => statisticalInformationClear,
            statisticalInformation      => statisticalInformation (i)
            );

      creditCount : SpaceWireRouterIPCreditCount
          port map (
          clock                       => clock,
          transmitClock               => transmitClock,
          reset                       => reset,
          creditCount                 => portCreditCount (i),
          outstndingCount             => portOutstandingCount (i),
          creditCountSynchronized     => portCreditCountSynchronized (i),
          outstndingCountSynchronized => portOutstandingCountSynchronized (i)
          );
    end generate port_gen;

    statisticsCounters : SpaceWireRouterIPStatisticsCounter
        port map (
            clock                 => clock,
            reset                 => reset,
            allCounterClear       => dropCouterClear,
--
            watchdogTimeOut       => timeOutEEPOut,
            packetDropped         => packetDropped,
            watchdogTimeOutCount  => timeOutCount,
            dropCount             => packetDropCount
            );

    statisticalInformationPort <= statisticalInformation;


--------------------------------------------------------------------------------
-- Router Link Control, Status Registers and Routing Table.
--------------------------------------------------------------------------------

    portLinkStatusGen : for i in 1 to cNumberOfInternalPort - 1 generate
        portLinkStatus2 (i) <= portLinkStatus (i)(7 downto 0);
    end generate;

    routerControlRegister : SpaceWireRouterIPRouterControlRegister
        port map (
            clock         => clock,
            reset         => reset,
            transmitClock => transmitClock,
            receiveClock  => receiveClock,
--
            writeData     => iBusSlaveDataIn,

            readData                    => ibusMasterDataOut,
            acknowledge                 => iBusSlaveAcknowledgeOut,
            address                     => iBusSlaveAddressIn,
            strobe                      => iBusSlaveStrobeIn,
            cycle                       => iBusSlaveCycleIn,
            writeEnable                 => iBusSlaveWriteEnableIn,
            dataByteEnable              => iBusSlaveByteEnableIn,
            requestPort                 => iBusSlaveOriginalPortIn,
--
            linkUp                      => iLinkUp,
            linkControl                 => portLinkControl,
            linkStatus                  => portLinkStatus2,
            errorStatus                 => portErrorStatus,
            linkReset                   => portLinkReset,

            creditCount                 => portCreditCountSynchronized,
            outstandingCount            => portOutstandingCountSynchronized,
            timeOutCount                => timeOutCount,
--
            dropCount                   => packetDropCount,
--
            dropCouterClear             => dropCouterClear,
--
            timeOutEnable               => timeOutEnable,
            timeOutCountValue           => timeOutCountValue,
--
            receiveTimeCode             => routerTimeCode,
            transmitTimeCodeEnable      => transmitTimeCodeEnable,
--
            port0TargetLogicalAddress   => port0LogicalAddress,
            port0RMAPKey                => port0RMAPKey,
            port0CRCRevision            => port0CRCRevision,
--
            autoTimeCodeValue           => autoTimeCodeValue,
            autoTimeCodeCycleTime       => autoTimeCodeCycleTime,
--
            statisticalInformation      => statisticalInformation,
            statisticalInformationClear => statisticalInformationClear
            );


--------------------------------------------------------------------------------
-- Bus arbiter.
--------------------------------------------------------------------------------
    busAbiter : SpaceWireRouterIPTableArbiter port map (
        clock               => clock,
        reset               => reset,
        request((cNumberOfInternalPort - 1) downto 0) => busMasterRequestOut ((cNumberOfInternalPort - 1) downto 0),
        request(cNumberOfInternalPort)  => busMasterUserRequestIn,
        granted             => busMasterGranted (cNumberOfInternalPort downto 0)
        );


----------------------------------------------------------------------
-- Timing adjustment.
-- BusSlaveAccessSelector.
----------------------------------------------------------------------
    process(clock)
    begin
        if (clock'event and clock = '1') then

            if or busMasterRequestOut then
                iBusSlaveCycleIn <= '1';
            elsif busMasterUserRequestIn = '1' then
              iBusSlaveCycleIn <= '1';
            else
                iBusSlaveCycleIn <= '0';
            end if;
--

            iBusSlaveStrobeIn            <= busMasterUserStrobeIn;
            iBusSlaveAddressIn           <= busMasterUserAddressIn;
            iBusSlaveByteEnableIn        <= busMasterUserByteEnableIn;
            iBusSlaveWriteEnableIn       <= busMasterUserWriteEnableIn;
            iBusSlaveOriginalPortIn      <= x"ff";
            iBusSlaveDataIn              <= busMasterUserDataIn;
            iBusMasterUserAcknowledgeOut <= iBusSlaveAcknowledgeOut;
            busMasterAcknowledgeIn       <= (others => '0');

            for i in 0 to cNumberOfInternalPort - 1 loop
                if (busMasterGranted(i) = '1') then
                    iBusSlaveStrobeIn         <= busMasterStrobeOut (i);
                    iBusSlaveAddressIn        <= busMasterAddressOut (i);
                    iBusSlaveByteEnableIn     <= busMasterByteEnableOut (i);
                    iBusSlaveWriteEnableIn    <= busMasterWriteEnableOut (i);
                    iBusSlaveOriginalPortIn   <= busMasterOriginalPortOut(i);
                    iBusSlaveDataIn           <= busMasterDataOut (i);
                    busMasterAcknowledgeIn    <= (others => '0');
                    busMasterAcknowledgeIn(i) <= iBusSlaveAcknowledgeOut;
                    exit;
                end if;
            end loop;

            busSlaveDataOut             <= ibusMasterDataOut;
            busMasterUserDataOut        <= ibusMasterDataOut;
            busMasterUserAcknowledgeOut <= iBusMasterUserAcknowledgeOut;
        end if;
    end process;

--------------------------------------------------------------------------------
-- time code forwarding logic.
--------------------------------------------------------------------------------
    timeCodeControl : SpaceWireRouterIPTimeCodeControl
        port map (
            clock                 => clock,
            reset                 => reset,
            -- switch info.
            linkUp                => iLinkUp,
            receiveTimeCode       => routerTimeCode,
            -- spacewire timecode.
            portTimeCodeEnable   => transmitTimeCodeEnable,
            portTickIn           => portTickIn,
            portTimeCodeIn       => portTimeCodeIn,
            portTickOut          => portTickOut,
            portTimeCodeOut      => portTimeCodeOut,
--
            autoTimeCodeValue     => autoTimeCodeValue,
            autoTimeCodeCycleTime => autoTimeCodeCycleTime
            );

end behavioral;
