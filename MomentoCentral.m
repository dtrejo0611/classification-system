function upq=MomentoCentral(f,p,q,xc,yc)
    [filas, columnas]=size(f);
    [X,Y] = meshgrid(1:columnas,1:filas);
    upq = sum(sum(((X-xc).^p).*((Y-yc).^q).*f));
end