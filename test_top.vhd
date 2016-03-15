--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:54:39 09/30/2015
-- Design Name:   
-- Module Name:   ARM
-- Project Name:  ARM
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: TOP
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY test_top IS
END test_top;
 
ARCHITECTURE behavior OF test_top IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT TOP
    PORT(
         DIP : IN  std_logic_vector(15 downto 0);
         PB : IN  std_logic_vector(3 downto 0);
         LED : OUT  std_logic_vector(15 downto 0);
         TX : OUT  std_logic;
         RX : IN  std_logic;
         PAUSE : IN  std_logic;
         RESET : IN  std_logic;
         CLK_undiv : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal DIP : std_logic_vector(15 downto 0) := (others => '0');
   signal PB : std_logic_vector(3 downto 0) := (others => '0');
   signal RX : std_logic := '0';
   signal PAUSE : std_logic := '0';
   signal RESET : std_logic := '0';
   signal CLK_undiv : std_logic := '0';

 	--Outputs
   signal LED : std_logic_vector(15 downto 0);
   signal TX : std_logic;

   -- Clock period definitions
   constant CLK_undiv_period : time := 2 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: TOP PORT MAP (
          DIP => DIP,
          PB => PB,
          LED => LED,
          TX => TX,
          RX => RX,
          PAUSE => PAUSE,
          RESET => RESET,
          CLK_undiv => CLK_undiv
        );

   -- Clock process definitions
   CLK_undiv_process :process
   begin
		CLK_undiv <= '0';
		wait for CLK_undiv_period/2;
		CLK_undiv <= '1';
		wait for CLK_undiv_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 10 ns;
		RESET <= '1';   --RESET is ACTIVE LOW
		DIP <= x"FFFF";

      -- insert stimulus here 
      wait for 100 ns;
      --RESET <= '0';
      DIP <= x"0000";
      wait for 20 ns;
      DIP <= x"FFFF";
      wait for 20 ns;
      DIP <= x"0F0F";
      wait for 20 ns;
      DIP <= x"F0F0";
      wait for 20 ns;
      DIP <= x"0000";
      wait for 20 ns;
      DIP <= x"FFFF";
      wait for 20 ns;
      DIP <= x"0F0F";
      wait for 20 ns;
      DIP <= x"F0F0";
      wait for 20 ns;
      
      wait;
   end process;

END;
