import ../../qml

Q_OBJECT NimType:
  var text: string

Q_OBJECT NimSingleton:
  event: string


var
  nimType = newTypeSpec("NimType")
  nimSingleton = newTypeSpec("NimSingleton", true)

run(proc() =
  registerTypes("NimExtensions", 1, 0, nimType, nimSingleton)

  let
    engine = newEngine()
    comp = engine.loadFile("customtype.qml")
    win = comp.createWindow(nil)
  win.show()
  win.wait()
)
