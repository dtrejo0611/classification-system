function momentos_hu = CalcularMomentosHu(f2)

    m00 = MomentoInicial(f2,0,0);
    m01 = MomentoInicial(f2,0,1);
    m10 = MomentoInicial(f2,1,0);
    
    xc = m10 / m00;
    yc = m01 / m00;
    
    u00 = MomentoCentral(f2,0,0,xc,yc);
    u20 = MomentoCentral(f2,2,0,xc,yc);
    u02 = MomentoCentral(f2,0,2,xc,yc);
    u11 = MomentoCentral(f2,1,1,xc,yc);
    u30 = MomentoCentral(f2,3,0,xc,yc);
    u12 = MomentoCentral(f2,1,2,xc,yc);
    u21 = MomentoCentral(f2,2,1,xc,yc);
    u03 = MomentoCentral(f2,0,3,xc,yc);

    n20 = MomentoNormalizado(u20,u00,2,0);
    n02 = MomentoNormalizado(u02,u00,0,2);
    n11 = MomentoNormalizado(u11,u00,1,1);
    n30 = MomentoNormalizado(u30,u00,3,0);
    n12 = MomentoNormalizado(u12,u00,1,2);
    n21 = MomentoNormalizado(u21,u00,2,1);
    n03 = MomentoNormalizado(u03,u00,0,3);
    
    momentos_hu = [n20 + n02;
                   (n20 - n02)^2 + 4*(n11^2);
                   (n30 - 3*n12)^2 + (3*n21 - n03)^2;
                   (n30 + n12)^2 + (n21 + n03)^2;
                   (n30 - 3*n12)*(n30 + n12)*((n30 + n12)^2 - 3*(n21 + n03)^2) + ...
                   (3*n21 - n03)*(n21 + n03)*(3*(n30 + n12)^2 - (n21 + n03)^2);
                   (n20 - n02)*((n30 + n12)^2 - (n21 + n03)^2) + ...
                   4*n11*(n30 + n12)*(n21 + n03);
                   (3*n21 - n03)*(n30 + n12)*((n30 + n12)^2 - 3*(n21 + n03)^2) - ...
                   (3*n12 - n30)*(n21 + n03)*(3*(n30 + n12)^2 - (n21 + n03)^2)];
    
    momentos_hu = momentos_hu';
end
