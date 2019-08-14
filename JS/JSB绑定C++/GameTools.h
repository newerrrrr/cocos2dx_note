
#include "platform/CCFileUtils.h"
#include <string>
#include <unordered_map>
#include <vector>

class GameTools {
public:
	static GameTools* getInstance();

	bool decompress(const std::string &zip);
	
protected:
    std::string basename(const std::string& path) const;
};



//--------------------------------------------below  for js binding -------------------------------------------------//

//SE_DECLARE_FUNC(js_GameTools_getInstance);
//SE_DECLARE_FUNC(js_GameTools_decompress);
//SE_DECLARE_FUNC(js_GameTools_finalize);
#include "cocos/scripting/js-bindings/jswrapper/SeApi.h"
#include "scripting/js-bindings/manual/jsb_conversions.hpp"
#include "scripting/js-bindings/manual/jsb_global.h"
bool js_register_GameTools(se::Object* obj);
