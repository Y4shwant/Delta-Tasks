from math import isqrt

p = 1000003
g = 2

A = int(input("Enter public key A: "))
B = int(input("Enter public key B: "))

def modinv(a, p):
    return pow(a, p - 2, p)

def baby_step_giant_step(g, h, p):
    m = isqrt(p) + 1
    baby_steps = {}

    print(f"Precomputing baby steps up to {m}...")

    for j in range(m):
        val = pow(g, j, p)
        baby_steps[val] = j

    g_inv_m = modinv(pow(g, m, p), p)

    print("Running giant steps...")

    current = h
    for i in range(m):
        if current in baby_steps:
            j = baby_steps[current]
            print(f"Found match: i = {i}, j = {j} → x = {i * m + j}")
            return i * m + j
        current = (current * g_inv_m) % p

    return None

print("Recovering private key a...")
recovered_a = baby_step_giant_step(g, A, p)

print("Recovering private key b...")
recovered_b = baby_step_giant_step(g, B, p)

print(f"Private key a: {recovered_a}")
print(f"Private key b: {recovered_b}")

secret = pow(B, recovered_a, p)
print(f"Shared secret: {secret}")
