----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: Rajesh Panicker
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: CondLogic
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: CondLogic Module
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

entity CondLogic is port(
			CLK			: in	std_logic;
			PCS			: in	std_logic;
			RegW		: in	std_logic;
			NoWrite		: in	std_logic;
			MemW		: in	std_logic;
			FlagW		: in	std_logic_vector(1 downto 0);
			Cond		: in	std_logic_vector(3 downto 0);
			ALUFlags	: in	std_logic_vector(3 downto 0);
			PCSrc		: out	std_logic;
			RegWrite	: out	std_logic;
			MemWrite	: out	std_logic;
			ALUFlags_reverse : out std_logic_vector(3 downto 0);
			Sh_Carry_Out : in std_logic;
			Sh_WriteC : in std_logic
			);
end CondLogic;

architecture CondLogic_arch of CondLogic is
	signal CondEx		: std_logic;
	signal N, Z, C, V, prevN, prevZ, prevC, prevV	: std_logic := '0';
	signal Flags        : std_logic_vector (3 downto 0) := (others => '0');
	signal FlagWrite    : std_logic_vector (1 downto 0) := (others => '0');
	signal C_Hack      : std_logic_vector (1 downto 0) := (others => '0');
	--<extra signals, if any>
begin

--    with FlagWrite(1) select N <= 
--        ALUFlags(3) when '1',
--       prevN when others;
        
--    with FlagWrite(1) select Z <=
--        ALUFlags(3) when '1',
--        prevZ when others;
        
--    with FlagWrite(1) select Flags(3 downto 2) <=
--        ALUFlags(3 downto 2) when '1',
--        "00" when others;
        
--    with FlagWrite(0) select V <=
--        ALUFlags(0) when '1',
--        prevV when others;
        
--    C_Hack <= FlagWrite(0) & Sh_WriteC;
    
--    with C_Hack select C <=
--        ALUFlags(1) when "10",
--        ALUFlags(1) when "11",
--        Sh_Carry_Out when "01",
--        prevC when others;
        
--    with FlagWrite(0) select Flags(1 downto 0) <=
--        ALUFlags(1 downto 0) when '1',
--        "00" when others;
        

	
	process(CLK, FlagWrite, ALUFlags, Sh_WriteC, Sh_Carry_Out)
	begin	
	    if (CLK'event and CLK = '1') then 
            if FlagWrite(1) = '1' then
                Flags(3 downto 2) <= ALUFlags(3 downto 2);
                N <= ALUFlags(3);
                Z <= ALUFlags(2);
            else
                Flags(3 downto 2) <= "00"; -- gut feeling
--                N <= prevN; -- L
--                Z <= prevZ; -- L
            end if;
           
            if FlagWrite(0) = '1' then
                Flags(1 downto 0) <= ALUFlags(1 downto 0);
                C <= ALUFlags(1);
                V <= ALUFlags(0);
            else
                Flags(1 downto 0) <= "00"; -- gut feeling
                if Sh_WriteC = '1' then
                    C <= Sh_Carry_Out;
                else    
--                    C <= prevC; -- L
                end if;
--                V <= prevV; --L
            end if;
            
            prevC <= C;
            prevZ <= Z;
            prevN <= N;
            prevV <= V;
            
            --N <= Flags(3);
            --Z <= Flags(2);
            --C <= Flags(1);
            --V <= Flags(0);
        end if;
    
    end process;
	
	ALUFlags_reverse(3) <= N;
	ALUFlags_reverse(2) <= Z;
	ALUFlags_reverse(1) <= C;
	ALUFlags_reverse(0) <= V;
	
	
	
	PCSrc <= PCS and CondEx;
    RegWrite <= RegW and CondEx;
    MemWrite <= MemW and CondEx;
    FlagWrite(0) <= FlagW(0) and CondEx;
    FlagWrite(1) <= FlagW(1) and CondEx;
    
	
	with Cond select CondEx <= 	Z						when "0000",	-- EQ
								not Z					when "0001",	-- NE
								C						when "0010",	-- CS / HS
								not C					when "0011",	-- CC / LO
								N						when "0100",	-- MI
								not N					when "0101",	-- PL
								V						when "0110",	-- VS
								not V					when "0111",	-- VC									
								not Z and C				when "1000",	-- HI
								Z or not C				when "1001",	-- LS
								N xnor V				when "1010",	-- GE
								N xor V					when "1011",	-- LT
								not Z and (N xnor V)	when "1100", 	-- GT
								Z or (N xor V)			when "1101",	-- LE
								'1'						when "1110",	-- AL
								'-'						when others;	-- unpredictable
								
    
    
end CondLogic_arch;