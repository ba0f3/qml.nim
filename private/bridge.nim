import capi, datatype, util

proc hookGoValueTypeNew*(cvalue: ptr GoValue, spec: ptr TypeSpec): ptr GoAddr {.exportc.} =
  var p: pointer
  getConstructor($spec.name)(p)
  trackPointer(p, $spec.name)
  cast[ptr GoAddr](p)

proc hookIdleTimer*() {.exportc.} =
  echo "hookIdleTimer called"

proc hookLogHandler*(message: ptr LogMessage) {.exportc.} =
  echo "hookLogHander called"

proc hookGoValueReadField*(engine: ptr QQmlEngine, value: ptr GoAddr, memberIndex, getIndex, setIndex: cint, result: ptr DataValue) {.exportc.} =
  let
    typeInfo = getType(getPointerType(value))
    memberInfo = getMemberInfo(typeInfo, memberIndex-1)

  let getMethod = getSlot($typeInfo.typeName, $memberInfo.memberName)
  var ret = cast[pointer](result)
  getMethod(ret, cast[pointer](value))

proc hookGoValueWriteField*(engine: ptr QQmlEngine, value: ptr GoAddr, memberIndex, setIndex: cint, assign: ptr DataValue) {.exportc.} =
  let
    typeInfo = getType(getPointerType(value))
    memberInfo = getMemberInfo(typeInfo, memberIndex-1)
  let setMethod = getSlot($typeInfo.typeName, getSetterName($memberInfo.memberName))
  var
    length = getDataLength(assign)

  if memberInfo.memberType == DTString:
    var cptr = cast[ptr cstring](assign.data)
    var str = $(cptr[])
    var sptr = cast[pointer](addr str)
    setMethod(sptr, cast[pointer](value))
  else:
    var dptr = alloc(length)
    copyMem(dptr, cast[pointer](assign.data), length)
    setMethod(dptr, cast[pointer](value))
    dealloc(dptr)

proc hookGoValueCallMethod*(engine: ptr QQmlEngine, value: ptr GoAddr, memberIndex: cint, result: ptr DataValue)  {.exportc.} =
  echo "hookGoValueCallMethod called, memberIndex: ", memberIndex

proc hookGoValueDestroyed*(engine: ptr QQmlEngine, value: ptr GoAddr) {.exportc.} =
  echo "hookGoValueDestroyed called"
  untrackPointer(value)

proc hookGoValuePaint*(engine: ptr QQmlEngine, value: ptr GoAddr, reflextIndex: intptr_t) {.exportc.} =
  echo "hookGoValuePaint called"

proc hookRequestImage*(imageFunc: pointer, id: cstring, idLen, width, height: cint): ptr QImage {.exportc.} =
  echo "hookRequestImage called"

proc hookSignalCall*(engine: ptr QQmlEngine, `func`: pointer, params: ptr DataValue) {.exportc.} =
  echo "hookSignalCall called"

proc hookSignalDisconnect*(`func`: pointer) {.exportc.} =
  echo "hookSignalDisconnect called"

proc hookPanic*(message: cstring) {.exportc.} =
  echo "hookPanic called"

proc hookListPropertyCount*(value: ptr GoAddr, reflectIndex, setIndex: intptr_t): cint {.exportc.} =
  echo "hookListPropertyCount called"

proc hookListPropertyAt*(value: ptr GoAddr, reflectIndex, setIndex: intptr_t, i: cint): ptr QObject {.exportc.} =
  echo "hookListPropertyAt called"

proc hookListPropertyAppend*(value: ptr GoAddr, reflectIndex, setIndex: intptr_t, obj: ptr QObject) {.exportc.} =
  echo "hookListPropertyAppend called"

proc hookListPropertyClear*(value: ptr GoAddr, reflectIndex, setIndex: intptr_t) {.exportc.} =
  echo "hookListPropertyClear called"
