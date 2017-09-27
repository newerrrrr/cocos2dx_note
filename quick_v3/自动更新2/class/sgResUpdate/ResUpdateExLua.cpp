
#include "tolua_fix.h"
#include "cocos2d.h"
#include "CCLuaStack.h"
#include "CCLuaValue.h"
#include "CCLuaEngine.h"
#include "LuaBasicConversions.h"

#include "ResUpdateExLua.h"
#include "ResUpdateEx.h"

USING_NS_CC;



static int lua_ResUpdateEx_create(lua_State* tolua_S)
{
    int argc = 0;
    
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isusertable(tolua_S,1, "ResUpdateEx", 0, &tolua_err)) goto tolua_lerror;
#endif
    
    argc = lua_gettop(tolua_S) - 1;
    
    if(0 == argc)
    {
        ResUpdateEx* tolua_ret = (ResUpdateEx *)ResUpdateEx::create();
        tolua_pushusertype(tolua_S, (void *)tolua_ret, "ResUpdateEx");
        //object_to_luaval<ResUpdateEx>(tolua_S, "ResUpdateEx", (ResUpdateEx*)tolua_ret);
        return 1;
    }
    
    luaL_error(tolua_S, "'ResUpdateEx::create has wrong number of arguments: %d, was expecting %d\n", argc, 2);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_ResUpdateEx_create'.",&tolua_err);
    return 0;
#endif
}


static int lua_ResUpdateEx_addUpdateHandler(lua_State *tolua_S)                                                                        
{
    int argc = 0;
    ResUpdateEx* self = nullptr;
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"ResUpdateEx",0,&tolua_err)) goto tolua_lerror;
#endif

    self = (ResUpdateEx*)  tolua_tousertype(tolua_S,1,0);
#if COCOS2D_DEBUG >= 1
    if (nullptr == self)
    {
        tolua_error(tolua_S,"invalid 'self' in function 'lua_ResUpdateEx_addUpdateHandler'\n", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;
    
    if (3 == argc)
    {
         LUA_FUNCTION onError = toluafix_ref_function(tolua_S, 2, 0);
         LUA_FUNCTION onProgress = toluafix_ref_function(tolua_S, 3, 0);
         LUA_FUNCTION onSuccess = toluafix_ref_function(tolua_S, 4, 0);
              
        self->addUpdateHandler(onError, onProgress, onSuccess);    
        return 1;
    }
    
    luaL_error(tolua_S, "'lua_ResUpdateEx_addUpdateHandler() has wrong number of arguments: %d, was expecting %d\n", argc, 3);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_ResUpdateEx_addUpdateHandler' ",&tolua_err);
    return 0;
#endif

}

static int lua_ResUpdateEx_removeUpdateHandler(lua_State *tolua_S)                                                                        
{
    int argc = 0;
    ResUpdateEx* self = nullptr;
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"ResUpdateEx",0,&tolua_err)) goto tolua_lerror;
#endif

    self = (ResUpdateEx*)  tolua_tousertype(tolua_S,1, 0);
#if COCOS2D_DEBUG >= 1
    if (nullptr == self)
    {
        tolua_error(tolua_S,"invalid 'self' in function 'lua_ResUpdateEx_removeUpdateHandler'\n", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;    
    if (0 == argc)
    {
        self->removeUpdateHandler();    
        return 1;
    }
    
    luaL_error(tolua_S, "'lua_ResUpdateEx_removeUpdateHandler() has wrong number of arguments: %d, was expecting %d\n", argc, 0);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_ResUpdateEx_removeUpdateHandler' ",&tolua_err);
    return 0;
#endif

}

static int lua_ResUpdateEx_downloadFileAsync(lua_State *tolua_S)                                                                        
{
    int argc = 0;
    ResUpdateEx* self = nullptr;
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"ResUpdateEx",0,&tolua_err)) goto tolua_lerror;
#endif

    self = (ResUpdateEx*)  tolua_tousertype(tolua_S,1,0);
#if COCOS2D_DEBUG >= 1
    if (nullptr == self)
    {
        tolua_error(tolua_S,"invalid 'self' in function 'lua_ResUpdateEx_downloadFileAsync'\n", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;
    
    if (3 == argc)
    {
        size_t len2, len3, len4;
        const char* srcUrl = lua_tolstring(tolua_S, 2, &len2);
        const char* storagePath = lua_tolstring(tolua_S, 3, &len3);
         const char* customId = lua_tolstring(tolua_S, 4, &len4);
         /*
         LUA_FUNCTION onError = toluafix_ref_function(tolua_S, 5, 0);
         LUA_FUNCTION onProgress = toluafix_ref_function(tolua_S, 6, 0);
         LUA_FUNCTION onSuccess = toluafix_ref_function(tolua_S, 7, 0);
         
        ScriptHandlerMgr::getInstance()->addCustomHandler((void*)self, onError);
        ScriptHandlerMgr::getInstance()->addCustomHandler((void*)self, onProgress);
        ScriptHandlerMgr::getInstance()->addCustomHandler((void*)self, onSuccess);
        
        self->downloadFileAsync(srcUrl, storagePath, customId, onError, onProgress, onSuccess);      
        */
        self->downloadFileAsync(srcUrl, storagePath, customId);    
        return 1;
    }
    
    luaL_error(tolua_S, "'lua_ResUpdateEx_downloadFileAsync() has wrong number of arguments: %d, was expecting %d\n", argc, 3);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_ResUpdateEx_downloadFileAsync' ",&tolua_err);
    return 0;
#endif

}

static bool luaval_to_file_info(lua_State* L, int lo, FileUnit* outValue, const char* funcName)
{
    if (nullptr == L || nullptr == outValue)
        return false;
    
    bool ok = true;
    
    tolua_Error tolua_err;
    if (!tolua_istable(L, lo, 0, &tolua_err) )
    {
#if COCOS2D_DEBUG >=1
        luaval_to_native_err(L,"#ferror:",&tolua_err,funcName);
#endif
        ok = false;
    }
    
    
    if (ok)
    {
        lua_pushstring(L, "srcUrl");
        lua_gettable(L, lo);
        outValue->srcUrl = lua_isnil(L, -1) ? "" : lua_tostring(L, -1);
        lua_pop(L, 1);
        
        lua_pushstring(L, "storagePath");
        lua_gettable(L, lo);
        outValue->storagePath = lua_isnil(L, -1) ? "" : lua_tostring(L, -1);
        lua_pop(L, 1);
        
        lua_pushstring(L, "fileName");
        lua_gettable(L, lo);
        outValue->fileName = lua_isnil(L, -1) ? "" : lua_tostring(L, -1);
        lua_pop(L, 1);
    }
    return ok;
}

static bool luaval_to_std_vector_infos(lua_State* L, int lo, std::vector<FileUnit> *ret, const char* funcName)
{
    if (nullptr == L || nullptr == ret || lua_gettop(L) < lo)
        return false;
    
    tolua_Error tolua_err;
    bool ok = true;
    
    if (!tolua_istable(L, lo, 0, &tolua_err))
    {
#if COCOS2D_DEBUG >=1
        luaval_to_native_err(L,"#ferror:",&tolua_err,funcName);
#endif
        ok = false;
    }
    
    if (ok)
    {
        size_t len = lua_objlen(L, lo);
        FileUnit info;
        for (size_t i = 0; i < len; i++)
        {
            lua_pushnumber(L, i + 1);
            lua_gettable(L,lo);
            if (lua_istable(L, lua_gettop(L)))
            {
                ok &= luaval_to_file_info(L, lua_gettop(L), &info, funcName);
                if (ok)
                {
                    ret->push_back(info);
                }
            }
            else
            {
                CCASSERT(false, "FileUnit type is needed");
            }
            lua_pop(L, 1);
        }
    }
    
    return ok;
}



static int lua_ResUpdateEx_batchDownloadFileAsync(lua_State *tolua_S)                                                                        
{
    int argc = 0;
    ResUpdateEx* self = nullptr;
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"ResUpdateEx",0,&tolua_err)) goto tolua_lerror;
#endif

    self = (ResUpdateEx*)  tolua_tousertype(tolua_S,1,0);
#if COCOS2D_DEBUG >= 1
    if (nullptr == self)
    {
        tolua_error(tolua_S,"invalid 'self' in function 'lua_ResUpdateEx_batchDownloadFileAsync'\n", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;
    
    if (2 == argc)
    {
        std::vector<FileUnit> arg0;
        std::string arg1;

        bool ok = luaval_to_std_vector_infos(tolua_S, 2, &arg0, "ResUpdateEx.batchDownloadFileAsync");
        ok &= luaval_to_std_string(tolua_S, 3, &arg1, "ResUpdateEx.batchDownloadFileAsync");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_ResUpdateEx_batchDownloadFileAsync", nullptr);
            return 0;
        }
        
        self->batchDownloadFileAsync(arg0, arg1);
        return 1;
    }
    
    luaL_error(tolua_S, "'lua_ResUpdateEx_batchDownloadFileAsync() has wrong number of arguments: %d, was expecting %d\n", argc, 3);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_ResUpdateEx_batchDownloadFileAsync' ",&tolua_err);
    return 0;
#endif

}

static int lua_ResUpdateEx_decompress(lua_State *tolua_S)                                                                        
{
    int argc = 0;
    ResUpdateEx* self = nullptr;
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"ResUpdateEx",0,&tolua_err)) goto tolua_lerror;
#endif

    self = (ResUpdateEx*)  tolua_tousertype(tolua_S,1,0);
#if COCOS2D_DEBUG >= 1
    if (nullptr == self)
    {
        tolua_error(tolua_S,"invalid 'self' in function 'lua_ResUpdateEx_decompress'\n", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;
    
    if (1 == argc)
    {
        size_t len;
        const char* path = lua_tolstring(tolua_S, 2, &len);
        bool ret = self->decompress(path);          
        LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
        //stack->clean();  
        stack->pushBoolean(ret);
       
        return 1;
    }
    
    luaL_error(tolua_S, "'lua_ResUpdateEx_decompress() has wrong number of arguments: %d, was expecting %d\n", argc, 1);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_ResUpdateEx_decompress' ",&tolua_err);
    return 0;
#endif

}


static int lua_ResUpdateEx_getFileString(lua_State *tolua_S)                                                                        
{
    int argc = 0;
    ResUpdateEx* self = nullptr;
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"ResUpdateEx",0,&tolua_err)) goto tolua_lerror;
#endif

    self = (ResUpdateEx*)  tolua_tousertype(tolua_S,1,0);
#if COCOS2D_DEBUG >= 1
    if (nullptr == self)
    {
        tolua_error(tolua_S,"invalid 'self' in function 'lua_ResUpdateEx_getFileString'\n", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;
    
    if (1 == argc)
    {
        size_t len;
        const char* fullpath = lua_tolstring(tolua_S, 2, &len);
        std::string str = self->getFileString(std::string(fullpath)); 
        LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
        //stack->clean();   
        stack->pushString(str.c_str(), str.size());

        return 1;
    }
    
    luaL_error(tolua_S, "'lua_ResUpdateEx_getFileString() has wrong number of arguments: %d, was expecting %d\n", argc, 1);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_ResUpdateEx_getFileString' ",&tolua_err);
    return 0;
#endif

}


static int lua_ResUpdateEx_exitUpdate(lua_State *tolua_S)                                                                        
{
    int argc = 0;
    ResUpdateEx* self = nullptr;
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"ResUpdateEx",0,&tolua_err)) goto tolua_lerror;
#endif

    self = (ResUpdateEx*)  tolua_tousertype(tolua_S,1, 0);
#if COCOS2D_DEBUG >= 1
    if (nullptr == self)
    {
        tolua_error(tolua_S,"invalid 'self' in function 'lua_ResUpdateEx_exitUpdate'\n", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;    
    if (0 == argc)
    {
        self->exitUpdate();    
        return 1;
    }
    
    luaL_error(tolua_S, "'lua_ResUpdateEx_exitUpdate() has wrong number of arguments: %d, was expecting %d\n", argc, 0);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_ResUpdateEx_exitUpdate' ",&tolua_err);
    return 0;
#endif

}

static int lua_ResUpdateEx_startGame(lua_State *tolua_S)                                                                        
{
    int argc = 0;
    ResUpdateEx* self = nullptr;
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"ResUpdateEx",0,&tolua_err)) goto tolua_lerror;
#endif

    self = (ResUpdateEx*)  tolua_tousertype(tolua_S,1, 0);
#if COCOS2D_DEBUG >= 1
    if (nullptr == self)
    {
        tolua_error(tolua_S,"invalid 'self' in function 'lua_ResUpdateEx_startGame'\n", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;    
    if (0 == argc)
    {
        self->startGame();    
        return 1;
    }
    
    luaL_error(tolua_S, "'lua_ResUpdateEx_startGame() has wrong number of arguments: %d, was expecting %d\n", argc, 0);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_ResUpdateEx_startGame' ",&tolua_err);
    return 0;
#endif

}

extern int register_ResUpdateEx_luabinding(lua_State* tolua_S)
{
    tolua_open(tolua_S); 
    tolua_usertype(tolua_S, "ResUpdateEx");
    tolua_module(tolua_S, NULL,0);
    tolua_beginmodule(tolua_S, NULL);
        tolua_cclass(tolua_S,"ResUpdateEx","ResUpdateEx", "cc.Ref",NULL);
        tolua_beginmodule(tolua_S, "ResUpdateEx"); 
            tolua_function(tolua_S, "create", lua_ResUpdateEx_create);
            tolua_function(tolua_S, "addUpdateHandler", lua_ResUpdateEx_addUpdateHandler);
            tolua_function(tolua_S, "removeUpdateHandler", lua_ResUpdateEx_removeUpdateHandler);
            tolua_function(tolua_S, "downLoadFileAsync", lua_ResUpdateEx_downloadFileAsync); 
            tolua_function(tolua_S, "batchDownloadFileAsync", lua_ResUpdateEx_batchDownloadFileAsync);            
            tolua_function(tolua_S, "decompress", lua_ResUpdateEx_decompress);
            tolua_function(tolua_S, "getFileString", lua_ResUpdateEx_getFileString);  
            tolua_function(tolua_S, "exitUpdate", lua_ResUpdateEx_exitUpdate);
            tolua_function(tolua_S, "startGame", lua_ResUpdateEx_startGame);
        tolua_endmodule(tolua_S);
    tolua_endmodule(tolua_S);
    
   return 1; 
}


