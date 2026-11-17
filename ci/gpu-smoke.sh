#!/usr/bin/env bash
# The GPU profile's acceptance test, run by the `GPU smoke` workflow on one
# fresh g6.xlarge (jaws's remote-task, profile gpu): the
# GPU and CUDA work, bullet's CUDA backend builds our trainer, and the
# dataset grants hold in both directions: the positions (braveheart-selfplay's
# bucket) can be read and not written or deleted, and the nets (this
# project's) can be written but not listed beyond the grant or deleted. A few
# minutes, well under a dollar.
# Starts in the repository root at the workflow's commit, with OUT_DIR and
# SCRATCH_DIR set. Never exits 75, which the runner reserves for interruptions.

set -euo pipefail
: "${OUT_DIR:?OUT_DIR is not set}"
scratch="${SCRATCH_DIR:-/tmp}/gpu-smoke"
mkdir -p "$scratch"
positions=s3://jwall-engineering-braveheart-selfplay-positions
nets=s3://jwall-engineering-braveheart-trainer-nets
stamp=$(date -u +%Y%m%dT%H%M%SZ)
summary="$OUT_DIR/summary.txt"
: > "$summary"
pass=0 fail=0
check() {  # check NAME EXPECTED(ok|denied) COMMAND...
  local name=$1 want=$2; shift 2
  local got
  if "$@" > "$scratch/check.out" 2>&1; then got=ok; else got=denied; fi
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); echo "PASS $name: $got (expected $want)" | tee -a "$summary"
  else
    fail=$((fail + 1)); echo "FAIL $name: $got (expected $want)" | tee -a "$summary"
    tail -n 30 "$scratch/check.out" | sed 's/^/    /'
  fi
}

echo "== GPU"
nvidia-smi | tee "$OUT_DIR/nvidia-smi.txt"
nvcc --version | tee -a "$summary"

echo "== CUDA: compile and run a kernel"
cat > "$scratch/add.cu" <<'CU'
#include <cstdio>
__global__ void add(const float* a, const float* b, float* c, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) c[i] = a[i] + b[i];
}
int main() {
    const int n = 1 << 20;
    float *a, *b, *c;
    cudaMallocManaged(&a, n * sizeof(float));
    cudaMallocManaged(&b, n * sizeof(float));
    cudaMallocManaged(&c, n * sizeof(float));
    for (int i = 0; i < n; i++) { a[i] = i; b[i] = 2.0f * i; }
    add<<<(n + 255) / 256, 256>>>(a, b, c, n);
    cudaError_t e = cudaDeviceSynchronize();
    if (e != cudaSuccess) { printf("CUDA error: %s\n", cudaGetErrorString(e)); return 1; }
    for (int i = 0; i < n; i++) if (c[i] != 3.0f * i) { printf("wrong at %d\n", i); return 1; }
    printf("kernel ok: %d additions on the GPU\n", n);
    return 0;
}
CU
check "a CUDA kernel compiles with nvcc" ok nvcc -O2 -o "$scratch/add" "$scratch/add.cu"
check "the kernel runs and adds correctly" ok "$scratch/add"

echo "== bullet's CUDA backend builds the trainer"
# bullet's build script needs CUDA_PATH; the image puts nvcc on PATH but doesn't export it.
CUDA_PATH=${CUDA_PATH:-$(dirname "$(dirname "$(readlink -f "$(command -v nvcc)")")")}
export CUDA_PATH
echo "CUDA_PATH=$CUDA_PATH" | tee -a "$summary"
start=$(date +%s)
check "cargo build trainer --features cuda" ok \
  env CARGO_TARGET_DIR="$scratch/trainer-target" cargo build --release --locked --manifest-path trainer/Cargo.toml --features cuda
echo "   (build took $(( $(date +%s) - start ))s)" | tee -a "$summary"
cp "$scratch/check.out" "$OUT_DIR/trainer-build.log"

echo "== dataset grants"
# A shard of generation 0's first run, copied from the engine's bucket at the split.
run=data/selfplay/v1/gen=0/run=20261030-41007876197-1/task=t1
one=$(aws s3 ls "$positions/$run/manifests/" | awk 'NR == 1 {print $4}')
check "list the positions" ok aws s3 ls "$positions/data/selfplay/v1/gen=0/"
check "read a position shard's manifest" ok aws s3 cp --only-show-errors "$positions/$run/manifests/$one" "$scratch/"
echo "smoke test $stamp" > "$scratch/hello.txt"
check "write under the positions" denied \
  aws s3 cp --only-show-errors "$scratch/hello.txt" "$positions/data/selfplay/SMOKE-TEST-MUST-BE-DENIED-$stamp.txt"
# Deletes name keys that don't exist: S3 answers a permitted delete of a missing
# key with success, so this tests the permission without risking any data.
check "delete under the positions" denied \
  aws s3api delete-object --bucket "${positions#s3://}" --key "data/selfplay/SMOKE-TEST-NO-SUCH-KEY-$stamp"
check "write under data/nets/" ok aws s3 cp --only-show-errors "$scratch/hello.txt" "$nets/data/nets/smoke-$stamp/hello.txt"
check "list the nets bucket outside the grant" denied aws s3 ls "$nets/data/"
check "delete under data/nets/" denied \
  aws s3api delete-object --bucket "${nets#s3://}" --key "data/nets/smoke-$stamp/SMOKE-TEST-NO-SUCH-KEY"

echo "== $pass passed, $fail failed" | tee -a "$summary"
[ "$fail" = 0 ]
