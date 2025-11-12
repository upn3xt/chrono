const std = @import("std");

const Token = @import("../token/token.zig");
const Lexer = @import("../lexer/lexer.zig");
const Parser = @import("../parser/parser.zig");
const ASTNode = @import("../ast/ast.zig").ASTNode;
const Object = @import("../object/object.zig");
const Printer = @import("../printer/printer.zig");
const Codegen = @import("../codegen/codegen.zig");
const Builder = @This();

const llvm = @cImport({
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/Analysis.h");
    @cInclude("llvm-c/Target.h");
    @cInclude("llvm-c/TargetMachine.h");
});

pub fn build() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    const filepath = args[1];
    var file = try std.fs.cwd().openFile(filepath, .{ .mode = .read_only });

    const filename = std.fs.path.basename(filepath);

    var contentBuf: [1024]u8 = undefined;
    const contentBytes = try file.readAll(&contentBuf);

    const content = contentBuf[0..contentBytes];

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    const line_map = std.StringHashMap(usize).init(allocator);
    var lexer = Lexer.init(content, line_map);

    std.debug.print("Starting Tokenization...\n", .{});

    const tokens = try lexer.tokens();

    // for (tokens) |value| {
    //     std.debug.print("[TOKEN]: {s} -> [TYPE]: {}\n", .{ value.lexeme, value.token_type });
    // }

    std.debug.print("Tokenization done.\n", .{});

    std.debug.print("Starting Parsing...\n", .{});
    var parser = Parser.init(allocator, tokens);
    const nodes = try parser.ParseTokens();

    std.debug.print("Parsing done.\n", .{});

    std.debug.print("LLVM Emit Object...\n", .{});

    var codegener = Codegen.init(allocator);

    try codegener.buildFile(filename, nodes);

    std.debug.print("Emition done!\n", .{});

    // try compileObject(allocator);
}

pub fn compileObject(allocator: std.mem.Allocator) !void {
    const clangcommand = try std.fmt.allocPrint(allocator, "clang output/main.o -o main", .{});
    // const clangcommand = try std.fmt.allocPrint(allocator, "clang", .{});
    var process = std.process.Child.init(&[1][]const u8{clangcommand}, allocator);
    const result = try process.spawnAndWait();

    if (result != .Exited) {
        std.debug.print("Command returned with signal {}.\n", .{result.Signal});
    }
}
