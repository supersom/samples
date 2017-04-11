#include <math.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

int main()
{
    double r0 = 0.253694159325;
    double phi0 = 1.53642500801;
    
    double rfocus = 0.000451274504769;
    double phifocus = 3.35644246713;
    
    double xfocus, yfocus, temp;
    double x, y, ux, uy, uz;
    
    double zfocus = 0.102;
    double z = 0.0;
    
    xfocus = rfocus*cos(phifocus);
    yfocus = rfocus*sin(phifocus);
    
    x = r0*cos(phi0);
    y = r0*sin(phi0);
    
    temp = sqrt((x-xfocus)*(x-xfocus)+(y-yfocus)*(y-yfocus)+(z-zfocus)*(z-zfocus));
    
    ux = -(x-xfocus)/temp;
    uy = -(y-yfocus)/temp;
    uz = sqrt(1-ux*ux-uy*uy);
    
    printf("ux:%0.10f,uy:%0.10f,uz:%0.10f\n",ux,uy,uz);
}