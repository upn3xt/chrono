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

var vars = std.StringHashMap(llvm.LLVMValueRef).init(std.heap.page_allocator);

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
    for (nodes) |node| {
        switch (node.kind) {
            .FunctionDeclaration => try createFunction(node, context, module, builder),
            .VariableDeclaration => try createVariable(node, context, builder),
            else => unreachable,
        }
    }
}

pub fn functionCall(context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef, func: llvm.LLVMValueRef) !void {
    // const func = node.data.FunctionReference;

    const i32_type = llvm.LLVMInt32TypeInContext(context);
    const call = llvm.LLVMBuildCall2(builder, i32_type, func, null, 0, "calltmp");

    _ = llvm.LLVMBuildRet(builder, call);
}

pub fn reassignment(node: ASTNode, context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef) !void {
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
            const variable = vars.get(varvarx.name);
            if (variable) |valueref|
                _ = llvm.LLVMBuildStore(builder, new_val, valueref);
        },
        else => {},
    }
}

pub fn createFunction(node: ASTNode, context: llvm.LLVMContextRef, module: llvm.LLVMModuleRef, builder: llvm.LLVMBuilderRef) !void {
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

        llvm.LLVMPositionBuilderAtEnd(builder, entry_bb);

        for (body) |b| {
            switch (b.kind) {
                .VariableDeclaration,
                => {
                    try createVariable(b, context, builder);
                },
                .Assignment => try reassignment(b, context, builder),
                else => unreachable,
            }
        }

        const ret_val = llvm.LLVMConstInt(i32_type, 0, 0);
        _ = llvm.LLVMBuildRet(builder, ret_val);
    } else {
        const func = llvm.LLVMAppendBasicBlock(fun, name_null.ptr);

        llvm.LLVMPositionBuilderAtEnd(builder, func);
        for (body) |b| {
            switch (b.kind) {
                .VariableDeclaration => try createVariable(b, context, builder),
                .Assignment => try reassignment(b, context, builder),
                else => unreachable,
            }
        }

        const ret_val = llvm.LLVMConstInt(i32_type, 0, 0);
        _ = llvm.LLVMBuildRet(builder, ret_val);
    }
}

pub fn createMain() !void {}

pub fn createVariable(node: ASTNode, context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef) !void {
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

            try vars.put(&name_buffer, variable);

            if (varvar.expression) |exp| {
                const raw_value = exp.data.NumberLiteral.value;
                const value = llvm.LLVMConstInt(i32_type, @intCast(raw_value), 0);
                if (varvar.mutable) _ = llvm.LLVMBuildStore(builder, value, variable);
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
