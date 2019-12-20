%
% Filename: $RCSfile: image_default_orientation.m,v $
%
% $Revision: 1.8 $  $Date: 2010/11/12 15:14:51 $
% $Author: bunk $
% $Tag: $
%
% Description:
% Determine default orientation for an image_orient.m call based on the
% file extension
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies: 
% ---
%
% history:
%
% September 30th 2010, Oliver Bunk:
% add orientation for HDF5 files
%
% November 19th 2008, Oliver Bunk:
% add .mat files
%
% August 28th 2008, Oliver Bunk:
% add orientation for extension .dat
%
% July 17th 2008, Oliver Bunk:
% add mar extension, raw default orientation changed before
%
% June 19th 2008, Oliver Bunk:
% add header to call parameters
%
% June 10th 2008, Oliver Bunk: 
% 1st version
%
function [orient_vec] = ...
   image_default_orientation(header, extension, varargin)

% check minimum number of input arguments
if (nargin < 1)
    fprintf('Usage:\n')
    fprintf('[orientation_vector]=%s(extension);\n',...
        m_file_name);
    fprintf('The vector contains three values which can be 0 or 1 for transpose, flip-left-right, flip-up-down\n');
    error('At least one input parameter has to be specified.');
end


% accept cell array with name/value pairs as well
no_of_in_arg = nargin;
if (nargin == 3)
    if (isempty(varargin))
        % ignore empty cell array
        no_of_in_arg = no_of_in_arg -1;
    else
        if (iscell(varargin{1}))
            % use a filled one given as first and only variable parameter
            varargin = varargin{1};
            no_of_in_arg = 2 + length(varargin);
        end
    end
end


% check number of input arguments
if (rem(no_of_in_arg,2) ~= 0)
    error('The optional parameters have to be specified as ''name'',''value'' pairs');
end



% parse the variable input arguments
% vararg_remain = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
%     value = varargin{ind+1};
    switch name
        otherwise
            error('Do not know how to handle parameter %s\n',name);
%             vararg_remain{end+1} = name;
%             vararg_remain{end+1} = value;
    end
end


% image_read calls this function prior to converting the single frame
% to a cell array of frames
if (~iscell(header))
    fprintf('Warning (%s): header is not a cell array\n',mfilename);
    fprintf('If this is an image_spec call then please report to Oliver:\n')
    whos header
    header
else
    if ((~isempty(header)) && (iscell(header{1})))
        header = header{1};
    end
end


% set the default orientation as a function of the filename extension
switch extension
    case 'dat'
        orient_vec = [ 0 0 0 ];
    case 'edf'
        orient_vec = [ 1 1 1 ];
    case 'cbf'
        orient_vec = [ 1 1 1 ];
    case {'h5', 'hdf5'}
        orient_vec = [ 1 1 1 ];        
    case {'tif', 'tiff'}
        if (strcmp(header{1}(1:5),'Andor'))
            orient_vec = [ 1 0 0 ];
        else
            orient_vec = [ 0 0 0 ];
        end
    case 'mar'
        orient_vec = [ 0 0 0 ];
    case 'mat'
        orient_vec = [ 0 0 0 ];
    case 'raw'
        % FLI CCD at ICON
%        orient_vec = [ 0 1 0 ];
        % FLI CCD at laser setup
        orient_vec = [ 1 0 1 ];
    case 'spe'
        orient_vec = [ 0 0 0 ];
    otherwise
        error([ 'unknown extension ''' extension '''' ]);
end
