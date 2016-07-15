import qml

var nimExtSpec: GoTypeSpec

nimExtSpec.name = "GoValue"
nimExtSpec.singleton = 10000
run(proc() =
  registerType("NimExtension", 1, 0, nimExtSpec)

  let
    engine = newEngine()
    comp = engine.loadFile("test.qml")
    win = comp.createWindow(nil)
  win.show()
  win.wait()
)
