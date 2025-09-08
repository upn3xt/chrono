const std = @import("std");

const Import = @import("../imports.zig");
const ParseError = @import("errors.zig");

const Token = Import.Token;
const ASTNode = Import.ASTNode;

const Parser = @This();

allocator: std.mem.Allocator,
tokens: []Token,
index: usize = 0,

pub fn init(allocator: std.mem.Allocator, tokens: []Token) Parser {
    return Parser{ .allocator = allocator, .tokens = tokens, .index = 0 };
}

/// Parses the tokens list
/// Returns an array of possibly null ASTNodes
pub fn ParseTokens(self: *Parser) !?[]*ASTNode {
    var node_list = std.ArrayList(*ASTNode).init(std.heap.page_allocator);

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
                const node = try self.parseAssignmentOrFnCall() orelse return error.VariableReferenceFailed;
                std.debug.print("NODE\n", .{});
                try node_list.append(node);
                self.index += 1;
            },
            .EOF, .UNKNOWN => break,
            .COMMENT => self.index += 1,
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
            self.index += 1;

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
            self.index += 1;

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
            self.index += 1;

            node.* = .{ .kind = .VariableDeclaration, .data = .{ .VariableDeclaration = .{ .name = varName, .expression = char_node, .mutable = isMutable } } };
            return node;
        } else if (tokentype == .NUMBER) {
            const num = try std.fmt.parseInt(i64, self.tokens[self.index].lexeme, 10);

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
            self.index += 1;

            tokentype = self.tokens[self.index].token_type;
            if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
            if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;
            self.index += 1;

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
                self.index += 1;

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
                self.index += 1;

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

            self.index += 1;

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

            self.index += 1;
            return node;
        }
        //char
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

    var parameters = std.ArrayList(*ASTNode).init(self.allocator);
    while (true) {
        if (tokentype == .SYMBOL)
            if (tokentype.SYMBOL == .r_roundBracket) break;

        if (tokentype != .IDENTIFIER) return error.ExpectedIdentifier;
        const name = self.tokens[self.index].lexeme;

        self.index += 1;
        tokentype = self.tokens[self.index].token_type;

        if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
        if (tokentype.PUNCTUATION != .colon) return error.ExpectedPuntuactionColon;

        self.index += 1;
        tokentype = self.tokens[self.index].token_type;

        if (tokentype != .IDENTIFIER) return error.ExpectedIdentifier;
        const par_type = self.tokens[self.index].lexeme;

        const parameter = try self.allocator.create(ASTNode);
        parameter.* = .{ .kind = .Parameter, .data = .{ .Parameter = .{ .name = name, .par_type = par_type } } };

        try parameters.append(parameter);
        std.debug.print("BANANA!\n", .{});

        self.index += 1;
        tokentype = self.tokens[self.index].token_type;

        if (tokentype == .PUNCTUATION) {
            if (tokentype.PUNCTUATION == .comma) {
                self.index += 1;
                tokentype = self.tokens[self.index].token_type;
            }
        }
    }

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
    fnNode.* = .{ .kind = .FunctionDeclaration, .data = .{ .FunctionDeclaration = .{ .name = fnName, .fn_type = fnType, .body = fnBody, .parameters = parameters.items } } };

    self.index = fin_pos;
    return fnNode;
}

pub fn parseFnBody(self: *Parser, start: usize) !?[]*ASTNode {
    self.index = start;
    var body = std.ArrayList(*ASTNode).init(self.allocator);

    while (true) {
        const current_token = self.tokens[self.index].token_type;

        switch (current_token) {
            .KEYWORD => |key| {
                if (key == .const_kw) {
                    const node = try self.parseVariableDeclaration(false) orelse return error.VariableDeclarationParsingFailed;
                    std.debug.print("VAR\n", .{});
                    try body.append(node);
                }
                if (key == .var_kw) {
                    const node = try self.parseVariableDeclaration(true) orelse return error.VariableDeclarationParsingFailed;
                    std.debug.print("VAR\n", .{});
                    try body.append(node);
                }
                self.index += 1;
            },
            .IDENTIFIER => {
                const node = try self.parseAssignmentOrFnCall() orelse return error.AssignmentParsingFailed;
                std.debug.print("VAR OR FN\n", .{});
                try body.append(node);
                self.index += 1;
            },
            else => break,
        }
    }

    return body.items;
}
pub fn parseAssignmentOrFnCall(self: *Parser) !?*ASTNode {
    const name = self.tokens[self.index].lexeme;

    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return null;
    self.index += 1;
    var tokentype = self.tokens[self.index].token_type;

    if (tokentype == .OPERATOR) {
        if (tokentype.OPERATOR == .equal) {
            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
            self.index += 1;
            tokentype = self.tokens[self.index].token_type;
            if (tokentype == .STRING) {
                const value = self.tokens[self.index].lexeme;

                const var_node = try self.allocator.create(ASTNode);
                var_node.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{ .name = name } } };

                const str_node = try self.allocator.create(ASTNode);
                str_node.* = .{ .kind = .StringLiteral, .data = .{ .StringLiteral = .{ .value = value } } };

                const node = try self.allocator.create(ASTNode);
                node.* = .{ .kind = .Assignment, .data = .{ .Assignment = .{ .expression = str_node, .variable = var_node, .asg_type = "string" } } };

                if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
                self.index += 1;
                tokentype = self.tokens[self.index].token_type;

                if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
                if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

                return node;
            }
            if (tokentype == .CHAR) {
                const value = self.tokens[self.index].lexeme[0];

                const var_node = try self.allocator.create(ASTNode);
                var_node.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{ .name = name } } };

                const char_node = try self.allocator.create(ASTNode);
                char_node.* = .{ .kind = .CharLiteral, .data = .{ .CharLiteral = .{ .value = value } } };

                const node = try self.allocator.create(ASTNode);
                node.* = .{ .kind = .Assignment, .data = .{ .Assignment = .{ .expression = char_node, .variable = var_node, .asg_type = "char" } } };

                if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
                self.index += 1;
                tokentype = self.tokens[self.index].token_type;

                if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
                if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

                return node;
            }
            if (tokentype == .NUMBER) {
                const node = try self.parseNumberOrOperation() orelse return error.ParsingNumberOrOperationFailed;
                return node;
            } else return error.UnexpectedToken;
        }
    }
    if (tokentype == .SYMBOL) {
        if (tokentype.SYMBOL != .l_roundBracket) return error.ExpectedSymbolLeftRoundBracket;
        if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
        self.index += 1;
        tokentype = self.tokens[self.index].token_type;

        var arguments = std.ArrayList(*ASTNode).init(self.allocator);
        while (true) {
            if (self.index + 1 >= self.tokens.len) return error.OutOfBoundsError;
            if (tokentype == .SYMBOL) {
                if (tokentype.SYMBOL == .r_roundBracket) break;
            }

            if (tokentype == .IDENTIFIER) {
                const id_name = self.tokens[self.index].lexeme;
                const id_node = try self.allocator.create(ASTNode);
                id_node.* = .{ .kind = .VariableReference, .data = .{ .VariableReference = .{ .name = id_name } } };

                try arguments.append(id_node);
                std.debug.print("arg!\n", .{});
            }
            if (tokentype == .STRING) {
                const value = self.tokens[self.index].lexeme;
                const str_node = try self.allocator.create(ASTNode);
                str_node.* = .{ .kind = .StringLiteral, .data = .{ .StringLiteral = .{ .value = value } } };

                try arguments.append(str_node);
                std.debug.print("arg!\n", .{});
            }
            if (tokentype == .CHAR) {
                const value = self.tokens[self.index].lexeme[0];
                const char_node = try self.allocator.create(ASTNode);
                char_node.* = .{ .kind = .CharLiteral, .data = .{ .CharLiteral = .{ .value = value } } };

                try arguments.append(char_node);
                std.debug.print("arg!\n", .{});
            }
            if (tokentype == .NUMBER) {
                const value_unparsed = self.tokens[self.index].lexeme;
                std.debug.print("{s}\n", .{value_unparsed});
                const value = try std.fmt.parseInt(i64, value_unparsed, 10);
                const num_node = try self.allocator.create(ASTNode);
                num_node.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };

                try arguments.append(num_node);
                std.debug.print("arg!\n", .{});
            }

            if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
            self.index += 1;
            tokentype = self.tokens[self.index].token_type;

            if (tokentype == .PUNCTUATION) {
                if (tokentype.PUNCTUATION == .comma) {
                    if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
                    self.index += 1;
                    tokentype = self.tokens[self.index].token_type;
                }
            }
        }
        if (self.index + 1 >= self.tokens.len or self.tokens[self.index + 1].token_type == .EOF) return error.OutOfBoundsError;
        self.index += 1;
        tokentype = self.tokens[self.index].token_type;

        if (tokentype != .PUNCTUATION) return error.ExpectedPuntuaction;
        if (tokentype.PUNCTUATION != .semi_colon) return error.ExpectedPuntuactionSemiColon;

        const fnCall = try self.allocator.create(ASTNode);

        fnCall.* = .{ .kind = .FunctionReference, .data = .{ .FunctionReference = .{ .name = name } } };
        std.debug.print("CALL\n", .{});
        return fnCall;
    } else return error.UnexpectedToken;

    return null;
}

pub fn parseNumberOrOperation(self: *Parser) !?*ASTNode {
    const value_unparsed = self.tokens[self.index].lexeme;
    const value = try std.fmt.parseInt(i64, value_unparsed, 10);
    const num_node = try self.allocator.create(ASTNode);
    num_node.* = .{ .kind = .NumberLiteral, .data = .{ .NumberLiteral = .{ .value = value } } };
    return num_node;
}
