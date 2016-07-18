import capi

template to*[T](p: pointer): expr =
  cast[ptr T](p)

template alloc*(a: typedesc): expr =
  system.alloc(sizeof(a))

proc dataTypeOf*(typ: typedesc): DataType =
  when typ is string:
    DTString
  elif typ is bool:
    DTBool
  elif typ is int:
    when sizeof(int) == 8:
      DTInt64
    else:
      DTInt32
  elif typ is int64:
    DTInt64
  elif typ is int32:
    DTInt32
  elif typ is float32:
    DTDloat32
  elif typ is float64:
    DTFload64
  elif typ is auto or typ is any:
    DTAny
  elif typ is seq or typ is array:
    DTListProperty
  else:
    DTObject


proc getDataLength*(dv: ptr DataValue): int =
  case  dv.dataType
  of DTBool:
    sizeof(bool)
  of DTInt64:
    sizeof(int64)
  of DTInt32:
    sizeof(int32)
  of DTFloat32:
    sizeof(float32)
  of DTFloat64:
    sizeof(float64)
  else:
    dv.`len`

proc dataLen*(val: auto): cint =
  when val is string:
    val.len.cint
  else:
    0


proc newTypeSpec*(name: string, singleton = false): TypeSpec =
  result.name = name
  result.singleton = cast[int](singleton)
