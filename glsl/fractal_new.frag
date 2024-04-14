#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.1415926538

uniform vec2 u_resolution;
uniform vec3 u_camera;
uniform mat4 u_modelViewProjectionMatrix;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 700.0;
const float EPSILON = 0.0001;
const float FIELD_OF_VIEW = 70.0;

#include "lygia/sdf.glsl"
#include "lygia/space/lookAt.glsl"

struct rayInfo
{
    vec3 rgb;
};

float sceneSDF(vec3 p) {
    return sphereSDF(vec3(0.0, 0.0, 0.0), 0.1);
}

rayInfo raymarch() {
    // vec3 dir = vec3(vec4(normalize(vec3(
    //                     gl_FragCoord.xy - u_resolution.xy,
    //                     -u_resolution.y / tan(radians(FIELD_OF_VIEW) / 2.0))), 0.0) * u_viewMatrix
    //     ).xyz;

    vec2 xy = gl_FragCoord.xy - u_resolution.xy / 2.0;
    float z = u_resolution.y / tan(radians(70.0) / 2.0);

    vec3 dir = lookAt(u_camera) * normalize(vec3(xy, -z));

    float depth = MIN_DIST;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(u_camera + depth * dir);
        if (dist < EPSILON) {
            return rayInfo(dir);
        }
        depth += dist;
        if (depth >= MAX_DIST) {
            return rayInfo(vec3(0.0, 0.0, 0.0));
        }
    }
    return rayInfo(vec3(0.0, 0.0, 0.0));
}

void main() {
    gl_FragColor = vec4(raymarch().rgb, 1.0);
}
