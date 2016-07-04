#!/usr/bin/env python
import random
import numpy as np

class Coin:
    def __init__(self):
        self.face = None
    
    def toss(self):
        self.face = random.randint(0,1)
        
    def show(self):
        return self.face

class CoinSet:
    def __init__(self,nCoin):
        self.coin = np.empty(nCoin,dtype=object)
        self.result = np.empty(nCoin,dtype=bool)
        for iCoin in range(nCoin):
            self.coin[iCoin] = Coin()        
    
    def toss(self):
        for iCoin in range(len(self.coin)):
            self.coin[iCoin].toss()
            self.result[iCoin] = self.coin[iCoin].show()
        
    def show(self):
        return self.result

class CoinExpt:
    def __init__(self,nToss,nCoin):
        self.coin_set = CoinSet(nCoin)
        self.exp_res = np.empty((nToss,nCoin),dtype=np.bool)
            
    def perform(self):
        for iToss in range(len(self.exp_res)):
            self.coin_set.toss()
            self.exp_res[iToss,:] = self.coin_set.show()
    
    def FindOutcome(self):
        result = self.exp_res.all(axis=0).any()
        print "Expt outcome: ",result
        if result:
            return True
        else:
            return False
        
if __name__ == '__main__':
    def main(nExpt,nToss,nCoin):
        count=0
        for iExpt in range(nExpt):
            exp_set = CoinExpt(nToss,nCoin)
            exp_set.perform()
            if exp_set.FindOutcome():
               count = count+1
            print "\nExpt #: ",iExpt, "; count: ",count
        print "\n\nProb: ",float(count)/nExpt
        
    nExpt=10000
    nToss=10
    nCoin=1000
    main(nExpt,nToss,nCoin)
    
