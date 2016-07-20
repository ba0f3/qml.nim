## # It's surprising that MaximumParamCount is privately defined within qmetaobject.cpp.
## # Must fix the objectInvoke function if this is changed.
## # This is Qt's MaximuParamCount - 1, as it does not take the result value in account.
{.compile: "all.cpp".}

proc getHeaderPath(): string {.compileTime.} =
  let path = currentSourcePath()
  result = substr(path, 0, path.len - 1 - "/capi.nim".len) & "/cpp"

{.passC:"-I"&getHeaderPath().}

{.pragma: cpp, header: "capi.h", importc.}

const
  MaxParams* = 10

type
  intptr_t* {.importc, pure.} = cint

type
  QApplication* {.cpp, importc: "QApplication_", pure.} = object
  QMetaObject* {.cpp, importc: "QMetaObject_", pure.} = object
  QObject* {.cpp, importc: "QObject_", pure.} = object
  QVariant* {.cpp, importc: "QVariant_", pure.} = object
  QVariantList* {.cpp, importc: "QVariantList_", pure.} = object
  QString* {.cpp, importc: "QString_", pure.} = object
  QQmlEngine* {.cpp, importc: "QQmlEngine_", pure.} = object
  QQmlContext* {.cpp, importc: "QQmlContext_", pure.} = object
  QQmlComponent* {.cpp, importc: "QQmlComponent_", pure.} = object
  QQmlListProperty* {.cpp, importc: "QQmlListProperty_", pure.} = object
  QQuickWindow* {.cpp, importc: "QQuickWindow_", pure.} = object
  QQuickView* {.cpp, importc: "QQuickView_", pure.} = object
  QMessageLogContext* {.cpp, importc: "QMessageLogContext_", pure.} = object
  QImage* {.cpp, importc: "QImage_", pure.} = object
  QThread* {.cpp, importc: "QThread_", pure.} = object
  GoValue* {.cpp, importc: "GoValue_", pure.} = object
  GoAddr* {.cpp, pure.} = object
  TypeSpec* {.cpp, importc: "GoTypeSpec_".} = object
    name*: cstring
    singleton*: int

  QPointer* = array[0..7, cchar]

  error* = char

proc errorf*(format: cstring): ptr error {.varargs, cpp.}
proc panicf*(format: cstring) {.varargs, cpp.}

type
  DataType* {.cpp.} = enum
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

  DataValue* {.importc.} = object
    dataType*: DataType
    data*: QPointer
    len*: cint

  MemberInfo* {.cpp, importc: "GoMemberInfo".} = object
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

  TypeInfo* {.cpp, importc: "GoTypeInfo".} = object
    typeName*: cstring
    fields*: ptr MemberInfo
    methods*: ptr MemberInfo
    members*: ptr MemberInfo  ## # fields + methods
    paint*: ptr MemberInfo    ## # in methods too
    fieldsLen*: cint
    methodsLen*: cint
    membersLen*: cint
    memberNames*: cstring
    metaObject*: ptr QMetaObject

  LogMessage* {.cpp.} = object
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
proc currentThread*(): ptr QThread {.cpp.}
proc appThread*(): ptr QThread {.cpp.}
proc newQEngine*(parent: ptr QObject = nil): ptr QQmlEngine {.cpp, importc: "newEngine".}
proc engineRootContext*(engine: ptr QQmlEngine): ptr QQmlContext {.cpp.}
proc engineSetOwnershipCPP*(engine: ptr QQmlEngine, qobject: ptr QObject) {.cpp.}
proc engineSetOwnershipJS*(engine: ptr QQmlEngine, qobject: ptr QObject) {.cpp.}
proc engineSetContextForObject*(engine: ptr QQmlEngine, qobject: ptr QObject) {.cpp.}
proc engineAddImageProvider*(engine: ptr QQmlEngine, providerId: ptr QString,
                            imageFunc: pointer) {.cpp.}
proc contextGetProperty*(context: ptr QQmlContext, name: ptr QString, value: ptr DataValue) {.cpp.}
proc contextSetProperty*(context: ptr QQmlContext, name: ptr QString, value: ptr DataValue) {.cpp.}
proc contextSetObject*(context: ptr QQmlContext, value: ptr QObject) {.cpp.}
proc contextSpawn*(context: ptr QQmlContext): ptr QQmlContext {.cpp.}
proc delObject*(qobject: ptr QObject) {.cpp.}
proc delObjectLater*(qobject: pointer) {.cpp.}
proc objectTypeName*(qobject: ptr QObject): cstring {.cpp.}
proc objectGetProperty*(qobject: ptr QObject, name: cstring, result: ptr DataValue): cint {.cpp.}
proc objectSetProperty*(qobject: ptr QObject, name: cstring, value: ptr DataValue): ptr error {.cpp.}
proc objectSetParent*(qobject: ptr QObject, parent: ptr QObject) {.cpp.}
proc objectInvoke*(qobject: ptr QObject, `method`: cstring, methodLen: cint,
                  result: ptr DataValue, params: ptr DataValue, paramsLen: cint): ptr error {.cpp.}
proc objectFindChild*(qobject: ptr QObject, name: ptr QString, result: ptr DataValue) {.cpp.}
proc objectContext*(qobject: ptr QObject): ptr QQmlContext {.cpp.}
proc objectIsComponent*(qobject: ptr QObject): cint {.cpp.}
proc objectIsWindow*(qobject: ptr QObject): cint {.cpp.}
proc objectIsView*(qobject: ptr QObject): cint {.cpp.}
proc objectConnect*(qobject: ptr QObject, signal: cstring, signalLen: cint,
                   engine: ptr QQmlEngine, `func`: pointer, argsLen: cint): ptr error {.cpp.}
proc objectGoAddr*(qobject: ptr QObject, goaddr: ptr ptr GoAddr): ptr error {.cpp.}
proc newComponent*(engine: ptr QQmlEngine, parent: ptr QObject): ptr QQmlComponent {.cpp.}
proc componentLoadURL*(component: ptr QQmlComponent, url: cstring, urlLen: cint) {.cpp.}
proc componentSetData*(component: ptr QQmlComponent, data: cstring, dataLen: cint,
                      url: cstring, urlLen: cint) {.cpp.}
proc componentErrorString*(component: ptr QQmlComponent): cstring {.cpp.}
proc componentCreate*(component: ptr QQmlComponent, context: ptr QQmlContext): ptr QObject {.cpp.}
proc componentCreateWindow*(component: ptr QQmlComponent, context: ptr QQmlContext): ptr QQuickWindow {.cpp.}
proc windowShow*(win: ptr QQuickWindow) {.cpp.}
proc windowHide*(win: ptr QQuickWindow) {.cpp.}
proc windowPlatformId*(win: ptr QQuickWindow): pointer {.cpp.}
proc windowConnectHidden*(win: ptr QQuickWindow) {.cpp.}
proc windowRootObject*(win: ptr QQuickWindow): ptr QObject {.cpp.}
proc windowGrabWindow*(win: ptr QQuickWindow): ptr QImage {.cpp.}
proc newImage*(width: cint, height: cint): ptr QImage {.cpp.}
proc delImage*(image: ptr QImage) {.cpp.}
proc imageSize*(image: ptr QImage, width: ptr cint, height: ptr cint) {.cpp.}
proc imageBits*(image: ptr QImage): ptr cuchar {.cpp.}
proc imageConstBits*(image: ptr QImage): ptr cuchar {.cpp.}
proc newString*(data: cstring, len: cint): ptr QString {.cpp.}
proc delString*(s: ptr QString) {.cpp.}
proc newGoValue*(goaddr: ptr GoAddr, typeInfo: ptr TypeInfo, parent: ptr QObject): ptr GoValue {.cpp.}
proc goValueActivate*(value: ptr GoValue, typeInfo: ptr TypeInfo, addrOffset: cint) {.cpp.}
proc packDataValue*(`var`: ptr QVariant, result: ptr DataValue) {.cpp.}
proc unpackDataValue*(value: ptr DataValue, result: ptr QVariant) {.cpp.}
proc newVariantList*(list: ptr DataValue, len: cint): ptr QVariantList {.cpp.}
proc newListProperty*(goaddr: ptr GoAddr, reflectIndex: pointer, setIndex: pointer): ptr QQmlListProperty {.cpp.}
proc registerType*(location: cstring, major: cint, minor: cint, name: cstring,
                  typeInfo: ptr TypeInfo, spec: ptr TypeSpec): cint {.cpp.}
proc registerSingleton*(location: cstring, major: cint, minor: cint, name: cstring,
                       typeInfo: ptr TypeInfo, spec: ptr TypeSpec): cint {.cpp.}
proc installLogHandler*() {.cpp.}
proc registerResourceData*(version: cint, tree: cstring, name: cstring, data: cstring) {.cpp.}
proc unregisterResourceData*(version: cint, tree: cstring, name: cstring, data: cstring) {.cpp.}
