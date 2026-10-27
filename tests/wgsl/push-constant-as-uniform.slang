//TEST:SIMPLE(filecheck=WGSL): -target wgsl -entry fsMain -stage fragment

// WGSL has no push constants: a `[[vk::push_constant]]` buffer is an ordinary
// uniform buffer there, with a binding and std140 layout, as it is on HLSL and
// Metal. A `var<uniform>` without `@group`/`@binding` is rejected by WebGPU.

struct ParamsData { float4 color; };
struct PushData { float4 tint; };

[[vk::binding(0, 0)]] ConstantBuffer<ParamsData> Params : register(b0, space0);
[[vk::push_constant]] [[vk::binding(1, 0)]] ConstantBuffer<PushData> Push : register(b1, space0);

// WGSL-DAG: @binding(0) @group(0) var<uniform> Params_0
// WGSL-DAG: @binding(1) @group(0) var<uniform> Push_0
// WGSL-NOT: PushData_std430

[shader("fragment")]
float4 fsMain() : SV_Target { return Params.color * Push.tint; }
