----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: Rajesh Panicker
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: ALU
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: ALU Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) do not post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) bear responsibility for any and all legal issues arising from the use of this code without proper permission from ARM;
--		(iv) accept that the program "as is" without warranty of any kind of assurance regarding its suitability for any particular purpose;
--		(v)	acknowledge that the program was written loosely based on the microarchitecture described in the book Digital Design and Computer Architecture, ARM Edition by Harris and Harris;
--		(vi) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vii) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is port(
			Src_A		: in 	std_logic_vector(31 downto 0);
			Src_B		: in 	std_logic_vector(31 downto 0);
			ALUControl	: in	std_logic_vector(3 downto 0);
			ALUResult	: out 	std_logic_vector(31 downto 0);
			ALUFlags	: out 	std_logic_vector(3 downto 0);
    	   ALUFlags_reverse : in std_logic_vector (3 downto 0);
    	   Sh_WriteC : out std_logic
			);
end ALU;


architecture ALU_arch of ALU is
	signal S_wider 		: std_logic_vector(32 downto 0);
	signal Src_A_comp	: std_logic_vector(32 downto 0);
	signal Src_B_comp	: std_logic_vector(32 downto 0);
	signal ALUResult_i	: std_logic_vector(31 downto 0);
	signal C_0			: std_logic_vector(32 downto 0);
	signal N, Z, C, V  	: std_logic;
begin
	S_wider <= std_logic_vector( unsigned(Src_A_comp) + unsigned(Src_B_comp) + unsigned(C_0) );
	process(Src_A, Src_B, ALUControl, S_wider, ALUFlags_reverse)
	begin
	    C_0 <= (others => '0'); -- default value, will help avoid latches
	    Src_A_comp <= '0' & Src_A; 
        Src_B_comp <= '0' & Src_B; 
        ALUResult_i <= Src_B; 
        V <= '0';
        Sh_WriteC <= '0';
		case ALUControl is
                when "0000" =>
                    --AND A4-8
                    ALUResult_i <= Src_A and Src_B;
                when "0001" =>
                    --XOR / EOR A4-26
                    ALUResult_i <= Src_A xor Src_B;
                    Sh_WriteC <= '1';
                when "0010" =>
                    --SUB A4-98
                    C_0(0) <= '1';
                    Src_B_comp <= not ('0' & Src_B);
                    ALUResult_i <= S_wider(31 downto 0);
                    V <= ( Src_A(31) xor  Src_B(31) )  and ( Src_B(31) xnor S_wider(31) );
                when "0011" =>
                    --RSB A4-72
                    C_0(0) <= '1';
                    Src_A_comp <= not ('0' & Src_A);
                    ALUResult_i <= S_wider(31 downto 0);
                    V <= ( Src_A(31) xor  Src_B(31) )  and ( Src_A(31) xnor S_wider(31) );
                when "0100" =>
                    --ADD A4-6
                    ALUResult_i <= S_wider(31 downto 0);
                    V <= ( Src_A(31) xnor  Src_B(31) )  and ( Src_B(31) xor S_wider(31) );
                when "0101" =>
                    --ADC A4-4
                    -- need to implement this later
                    --C_0(0) <= C;
                    C_0(0) <= ALUFlags_reverse(1);
                    ALUResult_i <= S_wider(31 downto 0);
                    V <= ( Src_A(31) xnor  Src_B(31) )  and ( Src_B(31) xor S_wider(31) );
                when "0110" =>
                    --SBC A4-76
                    -- need to implement this later
                    --if (ALUFlags_reverse(1) = 0) then
                    --    C_0 <= (others <= '0');
                    --else
                    --    C_0(0) <= '1';
                    --    C_0(32 downto 1) <= (others => '0');
                    --end if;
                    
                    C_0(0) <= ALUFlags_reverse(1);
                    C_0(32 downto 1) <= (others => '0');
                    
                    Src_B_comp <= not ('0' & Src_B);
                    ALUResult_i <= S_wider(31 downto 0);
                    V <= ( Src_A(31) xor  Src_B(31) )  and ( Src_B(31) xnor S_wider(31) );
                when "0111" =>
                    --RSC A4-74
                    --C_0 <= (others => not ALUFlags_reverse(1));
                    C_0(0) <= ALUFlags_reverse(1);
                    C_0(32 downto 1) <= (others => '0');
                                        
                    Src_A_comp <= not ('0' & Src_A);
                    ALUResult_i <= S_wider(31 downto 0);
                    V <= ( Src_A(31) xor  Src_B(31) )  and ( Src_A(31) xnor S_wider(31) );
                when "1000" =>
                    --TST A4-107
                    -- c flag <= shifter carry out
                    ALUResult_i <= Src_A and Src_B;
                    Sh_WriteC <= '1';
                when "1001" =>
                    --TEQ A4-106
                    -- c flag <= shifter carry out
                    ALUResult_i <= Src_A xor Src_B;
                    Sh_WriteC <= '1';
                when "1010" =>
                    --CMP A4-25
                    C_0(0) <= '1';
                    Src_B_comp <= not ('0' & Src_B);
                    ALUResult_i <= S_wider(31 downto 0);
                    V <= ( Src_A(31) xor  Src_B(31) )  and ( Src_B(31) xnor S_wider(31) );
                when "1011" =>
                    --CMN A4-23
                    ALUResult_i <= S_wider(31 downto 0);
                    V <= ( Src_A(31) xnor  Src_B(31) )  and ( Src_B(31) xor S_wider(31) );
                when "1100" =>
                    --ORR A4-70
                    ALUResult_i <= Src_A or Src_B;
                    Sh_WriteC <= '1';
                when "1101" =>
                    --MOV A4-56
                    ALUResult_i <= Src_B;
                    Sh_WriteC <= '1';
                when "1110" =>
                    --BIC A4-12
                    ALUResult_i <= Src_A and not Src_B;
                    Sh_WriteC <= '1';
                when "1111" =>
                    --MVN A4-68
                    ALUResult_i <= not Src_B;
                    Sh_WriteC <= '1';
                when others =>
                    --SHOULD NOT ENTER THIS
                    ALUResult_i <= (others => '0');
                    
			--when "00" =>
			    --ADD
				--ALUResult_i <= S_wider(31 downto 0);
				--V <= ( Src_A(31) xnor  Src_B(31) )  and ( Src_B(31) xor S_wider(31) );
			--when "01" =>
			    --SUBTRACT
				--C_0(0) <= '1';
                --Src_B_comp <= not ('0' & Src_B);
                --ALUResult_i <= S_wider(31 downto 0);
                --V <= ( Src_A(31) xor  Src_B(31) )  and ( Src_B(31) xnor S_wider(31) );
			--when "10" =>
			    -- LOGICAL AND
				--ALUResult_i <= Src_A and Src_B;
			--when others =>
			    -- LOGICAL OR
				--ALUResult_i <= Src_A or Src_B;
		end case;
	end process;
	N <= ALUResult_i(31);
	Z <= '1' when ALUResult_i = x"00000000" else '0';
	C <= S_wider(32);
	ALUResult <= ALUResult_i;
	ALUFlags <= N & Z & C & V;
end ALU_arch;			