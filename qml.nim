import strutils, os, streams
import private/capi


type
  Engine* = object
    cptr: pointer
    engine: ptr Engine
    destroyed: bool

  Component* = object
    cptr: pointer
    engine: ptr Engine

  Context* = object
    cptr: pointer
    engine: ptr Engine



proc run*(f: proc()) =
  newGuiApplication()
  #idleTimerInit()
  f()
  applicationExit()


proc newEngine(): Engine =
  result.cptr = capi.newEngine(nil)
  result.engine = addr result

proc destroy*(e: var Engine) =
  if not e.destroyed:
    e.destroyed = true
    delObjectlater(e.cptr)

proc load*(e: Egine, location, r: Stream): Component =
  if location.startsWith("qrc:"):
    if not r.isNil:
       return nil
  else:
    data = r.readAll()


proc loadFile(e: Engine, path: string): Component =
  if path.startsWith("qrc:"):
    return e.load(path, nil)
  var f: File
  if not open(f, path):
    return nil
  defer: close(f)
  return e.load(path, newFileStream(f))

proc loadString*(e: Engine, location, qml: string): Component
  return e.load(location, newStringStream(qml))

proc context*(e: Engine): Context =
  result.engine = e
  result.cptr = engineRootContext(e.cptr)
