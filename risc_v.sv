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

//////////////////////////////////////////////////////////////
//Internal signals to connect core and perturbation module
/////////////////////////////////////////////////////////////

// Additional instruction signals

logic                          instr_req_int;
logic                          instr_grant_int;
logic                          instr_rvalid_int;
logic [31:0]                   instr_addr_int;
logic [INSTR_RDATA_WIDTH-1:0]  instr_rdata_int;

// Additional data signals
logic                          data_req_int;
logic                          data_grant_int;
logic                          data_rvalid_int;
logic                          data_we_int;
logic [3:0]                    data_be_int;
logic [31:0]                   data_addr_int;
logic [31:0]                   data_wdata_int;
logic [31:0]                   data_rdata_int;

// Additional signals for pertubation/debug registers
logic                          debug_req_int;
logic                          debug_grant_int;
logic                          debug_rvalid_int;
logic                          debug_we_int;
logic [14:0]                   debug_addr_int;
logic [31:0]                   debug_wdata_int;
logic [31:0]                   debug_rdata_int;

// Additional interrupt signals
logic                          irq_int;
logic                          irq_ack_int;
logic [4:0]                    irq_id_int;
logic [4:0]                    irq_core_resp_id_int;



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
