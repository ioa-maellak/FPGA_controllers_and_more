library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

----------------------------------------------------------------------------------------------------------------------
-- entity

	entity flash_memory_transciever is
		generic
		(
			data_width : integer := 8 	--default value is 8
			address_width : integer := 22 --default value is 22
		);
		port
		( 
			clk : in std_logic;
			rst : in std_logic;
			switch1 : in std_logic;
			switch2 : in std_logic;
			flash_Address : out std_logic_vector(address_width-1 downto 0);
			flash_Data : in std_logic_vector(data_width-1 downto 0);
			flash_OE : out std_logic;
			flash_RST : out std_logic;
			flash_WE : out std_logic;
			vga_Address : out std_logic_vector(address_width-1 downto 0);
			vga_Data : out std_logic_vector(data_width-1 downto 0);
			vga_WE : out std_logic
		);
	end flash_memory_transciever;
	
----------------------------------------------------------------------------------------------------------------------
architecture bhv of flash_memory_transciever is
----------------------------------------------------------------------------------------------------------------------
-- component declaration
	
	-- 50 to 10 MHz clock frequency decrease PLL
	component pll is
		port
		(
			inclk0 : in std_logic  := '0';
			c0 : out std_logic 
		);
	end component;
	
----------------------------------------------------------------------------------------------------------------------
-- SIGNALS DECLARATION

	signal addressPointer : std_logic_vector(31 downto 0);
	signal dataFromFlash : std_logic_vector(data_width-1 downto 0);
	signal vgaWE : std_logic;
	signal vgaWE_Delay1 : std_logic;
	signal vgaWE_Delay2 : std_logic;
	signal flash_data_Delay1 : std_logic_vector(data_width-1 downto 0);
	signal flash_data_Delay2 : std_logic_vector(data_width-1 downto 0);
	signal clk_khz : std_logic;
	signal clk_Delay1 : std_logic;
	signal clk_Delay2 : std_logic;
	signal clk_10mhz : std_logic;
	signal counter_clk : std_logic_vector(7 downto 0);
	signal counter_address : std_logic_vector(31 downto 0);
	
	type state_type is (s1,s2);
	signal state : state_type;

----------------------------------------------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------------------------------------------
-- component initialization

	pll1: pll port map(clk,clk_10mhz);
	
----------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------
	
	-- 294 kHz clock to read Flash memory (15 fps rate)
	process(clk_10mhz,rst)
	begin
		if rst='0' then
			state <= s1;
			counter_clk <= ( others => '0');
		elsif rising_edge(clk_10mhz) then
			case state is
				when s1 =>  
					counter_clk <= counter_clk + 1;
					clk_khz <= '1';
					if counter_clk=16 then
						state <= s2;
						counter_clk <= ( others => '0');
					end if;
				when s2 =>  
					counter_clk <= counter_clk + 1;
					clk_khz <= '0';
					if counter_clk=16 then
						state <= s1;
						counter_clk <= (others => '0');
					end if;
				when others => 
					clk_khz <= '0';
					counter_clk <= (others => '0');
			end case;
		end if;
	end process;
	
	
	process(clk_khz,rst)
	begin
		if rst = '0' then
			addressPointer <= (others => '1');
			flash_OE <= '1'; 
		elsif rising_edge(clk_khz) then
			if switch1 = '1' then
				-- 1152000 = 4sec*15frames*160*120(resolution)
				-- use the form above to calculate various resolution/duration videos
				if addressPointer < 1151999 or addressPointer > 1151999 then
					addressPointer <= addressPointer + 1;
					flash_OE <= '0';
				else
					addressPointer <= (others => '0');
					flash_OE <= '0';
				end if;
			else
				flash_OE <= '1';
			end if;
		end if;
	end process;


	flash_Address <= addressPointer(address_width-1 downto 0);
	
	
	process(clk_10mhz,rst)
	begin
		if rst = '0' then
			clk_Delay1 <= '0';
			clk_Delay2 <= '0';
		elsif rising_edge(clk_10mhz) then
			if switch1 = '1' then
				clk_Delay1 <= clk_khz;
				clk_Delay2 <= clk_Delay1;
			end if;
		end if;
	end process;
	
	
	process(clk_10mhz,rst)
	begin
		if rst = '0' then
			dataFromFlash <= (others => '0');
			counter_address <= (others => '1');
			vgaWE <= '0';
		elsif rising_edge(clk_10mhz) then
			if switch1='1' and clk_khz='0' then 
				if clk_Delay2='1' and clk_Delay1='0' then
					-- 19200 = 160x120 pixels
					-- use the above form for various video resolutions
					if counter_address < 19199 or counter_address > 19199 then
						counter_address <= counter_address + 1;
						dataFromFlash <= flash_Data;
						vgaWE <= '1';
					else
						counter_address <= (others => '0');
						vgaWE <= '1';
					end if;
				else
					vgaWE <= '0';
				end if;
			else
				vgaWE <= '0';
			end if;
		end if;
	end process;
	
	
	process(clk,rst)
	begin
		if rst = '0' then
			vgaWE_Delay1 <= '0';
			vgaWE_Delay2 <= '0';
		elsif rising_edge(clk) then
			if switch1 = '1' then
				vgaWE_Delay1 <= vgaWE;
				vgaWE_Delay2 <= vgaWE_Delay1;
			end if;
		end if;
	end process;
	
	
	-- chose from 160x120 (switch2='0') or 80x60 (switch2='1') resolution output
	process(clk,rst)
	begin
		if rst = '0' then
			vga_Data <= (others => '0');
			vga_Address <= (others => '0');
			vga_WE <= '0';
		elsif rising_edge(clk) then
			if switch1 = '1' then
				if switch2 = '0' then
					if vgaWE_Delay2='0' and vgaWE_Delay1='1' then
						vga_Data <= dataFromFlash;
						vga_Address <= counter_address(address_width-1 downto 0);
						vga_WE <= vgaWE;
					else
						vga_WE <= '0';
					end if;
				else
					if vgaWE_Delay2='0' and vgaWE_Delay1='1' and counter_address(0)='0' then
						vga_Data <= dataFromFlash;
						vga_Address <= counter_address(address_width-1 downto 0);
						vga_WE <= vgaWE;
					else
						vga_WE <= '0';
					end if;
				end if;
			else
				vga_WE <= '0';
			end if;
		end if;
	end process;
	
	flash_WE <= '1';
	flash_RST <= '1';

end;