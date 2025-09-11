const std = @import("std");

const Import = @import("../imports.zig");
const Token = Import.Token;
const ASTNode = Import.ASTNode;

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

pub fn init(allocator: std.mem.Allocator, tokens: []Token) Parser {
    return Parser{ .allocator = allocator, .tokens = tokens, .index = 0, .current_token = tokens[0] };
}

pub fn advance(self: *Parser) !void {
    if (self.index + 1 >= self.tokens.len) try self.errorHandler(error.IndexOutOfBoundsError);

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
            std.debug.print("Unknow token found at position {}. Token: {s}\n", .{ self.index, self.current_token.lexeme });
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
    var node_list = std.ArrayList(*ASTNode).init(self.allocator);
    while (true) {
        if (self.index >= self.tokens.len) try self.errorHandler(error.IndexOutOfBoundsError);

        switch (self.current_token.token_type) {
            .KEYWORD => |key| {
                switch (key) {
                    .const_kw, .var_kw => {
                        var isMutable = false;
                        if (key == .var_kw) isMutable = true;
                        const var_node = try self.parseVariableDeclaration(isMutable);
                        try node_list.append(var_node);
                    },
                    .function_kw => {
                        const fn_node = try self.parseFunctionDeclaration();
                        try node_list.append(fn_node);
                    },
                    .pub_kw => try self.advance(),
                    else => break,
                }
            },
            .IDENTIFIER => {
                const id_node = try self.parseAssignment();
                try node_list.append(id_node);
            },
            .COMMENT => try self.advance(),
            .UNKNOWN => try self.errorHandler(error.UnknowTokenError),
            .EOF => break,
            else => try self.errorHandler(error.UnexpectedTokenError),
        }
    }

    return node_list.items;
}

pub fn parseVariableDeclaration(self: *Parser, isMutable: bool) !*ASTNode {
    const exp = try self.allocator.create(ASTNode);
    try self.advance();

    if (self.current_token.token_type != .IDENTIFIER) try self.errorHandler(error.ExpectedIdentifierError);
    const name = self.current_token.lexeme;

    try self.advance();

    if (self.current_token.token_type == .OPERATOR) {
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
                const value = try self.parseNumberLiteral();
                exp.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };
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
        } } };

        std.debug.print("{s}! Mutable: {}\n", .{ name, isMutable });

        return node;
    }
    if (self.current_token.token_type == .PUNCTUATION) {
        if (self.current_token.token_type.PUNCTUATION != .colon) try self.errorHandler(error.ExpectedPuntuactionColon);
        try self.advance();

        if (self.current_token.token_type != .IDENTIFIER) try self.errorHandler(error.ExpectedIdentifierError);
        const var_tpe = self.current_token.lexeme;

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
                const value = try self.parseNumberLiteral();
                exp.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };
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
            .var_type = var_tpe,
        } } };

        std.debug.print("{s}! Mutable: {}\n", .{ name, isMutable });
        return node;
    } else {
        try self.errorHandler(error.UnexpectedTokenError);
    }
    return error.OperationVarDecFailed;
}

pub fn parseAssignment(self: *Parser) !*ASTNode {
    const exp = try self.allocator.create(ASTNode);

    if (self.current_token.token_type != .IDENTIFIER) try self.errorHandler(error.ExpectedIdentifierError);
    const name = self.current_token.lexeme;
    const var_node = try self.allocator.create(ASTNode);
    var_node.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{ .name = name } } };

    try self.advance();

    if (self.current_token.token_type != .OPERATOR) return error.ExpectedOperator;
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
            const value = try self.parseNumberLiteral();
            exp.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };
        },
        else => try self.errorHandler(error.UnexpectedTokenError),
    }

    try self.advance();

    try self.semiAndGo();

    const node = try self.allocator.create(ASTNode);
    node.* = .{ .kind = .Assignment, .data = .{ .Assignment = .{ .variable = var_node, .expression = exp } } };

    std.debug.print("{s} mutated!\n", .{name});

    return node;
}

pub fn parseFunctionDeclaration(self: *Parser) !*ASTNode {
    const node = try self.allocator.create(ASTNode);
    try self.advance();

    if (self.current_token.token_type != .IDENTIFIER) try self.errorHandler(error.ExpectedIdentifierError);
    const fn_name = self.current_token.lexeme;

    try self.advance();

    if (self.current_token.token_type != .SYMBOL) return error.ExpectedSymbol;
    if (self.current_token.token_type.SYMBOL != .l_roundBracket) return error.ExpectedSymbolLeftRoundBracket;

    try self.advance();

    var parameters = std.ArrayList(*ASTNode).init(self.allocator);
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
        const par_type = self.tokens[self.index].lexeme;

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

    const ret_type = self.current_token.lexeme;

    try self.advance();

    if (self.current_token.token_type != .SYMBOL) return error.ExpectedSymbol;
    if (self.current_token.token_type.SYMBOL != .l_curlyBracket) return error.ExpectedSymbolLeftCurlyBracket;

    try self.advance();

    const start_pos = self.index;

    while (true) {
        try self.advance();
        if (self.current_token.token_type == .SYMBOL)
            if (self.current_token.token_type.SYMBOL == .r_curlyBracket) break;
    }

    const fin_pos = self.index;

    self.index = start_pos;
    const body = try self.parseFunctionBody();

    node.* = .{ .kind = .FunctionDeclaration, .data = .{ .FunctionDeclaration = .{
        .name = fn_name,
        .fn_type = ret_type,
        .parameters = parameters.items,
        .body = body,
    } } };

    self.index = fin_pos;

    try self.advance();

    std.debug.print("fn {s} defined!\n", .{fn_name});

    return node;
}

pub fn parseFunctionCall(self: *Parser) !*ASTNode {
    const node = try self.allocator.create(ASTNode);
    try self.advance();
    return node;
}

pub fn parseFunctionBody(self: *Parser) ![]*ASTNode {
    var body = std.ArrayList(*ASTNode).init(self.allocator);

    while (true) {
        switch (self.current_token.token_type) {
            .KEYWORD => |key| {
                switch (key) {
                    .const_kw, .var_kw => {
                        var isMutable = false;
                        if (key == .var_kw) isMutable = true;
                        const var_node = try self.parseVariableDeclaration(isMutable);
                        try body.append(var_node);
                    },
                    .return_kw => {
                        const ret_node = try self.parseReturn();
                        try body.append(ret_node);
                    },
                    else => break,
                }
            },
            .IDENTIFIER => {
                const id_node = try self.parseAssignment();
                try body.append(id_node);
            },
            .SYMBOL => |s| {
                if (s != .r_curlyBracket) try self.errorHandler(error.UnexpectedTokenError);
                break;
            },
            .COMMENT => try self.advance(),
            .UNKNOWN => try self.errorHandler(error.UnknowTokenError),
            .EOF => break,
            else => try self.errorHandler(error.UnexpectedTokenError),
        }
    }
    return body.items;
}

pub fn parseNumberLiteral(self: *Parser) !i64 {
    const value = try std.fmt.parseInt(i64, self.current_token.lexeme, 10);
    return value;
}

pub fn semiAndGo(self: *Parser) !void {
    if (self.current_token.token_type != .PUNCTUATION) try self.errorHandler(error.ExpectedPuntuactionError);
    if (self.current_token.token_type.PUNCTUATION != .semi_colon) try self.errorHandler(error.ExpectedPuntuactionSemiColonError);
    try self.advance();
}

pub fn parseReturn(self: *Parser) !*ASTNode {
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
            const value = try self.parseNumberLiteral();
            std.debug.print("returning {}...\n", .{value});
            exp.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };
        },
        else => try self.errorHandler(error.UnexpectedTokenError),
    }

    try self.semiAndGo();

    try self.advance();
    return exp;
}
