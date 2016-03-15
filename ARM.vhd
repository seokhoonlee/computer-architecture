----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: Rajesh Panicker
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: ARM
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: ARM Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: The interface (entity) SHOULD NOT be modified. The implementation (architecture) can be modified
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) do not post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) bear responsibility for any and all legal issues arising from the use of this code without proper permission from ARM;
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v)	acknowledge that the program was written loosely based on the microarchitecture described in the book Digital Design and Computer Architecture, ARM Edition by Harris and Harris;
--		(vi) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vii) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------

-- R15 is not stored
-- Save waveform file and add it to the project
-- Reset and launch simulation if you add interal signals to the waveform window



-- __          ___           _      _____                                _____          _      
--  \ \        / / |         | |    / ____|                              / ____|        | |     
--   \ \  /\  / /| |__   __ _| |_  | |     _ __ __ _ _ __  _ __  _   _  | |     ___   __| | ___ 
--    \ \/  \/ / | '_ \ / _` | __| | |    | '__/ _` | '_ \| '_ \| | | | | |    / _ \ / _` |/ _ \
--     \  /\  /  | | | | (_| | |_  | |____| | | (_| | |_) | |_) | |_| | | |___| (_) | (_| |  __/
--      \/  \/   |_| |_|\__,_|\__|  \_____|_|  \__,_| .__/| .__/ \__, |  \_____\___/ \__,_|\___|
--                                                  | |   | |     __/ |                         
--                                                  |_|   |_|    |___/                          



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ARM is 
generic (width 	: integer := 32); -- Keep this at 4 to verify your algorithms with 4 bit numbers (easier). When using MCycle as a component in ARM (Lab 4), generic map it to 32.

port(
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
end ARM;

architecture ARM_arch of ARM is

component RegFile is port(
			CLK			: in	std_logic;
			WE3			: in	std_logic;
			A1			: in	std_logic_vector(3 downto 0);
			A2			: in	std_logic_vector(3 downto 0);
			A3			: in	std_logic_vector(3 downto 0);
			A4_Sh       : in    std_logic_vector(3 downto 0);
			WD3			: in	std_logic_vector(31 downto 0);
			R15			: in 	std_logic_vector(31 downto 0);
			RD1			: out	std_logic_vector(31 downto 0);
			RD2			: out	std_logic_vector(31 downto 0);
			RD3_Sh      : out   std_logic_vector(31 downto 0)
			);
end component RegFile;			

component Extend is port(
			ImmSrc		: in	std_logic_vector(1 downto 0);
			InstrImm		: in	std_logic_vector(23 downto 0);
			ExtImm		: out	std_logic_vector(31 downto 0)
			);
end component Extend;

component Decoder is port(
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
end component Decoder;

component CondLogic is port(
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
			ALUFlags_reverse : out std_logic_vector (3 downto 0); -- added
			Sh_Carry_Out : in std_logic;
            Sh_WriteC : in std_logic
			);
end component CondLogic;

component Shifter is port(
			Sh			: in	std_logic_vector(1 downto 0); 
			Shamt5		: in	std_logic_vector(4 downto 0);
			ShIn		: in	std_logic_vector(31 downto 0);
			ShOut		: out	std_logic_vector(31 downto 0)		
			);
end component Shifter;
								

component ALU is port(
			Src_A		: in 	std_logic_vector(31 downto 0);
			Src_B		: in 	std_logic_vector(31 downto 0);
			ALUControl	: in	std_logic_vector(3 downto 0);
			ALUResult	: out 	std_logic_vector(31 downto 0);
			ALUFlags	: out 	std_logic_vector(3 downto 0);
			ALUFlags_reverse : in std_logic_vector (3 downto 0); -- added
			Sh_WriteC : out std_logic
			);
end component ALU;
			
component ProgramCounter is port(
			CLK			: in	std_logic;
			RESET		: in 	std_logic;
			WE_PC		: in	std_logic; -- write enable
			PC_IN		: in	std_logic_vector(31 downto 0);
			PC			: out	std_logic_vector(31 downto 0)
			);
end component ProgramCounter;

component MCycle is port(
        CLK		: in	STD_LOGIC;
		RESET		: in 	STD_LOGIC;  -- Connect this to the reset of the ARM processor (Lab 4).
		Start		: in 	STD_LOGIC;  -- Multi-cycle Enable. The control unit should assert this when an instruction with a multi-cycle operation is detected.
		MCycleOp	: in	STD_LOGIC_VECTOR (1 downto 0); -- Multi-cycle Operation. "00" for signed multiplication, "01" for unsigned multiplication, "10" for signed division, "11" for unsigned division.
		Operand1	: in	STD_LOGIC_VECTOR (width-1 downto 0); -- Multiplicand / Dividend
		Operand2	: in	STD_LOGIC_VECTOR (width-1 downto 0); -- Multiplier / Divisor
		Result1	: out	STD_LOGIC_VECTOR (width-1 downto 0); -- LSW of Product / Quotient
		Result2	: out	STD_LOGIC_VECTOR (width-1 downto 0); -- MSW of Product / Remainder
		Busy		: out	STD_LOGIC
		);  -- Set immediately when Start is set. Cleared when the Results become ready. This bit can be used to stall the processor while multi-cycle operations are on (Lab 4).
end component MCycle;

-- RegFile signals
-- signal CLK		: 	std_logic; 
signal WE3			: 	std_logic;
signal A1			: 	std_logic_vector(3 downto 0); 
signal A2			: 	std_logic_vector(3 downto 0); 
signal A3			: 	std_logic_vector(3 downto 0); 
signal WD3			: 	std_logic_vector(31 downto 0); 
signal R15			: 	std_logic_vector(31 downto 0); 
signal RD1			: 	std_logic_vector(31 downto 0); 
signal RD2			: 	std_logic_vector(31 downto 0);
           
-- Extend signals
signal ImmSrc		:	std_logic_vector(1 downto 0);
signal InstrImm	:	std_logic_vector(23 downto 0);
signal ExtImm		:	std_logic_vector(31 downto 0);

-- Decoder signals
signal Rd			:	std_logic_vector(3 downto 0);
signal Op			:	std_logic_vector(1 downto 0);
signal Funct		:	std_logic_vector(5 downto 0);
-- signal PCS			:	std_logic;
-- signal RegW			:	std_logic;
-- signal MemW		:	std_logic;
signal MemtoReg		:	std_logic;
signal ALUSrc		:	std_logic;
-- signal ImmSrc	:	std_logic_vector(1 downto 0);
signal RegSrc		:	std_logic_vector(1 downto 0);
-- signal NoWrite	:	std_logic;
-- signal ALUControl:	std_logic_vector(1 downto 0);
-- signal FlagW		:	std_logic_vector(1 downto 0);

-- CondLogic signals
-- signal CLK		: 	std_logic;
signal PCS			: 	std_logic;
signal RegW			: 	std_logic;
signal NoWrite		: 	std_logic;
signal MemW			: 	std_logic;
signal FlagW		: 	std_logic_vector(1 downto 0);
signal Cond			: 	std_logic_vector(3 downto 0);
-- signal ALUFlags	: 	std_logic_vector(3 downto 0);
signal PCSrc		: 	std_logic;
signal RegWrite		: 	std_logic;
-- signal MemWrite	: 	std_logic;

-- Shifter signals
signal Sh			: 	std_logic_vector(1 downto 0); 
signal Shamt5		: 	std_logic_vector(4 downto 0);
signal ShIn			: 	std_logic_vector(31 downto 0);
signal ShOut		: 	std_logic_vector(31 downto 0);	
								
-- ALU signals
signal Src_A		: 	std_logic_vector(31 downto 0);
signal Src_B		: 	std_logic_vector(31 downto 0);
signal ALUControl	: 	std_logic_vector(3 downto 0);
signal ALUResult_sig	: 	std_logic_vector(31 downto 0); -- name for internal signal -> output can't be read
signal ALUFlags		: 	std_logic_vector(3 downto 0);
signal ALUFlags_reverse : std_logic_vector (3 downto 0); -- added

--ProgramCounter signals
-- signal CLK		:	std_logic;			
signal WE_PC		:	std_logic; -- write enable	
-- signal RESET		: 	std_logic;		
signal PC_IN		:	std_logic_vector(31 downto 0);			
signal PC_sig		:	std_logic_vector(31 downto 0);  -- name for internal signal -> output can't be read

--MCycle Signals
signal Start		: 	STD_LOGIC;  -- Multi-cycle Enable. The control unit should assert this when an instruction with a multi-cycle operation is detected.
signal MCycleOp	:	STD_LOGIC_VECTOR (1 downto 0); -- Multi-cycle Operation. "00" for signed multiplication, "01" for unsigned multiplication, "10" for signed division, "11" for unsigned division.
signal Operand1	:	STD_LOGIC_VECTOR (width-1 downto 0); -- Multiplicand / Dividend
signal Operand2	:	STD_LOGIC_VECTOR (width-1 downto 0); -- Multiplier / Divisor
signal Result1	    :	STD_LOGIC_VECTOR (width-1 downto 0); -- LSW of Product / Quotient
signal Result2	    :	STD_LOGIC_VECTOR (width-1 downto 0); -- MSW of Product / Remainder
signal Busy		:	STD_LOGIC;

-- Other internal signals
signal PCPlus4		: 	std_logic_vector(31 downto 0);
signal PCPlus8		: 	std_logic_vector(31 downto 0);
signal Result		: 	std_logic_vector(31 downto 0);	
signal Result_Hack : std_logic_vector(31 downto 0);	
signal MCycleHack : std_logic_vector(15 downto 0);
signal Rd_Mul : std_logic_vector(3 downto 0);
signal Rs_Mul : std_logic_vector(3 downto 0);
signal Rm_Mul : std_logic_vector(3 downto 0);
signal RegSrc0_Hack : std_logic_vector(3 downto 0);
signal RegSrc1_Hack : std_logic_vector(3 downto 0);
signal Sh_Hack : std_logic_vector(4 downto 0);
signal ShImm8_Hack : std_logic_vector(31 downto 0);
signal Shamt5_Imm_Shift : std_logic_vector(4 downto 0);
signal Shamt5_Imm : std_logic_vector(4 downto 0);
signal Sh_Carry_Out : std_logic;
signal Sh_Carry_Out_Rs_Shift : std_logic;
signal Sh_Carry_Out_Imm : std_logic;
signal Sh_Rs_0 : std_logic;
signal Sh_Rs_32 : std_logic;
signal Sh_Rs : std_logic_vector(1 downto 0);
signal Sh_Imm : std_logic;
signal Sh_WriteC : std_logic;
signal A4_Sh : std_logic_vector(3 downto 0);
signal RD3_Sh : std_logic_vector(31 downto 0);
			
begin

    --<Datapath connections here>		
    
    Cond <=	Instr(31 downto 28);
    Op <= Instr (27 downto 26);
    Funct <= Instr(25 downto 20);
    Rd <= Instr(15 downto 12);
    -- A1 <= Instr(19 downto 16);
    -- A2 <= Instr(15 downto 12);
    -- A3 <= Instr(15 downto 12);
    InstrImm <= Instr(23 downto 0);
    
    Rd_Mul <= Instr(19 downto 16);
    Rs_Mul <= Instr(11 downto 8);
    Rm_Mul <= Instr(3 downto 0);
    
    -- Implemented in MCycleControl
    Src_A <= RD1;
    
    -- Src_B <= ExtImm;
    PCPlus4 <= PC_sig + 4;
    PCPlus8 <= PC_sig + 8; -- Could be PCPlus4 + 4
    PC <= PC_sig;
    R15 <= PC_sig + 8;
    --R15 <= PCPlus8;
    WriteData <= RD2;
    WE3 <= RegWrite; -- and !Busy; -- edited
    ALUResult <= ALUResult_sig;
    
    with PCSrc select PC_IN <=  
        PCPlus4 when '0',
        Result when '1';
    
    -- When mul, destination reg
    with RegSrc(0) select RegSrc0_Hack <= 
        Instr(19 downto 16) when '0',
        "1111" when '1';

    -- When mul, first operand           
    with RegSrc(1) select RegSrc1_Hack <= 
        Instr(3 downto 0) when '0',
        Instr(15 downto 12) when '1';
    
    with ALUSrc select Src_B <= 
        ShOut when '0',
        ExtImm when '1';
    
    with MemtoReg select Result_Hack <=  
        ALUResult_sig when '0',
        ReadData when '1';
        
    Operand1 <= Src_A;
    Operand2 <= Src_B;
    
    MCycleHack <= Op & Funct & Instr(15 downto 12) & Instr(7 downto 4);
    
    with MCycleHack select A1 <=
        Rm_Mul when "0000000000001001",
        Rm_Mul when "0000001000001001",
        RegSrc0_Hack when others;
        
    with MCycleHack select A2 <=
        Rs_Mul when "0000000000001001",
        Rs_Mul when "0000001000001001",
        RegSrc1_Hack when others;
        
    with MCycleHack select A3 <=
        Rd_Mul when "0000000000001001",
        Rd_Mul when "0000001000001001",
        Instr(15 downto 12) when others;
    
    A4_Sh <= Instr(11 downto 8);
    
    with MCycleHack select Start <= 
        '1' when "0000000000001001",
        '1' when "0000001000001001",
        '0' when others;
    
    with MCycleHack select MCycleOp <=
        "01" when "0000000000001001",
        "11" when "0000001000001001",
        "00" when others;
    
    with MCycleHack select Result <=
        Result1 when "0000000000001001",
        Result1 when "0000001000001001",
        Result_Hack when others;
    
    -- Hack for Input to Operand1 and Operand2
    
    with MCycleHack select Shamt5_Imm_Shift <=
        "00000" when "0000000000001001",
        "00000" when "0000001000001001",
        Instr (11 downto 7) when others;
        
    with MCycleHack select Shamt5_Imm <=
        "00000" when "0000000000001001",
        "00000" when "0000001000001001",
        Instr (11 downto 8) & '0' when others;
    
    Sh_Hack <= Instr (27 downto 25) & Instr(7) & Instr(4);
    
    with Sh_Hack select Sh <=
        Instr (6 downto 5) when "00010", --immediate shift
        Instr (6 downto 5) when "00000", --immediate shift
        Instr (6 downto 5) when "00001", --register shift
        "11" when others; --immediate
        
    ShImm8_Hack <= (31 downto 8 => '0') & Instr (7 downto 0);

    -- Correpsonds to Sh_hack being "00011"
    -- with Instr(22) select Sh_Misc_Load_store <=
        
    
    

    with Sh_Hack select ShIn <=
        RD2 when "00010",
        RD2 when "00000",
        RD2 when "00001",
        RD2 when "00011", -- Should be Sh_Misc_Load_store
        ShImm8_Hack when others;
        
    with Sh_Hack select Shamt5 <=
        Shamt5_Imm_Shift when "00010",
        Shamt5_Imm_Shift when "00000",
        RD3_Sh (4 downto 0) when "00001",
        Shamt5_Imm when others;

    Sh_Rs_0 <= RD3_Sh(7) or RD3_Sh(6) or RD3_Sh(5) or RD3_Sh(4) or RD3_Sh(3) or RD3_Sh(2) or RD3_Sh(1) or RD3_Sh(0);
    Sh_Rs_32 <= RD3_Sh(7) or RD3_Sh(6);
    Sh_Rs <= Sh_Rs_0 & Sh_Rs_32; 
    
    With Sh_Rs select Sh_Carry_Out_Rs_Shift <= 
        ALUFlags(1) when "00",
        ShOut(31) when "01",
        RD2(31) when others;
    
    Sh_Imm <= Instr(11) or Instr(10) or Instr(9) or Instr(8);
    
    With Sh_Imm select Sh_Carry_Out_Imm <=
        ALUFlags(1) when '0',
        ShOut(31) when others;
    
    with Sh_Hack select Sh_Carry_Out <=
        ShOut(31) when "00010",
        ShOut(31) when "00000",
        Sh_Carry_Out_Rs_Shift when "00001",
        Sh_Carry_Out_Imm when others;
    
    -- Sh <= Instr (6 downto 5);
    -- Shamt5 <= Instr (11 downto 7);
    -- ShIn <= RD2;
    WE_PC <= not Busy;
    WD3 <= Result;
    
    --    if Op = "00" and Funct = "00000-" then
            -- MUL
            -- last bit indicates update to NCSV flags
            -- If we want to set flags, pipe 'S' bit into condlogic
            
    --        if Start = '0' then
                -- fire start
    --            Start <= '1'; -- Done
    --            MCycleOp <= "01"; -- Done
    --            WE_PC <= '0'; -- Done
    --        else
    --            WE_PC <= not Busy;
    --            if Busy = '0' then
                    -- Exit Cond
    --                Start <= '0'; -- Done
    --                ALUResult_sig <= Result1;
    --            end if;
    --        end if;
                
    --    else if Op = "00" and Funct = "00001-" then
            -- DIV
            -- last bit indicates update to NCSV flags
            
    --        if Start = '0' then
                -- fire start
    --            Start <= '1'; -- Done
    --            MCycleOp <= "11"; -- Done
    --            WE_PC <= '0';
    --        else
    --            WE_PC <= not Busy;
    --            if Busy = '0' then
                    -- Exit Cond
    --                Start <= '0'; -- Done
    --                ALUResult_sig <= Result1;
    --            end if;
    --        end if;
            
            -- Fire start to Mcycle
                -- Write !Busy to PC_E
                -- Set Operand 1 and 2 to result
            -- IF !Busy
                -- Set Result1 => dest reg (ALUResuly)
    --    end if;  
    
    --if PCSrc = '0' and MemtoReg = '0' then
    --    Result <= ALUResult_sig;
    --    -- PC_IN <= PCPlus4;
    --    PC_IN <= PC_sig + 4;
    --    WD3 <= ALUResult_sig;
    --elsif PCSrc = '0' and MemtoReg = '1' then
    --    Result <= ReadData;
        -- PC_IN <= PCPlus4;
    --    PC_IN <= PC_sig + 4;
    --    WD3 <= ReadData;
    --elsif PCSrc = '1' and MemtoReg = '0' then
    --    Result <= ALUResult_sig;
    --    PC_IN <= ALUResult_sig;
    --    WD3 <= ALUResult_sig;
    --elsif PCSrc = '1' and MemtoReg = '1' then
    --    Result <= ReadData;
    --    PC_IN <= ReadData;
    --    WD3 <= ReadData;
    --end if;         
    
    --if ALUSrc = '1' then
    --    Src_B <= ExtImm;
    --else
    --    Src_B <= RD2;
    --end if;
    
    --if RegSrc(0) = '1' then
    --    A1 <= Instr(19 downto 16);
    --else
    --    A1 <= "1111";
    --end if;
    
    --if RegSrc(1) = '1' then
    --    A2 <= Instr(15 downto 12);
    --else
    --    A2 <= Instr(3 downto 0);
    --end if;
    
    
    --WE_PC		<= '1'; -- Will need to control it for multi-cycle operations (Multiplication, Division) and/or Pipelining with hazard hardware.
    
    -- Port maps 
    RegFile1 :RegFile port map(
    CLK			=>  	CLK  	,
    WE3			=>  	WE3  	,
    A1			=>  	A1	 	,
    A2			=>  	A2	 	,
    A3			=>  	A3	 	,
    A4_Sh       => A4_Sh        ,
    WD3			=>  	WD3  	,
    R15			=>  	R15  	,
    RD1			=>  	RD1  	,
    RD2			=>  	RD2	     ,
    RD3_Sh => RD3_Sh
                );
            
    Extend1 :Extend port map(
    ImmSrc		=>	ImmSrc		,
    InstrImm		=>  InstrImm	,
    ExtImm		=>  ExtImm
                );
    
    Decoder1 : Decoder port map(
    Rd			=>	Rd			,
    Op			=>	Op			,
    Funct		=>	Funct		,
    PCS			=>	PCS			,
    RegW		=>	RegW		,
    MemW		=>	MemW		,
    MemtoReg	=>	MemtoReg	,
    ALUSrc		=>	ALUSrc		,
    ImmSrc		=>	ImmSrc		,
    RegSrc		=>	RegSrc		,
    NoWrite		=>	NoWrite		,
    ALUControl	=>	ALUControl	,
    FlagW		=>	FlagW
                );
                
    CondLogic1: CondLogic port map (
    CLK			=>	CLK			,	
    PCS		    =>  PCS		    ,
    RegW		=>  RegW	    ,
    NoWrite	    =>  NoWrite	    ,
    MemW		=>  MemW	    ,
    FlagW	    =>  FlagW	    ,
    Cond		=>  Cond	    ,
    ALUFlags	=>  ALUFlags    ,
    PCSrc	    =>  PCSrc	    ,
    RegWrite	=>  RegWrite    ,
    MemWrite	=>  MemWrite    ,
    ALUFlags_reverse => ALUFlags_reverse, -- added
    Sh_Carry_Out => Sh_Carry_Out,
    Sh_WriteC => Sh_WriteC
                );
    
    Shifter1 : Shifter port map (
    Sh			=>	Sh			,
    Shamt5		=>	Shamt5		,	
    ShIn		=>	ShIn		,	
    ShOut		=>	ShOut
                );
                
    ALU1 : ALU port map(
    Src_A		=>	Src_A		,	
    Src_B		=>	Src_B		,
    ALUControl	=>	ALUControl	,
    ALUResult	=>	ALUResult_sig	,
    ALUFlags	=>	ALUFlags ,
    ALUFlags_reverse => ALUFlags_reverse,    -- added
    Sh_WriteC => Sh_WriteC
                );
    
    ProgramCounter1 : ProgramCounter port map(			
    CLK			=>	CLK			,
    RESET		=>	RESET		,
    WE_PC		=>	WE_PC	    ,
    PC_IN   	=>	PC_IN       ,
    PC			=>	PC_sig
                );

    MCycle1 : MCycle port map(
    CLK => CLK,
    RESET => RESET,
    Start => Start,
    MCycleOp => MCycleOp,
    Operand1 => Operand1,
    Operand2 => Operand2,
    Result1 => Result1,
    Result2 => Result2,
    Busy => Busy);    

   

end ARM_arch;