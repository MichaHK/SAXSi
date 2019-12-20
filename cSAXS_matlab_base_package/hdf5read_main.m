%
% Filename: $RCSfile: hdf5read_main.m,v $
%
% $Revision: 1.1 $  $Date: 2010/10/02 07:58:50 $
% $Author: bunk $
% $Tag: $
%
% Description:
% Macro for reading HDF5 files written for example by the EIGER server
% program cbd_server
%
% Note:
% So far this is mainly a place holder for a thorough implementation. 
%
% Dependencies:
% - image_read_set_default
% - fopen_until_exists
% - get_hdr_val
%
%
% history:
%
% September 30th 2010, Oliver Bunk: 1st version
%

function [frame,vararg_remain] = hdf5read_main(filename,varargin)

% 0: no debug information
% 1: some feedback
% 2: a lot of information
debug_level = 0;

% initialize return argument
frame = struct('header',[], 'data',[]);


% check minimum number of input arguments
if (nargin < 1)
    image_read_sub_help(mfilename,'h5');
    error('At least the filename has to be specified as input parameter.');
end

% accept cell array with name/value pairs as well
no_of_in_arg = nargin;
if (nargin == 2)
    if (isempty(varargin))
        % ignore empty cell array
        no_of_in_arg = no_of_in_arg -1;
    else
        if (iscell(varargin{1}))
            % use a filled one given as first and only variable parameter
            varargin = varargin{1};
            no_of_in_arg = 1 + length(varargin);
        end
    end
end

% check number of input arguments
if (rem(no_of_in_arg,2) ~= 1)
    error('The optional parameters have to be specified as ''name'',value pairs');
end
    
% set default values for the variable input arguments and parse the named
% parameters: 
vararg = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        otherwise
            % pass further arguments on to fopen_until_exists
            vararg{end+1} = name;
            vararg{end+1} = value;
    end
end


% try to open the data file
if (debug_level >= 1)
    fprintf('Opening %s.\n',filename);
end
[fid,vararg_remain] = fopen_until_exists(filename,vararg);
if (fid < 0)
    return;
end
% close input data file
fclose(fid);

% get file header
hdr = hdf5info(filename);

% store part of the file header in the return argument
frame.header = {};
frame.header{end+1} = 'Exposure_time 1.0';
% add the file modification date to the header
dir_entry = dir(filename);
frame.header{end+1} = [ 'DateTime ' dir_entry.date ];

% read all data of first data set at once
frame.data = hdf5read(hdr.GroupHierarchy(1).Groups(1).Datasets(1));

if (debug_level >= 2)
    fprintf('%dx%dx%dx%s data bytes read\n',...
        size(fdat,1),size(fdat,2),size(fdat,3),size(fdat,4));
end
