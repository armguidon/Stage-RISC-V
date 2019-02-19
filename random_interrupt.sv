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
  
  
