const std = @import("std");
const Import = @import("../imports.zig");

const Type = Import.Types.Types;
const ASTNode = Import.ASTNode;
const Object = Import.Object;

const IndieAnalyzer = @This();

symbols: std.StringHashMap(Object),

pub fn init(symbols: std.StringHashMap(Object)) IndieAnalyzer {
    return IndieAnalyzer{ .symbols = symbols };
}

pub fn analyzeVariableDeclaration(self: *IndieAnalyzer, node: ASTNode) !void {
    const name = node.data.VariableDeclaration.name;

    const exp = node.data.VariableDeclaration.expression;

    const var_type = node.data.VariableDeclaration.var_type;

    const mutable = node.data.VariableDeclaration.mutable;

    var exp_type: Type = undefined;

    if (exp == null) {
        std.debug.print("Error, expression node for variable {s} is null.", .{name});
        return error.ExpressionNodeNullError;
    }
    switch (exp.?.kind) {
        .NumberLiteral => {
            exp_type = .Int;
        },
        .StringLiteral => {
            exp_type = .String;
        },
        .CharLiteral => {
            exp_type = .Char;
        },
        else => return error.InvalidType,
    }

    if (self.symbols.get(name)) |_| {
        std.debug.print("Variable already declared.\n", .{});
        return error.RedeclarationError;
    }
    if (var_type != null)
        if (var_type.? != exp_type) return error.TypeMismatch;

    try self.symbols.put(name, .{ .identifier = name, .mutable = mutable, .obtype = exp_type });
}

pub fn analyzeAssignment(self: *IndieAnalyzer, node: ASTNode) !void {
    const asg_type = node.data.Assignment.asg_type;
    const variable = node.data.Assignment.variable;

    const varvar = variable.data.VariableReference;
    if (self.symbols.get(varvar.name)) |ob| {
        if (ob.mutable == true) {
            if (ob.obtype != asg_type) {
                std.debug.print("Type TypeMismatch!\n", .{});
                return error.TypeMismatchError;
            }
        } else {
            std.debug.print("{}\n", .{varvar.mutable});
            std.debug.print("Error, trying to asign value to a constant: {s}\n", .{varvar.name});
            return error.AssignToConstantError;
        }
    } else {
        std.debug.print("Variable {s} doesnt exist!\n", .{varvar.name});
        return error.UndefinedVariable;
    }
}

pub fn analyzeFunctionDeclaration(self: *IndieAnalyzer, node: ASTNode) !void {
    switch (node.kind) {
        .FunctionDeclaration => {
            const name = node.data.FunctionDeclaration.name;

            const body = node.data.FunctionDeclaration.body;

            const fn_type = node.data.FunctionDeclaration.fn_type;

            const params = node.data.FunctionDeclaration.parameters;

            const value = node.data.FunctionDeclaration.value;

            if (self.symbols.get(name)) |_| {
                return error.FunctionRedeclarationError;
            }

            for (body) |b| {
                switch (b.kind) {
                    .VariableDeclaration => {
                        try self.analyzeFunctionDeclaration(b);
                    },
                    .Assignment => {
                        try self.analyzeAssignment(b);
                    },
                    else => unreachable,
                }
            }

            if (fn_type == .Void and value != null) {
                return error.FunctionReturnsWithVoidTypeError;
            }

            var parameters_syms = std.StringHashMap(Object).init(std.heap.page_allocator);
            if (params) |pams| {
                for (pams) |p| {
                    switch (p.kind) {
                        .Parameter => {
                            if (p.data.Parameter.par_type == .Void) return error.InvalidParameterType;
                            if (parameters_syms.get(p.data.Parameter.name)) |_| {
                                return error.RedeclarationOfParameterError;
                            }
                            try parameters_syms.put(p.data.Parameter.name, .{ .identifier = p.data.Parameter.name, .mutable = true, .obtype = p.data.Parameter.par_type });
                        },
                        else => unreachable,
                    }
                }
            }
        },
        else => unreachable,
    }
}
