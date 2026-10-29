//TEST:SIMPLE(filecheck=SPV): -target spirv-asm -stage compute -entry computeMain
#include "../compute/portable-int16-matrix-layout.slang"
// The signed 2x3 matrix occupies three 16-byte columns, followed by the
// unsigned 3x2 matrix. Legalizing logical matrices must not turn it into
// two 16-byte rows and move the second member to offset 32.
// SPV: OpMemberDecorate %Data_std140 0 Offset 0
// SPV: OpMemberDecorate %Data_std140 1 Offset 48
