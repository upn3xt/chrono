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
