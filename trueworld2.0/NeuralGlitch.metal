#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct VertexIn {
    float4 position [[attribute(SCNVertexSemanticPosition)]];
    float2 texcoord [[attribute(SCNVertexSemanticTexcoord0)]];
};

struct NodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewProjectionTransform;
};

struct VertexOut {
    float4 position [[position]];
    float2 texcoord;
};

vertex VertexOut glitchVertex(VertexIn in [[stage_in]], constant NodeBuffer& scn_node [[buffer(1)]]) {
    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * in.position;
    out.texcoord = in.texcoord;
    return out;
}

fragment float4 glitchFragment(VertexOut in [[stage_in]], 
                               texture2d<float> colorSampler [[texture(0)]],
                               constant float& time [[buffer(0)]],
                               constant float& intensity [[buffer(1)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    float2 uv = in.texcoord;
    
    // Neural Jitter
    float jitter = sin(time * 50.0) * cos(time * 20.0) * intensity * 0.05;
    uv.x += jitter;
    
    // Chromatic Aberration
    float offset = intensity * 0.02;
    float4 r = colorSampler.sample(s, uv + float2(offset, 0));
    float4 g = colorSampler.sample(s, uv);
    float4 b = colorSampler.sample(s, uv - float2(offset, 0));
    
    float4 result = float4(r.r, g.g, b.b, 1.0);
    
    // Scanline effect
    float scanline = sin(uv.y * 1000.0) * 0.05 * intensity;
    result -= scanline;
    
    return result;
}
