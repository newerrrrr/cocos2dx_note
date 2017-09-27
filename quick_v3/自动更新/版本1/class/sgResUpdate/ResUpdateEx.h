

#ifndef ResUpdateEx_H
#define ResUpdateEx_H

#include "cocos2d.h"
#include "AppDelegate.h"
#include "network/CCDownloader.h"

USING_NS_CC;


class ResUpdateEx: public Ref
{
public:
    static ResUpdateEx* create();
    void runUpdate();
    void addUpdateHandler(int luaFunc_error, int luaFunc_progress, int luaFunc_success);
    void removeUpdateHandler();
    void downLoadFileAsync(const std::string& srcUrl, const std::string& storagePath, const std::string& customId);
    std::string getBaseName(const std::string& path) const;
    bool decompress(const std::string &path);
    std::string getFileString(std::string fullPath);
    void startGame();
    void exitUpdate();
    void setDelegate(AppDelegate *delegate);   
    ResUpdateEx();
    ~ResUpdateEx();    
private:

    void onError(const network::Downloader::Error &error);
    void onProgress(double total, double downloaded, const std::string &url, const std::string &customId);
    void onSuccess(const std::string &srcUrl, const std::string &storagePath, const std::string &customId);
    
    std::shared_ptr<network::Downloader> _downloader;
    AppDelegate *_delegate;
    int _luaFunc_error;
    int _luaFunc_progress;
    int _luaFunc_success;
    
};

    
#endif
