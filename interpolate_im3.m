function z = interpolate_im3(im_data,r)

[xsize,ysize] = size(im_data);

ix = floor(r(:,1));
iy = floor(r(:,2));

dx = r(:,1)-ix;
dy = r(:,2)-iy;

try
z = diag(im_data(ix,iy)).*(1-dx).*(1-dy)+diag(im_data(ix,iy+1)).*(1-dx).*(dy)+diag(im_data(1+ix,iy)).*(dx).*(1-dy)+diag(im_data(ix+1,iy+1)).*(dx).*(dy);
catch
    z=0.*ix;
end
%z = max(0,z);



