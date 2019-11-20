
#include "MyCrypto.h"
#include "aes.h" 



#define  AES_KEY_SIZE 32

#define HEAD_SIZE sizeof(int) 

using namespace cocos2d;
using namespace std;

static MyCrypto* _pInstance  = nullptr;

static const unsigned char key_mask[8] = {0x7a,0x76,0x79,0x78,0x74,0x7a,0x6a,0x71};
static const unsigned char xcvxcvxcv[8] = {0x77,0x63,0x60,0x7c,0x60,0x67,0x7c,0x26};
static const unsigned char gfhfdgdfg[16] = {0x2b,0x21,0x20,0x2d,0x20,0x2b,0x71,0x7d,0x6a,0x72,0x73,0x7f,0x71,0x78,0x7d,0x6b};

//Ð­¶¨´ó¶Ë
static int convertToBigEndian(int v)
{
	unsigned short var = 0xddff;
	if ((*((unsigned char*)&var)) == 0xff)
	{
		int var = v;
		int len = sizeof(int);
		unsigned char * p = (unsigned char *)&var;
		for (int i = 0, j = len - 1; j > i; j--, i++)
		{
			unsigned char tv = p[j];
			p[j] = p[i];
			p[i] = tv;
		}
		return var;
	}
	return v;
}

static void en_sdfsxcvxcv(const char * password, int passwordLength, unsigned char * in_buffer, int in_length, unsigned char ** out_buffer, int * out_length)
{
	aes_context aes_ctx;
	unsigned char iv[16] = {};
	unsigned char key[32] = {};
	memset(iv, 0, sizeof(iv));
	memset(key, 0, sizeof(key));
	memcpy(key, password, passwordLength);
	aes_setkey_enc(&aes_ctx, key, 256);

	int enc_length = in_length + 16 - in_length % 16;
	unsigned char * tempBuff = new unsigned char[enc_length];
	memcpy(tempBuff, in_buffer, in_length);
	if (enc_length > in_length)
	{
		memset(tempBuff + in_length, 0, enc_length - in_length);
	}

	*out_length = enc_length + HEAD_SIZE;
	*out_buffer = new unsigned char[*out_length];
	int originDataLength = convertToBigEndian((int)in_length);
	memcpy(*out_buffer, &originDataLength, HEAD_SIZE);

	aes_crypt_cbc(&aes_ctx, AES_ENCRYPT, enc_length, iv, tempBuff, (*out_buffer) + HEAD_SIZE);

	delete[] tempBuff;
}

static void de_sdfsxcvxcv(const char * password, int passwordLength, unsigned char * in_buffer, int in_length, unsigned char ** out_buffer, int * out_length)
{
	aes_context aes_ctx;
	unsigned char iv[16] = {};
	unsigned char key[32] = {};
	memset(iv, 0, sizeof(iv)); // iv set to \0
	memset(key, 0, sizeof(key));
	memcpy(key, password, passwordLength);
	aes_setkey_dec(&aes_ctx, key, 256);
	
	int originDataLength = 0;
	memcpy(&originDataLength, in_buffer, HEAD_SIZE);
	*out_length = convertToBigEndian(originDataLength);
	*out_buffer = new unsigned char[in_length - HEAD_SIZE];

	aes_crypt_cbc(&aes_ctx, AES_DECRYPT, in_length - HEAD_SIZE, iv, in_buffer + HEAD_SIZE, *out_buffer);
}

std::string MyCrypto::packString(const std::string & msgBuff)
{
	unsigned char * outBuffer = nullptr;
	int outLength = 0;

	char aes_key_buf[AES_KEY_SIZE] = { 0 };
	for (int i = 0; i < AES_KEY_SIZE; i++)
	{
		if (i < 8) {
			aes_key_buf[i] = ((unsigned char)(key_mask[i])) ^ 18;
		}
		else if (i < 16) {
			aes_key_buf[i] = ((unsigned char)(xcvxcvxcv[i - 8])) ^ 21;
		}
		else {
			aes_key_buf[i] = ((unsigned char)(gfhfdgdfg[i - 16])) ^ 25;
		} 
	}
	
	en_sdfsxcvxcv(aes_key_buf, AES_KEY_SIZE, (unsigned char*)msgBuff.c_str(), (unsigned int)msgBuff.size(), &outBuffer, &outLength);


	if (outBuffer == nullptr || outLength <= 0)
	{
		if (outBuffer) {
			delete[] outBuffer;
		}
		return "";
	}
	
	char *encodedData = nullptr;
	cocos2d::base64Encode(outBuffer, (unsigned int)outLength, &encodedData);

	if (outBuffer) {
		delete[] outBuffer;
	}

	std::string ret(encodedData);
	
	free(encodedData);
	
	return ret; 
}


std::string MyCrypto::unpackString(const std::string & msgBuff)
{
	char aes_key_buf[AES_KEY_SIZE] = { 0 };
	for (int i = 0; i < AES_KEY_SIZE; i++)
	{
		if (i < 8)
			aes_key_buf[i] = ((unsigned char)(key_mask[i])) ^ 18;
		else if (i < 16)
			aes_key_buf[i] = ((unsigned char)(xcvxcvxcv[i - 8])) ^ 21;
		else
			aes_key_buf[i] = ((unsigned char)(gfhfdgdfg[i - 16])) ^ 25;
	}

	std::string ret = "";

	if (msgBuff.size() == 0) {
		return ret;
	}

	unsigned char *decodedData = nullptr;
	int decodedDataLen = cocos2d::base64Decode((unsigned char*)msgBuff.c_str(), (unsigned int)(msgBuff.size()), &decodedData);

	if (decodedDataLen > 0)
	{
		unsigned char * outBuffer = nullptr;
		int outLength = 0;
		de_sdfsxcvxcv(aes_key_buf, AES_KEY_SIZE, decodedData, decodedDataLen, &outBuffer, &outLength);
		
		if (decodedData){
			free(decodedData);
		}

		if (outBuffer == nullptr || outLength <= 0)
		{

			std::string originData(msgBuff.c_str(), msgBuff.size());
			originData.append("\0", 1);
			//CCLOG("decrypt error : %s", originData.c_str());
		}
		else
		{
			ret.append((const char *)outBuffer, (std::string::size_type)outLength);
		}
		
		if (outBuffer) 
		{
			delete[] outBuffer;
		}
	}

	return ret;
}


MyCrypto* MyCrypto::getInstance() 
{
    if (!_pInstance)
    {
        _pInstance = new MyCrypto();
    }
    return _pInstance;
}

