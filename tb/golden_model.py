# golden_model.py — Python golden reference for the CNN accelerator
# Mirrors RTL: valid 3x3 conv (stride 1) -> ReLU -> round+shift+sat formatter.
# Usage:
#   python golden_model.py --kernel kernel.hex --image image.hex \
#                          --out expected.hex [--k 3] [--shift 1] [--round 1] [--relu 1]
# File formats (simple hex, one value per line):
#   kernel.hex : K*K lines, 8-bit hex (two's complement for negative coeffs), row-major
#   image.hex  : H*W lines, 8-bit hex (unsigned pixel), row-major
#   expected.hex (output): (H-K+1)*(W-K+1) lines, 16-bit hex (two's complement), row-major
# Image dims are passed explicitly (default 32x32 to match conv_pkg).
import argparse

def to_signed(val, bits):
    val &= (1 << bits) - 1
    if val >= (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def to_unsigned(val, bits):
    return val & ((1 << bits) - 1)

def load_hex(path):
    vals = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            vals.append(int(line, 16))
    return vals

def golden(image, kernel, H, W, K, shift_amt=1, round_en=1, relu_en=1):
    OH, OW = H - K + 1, W - K + 1
    out = []
    for r in range(OH):
        for c in range(OW):
            acc = 0
            for kr in range(K):
                for kc in range(K):
                    px = image[(r + kr) * W + (c + kc)]          # unsigned 8b
                    cf = to_signed(kernel[kr * K + kc], 8)       # signed 8b
                    acc += px * cf
            # ReLU
            if relu_en and acc < 0:
                acc = 0
            # rounding bias then arithmetic shift (>>> in RTL)
            if round_en and shift_amt != 0:
                acc = acc + (1 << (shift_amt - 1))
            # Python >> on ints is arithmetic (floor), matches RTL >>> 
            acc = acc >> shift_amt if shift_amt != 0 else acc
            # saturate to signed 16-bit
            if acc > 32767:
                acc = 32767
            elif acc < -32768:
                acc = -32768
            out.append(to_unsigned(acc, 16))
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kernel", required=True)
    ap.add_argument("--image", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--img-h", type=int, default=32)
    ap.add_argument("--img-w", type=int, default=32)
    ap.add_argument("--k", type=int, default=3)
    ap.add_argument("--shift", type=int, default=1)
    ap.add_argument("--round", type=int, default=1)
    ap.add_argument("--relu", type=int, default=1)
    a = ap.parse_args()

    k_raw = load_hex(a.kernel)
    i_raw = load_hex(a.image)
    assert len(k_raw) == a.k * a.k, f"kernel len {len(k_raw)} != {a.k*a.k}"
    assert len(i_raw) == a.img_h * a.img_w, f"image len {len(i_raw)} != {a.img_h*a.img_w}"

    exp = golden(i_raw, k_raw, a.img_h, a.img_w, a.k, a.shift, a.round, a.relu)
    with open(a.out, "w") as f:
        for v in exp:
            f.write(f"{v:04x}\n")
    print(f"golden_model: wrote {len(exp)} outputs -> {a.out}")

if __name__ == "__main__":
    main()
