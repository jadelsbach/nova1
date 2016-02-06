
module tb;

   reg clk = 1;
   reg rst = 1;

   wire [0:15] mm_adr;
   wire        mm_we;
   wire [0:15] mm_din;
   wire [0:15] mm_dout;

   always #10 clk = ~clk;

   wire        bs_stb, we_we;
   wire [0:7]  bs_adr;
   wire [0:15] bs_dout;
   wire [0:15] bs_din;
   wire bs_rst;
   reg 	mm_inhibit = 1'b0;

   wire mm_grant;

   nova_ram ram(clk, rst, mm_adr, mm_we, mm_din, mm_dout);
   nova_cpu cpu(
		clk, rst,
		mm_grant, mm_inhibit, mm_adr, mm_we, mm_dout, mm_din,
		bs_rst, bs_stb, bs_we, bs_adr, bs_dout, bs_dout);
   nova_io_pio_snooper snoop(clk, rst, bs_stb, bs_we, bs_adr, bs_dout, bs_din);

   initial begin
      $dumpfile("nova_cpu.vcd");
      $dumpvars(0, ram);
      $dumpvars(0, cpu);
      #11 rst = 0;
      
     #100000 $finish();
   end
   
endmodule // tb
 
