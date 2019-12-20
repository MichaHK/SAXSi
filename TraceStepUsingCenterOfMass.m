function [success, rn,tt,X] = TraceStepUsingCenterOfMass(r,tt,data,stepsize,scansize,scannum,maxiter,sigmasInsideThreshold)

data(data < 0) = -inf;

pixelsize = 1;

if (nargin < 8)
    sigmasInsideThreshold = 1;
end

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
% disp ('strating from');
% disp (r)
%[scansize,scannum]
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

    % fit to a gaussian
    %yy=(rscanvec(:,2)./pixelsize);
    %xx=(rscanvec(:,1)./pixelsize);
    
    yy=rscanvec(:,2);
    xx=rscanvec(:,1);
    z = interp2(1:size(data, 1), 1:size(data, 2), data', yy, xx, 'nearest');

    if (1)
        rscanvec = scanvec'*normal + ones(sizescan,1)*(rn + 1);
        z = z + interp2(1:size(data, 1), 1:size(data, 2), data', ...
            rscanvec(:,2), rscanvec(:,1), 'nearest');

%         rscanvec = scanvec'*normal + ones(sizescan,1)*(rn - 1);
%         z = z + interp2(1:size(data, 1), 1:size(data, 2), data', ...
%             rscanvec(:,2), rscanvec(:,1), 'linear');
    end
    
    if (any(z < 0 | isnan(z)))
        success = 0;
        return;
    end

    za=sqrt((xx-xx(1)).^2+(yy-yy(1)).^2);

    try
        % test code
        if (0)
            tStarted = tic;
            
%             figure;
%             plot(za, z, '-k');
%             z(z<0.1*max(z)) = 0;
%             plot(za, z, '-k');
%             hold on;
            
        end

        if (0)
            gaussFit = fit(za, z, fittype('gauss1'));
            
            a = gaussFit.a1;
            b = gaussFit.b1;
            c = gaussFit.c1;
        else
            rnn = z'*rscanvec;
            
            % and dividing by the sum of the z's or the total mass
            rn = rnn/sum(z);
            X=X.*0;
            muNewX = rn(1);
            muNewY = rn(2);
        end
            
        % test code
        if (1)
            plot(za, a * exp(-((za-b)/c).^2), '-g');
            
            tElapsed = toc(tStarted);
            display(sprintf('GaussFit took %02.3f seconds', tElapsed));
        end
        
        X = [a, b, c, 0, 0];
        zfit = 0;
        
        muNewZ=X(2);
        muNewX=interp1(za,xx,muNewZ,'linear');
        muNewY=interp1(za,yy,muNewZ,'linear');

    catch
        success = 0;
    end
    
    rn=[muNewX muNewY];
        
%     if (any(isnan(rn)))
%         1;
%     end
    
    if (isnan(muNewZ) || isnan(muNewY) || isnan (muNewX) || (muNewY>max(yy)) || (muNewY<min(yy)) || (muNewX>max(xx)) || (muNewX<min(xx)) || ...
            (muNewZ - sigmasInsideThreshold * X(3) < min(za)) || (muNewZ + sigmasInsideThreshold * X(3) > max(za)))
%     if(1)
        % in case the fit wasn't good (the maximum wasn't in field of view
        % we use the center of mass protocol to find  the maximum
        % Now we compute the center of mass by multiplying these
        % z values (the mass) by their spatial positions
        rnn = z'*rscanvec;

        % and dividing by the sum of the z's or the total mass
        rn = rnn/sum(z);
        
        X=X.*0;
        
        flagit=1;
        disp ('used center of mass');
    end


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
    
