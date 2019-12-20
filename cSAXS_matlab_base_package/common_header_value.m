%
% Filename: $RCSfile: common_header_value.m,v $
%
% $Revision: 1.6 $  $Date: 2010/10/02 07:58:01 $
% $Author: bunk $
% $Tag: $
%
% Description:
% return header information which are common to most file formats used at
% the cSAXS beamline
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies:
% - get_hdr_val
%
%
% history:
%
% September 30th 2010, Oliver Bunk:
% add HDF5
%
% October 3rd 2008, Oliver Bunk:
% update FLI date-field since version 1.20 provides a time stamp string
%
% August 28th 2008, Oliver Bunk:
% correct error display for unknown extensions,
% add extension .dat
%
% July 17th 2008, Oliver Bunk: add mar extension
%
% May 7th 2008, Oliver Bunk: 1st version
%
function [value] = common_header_value(header,extension,signature)

% initialize return value
value = [];

% check number of input arguments
if (nargin ~= 3)
    common_header_value_help();
    error('invalid number of input arguments');
end
    
switch extension
    case 'cbf'
        switch signature
            case 'ExposureTime'
                value = get_hdr_val(header,'Exposure_time',' %f',1);
            case 'Date'
                % The date is available in the Pilatus comments, without
                % any signature. Searching for the 20 string will fail
                % beyond the year 2099
                value = [ '20' get_hdr_val(header,'# 20',' %[^\r]',1) ];
            otherwise
                error('unknown signature %s for extension %s',...
                    signature,extension);
        end
    case {'h5', 'hdf5'}
        switch signature
            case 'ExposureTime'
                value = get_hdr_val(header,'Exposure_time',' %f',1);
            case 'Date'
                value = get_hdr_val(header,'DateTime',' %[^\n]',1);
            otherwise
                error('unknown signature %s for extension %s',...
                    signature,extension);
        end
    case 'dat'
        switch signature
            case 'ExposureTime'
                value = get_hdr_val(header,'Exposure_time',' %f',1);
            case 'Date'
                value = get_hdr_val(header,'DateTime',' %[^\n]',1);
            otherwise
                error('unknown signature %s for extension %s',...
                    signature,extension);
        end        
    case 'edf'
        switch signature
            case 'ExposureTime'
                value = get_hdr_val(header,'count_time',' = %f',1);
            case 'Date'
                value = get_hdr_val(header,'Date',' = %[^;]',1);
            otherwise
                error('unknown signature %s for extension %s',...
                    signature,extension);
        end
    case {'mar'}
        switch signature
            case 'ExposureTime'
                value = get_hdr_val(header,'ExposureTime_ms',' %f',1)/1000;
            case 'Date'
                value = get_hdr_val(header,'DateTime',' %[^\n]',1);
            otherwise
                error('unknown signature %s for extension %s',...
                    signature,extension);
        end
    case {'mat'}
        switch signature
            case 'ExposureTime'
                value = get_hdr_val(header,'Exposure_time',' %f',1);
            case 'Date'
                value = get_hdr_val(header,'DateTime',' %[^\n]',1);
            otherwise
                error('unknown signature %s for extension %s',...
                    signature,extension);
        end
    case 'raw'
        switch signature
            case 'ExposureTime'
                value = get_hdr_val(header,'exptimesec',' %f',1);
            case 'Date'
                value = get_hdr_val(header,'version',' %[^\n]',1);
                if (version < 1.20)
                    value = get_hdr_val(header,'FileTimestamp',' %[^\n]',1);
                else
                    value = get_hdr_val(header,'timestamp_string',' %[^\n]',1);
                end
            otherwise
                error('unknown signature %s for extension %s',...
                    signature,extension);
        end
    case 'spe'
        switch signature
            case 'ExposureTime'
                value = get_hdr_val(header,'exposure',' %f',1);
            case 'Date'
                value = [ get_hdr_val(header,'date',' %[^\n]',1)'; ' '; 
                    get_hdr_val(header,'ExperimentTimeLocal',' %[^\n]',1)' ]';
            otherwise
                error('unknown signature %s for extension %s',...
                    signature,extension);
        end
    case {'tif', 'tiff'}
        switch signature
            case 'ExposureTime'
                value = get_hdr_val(header,'Exposure_time',' %f',1);
            case 'Date'
                value = get_hdr_val(header,'DateTime',' %[^\n]',1);
            otherwise
                error('unknown signature %s for extension %s',...
                    signature,extension);
        end
    otherwise
        common_header_value_help();
        error('unknown extension ''%s''',extension);
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = common_header_value_help()

fprintf('Usage:\n');
fprintf('[value]=%s(header,extension,signature);',mfilename);
fprintf('header and extension are returned by image_read\n');
fprintf('The following signatures are recognized:\n');
fprintf('ExposureTime      exposure time in seconds\n');
fprintf('Date              date string in detector specific format\n');
fprintf('Example:\n');
fprintf('exp_time_sec=common_header_value(frame.header{1},frame.extension{1},''ExposureTime'');\n');
