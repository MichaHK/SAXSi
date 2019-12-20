function [x,y]=readchifilenew (filename,igorflag)
% try
ta=readtext (filename,'[\t ,]', '', '"', 'numeric-empty2zero');
% catch
% ta=readtext (filename,'[\t ,]', '' ,'"');
% end
if length (ta) >0
ft=find (ta(:,2)>0);
len=length(ta(:,2));
lenf=length(filename);
ext=filename(lenf-3:lenf);
if ((igorflag==1) || strcmp(ext,'.dat'))
    x=ta(ft:len,1); y=ta(ft:len,2);
elseif ((igorflag==2) || strcmp(ext,'.chi'))
    x=ta(ft(1):len,2)/10; y=ta(ft(1):len,4); %(so all will be in angstrum and not in nm)
end
else
    x=[0.1 1];y=[0.1 1];
end
%removeing zeros from the data
ind=find(y>eps);
y=y(ind);x=x(ind);