library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.SpaceWireCODECIPPackage.all;
use work.SpaceWireRouterIPPackage.all;

entity Tester is
  port (
  clock : in std_logic;
  transmitClock : in std_logic;
  receiveClock : in std_logic;
  reset : in std_logic
  );
end Tester;

architecture Behavioral of Tester is

  component SpaceWireCODECIP is

      port (
          -- Clock & Reset.
          clock                       : in  std_logic;
          transmitClock               : in  std_logic;
          receiveClock                : in  std_logic;
          reset                       : in  std_logic;
          -- SpaceWire Buffer Status/Control.
          transmitFIFOWriteEnable     : in  std_logic;
          transmitFIFODataIn          : in  std_logic_vector (8 downto 0);
          transmitFIFOFull            : out std_logic;
          transmitFIFODataCount       : out unsigned (5 downto 0);
          receiveFIFOReadEnable       : in  std_logic;
          receiveFIFODataOut          : out std_logic_vector (8 downto 0);
          receiveFIFOFull             : out std_logic;
          receiveFIFOEmpty            : out std_logic;
          receiveFIFODataCount        : out unsigned (5 downto 0);
          -- TimeCode.
          tickIn                      : in  std_logic;
          timeIn                      : in  std_logic_vector (5 downto 0);
          controlFlagsIn              : in  std_logic_vector (1 downto 0);
          tickOut                     : out std_logic;
          timeOut                     : out std_logic_vector (5 downto 0);
          controlFlagsOut             : out std_logic_vector (1 downto 0);
          -- Link Status/Control.
          linkStart                   : in  std_logic;
          linkDisable                 : in  std_logic;
          autoStart                   : in  std_logic;
          linkStatus                  : out std_logic_vector (15 downto 0);
          errorStatus                 : out std_logic_vector (7 downto 0);
          transmitClockDivideValue    : in  unsigned (5 downto 0);
          creditCount                 : out unsigned (5 downto 0);
          outstandingCount            : out unsigned (5 downto 0);
          -- LED.
          transmitActivity            : out std_logic;
          receiveActivity             : out std_logic;
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

  component SpaceWireRouterIP is
      generic (
          gNumberOfInternalPort : integer := cNumberOfInternalPort
          );
      port (
          clock                       : in  std_logic;
          transmitClock               : in  std_logic;
          receiveClock                : in  std_logic;
          reset                       : in  std_logic;
          -- SpaceWire Signals.
          spaceWireDataIn             : in  std_logic_vector(gNumberOfInternalPort - 1 downto 0);
          spaceWireStrobeIn           : in  std_logic_vector(gNumberOfInternalPort - 1 downto 0);
          spaceWireDataOut            : out std_logic_vector(gNumberOfInternalPort - 1 downto 0);
          spaceWireStrobeOut          : out std_logic_vector(gNumberOfInternalPort - 1 downto 0);
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
  end component;

  signal tickIn                      : std_logic;
  signal timeIn                      : std_logic_vector (5 downto 0);
  signal controlFlagsIn              : std_logic_vector (1 downto 0);

  signal interfaceToRouterData       : std_logic_vector(cNumberOfInternalPort - 1 downto 0);
  signal interfaceToRouterStrobe     : std_logic_vector(cNumberOfInternalPort - 1 downto 0);
  signal routerToInterfaceData       : std_logic_vector(cNumberOfInternalPort - 1 downto 0);
  signal routerToInterfaceStrobe     : std_logic_vector(cNumberOfInternalPort - 1 downto 0);

  signal busMasterUserAddressIn      : std_logic_vector (31 downto 0);
  signal busMasterUserDataIn         : std_logic_vector (31 downto 0);
  signal busMasterUserWriteEnableIn  : std_logic;
  signal busMasterUserByteEnableIn   : std_logic_vector (3 downto 0);
  signal busMasterUserStrobeIn       : std_logic;
  signal busMasterUserRequestIn      : std_logic := '0';

  signal linkStatus : std_logic_vector (15 downto 0);
  signal errorStatus : std_logic_vector (7 downto 0);

begin

  interface01 : SpaceWireCODECIP
    port map (
      clock => clock,
      transmitClock => transmitClock,
      receiveClock => receiveClock,
      reset => reset,
      transmitFIFOWriteEnable => '0',
      receiveFIFOReadEnable => '0',
      transmitFIFODataIn => "000000000",
      tickIn => tickIn,
      timeIn => timeIn,
      controlFlagsIn => controlFlagsIn,
      linkStart => '0',
      linkDisable => '0',
      autoStart => '1',
      transmitClockDivideValue => "001001",
      spaceWireDataIn    => routerToInterfaceData (1),
      spaceWireStrobeIn  => routerToInterfaceStrobe (1),
      spaceWireDataOut   => interfaceToRouterData (1),
      spaceWireStrobeOut => interfaceToRouterStrobe (1),
      statisticalInformationClear => '0',
      linkStatus => linkStatus,
      errorStatus => errorStatus
    );

  interface02 : SpaceWireCODECIP
    port map (
      clock => clock,
      transmitClock => transmitClock,
      receiveClock => receiveClock,
      reset => reset,
      transmitFIFOWriteEnable => '0',
      receiveFIFOReadEnable => '0',
      transmitFIFODataIn => "000000000",
      tickIn => tickIn,
      timeIn => timeIn,
      controlFlagsIn => controlFlagsIn,
      linkStart => '0',
      linkDisable => '0',
      autoStart => '1',
      transmitClockDivideValue => "001001",
      spaceWireDataIn    => routerToInterfaceData (2),
      spaceWireStrobeIn  => routerToInterfaceStrobe (2),
      spaceWireDataOut   => interfaceToRouterData (2),
      spaceWireStrobeOut => interfaceToRouterStrobe (2),
      statisticalInformationClear => '0',
      linkStatus => linkStatus,
      errorStatus => errorStatus
    );

  interface03 : SpaceWireCODECIP
    port map (
      clock => clock,
      transmitClock => transmitClock,
      receiveClock => receiveClock,
      reset => reset,
      transmitFIFOWriteEnable => '0',
      receiveFIFOReadEnable => '0',
      transmitFIFODataIn => "000000000",
      tickIn => tickIn,
      timeIn => timeIn,
      controlFlagsIn => controlFlagsIn,
      linkStart => '0',
      linkDisable => '0',
      autoStart => '1',
      transmitClockDivideValue => "001001",
      spaceWireDataIn    => routerToInterfaceData (3),
      spaceWireStrobeIn  => routerToInterfaceStrobe (3),
      spaceWireDataOut   => interfaceToRouterData (3),
      spaceWireStrobeOut => interfaceToRouterStrobe (3),
      statisticalInformationClear => '0',
      linkStatus => linkStatus,
      errorStatus => errorStatus
    );

  interface04 : SpaceWireCODECIP
    port map (
      clock => clock,
      transmitClock => transmitClock,
      receiveClock => receiveClock,
      reset => reset,
      transmitFIFOWriteEnable => '0',
      receiveFIFOReadEnable => '0',
      transmitFIFODataIn => "000000000",
      tickIn => tickIn,
      timeIn => timeIn,
      controlFlagsIn => controlFlagsIn,
      linkStart => '0',
      linkDisable => '0',
      autoStart => '1',
      transmitClockDivideValue => "001001",
      spaceWireDataIn    => routerToInterfaceData (4),
      spaceWireStrobeIn  => routerToInterfaceStrobe (4),
      spaceWireDataOut   => interfaceToRouterData (4),
      spaceWireStrobeOut => interfaceToRouterStrobe (4),
      statisticalInformationClear => '0',
      linkStatus => linkStatus,
      errorStatus => errorStatus
    );

  interface10 : SpaceWireCODECIP
    port map (
      clock => clock,
      transmitClock => transmitClock,
      receiveClock => receiveClock,
      reset => reset,
      transmitFIFOWriteEnable => '0',
      receiveFIFOReadEnable => '0',
      transmitFIFODataIn => "000000000",
      tickIn => tickIn,
      timeIn => timeIn,
      controlFlagsIn => controlFlagsIn,
      linkStart => '0',
      linkDisable => '0',
      autoStart => '1',
      transmitClockDivideValue => "001001",
      spaceWireDataIn    => routerToInterfaceData (10),
      spaceWireStrobeIn  => routerToInterfaceStrobe (10),
      spaceWireDataOut   => interfaceToRouterData (10),
      spaceWireStrobeOut => interfaceToRouterStrobe (10),
      statisticalInformationClear => '0',
      linkStatus => linkStatus,
      errorStatus => errorStatus
    );

  router : SpaceWireRouterIP
    port map (
      clock => clock,
      transmitClock => transmitClock,
      receiveClock => receiveClock,
      reset => reset,
      spaceWireDataIn    =>  interfaceToRouterData,
      spaceWireStrobeIn  =>  interfaceToRouterStrobe,
      spaceWireDataOut   =>  routerToInterfaceData,
      spaceWireStrobeOut =>  routerToInterfaceStrobe,
      busMasterUserAddressIn => busMasterUserAddressIn,
      busMasterUserDataIn => busMasterUserDataIn,
      busMasterUserWriteEnableIn => busMasterUserWriteEnableIn,
      busMasterUserByteEnableIn => busMasterUserByteEnableIn,
      busMasterUserStrobeIn => busMasterUserStrobeIn,
      busMasterUserRequestIn => busMasterUserRequestIn
    );

end architecture;
