const std = @import("std");

const ASTNode = @import("../../chrono/ast/ast.zig").ASTNode;
const Type = @import("../types/types.zig").Type;
const Object = @import("../object/object.zig");

const IndieAnalyzer = @This();

pub fn getStuff(key: []const u8, symbols: *std.StringHashMap(Object)) ?Object {
    return symbols.get(key);
}
pub fn analyzeVariableDeclaration(node: *ASTNode, symbols: *std.StringHashMap(Object)) !void {
    const name = node.*.data.VariableDeclaration.name;

    const exp = node.*.data.VariableDeclaration.expression;

    const var_type = node.*.data.VariableDeclaration.var_type;

    const mutable = node.*.data.VariableDeclaration.mutable;

    var exp_type: Type = .Void;

    switch (exp.kind) {
        .NumberLiteral => {
            exp_type = .Int;
        },
        .StringLiteral => {
            exp_type = .String;
        },
        .CharLiteral => {
            exp_type = .Char;
        },
        .VariableReference => {
            const expvar = exp.*.data.VariableReference.name;
            const obj = symbols.get(expvar) orelse {
                std.debug.print("Error: Undefined variable error\n", .{});
                return error.UndefinedVariable;
            };

            exp_type = obj.obtype;
            // if (obj.obtype != var_type) return error.TypeMismatch;
            //
            // if (symbols.contains(name)) {
            //     std.debug.print("Variable `{s}` already declared.\n", .{name});
            //     return error.RedeclarationError;
            // }
            //
            // try symbols.put(name, .{ .identifier = name, .mutable = mutable, .obtype = exp_type });
            // return;
        },
        else => return error.InvalidType,
    }

    if (symbols.contains(name)) {
        std.debug.print("Variable `{s}` already declared.\n", .{name});
        return error.RedeclarationError;
    }
    if (var_type != exp_type) {
        std.debug.print("Expected type: {s} got {s}\n", .{ @tagName(var_type), @tagName(exp_type) });
        return error.TypeMismatch;
    }

    try symbols.put(name, .{ .identifier = name, .mutable = mutable, .obtype = exp_type });
}

pub fn analyzeAssignment(node: *ASTNode, symbols: *std.StringHashMap(Object)) !void {
    if (node.kind == .FunctionReference) {
        // node.*.data.FunctionReference.name;
        // node.*.data.FunctionReference.arguments;
    }
    if (node.kind == .Assignment) {
        const asg_type = node.*.data.Assignment.asg_type;
        const variable = node.*.data.Assignment.variable;

        const varvar = variable.data.VariableReference;
        if (symbols.get(varvar.name)) |ob| {
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
}

pub fn analyzeFunctionDeclaration(node: *ASTNode, symbols: *std.StringHashMap(Object)) !void {
    if (node.kind != .FunctionDeclaration) {
        std.debug.print("Expected FunctionDeclaration node got {}\n", .{node.kind});
        return error.UnexpectedNodeType;
    }
    switch (node.kind) {
        .FunctionDeclaration => {
            const name = node.*.data.FunctionDeclaration.name;

            const body = node.*.data.FunctionDeclaration.body;

            const fn_type = node.*.data.FunctionDeclaration.fn_type;

            const params = node.*.data.FunctionDeclaration.parameters;

            // const value = node.*.data.FunctionDeclaration.value;

            if (symbols.get(name)) |_| {
                return error.FunctionRedeclarationError;
            }

            for (body) |b| {
                switch (b.kind) {
                    .VariableDeclaration => {
                        try analyzeVariableDeclaration(b, symbols);
                    },
                    .Assignment => {
                        try analyzeAssignment(b, symbols);
                    },
                    .FunctionReference => try analyzeAssignment(b, symbols),
                    else => unreachable,
                }
            }

            if (fn_type == .Void) {
                return error.FunctionReturnsWithVoidTypeError;
            }

            var parameters_syms = std.StringHashMap(Object).init(std.heap.page_allocator);
            for (params) |p| {
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

            try symbols.put(name, .{ .identifier = name, .mutable = false, .obtype = fn_type });
        },
        else => {},
    }
}
