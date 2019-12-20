%
% Filename: $RCSfile: image_info.m,v $
%
% $Revision: 1.2 $  $Date: 2010/11/22 15:32:30 $
% $Author: bunk $
% $Tag: $
%
% Description:
% Get information like the dimensions of the data stored in an image file
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies: 
%
% history:
%
% November 11th 2010, Oliver Bunk:
% 1st version
%

function [im_info,vararg_remain] = image_info(filenames,varargin)

% initialize return arguments
im_info = struct('no_of_frames',[]);

% check minimum number of input arguments
if (nargin < 1)
%    image_read_help('ext',mfilename);
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
    error('The optional parameters have to be specified as ''name'',''value'' pairs');
end


% % set default values for the variable input arguments:
% % default data type for the returned frames
% data_type = default_parameter_value(mfilename,'DataType');
% % recognize file type by file name extension
% force_file_type = default_parameter_value(mfilename,'ForceFileType');
% % determine default orientation based on the file name extension
% orient_by_extension = default_parameter_value(mfilename,'OrientByExtension');
% % filename is actually a mask that may include wildcards
% filename_is_fmask = default_parameter_value(mfilename,'IsFmask');
% % display file name of the file to be loaded
% display_filename = default_parameter_value(mfilename,'DisplayFilename');

% exit with an error message if unhandled named parameters are left at the
% end of this macro
unhandled_par_error = 1;
filename_is_fmask = 0;
force_file_type = [];
display_filename = 0;

% parse the variable input arguments
vararg = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        case 'ForceFileType'
            force_file_type = lower(value);
        case 'OrientByExtension' 
            orient_by_extension = value;
        case 'UnhandledParError'
            unhandled_par_error = value;
        case 'IsFmask' 
            filename_is_fmask = value;
        case 'DisplayFilename' 
            display_filename = value;
        otherwise
            vararg{end+1} = name; %#ok<AGROW>
            vararg{end+1} = value; %#ok<AGROW>
    end
end


% initialize the list of unhandled parameters
vararg_remain = cell(0,0);

% convert the filename to a cell array to use the same loop for single and
% multiple file names
if (~iscell(filenames))
    filenames = { filenames };
end

% loop over all specified file names
file_ind_max = length(filenames);
for (file_ind=1:file_ind_max)
    filename = filenames{file_ind};
    vararg_remain = vararg;

    % in case of file name mask get a list of all matching file names
    data_dir = '';
    if (filename_is_fmask)
        % sub macros must not complain about unknown arguments
        vararg_remain{end+1} = 'UnhandledParError';
        vararg_remain{end+1} = 0;
        
        [data_dir, fnames, vararg_remain] = ...
            find_files( filename, vararg_remain );
    else
        fnames = struct('name',filename);
    end
    
    for (sub_file_ind = 1:length(fnames))
        % pick out the current filename
        filename = [ data_dir fnames(sub_file_ind).name ];
        
        % check for minimum filename length
        if (length(filename) < 5)
            error([ mfilename ': invalid filename ' filename ]);
        end

        if (isempty(force_file_type))
            % get the extension from the last three to four characters
            extension = lower(filename((end-4):end));
            pos = strfind(extension,'.');
            if (length(pos) < 1)
                error([ mfilename ': invalid extension in ' filename ]);
            end
            extension = extension(pos(end)+1:end);
        else
            % the file name extension is ignored since the file type is
            % forced to a specific one
            extension = force_file_type;
        end

        if (display_filename)
            fprintf('file information on %s\n',filename);
        end
        
        if ((strcmp(extension,'dat')) || ...
            (strcmp(extension,'tif')) || (strcmp(extension,'tiff')) || ...
            (strcmp(extension,'mat')))
            % open the file to support functionality like 
            % wait-until-exists
            [fid,vararg_remain] = fopen_until_exists(filename,vararg);
            if (fid >= 0)
              fclose(fid);
            end        
        end
        
        % interprete file in the format indicated by the filename extension
        switch extension
            case {'h5', 'hdf5'}
                fi = hdf5info(filename);
                im_info.no_of_frames = fi.GroupHierarchy.Groups.Datasets.Dims(3);
            case {'cbf', 'dat', 'edf', 'mar', 'mat', 'raw', 'spe', 'tif', 'tiff'}
                [frame,vararg_remain] = image_read(filename,vararg_remain);
                im_info.no_of_frames = size(frame.data,3);
            otherwise
                error([ 'unknown extension of ' filename ]);
        end
    end
end

