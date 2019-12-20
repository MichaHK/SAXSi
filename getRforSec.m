function rout=getRforSec(x,y,scannum)

rn=[mean(x),mean(y)];
scanvec = ((-scannum/2):scannum/2)/scannum;
 % get the length of this vector
sizescan = max(size(scanvec));
tt=[diff(x),diff(y)];    
normal = [tt(1),tt(2)];    
rscanvec = zeros(sizescan,2); %#ok<NASGU>
rout = scanvec'*normal + ones(sizescan,1)*rn;
%rout = scanvec + ones(sizescan,1)*rn;