

local AssetTest = class("AssetTest")

function AssetTest:ctor()
  AssetTest.super.ctor(self)
end 

function AssetTest:updateRes()
  print("=== AssetTest:updateRes")

  local storagePath = cc.FileUtils:getInstance():getWritablePath() .. "hlb_asset"
  local assetMgr = cc.AssetsManagerEx:create("res/HLB_ASSET/project.manifest",  storagePath)
  assetMgr:retain()

  if not assetMgr:getLocalManifest():isLoaded() then
      print("Fail to update assets, step skipped.")
      return 
  end 


  local function onUpdateEvent(event)
      local eventCode = event:getEventCode()
      if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST then
        print("No local manifest file found, skip assets update.")

      elseif  eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then
        print("has  new version found !!!")
        assetMgr:update()

      elseif  eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
        local assetId = event:getAssetId()
        local percent = event:getPercent()
        local strInfo = ""

        if assetId == cc.AssetsManagerExStatic.VERSION_ID then
            strInfo = string.format("Version file: %d%%", percent)
        elseif assetId == cc.AssetsManagerExStatic.MANIFEST_ID then
            strInfo = string.format("Manifest file: %d%%", percent)
        else
            strInfo = string.format("%d%%", percent)
        end
        print(strInfo)

      elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST or 
        eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST then
        print("Fail to download manifest file, update skipped.")

      elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE or 
             eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
        print("Update finished.")

      elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
        print("error updating....Asset ", event:getAssetId(), ", ", event:getMessage())

      end
  end

  local listener = cc.EventListenerAssetsManagerEx:create(assetMgr, onUpdateEvent)
  cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)

  -- assetMgr:update()  --强制更新
  assetMgr:checkUpdate() --有更新则返回消息 NEW_VERSION_FOUND ，在那里再有用户决定是否更新
end 


return AssetTest 
