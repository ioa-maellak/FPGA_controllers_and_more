library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity alu is
	generic( 
		data_width : integer := 32 	--default value is 32
		);   
     port( 
		AluInA : in std_logic_vector(data_width-1 downto 0);
        AluInB : in std_logic_vector(data_width-1 downto 0);
        operation : in std_logic_vector(3 downto 0);
        AluOut : out std_logic_vector(data_width-1 downto 0);
        overflow : out std_logic
		);
end alu;

architecture bhv of alu is

  signal AaddB : std_logic_vector(data_width downto 0);
  signal AsubB : std_logic_vector(data_width downto 0);
  signal AmulB : std_logic_vector((data_width*2)-1 downto 0);
  signal AorB : std_logic_vector(data_width-1 downto 0);
  signal AandB : std_logic_vector(data_width-1 downto 0);
  signal AnandB : std_logic_vector(data_width-1 downto 0);
  signal AxorB : std_logic_vector(data_width-1 downto 0);
  signal AnorB : std_logic_vector(data_width-1 downto 0);
  signal overfl1 : std_logic;
  signal overfl2 : std_logic;
  signal AeqB : std_logic;
  signal AneqB : std_logic;
  signal AgteqB_signed : std_logic;
  signal AstB_signed : std_logic;
  signal AgteqB_unsigned : std_logic;
  signal AstB_unsigned : std_logic;
  
begin
 
  -- operation ADD
  AaddB <= ('0' & AluInA) + ('0' & AluInB);
  overfl1 <= AaddB(32) xor AaddB(31);
  -- operation SUB
  AsubB <= ('0' & AluInA) + ('0' & (not AluInB)) + 1;
  overfl2 <= AsubB(32) xor AsubB(31);
  -- operation MUL
  AmulB <= AluInA * AluInB;
  -- operation OR
  AorB <= AluInA or AluInB;
  -- operation AND
  AandB <= AluInA and AluInB;
  -- operation NAND
  AnandB <= not(AandB);
  -- operation XOR
  AxorB <= AluInA xor AluInB;
  -- operation NOR
  AnorB <= AluInA nor AluInB;
  -- rA==rB unsigned
  AeqB <= '1' when AluInA=AluInB else '0';
  -- rA>=rB signed 
  AgteqB_signed <= '1' when signed(AluInA)>=signed(AluInB) else '0';
  -- rA>=rB unsigned
  AgteqB_unsigned <= '1' when unsigned(AluInA)>=unsigned(AluInB) else '0';
  -- rA<rB signed
  AstB_signed <= not(AgteqB_signed);
  -- rA<rB unsigned
  AstB_unsigned <= not(AgteqB_unsigned);
  -- rA!=rB unsigned
  AneqB <= not(AeqB);
  
  process(operation, AaddB, AsubB, AorB, AandB, AnandB, AluInA, AluInB, AxorB, AnorB, AmulB, 
          overfl1 ,overfl2 ,AeqB ,AgteqB_signed ,AgteqB_unsigned ,AneqB, AstB_signed, AstB_unsigned)
  begin
    overflow <= '0';
    case operation is 
      when "0001" => -- operation ADD
        AluOut <= AaddB(data_width-1 downto 0);
        overflow <= overfl1;
      when "0010" => -- operation SUB
        AluOut <= AsubB(data_width-1 downto 0);
        overflow <= overfl2;
	  when "0011" => -- operation MUL (lower)
	    AluOut <= AmulB(data_width-1 downto 0);
      when "0100" => -- operation MUL (higher)
	    AluOut <= AmulB((data_width*2)-1 downto data_width);
      
	  when "0101" => -- logical OR
        AluOut <= AorB;
      when "0110" => -- logical AND
        AluOut <= AandB;
      when "0111" => -- logical NAND
        AluOut <= AnandB;
      when "1000" => -- logical XOR
        AluOut <= AxorB;
      when "1001" => -- logical NOR
        AluOut <= AnorB;
		
      when "1010" => -- rA==rB unsigned
        AluOut(0) <= AeqB;
        AluOut(data_width-1 downto 1) <= (others => '0');
      when "1011" => -- rA>=rB signed
        AluOut(0) <= AgteqB_signed;
        AluOut(data_width-1 downto 1) <= (others => '0');
      when "1100" => -- rA>=rB unsigned
        AluOut(0) <= AgteqB_unsigned;
        AluOut(data_width-1 downto 1) <= (others => '0');
      when "1101" => -- rA<rB signed
        AluOut(0) <= AstB_signed;
        AluOut(data_width-1 downto 1) <= (others => '0');
      when "1110" => -- rA<rB unsigned
        AluOut(0) <= AstB_unsigned;
        AluOut(data_width-1 downto 1) <= (others => '0');
      when "1111" => -- rA!=rB unsigned
        AluOut(0) <= AneqB;
        AluOut(data_width-1 downto 1) <= (others => '0');
      when others => 
        AluOut <= (others => '0');
    end case;
	
    if ((AluInA(data_width-1))xor(AluInB(data_width-1)))='1' then
      overflow <= '0';
    end if;
  end process;
end;
