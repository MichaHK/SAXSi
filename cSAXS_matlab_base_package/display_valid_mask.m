%
% Filename: $RCSfile: display_valid_mask.m,v $
%
% $Revision: 1.2 $  $Date: 2011/08/09 10:03:48 $
% $Author: bunk $
% $Tag: $
%
% Description:
% display a valid pixel mask
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies: 
% none
%
% history:
%
% May 9th 2008, Oliver Bunk: 1st version
%
function [ valid_mask ] = display_valid_mask(varargin)

% set default values for the variable input arguments:
% valid pixel mask
filename_valid_mask = '~/Data10/analysis/data/pilatus_valid_mask.mat';
% figure number
fig_no = 210;
% display help upon startup
no_help = 0;

% accept cell array with name/value pairs as well
no_of_in_arg = nargin;
if (nargin == 1)
    if (isempty(varargin))
        % ignore empty cell array
        no_of_in_arg = no_of_in_arg -1;
    else
        if (iscell(varargin{1}))
            % use a filled one given as first and only variable parameter
            varargin = varargin{1};
            no_of_in_arg = length(varargin);
        end
    end
end

% check number of input arguments
if (rem(no_of_in_arg,2) ~= 0)
    display_help(filename_valid_mask,fig_no);
    error('The optional parameters have to be specified as ''name'',''value'' pairs');
end


% parse the variable input arguments
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        case 'FigNo' 
            fig_no = value;
        case 'FilenameValidMask' 
            filename_valid_mask = value;
        case 'NoHelp' 
            no_help = value;
        otherwise
            error('unknown argument %s',name);
    end
end

% display help
if (~no_help)
    display_help(filename_valid_mask,fig_no);
end

% load the valid pixel mask ind_valid
load(filename_valid_mask);
if (~exist('valid_mask','var'))
    fprintf('Warning: this seems to be an old format of the valid pixel mask. Trying to use it anyway.\n');
    valid_mask.framesize = [framesize1 framesize2];
    fprintf('!!! Mirroring about the vertical axis !!!\n');
    frame = zeros(valid_mask.framesize);
    frame(ind_valid) = 1;
    frame = fliplr(frame);
    valid_mask.indices = find(frame ~= 0);    
end

% mark the valid pixels as 1, leave the invalid at 0
frame = zeros(valid_mask.framesize);
frame(valid_mask.indices) = 1;

% plot the result
figure(fig_no);
imagesc(frame);
axis xy;
axis equal;
axis tight;
colorbar;
title('valid pixels');
set(gcf,'Name','valid pixels');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = display_help(filename_valid_mask,fig_no)

fprintf('Usage:\n');
fprintf('%s([[<name>,<value>],...]);\n',mfilename)
fprintf('The optional <name>,<value> pairs are:\n');
fprintf('''FilenameValidMask'',<path and filename>  Matlab file with the valid pixel indices ind_valid,\n');
fprintf('                                         default is %s\n',filename_valid_mask);
fprintf('''FigNo'',<integer>                        number of the figure in which the result is displayed, default is %d\n',...
    fig_no);
fprintf('\n');
fprintf('A valid pixel mask can be created using the macro prep_valid_mask.\n')
fprintf('\n');

