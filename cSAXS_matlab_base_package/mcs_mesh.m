%
% Filename: $RCSfile: mcs_mesh.m,v $
%
% $Revision: 1.5 $  $Date: 2012/07/30 12:21:28 $
% $Author: bunk $
% $Tag: $
%
% Description:
% Macro for reading .dat files in self-defined data formats
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies:
% - image_read_set_default
% - fopen_until_exists
% - get_hdr_val
% - compiling cbf_uncompress.c increases speed but is not mandatory
%
%
% history:
%
% February 18th 2009, Oliver Bunk: 1st version
%


function [mcs_data] = mcs_mesh(first_scan_no,no_of_intervals,varargin)

% initialize return arguments
mcs_data = [];

% set default parameter
% plot this MCS channel
ch_to_plot = 2;
% create the plot in this figure
fig_no = 2;
% exit with an error message if unhandled named parameters are left at the
% end of this macro
unhandled_par_error = 1;
% file name base
fname_base = '';
% first part of directory path
dir_base = '~/Data10/mcs/';
% scaling factors for the axes
x_scale = 1.0;
y_scale = 1.0;
%
axis_minmax = [];
% save resulting figure
figure_dir = '~/Data10/analysis/online/stxm/figures/';
% save the resulting data
data_dir = '~/Data10/analysis/online/stxm/data/';

% check minimum number of input arguments
if (nargin < 2)
    fprintf('[mcs_data]=%s(<first scan no.>, <no. of line intervals> [[,<name>,<value>] ...]);\n',...
        mfilename);
    fprintf('The optional <name>,<value> pairs are:\n');
    fprintf('''ChToPlot'',<channel no.>              if greater than zero than this channel is plotted, default is %d\n',ch_to_plot);
    fprintf('''FigNo'',<figure number>               plot the data in this figure, 0 for no figure, default is %d\n',fig_no);
    fprintf('''XScale'',<scale factor>               scale the x-axis with this factor\n');
    fprintf('''YScale'',<scale factor>               scale the y-axis with this factor\n');
    fprintf('''AxisMinMax'',<[ min max]>             specify both min and max value\n');    
    fprintf('''DirBase'',<first part of data path>   including an ending slash, default is ''%s''\n',dir_base);
    fprintf('''FnameBase'',<first part of file name> in case of an empty string the current Unix user name is used followed by an underscore, default if ''%s''\n',fname_base);
    fprintf('''FigureDir'',''directory''               save the resulting plot in eps, jpeg and Matlab fig format, '''' for no saving, default is %s\n',figure_dir);
    fprintf('''DataDir'',''directory''                 save the resulting data as Matlab file, '''' for no saving, default is %s\n',data_dir);
    fprintf('The data are in the format ''fast to slow axis'', i.e., the first dimension is the MCS channel,\n');
    fprintf('the second dimension is the exposure index, the third dimension is the fast axis of a mesh scan\n');
    fprintf('and the fourth dimension is the slow axis of a mesh scan.\n');
    error('At least the number of the first scan and the number of line intervals need to be specified as input parameter.');
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



% parse the variable input arguments
vararg = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        case 'ChToPlot'
            ch_to_plot = value;
        case 'FigNo'
            fig_no = value;
        case 'XScale'
            x_scale = value;
        case 'YScale'
            y_scale = value;
        case 'AxisMinMax'
            axis_minmax = value;
        case 'UnhandledParError'
            unhandled_par_error = value;
        case 'FnameBase'
            fname_base = value;
        case 'DirBase'
            dir_base = value;
        case 'DataDir'
            data_dir = value;
        otherwise
            vararg{end+1} = name; %#ok<AGROW>
            vararg{end+1} = value; %#ok<AGROW>
    end
end


% initialize the list of unhandled parameters
vararg_remain = cell(0,0);


% get the current user name
if (length(fname_base) < 1)
    [stat,usr]=unix('echo $USER');
    fname_base = [ sscanf(usr,'%s') '_' ];
end

% initialize the output figure
figure(fig_no);
hold off;
clf;

last_scan_no = first_scan_no + no_of_intervals;
store_ind = 1;
last_draw_time = clock;
for scan_no = first_scan_no:last_scan_no
    dir = [ dir_base 'S' num2str(floor(scan_no/1000)*1000,'%05d') '-' ...
        num2str(floor(scan_no/1000)*1000+999,'%05d') '/S' num2str(scan_no,'%05d') '/' ];
    filename =  [ fname_base num2str(scan_no,'%05d') '.dat' ];

    % read the frame until all data are available
    ind_rep = 0;
    ind_max = 3;
    last_no_of_el_read = 0;
    while (ind_rep < ind_max)
      frame = image_read([dir filename ], 'RetryReadSleep',10, ...
          'RetryReadMax',0, 'RetrySleepWhenFound',10);
      if (frame.no_of_el_read{1} >= numel(frame.data))
          % the complete data set has been read
          break;
      end
      if (frame.no_of_el_read{1} <= last_no_of_el_read)
          % no progress, increase timeout counter
          ind_rep = ind_rep +1;
      else
          ind_rep = 0;
      end
      last_no_of_el_read = frame.no_of_el_read{1};
      exp_time = get_hdr_val(frame.header{1},'Exposure_time','%f',1);
      wait_time = numel(frame.no_of_el_read)*exp_time;
      if (wait_time > 2.0)
          fprintf('%d/%d: frame incomplete (%d/%d), waiting %.1fs and retrying\n',...
              ind_rep+1,ind_max,frame.no_of_el_read{1},numel(frame.data));
      end
      pause(wait_time);
    end

    % initialize return array
    if (scan_no == first_scan_no)
        mcs_data = zeros(size(frame.data,1),size(frame.data,2),...
            size(frame.data,3),no_of_intervals+1);
    end
    
    store_ind_to = store_ind + size(frame.data,4) -1;
    mcs_data(:,:,:,store_ind:(store_ind+size(frame.data,4)-1)) = frame.data;
    store_ind = store_ind_to +1;
    
    if ((scan_no == first_scan_no) || (scan_no == last_scan_no) ||  ...
        (etime(clock,last_draw_time) > 10))
        if (size(mcs_data,2) == 1)
            data_plot = fliplr(flipud(squeeze(mcs_data(ch_to_plot,1,:,:))'));
        else
            data_plot = squeeze(mcs_data(ch_to_plot,:,:,1));
        end
        if ((size(data_plot,1) > 1) && (size(data_plot,2) > 1))
            % 2D plot
            x_values = (1:size(data_plot,2)) * x_scale;
            y_values = (1:size(data_plot,1)) * y_scale;
            imagesc(x_values,y_values,data_plot);
            if (~isempty(axis_minmax))
                caxis(axis_minmax);
            end
            axis xy;
            axis equal;
            axis tight;
            colormap gray;
            colorbar;
        else
            % 1D plot if only one line has been read
            x_values = (1:length(data_plot)) * x_scale;
            plot(x_values,data_plot);
        end
        title( [ fname_base ': #'  num2str(first_scan_no) ' -' num2str(scan_no)] );
        drawnow;
        last_draw_time = clock;
    end
end

% file name for saving
filename = sprintf('stxm_scans_%05d-%05d_mcs',first_scan_no,...
    last_scan_no);

% save figures
if (~isempty(figure_dir))
    figure(fig_no);

    % create output directories and write the plot in different formats
    if (~exist(figure_dir,'dir'))
        mkdir(figure_dir)
    end
    if ((figure_dir(end) ~= '/') && (figure_dir(end) ~= '\')) 
        figure_dir = [ figure_dir '/' ];
    end
    fprintf('output directory for figures is %s\n',figure_dir);
    
    subdir = [ figure_dir 'jpg/' ];
    if (~exist(subdir,'dir'))
        mkdir(subdir);
    end
    fprintf('saving %s.jpg\n',filename);
    print('-djpeg','-r300',[subdir filename '.jpg'] );
    
    subdir = [ figure_dir 'eps/' ];
    if (~exist(subdir,'dir'))
        mkdir(subdir);
    end
    fprintf('saving %s.eps\n',filename);
    print('-depsc','-r1200',[subdir filename '.eps'] );
    
    subdir = [ figure_dir 'fig/' ];
    if (~exist(subdir,'dir'))
        mkdir(subdir);
    end
    fprintf('saving %s.fig\n',filename);
    hgsave([subdir filename '.fig']);    
end

% save resulting data
if (~isempty(data_dir))
    if ((data_dir(end) ~= '/') && (data_dir(end) ~= '\')) 
        data_dir = [ data_dir '/' ];
    end
    
    % create output directory
    if (~exist(data_dir,'dir'))
        mkdir(data_dir)
    end
    
    % save data
    fprintf('saving %s.mat\n',[data_dir filename]);
    save([data_dir filename],'mcs_data','first_scan_no','last_scan_no');
end


