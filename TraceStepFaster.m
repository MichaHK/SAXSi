function [success, rn,tt,X] = TraceStepFaster(r,tt,data,stepsize,scansize,scannum,maxiter)

data(data < 0) = -inf;

pixelsize = 1;

scannum = scannum / 2;
tt = tt / norm(tt);
flagit = 0;
fitstTT=tt;

muNewZ = 0;
muNewX = nan;
muNewY = nan;
X = zeros(1,5);

if (maxiter<0)
    maxiter2=-maxiter;
    %a flag to use when init
else
    maxiter2=maxiter;
end

for a=1:maxiter2

    % use the last tangent to guess the position
    % of the next point distance stepsize away.
    rn = r+tt*stepsize;
    %  plot(rn(1)+.5,rn(2)+.5,'w.');


    % compute a normal to the tangent
    normal = [tt(2),-tt(1)];

    % and project the data onto a segment defined
    % by scanvec. scanvec is a vector with the
    % distance at which the the data will be interpolated
    % on the normal...
    scanvec = ((-scannum):scannum)/scannum*(scansize / 2);

    % get the length of this vector
    sizescan = max(size(scanvec));

    % now make the point at which we wish to interp
    % the data. They are at the guessed position normal
    % to the curve with the spacing given by scanvec.
    rscanvec = zeros(sizescan,2); %#ok<NASGU>
    rscanvec = scanvec'*normal + ones(sizescan,1)*rn;


    %rscanvec = floor(rscanvec);
    yy=rscanvec(:,2);
    xx=rscanvec(:,1);

    xx0 = min(xx);
    yy0 = min(yy);
    
    xxMax = max(xx);
    yyMax = max(yy);

    xx = xx - xx0 + 1;
    yy = yy - yy0 + 1;

    k = 5;
    dataBig = data(yy0:yyMax+1, xx0:xxMax+1);
    dataBig = kron(dataBig, ones(k));
    dataBig = conv2(dataBig, gausswin(5) * gausswin(5)', 'same');
    dataBig = conv2(dataBig, gausswin(3 + k) * gausswin(3 + k)', 'same');
    dataBig = conv2(dataBig, gausswin(5) * gausswin(5)', 'same');
    dataBig = conv2(dataBig, [0, 0, 1; 0, 1, 0; 1, 0, 0], 'same');
    %figure; imagesc(dataBig);
    %figure; surface(dataBig);
    
    xx = floor(k * xx);
    yy = floor(k * yy);
    
    z = dataBig(xx * size(dataBig, 1) + yy);
    [v, i] = max(z);
    rn = [xx0 + xx(i) / k, yy0 + yy(i) / k]


    % to give a new guess for the position of the curve...
    % but this new point does not lie at the right distance
    % so we will compute the tangent only... which in turn
    % will update the the r guess... then we iterate to improve
    % the guess
    if ((maxiter>0) || (maxiter2>1))
        tt = (rn.*pixelsize-r);
        tt = tt/norm(tt);
        rn = r + tt * stepsize;
    else
        rn = rn .* pixelsize;
    end
    %     disp ('steping to')
    %     disp (rn)
end

if (0)
    zWO=z-polyval(X(4:5),za);
    if ~flagSavePlots
        za=(za-X(2)).*pixelsize*1e3;  %convert to nm;
    else
        za=(za).*pixelsize*1e3;
    end
    
    X(2)=X(2).*pixelsize*1e3; %convert to nm
    X(3)=X(3).*pixelsize*1e3; %convert to nm
    X(4)=X(4)./pixelsize;
    
    if (sum(z)/length(z)<(1e-3))
        %Asylum
        X(1)=X(1)*1e9; %converet to nm
        z=z*1e9;
        zfit=zfit*1e9;
        zWO=zWO*1e9;
    else
        %Vecco
        
        %     disp ('check me trace step 104');
    end
    X = [X trapz(za,zWO)];
end

if (0)
    axes (csaxes);
    hold off
    plot (za,z,'o',za,zfit,'-r');%za,zWO,'-k');
    axis tight
end

% if flagSavePlots
%     fid=fopen (SavePlotsName,'w+');
%     outza=[za,z,zfit];
%     fprintf (fid,'r\t Data\t Fit \n');
%     fprintf (fid,'%g \t %g \t %g \n',outza');
%     fclose (fid);
% end
    
%rn=rn.*pixelsize;

success = 1;

% make the next point equal to the guess... which is now pretty
% good since we interated it...
mt=abs(atan2(fitstTT(2),fitstTT(1))-atan2(tt(2),tt(1)));

if (flagit || (min(mt,2*pi-mt)>pi/2))
    rn=-178889789;
%     disp ('no fit --> automatic stop...');
    beep
    success = 0;
end
    
