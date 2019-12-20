function [imagemat,minmin,maxmax,filenameIn]=readimgSAXSgfrm (filenameIn)
if (nargin<1)
    [FileName1,PathName] = uigetfile('*.gfrm','Select the gfrm file');
    filenameIn=strcat(PathName,FileName1);
end

fid=fopen(filenameIn,'r');
% for i=1:8192
%     fseek(fid,i,'bof');
%     disp(['i=',num2str(i),':',char(fread(fid,1,'char' ))])
% end
fseek(fid,8192,'bof');
imagemat2=fread(fid,[1024,1024],'uint8');
fclose(fid);
imagemat(1:512,:)=imagemat2(513:1024,:);
imagemat(513:1024,:)=imagemat2(1:512,:);
imagemat=imagemat';
% fid=fopen(filenameIn,'r');
% fseek(fid,533,'bof');
% temp=fread(fid,8,'*char');
% I2=str2double(temp');
%imagemat=imagemat;
%minmin=min(min(imagemat));
%maxmax=max(max(imagemat));
minmin=0;maxmax=0;

%image((imagemat.*100./max(max(imagemat))));
% image (imagemat);
% axis image
% colormapeditor