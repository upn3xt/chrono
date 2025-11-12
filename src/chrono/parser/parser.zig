const std = @import("std");

const IndieAnalyzer = @import("../../chrono/analyzer/indieanalyzer.zig");
const ASTNode = @import("../../chrono/ast/ast.zig").ASTNode;
const Object = @import("../../chrono/object/object.zig");
const Type = @import("../types/types.zig").Type;
const Token = @import("../token/token.zig");

// var major_allocator = std.heap.page_allocator;

var lex_line = std.array_list.Managed([]const u8).init(std.heap.page_allocator);

var vars = std.StringHashMap(Object).init(std.heap.page_allocator);
var funcs = std.StringHashMap(Object).init(std.heap.page_allocator);

const ExpectedTokenError = error{
    ExpectedIdentifierError,
    ExpectedPuntuactionError,
    ExpectedPuntuactionSemiColonError,
    ExpectedNumberLiteralError,
    ExpecterOperator,
    ExpectedOperatorEqual,
    ExpectedPuntuactionColon,
};
const GeneralError = error{ IndexOutOfBoundsError, UnknowTokenError, UnexpectedTokenError };
const ParserError = GeneralError || ExpectedTokenError;

const Parser = @This();

allocator: std.mem.Allocator,
tokens: []Token,
index: usize = 0,
current_token: Token,
line: usize = 0,

pub fn init(allocator: std.mem.Allocator, tokens: []Token) Parser {
    return Parser{
        .allocator = allocator,
        .tokens = tokens,
        .index = 0,
        .current_token = tokens[0],
        .line = 0,
    };
}

pub fn advance(self: *Parser) !void {
    if (self.index + 1 >= self.tokens.len) try self.errorHandler(error.IndexOutOfBoundsError);

    if (self.current_token.token_type == .NEWLINE) self.line += 1;

    self.index += 1;
    self.current_token = self.tokens[self.index];
}

pub fn previous(self: *Parser) !void {
    self.index -= 1;
    self.current_token = self.tokens[self.index];
}

pub fn errorHandler(self: *Parser, err: ParserError) ParserError!void {
    switch (err) {
        error.IndexOutOfBoundsError => {
            std.debug.print("Failed to advance any further. Reached EOF early at position {}.\n Last token: {s}\n", .{ self.index, self.current_token.lexeme });
            return err;
        },
        error.UnknowTokenError => {
            std.debug.print("Unknow token found at position {}. Token: {s} Type: {}\n", .{ self.index, self.current_token.lexeme, self.current_token.token_type });
            return err;
        },
        error.UnexpectedTokenError => {
            std.debug.print("Unexpected token at position {}. Token: {s}\n", .{ self.index, self.current_token.lexeme });
            return err;
        },
        else => {
            std.debug.print("Unknow error.\n Check index {}.\nLast Token: {s}\n", .{ self.index, self.current_token.lexeme });
            return err;
        },
    }
}

pub fn ParseTokens(self: *Parser) ![]*ASTNode {
    var node_list = std.array_list.Managed(*ASTNode).init(self.allocator);
    while (true) {
        if (self.index >= self.tokens.len) try self.errorHandler(error.IndexOutOfBoundsError);

        switch (self.current_token.token_type) {
            .KEYWORD => |key| {
                switch (key) {
                    .const_kw, .var_kw => {
                        var isMutable = false;
                        if (key == .var_kw) isMutable = true;
                        const var_node = try self.parseVariableDeclaration(isMutable, &vars);
                        try IndieAnalyzer.analyzeVariableDeclaration(var_node, &vars);
                        try node_list.append(var_node);

                        std.debug.print("added\n", .{});
                    },
                    .function_kw => {
                        const fn_node = try self.parseFunctionDeclaration();
                        try IndieAnalyzer.analyzeFunctionDeclaration(fn_node, &funcs);
                        try node_list.append(fn_node);
                    },
                    .pub_kw => try self.advance(),
                    else => break,
                }
            },
            .IDENTIFIER => {
                const id_node = try self.parseAssignment(&vars);
                try IndieAnalyzer.analyzeAssignment(id_node, &vars);
                try node_list.append(id_node);
            },
            .COMMENT => try self.advance(),
            .UNKNOWN => try self.errorHandler(error.UnknowTokenError),
            .EOF => break,
            .NEWLINE => try self.advance(),
            else => try self.errorHandler(error.UnexpectedTokenError),
        }
    }
    std.debug.print("Number of lines: {}\n", .{self.line});

    // for (lex_line.items) |value| {
    //     std.debug.print("{s}\n", .{value});
    // }
    return node_list.items;
}

pub fn parseVariableDeclaration(self: *Parser, isMutable: bool, syms: *std.StringHashMap(Object)) !*ASTNode {
    const exp = try self.allocator.create(ASTNode);
    try self.advance();

    if (self.current_token.token_type != .IDENTIFIER) {
        try lex_line.append(self.current_token.lexeme);
        const plhd = lex_line.items;
        const error_slice = plhd[self.index - 1 .. lex_line.items.len];
        std.debug.print("Check this line:\n", .{});
        for (error_slice) |value| {
            std.debug.print("{s} ", .{value});
        }
        // std.debug.print("Got token: {s}\t type: {}", .{ self.current_token.lexeme, self.current_token.token_type });
        try self.errorHandler(error.ExpectedIdentifierError);
    }
    const name = self.current_token.lexeme;

    try self.advance();

    var var_type: Type = .Int;
    if (self.current_token.token_type == .OPERATOR) {
        if (self.current_token.token_type.OPERATOR != .equal) try self.errorHandler(error.ExpectedOperatorEqual);

        try self.advance();
        switch (self.current_token.token_type) {
            .STRING => {
                const value = self.current_token.lexeme;

                var_type = .String;
                exp.* = .{ .kind = .StringLiteral, .data = .{ .StringLiteral = .{ .value = value } } };
            },
            .CHAR => {
                const value = self.current_token.lexeme[0];

                var_type = .Char;
                exp.* = .{ .kind = .CharLiteral, .data = .{ .CharLiteral = .{ .value = value } } };
            },
            .NUMBER => {
                const value = try self.parseNumber(0);

                std.debug.print("Result: {}\n", .{value});
                var_type = .Int;
                exp.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };

                const node = try self.allocator.create(ASTNode);
                node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{
                    .name = name,
                    .expression = exp,
                    .mutable = isMutable,
                    .var_type = .Int,
                } } };

                std.debug.print("{s}! Mutable: {}\n", .{ name, isMutable });

                return node;
            },
            .IDENTIFIER => {
                const id_name = self.current_token.lexeme;

                const obb = IndieAnalyzer.getStuff(id_name, syms) orelse {
                    std.debug.print("Variable {s} undefined\n", .{id_name});
                    return error.NonDeclaredVariable;
                };
                var_type = obb.obtype;
                exp.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{ .name = id_name, .mutable = isMutable, .var_type = obb.obtype } } };
            },
            else => try self.errorHandler(error.UnknowTokenError),
        }

        try self.advance();

        try self.semiAndGo();

        const node = try self.allocator.create(ASTNode);
        node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{
            .name = name,
            .expression = exp,
            .mutable = isMutable,
            .var_type = var_type,
        } } };

        std.debug.print("{s}! Mutable: {}\n", .{ name, isMutable });

        return node;
    }
    if (self.current_token.token_type == .PUNCTUATION) {
        if (self.current_token.token_type.PUNCTUATION != .colon) try self.errorHandler(error.ExpectedPuntuactionColon);
        try self.advance();

        if (self.current_token.token_type != .IDENTIFIER) try self.errorHandler(error.ExpectedIdentifierError);

        try self.advance();

        if (self.current_token.token_type != .OPERATOR) try self.errorHandler(error.ExpecterOperator);
        if (self.current_token.token_type.OPERATOR != .equal) try self.errorHandler(error.ExpectedOperatorEqual);

        try self.advance();

        switch (self.current_token.token_type) {
            .STRING => {
                const value = self.current_token.lexeme;
                exp.* = .{ .kind = .StringLiteral, .data = .{ .StringLiteral = .{ .value = value } } };
            },
            .CHAR => {
                const value = self.current_token.lexeme[0];
                exp.* = .{ .kind = .CharLiteral, .data = .{ .CharLiteral = .{ .value = value } } };
            },
            .NUMBER => {
                const value = try self.parseNumber(0);
                exp.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };
            },
            .IDENTIFIER => {
                const id_name = self.current_token.lexeme;
                exp.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{ .name = id_name, .mutable = isMutable, .var_type = .Int } } };
            },
            else => try self.errorHandler(error.UnknowTokenError),
        }

        try self.advance();

        try self.semiAndGo();

        const node = try self.allocator.create(ASTNode);
        node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{
            .name = name,
            .expression = exp,
            .mutable = isMutable,
            .var_type = .Int,
        } } };

        std.debug.print("{s}! Mutable: {}\n", .{ name, isMutable });

        return node;
    } else {
        try self.errorHandler(error.UnexpectedTokenError);
    }
    return error.OperationVarDecFailed;
}

pub fn parseAssignment(self: *Parser, syms: *std.StringHashMap(Object)) !*ASTNode {
    var asgtype: Type = undefined;
    const exp = try self.allocator.create(ASTNode);

    if (self.current_token.token_type != .IDENTIFIER) try self.errorHandler(error.ExpectedIdentifierError);
    const name = self.current_token.lexeme;
    const var_node = try self.allocator.create(ASTNode);

    var_node.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{ .name = name, .mutable = true, .var_type = .Int } } };
    try self.advance();

    if (self.current_token.token_type == .SYMBOL) {
        if (self.current_token.token_type.SYMBOL == .l_roundBracket) {
            try self.advance();
            var args = std.array_list.Managed(*ASTNode).init(std.heap.page_allocator);
            while (true) {
                var current_token = self.current_token.token_type;
                switch (current_token) {
                    .STRING => {
                        const strnode = try self.allocator.create(ASTNode);
                        strnode.* = .{ .kind = .StringLiteral, .data = .{ .StringLiteral = .{ .value = self.current_token.lexeme } } };
                        try args.append(strnode);
                        try self.advance();
                    },
                    .NUMBER => {
                        const num = try std.fmt.parseInt(i32, self.current_token.lexeme, 10);
                        const numnode = try self.allocator.create(ASTNode);
                        numnode.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = num } } };
                        try args.append(numnode);
                        try self.advance();
                    },
                    .IDENTIFIER => {},
                    .SYMBOL => |s| if (s == .r_roundBracket) {
                        try self.advance();
                        break;
                    },

                    else => unreachable,
                }
                current_token = self.current_token.token_type;
            }

            try self.semiAndGo();

            const node = try self.allocator.create(ASTNode);
            node.* = .{ .kind = .FunctionReference, .data = .{ .FunctionReference = .{ .arguments = args.items, .name = name } } };
            return node;
        }
    }
    if (self.current_token.token_type == .OPERATOR) {
        if (self.current_token.token_type.OPERATOR != .equal) try self.errorHandler(error.ExpectedOperatorEqual);

        try self.advance();

        switch (self.current_token.token_type) {
            .STRING => {
                const value = self.current_token.lexeme;
                exp.* = .{ .kind = .StringLiteral, .data = .{ .StringLiteral = .{
                    .value = value,
                } } };
                asgtype = .String;
            },
            .CHAR => {
                const value = self.current_token.lexeme[0];
                exp.* = .{ .kind = .CharLiteral, .data = .{ .CharLiteral = .{ .value = value } } };
                asgtype = .Char;
            },
            .NUMBER => {
                const value = try self.parseNumber(0);
                exp.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };
                asgtype = .Int;

                const node = try self.allocator.create(ASTNode);
                node.* = .{ .kind = .Assignment, .data = .{ .Assignment = .{ .variable = var_node, .expression = exp, .asg_type = asgtype } } };

                std.debug.print("{s} mutated!\n", .{name});

                return node;
            },
            else => try self.errorHandler(error.UnexpectedTokenError),
        }

        try self.advance();

        try self.semiAndGo();

        if (syms.get(name)) |_| {} else return error.UndefinedVariableError;

        const node = try self.allocator.create(ASTNode);
        node.* = .{ .kind = .Assignment, .data = .{ .Assignment = .{ .variable = var_node, .expression = exp, .asg_type = asgtype } } };

        std.debug.print("{s} mutated!\n", .{name});

        return node;
    }

    return error.Bablabablah;
}

pub fn parseFunctionDeclaration(self: *Parser) !*ASTNode {
    const node = try self.allocator.create(ASTNode);
    try self.advance();

    if (self.current_token.token_type != .IDENTIFIER) try self.errorHandler(error.ExpectedIdentifierError);
    const fn_name = self.current_token.lexeme;
    std.debug.print("function {s}\n", .{fn_name});

    try self.advance();

    if (self.current_token.token_type != .SYMBOL) return error.ExpectedSymbol;
    if (self.current_token.token_type.SYMBOL != .l_roundBracket) return error.ExpectedSymbolLeftRoundBracket;

    try self.advance();

    var parameters = std.array_list.Managed(*ASTNode).init(self.allocator);
    while (true) {
        if (self.current_token.token_type == .SYMBOL)
            if (self.current_token.token_type.SYMBOL == .r_roundBracket) break;

        if (self.current_token.token_type != .IDENTIFIER) return error.ExpectedIdentifier;
        const name = self.tokens[self.index].lexeme;

        try self.advance();

        if (self.current_token.token_type != .PUNCTUATION) return error.ExpectedPuntuaction;
        if (self.current_token.token_type.PUNCTUATION != .colon) return error.ExpectedPuntuactionColon;

        try self.advance();

        if (self.current_token.token_type != .IDENTIFIER) return error.ExpectedIdentifier;
        const par_type = self.h_getType(self.tokens[self.index].lexeme) orelse return error.InvalidTypeError;

        const parameter = try self.allocator.create(ASTNode);
        parameter.* = .{ .kind = .Parameter, .data = .{ .Parameter = .{ .name = name, .par_type = par_type } } };

        try parameters.append(parameter);
        std.debug.print("param {s}\n", .{name});

        try self.advance();

        if (self.current_token.token_type == .PUNCTUATION) {
            if (self.current_token.token_type.PUNCTUATION == .comma) {
                try self.advance();
            }
        }
    }

    try self.advance();

    // const ret_type = self.h_getType(self.current_token.lexeme) orelse return error.InvalidTypeError;
    const ret_type: Type = .Int;

    try self.advance();

    if (self.current_token.token_type != .SYMBOL) return error.ExpectedSymbol;
    if (self.current_token.token_type.SYMBOL != .l_curlyBracket) return error.ExpectedSymbolLeftCurlyBracket;

    try self.advance();

    var body = std.array_list.Managed(*ASTNode).init(self.allocator);
    var varsbody = std.StringHashMap(Object).init(self.allocator);

    while (true) {
        switch (self.current_token.token_type) {
            .KEYWORD => |key| {
                switch (key) {
                    .const_kw, .var_kw => {
                        var isMutable = false;
                        if (key == .var_kw) isMutable = true;
                        const var_node = try self.parseVariableDeclaration(isMutable, &varsbody);
                        try IndieAnalyzer.analyzeVariableDeclaration(var_node, &varsbody);
                        try body.append(var_node);
                    },
                    .return_kw => {
                        const ret_node = try self.parseReturn();
                        try body.append(ret_node);
                        break;
                    },
                    else => {},
                }
            },
            .IDENTIFIER => {
                const id_node = try self.parseAssignment(&varsbody);
                try IndieAnalyzer.analyzeAssignment(id_node, &varsbody);
                try body.append(id_node);
            },
            .SYMBOL => |s| {
                if (s != .r_curlyBracket) try self.errorHandler(error.UnexpectedTokenError);
                break;
            },
            .COMMENT => try self.advance(),
            .UNKNOWN => try self.errorHandler(error.UnknowTokenError),
            .EOF => return error.ReachedEOFEarly,
            .NEWLINE => try self.advance(),
            else => try self.errorHandler(error.UnexpectedTokenError),
        }
    }
    node.* = .{ .kind = .FunctionDeclaration, .data = .{ .FunctionDeclaration = .{
        .name = fn_name,
        .fn_type = ret_type,
        .parameters = parameters.items,
        .body = body.items,
        .value = "",
    } } };

    try self.advance();

    std.debug.print("fn {s} defined!\n", .{fn_name});

    return node;
}

pub fn parseFunctionCall(self: *Parser) !ASTNode {
    const node: ASTNode = undefined;
    try self.advance();
    return node;
}

pub fn parseNumber(self: *Parser, min_bp: u8) !i64 {
    var left = try std.fmt.parseInt(i64, self.current_token.lexeme, 10);

    try self.advance();

    while (true) {
        if (self.current_token.token_type == .PUNCTUATION) {
            if (self.current_token.token_type.PUNCTUATION == .semi_colon) {
                try self.advance();
                break;
            }
        }

        if (self.current_token.token_type != .OPERATOR) break;

        const op = self.current_token.token_type.OPERATOR;

        const an = struct { lbp: u8, rbp: u8 }; // anonym struct
        const binding: ?an = switch (op) {
            .plus, .minus => .{ .lbp = 10, .rbp = 11 },
            .times, .divideBy => .{ .lbp = 20, .rbp = 21 },
            else => null,
        };

        if (binding == null or binding.?.lbp < min_bp) break;

        try self.advance();

        // Parse right-hand side expression with right binding power
        const rhs = try self.parseNumber(binding.?.rbp);

        left = switch (op) {
            .plus => left + rhs,
            .minus => left - rhs,
            .times => left * rhs,
            .divideBy => @divFloor(left, rhs),
            else => unreachable,
        };
    }

    return left;
}
pub fn semiAndGo(self: *Parser) !void {
    if (self.current_token.token_type != .PUNCTUATION) try self.errorHandler(error.ExpectedPuntuactionError);
    if (self.current_token.token_type.PUNCTUATION != .semi_colon) try self.errorHandler(error.ExpectedPuntuactionSemiColonError);
    try self.advance();
}

pub fn parseReturn(self: *Parser) !*ASTNode {
    const node = try self.allocator.create(ASTNode);
    const exp = try self.allocator.create(ASTNode);
    try self.advance();

    switch (self.current_token.token_type) {
        .STRING => {
            const value = self.current_token.lexeme;
            std.debug.print("returning {s}...\n", .{value});
            exp.* = .{ .kind = .StringLiteral, .data = .{ .StringLiteral = .{ .value = value } } };
        },
        .CHAR => {
            const value = self.current_token.lexeme[0];
            std.debug.print("returning {c}...\n", .{value});
            exp.* = .{ .kind = .CharLiteral, .data = .{ .CharLiteral = .{ .value = value } } };
        },
        .NUMBER => {
            const value = try self.parseNumber(0);
            exp.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };
        },
        else => try self.errorHandler(error.UnexpectedTokenError),
    }

    try self.semiAndGo();

    try self.advance();

    node.* = .{ .kind = .Return, .data = .{ .Return = .{ .value = exp } } };
    return node;
}

pub fn h_getType(_: *Parser, elem: []const u8) ?Type {
    if (elem[0] == 'i') return Type.Int;
    if (elem[0] == 'u') return Type.Char;
    if (std.mem.eql(u8, "string", elem)) return Type.String;
    if (std.mem.eql(u8, "void", elem)) return Type.Void;
    return null;
}
