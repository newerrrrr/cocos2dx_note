#include "lua_testClass_auto.hpp"
#include "testClass.h"
#include "tolua_fix.h"
#include "LuaBasicConversions.h"



int lua_testClass_testClass_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"cc.testClass",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 0)
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_testClass_testClass_create'", nullptr);
            return 0;
        }
        cocos2d::testClass* ret = cocos2d::testClass::create();
        object_to_luaval<cocos2d::testClass>(tolua_S, "cc.testClass",(cocos2d::testClass*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "cc.testClass:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_testClass_testClass_create'.",&tolua_err);
#endif
    return 0;
}
int lua_testClass_testClass_constructor(lua_State* tolua_S)
{
    int argc = 0;
    cocos2d::testClass* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif



    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_testClass_testClass_constructor'", nullptr);
            return 0;
        }
        cobj = new cocos2d::testClass();
        cobj->autorelease();
        int ID =  (int)cobj->_ID ;
        int* luaID =  &cobj->_luaID ;
        toluafix_pushusertype_ccobject(tolua_S, ID, luaID, (void*)cobj,"cc.testClass");
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "cc.testClass:testClass",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_error(tolua_S,"#ferror in function 'lua_testClass_testClass_constructor'.",&tolua_err);
#endif

    return 0;
}

static int lua_testClass_testClass_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (testClass)");
    return 0;
}

int lua_register_testClass_testClass(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"cc.testClass");
    tolua_cclass(tolua_S,"testClass","cc.testClass","cc.Ref",nullptr);

    tolua_beginmodule(tolua_S,"testClass");
        tolua_function(tolua_S,"new",lua_testClass_testClass_constructor);
        tolua_function(tolua_S,"create", lua_testClass_testClass_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(cocos2d::testClass).name();
    g_luaType[typeName] = "cc.testClass";
    g_typeCast["testClass"] = "cc.testClass";
    return 1;
}
TOLUA_API int register_all_testClass(lua_State* tolua_S)
{
	tolua_open(tolua_S);
	
	tolua_module(tolua_S,"cc",0);
	tolua_beginmodule(tolua_S,"cc");

	lua_register_testClass_testClass(tolua_S);

	tolua_endmodule(tolua_S);
	return 1;
}

