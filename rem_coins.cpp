#include <iostream>
#include <random>
#include <cstdlib>
using namespace std;

int i,j,b,d;
int nexpt=10000;
int ncoin=10000;
int ntoss=3;

class experiment
{
public:
    int cointoss(int ncoin,int ntoss)
    {
        cout << "====Start experiment====" << endl;
        for(i=0;i<ntoss;i++)
        {
            b=0;      // b=Number of head
            d=0;
            for(j=0;j<ncoin;j++)
            {
                int a = rand() % 2;
                //cout << "a: " << a;
                if (a==0)
                {
                    b++;
                   //cout << "\n";
                   //cout << b;
                }
            }
            /*
            cout << "Initial coins: \n";
            cout << ncoin;
            cout << "\n";
            cout << "Number of heads:\n";
            cout << b;
            cout << "\n";
            */
            d = (ncoin) - b;
            ncoin = d ;
            /*
            cout << "Remaining coin:\n";
            cout << ncoin;
            cout << "\n";
            cout << "\n";
            */
        }
        cout << "*** Final coins remaining: " << ncoin << "***" << endl;
        return ncoin;
    }
    
};

int main()
{
    experiment ex1;
    //experiment ex2;
    float coins_rem;
    int sum=0;
    for(int i=0; i<nexpt; i++) {
        coins_rem=ex1.cointoss(ncoin,ntoss);
        sum += coins_rem;
    }
    
    cout << "avg number of coins left: " << sum/nexpt << endl;
    //experiment ex1;
    //experiment ex2;
    //ex1.cointoss(ncoin,ntoss);
    return 0;
}

