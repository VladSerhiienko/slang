//TEST(compute):COMPARE_COMPUTE_EX(filecheck-buffer=CHECK):-mtl -compute -shaderobj -output-using-type
// A direct whole-struct copy crosses distinct physical storage layouts: std140
// pads both the scalar array and the matrix columns, while std430 packs them.
struct Data
{
    half values[2];
    column_major half2x2 transform;
    half tail;
};
//TEST_INPUT:cbuffer(data=[15360 0 0 0 49408 0 0 0 1157644800 0 0 0 1174422528 0 0 0 50944 0 0 0]):name input
ConstantBuffer<Data, Std140DataLayout> input;
//TEST_INPUT:ubuffer(data=[0 0 0 0 0 0 0 0 0 0 0 0], stride=16):name records
RWStructuredBuffer<Data, Std430DataLayout> records;
//TEST_INPUT:ubuffer(data=[0 0 0 0 0 0 0], stride=4):out,name output
RWStructuredBuffer<float> output;
[numthreads(1, 1, 1)]
void computeMain()
{
    records[1] = input;
    DeviceMemoryBarrier();
    output[0] = float(records[1].values[0]);
    output[1] = float(records[1].values[1]);
    for (int r = 0; r < 2; ++r)
        for (int c = 0; c < 2; ++c)
            output[2 + r * 2 + c] = float(records[1].transform[r][c]);
    output[6] = float(records[1].tail);
}
// CHECK: 1
// CHECK-NEXT: -2.5
// CHECK-NEXT: 3
// CHECK-NEXT: 4
// CHECK-NEXT: 5
// CHECK-NEXT: 6
// CHECK-NEXT: -7
