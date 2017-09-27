#include "base/ccConfig.h"
#ifndef __testClass_h__
#define __testClass_h__

#ifdef __cplusplus
extern "C" {
#endif
#include "tolua++.h"
#ifdef __cplusplus
}
#endif

int register_all_testClass(lua_State* tolua_S);




#endif // __testClass_h__
