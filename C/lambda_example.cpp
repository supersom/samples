#include <iostream>

using namespace std;

auto Identity = [](auto x) {
  return x;
};

auto identityf = [](auto x) {
  return [=]() { return x; };
};

int main(int argc, char** argv) {
    if(argc<2) {
        cout << Identity(3) << endl;
        cout << identityf(5)() << endl; // 5
    }
    else {
        cout << Identity(atoi(argv[1])) << endl;    
        cout << identityf(atoi(argv[1])+2)() << endl;
    }
}
