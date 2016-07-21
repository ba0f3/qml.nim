import macros, strutils, tables, capi, util

let
  MEMBER_INFO_LENGTH* = sizeof(MemberInfo)

var
  typeInfoMap = newTable[string, TypeInfo]()
  constructors = newTable[string, proc(retval: var pointer, args: varargs[pointer])]()
  slots = newTable[string, proc(retval: var pointer, args: varargs[pointer])]()
  pointerToTypeMap = newTable[pointer, string]()
  typeIndex {.compileTime.} = 0

proc addType*(name: string, typeInfo: TypeInfo) =
  typeInfoMap[name] = typeInfo

proc getType*(name: string): TypeInfo =
  typeInfoMap[name]

proc getMemberInfo*(typeInfo: TypeInfo, memberIndex: int): ptr MemberInfo =
  to[MemberInfo](cast[uint](typeInfo.members) + uint(sizeof(MemberInfo) * memberIndex))

proc registerConstructor*(typeName: string, f: proc(retval: var pointer, args: varargs[pointer])) =
  constructors.add(typeName, f)

proc getConstructor*(typeName: string): proc(retval: var pointer, args: varargs[pointer]) =
  constructors[typeName]

proc addSlot*(typeName, methodName: string, f: proc(retval: var pointer, args: varargs[pointer])) =
  slots.add("$1.$2" % [typeName, methodName], f)

proc getSlot*(typeName, methodName: string): proc(retval: var pointer, args: varargs[pointer]) =
  slots["$1.$2" % [typeName, methodName]]

proc trackPointer*(p: pointer, typ: string) =
  pointerToTypeMap.add(p, typ)

proc destroyPointer*(p: pointer) =
  pointerToTypeMap.del(p)
  dealloc(p)

proc getPointerType*(p: pointer): string =
  pointerToTypeMap[p]

proc getSetterName*(fieldName: string): string =
  "set" & capitalize(fieldName)

proc rewriteMethodDeclaration(node: NimNode) {.compileTime.} =
  var
    oldParams = node.params
    oldBody = node.body
    params = newNimNode(nnkFormalParams)
    body = newStmtList()

  params.add newEmptyNode() # no return value
  params.add newIdentDefs(ident("retVal"), newNimNode(nnkVarTy).add(ident("pointer"))) # retval: var pointer
  params.add newIdentDefs(ident("args"), newNimNode(nnkBracketExpr).add(ident("varargs"), ident("pointer"))) # args: varargs[pointer]

  if oldParams[0].kind != nnkEmpty:
    body.add(newIfStmt((
      newDotExpr(ident("retVal"), ident("isNil")), # if retVal.isNil
      newStmtList(newAssignment(ident("retVal"), newCall(ident("alloc"), oldParams[0]))) # retVal = alloc(`retVal`)
    )))

    body.add(newVarStmt(ident("result"), # var result = to[`retVal`](retVal)
      newCall(
        newNimNode(nnkBracketExpr).add(ident("to"), oldParams[0]),
        ident("retVal")
      )
    ))

  for i in 1..<oldParams.len:
    let
      param = oldParams[i]
      argIndex = i-1

    body.add(newVarStmt(param[0], # var self = to[Type](args[0])
      newCall(
        newNimNode(nnkBracketExpr).add(ident("to"), param[1]),
        newNimNode(nnkBracketExpr).add(ident("args"), newIntLitNode(argIndex)),
      )
    ))
  body.add(oldBody)

  node.params = params
  node.body = body

proc processFieldList(body: NimNode): seq[tuple[name, typ: string]] {.compileTime.} =
  result = @[]
  var fieldList: seq[string] = @[]
  for node in body.children:
    if node.kind  == nnkVarSection:
      for n in node.children:
        let
          fieldName = $n[0]
          fieldType = $n[1]
        if fieldName.toLower() in fieldList:
          raise newException(FieldError, "redefinition of '$1'" % [fieldName])
        fieldList.add(fieldName.toLower())
        result.add((fieldName, fieldType))

macro Q_OBJECT*(head: expr, body: stmt): stmt {.immediate.} =
  inc(typeIndex)
  result = newStmtList()

  var typeName, baseName: NimNode
  if head.kind == nnkIdent:
    typeName = head
  elif head.kind == nnkInfix and $head[0] == "of":
    typeName = head[1]
    baseName = head[2]
  else:
    quit "Invalid node: " & head.lispRepr

  if not baseName.isNil:
    raise newException(SystemError, "inheritance for QObject is not supported")

  var
    objectTy = newNimNode(nnkObjectTy)
    fieldList, methodList: seq[string] = @[]

  objectTy.add(newEmptyNode(), newEmptyNode())
  result.add(newNimNode(nnkTypeSection).add(
    newNimNode(nnkTypeDef).add(typeName, newEmptyNode(), objectTy)
  ))

  fieldList = processFieldList(body)

  var


    fieldName, fieldType: NimNode
    fieldNameStr, fieldTypeStr: string
    signal, setter: NimNode
    isArray: bool
    typeNameStr = $typeName
    constructorName = ident("new" & typeNameStr)


    recList = newNimNode(nnkRecList)
    slotProcs = newStmtList()
    signalProcs = newStmtList()
    typeDeclaration, memberDeclaration = newStmtList()

    numField: int
    numMethod: int

  var stm = """
var
  membersSize, membersi: int
  members: uint
  memberInfo: ptr MemberInfo"""

  for node in body.children:
    case node.kind:
      of nnkMethodDef, nnkProcDef:
        if node[0].kind == nnkIdent:
          methodList.add(toLower($node[0]))
        else:
          methodList.add(toLower($node[0][1]))
        inc(numMethod)
        rewriteMethodDeclaration(node)
        result.add(node)

      of nnkVarSection:
        for n in node.children:
          fieldNameStr = toLower($n[0])
          if fieldNameStr in fieldList:
            raise newException(FieldError, "redefinition of '$1' [$2]" % [fieldNameStr, $typeName])
          fieldList.add(fieldNameStr)

        inc(numField)
      else:
        discard
  let
    methodsLen = numField * 2 # setter + getter + sinal?
    membersLen = numField * 3 # field + setter * getter
  stm.add """

  typeInfo$1: TypeInfo
members = cast[uint](alloc(MEMBER_INFO_LENGTH * $2))
membersi = 0
""" % [$typeIndex, $membersLen]

  if not (toLower($constructorName) in methodList):
    result.add quote do:
      proc `constructorName`*(p: var pointer, args: varargs[pointer]) =
        if p.isNil:
          p = alloc(`typeName`)
  result.add quote do:
    registerConstructor(`typeNameStr`, `constructorName`)
  var i = 0
  for node in body.children:
    if node.kind == nnkVarSection:
      # variables get turned into fields of the type.
      for n in node.children:
        fieldName = n[0]
        fieldType = n[1]
        fieldNameStr = $fieldName
        fieldTypeStr = $fieldType

        if n[1].kind == nnkBracketExpr:
          if n[1][0] != ident("seq"):
            raise newException(ValueError, "only seq is support as array")
          isArray = true
        else:
          isArray = false

        recList.add(n)

        signal = ident("$1Changed" % $fieldName)
        setter = ident(getSetterName($fieldName))

        if isArray:
          slotProcs.add quote do:
            proc `fieldName`*(self: `typeName`): var `fieldType` =
              if self.`fieldName`.isNil:
                self.`fieldName` = @[]
              self.`fieldName`
        else:
          slotProcs.add quote do:
            proc `fieldName`*(p: var pointer, args: varargs[pointer]) =
              var self = to[`typeName`](args[0])[]
              if p.isNil:
                p = alloc(DataValue)
              var
                dv = to[DataValue](p)
              dataValueOf(dv, self.`fieldName`)

          if not (($setter).toLower() in methodList): # allow custom setters
            slotProcs.add quote do:
              proc `setter`*(p: var pointer, args: varargs[pointer]) =
                let self = to[`typeName`](args[0])
                let value = to[`fieldType`](args[1])
                self.`fieldName` = value[]
                self[].`signal`()
          stm.add("addSlot(\"$1\", \"$2\", $3)\n" % [typeNameStr, $fieldName, $fieldName])
          stm.add("addSlot(\"$1\", \"$2\", $3)\n" % [typeNameStr, $setter, $setter])

          signalProcs.add quote do:
            proc `signal`*(self: `typeName`) =
              discard #echo "signal ", self
        inc(i)
        stm.add """

memberInfo = to[MemberInfo](members + uint(MEMBER_INFO_LENGTH * membersi))
memberInfo.memberName = "$1"
memberInfo.memberType = dataTypeOf($2)
memberInfo.reflectIndex = $3
inc(membersi)
""" % [$fieldName, fieldTypeStr, $i]

  stm.add """
typeInfo$1.membersLen = $5
typeInfo$1.members = to[MemberInfo](members)
typeInfo$1.typeName = "$2"
typeInfo$1.fieldsLen = $3 # * 2
typeInfo$1.fields = typeInfo$1.members
addType("$2", typeInfo$1)
""" % [$typeIndex, typeNameStr, $numField, $methodsLen, $membersLen]
  echo stm
  objectTy.add(recList)
  typeDeclaration = parseStmt(stm)
  result.add(signalProcs)
  result.add(slotProcs)
  result.add(typeDeclaration)
  #echo slotProcs.treeRepr
