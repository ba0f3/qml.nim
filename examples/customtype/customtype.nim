import ../../qml

Q_OBJECT NimType:
  var text: string

  proc setText*(self: NimType, value: string) =
    echo "Text changing to: ", value[]
    self.text = value[]

  proc newNimType*(): NimType =
    discard

Q_OBJECT NimSingleton:
  var event: string

  proc newNimSingleton*(): NimSingleton =
    result.event = "birthday"


let
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
