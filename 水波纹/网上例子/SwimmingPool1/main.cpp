/**********************************************************************

  Swimming Pool Simulation

  Sept. 24th, 2002

  This opengl sample was written by Philipp Crocoll
  Contact: 
	philipp.crocoll@web.de
	www.codecolony.de

  Every comment would be appreciated.

  If you want to use parts of any code of mine:
	let me know and
	use it!
***********************************************************************

	Controls: w,a,s,d to move/turn

***********************************************************************/

#include <GL\glut.h>
#include <vector>
#include <math.h>
#include <time.h>

#include "camera.h"

using namespace std;
#define PI 3.14159265359
struct SOscillator
{
	GLfloat x,y,z;
	GLfloat nx,ny,nz;  //normal vector
	GLfloat UpSpeed;
	GLfloat newY;
	bool bIsExciter;
	//only in use, if bIsExciter is true:
	float ExciterAmplitude;  
	float ExciterFrequency;
};

//lighting:
GLfloat LightAmbient[]=		{ 0.2f, 0.6f, 1.0f, 0.5f };
GLfloat LightDiffuse[]=		{ 0.2f, 0.6f, 1.0f, 0.5f };
GLfloat LightPosition[]=	{ 1.0f, 1.0f, -0.5f, 0.0f };


//Constants:
#define NUM_X_OSCILLATORS		150
#define NUM_Z_OSCILLATORS		150
#define NUM_OSCILLATORS			NUM_X_OSCILLATORS*NUM_Z_OSCILLATORS
#define OSCILLATOR_DISTANCE		0.05

#define OSCILLATOR_WEIGHT       0.0002


//Camera object:
CCamera Camera;


//vertex data for the waves:
SOscillator * Oscillators;
int NumOscillators;  //size of the vertex array
vector <GLuint> IndexVect;  //we first put the indices into this vector, then copy them to the array below
GLuint * Indices;
int NumIndices;   //size of the index array

float g_timePassedSinceStart = 0.0f;  //note: this need not be the real time
bool  g_bExcitersInUse = true;

///////////////////////////////////////////////////
//Required for calculating the normals:
GLfloat GetF3dVectorLength( SF3dVector * v)
{
	return (GLfloat)(sqrt(v->x*v->x+v->y*v->y+v->z*v->z));	
}
SF3dVector CrossProduct (SF3dVector * u, SF3dVector * v)
{
	SF3dVector resVector;
	resVector.x = u->y*v->z - u->z*v->y;
	resVector.y = u->z*v->x - u->x*v->z;
	resVector.z = u->x*v->y - u->y*v->x;
	return resVector;
}
SF3dVector Normalize3dVector( SF3dVector v)
{
	SF3dVector res;
	float l = GetF3dVectorLength(&v);
	if (l == 0.0f) return F3dVector(0.0f,0.0f,0.0f);
	res.x = v.x / l;
	res.y = v.y / l;
	res.z = v.z / l;
	return res;
}
SF3dVector operator+ (SF3dVector v, SF3dVector u)
{
	SF3dVector res;
	res.x = v.x+u.x;
	res.y = v.y+u.y;
	res.z = v.z+u.z;
	return res;
}
SF3dVector operator- (SF3dVector v, SF3dVector u)
{
	SF3dVector res;
	res.x = v.x-u.x;
	res.y = v.y-u.y;
	res.z = v.z-u.z;
	return res;
}
///////////////////////////////////////////////////


void CreatePool()
{
	NumOscillators = NUM_OSCILLATORS;
	Oscillators = new SOscillator[NumOscillators];
	IndexVect.clear();  //to be sure it is empty
	for (int xc = 0; xc < NUM_X_OSCILLATORS; xc++) 
		for (int zc = 0; zc < NUM_Z_OSCILLATORS; zc++) 
		{
			Oscillators[xc+zc*NUM_X_OSCILLATORS].x = OSCILLATOR_DISTANCE*float(xc);
			Oscillators[xc+zc*NUM_X_OSCILLATORS].y = 0.0f;
			Oscillators[xc+zc*NUM_X_OSCILLATORS].z = OSCILLATOR_DISTANCE*float(zc);

			Oscillators[xc+zc*NUM_X_OSCILLATORS].nx = 0.0f;
			Oscillators[xc+zc*NUM_X_OSCILLATORS].ny = 1.0f;
			Oscillators[xc+zc*NUM_X_OSCILLATORS].nz = 0.0f;

			Oscillators[xc+zc*NUM_X_OSCILLATORS].UpSpeed = 0;
			Oscillators[xc+zc*NUM_X_OSCILLATORS].bIsExciter = false;

			//create two triangles:
			if ((xc < NUM_X_OSCILLATORS-1) && (zc < NUM_Z_OSCILLATORS-1))
			{
				IndexVect.push_back(xc+zc*NUM_X_OSCILLATORS);
				IndexVect.push_back((xc+1)+zc*NUM_X_OSCILLATORS);
				IndexVect.push_back((xc+1)+(zc+1)*NUM_X_OSCILLATORS);

				IndexVect.push_back(xc+zc*NUM_X_OSCILLATORS);
				IndexVect.push_back((xc+1)+(zc+1)*NUM_X_OSCILLATORS);
				IndexVect.push_back(xc+(zc+1)*NUM_X_OSCILLATORS);
			}

		}

	//copy the indices:
	Indices = new GLuint[IndexVect.size()];  //allocate the required memory
	for (int i = 0; i < IndexVect.size(); i++)
	{
		Indices[i] = IndexVect[i];
	}

	Oscillators[100+30*NUM_X_OSCILLATORS].bIsExciter = true;
	Oscillators[100+30*NUM_X_OSCILLATORS].ExciterAmplitude = 0.5f;
	Oscillators[100+30*NUM_X_OSCILLATORS].ExciterFrequency = 50.0f;
	Oscillators[30+80*NUM_X_OSCILLATORS].bIsExciter = true;
	Oscillators[30+80*NUM_X_OSCILLATORS].ExciterAmplitude = 0.5f;
	Oscillators[30+80*NUM_X_OSCILLATORS].ExciterFrequency = 50.0f;
	NumIndices = IndexVect.size();
	IndexVect.clear();  //no longer needed, takes only memory
}


void UpdateScene(bool bEndIsFree, float deltaTime, float time)
{
//********
// Here we do the physical calculations: 
// The oscillators are moved according to their neighbors.
// The parameter bEndIsFree indicates, whether the oscillators in the edges can move or not.
// The new position may be assigned not before all calculations are done!

// PLEASE NOTE: THESE ARE APPROXIMATIONS AND I KNOW THIS! (but is looks good, doesn't it?)

	//if we use two loops, it is a bit easier to understand what I do here.
	for (int xc = 0; xc < NUM_X_OSCILLATORS; xc++) 
	{
		for (int zc = 0; zc < NUM_Z_OSCILLATORS; zc++) 
		{
			int ArrayPos = xc+zc*NUM_X_OSCILLATORS;

			//check, if oscillator is an exciter (these are not affected by other oscillators)
			if ((Oscillators[ArrayPos].bIsExciter) && g_bExcitersInUse)
			{
				Oscillators[ArrayPos].newY = Oscillators[ArrayPos].ExciterAmplitude*sin(time*Oscillators[ArrayPos].ExciterFrequency);
			}


			//check, if this oscillator is on an edge (=>end)
			if ((xc==0) || (xc==NUM_X_OSCILLATORS-1) || (zc==0) || (zc==NUM_Z_OSCILLATORS-1))
				;//TBD: calculating oscillators at the edge (if the end is free)
			else
			{
			  //calculate the new speed:
				

				//Change the speed (=accelerate) according to the oscillator's 4 direct neighbors:
				float AvgDifference = Oscillators[ArrayPos-1].y				//left neighbor
									 +Oscillators[ArrayPos+1].y				//right neighbor
									 +Oscillators[ArrayPos-NUM_X_OSCILLATORS].y  //upper neighbor
									 +Oscillators[ArrayPos+NUM_X_OSCILLATORS].y  //lower neighbor
									 -4*Oscillators[ArrayPos].y;				//subtract the pos of the current osc. 4 times	
				Oscillators[ArrayPos].UpSpeed += AvgDifference*deltaTime/OSCILLATOR_WEIGHT;

			  //calculate the new position, but do not yet store it in "y" (this would affect the calculation of the other osc.s)
				Oscillators[ArrayPos].newY += Oscillators[ArrayPos].UpSpeed*deltaTime;
			  
				
				
			}
		}		
	}

	//copy the new position to y:
	for (int xc = 0; xc < NUM_X_OSCILLATORS; xc++) 
	{
		for (int zc = 0; zc < NUM_Z_OSCILLATORS; zc++) 
		{
			Oscillators[xc+zc*NUM_X_OSCILLATORS].y =Oscillators[xc+zc*NUM_X_OSCILLATORS].newY;
		}
	}
	//calculate new normal vectors (according to the oscillator's neighbors):
	for (int xc = 0; xc < NUM_X_OSCILLATORS; xc++) 
	{
		for (int zc = 0; zc < NUM_Z_OSCILLATORS; zc++) 
		{
			///
			//Calculating the normal:
			//Take the direction vectors 1.) from the left to the right neighbor 
			// and 2.) from the upper to the lower neighbor.
			//The vector orthogonal to these 

			SF3dVector u,v,p1,p2;	//u and v are direction vectors. p1 / p2: temporary used (storing the points)

			if (xc > 0) p1 = F3dVector(Oscillators[xc-1+zc*NUM_X_OSCILLATORS].x,
									   Oscillators[xc-1+zc*NUM_X_OSCILLATORS].y,
									   Oscillators[xc-1+zc*NUM_X_OSCILLATORS].z);
			else
						p1 = F3dVector(Oscillators[xc+zc*NUM_X_OSCILLATORS].x,
									   Oscillators[xc+zc*NUM_X_OSCILLATORS].y,
									   Oscillators[xc+zc*NUM_X_OSCILLATORS].z);	
			if (xc < NUM_X_OSCILLATORS-1) 
						p2 = F3dVector(Oscillators[xc+1+zc*NUM_X_OSCILLATORS].x,
									   Oscillators[xc+1+zc*NUM_X_OSCILLATORS].y,
									   Oscillators[xc+1+zc*NUM_X_OSCILLATORS].z);
			else
						p2 = F3dVector(Oscillators[xc+zc*NUM_X_OSCILLATORS].x,
									   Oscillators[xc+zc*NUM_X_OSCILLATORS].y,
									   Oscillators[xc+zc*NUM_X_OSCILLATORS].z);	
			u = p2-p1; //vector from the left neighbor to the right neighbor
			if (zc > 0) p1 = F3dVector(Oscillators[xc+(zc-1)*NUM_X_OSCILLATORS].x,
									   Oscillators[xc+(zc-1)*NUM_X_OSCILLATORS].y,
									   Oscillators[xc+(zc-1)*NUM_X_OSCILLATORS].z);
			else
						p1 = F3dVector(Oscillators[xc+zc*NUM_X_OSCILLATORS].x,
									   Oscillators[xc+zc*NUM_X_OSCILLATORS].y,
									   Oscillators[xc+zc*NUM_X_OSCILLATORS].z);	
			if (zc < NUM_Z_OSCILLATORS-1) 
						p2 = F3dVector(Oscillators[xc+(zc+1)*NUM_X_OSCILLATORS].x,
									   Oscillators[xc+(zc+1)*NUM_X_OSCILLATORS].y,
									   Oscillators[xc+(zc+1)*NUM_X_OSCILLATORS].z);
			else
						p2 = F3dVector(Oscillators[xc+zc*NUM_X_OSCILLATORS].x,
									   Oscillators[xc+zc*NUM_X_OSCILLATORS].y,
									   Oscillators[xc+zc*NUM_X_OSCILLATORS].z);	
			v = p2-p1; //vector from the upper neighbor to the lower neighbor
			//calculat the normal:
			SF3dVector normal = Normalize3dVector(CrossProduct(&u,&v));

			//assign the normal:
			Oscillators[xc+zc*NUM_X_OSCILLATORS].nx = normal.x;
			Oscillators[xc+zc*NUM_X_OSCILLATORS].ny = normal.y;
			Oscillators[xc+zc*NUM_X_OSCILLATORS].nz = normal.z;
		}
	}

}


void KeyDown(unsigned char key, int x, int y)
{	
	switch(key)
	{
	case 27:	//ESC
		exit(0);
		break;
	case 'a':		
		Camera.RotateY(5.0f);
		break;
	case 'd':		
		Camera.RotateY(-5.0f);
		break;
	case 'w':		
		Camera.MoveForwards( -0.3f ) ;
		break;
	case 's':		
		Camera.MoveForwards( 0.3f ) ;
		break;
	case 'x':		
		Camera.RotateX(5.0f);
		break;
	case 'y':		
		Camera.RotateX(-5.0f);
		break;
	case 'c':		
		Camera.StrafeRight(-0.3f);
		break;
	case 'v':		
		Camera.StrafeRight(0.3f);
		break;
	case 'f':
		Camera.Move(F3dVector(0.0,-0.3,0.0));
		break;
	case 'r':
		Camera.Move(F3dVector(0.0,0.3,0.0));
		break;
	}
}


void DrawScene(void)
{
	glDrawElements(	GL_TRIANGLES, //mode
						NumIndices,  //count, ie. how many indices
						GL_UNSIGNED_INT, //type of the index array
						Indices);;

}

void Display(void)
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();
    
	glLightfv(GL_LIGHT0,GL_POSITION,LightPosition);
	//Turn two sided lighting on:
	glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE);

	Camera.Render();	

	DrawScene();
	glFlush();			//Finish rendering
	glutSwapBuffers();
}

void Reshape(int x, int y)
{
	if (y == 0 || x == 0) return;  //Nothing is visible then, so return
	//Set a new projection matrix
	glMatrixMode(GL_PROJECTION);  
	glLoadIdentity();
	//Angle of view:40 degrees
	//Near clipping plane distance: 0.5
	//Far clipping plane distance: 20.0
	gluPerspective(40.0,(GLdouble)x/(GLdouble)y,0.5,20.0);
	glViewport(0,0,x,y);  //Use the whole window for rendering
	glMatrixMode(GL_MODELVIEW);
	
}

void Idle(void)
{
	float dtime = 0.004f;  //if you want to be exact, you would have to replace this by the real time passed since the last frame (and probably divide it by a certain number)
	g_timePassedSinceStart += dtime;

	if (g_timePassedSinceStart > 1.7f)
	{
		g_bExcitersInUse = false;  //stop the exciters
	}
/*  //ENABLE THE FOLLOWING LINES FOR A RAIN EFFECT
	int randomNumber = rand();
	if (randomNumber < NUM_OSCILLATORS)
	{
		Oscillators[randomNumber].y = -0.05;
	}
	*/


	UpdateScene(false,dtime,g_timePassedSinceStart);
	Display();
}

int main (int argc, char **argv)
{
	//Initialize GLUT
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH );
	glutInitWindowSize(600,600);
	//Create a window with rendering context and everything else we need
	glutCreateWindow("SwimmingPool");
	//compute the vertices and indices
	CreatePool();
	//initialize camera: 
	Camera.Move(F3dVector(NUM_X_OSCILLATORS*OSCILLATOR_DISTANCE / 2.0,2.5,NUM_X_OSCILLATORS*OSCILLATOR_DISTANCE+1.0));
	Camera.RotateX(-20);

	//Enable the vertex array functionality:
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glVertexPointer(	3,   //3 components per vertex (x,y,z)
						GL_FLOAT,
						sizeof(SOscillator),
						Oscillators);
	glNormalPointer(	GL_FLOAT,
						sizeof(SOscillator),
						&Oscillators[0].nx);  //Pointer to the first color*/
	glPointSize(2.0);
	glClearColor(0.0,0.0,0.0,0.0);
	
	//Switch on solid rendering:
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	glEnable(GL_DEPTH_TEST);

	//Initialize lighting:
	glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);		
	glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);		
	glLightfv(GL_LIGHT1, GL_POSITION,LightPosition);
	glEnable(GL_LIGHT1);								

	glEnable(GL_LIGHTING);

	glFrontFace(GL_CCW);   //Tell OGL which orientation shall be the front face
	glShadeModel(GL_SMOOTH);

	//initialize generation of random numbers:
	srand((unsigned)time(NULL));

	
	//Assign the two used Msg-routines
	glutDisplayFunc(Display);
	glutReshapeFunc(Reshape);
	glutKeyboardFunc(KeyDown);
	glutIdleFunc(Idle);
	//Let GLUT get the msgs
	glutMainLoop();
	return 0;
}
