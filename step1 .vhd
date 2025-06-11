library IEEE;
library lpm;
use lpm.lpm_components.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use IEEE.numeric_std.all;


entity step1 is
port(  
	clk, clk_200n  			: in  std_logic:='0';
	address 			: in  std_logic_vector(11 downto 0):=(others => '0');
	u_d 				: in  std_logic_vector(23 downto 0):=(others => '0');
	u_q				: in  std_logic_vector(23 downto 0):=(others => '0');
	PWM1,PWM2,PWM3,PWM4,PWM5,PWM6	: out  STD_LOGIC:='0');
end step1; 

ARCHITECTURE step1_arch OF step1 IS

signal u_alpha, u_beta 		: STD_LOGIC_VECTOR (23 downto 0):=(others =>'0');

component park_clark_inv is
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
end component park_clark_inv;

component SVPWM1 is
port(  
	clk,clk_200n				: in   STD_LOGIC:='0';
	Vref1,Vref2,Vref3			: in  STD_LOGIC_VECTOR (23 downto 0):=(others =>'0');
	PWM1,PWM2,PWM3,PWM4,PWM5,PWM6		: out  STD_LOGIC:='0'
	);
end component svpwm1;

signal Vref_1,Vref_2,Vref_3 	: std_logic_vector (23 downto 0):=(others =>'0');
signal Vref1,Vref2,Vref3	: STD_LOGIC_VECTOR (23 downto 0):=(others =>'0');	
signal CNT		 	: std_logic_vector (7 downto 0):=(others =>'0');
signal go			: std_logic:='0';

begin 
U_SIN_COS: park_clark_inv port map (
	clk => CLK,		
	address => address,			
	u_d => 	u_d	,		--   u_d,	X"00000000"	
	u_q => u_q,		
	u_alpha => u_alpha,		
	u_beta	=> u_beta,		
	Vrefa	=> Vref_1,
	Vrefb	=> Vref_2,
	Vrefc  	=> Vref_3,             
	done	=> go			
	);

U_SVPWM: svpwm1 port map(  
	clk	=> clk,
	clk_200n=> clk_200n,
	Vref1	=> Vref1,
	Vref2	=> Vref2,
	Vref3	=> Vref3,
	PWM1	=> PWM1,
	PWM2	=> PWM2,
	PWM3	=> PWM3,
	PWM4	=> PWM4,
	PWM5	=> PWM5,
	PWM6	=> PWM6
	);
TR : block 
begin
	process (clk)
	begin
	if clk'event and clk='1' then
		CNT <= CNT+1;
		if cnt=x"20" then --go='1' then
			Vref1 <= Vref_1;
			Vref2 <= Vref_2;
			Vref3 <= Vref_3;
			CNT <=x"00";
		end if;
	end if;
	end process;
end block TR;
end step1_arch;