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

## Statements ##
Push a string, and write it to stdout. That's how you call statements by the way.

`>> "Hello, world!" print`
`Hello, world!`

## Variables ##
Sets `someNumber` to `123`, and finally prints the `someNumber` variable.

`>> "someNumber" 123 =`

`>> someNumber print`

`123`
