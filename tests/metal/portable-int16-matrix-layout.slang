//TEST:SIMPLE(filecheck=MSL): -target metal -stage compute -entry computeMain
//TEST:SIMPLE(filecheck=AIR): -target metallib -stage compute -entry computeMain
#include "../compute/portable-int16-matrix-layout.slang"
// MSL-NOT: matrix<short
// MSL-NOT: matrix<ushort
// MSL: void computeMain
// AIR: define void @computeMain
