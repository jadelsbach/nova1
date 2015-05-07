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

module nova_disa(clk, oe, inst, pc);
   input clk;
   input oe;
   input [0:15] inst;
   input [0:14] pc;
   

   wire [0:1] inst_io_acc;
   wire [0:2] inst_io_transfer;
   wire [0:1] inst_io_control;
   wire [0:5] inst_io_device;

   assign inst_io_acc      = inst[`NOVA_IO_ACC];
   assign inst_io_transfer = inst[`NOVA_IO_TRANSFER];
   assign inst_io_control  = inst[`NOVA_IO_CONTROL];
   assign inst_io_device   = inst[`NOVA_IO_DEVICE];

   wire [0:3] inst_cm_function;
   wire [0:1] inst_cm_srcacc;
   wire [0:1] inst_cm_dstacc;
   wire       inst_cm_load;
   wire [0:1] inst_cm_carry;
   wire [0:1] inst_cm_shift;
   wire [0:2] inst_cm_skip;

   assign inst_cm_function = inst[`NOVA_CM_FUNCTION];
   assign inst_cm_srcacc = inst[`NOVA_CM_SRCACC];
   assign inst_cm_dstacc = inst[`NOVA_CM_DSTACC];
   assign inst_cm_load   = inst[`NOVA_CM_LOAD];
   assign inst_cm_carry   = inst[`NOVA_CM_CARRY];
   assign inst_cm_shift   = inst[`NOVA_CM_SHIFT];
   assign inst_cm_skip   = inst[`NOVA_CM_SKIP];

   wire [0:4] inst_ls_function;
   wire       inst_ls_indirect;
   wire [0:7] inst_ls_displace;
   wire [0:1] inst_ls_acc;
   wire [0:1] inst_ls_mode;

   assign inst_ls_function = inst[`NOVA_LS_FUNCTION];
   assign inst_ls_indirect = inst[`NOVA_LS_INDIRECT];
   assign inst_ls_displace = inst[`NOVA_LS_DISPLACE];
   assign inst_ls_acc = inst[`NOVA_LS_ACC];
   assign inst_ls_mode = inst[`NOVA_LS_MODE];
   
      
   always @(posedge clk) begin
      if(oe) begin
	 $write(" %o/0x%h ", pc, pc);
	 
	 if(inst[0]) begin
	    case(inst_cm_function)
	      `NOVA_CM_FUNC_COM:
		$write("COM");
	      `NOVA_CM_FUNC_NEG:
		$write("NEG");
	      `NOVA_CM_FUNC_MOV:
		$write("MOV");
	      `NOVA_CM_FUNC_INC:
		$write("INC");	 
	      `NOVA_CM_FUNC_ADC:
		$write("ADC");
	      `NOVA_CM_FUNC_SUB:
		$write("SUB");
	      `NOVA_CM_FUNC_ADD:
		$write("ADD");
	      `NOVA_CM_FUNC_AND:
		$write("AND");     
	    endcase // case (inst_cm_function)
	    case(inst_cm_carry)
	      `NOVA_CM_CARRY_ZRO:
		$write("C");
	      `NOVA_CM_CARRY_ONE:
		$write("O");
	      `NOVA_CM_CARRY_INV:
		$write("C");
	    endcase // case (inst_cm_carry)
	    case(inst_cm_shift)
	      `NOVA_CM_SHIFT_SLL:
		$write("L");
	      `NOVA_CM_SHIFT_SRR:
		$write("R");
	      `NOVA_CM_SHIFT_SWP:
		$write("S");
	    endcase // case (inst_cm_shift)
	    $write(" %o,%o", inst_cm_srcacc, inst_cm_dstacc);
	    case(inst_cm_skip)
	      `NOVA_CM_SKIP_SKP:
		$write(", SKP");
	      `NOVA_CM_SKIP_SZC:
		$write(", SZC");
	      `NOVA_CM_SKIP_SNC:
		$write(", SNC");
	      `NOVA_CM_SKIP_SZR:
		$write(", SZR");
	      `NOVA_CM_SKIP_SNR:
		$write(", SNR");
	      `NOVA_CM_SKIP_SEZ:
		$write(", SEZ");
	      `NOVA_CM_SKIP_SBN:
		$write(", SBN");	      
	    endcase // case (inst_cm_skip)
	    $write("\n");
	 end // if (inst[0])
	 else if(inst[0:2] == 3'b011) begin
	    case(inst_io_transfer)
	      `NOVA_IO_TRANSFER_NIO:
		$write("NIO");
	      `NOVA_IO_TRANSFER_DIA:
		$write("DIA");
	      `NOVA_IO_TRANSFER_DOA:
		$write("DOA");
	      `NOVA_IO_TRANSFER_DIB:
		$write("DIB");
	      `NOVA_IO_TRANSFER_DOB:
		$write("DOB");
	      `NOVA_IO_TRANSFER_DIC:
		$write("DIC");
	      `NOVA_IO_TRANSFER_DOC:
		$write("DOC");
	      `NOVA_IO_TRANSFER_SKP:
		begin
		   case(inst_io_control)
		     2'b00:
		       $write("SKPBN");
		     2'b01:
		       $write("SKPBZ");
		     2'b10:
		       $write("SKPDN");
		     2'b11:
		       $write("SKPDZ");
		   endcase // case (inst_io_control)
		end
	    endcase // case (inst_io_transfer)
	    if(inst_io_transfer != `NOVA_IO_TRANSFER_SKP) begin
	       case(inst_io_control)
		 `NOVA_IO_CONTROL_STA:
		   $write("S");
		 `NOVA_IO_CONTROL_CLR:
		   $write("C");
		 `NOVA_IO_CONTROL_PLS:
		   $write("P");
	       endcase // case (inst_io_control)
	       $write(" %o, %o", inst_io_acc, inst_io_device);
	    end
	    else
	      $write(" %o", inst_io_device);
	    $write("\n");
	 end // if (inst[0:2] == 3'b011)
	 else begin
	    if(inst_ls_function[0:2] != 3'b001 &
	       inst_ls_function[0:2] != 3'b010) begin
	       if(~(|inst_ls_function))
		 $write("JMP");
	       else if(inst_ls_function == 5'b00001)
		 $write("JSR");
	       else if(inst_ls_function == 5'b00010)
		 $write("ISZ");
	       else if(inst_ls_function == 5'b00011)
		 $write("DSZ");
	       
	       if(inst_ls_indirect)
		 $write(" @%o", inst_ls_displace);
	       else
		 $write(" %o", inst_ls_displace);
	       $write("\n");
	       
	    end // if (inst_ls_function != 3'b001 &...
	    else begin
	       if(inst_ls_function[0:2] == 3'b001)
		 $write("LDA");
	       else if(inst_ls_function[0:2] == 3'b010)
		 $write("STA");
	       else $display("Unknown Instruction (%o) %b", inst, inst);

	       $write(" %o", inst_ls_acc);
	       	       
	       if(inst_ls_indirect)
		 $write(", @%o", inst_ls_displace);
	       else
		 $write(", %o", inst_ls_displace);

	       if((|inst_ls_mode))
		 $write(", %o", inst_ls_mode);
	       $write("\n");
	       
	    end // else: !if(inst_ls_function != 3'b001 &...
	 end // else: !if(inst[0:2] == 3'b011)
      end
   end
      
endmodule // nova_disa

 
