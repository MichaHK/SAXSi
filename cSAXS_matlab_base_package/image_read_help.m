%
% Filename: $RCSfile: image_read_help.m,v $
%
% $Revision: 1.2 $  $Date: 2008/07/17 16:55:40 $
% $Author: bunk $
% $Tag: $
%
% Description:
% parameter help for image_read
%
% Note:
% none
%
% Dependencies:
% none
%
%
% history:
%
% July 17th 2008, Oliver Bunk: 
% add ForceFileType parameter and support for MAR CCD TIFF
%
% May 9th 2008, Oliver Bunk: 1st version
%
function [] = image_read_help(extension,m_file_name,varargin)

% check minimum number of input arguments
if (nargin < 2)
    error('At least the extension and m-file name have to be specified as input parameter.');
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
examples = 1;
vararg = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        case 'Examples' 
            examples = value;
        otherwise
            % pass unknown parameters to image_read_sub_help
            vararg{end+1} = name;
            vararg{end+1} = value;
    end
end

% do not display examples from image_read_sub_help
vararg{end+1} = 'Examples';
vararg{end+1} = 0;

image_read_sub_help(m_file_name,extension,vararg)
fprintf('''DataType'',<Matlab class>            default is ''double'', other possibilities are ''single'', ''uint16'', ''int16'', ''uint32'', etc.\n');
fprintf('                                     The conversion is done using ''cast'', i.e, out-of-range values are mapped to the minimum or maximum value\n');
fprintf('''ForceFileType'',<''extension''>        force the file types to be recognized by the here specified extension,\n');
fprintf('                                     useful in case of no or other types of extensions\n');
fprintf('                                     The extension ''mar'' can be used to read MAR CCD TIFF data.\n');
fprintf('''RowFrom'',<0-max>                    region of interest definition, 0 or 1 for full frame\n');
fprintf('''RowTo'',<0-max>                      region of interest definition, 0 for full frame\n');
fprintf('''ColumnFrom'',<0-max>                 region of interest definition, 0 or 1 for full frame\n');
fprintf('''ColumnTo'',<0-max>                   region of interest definition, 0 for full frame\n');
image_orient_help(m_file_name,'ParametersOnly',1);
fprintf('''IsFmask'',<0-no,1-yes>               interprete the filename(s) as search mask that may include wildcards, default no\n');
fprintf('''DisplayFilename'',<0-no,1-yes>       display filename of a file before loading it, default yes\n');
fprintf('''UnhandledParError'',<0-no,1-yes>     exit in case not all named parameters are used/known, default is yes\n');

if (examples)
    fprintf('\n');
    fprintf('\n');
    fprintf('Examples:\n');
    fprintf('[frame]=%s(''~/Data10/pilatus/image_1_ct.cbf'');\n',...
        m_file_name);
    fprintf('[frame]=%s({''~/Data10/pilatus/image_1_ct1.cbf'',''~/Data10/pilatus/image_1_ct2.cbf''});\n',...
        m_file_name);
    fprintf('[frame]=%s(''~/Data10/pilatus/S00010/*.cbf'',''IsFmask'',1);\n',...
        m_file_name);
    fprintf('[frame]=%s(''~/Data10/pilatus/image_1_ct.cbf'',''RowFrom'',500,''RowTo'',600);\n',...
        m_file_name);
    fprintf('\n');
    fprintf('The returned structure has the fields data, header, filename and extension.\n');
end
