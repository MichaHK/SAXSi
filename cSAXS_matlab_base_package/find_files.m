%
% Filename: $RCSfile: find_files.m,v $
%
% $Revision: 1.8 $  $Date: 2011/08/09 10:05:15 $
% $Author: bunk $
% $Tag: $
%
% Description:
% find file names matching the specified mask
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies: 
% - Linux/Unix find command, if specified to use
%
% history:
%
% October 10th 2009, Oliver Bunk:
% only check for files if changing to the directory was possible
%
% September 14th 2008, Oliver Bunk: 
% bug fix: add directory to filename in isdir check
%
% September 4th 2008, Oliver Bunk:
% bug fix: vararg_remain was not filled and unhandled parameters did not
% cause an error
%
% June 16th 2008, Oliver Bunk: send find output through sort
%
% June 10th 2008, Oliver Bunk: 1st documented version
%
function [ directory, fnames, vararg_remain ] = find_files( filename_mask, varargin )

% initialize return arguments
fnames = [ ];

% set default values
use_find = default_parameter_value(mfilename,'UseFind');
unhandled_par_error = default_parameter_value(mfilename,'UnhandledParError');

% check minimum number of input arguments
if (nargin < 1)
    fprintf('\nUsage:\n');
    fprintf('[directory filenames]=%s(filename_mask,  [[,<name>,<value>] ...]);\n',mfilename);
    fprintf('filename_mask can be something like ''*.cbf'' or ''image.cbf''\n');
    fprintf('The optional <name>,<value> pairs are:\n');
    fprintf('''UseFind'',<0-no, 1-yes>              use Linux/Unix command find to interprete the filename mask, default is %d\n',use_find);
    fprintf('''UnhandledParError'',<0-no,1-yes>     exit in case not all named parameters are used/known, default is %d\n',unhandled_par_error);
    fprintf('Examples:\n');
    fprintf('%s(''~/Data10/pilatus/mydatadir/*.cbf'',''OutdirData'',''~/Data10/analysis/my_int_dir/'');\n',mfilename);
    fprintf('Additional <name>,<value> pairs recognized by image_read can be specified.\n');
    error('At least the filename mask has to be specified as input argument.');
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

% parse the variable input arguments:
% initialize the list of unhandled parameters
vararg_remain = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        case 'UseFind' 
            use_find = value;
        case 'UnhandledParError'
            unhandled_par_error = value;
        otherwise
            vararg_remain{end+1} = name; %#ok<AGROW>
            vararg_remain{end+1} = value; %#ok<AGROW>
    end
end

[directory, name, ext] = fileparts(filename_mask);
% add slash to directories
if ((~isempty(directory)) && (directory(end) ~= '/'))
    directory = [ directory '/' ];
end

% exit in case of unhandled named parameters, if this has not been switched
% off
if ((unhandled_par_error) && (~isempty(vararg_remain)))
    vararg_remain %#ok<NOPRT>
    error('Not all named parameters have been handled.');
end


% search matching filenames
if (use_find)
    find_cmd = sprintf('find . -noleaf -maxdepth 1 -name ''%s''|sort',[ name ext ]);
    cd_cmd = '';
    if (~isempty(directory))
        cd_cmd = sprintf('cd %s 2>/dev/null',directory);
    end
    % if the directory exists check for files within it
    st = 1;
    if ((isempty(directory)) || (exist(directory,'dir')))
        [st,files]=unix([cd_cmd ';' find_cmd ]);
    end
    % store names of files found in fnames
    if (st == 0)
        % count number of newline characters
        no_of_files = length(sscanf(files,'%*[^\n]%1c'));
        fnames = struct('name',cell(1,no_of_files),'isdir',cell(1,no_of_files));
        % extract file names
        file_ind = 1;
        while (~isempty(files))
            name = sscanf(files,'%[^\n]',1);
            files = files( (length(name)+2):end );
            if ((length(name) > 2) && (strcmp(name(1:2),'./')))
                name = name(3:end);
            end
            if (~strcmp(name,'.'))
                fnames(file_ind).name = name;
                fnames(file_ind).isdir = isdir([ directory fnames(file_ind).name ]);
                file_ind = file_ind +1;
            end
        end
        % shorten the result if for example '.' entries have been skipped
        if (file_ind <= no_of_files)
            fnames = fnames(1:(file_ind-1));
        end
    end
else
    fnames = dir( filename_mask );
end
