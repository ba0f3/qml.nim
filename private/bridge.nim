import capi

proc hookGoValueTypeNew*(value: ptr GoValue, spec: ptr TypeSpec): ptr GoAddr {.exportc.} =
  echo "hookGoValueTypeNew called"
  echo "type name: ", spec.name
  echo "type singleton: ", spec.singleton


proc hookIdleTimer*() {.exportc.} =
  echo "hookIdleTimer called"

proc hookLogHandler*(message: ptr LogMessage) {.exportc.} =
  echo "hookLogHander called"

proc hookGoValueReadField*(engine: ptr QQmlEngine; goaddr: ptr GoAddr;
                          memberIndex: cint; getIndex: cint; setIndex: cint;
                          result: ptr DataValue) {.exportc.} =
  echo "hookGoValueReadField called, memberIndex: ", memberIndex, " getIndex: ", getIndex, " setIndex: ", setIndex

proc hookGoValueWriteField*(engine: ptr QQmlEngine; goaddr: ptr GoAddr;
                           memberIndex: cint; setIndex: cint; assign: ptr DataValue) {.exportc.} =
  echo "hookGoValueWriteField called, memberIndex: ", memberIndex, " setIndex: ", setIndex, " assign: ", cast[cstring](assign.data)

proc hookGoValueCallMethod*(engine: ptr QQmlEngine; goaddr: ptr GoAddr;
                           memberIndex: cint; result: ptr DataValue)  {.exportc.} =
  echo "hookGoValueCallMethod called, memberIndex: ", memberIndex

proc hookGoValueDestroyed*(engine: ptr QQmlEngine; goaddr: ptr GoAddr) {.exportc.} =
  echo "hookGoValueDestroyed called"

proc hookGoValuePaint*(engine: ptr QQmlEngine; goaddr: ptr GoAddr;
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

proc hookListPropertyCount*(goaddr: ptr GoAddr; reflectIndex: intptr_t;
                           setIndex: intptr_t): cint {.exportc.} =
  echo "hookListPropertyCount called"

proc hookListPropertyAt*(goaddr: ptr GoAddr; reflectIndex: intptr_t;
                        setIndex: intptr_t; i: cint): ptr QObject {.exportc.} =
  echo "hookListPropertyAt called"

proc hookListPropertyAppend*(goaddr: ptr GoAddr; reflectIndex: intptr_t;
                            setIndex: intptr_t; obj: ptr QObject) {.exportc.} =
  echo "hookListPropertyAppend called"

proc hookListPropertyClear*(goaddr: ptr GoAddr; reflectIndex: intptr_t;
                           setIndex: intptr_t) {.exportc.} =
  echo "hookListPropertyClear called"
