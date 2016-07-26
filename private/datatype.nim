import macros, strutils, tables, capi, util

type
  QMethod = proc(retval: var pointer, args: varargs[pointer])

var
  typeInfoMap = newTable[string, TypeInfo]()
  methodMaps: seq[QMethod] = @[]
  pointerToTypeMap = newTable[pointer, string]()
  typeIndex {.compileTime.} = 0

proc addType*(name: string, typeInfo: TypeInfo) =
  typeInfoMap[name] = typeInfo

proc getType*(name: string): TypeInfo =
  typeInfoMap[name]

proc getMemberInfo*(typeInfo: TypeInfo, memberIndex: int): ptr MemberInfo =
  to[MemberInfo](cast[uint](typeInfo.members) + uint(sizeof(MemberInfo) * memberIndex))

proc registerMethod*(m: QMethod): int =
  methodMaps.add(m)
  result = methodMaps.len - 1

proc getMethod*(index: int): QMethod =
  methodMaps[index]

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

iterator methods(body: NimNode): NimNode =
  for node in body.children:
    if node.kind == nnkMethodDef or node.kind == nnkProcDef:
      yield node

iterator properties(body: NimNode): NimNode =
  for node in body.children:
    if node.kind == nnkVarSection:
      for n in node.children:
        yield n

proc processRecList(body: NimNode): NimNode {.compileTime.} =
  result = newNimNode(nnkRecList)

  var fieldList: seq[string] = @[]


  for node in body.properties:
    let fieldName = toLower($node[0])
    if fieldName in fieldList:
      raise newException(FieldError, "redefinition of '$1'" % [$node[0]])
    fieldList.add(fieldName)

    result.add(node)

proc createMandatoryMethods(typeName: string, body: NimNode) {.compileTime.} =
  var methodList: seq[string] = @[]

  # get declared methods
  for node in body.methods:
    if node[0].kind == nnkIdent:
      methodList.add(toLower($node[0]))
    else:
      methodList.add(toLower($node[0][1]))

  # construct constructor if not exists
  let constructorNameNode = ident("new" & typeName)

  if not (toLower($constructorNameNode) in methodList):
    body.add(newProc(constructorNameNode, params = [ident(typeName)]))

  # construct setters & getters
  var
    typeNameNode = ident(typeName)
    fieldNameNode, fieldTypeNode: NimNode
    setterNameNode: NimNode

  for node in body.properties:
    if node[1].kind == nnkBracketExpr and node[1][0] != ident("seq"):
      raise newException(ValueError, "only seq is support as array")

    fieldNameNode = node[0]
    fieldTypeNode = node[1]

    setterNameNode = ident(getSetterName($fieldNameNode))

    if not (toLower($fieldNameNode) in methodList):
      body.add quote do:
        proc `fieldNameNode`*(self: `typeNameNode`): ptr DataValue =
          result = dataValueOf(self.`fieldNameNode`)

    if not (toLower($setterNameNode) in methodList):
      body.add quote do:
        proc `setterNameNode`*(self: `typeNameNode`, value: `fieldNameNode`) =
          self.`fieldNameNode` = value[]

proc newMemberInfo(name: string, typ: DataType, index: int): MemberInfo =
  result.memberName = name
  result.memberType = typ
  result.reflectIndex = index.cint


proc constructTypeInfo*(typeName: string, body: NimNode): NimNode {.compileTime.} =
  var methodIndexMap = newTable[string, int]()
  for node in body.methods:
    if not endsWith($node[0], "*"):
      continue
    echo node.treeRepr


  result = newStmtList()
  var index = 0
  for node in body.properties:
    inc(index)
    let
      fieldName = $node[0]
      fieldType = $node[1]
    result.add(quote do:
      member = newMemberInfo(`fieldName`, dataTypeOf("`fieldType`"), i)
    )


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
  objectTy.add(processRecList(body))

  createMandatoryMethods($typeName, body)
  result.add constructTypeInfo($typeName, body)

  # 1. rewrite method declaration
  # 2. add procs to result
