import qml

run(proc() =
  let
    engine = newEngine()
    comp = engine.loadFile("test.qml")
    win = comp.createWindow(nil)
  win.show()
  win.wait()
)
