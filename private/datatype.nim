import macros, strutils, tables, capi, util

const
  FIELD_PREFIX = "m"

type
  NimObject* = ref object of RootObj

var
  types = newTable[string, TypeInfo]()
  constructors = newTable[string, proc(retval: var pointer, args: varargs[pointer])]()
  slots = newTable[string, proc(retval: var pointer, args: varargs[pointer])]()
  pointerToTypeMap = newTable[pointer, string]()

proc addType*(name: string, typeInfo: TypeInfo) =
  types[name] = typeInfo

proc getType*(name: string): TypeInfo =
  types[name]

proc getMemberInfo*(typeInfo: TypeInfo, memberIndex: int): ptr MemberInfo =
  cast[ptr MemberInfo](cast[uint](typeInfo.members) + uint(sizeof(MemberInfo) * memberIndex))

proc addConstructor*(typeName: string, f: proc(retval: var pointer, args: varargs[pointer])) =
  constructors.add(typeName, f)

proc getConstructor*(typeName: string): proc(retval: var pointer, args: varargs[pointer]) =
  constructors[typeName]

proc addSlot*(typeName, methodName: string, f: proc(retval: var pointer, args: varargs[pointer])) =
  slots.add("$1.$2" % [typeName, methodName], f)

proc getSlot*(typeName, methodName: string): proc(retval: var pointer, args: varargs[pointer]) =
  slots["$1.$2" % [typeName, methodName]]


proc trackPointer*(p: pointer, typ: string) =
  pointerToTypeMap.add(p, typ)

proc untrackPointer*(p: pointer) =
  pointerToTypeMap.del(p)

proc getPointerType*(p: pointer): string =
  pointerToTypeMap[p]

proc getSetterName*(fieldName: string): string =
  "set" & capitalize(fieldName)

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
    fieldList, methodList: seq[string] = @[]
    fieldName, fieldType: NimNode
    fieldNameStr, fieldTypeStr: string
    signal, setter, length: NimNode
    isArray: bool
    typeNameStr = $typeName
    constructorNameStr = "new" & typeNameStr


    recList = newNimNode(nnkRecList)
    slotProcs = newStmtList()
    signalProcs = newStmtList()
    typeDeclaration, memberDeclaration = newStmtList()

    numField: int
    numMethod: int


  for node in body.children:
    case node.kind:
      of nnkMethodDef, nnkProcDef:
        if node[0].kind == nnkIdent:
          methodList.add(toLower($node[0]))
        else:
          methodList.add(toLower($node[0][1]))
        inc(numMethod)
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
      var methodName: string
      if node[0].kind == nnkIdent:
        methodName = $node[0]
      else:
        methodName = $node[0][1]
      if methodName == constructorNameStr:
        stm.add("addConstructor(\"$1\", $2)\n" % [typeNameStr, constructorNameStr])
      #if methodName.startsWith("set"):

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

        recList.add(n)

        signal = ident("$1Changed" % $fieldName)
        setter = ident(getSetterName($fieldName))
        length = ident("len")

        if isArray:
          slotProcs.add quote do:
            proc `fieldName`*(self: `typeName`): var `fieldType` =
              if self.`fieldName`.isNil:
                self.`fieldName` = @[]
              self.`fieldName`
        else:
          slotProcs.add quote do:
            proc `fieldName`*(p: var pointer, args: varargs[pointer]) =
              let self = to[`typeName`](args[0])
              if p.isNil:
                p = alloc(DataValue)
              var dv = cast[ptr DataValue](p)

              dv.dataType = dataTypeOf(`fieldType`)
              dv.data = cast[array[8, char]](addr self.`fieldName`)
              dv.`length` = dataLen(self.`fieldName`)

          if not (($setter).toLower() in methodList): # allow custom setters
            slotProcs.add quote do:
              proc `setter`*(p: var pointer, args: varargs[pointer]) =
                let self = to[`typeName`](args[0])
                let value = cast[ptr `fieldType`](p)
                self.`fieldName` = value[]
                self[].`signal`()
          stm.add("addSlot(\"$1\", \"$2\", $3)\n" % [typeNameStr, $fieldName, $fieldName])
          stm.add("addSlot(\"$1\", \"$2\", $3)\n" % [typeNameStr, $setter, $setter])

          signalProcs.add quote do:
            proc `signal`*(self: `typeName`) =
              echo "signal ", self

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
#        type `typeName` = ref object of NimObject
        type `typeName` = object
  )
  #echo result.treeRepr
#  result[0][0][0][2][0][2] = recList
  result[0][0][0][2][2] = recList

  typeDeclaration = parseStmt(stm)
  result.add(signalProcs)
  result.add(slotProcs)
  result.add(typeDeclaration)
  #echo slotProcs.treeRepr
