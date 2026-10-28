//TEST:SIMPLE(filecheck=HLSL): -target hlsl -stage compute -entry computeMain
//TEST:REFLECTION(filecheck=REFL): -target hlsl -stage compute -entry computeMain

// FXC packs HLSL constant buffers with its own rules, so a std140 constant
// buffer (`ConstantBuffer<T, Std140DataLayout>`) is emitted with `uint` padding
// members that make FXC place every member on its std140 offset. Reflection
// reports the std140 offsets, which is the layout the host fills.

struct Params
{
    float a;    // std140 0
    float3 b;   // std140 16; FXC would pack it at 4
    float c[2]; // std140 32, stride 16; FXC ends it at 52
    float d;    // std140 64; FXC would pack it at 52
    float2 e;   // std140 72; FXC would pack it at 68
};

ConstantBuffer<Params, Std140DataLayout> params;
RWStructuredBuffer<float> output;

[numthreads(1, 1, 1)]
void computeMain()
{
    output[0] = params.a + params.b.y + params.c[1] + params.d + params.e.y;
}

// HLSL: struct Params_std140
// HLSL-NEXT: {
// HLSL-NEXT: float a
// HLSL-NEXT: uint _padding
// HLSL-NEXT: uint _padding
// HLSL-NEXT: uint _padding
// HLSL-NEXT: float3 b
// HLSL-NEXT: uint _padding
// HLSL-NEXT: float {{.*}}c{{.*}}[int(2)]
// HLSL-NEXT: uint _padding
// HLSL-NEXT: uint _padding
// HLSL-NEXT: uint _padding
// HLSL-NEXT: float d
// HLSL-NEXT: uint _padding
// HLSL-NEXT: float2 e
// HLSL-NEXT: };
// HLSL: Params_std140{{.*}} params

// REFL: "name": "a"
// REFL: "offset": 0
// REFL: "name": "b"
// REFL: "offset": 16
// REFL: "name": "c"
// REFL: "offset": 32
// REFL: "name": "d"
// REFL: "offset": 64
// REFL: "name": "e"
// REFL: "offset": 72
