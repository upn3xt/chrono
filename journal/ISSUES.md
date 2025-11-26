# ISSUES

Place to let problems and fixes organized.

## Assign variables to variables

Type mismatch error. What I guess: I need to make sure(at compile time) that the types match when assigning so returns the error early. The error risides in 
the variable declaration error. 

Idea: Use a symbol map

The thing is that I can't modify the node after it has been created and there's some confusion while getting the types.

Update: Still no fix, but need to use the maps to get the object type

## Assign variables to variables (partial fix)

Got LLVM IR from the assigning a variable to a variable and it's partially working. Why partially? Had to do some tricks to make it work and still needs to be 
a general solution for all of the types. 

## Better errors

There's a need for better errors.

## Assigning variables to variables(mostly fixed)

Now assigning variables to variables is possible. The fix was adding a symbol map to the 
parseVariableDeclaration function in the parser.zig. It was a scope problem because I was 
using a global map and the function one.

Now there's a problem on emitting the IR. I assume there's a problem on the assignment anda fix for it.


## Assigning variables to variables(fixed)

Now is possible to assign variables to variables. The only catch is that somehow it got more instructions that I thought💀. Anyway victory.


## Better errors

To address this issue, this will have to happen(mostly) at the parser level. Things like type-checking and bounds check are done within the analyzer.


## Better erros, now we have lines 

The title is right. Now we have line count. Making the newline a token, a parse it and there we go. This'll help address parsing and type-checking errors.


## Better errors, they're nicer now

Errors just got a lot more specific and nicer. The line and index thing now are a thing two along with informative error messages.

Next, I want a even better error handler to handle all things and have even more information. But for now they're good as they are.

## Hanle all native cases (next step)

To handle all cases for types. No more integer priority and this will help move forward way faster.


## Printing and formatting all native types

One of the parts of being able to work with all types is to print all kinds of result. Therefore, it'd be nice to implement string formatting early in the language using the C# like 
technique of formatting. Either that or C's native way of formatting.


## String interpolation(on the way)

This is related and way better title for the last 2 points. I've been making changes and updates to now use the `$ AKA inter` to activate a new ast node called InterpolatedString.
Will work on it and make it a thing.


## String interpolation(the first odd case)

String interpolation turned out to be more simpler than I thought. However, with the current lexer and tokens, theres a case for strings in the interpolation. Since the symbols 
`"` are trimmed the content within it is also removed. Also it finds EOF early and one of the symbols `}` disappears. The solution for this would be to only assign the string value
to a variable and then let it unwrapp.

But other types suchs as integers have no problem with that and now all that's left is make the llvm generate the code.


## String interpolation(corrupted memory)

While I managed to get the llvm API to print the stuff, I just have garbage or straight up "nothing". This is a minor issue that when solved will be 50% progress to string interpolation.


## Code generator refactor or remake

The code generator needs improvement and documentation.
