library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity vga_controller is
	generic( 
		color_width : integer := 4 	--default value is 3
		buffer_address : integer := 14 	--default value is 14 for 160x120 resolution
		buffer_data : integer := 12 	--default value is 12
		);             
	port(  
		clk : in std_logic;
		rst : in std_logic;
		switch : in std_logic;
		validData : in std_logic;
		addressForVGA : in std_logic_vector(buffer_address-1 downto 0);
		dataForVGA : in std_logic_vector(buffer_data-1 downto 0);
		hsync : out std_logic;
		vsync : out std_logic;
		red : out std_logic_vector(color_width-1 downto 0);
		green : out std_logic_vector(color_width-1 downto 0);
		blue : out std_logic_vector(color_width-1 downto 0)
		);
end vga_controller;


architecture bhv of vga_controller is 

	-- memory buffer // default settings for 160x120 image resolution
	-- for different address/data width use Altera's MegaWizard plug-in manager to re-create the vgaBuffer.vhd 
	component vgaBuffer is
		port(
			clock : in std_logic;
			data : in std_logic_vector (11 downto 0);
			rdaddress : in std_logic_vector (14 downto 0);
			wraddress : in std_logic_vector (14 downto 0);
			wren : in std_logic;
			q : out std_logic_vector (11 downto 0)
			);
	end component;


	signal enable : std_logic;
	signal hcount : std_logic_vector(9 downto 0);
	signal vcount : std_logic_vector(9 downto 0);
	signal sigVsync : std_logic;
	signal sigHsync : std_logic;
	signal addressPointer : std_logic_vector(2 downto 0);
	signal vgaBuffer_rdaddress : std_logic_vector(buffer_address-1 downto 0);
	signal vgaBuffer_dataOut : std_logic_vector(buffer_data-1 downto 0);
	
	type state_type is (s1,s2);
	signal state : state_type;
	
begin
  
  vgaBuffer1: vgaBuffer port map(clk,dataForVGA,vgaBuffer_rdaddress,
              addressForVGA,validData,vgaBuffer_dataOut);
   
   
	vsync <= sigVsync;
	hsync <= sigHsync;
  
	process(clk,rst)
	begin
		if rst='0' then
			state <= s1;
		elsif rising_edge(clk) then
			case state is
				when s1 =>  
					state <= s2;
					enable <= '1';
				when s2 =>  
					state <= s1;
					enable <= '0';
				when others => 
					enable <= '0';
			end case;
		end if;
	end process;
 
 
  process(clk,rst)
  begin
    if rst='0' then
      hcount <= (others => '0');
      sigHsync <= '1';
    elsif rising_edge(clk) then 
      if enable = '1' then
        hcount <= hcount + 1;
        if hcount>655 and hcount<752 then
          sigHsync <= '0';
        elsif (hcount>639 and hcount<656) or (hcount>751 and hcount<799) then
          sigHsync <= '1';
        elsif hcount=799 then
          hcount <= (others => '0');
          sigHsync <= '1';
        else 
          sigHsync <= '1';
        end if;
      end if; 
    end if; 
  end process;
	
  process(clk,rst)
  begin
    if rst='0' then
      vcount <= (others => '0');
      sigVsync <= '1';
    elsif rising_edge(clk) then 
      if enable='1' then
        if hcount=799 then
          vcount <= vcount + 1;
        end if;
        if vcount>490 and vcount<493 then
          sigVsync <= '0';
        elsif (vcount>479 and vcount<491) or (vcount>492 and vcount<524) then
          sigVsync<='1';
        elsif vcount=524 then
          sigVsync <= '1';
          vcount <= (others=>'0');
        else
          sigVsync <= '1';
        end if;
      end if; 
    end if; 
  end process;
	
	process(hcount,vcount,vgaBuffer_dataOut)
	begin
		if ( ( hcount>159 and hcount<480 ) and ( vcount>119 and vcount<360 ) ) then
			red <= vgaBuffer_dataOut(color_width-1 downto 0);
			green <= vgaBuffer_dataOut((color_width*2)-1 downto color_width);
			blue <= vgaBuffer_dataOut((color_width*3)-1 downto (color_width*2));
		else
			red <= (others => '0');
			green <= (others => '0');
			blue <= (others => '0');
		end if;
	end process;

	
	process(clk,rst)
	begin
		if rst='0' then
			vgaBuffer_rdaddress <= (others => '0');
			addressPointer <= (others => '0');
		elsif rising_edge(clk) then
			if enable='1' then
				-- x2 to kathe pixel
				if switch='0' then
					if ( ( hcount>159 and hcount<480 ) and ( vcount>119 and vcount<360 ) ) then
						addressPointer <= addressPointer + 1;
						if addressPointer=1 then
							vgaBuffer_rdaddress <= vgaBuffer_rdaddress + 1;
							addressPointer <= (others => '0');
						end if;
						if vcount(0)='0' and hcount=479 then
							vgaBuffer_rdaddress <= vgaBuffer_rdaddress - 159;
						end if;
					elsif vcount=360 then
						vgaBuffer_rdaddress <= (others => '0');
						addressPointer <= (others => '0');
					end if;
				-- x4 to kathe pixel
				elsif switch='1' then
					if ( ( hcount>159 and hcount<480 ) and ( vcount>119 and vcount<360 ) ) then
						addressPointer <= addressPointer + 1;
						if addressPointer=3 then
							vgaBuffer_rdaddress <= vgaBuffer_rdaddress + 2;
							addressPointer <= (others => '0');
						end if;
						if vcount(1 downto 0)/="11" and hcount=479 then
							vgaBuffer_rdaddress <= vgaBuffer_rdaddress - 158;
						end if;
						if vcount(1 downto 0)="11" and hcount=479 then
							vgaBuffer_rdaddress <= vgaBuffer_rdaddress + 162;
						end if;
					elsif vcount=360 then
						vgaBuffer_rdaddress <= (others => '0');
						addressPointer <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process;

end;