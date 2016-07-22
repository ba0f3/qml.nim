import macros, strutils, tables, capi, util

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


proc processRecList(body: NimNode): NimNode {.compileTime.} =
  result = newNimNode(nnkRecList)

  var fieldList: seq[string] = @[]

  for node in body.children:
    if node.kind  == nnkVarSection:
      for n in node.children:
        let fieldName = toLower($n[0])
        if fieldName in fieldList:
          raise newException(FieldError, "redefinition of '$1'" % [$n[0]])
        fieldList.add(fieldName)

        result.add(n)

proc createMandatoryMethods(typeName: string, body: NimNode) {.compileTime.} =
  var methodList: seq[string] = @[]

  # get declared methods
  for node in body.children:
    if node.kind == nnkMethodDef or node.kind == nnkProcDef:
      if node[0].kind == nnkIdent:
        methodList.add(toLower($node[0]))
      else:
        methodList.add(toLower($node[0][1]))

  # construct constructor if not exists
  let constructorName = ident("new" & typeName)

  if not (constructorName.toLower in methodList):
    body.add(newProc(ident(constructorName), [ident(typeName)]))


  # construct setters & getters
  var
    typeNameNode = ident(typeName)
    fieldNameNode, fieldTypeNode: NimNode
    setterNameNode: NimNode

  for node in body.children:
    if node.kind == nnkVarSection:
      for n in node.children:

        if n[1].kind == nnkBracketExpr and n[1][0] != ident("seq"):
            raise newException(ValueError, "only seq is support as array")


        fieldNameNode = n[0]
        fieldTypeNode = n[1]

        setterNameNode = ident(getSetterName($fieldNameNode))


        if not (toLower($fieldNameNode) in methodList):
          body.add quote do:
            proc `fieldNameNode`*(self: `typeNameNode`): ptr DataValue =
              result = dataValueOf(self.`fieldName`)

        if not (toLower($setterNameNode) in methodList):
          body.add quote do:
            proc `setterNameNode`*(self: `typeNameNode`, value: `fieldNameNode`) =
              self.`fieldName` = value[]

  #for node in body.children:
  #  if node.kind == nnkMethodDef or node.kind == nnkProcDef:
  #    rewriteMethodDeclaration(node)

proc construcTypeInfo*(typeName: string, body: NimNode): NimNode =
  var stm = """
var
  membersSize, membersi: int
  members: uint
  memberInfo: ptr MemberInfo"""

  let
    methodsLen = numField * 2 # setter + getter + sinal?
    membersLen = numField * 3 # field + setter * getter

  for node in body.children:
    if node.kind == nnkVarSection:
      discard
  stm.add """

  typeInfo$1: TypeInfo
members = cast[uint](alloc($2))
membersi = 0
""" % [$typeIndex, $(membersLen)]

  if not (toLower($constructorName) in methodList):
  result.add quote do:
    registerConstructor(`typeNameStr`, `constructorName`)
  var i = 0
  for node in body.children:
    if node.kind == nnkVarSection:
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
    fieldList: seq[MemberInfo]
    methodList: seq[string] = @[]
    numField, numMethod: int

  objectTy.add(newEmptyNode(), newEmptyNode())
  result.add(newNimNode(nnkTypeSection).add(
    newNimNode(nnkTypeDef).add(typeName, newEmptyNode(), objectTy)
  ))


  # variables get turned into fields of the type.
  result.add(processRecList(body))
  createMandatoryMethods($typeName, body)
  constructTypeInfo(body)
