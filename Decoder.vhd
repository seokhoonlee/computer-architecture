----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: Rajesh Panicker
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: Decoder
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: Decoder Module
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

entity Decoder is port(
			Rd			: in 	std_logic_vector(3 downto 0);
			Op			: in 	std_logic_vector(1 downto 0);
			Funct		: in 	std_logic_vector(5 downto 0);
			PCS			: out	std_logic;
			RegW		: out	std_logic;
			MemW		: out	std_logic;
			MemtoReg	: out	std_logic;
			ALUSrc		: out	std_logic;
			ImmSrc		: out	std_logic_vector(1 downto 0);
			RegSrc		: out	std_logic_vector(1 downto 0);
			NoWrite		: out	std_logic;
			ALUControl	: out	std_logic_vector(3 downto 0);
			FlagW		: out	std_logic_vector(1 downto 0)
			);
end Decoder;

architecture Decoder_arch of Decoder is
	signal ALUOp 			: std_logic;
	signal Branch 			: std_logic;
	signal RegW_sig         : std_logic;
	--<extra signals, if any>
begin
    -- Op is set by instr bits 27:26
    -- Funct 5:0 is [I 1-bit] [OpCode 4-bits] [S 1-bit] // Only for DPI
        -- I => Immediate or Shifter (register) Operand
        -- S => Update Condition Codes
    process(Op, Funct)
    begin
        if Op = "00" and Funct(5) = '0' then
            -- Data Processing Instructions with Shifter Operand
            Branch <= '0';
            MemtoReg <= '0';
            MemW <= '0';
            ALUSrc <= '0';
            ImmSrc <= "--";
            RegW_sig <= '1';
            RegSrc <= "00";
            ALUOp <= '1';
            --ALUOp(0) <= '1';
        elsif Op = "00" and Funct(5) = '1' then
            -- Data Processing Instructions with Register Operand
            Branch <= '0';
            MemtoReg <= '0';
            MemW <= '0';
            ALUSrc <= '1';
            ImmSrc <= "00";
            RegW_sig <= '1';
            RegSrc <= "-0";
            ALUOp <= '1';
            --ALUOp(0) <= '1';
        elsif Op = "01" and Funct(0) = '0' then
            -- Load Store Instructions with no Condition Update
            Branch <= '0';
            MemtoReg <= '-';
            MemW <= '1';
            ALUSrc <= '1';
            ImmSrc <= "01";
            RegW_sig <= '0';
            RegSrc <= "10";
            ALUOp <= '0';
            --ALUOp(0) <= '0';
        elsif Op = "01" and Funct(0) = '1' then
            -- Load Store Instructions with Condition Update
            Branch <= '0';
            MemtoReg <= '1';
            MemW <= '0';
            ALUSrc <= '1';
            ImmSrc <= "01";
            RegW_sig <= '1';
            RegSrc <= "-0";
            ALUOp <= '0';
            --ALUOp(0) <= '0';
        elsif Op = "10" then
            -- Branch/ Load Store Multiple Instructions
            Branch <= '1';
            MemtoReg <= '0';
            MemW <= '0';
            ALUSrc <= '1';
            ImmSrc <= "10";
            RegW_sig <= '0';
            RegSrc <= "-1";
            ALUOp <= '0';
            --ALUOp(0) <= '0';
        else
            -- Op = "11"
            -- Exception Generating Instructions
            Branch <= '-';
            MemtoReg <= '-';
            MemW <= '-';
            ALUSrc <= '-';
            ImmSrc <= "--";
            RegW_sig <= '-';
            RegSrc <= "--";
            ALUOp <= '-';
            ---ALUOp(0) <= '-';
        end if;
        
        --if funct(3) = '1' then
        --    ALUOp(1) <= '1';
        --else
        --    ALUOp(1) <= '0';
        --end if;
    end process;
    
    process(ALUOp, Funct)
    begin
    
    -- This section deals with outputs for decoder, namely FlagW, NoWrite and ALUControl
    -- FlagW
        -- Ends up in CondLogic, sets NZCV flags from ALUFlags accordingly (page 46)
    -- NoWrite
        -- Ends up in CondLogic, tells RegWrite to not update reg with result from ALU
    -- ALUControl
        -- Simple, this controls what instruction is executed in the ALU
        
        if ALUOp = '0' then
            if Funct(3) = '0' then
                --Negative immediate offset (substract)
                ALUControl <= "0010";
            else
                --Positive immediate offset (addition)
                ALUControl <= "0100";
            end if;
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "00000" then
            -- AND w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "00001" then
            -- AND w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "10";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "00010" then
            -- XOR w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "00011" then
            -- XOR w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "10";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "00100" then
            -- SUB w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "00101" then
            -- SUB w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "11";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "00110" then
            -- RSB w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "00111" then
            -- RSB w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "11";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "01000" then
            -- ADD w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "01001" then
            -- ADD w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "11";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "01010" then
            -- ADC w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "01011" then
            -- ADC w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "11";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "01100" then
            -- SBC w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "01101" then
            -- SBC w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "11";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "01110" then
            -- RSC w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "01111" then
            -- RSC w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "11";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "10000" then
            -- TST w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '1';
        elsif ALUOp = '1' and Funct(4 downto 0) = "10001" then
            -- TST w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "10";
            NoWrite <= '1';
        elsif ALUOp = '1' and Funct(4 downto 0) = "10010" then
            -- TEQ w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '1';
        elsif ALUOp = '1' and Funct(4 downto 0) = "10011" then
            -- TEQ w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "10";
            NoWrite <= '1';
        elsif ALUOp = '1' and Funct(4 downto 0) = "10100" then
            -- CMP w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '1';
        elsif ALUOp = '1' and Funct(4 downto 0) = "10101" then
            -- CMP w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "11";
            NoWrite <= '1';
        elsif ALUOp = '1' and Funct(4 downto 0) = "10110" then
            -- CMN w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '1';
        elsif ALUOp = '1' and Funct(4 downto 0) = "10111" then
            -- CMN w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "11";
            NoWrite <= '1';
        elsif ALUOp = '1' and Funct(4 downto 0) = "11000" then
            -- ORR w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "11001" then
            -- ORR w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "10";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "11010" then
            -- MOV w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "11011" then
            -- MOV w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "10";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "11100" then
            -- BIC w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "11101" then
            -- BIC w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "10";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "11110" then
            -- MVN w/o update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "00";
            NoWrite <= '0';
        elsif ALUOp = '1' and Funct(4 downto 0) = "11111" then
            -- MVN w/ update
            ALUControl <= Funct(4 downto 1);
            FlagW <= "10";
            NoWrite <= '0';            
        else
            -- LDR and STR are non ALU Operations, should have been caught in the first condition.
            ALUControl <= Funct(4 downto 1);
            FlagW <= "--";
            NoWrite <= '-';
        end if;
        
    end process;
    
    process(Rd, Branch, RegW_sig)
    begin
        if (Rd = "1111" and RegW_sig = '1') or Branch = '1' then
            PCS <= '1';
        else
            PCS <= '0';
        end if;
    end process;
    
    RegW <= RegW_sig;

end Decoder_arch;