#version 330 core

uniform float u_time;
// in vec3 pos;
out vec4 o;

void main() {
    // //Normalize Fragment Coordinates:
    // vec3 uv = (pos + 1);
    // vec3 backgroundColor = vec3(0.835, 1, 1);
    // vec3 col = vec3(0);


    // Calculate Camera Position& matrix
    // vec3 lookAtPos = vec3(0, 0.5, 0);
    // vec3 ro = cameraLookatPosition(.5, 5., lookAtPos);
    // mat3 cam = cameraLookat(ro, lookAtPos);
    // Calculate Ray Direction:
    // vec3 rd = cam * normalize(vec3(uv, -1));

    // color = vec4(cos(pos.x), sin(pos.y), 0.0, 1.0);

    // const vec2 r = vec2(1, 1);
    // vec2 p = (pos.xy - r) / r.y;

    // float t = u_time;
    // o = vec4(sin(t) * pos.x * pos.y, cos(t) * pos.y, 0.0, 1.0);

    vec2 FC = gl_FragCoord.xy;
    float t = u_time;
    const vec2 r = vec2(800, 600);

    vec2 p = (FC * 2. - r) / r.y;
    float l = 4. - 4. * abs(.7 - dot(p, p));
    vec2 i = vec2(0.);
    vec2 v = p * l;
    o = vec4(0.);

    for(; i.y++ < 8.; o += (sin(v.xyyx) + 1.) * abs(v.x - v.y)) {
        v += cos(v.yx * i.y + i + t) / i.y + .7;
    }
    o = tanh(5. * exp(l - 4. - p.y * vec4(-1, 1, 2, 0)) / o);

}
