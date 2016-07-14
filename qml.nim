
import strutils, os, streams, coro
import private/capi#, private/util

export Q_OBJECT, GoTypeSpec

type

  Common* = ref object of RootObj
    cptr: pointer
    engine: ptr Engine

  Engine* = ref object of Common
    destroyed: bool

  Component* = ref object of Common
  Context* = ref object of Common
  Window* = ref object of Common

var
  initialized: bool
  guiIdleRun: int32
  guiLock: int

  waitingWindows: int

proc run*(f: proc()) =
  if initialized:
    raise newException(SystemError, "qml.run called more than once")
  initialized = true

  newGuiApplication()

  if currentThread() != appThread():
    raise newException(SystemError, "run must be called on the main thread")

  idleTimerInit(addr guiIdleRun)
  coro.start(f)
  coro.run()
  applicationExec()


proc lock*() =
  inc(guiLock)

proc unlock*() =
  if guiLock == 0:
    raise newException(SystemError, "qml.unlock callied without lock being held")
  dec(guiLock)

proc flush*() =
  applicationFlushAll()

#proc changed*() =

type
  ValueFold* = object
    engine*: ptr Engine
    gvalue: proc()
    cvalue: pointer
    init: proc()
    prev: ptr ValueFold
    next : ptr ValueFold
    owner: uint8



proc newEngine*(): Engine =
  result = new(Engine)
  result.cptr = capi.newEngine()
  result.engine = addr result

proc destroy*(e: var Engine) =
  if not e.destroyed:
    e.destroyed = true
    delObjectLater(e.cptr)

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
  result = new(Context)
  result.engine = e.engine
  result.cptr = engineRootContext(cast[ptr QQmlEngine](e.cptr))

proc createWindow*(obj: Common, ctx: Context): Window =
  if objectIsComponent(cast[ptr QObject](obj.cptr)) == 0:
    panicf("oject is not a component")
  var win = new(Window)
  win.engine = obj.engine

  var ctxaddr: ptr QQmlContext
  if ctx != nil:
    ctxaddr = cast[ptr QQmlContext](ctx.cptr)
  win.cptr = componentCreateWindow(cast[ptr QQmlComponent](obj.cptr), ctxaddr)
  result = win

proc show*(w: Window) =
  windowShow(cast[ptr QQuickWindow](w.cptr))

proc hide*(w: Window) =
  windowHide(cast[ptr QQuickWindow](w.cptr))

proc platformId*(w: Window): Common =
  var obj = new(Common)
  obj.engine = w.engine
  obj.cptr = windowRootObject(cast[ptr QQuickWindow](w.cptr))

  result = obj

proc wait*(w: Window) =
  inc(waitingWindows)
  windowConnectHidden(cast[ptr QQuickWindow](w.cptr))

proc hookWindowHidden*(cptr: ptr QObject) {.exportc.} =
  echo "hookWindowHidden: only quit once no handler is handling this event"
  if waitingWindows <= 0:
    raise newException(SystemError, "no window is waiting")

  dec(waitingWindows)
  if waitingWindows <= 0:
    applicationExit()

type
  NimObject* = object
    value: string
  Object* = object


var
  types: seq[GoTypeSpec] = @[]

proc registerType*(location: string, major, minor: int, spec: GoTypeSpec) =
  var localSpec = spec

  var typeInfo: TypeInfo

  echo "registerType ", cast[int](addr localSpec)

  if spec.singleton == 1:
    discard registerSingleton(location.cstring, major.cint, minor.cint, spec.name, addr typeInfo, addr localSpec)
  else:
    discard capi.registerType(location.cstring, major.cint, minor.cint, spec.name, addr typeInfo, addr localSpec)

  types.add(spec)

proc registerTypes*(location: string, major, minor: int, types: openArray[GoTypeSpec]) =
  for t in types:
    registerType(location, major, minor, t)

proc hookGoValueTypeNew*(value: ptr GoValue, spec: ptr GoTypeSpec): pointer {.exportc.} =
  echo "hookGoValueTypeNew called"
  echo "type name: ", cast[int](spec)

type
  NimValue* {.importc.} = object
