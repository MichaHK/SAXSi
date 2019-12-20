%
% Filename: $RCSfile: integrate_range.m,v $
%
% $Revision: 1.5 $  $Date: 2011/08/13 14:13:15 $
% $Author: bunk $
% $Tag: $
%
% Description:
% azimuthal integration of a range of scans
%
% Note:
% Call without arguments for a brief help text.
% The integration masks need to be prepared first using prep_integ_masks.m
%
% Dependencies: 
% - compile_x12sa_filename
% - find_files
% - radial_integ
%
% history:
%
% May 19th 2010, Oliver Bunk: 1st documented version
%
function [] = integrate_range(scan_no_from,scan_no_to,varargin)

% set default values for the variable input arguments:
% select PILATUS 2M
pilatus_det_no = 1;
% writing cbf files
file_extension = 'cbf';

if (nargin < 2)
    fprintf('\nUsage:\n');
    fprintf('%s(scan_no_from,scan_no_to,  [[,<name>,<value>] ...]);\n',mfilename);
    fprintf('integrates the scans within the range [scan_no_from, scan_no_to].\n');
    fprintf('The optional <name>,<value> pairs are:\n');
    fprintf('''PilatusDetNo'',<directory>           Detector number, 1 for 2M, default is %d\n',pilatus_det_no);
    fprintf('''FileExtension'',<extension string>   default is %s\n',file_extension);
    fprintf('Example:\n');
    fprintf('%s(100,500);\n',mfilename);
    fprintf('Additional <name>,<value> pairs recognized by radial_integ can be specified.\n');
    error('At least the scan number range has to be specified as input argument.');
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
            no_of_in_arg = 1 + length(varargin);
        end
    end
end

% check number of input arguments
if (rem(no_of_in_arg,2) ~= 0)
    error('The optional parameters have to be specified as ''name'',''value'' pairs');
end

% parse the variable input arguments:
% initialize the list of unhandled parameters
vararg_remain = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        case 'PilatusDetNo'
            pilatus_det_no = value;
        case 'FileExtension'
            file_extension = value;
            vararg_remain{end+1} = name; %#ok<AGROW>
            vararg_remain{end+1} = value; %#ok<AGROW>
        otherwise
            vararg_remain{end+1} = name; %#ok<AGROW>
            vararg_remain{end+1} = value; %#ok<AGROW>
    end
end

vararg_remain{end+1} = 'UnhandledParError';
vararg_remain{end+1} = 0;

vararg_remain_x12sa_filename = vararg_remain;
vararg_remain_x12sa_filename{end+1} = 'DetectorNumber';
vararg_remain_x12sa_filename{end+1} = pilatus_det_no;

vararg_remain_x12sa_filename_wildcard = vararg_remain_x12sa_filename;
vararg_remain_x12sa_filename_wildcard{end+1} = 'PointWildcard';
vararg_remain_x12sa_filename_wildcard{end+1} = 1;
vararg_remain_x12sa_filename_wildcard{end+1} = 'SubExpWildcard';
vararg_remain_x12sa_filename_wildcard{end+1} = 1;


% highest number of an existing scan
scan_no_exists = scan_no_from -1;
scan_no_check = scan_no_from;

for scan_no = scan_no_from:scan_no_to  
    % wait until the first file of the next scan is available
    while (scan_no >= scan_no_exists)
        scan_no_check = scan_no_check +1;
        if (scan_no_check > scan_no + 100)
            scan_no_check = scan_no +1;
            fprintf('Pausing for 1 minute.\n');
            pause(60);

            % check if the data directory and first file exists
            filename_mask = compile_x12sa_filename(scan_no,0,vararg_remain_x12sa_filename);
            [ddir fnames] = find_files(filename_mask);
            if (~isempty(fnames))
                % integrate all data available until now
                filename_mask = [ compile_x12sa_filename(scan_no,-1,vararg_remain_x12sa_filename) '*_' num2str(pilatus_det_no) '_' ['*' file_extension] ];
                radial_integ(filename_mask,vararg_remain);
            end
        end
        filename_next = compile_x12sa_filename(scan_no_check,0,vararg_remain_x12sa_filename);
        [ddir fnames] = find_files(filename_next);
        if (~isempty(fnames))
            scan_no_exists = scan_no_check;
        end
    end
    
    % integrate scan if a following scan has been started, i.e., 
    % if the current one must be finished
    if (scan_no < scan_no_exists)
        % check if the data directory and first file exists
        filename_mask = compile_x12sa_filename(scan_no,0,vararg_remain_x12sa_filename);
        [ddir fnames] = find_files(filename_mask);
        if (isempty(fnames))
            fprintf('Skipping scan no %d: no data found\n',scan_no);
            continue;
        end

        % integrate all data, i.e., all points and sub exposures
        filename_mask = [ compile_x12sa_filename(scan_no,0,vararg_remain_x12sa_filename_wildcard) ];
        radial_integ(filename_mask,vararg_remain);
    end
end
