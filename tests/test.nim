import qml

newGuiApplication()
var
  engine = newEngine(nil)
  component = newComponent(engine, nil)

component.componentLoadURL("test.qml", 8)

var window = component.componentCreateWindow(nil)
window.windowShow()
