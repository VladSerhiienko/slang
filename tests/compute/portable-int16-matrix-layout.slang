//TEST(compute):COMPARE_COMPUTE_EX(filecheck-buffer=CHECK):-mtl -compute -shaderobj -output-using-type
// Non-square integer matrices keep their column-major buffer layout while
// logical matrix loads/stores lower to Metal's supported arrays of row vectors.
struct Data
{
    column_major matrix<int16_t, 2, 3> signedMatrix;
    column_major matrix<uint16_t, 3, 2> unsignedMatrix;
};
//TEST_INPUT:cbuffer(data=[6618136 0 0 0 13170736 0 0 0 19723336 0 0 0 3932285536 60002 0 0 3997822536 61002 0 0]):name input
ConstantBuffer<Data, Std140DataLayout> input;
//TEST_INPUT:ubuffer(data=[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0], stride=32):name records
RWStructuredBuffer<Data, Std430DataLayout> records;
//TEST_INPUT:ubuffer(data=[0 0 0 0 0 0 0 0 0 0 0 0], stride=4):out,name output
RWStructuredBuffer<int> output;
[numthreads(1, 1, 1)]
void computeMain()
{
    records[1].signedMatrix = input.signedMatrix;
    records[1].unsignedMatrix = input.unsignedMatrix;
    records[1].signedMatrix[1] = vector<int16_t, 3>(-7, 123, 32767);
    records[1].unsignedMatrix[2][1] = uint16_t(65534);
    DeviceMemoryBarrier();
    for (int r = 0; r < 2; ++r)
        for (int c = 0; c < 3; ++c)
            output[r * 3 + c] = int(records[1].signedMatrix[r][c]);
    for (int r = 0; r < 3; ++r)
        for (int c = 0; c < 2; ++c)
            output[6 + r * 2 + c] = int(records[1].unsignedMatrix[r][c]);
}

// CHECK: -1000
// CHECK-NEXT: -2000
// CHECK-NEXT: -3000
// CHECK-NEXT: -7
// CHECK-NEXT: 123
// CHECK-NEXT: 32767
// CHECK-NEXT: 60000
// CHECK-NEXT: 61000
// CHECK-NEXT: 60001
// CHECK-NEXT: 61001
// CHECK-NEXT: 60002
// CHECK-NEXT: 65534
