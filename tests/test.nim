import qml

Q_OBJECT Student:
  var name: string
  var age: int

  proc newStudent*(p: var pointer, args: varargs[pointer]) =
    if p.isNil:
      p = alloc(Student)
    var self = to[Student](p)
    echo "Constructor for Student called"
    self.mName = "John"


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
