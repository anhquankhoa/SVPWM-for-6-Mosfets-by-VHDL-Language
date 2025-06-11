LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.LPM_COMPONENTS.ALL;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_signed.all;

entity park_clark_inv is
port(
	clk 				: in  std_logic:='0';
	address 			: in  std_logic_vector(11 downto 0):=(others => '0');
	u_d 				: in  std_logic_vector(23 downto 0):=(others => '0');
	u_q				: in  std_logic_vector(23 downto 0):=(others => '0');
	u_alpha 			: out std_logic_vector(23 downto 0):=(others => '0');
	u_beta				: out std_logic_vector(23 downto 0):=(others => '0');
	Vrefa,Vrefb,Vrefc               : out std_logic_vector(23 downto 0):=(others => '0');
	done				: out std_logic:='0'
);
end park_clark_inv;

architecture park_clark_inv_arch of park_clark_inv is
	signal sin_out,cos_out,nsin_out 	: std_logic_vector(23 downto 0):=(others => '0');
	signal cos_phi				: std_logic_vector(23 downto 0):=(others => '0');
	signal sin_phi, nsin_phi		: std_logic_vector(23 downto 0):=(others => '0');
	signal cnt		 		: std_logic_vector(7 downto 0):=(others => '0');
	signal adda, addb, addr, mula, mulb 	: std_logic_vector(23 downto 0):=(others => '0');
	signal mulr 				: std_logic_vector(47 downto 0):=(others => '0');
	signal u_a,u_b				: std_logic_vector(23 downto 0):=(others => '0');
	signal Vrefx, Vrefy, Vrefz		: std_logic_vector(23 downto 0):=(others => '0');
	SIGNAL theta 				: INTEGER := 0;
COMPONENT sin625_24bit
		PORT (
			address : IN INTEGER;
			sinx : OUT STD_LOGIC_VECTOR (23 DOWNTO 0)
		);
	END COMPONENT;

COMPONENT cos625_24bit
		PORT (
			address : IN INTEGER;
			cosx : OUT STD_LOGIC_VECTOR (23 DOWNTO 0)
		);
	END COMPONENT;
begin
sinx1 : sin625_24bit PORT MAP(theta, sin_out);
cosx1 : cos625_24bit PORT MAP(theta, cos_out);
mull: lpm_mult
generic map(LPM_WIDTHA=>24,LPM_WIDTHB=>24,LPM_WIDTHS=>24,LPM_WIDTHP=>48,LPM_REPRESENTATION=>"SIGNED",LPM_PIPELINE=>1)
port map(dataa=> mula,datab=> mulb,clock=> clk,result=> mulr);

adder1: lpm_add_sub
generic map(lpm_width=>24,LPM_REPRESENTATION=>"SIGNED",lpm_pipeline=>1)
port map(dataa=>adda,datab=>addb,clock=> clk,result=>addr);
GEN : block
begin
process(clk)
begin
if clk' event and clk = '1' then
	cnt <= cnt + 1;
if cnt = x"00" then
	theta<=CONV_INTEGER(address); --Chuyen tu STD_LOGIC_12bit sang INTERGER
elsif cnt = x"02" then
	sin_phi  <=   sin_out;
	nsin_phi <= - sin_out;
	cos_phi  <=   cos_out;
--INV_PARK
elsif cnt = x"04" then
	mula <= cos_phi;
	mulb <= u_d;
elsif cnt = x"06" then
	adda <= mulr(46 downto 23);   --Ud*cos(phi) --24Q11
	mula <= nsin_phi;
	mulb <= u_q;
elsif cnt = x"08" then
	addb <= mulr(46 downto 23);   --Uq*-sin(phi)--24Q11
	mula <= sin_phi;
	mulb <= u_d;
elsif cnt = x"0A" then
	u_a <= addr;		      --Ud*cos(phi)+Uq*-sin(phi)
	adda <= mulr(46 downto 23);   --Ud*sin(phi) --24Q11
	mula <= cos_phi;
	mulb <= u_q;
elsif cnt = x"0C" then
	addb <= mulr(46 downto 23);   --Uq*cos(phi) --24Q11
elsif cnt = x"0E" then
	u_b <= addr;  		      --Ud*sin(phi)+Uq*cos(phi)
elsif cnt = x"10" then
	u_alpha <= u_a;
	u_beta <= u_b;
--INV_CLARKE Modification
elsif cnt = x"12" then
	Vrefx <= u_b;
	mula <= x"400000"; --24Q23
	mulb <= -u_b;
elsif cnt = x"14" then
	adda <= mulr(46 downto 23);
	mula <= x"6ED9EB";
	mulb <= u_a;
elsif cnt = x"16" then
	addb <= mulr(46 downto 23);
	mula <= x"400000";
	mulb <= -u_b;
elsif cnt = x"18" then
	Vrefy <= addr;
	adda <= mulr(46 downto 23);
	mula <= x"6ED9EB"; --24Q23
	mulb <= -u_a;
elsif cnt = x"1A" then
	addb <= mulr(46 downto 23);
elsif cnt = x"1C" then
	Vrefz <= addr;
elsif cnt = x"1E" then
	Vrefa <= Vrefx;
	Vrefb <= Vrefy;
	Vrefc <= Vrefz;
elsif cnt = x"20" then
	done <= '1','0' after 50 ns;
	cnt <= x"00";
end if;
end if;
end process;
end block GEN;
end park_clark_inv_arch;
