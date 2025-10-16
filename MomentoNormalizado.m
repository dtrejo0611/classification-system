function npq=MomentoNormalizado(upq,u00,p,q)
    if (p+q)>=2
        d=((p+q)/2)+1;
    else
        d=1;
    end
    npq = upq/(u00^d);
end