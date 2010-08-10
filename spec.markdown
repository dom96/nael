nael specification v0.1
=======================
---
The algorithm for evaluating nael expressions, is pretty straightforward, and very similar to the postfix algorithm described [here](http://en.wikipedia.org/wiki/Reverse_Polish_notation#Postfix_algorithm "here")

* While there are input tokens left
  * Read the next token from input
  * If the token is a value
    * Push it onto the stack
  * Otherwise, the token is a function.
    * It is known [a priori](http://www.google.com/search?client=ubuntu&channel=fs&q=define%3A+a+priori&ie=utf-8&oe=utf-8) that the function takes **n** arguments.
    * If there are fewer than **n** values on the stack
      * **(ERROR):** Not enough values on the stack.
    * Else, pop the top **n** values from the stack.
    * Evaluate the operator, with the values as arguments.
    * Push the returned results, if any, back onto the stack.

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

### ! ###
Negates a boolean.

`>> false !`

`stack → [true]`

### if ###
Executes a quotation based on the value on the stack.

`>> (true) ("The value is True" print) ("The value is False" print) if`

`The value is True`

### while ###
Executes a quotation until the *cond* quotation pushes false on the stack

`>> (true) ("Infinite loop" print) while`

`Infinite loop` * forever

### each ###
Iterates over a list

`>> [1, 2, 3, 4] (print) each`

`1`

`2`

`3`

`4`

## Modules ##
You can import modules using the `import` keyword.

`"math" import`

You can then access the modules functions with, `module.function`

You can also use `include` instead of `import` which will import all the functions, which means you will be able to just do `function`

## Variables ##
Before you can set a variables value you need to declare it.

`>> x let`

You can then set it to whatever value you want. nael is a dynamically typed language.

`>> x 123 =`

`>> x get print`

`123`

**Note:** Whenever you declare a variable it's default value is nil

## Anonymous functions ##
Anonymous functions are code snippets which haven't been executed yet.
Functions have their own scope, while anonymous functions share scope with the scope of the function that it was executed in.

Anonymous functions are declared with `(` and `)`, code in between the parenthesis will become an anonymous function and will get pushed to the stack.

`>> ("foo" print)`

`stack → [("foo" print)]`

You can then execute this code, by using the built in keyword, `call`

`>> call`

`foo`

## Functions ##
Declaring functions is easy. And calling them is easy too.

`>> func foo [arg] (arg print, arg " again" + print);`

`>> "hi" foo`

`hi`

`hi again`

You can also have multi-line functions.

    func foo [arg]
        (
            arg print
            arg " again" + print
        );

A thing to remember about functions is that they do not share scope. Everything you declare with the `let` keyword, inside a function will be deallocated when the function returns. However you can declare `global variables` with the `def` keyword.

## Tuples ##

`>> bar [field, field1] tuple`

`>> bar new, instance swap =`

`>> instance.field 10 =, instance.field1 2 =`

`>> instance.field instance.field1 /`

`5`

# nael 0.2 - ideas

## Functions
The interpreter could infer the stack effect of functions.

`func a [] (+);`

Would be inferred as, `String String -- String`

The programmer could also specify the stack effect of functions. Like in haskell.

`a :: String String -- String`

Perhaps a different function declaration syntax would be better.

Getting rid of ( ) might be a good idea, instead for a non rpn syntax.

`a := +`

`a arg = arg get +`
