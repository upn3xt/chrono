const std = @import("std");

const Import = @import("../imports.zig");
const Token = Import.Token;
const ASTNode = Import.ASTNode;

const Printer = @This();

pub fn printTokens(tokens: []Token) void {
    for (tokens) |token| {
        std.debug.print("[Token]:{s}\t [Type]:{}\n", .{ token.lexeme, token.token_type });
    }
}

pub fn printAST(nodes: ?[]*ASTNode) void {
    if (nodes == null) {
        std.debug.print("Nodes returned null.\n", .{});
        return;
    }

    for (nodes.?) |node| {
        const kind = node.kind;
        const data = node.data;
        switch (kind) {
            .Assignment => {
                // const asg_type = data.Assignment.asg_type.?;
                // const exp = data.Assignment.expression;
                // const variable = data.Assignment.variable;
                //
                // // variable
                // const var_name = variable.data.VariableReference.name;
                // const mutable = variable.data.VariableReference.mutable;
                //
                // // expression
                // const asg_exp = switch (exp.kind) {
                //     .StringLiteral => {
                //         exp.data.StringLiteral.value;
                //     },
                //     else => return "",
                //     // .NumberLiteral => {
                //     //     return exp.data.NumberLiteral.value;
                //     // },
                //     // .CharLiteral => {
                //     //     return exp.data.CharLiteral.value;
                //     // },
                // };
                //
                // std.debug.print(
                //     \\ {s} = {s};
                //     \\ mutable? = {};
                // , .{ var_name, asg_exp, mutable });
            },
            .BinaryOperation => {},
            .CharLiteral => {},
            .FunctionDeclaration => {},
            .FunctionReference => {},
            .NumberLiteral => {},
            .StringLiteral => {},
            .VariableDeclaration => {
                const name = data.VariableDeclaration.name;
                const mutable = data.VariableDeclaration.mutable;
                const exp = data.VariableDeclaration.expression;

                const value = exp.?.data.StringLiteral.value;
                std.debug.print(
                    \\ (mutable?){} {s} = {s};\n
                , .{ mutable, name, value });
            },
            .VariableReference => {},
        }
    }
}
