# VLSI Neural Network – XOR Classifier

A fully fixed-point neural network implemented in Verilog, trained in Python and synthesised as hardware.  
The network solves the classic XOR problem using a 2-layer MLP (2 → 2 → 1).

---

## Project Structure

```
vlsi2/
├── hex/                    # Pre-trained weights & biases (Q5.11 fixed-point hex)
│   ├── W1.hex              # Input → Hidden weights  (4 values, 2×2)
│   ├── B1.hex              # Hidden biases           (2 values)
│   ├── W2.hex              # Hidden → Output weights (2 values)
│   ├── B2.hex              # Output bias             (1 value)
│   └── sigmoid_lut.hex     # Sigmoid lookup table    (256 entries)
├── src/                    # Verilog RTL source
│   ├── top_nn.v            # Top-level neural network module
│   ├── macc.v              # Multiply-Accumulate unit (2-input Q5.11)
│   ├── fixed_point.v       # Q5.11 multiplier & saturating adder
│   ├── activation_sigmoid.v# Sigmoid activation (LUT-based)
│   └── rom_loader.v        # Example weight ROM loader
├── tb/
│   └── tb_nn.v             # Testbench – drives all 4 XOR inputs
└── train_xor_to_hex.py     # Train the model & export hex weight files
```

---

## Architecture

```
        Input (2 bits)
              │
    ┌─────────▼──────────┐
    │  Q5.11 conversion  │   0 → 0x0000  /  1 → 0x0800
    └─────────┬──────────┘
              │
    ┌─────────▼──────────┐   W1 (2×2), B1 (2)
    │    Hidden layer     │   activation: sigmoid LUT
    │   (2 neurons MACC) │
    └─────────┬──────────┘
              │
    ┌─────────▼──────────┐   W2 (2×1), B2 (1)
    │    Output layer     │   activation: sigmoid LUT
    │   (1 neuron MACC)  │
    └─────────┬──────────┘
              │
         Threshold 0.5
              │
          XOR output
```

**Fixed-Point Format:** Q5.11 – 16-bit signed, 1 sign bit + 4 integer bits + 11 fractional bits.  
All arithmetic is performed in 32-bit signed to prevent overflow.

---

## Quickstart

### 1. Retrain the model (optional)

The `hex/` directory already contains pre-trained weights.  
To retrain and regenerate them:

```bash
pip install numpy
python train_xor_to_hex.py
```

This produces `hex/W1.hex`, `hex/B1.hex`, `hex/W2.hex`, `hex/B2.hex`, and `hex/sigmoid_lut.hex`.

### 2. Simulate with Icarus Verilog

```bash
# From the repo root (compile from src/ so include directives resolve correctly)
cd src && iverilog -g2005 -o ../sim.out \
    fixed_point.v \
    activation_sigmoid.v \
    macc.v \
    ../tb/tb_nn.v && cd ..

vvp sim.out
```

Expected output:

```
XOR Neural Network Simulation
==============================
IN=00  OUT_q15=0x0025  OUT_bin=0  (expected 0)  PASS
IN=01  OUT_q15=0x07db  OUT_bin=1  (expected 1)  PASS
IN=10  OUT_q15=0x07dd  OUT_bin=1  (expected 1)  PASS
IN=11  OUT_q15=0x0021  OUT_bin=0  (expected 0)  PASS
==============================
All 4 XOR test cases PASSED
Simulation finished.
```

### 3. Simulate with ModelSim / Questa

```tcl
vlog src/fixed_point.v src/activation_sigmoid.v src/macc.v tb/tb_nn.v
vsim tb_nn
run -all
```

---

## Module Reference

| Module | File | Description |
|---|---|---|
| `top_nn` | `src/top_nn.v` | Wires layers together; loads weights from hex ROMs |
| `simple_2in_macc_q15` | `src/macc.v` | `w0·in0 + w1·in1 + bias` in Q5.11 |
| `fixed_mul_q15` | `src/fixed_point.v` | Q5.11 × Q5.11 → Q5.11 (32-bit) |
| `sat_add32` | `src/fixed_point.v` | Saturating 32-bit signed adder |
| `sigmoid_lut_q15` | `src/activation_sigmoid.v` | LUT-based sigmoid, maps \[-8, 8\] → \[0, 1\] |

---

## Fixed-Point Arithmetic Details

- **Format:** Q5.11 (sign bit + 4 integer bits + 11 fractional bits, 16-bit signed)
- **Range:** −16.0 to ≈ +15.9995
- **Multiply:** `a × b` gives a 32-bit Q10.22 product; shift right 11 bits to restore Q5.11
- **Bias add:** 16-bit bias is sign-extended to 32 bits before addition
- **Sigmoid LUT:** 256 uniformly-spaced entries covering \[−8, +8\]; index clamped to \[0, 255\]

---

## License

MIT
