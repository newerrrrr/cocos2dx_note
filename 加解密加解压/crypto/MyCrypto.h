
#include "cocos2d.h"
#include <string>

class MyCrypto {
public:
	static MyCrypto* getInstance();
	std::string packString(const std::string & msgBuff);
	std::string unpackString(const std::string & msgBuff);
};


