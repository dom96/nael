nael todo list
==============

* `type` function - Pop's a value from the stack and pushes it's type.
* tuples
* dictionaries
* Loading of C Libraries
* Functions for converting types - **Partly Done**
  * `string>int`
  * `int>string`
  * `float>string`
  * etc
* When a module is loaded, it's directory should be added to it's path.
  * **FIXED**
* Make every error, report it's origin(function).
  * `[0, 0] Error: Wrong types... @ +`  -  **Partly done**
* Make global variables work, the `def` keyword.
* Make raising exceptions work, and change any functions that need exception raising, to use raise.
* Add stack effects to functions, `func [args] -> [return] (...);`
* Make var references better, so that a function can change the contents of a variable passed to it.