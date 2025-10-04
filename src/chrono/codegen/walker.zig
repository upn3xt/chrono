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

const Function = struct {
    func: llvm.LLVMValueRef,
    args: []llvm.LLVMValueRef,
    args_len: usize,
};

var functionsmap = std.StringHashMap(Function).init(std.heap.page_allocator);

pub fn buildFile(filename: []const u8, nodes: []ASTNode) !void {
    const context = llvm.LLVMContextCreate();
    defer llvm.LLVMContextDispose(context);

    const module = llvm.LLVMModuleCreateWithName(filename.ptr);
    defer llvm.LLVMDisposeModule(module);

    const builder = llvm.LLVMCreateBuilder();
    defer llvm.LLVMDisposeBuilder(builder);

    try Walker.walk(nodes, module, context, builder);

    try emitObjectFile(module, "output/main.o");

    llvm.LLVMDumpModule(module);
}
/// Walks through the AST nodes and emits an object
pub fn walk(nodes: []ASTNode, module: llvm.LLVMModuleRef, context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef) !void {
    var global = std.StringHashMap(llvm.LLVMValueRef).init(std.heap.page_allocator);
    for (nodes) |node| {
        switch (node.kind) {
            .FunctionDeclaration => try createFunction(node, context, module, builder),
            .VariableDeclaration => try createVariable(node, context, builder, &global),
            else => unreachable,
        }
    }
}

pub fn functionCall(node: ASTNode, context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef) !void {
    const func = node.data.FunctionReference;

    const funfun = functionsmap.get(func.name) orelse return error.FunctionNull;
    const i32_type = llvm.LLVMInt32TypeInContext(context);
    if (funfun.func == null) {
        return error.FunctionNull;
    }
    if (func.arguments) |argsm| {
        if (argsm.len != funfun.args_len) return error.DifferentArgNumbers;
    }

    // const fx = llvm.LLVMGetNamedFunction(module, func.name.ptr);
    const args: [*c]llvm.LLVMValueRef = funfun.args.ptr;
    const call = llvm.LLVMBuildCall2(builder, i32_type, funfun.func, args, @intCast(funfun.args_len), func.name.ptr);

    _ = llvm.LLVMBuildRet(builder, call);
}

pub fn reassignment(node: ASTNode, context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef, map: *std.StringHashMap(llvm.LLVMValueRef)) !void {
    if (node.kind != .Assignment) {
        std.debug.print("{}\n", .{node.kind});
        return error.ExpectedAssignmentNode;
    }

    const varvar = node.data.Assignment.variable;
    const varvarx = switch (varvar.kind) {
        .VariableReference => varvar.data.VariableReference,
        else => unreachable,
    };
    const asg = node.data.Assignment;

    switch (asg.expression.kind) {
        .NumberLiteral => {
            const i32_type = llvm.LLVMInt32TypeInContext(context);
            const value = asg.expression.data.NumberLiteral.value;

            const new_val = llvm.LLVMConstInt(i32_type, @intCast(value), 0);
            const variable = map.get(varvarx.name) orelse return error.VariableNull;
            if (variable) |valueref|
                _ = llvm.LLVMBuildStore(builder, new_val, valueref);
        },
        else => {},
    }
}

pub fn createFunction(node: ASTNode, context: llvm.LLVMContextRef, module: llvm.LLVMModuleRef, builder: llvm.LLVMBuilderRef) !void {
    const name = node.data.FunctionDeclaration.name;
    const body = node.data.FunctionDeclaration.body;
    const parameters = node.data.FunctionDeclaration.parameters;
    // const fn_type = node.data.FunctionDeclaration.fn_type;
    // const value = node.data.FunctionDeclaration.value;

    var vars = std.StringHashMap(llvm.LLVMValueRef).init(std.heap.page_allocator);
    const i32_type = llvm.LLVMInt32TypeInContext(context);
    const name_null = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{ name, "\x00" });

    if (std.mem.eql(u8, name, "main")) {
        const entry_bb = llvm.LLVMAppendBasicBlock(fun, "entry");

        llvm.LLVMPositionBuilderAtEnd(builder, entry_bb);
        var pams = std.array_list.Managed(llvm.LLVMValueRef).init(std.heap.page_allocator);
        if (parameters) |params| {
            for (params) |p| {
                switch (p.kind) {
                    .NumberLiteral => {
                        try pams.append(llvm.LLVMConstInt(llvm.LLVMInt32Type(), @intCast(p.data.NumberLiteral.value), 0));
                    },
                    // .StringLiteral => try pams.append(llvm.string),
                    //

                    else => {},
                }
            }
        }

        for (body) |b| {
            switch (b.kind) {
                .VariableDeclaration => try createVariable(b, context, builder, &vars),
                .Assignment => try reassignment(b, context, builder, &vars),
                .FunctionReference => try functionCall(b, context, builder),
                else => unreachable,
            }
        }

        const ret_val = llvm.LLVMConstInt(i32_type, 0, 0);

        const func_type = llvm.LLVMFunctionType(i32_type, pams.items.ptr, @intCast(pams.capacity), 0);
        const fun = llvm.LLVMAddFunction(module, name_null.ptr, func_type);
        llvm.LLVMSetFunctionCallConv(fun, llvm.LLVMCCallConv);
        try functionsmap.put(name, .{ .func = fun, .args = pams.items, .args_len = pams.capacity });
        _ = llvm.LLVMBuildRet(builder, ret_val);
    } else {
        const func = llvm.LLVMAppendBasicBlock(fun, name_null.ptr);
        var pams = std.array_list.Managed(llvm.LLVMValueRef).init(std.heap.page_allocator);
        if (parameters) |params| {
            for (params) |p| {
                switch (p.kind) {
                    .NumberLiteral => try pams.append(llvm.LLVMConstInt(llvm.LLVMInt32Type(), @intCast(p.data.NumberLiteral.value), 0)),

                    // .StringLiteral => try pams.append(llvm.string),
                    //

                    else => {},
                }
            }
        }
        llvm.LLVMPositionBuilderAtEnd(builder, func);
        for (body) |b| {
            switch (b.kind) {
                .VariableDeclaration => try createVariable(b, context, builder, &vars),
                .Assignment => try reassignment(b, context, builder, &vars),
                else => unreachable,
            }
        }

        const ret_val = llvm.LLVMConstInt(i32_type, 0, 0);

        const func_type = llvm.LLVMFunctionType(i32_type, pams.items.ptr, @intCast(pams.capacity), 0);
        const fun = llvm.LLVMAddFunction(module, name_null.ptr, func_type);
        llvm.LLVMSetFunctionCallConv(fun, llvm.LLVMCCallConv);
        try functionsmap.put(name, .{ .func = fun, .args = pams.items, .args_len = pams.capacity });
        _ = llvm.LLVMBuildRet(builder, ret_val);
    }
}

pub fn definePrintf(context: llvm.LLVMContextRef, module: llvm.LLVMModuleRef) llvm.LLVMValueRef {
    const printf_arg_t = llvm.LLVMPointerType(llvm.LLVMInt8TypeInContext(context), 0);
    const printf_type = llvm.LLVMFunctionType(llvm.LLVMInt32TypeInContext(context), &printf_arg_t, 1, 1); // vararg = 1
    return llvm.LLVMAddFunction(module, "printf", printf_type);
}

pub fn createVariable(node: ASTNode, context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef, map: *std.StringHashMap(llvm.LLVMValueRef)) !void {
    if (node.kind != .VariableDeclaration) {
        std.debug.print("{}\n", .{node.kind});
        return error.ExpectedVariableDeclarationNode;
    }

    const varvar = node.data.VariableDeclaration;
    switch (varvar.var_type) {
        .Int => {
            const i32_type = llvm.LLVMInt32TypeInContext(context);
            var name_buffer: [64]u8 = undefined;
            _ = @memcpy(name_buffer[0..varvar.name.len], varvar.name);
            name_buffer[varvar.name.len] = 0; // null terminate
            const variable = llvm.LLVMBuildAlloca(builder, i32_type, &name_buffer[0]);

            if (varvar.expression) |exp| {
                const raw_value = exp.data.NumberLiteral.value;
                const value = llvm.LLVMConstInt(i32_type, @intCast(raw_value), 0);
                if (varvar.mutable) _ = llvm.LLVMBuildStore(builder, value, variable);
                try map.put(varvar.name, variable);
            } else return error.ExpressionIsNull;
        },
        else => unreachable,
    }
}
pub fn emitObjectFile(
    module: llvm.LLVMModuleRef,
    output_path: [*:0]const u8,
) !void {
    var errorx: [*c]u8 = null;

    // Initialize native target for code generation
    if (llvm.LLVMInitializeNativeTarget() != 0) {
        std.debug.print("Failed to initialize native target", .{});
        return error.TargetError;
    }
    if (llvm.LLVMInitializeNativeAsmPrinter() != 0) {
        std.debug.print("Failed to initialize ASM printer", .{});
        return error.ASMPrinterError;
    }
    if (llvm.LLVMInitializeNativeAsmParser() != 0) {
        std.debug.print("Failed to initialize ASM parser", .{});
        return error.ASMParserError;
    }
    var target: llvm.LLVMTargetRef = undefined;

    // Get target triple for host
    const target_triple = llvm.LLVMGetDefaultTargetTriple();

    // Lookup target by triple
    const ret = llvm.LLVMGetTargetFromTriple(target_triple, &target, &errorx);
    if (ret != 0) {
        std.debug.print("Failed to get target for triple", .{});
        return error.TripleTargetError;
    }

    // Create target machine
    const cpu = "generic";
    const features = "";
    const opt_level = llvm.LLVMCodeGenLevelDefault;
    const reloc_mode = llvm.LLVMRelocDefault;
    const code_model = llvm.LLVMCodeModelDefault;

    const target_machine = llvm.LLVMCreateTargetMachine(
        target,
        target_triple,
        cpu,
        features,
        opt_level,
        reloc_mode,
        code_model,
    );

    // Set module target triple and data layout
    llvm.LLVMSetTarget(module, target_triple);
    const data_layout_ref = llvm.LLVMCreateTargetDataLayout(target_machine);
    // const data_layout_str = llvm.LLVMGetDataLayoutStr(data_layout_ref); // returns [*c]const u8
    // llvm.LLVMSetDataLayout(module, data_layout_str);
    // llvm.LLVMSetDataLayout(module, data_layout_str);

    // Emit object file
    if (llvm.LLVMTargetMachineEmitToFile(
        target_machine,
        module,
        output_path,
        llvm.LLVMObjectFile,
        &errorx,
    ) != 0) {
        std.debug.print("Failed to emit object file", .{});
        return error.EmitObjectFileError;
    }

    // Cleanup
    llvm.LLVMDisposeTargetData(data_layout_ref);
    llvm.LLVMDisposeTargetMachine(target_machine);
}
