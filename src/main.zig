const std = @import("std");
const Token = @import("chrono/token.zig");
const Lexer = @import("chrono/lexer.zig");
const Parser = @import("chrono/parser.zig");
const ASTNode = @import("chrono/ast.zig");

pub fn main() !void {

    // TASK: MAKE SOME CHRONO CODE COMPILE

    var file = try std.fs.cwd().openFile("syntaxv1/operations.chro", .{ .mode = .read_only });

    var contentBuf: [1024]u8 = undefined;
    const contentBytes = try file.readAll(&contentBuf);

    const content = contentBuf[0..contentBytes];

    var lexer = Lexer.init(content);

    const allocator = std.heap.page_allocator;

    const tokens = try lexer.tokens();

    tokenPrinter(tokens);

    std.debug.print("Last token type: {}\n", .{tokens[tokens.len - 1]});
    std.debug.print("Tokens size:{}\n\n", .{tokens.len});

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.ParseTokens();

    if (nodes != null) {
        std.debug.print("Nodes has length of {}\n", .{nodes.?.len});
    } else {
        std.debug.print("Nodes returned null.\n", .{});
    }
}

fn tokenPrinter(tokens: []Token) void {
    for (tokens, 0..) |t, i| {
        std.debug.print("[TOKEN]: {s}\t[INDEX]: {}\t\t[TYPE]: {}\n", .{ t.lexeme, i, t.token_type });
    }
}
