import qml

Q_OBJECT Student:
  var name: string
  var age: int

var hello = "Welcome"

run(proc() =
  registerType("NimExtension", 1, 0, newTypeSpec("Student"))

  let
    engine = newEngine()
    ctx = engine.context()

  ctx.setVar("hello", hello)
  discard ctx.getVar("model")
  let
    comp = engine.loadFile("test.qml")
    win = comp.createWindow(nil)



  win.show()
  win.wait()
)
