#coding=utf-8

#生成所有文件的MD5信息

#将WinRAR的目录("C:\Program Files\WinRAR\")添加到系统环境变量Path中,否则无法识别 WinRAR 命令.

import os
import os.path
import sys
import hashlib
import json
import shutil
import time


path_root = os.path.abspath("../../").replace("\\", "/")			#工程项目的根目录
path_diff_res = os.path.abspath("Resource/").replace("\\", "/") 	#差分资源包目录


curTimeTag = "@" + time.strftime('%Y%m%d%H%M',time.localtime(time.time())) #当前时间戳


#压缩目录列表(目录下所有子目录)
zip_paths_ext = {"/src/",
				 "/src/data/",
				 "/src/data/data/",
				 "/src/game/",
				 "/src/game/uilayer/",
				 "/res/anime/",
				 "/res/tournament/",
				}
		
#压缩目录转为全路径存储
zip_full_path = {}
for dir in zip_paths_ext:
	for tmp in os.listdir(path_root + dir):
		path = dir + tmp + "/" 	#os.path.join(dir, tmp).replace("\\", "/")
		if not (path in zip_paths_ext):
			zip_full_path[path_diff_res + dir + tmp] = None


#去掉基目录
def removeBaseDir(fullpath):
	return fullpath.replace(path_diff_res + "/", "") 
	
def removeOrgBaseDir(fullpath):
	return fullpath.replace(path_root + "/", "") 

#压缩目录/文件
def zip_files(target_path, source_path, bDeleteAfterZip):
	#注意：rar命令打包的zip在cocos2dx无法解析！！！ 
	#zip_command = "rar a -ep1 -r -ad %s %s" %(target_path, ''.join(source_path))
	zip_command = "WinRAR a -ep1 -r -y {0} {1}".format(target_path, source_path)
	if bDeleteAfterZip:
		#zip_command = "rar a -ep1 -r -ad -dw %s %s" %(target_path, ''.join(source_path)) 
		zip_command = "WinRAR a -ep1 -r -dw -y -ibck {0} {1}".format(target_path, source_path)
	
	assert os.system(zip_command)==0

	
	
	
def GetFileMd5(filepath, assets, childList):
    file = None
    bRet = False
    strMd5 = ""
	
    filepath = os.path.abspath(filepath).replace("\\", "/")
    	
    try:
        file = open(filepath, "rb")
        md5 = hashlib.md5()
        strRead = ""
        while True:
            strRead = file.read(4096)
            if not strRead:
                break
            md5.update(strRead)
            #read file finish
        bRet = True
        strMd5 = md5.hexdigest()
		
        file_info = {}
        file_info["md5"] = strMd5
        file_info["fileSize"] = os.path.getsize(filepath)
        file_info["timeStamp"] = curTimeTag 
			
        if childList != None:
			file_info["childList"] = childList		
        extName = os.path.splitext(filepath)[1]
        if extName == '.zip':
			file_info["compressed"] = True

        file.close()
		
        
        key = removeBaseDir(filepath)
		
#        if True: #添加时间戳
#			extName = os.path.splitext(removeBaseDir(filepath))
#			key = extName[0] + curTimeTag + extName[1] #MD5列表的key加上时间戳
			
#			#获取完MD5后把文件名加上时间戳
#			extName = os.path.splitext(filepath)
#			newPath = extName[0] + curTimeTag + extName[1]
#			os.rename(filepath, newPath)		
        if assets != None:
			if assets.has_key(key):
				return True			
			assets[key] = file_info

		
		
    except:
        bRet = False


    #return [bRet, strMd5]
	
    return bRet
		

		
	
#递归生成每个文件的MD5信息(如果是zip文件则跳过)
def md5_walk_dir(dir, assets):
    print("@@@ md5_walk_dir: " + dir)
	
	#如果是压缩过的目录或者是zip文件,则不处理
    if zip_full_path.has_key(dir) and os.path.exists(dir + ".zip"):
		return 
	
    for filename in os.listdir(dir):
        if filename.startswith('~') or filename.startswith('.'): 	#这里需要忽略隐藏目录和隐藏文件
            continue
        filepath = os.path.join(dir, filename).replace("\\", "/")
        print("### md5_walk_dir: " + filepath)
		
        if zip_full_path.has_key(filepath) and os.path.exists(filepath + ".zip"):
			continue
			
        if os.path.isdir(filepath):
            md5_walk_dir(filepath, assets)
			
        elif os.path.isfile(filepath):
            GetFileMd5(filepath, assets, None)	

			
#压缩指定目录/文件
#fullpath:绝对路径
def md5_walk_zip_dir(fullpath, assets):
    print("@@@ md5_walk_zip_dir: " + fullpath)
	
    if os.path.isdir(fullpath):
		#1)先获取该目录下所有文件的MD5信息
		child_md5_list = {}
		md5_walk_dir(fullpath, child_md5_list)
				
		#2)开始压缩该目录
		target_path = fullpath + ".zip"
		zip_files(target_path, fullpath, True)
		
		#3).对zip包生成MD5, 同时更新其 childList 字段
		GetFileMd5(target_path, assets, child_md5_list)	
		
    elif os.path.isfile(fullpath):
		#不压缩文件
		#GetFileMd5(fullpath, assets, None) 
		
		#压缩文件
		#1)先获取该文件的MD5信息
		child_md5_list = {}
		GetFileMd5(fullpath, child_md5_list, None)	
		
		#2)开始压缩该文件
		target_path = fullpath + ".zip"
		zip_files(target_path, fullpath, True)
		
		#3)对zip文件生成MD5
		GetFileMd5(target_path, assets, child_md5_list)	


	
def load_json_file(filepath):
    file = open(filepath, "rb")
    str = file.read()
    dict = json.loads(str)
    return  dict

def save_manifest(filepath, dict):
    dir_file = os.path.split(filepath)		#获取路径名和文件名
    if not os.path.exists(dir_file[0]):		#如果目录不存在则递归创建
		os.makedirs(dir_file[0])
		
    file = open(filepath, "wb")
    dump_str = json.dumps(dict, sort_keys=True, separators=(',',':'), indent=4)
    file.write(dump_str)
    file.close()	
    print("save file: " + filepath)

	
#shutil.copytree拷贝目录时经常因为权限问题而报错,这里重写下
def my_copy_tree(src,dst):
    _orig_copystat = shutil.copystat
    shutil.copystat = lambda x, y: x
    shutil.copytree(src, dst)
    shutil.copystat = _orig_copystat
	
def init_env():
	#先清空目标目录
    if os.path.exists(path_diff_res):
		print("start remove files...")
		os.system("rm -rf " + path_diff_res)
		#os.system("rm -rf " + path_diff_res + path) #rmtree经常因为权限问题,目录非空问题而提示报错, 所有这里使用windows命令
		#shutil.rmtree(path) 

	#将所有资源拷贝到指定目录,用来制作更新包	
    tmp_path = path_diff_res + "_tmp"
    os.makedirs(tmp_path)	
    my_copy_tree(path_root + "/src", tmp_path + "/src")	
    my_copy_tree(path_root + "/res", tmp_path + "/res")		
    os.rename(tmp_path, path_diff_res)
	
	#清除所有svn信息
    for (p,d,f) in os.walk(path_diff_res):
		if p.find('.svn')>0:
			os.system("rm -rf " + p)


	
#先将需要压缩的目录进行打包成zip	
def zip_compress():
    for dir in zip_paths:
		#获取指定目录的上一级目录, 供压缩后存放zip文件
		cur_dir = os.path.abspath(dir).replace("\\", "/")
		index = cur_dir.rfind("/") 
		pre_dir = cur_dir[:index]	#上一级目录路径
		print(pre_dir)
		
		#source = cur_dir + "/" + zip_paths[dir] #如果只针对该目录下指定类型文件进行压缩,则压缩包的内容列表不显示该目录,而是直接显示目录下的内容.
		source = cur_dir 						 #针对该目录下所有内容进行压缩,压缩后的内容列表自动显示该目录.(注意:目录路径后面不能带目录分隔符号"\")
		target = pre_dir + "/" + cur_dir[index+1:] + ".zip" #保存到上一级目录下
		print(source)
		print(target)
		zip_command = "rar a -ep1 -r -ad %s %s" %(target, ''.join(source))
		assert os.system(zip_command)==0


	
def create_project_manifest():

    version = load_json_file("version.manifest")
    project = {}
    project["serverCfgUrl"] = version["serverCfgUrl"]
    project["version"] = version["version"]
    project["engineVersion"] = version["engineVersion"]		
    project["searchPaths"] = version["searchPaths"]
	
	#为了适应老玩家无法下载最新的自动更新代码,这里暂时多配置一份资源服地址
    project["packageUrl_1"] = version["packageUrl_1"]
    project["packageUrl_2"] = version["packageUrl_2"]

    assets = {}
    project["assets"] = assets

	#1)先处理压缩目录
    for dir in zip_full_path:
		print("->>>>" + dir)
		md5_walk_zip_dir(dir, assets)
	
    #2)处理非压缩目录
    md5_walk_dir(path_diff_res, assets)
	
	#3)文件名统一加上时间戳
    renameFileWithTimeStamp(path_diff_res)
	
    save_manifest(path_root + "/project.manifest", project) #工程目录下放一份供发布apk时内置	
    save_manifest(path_diff_res + "/version.manifest", version) #资源服务器放一份
    save_manifest(path_diff_res + "/project.manifest", project)
	
    zip_files(path_diff_res + "/project.manifest.zip", path_diff_res + "/project.manifest", True)
	
    return  project

	
	
#文件名添加时间戳
def renameFileWithTimeStamp(dir):	
    for filename in os.listdir(dir):
        if filename.startswith('~') or filename.startswith('.'): 	#这里需要忽略隐藏目录和隐藏文件
            continue
        filepath = os.path.join(dir, filename).replace("\\", "/")

        if os.path.isdir(filepath):
            renameFileWithTimeStamp(filepath)
			
        elif os.path.isfile(filepath):
			extName = os.path.splitext(filepath)
			newPath = extName[0] + curTimeTag + extName[1]
			os.rename(filepath, newPath)	            





			

print("start generate md5 list...")
init_env()

time.sleep(3)

#针对该目录下所有文件生成
create_project_manifest()







