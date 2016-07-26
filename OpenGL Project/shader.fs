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

in vec4 vShaderColor;
in float distance;
in vec3 fShaderNormal;
in vec3 fShaderEye;
in vec3 fShaderLight;
in vec4 fPosition;

out vec4 fColor;

uniform vec4 vColor;
uniform mat4 ModelView;
uniform mat4 Projection;
uniform int vShading;
uniform int vMapping;
uniform sampler2D vMap;

void main() 
{
    if(vShading == GOURAUD){
        
        fColor = vShaderColor;
        
    } else if(vShading == PHONG){
        
        vec3 lightCol = vec3(LIGHT_R, LIGHT_G, LIGHT_B);
        vec4 ambient = vec4(AMBIENT_R, AMBIENT_G, AMBIENT_B, 1);
        
        vec3 N = normalize(fShaderNormal);
        vec3 E = normalize(fShaderEye);
        vec3 L = normalize(fShaderLight);
        vec3 H = normalize( L + E );
        
        fColor = ambient * AMBIENT_PRODUCT;
        
        float Kd = max(dot(L, N), 0.0);
        float Ks = pow(max(dot(N, H), 0.0), SHININESS_PRODUCT);
        
        float diffuse = Kd * DIFFUSE_PRODUCT;
        float specular = Ks * SPECULAR_PRODUCT;
        if(dot(L, N) < 0.0){
            specular = 0;
        }
        fColor += vec4(lightCol,1) * ambient/10 + vec4(lightCol,1) * 10 * diffuse/distance + vec4(lightCol,1) * 10 *  specular/distance;
        if(vMapping == TEXTURE){
            fColor *= texture(vMap, vec2(fPosition.x/10.0f, fPosition.z/10.0f));
        } else {
            fColor *= vColor;
        }
        
    } else {
        fColor = vColor;
    }
} 

