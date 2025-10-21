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


## I'm getting lazy about this :/ 

Lowkey got tired of the chrono work, not exactly, just being and talking lazy. I recently worked on another project and the same happened. I got confortable
about the results. Maybe im tired but whatever, going to work on other stuff and then comeback to this. Working on assignment.


## ITS BEEN A WHILE SINCE CODE SUM BUT GOT SOME NEWS 

Well, tonight I decided the fate of the chronolang. It's not ready yet to have implemented the concepts of classes, RAII and etc. First of all, to be a language 
that at the very least can do logic. I will have a time to study more about certain things like RAII and auto clean ups. Along will come syntax specifications.


## Back on it, now everything is broken 

Today I got back on chrono development and man let me tell ya- Everything suddenly doesn't work. The indie analyzer genuinely sucks for working so well and yet 
being so fucking ass. Now assignment compiles but I'm not sure if it works but yea. The parser suddenly sucks at parsing and had to try many things just to reach the same output. Even now I had to comment things just to make it work. How do you declare a variable one time and still get a redeclaration error??? Fucking 
shit.


## Entering scope resolution fields

Fixed the redeclaration error. It simply needed different symbol hashmaps. This was good, so confusing but finally makes sense and the parser's still evolving
through this process. Nice, also now ""tying object lifetimes"" to the scope now. At the very least is what I'm trying to say/do. As I proceed more refactoring 
will be needed because this codebase is to laugh at, but being serious I liked this error resolution.


## Hashmaps, ArrayLists and wasted allocators

Right now I'm attemping to get printf to be a thing in my language. To print stuff and even have string formating, but I gotta be honest this is getting too 
messy to keep up. I have like 20 flexible datastructures duck taping the project and most of them are wasting memory with page allocators instead of fba or GPA
ones. Also having to take care of all of it is mentally challenging and I get desmotivated pretty quickly but later on I might finish it or just run into a 
problem with a simple resolution. That's the routine lol. Just saving this progress tho-


## Function calls are doomed to segfault

It's been like 3 days already trying to get function calls to be a thing. This is for the 'Hello world' achievement using printf but for some reason, this bitch
of a API keeps segfaulting. I've already done some rework but I just keep getting the same result. Now I understand the hate for segmentation fault. It stops 
being funny the 67th time.


## I've found it!

It's been like a week since I tried to get this thing working but school and lazyness got in the way. Today I was ready to fix a probable version issue when 
I opened a different chat to help me fix the problem and there were two exactly: Not making the module based on the current context and not using the function 
version constant rather than llvmsometypeyadayada. The moment clean llvm code got generated in the sample file(main.c) I was so happy!! Now I just gotta fix 
another issue which is the getnamedfunction. As soon this flies, its fireworks!


## Garbage garbage garbage \@/ 

Now function calls are a thing.. Kind of. I used the ducktape approach and it works!.. But now theres poop all over the place. Got a dangling pointer in my 
hands guys. Where? HA! you wish I knew.... In a code with 2000+ lines of code you want ME to find a dangling pointer? IT COULD ANYWHERE! I have to find this 
to properly get printf to work.

## segfault and stupid zig errors. seriously this is making my day bad 

I can't even compile my code anymore because there's a circular dependency error going on (apparently) on the parser and ast but ofc this just exists the moment 
function calls stop being a problem. This is so stupid. And previously hit a half segfault(don't even ask me how is that possible) and need to make it right 
before printf.


## Recursion, pointers and refactoring 

AI is a blessing at times like this. GPT said that ASTNode as main struct would create a circular dependency cycle since im doing SomeField: ASTNode ←  this 
is the circular point. The fix is simple using pointers. I know that a while ago I said that pointers were bad so guess what? They're not. And a massive refactor is coming.


## Set a world record for refactor cause I'm just like that! 

Made a the previous commit like 10 mins ago and the massive refactoring is done in less time.

## Too many lists and allocators!

I WILL pause the project to refactor the walker. The duck tape aint doin it no muh :( and to be honest it's about time I done this. Like, the allocator waste 
is massive. And I believe that somewhere between the analyzer and the walker the symbol table might be the solution to something else. Btw scope resolution 
is the reason why things are the way they are right now. I was generating invalid parameters which when calling the code, it segfaults almost immediately.
Anyway, that's work for the future.


## Bruh I'm bored and confused

It's so incredible that even people that develop the code can have a hard time while reading and understanding the code they wrote themselves! It's priceless and that's my case! Anyway, just making a restore point so I don't lose progress in this new code generator.


## Feels like a step back 

Since I've been reworking on the code generator it really seems like a step back. Not a good one tho, feels like this is taking longer than it should and 
procrastinating just makes it worse. I want to understand my code. The previous walker was dangerous and poorly written but it worked. I don't want to make that 
mistake but iteration at this rate just seems worse on paper. On the other hand, scope resolution works better than ever. Since those are variables that live in 
the context(block) or are global, passing a map and look for it is just nice. This resolution is one of the few things I'm proud of in this sense. And man 
parameters suck. These are the only reason I'm not moving forward. There's still other types to work with such as string, chars and booleans and yet just 
integers are causing a lot of pain. Maybe in the future, before actually making the language written in itself, I make a better and more documented backend for 
language creation. It could be llvm based or written intirely from scratch(this is such a bad idea) and it would just be quick. The only real work in a language 
in 2025 should be STL's, Frameworks and Comptime checks. ANYWAY, the new codegen is just starting to work but there's still errors and parameters to work on.


## WHOLE LOTTA TRASH - LESS EACH TIME, MORE REWORK BECAUSE 

The garbage problem is back and now even the previous solution isn't 100% effective, but now the code generator is better each time. The amount of rework tho 
is kinda ahh.


## Ownership, lifetimes and clean IR

Fixed the garbage thing by using dupe instead of allocPrint, smart choice. It did cross my mind b4 but I didn't want my compiler to be slow. But it really 
needed the variable that was holding the value(the name of variables/functions/etc..) have a straight copy of the pointer's value instead of just a partial 
allocation(don't know if that makes sense but I just understand). Also the concept of ownership and lifetimes is starting to make sense little by little.
And finally that clean IR.


## Null values are the problem 

While making the AST back then, using null values was cool because it got the work done. Now this has catch up to me and the null check are becoming more than 
a headache. On the other side, parameter work is way more ellaborate and believe that it'll work soon enough, but I HAVE to make a stop to remove the 
unnecessary null's and just make null checks on certain parts of the code that I don't own like the STl and the LLVM API. If I keep going with these nulls 
it will lead me to rewriting all the project. It's either: handle a error, return a error, initialize or whatever else is better than just say null.


## Nulls were the problem and now I'm getting closer to end this parameter saga 

As much as I would like to keep coding and fixing all the problems today, there's still much to do and finally the code is starting to make sense. Also I will 
be using more of the LLVM API instead of a bunch of arraylists and custom structs. It really just makes sense and avoids extra allocation.

## Segmentation fault hell 

It was my fault to celebrate early. It's been a whole week since I'm stuck in this shit. BuildCall2 is always segfaulting even with (what I assume is) correct 
arguments. Valid memory addresses but still something is wrong. I'm in this debug saga trying to find where shit got all wrong to not work.
