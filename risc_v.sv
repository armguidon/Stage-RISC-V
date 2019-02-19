module tb_riscv_core
#(
  parameter N_EXT_PERF_COUNTERS =  0,
  parameter INSTR_RDATA_WIDTH   = 32,
  parameter PULP_SECURE         =  0,
  parameter N_PMP_ENTRIES       = 16,
  parameter PULP_CLUSTER        =  1,
  parameter FPU                 =  0,
  parameter SHARED_FP           =  0,
  parameter SHARED_DSP_MULT     =  0,
  parameter SHARED_INT_DIV      =  0,
  parameter SHARED_FP_DIVSQRT   =  0,
  parameter WAPUTYPE            =  0,
  parameter APU_NARGS_CPU       =  3,
  parameter APU_WOP_CPU         =  6,
  parameter APU_NDSFLAGS_CPU    = 15,
  parameter APU_NUSFLAGS_CPU    =  5,
  parameter SIMCHECKER          =  0
)
(
  // Clock and Reset
  input  logic        clk_i,
  input  logic        rst_ni,

  input  logic        clock_en_i,    // enable clock, otherwise it is gated
  input  logic        test_en_i,     // enable all clock gates for testing

  input  logic        fregfile_disable_i,  // disable the fp regfile, using int regfile instead

  // Core ID, Cluster ID and boot address are considered more or less static
  input  logic [31:0] boot_addr_i,
  input  logic [ 3:0] core_id_i,
  input  logic [ 5:0] cluster_id_i,

  // Instruction memory interface
  output logic                         instr_req_o,
  input  logic                         instr_gnt_i,
  input  logic                         instr_rvalid_i,
  output logic                  [31:0] instr_addr_o,
  input  logic [INSTR_RDATA_WIDTH-1:0] instr_rdata_i,

  // Data memory interface
  output logic        data_req_o,
  input  logic        data_gnt_i,
  input  logic        data_rvalid_i,
  output logic        data_we_o,
  output logic [3:0]  data_be_o,
  output logic [31:0] data_addr_o,
  output logic [31:0] data_wdata_o,
  input  logic [31:0] data_rdata_i,
  // apu-interconnect
  // handshake signals
  output logic                       apu_master_req_o,
  output logic                       apu_master_ready_o,
  input logic                        apu_master_gnt_i,
  // request channel
  output logic [31:0]                 apu_master_operands_o [APU_NARGS_CPU-1:0],
  output logic [APU_WOP_CPU-1:0]      apu_master_op_o,
  output logic [WAPUTYPE-1:0]         apu_master_type_o,
  output logic [APU_NDSFLAGS_CPU-1:0] apu_master_flags_o,
  // response channel
  input logic                        apu_master_valid_i,
  input logic [31:0]                 apu_master_result_i,
  input logic [APU_NUSFLAGS_CPU-1:0] apu_master_flags_i,

  // Interrupt inputs
  input  logic        irq_i,                 // level sensitive IR lines
  input  logic [4:0]  irq_id_i,
  output logic        irq_ack_o,
  output logic [4:0]  irq_id_o,
  input  logic        irq_sec_i,

  output logic        sec_lvl_o,

  // Debug Interface
  input  logic        debug_req_i,
  output logic        debug_gnt_o,
  output logic        debug_rvalid_o,
  input  logic [14:0] debug_addr_i,
  input  logic        debug_we_i,
  input  logic [31:0] debug_wdata_i,
  output logic [31:0] debug_rdata_o,
  output logic        debug_halted_o,
  input  logic        debug_halt_i,
  input  logic        debug_resume_i,

  // CPU Control Signals
  input  logic        fetch_enable_i,
  output logic        core_busy_o,

  input  logic [N_EXT_PERF_COUNTERS-1:0] ext_perf_counters_i
);

localparam PERT_REGS = 15;
  
//------------------------------------------------------------------
//------------------------------------------------------------------


  riscv_core
  #(
    .N_EXT_PERF_COUNTERS            ( N_EXT_PERF_COUNTERS      ),
    .INSTR_RDATA_WIDTH              ( INSTR_RDATA_WIDTH        ),
    .PULP_SECURE                    ( PULP_SECURE              ),
    .N_PMP_ENTRIES                  ( N_PMP_ENTRIES            ),
    .FPU                            ( FPU                      ),
    .SHARED_FP                      ( SHARED_FP                ),
    .SHARED_DSP_MULT                ( SHARED_DSP_MULT          ),
    .SHARED_INT_DIV                 ( SHARED_INT_DIV           ),
    .SHARED_FP_DIVSQRT              ( SHARED_FP_DIVSQRT        ),
    .WAPUTYPE                       ( WAPUTYPE                 ),
    .APU_NARGS_CPU                  ( APU_NARGS_CPU            ),
    .APU_WOP_CPU                    ( APU_WOP_CPU              ),
    .APU_NDSFLAGS_CPU               ( APU_NDSFLAGS_CPU         ),
    .APU_NUSFLAGS_CPU               ( APU_NUSFLAGS_CPU         )
    )
  
  
  RISCV_CORE
  (
    .clk_i                          ( clk_i                   ),
    .rst_ni                         ( rst_ni                  ),

    .clock_en_i                     ( clock_en_i              ),
    .test_en_i                      ( test_en_i               ),

    .fregfile_disable_i             ( fregfile_disable_i      ),

    .boot_addr_i                    ( boot_addr_i             ),
    .core_id_i                      ( core_id_i               ),
    .cluster_id_i                   ( cluster_id_i            ),

    .instr_req_o                    ( instr_req_int           ),
    .instr_gnt_i                    ( instr_grant_int         ),
    .instr_rvalid_i                 ( instr_rvalid_int        ),
    .instr_addr_o                   ( instr_addr_int          ),
    .instr_rdata_i                  ( instr_rdata_int         ),

    .data_req_o                     ( data_req_int            ),
    .data_gnt_i                     ( data_grant_int          ),
    .data_rvalid_i                  ( data_rvalid_int         ),
    .data_we_o                      ( data_we_int             ),
    .data_be_o                      ( data_be_int             ),
    .data_addr_o                    ( data_addr_int           ),
    .data_wdata_o                   ( data_wdata_int          ),
    .data_rdata_i                   ( data_rdata_int          ),

    .apu_master_req_o               ( apu_master_req_o        ),
    .apu_master_ready_o             ( apu_master_ready_o      ),
    .apu_master_gnt_i               ( apu_master_gnt_i        ),
    .apu_master_operands_o          ( apu_master_operands_o   ),
    .apu_master_op_o                ( apu_master_op_o         ),
    .apu_master_type_o              ( apu_master_type_o       ),
    .apu_master_flags_o             ( apu_master_flags_o      ),

    .apu_master_valid_i             ( apu_master_valid_i      ),
    .apu_master_result_i            ( apu_master_result_i     ),
    .apu_master_flags_i             ( apu_master_flags_i      ),

    .irq_i                          ( irq_int                 ),
    .irq_id_i                       ( irq_id_int              ),
    .irq_ack_o                      ( irq_ack_int             ),
    .irq_id_o                       ( irq_core_resp_id_int    ),
    .irq_sec_i                      ( irq_sec_i               ),

    .sec_lvl_o                      ( sec_lvl_o               ),

    .debug_req_i                    ( debug_req_int           ),
    .debug_gnt_o                    ( debug_grant_int         ),
    .debug_rvalid_o                 ( debug_rvalid_int        ),
    .debug_addr_i                   ( debug_addr_int          ),
    .debug_we_i                     ( debug_we_int            ),
    .debug_wdata_i                  ( debug_wdata_int         ),
    .debug_rdata_o                  ( debug_rdata_int         ),
    .debug_halted_o                 ( debug_halted_o          ),
    .debug_halt_i                   ( debug_halt_i            ),
    .debug_resume_i                 ( debug_resume_i          ),

    .fetch_enable_i                 ( fetch_enable_i          ),
    .core_busy_o                    ( core_busy_o             ),

    .ext_perf_counters_i            ( ext_perf_counters_i     )
  );
  //------------------------------------------------------------
  // signaux de routage 
    
  logic           irq_interm
  logic   [4:0]   irq_id_interm;
  logic           irq_ack_interm;
  logic          irq_o_interm;
  
  logic  [4:0]   irq_id_o_interm;
  logic          irq_ack_o_interm;
  logic  [31:0]   irq_mode_interm;
  logic  [31:0]   irq_min_cycles_interm;
  
  logic  [31:0]   irq_max_cycles_interm;
  logic  [31:0]   irq_min_id_interm;
  logic  [31:0]   irq_max_id_interm;
  logic [31:0]   irq_act_id_o_interm;
  
  logic          irq_id_we_o_interm;
  logic  [31:0]   irq_pc_id_interm;
  logic  [31:0]   irq_pc_trig_interm;
//----------------------------------------------------------------
  
  
  // random_interrupt instance 
  random_interrupt random_interrupt_i (
  
       .rst_ni                    (rst_ni),
       .clk_i                     (clk_i),
       .irq_i                     (irq_interm),
       .irq_id_i                  (irq_id_interm),
       .irq_ack_i                 (irq_ack_interm),
       .irq_o                     (irq_o_interm),
       .irq_id_o                  (irq_id_o_interm),
       .irq_ack_o                 (irq_ack_o_interm),
       .irq_mode_i                (irq_mode_interm),
       .irq_min_cycles_i          (irq_min_cycles_interm),
       .irq_max_cycles_i          (irq_max_cycles_interm),
       .irq_min_id_i              (irq_act_id_o_interm),
       .irq_max_id_i              (irq_id_we_o_interm),
       .irq_act_id_o              (irq_act_id_o_interm),
       .irq_id_we_o               (irq_id_we_o_interm),
       .irq_pc_id_i               (irq_pc_id_interm),
       .irq_pc_trig_i             (irq_pc_trig_interm)
);

//-------------------------------------------------------------------
//-------------------------------------------------------------------
  `ifndef VERILATOR
   generate
       if(SIMCHECKER) begin: ri5cy_simchecker
          riscv_simchecker riscv_simchecker_i
          (
            .clk              ( RISCV_CORE.clk_i                                ),
            .rst_n            ( RISCV_CORE.rst_ni                               ),

            .fetch_enable     ( RISCV_CORE.fetch_enable_i                       ),
            .boot_addr        ( RISCV_CORE.boot_addr_i                          ),
            .core_id          ( RISCV_CORE.core_id_i                            ),
            .cluster_id       ( RISCV_CORE.cluster_id_i                         ),

            .instr_compressed ( RISCV_CORE.if_stage_i.fetch_rdata[15:0]         ),
            .if_valid         ( RISCV_CORE.if_stage_i.if_valid                  ),
            .pc_set           ( RISCV_CORE.pc_set                               ),


            .pc               ( RISCV_CORE.id_stage_i.pc_id_i                   ),
            .instr            ( RISCV_CORE.id_stage_i.instr                     ),
            .is_compressed    ( RISCV_CORE.is_compressed_id                     ),
            .id_valid         ( RISCV_CORE.id_stage_i.id_valid_o                ),
            .is_decoding      ( RISCV_CORE.id_stage_i.is_decoding_o             ),
            .is_illegal       ( RISCV_CORE.id_stage_i.illegal_insn_dec          ),
            .is_interrupt     ( RISCV_CORE.is_interrupt                         ),
            .irq_no           ( RISCV_CORE.irq_id_i                             ),
            .pipe_flush       ( RISCV_CORE.id_stage_i.controller_i.pipe_flush_i ),
            .irq_i            ( RISCV_CORE.irq_i                                ),
            .is_mret          ( RISCV_CORE.id_stage_i.controller_i.mret_insn_i  ),

            .int_enable       ( RISCV_CORE.id_stage_i.m_irq_enable_i            ),

            .lsu_ready_wb     ( RISCV_CORE.lsu_ready_wb                         ),
            .apu_ready_wb     ( RISCV_CORE.apu_ready_wb                         ),
            .wb_contention    ( RISCV_CORE.ex_stage_i.wb_contention             ),

            .apu_en_id        ( RISCV_CORE.id_stage_i.apu_en                    ),
            .apu_req          ( RISCV_CORE.ex_stage_i.apu_req                   ),
            .apu_gnt          ( RISCV_CORE.ex_stage_i.apu_gnt                   ),
            .apu_valid        ( RISCV_CORE.ex_stage_i.apu_valid                 ),
            .apu_singlecycle  ( RISCV_CORE.ex_stage_i.apu_singlecycle           ),
            .apu_multicycle   ( RISCV_CORE.ex_stage_i.apu_multicycle            ),
            .apu_latency      ( RISCV_CORE.ex_stage_i.apu_lat_i                 ),
            .apu_active       ( RISCV_CORE.ex_stage_i.apu_active                ),
            .apu_en_ex        ( RISCV_CORE.ex_stage_i.apu_en_i                  ),

            .ex_valid         ( RISCV_CORE.ex_valid                             ),
            .ex_reg_addr      ( RISCV_CORE.id_stage_i.registers_i.waddr_b_i     ),

            .ex_reg_we        ( RISCV_CORE.id_stage_i.registers_i.we_b_i        ),
            .ex_reg_wdata     ( RISCV_CORE.id_stage_i.registers_i.wdata_b_i     ),

            .ex_data_req      ( RISCV_CORE.data_req_o                           ),
            .ex_data_gnt      ( RISCV_CORE.data_gnt_i                           ),
            .ex_data_we       ( RISCV_CORE.data_we_o                            ),
            .ex_data_addr     ( RISCV_CORE.data_addr_o                          ),
            .ex_data_wdata    ( RISCV_CORE.data_wdata_o                         ),

            .lsu_misaligned   ( RISCV_CORE.data_misaligned                      ),
            .wb_bypass        ( RISCV_CORE.ex_stage_i.branch_in_ex_i            ),

            .wb_valid         ( RISCV_CORE.wb_valid                             ),
            .wb_reg_addr      ( RISCV_CORE.id_stage_i.registers_i.waddr_a_i     ),
            .wb_reg_we        ( RISCV_CORE.id_stage_i.registers_i.we_a_i        ),
            .wb_reg_wdata     ( RISCV_CORE.id_stage_i.registers_i.wdata_a_i     ),
            .wb_data_rvalid   ( RISCV_CORE.data_rvalid_i                        ),
            .wb_data_rdata    ( RISCV_CORE.data_rdata_i                         )
          );
        end
   endgenerate
   `endif

endmodule // tb_riscv_core
  
  );
  
  
  
