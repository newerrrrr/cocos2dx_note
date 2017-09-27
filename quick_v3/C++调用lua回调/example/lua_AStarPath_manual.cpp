#include "lua_AStarPath_manual.hpp"
#include "AStarPath.h"
#include "tolua_fix.h"
#include "LuaBasicConversions.h"
#include "CCLuaValue.h"


int lua_AStarPath_AStarPath_test(lua_State* tolua_S)
{
    int argc = 0;
    cocos2d::AStarPath* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"cc.AStarPath",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (cocos2d::AStarPath*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_AStarPath_AStarPath_test'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_AStarPath_AStarPath_test'", nullptr);
            return 0;
        }
        cobj->test();
        return 0;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "cc.AStarPath:test",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_AStarPath_AStarPath_test'.",&tolua_err);
#endif

    return 0;
}
int lua_AStarPath_AStarPath_findPath(lua_State* tolua_S)
{
    int argc = 0;
    cocos2d::AStarPath* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"cc.AStarPath",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (cocos2d::AStarPath*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_AStarPath_AStarPath_findPath'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 2) 
    {
        cocos2d::Vec2 arg0;
        cocos2d::Vec2 arg1;

        ok &= luaval_to_vec2(tolua_S, 2, &arg0, "cc.AStarPath:findPath");

        ok &= luaval_to_vec2(tolua_S, 3, &arg1, "cc.AStarPath:findPath");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_AStarPath_AStarPath_findPath'", nullptr);
            return 0;
        }
        std::vector<cocos2d::Vec2, std::allocator<cocos2d::Vec2> >* ret = cobj->findPath(arg0, arg1);
		//add by hlb manul 2015-03-22
        //object_to_luaval<std::vector<cocos2d::Vec2, std::allocator<cocos2d::Vec2> >>(tolua_S, "std::vector<cocos2d::Vec2, std::allocator<cocos2d::Vec2> >*",(std::vector<cocos2d::Vec2, std::allocator<cocos2d::Vec2> >*)ret);
		
		lua_newtable(tolua_S);
		for (int i=0; i< ret->size();i++)
		{
			lua_pushnumber(tolua_S, i+1);
			vec2_to_luaval(tolua_S, ret->at(i));
			lua_rawset(tolua_S, -3);
		}

		
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "cc.AStarPath:findPath",argc, 2);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_AStarPath_AStarPath_findPath'.",&tolua_err);
#endif

    return 0;
}
int lua_AStarPath_AStarPath_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"cc.AStarPath",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 4)
    {
        int arg0;
        int arg1;
        int arg2;
        bool arg3;
        ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "cc.AStarPath:create");
        ok &= luaval_to_int32(tolua_S, 3,(int *)&arg1, "cc.AStarPath:create");
        ok &= luaval_to_int32(tolua_S, 4,(int *)&arg2, "cc.AStarPath:create");
        ok &= luaval_to_boolean(tolua_S, 5,&arg3, "cc.AStarPath:create");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_AStarPath_AStarPath_create'", nullptr);
            return 0;
        }
        cocos2d::AStarPath* ret = cocos2d::AStarPath::create(arg0, arg1, arg2, arg3);
        object_to_luaval<cocos2d::AStarPath>(tolua_S, "cc.AStarPath",(cocos2d::AStarPath*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "cc.AStarPath:create",argc, 4);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_AStarPath_AStarPath_create'.",&tolua_err);
#endif
    return 0;
}
int lua_AStarPath_AStarPath_constructor(lua_State* tolua_S)
{
    int argc = 0;
    cocos2d::AStarPath* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif



    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_AStarPath_AStarPath_constructor'", nullptr);
            return 0;
        }
        cobj = new cocos2d::AStarPath();
        cobj->autorelease();
        int ID =  (int)cobj->_ID ;
        int* luaID =  &cobj->_luaID ;
        toluafix_pushusertype_ccobject(tolua_S, ID, luaID, (void*)cobj,"cc.AStarPath");
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "cc.AStarPath:AStarPath",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_error(tolua_S,"#ferror in function 'lua_AStarPath_AStarPath_constructor'.",&tolua_err);
#endif

    return 0;
}

static int lua_AStarPath_AStarPath_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (AStarPath)");
    return 0;
}


static int lua_AStarPath_AStarPath_registerScriptHandler(lua_State* tolua_S)
{
    if (NULL == tolua_S)
        return 0;
    
    int argc = 0;
    AStarPath* self = nullptr;
    
#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
	if (!tolua_isusertype(tolua_S,1,"cc.AStarPath",0,&tolua_err)) goto tolua_lerror;
#endif
    
    self = static_cast<AStarPath *>(tolua_tousertype(tolua_S,1,0));
#if COCOS2D_DEBUG >= 1
	if (nullptr == self) {
		tolua_error(tolua_S,"invalid 'self' in function 'tolua_cocos2d_Node_registerScriptHandler'\n", NULL);
		return 0;
	}
#endif
    
    argc = lua_gettop(tolua_S) - 1;
    
    if (argc == 1)
    {
#if COCOS2D_DEBUG >= 1
        if(!toluafix_isfunction(tolua_S,2,"LUA_FUNCTION",0,&tolua_err))
            goto tolua_lerror;
#endif
        
        LUA_FUNCTION handler = toluafix_ref_function(tolua_S,2,0);
        ScriptHandlerMgr::getInstance()->addObjectHandler((void*)self, handler, ScriptHandlerMgr::HandlerType::CALLFUNC);

        return 0;
    }
    
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n", "cc.AStarPath:registerScriptHandler",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_AStarPath_AStarPath_registerScriptHandler'.",&tolua_err);
    return 0;
#endif
}


static int lua_AStarPath_AStarPath_unregisterScriptHandler(lua_State* tolua_S)
{
    if (NULL == tolua_S)
        return 0;
    
    int argc = 0;
    AStarPath* self = nullptr;
    
#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
	if (!tolua_isusertype(tolua_S,1,"cc.AStarPath",0,&tolua_err)) goto tolua_lerror;
#endif
    
    self = static_cast<AStarPath *>(tolua_tousertype(tolua_S,1,0));
#if COCOS2D_DEBUG >= 1
	if (nullptr == self) {
		tolua_error(tolua_S,"invalid 'self' in function 'lua_AStarPath_AStarPath_unregisterScriptHandler'\n", NULL);
		return 0;
	}
#endif
    
    argc = lua_gettop(tolua_S) - 1;
    
    if (argc == 0)
    {
        ScriptHandlerMgr::getInstance()->removeObjectHandler((void*)self, ScriptHandlerMgr::HandlerType::CALLFUNC);
        return 0;
    }
    
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n", "cc.AStarPath:unregisterScriptHandler", argc, 0);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_AStarPath_AStarPath_unregisterScriptHandler'.",&tolua_err);
    return 0;
#endif
}


int lua_register_AStarPath_AStarPath(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"cc.AStarPath");
    tolua_cclass(tolua_S,"AStarPath","cc.AStarPath","cc.Ref",nullptr);

    tolua_beginmodule(tolua_S,"AStarPath");
        tolua_function(tolua_S,"new",lua_AStarPath_AStarPath_constructor);
        tolua_function(tolua_S,"test",lua_AStarPath_AStarPath_test);
        tolua_function(tolua_S,"findPath",lua_AStarPath_AStarPath_findPath);
        tolua_function(tolua_S,"create", lua_AStarPath_AStarPath_create);
        tolua_function(tolua_S,"registerScriptHandler", lua_AStarPath_AStarPath_registerScriptHandler);
        tolua_function(tolua_S,"unregisterScriptHandler", lua_AStarPath_AStarPath_unregisterScriptHandler);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(cocos2d::AStarPath).name();
    g_luaType[typeName] = "cc.AStarPath";
    g_typeCast["AStarPath"] = "cc.AStarPath";
    return 1;
}


TOLUA_API int register_all_AStarPath(lua_State* tolua_S)
{
	tolua_open(tolua_S);
	
	tolua_module(tolua_S,"cc",0);
	tolua_beginmodule(tolua_S,"cc");

	lua_register_AStarPath_AStarPath(tolua_S);

	tolua_endmodule(tolua_S);
	return 1;
}

