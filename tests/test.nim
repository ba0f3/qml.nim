import qml

Q_OBJECT Student:
  var name: string
  var age: int

var nimExtSpec: TypeSpec

nimExtSpec.name = "Student"
run(proc() =
  registerType("NimExtension", 1, 0, nimExtSpec)

  let
    engine = newEngine()
    comp = engine.loadFile("test.qml")
    win = comp.createWindow(nil)
  win.show()
  win.wait()
)
