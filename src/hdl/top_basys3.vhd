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
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(        
        clk: in std_logic;
        sw: in std_logic_vector(7 downto 0);
        btnC: in std_logic;
        btnU: in std_logic;
        led: out std_logic_vector(15 downto 0);
        seg: out std_logic_vector(6 downto 0);
        an: out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
    component clock_divider is
        generic ( constant k_DIV : natural := 2    ); -- How many clk cycles until slow clock toggles                                         -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port (    
            i_clk    : in std_logic;
            i_reset  : in std_logic;           -- asynchronous
            o_clk    : out std_logic           -- divided (slow) clock
        );
    end component clock_divider;
    
    component clock_divider2 is
        generic ( constant k_DIV : natural := 2    ); -- How many clk cycles until slow clock toggles                                         -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port (    
            i_clk    : in std_logic;
            i_reset  : in std_logic;           -- asynchronous
            o_clk    : out std_logic           -- divided (slow) clock
        );
    end component clock_divider2;
    
    component twoscomp_decimal is
        port (
            i_binary: in std_logic_vector(7 downto 0);
            o_negative: out std_logic_vector(3 downto 0);
            o_hundreds: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twoscomp_decimal;
    
    --TDM4
    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( 
            i_clk        : in  STD_LOGIC;
            i_reset        : in  STD_LOGIC; -- asynchronous
            i_D3         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D2         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D1         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D0         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            o_data        : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            o_sel        : out STD_LOGIC_VECTOR (3 downto 0)    -- selected data line (one-cold)
        );
    end component TDM4;
    
--    component top_mux is
--        port(
--            i_cycle :   in std_logic_vector(3 downto 0);
--            i_A    :   in std_logic_vector(7 downto 0);
--            i_B    :   in std_logic_vector(7 downto 0);
--            i_result    :   in std_logic_vector(7 downto 0);
--            o_bin   :   out std_logic_vector(7 downto 0)
--        );
--    end component top_mux;
    
    component controller_fsm is
            port(
                i_reset  : in std_logic;
                i_next: in std_logic;
                i_clk: in std_logic;
                o_state: out std_logic_vector(3 downto 0)
            );
    end component controller_fsm;
    
    component sevenSegDecoder is
            port(
                i_D    :    in  std_logic_vector(3 downto 0);
                o_S :   out std_logic_vector(6 downto 0)
            );
        end component sevenSegDecoder;
    component ALU is
            port(
                i_op    :   in std_logic_vector(2 downto 0); --signed
                i_A     :   in std_logic_vector(8 downto 0);
                i_B     :   in std_logic_vector(8 downto 0);
                o_result:   out std_logic_vector(7 downto 0);
                o_flag  :   out std_logic_vector(2 downto 0)
            );
    end component ALU;
    constant k_clk_period : time := 20 ns;
       -- Constants
    constant k_IO_WIDTH : natural := 4;
       -- Signals
    signal w_clk1, w_clk2 : std_logic;
    signal w_data : std_logic_vector(3 downto 0);
    signal w_sel : std_logic_vector(3 downto 0);
    signal w_D3, w_D2, w_D1, w_D0 : std_logic_vector (k_IO_WIDTH - 1 downto 0);
    signal f_sel_n : std_logic_vector (3 downto 0);
    signal w_reset,w_next : std_logic := '0';
    signal w_negative, w_hundreds, w_tens, w_ones, w_cycle : std_logic_vector(3 downto 0);
    signal w_flag, w_op : std_logic_vector(2 downto 0);
    signal w_A, w_B : std_logic_vector(8 downto 0) := (others => '0');
    signal w_Aconst, w_Bconst : std_logic_vector(7 downto 0) := (others => '0');
    signal w_result,w_binary : std_logic_vector(7 downto 0) := (others => '0');
    
begin
	-- PORT MAPS ----------------------------------------
    w_reset <= btnU;
    w_next <= btnC;
    controller_fsm_inst : controller_fsm
        port map(
            i_reset => w_reset,
            i_clk => w_clk2,
            i_next => w_next,
            o_state => w_cycle
        );
        
    ALU_inst: ALU
        port map(
            i_op => sw(2 downto 0),
            i_A => w_A,
            i_B => w_B,
            o_result => w_result,
            o_flag => w_flag
        );
            
    clkdiv_inst : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 100000 ) -- 1 Hz clock from 100 MHz
        port map (                          
            i_clk   => clk,
            i_reset => w_reset,
            o_clk   => w_clk1
        ); 
               
    clkdiv_inst2 : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 25000000 ) -- 1 Hz clock from 100 MHz
        port map (                          
            i_clk   => clk,
            i_reset => '0',
            o_clk   => w_clk2
        ); 

    twoscomp_decimal_inst: twoscomp_decimal
        port map (
            i_binary => w_binary,
            o_negative => w_negative,
            o_hundreds => w_hundreds,
            o_tens => w_tens,
            o_ones => w_ones
        );
     
    TDM4_inst: TDM4
        generic map (k_WIDTH => 4) -- bits in input and output
        port map( 
            i_clk => w_clk1,
            i_reset => w_reset,
            i_D3 => w_negative,
            i_D2 => w_hundreds,
            i_D1 => w_tens,
            i_D0 => w_ones,
            o_data => w_data,
            o_sel => w_sel
        );
    
    sevenSegDecoder_inst: sevenSegDecoder
        port map(
            i_D => w_data(3 downto 0),
            o_S => seg
        );
--    top_mux_inst: top_mux
--        port map(
--                i_cycle => w_cycle,
--                i_A => w_A,
--                i_B => w_B,
--                i_result => w_result,
--                o_bin => w_binary
--            );
    register_A_proc: process (w_cycle(0), w_reset)
    begin
        if (rising_edge(w_cycle(0))) then
            w_A(7 downto 0) <= sw(7 downto 0);
        if (w_reset = '1') then 
            w_A(7 downto 0) <= "00000000";
        end if;
        end if;
    end process;
    
    register_B_proc: process (w_cycle(1), w_reset)
    begin
        if (rising_edge(w_cycle(1))) then
            w_B(7 downto 0) <= sw(7 downto 0);
        if (w_reset = '1') then 
            w_B(7 downto 0) <= "00000000";
        end if;
        end if;
    end process;
    
    w_A(8) <= '0';
    w_B(8) <= '0';

    w_op <= sw(2 downto 0);
   --when(w_cycle = "0100");

	w_binary <= w_A(7 downto 0) when (w_cycle = "0001") else
             w_B(7 downto 0) when (w_cycle = "0010") else
             w_result when (w_cycle = "0100") else
             "00000000" when (w_cycle = "1000") else
             "00000000";  
	led(3 downto 0) <= w_cycle;
	an(3 downto 0) <= w_sel;
	w_flag(2) <= '1' when to_integer(unsigned(w_result)) = 0 and w_cycle = "0100" else '0';
	led(15) <= w_flag(2);
	led(14) <= w_flag(1);
	led(13) <= w_flag(0);
	led(12 downto 4) <= (others => '0');

end top_basys3_arch;