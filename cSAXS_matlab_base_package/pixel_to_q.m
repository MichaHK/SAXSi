%
% Filename: $RCSfile: pixel_to_q.m,v $
%
% $Revision: 1.1 $  $Date: 2008/06/10 17:05:14 $
% $Author: bunk $
% $Tag: $
%
% Description:
% calculated momentum transfer q in inverse Angstroem from pixel numbers
% relative to the beam center
%
% Dependencies: 
% none
%
% history:
%
% June 9th 2008, Oliver Bunk: 1st documented version
%
function [ q_A ] = pixel_to_q( pixel, pixel_size_mm, det_dist_mm, E_keV )

if (nargin ~= 4)
    fprintf('Usage:\n');
    fprintf('[ q_A ] = %s( pixel, pixel_size_mm, det_dist_mm, E_keV );\n',...
        mfilename);
    error('Wrong number of parameters, 4 expected, %d found',nargin);
end

lambda_A = 12.39852 / E_keV;

q_A = 4*pi * sin( atan(pixel*pixel_size_mm/det_dist_mm) /2) / lambda_A;
