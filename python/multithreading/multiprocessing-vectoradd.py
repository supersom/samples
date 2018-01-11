#!/usr/bin/env python

import numpy as np
import time
import multiprocessing as mp

from numba import vectorize, cuda

def VectorAdd(a, b):
    N=2000
    c=0
    for i in range(N):
        c=c+a
        c=c+b
    return c

def VectorAddDriver():
    N = 3200000
    A = np.ones(N, dtype=np.float32)
    B = np.ones(N, dtype=np.float32)

    C = VectorAdd(A, B)
    return C

def multiprocess(processes, iters):
    pool = mp.Pool(processes=processes)
    results = [pool.apply_async(VectorAddDriver, args=()) for i in iters]
    results = [p.get() for p in results]
    # results.sort() # to sort the results by input window width
    return results
    

def main():
    M = 100
    N = 3200000
    nProcesses=20
    C = np.zeros((M,N), dtype=np.float32)
    start = time.time()
    # for i in range(M):
        # print "Calling VectorAddDriver() for the {}th time".format(i)
    results = multiprocess(nProcesses, range(M))
    # C = VectorAddDriver()
    # if not np.mod(i,10):
    #     print "C[i,:5] = " + str(C[i,:5])
    #     print "C[i,-5:] = " + str(C[i,-5:])

    # print "C[:5,:5] = " + str(C[i,:5])
    # print "C[-5:,-5:] = " + str(C[i,-5:])
    print "multiprocess results: ", results            
    vector_add_time = time.time() - start
    print "VectorAdd took for % seconds" % vector_add_time

if __name__=='__main__':
    main()

