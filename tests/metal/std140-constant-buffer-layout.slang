//TEST:SIMPLE(filecheck=METAL): -target metal -stage compute -entry computeMain
//TEST:REFLECTION(filecheck=REFL): -target metal -stage compute -entry computeMain

// A std140 constant buffer (`ConstantBuffer<T, Std140DataLayout>`) keeps the
// std140 layout on Metal. Native MSL vectors are sized and aligned to a power
// of two (`float3` is 16 bytes) and `bool` is 1 byte, so the storage struct
// holds packed vectors, `uint` booleans, 16-byte array elements and matrix
// columns, and `uint` padding up to each std140 offset.

struct Params
{
    float3 a;                 // std140 0
    float b;                  // std140 12; a native float3 ends at 16
    float c[2];               // std140 16, stride 16
    bool d;                   // std140 48
    column_major float3x3 m;  // std140 64, three 16-byte columns
    float e;                  // std140 112
};

ConstantBuffer<Params, Std140DataLayout> params;
RWStructuredBuffer<float> output;

[numthreads(1, 1, 1)]
void computeMain()
{
    output[0] = params.a.z + params.b + params.c[1] + (params.d ? 1.0 : 0.0) + params.m[2][1] + params.e;
}

// METAL-DAG: struct _MatrixStorage_float3x3_ColMajorstd140
// METAL-DAG: array<float4, int(3)> data
// METAL-DAG: struct _Array_std140_float
// METAL-DAG: array<float4, int(2)> data

// METAL: struct Params_std140
// METAL-NEXT: {
// METAL-NEXT: packed_float3 a
// METAL-NEXT: float b
// METAL-NEXT: _Array_std140_float{{.*}} c
// METAL-NEXT: uint d
// METAL-NEXT: uint _padding
// METAL-NEXT: uint _padding
// METAL-NEXT: uint _padding
// METAL-NEXT: _MatrixStorage_float3x3_ColMajorstd140{{.*}} m
// METAL-NEXT: float e
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
// REFL: "offset": 48
// REFL: "name": "m"
// REFL: "offset": 64
// REFL: "name": "e"
// REFL: "offset": 112
