#include <iostream>
#include <string>
#include <vector>
#include <math.h>
#include <stdlib.h>

using namespace std;
/*
int main(int argc, char** argv) {
    string pattern="HT";
    cout<<pattern<<endl;
    //int a = 1;
    //cout<<a;
}
*/

double expectedTime(string, double);  ///example pattern: "TTH" , p = 0.5

double expectedTime(string pattern, double p)  ///example pattern: "TTH" , p = 0.5
{
    vector<int> partial_sum;
    vector<int> num_heads;
    int heads = 0;
    int sum = 0;
    double expected_toss = 0;
    
    for(int i=0;i<pattern.size();++i,partial_sum.push_back(sum), num_heads.push_back(heads))
        if(pattern[pattern.size()-i-1]=='H'||pattern[pattern.size()-i-1]=='h')
        {
            sum+=pow(2,i);
            heads++;
        }
    
    for(int i=0;i<pattern.size();++i,sum/=2)
        if(sum==partial_sum[pattern.size()-i-1])
            expected_toss+=pow(1/p,num_heads[pattern.size()-i-1])*pow(1/(1-p),pattern.size()-i-num_heads[pattern.size()-i-1]);
    
    return expected_toss;
}

int main(int argc, char** argv) {
    string pattern="HH";
    double p=1.0/2;
    cout<<expectedTime(pattern,p)<<endl;
}
