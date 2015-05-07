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

`include "nova_defs.v"

module nova_io(pclk, prst,
	       io_inst, io_op, io_result, io_skip, io_busy, io_pulse,
	       bs_stb, bs_we, bs_adr, bs_dout, bs_din);

   input pclk;
   input prst;

   input [0:15] io_inst;
   input [0:15] io_op;
   output reg [0:15] io_result;
   output reg	 io_skip;
   output 	 io_busy;
   input 	 io_pulse;
   
   output reg	 bs_stb;
   output reg	 bs_we;
   output reg [0:7]  bs_adr;
   output reg [0:15] bs_dout;
   input [0:15]  bs_din;

   // Decode
   wire [0:1] 	 inst_acc;
   wire [0:2] 	 inst_transfer;
   wire [0:1] 	 inst_control;
   wire [0:5] 	 inst_device;

   assign inst_acc = io_inst[`NOVA_IO_ACC];
   assign inst_transfer = io_inst[`NOVA_IO_TRANSFER];
   assign inst_control = io_inst[`NOVA_IO_CONTROL];
   assign inst_device = io_inst[`NOVA_IO_DEVICE];

   wire [0:1] 	 w_register;
   assign w_register = (inst_transfer == `NOVA_IO_TRANSFER_DIA |
			inst_transfer == `NOVA_IO_TRANSFER_DOA) ? 2'b01 :
		       (inst_transfer == `NOVA_IO_TRANSFER_DIB |
			inst_transfer == `NOVA_IO_TRANSFER_DOB) ? 2'b10 :
		       (inst_transfer == `NOVA_IO_TRANSFER_DIC |
			inst_transfer == `NOVA_IO_TRANSFER_DOC) ? 2'b11 :
		       (inst_transfer == `NOVA_IO_TRANSFER_SKP |
			inst_transfer == `NOVA_IO_TRANSFER_NIO) ? 2'b00 :
		       2'bxx;
   
   reg [0:2] 	 r_state;
   reg [0:2] 	 r_state_next;

   localparam SIDLE = 3'b000;
   localparam SWAIT = 3'b001;
   localparam SREAD = 3'b010;
   localparam SSKIP = 3'b011;
   localparam SCNTR = 3'b100;
   
   assign io_busy = (|r_state) | io_pulse;
   
   always @(posedge pclk) begin
      if(prst) begin
	 io_result <= 16'h0000;
	 io_skip <= 1'b0;
	 //io_busy <= 1'b0;
	 bs_stb <= 1'b0;
	 bs_we <= 1'b0;
	 bs_adr <= 8'h00;
	 bs_dout <= 16'h0000;

	 r_state <= SIDLE;
	 r_state_next <= SIDLE;
      end
      else begin
	 case(r_state)
	   SIDLE:
	     begin
		if(io_pulse) begin
		   io_skip <= 1'b0;
		   bs_adr <= {inst_device, w_register};
		
		   if(io_inst[0:2] == 3'b011) begin
		      if(inst_transfer == `NOVA_IO_TRANSFER_DIA |
			 inst_transfer == `NOVA_IO_TRANSFER_DIB |
			 inst_transfer == `NOVA_IO_TRANSFER_DIC) begin
			 bs_stb <= 1'b1;
			 bs_we <= 1'b0;
			 r_state <= SWAIT;
			 r_state_next <= SREAD;
			 end
		      else if(inst_transfer == `NOVA_IO_TRANSFER_DOA |
			      inst_transfer == `NOVA_IO_TRANSFER_DOB |
			      inst_transfer == `NOVA_IO_TRANSFER_DOC |
			      inst_transfer == `NOVA_IO_TRANSFER_NIO) begin
			 bs_stb <= 1'b1;
			 bs_we <= 1'b1;
			 bs_dout <= io_op;
			 
			 if(|inst_control & 
			    inst_transfer != `NOVA_IO_TRANSFER_NIO) begin
			    r_state <= SCNTR;
			 end
			 else begin
			    r_state <= SWAIT;
			    r_state_next <= SIDLE;
			    end
		      end // if (inst_transfer == `NOVA_IO_TRANSFER_DOA |...
		      else if(inst_transfer == `NOVA_IO_TRANSFER_SKP) begin
		         bs_stb <= 1'b1;
		         bs_we <= 1'b0;
		         r_state <= SWAIT;
		         r_state_next <= SSKIP;
		      end
		   end // if (io_inst[0:2] == 3'b011)
		end
	     end // case: SIDLE
	   SREAD: begin
	      // TODO handle io errors (maybe?)
	      io_result <= bs_din;

	      if(|inst_control) begin
		 bs_we <= 1'b1;
		 bs_stb <= 1'b1;
		 bs_adr <= {inst_device, 2'b00};
		 bs_dout <= {14'h00, inst_control};
		 r_state <= SWAIT;
		 r_state_next <= SIDLE;
	      end
	      else
		r_state <= SIDLE;
	   end
	   SCNTR: 
	     begin
		bs_adr <= {inst_device, 2'b00};
		bs_dout <= {14'h00, inst_control};
		bs_we <= 1'b1;
		r_state <= SWAIT;
		r_state_next <= SIDLE;
	     end
	   SWAIT:
	     begin
		bs_stb <= 1'b0;
		r_state <= r_state_next;
	     end
	   SSKIP:
	     begin
		case(inst_control)
		  2'b00:
		    io_skip <= bs_din[0];
		  2'b01:
		    io_skip <= ~bs_din[0];
		  2'b10:
		    io_skip <= bs_din[1];
		  2'b11:
		    io_skip <= ~bs_din[1];
		endcase // case (inst_control)
		
		r_state <= SIDLE;
	     end
	 endcase // case (r_state)
      end
   end
      
endmodule // nova_io
