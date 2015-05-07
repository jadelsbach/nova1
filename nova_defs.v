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

// IO
`define NOVA_IO_ACC      3:4
`define NOVA_IO_TRANSFER 5:7
`define NOVA_IO_CONTROL  8:9
`define NOVA_IO_DEVICE   10:15

`define NOVA_IO_CONTROL_NOP 2'b00
`define NOVA_IO_CONTROL_STA 2'b01
`define NOVA_IO_CONTROL_CLR 2'b10
`define NOVA_IO_CONTROL_PLS 2'b11

`define NOVA_IO_TRANSFER_NIO 3'b000
`define NOVA_IO_TRANSFER_DIA 3'b001
`define NOVA_IO_TRANSFER_DOA 3'b010
`define NOVA_IO_TRANSFER_DIB 3'b011
`define NOVA_IO_TRANSFER_DOB 3'b100
`define NOVA_IO_TRANSFER_DIC 3'b101
`define NOVA_IO_TRANSFER_DOC 3'b110
`define NOVA_IO_TRANSFER_SKP 3'b111

// Compute instruction carry control
`define NOVA_CM_CARRY_NOP 2'b00
`define NOVA_CM_CARRY_ZRO 2'b01
`define NOVA_CM_CARRY_ONE 2'b10
`define NOVA_CM_CARRY_INV 2'b11

`define NOVA_CM_SHIFT_NOP 2'b00
`define NOVA_CM_SHIFT_SLL 2'b01
`define NOVA_CM_SHIFT_SRR 2'b10
`define NOVA_CM_SHIFT_SWP 2'b11

`define NOVA_CM_FUNC_COM 3'b000
`define NOVA_CM_FUNC_NEG 3'b001
`define NOVA_CM_FUNC_MOV 3'b010
`define NOVA_CM_FUNC_INC 3'b011
`define NOVA_CM_FUNC_ADC 3'b100
`define NOVA_CM_FUNC_SUB 3'b101
`define NOVA_CM_FUNC_ADD 3'b110
`define NOVA_CM_FUNC_AND 3'b111

`define NOVA_CM_SKIP_NOP 3'b000
`define NOVA_CM_SKIP_SKP 3'b001
`define NOVA_CM_SKIP_SZC 3'b010
`define NOVA_CM_SKIP_SNC 3'b011
`define NOVA_CM_SKIP_SZR 3'b100
`define NOVA_CM_SKIP_SNR 3'b101
`define NOVA_CM_SKIP_SEZ 3'b110
`define NOVA_CM_SKIP_SBN 3'b111

// Compute instruction decode
`define NOVA_CM_SRCACC    1:2
`define NOVA_CM_DSTACC    3:4
`define NOVA_CM_FUNCTION  5:7
`define NOVA_CM_SHIFT     8:9
`define NOVA_CM_CARRY    10:11
`define NOVA_CM_LOAD     12
`define NOVA_CM_SKIP     13:15

// Memory instructions
`define NOVA_LS_FUNCTION   0:4
`define NOVA_LS_INDIRECT    5
`define NOVA_LS_MODE       6:7
`define NOVA_LS_DISPLACE  8:15
`define NOVA_LS_ACC       3:4

`define NOVA_LS_MODE_ZRO 2'b00
`define NOVA_LS_MODE_PCR 2'b01
`define NOVA_LS_MODE_AC2 2'b10
`define NOVA_LS_MODE_AC3 2'b11
