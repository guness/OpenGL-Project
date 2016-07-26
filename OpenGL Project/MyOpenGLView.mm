#import "MyOpenGLView.h"
#import "ViewController.h"

/* Setting FPS */
static const NSTimeInterval kScheduledTimerInSeconds = 1.0f / 120.0f;

@implementation MyOpenGLView

/* This is used like constructor. OSX calls this method for initialization of
 * MyOpenGLView  */
- (id)initWithCoder:(id)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.WIDTH  = 640;
        self.HEIGHT = 480;

        SURFACE_DATA_SIZE = 0;
        CONTROL_DATA_SIZE = 0;

        self.UPDATE_NEEDED       = TRUE;
        self.SHOW_CONTROL_POINTS = TRUE;
        self.SHOW_WIREFRAME      = TRUE;
        self.shading             = GOURAUD;
        self.EDIT_MODE           = FALSE;
        self.mapping             = COLOR;

        model_view = mat4();
        vMap       = -1;

        self.zNear = -150;
        self.zFar  = 150;
        self.zoom  = 60.0;
        self.xpos  = 5;
        self.ypos  = 10;
        self.zpos  = 15;
        self.xrot  = 45;
        self.yrot  = 0;
        self.zrot  = 0;
        lastX      = 0;
        lastY      = 0;
        self.color =
            [NSColor colorWithCalibratedRed:0.3f green:0.6f blue:1.0f alpha:0.6f];
    }
    return self;
}

/* OSX calls this method just before activation OpenGLView */
- (void)prepareOpenGL {
    [super prepareOpenGL];
    [self initExample];
    [self initOpenGL];
    [self initUpdateTimer];
}

/* This is where we are preparing our OpenGL variables  */
- (void)initOpenGL {
    /* Generating texture variables. */
    glGenTextures(1, &myTextureName);
    glBindTexture(GL_TEXTURE_2D, myTextureName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    vMap = glGetUniformLocation(program, "vMap");

    // Create a vertex array object
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    // Create and initialize a buffer object
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cpoints) + sizeof(points) + sizeof(cnormals) + sizeof(normals), NULL, GL_STATIC_DRAW);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(cpoints), cpoints);
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(cpoints), sizeof(points), points);
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(cpoints) + sizeof(points), sizeof(cnormals), cnormals);
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(cpoints) + sizeof(points) + sizeof(cnormals), sizeof(normals), normals);

    // Load shaders and use the resulting shader program
    program = InitShader("shader.vs", "shader.fs");
    glUseProgram(program);

    GLuint vPosition = glGetAttribLocation(program, "vPosition");
    glEnableVertexAttribArray(vPosition);
    glVertexAttribPointer(vPosition, 4, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));

    GLuint vNormal = glGetAttribLocation(program, "vNormal");
    glEnableVertexAttribArray(vNormal);
    glVertexAttribPointer(vNormal, 3, GL_FLOAT, GL_TRUE, 0, BUFFER_OFFSET(sizeof(points) + sizeof(cpoints)));

    /* Getting shader variable locations */
    ModelView  = glGetUniformLocation(program, "ModelView");
    Projection = glGetUniformLocation(program, "Projection");
    vColor     = glGetUniformLocation(program, "vColor");
    vShading   = glGetUniformLocation(program, "vShading");
    vMapping   = glGetUniformLocation(program, "vMapping");

    glEnable(GL_DEPTH_TEST);

    /* Blank space color */
    glClearColor(0.09, 0.09, 0.03, 1);
    /* Setting transparency */
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glShadeModel(GL_SMOOTH);
}
/* We dont use glut's idle method. Instead, we are creating a timer in order to
 * get a fixed FPS. */
- (void)initUpdateTimer {
    timer = [NSTimer timerWithTimeInterval:kScheduledTimerInSeconds
                                    target:self
                                  selector:@selector(heartbeat)
                                  userInfo:nil
                                   repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer
                                 forMode:NSEventTrackingRunLoopMode];
} // initUpdateTimer

/* This is similar to glut's display method. It has been called in fixed rate.
 */
- (void)drawRect:(NSRect)theRect {
    [[self openGLContext]
        makeCurrentContext];        // Thread related, OSX's internal bussiness.
    [self resizeView];              // Calculating viewport according to changes on View's
                                    // size.
    [self updatePerspectiveMatrix]; // Perspective matrix calculation.
    [self keyboard];                // Navigating within space.
    [self camera];                  // Calculating final ModelView matrix here.
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self sendDataToShaders];
    glSwapAPPLE(); // equivalent to glutSwapBuffers() or [[self openGLContext]
                   // flushBuffer];
}

/* This method is used for sending all data to shaders using uniform location
 * variables.  */
- (void)sendDataToShaders {
    glUniformMatrix4fv(ModelView, 1, GL_TRUE, model_view);

    if (self.UPDATE_NEEDED) {
        self.UPDATE_NEEDED = false;

        if (self.mapping != COLOR) {
            glActiveTexture(GL_TEXTURE0); // activate texels for texture mapping
            glBindTexture(GL_TEXTURE_2D, myTextureName);
            glUniform1i(vMap, myTextureName);
        }

        if (CONTROL_DATA_SIZE > 0) {
            glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(cpoints[0]) * CONTROL_DATA_SIZE, cpoints);
            glBufferSubData(GL_ARRAY_BUFFER, sizeof(cpoints) + sizeof(points), sizeof(cnormals[0]) * CONTROL_DATA_SIZE, cnormals);
        }
        if (!self.EDIT_MODE && SURFACE_DATA_SIZE > 2) {
            glBufferSubData(GL_ARRAY_BUFFER, sizeof(cpoints), sizeof(points[0]) * SURFACE_DATA_SIZE, points);
            glBufferSubData(GL_ARRAY_BUFFER,
                            sizeof(cpoints) + sizeof(points) + sizeof(cnormals),
                            sizeof(normals[0]) * SURFACE_DATA_SIZE,
                            normals);
        }
    }
    glUniform1i(vShading, self.shading);
    glUniform1i(vMapping, self.mapping);
    if (self.EDIT_MODE || self.SHOW_CONTROL_POINTS) {
        glUniform4f(vColor, 1, 0.5, 0.5, 0.9);
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        glDrawArrays(GL_LINES, 0, CONTROL_DATA_SIZE);
    }
    glUniform4f(vColor, self.color.redComponent, self.color.greenComponent, self.color.blueComponent, self.color.alphaComponent);
    if (self.SHOW_WIREFRAME) {
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    } else {
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    }
    if (!self.EDIT_MODE) {
        glDrawArrays(GL_TRIANGLES, CONTROL_DATA_CAPACITY, SURFACE_DATA_SIZE);
    }
}

/* Calculating and sending perspective matrix here. Zoom is also handled here.
 */
- (void)updatePerspectiveMatrix {
    GLfloat aspect  = GLfloat(NSWidth(bounds)) / NSHeight(bounds);
    mat4 projection = Perspective(
        self.zoom, aspect, 0.0001,
        100.0); // set the perspective (angle of sight, width, height, ,
    glUniformMatrix4fv(Projection, 1, GL_TRUE, projection);
} // updatePrespectiveMatrix

/* Handles resizing/updating of OpenGL needs context update and if the window
 * dimensions change, window dimensions update, reseting of viewport and an
 * update of the projection matrix. */
- (void)resizeView {
    NSRect viewBounds = [self bounds];
    if (!NSEqualRects(viewBounds, bounds)) {
        GLsizei width  = (GLsizei)NSWidth(viewBounds);
        GLsizei height = (GLsizei)NSHeight(viewBounds);

        // Update the view bounds
        bounds = viewBounds;

        // View port has changed as well
        glViewport(0, 0, width, height);
    }
}
- (void)camera {
    model_view =
        RotateX(self.xrot) * // rotate our camera on the x-axis (left and right)
        RotateY(self.yrot) * // rotate our camera on the y-axis (up and down)
        Translate(
            -self.xpos, -self.ypos,
            -self.zpos); // translate the screen to the position of our camera
}
- (void)heartbeat {
    [self drawRect:[self bounds]];
}
/* This is called when OpenGLView is about be shown. We are setting OpenGL
 * version 3.2 compatibility here. */
- (void)awakeFromNib {
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)24, NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core, NSOpenGLPFADoubleBuffer, NSOpenGLPFAAccelerated, (NSOpenGLPixelFormatAttribute)0};

    NSOpenGLPixelFormat *pf =
        [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    [self setPixelFormat:pf];
}
/* glut' keyboard convenient. But this method is being called before calculating
 * ModelView for each frame. If there is no key pressed it's function is NOP. */
- (void)keyboard {
    float xrotrad, yrotrad;
    if (keysDown[kVK_ANSI_A] && !keysDown[kVK_ANSI_D]) { /* move left */
        yrotrad = (self.yrot / 180 * M_PI);
        self.xpos -= float(cos(yrotrad)) * 0.1;
        self.zpos -= float(sin(yrotrad)) * 0.1;
        if (controller != nil) {
            [[controller posXText] setFloatValue:self.xpos];
            [[controller posZText] setFloatValue:self.zpos];
        }
    }
    if (keysDown[kVK_ANSI_D] && !keysDown[kVK_ANSI_A]) { /* move right */
        yrotrad = (self.yrot / 180 * M_PI);
        self.xpos += float(cos(yrotrad)) * 0.1;
        self.zpos += float(sin(yrotrad)) * 0.1;
        if (controller != nil) {
            [[controller posXText] setFloatValue:self.xpos];
            [[controller posZText] setFloatValue:self.zpos];
        }
    }
    if (keysDown[kVK_ANSI_W] && !keysDown[kVK_ANSI_S]) { /* move up */
        yrotrad = (self.yrot / 180 * M_PI);
        xrotrad = (self.xrot / 180 * M_PI);
        self.xpos += float(cos(xrotrad) * sin(yrotrad)) / 10;
        self.zpos -= float(cos(xrotrad) * cos(yrotrad)) / 10;
        self.ypos -= float(sin(xrotrad)) / 10;
        if (controller != nil) {
            [[controller posXText] setFloatValue:self.xpos];
            [[controller posYText] setFloatValue:self.ypos];
            [[controller posZText] setFloatValue:self.zpos];
        }
    }
    if (keysDown[kVK_ANSI_S] && !keysDown[kVK_ANSI_W]) { /* move down */
        yrotrad = (self.yrot / 180 * M_PI);
        xrotrad = (self.xrot / 180 * M_PI);
        self.xpos -= float(cos(xrotrad) * sin(yrotrad)) / 10;
        self.zpos += float(cos(xrotrad) * cos(yrotrad)) / 10;
        self.ypos += float(sin(xrotrad)) / 10;
        if (controller != nil) {
            [[controller posXText] setFloatValue:self.xpos];
            [[controller posYText] setFloatValue:self.ypos];
            [[controller posZText] setFloatValue:self.zpos];
        }
    }
}
/* Setting up pressed keys. This is called for each button pushed down. */
- (void)keyDown:(NSEvent *)theEvent {
    unsigned keyCode = [theEvent keyCode];
    if (keyCode < 128)
        keysDown[keyCode] = YES;
    else
        [super keyUp:theEvent];
}
/* Setting up pressed keys. This is called for each button released. */
- (void)keyUp:(NSEvent *)theEvent {
    unsigned keyCode = [theEvent keyCode];
    if (keyCode < 128)
        keysDown[keyCode] = NO;
    else
        [super keyUp:theEvent];
}
/* For future development, currently not used. */
- (void)mouseDown:(NSEvent *)theEvent {
}
/* Reset last position at the end of mouse drag. */
- (void)mouseUp:(NSEvent *)theEvent {
    lastX = 0, lastY = 0;
}
/* So we can turn right and left, up and down with the help of this function. */
- (void)mouseDragged:(NSEvent *)theEvent {
    NSPoint pos = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (lastX != 0 && lastY != 0) {
        float dx = pos.x - lastX;
        float dy = pos.y - lastY;

        self.yrot += dx;
        self.xrot -= dy;
    }
    lastX = pos.x;
    lastY = pos.y;
    if (controller != nil) {
        [[controller pitchText] setFloatValue:self.xrot];
        [[controller yavText] setFloatValue:self.yrot];
    }
}
/* Zoom variable set here. */
- (void)scrollWheel:(NSEvent *)theEvent {
    self.zoom += [theEvent deltaY];
    if (self.zoom > 100) {
        self.zoom = 100;
    } else if (self.zoom < 0) {
        self.zoom = 0;
    }
    if (controller != nil) {
        [[controller zoomText] setFloatValue:self.zoom];
    }
}
/* These there overriden in order to get mouse and keyboard events */
- (BOOL)acceptsFirstResponder {
    return YES;
}
- (BOOL)becomeFirstResponder {
    return YES;
}
- (BOOL)resignFirstResponder {
    return YES;
}

/* We are getting reference in order to update GUI element's values after a
 * change on values like position, rotation etc. */
- (void)setViewController:(ViewController *)theController {
    controller = theController;
}
/* Inialize the random surface here. */
- (void)initExample {
    int i, j, ki, kj;
    double mui, muj, bi, bj;

    SURFACE_DATA_SIZE = 0;
    CONTROL_DATA_SIZE = 0;

    /* Create a random surface */
    //    srandom(1111);
    for (i = 0; i <= NI; i++) {
        for (j = 0; j <= NJ; j++) {
            inp[i][j].x = ((float)i);
            inp[i][j].y = (random() % 10000) / 5000.0 - tan(i) + sin(j);
            inp[i][j].z = ((float)j);
        }
    }

    for (i = 0; i < RESOLUTIONI; i++) {
        mui = i / (double)(RESOLUTIONI - 1);
        for (j = 0; j < RESOLUTIONJ; j++) {
            muj          = j / (double)(RESOLUTIONJ - 1);
            outp[i][j].x = 0;
            outp[i][j].y = 0;
            outp[i][j].z = 0;
            for (ki = 0; ki <= NI; ki++) {
                bi = BezierBlend(ki, mui, NI);
                for (kj = 0; kj <= NJ; kj++) {
                    bj = BezierBlend(kj, muj, NJ);
                    outp[i][j].x += (inp[ki][kj].x * bi * bj);
                    outp[i][j].y += (inp[ki][kj].y * bi * bj);
                    outp[i][j].z += (inp[ki][kj].z * bi * bj);
                }
            }
        }
    }

    for (i = 0; i < SURFACE_DATA_CAPACITY; i++) {
        normals[i] = vec3();
    }

    // Display the surface, in this case in OOGL format for GeomView
    vec4 v1, v2, p1, p2, p3, p4;
    vec3 c = vec3();

    vec3 preNorms[RESOLUTIONI][RESOLUTIONJ];
    for (i = 0; i < RESOLUTIONI; i++) {
        for (j = 0; j < RESOLUTIONJ; j++) {
            preNorms[i][j] = vec3();
        }
    }

    for (i = 0; i < RESOLUTIONI - 1; i++) {
        for (j = 0; j < RESOLUTIONJ - 1; j++) {
            p1 = vec4(outp[i][j].x, outp[i][j].y, outp[i][j].z, 1);
            p2 = vec4(outp[i][j + 1].x, outp[i][j + 1].y, outp[i][j + 1].z, 1);
            p3 = vec4(outp[i + 1][j + 1].x, outp[i + 1][j + 1].y, outp[i + 1][j + 1].z, 1);
            p4 = vec4(outp[i + 1][j].x, outp[i + 1][j].y, outp[i + 1][j].z, 1);

            // calculate normals
            v1 = p1 - p2;
            v2 = p1 - p3;

            c.x = v1.y * v2.z - v1.z * v2.y;
            c.y = v1.z * v2.x - v1.x * v2.z;
            c.z = v1.x * v2.y - v1.y * v2.x;

            preNorms[i][j] += c;
            preNorms[i][j + 1] += c;
            preNorms[i + 1][j + 1] += c;
            preNorms[i + 1][j] += c;

            points[SURFACE_DATA_SIZE++] = p1;
            points[SURFACE_DATA_SIZE++] = p2;
            points[SURFACE_DATA_SIZE++] = p3;

            points[SURFACE_DATA_SIZE++] = p3;
            points[SURFACE_DATA_SIZE++] = p4;
            points[SURFACE_DATA_SIZE++] = p1;
        }
    }

    int k = 0;
    for (i = 0; i < RESOLUTIONI - 1; i++) {
        for (j = 0; j < RESOLUTIONJ - 1; j++) {
            vec3 p1 = preNorms[i][j];
            vec3 p2 = preNorms[i][j + 1];
            vec3 p3 = preNorms[i + 1][j + 1];
            vec3 p4 = preNorms[i + 1][j];

            normals[k++] = p1;
            normals[k++] = p2;
            normals[k++] = p3;

            normals[k++] = p3;
            normals[k++] = p4;
            normals[k++] = p1;
        }
    }
    for (i = 0; i < SURFACE_DATA_SIZE; i++) {
        normals[i] = normalize(normals[i]);
    }
    // Control point polygon
    CONTROL_DATA_SIZE = 0;
    for (i = 0; i < NI; i++) {
        for (j = 0; j < NJ; j++) {
            vec4 p1                      = vec4(inp[i][j].x, inp[i][j].y, inp[i][j].z, 1);
            vec4 p2                      = vec4(inp[i][j + 1].x, inp[i][j + 1].y, inp[i][j + 1].z, 1);
            vec4 p3                      = vec4(inp[i + 1][j + 1].x, inp[i + 1][j + 1].y, inp[i + 1][j + 1].z, 1);
            vec4 p4                      = vec4(inp[i + 1][j].x, inp[i + 1][j].y, inp[i + 1][j].z, 1);
            cpoints[CONTROL_DATA_SIZE++] = p1;
            cpoints[CONTROL_DATA_SIZE++] = p2;
            cpoints[CONTROL_DATA_SIZE++] = p2;
            cpoints[CONTROL_DATA_SIZE++] = p3;
            cpoints[CONTROL_DATA_SIZE++] = p3;
            cpoints[CONTROL_DATA_SIZE++] = p4;
            cpoints[CONTROL_DATA_SIZE++] = p4;
            cpoints[CONTROL_DATA_SIZE++] = p1;
        }
    }
    self.UPDATE_NEEDED = true;
}

static double BezierBlend(int k, double mu, int n) {
    int nn, kn, nkn;
    double blend = 1;

    nn  = n;
    kn  = k;
    nkn = n - k;

    while (nn >= 1) {
        blend *= nn;
        nn--;
        if (kn > 1) {
            blend /= (double)kn;
            kn--;
        }
        if (nkn > 1) {
            blend /= (double)nkn;
            nkn--;
        }
    }
    if (k > 0)
        blend *= pow(mu, (double)k);
    if (n - k > 0)
        blend *= pow(1 - mu, (double)(n - k));

    return (blend);
}

/* Called on GUI class, in order to send Mapping data. */
- (void)setMapFile:(NSURL *)url {
    if (self.mapping != COLOR) {
    }
    if (url == nil) {
        self.mapping = COLOR;
    } else {
        CGImageSourceRef myImageSourceRef =
            CGImageSourceCreateWithURL((CFURLRef)url, NULL);
        CGImageRef myImageRef =
            CGImageSourceCreateImageAtIndex(myImageSourceRef, 0, NULL);
        int width                    = static_cast<int>(CGImageGetWidth(myImageRef));
        int height                   = static_cast<int>(CGImageGetHeight(myImageRef));
        CGRect rect                  = CGRectMake(0, 0, width, height);
        void *myData                 = calloc(width * 4, height);
        CGColorSpaceRef space        = CGColorSpaceCreateDeviceRGB();
        CGContextRef myBitmapContext = CGBitmapContextCreate(
            myData, width, height, 8, width * 4, space, kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
        CGContextSetBlendMode(myBitmapContext, kCGBlendModeCopy);
        CGContextDrawImage(myBitmapContext, rect, myImageRef);
        CGContextRelease(myBitmapContext);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, width);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, myData);
        free(myData);
        self.UPDATE_NEEDED = TRUE;
    }
}
- (void)dealloc {
    glDeleteProgram(program);
    //    GetError();
    glDeleteBuffers(1, &vao);
    //    GetError();
}
@end