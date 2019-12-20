%function [qvec,Ivec,xhi,Ixhi]=IntFast(...
function [integrated]=IntFast(...
    imagemat, maskin, CalibrationData, IntegrationParams, dezingerPer, FastIntegrationCache)
% This functions accepts the following forms:
% IntFast(Image, Mask, CalibrationData, IntegrationParams)
% IntFast(Image, Mask, CalibrationData, IntegrationParams, DezingerPortion)
% IntFast(Image, Mask, CalibrationData, IntegrationParams, DezingerPortion, FastIntegrationCache)
%

if (nargin < 5)
    dezingerPer = 0;
end

if (nargin < 6 || isempty(FastIntegrationCache))
    FastIntegrationCache = FastIntegrationCacheClass();
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

if ifans
    %% need to do it slower
    
    %tic
    FastIntegrationCache.ImageSize = szMatin;
    FastIntegrationCache.CopyParams(CalibrationData, IntegrationParams);
    
    L = CalibrationData.SampleToDetDist;
    pixsize = CalibrationData.PixelSize;
    lamda = CalibrationData.Lambda;
    alpha = CalibrationData.AlphaRadians;
    beta = CalibrationData.BetaRadians;
%     flipY = .shouldFlipY;
    
    binsizeInt = IntegrationParams.QStepsCount;
    qmin = IntegrationParams.QMin;
    qmax = IntegrationParams.QMax;
    doxhi = IntegrationParams.shouldDoXhi;
    
    d=L/pixsize;
    lenIm=length(imagemat);
    [Xd,Yd]=find_Direct_Beam_conX(...
        CalibrationData.BeamCenterX,...
        CalibrationData.BeamCenterY, beta);
%     if flipY
%         y0=lenIm-y0;
%     end
    
    difq=(qmax-qmin)/binsizeInt;
    qvec=qmin:difq:qmax;
    FastIntegrationCache.QVector = qvec;
    abovebinsize=binsizeInt+1;
    M=szMatin(1);N=szMatin(2);
    FastIntegrationCache.ImageToQMatrix = zeros([szMatin(1) szMatin(2)],'uint32')+abovebinsize;%,'uint32');
    FastIntegrationCache.ImageToXhiMatrix = zeros([szMatin(1) szMatin(2)],'uint32')+361;
    maskinFull=ones(M,N,'uint8');
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
    
    fourPiOverLamda=12.56637061435917/lamda;
    pixelsizeOverL=pixsize/L;
    
    %%%%%% calculate matries %%%%%%%
    
    [xx,yy]=meshgrid(1:N,1:M);
    
    XX=Xd+xx*cos(beta)-yy*sin(beta);
    YY=Yd-xx*sin(beta)-yy*cos(beta);
    
    clear xx; clear yy;
    
    xx=YY*cos(alpha);
    yy=-XX;
    zz=d/cos(alpha)-YY*sin(alpha);
    
    Dist=sqrt(xx.^2+yy.^2+zz.^2);
    %  Theta=180*acos(zz./Dist)/pi;
    
    %   q=4*pi*sin(0.5*atan(pixsize*rmin/L))/lamda
    %  q=forpiOverLamda*sin(0.5.*acos(zz./Dist));
    %maskin=maskin';
    
    FastIntegrationCache.ImageToQMatrix = uint32(max(0, round((fourPiOverLamda*sin(0.5.*acos(zz./Dist))-qmin+difq/2)./difq)));
    %fM=find((~maskinFull)|(TrasformMatIn.TR<1) | (TrasformMatIn.TR>binsizeInt));
    
    % Modified by Ram Avinery due to changes in the masking code
    fM = find(maskin | (FastIntegrationCache.ImageToQMatrix < 1) | ...
        (FastIntegrationCache.ImageToQMatrix > binsizeInt));
    FastIntegrationCache.ImageToQMatrix(fM) = abovebinsize; % Mask out pixels
    
    % Ram
    %FastIntegrationCache.ImageToQMatrix = floor(FastIntegrationCache.ImageToQMatrix);
    
    clear Dist
    if doxhi
        FastIntegrationCache.ImageToXhiMatrix=uint32(ceil(180*atan2(yy,xx)/pi)+180);
        FastIntegrationCache.ImageToXhiMatrix(fM)=361;
    end
    
    %
    %     TRrem=TrasformMatIn.TR;
    %     ImageToXhiMatrixrem=TrasformMatIn.ImageToXhiMatrix;
    %     TrasformMatIn.TR=zeros([szMatin(1) szMatin(2)],'uint32')+abovebinsize;%,'uint32');
    %     TrasformMatIn.ImageToXhiMatrix=zeros([szMatin(1) szMatin(2)],'uint32')+361;
    %
    %
    %     for xcount=1:szMatin(1)
    %         for ycount=1:szMatin(2)
    %             if (maskin(min(ycount,masknx),min(maskny,xcount)))
    %                  if (maskin(min(xcount,masknx),min(maskny,ycount)))
    %                 roverL=pixelsizeOverL*sqrt((xcount-x0)^2+(ycount-y0)^2);
    %
    %                 q=forpiOverLamda*sin(0.5*atan(roverL));
    %
    %                 inq=round((q-qmin+difq/2)/difq);
    %                 if ((inq>0) && (inq<binsizeInt+1))
    %                     TrasformMatIn.TR(xcount,ycount)=inq;   %%%%flipped%%%%%
    %                     if doxhi
    %                         tempX=ceil(rad2deg(atan2((xcount-x0),(ycount-y0))+pi));
    %                         if tempX
    %                             TrasformMatIn.ImageToXhiMatrix(xcount,ycount)=tempX;  %%%%flipped%%%%%
    %                         end
    %                     end
    %
    %                 end
    %
    %             end
    %         end
    %     end
    %toc
    
    
%     figure (2)
%     image (double(TrasformMatIn.ImageToXhiMatrix-ImageToXhiMatrixrem))
%     figure (3)
%     image (double(TrasformMatIn.TR-TRrem));
%     disp ('help her');
%     
    
    
    
    
    
    
    
    disp('first part');
end

%tic

IErrVec = [];
N = [];

% TODO: Modify "de-zinger", because it is incompatible with measurements
% without a beam-stop

if dezingerPer
    % dezinger
    Ivec = accumarray(FastIntegrationCache.ImageToQMatrix(:), double(imagemat(:)),[],@(x) trimmean(x,dezingerPer));
    
    if doxhi
        Ixhi=accumarray(FastIntegrationCache.ImageToXhiMatrix(:), double(imagemat(:)),[],@(x) trimmean(x,dezingerPer));
    else
        Ixhi=[];
    end
else % No dezingering
    
    Ivec=accumarray(FastIntegrationCache.ImageToQMatrix(:), double(imagemat(:)),[],@mean);
    
    % This alternative accumulation can be used to look at the curve using
    % the poisson distribution property that the variance equals the mean
    %Ivec=accumarray(FastIntegrationCache.ImageToQMatrix(:), double(imagemat(:)),[],@(x)var(x));

    if doxhi
        Ixhi=accumarray(FastIntegrationCache.ImageToXhiMatrix(:), double(imagemat(:)),[],@mean);
    else
        Ixhi=[];
    end
end

N = accumarray(FastIntegrationCache.ImageToQMatrix(:), 1,[],@sum);

if dezingerPer
    % TODO: Make sure the outliers for the mean and for the error are the same
    IErrVec = accumarray(FastIntegrationCache.ImageToQMatrix(:), double(imagemat(:)) .^ 2, [], @(x)trimmean(x,dezingerPer));
else
    IErrVec = accumarray(FastIntegrationCache.ImageToQMatrix(:), double(imagemat(:)), [], @(x)var(x));
end

IErrVec = sqrt(IErrVec) ./ sqrt(N);


if doxhi
    IxhiErr = accumarray(FastIntegrationCache.ImageToXhiMatrix(:), double(imagemat(:)), [], @(x)std(x)*(1/sqrt(numel(x))));
else
    IxhiErr = [];
end

lenIv=length(Ivec);
Ivec=Ivec(1:lenIv-1);
IErrVec=IErrVec(1:lenIv-1);
FastIntegrationCache.QVector = FastIntegrationCache.QVector(1:lenIv-1);
qvec = FastIntegrationCache.QVector(:);

integrated.Q = qvec;
integrated.I = Ivec;
integrated.IErr = IErrVec;
integrated.N = N;

if ~isempty(Ixhi)
    lenxhi=length(Ixhi);
    Ixhi=Ixhi(1:lenxhi-1);
    IxhiErr=IxhiErr(1:lenxhi-1);
    xhi=(1:lenxhi-1)';
    FastIntegrationCache.XhiVector=xhi;
else
    Ixhi=[0 0];xhi=[1 360];IxhiErr = [0, 0];
end

integrated.Xhi = xhi;
integrated.IXhi = Ixhi;
integrated.IXhiErr = IxhiErr;


%toc



