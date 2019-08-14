#coding=utf-8
import os  
import hashlib  
import time  
import shutil
import subprocess

def getFileMd5(filename):  
    if not os.path.isfile(filename):  
        return  
    myhash = hashlib.md5()
    f = file(filename,'rb')  
    while True:  
        b = f.read(8096)
        if not b :  
            break  
        myhash.update(b)
    f.close()  
    return myhash.hexdigest()  

def walk(path):
    xml = ""
    for parent,dirnames,filenames in os.walk(path):
        for filename in filenames:
            pathfile = os.path.join(parent, filename)
            md5 = getFileMd5(pathfile)
            name = pathfile[len(path)+1:]
            name = name.replace('\\', '/')
            if xml == "":
                xml = "\n\t\t\"%s\" : {\n\t\t\t\"md5\" : \"%s\"\n\t\t}" % (name, md5)
            else:
                xml += ",\n\t\t\"%s\" : {\n\t\t\t\"md5\" : \"%s\"\n\t\t}" % (name, md5)
    return xml


def main():
    #修改版本号
    version = "1.0.0.1"
    hot_url = "http://192.168.3.253:8080/" 
    app_download_url = "http://abc.9happytech.com/startgame.html" 

    #创建目录hotupdate, 其包含两个manifest文件和版本目录, 该版本目录存放当前热更资源
    root_path = os.getcwd()
    hot_path = os.path.join(root_path, 'hotupdate') 
    if os.path.exists(hot_path):
        shutil.rmtree(hot_path)
    os.mkdir(hot_path)

    #创建版本目录
    ver_path = os.path.join(hot_path, 'v'+version) 
    os.mkdir(ver_path)

    #拷贝资源
    shutil.copytree(os.path.join(root_path, 'build/jsb-default/res'), os.path.join(ver_path, 'res'))
    shutil.copytree(os.path.join(root_path, 'build/jsb-default/src'), os.path.join(ver_path, 'src'))

    #save to file: project.manifest
    assets = walk(ver_path)

    xml = '{'\
    + '\n\t"version" : "' + version + '",'\
    + '\n\t"packageUrl" : "' + hot_url + 'v'+ version + '/'+ '",'\
    + '\n'\
    + '\n\t"assets" : {'\
    + assets\
    + '\n\t},'\
    + '\n\t"searchPaths" : ['\
    + '\n\t]'\
    + '\n}'
    
    f = file(os.path.join(ver_path, 'project.manifest'), 'w+')
    f.write(xml)
    f.close()
    print 'generate project.manifest finish.'

    #save to file: version.manifest
    xml = '{'\
    + '\n\t"version" : "' + version + '",'\
    + '\n\t"manifestUrl" : "' + hot_url + '",'\
    + '\n\t"appDownLoadUrl" : "' + app_download_url + '"'\
    + '\n}'
    f = file(os.path.join(ver_path, 'version.manifest'), 'w+')
    f.write(xml)
    f.close()
    print 'generate version.manifest finish.'

    # manefest文件拷贝一份放到外面
    shutil.copyfile(os.path.join(ver_path, 'project.manifest'), os.path.join(hot_path, 'project.manifest')) 
    shutil.copyfile(os.path.join(ver_path, 'version.manifest'), os.path.join(hot_path, 'version.manifest')) 


if __name__ == "__main__":
    main()
