- Friendly proc declaration, instead of using pointer

    ```nim
    proc setName(self: Student, name: string)
    ```
    Will becomes:
    ```nim
	proc setName(retval: var pointer, args: varargs[pointer]) =
      var self = to[Student](retval)
      let name = to[string](args[0])
    ```
