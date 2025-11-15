# Chrono language syntax v3 

Chrono language syntax version 3 aims for a consise design and organized syntax for ease of 
use and swag.


Now focusing on only a few things:


## Classes, structs and attributes

unmanaged class SomeClass {

    x: type,
    y: type,

    constructor(){}

    destroyer SomeDestroyer(){}
};

This time it will remove the creator keyword and add the constructor for a single way 
to make a constructor. Multiple constructors are something to leave for later on if not 
remove it all together.

Now introducing the concepts of `unmanaged classes`. These are classes that use custom
destroyers and maybe even constructors paring with the `defer` keyword to make class 
control more effective. These are not automatically cleared at the end of the scope as 
normal classes do.


struct SomeStruct {
    x: type,
    y: type,
}


class SomeClass{

} with [att],[att2];
