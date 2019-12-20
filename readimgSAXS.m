function [imagemat,minmin,maxmax,filenameIn]=readimgSAXS (filenameIn)
if (nargin<1)
    [FileName1,PathName] = uigetfile('*.img;*.tif','Select the SAXS 2D file');
    filenameIn=strcat(PathName,FileName1);
end

% fid=fopen(filenameIn,'r');
% fseek(fid,1024,'bof');
% imagemat=fread(fid,[2304,2304],'uint16');
% 
% 
% % fid=fopen(filenameIn,'r');
% % fseek(fid,533,'bof');
% % temp=fread(fid,8,'*char');
% % I2=str2double(temp');
% fclose(fid);
imagemat=double(read2D(filenameIn));
%imagemat=imagemat;
%minmin=min(min(imagemat));
%maxmax=max(max(imagemat));
minmin=0;maxmax=0;

%image((imagemat.*100./max(max(imagemat))));
% image (imagemat);
% axis image
% colormapeditor