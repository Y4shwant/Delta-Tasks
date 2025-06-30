import random

#Common Public Parameters 
p = 1000003  
g = 2   

#Private Keys
a = random.randint(2, p - 2)  
b = random.randint(2, p - 2)  

#Compute Public Keys
A = pow(g, a, p)  
B = pow(g, b, p)  

#Compute Shared Secret
shared_secret_alice = pow(B, a, p)
shared_secret_bob = pow(A, b, p)

#Output
print(f"Public parameters:\n  p = {p}\n  g = {g}")
print(f"\nPrivate keys:\n  Alice's a = {a}\n  Bob's b = {b}")
print(f"\nPublic keys:\n  Alice's A = {A}\n  Bob's B = {B}")
print(f"\nShared secrets:\n  Alice's = {shared_secret_alice}\n  Bob's = {shared_secret_bob}")

#Veerify
assert shared_secret_alice == shared_secret_bob, "Key mismatch!"
print("\n Shared secret verified: Key exchange successful.")
