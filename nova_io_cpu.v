//
//    Copyright (c) 2014 Jan Adelsbach <jan@janadelsbach.com>.  
//    All Rights Reserved.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

module nova_io_cpu(pclk, prst,
		   bs_rst, bs_stb, bs_we, bs_adr, bs_din, bs_dout,
		   cntrl_halt, cntrl_intr, cntrl_intr_ack
		   );
   input pclk;
   input prst;
   output bs_rst;
   input bs_stb;
   input bs_we;
   input [0:7] bs_adr;
   input [0:15] bs_din;
   output reg [0:15] bs_dout;

   output reg cntrl_halt;
   output reg cntrl_intr;
   input      cntrl_intr_ack;


   parameter device_addr = 6'o77;

   reg 		     r_int_en;
   reg [0:15] 	     r_int_mask;
   reg r_iorst;

   assign bs_rst = prst | r_iorst;

   // XXX
   integer i = 0;
   reg 	   tmp = 1;


   always @(posedge pclk) begin

      // XXX
      i  = i+1;
      if(i > 200) begin
	 cntrl_intr <= tmp;
	 tmp = 0;
      end

      if(prst) begin
	 bs_dout <= 16'hzzzz;
	 r_int_en <= 1'b0;
	 r_int_mask <= 16'h0000;
	 cntrl_halt <= 1'b0;
	 cntrl_intr <= 1'b0;
	 r_iorst <= 1'b0;
      end
      else begin
	 if(cntrl_intr & cntrl_intr_ack) begin
	    cntrl_intr <= 1'b0;
	    r_int_en <= 1'b0;
	 end

	 if(bs_stb & bs_adr[0:5] == device_addr) begin
	    if(bs_we) begin
	       case(bs_adr[6:7])
		 2'b00:
		   begin
		      case(bs_din[14:15])
			2'b00:
			  $display("%m Spurious Update");
			2'b01:
			  r_int_en <= 1'b1;
			2'b10:
			  r_int_en <= 1'b0;
			2'b11:
			  $display("%m 64K Enable? %b (unsupported)", bs_din[0]);
		      endcase // case (bs_din[0:1])
		   end
		 2'b01:
		   $display("%m DOA %h", bs_din);
		 2'b10: // READA
		   r_int_mask <= bs_din;
		 2'b11: // HALT
		   cntrl_halt <= 1'b1;
	       endcase // case (bs_adr[6:7])
	    end // if (bs_we)
	    else begin
	       case(bs_adr[6:7])
		 2'b00:
		   $display("%m Flag Read");
		 2'b01:
		   bs_dout <= 16'h8010;
		 2'b10:
		   $display("%m DIB"); // INTA
		 2'b11: // IORST
		   begin
		    r_int_mask = 0;
		    r_iorst <= 1'b1;
		   end
	       endcase // case (bs_adr[6:7])	    
	    end // else: !if(bs_we)
	 end
	 else begin
	  bs_dout <= 16'hzzzz;
	  r_iorst <= 1'b0;
	 end
      end
   end
endmodule // nova_io_cpu
