


#ifndef __CUSTOM__CLASS

#define __CUSTOM__CLASS

#include "cocos2d.h"
//#include "cocos2d/LuaScriptHandlerMgr.h"

namespace cocos2d {

typedef enum{
    NONE = 0,
    IN_OPEN_LIST,
    IN_CLOSE_LIST
}WhichList;


//all map grid info sored in continus memory for speed up access.
typedef struct tagGridInfo{ 
    int x;
    int y;
    int F;
    int G; 
    //int H;
    int whichList;
    struct tagGridInfo *pParent;
}GridInfo;


class AStarPath : public cocos2d::Ref
{
public:
    AStarPath();
    ~AStarPath();
    
    static AStarPath* create(int mapWidth, int mapHeight, int gridSize, bool isDirection8);
    std::vector<Vec2>* findPath(const Vec2 &from, const Vec2 &to); 

    void test();
    
private:
    GridInfo *_MAP_INFO;
    GridInfo** _OPEN_LIST;
    std::vector<GridInfo *> _CLOSE_LIST;
    std::vector<Vec2> _resultPath;
    int _openSize;
    int _closeSize;
    int _mapWidth;
    int _mapHeight; // 0 :none; 1: open list;  2:close list.
    int _gridSize;
    int _targetX;  //target point (pixes to grid)
    int _targetY;
    bool _isDirector8; // is 4 or 8 dierection
    void init(int mapWidth, int mapHeight, int gridSize, bool isDirection8);
    void clear();
    GridInfo * getGridNodeByPos(int grid_x, int grid_y);

    /*belows for  bi tree heap sort */
    void addToOpenList(GridInfo *node);
    GridInfo *getMinFromOpen();
    void resortOpenListForIndex(int index);
    
    bool isWalkable(int grid_x, int grid_y);
    
};


} //namespace cocos2d

#endif // __CUSTOM__CLASS

