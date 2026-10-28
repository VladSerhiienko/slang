// A `ConstantBuffer<T, Std140DataLayout>` has the std140 byte layout on every
// target, so one host-side byte image feeds it everywhere. HLSL (FXC packing)
// and Metal (native vector sizes) would otherwise place most of these members
// at different offsets; the comments give the std140 offset of each member.

//TEST(compute, vulkan):COMPARE_COMPUTE_EX(filecheck-buffer=BUF):-vk -compute -shaderobj -output-using-type
//TEST(compute):COMPARE_COMPUTE_EX(filecheck-buffer=BUF):-dx12 -compute -shaderobj -output-using-type
//TEST(compute):COMPARE_COMPUTE_EX(filecheck-buffer=BUF):-mtl -compute -shaderobj -output-using-type
//TEST(compute):COMPARE_COMPUTE_EX(filecheck-buffer=BUF):-wgpu -compute -shaderobj -output-using-type

struct Light
{
    float3 position; // 0 (in Light)
    float radius;    // 12
};

struct Params
{
    float a;                   // 0
    float3 b;                  // 16: FXC packs it at 4
    float c;                   // 28: a native MSL float3 ends at 32
    float d[2];                // 32, stride 16
    float e;                   // 64: FXC packs it into the last array register
    column_major float3x3 m;   // 80, three 16-byte columns
    float f;                   // 128: FXC packs it after the unpadded last column
    bool g;                    // 132: MSL bool is 1 byte
    Light l;                   // 144
    float h;                   // 160
    float2 i;                  // 168: FXC packs it at 164
};

// Each value is stored at the std140 offset of its member (words = offset / 4):
// a=1 @0, b=2,3,4 @16, c=5 @28, d=6 @32 and 7 @48, e=8 @64,
// m columns @80/96/112 hold m[r][c] = 10 + 3r + c, f=19 @128, g=1 @132,
// l.position=20,21,22 @144, l.radius=23 @156, h=24 @160, i=25,26 @168.
//TEST_INPUT:cbuffer(data=[1.0 0 0 0  2.0 3.0 4.0 5.0  6.0 0 0 0  7.0 0 0 0  8.0 0 0 0  10.0 13.0 16.0 0  11.0 14.0 17.0 0  12.0 15.0 18.0 0  19.0 1 0 0  20.0 21.0 22.0 23.0  24.0 0 25.0 26.0]):name params
ConstantBuffer<Params, Std140DataLayout> params;

//TEST_INPUT:ubuffer(data=[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0], stride=4):out,name output
RWStructuredBuffer<uint> output;

[numthreads(1, 1, 1)]
void computeMain()
{
    output[0] = uint(params.a);
    output[1] = uint(params.b.x);
    output[2] = uint(params.b.y);
    output[3] = uint(params.b.z);
    output[4] = uint(params.c);
    output[5] = uint(params.d[0]);
    output[6] = uint(params.d[1]);
    output[7] = uint(params.e);
    for (int r = 0; r < 3; ++r)
        for (int c = 0; c < 3; ++c)
            output[8 + r * 3 + c] = uint(params.m[r][c]);
    output[17] = uint(params.f);
    output[18] = params.g ? 1u : 0u;
    output[19] = uint(params.l.position.x);
    output[20] = uint(params.l.position.y);
    output[21] = uint(params.l.position.z);
    output[22] = uint(params.l.radius);
    output[23] = uint(params.h);
    output[24] = uint(params.i.x);
    output[25] = uint(params.i.y);
}

// BUF: 1
// BUF-NEXT: 2
// BUF-NEXT: 3
// BUF-NEXT: 4
// BUF-NEXT: 5
// BUF-NEXT: 6
// BUF-NEXT: 7
// BUF-NEXT: 8
// BUF-NEXT: 10
// BUF-NEXT: 11
// BUF-NEXT: 12
// BUF-NEXT: 13
// BUF-NEXT: 14
// BUF-NEXT: 15
// BUF-NEXT: 16
// BUF-NEXT: 17
// BUF-NEXT: 18
// BUF-NEXT: 19
// BUF-NEXT: 1
// BUF-NEXT: 20
// BUF-NEXT: 21
// BUF-NEXT: 22
// BUF-NEXT: 23
// BUF-NEXT: 24
// BUF-NEXT: 25
// BUF-NEXT: 26
