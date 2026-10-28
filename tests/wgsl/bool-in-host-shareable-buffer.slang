//TEST:SIMPLE(filecheck=WGSL): -target wgsl -stage compute -entry computeMain

// WGSL `bool` is not host-shareable, so uniform and storage buffers store
// `bool` members as `u32` (4 bytes, as every buffer layout rule assigns) and
// convert on access. Emitting `bool` there is rejected by WebGPU.

struct Params
{
    float a;
    bool flag;
    bool2 flags;
};

ConstantBuffer<Params> params;
RWStructuredBuffer<Params> records;
RWStructuredBuffer<float> output;

[numthreads(1, 1, 1)]
void computeMain()
{
    output[0] = (params.flag ? 1.0 : 0.0) + (params.flags.y ? 2.0 : 0.0) + (records[0].flag ? 4.0 : 0.0);
}

// WGSL-NOT: : bool,
// WGSL-NOT: : vec2<bool>,
// WGSL-DAG: flag_0 : u32
// WGSL-DAG: flags_0 : vec2<u32>
