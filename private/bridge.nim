import capi, datatype, util

proc hookGoValueTypeNew*(cvalue: ptr GoValue, spec: ptr TypeSpec): ptr GoAddr {.exportc.} =
  var p: pointer
  let
    typeInfo = getType($spec.name)
    constructor = getMethod(typeInfo.constructorIndex)
  trackPointer(p, $spec.name)
  to[GoAddr](p)

proc hookIdleTimer*() {.exportc.} =
  echo "hookIdleTimer called"

proc hookLogHandler*(message: ptr LogMessage) {.exportc.} =
  echo "hookLogHander called"

proc hookGoValueReadField*(engine: ptr QQmlEngine, value: ptr GoAddr, memberIndex, getIndex, setIndex: cint, result: ptr DataValue) {.exportc.} =
  let
    typeInfo = getType(getPointerType(value))
    memberInfo = getMemberInfo(typeInfo, memberIndex-1)

  let getMethod = getMethod(getIndex)
  var
    ret: pointer
  getMethod(ret, cast[pointer](value))
  copyMem(result, ret, sizeof(DataValue))

  dealloc(ret)

proc hookGoValueWriteField*(engine: ptr QQmlEngine, value: ptr GoAddr, memberIndex, setIndex: cint, assign: ptr DataValue) {.exportc.} =
  let
    typeInfo = getType(getPointerType(value))
    memberInfo = getMemberInfo(typeInfo, memberIndex-1)
    setMethod = getMethod(setIndex)
    length = getDataLength(assign)
  var
      NULL: pointer
  if memberInfo.memberType == DTString:
    var
      cptr = to[cstring](assign.data)
      str = $(cptr[])
    setMethod(NULL, cast[pointer](value), cast[pointer](addr str))

  else:
    let
      dptr = alloc(length)
    copyMem(dptr, cast[pointer](assign.data), length)
    setMethod(NULL, cast[pointer](value), dptr)
    dealloc(dptr)

proc hookGoValueCallMethod*(engine: ptr QQmlEngine, value: ptr GoAddr, memberIndex: cint, result: ptr DataValue)  {.exportc.} =
  echo "hookGoValueCallMethod called, memberIndex: ", memberIndex

proc hookGoValueDestroyed*(engine: ptr QQmlEngine, value: ptr GoAddr) {.exportc.} =
  destroyPointer(value)

proc hookGoValuePaint*(engine: ptr QQmlEngine, value: ptr GoAddr, reflextIndex: intptr_t) {.exportc.} =
  echo "hookGoValuePaint called"

proc hookRequestImage*(imageFunc: pointer, id: cstring, idLen, width, height: cint): ptr QImage {.exportc.} =
  echo "hookRequestImage called"

proc hookSignalCall*(engine: ptr QQmlEngine, `func`: pointer, params: ptr DataValue) {.exportc.} =
  echo "hookSignalCall called"

proc hookSignalDisconnect*(`func`: pointer) {.exportc.} =
  echo "hookSignalDisconnect called"

proc hookPanic*(message: cstring) {.exportc.} =
  raise newException(SystemError, $message)

proc hookListPropertyCount*(value: ptr GoAddr, reflectIndex, setIndex: intptr_t): cint {.exportc.} =
  echo "hookListPropertyCount called"

proc hookListPropertyAt*(value: ptr GoAddr, reflectIndex, setIndex: intptr_t, i: cint): ptr QObject {.exportc.} =
  echo "hookListPropertyAt called"

proc hookListPropertyAppend*(value: ptr GoAddr, reflectIndex, setIndex: intptr_t, obj: ptr QObject) {.exportc.} =
  echo "hookListPropertyAppend called"

proc hookListPropertyClear*(value: ptr GoAddr, reflectIndex, setIndex: intptr_t) {.exportc.} =
  echo "hookListPropertyClear called"
