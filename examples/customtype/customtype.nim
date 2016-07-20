import ../../qml

Q_OBJECT NimType:
  var text: string

  proc setText*(p: var pointer, args: varargs[pointer]) =
    let
      self = to[NimType](args[0])
      value = to[string](p)
    echo "Text changing to: ", value[]
    self.text = value[]

Q_OBJECT NimSingleton:
  var event: string

  proc newNimSingleton*(p: var pointer, args: varargs[pointer]) =
    if p.isNil:
       p = alloc(NimSingleton)
    let self = to[NimSingleton](p)
    self.event = "birthday"


var
  nimType = newTypeSpec("NimType")
  nimSingleton = newTypeSpec("NimSingleton", true)

run(proc() =
  registerTypes("NimExtensions", 1, 0, nimType, nimSingleton)

  var
    engine = newEngine()
    comp = engine.loadFile("customtype.qml")
    value = comp.create()
    nimType = to[NimType](value.getPointer())

  echo "Text is: ", nimType.text
)
