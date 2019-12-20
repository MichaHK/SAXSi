%function [qvec,Ivec,xhi,Ixhi]=IntFast(...
function [integrated]=IntFast(...
    imagemat, CalibrationData, IntegrationParams, FastIntegrationCache)
% This functions accepts the following forms:
% IntFast(Image, Mask, CalibrationData, IntegrationParams)
% IntFast(Image, Mask, CalibrationData, IntegrationParams, DezingerPortion)
% IntFast(Image, Mask, CalibrationData, IntegrationParams, DezingerPortion, FastIntegrationCache)
%

maskin = IntegrationParams.MaskBitmap;

dezingerType = IntegrationParams.DezingerType;
dezingerPer = IntegrationParams.DezingerPercentile;

if (nargin < 4 || isempty(FastIntegrationCache))
    FastIntegrationCache = FastIntegrationCacheClass();
end

if (~isa(imagemat, 'double'))
    imagemat = double(imagemat);
end

integrated = [];
integrated.Q = [];
integrated.I = [];
integrated.IErr = [];
integrated.Xhi = [];
integrated.IXhi = [];
integrated.IXhiErr = [];

tStarted = tic();
szMatin=size(imagemat);

try
    ise=isempty(FastIntegrationCache.QVector);
catch
    ise=true;
end

doxhi = IntegrationParams.shouldDoXhi;
if doxhi
    FastIntegrationCache.XhiVector=1:360;
else
    FastIntegrationCache.XhiVector=[]; xhi=[];Ixhi=[];
end

try
    ifans = FastIntegrationCache.AnyParamsChanged(CalibrationData, IntegrationParams);
    
    ifans = ifans | ((FastIntegrationCache.Factor ~= FastIntegrationCache.PrevFactor) | ...
        any(szMatin ~= FastIntegrationCache.ImageSize) | ...
        isempty(FastIntegrationCache.QVector));
catch
    ifans=true;
end
% ifans=true;   %%%% remove that%%%%%

FastIntegrationCache.PrevFactor = FastIntegrationCache.Factor;

% For debug
ifans = 1;

binsizeInt = IntegrationParams.QStepsCount;
qmin = IntegrationParams.QMin;
qmax = IntegrationParams.QMax;
doxhi = IntegrationParams.shouldDoXhi;

difq = (qmax-qmin) / binsizeInt;
qvec = qmin:difq:qmax;
abovebinsize = binsizeInt+1;
aboveXhiBins = 361;

M = szMatin(1);
N = szMatin(2);

if ifans
    %% need to do it slower
    
    %tic
    FastIntegrationCache.ImageSize = szMatin;
    FastIntegrationCache.CopyParams(CalibrationData, IntegrationParams);
    
    FastIntegrationCache.QVector = qvec;
    
    FastIntegrationCache.ImageToQMatrix = zeros([szMatin(1) szMatin(2)],'uint32') + abovebinsize;%,'uint32');
    FastIntegrationCache.ImageToXhiMatrix = zeros([szMatin(1) szMatin(2)],'uint32') + aboveXhiBins;
    maskinFull=ones(M, N, 'uint8');
    if ~isempty (maskin)
        [mx,my]=size(maskin);
        tmp1=min(M,my);
        tmp2=min(N,mx);
        %maskinFull(1:tmp1,1:tmp2)=maskin(1:tmp2,1:tmp1)';
        maskinFull = maskin;
    end;
    
    if isempty(maskin)
        masknx=1;
        maskny=1;
        maskin (1,1) = false;
    else
        masks=size(maskin);
        masknx=min(szMatin(1),masks(1));
        maskny=min(szMatin(2),masks(2));
        
    end
    
    FastIntegrationCache.QImage = GenerateQImage(1:N, 1:M, CalibrationData);
    FastIntegrationCache.ImageToQMatrix = uint32(max(0, round((FastIntegrationCache.QImage - qmin + difq/2) ./ difq)));
    %fM=find((~maskinFull)|(TrasformMatIn.TR<1) | (TrasformMatIn.TR>binsizeInt));
    
    % Modified by Ram Avinery due to changes in the masking code
    fM = find(maskin | (FastIntegrationCache.ImageToQMatrix < 1) | ...
        (FastIntegrationCache.ImageToQMatrix > binsizeInt));
    FastIntegrationCache.ImageToQMatrix(fM) = abovebinsize; % Mask out pixels
    
    % Ram
    %FastIntegrationCache.ImageToQMatrix = floor(FastIntegrationCache.ImageToQMatrix);
    
    clear Dist
    if doxhi
        FastIntegrationCache.XhiImage = GenerateXhiImage(1:N, 1:M, CalibrationData);
        FastIntegrationCache.ImageToXhiMatrix=uint32(FastIntegrationCache.XhiImage);
        FastIntegrationCache.ImageToXhiMatrix(fM) = aboveXhiBins;
    end
    
    N = accumarray(FastIntegrationCache.ImageToQMatrix(:), 1, [], @sum);

    whichEmpty = (N == 0);
    
end

%tic

IErrVec = [];
N = [];


switch (dezingerType)
    case 0 % mean
        Ivec=accumarray(FastIntegrationCache.ImageToQMatrix(:), imagemat(:), [], @mean);
        N = accumarray(FastIntegrationCache.ImageToQMatrix(:), 1, [], @sum);
        IErrVec = accumarray(FastIntegrationCache.ImageToQMatrix(:), imagemat(:), [], @(x)std(x)) ...
             ./ sqrt(N);
        
    case 1 % trimmean
        Ivec = accumarray(FastIntegrationCache.ImageToQMatrix(:), imagemat(:), [], @(x) trimmean(x,dezingerPer));
        N = accumarray(FastIntegrationCache.ImageToQMatrix(:), 1, [], @sum) .* (1 - 0.02*dezingerPer); % TODO: Get a more accurate number of values

        % TODO: Make sure the outliers for the mean and for the error are the same
        IErrVec = accumarray(FastIntegrationCache.ImageToQMatrix(:), imagemat(:), [], @(x)trimmean((x-trimmean(x,dezingerPer)).^2, dezingerPer));
        IErrVec = sqrt(IErrVec) ./ sqrt(N);
        
    case 2 % poisson-median rejection filter
        % Use the initial estimate to reject outliers assuming poisson distribution

        %%
        %medianIntensities = accumarray(FastIntegrationCache.ImageToQMatrix(:), imagemat(:), [], @(x) median(x));
        medianIntensities = accumarray(FastIntegrationCache.ImageToQMatrix(:), imagemat(:), [], @(x) trimmean(x, dezingerPer));
        
        if (0)
            %%
            % TODO: Add this kind of median-to-mean-ratio plot
            figure(1);
            plot(FastIntegrationCache.QVector, accumarray(FastIntegrationCache.ImageToQMatrix(:), imagemat(:), [], @(x) median(x)) ./ accumarray(FastIntegrationCache.ImageToQMatrix(:), imagemat(:), [], @(x) trimmean(x, dezingerPer)));
        end
        
        if (0)
            maxInclusiveValue = poissinv(1-dezingerPer*0.01, medianIntensities) + 1;
            minInclusiveValue = poissinv(dezingerPer*0.01, medianIntensities) - 1;
        else
            N = accumarray(FastIntegrationCache.ImageToQMatrix(:), 1, [], @sum);
            alpha = 1 - (1 - 0.01*dezingerPer).^(1./N);
            maxInclusiveValue = poissinv(1-alpha, medianIntensities) + 1;
            minInclusiveValue = poissinv(alpha, medianIntensities) - 1;
        end
        
        upperThreshold = reshape(maxInclusiveValue(FastIntegrationCache.ImageToQMatrix(:)), size(FastIntegrationCache.ImageToQMatrix));
        lowerThreshold = reshape(minInclusiveValue(FastIntegrationCache.ImageToQMatrix(:)), size(FastIntegrationCache.ImageToQMatrix));

        filteredQMatrix = FastIntegrationCache.ImageToQMatrix;
        filteredQMatrix(imagemat > upperThreshold) = abovebinsize;
        filteredQMatrix(imagemat < lowerThreshold) = abovebinsize;
        
        if (0) % for debug
            %%
            figure(10);
            x = imagemat;
            x = zeros(size(imagemat));
            x(imagemat > upperThreshold) = 1;
            x(imagemat < lowerThreshold) = -1;
            %x(imagemat > upperThreshold) = x(imagemat > upperThreshold)*1;
            %x(imagemat < lowerThreshold) = x(imagemat < lowerThreshold)*-1;
            %x((imagemat <= upperThreshold) & (imagemat >= lowerThreshold)) = 0;
            %imagesc(real(log10(x)));
            imagesc(x);
        end
        
        if (0) % for debug
            %%
            figure(10);
            imagesc(filteredQMatrix);
        end

        if (0) % for debug
            %%
            figure(10);
            %imagesc(upperThreshold);
            imagesc(lowerThreshold);
        end

        [Ivec, S, N] = accumarrayMultiFun(filteredQMatrix(:), imagemat(:), [], ...
            @(x)mean(x), @(x)std(x), @(x)numel(x)); % Get: mean, std, N
        IErrVec = S ./ sqrt(N);
        
    otherwise
        error('Bad dezinger method selected. Only 0 (none), 1 (trimmean), or 2 (poisson-median filter) are allows.');
end

% Now radial, instead of azimuthal, averaging... ("xhi" plot)
if (1 && doxhi)
    switch (dezingerType)
        case 0 % mean
            Ixhi = accumarray(FastIntegrationCache.ImageToXhiMatrix(:), imagemat(:),[],@mean);
            IxhiErr = accumarray(FastIntegrationCache.ImageToXhiMatrix(:), imagemat(:), [], @(x)std(x)*(1/sqrt(numel(x))));

        case 1 % trimmean
            Ixhi = accumarray(FastIntegrationCache.ImageToXhiMatrix(:), imagemat(:),[],@(x) trimmean(x, dezingerPer));
            
            % TODO: Redo the error calculation. Should use the same pixels used in the mean
            IxhiErr = accumarray(FastIntegrationCache.ImageToXhiMatrix(:), imagemat(:), [], ...
                @(x) sqrt(trimmean((x-trimmean(x, dezingerPer)).^2, dezingerPer)) * (1/sqrt(numel(x))) );
            
        case 2 % poisson-median rejection filter
            % Not meaningful for "xhi" plot, use trimmean instead

            filteredXhiMatrix = FastIntegrationCache.ImageToXhiMatrix;
            filteredQMatrix(imagemat > upperThreshold) = aboveXhiBins;
            filteredQMatrix(imagemat < lowerThreshold) = aboveXhiBins;
            
            Ixhi = accumarray(filteredXhiMatrix(:), imagemat(:),[], @(x) mean(x));
            IxhiErr = accumarray(FastIntegrationCache.ImageToXhiMatrix(:), imagemat(:), [], @(x)std(x)*(1/sqrt(numel(x))));
    end
else
    Ixhi=[];
    IxhiErr = [];
end


lenIv = length(Ivec);
Ivec = Ivec(1:lenIv-1);
IErrVec = IErrVec(1:lenIv-1);
FastIntegrationCache.QVector = FastIntegrationCache.QVector(1:lenIv-1);
qvec = FastIntegrationCache.QVector(:);

integrated.Q = qvec;
integrated.I = Ivec;
integrated.IErr = IErrVec;
integrated.N = N;

if ~isempty(Ixhi)
    lenxhi = length(Ixhi);
    Ixhi = Ixhi(1:lenxhi-1);
    IxhiErr = IxhiErr(1:lenxhi-1);
    xhi = (1:lenxhi-1)';
    FastIntegrationCache.XhiVector = xhi;
else
    Ixhi=[0 0];
    xhi=[1 360];
    IxhiErr = [0, 0];
end

integrated.Xhi = xhi;
integrated.IXhi = Ixhi;
integrated.IXhiErr = IxhiErr;


%toc


