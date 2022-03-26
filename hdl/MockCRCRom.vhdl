library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MockCRCRom is
  port (
      clock    : in  std_logic;
      address  : in  std_logic_vector (8 downto 0);
      readData : out std_logic_vector (7 downto 0)
  );
end MockCRCRom;

architecture behavioral of MockCRCRom is
  type romType is array(0 to 511) of std_logic_vector(7 downto 0);

  constant rom : romType := (
    x"00", x"07", x"0E", x"09", x"1C", x"1B", x"12", x"15",
    x"38", x"3F", x"36", x"31", x"24", x"23", x"2A", x"2D",
    x"70", x"77", x"7E", x"79", x"6C", x"6B", x"62", x"65",
    x"48", x"4F", x"46", x"41", x"54", x"53", x"5A", x"5D",
    x"E0", x"E7", x"EE", x"E9", x"FC", x"FB", x"F2", x"F5",
    x"D8", x"DF", x"D6", x"D1", x"C4", x"C3", x"CA", x"CD",
    x"90", x"97", x"9E", x"99", x"8C", x"8B", x"82", x"85",
    x"A8", x"AF", x"A6", x"A1", x"B4", x"B3", x"BA", x"BD",
    x"C7", x"C0", x"C9", x"CE", x"DB", x"DC", x"D5", x"D2",
    x"FF", x"F8", x"F1", x"F6", x"E3", x"E4", x"ED", x"EA",
    x"B7", x"B0", x"B9", x"BE", x"AB", x"AC", x"A5", x"A2",
    x"8F", x"88", x"81", x"86", x"93", x"94", x"9D", x"9A",
    x"27", x"20", x"29", x"2E", x"3B", x"3C", x"35", x"32",
    x"1F", x"18", x"11", x"16", x"03", x"04", x"0D", x"0A",
    x"57", x"50", x"59", x"5E", x"4B", x"4C", x"45", x"42",
    x"6F", x"68", x"61", x"66", x"73", x"74", x"7D", x"7A",
    x"89", x"8E", x"87", x"80", x"95", x"92", x"9B", x"9C",
    x"B1", x"B6", x"BF", x"B8", x"AD", x"AA", x"A3", x"A4",
    x"F9", x"FE", x"F7", x"F0", x"E5", x"E2", x"EB", x"EC",
    x"C1", x"C6", x"CF", x"C8", x"DD", x"DA", x"D3", x"D4",
    x"69", x"6E", x"67", x"60", x"75", x"72", x"7B", x"7C",
    x"51", x"56", x"5F", x"58", x"4D", x"4A", x"43", x"44",
    x"19", x"1E", x"17", x"10", x"05", x"02", x"0B", x"0C",
    x"21", x"26", x"2F", x"28", x"3D", x"3A", x"33", x"34",
    x"4E", x"49", x"40", x"47", x"52", x"55", x"5C", x"5B",
    x"76", x"71", x"78", x"7F", x"6A", x"6D", x"64", x"63",
    x"3E", x"39", x"30", x"37", x"22", x"25", x"2C", x"2B",
    x"06", x"01", x"08", x"0F", x"1A", x"1D", x"14", x"13",
    x"AE", x"A9", x"A0", x"A7", x"B2", x"B5", x"BC", x"BB",
    x"96", x"91", x"98", x"9F", x"8A", x"8D", x"84", x"83",
    x"DE", x"D9", x"D0", x"D7", x"C2", x"C5", x"CC", x"CB",
    x"E6", x"E1", x"E8", x"EF", x"FA", x"FD", x"F4", x"F3",
    x"00", x"91", x"E3", x"72", x"07", x"96", x"E4", x"75",
    x"0E", x"9F", x"ED", x"7C", x"09", x"98", x"EA", x"7B",
    x"1C", x"8D", x"FF", x"6E", x"1B", x"8A", x"F8", x"69",
    x"12", x"83", x"F1", x"60", x"15", x"84", x"F6", x"67",
    x"38", x"A9", x"DB", x"4A", x"3F", x"AE", x"DC", x"4D",
    x"36", x"A7", x"D5", x"44", x"31", x"A0", x"D2", x"43",
    x"24", x"B5", x"C7", x"56", x"23", x"B2", x"C0", x"51",
    x"2A", x"BB", x"C9", x"58", x"2D", x"BC", x"CE", x"5F",
    x"70", x"E1", x"93", x"02", x"77", x"E6", x"94", x"05",
    x"7E", x"EF", x"9D", x"0C", x"79", x"E8", x"9A", x"0B",
    x"6C", x"FD", x"8F", x"1E", x"6B", x"FA", x"88", x"19",
    x"62", x"F3", x"81", x"10", x"65", x"F4", x"86", x"17",
    x"48", x"D9", x"AB", x"3A", x"4F", x"DE", x"AC", x"3D",
    x"46", x"D7", x"A5", x"34", x"41", x"D0", x"A2", x"33",
    x"54", x"C5", x"B7", x"26", x"53", x"C2", x"B0", x"21",
    x"5A", x"CB", x"B9", x"28", x"5D", x"CC", x"BE", x"2F",
    x"E0", x"71", x"03", x"92", x"E7", x"76", x"04", x"95",
    x"EE", x"7F", x"0D", x"9C", x"E9", x"78", x"0A", x"9B",
    x"FC", x"6D", x"1F", x"8E", x"FB", x"6A", x"18", x"89",
    x"F2", x"63", x"11", x"80", x"F5", x"64", x"16", x"87",
    x"D8", x"49", x"3B", x"AA", x"DF", x"4E", x"3C", x"AD",
    x"D6", x"47", x"35", x"A4", x"D1", x"40", x"32", x"A3",
    x"C4", x"55", x"27", x"B6", x"C3", x"52", x"20", x"B1",
    x"CA", x"5B", x"29", x"B8", x"CD", x"5C", x"2E", x"BF",
    x"90", x"01", x"73", x"E2", x"97", x"06", x"74", x"E5",
    x"9E", x"0F", x"7D", x"EC", x"99", x"08", x"7A", x"EB",
    x"8C", x"1D", x"6F", x"FE", x"8B", x"1A", x"68", x"F9",
    x"82", x"13", x"61", x"F0", x"85", x"14", x"66", x"F7",
    x"A8", x"39", x"4B", x"DA", x"AF", x"3E", x"4C", x"DD",
    x"A6", x"37", x"45", x"D4", x"A1", x"30", x"42", x"D3",
    x"B4", x"25", x"57", x"C6", x"B3", x"22", x"50", x"C1",
    x"BA", x"2B", x"59", x"C8", x"BD", x"2C", x"5E", x"CF"
  );
begin

  process(clock)
  begin
    readData <= rom(to_integer(unsigned(address)));
  end process;

end behavioral;
