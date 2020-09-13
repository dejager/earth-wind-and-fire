#include <metal_stdlib>
using namespace metal;

float noise(float3 p) {
  p = floor(p);
  p = fract(p * float3(283.343, 251.691, 634.127));
  p += dot(p, p + 23.453);
  return fract(p.x * p.y);
}

float blendThatNoise(float3 p) {
    float2 off = float2(1.0, 0.0);

    return mix(mix(mix(noise(p), noise(p+off.xyy), fract(p.x)),
                   mix(noise(p + off.yxy), noise(p+off.xxy), fract(p.x)), fract(p.y)),
               mix(mix(noise(p + off.yyx), noise(p+off.xyx), fract(p.x)),
                   mix(noise(p + off.yxx), noise(p+off.xxx), fract(p.x)), fract(p.y)),
               fract(p.z));
}

float gimmeSomeTurb(float3 p, float time) {
    p *= 4.0;
    float3 dp = float3(p.xy, p.z + time * 0.25);
    float inc = 0.75;
    float div = 1.75;
    float3 octs = dp * 2.13;
    float n = blendThatNoise(dp);
    for(float i = 0.0; i < 5.0; i++) {
      float ns = blendThatNoise(octs);
      n += inc * ns;

      octs *= 2.0 + (float3(ns, blendThatNoise(octs + float3(n, 0.0, 0.1)), 0.0));
      inc *= 0.5 * n;
      div += inc;
    }
    float v = n / div;
    v *= 1.0 -max(0.0, 1.2 - length(float3(0.5, 0.0, 6.0) - p));
    return v;
}

kernel void iThinkImGettingTheBlackLungPop(texture2d<float, access::write> o[[texture(0)]],
                                           constant float &time [[buffer(0)]],
                                           constant float2 *touchEvent [[buffer(1)]],
                                           constant int &numberOfTouches [[buffer(2)]],
                                           ushort2 gid [[thread_position_in_grid]]) {


  // coordinates
  int width = o.get_width();
  int height = o.get_height();
  float2 res = float2(width, height);
  float2 uv = (float2(gid) * 2.0 - res.xy) / res.y;

  uv *= 1.0 + 0.2 * length(uv);
  float uvlen = 1.0 - length(uv);
  float tt = 0.5 * time + (0.3 - 0.3 * uvlen * uvlen);
  float2 rot = float2(sin(tt), cos(tt));
  uv = float2(uv.x * rot.x + uv.y * rot.y, uv.x * rot.y - uv.y * rot.x);
  float3 rd = normalize(float3(uv, 5.0));

  float3 color = float3(0.0);
  rd.z += tt * 0.01;
  float nv = gimmeSomeTurb(rd, time);
  for(float i = 0.0; i < 1.0; i += 0.2) {
    nv *=.5;
    nv = gimmeSomeTurb(float3(rd.xy, rd.z +i), time);
    color += (1.5 - i) * float3(nv, nv * nv * (3.0 -2.0 * nv), nv * nv);
  }
  color /= float3(5.0, 10.0, 10.0);

  o.write(float4(color, 1.0), gid);
}
