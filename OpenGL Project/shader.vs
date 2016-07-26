#version 400

/* --------------  DONT FORGET TO CHANGE OTHER SHADER TOO  --------------- */
#define NONE 0
#define PHONG 1
#define GOURAUD 2

#define COLOR 0
#define BUMP 1
#define TEXTURE 2

#define DIFFUSE_PRODUCT 0.7
#define AMBIENT_PRODUCT 0.6
#define SPECULAR_PRODUCT 0.7
#define SHININESS_PRODUCT 20

#define LIGHT_X 0
#define LIGHT_Y 7
#define LIGHT_Z 0

#define LIGHT_R 0.9
#define LIGHT_G 0.9
#define LIGHT_B 0.9

#define AMBIENT_R 0.6
#define AMBIENT_G 0.6
#define AMBIENT_B 0.6
/* --------------  --------------------------------------  --------------- */

in vec4 vPosition;
in vec3 vNormal;

out vec4 fPosition;
out vec4 vShaderColor;
out float distance;
out vec3 fShaderNormal;
out vec3 fShaderEye;
out vec3 fShaderLight;

uniform vec4 vColor;
uniform mat4 ModelView;
uniform mat4 Projection;
uniform int vShading;
uniform int vMapping;
uniform sampler2D vMap;

void main()
{
    vec4 lightPos = vec4(LIGHT_X, LIGHT_Y, LIGHT_Z, 1);
    vec3 lightCol = vec3(LIGHT_R, LIGHT_G, LIGHT_B);
    vShaderColor = vec4(AMBIENT_R, AMBIENT_G, AMBIENT_B, 1) * AMBIENT_PRODUCT;
    vec4 ambient = vec4(AMBIENT_R, AMBIENT_G, AMBIENT_B, 1);
    
    // Transform positions to eye coordinates
    vec3 pos = (ModelView * vPosition).xyz;
    vec3 E = normalize( -pos );
    vec3 N;
    if(vMapping == BUMP){
        N = normalize( ModelView * vec4(vNormal + texture(vMap, vec2(vPosition.x/10.0f, vPosition.z/10.0f)).xyz, 0.0) ).xyz;
    } else {
        N = normalize( ModelView * vec4(vNormal, 0.0) ).xyz;
    }
    
    
    vec3 L;
    
    /* Check if light is at infinity */
    if(lightPos.w == 0){
        L = (ModelView * lightPos).xyz;
    } else {
        L = (ModelView * lightPos).xyz - pos;
    }
    
    distance = sqrt(L.x * L.x + L.y * L.y + L.z * L.z);
    L =  normalize( L );
    
    if(vShading == GOURAUD){
        
        vec3 H = normalize( L + E );
    
        float Kd = max( dot(L, N), 0.0 );
        float Ks = pow( max(dot(N, H), 0.0), SHININESS_PRODUCT );
    
        float diffuse = Kd * DIFFUSE_PRODUCT;
        float specular = Ks * SPECULAR_PRODUCT;
        /* If the light source and the surface is not facing each other, then no specular lightning */;
        if(dot(L, N) < 0.0){
            specular = 0;
        }
        vShaderColor +=  vec4(lightCol,1) * ambient/10 + vec4(lightCol,1) * diffuse * 10/distance + vec4(lightCol,1) * 10 * specular/distance;
        if(vMapping == TEXTURE){
            vShaderColor *= texture(vMap, vec2(vPosition.x/10.0f, vPosition.z/10.0f));
        } else {
            vShaderColor *= vColor;
        }
    }
    
    fShaderLight = L;
    fShaderEye = E;
    fShaderNormal = N;
    fPosition = vPosition;
    gl_Position = Projection * ModelView * vPosition;
    
}