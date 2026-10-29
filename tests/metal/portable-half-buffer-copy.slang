//TEST:SIMPLE(filecheck=AIR): -target metallib -stage compute -entry computeMain
#include "../compute/portable-half-buffer-copy.slang"
// AIR: define void @computeMain
