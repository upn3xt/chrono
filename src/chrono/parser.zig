const Token = @import("token.zig");
const ASTNode = @import("ast.zig");
const std = @import("std");

const Parser = @This();

allocator: std.mem.Allocator,
tokens: []Token,
index: usize = 0,

pub fn init(allocator: std.mem.Allocator, tokens: []Token) Parser {
    return Parser{ .allocator = allocator, .tokens = tokens, .index = 0 };
}

/// Parses the tokens list
/// Returns an array of possibly null ASTNodes
pub fn ParseTokens(self: *Parser) !?[]?*ASTNode {
    var node_list = std.ArrayList(?*ASTNode).init(std.heap.page_allocator);

    while (true) {
        if (self.index >= self.tokens.len) return error.IndexOutOfBounds;
        const current_token = self.tokens[self.index];
        switch (current_token.token_type) {
            .KEYWORD => |key| {
                switch (key) {
                    .const_kw, .var_kw => {
                        var ismutable = false;
                        if (key == .var_kw) ismutable = true;
                        const node = try self.parseVariableDeclaration(ismutable) orelse return error.VariableDeclarationParsingFailed;
                        std.debug.print("VAR\n", .{});
                        try node_list.append(node);
                        self.index += 1;
                    },
                    .function_kw => {
                        const node = try self.parseFunctionDeclaration() orelse return error.FunctionDeclarationFailed;
                        std.debug.print("FUNCTION\n", .{});
                        try node_list.append(node);
                        self.index += 1;
                    },
                    .pub_kw => self.index += 1,
                    else => break,
                }
            },
            .IDENTIFIER => {
                const node = try self.parseVariableReference() orelse return error.VariableReferenceFailed;
                std.debug.print("NODE\n", .{});
                try node_list.append(node);
                self.index += 1;
            },
            .EOF, .UNKNOWN => break,
            else => {},
        }
    }
    return node_list.items;
}

pub fn parseVariableDeclaration(self: *Parser, isMutable: bool) !?*ASTNode {
    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
    self.index += 1;

    var tokentype = self.tokens[self.index].token_type;

    if (tokentype != .IDENTIFIER) {
        std.debug.print("Expected indetifier, got {s}.\n", .{self.tokens[self.index].lexeme});
        return error.ExpectedIdentifier;
    }

    const varName = self.tokens[self.index].lexeme;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
    self.index += 1;

    tokentype = self.tokens[self.index].token_type;

    // type inference
    if (tokentype == .OPERATOR) {
        if (tokentype.OPERATOR != .equal) return error.ExpectedOperatorEqual;

        if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
        self.index += 1;

        tokentype = self.tokens[self.index].token_type;

        if (tokentype == .IDENTIFIER) {
            const var_ref = try self.allocator.create(ASTNode);
            var_ref.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{ .name = varName } } };

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
            self.index += 1;

            tokentype = self.tokens[self.index].token_type;
            if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
            if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

            const node = try self.allocator.create(ASTNode);
            node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{ .name = varName, .expression = var_ref, .mutable = isMutable } } };
            return node;
        } else if (tokentype == .STRING) {
            const value_str = self.tokens[self.index].lexeme;

            const str_node = try self.allocator.create(ASTNode);

            str_node.* = .{ .kind = .StringLiteral, .data = .{ .StringLiteral = .{ .value = value_str } } };

            const node = try self.allocator.create(ASTNode);

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
            self.index += 1;
            tokentype = self.tokens[self.index].token_type;

            if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
            if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

            node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{ .name = varName, .expression = str_node, .mutable = isMutable } } };
            return node;
        } else if (tokentype == .CHAR) {
            const value_char = self.tokens[self.index].lexeme[0];

            const char_node = try self.allocator.create(ASTNode);

            char_node.* = .{ .kind = .StringLiteral, .data = .{ .CharLiteral = .{ .value = value_char } } };

            const node = try self.allocator.create(ASTNode);

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
            self.index += 1;
            tokentype = self.tokens[self.index].token_type;

            if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
            if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

            node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{ .name = varName, .expression = char_node, .mutable = isMutable } } };
            return node;
        } else if (tokentype == .NUMBER) {
            const num = try std.fmt.parseInt(i64, self.tokens[self.index].lexeme, 10);

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
            self.index += 1;

            tokentype = self.tokens[self.index].token_type;
            if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
            if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

            const num_lit = try self.allocator.create(ASTNode);
            num_lit.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = num } } };

            const node = try self.allocator.create(ASTNode);
            node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{ .name = varName, .expression = num_lit, .mutable = isMutable } } };
            return node;
        }
    }
    // type inference
    //
    // type annotation
    else if (tokentype == .PUNCTUATION) {
        if (tokentype.PUNCTUATION != .colon) return error.ExpectedPuntuactionColon;

        if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
        self.index += 1;

        tokentype = self.tokens[self.index].token_type;

        if (tokentype != .IDENTIFIER) return error.ExpectedIdentifier;

        if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
        self.index += 1;

        tokentype = self.tokens[self.index].token_type;

        if (tokentype != .OPERATOR) return error.ExpectedOperator;
        if (tokentype.OPERATOR != .equal) return error.ExpectedOperatorEqual;

        if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
        self.index += 1;
        tokentype = self.tokens[self.index].token_type;

        //number
        if (tokentype == .NUMBER) {
            const value = try std.fmt.parseInt(i64, self.tokens[self.index].lexeme, 10);

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;

            tokentype = self.tokens[self.index].token_type;

            if (tokentype == .OPERATOR) {
                if (tokentype.OPERATOR == .equal) return error.UnexpectedOperatorEqual;

                const oper: u8 = self.tokens[self.index].lexeme[0];

                if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
                self.index += 1;

                const value2 = try std.fmt.parseInt(i64, self.tokens[self.index].lexeme, 10);

                if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
                self.index += 1;
                tokentype = self.tokens[self.index].token_type;

                if (tokentype != .PUNCTUATION) {
                    std.debug.print("Error: Expected puntuaction type got: {s} with type: {}\n", .{ self.tokens[self.index].lexeme, self.tokens[self.index].token_type });
                    return error.ExpectedPuntuaction;
                }
                if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

                const l_node = try self.allocator.create(ASTNode);

                l_node.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };
                const r_node = try self.allocator.create(ASTNode);

                r_node.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value2 } } };

                const bin_node = try self.allocator.create(ASTNode);

                bin_node.* = .{ .kind = .BinaryOperation, .data = .{ .BinaryOperation = .{ .left = l_node, .right = r_node, .operator = oper } } };

                const varRef = try self.allocator.create(ASTNode);

                varRef.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{ .name = varName } } };

                const node = try self.allocator.create(ASTNode);

                node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{ .expression = bin_node, .name = varName, .mutable = isMutable } } };
                return node;
            } else if (tokentype == .PUNCTUATION) {
                if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

                const x_node = try self.allocator.create(ASTNode);

                x_node.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };

                const node = try self.allocator.create(ASTNode);

                node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{ .expression = x_node, .name = varName, .mutable = isMutable } } };

                return node;
            }
        }
        //number
        //
        //string
        else if (tokentype == .STRING) {
            const value_str = self.tokens[self.index].lexeme;

            const str_node = try self.allocator.create(ASTNode);

            str_node.* = .{ .kind = .StringLiteral, .data = .{ .StringLiteral = .{ .value = value_str } } };

            const node = try self.allocator.create(ASTNode);

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
            self.index += 1;
            tokentype = self.tokens[self.index].token_type;

            if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
            if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

            node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{ .name = varName, .expression = str_node, .mutable = isMutable } } };

            return node;
        }
        //string
        //
        //char
        else if (tokentype == .CHAR) {
            const valueChar = self.tokens[self.index].lexeme[0];

            const char_node = try self.allocator.create(ASTNode);
            char_node.* = .{ .kind = .CharLiteral, .data = .{ .CharLiteral = .{ .value = valueChar } } };

            const node = try self.allocator.create(ASTNode);
            node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{ .name = varName, .expression = char_node, .mutable = isMutable } } };

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
            self.index += 1;
            tokentype = self.tokens[self.index].token_type;

            if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
            if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;
            return node;
        }
        //char
    }
    return null;
}

pub fn parseVariableReference(self: *Parser) !?*ASTNode {
    const varName = self.tokens[self.index].lexeme;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
    self.index += 1;
    const tokentype = self.tokens[self.index].token_type;

    switch (tokentype) {
        // ASSIGNMENT
        // Procedure:
        // IDENTIFIER
        // operator
        // binary expression
        // semi_colon
        .OPERATOR => |op| {
            if (op != .equal) return error.ExpectedOperatorEqual;

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
            self.index += 1;
            var t2 = self.tokens[self.index].token_type;

            const value = try std.fmt.parseInt(i64, self.tokens[self.index].lexeme, 10);

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
            self.index += 1;
            t2 = self.tokens[self.index].token_type;

            if (t2 == .PUNCTUATION) {
                if (t2.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

                const a_node = try self.allocator.create(ASTNode);

                a_node.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{
                    .name = varName,
                } } };

                const v_node = try self.allocator.create(ASTNode);

                v_node.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };

                const node = try self.allocator.create(ASTNode);

                node.* = .{ .kind = .Assignment, .data = .{ .Assignment = .{ .variable = a_node, .expression = v_node } } };

                return node;
            } else if (t2 == .OPERATOR) {
                if (t2.OPERATOR == .equal) return null;

                const oper: u8 = self.tokens[self.index].lexeme[0];

                if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
                self.index += 1;

                const value2 = try std.fmt.parseInt(i64, self.tokens[self.index].lexeme, 10);

                if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
                self.index += 1;
                t2 = self.tokens[self.index].token_type;

                if (t2 != .PUNCTUATION) {
                    std.debug.print("Error: Expected puntuaction type got: {s} with type: {}\n", .{ self.tokens[self.index].lexeme, self.tokens[self.index].token_type });
                    return error.ExpectedPuntuaction;
                }
                if (t2.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

                const l_node = try self.allocator.create(ASTNode);

                l_node.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };
                const r_node = try self.allocator.create(ASTNode);

                r_node.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value2 } } };

                const bin_node = try self.allocator.create(ASTNode);

                bin_node.* = .{ .kind = .BinaryOperation, .data = .{ .BinaryOperation = .{ .left = l_node, .right = r_node, .operator = oper } } };

                const varRef = try self.allocator.create(ASTNode);

                varRef.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{ .name = varName } } };

                const node = try self.allocator.create(ASTNode);

                node.* = .{ .kind = .Assignment, .data = .{ .Assignment = .{ .expression = bin_node, .variable = varRef } } };

                return node;
            }
        },
        // VARIABLE REFERENCE
        .PUNCTUATION => |p| {
            if (p == .colon) return error.UnexpectedOperatorColon;
            const ref_node = try self.allocator.create(ASTNode);
            ref_node.* = .{
                .kind = .VariableReference,
                .data = .{ .VariableReference = .{ .name = varName } },
            };

            return ref_node;
        },
        else => return null,
    }

    return null;
}

pub fn parseFunctionDeclaration(self: *Parser) !?*ASTNode {
    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
    self.index += 1;
    var tokentype = self.tokens[self.index].token_type;

    if (tokentype != .IDENTIFIER) return error.ExpectedIdentifier;

    const fnName = self.tokens[self.index].lexeme;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
    self.index += 1;
    tokentype = self.tokens[self.index].token_type;

    if (tokentype != .SYMBOL) return error.ExpectedSymbol;
    if (tokentype.SYMBOL != .l_roundBracket) return error.ExpectedSymbolLeftRoundBracket;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
    self.index += 1;
    tokentype = self.tokens[self.index].token_type;

    if (tokentype != .SYMBOL) return error.ExpectedSymbol;
    if (tokentype.SYMBOL != .r_roundBracket) return error.ExpectedSymbolLeftRoundBracket;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
    self.index += 1;
    tokentype = self.tokens[self.index].token_type;

    if (tokentype != .IDENTIFIER) return error.ExpectedIdentifier;
    const fnType = self.tokens[self.index].lexeme;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
    self.index += 1;
    tokentype = self.tokens[self.index].token_type;

    if (tokentype != .SYMBOL) return error.ExpectedSymbol;
    if (tokentype.SYMBOL != .l_curlyBracket) return error.ExpectedSymbolLeftCurlyBracket;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
    self.index += 1;
    tokentype = self.tokens[self.index].token_type;

    const start_pos = self.index;

    while (true) {
        if (self.index + 1 >= self.tokens.len) return error.OutOfBoundsError;
        self.index += 1;
        tokentype = self.tokens[self.index].token_type;
        if (tokentype == .SYMBOL)
            if (tokentype.SYMBOL == .r_curlyBracket) break;
    }

    const fin_pos = self.index;

    const fnBody = try self.parseFnBody(start_pos) orelse return error.ParsingBodyFailed;

    const fnNode = try self.allocator.create(ASTNode);
    fnNode.* = .{ .kind = .FunctionDeclaration, .data = .{ .FunctionDeclaration = .{ .name = fnName, .fn_type = fnType, .body = fnBody } } };

    self.index = fin_pos;
    return fnNode;
}

pub fn parseFnBody(self: *Parser, start: usize) !?[]*ASTNode {
    self.index = start;
    var body = std.ArrayList(*ASTNode).init(self.allocator);

    while (true) {
        const current_token = self.tokens[self.index];

        if (current_token.token_type == .KEYWORD) {
            const toktype = current_token.token_type.KEYWORD;
            if (toktype == .const_kw) {
                const node = try self.parseVariableDeclaration(false) orelse return error.VariableDeclarationParsingFailed;
                try body.append(node);
                self.index += 1;
            }
        }
        if (current_token.token_type == .IDENTIFIER) {
            const node = try self.parseVariableReference() orelse return error.VariableReferenceParsingFailed;
            try body.append(node);
        } else break;
    }

    return body.items;
}

pub fn parseFunctionCall(self: *Parser) !?*ASTNode {
    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
    self.index += 1;
    var tokentype = self.tokens[self.index].token_type;

    if (tokentype != .IDENTIFIER) return error.ExpectedIdentifier;
    const fnName = self.tokens[self.index].lexeme;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
    self.index += 1;
    tokentype = self.tokens[self.index].token_type;

    if (tokentype != .SYMBOL) return error.ExpectedSymbol;
    if (tokentype.SYMBOL != .l_roundBracket) return error.ExpectedSymbolLeftRoundBracket;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
    self.index += 1;
    tokentype = self.tokens[self.index].token_type;

    if (tokentype != .SYMBOL) return error.ExpectedSymbol;
    if (tokentype.SYMBOL != .r_roundBracket) return error.ExpectedSymbolLeftRoundBracket;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
    self.index += 1;
    tokentype = self.tokens[self.index].token_type;

    if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
    if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

    const fn_ref = try self.allocator.create(ASTNode);

    fn_ref.* = .{ .kind = .FunctionReference, .data = .{ .FunctionReference = .{ .name = fnName } } };

    return fn_ref;
}
