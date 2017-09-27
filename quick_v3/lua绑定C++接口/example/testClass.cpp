
 
#include "testClass.h"


NS_CC_BEGIN

testClass::testClass()
{
}

testClass::~testClass()
{
}

testClass* testClass::create()
{
    CCLOG(" testClass::create ");

    testClass *node = new testClass();
    return node;
}


void testClass::ignorFunction()
{
    CCLOG(" ignorFunction");
}


NS_CC_END

