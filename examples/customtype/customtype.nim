import ../../qml

Q_OBJECT NimType:
  var text: string

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

  let
    engine = newEngine()
    comp = engine.loadFile("customtype.qml")
  var
    value = comp.create(nil)
    nimType = to[NimType](value.getPointer())

  echo "Text is: ", nimType.text
)
