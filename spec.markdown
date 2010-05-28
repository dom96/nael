nael specification v0.1
=======================
---
## strings ##
`>> "string"`

`stack → ["string"]`

## integers ##
`>> 5`

`stack → [5]`

## Arithmetic Expressions ##
First two 5's are pushed on the stack, then `+` is called.

`>> 5 5 +`

`stack → [10]`

`-`, `*` and `/` work as you would expect. A good thing to remember is that "`10 2 /`" is "`10 / 2`" in [Infix Notation](http://en.wikipedia.org/wiki/Infix_notation "Infix Notation") 

## Lists ##
Lists can contain any type.

`>> ["string", 56]`
`stack → [["string", 56]]`


## Statements ##
Push a string, and write it to stdout. That's how you call statements by the way.

`>> "Hello, world!" print`

`Hello, world!`

## Variables ##
Sets `someNumber` to `123`, and finally prints the `someNumber` variable.

`>> "someNumber" 123 =`

`>> someNumber print`

`123`

## Anonymous functions ##
Anonymous functions are code snippets which haven't been executed yet.

Anonymous functions are declared with `(` and `)`, code in between the parenthesis will become an anonymous function and will get pushed to the stack.

`>> ("foo" print)`

`stack → [("foo" print)]`

You can then execute this code, by using the built in keyword, `call`

`>> call`

`foo`

## Functions ##
Declaring functions is easy. And calling them is easy too.

`>> "foo" ["arg"] (arg print, arg ", again" + print);`

`>> "hi" foo`

`hi`

`hi, again`

You can also have multi-line functions.

    "foo" ["arg"]
        (
            arg print, arg "
            again" + print
        );
