// A half field can leave subword padding, and std140 half arrays/matrix
// columns have a 16-byte stride without a buffer-storable Metal half8 type.
// Read one std140 byte image, copy its logical value into element 1 of a
// std430 structured buffer, then read every stored member after a barrier.
//TEST(compute):COMPARE_COMPUTE_EX(filecheck-buffer=BUF):-mtl -compute -shaderobj -output-using-type
//TEST(compute):COMPARE_COMPUTE_EX(filecheck-buffer=BUF):-mtl -compute -shaderobj -output-using-type -xslang -DROW_MAJOR=1

#ifndef ROW_MAJOR
#define ROW_MAJOR 0
#endif

struct Params
{
    half a;                  // std140/std430 0
    half3 b;                 // 8
    half c;                  // 14
    half d[2];               // std140 16/32; std430 16/18
#if ROW_MAJOR
    row_major half3x3 m;
#else
    column_major half3x3 m;  // std140 48, stride 16; std430 24, stride 8
#endif
    half2 tail;              // std140 96 (size 112); std430 48 (stride 56)
};

//TEST_INPUT:cbuffer(data=[15360 0 1107312640 1157645312 17920 0 0 0 18176 0 0 0 1249921280 19456 0 0 1258310016 19520 0 0 1266698752 19584 0 0 1304448384 0 0 0]):name params
ConstantBuffer<Params, Std140DataLayout> params;
//TEST_INPUT:ubuffer(data=[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0], stride=56):name records
RWStructuredBuffer<Params, Std430DataLayout> records;
//TEST_INPUT:ubuffer(data=[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0], stride=4):out,name output
RWStructuredBuffer<uint> output;

void dump(uint base, Params p)
{
    output[base + 0] = uint(p.a);
    output[base + 1] = uint(p.b.x);
    output[base + 2] = uint(p.b.y);
    output[base + 3] = uint(p.b.z);
    output[base + 4] = uint(p.c);
    output[base + 5] = uint(p.d[0]);
    output[base + 6] = uint(p.d[1]);
    for (int r = 0; r < 3; ++r)
        for (int c = 0; c < 3; ++c)
#if ROW_MAJOR
            // The same byte image represents the transpose in row-major layout.
            output[base + 7 + r * 3 + c] = uint(p.m[c][r]);
#else
            output[base + 7 + r * 3 + c] = uint(p.m[r][c]);
#endif
    output[base + 16] = uint(p.tail.x);
    output[base + 17] = uint(p.tail.y);
}

[numthreads(1, 1, 1)]
void computeMain()
{
    dump(0, params);
    Params p = params;
    p.a += 100;
    p.b += 100;
    p.c += 100;
    p.d[0] += 100;
    p.d[1] += 100;
    p.m += 100;
    p.tail += 100;
    records[1] = p;
    records[1].m[1] = p.m[1];
    records[1].m[1][1] += 1;
    DeviceMemoryBarrier();
    dump(18, records[1]);
}

// BUF: 1
// BUF-NEXT: 2
// BUF-NEXT: 3
// BUF-NEXT: 4
// BUF-NEXT: 5
// BUF-NEXT: 6
// BUF-NEXT: 7
// BUF-NEXT: 10
// BUF-NEXT: 11
// BUF-NEXT: 12
// BUF-NEXT: 13
// BUF-NEXT: 14
// BUF-NEXT: 15
// BUF-NEXT: 16
// BUF-NEXT: 17
// BUF-NEXT: 18
// BUF-NEXT: 22
// BUF-NEXT: 23
// BUF-NEXT: 101
// BUF-NEXT: 102
// BUF-NEXT: 103
// BUF-NEXT: 104
// BUF-NEXT: 105
// BUF-NEXT: 106
// BUF-NEXT: 107
// BUF-NEXT: 110
// BUF-NEXT: 111
// BUF-NEXT: 112
// BUF-NEXT: 113
// BUF-NEXT: 115
// BUF-NEXT: 115
// BUF-NEXT: 116
// BUF-NEXT: 117
// BUF-NEXT: 118
// BUF-NEXT: 122
// BUF-NEXT: 123
