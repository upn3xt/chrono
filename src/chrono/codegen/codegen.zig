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
    for (nodes) |node| {
        switch (node.*.kind) {
            .FunctionDeclaration => try self.createFunction(node, context, module, builder, &global_fns),
            .VariableDeclaration => try self.createVariable(node, context, module, builder, &global_vars),
            .FunctionReference => try self.functionCall(node, context, module, builder, &global_fns),
            else => unreachable,
        }
    }
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

            if (varvar.expression) |exp| {
                const raw_value = exp.data.NumberLiteral.value;
                const value = llvm.LLVMConstInt(i32_type, @intCast(raw_value), 0);
                if (varvar.mutable) _ = llvm.LLVMBuildStore(builder, value, variable);
                try map.put(cname, variable);
            } else return error.ExpressionIsNull;
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

pub fn createFunction(self: *Codegen, node: *ASTNode, context: ContextRef, module: ModuleRef, builder: BuilderRef, globfuncs: *std.StringHashMap(Function)) !void {
    if (node.*.kind != .FunctionDeclaration) {
        std.debug.print("Expected FunctionDeclarationNode got {}\n", .{node.*.kind});
        return error.ExpectedFunctionDeclarationNode;
    }
    const nfunc = node.*.data.FunctionDeclaration;
    const cname = try std.mem.Allocator.dupe(self.allocator, u8, nfunc.name);
    var paramslist = std.array_list.Managed(Parameter).init(self.allocator);

    // var pamslist_items: ?[]Parameter = null;

    if (nfunc.parameters) |nparams| {
        for (nparams, 0..) |param, i| {
            switch (param.*.kind) {
                .Parameter => {
                    switch (param.data.Parameter.par_type) {
                        .Int => {
                            try paramslist.append(.{ .name = param.*.data.Parameter.name, .index = i, .ptype = llvm.LLVMInt32Type() });
                        },
                        else => {},
                    }
                },
                else => unreachable,
            }
        }
        if (paramslist.items.len <= 0) {
            const func_type = llvm.LLVMFunctionType(llvm.LLVMInt32Type(), null, 0, 0);
            const func = llvm.LLVMAddFunction(module, cname.ptr, func_type);
            const entry_bb = llvm.LLVMAppendBasicBlock(func, "entry");
            llvm.LLVMPositionBuilderAtEnd(builder, entry_bb);
            var vars = std.StringHashMap(ValueRef).init(self.allocator);
            var funcs =
                std.StringHashMap(Function).init(self.allocator);
            for (nfunc.body) |b| {
                switch (b.kind) {
                    .VariableDeclaration => try self.createVariable(b, context, module, builder, &vars),
                    .Assignment => try self.reassignment(b, context, module, builder, &vars),
                    .FunctionReference => try self.functionCall(b, context, module, builder, &funcs),
                    .Return => break,
                    else => unreachable,
                }
            }

            const ret_val = llvm.LLVMConstInt(llvm.LLVMInt32Type(), 0, 0);

            try globfuncs.put(nfunc.name, .{ .func = func, .args = null, .args_len = 0, .func_type = func_type });
            _ = llvm.LLVMBuildRet(builder, ret_val);
        } else {
            // work here
        }
        return;
    }

    const func_type = llvm.LLVMFunctionType(llvm.LLVMInt32Type(), null, 0, 0);
    const func = llvm.LLVMAddFunction(module, cname.ptr, func_type);
    const entry_bb = llvm.LLVMAppendBasicBlock(func, "entry");
    llvm.LLVMPositionBuilderAtEnd(builder, entry_bb);
    var vars = std.StringHashMap(ValueRef).init(self.allocator);
    var funcs =
        std.StringHashMap(Function).init(self.allocator);
    for (nfunc.body) |b| {
        switch (b.kind) {
            .VariableDeclaration => try self.createVariable(b, context, module, builder, &vars),
            .Assignment => try self.reassignment(b, context, module, builder, &vars),
            .FunctionReference => try self.functionCall(b, context, module, builder, &funcs),
            .Return => break,
            else => unreachable,
        }
    }

    const ret_val = llvm.LLVMConstInt(llvm.LLVMInt32Type(), 0, 0);

    try globfuncs.put(nfunc.name, .{ .func = func, .args = null, .args_len = 0, .func_type = func_type });
    _ = llvm.LLVMBuildRet(builder, ret_val);
}

pub fn functionCall(self: *Codegen, node: *ASTNode, context: ContextRef, module: ModuleRef, builder: BuilderRef, funcmap: *std.StringHashMap(Function)) !void {
    const nfunc = node.*.data.FunctionReference;
    const cname = try std.fmt.allocPrint(self.allocator, "{s}", .{nfunc.name});
    const function = funcmap.get(nfunc.name) orelse return error.FunctionNull;
    if (function.args) |args| {
        const call = llvm.LLVMBuildCall2(builder, function.func_type, function.func, args.ptr, @intCast(function.args_len), cname.ptr);
        _ = llvm.LLVMBuildRet(builder, call);
        return;
    }

    const call = llvm.LLVMBuildCall2(builder, function.func_type, function.func, null, @intCast(function.args_len), cname.ptr);
    _ = llvm.LLVMBuildRet(builder, call);
    _ = module;
    _ = context;
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
