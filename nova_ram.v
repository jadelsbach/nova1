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

module nova_ram(pclk, prst, mm_adr, mm_we, mm_din, mm_dout);
   parameter addr_width = 16;
   parameter mem_size = 1 << addr_width;
   parameter mem_mask = mem_size-1;
   
   input pclk;
   input prst;

   input [0:15] mm_adr;
   input 	mm_we;
   input [0:15] mm_din;
   output [0:15] mm_dout;

   reg [0:15] 	 m_mem[0:mem_size];
   wire [0:addr_width-1] w_adr_masked;
   
   integer 	 i;

   assign w_adr_masked = mm_adr[0:addr_width-1];
   assign mm_dout = (~mm_we) ? m_mem[w_adr_masked] : 16'h0000;
      
   always @(posedge pclk) begin
      if(prst) begin	 
	for(i = 0; i < mem_size; i = i + 1)
	   m_mem[i] <= 16'h0000;
//	   #9 $readmemh("rdos.hex", m_mem);
      end
      else begin
	 if(mm_we) begin
	   // $display("M[%h] = %h", mm_adr, mm_din);
	    
	   m_mem[w_adr_masked] <= mm_din;
	 end
      end
   end
   
endmodule // nova_ram 
