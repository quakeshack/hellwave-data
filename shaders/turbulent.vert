precision mediump float;

uniform vec3 uOrigin;
uniform mat3 uAngles;
uniform vec3 uViewOrigin;
uniform mat3 uViewAngles;
uniform mat4 uPerspective;

uniform bool uPerformDotLighting;

uniform float uTime;
// fog uniforms
uniform vec3 uFogColor;
uniform vec4 uFogParams; // start, end, density, mode

attribute vec3 aPosition;
// attribute vec3 aNormal;
attribute vec4 aTexCoord;
attribute vec4 aLightStyle;
// attribute vec3 aTangent;
// attribute vec3 aBitangent;

varying vec4 vTexCoord;
varying vec4 vLightStyle;
varying float vFog;

varying vec3 vPosition;
varying vec3 vNormal;

void main(void) {
  vec3 aPositionA = aPosition;

  aPositionA.z += sin(aPosition.x + uTime) * 2.0 - 1.0;
  aPositionA.z += cos(aPosition.y + uTime) * 2.0 - 1.0;

  vec3 position = uViewAngles * (uAngles * aPositionA + uOrigin - uViewOrigin);
  gl_Position = uPerspective * vec4(position.xz, -position.y, 1.0);

  vTexCoord = aTexCoord;
  vLightStyle = aLightStyle;
  vPosition = position;
  vNormal = uViewAngles * vec3(0.0, 0.0, 1.0);

  // compute fog based on distance from camera
  float dist = length((uAngles * aPositionA + uOrigin) - uViewOrigin);
  float denom = max(0.0001, uFogParams.y - uFogParams.x);
  float distNorm = clamp((dist - uFogParams.x) / denom, 0.0, 1.0);
  if (uFogParams.w < 0.0) {
    vFog = 1.0;
  } else if (uFogParams.w < 0.5) {
    // linear: fog = (end - dist) / (end - start)
    float denom = max(0.0001, uFogParams.y - uFogParams.x);
    vFog = clamp((uFogParams.y - dist) / denom, 0.0, 1.0);
  } else if (abs(uFogParams.w - 1.0) < 0.5) {
    // exp (apply density across [start,end])
    vFog = clamp(exp(-uFogParams.z * distNorm), 0.0, 1.0);
  } else {
    // exp2 (apply density across [start,end])
    vFog = clamp(exp(-uFogParams.z * uFogParams.z * distNorm * distNorm), 0.0, 1.0);
  }
}
