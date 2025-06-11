library IEEE;
library lpm;
use lpm.lpm_components.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use IEEE.numeric_std.all;
entity SVPWM1 is
port(  
	clk,clk_200n				: in   STD_LOGIC:='0';
	Vref1,Vref2,Vref3			: in  STD_LOGIC_VECTOR (23 downto 0):=(others =>'0');
	PWM1,PWM2,PWM3,PWM4,PWM5,PWM6		: out  STD_LOGIC:='0'
	);
end svpwm1;
architecture svpwm_ARCH of SVPWM1 is
--Bien
signal TTA,TTB,T_sum				: STD_LOGIC_VECTOR(23 downto 0):=(others =>'0');
signal num,den,sat				: STD_LOGIC_VECTOR(23 downto 0):=(others =>'0');
signal T1,T2					: STD_LOGIC_VECTOR(11 downto 0):=(others =>'0');
signal TAA,TBB         				: STD_LOGIC_VECTOR(11 downto 0):=(others =>'0');
signal TX,TY,TZ					: STD_LOGIC_VECTOR(11 downto 0):=(others =>'0');
signal TAM					: STD_LOGIC_VECTOR(11 downto 0):=(others =>'0');
signal TAO,TBO,TCO				: STD_LOGIC_VECTOR(11 downto 0):=(others =>'0');
signal CMPR1,CMPR2,CMPR3			: STD_LOGIC_VECTOR(11 downto 0):=(others =>'0');
signal CMPAA,CMPBB,CMPCC			: STD_LOGIC_VECTOR(11 downto 0):=(others =>'0');
signal CNT              			: STD_LOGIC_VECTOR(7 downto 0):=(others =>'0'); 
signal PWMEA_1,PWMEA_2,PWMEB_1   		: STD_LOGIC:='0';
signal PWMEB_2, PWMEC_1,PWMEC_2  		: STD_LOGIC:='0';
signal mula, mulb 				: STD_LOGIC_VECTOR(23 downto 0):=(others => '0');
signal mulr 					: STD_LOGIC_VECTOR(47 downto 0):=(others => '0');
--Hang so
signal Vdc_INV					: STD_LOGIC_VECTOR(23 downto 0):=X"00DA74"; -- 1/150 V
signal T					: STD_LOGIC_VECTOR(23 downto 0):=X"3A9800"; -- 1875 -13.333kHz or T = 1250 - 271000 - 20kHz 
signal K					: STD_LOGIC_VECTOR(23 downto 0);
signal T_INT					: STD_LOGIC_VECTOR(23 downto 0):=(others =>'0');
begin
---------------------------------------------------------------------------------------A-------
m0 : lpm_divide----------divide component
GENERIC MAP (LPM_WIDTHN=>24, LPM_WIDTHD =>24, LPM_PIPELINE=>1,LPM_NREPRESENTATION =>"SIGNED", LPM_DREPRESENTATION =>"SIGNED")
port map (numer=>num,denom=>den,clock=>clk,quotient=>sat);
mull: lpm_mult ----------mull component
generic map(LPM_WIDTHA=>24,LPM_WIDTHB=>24,LPM_WIDTHS=>24,LPM_WIDTHP=>48,LPM_REPRESENTATION=>"SIGNED",LPM_PIPELINE=>1)
port map(dataa=> mula,datab=> mulb,clock=> clk,result=> mulr); 
----------------------------------------------------------------------------------------------
state : block
signal SECT: STD_LOGIC_VECTOR(2 downto 0):=(others =>'0');
begin
process (clk,sect)
begin
T_INT <= X"00"&B"000"&T(23 downto 11);
------------------------------------------
if clk'event and clk='1' then
	CNT<=CNT+1;
if CNT=x"00" then ---------------------------------step 1  (identify section)
	SECT  <= not (Vref3(23) & Vref2(23) & Vref1(23) );--(S=a+2b+4c) NOT DE DOI DAU.
elsif CNT=x"01" then------------------------------step 2  
	mula <= T; --24Q11
	mulb <= X"6ED9EB"; --sqrt(3) 24Q22
elsif CNT=x"03" then
	mula <= mulr (45 downto 22);--24Q11
	mulb <= Vdc_INV; --24Q23
elsif CNT=x"05" then
	K <= mulr (46 downto 23);--24Q11
elsif CNT=x"07" then
	mula <= K;
	mulb <=  Vref1; --24Q11
elsif CNT=x"09" then
	TX <= mulr (33 downto 22); --lay nguyen
	mula <= K;
	mulb <=  -Vref3; -- 24Q11
elsif CNT=x"0B" then
	TY <= mulr (33 downto 22); --lay nguyen 
	mula <=K;	--24Q11	
	mulb <=  -Vref2;--24Q11
elsif CNT=x"0D" then
	TZ <= mulr (33 downto 22); -- lay nguyen 
ELSIF CNT=x"0F" THEN

case SECT is
when "011" =>    --S3--
	T1  <=  -TZ;
	T2  <=  TX;
when "001" =>    --S1--
	T1  <=  TZ;
	T2  <=  TY;
when "101" =>    --S5--
	T1  <=  TX;
	T2  <=  -TY;
when "100" =>    --S4--
	T1  <=  -TX;
	T2  <=  TZ;
when "110" =>    --S6--
	T1  <=  -TY;
	T2  <=  -TZ;
when "010" =>    --S2--
	T1  <=  TY;
	T2  <=  -TX;
when others =>
	T1  <=  T1;  
	T2  <=  T2;  
end case;

elsif CNT=x"11" then---------------------------step 3-2  (saturation test) 

	T_sum <= X"000"&(T1 + T2);

	if T_sum>= T_INT then --X"410 = 2.4KHz"  (61a = 1.6KHz)    
		TTA <=T1*T_INT(11 downto 0);
		TTB <=T2*T_INT(11 downto 0);
	else
		TAA <=T1;
		TBB <=T2;
	end if;
elsif CNT=x"13" then --------------------------step 3-3  (saturation condition)
	if T_sum>= T_INT then        
		num <=TTA;
		den <=T_sum;
	end if;   
elsif CNT=x"15" then---------------------------step 3-4
	if T_sum>= T_INT then 
		TAA <= sat(11 downto 0);
	end if;   
elsif CNT=x"17" then---------------------------step 3-5
	if T_sum>= T_INT then 
		num <=TTB;
		den <=T_sum;
	end if;   
elsif CNT=x"19" then---------------------------step 3-6
	if T_sum>= T_INT then 
		TBB <= sat (11 downto 0);
	end if;   
elsif CNT=x"1A" then---------------------------step 4-1 (Taon, Tbon and Tcon)
	TAM  <= T_INT(11 downto 0) -TAA -TBB;    
elsif CNT=x"1B" then---------------------------step 4-2
	TAO  <= '0' & TAM(11 downto 1);  --(T-T1-T2)/2
elsif CNT=x"1C" then---------------------------step 4-3
	TBO  <= TAO + TAA;
elsif CNT=x"1D" then---------------------------step 4-4
	TCO  <= TBO + TBB;        
elsif CNT=x"1E" then--------step 5

case SECT is
	when "011" =>	--S3--
		CMPR1  <= TAO;
		CMPR2  <= TBO;
		CMPR3  <= TCO;                       
	when "001" =>	--S1--
		CMPR1  <= TBO;
		CMPR2  <= TAO;
		CMPR3  <= TCO;                            
	when "101" =>	--S5--
		CMPR1  <= TCO;
		CMPR2  <= TAO;
		CMPR3  <= TBO;                          
	when "100" =>	--S4--
		CMPR1  <= TCO;
		CMPR2  <= TBO;
		CMPR3  <= TAO;                           
	when "110" =>	--S6--
		CMPR1  <= TBO;
		CMPR2  <= TCO;
		CMPR3  <= TAO;                             
	when "010" =>	--S2--
		CMPR1  <= TAO;
		CMPR2  <= TCO;
		CMPR3  <= TBO;                          
	when others =>                      
		CMPR1  <= CMPR1;
		CMPR2  <= CMPR2;
		CMPR3  <= CMPR3;  
end case;
----------------------------------
	CNT <=x"00";
end if;
end if;    
end process;
end block state;

pwm_counter: block
signal D  : STD_LOGIC:='0';
signal Q  : STD_LOGIC_VECTOR (11 downto 0):=(others =>'0');  
begin        
process (clk)
begin
if clk'event and clk='0' then  
--------------------------------------
	if D='0' then
		if Q <T_INT(11 downto 0)-1 then 
			D <= '0';
			Q <= Q+x"1";
		else
			D <= '1';
			Q <= T_INT(11 downto 0);
		end if; 
	end if; 
	if D='1' then 
		if Q > x"001" then 
			D <= '1';
			Q <= Q-x"1";          
		else
			D <= '0';
			Q <= x"000";
			CMPAA<=CMPR1; 
			CMPBB<=CMPR2;
			CMPCC<=CMPR3;
		end if;
	end if;
	
--------------------------
end if;
end process;

process (CLK)
begin
if clk'event and clk='1' then
	if Q(11 downto 0) >= CMPAA(11 downto 0) then 
		PWMEA_1 <= '1';
		PWMEA_2 <= '0'; 
	else 
		PWMEA_1 <= '0'; 
		PWMEA_2 <= '1'; 
	end if;  
	if Q(11 downto 0) >= CMPBB(11 downto 0) then 
		PWMEB_1 <= '1';
		PWMEB_2 <= '0'; 
	else 
		PWMEB_1 <= '0'; 
		PWMEB_2 <= '1'; 
	end if; 
	if Q(11 downto 0) >= CMPCC(11 downto 0) then 
		PWMEC_1 <= '1';
		PWMEC_2 <= '0'; 
	else 
		PWMEC_1 <= '0'; 
		PWMEC_2 <= '1'; 
	end if;  
end if;
end process;
end block pwm_counter;


pwm_out: block   --------dead-band of PWM 
signal DTCNT,CNTA_1,CNTA_2,CNTB_1    : STD_LOGIC_VECTOR(9 downto 0):=(others => '0');
signal CNTB_2,CNTC_1,CNTC_2           : STD_LOGIC_VECTOR(9 downto 0):=(others => '0');
   
begin
	DTCNT<="0000001010";-----dead-band setting, 5*200ns=1us 
process (clk_200n)
begin
if clk_200n'event and clk_200n='1' then  

if (PWMEA_1='1') then          
	if(CNTA_1<DTCNT)then
		CNTA_1<=CNTA_1+'1';  
		PWM1<='0';
	else
		PWM1<='1';
	end if;
else
	CNTA_1<=(others=>'0');
	PWM1<='0';
end if;
if (PWMEA_2='1') then
	if(CNTA_2<DTCNT)then
		CNTA_2<=CNTA_2 + '1';
		PWM2<='0';
	else
		PWM2<='1';
	end if;
else
	CNTA_2<=(others=>'0');
	PWM2<='0';           
end if;
if (PWMEB_1='1') then
	if(CNTB_1<DTCNT)then
		CNTB_1<=CNTB_1+'1';
		PWM3<='0';
	else
		PWM3<='1';
	end if;
else
	CNTB_1<=(others=>'0');
	PWM3<='0';
end if;       
if (PWMEB_2='1') then
	if(CNTB_2<DTCNT)then
		CNTB_2<=CNTB_2+'1';
		PWM4<='0';
	else
		PWM4<='1';
	end if;
else
	CNTB_2<=(others=>'0');
	PWM4<='0';
end if;
if (PWMEC_1='1') then
	if(CNTC_1<DTCNT)then
		CNTC_1<=CNTC_1+'1';
		PWM5<='0';
	else
		PWM5<='1';
	end if;
else
	CNTC_1<=(others=>'0');
	PWM5<='0';
end if;
if (PWMEC_2='1') then
	if(CNTC_2<DTCNT)then
		CNTC_2<=CNTC_2+'1';
		PWM6<='0';
	else
		PWM6<='1';
	end if;
else
	CNTC_2<=(others=>'0');
	PWM6<='0';
end if;
end if;
end process;
end block pwm_out;
end svpwm_arch;
