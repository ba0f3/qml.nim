import qml

newGuiApplication()

var
  engine = newEngine(nil)
  comp = newComponent(engine, nil)

comp.componentLoadURL("test.qml", 8)
let message = componentErrorString(comp)
if message != nil:
   echo "Error: ", message
var win = comp.componentCreateWindow(nil)
windowShow(win)
windowConnectHidden(win)
applicationExec()
