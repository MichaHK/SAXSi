function d=readMAR345 (fn)
% reading '.IMAGE file format'
f=fopen(fn,'r');
i1=fread(f,5,'uint32');
n=i1(1);
d=zeros(n,n,'uint16');
%ftell (f)
fseek (f,-2*n^2,1);
%ftell (f)
d=fread(f,[n n],'uint16');
%disp(size(d));
  fclose(f);
%figure (1)

%image(d)
%figure (2)
%plot (d(:,1))