import qml

Q_OBJECT Student:
  var name: string
  var age: int

run(proc() =
  registerType("NimExtension", 1, 0, newTypeSpec("Student"))

  let
    engine = newEngine()
    comp = engine.loadFile("test.qml")
    win = comp.createWindow(nil)
  win.show()
  win.wait()
)
