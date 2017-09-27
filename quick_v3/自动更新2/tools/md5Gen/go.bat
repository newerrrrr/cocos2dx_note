set ORIGIN_DIR=%~dp0%~dp0
rmdir /s/q Resource_tmp
rmdir /s/q Resource
cd ../../
EncryptForResources.exe -en
cd tools/md5Gen
python make_manifest.py
cd ../../
EncryptForResources.exe -de
pause