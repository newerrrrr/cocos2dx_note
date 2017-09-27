#include "textures.h"
void COGLTexture::LoadFromFile(char *filename)
{
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glGenTextures(1,&ID); 
	glBindTexture( GL_TEXTURE_2D, ID);
	Image = auxDIBImageLoadA( (const char*) filename );
	Width = Image->sizeX;
	Height = Image->sizeY;
	gluBuild2DMipmaps(	GL_TEXTURE_2D, 
						3, 
						Image->sizeX,
						Image->sizeY,
						GL_RGB,
						GL_UNSIGNED_BYTE,
						Image->data);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);


	delete Image;
}

void COGLTexture::SetActive()
{
	glBindTexture( GL_TEXTURE_2D, ID);
}

unsigned int COGLTexture::GetID()
{
	return ID;
}

