--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
--|
--| ALU OPCODES:
--|
--|     ADD     000
--|     SUB     001
--|     AND     010
--|     OR      100
--|     Left    110
--|     Right   111
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is
    port(
        i_op    :   in std_logic_vector(2 downto 0); --signed
        i_A     :   in std_logic_vector(8 downto 0);
        i_B     :   in std_logic_vector(8 downto 0);
        o_result:   out std_logic_vector(7 downto 0);
        o_flag  :   out std_logic_vector(2 downto 0)
    );
end ALU;

architecture behavioral of ALU is 
    
	-- declare components and signals
	--component andop is
    --    port(
--            i_A     :   in std_logic_vector(7 downto 0);
--            i_B     :   in std_logic_vector(7 downto 0);
--            o_and   :   out std_logic_vector(7 downto 0)
--        );
--    end component andop;

--    component adder is
--        port(
--            i_op    :   in std_logic_vector(2 downto 0); --signed
--            i_A     :   in std_logic_vector(8 downto 0);
--            i_B     :   in std_logic_vector(8 downto 0);
--            o_sum   :   out std_logic_vector(7 downto 0);
--            o_cout  :   out std_logic
--        );
--    end component adder;

--    component orop is
--        port(
--            i_A     :   in std_logic_vector(7 downto 0);
--            i_B     :   in std_logic_vector(7 downto 0);
--            o_or   :   out std_logic_vector(7 downto 0)
--        );
--    end component orop;

--    component shifter is
--        port(
--            i_op    :   in std_logic_vector(2 downto 0); --signed
--            i_A     :   in std_logic_vector(7 downto 0);
--            i_B     :   in std_logic_vector(7 downto 0);
--            o_shift   :   out std_logic_vector(7 downto 0)
--        );
--    end component shifter;

    signal w_opcode : std_logic_vector(8 downto 0) := (others => '0');
    signal w_add : std_logic_vector(8 downto 0) := (others => '0');
    signal w_sum : std_logic_vector(8 downto 0) := (others => '0');
    signal w_cout, w_sign, w_zero: std_logic;
    signal w_B   : std_logic_vector(8 downto 0);
    signal w_shiftR : std_logic_vector(8 downto 0) := (others => '0');
    signal w_shiftL : std_logic_vector(8 downto 0) := (others => '0');
    signal w_shift, w_and, w_or : std_logic_vector(8 downto 0) := (others => '0');

        
    
begin
	
--                   
   w_opcode <=    "000000001" when i_op(0) = '1' else
	              "000000000";
   w_B <= not(i_B) when (i_op = "001") else i_B;
   w_add <= std_logic_vector(signed(i_A) + signed(w_B) + signed(w_opcode));
   
   
   w_shiftR <= std_logic_vector(shift_right(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));
   w_shiftL <= std_logic_vector(shift_left(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));
   w_shift <= w_shiftR when (i_op(0) = '0') else
              w_shiftL; 
   
   w_and <= i_A and i_B;
   w_or <= i_A or i_B;
   
   w_sum <= w_add when (i_op(2 downto 1) = "00") else
            w_or when (i_op(2 downto 1) = "10") else
            w_and when (i_op(2 downto 1) = "01") else
            w_shift when (i_op(2 downto 1) = "11"); 

   o_result <= w_sum(7 downto 0);

   w_cout <= w_sum(8);
   w_sign <= w_sum(7);
   --w_zero <= '1' when to_integer(unsigned(w_sum)) = 0 else '0';
   
   --w_sum(7 downto 0) = "00000000" else '0';
   o_flag(0) <= w_cout;
   o_flag(1) <= '0';--w_zero;
   o_flag(2) <= w_sign;
	
end behavioral;
