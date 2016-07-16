template to*[T](p: pointer): expr =
  cast[T](p)

template alloc*(a: typedesc): expr =
  system.alloc(sizeof(a))
