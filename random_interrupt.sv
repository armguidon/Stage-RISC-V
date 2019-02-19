import riscv_defines::*;
`include "riscv_config.sv"

module random_interrupt (
 // inputs
  input logic           rst_ni,           // reset
  input logic           clk_i,            // clock
  input logic           irq_i,            // instruction request
  input logic   [4:0]   irq_id_i,         // instruction request decode
  input logic           irq_ack_i,        // instruction acknowlage
  input logic  [31:0]   irq_mode_i,       // mode choice
  input logic  [31:0]   irq_min_cycles_i, // cycle min ifetch
  input logic  [31:0]   irq_max_cycles_i, // cycle max ifetch
  input logic  [31:0]   irq_min_id_i,     // cycle min decode 
  input logic  [31:0]   irq_max_id_i,     // cycle max decode
  input logic  [31:0]   irq_pc_id_i,      // pc ifetch/dec
  input logic  [31:0]   irq_pc_trig_i,    // trigger ifetch
 
  // outputs 
    output logic          irq_o,
    output logic  [4:0]   irq_id_o,
    output logic          irq_ack_o,
    output logic [31:0]   irq_act_id_o,
    output logic          irq_id_we_o

);
// calss random pour le nombre de cycles 
 class rand_irq_cycles;
    rand int n;
endclass : rand_irq_cycles
 
 // class random pour I/D
 
  class rand_irq_id;
    rand int n;
endclass : rand_irq_id
 
 // les signaux intermediaires
 
logic [31:0] irq_mode_q;
logic        irq_random;
logic  [4:0] irq_id_random;
logic        irq_ack_random;
logic        irq_monitor;
logic  [4:0] irq_id_monitor;
logic        irq_ack_monitor;

 // routage
 assign irq_ack_o = irq_ack_i;
 
 // reset
 always_ff @(posedge clk_i or negedge rst_ni)
begin
    if(~rst_ni) begin
        irq_mode_q <= 0;
    end else begin
        irq_mode_q <= irq_mode_i;
    end
end
 
 // les cases
 
 always_comb
begin
    unique case (irq_mode_q)
        RANDOM:                                // interruption aleatoire
        begin
         irq_o     = irq_random;
         irq_id_o  = irq_id_random;
        end

        PC_TRIG:
        begin                                 // triguer le pc sur une valeur choisi
         irq_o     = irq_monitor;
         irq_id_o  = irq_id_monitor;
        end

        default:                             // mode default, routage des entree sur les sorties
        begin
         irq_o     = irq_i;
         irq_id_o  = irq_id_i;
        end
    endcase
end
 //------------------------------------------------------------------------------------------------------
 
 
 //Random Process
 
initial
begin
    automatic rand_irq_cycles wait_cycles = new();
    automatic rand_irq_id value = new();
 
    int temp,i, min_irq_cycles, max_irq_cycles, min_irq_id, max_irq_id;
 
    irq_id_monitor = 1'b0;
    irq_id_monitor = '0;
    while(1) begin

        irq_id_monitor = 1'b0;
        irq_id_monitor = '0;

        @(posedge clk_i);

        wait(irq_mode_q == RANDOM);
        min_irq_id     = irq_min_id_i;
        max_irq_id     = irq_max_id_i;
        min_irq_cycles = irq_min_cycles_i;
        max_irq_cycles = irq_max_cycles_i;

        temp = value.randomize() with{
            n >= min_irq_id;
            n <= max_irq_id;
        };
        temp = wait_cycles.randomize() with{
            n >= min_irq_cycles;
            n <= max_irq_cycles;
        };
        while(wait_cycles.n != 0) begin
            @(posedge clk_i);
            wait_cycles.n--;
        end

        irq_id_monitor = value.n;
        irq_monitor    = 1'b1;
        irq_act_id_o   = value.n;
        @(posedge clk_i);
        //we don't care about the ack in this mode
        for(i=0; i<max_irq_cycles; i++) begin
            @(posedge clk_i);
        end
    end
end


//Monitor Process
initial
begin
    int pc_value;
    irq_monitor    = 1'b0;
    irq_id_monitor = '0;
    pc_value = 0;
    wait(irq_mode_q == PC_TRIG);
    wait(irq_pc_id_i == irq_pc_trig_i);
    irq_monitor    = 1'b1;
    irq_id_monitor = PC_TRIG_ID;
    while(irq_ack_i != 1'b1) begin
        @(posedge clk_i);   //Keep the request high until the acknowledge is received
    end
    @(posedge clk_i);
    irq_monitor    = 1'b0;
    irq_id_monitor = '0;
end

initial
begin
    while(1) begin
        irq_id_we_o = 1'b0;
        wait(irq_ack_i == 1'b1);
        irq_id_we_o = 1'b1;   //Give the write enable to store the core response
        @(posedge clk_i);
    end
end


endmodule
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
