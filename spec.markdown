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

## Variables ##
Before you can set a variables value you need to declare it.

`>> x let`

You can then set it to whatever value you want. nael is dynamically typed language.

`>> x 123 =`

`>> x print`

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

`>> foo [arg] (arg print, arg " again" + print);`

`>> "hi" foo`

`hi`

`hi again`

You can also have multi-line functions.

    foo [arg]
        (
            arg print
            arg " again" + print
        );

A thing to remember about functions is that they do not share scope. Everything you declare with the `let` keyword, inside a function will be deallocated when the function returns. However you can declare `global variables` with the `def` keyword.

## Tuples ##

`>> bar [field, field1] tuple`

`>> instance let, instance bar =`

`>> instance.field 10 =, instance.field1 2 =`

`>> instance.field instance.field1 /`

`5`

