#ifndef GOVALUETYPE_H
#define GOVALUETYPE_H

#include "govalue.h"

template <int N>
class GoValueType : public GoValue
{
public:

 GoValueType()
   : GoValue(hookGoValueTypeNew(this, &typeSpec), &typeInfo, 0) {};

    static void init(GoTypeInfo *info, GoTypeSpec_ *spec)
    {

        memcpy(&typeInfo, info, sizeof(GoTypeInfo));
        memcpy(&typeSpec, spec, sizeof(GoTypeSpec_));
        static_cast<QMetaObject &>(staticMetaObject) = *metaObjectFor(&typeInfo);

	qDebug() << "Initializing new value for type:" << typeSpec.name;


    };

    static GoTypeSpec_ typeSpec;
    static GoTypeInfo typeInfo;
    static QMetaObject staticMetaObject;
};

template <int N>
class GoPaintedValueType : public GoPaintedValue
{
public:

    GoPaintedValueType()
        : GoPaintedValue(hookGoValueTypeNew(this, &typeSpec), &typeInfo, 0) {};

    static void init(GoTypeInfo *info, GoTypeSpec_ *spec)
    {
        memcpy(&typeInfo, info, sizeof(GoTypeInfo));
        memcpy(&typeSpec, spec, sizeof(GoTypeSpec_));
        static_cast<QMetaObject &>(staticMetaObject) = *metaObjectFor(&typeInfo);
    };

    static GoTypeSpec_ typeSpec;
    static GoTypeInfo typeInfo;
    static QMetaObject staticMetaObject;
};

#endif // GOVALUETYPE_H

// vim:ts=4:sw=4:et
