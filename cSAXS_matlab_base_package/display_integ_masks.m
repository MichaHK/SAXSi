%
% Filename: $RCSfile: display_integ_masks.m,v $
%
% $Revision: 1.3 $  $Date: 2010/04/28 18:00:16 $
% $Author: bunk $
% $Tag: $
%
% Description:
% display azimuthal integration masks
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies: 
% none
%
% history:
%
% October 2nd 2009, Oliver Bunk: 1st version
%
function [ valid_mask ] = display_integ_masks(filename_frame,varargin)

% set default values for the variable input arguments:
% valid pixel mask
filename_integ_masks = '~/Data10/analysis/data/pilatus_integration_masks.mat';
% figure number
fig_no = 220;

% accept cell array with name/value pairs as well
no_of_in_arg = nargin;
if (nargin > 1)
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
if (rem(no_of_in_arg,2) ~= 1)
    display_help(filename_integ_masks,fig_no);
    error('The optional parameters have to be specified as ''name'',''value'' pairs');
end


% parse the variable input arguments
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        case 'FigNo' 
            fig_no = value;
        case 'FilenameIntegMasks' 
            filename_integ_masks = value;
        otherwise
            error('unknown argument %s',name);
    end
end

% load the integration masks integ_masks
load(filename_integ_masks);
% load the example frame
frame = image_read(filename_frame);

frame_plot = frame.data;
frame_plot( frame_plot < 1 ) = 1;

plot_step = round(length(integ_masks.indices)/50);
if (plot_step < 2)
    plot_step = 2;
end
ind_r_max = size(integ_masks.indices,1);
for (ind_r = 1:plot_step:ind_r_max)
    for (ind_seg = 1:no_of_segments)
        if (rem(ind_seg,2) == 1)
            pixel_value = 2;
        else
            pixel_value = 10^(6*ind_seg/no_of_segments);
        end
        frame_plot(integ_masks.indices{ind_r,ind_seg}) = pixel_value;
        if ((plot_step > 8) && (ind_r +2 < ind_r_max))
            frame_plot(integ_masks.indices{ind_r+1,ind_seg}) = pixel_value;
            frame_plot(integ_masks.indices{ind_r+2,ind_seg}) = pixel_value;
        end
    end
end

% plot the result
figure(fig_no);
imagesc(log10(frame_plot));
colormap(franzmap);
axis xy;
axis equal;
axis tight;
colorbar;
title('integration masks');
set(gcf,'Name','valid pixels');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = display_help(filename_valid_mask,fig_no)

fprintf('Usage:\n');
fprintf('%s(filename, [[<name>,<value>],...]);\n',mfilename)
fprintf('The optional <name>,<value> pairs are:\n');
fprintf('''FilenameIntegMasks'',<path and filename>  Matlab file with the integration masks,\n');
fprintf('                                          default is %s\n',filename_valid_mask);
fprintf('''FigNo'',<integer>                         number of the figure in which the result is displayed, default is %d\n',...
    fig_no);
fprintf('\n');
fprintf('Integration masks can be created using the macro prep_integ_masks.\n')
fprintf('\n');

