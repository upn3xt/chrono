const std = @import("std");
const Import = @import("chrono/imports.zig");

const Token = Import.Token;
const Lexer = Import.Lexer;
const Parser = Import.Parser2;
const ASTNode = Import.ASTNode;
const Analyzer = Import.Analyzer;
const Object = Import.Object;
const Codegen = Import.Codegen;
const Printer = Import.Printer;
const Walker = Import.Walker;

const llvm = @cImport({
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/Analysis.h");
    @cInclude("llvm-c/Target.h");
    @cInclude("llvm-c/TargetMachine.h");
});

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    const filepath = args[1];
    var file = try std.fs.cwd().openFile(filepath, .{ .mode = .read_only });

    const filename = std.fs.path.basename(filepath);

    var contentBuf: [1024]u8 = undefined;
    const contentBytes = try file.readAll(&contentBuf);

    const content = contentBuf[0..contentBytes];

    var lexer = Lexer.init(content);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    std.debug.print("Starting Tokenization...\n", .{});
    const tokens = try lexer.tokens();
    std.debug.print("Tokenization done.\n", .{});

    const sym = std.StringHashMap(Object).init(allocator);

    std.debug.print("Starting Parsing...\n", .{});
    var parser = Parser.init(allocator, tokens, sym);
    const nodes = try parser.ParseTokens();

    // Printer.printAST(nodes);

    std.debug.print("Parsing done.\n", .{});
    // std.debug.print("Nodes has length of {}\n", .{nodes.len});

    std.debug.print("LLVM Emit Object...\n", .{});

    const context = llvm.LLVMContextCreate();
    defer llvm.LLVMContextDispose(context);

    const module = llvm.LLVMModuleCreateWithName(filename.ptr);
    defer llvm.LLVMDisposeModule(module);

    // const builder = llvm.LLVMCreateBuilder();
    // defer llvm.LLVMDisposeBuilder(builder);

    // Codegen.createMainWithVariable(module, context, nodes[0]);

    try Walker.walk(nodes, module, context);

    try Codegen.emitObjectFile(module, "main.o");

    std.debug.print("Emition done!\n", .{});

    llvm.LLVMDumpModule(module);
}
