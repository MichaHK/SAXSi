%
% Filename: $RCSfile: get_beam_center.m,v $
%
% $Revision: 1.4 $  $Date: 2011/04/07 17:57:03 $
% $Author: bunk $
% $Tag: $
%
% Description:
% try to find the center of a radially symmetric SAXS pattern
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies: 
% - image_read
% - prep_integ_masks
%
% history:
%
% May 9th 2008, Oliver Bunk: 1st documented version
%
function [ center_xy ] = get_beam_center(filename,varargin)

% set default values for the variable input arguments:
% beam center guess
guess_x = 512;
guess_y = 512;
% +/- test range in pixels around the good guess
test_x = 3;
test_y = 3;
% angular beam-stop region to exclude
bs_angle_from = 0;
bs_angle_to = 0;
% integration range
r_from = 50;
r_step = 1;
r_to = 60;
% figure number for display
fig_no = 230;
% directory and filename with the valid pixel mask
filename_valid_mask = '~/Data10/analysis/data/pilatus_valid_mask.mat';
% check minimum number of input arguments
if (nargin < 1)
    fprintf('Usage:\n');
    fprintf('[center_xy]=%s(filename [[,<name>,<value>] ...]);\n',mfilename)
    fprintf('The optional <name>,<value> pairs are:\n');
    fprintf('''GuessX'',<integer>                    good guess for the beam center in x\n');
    fprintf('''GuessY'',<integer>                    good guess for the beam center in y\n');
    fprintf('''TestX'',<integer>                   check +/- this many pixel around the good guess, default in x is %d\n',...
        test_x);
    fprintf('''TestY'',<integer>                   check +/- this many pixel around the good guess, default in y is %d\n',...
        test_y);
    fprintf('''BeamstopAngleFrom'',<float>         exclude an angular region from the integration, default for the start value is %d\n',...
        bs_angle_from);
    fprintf('''BeamstopAngleTo'',<float>           exclude an angular region from the integration, default for the end value is %d\n',...
        bs_angle_to);
    fprintf('''RadiusFrom'',<integer>              radial integration start radius, default is %d\n',r_from);
    fprintf('''RadiusStep'',<integer>              radial integration step size, default is %d\n',r_step);
    fprintf('''RadiusFrom'',<integer>              radial integration end radius, default is %d\n',r_to);
    fprintf('''FilenameValidMask'',<path and filename>  Matlab file with the valid pixel indices ind_valid,\n');
    fprintf('                                    default is %s\n',filename_valid_mask);
    fprintf('''FigNo'',<integer>                   number of the figure in which the result is displayed\n');
    fprintf('\n');
    fprintf('Extending the test region will slow down the processing in an unbearable amount.\n');
    fprintf('Therefore the good guess should be really good and the test area kept at its default value.\n');
    fprintf('\n');
    fprintf('Example:\n');
    fprintf('[cen]=%s(''~/Data10/pilatus/image_silver_behenate_10sec.cbf'',''GuessX'',512,''GuessY'',512,''RadiusFrom'',50,''RadiusTo'',60);\n',...
        mfilename);
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


% parse the variable input arguments
vararg_remain = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        case 'GuessX' 
            guess_x = round(value);
        case 'GuessY' 
            guess_y = round(value);
        case 'TestX' 
            test_x = value;
        case 'TestY' 
            test_y = value;
        case 'BeamstopAngleFrom' 
            bs_angle_from = value;
        case 'BeamstopAngleTo' 
            bs_angle_to = value;
        case 'RadiusFrom' 
            r_from = value;
        case 'RadiusStep' 
            r_step = value;
        case 'RadiusTo' 
            r_to = value;
        case 'FilenameValidMask' 
            filename_valid_mask = value;
        case 'FigNo' 
            fig_no = value;
        otherwise
            vararg_remain{end+1} = name; %#ok<AGROW>
            vararg_remain{end+1} = value; %#ok<AGROW>
    end
end

   
% load the calibration image
fprintf('loading %s\n',filename);
frame = image_read(filename,vararg_remain);

% plot the calibration image
figure(fig_no);
hold off;
clf;
frame_plot = frame.data(:,:,1);
frame_plot(frame_plot < 1) = 1;
% mark the good guess for the beam center
frame_plot(guess_y,(guess_x-20):(guess_x+20)) = 1e6;
frame_plot((guess_y-20):(guess_y+20),guess_x) = 1e6;
imagesc(log10(frame_plot));
axis xy;
axis equal;
axis tight
colorbar;
title([ 'beam center guess marked at (' num2str(guess_x,'%.0f') ...
    ',' num2str(guess_y,'%.0f') ')' ]);
set(gcf,'Name','beam center guess');
drawnow;

% calculate the standard deviation along the integration circles for all
% beam centers within the test range
y = (guess_y-test_y):(guess_y+test_y);
x = (guess_x-test_x):(guess_x+test_x);
ind_x_max = length(x);
ind_y_max = length(y);
ind_total = ind_x_max * ind_y_max;
std_val = zeros(ind_y_max,ind_x_max);
arg_prep_integ_masks = cell(1,length(vararg_remain)+16);
arg_prep_integ_masks{ 1} = 'RadiusFrom';
arg_prep_integ_masks{ 2} = r_from;
arg_prep_integ_masks{ 3} = 'RadiusTo';
arg_prep_integ_masks{ 4} = r_to;
arg_prep_integ_masks{ 5} = 'RadiusStep';
arg_prep_integ_masks{ 6} = r_step;
arg_prep_integ_masks{ 7} = 'SaveData';
arg_prep_integ_masks{ 8} = 0;
arg_prep_integ_masks{ 9} = 'FilenameValidMask';
arg_prep_integ_masks{10} = filename_valid_mask;
arg_prep_integ_masks{11} = 'DisplayValidMask';
arg_prep_integ_masks{12} = 0;
arg_prep_integ_masks{13} = 'BeamstopAngleFrom';
arg_prep_integ_masks{14} = bs_angle_from;
arg_prep_integ_masks{15} = 'BeamstopAngleTo';
arg_prep_integ_masks{16} = bs_angle_to;
arg_prep_integ_masks(17:end) = vararg_remain;

for (ind_y = 1:ind_y_max)
    for (ind_x = 1:ind_x_max)
        fprintf('%3d / %3d\n',(ind_y-1)*ind_x_max + ind_x,ind_total);
        [ integ_masks ] = ...
            prep_integ_masks( filename, [x(ind_x) y(ind_y)], ...
                arg_prep_integ_masks);
%                 'RadiusFrom',r_from,'RadiusTo',r_to,'RadiusStep',r_step,...
%                 'SaveData',0, ...
%                 'FilenameValidMask',filename_valid_mask,...
%                 'DisplayValidMask',0,...
%                 'BeamstopAngleFrom',bs_angle_from,...
%                 'BeamstopAngleFrom',bs_angle_to);
        
        ind_r_max = length(integ_masks.radius);
        % sum standard deviation over circle segments
        norm_by = 0;
        for (ind_r = 1:ind_r_max)
            if (integ_masks.norm_sum(ind_r,1) > 0)
                std_val(ind_y, ind_x) = std_val(ind_y, ind_x) + ...
                    std(frame.data(integ_masks.indices{ind_r,1})) / ...
                        integ_masks.norm_sum(ind_r,1);
                norm_by = norm_by +1;
            end
        end
        if (norm_by > 0)
            std_val(ind_y, ind_x) = std_val(ind_y, ind_x) / norm_by;
        end
    end
end
   
% find the beam center of minimum standard deviation
[min_y ind_y] = min(std_val);
[min_x ind_x] = min(min_y);
ind_y = ind_y(ind_x);
cen_x_coarse = x(ind_x);
cen_y_coarse = y(ind_y);

% interpolate center within three pixels
cen_x = cen_x_coarse;
if ((ind_x > 1) && (ind_x < size(std_val,2)))
    denom = std_val(ind_y, ind_x +1) - 2*std_val(ind_y,ind_x) + ...
        std_val(ind_y,ind_x -1);
    if (abs(denom) > 1e-6)
         cen_x = cen_x + 0.5 - ...
            (std_val(ind_y,ind_x+1)-std_val(ind_y,ind_x)) / denom;
    end
end

cen_y = cen_y_coarse;
if ((ind_y > 1) && (ind_y < size(std_val,1)))
    denom = std_val(ind_y +1, ind_x) - 2*std_val(ind_y,ind_x) + ...
        std_val(ind_y -1,ind_x);
    if (abs(denom) > 1e-6)
        cen_y = cen_y + 0.5 - ...
            (std_val(ind_y+1,ind_x)-std_val(ind_y,ind_x)) / denom;
    end
end

% compile return argument
center_xy = [ cen_x cen_y ];

% display the result
fprintf('Minimum standard deviation position interpolated to (%.3f,%.3f)\n',...
    cen_x,cen_y);

% plot the standard deviation as a function of tested pixel coordinates
figure(fig_no +1);
surf(x,y,std_val);
colorbar;
title( ['standard deviation of the radial integration, center = (' ...
    num2str(cen_x,'%.1f') ', ' num2str(cen_y,'%.1f') ')' ] );
xlabel('x [ pixel ]');
ylabel('y [ pixel ]');
set(gcf,'Name','standard deviation');
