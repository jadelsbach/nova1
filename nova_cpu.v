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

module nova_cpu(
		pclk, prst,
		mm_grant, mm_inhibit, mm_adr, mm_we, mm_din, mm_dout,
		bs_rst, bs_stb, bs_we, bs_adr, bs_dout, bs_din);
   input pclk;
   input prst;

   output reg mm_grant;
   input mm_inhibit;
   output reg [0:15] mm_adr;
   output reg	 mm_we;
   input [0:15]  mm_din;
   output reg [0:15] mm_dout;

   output bs_rst;
   output 	     bs_stb;
   output 	     bs_we;
   output [0:7]      bs_adr;
   output [0:15]     bs_dout;
   input [0:15]      bs_din;
      
   // Registers
   reg [0:14] r_PC;
   reg [0:15] r_AC0;
   reg [0:15] r_AC1;
   reg [0:15] r_AC2;
   reg [0:15] r_AC3;

   reg [0:15] r_inst;
   
   // Instruction decode
   wire [0:1] inst_io_acc;
   wire [0:2] inst_io_transfer;
   wire [0:1] inst_io_control;
   wire [0:5] inst_io_device;

   assign inst_io_acc      = r_inst[`NOVA_IO_ACC];
   assign inst_io_transfer = r_inst[`NOVA_IO_TRANSFER];
   assign inst_io_control  = r_inst[`NOVA_IO_CONTROL];
   assign inst_io_device   = r_inst[`NOVA_IO_DEVICE];
      
   wire [0:1] inst_cm_srcacc;
   wire [0:1] inst_cm_dstacc;
   wire       inst_cm_load;

   assign inst_cm_srcacc = r_inst[`NOVA_CM_SRCACC];
   assign inst_cm_dstacc = r_inst[`NOVA_CM_DSTACC];
   assign inst_cm_load   = r_inst[`NOVA_CM_LOAD];
      
   wire [0:4] inst_ls_function;
   wire       inst_ls_indirect;
   wire [0:7] inst_ls_displace;
   wire [0:1] inst_ls_acc;
   wire [0:1] inst_ls_mode;
   
   wire       w_ls_inst;

   assign w_ls_inst = (r_inst[0:2] == 3'b001)   | //LDA
		      (r_inst[0:2] == 3'b010)   | //SDA
		      (r_inst[0:4] == 5'b00000) | //JMP
		      (r_inst[0:4] == 5'b00001) | //JSR
		      (r_inst[0:4] == 5'b00010) | //ISZ
		      (r_inst[0:4] == 5'b00011);  //DSZ

   assign inst_ls_function = r_inst[`NOVA_LS_FUNCTION];
   assign inst_ls_indirect = r_inst[`NOVA_LS_INDIRECT];
   assign inst_ls_displace = r_inst[`NOVA_LS_DISPLACE];
   assign inst_ls_acc      = r_inst[`NOVA_LS_ACC];
   assign inst_ls_mode     = r_inst[`NOVA_LS_MODE];

   wire [0:14] w_unsigned_displace;
   assign w_unsigned_displace = (inst_ls_displace[0]) ? 
				{8'hff,inst_ls_displace} : inst_ls_displace;
   
   wire [0:14] w_E;
   assign w_E = (inst_ls_mode == `NOVA_LS_MODE_ZRO) ? 
		{7'h00, inst_ls_displace} :
		(inst_ls_mode == `NOVA_LS_MODE_PCR) ? 
		r_PC + w_unsigned_displace   :
		(inst_ls_mode == `NOVA_LS_MODE_AC2) ? 
		r_AC2 + w_unsigned_displace  :
		(inst_ls_mode == `NOVA_LS_MODE_AC3) ? 
		r_AC3 + w_unsigned_displace  : 16'hzzzz;

   reg [0:15]  r_saved_mem;
   reg 	       r_indirect;
   wire [0:14] w_addr;
   
   assign w_addr = (r_indirect) ? r_saved_mem[1:15] : w_E;
   wire[0:15] w_idsz = (inst_ls_function == 5'b00010) ? mm_din + 1 :
	      (inst_ls_function == 5'b00011) ? mm_din - 1 : 16'h0000;

   // ALU
   wire [0:15] alu_result;
   wire        alu_skip;
   wire [0:15] alu_op1;
   wire [0:15] alu_op2;

   assign alu_op1 = (inst_cm_srcacc == 2'b00) ? r_AC0 :
		    (inst_cm_srcacc == 2'b01) ? r_AC1 :
		    (inst_cm_srcacc == 2'b10) ? r_AC2 :
		    (inst_cm_srcacc == 2'b11) ? r_AC3 : 16'hxxxx;
   assign alu_op2 = (inst_cm_dstacc == 2'b00) ? r_AC0 :
		    (inst_cm_dstacc == 2'b01) ? r_AC1 :
		    (inst_cm_dstacc == 2'b10) ? r_AC2 :
		    (inst_cm_dstacc == 2'b11) ? r_AC3 : 16'hxxxx; 
    
   nova_alu alu(pclk, prst,
      		r_inst, alu_op1, alu_op2, alu_result, alu_skip);
   

   // IO
   wire [0:15] io_result;
   wire        io_skip;
   wire        io_busy;
   reg 	       io_pulse;
   wire        io_nosave;
   
   nova_io io(pclk, prst,
	      r_inst, alu_op2, io_result, io_skip, io_busy, io_pulse,
	       bs_stb, bs_we, bs_adr, bs_dout, bs_din);

   assign io_nosave = ((inst_io_device == 6'o77) & 
		       (inst_io_transfer == `NOVA_IO_TRANSFER_DIC)) |
		       (inst_io_transfer == `NOVA_IO_TRANSFER_DOA |
			inst_io_transfer == `NOVA_IO_TRANSFER_DOB |
			inst_io_transfer == `NOVA_IO_TRANSFER_DOC |
			inst_io_transfer == `NOVA_IO_TRANSFER_NIO |
			inst_io_transfer == `NOVA_IO_TRANSFER_SKP);

   // CPU device
   wire cntrl_halt;
   wire cntrl_intr;
   reg 	cntrl_intr_ack;

   nova_io_cpu cpu_dev(pclk, prst, 
		       bs_rst, bs_stb, bs_we, bs_adr, bs_din, bs_dout,
		       cntrl_halt, cntrl_intr, cntrl_intr_ack
		      );

   wire w_stall;
   assign w_stall = mm_inhibit | cntrl_halt;

   // State machine
   reg [0:2]   r_state;
   localparam SFETCHI1   = 3'b000;
   localparam SFETCHI2   = 3'b001;
   localparam SEXEC      = 3'b010;
   localparam SINDIRECT  = 3'b011;
   localparam SIDSZ      = 3'b100;
   localparam SFETCHD    = 3'b101;
   localparam SINDIRECTW = 3'b110;

   // synthesis translate_off
   nova_disa disassembler(pclk,io_pulse, r_inst, r_PC);
   // synthesis translate_on

   always @(posedge pclk) begin
      if(prst) begin
	 r_PC <= 2;   // XXX
	 r_AC0 <= 16'h0000;
	 r_AC1 <= 16'h0000;
	 r_AC2 <= 16'h0000;
	 r_AC3 <= 16'h0000;

	 mm_grant <= 1'b0;
	 mm_adr <= 16'hzzzz;
	 mm_dout <= 16'hzzzz;
	 mm_we <= 1'bz;

	 cntrl_intr_ack <= 1'b0;

	 r_state <= SFETCHI1;
	 r_inst <= 16'h0000;
	 r_indirect <= 1'b0;
	 r_saved_mem <= 16'h0000;

	 io_pulse <= 1'b0;
      end
      else begin
	 case(r_state)
	   SFETCHI1:
	     begin
		if(~w_stall) begin
		   if(cntrl_intr) begin
		      mm_we <= 1'b1;
		      mm_adr <= 16'h0000;
		      mm_dout <= r_PC;

		      r_inst <= 16'b0000_0100_0000_0001; // JMP @1
		      r_state <= SEXEC;
		      r_indirect <= 1'b0;

		      cntrl_intr_ack <= 1'b1;

		      // synthesis translate_off
		      $display("%m: Interrupt!\n");
		      // synthesis translate_on
		   end
		   else begin
		      mm_we <= 1'b0;
		      mm_adr <= r_PC;
		      mm_grant <= 1'b0;
		      r_state <= SFETCHI2;

		      r_indirect <= 1'b0;
		   end
		end
		else if(mm_inhibit) begin
		  mm_grant <= 1'b1;
		  mm_we <= 1'bz;
		  mm_adr <= 1'bz;
		  mm_dout <= 16'hzzzz;
		end  
	     end
	   SFETCHI2:
	     begin
		r_inst <= mm_din;
		r_state <= SEXEC;

		r_indirect <= 1'b0;
		io_pulse <= 1'b1;
	     end
	   SEXEC:
	     begin
		io_pulse <= 1'b0;
		cntrl_intr_ack <= 1'b0;
		mm_we <= 1'b0;

		if(w_ls_inst) begin
		   if(~r_indirect & inst_ls_indirect) begin
		      mm_we <= 1'b0;
		      mm_adr <= w_E;
		      r_state <= SINDIRECT;
		   end
		   else begin
		      if(inst_ls_function == 5'b00000) begin // JMP
			 r_PC <= w_addr;
			 r_state <= SFETCHI1;
//			 $display("%m JMP %h (%o)", w_addr, w_addr);	 
		      end
		      else if(inst_ls_function == 5'b00001) begin
			 r_AC3 <= r_PC + 1;
			 r_PC <= w_addr;
			 r_state <= SFETCHI1;
		      end
		      else if(inst_ls_function == 5'b00010 |      // ISZ
			      inst_ls_function == 5'b00011) begin // DSZ
			 mm_we <= 1'b0;
			 mm_adr <= w_addr;
			 r_state <= SIDSZ;
		      end
		      else if(inst_ls_function[0:2] == 3'b001) begin // LDA
			 mm_we <= 1'b0;
			 mm_adr <= w_addr;
			 r_state <= SFETCHD;
		      end
		      else if(inst_ls_function[0:2] == 3'b010) begin // STA
			 mm_we <= 1'b1;
			 mm_adr <= w_addr;
			 
			 case(inst_ls_acc)
			   2'b00:
			     mm_dout <= r_AC0;
			   2'b01:
			     mm_dout <= r_AC1;
			   2'b10:
			     mm_dout <= r_AC2;
			   2'b11:
			     mm_dout <= r_AC3;			   
			 endcase // case (inst_ls_acc)
			 
			 r_state <= SFETCHI1;
			 r_PC <= r_PC + 1;
		      end
		   end
		end // if (w_ls_inst)
		else if(r_inst[0]) begin //Compute
		   if(~inst_cm_load) begin
		      case(inst_cm_dstacc)
			2'b00:
			  r_AC0 <= alu_result;
			2'b01:
			  r_AC1 <= alu_result;
			2'b10:
			  r_AC2 <= alu_result;
			2'b11:
			  r_AC3 <= alu_result;
		      endcase // case (inst_cm_dstacc)
		   end // if (~inst_cm_load)
		   
		   //$display("%m INST: %h SKP: %b PC=%d", r_inst, alu_skip, r_PC);
		   
		   if(alu_skip)
		     r_PC <= r_PC + 2;
		   else
		     r_PC <= r_PC + 1;
		
		   r_state <= SFETCHI1;
		end // if (r_inst[0])
		else if(r_inst[0:2] == 3'b011) begin
		   if(~io_busy) begin
		      if(io_skip)
			r_PC <= r_PC + 2;
		      else
			r_PC <= r_PC + 1;

		      if(~io_nosave) begin
			 case(inst_io_acc)
			   2'b00:
			     r_AC0 <= io_result;
			   2'b01:
			     r_AC1 <= io_result;
			   2'b10:
			     r_AC2 <= io_result;
			   2'b11:
			     r_AC3 <= io_result;
			 endcase // case (inst_io_acc)
		      end // if (~io_nosave)
		      
		      r_state <= SFETCHI1;
		   end
		end // case: SEXEC
		// synthesis translate_off
		else
		  $display("Unknown Instruction %h", r_inst);
		// synthesis translate_on
		
	 end
	   SINDIRECT:
	     begin
		if(mm_adr >= 16'o20 && mm_adr <= 16'o37) begin
		   mm_we <= 1'b1;

		   if(mm_adr >= 16'o20 & mm_adr <= 16'o27)
		     mm_dout <= mm_din + 1;
		   else
		     mm_dout <= mm_din - 1;

		   r_state <= SINDIRECTW;
		   
		end
		else if(mm_din[0]) begin
		   mm_we <= 1'b0;
		   mm_adr <= mm_din[1:15];
		end
		else begin
		   r_saved_mem <= mm_din;
		   r_indirect <= 1'b1;
		   r_state <= SEXEC;
		   //$display("Indirection Resolve %h -> %h (%h)",
		   // w_E, mm_adr[1:15], mm_din);
		end
	     end // case: SINDIRECT
	   SINDIRECTW:
	     begin
		r_state <= SINDIRECT;
		mm_we <= 1'b0;
		
		if(mm_dout[0]) begin
		   mm_adr <= mm_dout;
		   r_state <= SINDIRECT;
		end
		else begin
		   r_saved_mem <= mm_dout;
		   r_indirect <= 1'b1;
		   r_state <= SEXEC;		   
		end
	     end
	   SIDSZ:
	     begin
		mm_we <= 1'b1;
		mm_dout <= w_idsz;
				
		if(~(|w_idsz))
		  r_PC <= r_PC + 2;
		else
		  r_PC <= r_PC + 1;
		
		r_state <= SFETCHI1;
	     end // case: SIDSZ
	   SFETCHD:
	     begin
		mm_we <= 1'b0;

		case(inst_ls_acc)
		  2'b00:
		    r_AC0 <= mm_din;
		  2'b01:
		    r_AC1 <= mm_din;
		  2'b10:
		    r_AC2 <= mm_din;
		  2'b11:
		    r_AC3 <= mm_din;
		endcase // case (inst_ls_acc)

		r_PC <= r_PC + 1;
		r_state <= SFETCHI1;
	     end
	 endcase // case (r_state)
      end
   end
   
endmodule 
