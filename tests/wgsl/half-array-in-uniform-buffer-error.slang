//DIAGNOSTIC_TEST:SIMPLE(diag=CHECK): -target wgsl -stage compute -entry computeMain

// A uniform buffer gives each element of a 16-bit array or matrix a 16-byte stride, which
// would need an 8-component vector in WGSL. Compilation fails with a diagnostic instead of
// emitting `vec8<f16>`; shaders select another type for WGSL at compile time.

//CHECK: 8-component vector not supported in WGSL
//CHECK: WGSL vectors have at most 4 components, but this buffer layout needs vectors of 8 components: a uniform buffer gives each element of a 16-bit array or matrix a 16-byte stride. Check the target at compile time and use 32-bit types or a storage buffer for this data on WGSL.

struct Params
{
    half weights[3];
    half2x2 transform;
    float scale;
};

ConstantBuffer<Params> gParams;
RWStructuredBuffer<float> gOut;

[numthreads(1, 1, 1)]
void computeMain(uint3 tid: SV_DispatchThreadID)
{
    gOut[0] = float(gParams.weights[2]) * float(gParams.transform[1][1]) * gParams.scale;
}
