precision mediump float;

uniform float uGamma;
uniform float uTime;
uniform sampler2D tTexture;
uniform sampler2D tLightmap;
uniform sampler2D tDlight;
uniform sampler2D tLightStyle;

varying vec4 vTexCoord;
varying vec4 vLightStyle;
varying float vFog;
uniform vec3 uFogColor;

void main(void) {
  vec4 texture = vec4(texture2D(tTexture, vTexCoord.st + vec2(sin(vTexCoord.t * 3.141593 + uTime), sin(vTexCoord.s * 3.141593 + uTime)) * 0.125).rgb, 1.0);

  vec4 lightstyle = vec4(
    texture2D(tLightStyle, vec2(vLightStyle.x, 0.0)).a,
    texture2D(tLightStyle, vec2(vLightStyle.y, 0.0)).a,
    texture2D(tLightStyle, vec2(vLightStyle.z, 0.0)).a,
    texture2D(tLightStyle, vec2(vLightStyle.w, 0.0)).a
  );

  vec3 d;

  d.r = dot(
    texture2D(
      tLightmap,
      vec2(vTexCoord.z, vTexCoord.w / 4.0)
    ),
    lightstyle * 43.828125
  );
  d.g = dot(
    texture2D(
      tLightmap,
      vec2(vTexCoord.z, vTexCoord.w / 4.0 + 0.25)
    ),
    lightstyle * 43.828125
  );
  d.b = dot(
    texture2D(
      tLightmap,
      vec2(vTexCoord.z, vTexCoord.w / 4.0 + 0.5)
    ),
    lightstyle * 43.828125
  );

  gl_FragColor = vec4(
    texture.r * mix(1.0, d.r + texture2D(tDlight, vTexCoord.st).r, texture.a),
    texture.g * mix(1.0, d.g + texture2D(tDlight, vTexCoord.st).g, texture.a),
    texture.b * mix(1.0, d.b + texture2D(tDlight, vTexCoord.st).b, texture.a),
    0.66
  );
  // apply fog (mix RGB only, preserve alpha)
  vec3 finalRgb = gl_FragColor.rgb;
  finalRgb = mix(uFogColor, finalRgb, vFog);
  gl_FragColor = vec4(finalRgb, gl_FragColor.a);
}
