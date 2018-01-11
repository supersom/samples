#!/usr/bin/env python

import numpy as np
import time

from numba import vectorize, cuda

@vectorize(['float32(float32, float32)'], target='parallel')
def VectorAdd(a, b):
    N=2000
    c=0
    # c=a+b
    for i in range(N):
        c=c+a
        c=c+b
    # c=c*c
    # c=c+a
    # c=c+b
    # c=c*c
    return c
#    return a + b

def main():
    N = 320000000

    A = np.ones(N, dtype=np.float32)
    B = np.ones(N, dtype=np.float32)

    start = time.time()
    C = VectorAdd(A, B)
    vector_add_time = time.time() - start

    print "C[:5] = " + str(C[:5])
    print "C[-5:] = " + str(C[-5:])

    print "VectorAdd took for % seconds" % vector_add_time

if __name__=='__main__':
    main()
