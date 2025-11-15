# Chrono syntax version 2

Chrono now is aiming at another design that transcends zig dependency or superset mindset.


## Variable declaration

I belive this makes sense in any other language and avoids repetitiveness(idk how to write that):

const name = value;
var name = value;

or 

const name: type = value;
var name: type = value;


## Functions

The same goes for functions 

fn name(params:type, ...) type {}


## Classes and structures

Here goes a mix up between C# and Zig:

const SomeClass = struct{

    private_field: type,
    pub public_field: type,

    creator SomeClass(param){

    }
    
    destroyer SomeClass(){
        
    }
} with @atribute1, @atribute2withparams();

Now intruducing a single way to do classes and structures and with the bonus of decorators.
