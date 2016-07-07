import strutils, os, streams
import private/capi


type
  Common* = ref object of RootObj
    cptr: pointer
    engine: ptr Engine

  Engine* = ref object of Common
    destroyed: bool

  Component* = ref object of Common

  Context* = ref object of Common



proc run*(f: proc()) =
  newGuiApplication()
  #idleTimerInit()
  f()
  applicationExit()

proc newEngine*(): Engine =
  result = new(Engine)
  result.cptr = capi.newEngine()
  result.engine = addr result

proc destroy*(e: var Engine) =
  if not e.destroyed:
    e.destroyed = true
    delObjectlater(e.cptr)

proc load*(e: Engine, location: string, r: Stream): Component =
  let qrc = location.startsWith("qrc:")
  if qrc:
    if not r.isNil:
       return nil
  let
    colon = location.find(':', 0)
    slash = location.find('/', 0)

  var location = location

  if colon == -1 or slash <= colon:
    if location.isAbsolute():
      location = "file:///" & location
    else:
      location = "file:///" & joinPath(getCurrentDir(), location)

  result = new(Component)
  result.cptr = newComponent(cast[ptr QQmlEngine](e.cptr), nil)
  if qrc:
    componentLoadURL(cast[ptr QQmlComponent](result.cptr), location, location.len.cint)
  else:
    let data = r.readAll()
    componentSetData(cast[ptr QQmlComponent](result.cptr), data, data.len.cint, location, location.len.cint)
  let message = componentErrorString(cast[ptr QQmlComponent](result.cptr))
  if message != nil:
    # free meesage?
    raise newException(IOError, $message)


proc loadFile*(e: Engine, path: string): Component =
  if path.startsWith("qrc:"):
    return e.load(path, nil)
  var f: File
  if not open(f, path):
    return nil
  defer: close(f)
  return e.load(path, newFileStream(f))

proc loadString*(e: Engine, location: string, qml: string): Component =
  return e.load(location, newStringStream(qml))

proc context*(e: Engine): Context =
  result.engine = e.engine
  result.cptr = engineRootContext(cast[ptr QQmlEngine](e.cptr))
