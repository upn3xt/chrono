# Chrono Development Journal

This journal is were all of the next changes, decisions and achievements will be written.

## Chrono redesign 2025-08-26

Chrono so far was designed to be kind of a superset of zig and kind of a dsl language. But I was wrong for thinking that way. The longer I used zig and 
saw what is becoming I realized that chrono won't be following the same path, as well being domain specific would put a label on it. And I don't want that.

As the creator of the chrono, I need to make the next changes:

* Give chrono the liberty to be a general purpose language 

* Create a new design for it (in terms of syntax, nothing much, just so it's no ultra zig-coded/ imitation)

* Make the framework system decentrilized, meaning that the language will only have official: compiler and stdlib. For library, packages and frameworks,
they'll only be marked as trusted and/or third-party.

And other things will give chrono a new identity as: a flexible language with a self-sufficient stdlib.

And so the development will go like:


* Variable declaration, assignment and reference

* Main entry point

* Functions

* if/else

* for/while

* namespacing

* release version 0

* other language features 

* release version 0.2

* make stdlib 

* release version 1

* evolve from there


My focus now is the first point. I want to get some code gen in it and see the assembly generated. Then is, tokenize, parse, analyze, generate, geek, repeat.

## Chrono specs and split up

Today I've talked with some people and they've made me realize the following:

- Find a sweet spot between precision and ergonomics
- Make a language spec to allow the existance of other compilers for the chrono language.
- LLVM is harder than I thought but it's cool and got some output from it(not in the compiler tho)


With that, the next language changes won't happen in this repository. Rather, in a separate repository for all of the spec of the language. Will be working on 
the speculation repository then while also learning how to mess with LLVM. At the end the compiler will(likely) be re-writen(again XD) from scratch based on 
the language speculation and having an idea of how to work with llvm. The goal will be to output some text like hello world in it.


## Fuck that and lets code!

Fuck the specs! I want to code! Today I have a very crappy AI generated form of output! My first every llvm object file. clang linked it and made it executable
and returned 0!

Ofc this need heavy improvement and research but that's a huge step! The moment I grasp this and know how to transverse ts, chrono programs will be become a 
reality!

I'm saving this progress for sure!!


### Recommended Resources to Learn LLVM IR and LLVM C API

 1. **Official LLVM Documentation and Tutorials**
- **LLVM Language Reference Manual**  
  Comprehensive guide to LLVM IR language and instructions.  
  https://llvm.org/docs/LangRef.html

- **Kaleidoscope Tutorial (LLVM Tutorial 1)**  
  Introductory LLVM tutorial walking step-by-step through building a language and generating IR with the LLVM C++ API. Though it uses C++ API, concepts translate well to C API.  
  https://llvm.org/docs/tutorial/

- **LLVM C API Reference**  
  The authoritative documentation of LLVM’s C API functions you’ll use with Zig `@cImport`.  
  https://llvm.org/doxygen/group__LLVMCCore.html

 2. **Learning LLVM IR**
- **Understanding LLVM Intermediate Representation**  
  This article explains LLVM IR design and concepts in an approachable way.  
  https://mcyoung.xyz/2023/08/01/llvm-ir/

- **LLVM IR Examples and Cheatsheets (GitHub, etc.)**  
  Many repositories and blogs contain sample IR snippets; searching “LLVM IR examples” helps a lot.

 3. **Using the LLVM C API**
- **LLVM Kaleidoscope C API Tutorial** (from the official tutorial, but adapted to C API)  
  https://releases.llvm.org/9.0.0/docs/tutorial/BuildingAJIT1.html  
  (Reference C API examples in LLVM sources or external repos)

- **Zig Community Examples**  
  The Zig community forums, Zig LLVM binding examples, and repositories have useful C API usages in Zig.  
  https://github.com/ziglang/zig/wiki/Using-the-LLVM-library

- **Blogs and Articles**  
  Tutorials like “Using LLVM from C” or “Writing a compiler with LLVM C API” surface with examples and explanations.

4. **Books**
- *“LLVM Essentials”* (Packt Publishing) — A practical book focused on LLVM concepts including IR, optimization, and codegen via C++ API but very helpful.

- *“Getting Started with LLVM Core Libraries”* by Bruno Cardoso Lopes and Rafael Auler — in-depth and approachable for beginners.

 -> Tips to Learn Efficiently

- Start by writing simple LLVM IR by hand based on tutorials to understand instruction mechanics.
- Experiment with the LLVM `llc` and `llvm-as` tools to assemble/disassemble IR.
- Gradually move to generating IR programmatically with the C API in small independent steps.
- Incrementally build traversal of your AST into LLVM IR snippets for each node.
- Use LLVM tools like `opt` and `llvm-dis` for inspecting and debugging generated IR.





## What's next?

Since my goal was to first get some output, some actual object that I can run. And I did.. kind of. It wasn't code "I wrote". This is where AST transversal
comes in. This is basically just iterating over the node list and do checks for subnodes(in cases of binary operation or expression).

Then at each iteration we build the code.

So based on the current status:

- Unfinished parser
- Fasade Analyzer(Semantic Analyzer)
- Fasade LLVM worker 


### The game plan 

The game plan is:

- Have the parser work with:

variable declaration and reference;
function declaration and call;
maybe some if and else;


- Add type annotation; Proper error returns; 

- Make a proper code generator

- Add terminal output to see the stages 

In resume:

- Make the parser work with very basics. 
- Add type annotation to the AST and evolve the token table. 
- Evolve the analyzer and make a code gen struct to handle all the LLVM stuff.
