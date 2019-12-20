function Error=Error_on_Lines_theta(parameters,LINES,W)

Error=0;
Nl=length(LINES);
for l=1:Nl

    theta=(LINES(l).theta);
    xy=[LINES(l).xy];
    
    theta_theor=Theta_xy(xy,parameters);
    
    Error=Error+sum(abs(theta-theta_theor))*W(l);
    
end

