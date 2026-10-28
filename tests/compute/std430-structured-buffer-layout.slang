// A `StructuredBuffer<T, Std430DataLayout>` (and its read-write variant) has the
// std430 byte layout on every target, so one host-side byte image feeds it and
// one host-side structure reads it back. HLSL structured buffers pack members
// with their scalar alignment and Metal sizes vectors to a power of two, so most
// of these members would otherwise move; the comments give each std430 offset.
// The shader adds 100 to every number and negates the flag, so a member read
// and written back at a wrong offset cannot reproduce the expected words.

//TEST(compute, vulkan):COMPARE_COMPUTE_EX(filecheck-buffer=BUF):-vk -compute -shaderobj
//TEST(compute):COMPARE_COMPUTE_EX(filecheck-buffer=BUF):-dx12 -compute -shaderobj
//TEST(compute):COMPARE_COMPUTE_EX(filecheck-buffer=BUF):-mtl -compute -shaderobj
//TEST(compute):COMPARE_COMPUTE_EX(filecheck-buffer=BUF):-wgpu -compute -shaderobj

struct Record
{
    float a;                 // 0
    float3 b;                // 16: HLSL would pack it at 4
    float c;                 // 28: a native MSL float3 ends at 32
    float2 d;                // 32
    float e[3];              // 40, stride 4
    float3 f[2];             // 64, stride 16: HLSL packs float3 every 12 bytes
    column_major float3x3 m; // 96, columns 16 bytes apart
    float g;                 // 144
    bool h;                  // 148: MSL bool is 1 byte
    uint i;                  // 152; element stride 160
};

//TEST_INPUT:ubuffer(data=[1.0 0 0 0  2.0 3.0 4.0 5.0  6.0 7.0 8.0 9.0  10.0 0 0 0  11.0 12.0 13.0 0  14.0 15.0 16.0 0  17.0 18.0 19.0 0  20.0 21.0 22.0 0  23.0 24.0 25.0 0  26.0 1 27 0], stride=160):name input
StructuredBuffer<Record, Std430DataLayout> input;

//TEST_INPUT:ubuffer(data=[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0], stride=160):out,name output
RWStructuredBuffer<Record, Std430DataLayout> output;

[numthreads(1, 1, 1)]
void computeMain()
{
    Record r = input[0];
    r.a += 100.0;
    r.b += 100.0;
    r.c += 100.0;
    r.d += 100.0;
    for (int k = 0; k < 3; ++k)
        r.e[k] += 100.0;
    for (int k = 0; k < 2; ++k)
        r.f[k] += 100.0;
    r.m += 100.0;
    r.g += 100.0;
    r.h = !r.h;
    r.i += 100;
    output[0] = r;
}

// BUF: 42CA0000
// BUF-NEXT: 0
// BUF-NEXT: 0
// BUF-NEXT: 0
// BUF-NEXT: 42CC0000
// BUF-NEXT: 42CE0000
// BUF-NEXT: 42D00000
// BUF-NEXT: 42D20000
// BUF-NEXT: 42D40000
// BUF-NEXT: 42D60000
// BUF-NEXT: 42D80000
// BUF-NEXT: 42DA0000
// BUF-NEXT: 42DC0000
// BUF-NEXT: 0
// BUF-NEXT: 0
// BUF-NEXT: 0
// BUF-NEXT: 42DE0000
// BUF-NEXT: 42E00000
// BUF-NEXT: 42E20000
// BUF-NEXT: 0
// BUF-NEXT: 42E40000
// BUF-NEXT: 42E60000
// BUF-NEXT: 42E80000
// BUF-NEXT: 0
// BUF-NEXT: 42EA0000
// BUF-NEXT: 42EC0000
// BUF-NEXT: 42EE0000
// BUF-NEXT: 0
// BUF-NEXT: 42F00000
// BUF-NEXT: 42F20000
// BUF-NEXT: 42F40000
// BUF-NEXT: 0
// BUF-NEXT: 42F60000
// BUF-NEXT: 42F80000
// BUF-NEXT: 42FA0000
// BUF-NEXT: 0
// BUF-NEXT: 42FC0000
// BUF-NEXT: 0
// BUF-NEXT: 7F
// BUF-NEXT: 0
