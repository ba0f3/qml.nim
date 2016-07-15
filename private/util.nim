import macros, strutils, capi

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

  var stm = """
    var
      typeInfo: TypeInfo
      memberInfoSize = sizeof(MemberInfo)
      membersSize = memberInfoSize * $1
      members = cast[uint](alloc(membersSize))

      membersi = 0
      memberInfo: ptr MemberInfo
""" % [$membersLen]

  for node in body.children:
    if node.kind == nnkVarSection:
      stm.add """

    memberInfo = cast[ptr MemberInfo](members + uint(memberInfoSize * membersi))
    memberInfo.memberName = $1
    inc(membersi)
""" % [fieldNameStr]
  echo stm
  typeDeclaration = parseStmt(stm)

  typeDeclaration[0].add quote do:
    typeInfo.typeName = `typeNameStr`
    typeInfo.fieldsLen = `numField`
    typeInfo.methodsLen = `methodsLen`
    typeInfo.membersLen = `membersLen`
    typeInfo.members = cast[ptr MemberInfo](members)
    add(types, typeInfo)

  var newproc = ident("new" & $typeName)
  result.add(signalProcs)
  result.add(slotProcs)
  result.add(typeDeclaration)
  echo typeDeclaration.treeRepr
  #echo result.treeRepr
