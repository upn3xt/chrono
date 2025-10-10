const std = @import("std");

const ASTNode = @import("../../chrono/ast/ast.zig").ASTNode;

const Walker = @This();
const llvm = @cImport({
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/Analysis.h");
    @cInclude("llvm-c/Target.h");
    @cInclude("llvm-c/TargetMachine.h");
});

const Function = struct {
    func: llvm.LLVMValueRef,
    func_type: llvm.LLVMTypeRef,
    args: []llvm.LLVMTypeRef,
    args_len: usize,
};

const Parameter = struct {
    name: []const u8,
    value: llvm.LLVMValueRef,
    ptype: llvm.LLVMTypeRef,
    index: usize,
};

var functionsmap = std.StringHashMap(Function).init(std.heap.page_allocator);

pub fn buildFile(filename: []const u8, nodes: []*ASTNode) !void {
    const context = llvm.LLVMContextCreate();
    defer llvm.LLVMContextDispose(context);

    const module = llvm.LLVMModuleCreateWithNameInContext(filename.ptr, context);
    defer llvm.LLVMDisposeModule(module);

    const builder = llvm.LLVMCreateBuilder();
    defer llvm.LLVMDisposeBuilder(builder);

    try Walker.walk(nodes, module, context, builder);

    const output_path = "output/main.o";
    try emitObjectFile(module, output_path);

    llvm.LLVMDumpModule(module);
}
/// Walks through the AST nodes and emits an object
pub fn walk(nodes: []*ASTNode, module: llvm.LLVMModuleRef, context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef) !void {
    var global = std.StringHashMap(llvm.LLVMValueRef).init(std.heap.page_allocator);
    for (nodes) |node| {
        switch (node.*.kind) {
            .FunctionDeclaration => try createFunction(node, context, module, builder),
            .VariableDeclaration => try createVariable(node, context, builder, &global),
            .FunctionReference => try functionCall(node, builder, module),
            else => unreachable,
        }
    }
}

pub fn functionCall(node: *ASTNode, builder: llvm.LLVMBuilderRef, module: llvm.LLVMModuleRef) !void {
    const func = node.*.data.FunctionReference;
    _ = module;
    const funcx = functionsmap.get(func.name) orelse return error.FunctionNull;

    // const cname = try std.fmt.allocPrint(std.heap.page_allocator, "{s}", .{func.name});
    const call = llvm.LLVMBuildCall2(builder, funcx.func_type, funcx.func, funcx.args.ptr, @intCast(funcx.args_len), func.name.ptr);
    _ = llvm.LLVMBuildRet(builder, call);
}
pub fn reassignment(node: *ASTNode, context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef, map: *std.StringHashMap(llvm.LLVMValueRef)) !void {
    if (node.*.kind != .Assignment) {
        std.debug.print("{}\n", .{node.*.kind});
        return error.ExpectedAssignmentNode;
    }

    const varvar = node.*.data.Assignment.variable;
    const varvarx = switch (varvar.kind) {
        .VariableReference => varvar.data.VariableReference,
        else => unreachable,
    };
    const asg = node.*.data.Assignment;

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

pub fn createFunction(node: *ASTNode, context: llvm.LLVMContextRef, module: llvm.LLVMModuleRef, builder: llvm.LLVMBuilderRef) !void {
    const name = node.*.data.FunctionDeclaration.name;
    std.debug.print("generating function {s}\n", .{name});
    const body = node.*.data.FunctionDeclaration.body;
    const parameters = node.*.data.FunctionDeclaration.parameters;
    // const fn_type = node.*.data.FunctionDeclaration.fn_type;
    // const value = node.*.data.FunctionDeclaration.value;

    var vars = std.StringHashMap(llvm.LLVMValueRef).init(std.heap.page_allocator);
    const i32_type = llvm.LLVMInt32Type();
    var pams = std.array_list.Managed(llvm.LLVMTypeRef).init(std.heap.page_allocator);
    var pamsLen: usize = 0;
    if (parameters) |params| {
        for (params) |p| {
            switch (p.kind) {
                .Parameter => {
                    switch (p.data.Parameter.par_type) {
                        .Int => {
                            try pams.append(i32_type);
                            pamsLen += 1;
                        },
                        else => {},
                    }
                },
                else => {
                    std.debug.print("nope, kind:{}\n", .{p.kind});
                    break;
                },
            }
        }
    }

    // const cname = try std.fmt.allocPrint(std.heap.page_allocator, "{s}", .{name});

    var pamsItems = std.array_list.Managed(llvm.LLVMTypeRef).init(std.heap.page_allocator);
    var valueIt = pams.valueIterator();
    while (valueIt.next()) |e| {
        try pamsItems.append(e.*);
    }
    const func_type = llvm.LLVMFunctionType(i32_type, pamsItems.items.ptr, @intCast(pamsLen), 0);
    const fun = llvm.LLVMAddFunction(module, name.ptr, func_type);
    _ = llvm.LLVMGetNamedFunction(module, name.ptr) orelse return error.FailedToAddFunction;

    var it = pams.iterator();
    var i: usize = 0;
    while (it.next()) |_| {
        i += 1;
        const param = llvm.LLVMGetParam(fun, @intCast(i));
        llvm.LLVMSetValueName(param, "x");
    }

    std.debug.print("Function {s} was added\n", .{name});
    // llvm.LLVMSetFunctionCallConv(fun, llvm.LLVMCCallConv);
    try functionsmap.put(name, .{ .func = fun, .func_type = func_type, .args = pamsItems.items, .args_len = pamsLen });
    const entry_bb = llvm.LLVMAppendBasicBlock(fun, "entry");

    llvm.LLVMPositionBuilderAtEnd(builder, entry_bb);
    for (body) |b| {
        switch (b.kind) {
            .VariableDeclaration => try createVariable(b, context, builder, &vars),
            .Assignment => try reassignment(b, context, builder, &vars),
            .FunctionReference => try functionCall(b, builder, module),
            .Return => break,
            else => unreachable,
        }
    }

    const ret_val = llvm.LLVMConstInt(i32_type, 0, 0);

    _ = llvm.LLVMBuildRet(builder, ret_val);
}

pub fn definePrintf(context: llvm.LLVMContextRef, module: llvm.LLVMModuleRef) llvm.LLVMValueRef {
    const printf_arg_t = llvm.LLVMPointerType(llvm.LLVMInt8TypeInContext(context), 0);
    const printf_type = llvm.LLVMFunctionType(llvm.LLVMInt32TypeInContext(context), &printf_arg_t, 1, 1); // vararg = 1
    return llvm.LLVMAddFunction(module, "printf", printf_type);
}

pub fn createVariable(node: *ASTNode, context: llvm.LLVMContextRef, builder: llvm.LLVMBuilderRef, map: *std.StringHashMap(llvm.LLVMValueRef)) !void {
    if (node.*.kind != .VariableDeclaration) {
        std.debug.print("{}\n", .{node.*.kind});
        return error.ExpectedVariableDeclarationNode;
    }

    const varvar = node.*.data.VariableDeclaration;
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
// pub fn emitObjectFile(
//     module: llvm.LLVMModuleRef,
//     output_path: []const u8,
// ) !void {
//     var errorx: [*c]u8 = null;
//
//     // Initialize native target for code generation
//     if (llvm.LLVMInitializeNativeTarget() != 0) {
//         std.debug.print("Failed to initialize native target", .{});
//         return error.TargetError;
//     }
//     if (llvm.LLVMInitializeNativeAsmPrinter() != 0) {
//         std.debug.print("Failed to initialize ASM printer", .{});
//         return error.ASMPrinterError;
//     }
//     if (llvm.LLVMInitializeNativeAsmParser() != 0) {
//         std.debug.print("Failed to initialize ASM parser", .{});
//         return error.ASMParserError;
//     }
//     var target: llvm.LLVMTargetRef = undefined;
//
//     // Get target triple for host
//     const target_triple = llvm.LLVMGetDefaultTargetTriple();
//
//     // Lookup target by triple
//     const ret = llvm.LLVMGetTargetFromTriple(target_triple, &target, &errorx);
//     if (ret != 0) {
//         std.debug.print("Failed to get target for triple", .{});
//         return error.TripleTargetError;
//     }
//
//     // Create target machine
//     const cpu = "generic";
//     const features = "";
//     const opt_level = llvm.LLVMCodeGenLevelDefault;
//     const reloc_mode = llvm.LLVMRelocDefault;
//     const code_model = llvm.LLVMCodeModelDefault;
//
//     const target_machine = llvm.LLVMCreateTargetMachine(
//         target,
//         target_triple,
//         cpu,
//         features,
//         opt_level,
//         reloc_mode,
//         code_model,
//     );
//
//     // Set module target triple and data layout
//     llvm.LLVMSetTarget(module, target_triple);
//     const data_layout_ref = llvm.LLVMCreateTargetDataLayout(target_machine);
//     const data_layout_str = llvm.LLVMGetDataLayoutStr(module);
//     llvm.LLVMSetDataLayout(module, data_layout_str);
//     // const data_layout_str = llvm.LLVMGetDataLayoutStr(data_layout_ref); // returns [*c]const u8
//     // llvm.LLVMSetDataLayout(module, data_layout_str);
//     // llvm.LLVMSetDataLayout(module, data_layout_str);
//
//     // Emit object file
//     if (llvm.LLVMTargetMachineEmitToFile(
//         target_machine,
//         module,
//         output_path.ptr,
//         llvm.LLVMObjectFile,
//         &errorx,
//     ) != 0) {
//         std.debug.print("Failed to emit object file", .{});
//         return error.EmitObjectFileError;
//     }
//
//     // Cleanup
//     llvm.LLVMDisposeTargetData(data_layout_ref);
//     llvm.LLVMDisposeTargetMachine(target_machine);
// }
//
pub fn emitObjectFile(
    module: llvm.LLVMModuleRef,
    output_path: []const u8,
) !void {
    var errorx: [*c]u8 = null;

    // Initialize native target
    if (llvm.LLVMInitializeNativeTarget() != 0) return error.TargetError;
    if (llvm.LLVMInitializeNativeAsmPrinter() != 0) return error.ASMPrinterError;
    if (llvm.LLVMInitializeNativeAsmParser() != 0) return error.ASMParserError;

    var target: llvm.LLVMTargetRef = undefined;
    const target_triple = llvm.LLVMGetDefaultTargetTriple();

    if (llvm.LLVMGetTargetFromTriple(target_triple, &target, &errorx) != 0) {
        defer if (errorx == null) llvm.LLVMDisposeMessage(errorx);
        return error.TripleTargetError;
    }

    const cpu = "generic";
    const features = "";
    const target_machine = llvm.LLVMCreateTargetMachine(
        target,
        target_triple,
        cpu,
        features,
        llvm.LLVMCodeGenLevelDefault,
        llvm.LLVMRelocDefault,
        llvm.LLVMCodeModelDefault,
    );
    if (target_machine == null) {
        return error.TargetMachineCreationFailed;
    }

    llvm.LLVMSetTarget(module, target_triple);

    const data_layout_ref = llvm.LLVMCreateTargetDataLayout(target_machine);
    const data_layout_str = llvm.LLVMGetDataLayoutStr(module);
    llvm.LLVMSetDataLayout(module, data_layout_str);

    // Emit to file, ensure output_path is null-terminated
    const coutpath = try std.fmt.allocPrint(std.heap.page_allocator, "{s}", .{output_path});
    if (llvm.LLVMTargetMachineEmitToFile(
        target_machine,
        module,
        coutpath.ptr,
        llvm.LLVMObjectFile,
        &errorx,
    ) != 0) {
        defer if (errorx == null) llvm.LLVMDisposeMessage(errorx);
        return error.EmitObjectFileError;
    }

    llvm.LLVMDisposeTargetData(data_layout_ref);
    llvm.LLVMDisposeTargetMachine(target_machine);
}
