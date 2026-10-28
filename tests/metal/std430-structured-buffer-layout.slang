//TEST:SIMPLE(filecheck=METAL): -target metal -stage compute -entry computeMain
//TEST:REFLECTION(filecheck=REFL): -target metal -stage compute -entry computeMain

// A std430 structured buffer (`StructuredBuffer<T, Std430DataLayout>`) keeps the
// std430 layout on Metal. Native MSL vectors are sized and aligned to a power
// of two (`float3` is 16 bytes) and `bool` is 1 byte, so the storage struct
// holds packed vectors, `uint` booleans, 16-byte `float3` array elements and
// matrix columns, and `uint` padding up to each std430 offset and the stride.

struct Element
{
    float3 a;                 // std430 0
    float b;                  // std430 12; a native float3 ends at 16
    float2 c[2];              // std430 16, stride 8
    float3 d[2];              // std430 32, stride 16
    bool e;                   // std430 64: the member after an array aligns to the array
    column_major float3x3 m;  // std430 80, columns 16 bytes apart
    float f;                  // std430 128; element stride 144
};

RWStructuredBuffer<Element, Std430DataLayout> elements;

[numthreads(1, 1, 1)]
void computeMain()
{
    Element element = elements[0];
    element.f = element.a.z + element.b + element.c[1].y + element.d[1].z + (element.e ? 1.0 : 0.0) + element.m[2][1];
    elements[1] = element;
}

// METAL-DAG: array<packed_float2, int(2)> data
// METAL-DAG: array<float4, int(2)> data
// METAL-DAG: array<float4, int(3)> data

// METAL: struct Element_std430
// METAL-NEXT: {
// METAL-NEXT: packed_float3 a
// METAL-NEXT: float b
// METAL-NEXT: _Array_std430_{{.*}} c
// METAL-NEXT: _Array_std430_{{.*}} d
// METAL-NEXT: uint e
// METAL-NEXT: uint _padding
// METAL-NEXT: uint _padding
// METAL-NEXT: uint _padding
// METAL-NEXT: _MatrixStorage_float3x3_ColMajorstd430{{.*}} m
// METAL-NEXT: float f
// METAL-NEXT: uint _padding
// METAL-NEXT: uint _padding
// METAL-NEXT: uint _padding
// METAL-NEXT: };

// REFL: "name": "a"
// REFL: "offset": 0
// REFL: "name": "b"
// REFL: "offset": 12
// REFL: "name": "c"
// REFL: "offset": 16
// REFL: "name": "d"
// REFL: "offset": 32
// REFL: "name": "e"
// REFL: "offset": 64
// REFL: "name": "m"
// REFL: "offset": 80
// REFL: "name": "f"
// REFL: "offset": 128
