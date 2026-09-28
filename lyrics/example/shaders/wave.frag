#version 450 core

// 示例插件背景：三种主题色搅动的波浪光晕（只做背景，不抢歌词）
layout(location = 0) in vec2 qt_TexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4  uColorA;
    vec4  uColorB;
    vec4  uColorC;
    vec2  uResolution;
    float uTime;
    float uEnergy;
};

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 res = max(uResolution, vec2(1.0));
    vec2 uv = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y);
    vec2 p = (uv * res * 2.0 - res) / res.y;

    float t = uTime * 0.15;
    float w1 = sin(p.x * 1.7 + t * 1.3 + sin(p.y * 2.3 - t) * 0.9);
    float w2 = sin(p.y * 2.1 - t * 0.9 + sin(p.x * 1.3 + t * 0.7) * 1.1);
    float band = smoothstep(-0.25, 0.65, w1 * 0.5 + w2 * 0.5);

    vec3 col = mix(uColorA.rgb, uColorB.rgb, band);
    col = mix(col, uColorC.rgb, 0.35 * (0.5 + 0.5 * w2));
    col *= (0.45 + 0.85 * band) * (0.55 + 0.65 * uEnergy);
    col *= clamp(1.15 - 0.55 * dot(p, p), 0.04, 1.15);

    fragColor = vec4(pow(max(col, 0.0), vec3(0.4545)), 1.0) * qt_Opacity;
}
