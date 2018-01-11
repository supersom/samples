#!/usr/bin/env python

from numba import vectorize, int32
import numpy as np

@vectorize(['float32[:](int32[:], int32[:])'], target='parallel', nopython=True) 
def VectorAdd(a, b):
    N=2000
    c=0
    for i in range(N):
        c=c+a
        c=c+b
    return c

if __name__ == '__main__':
    l=5000000
    a=np.ones(l)
    b=np.ones(l)
    VectorAdd(a,b)
    # print "c: ",c
    