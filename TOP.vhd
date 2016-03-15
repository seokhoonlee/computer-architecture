----------------------------------------------------------------------------------
-- Company: NUS
-- Engineer: Rajesh Panicker
-- 
-- Create Date:   21:06:18 24/09/2015
-- Design Name: 	TOP (ARM Wrapper)
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool versions: Vivado 2015.2
-- Description: Top level module - wrapper for ARM processor
--
-- Dependencies: Uses uart.vhd by (c) Peter A Bennett
--
-- Revision: 
-- Revision 0.01
-- Additional Comments: See the notes below. The interface (entity) as well as implementation (architecture) can be modified
----------------------------------------------------------------------------------
--	License terms :
--	(c) Rajesh Panicker. You are free to use this code any way you wish, as long as 
-- 			(i) this copyright notice is retained in the source code;
--			(ii) you send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--			(iii) you accept that the copyright holder and/or other parties provide the program "as is" without warranty of any kind.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

----------------------------------------------------------------
-- TOP level module interface
----------------------------------------------------------------

entity TOP is
		Generic 
		(
			constant N_LEDs_OUT	: integer := 8; -- Number of LEDs displaying Result. LED(15 downto 15-N_LEDs_OUT+1). 8 by default
			-- LED(15-N_LEDs_OUT) showing the divided clock. 
			-- LED(15-N_LEDs_OUT-1 downto 0) showing the PC.
			constant N_DIPs		: integer := 16;  -- Number of DIPs. 16 by default
			constant N_PBs		: integer := 4  -- Number of PushButtons. 4 by default
			-- Order (3 downto 0) -> BTNU, BTNL, BTNR, BTND.
			-- Note that BTNC is used as PAUSE
		);
		Port 
		(
			DIP 			: in  STD_LOGIC_VECTOR (N_DIPs-1 downto 0);  -- DIP switch inputs. Not debounced.
			PB    			: in  STD_LOGIC_VECTOR (N_PBs-1 downto 0);  -- PB switch inputs. Not debounced.
			LED 			: out  STD_LOGIC_VECTOR (15 downto 0); -- LEDs.
			-- (15 downto 8) mapped to the address 0x00000C00
			-- (7) showing the divided clock
			-- (6 downto 0) showing PC(8 downto 2)
			TX 				: out STD_LOGIC;
			RX 				: in  STD_LOGIC;
			PAUSE			: in  STD_LOGIC;  -- Pause -> BTNC (Centre push button)
			RESET			: in  STD_LOGIC; 	-- Reset -> CPU_RESET (Red push button). ACTIVE LOW. Set it to '1' for simulation
			CLK_undiv		: in  STD_LOGIC 	-- 100MHz clock. Converted to a lower frequency using CLK_DIV_PROCESS before use.
		);
end TOP;


architecture arch_TOP of TOP is

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------
constant CLK_DIV_BITS	: integer := 25; --26 for a clock of the order of 1Hz. Changed in top.vhd_v2 : use (CLK_DIV_BITS of top.vhd_v2)+1. 
-- 1 for a 50MHz clock.
-- See the notes in CLK_DIV_PROCESS for SIMULATION or for obtaining a 100MHz clock frequency, 

----------------------------------------------------------------
-- ARM component declaration
----------------------------------------------------------------
component ARM is port(
			CLK			: in 	std_logic;
			RESET		: in 	std_logic;
			--Interrupt	: in	std_logic;  -- for optional future use
			Instr		: in 	std_logic_vector(31 downto 0);
			ReadData	: in 	std_logic_vector(31 downto 0);
			MemWrite	: out	std_logic;
			PC			: out	std_logic_vector(31 downto 0);
			ALUResult	: out 	std_logic_vector(31 downto 0);
			WriteData	: out 	std_logic_vector(31 downto 0)
			);
end component ARM;

----------------------------------------------------------------
-- ARM signals
----------------------------------------------------------------
signal PC 	             : STD_LOGIC_VECTOR (31 downto 0);
signal Instr 			: STD_LOGIC_VECTOR (31 downto 0);
signal ReadData			: STD_LOGIC_VECTOR (31 downto 0);
signal ALUResult		: STD_LOGIC_VECTOR (31 downto 0);
signal WriteData		: STD_LOGIC_VECTOR (31 downto 0);
signal MemWrite 		: STD_LOGIC; 

----------------------------------------------------------------
-- Others signals
----------------------------------------------------------------
signal dec_DATA_CONST, dec_DATA_VAR, dec_LED, dec_DIP, dec_CONSOLE, dec_PB : std_logic;  -- data memory address decoding
signal CLK 			: std_logic; -- divided (low freq) clock
signal RESET_EXT	: std_logic; -- effective reset

----------------------------------------------------------------
-- Memory type declaration
----------------------------------------------------------------
type MEM_128x32 is array (0 to 127) of std_logic_vector (31 downto 0); -- 128 words

----------------------------------------------------------------
-- Instruction Memory
----------------------------------------------------------------
constant INSTR_MEM : MEM_128x32 := (		x"E59FC1FC", 
											x"E59FB1F4", 
											x"E59FA1FC", 
											x"E59F0214", 
											x"E59F1214", 
											x"E2511001", 
											x"1AFFFFFD", 
											x"E59F5200", 
											x"E58B5000", 
											x"E59F21F0", 
											x"E59F31F8", 
											x"E0040392", 
											x"E58B4000", 
											x"E59F21D8", 
											x"E59F31DC", 
											x"E0040392", 
											x"E58B4000", 
											x"E59F21D0", 
											x"E59F31C4", 
											x"E0240392", 
											x"E58B4000", 
											x"E59F21B8", 
											x"E59F31BC", 
											x"E0240392", 
											x"E58B4000", 
											x"E59F21A4", 
											x"E59F31A8", 
											x"E0822FE3", 
											x"E58B2000", 
											x"E59F2194", 
											x"E59F3198", 
											x"E08220E3", 
											x"E58B2000", 
											x"E59F2184", 
											x"E59F3188", 
											x"E08221E3", 
											x"E59F2178", 
											x"E59F317C", 
											x"E09221E3", 
											x"E3B02010", 
											x"E1B022E2", 
											x"E3B02010", 
											x"E59F2160", 
											x"E59F3174", 
											x"E0022003", 
											x"E59F2154", 
											x"E59F3150", 
											x"E0222003", 
											x"E59F214C", 
											x"E59F3144", 
											x"E0422003", 
											x"E59F2140", 
											x"E59F3138", 
											x"E0622003", 
											x"E59F2144", 
											x"E59F312C", 
											x"E0922003", 
											x"E59F2138", 
											x"E59F3120", 
											x"E0A22003", 
											x"E59F211C", 
											x"E59F3114", 
											x"E0C22003", 
											x"E59F210C", 
											x"E59F310C", 
											x"E0E22003", 
											x"E59F2100", 
											x"E59F30FC", 
											x"E1120003", 
											x"E59F20F4", 
											x"E59F30F0", 
											x"E1320003", 
											x"E59F20EC", 
											x"E59F30E4", 
											x"E1520003", 
											x"E59F20E0", 
											x"E59F30E8", 
											x"E1720003", 
											x"E59F20D0", 
											x"E59F30E4", 
											x"E1822003", 
											x"E3A02008", 
											x"E59F20C0", 
											x"E59F30CC", 
											x"E1C22003", 
											x"E3A02000", 
											x"E59C1000", 
											x"E58B1000", 
											x"E58A1000", 
											x"EAFFFFFB", 
											others => x"00000000");


----------------------------------------------------------------
-- Data (Constant) Memory
----------------------------------------------------------------
constant DATA_CONST_MEM : MEM_128x32 := (	x"00000C00", 
											x"00000C04", 
											x"00000C08", 
											x"00000C0C", 
											x"00000001", 
											x"00000002", 
											x"00000004", 
											x"0000000A", 
											x"FFFFFFFF", 
											x"FFFFFFFF", 
											x"00000000", 
											x"00000004", 
											x"00000234", 
											x"6C6C6548", 
											x"6F57206F", 
											x"21646C72", 
											x"00212121", 
											others => x"00000000");


											
----------------------------------------------------------------
-- Data (Variable) Memory
----------------------------------------------------------------
signal DATA_VAR_MEM : MEM_128x32 := (others=> x"00000000");

----------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------

constant BAUD_RATE				: positive 	:= 115200;
constant CLOCK_FREQUENCY		: positive 	:= 50000000;

----------------------------------------------------------------------------
-- UART component
----------------------------------------------------------------------------
component UART is
    generic (
            BAUD_RATE           : positive;
            CLOCK_FREQUENCY     : positive
        );
    port (  -- General
            CLOCK		        : in      std_logic;
            RESET               : in      std_logic;    
            DATA_STREAM_IN      : in      std_logic_vector(7 downto 0);
            DATA_STREAM_IN_STB  : in      std_logic;
            DATA_STREAM_IN_ACK  : out     std_logic;
            DATA_STREAM_OUT     : out     std_logic_vector(7 downto 0);
            DATA_STREAM_OUT_STB : out     std_logic;
            DATA_STREAM_OUT_ACK : in      std_logic;
            TX                  : out     std_logic;
            RX                  : in      std_logic
         );
end component UART;
 

----------------------------------------------------------------------------
-- UART signals
----------------------------------------------------------------------------

signal uart_data_in             : std_logic_vector(7 downto 0);
signal uart_data_out            : std_logic_vector(7 downto 0);
signal uart_data_in_stb         : std_logic;
signal uart_data_in_ack         : std_logic;
signal uart_data_out_stb        : std_logic;
signal uart_data_out_ack        : std_logic;	 

----------------------------------------------------------------------------
-- Other UART wrapper signals
----------------------------------------------------------------------------

type states is (WAITING, CONSOLE);
signal recv_state : states := WAITING;
signal CLK_uart : std_logic;	

-- UART console related
signal CONSOLE_IN : std_logic_vector(7 downto 0);
signal CONSOLE_OUT : std_logic_vector(7 downto 0);
signal CONSOLE_send, CONSOLE_send_prev : std_logic := '0'; 
signal CONSOLE_IN_valid, CONSOLE_IN_ack: std_logic := '0';
signal uart_data_out_stb_prev: std_logic := '0'; 
signal RESET_INT, RESET_EFF : STD_LOGIC; -- internal and effective reset, for future use.

----------------------------------------------------------------	
----------------------------------------------------------------
-- <Wrapper architecture>
----------------------------------------------------------------
----------------------------------------------------------------	
		
begin

----------------------------------------------------------------
-- Debug LEDs
----------------------------------------------------------------			
LED(15-N_LEDs_OUT-1 downto 0) <= PC(15-N_LEDs_OUT+1 downto 2); -- debug showing PC
LED(15-N_LEDs_OUT) <= CLK; 		-- debug showing clock on LED(15)

----------------------------------------------------------------
-- Debug LEDs
----------------------------------------------------------------	
RESET_EXT <= not RESET; -- CPU_RESET is active low. 
RESET_EFF <= RESET_INT or RESET_EXT;
RESET_INT <= '0'; 	-- internal reset, for future use.	

----------------------------------------------------------------
-- ARM port map
----------------------------------------------------------------
ARM1 : ARM port map ( 
			CLK         =>  CLK,
			RESET		=>	RESET_EFF,  
			--Interrupt	=> 	Interrupt,
			Instr 		=>  Instr,
			ReadData	=>  ReadData,
			MemWrite 	=>  MemWrite,
			PC          =>  PC,
			ALUResult   =>  ALUResult,			
			WriteData	=>  WriteData					
			);

----------------------------------------------------------------------------
-- UART port map
----------------------------------------------------------------------------
UART1 : UART
generic map (
		BAUD_RATE           => BAUD_RATE,
		CLOCK_FREQUENCY     => CLOCK_FREQUENCY
)
port map (  
		CLOCK		        => CLK_uart,
		RESET               => RESET_EXT,
		DATA_STREAM_IN      => uart_data_in,
		DATA_STREAM_IN_STB  => uart_data_in_stb,
		DATA_STREAM_IN_ACK  => uart_data_in_ack,
		DATA_STREAM_OUT     => uart_data_out,
		DATA_STREAM_OUT_STB => uart_data_out_stb,
		DATA_STREAM_OUT_ACK => uart_data_out_ack,
		TX                  => TX,
		RX                  => RX
);

----------------------------------------------------------------
-- Data memory address decoding
----------------------------------------------------------------
dec_DATA_CONST  <= '1' 	when ALUResult>=x"00000200" and ALUResult<=x"000003FC" else '0';
dec_DATA_VAR    <= '1' 	when ALUResult>=x"00000800" and ALUResult<=x"000009FC" else '0';
dec_LED 		<= '1'	when ALUResult=x"00000C00" else '0';
dec_DIP 		<= '1' 	when ALUResult=x"00000C04" else '0';
dec_PB 		    <= '1'	when ALUResult=x"00000C08" else '0';
dec_CONSOLE	    <= '1' 	when ALUResult=x"00000C0C" else '0';

----------------------------------------------------------------
-- Data memory read
----------------------------------------------------------------
ReadData 	<= (31-N_DIPs downto 0 => '0') & DIP						when dec_DIP = '1' 
                else (31-N_PBs downto 0 => '0') & PB						    when dec_PB = '1' 
				else DATA_VAR_MEM(conv_integer(ALUResult(8 downto 2)))	when dec_DATA_VAR = '1'
				else DATA_CONST_MEM(conv_integer(ALUResult(8 downto 2)))when dec_DATA_CONST = '1'
				else x"000000" & CONSOLE_IN 							when dec_CONSOLE = '1' and CONSOLE_IN_valid = '1'
				else (others=>'-');
				
----------------------------------------------------------------
-- Instruction memory read
----------------------------------------------------------------
Instr <= INSTR_MEM(conv_integer(PC(8 downto 2))) 
			when PC>=x"00000000" and PC<=x"000001FC" -- To check if address is in the valid range, assuming 128 word memory. Also helps minimize warnings
			else x"00000000";

----------------------------------------------------------------
-- Console write; read ack3
----------------------------------------------------------------

write_CONSOLE_n_ack: process (CLK)
begin
	if CLK'event and CLK = '1' then
		CONSOLE_send <= '0';
		CONSOLE_IN_ack <= '0'; 
		if MemWrite = '1' and dec_CONSOLE = '1' then
			CONSOLE_OUT <= WriteData(7 downto 0);
			CONSOLE_send <= '1';
		end if;
		if dec_CONSOLE = '1' then
			CONSOLE_IN_ack <= '1';
		end if;			
	end if;
end process;

UART_wrapper: process (CLK_uart)
begin
if CLK_uart'event and CLK_uart = '1' then

   if RESET_EXT = '1' then
		uart_data_in_stb        <= '0';
      uart_data_out_ack       <= '0';
      uart_data_in            <= (others => '0');
		recv_state			  <= WAITING;
		uart_data_out_stb_prev <= '0';
   else
		---------------------
		-- Sending
		---------------------
		uart_data_out_ack <= '0';
		if CONSOLE_send = '1' and CONSOLE_send_prev = '0' then -- uart_data_in_ack ensure the next character is sent only if the previous character has been sent.
			uart_data_in <= CONSOLE_OUT; -- to do : write only if uart_data_in_ack is received
			uart_data_in_stb <= '1';
		end if;
		CONSOLE_send_prev <= CONSOLE_send;
		if uart_data_in_ack = '1' then
			uart_data_in_stb    <= '0';
		end if;
		---------------------
		-- Receiving
		---------------------
		case recv_state is 
		when WAITING =>
			if uart_data_out_stb = '1' and uart_data_out_stb_prev = '0' then
				uart_data_out_ack   <= '1';
				recv_state <= CONSOLE;	
				CONSOLE_IN <= uart_data_out;
				CONSOLE_IN_valid <= '1';
			end if;
			
		when CONSOLE =>	
			if uart_data_out_stb = '1' and uart_data_out_stb_prev = '0' then -- just read and ignore further characters before the current valid character is read.
				uart_data_out_ack   <= '1';
			end if;
			if CONSOLE_IN_ack = '1' then
				recv_state <= WAITING;
				CONSOLE_IN_valid <= '0';
			end if;	
			
		end case; 			
		uart_data_out_stb_prev <= uart_data_out_stb;
	end if;
end if;
end process;				

----------------------------------------------------------------
-- Receive state for debug
----------------------------------------------------------------
--state_indicator : process(recv_state)
--begin
--	case recv_state is
--		when WAITING 		=> 	LED(15) <= "0";
--		when CONSOLE	 	=> 	LED(15) <= "1";
--	end case;
--end process;
--
--LED(14 downto 8) <= (others => '0');

----------------------------------------------------------------
-- Data Memory-mapped LED write
----------------------------------------------------------------
write_LED: process (CLK)
begin
	if CLK'event and CLK = '1' then
		if RESET_EXT = '1' then
			LED(15 downto 15-N_LEDs_OUT+1) <= (others=> '0');
		elsif MemWrite = '1' and  dec_LED = '1' then
			LED(15 downto 15-N_LEDs_OUT+1) <= WriteData(N_LEDs_OUT-1 downto 0);
		end if;
	end if;
end process;

----------------------------------------------------------------
-- Data Memory write
----------------------------------------------------------------
write_DATA_VAR_MEM: process (CLK)
begin
    if CLK'event and CLK = '1' then
        if MemWrite = '1' and dec_DATA_VAR = '1' then
            DATA_VAR_MEM(conv_integer(ALUResult(8 downto 2))) <= WriteData;
        end if;
    end if;
end process;

----------------------------------------------------------------
-- Clock divider
----------------------------------------------------------------
-- CLK <= CLK_undiv 
-- CLK_uart <= CLK_undiv;
-- IMPORTANT : >>> uncomment the previous lines and comment out the rest of the process
--			   >>> for obtaining a 100MHz clock frequency. Make sure CLOCK_FREQUENCY is set to 100000000
CLK_DIV_PROCESS : process(CLK_undiv)
variable clk_counter : std_logic_vector(CLK_DIV_BITS-1 downto 0) := (others => '0');
begin
	if CLK_undiv'event and CLK_undiv = '1' then
		if PAUSE = '0' then
			clk_counter := clk_counter+1;
			CLK <= clk_counter(CLK_DIV_BITS-1);
			CLK_uart <= clk_counter(0);
		end if;
	end if;
end process;

end arch_TOP;

----------------------------------------------------------------	
----------------------------------------------------------------
-- </Wrapper architecture>
----------------------------------------------------------------
----------------------------------------------------------------	
