# First print of AST

Tokens size:5

chrono.ast.NodeKind.VariableDeclaration
	chrono.ast__union_23939{ .VariableDeclaration = chrono.ast__union_23939__struct_23940{ .name = { 120 }, .expression = chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23939{ ... } } } }


## First multiple assignmet

Tokens size:26

Nodes has length of 5
Kind: VariableDeclaration
	VariableDeclaration:
	x
chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23949{ .NumberLiteral = chrono.ast__union_23949__struct_23952{ .value = 20 } } }
Kind: VariableDeclaration
	VariableDeclaration:
	y
chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23949{ .NumberLiteral = chrono.ast__union_23949__struct_23952{ .value = 40 } } }
Kind: VariableDeclaration
	VariableDeclaration:
	z
chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23949{ .NumberLiteral = chrono.ast__union_23949__struct_23952{ .value = 50 } } }
Kind: Assignment
	Assignment:
	chrono.ast{ .kind = chrono.ast.NodeKind.VariableReference, .data = chrono.ast__union_23949{ .VariableReference = chrono.ast__union_23949__struct_23951{ .name = { ... } } } }
chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23949{ .NumberLiteral = chrono.ast__union_23949__struct_23952{ .value = 25 } } }
Kind: Assignment
	Assignment:
	chrono.ast{ .kind = chrono.ast.NodeKind.VariableReference, .data = chrono.ast__union_23949{ .VariableReference = chrono.ast__union_23949__struct_23951{ .name = { ... } } } }
chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23949{ .NumberLiteral = chrono.ast__union_23949__struct_23952{ .value = 45 } } }


## Multiple declarations, assignments and variable references

Last token type: chrono.token{ .token_type = chrono.token.TokenType{ .EOF = void }, .lexeme = {  } }
Tokens size:30

Nodes has length of 8
Kind: VariableDeclaration
	VariableDeclaration:
	x
chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23955{ .NumberLiteral = chrono.ast__union_23955__struct_23958{ .value = 20 } } }
Kind: VariableDeclaration
	VariableDeclaration:
	y
chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23955{ .NumberLiteral = chrono.ast__union_23955__struct_23958{ .value = 40 } } }
Kind: VariableDeclaration
	VariableDeclaration:
	z
chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23955{ .NumberLiteral = chrono.ast__union_23955__struct_23958{ .value = 50 } } }
Kind: Assignment
	Assignment:
	chrono.ast{ .kind = chrono.ast.NodeKind.VariableReference, .data = chrono.ast__union_23955{ .VariableReference = chrono.ast__union_23955__struct_23957{ .name = { ... } } } }
chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23955{ .NumberLiteral = chrono.ast__union_23955__struct_23958{ .value = 25 } } }
Kind: Assignment
	Assignment:
	chrono.ast{ .kind = chrono.ast.NodeKind.VariableReference, .data = chrono.ast__union_23955{ .VariableReference = chrono.ast__union_23955__struct_23957{ .name = { ... } } } }
chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23955{ .NumberLiteral = chrono.ast__union_23955__struct_23958{ .value = 45 } } }
Kind: VariableReference
	VariableReference:
	z
Kind: VariableReference
	VariableReference:
	x
Kind: VariableReference
	VariableReference:
	y

## First operation

operation: 10 + 20
Nodes has length of 1
Kind: BinaryOperator
	BinaryOperator:
	Left: chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23960{ .NumberLiteral = chrono.ast__union_23960__struct_23963{ .value = 10 } } }
Operator: +
Right: chrono.ast{ .kind = chrono.ast.NodeKind.NumberLiteral, .data = chrono.ast__union_23960{ .NumberLiteral = chrono.ast__union_23960__struct_23963{ .value = 20 } } }


## First function call

ModuleID = 'assig.chro'
source_filename = "assig.chro"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

define i32 @bro(i32 %x) {
entry:
  %w = alloca i32, align 4
  ret i32 0
}

define i32 @main() {
entry:
  %t = alloca i32, align 4
  store i32 20, ptr %t, align 4
  %y = alloca i32, align 4
  store i32 2000, ptr %t, align 4
  %bro = call i32 @bro(i32 1)
  ret i32 0
}
Emition done!


## Hello world

   chrono   git:(main)  zig build run -freference-trace=10 -- ts/helloworld.chro
Lines: 0
Starting Tokenization...
Tokenization done.
Starting Parsing...
function main
fn main defined!
Parsing done.
LLVM Emit Object...
func_type: half
val_type: ptr
func_type pointer: cimport.struct_LLVMOpaqueType@6eb44e0
 builder: 0x6ebd000
 func_type: 0x6eb44e0
 function: 0x6ebe2c8
 args.items.ptr: 0x7fa678720288
 argument length: 1
 cname.ptr: 0x7fa678720274
; ModuleID = 'helloworld.chro'
source_filename = "helloworld.chro"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@name = private unnamed_addr constant [13 x i8] c"Hello world!\00", align 1

declare i32 @printf(ptr %0, ...)

define i32 @main() {
entry:
  %0 = call i32 (ptr, ...) @printf(ptr @name)
  ret i32 0
}
Emition done!
   chrono   git:(main)  clang -fPIE output/main.o -o main
   chrono   git:(main)  ./main
Hello world!%                                                                                                                                                        chrono   git:(main)  
