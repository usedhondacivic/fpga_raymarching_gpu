#version 430
#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.1415926538

uniform vec2 u_resolution;
uniform vec3 u_camera;

out vec4 FragColor;

#define MAX_MARCHING_STEPS 255
#define MIN_DIST 0.0
#define MAX_DIST 7000.0
#define EPSILON 0.0001
#define FIELD_OF_VIEW 70.0

#include "lygia/sdf.glsl"
#include "lygia/space/lookAt.glsl"

struct rayInfo
{
    vec3 rgb;
};

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

// https://www.shadertoy.com/view/wsVBz1
const vec3[] vertices = vec3[](
        vec3(1.0, 1.0, 1.0),
        vec3(-1.0, 1.0, -1.0),
        vec3(-1.0, -1.0, 1.0),
        vec3(1.0, -1.0, -1.0));

vec3 fold(vec3 point, vec3 pointOnPlane, vec3 planeNormal)
{
    // Center plane on origin for distance calculation
    float distToPlane = dot(point - pointOnPlane, planeNormal);

    // We only want to reflect if the dist is negative
    distToPlane = min(distToPlane, 0.0);
    return point - 2.0 * distToPlane * planeNormal;
}

float sdTetrahedron(vec3 point)
{
    return (max(
        abs(point.x + point.y) - point.z,
        abs(point.x - point.y) + point.z
    ) - 1.0) / sqrt(3.);
}

float sdSierpinski(vec3 point, int level)
{
    float scale = 1.0;
    for (int i = 0; i < level; i++)
    {
        // Scale point toward corner vertex, update scale accumulator
        point -= vertices[0];
        point *= 2.0;
        point += vertices[0];

        scale *= 2.0;

        // Fold point across each plane
        for (int i = 1; i <= 3; i++)
        {
            // The plane is defined by:
            // Point on plane: The vertex that we are reflecting across
            // Plane normal: The direction from said vertex to the corner vertex
            vec3 normal = normalize(vertices[0] - vertices[i]);
            point = fold(point, vertices[i], normal);
        }
    }
    // Now that the space has been distorted by the IFS,
    // just return the distance to a tetrahedron
    // Divide by scale accumulator to correct the distance field
    return sdTetrahedron(point) / scale;
}

float sceneSDF(vec3 p) {
    // float d = sdTorus(p, vec2(1.0, 0.3));
    // return d;
    // return DE(p);
    return sdSierpinski(p, 10);
}

vec3 fragToWorldVector() {
    vec2 xy = gl_FragCoord.xy - u_resolution.xy / 2.0;
    float z = u_resolution.y / tan(radians(FIELD_OF_VIEW) / 2.0);
    vec3 viewDir = lookAt(
            -u_camera,
            vec3(0.0, 0.0, 0.0),
            vec3(0.0, 1.0, 0.0)
        ) * normalize(vec3(xy, -z));
    return normalize(viewDir.xyz);
}

rayInfo raymarch() {
    vec3 dir = fragToWorldVector();
    float depth = MIN_DIST;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(u_camera + depth * dir);
        if (dist < EPSILON) {
            return rayInfo(vec3(1.0, 1.0, 1.0) * (MAX_MARCHING_STEPS / (i * 100.0)) + 0.2);
        }
        depth += dist;
        if (depth >= MAX_DIST) {
            return rayInfo(vec3(0.0, 0.0, 0.0));
        }
    }
    return rayInfo(vec3(0.0, 1.0, 0.0));
}

void main() {
    FragColor = vec4(raymarch().rgb, 1.0);
}
