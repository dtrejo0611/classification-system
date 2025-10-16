function mpq=MomentoInicial(f,p,q)
    [filas, columnas]=size(f);
    [X,Y] = meshgrid(1:columnas,1:filas);
    mpq = sum(sum((X.^p).*(Y.^q).*f));
end