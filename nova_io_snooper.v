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

module nova_io_pio_snooper(pclk, prst, bs_stb, bs_we, bs_adr, bs_din, bs_dout);
   input pclk;
   input prst;
   input bs_stb;
   input bs_we;
   input [0:7] bs_adr;
   input [0:15] bs_din;
   output [0:15] bs_dout;
      
   always @(posedge pclk) begin
	 if(bs_stb) begin
	    $display("%m Device %o Strobe! %h %b %b", 
		     bs_adr[0:5], bs_din, bs_adr[6:7], bs_we);

	    if(bs_we) begin
	       case(bs_adr[6:7])
		 2'b00:
		   begin
		      case(bs_din[14:15])
			2'b00:
			  $display("%m Spurious Update");
			2'b01:
			  $display("%m Start");
			2'b10:
			  $display("%m Clear");
			2'b11:
			  $display("%m Pulse");
		      endcase // case (bs_din[0:1])
		   end
		 2'b01:
		   $display("%m DOA %h", bs_din);
		 2'b10:
		   $display("%m DOB %h", bs_din);
		 2'b11:
		   $display("%m DOC %h", bs_din);
	       endcase // case (bs_adr[6:7])
	    end // if (bs_we)
	    else begin
		 case(bs_adr[6:7])
		   2'b00:
		     $display("%m Flag Read");     
		   2'b01:
		     $display("%m DIA");
		   2'b10:
		     $display("%m DIB");
		   2'b11:
		     $display("%m DIC");
		   endcase // case (bs_adr[6:7])
	    end // else: !if(bs_we)
	 end
   end
endmodule // nova_io_pio_snooper
