%
% Filename: $RCSfile: compile_x12sa_filename.m,v $
%
% $Revision: 1.9 $  $Date: 2011/02/18 11:15:02 $
% $Author: bunk $
% $Tag: $
%
% Description:
% plot a STXM scan
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies: 
% - image_read
%
% history:
%
% October 9th 2009, Oliver Bunk:
% remove BurstScan parameter, add DetectorNumber and SubExpWildcard
% parameter
%
% August 5th 2009, Oliver Bunk:
% return just the directory in case of a negative point number
%
% September 5th 2009, Oliver Bunk:
% 1st version
%
function [ filename, vararg_remain ] = compile_x12sa_filename(scan_no,point_no,varargin)

% set default values
sys_id = identify_system();
switch sys_id
    case 'X12SA'
        base_path = '~/Data10/pilatus/';
    case 'CXS compute node'
        base_path = '/afs/psi.ch/project/cxs/';
    otherwise
        base_path = '';
end

% base name, default starts with the current user name
base_name = identify_eaccount();
if (isempty(base_name))
    base_name = 'image_';
else
    base_name = [ base_name '_' ];
end

add_scan_dir = 1;

sub_exp_no = 0;

point_wildcard = 0;

subexp_wildcard = 0;

detector_number = 1;

file_extension = 'cbf';

% exit with an error message if unhandled named parameters are left at the
% end of this macro
if (nargout > 1)
    unhandled_par_error = 0;
else
    unhandled_par_error = 1;
end

% check minimum number of input arguments
if (nargin < 2)
    fprintf('Usage:\n')
    fprintf('[filename]=%s(scan_no,point_no, [,<name>,<value>] ...]);\n',...
            mfilename);
    fprintf('The optional <name>,<value> pairs are:\n');
    fprintf('''BasePath'',<''path''>                    default is ''%s'', the scan directory is added\n',base_path);
    fprintf('''AddScanDir'',<0-no,1-yes>              add the scan number specific directory part, default is %d\n',add_scan_dir);
    fprintf('''BaseName'',<''name''>                    default is ''%s''\n',base_name);
    fprintf('''FileExtension'',<''extension''>          default is ''%s''\n',file_extension);
    fprintf('''SubExpNo'',<integer no.>               sub exposure number at the end of the file name (not in burst mode), default is %d\n',sub_exp_no);
    fprintf('''DetectorNumber'',<1-Pilatus 2M, 2-Pilatus 300k, 3-Pilatus 100k>\n');
    fprintf('                                       specifies the detector, default is %d\n',detector_number);
    fprintf('''PointWildcard'',<0-no,1-yes>           return a * for the point number in the filename, default is %d\n',point_wildcard);
    fprintf('''SubExpWildcard'',<0-no,1-yes>          return a * for the sub-exposure number in the filename, default is %d\n',subexp_wildcard);
    fprintf('If a negative point number is specified then just the directory is returned.\n');
    fprintf('\n');
    error('At least the scan and point number have to be specified as input parameter.');
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
vararg_remain = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        case 'BasePath' 
            base_path = value;
        case 'BaseName' 
            base_name = value;
        case 'FileExtension' 
            file_extension = value;
        case 'DetectorNumber'
            detector_number = value;
        case 'AddScanDir' 
            add_scan_dir = value;
        case 'SubExpNo'
            sub_exp_no = value;
        case 'PointWildcard'
            point_wildcard = value;
        case 'SubExpWildcard'
            subexp_wildcard = value;
        case 'UnhandledParError'
            unhandled_par_error = value;
        otherwise
            vararg_remain{end+1} = name; %#ok<AGROW>
            vararg_remain{end+1} = value; %#ok<AGROW>
    end
end
% exit in case of unhandled named parameters, if this has not been switched
% off
if ((unhandled_par_error) && (~isempty(vararg_remain)))
    vararg_remain %#ok<NOPRT>
    error('Not all named parameters have been handled.');
end

% add the detector number to the base name
base_name = [ base_name num2str(detector_number) '_' ];

% compile the name of the automatically created scan directory
if (add_scan_dir)
    scan_dir = sprintf('S%05d-%05d/S%05d/',floor(scan_no/1000)*1000, ...
        floor(scan_no/1000)*1000 + 999, ...
        scan_no);
else
    scan_dir = '';
end

% compile path and filename
if (point_no < 0)
    % just the directory without a file name
    filename = sprintf('%s%s',base_path,scan_dir);
else
    filename = sprintf('%s%s%s%05d_',...
        base_path,scan_dir,base_name,scan_no);
    if (point_wildcard)
        filename = sprintf('%s*_',filename);
    else
        filename = sprintf('%s%05d_',filename,point_no);
    end

    if (subexp_wildcard)
        filename = sprintf('%s*.%s',filename,file_extension);
    else
        filename = sprintf('%s%05d.%s',filename,sub_exp_no,file_extension);
    end
end
