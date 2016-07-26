#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h> // for kVK_* names
#import <OpenGL/OpenGL.h>
#import "Angel.h"

#define SURFACE_DATA_CAPACITY 1000000
#define CONTROL_DATA_CAPACITY 1000000
#define NI 10
#define NJ 10
#define RESOLUTIONI 10 * NI
#define RESOLUTIONJ 10 * NJ
typedef Angel::vec4 point4;
typedef Angel::vec4 color4;

enum SHADING{
    NONE, PHONG, GOURAUD
};
enum MAPPING{
    COLOR, BUMP, TEXTURE
};

@class ViewController;

@interface MyOpenGLView : NSOpenGLView{
@private
    NSTimer *timer;// timer to update the view content
    point4 cpoints[CONTROL_DATA_CAPACITY];
    point4 points[SURFACE_DATA_CAPACITY];
    vec3 cnormals[CONTROL_DATA_CAPACITY];
    vec3 normals[SURFACE_DATA_CAPACITY];
    NSRect bounds;// current view bounds
    mat4 model_view;
    GLuint ModelView, Projection, Transform, vColor, program, vShading, vMap, myTextureName, vMapping, vao;
    vec4 inp[NI+1][NJ+1];
    vec4 outp[RESOLUTIONI][RESOLUTIONJ];
    int SURFACE_DATA_SIZE;
    int CONTROL_DATA_SIZE;
    BOOL keysDown[128];
    ViewController *controller;
    float lastX,lastY;
}

@property (assign) GLuint main_window;
@property (assign) int WIDTH, HEIGHT ;

@property GLfloat zFar, zNear, zoom;

@property NSColor *color;

@property bool UPDATE_NEEDED;
@property bool SHOW_CONTROL_POINTS;
@property bool SHOW_WIREFRAME;
@property bool EDIT_MODE;

@property SHADING shading;
@property MAPPING mapping;



@property float xpos, ypos, zpos, xrot, yrot, zrot;
@property float lastx, lasty;

- (void) sendDataToShaders;
- (void) initExample;
- (void) initUpdateTimer;
- (void) initOpenGL;
- (void) camera;
- (void) setViewController:(ViewController*)theController;
- (void) setMapFile:(NSURL*)url;
@end