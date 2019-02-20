
  library ieee; 
  use ieee.std_logic_1164.all; 
  use ieee.std_logic_unsigned.all; 
  use ieee.std_logic_arith.all;




entity DMA_controller is 
  generic ( 
    adress_width = 32;
    data_width   = 32;
    );
port (
  -- inputs/outputs
  clk               : in std_logic;
  reset             : in std_logic;
  
  Dma_req           : in std_logic;
  hold_ack          : in std_logic;
  hold              : out std_logic;
  
  mread             : out std_logic_vector(adress_width-1 downto 0);
  mwrite            : out std_logic_vector(data_width -1 downto 0);
  Data_in           : in  std_logic_vector(data_width -1 downto 0);
  Data_out          : out std_logic_vector(data_width -1 downto 0);
  
  );

architecture Behavioral of DMA_controller is 

  signal memorie_read  : std_logic_vector(adress_width-1 downto 0);
  signal memorie_write : std_logic_vector(data_width -1 downto 0);

  

  begin

----------------------------------------------
  process ( clk, reset, Dma_req) 
  begin
     if rising_edge (clk) then 
        if (reset ='1') then 
          memorie_read  <= others => '0';
          memorie_write <= others => '0';
        else 
       if (Dma_req ='1') then
         hold <='1';
         end if ;
       end if;    
     end if;
  end process;
------------------------------------------------ 
       -- ecriture de la data --
 process ( clk, reset, hold_ack)
   begin 
     if rising_edge (clk) then 
       if hold_ack ='1' then
       
         memorie_read <= Data_in;
       end if;
      end if;
   end process;
     
 -----------------------------------------------
        -- envoi de la data --
        
        
 
       
     
  
       
          
          
          
          
          
       
    
       
 
