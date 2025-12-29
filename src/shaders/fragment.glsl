#version 330 core

uniform float u_time;
out vec4 o;


const vec2 iResolution = vec2(800, 600);


vec3 trace(vec2 uv) {
    float t = u_time;
    const vec2 r = vec2(800, 600);
    t = u_time;

    // vec3 origin = vec3(0.0, 0.0, 0.0);  // camera position
    vec3 d0 = normalize(vec3(uv, -1.0));  // straight into scene [web:12]

    vec3 p0 = vec3(uv, 0);
    vec3 n = normalize(p0);
    vec3 T = normalize(cross(cross(n, d0), n));

    int N = 1 * 512;
    float r0 = 50.0;
    float u0 = 1/dot(p0, p0);
    // float u0 = 1 / r0;
    float v0 = -u0 * dot(d0, n) / dot(d0, T);

    // float b = length(uv) * 9.0;   // impact parameter
    // float v-1 = sqrt(max(0.0, 1.0/(b*b) - u0*u0 + u0*u0*u0));

    float u = u0;
    float v = v0;
    float a = -u0 * (1 - 1.5 * u0 * u0);

    float delta_phi = 0.01;
    float phi = 0.0;

    vec3 color = vec3(0);
    float alpha = 1.0;

    for (int i = 0; i < N; i++) {
        // d^2 u(phi) / d phi^2 = -u(phi) (1 - 3/2 u(phi)^2)

        // a_i = A(u) = -u(phi) (1 - 3/2 u(phi)^2)
        // u_i+1 = u_i + v_i * delta_t + 1/2 * a_i * delta_t^2
        // v_i+1 = v_i + 1/2 (a_i + a_i+1) * delta_t

        float delta_u = v * delta_phi + 0.5 * a * delta_phi * delta_phi;

        u = u + delta_u;
        float ai = -u + 1.5 * u * u;
        v = v + 0.5 * (a + ai) * delta_phi;
        a = ai;


        phi += delta_phi;

        // if (u + delta_u < 0) {
        //     return color;
        // }
        // escaped to infinity
        if (u < 0.0)
            break;

        // crossed photon sphere inward → captured
        if (u > 1.0 / 3.0 && v > 0.0)
            return vec3(0.0);

        // horizon (strongest)
        if (u > 0.5 && v > 0.0)
            return vec3(0.0);


        // if (u > 1.0/3.0) {
        //     return vec3(0);
        //     // break;
        // }

        // p = origin + t * d0
    }


    float R = 1.0 / u;
    vec3 pos = (n * cos(phi) + T * sin(phi)) * R;
    // vec2 pos = R * vec2(cos(phi), sin(phi));
    vec3 dir = normalize(vec3(pos.xy, -R));
    // return vec3(pos.x * 0.21, pos.y * 0.72, pos.z * 0.07);
    // return color;
    return dir;
}


void main() {
    // Normalize screen coordinates to [-1, 1]
    vec2 uv = (gl_FragCoord.xy / iResolution.xy) * 2.0 - 1.0;

    // Correct for aspect ratio
    uv.x *= iResolution.x / iResolution.y;

    vec3 col = trace(uv);
    o = vec4(col, 1.0);
}