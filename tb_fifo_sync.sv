`timescale 1ns / 1ps
module tb_fifo_sync();

logic clk, reset_n, cs, rd_en, wr_en;
logic [31:0] data_in;
logic [31:0] data_out;
logic empty, full;

logic [31:0] ref_queue[$];
int error_count = 0;
int test_count  = 0;

fifo_sync DUT(clk, reset_n, cs, wr_en, rd_en,
              data_in, data_out, empty, full);

initial clk = 0;
always #5 clk = ~clk;

task write_data(input logic [31:0] d_in);
  if (!full) begin
    @(posedge clk); #1;
    cs      = 1;
    wr_en   = 1;
    data_in = d_in;
    ref_queue.push_back(d_in);
    $display("[%0t] WRITE data_in = %0d | full = %b | empty = %b",
              $time, d_in, full, empty);
    @(posedge clk); #1;
    wr_en   = 0;
    data_in = 0;
  end else begin
    $display("[%0t] WRITE SKIPPED - FIFO full", $time);
  end
endtask

task read_data();
  logic [31:0] expected;
  if (!empty) begin
    @(posedge clk); #1;
    cs    = 1;
    rd_en = 1;
    @(posedge clk); #1;
    rd_en    = 0;
    expected = ref_queue.pop_front();
    test_count++;
    if (data_out === expected)
      $display("[%0t] READ Got = %0d | Expected = %0d | PASS",
                $time, data_out, expected);
    else begin
      $display("[%0t] READ Got = %0d | Expected = %0d | FAIL <<<",
                $time, data_out, expected);
      error_count++;
    end
  end else begin
    $display("[%0t] READ SKIPPED - FIFO empty", $time);
  end
endtask

property not_full_and_empty;
  @(posedge clk) !(full && empty);
endproperty
assert property(not_full_and_empty)
  else $error("ASSERTION FAILED: full and empty both high");

property empty_after_reset;
  @(posedge clk) $rose(reset_n) |-> empty;
endproperty
assert property(empty_after_reset)
  else $error("ASSERTION FAILED: not empty after reset");

property no_x_on_read;
  @(posedge clk) (cs && rd_en && !empty) |->
                 !$isunknown(data_out);
endproperty
assert property(no_x_on_read)
  else $error("ASSERTION FAILED: X on data_out during read");

covergroup fifo_cg @(posedge clk);
  cp_full  : coverpoint full  { bins is_full  = {1}; bins not_full  = {0}; }
  cp_empty : coverpoint empty { bins is_empty = {1}; bins not_empty = {0}; }
  cp_wr    : coverpoint wr_en { bins writing  = {1}; }
  cp_rd    : coverpoint rd_en { bins reading  = {1}; }
  cx_rw    : cross cp_wr, cp_rd;
endgroup
fifo_cg cg_inst = new();

initial begin
  $display("=== FIFO SV Testbench Start ===");

  reset_n = 0; rd_en = 0; wr_en = 0; cs = 1; data_in = 0;
  ref_queue = {};
  repeat(3) @(posedge clk);
  reset_n = 1;
  repeat(2) @(posedge clk);
  $display("[RESET] Done");

  // TEST 1: Write until full
  $display("\n--- TEST 1: Write 8 values ---");
  for (int i = 0; i < 8; i++)
    write_data(2**i);
  repeat(2) @(posedge clk);

  // TEST 2: Read all and verify
  $display("\n--- TEST 2: Read and verify ---");
  for (int i = 0; i < 8; i++)
    read_data();
  repeat(2) @(posedge clk);

  // TEST 3: Fill then drain with different data
  $display("\n--- TEST 3: Fill then drain ---");
  reset_n   = 0;
  rd_en     = 0;
  wr_en     = 0;
  ref_queue = {};
  repeat(3) @(posedge clk);
  reset_n = 1;
  repeat(2) @(posedge clk);
  for (int i = 0; i < 8; i++)
    write_data(i + 100);
  repeat(2) @(posedge clk);
  for (int i = 0; i < 8; i++)
    read_data();
  repeat(2) @(posedge clk);

  // Summary
  $display("\n=== TEST SUMMARY ===");
  $display("Total checks : %0d", test_count);
  $display("Errors       : %0d", error_count);
  if (error_count == 0)
    $display("ALL TESTS PASSED");
  else
    $display("TESTS FAILED - %0d errors", error_count);

  $display("=== Testbench Complete ===");
  #40 $finish;
end

endmodule