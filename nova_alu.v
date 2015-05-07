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

module nova_alu(
		pclk, prst,

		alu_inst, alu_op1, alu_op2, alu_result, alu_skip);
   input pclk;
   input prst;

   input [0:15] alu_inst;
   input [0:15] alu_op1;
   input [0:15] alu_op2;
   output reg [0:15] alu_result;
   output reg	     alu_skip;
   
   wire [0:1] 	 inst_carry;
   wire [0:2] 	 inst_func;
   wire 	 inst_load;
   wire [0:2] 	 inst_shift;
   wire [0:2] 	 inst_skip;
         
   assign inst_carry = alu_inst[`NOVA_CM_CARRY];
   assign inst_func  = alu_inst[`NOVA_CM_FUNCTION];
   assign inst_load  = alu_inst[`NOVA_CM_LOAD];
   assign inst_shift = alu_inst[`NOVA_CM_SHIFT];
   assign inst_skip  = alu_inst[`NOVA_CM_SKIP];
   
   reg 		 r_C;
   wire 	 w_C_ld;
   reg 		 r_carry;
   
   assign w_C_ld = (inst_carry == `NOVA_CM_CARRY_NOP) ? r_C  :
		   (inst_carry == `NOVA_CM_CARRY_ZRO) ? 0    :
		   (inst_carry == `NOVA_CM_CARRY_ONE) ? 1    :
 		   (inst_carry == `NOVA_CM_CARRY_INV) ? ~r_C :
		   1'bx;

   always @(posedge pclk) begin
      if(prst) begin
	 r_C <= 0;
	 alu_result <= 16'h00;
	 alu_skip <= 1'b0;
	 r_carry <= 1'b0;
      end
      else if(~alu_inst[`NOVA_CM_LOAD] & alu_inst[0]) begin
	 r_C <= r_carry;
      end 
   end

    always @* begin
      	 case(inst_func)
	   `NOVA_CM_FUNC_COM:
	     alu_result <= ~alu_op1;
	   `NOVA_CM_FUNC_NEG:
	     {r_carry, alu_result} <= {w_C_ld, (~alu_op1)} + 16'h01;
	   `NOVA_CM_FUNC_MOV :
	     alu_result <= alu_op1;
	   `NOVA_CM_FUNC_INC:
	     {r_carry, alu_result} <= {w_C_ld, alu_op1} + 16'h01;
	   `NOVA_CM_FUNC_ADC:
	     {r_carry, alu_result} <= {w_C_ld, ~alu_op1} + alu_op2;
	   `NOVA_CM_FUNC_SUB:
	     {r_carry, alu_result} <= {w_C_ld, ~alu_op1} + alu_op2 + 16'h01;
	   `NOVA_CM_FUNC_ADD:
	      {r_carry, alu_result} <= {w_C_ld, alu_op1} + alu_op2;
	   `NOVA_CM_FUNC_AND:
	     alu_result <= alu_op1 & alu_op2;
	 endcase
    end

   always @* begin
      case(inst_shift)
	`NOVA_CM_SHIFT_NOP:
	  alu_result = alu_result;
	`NOVA_CM_SHIFT_SLL:
	  {alu_result, r_carry} = {r_carry, alu_result};
	`NOVA_CM_SHIFT_SRR:
	  {r_carry, alu_result} = {alu_result, r_carry};
	`NOVA_CM_SHIFT_SWP:
	  alu_result = {alu_result[0:7], alu_result[8:15]};
      endcase 
   end 
   
   always @* begin
      case(inst_skip)
	`NOVA_CM_SKIP_NOP:
	  alu_skip <= 1'b0;
	`NOVA_CM_SKIP_SKP:
	  alu_skip <= 1'b1;
	`NOVA_CM_SKIP_SZC:
	  alu_skip <= ~r_carry;
	`NOVA_CM_SKIP_SNC:
	  alu_skip <= r_carry;
	`NOVA_CM_SKIP_SZR:
	  alu_skip <= ~|alu_result;
	`NOVA_CM_SKIP_SNR:
	  alu_skip <= |alu_result;
	`NOVA_CM_SKIP_SEZ:
	  alu_skip <= ~r_carry | (~|alu_result);
	`NOVA_CM_SKIP_SBN:
	  alu_skip <= r_carry | (|alu_result);
	endcase // case (instr_skip)
      end // always @ (fresult, r_carry, instr_skip)
   
endmodule // nova_alu
