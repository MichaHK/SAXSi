function [XYc,RR]=fit_circles(LINES,XYc0)

Nl=length(LINES);
RR0=zeros(1,Nl);
for n=1:Nl
    xy=LINES(n).xy; Np=size(xy,1);
    RR0(n)=mean(sqrt(sum((xy-XYc0(ones(Np,1),:)).^2,2)));
end

par_0=[XYc0 RR0];

opt=optimset('maxfunevals',1e6,'maxiter',1e4,'display','off');
% par=fminsearch(@chi2_circles,par_0,opt);
% par_0=par;

for r=1:20
    par=fminsearch(@chi2_circles,par_0,opt);
    par_0=par;
end

XYc=par_0(1:2); RR=par_0(3:2+Nl);

function val=chi2_circles(param)
    xc=param(1); yc=param(2); rr=param(3:end);
    val=0;
    for l=1:Nl
        xy=LINES(l).xy;
        val=val+sum(abs((xy(:,1)-xc).^2+(xy(:,2)-yc).^2-rr(l)^2));
    end
end

end