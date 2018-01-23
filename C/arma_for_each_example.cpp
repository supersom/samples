#include <iostream>
#include <armadillo>

#define TOL 1E-12

using namespace std;
using namespace arma;

void AddElem123(mat::elem_type& );
void AddVec10(vec& v);
vec MySolve(mat Rt,vec& M);


int main(int argc, char** argv){
    Mat<double> A = ones<Mat<double>>(4,5);
    Mat<double> B = ones<Mat<double>>(4,5);
    
    // add 123 to each element of A
    A.for_each( [](mat::elem_type& val) { val += 123.0; } );  // NOTE: the '&' is crucial!
    A.print("A (elem-wise):");

    // add 123 to each element of B
    B.for_each( AddElem123 );  // NOTE: the '&' is crucial!
    B.print("B (elem-wise):");

    mat C = ones<mat>(4,5);
    mat D = ones<mat>(4,5);
    
    // add 123 to each element of A
    C.each_col( [](vec& a){ a += 10; } );  // NOTE: the '&' is crucial!
    C.print("C (col-wise):");

    // add 123 to each element of B
    D.each_col( AddVec10 );  // NOTE: the '&' is crucial!
    D.print("D (col-wise):");

    int nData, nGases, nMz;
    if (argc<4){
        nData = 20;
        nMz = 10;
        nGases = 7;
    }
    else {
        nData = atoi(argv[1]);
        nMz = atoi(argv[2]);
        nGases = atoi(argv[3]);
    }

    cout << endl << endl;
    cout << "Number of data: " << nData << endl;
    cout << "Number of m/z: " << nMz << endl;
    cout << "Number of gases: " << nGases << endl;

    if (nGases>nMz) {
        cout << "ERROR> Number of gases should be fewer than m/zs. Retry..." << endl;
        return 0;
    }

    if (nGases>nData) {
        cout << "ERROR> Number of data should be more than gases. Retry..." << endl;
        return 0;
    }

    mat P(nMz,nData,fill::zeros);
    mat Q(nMz,nGases,fill::randu);
    mat R(nGases,nData,fill::randu);
    
    P = Q * R;
    
    mat Qt_hat;
    mat Pt = P.t();
    mat Rt = R.t();
    Pt.each_col([Rt,&Qt_hat](vec& v) { Qt_hat = join_rows(Qt_hat,MySolve(Rt,v)); });
    mat Q_hat = Qt_hat.t();
    mat P_hat = Q_hat * R;
    
#ifdef DEBUG
    Q_hat.print("Q_hat:");
    Q.print("Q:");
    P_hat.print("P_hat:");
    P.print("P:");
#endif

    if (all(all((P - P_hat)<TOL))) {
        cout << endl << endl;
        cout << "****************************************************" << endl;
        cout << "********************** PASS ************************" << endl;
        cout << "****************************************************" << endl;
    }
    else
        (P == P_hat).print("P == P_hat");
}

void AddElem123(mat::elem_type& val) {
    val += 123.0;
}

void AddVec10(vec& v) {
    v += 10.0;
}

vec MySolve(mat Rt, vec& p) {
    mat MMt = Rt.t()*Rt;
    vec MYt = (Rt.t()*p);
    vec d;
//    fastnnls(MtM, MtY, &d);
    d = solve(MMt,MYt);
    return d;
}