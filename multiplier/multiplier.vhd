library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity multiplier is
  port( 
    clk : in std_logic;
    portA : in std_logic_vector(31 downto 0);
    portB : in std_logic_vector(31 downto 0);
    signA : in std_logic;
    signB : in std_logic;
    operation : in std_logic_vector(1 downto 0);
	 output : out std_logic_vector(31 downto 0)
      );
end multiplier;

architecture bhv of multiplier is

  component highpart is 
	 port(
		clock0		: in std_logic;
		dataa_0		: in std_logic_vector (31 downto 0);
		datab_0		: in std_logic_vector (15 downto 0);
		signa		: in std_logic;
		signb		: in std_logic;
		result		: out std_logic_vector (47 downto 0));
  end component;
  
  component lowpart is 
	 port(
		clock0		: in std_logic;
		dataa_0		: in std_logic_vector (31 downto 0);
		datab_0		: in std_logic_vector (15 downto 0);
		signa		: in std_logic;
		result		: out std_logic_vector (47 downto 0));
  end component;

  signal highoutput1 : std_logic_vector(47 downto 0);
  signal lowoutput1 : std_logic_vector(47 downto 0);
  signal highoutput2 : std_logic_vector(63 downto 0);
  signal lowoutput2 : std_logic_vector(63 downto 0);
  signal mulresult : std_logic_vector(63 downto 0);

begin

  highpart1: highpart port map(clk,portA,portB(31 downto 16),signA,signB,highoutput1);
  lowpart1: lowpart port map(clk,portA,portB(15 downto 0),signA,lowoutput1);
 
  process(clk)
  begin
    if rising_edge(clk) then
	   highoutput2(63 downto 16) <= highoutput1;
		lowoutput2(47 downto 0) <= lowoutput1;
    end if;
  end process;
  
  highoutput2(15 downto 0) <= (others => '0');
  
  process(signA,lowoutput2)
  begin
    if signA='1' then
      lowoutput2(63 downto 48) <= (others => lowoutput2(47));
    else
      lowoutput2(63 downto 48) <= (others => '0');
    end if;
  end process;

  mulresult <= lowoutput2 + highoutput2;
  
  process(operation,mulresult)
  begin
    case operation is
      when "01" => 
        output <= mulresult(31 downto 0);
      when "10" => 
        output <= mulresult(63 downto 32);
      when "11" =>
        output <= mulresult(31 downto 0) or mulresult(63 downto 32);
      when others => 
        output <= (others => '0');
    end case;
  end process;
 
end;