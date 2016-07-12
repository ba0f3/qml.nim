import macros, strutils

type
  QMetaObject* = object

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
  DataValue* {.importc.} = object
    dataType*: DataType
    data*: array[8, char]
    len*: cint

  MemberInfo* = object
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

  TypeInfo* = object
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


const
  FIELD_PREFIX = "m"

var
  types*: seq[TypeInfo] = @[]

macro Q_OBJECT*(head: expr, body: stmt): stmt {.immediate.} =
  var typeName, baseName: NimNode

  if head.kind == nnkIdent:
    typeName = head

  elif head.kind == nnkInfix and $head[0] == "of":
    typeName = head[1]
    baseName = head[2]
  else:
    quit "Invalid node: " & head.lispRepr

  result = newStmtList()

  var
    fieldList: seq[string] = @[]
    fieldName, fieldType: NimNode
    fieldNameStr: string
    newFieldName, setter: NimNode
    changed: NimNode
    isArray: bool
    typeNameStr = $typeName

    recList = newNimNode(nnkRecList)
    slotProcs = newStmtList()
    signalProcs = newStmtList()
    typeDeclaration, memberDeclaration = newStmtList()

    numField: int


  for node in body.children:
    case node.kind:
      of nnkMethodDef, nnkProcDef:
        # inject `this: T` into the arguments
        let p = copyNimTree(node.params)
        p.insert(1, newIdentDefs(ident"this", typeName))
        node.params = p
        result.add(node)

      of nnkVarSection:
        inc(numField)
        # variables get turned into fields of the type.
        for n in node.children:
          fieldName = n[0]
          fieldType = n[1]

          fieldNameStr = $n[0]

          if n[1].kind == nnkBracketExpr:
            if n[1][0] != ident("seq"):
              raise newException(ValueError, "only seq is support as array")
            isArray = true
          else:
            isArray = false

          fieldList.add($fieldName)

          setter = newNimNode(nnkAccQuoted)
          setter.add(fieldName)
          setter.add(ident("="))

          changed = ident($fieldName & "Changed")
          newFieldName = ident(FIELD_PREFIX & capitalize($fieldName))
          n[0] = newFieldName
          recList.add(n)

          if isArray:
            slotProcs.add quote do:
              proc `fieldName`*(self: `typeName`): var `fieldType` =
                if self.`newFieldName`.isNil:
                  self.`newFieldName` = @[]
                self.`newFieldName`
          else:
            slotProcs.add quote do:
              proc `fieldName`*(self: `typeName`): `fieldType` = self.`newFieldName`

          slotProcs.add quote do:
            proc `setter`*(self: `typeName`, val: `fieldType`) =
              self.`newFieldName` = val
              self.`changed`()

          signalProcs.add quote do:
            proc `changed`*(self: `typeName`) =
              discard
      else:
        result.add(node)

  result.insert(0,
    if baseName == nil:
      quote do:
        type `typeName` = ref object of RootObj
    else:
      quote do:
        type `typeName` = ref object of `baseName`
  )

  result[0][0][0][2][0][2] = recList

  var
    methodsLen = numField * 2 # setter + getter + sinal?
    membersLen = numField * 3 # field + setter * getter

  typeDeclaration.add quote do:
    var
      typeInfo: TypeInfo
      memberInfoSize = sizeof(MemberInfo)
      membersSize = memberInfoSize * `membersLen`
      members = cast[uint](alloc(membersSize))

      membersi = 0
      memberInfo: ptr MemberInfo

  for node in body.children:
    if node.kind == nnkVarSection:

        memberDeclaration =  quote do:
          memberInfo = cast[ptr MemberInfo](members + uint(memberInfoSize * membersi))
          memberInfo.memberName = `fieldNameStr`
          inc(membersi)

        typeDeclaration[0].add memberDeclaration[0]

  #typeDeclaration[0].add quote do:
  #  typeInfo.typeName = `typeNameStr`
  #  typeInfo.fieldsLen = `numField`
  #  typeInfo.methodsLen = `methodsLen`
  #  typeInfo.membersLen = `membersLen`
  #  typeInfo.members = cast[ptr MemberInfo](members)
  #  add(types, typeInfo)

  var newproc = ident("new" & $typeName)
  result.add(signalProcs)
  result.add(slotProcs)
  result.add(typeDeclaration)
  echo typeDeclaration.treeRepr
  #echo result.treeRepr
