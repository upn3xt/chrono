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


## Some progress 

Chars and strings are now a thing! Also a funny thing that was happening, a simple != and == switch up, wasn't making the parser work correctly. After some 
poking and changes to the input(the chrono file), i noticed that only chars wasn't working but strings would. Well now it works and just need to replicate 
this behavior on the type annotation format and proceed to making binary operations and floating numbers.


## Functions and refactoring 

Functions declaration and reference/calls are now a thing(without parameters). Also, realized that using switches are lowkey a headache and that using 
if/else allows me to have more control of the main loop. So now to do there's:

- Final touch on functions
- Maybe add parameters 
- Refactor main loop
- Modify assignment and reference 
- Add binary operation support

The development is actual going nice, for a moment thought of re-writing the parser just because of the function body. But then figured just storing the start 
and end of the function body and then make the parseFnBody adjust the position of the index to parse it and then return to the end position when the body parsing was done.

## When your logic is totally correct but your program still fails to retrieve the corrent result \ ò * ó / ¹¹

Posted up like this <_| õ - õ |_>  --> (Tf am I supposed to do if the logic is right but the result aint right)

## Switches are the solution, really

Once they caused me problems, but now they worked as the solution


## Im staring to hate this 

Again, my logic IT IS right. Even tried switch the methods, and it still doesn't work! Parameters are stupid for not working with the right logic!

Fixed, it was missing updating the token type, lol. How did I find that? by printing and not returning an error, b was a comma, lol. I just was updating the 
position but also missing the tokentype update.


## It's super cool 

Today, small improvements have made the language more alive! Parameters, arguments, comments, syntax highlighting and code editor integration! 
Now when coding in chrono in this very editor, when using commstring it comments! (lmao) But the difference is that it feels integrated! Arguments 
are now a thing, and before proceeding to transversing the AST, still have to do the binary operation thing. Then I can proceed to the analyzer.


## I'm scared 

Rn I need to make the binary operation thing. But the thing is, im scared. I guess its scared of failing. Not sure why but yea. Also, asking myself if this 
is worth it. It is. Just stalling for as long as I can...

Planning in remaking the parser again with helper functions, proper error handling(fr this time) and some extra properties like current token to avoid repetition.


## It's OK to ask for help.

Binary operations are a thing now, and they're solved at compile time! To be precise, at parse time! AI helped with the suggestion of Pratt's parser, gave 
examples and I simply adapted to my parser context, not thinking too much. Also, the parser arc is ending and the analyzer is now the thing that I'm working 
on, now here's where the actual logic of the code is being analyzed. Type mismatches, undefined variables and more are being caught in it. Is a more lightweight
task that the parser, since I'm just walking through nodes and making sure that everything matches.

Each day it passes, more progress is being made, little by little, and sometimes even big pushes. I'm becoming more and more proud of it too.

## Back at it!

Making a independent analyzer to work with the parser. Since some steps depend on it and helps catch errors earlier in the program.


## EMITION! START GENERATING REAL CODE! But just before that...

Now with a minimal analyzer, I can start doing code generation! But just before that I learned that the current way I was doing the AST nodes, allocation and 
other stuff were actually consuming. So refactoring is needed and resolving the currupted memory issue in the analyzer. THEN, I can start generating code.
Plus, need a way to print stuff. I'll get to that in the code generation.


## EMITION EMITION EMITION 

Take a look at the output:

   chrono   git:(main)  nvim
   chrono   git:(main)  zig build run -- tests/main.chro
Starting Tokenization...
Tokenization done.
Starting Parsing...
Result: 10
x! Mutable: false
Result: 20
y! Mutable: false
fn main defined!
Parsing done.
LLVM Emit Object...
Emition done!
; ModuleID = 'main.chro'
source_filename = "main.chro"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

define i32 @main() {
entry:
  %x = alloca i32, align 4
  store i32 10, ptr %x, align 4
  %y = alloca i32, align 4
  store i32 20, ptr %y, align 4
  ret i32 0
}

What a beatiful thing that was not handcrafted. But actually logically solved! Finally! We got some IR in our hands now and only need to make it in 
binary, but this is actually the milestone I was hoping for. Thank God I've made it this far, but I'm still not there yet. But today I take this win.


## Clean up 

Right now, I did a quick clean up on the repository and on the main file. Since the milestone was achieved, I took my time to rest and lowkey got lazy about it.
There's still awesome things to do and this is just the very very beginning. It's exciting and meh. Means more work too but it's alright. There's still a lot 
to clean but I'll do that with time and when proceeding to the next thing, I will talk about it. Maybe re-assignments and function definitions are the 
next step.


## More than just main! 

Another update on the LLVM IR generation journey. Now it can produce functions! Not yet using it.. but it is something! I need to learn LLVM IR tho. It's 
hard having to figure out things like this. Allot of segfaults happened even at compile time(bruh).
