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

module nova_io_pio_dummy(pclk, bs_rst, bs_stb, bs_we, bs_adr, bs_din, bs_dout);
   input pclk;
   input bs_rst;
   input bs_stb;
   input bs_we;
   input [0:7] bs_adr;
   input [0:15] bs_din;
   output reg [0:15] bs_dout;

   parameter device_addr = 6'o00;
   
   reg 		     r_DONE;
   reg 		     r_BUSY;
   
   
   always @(posedge pclk) begin
      if(bs_rst) begin
	 bs_dout <= 16'hzzzz;
	 r_DONE <= 1'b1;
	 r_BUSY <= 1'b0;
      end
      else begin
	 if(bs_stb & bs_adr[0:5] == device_addr) begin
	    if(bs_we) begin
	       case(bs_adr[6:7])
		 2'b00:
		   begin
		      case(bs_din[14:15])
			2'b01:
			  begin
			     r_DONE <= 1'b0;
			     r_BUSY <= 1'b1;
			  end
			2'b10:
			  begin
			     r_DONE <= 1'b0;
			     r_BUSY <= 1'b0;
			  end
			2'b11:
			  begin
			     // Pulse
			  end
		      endcase // case (bs_din[14:15])
		   end // case: 2'b00
		 2'b01:
		   $display("DOA");
		 2'b10:
		   $display("DOB");
		 2'b11:
		   $display("DOC");
	       endcase // case (bs_adr[6:7])
	    end // if (bs_we)
	    else begin
	       case(bs_adr[6:7])
		 2'b00:
		   bs_dout <=  {r_BUSY, r_DONE, 14'h0000};
		 2'b01:
		   $display("%m DIA");
		 2'b10:
		   $display("%m DIB");
		 2'b11:
		   $display("%m DIC");
	       endcase // case (bs_adr[6:7])
	    end // else: !if(bs_we)
	 end // if (bs_stb & bs_adr[0:5] == device_addr)
	 else
	   bs_dout <= 16'hzzzz;
      end
   end
endmodule // nova_io_pio_dummy
