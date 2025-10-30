const std = @import("std");
const llvm = @cImport({
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/Analysis.h");
    @cInclude("llvm-c/Target.h");
    @cInclude("llvm-c/TargetMachine.h");
});
const ASTNode = @import("../../chrono/ast/ast.zig").ASTNode;
const ValueRef = llvm.LLVMValueRef;
const TypeRef = llvm.LLVMTypeRef;
const ContextRef = llvm.LLVMContextRef;
const ModuleRef = llvm.LLVMModuleRef;
const BuilderRef = llvm.LLVMBuilderRef;

const Function = struct {
    func: ValueRef,
    func_type: TypeRef,
    args: ?[]TypeRef,
    args_len: usize,
};

const Parameter = struct {
    name: []const u8,
    // value: ValueRef,
    ptype: TypeRef,
    index: usize,
};

/// Code generation struct
const Codegen = @This();

allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) Codegen {
    return Codegen{
        .allocator = allocator,
    };
}

pub fn buildFile(self: *Codegen, filename: []const u8, nodes: []*ASTNode) !void {
    const context = llvm.LLVMContextCreate();
    defer llvm.LLVMContextDispose(context);

    const module = llvm.LLVMModuleCreateWithNameInContext(filename.ptr, context);
    defer llvm.LLVMDisposeModule(module);

    const builder = llvm.LLVMCreateBuilder();
    defer llvm.LLVMDisposeBuilder(builder);

    try self.walk(nodes, module, context, builder);

    const output_path = "output/main.o";
    try emitObjectFile(module, output_path);

    llvm.LLVMDumpModule(module);
}

pub fn walk(self: *Codegen, nodes: []*ASTNode, module: ModuleRef, context: ContextRef, builder: BuilderRef) !void {
    var global_vars =
        std.StringHashMap(ValueRef).init(self.allocator);
    var global_fns =
        std.StringHashMap(Function).init(self.allocator);

    try self.definePrintf(nodes[0], context, module, builder, &global_fns);
    for (nodes) |node| {
        switch (node.*.kind) {
            .FunctionDeclaration => try self.createFunction(node, context, module, builder, &global_fns),
            .VariableDeclaration => try self.createVariable(node, context, module, builder, &global_vars),
            .FunctionReference => try self.functionCall(node, context, module, builder, &global_fns),
            else => unreachable,
        }
    }
}

pub fn definePrintf(_: *Codegen, _: *ASTNode, context: ContextRef, module: ModuleRef, _: llvm.LLVMBuilderRef, map: *std.StringHashMap(Function)) !void {
    const i8ptr = llvm.LLVMInt8TypeInContext(context);
    var printf_args_types = [_]TypeRef{llvm.LLVMPointerType(i8ptr, 0)};
    const printf_type = llvm.LLVMFunctionType(llvm.LLVMInt32TypeInContext(context), &printf_args_types[0], 1, 1) orelse return error.FailedToInitType;

    const printf_func = llvm.LLVMAddFunction(module, "printf", printf_type) orelse return error.FailedToCreateFunctionPrintf;

    llvm.LLVMSetFunctionCallConv(printf_func, 0);

    try map.put("printf", .{ .func = printf_func, .func_type = printf_type, .args = null, .args_len = 0 });
}
pub fn createVariable(self: *Codegen, node: *ASTNode, context: ContextRef, module: ModuleRef, builder: llvm.LLVMBuilderRef, map: *std.StringHashMap(ValueRef)) !void {
    if (node.*.kind != .VariableDeclaration) {
        std.debug.print("{}\n", .{node.*.kind});
        return error.ExpectedVariableDeclarationNode;
    }

    const varvar = node.*.data.VariableDeclaration;
    const cname = try std.mem.Allocator.dupe(self.allocator, u8, varvar.name);
    switch (varvar.var_type) {
        .Int => {
            const i32_type = llvm.LLVMInt32TypeInContext(context);
            const variable = llvm.LLVMBuildAlloca(builder, i32_type, cname.ptr);

            const exp = varvar.expression;
            const raw_value = exp.data.NumberLiteral.value;
            const value = llvm.LLVMConstInt(i32_type, @intCast(raw_value), 0);
            if (varvar.mutable) _ = llvm.LLVMBuildStore(builder, value, variable);
            try map.put(cname, variable);
        },
        else => unreachable,
    }
    _ = module;
}

pub fn reassignment(self: *Codegen, node: *ASTNode, context: ContextRef, module: ModuleRef, builder: BuilderRef, map: *std.StringHashMap(ValueRef)) !void {
    if (node.*.kind != .Assignment) {
        std.debug.print("{}\n", .{node.*.kind});
        return error.ExpectedAssignmentNode;
    }

    const varvar = node.*.data.Assignment.variable;
    const varvarx = switch (varvar.kind) {
        .VariableReference => varvar.data.VariableReference,
        else => unreachable,
    };

    const cname = try std.fmt.allocPrint(self.allocator, "{s}", .{varvarx.name});

    const asg = node.*.data.Assignment;

    switch (asg.expression.kind) {
        .NumberLiteral => {
            const i32_type = llvm.LLVMInt32TypeInContext(context);
            const value = asg.expression.data.NumberLiteral.value;

            const new_val = llvm.LLVMConstInt(i32_type, @intCast(value), 0);
            const variable = map.get(cname) orelse return error.VariableNull;
            if (variable) |valueref|
                _ = llvm.LLVMBuildStore(builder, new_val, valueref);
        },
        else => {},
    }
    _ = module;
}

pub fn createFunction(self: *Codegen, node: *ASTNode, context: ContextRef, module: ModuleRef, builder: BuilderRef, funcs: *std.StringHashMap(Function)) !void {
    if (node.*.kind != .FunctionDeclaration) {
        std.debug.print("Expected FunctionDeclarationNode got {}\n", .{node.*.kind});
        return error.ExpectedFunctionDeclarationNode;
    }
    const nfunc = node.*.data.FunctionDeclaration;
    const cname = try std.mem.Allocator.dupe(self.allocator, u8, nfunc.name);
    var llvmparams = std.array_list.Managed(TypeRef).init(self.allocator);
    var llvmparamnames =
        std.array_list.Managed([]const u8).init(self.allocator);

    const nparams = nfunc.parameters;
    if (nparams.len == 0) {
        const func_type = llvm.LLVMFunctionType(llvm.LLVMInt32TypeInContext(context), null, 0, 0);
        const function = llvm.LLVMAddFunction(module, cname.ptr, func_type);
        llvm.LLVMSetFunctionCallConv(function, 0);

        const bb = llvm.LLVMAppendBasicBlockInContext(context, function, "entry");
        llvm.LLVMPositionBuilderAtEnd(builder, bb);

        var xvars =
            std.StringHashMap(ValueRef).init(self.allocator);
        // var xfuncs =
        //     std.StringHashMap(Function).init(self.allocator);
        for (nfunc.body) |b| {
            switch (b.kind) {
                .VariableDeclaration => try self.createVariable(b, context, module, builder, &xvars),
                .Assignment => try self.reassignment(b, context, module, builder, &xvars),
                .FunctionReference => try self.functionCall(b, context, module, builder, funcs),
                .Return => break,
                else => unreachable,
            }
        }

        const ret_val = llvm.LLVMConstInt(llvm.LLVMInt32TypeInContext(context), 0, 0);

        try funcs.put(cname, .{ .func = function, .args = null, .args_len = 0, .func_type = func_type });
        _ = llvm.LLVMBuildRet(builder, ret_val);
        return;
    }

    for (nparams) |param| {
        switch (param.kind) {
            .Parameter => {
                switch (param.data.Parameter.par_type) {
                    .Int => {
                        try llvmparams.append(llvm.LLVMInt32TypeInContext(context));
                        const name = try self.allocator.dupe(u8, param.data.Parameter.name);
                        try llvmparamnames.append(name);
                    },
                    .String => {
                        try llvmparams.append(llvm.LLVMPointerType(llvm.LLVMInt8TypeInContext(context), 0));
                        const name = try self.allocator.dupe(u8, param.data.Parameter.name);
                        try llvmparamnames.append(name);
                    },
                    else => {},
                }
            },
            else => unreachable,
        }
    }

    const params_ptr = &llvmparams.items[0];
    const func_type = llvm.LLVMFunctionType(llvm.LLVMInt32TypeInContext(context), params_ptr, @intCast(llvmparams.items.len), 0) orelse return error.FnTypeNull;

    const func_type_str = llvm.LLVMPrintTypeToString(func_type);
    std.debug.print("func_type: {s}\n", .{func_type_str});

    const function = llvm.LLVMAddFunction(module, cname.ptr, func_type);
    llvm.LLVMSetFunctionCallConv(function, 0);

    for (0..llvmparams.items.len, llvmparamnames.items) |i, pname| {
        const param = llvm.LLVMGetParam(function, @intCast(i));
        llvm.LLVMSetValueName(param, pname.ptr);
    }

    try funcs.put(cname, .{ .func = function, .args = llvmparams.items, .args_len = llvmparams.items.len, .func_type = func_type });
    const bb = llvm.LLVMAppendBasicBlockInContext(context, function, "entry");
    llvm.LLVMPositionBuilderAtEnd(builder, bb);
    var xvars =
        std.StringHashMap(ValueRef).init(self.allocator);
    // var xfuncs =
    //     std.StringHashMap(Function).init(self.allocator);
    for (nfunc.body) |b| {
        switch (b.kind) {
            .VariableDeclaration => try self.createVariable(b, context, module, builder, &xvars),
            .Assignment => try self.reassignment(b, context, module, builder, &xvars),
            .FunctionReference => try self.functionCall(b, context, module, builder, funcs),
            .Return => break,
            else => unreachable,
        }
    }

    const ret_val = llvm.LLVMConstInt(llvm.LLVMInt32TypeInContext(context), 0, 0);

    _ = llvm.LLVMBuildRet(builder, ret_val);
}

pub fn functionCall(self: *Codegen, node: *ASTNode, context: ContextRef, module: ModuleRef, builder: BuilderRef, funcmap: *std.StringHashMap(Function)) !void {
    const nfunc = node.*.data.FunctionReference;
    const cname = try std.mem.Allocator.dupe(self.allocator, u8, nfunc.name);

    const function = llvm.LLVMGetNamedFunction(module, cname.ptr) orelse return error.FunctionNull;

    const func_type = llvm.LLVMGetCalledFunctionType(function);
    const func_type_str = llvm.LLVMPrintTypeToString(func_type);
    std.debug.print("func_type: {s}\n", .{func_type_str});
    //
    // const s1 = llvm.LLVMPrintTypeToString(func_type);
    // const s2 = llvm.LLVMPrintTypeToString(llvm.LLVMTypeOf(function));
    // const testx = llvm.LLVMPointerType(func_type, 0);
    // std.debug.print("testx: {s}\n", .{llvm.LLVMPrintTypeToString(testx)});
    // // std.debug.print("func_type: {s}\nval_type: {s}\n", .{ s1, s2 });
    // llvm.LLVMDisposeMessage(s1);
    // llvm.LLVMDisposeMessage(s2);

    // get function type (unwrap pointer-to-func if necessary)
    // var t = llvm.LLVMTypeOf(function);
    // if (llvm.LLVMGetTypeKind(t) == llvm.LLVMPointerTypeKind) {
    //     t = llvm.LLVMGetElementType(t);
    //     if (t == null) return error.FnTypeNull;
    // }
    // std.debug.print("t value: {s}\n", .{llvm.LLVMPrintTypeToString(t).?});

    // const x = llvm.LLVMGetCalledFunctionType(function);
    // const fn_type = llvm.LLVMGetElementType(llvm.LLVMTypeOf(function));
    // std.debug.print(" x value: {s}\n", .{llvm.LLVMPrintTypeToString(x)});

    if (llvm.LLVMGetInsertBlock(builder) == null) {
        return error.BuilderNotPositioned;
    }

    var args = std.array_list.Managed(ValueRef).init(self.allocator);
    // defer args.deinit();

    for (nfunc.arguments) |arg| {
        switch (arg.*.kind) {
            .NumberLiteral => {
                const num = llvm.LLVMConstInt(llvm.LLVMInt32TypeInContext(context), @intCast(arg.*.data.NumberLiteral.value), 0);
                // std.debug.print("Arg ptr: {*}\n", .{@intFromPtr(num.?)});
                try args.append(num);
            },
            .StringLiteral => {
                const strclean = try self.allocator.dupe(u8, arg.*.data.StringLiteral.value);
                const str = llvm.LLVMBuildGlobalStringPtr(builder, strclean.ptr, "name");

                const array_type = llvm.LLVMTypeOf(str);
                // const element_type = llvm.LLVMGetElementType(llvm.LLVMTypeOf(str));
                // const ty = llvm.LLVMPrintTypeToString(element_type);
                // std.debug.print("str: {s}\nelement_type: {s}\n", .{ llvm.LLVMPrintTypeToString(array_type), ty });

                const zero = llvm.LLVMConstInt(llvm.LLVMInt32TypeInContext(context), 0, 0);
                var indices = [_]ValueRef{ zero, zero };

                try args.append(llvm.LLVMBuildGEP2(builder, array_type, str, &indices[0], 2, "fmt_ptr"));
            },
            else => unreachable,
        }
    }

    if (args.items.len != nfunc.arguments.len) return error.ArgumentCountMistach;

    // // optional: verify types match param types
    // for (0..args.items.len) |i| {
    //     const expected_param = llvm.LLVMGetParam(function, @intCast(i));
    //     const expected = llvm.LLVMTypeOf(expected_param);
    //     const actual = llvm.LLVMTypeOf(args.items[i]);
    //     if (expected != actual) return error.ArgumentTypeMismatch;
    // }

    var call: ValueRef = null;
    if (args.items.len == 0) {
        call = llvm.LLVMBuildCall2(builder, func_type, function, null, 0, cname.ptr);
    } else {
        // std.debug.print("Builder pointer: {*}\n", .{@intFromPtr(builder.?)});
        // std.debug.print("function type str: {*}\n", .{llvm.LLVMPrintTypeToString(fn_type).?});
        std.debug.print("func_type pointer: {p}\n", .{func_type.?});
        // std.debug.print("function pointer: {*}\n", .{@intFromPtr(function)});
        // std.debug.print("Arguments pointer: {*}\n", .{@intFromPtr(args.items.ptr)});
        // std.debug.print("Args count: {}\n", .{@as(c_uint, @intCast(args.items.len))});
        // std.debug.print("Name pointer: {*}\n", .{@intFromPtr(cname.ptr)});
        //
        // std.debug.assert(args.items.len == nfunc.arguments.len);
        // for (args.items) |a| {
        //     std.debug.assert(a != null);
        // }

        // const result =
        //     \\ builder: 0x{x}
        //     \\ func_type: 0x{x}
        //     \\ function: 0x{x}
        //     \\ args.items.ptr: 0x{x}
        //     \\ argument length: {}
        //     \\ cname.ptr: 0x{x}
        //     \\
        // ;
        // std.debug.print(result, .{
        //     @intFromPtr(builder),
        //     @intFromPtr(func_type),
        //     @intFromPtr(function),
        //     @intFromPtr(args.items.ptr),
        //     @as(c_uint, @intCast(args.items.len)),
        //     @intFromPtr(cname.ptr),
        // });
        if (std.mem.eql(u8, cname, "printf")) {
            const ff = funcmap.get("printf") orelse return error.PrintfNotDefined;
            call = llvm.LLVMBuildCall2(builder, ff.func_type, ff.func, &args.items[0], 1, "");
            return;
        }
        const args_ptr = &args.items[0];
        const functionget = funcmap.get(cname) orelse return error.FunctionNull;
        call = llvm.LLVMBuildCall2(builder, functionget.func_type, function, args_ptr, @as(c_uint, @intCast(args.items.len)), cname.ptr) orelse return error.BuildCallFailed;
    }

    // _ = funcmap;
}

pub fn emitObjectFile(
    module: ModuleRef,
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
        llvm.LLVMRelocPIC,
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
