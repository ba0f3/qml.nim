import qml

run(proc() =
  let
    engine = newEngine()
    comp = engine.loadFile("test.qml")
)
