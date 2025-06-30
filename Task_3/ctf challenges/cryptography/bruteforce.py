#public parameters
p = 1000003
g = 2



A = int(input('enter public key 1: '))
B = int(input('enter public key 2: '))

def brute_force(g, public_key, p):
    for x in range(1, p):
        if pow(g, x, p) == public_key:
            return x
    return None

#Brute Force to Recover Private Keys
recovered_a = brute_force(g, A, p)
recovered_b = brute_force(g, B, p)

print("Recovered private keys:")
print(f"  a = {recovered_a} (for A = {A})")
print(f"  b = {recovered_b} (for B = {B})")

secret = pow(B, recovered_a, p)
print(f"Recovered shared secret: {secret}")
