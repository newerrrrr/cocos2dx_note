

local language = "zhtw"
if cc.FileUtils:getInstance():isFileExist("src/localization/langConfig.lua") then 
    local langConfig = require("src.localization.langConfig") 
    local languagelist = langConfig.getLanguageList()
    local countryKey = langConfig.getCountryCode()
    language = languagelist[countryKey] or "zhcn"
end 

local lang 
if language == "zhcn" then 
  lang = {
    ["newVesion"] = "检测到新版本，需要更新 %s 资源，是否更新？",
    ["newMajorVesion"] = "发现最新安装包，请退出游戏重新下载安装！",
    ["networkError"] = "网络连接失败，是否再次尝试连接？",
    ["noLocalManifest"] = "安装包缺少资源列表，请重新安装。",  
    ["decompressFail"] = "解压缩失败，是否重新更新资源？",  
    ["updateFail"] = "更新失败,请重新尝试或者下载最新安装包。",
    ["fileRenameFail"] = "文件重命名失败，是否再次尝试下载？",
    ["fileSizeWrong"] = "文件下载失败，请更换网络重试",
    ["resUpdateTitle"] = "更新说明",
    ["updating"] = "更新中...",
    ["decompresing"] = "解压中...",
    ["runningGame"] = "启动游戏...",
    ["msgBox_ok"] = "确认",
    ["msgBox_cancle"] = "取消",  
  }
  
elseif language == "zhtw" then 
  lang = {
    ["newVesion"] = "檢測到新版本，需要更新 %s 資源，是否更新？",
    ["newMajorVesion"] = "發現最新安裝包，請退出遊戲重新下載安裝！",
    ["networkError"] = "網絡連接失敗，是否再次嘗試連接？",
    ["noLocalManifest"] = "安裝包缺少資源列表，請重新安裝。",  
    ["decompressFail"] = "解壓縮失敗，是否重新更新資源？",  
    ["updateFail"] = "更新失敗,請重新嘗試或者下載最新安裝包。",
    ["fileRenameFail"] = "文檔重命名失敗，是否再次嘗試下載？",
    ["fileSizeWrong"] = "文檔下載失敗，請更換網路重試",
    ["resUpdateTitle"] = "更新說明",
    ["updating"] = "更新中...",
    ["decompresing"] = "解壓中...",
    ["runningGame"] = "啟動遊戲...",
    ["msgBox_ok"] = "確認",
    ["msgBox_cancle"] = "取消",  
  }
end 



return lang 
