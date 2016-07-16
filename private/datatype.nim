import macros, strutils, tables, capi

const
  FIELD_PREFIX = "m"

type
  NimObject* = ref object of RootObj

var
  types = newTable[string, TypeInfo]()
  constructors = newTable[string, proc(retval: var pointer, args: varargs[pointer])]()

proc addType*(name: string, typeInfo: TypeInfo) =
  types[name] = typeInfo


proc getType*(name: string): TypeInfo =
  types[name]

proc addConstructor*(name: string, f: proc(retval: var pointer, args: varargs[pointer])) =
  constructors.add(name, f)

proc getConstructor*(name: string): proc(retval: var pointer, args: varargs[pointer]) =
  constructors[name]

macro Q_OBJECT*(head: expr, body: stmt): stmt {.immediate.} =
  var typeName, baseName: NimNode

  if head.kind == nnkIdent:
    typeName = head

  elif head.kind == nnkInfix and $head[0] == "of":
    typeName = head[1]
    baseName = head[2]
  else:
    quit "Invalid node: " & head.lispRepr

  if not baseName.isNil:
    raise newException(SystemError, "inheritance for NimObject is not supported")

  result = newStmtList()

  var
    fieldList: seq[string] = @[]
    fieldName, fieldType: NimNode
    fieldNameStr, fieldTypeStr: string
    newFieldName, setter: NimNode
    changed: NimNode
    isArray: bool
    typeNameStr = $typeName
    constructorNameStr = "new" & typeNameStr

    recList = newNimNode(nnkRecList)
    slotProcs = newStmtList()
    signalProcs = newStmtList()
    typeDeclaration, memberDeclaration = newStmtList()

    numField: int


  for node in body.children:
    case node.kind:
      of nnkMethodDef, nnkProcDef:
        result.add(node)

      of nnkVarSection:
        inc(numField)
      else:
        discard

  let
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
  var i = 0
  for node in body.children:
    case node.kind:
    of nnkMethodDef, nnkProcDef:
      if startsWith($node[0], constructorNameStr):
        stm.add("addConstructor(\"" & typeNameStr & "\", " & constructorNameStr & ")\n")
      ## inject `this: T` into the arguments
      #let p = copyNimTree(node.params)
      #p.insert(1, newIdentDefs(ident"self", typeName))
      #node.params = p
      #result.add(node)

    of nnkVarSection:
      # variables get turned into fields of the type.
      for n in node.children:
        fieldName = n[0]
        fieldType = n[1]

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


        fieldNameStr = $fieldName
        fieldTypeStr = $fieldType
        inc(i)
        stm.add """

memberInfo = cast[ptr MemberInfo](members + uint(memberInfoSize * membersi))
memberInfo.memberName = "$1"
memberInfo.memberType = dataTypeOf($2)
memberInfo.reflectIndex = $3
memberInfo.reflectGetIndex = -1
memberInfo.reflectSetIndex = -1
memberInfo.addrOffset = 0
inc(membersi)
""" % [$fieldName, fieldTypeStr, $i]

    else:
      discard


  stm.add """
typeInfo.membersLen = $4
typeInfo.members = cast[ptr MemberInfo](members)
typeInfo.typeName = "$1"
typeInfo.fieldsLen = $2 # * 2
typeInfo.fields = typeInfo.members
#typeInfo.methodsLen = $3
typeInfo.methods = nil
addType("$1", typeInfo)
""" % [typeNameStr, $numField, $methodsLen, $membersLen]

  #echo stm

  result.insert(0,
      quote do:
        type `typeName` = ref object of NimObject
  )

  result[0][0][0][2][0][2] = recList

  typeDeclaration = parseStmt(stm)
  #result.add(signalProcs)
  #result.add(slotProcs)
  result.add(typeDeclaration)
  #echo result.treeRepr


proc dataTypeOf*(typ: typedesc): DataType =
  when typ is string:
    DTString
  elif typ is bool:
    DTBool
  elif typ is int:
    when sizeof(int) == 8:
      DTInt64
    else:
      DTInt32
  elif typ is int64:
    DTInt64
  elif typ is int32:
    DTInt32
  elif typ is float32:
    DTDloat32
  elif typ is float64:
    DTFload64
  elif typ is auto or typ is any:
    DTAny
  elif typ is seq or typ is array:
    DTListProperty
  else:
    DTObject
