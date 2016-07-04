## # It's surprising that MaximumParamCount is privately defined within qmetaobject.cpp.
## # Must fix the objectInvoke function if this is changed.
## # This is Qt's MaximuParamCount - 1, as it does not take the result value in account.

{.compile: "cpp/capi.cpp".}
{.pragma: cpp, header: "../private/cpp/capi.h", importc.}

const
  MaxParams* = 10

type
  QApplication* {.cpp, importc: "QApplication_".} = object
  QMetaObject* {.cpp, importc: "QMetaObject_".} = object
  QObject* {.cpp, importc: "QObject_".} = object
  QVariant* {.cpp, importc: "QVariant_".} = object
  QVariantList* {.cpp, importc: "QVariantList_".} = object
  QString* {.cpp, importc: "QString_".} = object
  QQmlEngine* {.cpp, importc: "QQmlEngine_".} = object
  QQmlContext* {.cpp, importc: "QQmlContext_".} = object
  QQmlComponent* {.cpp, importc: "QQmlComponent".} = object
  QQmlListProperty* {.cpp, importc: "QQmlListProperty".} = object
  QQuickWindow* {.cpp, importc: "QQuickWindow".} = object
  QQuickView* {.cpp, importc: "QQuickView".} = object
  QMessageLogContext* {.cpp, importc: "QMessageLogContext".} = object
  QImage* {.cpp, importc: "QImage".} = object
  GoValue* {.cpp, importc: "GoValue_".} = object
  GoAddr* = object
  GoTypeSpec* {.cpp, importc: "GoTypeSpec_".} = object
  error* = char

proc errorf*(format: cstring): ptr error {.varargs, cpp.}
proc panicf*(format: cstring) {.varargs, cpp.}
type
  DataType* = enum
    DTUnknown = 0,              ## # Has an unsupported type.
    DTInvalid = 1,              ## # Does not exist or similar.
    DTString = 10, DTBool = 11, DTInt64 = 12, DTInt32 = 13, DTUint64 = 14, DTUint32 = 15,
    DTUintptr = 16, DTFloat64 = 17, DTFloat32 = 18, DTColor = 19, DTGoAddr = 100,
    DTObject = 101, DTValueMap = 102, DTValueList = 103, DTVariantList = 104, DTListProperty = 105, ##
                                                                                     ## #
                                                                                     ## Used
                                                                                     ## in
                                                                                     ## type
                                                                                     ## information,
                                                                                     ## not
                                                                                     ## in
                                                                                     ## an
                                                                                     ## actual
                                                                                     ## data
                                                                                     ## value.
    DTAny = 201,                ## # Can hold any of the above types.
    DTMethod = 202
  DataValue* = object
    dataType*: DataType
    data*: array[8, char]
    len*: cint

  GoMemberInfo* = object
    memberName*: cstring       ## # points to memberNames
    memberType*: DataType
    reflectIndex*: cint
    reflectGetIndex*: cint
    reflectSetIndex*: cint
    metaIndex*: cint
    addrOffset*: cint
    methodSignature*: cstring
    resultSignature*: cstring
    numIn*: cint
    numOut*: cint

  GoTypeInfo* = object
    typeName*: cstring
    fields*: ptr GoMemberInfo
    methods*: ptr GoMemberInfo
    members*: ptr GoMemberInfo  ## # fields + methods
    paint*: ptr GoMemberInfo    ## # in methods too
    fieldsLen*: cint
    methodsLen*: cint
    membersLen*: cint
    memberNames*: cstring
    metaObject*: ptr QMetaObject

  LogMessage* = object
    severity*: cint
    text*: cstring
    textLen*: cint
    file*: cstring
    fileLen*: cint
    line*: cint



proc newGuiApplication*() {.cpp.}
proc applicationExec*() {.cpp.}
proc applicationExit*() {.cpp.}
proc applicationFlushAll*() {.cpp.}
proc idleTimerInit*(guiIdleRun: ptr int32) {.cpp.}
proc idleTimerStart*() {.cpp.}
proc currentThread*(): pointer {.cpp.}
proc appThread*(): pointer {.cpp.}
proc newEngine*(parent: ptr QObject): ptr QQmlEngine {.cpp.}
proc engineRootContext*(engine: ptr QQmlEngine): ptr QQmlContext {.cpp.}
proc engineSetOwnershipCPP*(engine: ptr QQmlEngine; `object`: ptr QObject) {.cpp.}
proc engineSetOwnershipJS*(engine: ptr QQmlEngine; `object`: ptr QObject) {.cpp.}
proc engineSetContextForObject*(engine: ptr QQmlEngine; `object`: ptr QObject) {.cpp.}
proc engineAddImageProvider*(engine: ptr QQmlEngine; providerId: ptr QString;
                            imageFunc: pointer) {.cpp.}
proc contextGetProperty*(context: ptr QQmlContext; name: ptr QString;
                        value: ptr DataValue) {.cpp.}
proc contextSetProperty*(context: ptr QQmlContext; name: ptr QString;
                        value: ptr DataValue) {.cpp.}
proc contextSetObject*(context: ptr QQmlContext; value: ptr QObject) {.cpp.}
proc contextSpawn*(context: ptr QQmlContext): ptr QQmlContext {.cpp.}
proc delObject*(`object`: ptr QObject) {.cpp.}
proc delObjectLater*(`object`: ptr QObject) {.cpp.}
proc objectTypeName*(`object`: ptr QObject): cstring {.cpp.}
proc objectGetProperty*(`object`: ptr QObject; name: cstring; result: ptr DataValue): cint {.cpp.}
proc objectSetProperty*(`object`: ptr QObject; name: cstring; value: ptr DataValue): ptr error {.cpp.}
proc objectSetParent*(`object`: ptr QObject; parent: ptr QObject) {.cpp.}
proc objectInvoke*(`object`: ptr QObject; `method`: cstring; methodLen: cint;
                  result: ptr DataValue; params: ptr DataValue; paramsLen: cint): ptr error {.cpp.}
proc objectFindChild*(`object`: ptr QObject; name: ptr QString; result: ptr DataValue) {.cpp.}
proc objectContext*(`object`: ptr QObject): ptr QQmlContext {.cpp.}
proc objectIsComponent*(`object`: ptr QObject): cint {.cpp.}
proc objectIsWindow*(`object`: ptr QObject): cint {.cpp.}
proc objectIsView*(`object`: ptr QObject): cint {.cpp.}
proc objectConnect*(`object`: ptr QObject; signal: cstring; signalLen: cint;
                   engine: ptr QQmlEngine; `func`: pointer; argsLen: cint): ptr error {.cpp.}
proc objectGoAddr*(`object`: ptr QObject; `addr`: ptr ptr GoAddr): ptr error {.cpp.}
proc newComponent*(engine: ptr QQmlEngine; parent: ptr QObject): ptr QQmlComponent {.cpp.}
proc componentLoadURL*(component: ptr QQmlComponent; url: cstring; urlLen: cint) {.cpp.}
proc componentSetData*(component: ptr QQmlComponent; data: cstring; dataLen: cint;
                      url: cstring; urlLen: cint) {.cpp.}
proc componentErrorString*(component: ptr QQmlComponent): cstring {.cpp.}
proc componentCreate*(component: ptr QQmlComponent; context: ptr QQmlContext): ptr QObject {.cpp.}
proc componentCreateWindow*(component: ptr QQmlComponent; context: ptr QQmlContext): ptr QQuickWindow {.cpp.}
proc windowShow*(win: ptr QQuickWindow) {.cpp.}
proc windowHide*(win: ptr QQuickWindow) {.cpp.}
proc windowPlatformId*(win: ptr QQuickWindow): pointer {.cpp.}
proc windowConnectHidden*(win: ptr QQuickWindow) {.cpp.}
proc windowRootObject*(win: ptr QQuickWindow): ptr QObject {.cpp.}
proc windowGrabWindow*(win: ptr QQuickWindow): ptr QImage {.cpp.}
proc newImage*(width: cint; height: cint): ptr QImage {.cpp.}
proc delImage*(image: ptr QImage) {.cpp.}
proc imageSize*(image: ptr QImage; width: ptr cint; height: ptr cint) {.cpp.}
proc imageBits*(image: ptr QImage): ptr cuchar {.cpp.}
proc imageConstBits*(image: ptr QImage): ptr cuchar {.cpp.}
proc newString*(data: cstring; len: cint): ptr QString {.cpp.}
proc delString*(s: ptr QString) {.cpp.}
proc newGoValue*(`addr`: ptr GoAddr; typeInfo: ptr GoTypeInfo; parent: ptr QObject): ptr GoValue {.cpp.}
proc goValueActivate*(value: ptr GoValue; typeInfo: ptr GoTypeInfo; addrOffset: cint) {.cpp.}
proc packDataValue*(`var`: ptr QVariant; result: ptr DataValue) {.cpp.}
proc unpackDataValue*(value: ptr DataValue; result: ptr QVariant) {.cpp.}
proc newVariantList*(list: ptr DataValue; len: cint): ptr QVariantList {.cpp.}
proc newListProperty*(`addr`: ptr GoAddr; reflectIndex: pointer; setIndex: pointer): ptr QQmlListProperty {.cpp.}
proc registerType*(location: cstring; major: cint; minor: cint; name: cstring;
                  typeInfo: ptr GoTypeInfo; spec: ptr GoTypeSpec): cint {.cpp.}
proc registerSingleton*(location: cstring; major: cint; minor: cint; name: cstring;
                       typeInfo: ptr GoTypeInfo; spec: ptr GoTypeSpec): cint {.cpp.}
proc installLogHandler*() {.cpp.}
proc hookIdleTimer*() {.cpp.}
proc hookLogHandler*(message: ptr LogMessage) {.cpp.}
proc hookGoValueReadField*(engine: ptr QQmlEngine; `addr`: ptr GoAddr;
                          memberIndex: cint; getIndex: cint; setIndex: cint;
                          result: ptr DataValue) {.cpp.}
proc hookGoValueWriteField*(engine: ptr QQmlEngine; `addr`: ptr GoAddr;
                           memberIndex: cint; setIndex: cint; assign: ptr DataValue) {.cpp.}
proc hookGoValueCallMethod*(engine: ptr QQmlEngine; `addr`: ptr GoAddr;
                           memberIndex: cint; result: ptr DataValue) {.cpp.}
proc hookGoValueDestroyed*(engine: ptr QQmlEngine; `addr`: ptr GoAddr) {.cpp.}
proc hookGoValuePaint*(engine: ptr QQmlEngine; `addr`: ptr GoAddr;
                      reflextIndex: pointer) {.cpp.}
proc hookRequestImage*(imageFunc: pointer; id: cstring; idLen: cint; width: cint;
                      height: cint): ptr QImage {.cpp.}
proc hookGoValueTypeNew*(value: ptr GoValue; spec: ptr GoTypeSpec): ptr GoAddr {.cpp.}
proc hookWindowHidden*(`addr`: ptr QObject) {.cpp.}
proc hookSignalCall*(engine: ptr QQmlEngine; `func`: pointer; params: ptr DataValue) {.cpp.}
proc hookSignalDisconnect*(`func`: pointer) {.cpp.}
proc hookPanic*(message: cstring) {.cpp.}
proc hookListPropertyCount*(`addr`: ptr GoAddr; reflectIndex: pointer;
                           setIndex: pointer): cint {.cpp.}
proc hookListPropertyAt*(`addr`: ptr GoAddr; reflectIndex: pointer;
                        setIndex: pointer; i: cint): ptr QObject {.cpp.}
proc hookListPropertyAppend*(`addr`: ptr GoAddr; reflectIndex: pointer;
                            setIndex: pointer; obj: ptr QObject) {.cpp.}
proc hookListPropertyClear*(`addr`: ptr GoAddr; reflectIndex: pointer;
                           setIndex: pointer) {.cpp.}
proc registerResourceData*(version: cint; tree: cstring; name: cstring; data: cstring) {.cpp.}
proc unregisterResourceData*(version: cint; tree: cstring; name: cstring; data: cstring) {.cpp.}
