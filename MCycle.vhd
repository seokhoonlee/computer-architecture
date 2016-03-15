library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MCycle is
generic (width 	: integer := 32); -- Keep this at 4 to verify your algorithms with 4 bit numbers (easier). When using MCycle as a component in ARM (Lab 4), generic map it to 32.
Port (CLK		: in	STD_LOGIC;
		RESET		: in 	STD_LOGIC;  -- Connect this to the reset of the ARM processor (Lab 4).
		Start		: in 	STD_LOGIC;  -- Multi-cycle Enable. The control unit should assert this when an instruction with a multi-cycle operation is detected.
		MCycleOp	: in	STD_LOGIC_VECTOR (1 downto 0); -- Multi-cycle Operation. "00" for signed multiplication, "01" for unsigned multiplication, "10" for signed division, "11" for unsigned division.
		Operand1	: in	STD_LOGIC_VECTOR (width-1 downto 0); -- Multiplicand / Dividend
		Operand2	: in	STD_LOGIC_VECTOR (width-1 downto 0); -- Multiplier / Divisor
		Result1	: out	STD_LOGIC_VECTOR (width-1 downto 0); -- LSW of Product / Quotient
		Result2	: out	STD_LOGIC_VECTOR (width-1 downto 0); -- MSW of Product / Remainder
		Busy		: out	STD_LOGIC);  -- Set immediately when Start is set. Cleared when the Results become ready. This bit can be used to stall the processor while multi-cycle operations are on (Lab 4).
end MCycle;

architect8hbgvure Arch_MCycle of MCycle is

type states is (IDLE, COMPUTING);
signal state, n_state 	: states := IDLE;
signal done 	: std_logic;
signal test_a_old : std_logic_vector(width-1 downto 0);
signal test_m_div : std_logic_vector(width-1 downto 0);
signal test_acc_before : std_logic_vector(width downto 0);
signal test_acc_after : std_logic_vector(width downto 0);
signal test_q_div_before: std_logic_vector(width-1 downto 0);
signal test_q_div_after: std_logic_vector(width-1 downto 0);
signal test_mycleop : std_logic_vector(1 downto 0);
signal ones : std_logic_vector (width-1 downto 0) := (others => '1');

begin

IDLE_PROCESS : process (state, done, Start, RESET, Operand1, Operand2)
begin

Busy <= '0';
n_state <= IDLE;

if RESET = '1' then
	n_state <= IDLE;
else
	case state is
		when IDLE =>
			if Start = '1' then
				n_state <= COMPUTING;
				Busy <= '1';
			end if;
		when COMPUTING => 
			if done = '1' then
				n_state <= IDLE;
			else
				n_state <= COMPUTING;
				Busy <= '1';
			end if;
	end case;
end if;	
end process;

COMPUTING_PROCESS : process (CLK, Operand1, Operand2)
variable count : std_logic_vector(7 downto 0) := (others => '0');
variable temp_sum : std_logic_vector(2*width-1 downto 0) := (others => '0');
variable shifted_op1 : std_logic_vector(2*width-1 downto 0) := (others => '0');
variable shifted_op2 : std_logic_vector(2*width-1 downto 0) := (others => '0');
-- booth algorithm
variable a : std_logic_vector(width-1 downto 0) := (others => '0');
variable q_curr : std_logic_vector(width-1 downto 0) := Operand1;
variable q_prev : std_logic := '0';
variable m :  std_logic_vector(width-1 downto 0) := Operand2;
variable tc_m : std_logic_vector(width-1 downto 0) := not (Operand2) + '1';
-- division
-- Operand 1 is dividend, Operand 2 is divisor
variable m_div : std_logic_vector(width-1 downto 0) := Operand2;
variable q_div : std_logic_vector(width-1 downto 0) := Operand1;
variable acc : std_logic_vector(width downto 0) := (others => '0');
variable a_old : std_logic_vector(width-1 downto 0) := (others => '0');
variable rc_div : std_logic := '0';
variable rq_div : std_logic := '0';

begin  
   if (CLK'event and CLK = '1') then 
        -- n_state = COMPUTING and state = IDLE implies we are just transitioning into COMPUTING
		if RESET = '1' or (n_state = COMPUTING and state = IDLE) then
			count := (others => '0');
			temp_sum := (others => '0');
			shifted_op1 := (2*width-1 downto width => not(MCycleOp(0)) and Operand1(width-1)) & Operand1;					
			shifted_op2 := (2*width-1 downto width => not(MCycleOp(0)) and Operand2(width-1)) & Operand2;
            a := (others => '0');
            q_curr := Operand1;
            q_prev := '0';
            m := Operand2;
            tc_m := not (Operand2) + '1';
            
            -- Div
            -- 
            -- rc_div remainder to be negated at the end
            -- rq_div perform 2's complement at the end
            rc_div := '0';
            rq_div := '0';
            m_div := Operand2;
            test_mycleop <= MCycleOp;
            if MCycleOp = "10" then
                --signed
                if Operand1(width - 1) = '1' then
                    q_div := (ones xor Operand1) + '1';
                    rc_div := '1';
                else
                    q_div := Operand1;
                    rc_div := '0';
                end if;
                if Operand2(width - 1) = '1' then
                    m_div := (ones xor Operand2) + '1';
                end if;
                rq_div := Operand1 (width-1) xor Operand2 (width-1);
            else
                q_div := Operand1;
                rc_div := '0';
                rq_div := '0';
            end if;
            --q_div := Operand1;
            acc := (others => '0');
            a_old := (width-1 downto 1 => '0') & Operand1(width-1);
		end if;			
        done <= '0';

        if MCycleOp = "00" then -- Booth Algorithm
            -- Add or Sub depending on q_prev and q_curr(0)
            if q_prev = '1' and q_curr(0) = '0' then -- add a + m
                a := a + m;
            elsif q_prev = '0' and q_curr(0) = '1' then -- sub a - m
                a := a + tc_m;
            end if;
            
            -- shift (1. always takes place 2.done in a reverse order because variables are assigned immediately)
            q_prev := q_curr(0);
            q_curr := a(0) & q_curr(width - 1 downto 1);
            a := a(width - 1) & a(width - 1 downto 1);
            
            temp_sum := a & q_curr;
            
            if count = width-1 then
                done <= '1';
                -- set to Result when done
                Result2 <= temp_sum(2*width-1 downto width);
                Result1 <= temp_sum(width-1 downto 0);
            end if;
            
            count := count+1;
        elsif MCycleOp = "01" then -- multiply, takes 'width' cycles to execute, returns unsigned(Operand1)*unsigned(Operand2)
            if shifted_op2(0)= '1' then
                temp_sum := temp_sum + shifted_op1;
            end if;
            
            shifted_op2 := '0' & shifted_op2(2*width-1 downto 1);
            shifted_op1 := shifted_op1(2*width-2 downto 0) & '0';    
            
            if count = width then
                done <= '1';
                Result2 <= temp_sum(2*width-1 downto width);
                Result1 <= temp_sum(width-1 downto 0);
            end if;
            
            count := count+1;	 
		else -- Supposed to be Divide. The dummy code below takes 1 cycle to execute, just returns the operands. Change this to signed [MCycleOp(0) = '0'] and unsigned [MCycleOp(0) = '1'] division.
			
			-- To implement another bit && signed
			
			acc(width) := '0';
			acc(width-1 downto 1) := acc(width-2 downto 0);
			test_q_div_before <= q_div;
			acc(0) := q_div(width-1);
            a_old := acc(width-1 downto 0);
            test_a_old <= a_old;
            
            q_div(width-1 downto 1) := q_div(width-2 downto 0);
            test_q_div_after <= q_div;
            
			acc := acc - m_div;
			test_acc_before <= acc;
			
			if acc(width) = '0' then
			    q_div(0) := '1';
			    acc(width-1 downto 0) := acc(width-1 downto 0);
            else
                q_div(0) := '0'; 
                acc(width-1 downto 0) := a_old;
                acc(width) := '0';
            end if;
            
            test_acc_after <= acc;
                        
			count := count+1;
			
			if count = width then
                done <= '1';
                if rc_div = '0' then
                    Result2 <= acc(width-1 downto 0); -- remainder
                else
                    Result2 <= (ones xor acc(width-1 downto 0)) + 1; -- remainder
                end if;
                if rq_div = '0' then
                    Result1 <= q_div;
                else
                    Result1 <= (ones xor q_div) + 1; -- quotient
                end if;
            end if;
            
            test_m_div <= m_div;
            --Result2 <= acc; -- remainder
            --Result1 <= q_div; -- quotient
		end if;
	end if;
end process;

STATE_UPDATE_PROCESS : process (CLK) -- state updating
begin  
   if (CLK'event and CLK = '1') then
		state <= n_state;
   end if;
end process;

end Arch_MCycle;