//TEST:SIMPLE(filecheck=HLSL): -target hlsl -stage compute -entry computeMain
//TEST:REFLECTION(filecheck=REFL): -target hlsl -stage compute -entry computeMain

// HLSL structured buffers pack members with their scalar alignment, so a std430
// structured buffer (`StructuredBuffer<T, Std430DataLayout>`) is emitted with
// `uint` padding members, 16-byte `float3` array elements and matrix columns,
// and a struct padded to the std430 element stride. Reflection reports the
// std430 offsets, which is the layout the host fills.

struct Element
{
    float a;                 // std430 0
    float3 b;                // std430 16; HLSL would pack it at 4
    float c[2];              // std430 28, stride 4
    float3 d[2];             // std430 48, stride 16; HLSL packs float3 every 12 bytes
    column_major float3x3 m; // std430 80, columns 16 bytes apart
    float e;                 // std430 128; element stride 144
};

RWStructuredBuffer<Element, Std430DataLayout> elements;

[numthreads(1, 1, 1)]
void computeMain()
{
    Element element = elements[0];
    element.e = element.a + element.b.y + element.c[1] + element.d[1].z + element.m[2][1];
    elements[1] = element;
}

// HLSL-DAG: float4 {{.*}}data{{.*}}[int(2)]
// HLSL-DAG: float4 {{.*}}data{{.*}}[int(3)]

// HLSL: struct Element_std430
// HLSL-NEXT: {
// HLSL-NEXT: float a
// HLSL-NEXT: uint _padding
// HLSL-NEXT: uint _padding
// HLSL-NEXT: uint _padding
// HLSL-NEXT: float3 b
// HLSL-NEXT: float {{.*}}c{{.*}}[int(2)]
// HLSL-NEXT: uint _padding
// HLSL-NEXT: uint _padding
// HLSL-NEXT: uint _padding
// HLSL-NEXT: _Array_std430_{{.*}} d
// HLSL-NEXT: _MatrixStorage_float3x3_ColMajorstd430{{.*}} m
// HLSL-NEXT: float e
// HLSL-NEXT: uint _padding
// HLSL-NEXT: uint _padding
// HLSL-NEXT: uint _padding
// HLSL-NEXT: };
// HLSL: RWStructuredBuffer<Element_std430{{.*}}> elements

// REFL: "name": "a"
// REFL: "offset": 0
// REFL: "name": "b"
// REFL: "offset": 16
// REFL: "name": "c"
// REFL: "offset": 28
// REFL: "name": "d"
// REFL: "offset": 48
// REFL: "name": "m"
// REFL: "offset": 80
// REFL: "name": "e"
// REFL: "offset": 128
