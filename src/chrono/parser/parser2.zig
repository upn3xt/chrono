const std = @import("std");

const Import = @import("../imports.zig");
const Token = Import.Token;
const ASTNode = Import.ASTNode;

const ParserError = error{ IndexOutOfBoundsError, UnknowTokenError, UnexpectedTokenError, ExpectedPuntuactionError, ExpectedPuntuactionSemiColonError };

const Parser = @This();

allocator: std.mem.Allocator,
tokens: []Token,
index: usize = 0,
current_token: Token,

pub fn init(allocator: std.mem.Allocator, tokens: []Token) Parser {
    return Parser{ .allocator = allocator, .tokens = tokens, .index = 0, .current_token = tokens[0] };
}

pub fn advance(self: *Parser) !void {
    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) try self.errorHandler(error.IndexOutOfBoundsError);

    self.index += 1;
    self.current_token = self.tokens[self.index];
}

pub fn previous(self: *Parser) !void {
    self.index -= 1;
    self.current_token = self.tokens[self.index];
}

pub fn errorHandler(self: *Parser, err: ParserError) !void {
    switch (err) {
        error.IndexOutOfBoundsError => {
            std.debug.print("Failed to advance any further. Reached EOF early at position {}.\n Last token: {s}\n", .{ self.index, self.current_token.lexeme });
        },
        error.UnknowTokenError => {
            std.debug.print("Unknow token found at position {}. Token: {s}\n", .{ self.index, self.current_token.lexeme });
        },
        error.UnexpectedTokenError => {
            std.debug.print("Unexpected token at position {}. Token: {s}\n", .{ self.index, self.current_token.lexeme });
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
                    .function_kw => {},
                }
            },
            .IDENTIFIER => {},
            .COMMENT => self.index += 1,
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

    if (self.current_token.token_type != .IDENTIFIER) try self.errorHandler(error.ExpectedIdentifier);
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

        try self.checkForSemicolon();
    }
    if (self.current_token.token_type == .PUNCTUATION) {}

    const node = try self.allocator.create(ASTNode);
    node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{ .name = name, .expression = exp, .mutable = isMutable } } };
    return node;
}

pub fn parseAssignment(self: *Parser) !*ASTNode {
    const node = try self.allocator.create(ASTNode);
    try self.advance();
    return node;
}

pub fn parseFunctionDeclaration(self: *Parser) !*ASTNode {
    const node = try self.allocator.create(ASTNode);
    try self.advance();
    return node;
}

pub fn parseFunctionCall(self: *Parser) !*ASTNode {
    const node = try self.allocator.create(ASTNode);
    try self.advance();
    return node;
}

pub fn parseFunctionBody(self: *Parser) !*ASTNode {
    const node = try self.allocator.create(ASTNode);
    try self.advance();
    return node;
}

pub fn parseNumberLiteral(self: *Parser) !i64 {
    const value = try std.fmt.parseInt(i64, self.current_token.lexeme, 10);
    return value;
}

pub fn checkForSemicolon(self: *Parser) !void {
    if (self.current_token.token_type != .PUNCTUATION) try self.errorHandler(error.ExpectedPuntuactionError);
    if (self.current_token.token_type.PUNCTUATION != .semi_colon) try self.errorHandler(error.ExpectedPuntuactionSemiColonError);
}
