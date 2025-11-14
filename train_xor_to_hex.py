# tools/train_xor_to_hex.py
import numpy as np
from pathlib import Path

np.random.seed(42)

# XOR dataset
X = np.array([[0,0],[0,1],[1,0],[1,1]], dtype=float)
y = np.array([[0],[1],[1],[0]], dtype=float)

# network size
in_dim = 2
hid_dim = 2
out_dim = 1

# initialize
W1 = np.random.randn(in_dim, hid_dim) * 1.0
b1 = np.zeros((1, hid_dim))
W2 = np.random.randn(hid_dim, out_dim) * 1.0
b2 = np.zeros((1, out_dim))

def sigmoid(x): return 1.0/(1.0+np.exp(-x))
def tanh(x): return np.tanh(x)

lr = 0.1
epochs = 10000

for epoch in range(epochs):
    z1 = X.dot(W1) + b1
    a1 = tanh(z1)
    z2 = a1.dot(W2) + b2
    a2 = sigmoid(z2)
    loss = np.mean((a2 - y)**2)

    dz2 = (a2 - y) * (a2*(1-a2))
    dW2 = a1.T.dot(dz2)
    db2 = np.sum(dz2, axis=0, keepdims=True)
    da1 = dz2.dot(W2.T)
    dz1 = da1 * (1 - a1**2)
    dW1 = X.T.dot(dz1)
    db1 = np.sum(dz1, axis=0, keepdims=True)

    W2 -= lr * dW2
    b2 -= lr * db2
    W1 -= lr * dW1
    b1 -= lr * db1

# Q1.15 fixed-point conversion
scale = 2**15
def to_q15(x):
    x_clipped = np.clip(x, -1.0, 0.999969482421875)
    intval = np.round(x_clipped * scale).astype(np.int32)
    intval16 = (intval & 0xFFFF).astype(np.uint16)
    return intval16

# store W1 as column-major of W1.T.flatten() so ROM is [w_h0_in0, w_h0_in1, w_h1_in0, ...]
W1_q = to_q15(W1).T.flatten()
B1_q = to_q15(b1).flatten()
W2_q = to_q15(W2).T.flatten()
B2_q = to_q15(b2).flatten()

out_dir = Path('hex')
out_dir.mkdir(exist_ok=True)

def write_hex(arr, fname):
    path = out_dir / fname
    with open(path, 'w') as f:
        for val in arr:
            f.write(f"{val:04x}\n")
    return path

write_hex(W1_q, 'W1.hex')
write_hex(B1_q, 'B1.hex')
write_hex(W2_q, 'W2.hex')
write_hex(B2_q, 'B2.hex')

# sigmoid LUT (256 entries) mapping inputs [-8,8] -> sigmoid(x) in Q1.15
lut_size = 256
x_lut = np.linspace(-8, 8, lut_size)
sig_lut = sigmoid(x_lut)
sig_lut_q = to_q15(sig_lut)
write_hex(sig_lut_q, 'sigmoid_lut.hex')

print("W1, B1, W2, B2, sigmoid_lut written to ./hex/")