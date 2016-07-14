import qml

var nimExtSpec: GoTypeSpec

nimExtSpec.name = "NimValue"
nimExtSpec.singleton = 0
run(proc() =
  registerType("NimExtension", 1, 0, nimExtSpec)

  let
    engine = newEngine()
    comp = engine.loadFile("test.qml")
    win = comp.createWindow(nil)
  win.show()
  win.wait()
)
