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

proc hookGoValueReadField*(engine: ptr QQmlEngine; value: ptr GoAddr;
                          memberIndex: cint; getIndex: cint; setIndex: cint;
                          result: ptr DataValue) {.exportc.} =
  echo "hookGoValueReadField called, memberIndex: ", memberIndex, " getIndex: ", getIndex, " setIndex: ", setIndex
  let typeInfo = getType(getPointerType(value))
  let memberInfo = getMemberInfo(typeInfo, memberIndex-1)
  echo memberInfo[]

  result.dataType = memberInfo.memberType

  var text: cstring = "John Doe"
  result.data = cast[array[8, char]](text)
  result.len = 8

proc hookGoValueWriteField*(engine: ptr QQmlEngine; value: ptr GoAddr;
                           memberIndex: cint; setIndex: cint; assign: ptr DataValue) {.exportc.} =
  echo "hookGoValueWriteField called, memberIndex: ", memberIndex, " setIndex: ", setIndex, " assign: ", cast[cstring](assign.data)
  if assign.dataType == DTString:
    var s = cast[ptr cstring](assign.data)
    echo s[]


proc hookGoValueCallMethod*(engine: ptr QQmlEngine; value: ptr GoAddr;
                           memberIndex: cint; result: ptr DataValue)  {.exportc.} =
  echo "hookGoValueCallMethod called, memberIndex: ", memberIndex

proc hookGoValueDestroyed*(engine: ptr QQmlEngine; value: ptr GoAddr) {.exportc.} =
  echo "hookGoValueDestroyed called"
  untrackPointer(value)

proc hookGoValuePaint*(engine: ptr QQmlEngine; value: ptr GoAddr;
                      reflextIndex: intptr_t) {.exportc.} =
  echo "hookGoValuePaint called"

proc hookRequestImage*(imageFunc: pointer; id: cstring; idLen: cint; width: cint;
                      height: cint): ptr QImage {.exportc.} =
  echo "hookRequestImage called"

proc hookSignalCall*(engine: ptr QQmlEngine; `func`: pointer; params: ptr DataValue) {.exportc.} =
  echo "hookSignalCall called"

proc hookSignalDisconnect*(`func`: pointer) {.exportc.} =
  echo "hookSignalDisconnect called"

proc hookPanic*(message: cstring) {.exportc.} =
  echo "hookPanic called"

proc hookListPropertyCount*(value: ptr GoAddr; reflectIndex: intptr_t;
                           setIndex: intptr_t): cint {.exportc.} =
  echo "hookListPropertyCount called"

proc hookListPropertyAt*(value: ptr GoAddr; reflectIndex: intptr_t;
                        setIndex: intptr_t; i: cint): ptr QObject {.exportc.} =
  echo "hookListPropertyAt called"

proc hookListPropertyAppend*(value: ptr GoAddr; reflectIndex: intptr_t;
                            setIndex: intptr_t; obj: ptr QObject) {.exportc.} =
  echo "hookListPropertyAppend called"

proc hookListPropertyClear*(value: ptr GoAddr; reflectIndex: intptr_t;
                           setIndex: intptr_t) {.exportc.} =
  echo "hookListPropertyClear called"
