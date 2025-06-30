#!/usr/bin/env python3
from z3 import *

LEN = 30
SECRET_VALUE = 315525

chars = [BitVec(f'c{i}', 8) for i in range(LEN - 1)]
s = Solver()

val = BitVecVal(0, 32)

for i in range(LEN - 1):  
    c = chars[i]
    s.add(And(c >= 32, c <= 126, c!=10))  

    c_ext = SignExt(24, c) 
    i32 = BitVecVal(i, 32)

    expr = (
        (c_ext * c_ext)
        + (c_ext * BitVecVal(100 - i, 32))
        + i32
        + (c_ext * BitVecVal(7, 32))
        + ((c_ext | i32) & (i32 + BitVecVal(3, 32)))
        - URem(c_ext * c_ext, i32 + BitVecVal(1, 32))
    )
    val += expr

i = 29
c_ext = BitVecVal(0, 32)
i32 = BitVecVal(i, 32)

expr = (
    (c_ext * c_ext)
    + (c_ext * BitVecVal(100 - i, 32))
    + i32
    + (c_ext * BitVecVal(7, 32))
    + ((c_ext | i32) & (i32 + BitVecVal(3, 32)))
    - URem(c_ext * c_ext, i32 + BitVecVal(1, 32))
)
val += expr

# Constraint: total must match C program output
s.add(val == SECRET_VALUE)

# Solve
if s.check() == sat:
    m = s.model()
    string = ''.join([chr(m[c].as_long()) for c in chars])
    print("Valid string :", string)
else:
    print("No solution found.")
