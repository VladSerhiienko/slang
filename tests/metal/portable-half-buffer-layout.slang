//TEST:SIMPLE(filecheck=MSL): -target metal -stage compute -entry computeMain
//TEST:SIMPLE(filecheck=AIR): -target metallib -stage compute -entry computeMain
//TEST:SIMPLE(filecheck=AIR): -target metallib -stage compute -entry computeMain -DROW_MAJOR=1
//TEST:REFLECTION(filecheck=REFL): -target metal -stage compute -entry computeMain

#include "../compute/portable-half-buffer-layout.slang"

// MSL-NOT: half8
// MSL-DAG: ushort _padding
// MSL-DAG: packed_half3
// MSL-DAG: struct {{.*}}StridedStorage
// MSL-NOT: half8
// AIR: define void @computeMain
// REFL: "name": "a"
// REFL: "offset": 0
// REFL: "name": "b"
// REFL: "offset": 8
// REFL: "name": "c"
// REFL: "offset": 14
// REFL: "name": "d"
// REFL: "offset": 16
// REFL: "name": "m"
// REFL: "offset": 48
// REFL: "name": "tail"
// REFL: "offset": 96
