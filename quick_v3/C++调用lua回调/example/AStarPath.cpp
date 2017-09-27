
#include "AStarPath.h" 
#include "CCLuaEngine.h"


NS_CC_BEGIN



AStarPath::AStarPath()
{
}

AStarPath::~AStarPath()
{
    delete []_MAP_INFO;
    delete []_OPEN_LIST;
}

AStarPath* AStarPath::create(int mapWidth, int mapHeight, int gridSize, bool isDirection8)
{
    CCLOG(" AStarPath::create ");

    auto *node = new AStarPath();
    node->init(mapWidth, mapHeight, gridSize, isDirection8);
    
    return node;
}

void AStarPath::init(int mapWidth, int mapHeight, int gridSize, bool isDirection8)
{
    int len = mapWidth*mapHeight+1;
    
    _mapWidth = mapWidth;
    _mapHeight = mapHeight;
    _gridSize = gridSize;
    _isDirector8 = isDirection8;
    
    _openSize = 0;
    
    _MAP_INFO = new GridInfo[len];    
    _OPEN_LIST = new GridInfo* [len];
    //memset(_MAP_INFO, 0, sizeof(GridInfo)*len);
    memset(_OPEN_LIST, 0, len);

    //init map info.
    GridInfo *tmp;
    for (int h=0;h<mapHeight;h++)
    {
        for (int w=0; w<mapWidth; w++)
        {
            tmp = getGridNodeByPos(w, h);
            tmp->x = w;
            tmp->y = h;
            tmp->F = 0;
            tmp->G = 0;
            tmp->whichList = 0;
            tmp->pParent = nullptr;
        }
    }
    
    _CLOSE_LIST.reserve(len);
}

GridInfo * AStarPath::getGridNodeByPos(int grid_x, int grid_y)
{
    return  dynamic_cast<GridInfo *> (&_MAP_INFO[grid_y*_mapWidth+grid_x]);
}

std::vector<Vec2>* AStarPath::findPath(const Vec2 &from, const Vec2 &to)
{  
    CCLOG(" findPath");
    _targetX = to.x/_gridSize;
    _targetY = to.y/_gridSize;
    
    //check target pos can walkable.
    if (!isWalkable(_targetX, _targetY))
    {
        return nullptr;
    }
    
    // 1. add to open list    
    int grid_x = from.x/_gridSize;
    int grid_y = from.y/_gridSize;
    
    GridInfo *startNode = this->getGridNodeByPos(grid_x, grid_y);
    startNode->G = 0;
    startNode->F = startNode->G + 10*(abs(grid_x - _targetX) + abs(grid_y - _targetY));
    startNode->whichList = IN_OPEN_LIST;
    this->addToOpenList(startNode);

    bool bWalkability;
    bool foundResult = false;
    int addedGCost;

    GridInfo *minNode;
    GridInfo *tmpNode;    
    while (_openSize > 0)
    {
        minNode = this->getMinFromOpen();
        
        // 2. remove it to close list.
        _CLOSE_LIST.push_back(minNode);
        minNode->whichList = IN_CLOSE_LIST;

        // 3.Check the adjacent squares
        for (int Y = minNode->y-1; Y <= minNode->y+1; Y++)
        {
            if (foundResult)
            {
                break;
            }
            
            for (int X = minNode->x-1; X <= minNode->x+1; X++)
            {
                //If not off the map (do this first to avoid array out-of-bounds errors)
                if (X != -1 && Y != -1 && X != _mapWidth && Y != _mapHeight) //(X != 0 && Y != 0)
                {
                    if (!_isDirector8 && (abs(X - minNode->x) == 1 && abs(Y - minNode->y) == 1))
                    {
                        continue; //skip diagonal squares for 4 direction.
                    }
                     
                    tmpNode = this->getGridNodeByPos(X, Y);
                    //not in close list
                    if (tmpNode->whichList != IN_CLOSE_LIST)
                    {
                        //check can walk
                        bWalkability = this->isWalkable(X, Y);
                        if (bWalkability)
                        {
                            if (_isDirector8)
                            {
                                if (X ==minNode->x-1 && Y == minNode->y-1) //left_down
                                {
                                    bWalkability = this->isWalkable(X, Y+1) && this->isWalkable(X-1, Y);
                                }
                                else if (X ==minNode->x-1 && Y == minNode->y+1) //left_up
                                {
                                    bWalkability = this->isWalkable(X, Y-1) && this->isWalkable(X-1, Y);
                                }
                                else if (X ==minNode->x+1 && Y == minNode->y-1) //right_down
                                {
                                    bWalkability = this->isWalkable(X-1, Y) && this->isWalkable(X, Y+1);
                                }
                                else if (X ==minNode->x+1 && Y == minNode->y+1) //right_up
                                {
                                    bWalkability = this->isWalkable(X-1, Y) && this->isWalkable(X, Y-1);
                                }
                            }
                        }     
                    
                        if (bWalkability)
                        {
                            if (_isDirector8 && (abs(X - minNode->x) == 1 && abs(Y - minNode->y) == 1))
                            {
                                addedGCost = 14;//cost of going to diagonal squares	
                            }
                            else	
                            {
                                addedGCost = 10;//cost of going to non-diagonal squares
                            }
                        
                            if (tmpNode->whichList == IN_OPEN_LIST) //in open list
                            {
                                 //if G is less then old path,  point to new parent.
                                if (minNode->G + addedGCost < tmpNode->G)
                                {
                                    tmpNode->G = minNode->G + addedGCost;
                                    tmpNode->F = tmpNode->G + 10*(abs(X - _targetX) + abs(Y - _targetY));
                                    tmpNode->pParent = minNode;
                                }
                            }
                            else 
                            {
                                //add to open list.
                                tmpNode->G = minNode->G + addedGCost;
                                tmpNode->F = tmpNode->G + 10*(abs(X - _targetX) + abs(Y - _targetY));
                                tmpNode->whichList = IN_OPEN_LIST;
                                tmpNode->pParent = minNode; 
                                
                                //find finish.
                                if ((X == _targetX) && (Y == _targetY))
                                {
                                    foundResult = true;
                                    break;
                                }                                
                                this->addToOpenList(tmpNode);            
                            }
                        }     
                    
                    }
                }
            }
        }

    }


    if (!foundResult)
    {
        return nullptr;
    }

    _resultPath.clear();
    tmpNode = this->getGridNodeByPos(_targetX, _targetY);
    do{    
        _resultPath.insert(_resultPath.begin(), Vec2(tmpNode->x*_gridSize, tmpNode->y*_gridSize));
        tmpNode = tmpNode->pParent;
        
    }while (tmpNode != nullptr);
    
    return &_resultPath;
}


/**********************  bi tree sort ********************************/
void AStarPath::addToOpenList(GridInfo *node)
{
    //add to last
    _OPEN_LIST[++_openSize] = node;
    
     int last = _openSize;
    
    //check and make sure parent > child in bi tree.
    while (last > 1)
    {
        int half = last >>1; //parent node index 
        if (_OPEN_LIST[last]->F >= _OPEN_LIST[half]->F)
        {
            break;
        }
        
        //swap if child > parent 
        GridInfo *tmp = _OPEN_LIST[last];
        _OPEN_LIST[last] = _OPEN_LIST[half];
        _OPEN_LIST[half] = tmp;
        
        last >>=1; //upper parent node index
    }
    
}

GridInfo *AStarPath::getMinFromOpen()
{
   
    if (_openSize <= 0)
    {
        return nullptr;
    }
    
    GridInfo * _tmpGrid = _OPEN_LIST[1];
    
   //take the last one to first.
   _OPEN_LIST[1] = _OPEN_LIST[_openSize--];

   //resort open list
    int head = 1;   
    int last = _openSize ;
    while ((head<<1)+1 <= last)
    {
        int lchild = head<<1;
        int rchild = lchild + 1;
        int childmin = _OPEN_LIST[lchild]->F < _OPEN_LIST[rchild]->F ? lchild:rchild;
        if (_OPEN_LIST[head]->F <= _OPEN_LIST[childmin]->F)
        {
            break;
        }

        //swap
        GridInfo *tmp = _OPEN_LIST[head];
        _OPEN_LIST[head] = _OPEN_LIST[childmin];
        _OPEN_LIST[childmin] = tmp; 

        head = childmin;
    }
    
    return _tmpGrid;
}


void AStarPath::resortOpenListForIndex(int index)
{
    int last = index;

    while (last > 1)
    {
        int half = last>>1;
        if (_OPEN_LIST[last]->F >= _OPEN_LIST[half]->F)
        {
            break;
        }

        //swap
        GridInfo *tmp = _OPEN_LIST[last];
        _OPEN_LIST[last] = _OPEN_LIST[half];
        _OPEN_LIST[half] = tmp; 

        last >>=1;//upper parent node index
    }
}

void AStarPath::clear()
{

}

/*++++++++++++++++++++++++ BELOW FOR  CUSTOMIZER ++++++++++++++++++++++++++*/

bool AStarPath::isWalkable(int grid_x, int grid_y)
{
//	If not off the map (do this first to avoid array out-of-bounds errors)
//	if (a != -1 && b != -1 && a != mapWidth && b != mapHeight)

/*
    static int lianliankan_map[8][8] = {
        0, 0,  0,  0,  0,  0,  0,  0,
        0, 1,  3,  5,  7,  9, 11,  0,
        0, 17, 29, 13, 13, 11, 9, 0,
        0, 7, 29,  15, 17, 5,  5, 0,
        0, 1,  3,  3, 13, 11,  9, 0,
        0, 25, 27, 3, 5, 27,  1, 0, 
        0,  0,  0,  0,  0,  0,  0,  0}
        
    if (grid_x >= 0 && grid_x < _mapWidth && grid_y >= 0 && grid_y < _mapHeight)
    {
        //return (lianliankan_map[_mapHeight - grid_y-1][grid_x] > 0); // Y is from down to up
        
        
    }
*/

    int result = 0;
    int handler = ScriptHandlerMgr::getInstance()->getObjectHandler((void*)this, ScriptHandlerMgr::HandlerType::CALLFUNC);
    if (0 != handler)
    {        
        LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
        lua_State* L = stack->getLuaState();
        
        lua_newtable(L);
        result = stack->executeFunctionByHandler(handler, 0);
        stack->clean();
    }


    return false;
}
    
void AStarPath::test()
{
    CCLOG("-- test");
    
    this->findPath(Vec2(0, 0), Vec2(96, 96));

#if 0    
    for (int i=1; i <= 20;i++)
    {
        GridInfo *node = new GridInfo;
        node->F = random(1, 30);
        node->x = random(1, 30);
        node->y = random(1, 30);
        CCLOG("== org F:%d", node->F);
        addToOpenList(node);
    }

    for (int i=1; i<= _openSize;i++)
    {        
        CCLOG("-- F:%d", _OPEN_LIST[i]->F);
    }

    getMinFromOpen();
     for (int i=1; i<= _openSize;i++)
    {        
        CCLOG("get result- F:%d", _OPEN_LIST[i]->F);
    }   

    auto kk = _OPEN_LIST[5];
    kk->F = 1;
    resortOpenListForIndex(5);
     for (int i=1; i<= _openSize;i++)
    {        
        CCLOG("@@@ F:%d", _OPEN_LIST[i]->F);
    }  
#endif 

}



NS_CC_END

