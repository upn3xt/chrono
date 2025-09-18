const Walker = @This();
const std = @import("std");
const Import = @import("../imports.zig");
const ASTNode = Import.ASTNode;
const llvm = @cImport({
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/Analysis.h");
    @cInclude("llvm-c/Target.h");
    @cInclude("llvm-c/TargetMachine.h");
});

/// Walks through the AST nodes and emits an object
pub fn walk(nodes: []ASTNode, module: llvm.LLVMModuleRef, context: llvm.LLVMContextRef) !void {
    for (nodes) |node| {
        switch (node.kind) {
            .FunctionDeclaration => {
                const name = node.data.FunctionDeclaration.name;
                const body = node.data.FunctionDeclaration.body;
                // const parameters = node.data.FunctionDeclaration.parameters;
                // const fn_type = node.data.FunctionDeclaration.fn_type;
                // const value = node.data.FunctionDeclaration.value;

                const i32_type = llvm.LLVMInt32TypeInContext(context);
                const func_type = llvm.LLVMFunctionType(i32_type, null, 0, 0);
                const name_null = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{ name, "\x00" });

                const fun = llvm.LLVMAddFunction(module, name_null.ptr, func_type);
                llvm.LLVMSetFunctionCallConv(fun, llvm.LLVMCCallConv);
                if (std.mem.eql(u8, name, "main")) {
                    const entry_bb = llvm.LLVMAppendBasicBlock(fun, "entry");
                    const builder = llvm.LLVMCreateBuilderInContext(context);
                    defer llvm.LLVMDisposeBuilder(builder);

                    llvm.LLVMPositionBuilderAtEnd(builder, entry_bb);

                    for (body) |b| {
                        switch (b.kind) {
                            .VariableDeclaration => {
                                try createVariable(b, context, builder);
                            },
                            else => unreachable,
                        }
                    }

                    const ret_val = llvm.LLVMConstInt(i32_type, 0, 0);
                    _ = llvm.LLVMBuildRet(builder, ret_val);
                } else {
                    const builder = llvm.LLVMCreateBuilderInContext(context);
                    defer llvm.LLVMDisposeBuilder(builder);

                    for (body) |b| {
                        switch (b.kind) {
                            .VariableDeclaration => {
                                try createVariable(node, context, builder);
                            },
                            else => unreachable,
                        }
                    }

                    const ret_val = llvm.LLVMConstInt(i32_type, 0, 0);
                    _ = llvm.LLVMBuildRet(builder, ret_val);
                }
            },
            else => unreachable,
        }
    }
}

pub fn createMain() !void {}

pub fn createVariable(node: ASTNode, context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef) !void {
    if (node.kind != .VariableDeclaration) {
        std.debug.print("{}\n", .{node.kind});
        return error.ExpectedVariableDeclarationNode;
    }

    const varvar = node.data.VariableDeclaration;
    const null_name = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{ varvar.name, "\x00" });

    switch (varvar.var_type) {
        .Int => {
            const i32_type = llvm.LLVMInt32TypeInContext(context);
            const variable = llvm.LLVMBuildAlloca(builder, i32_type, null_name.ptr);
            if (varvar.expression) |exp| {
                const raw_value = exp.data.NumberLiteral.value;
                const value = llvm.LLVMConstInt(i32_type, @intCast(raw_value), 0);
                _ = llvm.LLVMBuildStore(builder, value, variable);
            } else return error.ExpressionIsNull;
        },
        else => unreachable,
    }
}

pub fn emitObject() !void {}
