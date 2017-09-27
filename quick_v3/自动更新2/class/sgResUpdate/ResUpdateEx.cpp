
#include "ResUpdateEx.h"
#include "CCLuaEngine.h"


#define BUFFER_SIZE    8192
#define MAX_FILENAME   512

ResUpdateEx::ResUpdateEx():_luaFunc_error(0), _luaFunc_progress(0),_luaFunc_success(0)
{
    _downloader = std::shared_ptr<network::Downloader>(new network::Downloader);
    _downloader->setConnectionTimeout(8);
    _downloader->setErrorCallback(std::bind(&ResUpdateEx::onError, this, std::placeholders::_1));
    _downloader->setProgressCallback(std::bind(&ResUpdateEx::onProgress,
                                         this,
                                         std::placeholders::_1,
                                         std::placeholders::_2,
                                         std::placeholders::_3,
                                         std::placeholders::_4)
                                     );
    _downloader->setSuccessCallback(std::bind(&ResUpdateEx::onSuccess, this, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3));

}

ResUpdateEx::~ResUpdateEx()
{
    _downloader->setErrorCallback(nullptr);
    _downloader->setSuccessCallback(nullptr);
    _downloader->setProgressCallback(nullptr); 
    removeUpdateHandler();
}


ResUpdateEx* ResUpdateEx::create()
{
    ResUpdateEx* ret = new (std::nothrow) ResUpdateEx();

    if (ret)
    {
        ret->autorelease();
    }
    else
    {
        CC_SAFE_DELETE(ret);
    }

    return  ret;
}


void ResUpdateEx::addUpdateHandler(int luaFunc_error, int luaFunc_progress, int luaFunc_success)
{
    removeUpdateHandler();
    
    _luaFunc_error = luaFunc_error;
    _luaFunc_progress = luaFunc_progress;
    _luaFunc_success = luaFunc_success;
    
    ScriptHandlerMgr::getInstance()->addCustomHandler((void*)this, _luaFunc_error);
    ScriptHandlerMgr::getInstance()->addCustomHandler((void*)this, _luaFunc_progress);
    ScriptHandlerMgr::getInstance()->addCustomHandler((void*)this, _luaFunc_success);
}

void ResUpdateEx::removeUpdateHandler()
{
    if (_luaFunc_error > 0) 
    {
        LuaEngine::getInstance()->removeScriptHandler(_luaFunc_error);
    }
    
    if (_luaFunc_progress > 0 )
    {
        LuaEngine::getInstance()->removeScriptHandler(_luaFunc_progress);
    }
    
    if (_luaFunc_success)
    {
        LuaEngine::getInstance()->removeScriptHandler(_luaFunc_success);
    }
    _luaFunc_error = 0;
    _luaFunc_progress = 0;
    _luaFunc_success = 0;
}


void ResUpdateEx::downloadFileAsync(const std::string& srcUrl, const std::string& storagePath, const std::string& customId)
{
    _downloader->downloadAsync(srcUrl, storagePath, customId); 
}

void ResUpdateEx::batchDownloadFileAsync(const std::vector<FileUnit>&infos, const std::string&batchId)
{
    _downloadUnits.clear();
    
    for (const auto& iter : infos)
    {
        network::DownloadUnit unit;
        
        unit.srcUrl = iter.srcUrl;
        unit.storagePath = iter.storagePath;
        unit.customId = iter.fileName;
        unit.resumeDownload = false;
        
        _downloadUnits.emplace(unit.customId, unit);
    }
    
    _downloader->batchDownloadAsync(_downloadUnits, batchId);
}

std::string ResUpdateEx::getBaseName(const std::string& path) const
{
    size_t found = path.find_last_of("/\\");
    
    if (std::string::npos != found)
    {
        return path.substr(0, found);
    }
    else
    {
        return path;
    }
}


bool ResUpdateEx::decompress(const std::string &path)
{
    std::string fullpath = FileUtils::getInstance()->fullPathForFilename(path);
    size_t pos = fullpath.find_last_of("/\\");
    if (pos == std::string::npos)
    {
        CCLOG("decompress : no root path specified for zip file %s\n", path.c_str());
        return false;
    }
    const std::string rootPath = fullpath.substr(0, pos+1);

    do {
        ssize_t size = 0;
        unsigned char *zipFileData = FileUtils::getInstance()->getFileData(fullpath.c_str(), "rb", &size);
        if (!zipFileData){
            return false;
        }
        ZipFile *zip = ZipFile::createWithBuffer(zipFileData, size);
        if (zip)
        {
            std::string filename = zip->getFirstFilename();
            while (filename.length()) 
            {
                // Check if this entry is a directory or a file.
                if (filename[filename.size()-1] == '/')
                {
                    if ( !FileUtils::getInstance()->createDirectory(getBaseName(rootPath+filename)) )
                    {
                        // Failed to create directory
                        CCLOG("decompress : can not create directory %s\n", filename.c_str());                        
                        delete zip;     
                        free(zipFileData);
                        return false;
                    }
                }
                else
                {
                    //is file             
                    ssize_t bufferSize = 0;
                    unsigned char *zbuffer = zip->getFileData(filename.c_str(), &bufferSize);
                    if (bufferSize) 
                    { 
                        // Create a file to store current file.
                        do{
                            FILE *fp = fopen(FileUtils::getInstance()->getSuitableFOpen(rootPath + filename).c_str(), "wb+");
                            if (fp){
                                fwrite(zbuffer, bufferSize, 1, fp);
                                fclose(fp);
                            }
                            else{
                                free(zbuffer);
                                delete zip;     
                                free(zipFileData);                               
                                return false;
                            }
                        } while (0);                

                    
                        free(zbuffer);
                    }
                }
                
                filename = zip->getNextFilename();
            }

            delete zip; 
        }
        else 
        {
            CCLOG("decompress: - not found or invalid zip file: %s", path.c_str());
            return false;
        }
        
        free(zipFileData);
       
    }while(0);

    return true;
}


std::string ResUpdateEx::getFileString(std::string fullPath)
{
    if (fullPath.empty())
    {
        return "";
    }

    Data ret;
    unsigned char* buffer = nullptr;
    size_t size = 0;
    size_t readsize;
    
    auto fileutils = FileUtils::getInstance();
    do
    {
        FILE *fp = fopen(fileutils->getSuitableFOpen(fullPath).c_str(), "rt");
        CC_BREAK_IF(!fp);
        fseek(fp,0,SEEK_END);
        size = ftell(fp);
        fseek(fp,0,SEEK_SET);

        buffer = (unsigned char*)malloc(sizeof(unsigned char) * (size + 1));
        buffer[size] = '\0';

        readsize = fread(buffer, sizeof(unsigned char), size, fp);
        fclose(fp);

        if (readsize < size)
        {
            buffer[readsize] = '\0';
        }
    } while (0);

    if (nullptr == buffer || 0 == readsize)
    {
        CCLOG("Get data from file %s failed", fullPath.c_str());
    }
    else
    {
        ret.fastSet(buffer, readsize);
    }

    std::string str((const char*)ret.getBytes());
    return str;
}

void ResUpdateEx::startGame()
{
    Director::getInstance()->getScheduler()->schedule([&](float){
        _delegate->startGame();
    },
    this, 0.0f, 0, 0.8f, false, "ResUpdateEx");
}

void ResUpdateEx::exitUpdate()
{
    if (_delegate)
    {
        _delegate->exitGame();
    }
}

void ResUpdateEx::setDelegate(AppDelegate *delegate) 
{
    _delegate = delegate;
}


void ResUpdateEx::onError(const network::Downloader::Error &error)
{
     //CCLOG(" ResUpdateEx::onError ");
    
    auto pStack = LuaEngine::getInstance()->getLuaStack();
    pStack->pushString(error.customId.c_str(), error.customId.size());
    pStack->executeFunctionByHandler(_luaFunc_error, 1);
    pStack->clean();
    /*
    LuaEngine::getInstance()->removeScriptHandler(_luaFunc_error);
    LuaEngine::getInstance()->removeScriptHandler(_luaFunc_progress);
    LuaEngine::getInstance()->removeScriptHandler(_luaFunc_success); 
    */
}

void ResUpdateEx::onProgress(double total, double downloaded, const std::string &url, const std::string &customId)
{
    //CCLOG(" ResUpdateEx::onProgress ");

    auto pStack = LuaEngine::getInstance()->getLuaStack();
    lua_State* L = pStack->getLuaState();
    lua_pushnumber(L, total);
    lua_pushnumber(L, downloaded);
    pStack->pushString(customId.c_str(), customId.size());
    
    pStack->executeFunctionByHandler(_luaFunc_progress, 3);
    pStack->clean();

    //LuaEngine::getInstance()->removeScriptHandler(_luaFunc_error);
    //LuaEngine::getInstance()->removeScriptHandler(_luaFunc_progress);
    //LuaEngine::getInstance()->removeScriptHandler(_luaFunc_success);
}

void ResUpdateEx::onSuccess(const std::string &srcUrl, const std::string &storagePath, const std::string &customId)
{
    //CCLOG(" ResUpdateEx::onSuccess ");
    
    auto pStack = LuaEngine::getInstance()->getLuaStack();
    pStack->pushString(customId.c_str(), customId.size());
    pStack->executeFunctionByHandler(_luaFunc_success, 1);
    pStack->clean();
    /*
    LuaEngine::getInstance()->removeScriptHandler(_luaFunc_error);
    LuaEngine::getInstance()->removeScriptHandler(_luaFunc_progress);
    LuaEngine::getInstance()->removeScriptHandler(_luaFunc_success);
    */
}

