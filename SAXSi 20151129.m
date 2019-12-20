function varargout = SAXSi(varargin)
%global handles
% SAXSI M-file for SAXSi.fig
%      SAXSI, by itself, creates a new SAXSI or raises the existing
%      singleton*.
%
%      H = SAXSI returns the handle to a new SAXSI or the handle to
%      the existing singleton*.
%
%      SAXSI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SAXSI.M with the given input arguments.
%
%      SAXSI('Property','Value',...) creates a new SAXSI or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SAXSi_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SAXSi_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SAXSi

% Last Modified by GUIDE v2.5 29-Nov-2015 16:56:46

% Taken from "X-ray transition energies: new approach to a comprehensive evaluation", Rev. Mod. Phys. 75, 35–99 (2003)
WaveEnergyFor1Angstrom_eV = 12398.41857; % ev
WaveEnergyFor1Angstrom_KeV = WaveEnergyFor1Angstrom_eV * 1e-3;


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SAXSi_OpeningFcn, ...
    'gui_OutputFcn',  @SAXSi_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


function dirName_Callback(hObject, eventdata, handles)
SetDirectory(hObject, get(handles.dirName, 'String'));

function [menu] = CopyMenu(parent, original)
menu = uimenu(parent, ...
    'UserData', get(original, 'UserData'), ...
    'Callback', get(original, 'Callback'), ...
    'Separator', get(original, 'Separator'), ...
    'Label', get(original, 'Label'), ...
    'Checked', get(original, 'Checked'));

children = get(original, 'Children');
newChildren = [];
for i = 1:numel(children)
    c = children(i);
    newChildren(end+1) = CopyMenu(menu, c);
end

for i = 1:numel(children)
    set(newChildren(i), 'Position', get(children(i), 'Position'));
end
1;

% --- Executes just before SAXSi is made visible.
function SAXSi_OpeningFcn(hObject, eventdata, handles, varargin)
%global handles
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SAXSi (see VARARGIN)

try
saxsiPath = which('SAXSi');
saxsiFolder = fileparts(saxsiPath);
addpath(saxsiFolder);
addpath([saxsiFolder filesep 'CONEX']);
addpath([saxsiFolder filesep 'Conic']);
addpath([saxsiFolder filesep 'cSAXS_matlab_base_package']);

% Choose default command line output for SAXSi
handles.output = hObject;
refresh_period =  1; %setappdata(handles.fig_main,'refreshRate','2');
handles.isWithinLoadSettings = 0;

% Update handles structure
guidata(hObject, handles);
%plotedit on
% plotbrowser on
% propertyeditor('on')

%showplottool('on','tool')

% Current directory.
if isdeployed
    root_cur = [ctfroot '' filesep '..'];
else
    root_cur = fileparts(mfilename('fullpath'));
end

[~, ~, versionShortText, ~] = GetVersion();
set(handles.VersionTextBox, 'String', versionShortText);

handles.Bindings = BindingsClass();
handles.CalibrationData = CalibrationDataClass();
handles.IntegrationParams = IntegrationParamsClass();
handles.DisplayOptions = DisplayOptionsClass();
handles.GeneralOptions = GeneralOptionsClass();
handles.State = SAXSiStateClass(); % Intended for transient information (not saved for next sessions)
handles.FastIntegrationCache = FastIntegrationCacheClass();
handles.MaskBitmap = [];
guidata(hObject, handles);

% First try to load previous settings
try
    loadsettingbu_Callback(hObject, [], handles, true);
catch err
    h = errordlg(sprintf('There was some problem loading the default settings.\nSAXSi will try to initialize anyway.\n\nIf the problem persists, please delete the file "defaults.sxs".'));
    waitfor(h);
end

handles = guidata(hObject);
handles.isWithinLoadSettings = 1;
guidata(hObject, handles);

[pathn,nv,exv]=fileparts(mfilename('fullpath'));
addpath(pathn,0);
handles.DirIn=[];
handles.qvec=[];
handles.Ivec=[];
handles.xhivec=[];
handles.Ixhivec=[];
handles.ImatMul=[];


guidata(hObject, handles);

axes (handles.axes1);
plot (1,1,'x');
set(handles.calcText,'String','SAXSi is ready');
% setappdata(handles.fig_main,'imIn',[]);
% setappdata(handles.fig_main,'qvec',[]);
% setappdata(handles.fig_main,'Ivec',[]);
% setappdata(handles.fig_main,'ImatMul',[]);

LoadFileFilters(hObject);

Timers = [];
Timers.timeDisplayTimer = timer('ExecutionMode', 'fixedRate', ...
    'Period', 1, ...
    'StartDelay', 0, ...
    'TimerFcn', {@TimedUpdateForTimeDisplay, handles.fig_main});
Timers.monitoring = timer('ExecutionMode', 'fixedRate', ...
    'Period', handles.DisplayOptions.FileRefreshInterval, ...
    'StartDelay', 0, ...
    'TimerFcn', {@TimedFileMonitoringHandler, handles.fig_main});
setappdata(handles.fig_main,'Timers',Timers);

%pause (1);
try
    start(Timers.timeDisplayTimer);
    %start(Timers.monitoring);
catch
    display ('error'); % flag as error/warning needing to be thrown at end
end

% Update handles structure
initialize_gui(hObject, handles, false);

BindSelectionMenuDisplay(handles.Bindings, handles.DisplayOptions, ...
    'Displayed1dScaleType', ...
    {handles.DisplayScaleInAMenuItem, ...
    handles.DisplayScaleInNMMenuItem, ...
    handles.DisplayScaleInvertedInA, ...
    handles.DisplayScaleInvertedInNM, ...
    handles.DisplayScaleInDegrees}, ...
    [1:5], @plotit);

copyOfDisplayOptionsMenu = CopyMenu(handles.PlotMenu, handles.DisplayScaleMenuItem);

UpdateCalibrationDataDisplay(hObject);
UpdateIntegrationParamsDisplay(hObject);
UpdateDisplayOptionsDisplay(hObject);

switchIt_Callback(hObject, [], handles);
SetDirectory(hObject, handles.DisplayOptions.Directory);
AutoRefreshCheckbox_Callback(handles.AutoRefreshCheckbox, [], handles);

handles.isWithinLoadSettings = 0;
guidata(hObject, handles);

RefreshFilesList(hObject);

% Block inputs until the application ends
if (isdeployed() || ~strcmp(lower(getenv('COMPUTERNAME')), 'jeremyah'))
    % UIWAIT makes SAXSi wait for user response (see UIRESUME)
    %uiwait(handles.fig_main);
    
    % Save settings for next time
    %saveDefaultSettings(hObject)
    
    %license ('inuse') % Display toolboxes used
end

catch err
    msgbox(err.message);
end

1;

% --- Outputs from this function are returned to the command line.
function varargout = SAXSi_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;
% Timers = getappdata(handles.fig_main,'Timers');
% stop(Timers.monitoring);
% saveDefaultSettings(hObject)
% set (gca,'xcolor',[1 1 1]);
% set (gca,'ycolor',[1 1 1]);
license ('inuse')

varargout={1};

function UpdateAllBoundMenuItems(hObject, handles)

selectionMenuBindings = handles.Bindings.SelectionMenuBindings;
for i = 1:numel(selectionMenuBindings)
    UpdateBoundSelectionMenuItems(hObject, handles, selectionMenuBindings{i});
end
1;

function UpdateBoundSelectionMenuItems(hObject, handles, bindingData)
menuItems = bindingData.DisplayElementsBound;
values = bindingData.Values;
currentValue = handles.DisplayOptions.(bindingData.ClassFieldName);
indexInGroup = find(values == currentValue);

for i = [1:indexInGroup-1 indexInGroup+1:numel(menuItems)]
    set(menuItems{i}, 'Checked', 'off');
end

set(menuItems{indexInGroup}, 'Checked', 'on');
1;

function HandleBoundSelectionMenuItem(hObject, ~, handles)
userData = get(hObject, 'UserData');
bindingData = userData{1};
value = userData{2};
postAction = userData{3};

handles.DisplayOptions.(bindingData.ClassFieldName) = value;

postAction(hObject);

% Update menu
UpdateBoundSelectionMenuItems(hObject, handles, bindingData);
1;

function BindSelectionMenuDisplay(Bindings, DisplayOptions, classField, menuItems, values, postAction)
currentValue = DisplayOptions.(classField);

bindingData = BindingDataClass();
bindingData.ClassFieldName = classField;
bindingData.DisplayElementsBound = menuItems;
bindingData.Values = values;
Bindings.SelectionMenuBindings{end+1} = bindingData;

for i = 1:numel(menuItems)
    mi = menuItems{i};
    
    set(mi, 'UserData', {bindingData, values(i), postAction});
    set(mi, 'Callback', @(o, ed)HandleBoundSelectionMenuItem(o,ed,guidata(o)));
end

1;


function [finalMask] = GetMask(hObject, handles)
%if (isempty(handles.MaskBitmap) || any(size(handles.MaskBitmap) > size(handles.State.Image)))
if (isempty(handles.MaskBitmap))
    handles.MaskBitmap = zeros(size(handles.State.Image));
    guidata(hObject, handles);
end

% Image larger than the mask?... complete the mask to match
handles = ExpandMaskToMatchImage(hObject, handles);
guidata(hObject, handles);

% Automatically mask negative values as well
finalMask = handles.MaskBitmap(...
    1:min(size(handles.State.Image, 1), size(handles.MaskBitmap, 1)), ...
    1:min(size(handles.State.Image, 2), size(handles.MaskBitmap, 2)) ...
    );

%finalMask(handles.State.Image < 0) = 1;

function DrawMask(hObject, shouldRotate, shouldRedraw)

if (nargin < 2)
    shouldRotate = 0;
end

if (nargin < 3)
    shouldRedraw = 0;
end

handles = guidata(hObject);
mask = GetMask(hObject, handles);

if (shouldRotate)
    mask = mask';
end

if (isempty(handles.State.MaskHandle) || ~ishandle(handles.State.MaskHandle))
    if (~isempty(mask))
        %axes(handles.axes1);
        %hold on;
        maskImage = zeros([size(handles.State.Image), 3]);
        maskImage(:, :, 1) = 1;
        handles.State.MaskHandle = image(maskImage, 'AlphaDataMapping', 'none', 'AlphaData', mask);
        set(handles.State.MaskHandle, 'UIContextMenu', handles.PlotMenu);
    end
else
    if (~isempty(mask))
        set(handles.State.MaskHandle, 'AlphaData', mask);
    end
end

function [matrixToAdjust] = ExpandOrCropToMatch(matrixToAdjust, matrixToMatch, doNotCrop)

if (nargin < 3)
    doNotCrop = 0;
end

if (numel(matrixToMatch) == 2)
    sizeToMatch = matrixToMatch;
else
    sizeToMatch = size(matrixToMatch);
end

if (any(size(matrixToAdjust) > 4e3))
    matrixToAdjust = [];
end

if (any(size(matrixToMatch) > 5e3))
    error('To large a matrix to match! Is this a valid image file?...');
end

if (size(matrixToAdjust, 2) < sizeToMatch(2))
    matrixToAdjust(:, size(matrixToAdjust, 2)+1:sizeToMatch(2)) = 0;
elseif (~doNotCrop && size(matrixToAdjust, 2) > sizeToMatch(2))
    matrixToAdjust(:, sizeToMatch(2)+1:size(matrixToAdjust, 2)) = [];
end

if (size(matrixToAdjust, 1) < sizeToMatch(1))
    matrixToAdjust(size(matrixToAdjust, 1)+1:sizeToMatch(1), :) = 0;
elseif (~doNotCrop && size(matrixToAdjust, 1) > sizeToMatch(1))
    matrixToAdjust(sizeToMatch(1)+1:size(matrixToAdjust, 1), :) = [];
end


function [handles] = ExpandMaskToMatchImage(hObject, handles)
if (any(size(handles.State.Image) > size(handles.MaskBitmap)))
    handles.MaskBitmap = ExpandOrCropToMatch(handles.MaskBitmap, size(handles.State.Image), 1);
end


% --- Executes on button press in load2dButton.
function load2dButton_Callback(hObject, eventdata, handles)
% hObject    handle to load2dButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

tStart = tic;

filenameList = get(handles.filenameListBox, 'String');
fullPathsList = get(handles.filenameListBox, 'UserData');
vl=get(handles.filenameListBox,'value');

if ~isempty (filenameList)
%     if (get(handles.switchIt,'value') ~= 2)
%         set(handles.switchIt,'value',2);
%     end
    
    %fn=fullfile(get(handles.dirName,'String'),filenameList{vl});
    fn=fullPathsList{vl};
    handles.State.FilePath = fn;
    
    % Commented out by Ram (Oct 12 2012) because the image update method
    % has changed. No need to re-focus on the axes.
    % TODO: Worth checking "gca" if the current axes are already these.
    % because it turns out this actually takes a lot of time to execute.
    %axes(handles.axes1);
    
    
    image = squeeze(read2D(fn, 1));
    
    if (ndims(image) == 3)
        if (0) % Should break-up into frames?
        else
            image = squeeze(mean(image, 1));
        end
    elseif (numel(size(image))> 3) % Image has too many dimensions
        errordlg(sprintf('Image has too many dimensions. Should have 2!\n\n(is this an RGB image you are trying to load?...)'));
        return;
    end
    
    handles.State.Image = image;
    
    %if (isempty(handles.MaskBitmap) || any(size(handles.MaskBitmap) ~= size(handles.State.Image)))
    if (isempty(handles.MaskBitmap))
        clearmaskbu_Callback(hObject, 0, handles);
        handles = guidata(hObject);
    elseif (any(size(handles.MaskBitmap) < size(handles.State.Image)))
        handles = ExpandMaskToMatchImage(hObject, handles);
    end
else
    handles.State.Image=[];
end

% Update handles structure
guidata(hObject, handles);

if (any(get(handles.switchIt,'value') == [2 5 6]))
    plotit(hObject, [], 0, 0);
end

if handles.State.Image
    set(handles.calcText,'String','Error loading');
else
    set(handles.calcText,'String',strcat('SAXSi is showing: ', filenameList{vl}));
end

tElapsed=toc(tStart);
display(sprintf('Took %0.3f seconds to execute "load2d_Callback"', tElapsed));



% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)
% If the metricdata field is present and the ClearButton flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to ClearButton the data.
if isfield(handles, 'metricdata') && ~isreset
    return;
end






function refreshTm_Callback(hObject, eventdata, handles)
% hObject    handle to refreshTm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of refreshTm as text
%        str2double(get(hObject,'String')) returns contents of refreshTm as a double
handles.DisplayOptions.FileRefreshInterval = str2num(get(hObject, 'String'));
SaveAndUpdateDisplayOptions(hObject);

Timers = getappdata(handles.fig_main, 'Timers');
stop(Timers.monitoring);
set(Timers.monitoring, 'Period', handles.DisplayOptions.FileRefreshInterval);
start(Timers.monitoring);


% --- Executes during object creation, after setting all properties.
function refreshTm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refreshTm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function [filter] = getFilenameFilter(handles)
filter = handles.DisplayOptions.FilesFilter;

function TimedUpdateForTimeDisplay(obj,event,hObject)
handles = guidata(hObject);
set (handles.timeStr, 'String', datestr(clock));
1;

function RefreshFilesList(hObject)
handles = guidata(hObject);
DisplayOptions = handles.DisplayOptions;
directory_name = DisplayOptions.Directory;

[listOfFiles, listOfFilePaths, newFileIndexes, newestFileTime] = finddiffdir(...
    directory_name, getFilenameFilter(handles), ...
    DisplayOptions);

DisplayOptions.LastSeenFileTime = newestFileTime;

if (0) % Diamond patch - display sample name
    for i = 1:numel(listOfFiles)
        [folder, filename, ext] = fileparts(listOfFilePaths{i});
        
        if (strcmp(ext, '.h5'))
            parts = strsplit(filename, '-');
            
            if (numel(parts) == 3 && strcmp(parts{1}, 'i22')) % Let's verify some more stuff
                prefix = strjoin(parts(1:2), '-');
                
                nxsFilePath = [folder filesep prefix '.nxs'];
                if (exist(nxsFilePath, 'file'))
                    try
                        sampleName = h5read(nxsFilePath, '/entry1/sample/name');
                        sampleName = sampleName{1};
                        if (sampleName(end) == 0); sampleName = sampleName(1:end-1); end
                        
                        listOfFiles{i} = [sampleName ' (' listOfFiles{i} ')'];
                    catch err
                    end
                end
            end
        end
        1;
    end
end


set(handles.filenameListBox, 'String', listOfFiles);
set(handles.filenameListBox, 'UserData', listOfFilePaths);

if (get(handles.filenameListBox, 'value') > length(listOfFiles))
    set (handles.filenameListBox, 'value', 1);
end

if (~isempty(newFileIndexes) && handles.DisplayOptions.AutoAddNewFiles)
    for i = 1:length(newFileIndexes)
        handles = addingnew(hObject, handles, listOfFiles, ...
            listOfFiles(newFileIndexes(i)), directory_name, false, true);
    end
end
1;

% Monitoring thread. (cf. help timer)
function TimedFileMonitoringHandler(obj, event, hObject)


try
    handles = guidata(hObject);
catch
    stop(obj); % GUI must have closed... stop timer
    return;
end

handles.State.FileMonitoringRefreshCounter = handles.State.FileMonitoringRefreshCounter + 1;
display(sprintf('Running "TimedFileMonitoringHandler" (%d)', handles.State.FileMonitoringRefreshCounter));

if (handles.State.IsFileMonitoringCurrentlyRunning)
    display('Previous "TimedFileMonitoringHandler" is still running...');
    return;
end

handles.State.IsFileMonitoringCurrentlyRunning = 1;

try
    RefreshFilesList(hObject);
    
    % Because if the refresh time exceeds the timer's period,
    % it could result in the display having no time to update
    drawnow();
catch
end
handles.State.IsFileMonitoringCurrentlyRunning = 0;


function UpdateIntegrationParamsFieldFromUI(hObject, fieldName, convertValueHandler)
% UpdateIntegrationParamsFieldFromUI(hObject, fieldName, convertValueHandler)

handles = guidata(hObject);
IntegrationParams = handles.IntegrationParams;

style = get(hObject, 'Style');
if (strcmp(style, 'edit') || strcmp(style, 'text'))
    value = get(hObject, 'String');
elseif (strcmp(style, 'checkbox') || strcmp(style, 'popupmenu') || ...
        strcmp(style, 'listbox') || strcmp(style, 'togglebutton'))
    value = get(hObject, 'Value');
else
    value = [];
end

if (nargin > 2 && ~isempty(convertValueHandler))
    value = convertValueHandler(value);
end

IntegrationParams.(fieldName) = value;
UpdateIntegrationParamsDisplay(hObject);
plotit(hObject,handles);
saveDefaultSettings(hObject)

%--- Executes on selection change in filenameListBox.
function filenameListBox_Callback(hObject, eventdata, handles)
% hObject    handle to filenameListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns filenameListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from filenameListBox
contents = get(hObject, 'String');
fullPathsList = get(hObject, 'UserData');

val=get(hObject,'Value');

if (any(get(handles.switchIt,'value') == [2 5 6]))
    if (numel(val) > 1)
        set(hObject,'Value', val(1));
    end
    
    load2dButton_Callback(hObject, eventdata, handles)
elseif (numel(val) > 0)
    dirName = get(handles.dirName,'String');
    
    
    lp = LongProcessStarted(numel(val), 'files');
    
    try
        for i = 1:numel(val)
            if (~LongProcessStep(lp, i, [])); break; end
            
            filePath = fullPathsList{val(i)};
            [folder, filenameWithoutExt, ext] = fileparts(filePath);
            if (0) %strcmp(ext, '.h5')) % Read frames of h5 file (used in Diamond)
                dset = hdf5read(filePath, '/entry/instrument/detector/data');
                numOfFrames = size(dset, 3);
                
                for f = 1:numOfFrames
                    handles = addingnew(hObject, handles, [filePath ';' num2str(f)], false, false);
                end
            else
                handles = addingnew(hObject, handles, filePath, false, false);
            end
            
        end
    catch err
        beep;
    end
    
    LongProcessEnded(lp);
    
    plotit(hObject, handles);
    % TODO: Why was this here?? load2dButton_Callback(hObject, eventdata, handles)
    set(hObject, 'Value', val(1));
end

function [handles] = addingnew(hObject, handles, filepath, shouldReintegrate, shouldPlot)

[folder, filenameWithoutExt, ext] = fileparts(filepath);
filename = [filenameWithoutExt, ext];
handles.hObjectAdding = hObject;
% Update handles structure
guidata(hObject, handles);

oldlist = get(handles.DisplayedFilesList, 'String');
alreadyInTheFilesList = false;

curveIndex = numel(handles.State.Curves) + 1;

for i = 1:numel(handles.State.Curves)
    if (strcmp(fullfile(handles.State.Curves(i).Folder), fullfile(folder)) && ...
        strcmp(handles.State.Curves(i).Filename, [filenameWithoutExt ext]))
        alreadyInTheFilesList = true;
        curveIndex = i;
    end
end

if ~alreadyInTheFilesList || shouldReintegrate % If not already on the list 
    
    CalibrationData = handles.CalibrationData;
    IntegrationParams = handles.IntegrationParams;
    GeneralOptions = handles.GeneralOptions;
    
    try
        maskIn = GetMask(hObject, handles);
    catch
        maskIn = [];
    end
    set(handles.calcText,'String','Calculating...please wait');
    
    %'calculating'
    guidata(hObject, handles);
    
    if (get(handles.dezingerCheck, 'value'))
        dezingerPer = str2num(get(handles.dezingerPer, 'String'))
    else
        dezingerPer = 0;
    end
    
    handles.State.FilePath = filepath;

    % Integrate the image
    [curve, xhiCurve, wasRead, fileNameForDisplay] = ...
        readOrIntigrate (filepath, ...
        GeneralOptions, CalibrationData, IntegrationParams, maskIn, ...
        shouldReintegrate || ~handles.GeneralOptions.ShouldLoadIntegratedFileInsteadOfIntegrating, ...
        handles.FastIntegrationCache, ...
        dezingerPer);
    
    if (~wasRead)
        if (handles.GeneralOptions.SaveIntegrationToFsiFile)
            mat = [curve.Q(:), curve.I(:), curve.IErr(:)];
            curveFilename = ReplaceFileExtension(filepath, '.fsi');
            save(curveFilename, 'mat', '-ascii');
        end
        
        if (handles.GeneralOptions.SaveIntegrationFsxFile)
            if (~isempty(xhiCurve) && ~isempty(xhiCurve.I))
                mat = [xhiCurve.Angle, xhiCurve.I, xhiCurve.IErr];
                xhiCurveFilename = ReplaceFileExtension(filepath, '.fsx');
                save(xhiCurveFilename, 'mat', '-ascii');
            end
        end
        
        % Generate output file if doesn't already exist
        if (handles.GeneralOptions.SaveIntegrationToDatFile)
            [imageFileFolder, imageFileName, imageFileExt] = fileparts(filepath);
            datFilepath = ReplaceFileExtension(filepath, '.dat');
            
            SaveCurveToDatFile(curve, datFilepath, filepath, CalibrationData, IntegrationParams, (handles.GeneralOptions.SaveIntegrationToDatFile == 2));
        end
    end
    
    if ((length(curve.Q)==length(curve.I)) & (length(curve.Q))) | ( ~isempty(xhiCurve.I))
%         if get(handles.checkboxSubBck, 'Value')
%             try
%                 % Subtract
%                 matBck = load(get(handles.bckFN, 'String'), '-ascii');
%                 qBck = matBck(:,1);
%                 IBck = matBck(:,2);
%                 IBck_int = str2num(get(handles.mulBck, 'String')) .* interp1(qBck, IBck, qv, 'linear', 'extrap');
%                 iv = iv - IBck;
%                 
%                 % Save
%                 mat = [qv, iv];
%                 fullImagePath = fullfile(dirName, filename)
%                 [pathstr, name, ext] = fileparts(fullImagePath);
%                 newfilena = fullfile(pathstr, [name '.fsi']);
%                 copyfile(newfilena, fullfile(pathstr, [name '_nbck.fsi']));
%                 save (newfilena, 'mat', '-ascii');
%                 
%                 % Write to info file
%                 fidw = fopen(fullfile(pathstr, [name '.info']), 'w+');
%                 fprintf(fidw, 'I=Imeasured - c*Ibck \n subtracting from file %s after multiplying by %g \n', ...
%                     get(handles.bckFN, 'String'), str2num(get(handles.mulBck, 'String')));
%                 close(fidw);
%                 
%             catch
%                 disp ('error in subtracting bck');
%             end
%         end
        

        curve.Metadata = struct();
        %curve.Filename = filename;
        curve.Filename = fileNameForDisplay;
        curve.Folder = folder;
        xhiCurve.Filename = filename;
        xhiCurve.Folder = folder;
        
        if (isempty(handles.State.Curves))
            handles.State.Curves = curve;
        else
            handles.State.Curves(curveIndex) = curve;
        end
        
        if (isempty(handles.State.XhiCurves))
            handles.State.XhiCurves = xhiCurve;
        else
            handles.State.XhiCurves(curveIndex) = xhiCurve;
        end
        
        set (handles.DisplayedFilesList,'String', {handles.State.Curves.Filename});
        
        %  set(handles.switchIt,'Value',1);
        set(handles.calcText,'String','SAXSi is ready');
        
        guidata(hObject, handles);
        
        if shouldPlot
            figure (handles.fig_main);
            plotit(hObject, handles);
        end
    end
else
    beep;
end

function plotit (hObject, ~, sOutFlag, shouldRedraw)
handles = guidata(hObject);

if (nargin < 3)
    sOutFlag = false;
end

if (nargin < 4)
    shouldRedraw = 1;
end

plotType = get(handles.switchIt, 'Value');
justSwitched = (plotType ~= handles.State.LastPlotType);
handles.State.LastPlotType = plotType;

set(handles.calcText, 'String', 'SAXSi is plotting');
%pause(0.01); % Removed by Ram
%plotedit(gcf)

%     xl = xlim(handles.axes1);
%     yl = ylim(handles.axes1);
%     xlim(handles.axes1, xl);
%     ylim(handles.axes1, yl);

switch (plotType)
    case {1, 3} % 1d, Xhi
        [sOutFlag, handles] = plotit1D(hObject, handles, sOutFlag);
        
    case 2 % image
        [sOutFlag, handles] = plotit2D(hObject, handles, shouldRedraw | justSwitched, sOutFlag);
        
    case 4 % pixel count
        [sOutFlag, handles] = plotitPixelPerBinCount(hObject, handles, sOutFlag);
        
    case 5 % anisotropy 2d
        [sOutFlag, handles] = plotit2D(hObject, handles, shouldRedraw | justSwitched, sOutFlag, 2);
        
    case 6 % residuals 2d
        [sOutFlag, handles] = plotit2D(hObject, handles, shouldRedraw | justSwitched, sOutFlag, 3);
        
        
    otherwise
end

guidata(hObject, handles);

% set (handles.axes1,'ButtonDownFcn','selectmoveresize');
set(handles.calcText,'String','SAXSi is ready');
% if get(handles.resizeWinButton,'value')
%
%     chil=get(gcf,'child');
%     for ind=1:length(chil)
%         if (strcmp(get(chil(ind),'type'),'axes') & (chil(ind)~=handles.axes1))
%             delete(chil(ind));
%         end
%     end
% end
%Update handles structure
if sOutFlag
    Out=handles.Out;
    save ('forSaxsi.mat','Out');
end
1; % end of "plotit" function

function DrawQConic(hObject, handles, q, color, lineWidth)

if (nargin < 4)
    color = [0 0 0];
end

if (nargin < 5)
    lineWidth = 2;
end

CalibrationData = handles.CalibrationData;
twoK = 4 * pi / CalibrationData.Lambda;

conic = ConicClass();

% Draw the min conic
conic.SetConexParameters(CalibrationData.AlphaRadians, ...
    CalibrationData.SampleToDetDist / CalibrationData.PixelSize,...
    CalibrationData.BeamCenterX, CalibrationData.BeamCenterY,...
    CalibrationData.BetaRadians, 2 * asin(q / twoK));

if (0) % Plot the whole conic?
    [x,y] = conic.GetPointsFromParametricForm(linspace(0, 2*pi, 200));
    plot(x, y, '-', 'LineWidth', lineWidth, 'Color', color);
else % Plot only segments of the conic within the image
    [segments] = conic.GetSegmentsWithinRect([1, 1, size(handles.State.Image, 2)-1, size(handles.State.Image, 1)-1]);
    for seg = 1:size(segments, 1)
        [x,y] = conic.GetPointsFromParametricForm(linspace(segments(seg, 1), segments(seg, 2), 200));
        plot(x, y, '-', 'LineWidth', lineWidth, 'Color', color);
    end
end
1;

function [coloredImage] = MapColors(intensityImage, colorMap, ...
    lowestIntensity, highestIntensity)

if (~exist('lowestIntensity', 'var'))
    lowestIntensity = min(intensityImage(:));
end

if (~exist('highestIntensity', 'var'))
    highestIntensity = max(intensityImage(:));
end

intensityImage(intensityImage < lowestIntensity) = lowestIntensity;
intensityImage(intensityImage > highestIntensity) = highestIntensity;
intensityRange = highestIntensity - lowestIntensity;

if (intensityRange > 0)
    intensityImage = (intensityImage - lowestIntensity) ./ intensityRange;
end

coloredImage = zeros([size(intensityImage), 3]);
1;

function [result] = IsSameImageSize(i1, i2)
s1 = size(i1);
s2 = size(i2);
result = (numel(s1)==numel(s2) && all(s1 == s2));

function [sOutFlag, handles] = plotit2D (hObject, handles, shouldRedraw, sOutFlag, preprocessingType)

if (~exist('shouldRedraw', 'var'))
    shouldRedraw = 1;
end

if (~exist('preprocessingType', 'var'))
    preprocessingType = 0;
end


imageToDisplay = handles.State.Image;

if (preprocessingType > 0)
    CalibrationData = handles.CalibrationData;
    IntegrationParams = handles.IntegrationParams;
    GeneralOptions = handles.GeneralOptions;
    
    maskIn = GetMask(hObject, handles);
    
    set(handles.calcText, 'String', 'Calculating...please wait');
    
    if (get(handles.dezingerCheck, 'value'))
        dezingerPercentile = str2num(get(handles.dezingerPer, 'String'))
    else
        dezingerPercentile = 0;
    end
    
    % Integrate the image
    [curve, xhiCurve] = Integrate (...
        handles.State.Image, maskIn, ...
        handles.CalibrationData, handles.IntegrationParams, ...
        handles.FastIntegrationCache, dezingerPercentile);
    
    I = [curve.I; -1];
    I = I(handles.FastIntegrationCache.ImageToQMatrix(:));
    I = reshape(I, size(handles.State.Image));
    
    switch (preprocessingType)
        case 2
            imageToDisplay = double(handles.State.Image) ./ I;
            
        case 3
            factor = double(handles.State.Image) ./ I;
            factor = mean(factor(factor > 0));
            
            imageToDisplay = double(handles.State.Image) - I;
            
        otherwise
            imageToDisplay = I;
    end
    
    %imageToDisplay = conv2(imageToDisplay, ones(3) ./ 9, 'same');
end


if (~isempty(imageToDisplay))
    imageToDisplay = Get2dIntensity(imageToDisplay, handles.DisplayOptions);
    
    shouldRedraw = shouldRedraw || ...
        (numel(handles.State.LastImageDimensions) ~= numel(size(imageToDisplay))) || ...
        any(handles.State.LastImageDimensions ~= size(imageToDisplay));
    handles.State.LastImageDimensions = size(imageToDisplay);
    
    maskBitmap = GetMask(hObject, handles);

    if (~isempty(maskBitmap) && IsSameImageSize(imageToDisplay, maskBitmap))
        imageAsVector = imageToDisplay .* (maskBitmap == 0);
        imageAsVector = imageAsVector(:);
    else
        imageAsVector = imageToDisplay(:);
    end
    
    imageAsVector = imageAsVector(imageAsVector >= 0);
    imageMax = max(imageAsVector);
    imageSum = double(sum(imageAsVector));
else
    imageMax = 1e3;
    imageSum = 0;
end

isAutoMaxIntensityEnabled = handles.DisplayOptions.AutoMaxIntensity;
if (isAutoMaxIntensityEnabled)
    set(handles.cLimMaxnew, 'String', num2str(imageMax));
end

if (0)
    intensityLoLim = str2num(get(handles.cLimMinnew,'string'));
    intensityHiLim = str2num(get(handles.cLimMaxnew,'string'));
    [coloredImage] = MapColors(imageToDisplay, colorMap, intensityLoLim, intensityHiLim);
end

shouldRotate = 0;

%axes(handles.axes1);
if (~isempty(imageToDisplay))
    if (handles.DisplayOptions.Normalize2dImageOrientation ~= 0)
        [~, longDim] = max(size(imageToDisplay));
        if (longDim ~= 1)
            imageToDisplay = imageToDisplay';
            shouldRotate = 1;
        end
    end
end

handles.State.DisplayedImage = imageToDisplay;

if (~shouldRedraw) % Just replace data, do not fully redraw
    if (~isempty(imageToDisplay))
        
        hold on
        set(handles.State.ImageHandle, 'CData', handles.State.DisplayedImage);
        hold off;
        
        set(handles.axes1,'clim',[str2num(get(handles.cLimMinnew,'string')),str2num(get(handles.cLimMaxnew,'string'))]);
        
        DrawMask(hObject, shouldRotate, 0);
        
    return;
    end
end

if (gca ~= handles.axes1)
    axes(handles.axes1);
end

hold off
if ~isempty(imageToDisplay)
    imageHandle = image (imageToDisplay,'CDataMapping','scaled', ...
        'AlphaDataMapping', 'none');
    
    axis equal;
    %xlim([1 size(imageToDisplay, 2)]);
    %ylim([1 size(imageToDisplay, 1)]);
    xlim('auto');
    ylim('auto');
    set(handles.axes1,'clim',[str2num(get(handles.cLimMinnew,'string')),str2num(get(handles.cLimMaxnew,'string'))]);
    %    set(gca,'clim',[str2num(handles.cLimMinnew),str2num(handles.cLimMaxnew)]);
    set(imageHandle, 'UIContextMenu', handles.PlotMenu);
    handles.State.ImageHandle = imageHandle;
    guidata(hObject, handles);
end

axR=axis;
hold on
%[get(handles.axes1, 'OuterPosition'), get(handles.axes1, 'Position')]

DrawMask(hObject, shouldRotate, 1);

lenIm=length(imageToDisplay);

x0 = handles.CalibrationData.BeamCenterX;
y0 = handles.CalibrationData.BeamCenterY;
pixsize = handles.CalibrationData.PixelSize;
%rmin=param(7);rmax=param(8);
if handles.DisplayOptions.shouldFlipY
    y0=lenIm-y0;
end

plot (x0,y0,'wx','MarkerSize',12);

CalibrationData = handles.CalibrationData;

if (handles.IntegrationParams.QMin > 0 && handles.IntegrationParams.QMax > handles.IntegrationParams.QMin)
    % Draw the min conic
    q = handles.IntegrationParams.QMin;
    DrawQConic(hObject, handles, handles.IntegrationParams.QMin);
    
    % Draw the max conic
    DrawQConic(hObject, handles, handles.IntegrationParams.QMax);
end

qMarks = handles.State.QMarks;

for i = 1:length(qMarks)
    q = qMarks{i}.Q;
    if (qMarks{i}.Visible && q >= handles.IntegrationParams.QMin)
        DrawQConic(hObject, handles, q, qMarks{i}.Color, qMarks{i}.Width);
        
        derivedQs = qMarks{i}.Series * q;
        derivedQs(derivedQs < handles.IntegrationParams.QMin) = [];
        derivedQs(derivedQs > handles.IntegrationParams.QMax) = [];
        % Draw the chosen series as well
        for q = derivedQs
            DrawQConic(hObject, handles, q, qMarks{i}.Color, qMarks{i}.Width);
        end
        
    end
end

% For debug...
%DrawQConic(hObject, handles, 0.05, 'red', 1);

% h2=circle ([x0 y0],rmin,100,'k'); %/pixsize
% set(h2,'LineWidth',2);
% h2=circle ([x0 y0],rmax,100,'k');
% set(h2,'LineWidth',2);
hold off
xlabel('x'); ylabel('y');
axis (axR);
axis equal;

% Write some info
set(handles.InfoText, 'String', '');
[~, fileName, fileExt] = fileparts(handles.State.FilePath);
infoText = sprintf('%s\nMax/Total Intensity: %g / %g\n',...
    fileName, imageMax, imageSum);
%[fileName fileExt], imageMax, imageSum);
set(handles.InfoText, 'String', infoText);
1;

function [curves] = GetCurvesToBeUsed(hObject, handles)
if (~exist('handles', 'var') || isempty(handles))
    handles = guidata(hObject);
end

filenamelist = get(handles.DisplayedFilesList, 'String');

shouldDisplayOnlySelected = get(handles.UseOnlySelectedCheckbox, 'Value');

if (~shouldDisplayOnlySelected)
    which = true(size(filenamelist));
else
    which = false(size(filenamelist));
    tmp = get(handles.DisplayedFilesList, 'Value');
    which(tmp) = true;
end

curves = handles.State.Curves(which);

function [sOutFlag,handles] = plotit1D (hObject,handles,sOutFlag)
DisplayOptions = handles.DisplayOptions;
filenamelist = get(handles.DisplayedFilesList, 'String');
shouldDisplayOnlySelected = get(handles.UseOnlySelectedCheckbox, 'Value');

if (~shouldDisplayOnlySelected)
    which = true(size(filenamelist));
else
    which = false(size(filenamelist));
    tmp = get(handles.DisplayedFilesList, 'Value');
    which(tmp) = true;
end

In.notfirst = ~DisplayOptions.IsDisplayCleared;

numOfFilesCurrentlyDisplayed = numel(find(which));

if (numOfFilesCurrentlyDisplayed)
    %In.notfirst = (numOfFilesCurrentlyDisplayed > 1);
    
    In.diff = DisplayOptions.SpreadCurvesBy;
    In.filenames = filenamelist(which);
    In.fid = handles.axes1;
    In.SP = DisplayOptions.SpreadCurvesMethod;
    In.flagedit = false;
    
    if (get(handles.switchIt,'Value')==1)
        handles.Out = readitAxes (handles.State.Curves(which), handles.DisplayOptions, handles.CalibrationData, In);
    elseif (get(handles.switchIt,'Value')==3)
        try
            handles.Out = readitAxes (handles.State.XhiCurves(which), handles.DisplayOptions, handles.CalibrationData, In, 'Angle');
            %fix what to do when there is no xhi plots to read ---> I think
        catch
            disp ('no Xhi to plot!');
            %it is ok now! %%%%%
        end
        set (gca,'XScale','linear');
        xlabel ('\chi (deg)')
        ylabel ('I (a.u.)');
    end
    DisplayOptions.IsDisplayCleared = 0;
else
    axes(handles.axes1);
    handles.Out=[];
    cla;
    legend off;
    DisplayOptions.IsDisplayCleared = 1;
end

if (~isfield(handles, 'axes2'))
    handles.axes2 = [];
end

if (~isempty(handles.axes2) && ishandle(handles.axes2))
    %cla(handles.axes2);
else
    handles.axes2 = axes('Position', get(handles.axes1, 'Position'), ...
        'XScale', get(handles.axes1, 'XScale'), ...
        'YScale', get(handles.axes1, 'YScale'), ...
        'Color', 'none', 'Visible', 'off');
end

%propedit(handles.axes2);
linkaxes([handles.axes1 handles.axes2], 'xy')

guidata(hObject, handles);
axes(handles.axes2);

1;

function [sOutFlag,handles] = plotitPixelPerBinCount (hObject,handles,sOutFlag)
filenamelist = get(handles.DisplayedFilesList,'String');
len = length(filenamelist);

maskIn = GetMask(hObject, handles);
im = ones(size(maskIn));

try
    integrated = IntFast(im, maskIn, ...
        handles.CalibrationData, handles.IntegrationParams, 0, handles.FastIntegrationCache);
    q = integrated.Q;
    
    % TODO: Understand why the last item is ok to be dropped
    I = accumarray(handles.FastIntegrationCache.ImageToQMatrix(:), double(im(:)),[],@sum);
    integrated.I = I(1:end-1);
    
    In.diff = 0;
    In.filenames = filenamelist;
    In.fid = handles.axes1;
    In.SP = 1;
    In.flagedit = false;
    In.notfirst = false;
    
    handles.Out = readitAxes(integrated, handles.DisplayOptions, handles.CalibrationData, In);
    xlabel ('q(Å^{-1})')
    ylabel ('Pixel Count');
    legend('off');
catch
end
1;

% --- Executes during object creation, after setting all properties.
function filenameListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filenameListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function filterNameEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to filterNameEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filterNameEditBox as text
%        str2double(get(hObject,'String')) returns contents of filterNameEditBox as a double
handles.DisplayOptions.FilesFilter = get(handles.filterNameEditBox, 'String');
SaveAndUpdateDisplayOptions(hObject);
RefreshFilesList(hObject);

% --- Executes during object creation, after setting all properties.
function filterNameEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filterNameEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chgDir.
function chgDir_Callback(hObject, eventdata, handles)
% hObject    handle to chgDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dirname = uigetdir(get(handles.dirName,'String'),'Select dirctory');
SetDirectory(hObject, dirname);


function HandleRecentFolderMenuItem(hObject, eventdata)
dirname = get(hObject, 'UserData');
SetDirectory(hObject, dirname);
1;

function UpdateRecentFolderMenuItems(hObject, eventdata, handles)
recentFoldersMenuItems = get(handles.RecentFoldersMenuItem, 'Children');

if (numel(recentFoldersMenuItems) < 10)
    for i = numel(recentFoldersMenuItems)+1:10
        uimenu(handles.RecentFoldersMenuItem, 'Label', '', 'UserData', '', 'Callback', @HandleRecentFolderMenuItem);
    end
    recentFoldersMenuItems = get(handles.RecentFoldersMenuItem, 'Children');
end

positions = get(recentFoldersMenuItems, 'Position');
[~, order] = sort([positions{:}]);
recentFoldersMenuItems = recentFoldersMenuItems(order);

for i = 1:numel(handles.DisplayOptions.RecentFolders)
    set(recentFoldersMenuItems(i), ...
        'Label', handles.DisplayOptions.RecentFolders{i}, ...
        'UserData', handles.DisplayOptions.RecentFolders{i});
end

1;

function SetDirectory(hObject, dirname)
handles = guidata(hObject);

if (~isempty(dirname) && exist(dirname, 'dir'))
    dirname = fullfile(dirname); % Normalize the name
    if (dirname(end) == '/' || dirname(end) == '\')
        dirname = dirname(1:end-1);
    end
    
    wasRecent = cellfun(@(s)strcmpi(dirname, s), handles.DisplayOptions.RecentFolders);
    handles.DisplayOptions.RecentFolders(wasRecent) = [];
    handles.DisplayOptions.RecentFolders = {dirname handles.DisplayOptions.RecentFolders{:}};
    
    if (numel(handles.DisplayOptions.RecentFolders) > 10)
        handles.DisplayOptions.RecentFolders = handles.DisplayOptions.RecentFolders(1:10);
    end
    
    handles.DisplayOptions.Directory = dirname;
    handles.DisplayOptions.LastSeenFileTime = [];
    
    set(handles.filenameListBox,'Value',1);
    set(handles.dirName, 'String', dirname);
    
    % Update handles structure
    handles.DirIn = [];
    guidata(hObject, handles);
    
    saveDefaultSettings(hObject);
end
UpdateRecentFolderMenuItems(hObject, [], handles);
RefreshFilesList(hObject);

% --- Executes on button press in refreshDir.
function refreshDir_Callback(hObject, eventdata, handles)
% hObject    handle to refreshDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
RefreshFilesList(hObject);

% --- Executes on selection change in DisplayedFilesList.
function DisplayedFilesList_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayedFilesList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
shouldDisplayOnlySelected = get(handles.UseOnlySelectedCheckbox, 'Value');
if (shouldDisplayOnlySelected)
    plotit (hObject, handles);
end


% --- Executes during object creation, after setting all properties.
function DisplayedFilesList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DisplayedFilesList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on selection change in filenameListbox.
function filenameListbox_Callback(hObject, eventdata, handles)
% hObject    handle to filenameListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns filenameListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from filenameListbox


% --- Executes during object creation, after setting all properties.
function filenameListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filenameListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in autoaddnew.
function autoaddnew_Callback(hObject, eventdata, handles)
% hObject    handle to autoaddnew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.DisplayOptions.AutoAddNewFiles = get(hObject, 'Value');
SaveAndUpdateDisplayOptions(hObject);



% --- Executes on button press in flipTag.
function flipTag_Callback(hObject, eventdata, handles)
DisplayOptions = handles.DisplayOptions;
DisplayOptions.shouldFlipY = (get(handles.flipTag, 'Value') == 1);
SaveAndUpdateDisplayOptions(hObject);
plotit(hObject,handles);

function qmax_Callback(hObject, eventdata, handles)
UpdateIntegrationParamsFieldFromUI(hObject, 'QMax', @(x)str2double(x));

% --- Executes during object creation, after setting all properties.
function qmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to qmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bmy_Callback(hObject, eventdata, handles)
handles.CalibrationData.BeamCenterY = str2double(get(handles.bmy, 'String'));
UpdateCalibrationDataDisplay(hObject);
saveDefaultSettings(hObject);
plotit(hObject, handles);

% --- Executes during object creation, after setting all properties.
function bmy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bmy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function s2d_Callback(hObject, eventdata, handles)
handles.CalibrationData.SampleToDetDist = str2double(get(handles.s2d, 'String'));
UpdateCalibrationDataDisplay(hObject);
saveDefaultSettings(hObject);
plotit(hObject, handles);

% --- Executes during object creation, after setting all properties.
function s2d_CreateFcn(hObject, eventdata, handles)
% hObject    handle to s2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function pxSz_Callback(hObject, eventdata, handles)
handles.CalibrationData.UpdatePixelSize(str2double(get(handles.pxSz, 'String')));
%handles.CalibrationData.PixelSize = str2double(get(handles.pxSz, 'String'));
UpdateCalibrationDataDisplay(hObject);
saveDefaultSettings(hObject);
plotit(hObject, handles);

% --- Executes during object creation, after setting all properties.
function pxSz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pxSz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function lambda_Callback(hObject, eventdata, handles)
handles.CalibrationData.Lambda = str2double(get(handles.lambda, 'String'));
UpdateCalibrationDataDisplay(hObject);
saveDefaultSettings(hObject);
plotit(hObject, handles);

% --- Executes during object creation, after setting all properties.
function lambda_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lambda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function qStepsCount_Callback(hObject, eventdata, handles)
UpdateIntegrationParamsFieldFromUI(hObject, 'QStepsCount', @(x)str2double(x));


% --- Executes during object creation, after setting all properties.
function qStepsCount_CreateFcn(hObject, eventdata, handles)
% hObject    handle to qStepsCount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function qmin_Callback(hObject, eventdata, handles)
UpdateIntegrationParamsFieldFromUI(hObject, 'QMin', @(x)str2double(x));

% --- Executes during object creation, after setting all properties.
function qmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to qmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bmx_Callback(hObject, eventdata, handles)
handles.CalibrationData.BeamCenterX = str2double(get(handles.bmx, 'String'));
UpdateCalibrationDataDisplay(hObject);
saveDefaultSettings(hObject);
plotit(hObject, handles);

% --- Executes during object creation, after setting all properties.
function bmx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bmx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in switchIt.
function switchIt_Callback(hObject, eventdata, handles)
% hObject    handle to switchIt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

zoomLim = [get(handles.axes1, 'xlim'); get(handles.axes1, 'ylim')];
handles.DisplayOptions.ZoomInEachView{handles.DisplayOptions.CurrentPlotType} = zoomLim;

plotType = get(handles.switchIt,'Value');
handles.DisplayOptions.CurrentPlotType = plotType;
SaveAndUpdateDisplayOptions(hObject);
plotit(hObject,handles);

if (numel(handles.DisplayOptions.ZoomInEachView) >= plotType && ...
    ~isempty(handles.DisplayOptions.ZoomInEachView{plotType}))

    zoomLim = handles.DisplayOptions.ZoomInEachView{handles.DisplayOptions.CurrentPlotType};
    set(handles.axes1, 'xlim', zoomLim(1, :));
    set(handles.axes1, 'ylim', zoomLim(2, :));
end

%axis tight


% --- Executes during object creation, after setting all properties.
function switchIt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to switchIt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called





function spread_Callback(hObject, eventdata, handles)
% hObject    handle to spread (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
DisplayOptions = handles.DisplayOptions;
DisplayOptions.SpreadCurvesBy = str2double(get(handles.spread, 'string'));
SaveAndUpdateDisplayOptions(hObject);
plotit(hObject,handles);

% --- Executes during object creation, after setting all properties.
function spread_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spread (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on selection change in slist.
function slist_Callback(hObject, eventdata, handles)
handles.DisplayOptions.SpreadCurvesMethod = get(handles.slist, 'Value');
SaveAndUpdateDisplayOptions(hObject);
plotit(hObject,handles);

% --- Executes during object creation, after setting all properties.
function slist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in dobeamstop.
function dobeamstop_Callback(hObject, eventdata, handles)
axes(handles.axes1);
[x,y,button] = ginput(1);

if (button == 1)
    handles.CalibrationData.BeamCenterX = x;
    handles.CalibrationData.BeamCenterY = y;
    UpdateCalibrationDataDisplay(hObject);
    plotit(hObject,handles);
end

% --- Executes on button press in RminBu.
function QminBu_Callback(hObject, eventdata, handles)
% hObject    handle to RminBu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
o=ginput(1);

[q, theta] = XY2QValue(o(1), o(2), handles.CalibrationData);
handles.IntegrationParams.QMin = q;

UpdateIntegrationParamsDisplay(hObject);
plotit(hObject,handles);

% --- Executes on button press in RmaxBu.
function QmaxBu_Callback(hObject, eventdata, handles)
axes(handles.axes1);
o=ginput(1);

[q, theta] = XY2QValue(o(1), o(2), handles.CalibrationData);
handles.IntegrationParams.QMax = q;

UpdateIntegrationParamsDisplay(hObject);
plotit(hObject,handles);


% --- Executes on button press in reintigrateButton.
function reintigrateButton_Callback(hObject, eventdata, handles)
% hObject    handle to reintigrateButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[curves] = GetCurvesToBeUsed(hObject, handles);

filenames = {curves.Filename};
folders = {curves.Folder};

set(handles.DisplayedFilesList,'String',[]);

waitBarHandle = [];
tStarted = tic();
shouldShowProgress = 0;

filenamesThatFailed = {};

try
    for i = 1:length (curves)
        try
            tElapsed = toc(tStarted);
            done = (i-1)/numel(curves);
            estimatedTimeLeft = tElapsed * (1-done) / done;
            
            if (~shouldShowProgress)
                if (tElapsed > 3 && estimatedTimeLeft > 2)
                    shouldShowProgress = 1;
                    waitBarHandle = waitbar(0, 'This is taking too long...', ...
                        'CreateCancelBtn', 'setappdata(gcbf, ''canceling'', 1)');
                    setappdata(waitBarHandle, 'canceling', 0);
                end
            end
            
            if (shouldShowProgress)
                waitbar(done, waitBarHandle, sprintf('%d/%d files done (%0.1f%%). Approximately %0.0f more seconds.', i-1, numel(outfilename), done*100, estimatedTimeLeft))
                
                % Did the user click "cancel"?
                if (getappdata(waitBarHandle, 'canceling'))
                    break;
                end
            end
            
            handles = addingnew(hObject, handles, fullfile(folders{i}, filenames{i}), true, false);
        catch ex
            filenamesThatFailed{end + 1} = filenames{i};
        end
    end
catch err
    1;
end

if (~isempty(waitBarHandle))
    delete(waitBarHandle);
end

% Update handles structure
guidata(hObject, handles);
plotit(hObject,handles);

if (numel(filenamesThatFailed) > 0)
    msgbox([sprintf('Failed reintegration on some files:\r\n') sprintf('%s \r\n', filenamesThatFailed{:})], 'Failed reintegration on some files');
end



% --- Executes on button press in exportFigure.
function exportFigure_Callback(hObject, eventdata, handles)
% hObject    handle to exportFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cf=gcf;
fid=figure;
handles.axes1Copy = handles.axes1;
handles.axes1=gca;
% Update handles structure
guidata(hObject, handles);
plotit(hObject,handles);
fixThisGraphFid (fid)
%legend hide
%plotedit on
%propertyeditor('on')
%plotbrowser on
axis tight
figure(cf);
handles.axes1 = handles.axes1Copy;
%axes(handles.axes1);
rmfield(handles, 'axes1Copy');

% Update handles structure
guidata(hObject, handles);

function [maskBitmap] = ConvertOldFormatMaskToMaskBitmap(maskIn)

maskIn(maskIn(:) < 1) = 1;

endXY = maskIn(:, 1:2) + maskIn(:, 3:4);
maxXY = max(endXY, [], 1);

maskBitmap = zeros(ceil([maxXY(2), maxXY(1)]));

for rectIndex = 1:size(maskIn, 1)
    rect = maskIn(rectIndex, :);
    maskBitmap(ceil(rect(2)):floor(rect(2)+rect(4)), ceil(rect(1)):floor(rect(1)+rect(3))) = 1;
end


% --- Executes on button press in loadmaskBu.
function loadmaskBu_Callback(hObject, eventdata, handles)
% hObject    handle to loadmaskBu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currentFolder = handles.DisplayOptions.GetDirectory();
[fn,pathn] = uigetfile('*.msk', 'Load mask file', currentFolder);
if fn
    try
        maskData = load (fullfile(pathn,fn),'-mat');
        
        if (isfield(maskData, 'maskIn')) % Old format
            MaskBitmap = ConvertOldFormatMaskToMaskBitmap(maskData.maskIn);
        else
            MaskBitmap = maskData.MaskBitmap;
        end
        
        handles.MaskBitmap = MaskBitmap;
        handles.FastIntegrationCache.Clear();
    catch err
        msgbox(err.message);
    end
end

% Update handles structure
guidata(hObject, handles);
plotit(hObject, handles);

% --- Executes on button press in clearmaskbu.
function clearmaskbu_Callback(hObject, eventdata, handles)
% hObject    handle to clearmaskbu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%handles.MaskBitmap = zeros(size(handles.State.Image));
handles.MaskBitmap = [];
% Update handles structure
guidata(hObject, handles);

handles.FastIntegrationCache.Clear();

% --- Executes on button press in addmaskbu.
function addmaskbu_Callback(hObject, eventdata, handles)
% hObject    handle to addmaskbu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%handles.MaskBitmap=MakemaskMat(handles.maskIn);
%handles.TrasformMat.param=zeros(1,11);
% Update handles structure
%guidata(hObject, handles);

% --- Executes on button press in savemaskBu.
function savemaskBu_Callback(hObject, eventdata, handles)
% hObject    handle to savemaskBu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

currentFolder = handles.DisplayOptions.GetDirectory();

[fn,pathn] = uiputfile('*.msk', 'Save mask file', currentFolder);
if fn
    len=length(fn);
    if ~(strcmp(upper(fn(len-3:len)),'.MSK'))
        fn=[fn '.msk'];
    end
    MaskBitmap = handles.MaskBitmap;
    save(fullfile(pathn,fn),'-mat','MaskBitmap');
end


% --- Executes on button press in refreshG.
function redrawMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to redrawMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotit(hObject, handles, 0, 1);
%resetZoomMenuItem_Callback(hObject, eventdata, handles);

% --- Executes on button press in getxyBu.
function getxyBu_Callback(hObject, eventdata, handles)
% hObject    handle to getxyBu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Left mouse button picks points.')
disp('Right mouse button picks last point.')
but = 1;
while but == 1
    [xi,yi,but] = ginput(1);
    
    
    imageToQMatrix = handles.FastIntegrationCache.ImageToQMatrix;
    
    q = 0;
    if (~isempty(imageToQMatrix))
        try
            q = handles.FastIntegrationCache.QVector(imageToQMatrix(round(yi), round(xi)));
        catch
        end
    end
    
    displayedImage = get(handles.State.ImageHandle, 'CData');
    v = displayedImage(round(yi), round(xi));
    
    str = sprintf('x=%i y=%i q=%f value=%f', xi, yi, q, v);
    %str=['x=',num2str(xi),' y=',num2str(yi)];
    set(handles.calcText,'String',str)
    % Update handles structure
    guidata(hObject, handles);
    refresh ;
end
set(handles.calcText,'String','SAXSi is ready');
% Update handles structure
guidata(hObject, handles);
refresh;


function SaveAndUpdateDisplayOptions(hObject)
UpdateDisplayOptionsDisplay(hObject);
saveDefaultSettings(hObject);

function saveDefaultSettings(hObject)
savesetting_Callback(hObject, [], guidata(hObject), true);

% --- Executes on button press in savesetting.
function savesetting_Callback(hObject, eventdata, handles, shouldSaveDefaults)
% hObject    handle to savesetting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (~exist('shouldSaveDefaults', 'var') || isempty(shouldSaveDefaults))
    shouldSaveDefaults = false;
end

% Avoid saving the currently loaded setting
if (handles.isWithinLoadSettings)
    return;
end

currentFolder = handles.DisplayOptions.GetDirectory();

if (~shouldSaveDefaults)
    [fn,pathn]=uiputfile('*.sxs', 'Save settings file', currentFolder);
else
    fn='defaults.sxs';
    [pathn,nv,exv]=fileparts(mfilename('fullpath'));
end
if fn
    len=length(fn);
    if ~(strcmp(upper(fn(len-3:len)),'.SXS'))
        fn=[fn '.sxs'];
    end
    try
        CalibrationData = handles.CalibrationData;
        IntegrationParams = handles.IntegrationParams;
        DisplayOptions = handles.DisplayOptions;
        GeneralOptions = handles.GeneralOptions;
        maskBitmap = handles.MaskBitmap;
        %listboxRmv=get (handles.DisplayedFilesList,'String');
        
        %save (fullfile(pathn,fn),'-mat','handles',...
        save (fullfile(pathn,fn),'-mat', 'maskBitmap', ...
            'CalibrationData', 'IntegrationParams', 'DisplayOptions', 'GeneralOptions');
    catch
        disp ('error in saving');
        beep
    end
end

function [h] = LoadSettings(hObject, fn)
handles = guidata(hObject);
handles.isWithinLoadSettings = 1;
guidata(hObject, handles);

try
    h = load (fn,'-mat');
    
    currentDataFolder = handles.DisplayOptions.Directory;
    currentRecentFolders = handles.DisplayOptions.RecentFolders;
    
    % Old file?...
    if (~isfield(h, 'CalibrationData'))
        vars = load (fn, '-mat', 'handles', 'alpha', 'beta', 'bmx', 'bmy', 's2d', ...
            'pxSz', 'lambda', 'flipTag', 'binSz', 'rmin', 'rmax',...
            'threshold', 'spread', 'filterName');
        
        CalibrationData = struct();
        
        CalibrationData.PixelSize = str2double(vars.pxSz);
        CalibrationData.AlphaDegrees = str2double(vars.alpha);
        CalibrationData.AlphaRadians = CalibrationData.AlphaDegrees*pi/180;
        CalibrationData.BetaDegrees = str2double(vars.beta);
        CalibrationData.BetaRadians = CalibrationData.BetaDegrees*pi/180;
        CalibrationData.SampleToDetDist = str2double(vars.s2d);
        CalibrationData.BeamCenterX = str2double(vars.bmx);
        CalibrationData.BeamCenterY = str2double(vars.bmy);
        CalibrationData.Lambda = str2double(vars.lambda);
        
        % Copy into internal object
        handles.CalibrationData.CopyFrom(CalibrationData);
        
        IntegrationParams = struct();
        IntegrationParams.QStepsCount = str2double(vars.binSz);
        
        % This is actually wrong, but obsolete anyways. It is fixed a
        % Calculate Q instead of "r" (assume circle, which is not
        % accurate, but most time good enough)
        IntegrationParams.QMin = handles.CalibrationData.GetQForXY(CalibrationData.BeamCenterX + str2double(vars.rmin), CalibrationData.BeamCenterY);
        IntegrationParams.QMax = handles.CalibrationData.GetQForXY(CalibrationData.BeamCenterX + str2double(vars.rmax), CalibrationData.BeamCenterY);
        
        IntegrationParams.shouldDoXhi = false;
        IntegrationParams.Threshold = str2double(vars.threshold);
        
        % Copy into internal object
        handles.IntegrationParams.CopyFrom(IntegrationParams);
        
        DisplayOptions = struct();
        DisplayOptions.SpreadCurvesBy = vars.spread;
        DisplayOptions.shouldFlipY = vars.flipTag;
        DisplayOptions.CurrentPlotType = 2;
        DisplayOptions.FilesFilter = vars.filterName;
        
        if (~isempty(handles.DisplayOptions.Directory))
            DisplayOptions.Directory = handles.DisplayOptions.Directory;
        else
            DisplayOptions.Directory = cd;
        end
        
        % Copy into internal object
        handles.DisplayOptions.CopyFrom(DisplayOptions);
        
        if (isfield(vars.handles, 'maskIn') && ~isempty(vars.handles.maskIn))
            maskBitmap = ConvertOldFormatMaskToMaskBitmap(vars.handles.maskIn);
            handles.MaskBitmap = maskBitmap;
        end
        
        %GeneralOptions = struct();
    else
        if (isfield(h, 'CalibrationData')); handles.CalibrationData.CopyFrom(h.CalibrationData); end
        if (isfield(h, 'IntegrationParams')); handles.IntegrationParams.CopyFrom(h.IntegrationParams); end
        if (isfield(h, 'DisplayOptions')); handles.DisplayOptions.CopyFrom(h.DisplayOptions); end
        if (isfield(h, 'GeneralOptions')); handles.GeneralOptions.CopyFrom(h.GeneralOptions); end
    end
    
    % Restore current data folder
    handles.DisplayOptions.Directory = currentDataFolder;
    handles.DisplayOptions.RecentFolders = currentRecentFolders;
    
    % Override for now. Not sure users would want this option to persist
    handles.DisplayOptions.AutoAddNewFiles = 0;
    % Override for now. Not sure users would want this option to persist
    handles.DisplayOptions.ShouldSearchFilesRecursively = 0;
    
    UpdateCalibrationDataDisplay(hObject);
    UpdateIntegrationParamsDisplay(hObject);
    UpdateDisplayOptionsDisplay(hObject);
    UpdateGeneralOptionsDisplay(hObject);
    %SetDirectory(hObject, handles.DisplayOptions.Directory);
catch
    h=handles;
end

try
    if (isfield(h, 'maskBitmap'))
        handles.MaskBitmap = h.maskBitmap;
    end
catch err
    handles.MaskBitmap=[];
end    

try
    fieldNames = fieldnames(h.handles.TrasformMat);
    for fieldIndex = 1:numel(fieldNames)
        handles.TrasformMat.(fieldNames{fieldIndex}) = ...
            h.handles.TrasformMat.(fieldNames{fieldIndex});
    end
catch err
    
    handles.TrasformMat.param=zeros(1,10);
    handles.TrasformMat.imsize=[0,0];
    handles.TrasformMat.TR=[];
    handles.TrasformMat.TRxhi=[];
    handles.TrasformMat.qvecin=[];
    handles.TrasformMat.xhivecin=[];
end

if ~isfield(handles.TrasformMat,'TRxhi')
    handles.TrasformMat.xhi=[];
    handles.TrasformMat.xhivecin=[];
end
if length (handles.TrasformMat.param)<10
    handles.TrasformMat.param(10)=0;
end

%     button = questdlg('replace plots','replacing','No','Yes','No')
%     if strcmp (button,'Yes');
%         handles.DirIn=h.handles.DirIn;
%         handles.qvec=h.handles.qvec;
%         handles.State.Image=h.handles.State.Image;
%         handles.imIn=h.handles.imIn;
%         handles.Ivec=h.handles.Ivec;
%         set (handles.DisplayedFilesList,'String',h.DisplayedFilesList);
%     end

handles.isWithinLoadSettings = 0;
guidata(hObject, handles);

refresh;
plotit(hObject,handles);


% --- Executes on button press in loadsettingbu.
function loadsettingbu_Callback(hObject, eventdata, handles, shouldLoadDefaults)
% hObject    handle to loadsettingbu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (~exist('shouldLoadDefaults', 'var') || isempty(shouldLoadDefaults))
    shouldLoadDefaults = false;
end

handles.isWithinLoadSettings = 1;
guidata(hObject, handles);

if (nargin < 4)
    fUpdateDisplay = 1;
end

currentFolder = handles.DisplayOptions.GetDirectory();

if (~shouldLoadDefaults)
    [fn,pathn]=uigetfile('*.sxs', 'Load settings file', currentFolder);
    if (fn == 0), fn = []; end
else
    fn='defaults.sxs';
    [pathn,nv,exv]=fileparts(mfilename('fullpath'));
    handles.State.Image=[];
end

if (~isempty(fn) && ~isempty(pathn))
    fn=fullfile(pathn,fn);
end

loadedSettings = [];
if (~isempty(fn) && exist(fn, 'file'))
    loadedSettings = LoadSettings(hObject, fn);
    handles = guidata(hObject);
end

if (shouldLoadDefaults) % If this was the defaults, set current directory
    if (~isempty(loadedSettings) && ~isempty(loadedSettings.DisplayOptions.Directory))
        SetDirectory(hObject, loadedSettings.DisplayOptions.Directory);
    end
else % If this wasn't the default's, save as defaults
    saveDefaultSettings(hObject);
end

handles.isWithinLoadSettings = 0;
guidata(hObject, handles);


% --- Executes on button press in save1D.
function save1D_Callback(hObject, eventdata, handles)
% hObject    handle to save1D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    plotit(hObject,handles,true);
    load ('forSaxsi.mat');
    delete ('forSaxsi.mat');
catch
end

[fn,pathn]=uiputfile('*.txt', 'save settings file');
if fn
    len=length(fn);
    if ~(strcmp(upper(fn(len-3:len)),'.TXT'))
        fn=[fn '.txt'];
    end
    slist = handles.DisplayOptions.SpreadCurvesMethod;
    if (slist==1)
        mat=[Out.q,Out.I'];
    elseif (slist==2)
        mat=[Out.q,Out.Id2'];
    elseif (slist==3)
        mat=[Out.q,Out.Id3'];
    end
    
    s=[Out.filenames'];
    fid=fopen(fullfile(pathn,fn),'w+');
    fprintf(fid,'q');
    for i=1:length(s)
        fprintf (fid,'\t%s',s{i});
    end
    fprintf(fid,'\n');
    fclose (fid);
    %save (fullfile(pathn,fn),'-ascii','s');
    save (fullfile(pathn,fn),'-ascii', '-append','-tabs','mat');
    save (fullfile(pathn,[fn '.mat']),'-mat','mat');
end


% --- Executes on button press in loglinQ.
function loglinQ_Callback(hObject, eventdata, handles)
% hObject    handle to loglinQ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (all(get(handles.switchIt,'Value') ~= [2 5 6]))
    plotType = handles.DisplayOptions.CurrentPlotType;

    if (numel(handles.DisplayOptions.DisplayXLogarithmic) < plotType)
        handles.DisplayOptions.DisplayXLogarithmic(plotType) = false;
    end
    
    handles.DisplayOptions.DisplayXLogarithmic(plotType) = ...
        ~handles.DisplayOptions.DisplayXLogarithmic(plotType);

    saveDefaultSettings(hObject);
    plotit(hObject);
end

% --- Executes on button press in loglinI.
function loglinI_Callback(hObject, eventdata, handles)
% hObject    handle to loglinI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (all(get(handles.switchIt,'Value') ~= [2 5 6]))
    plotType = handles.DisplayOptions.CurrentPlotType;
    
    if (numel(handles.DisplayOptions.DisplayYLogarithmic) < plotType)
        handles.DisplayOptions.DisplayYLogarithmic(plotType) = false;
    end
    
    handles.DisplayOptions.DisplayYLogarithmic(plotType) = ...
        ~handles.DisplayOptions.DisplayYLogarithmic(plotType);
else
    handles.DisplayOptions.Display2dLogarithmic = ...
        ~handles.DisplayOptions.Display2dLogarithmic;
end
saveDefaultSettings(hObject);
plotit(hObject);

function maskmenu_Callback(hObject, eventdata, handles)

% --- Executes on button press in needrefresh.
function needrefresh_Callback(hObject, eventdata, handles)
% hObject    handle to needrefresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of needrefresh

plotit(hObject,handles);
set (handles.needrefresh,'value',0);
%axis tight


% --- Executes on button press in ClearButton.
function ClearButton_Callback(hObject, eventdata, handles)
% hObject    handle to ClearButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

initialize_gui(gcbf, handles, true);
set(handles.DisplayedFilesList, 'String', {});
set(handles.DisplayedFilesList, 'Value', 1);
handles.State.Curves = [];
handles.State.XhiCurves = [];

plotit(hObject, [], 0, true);

DisplayOptions = handles.DisplayOptions;
DisplayOptions.IsDisplayCleared = 1;


% --- Executes on button press in removeCurveButton.
function removeCurveButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeCurveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selectedIndex = get(handles.DisplayedFilesList,'Value');
fileList = get(handles.DisplayedFilesList,'String');
numOfFiles = length(fileList);

if (selectedIndex >= 1)
    fileList(selectedIndex) = [];
    handles.State.Curves(selectedIndex) = [];
    handles.State.XhiCurves(selectedIndex) = [];

    selectedIndex = min(selectedIndex) - 1;
    if (selectedIndex <= 0 || selectedIndex > numel(fileList));
        selectedIndex = 1;
    end
    
    set(handles.DisplayedFilesList, 'Value', selectedIndex);
    set (handles.DisplayedFilesList, 'String', fileList);
end

% Update handles structure
guidata(hObject, handles);
plotit(hObject,handles);

% --- Executes on button press in MoveDownButton.
function MoveDownButton_Callback(hObject, eventdata, handles)
% hObject    handle to MoveDownButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val=get(handles.DisplayedFilesList,'value');
oldlist=get(handles.DisplayedFilesList,'String');
len=length(oldlist);
%oldlist{len+1}=str;
if ((len>1)&(val<len))
    set(handles.DisplayedFilesList,'String',replaceCell(oldlist,val,val+1));

    tmp = handles.State.Curves(val + 1);
    handles.State.Curves(val + 1) = handles.State.Curves(val);
    handles.State.Curves(val) = tmp;
    
    guidata(hObject, handles);
    plotit(hObject, handles);
    set(handles.DisplayedFilesList,'value',val+1);
else
    beep;
end

% --- Executes on button press in MoveUpButton.
function MoveUpButton_Callback(hObject, eventdata, handles)
% hObject    handle to MoveUpButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val=get(handles.DisplayedFilesList,'value');
oldlist=get(handles.DisplayedFilesList,'String');
len=length(oldlist);
%oldlist{len+1}=str;
if ((len>1)&(val>1))
    set(handles.DisplayedFilesList,'String',replaceCell(oldlist,val,val-1));
    
    tmp = handles.State.Curves(val - 1);
    handles.State.Curves(val - 1) = handles.State.Curves(val);
    handles.State.Curves(val) = tmp;
    
    set(handles.DisplayedFilesList, 'value', val-1);
    
    guidata(hObject, handles);
    plotit(hObject, handles);
else
    beep;
end

function oldlist=replaceCell(oldlist,val1,val2);
str1=oldlist{val1};
str2=oldlist{val2};
oldlist{val2}=str1;oldlist{val1}=str2;


% --- Executes during object creation, after setting all properties.
function dirName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dirName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in exitBu.
function exitBu_Callback(hObject, eventdata, handles)
% hObject    handle to exitBu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.fig_main);



% --- Executes on button press in pushbutton37.
function pushbutton37_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton37 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in dezingerCheck.
function dezingerCheck_Callback(hObject, eventdata, handles)
% hObject    handle to dezingerCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dezingerCheck



function dezingerPer_Callback(hObject, eventdata, handles)
% hObject    handle to dezingerPer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dezingerPer as text
%        str2double(get(hObject,'String')) returns contents of dezingerPer as a double


% --- Executes during object creation, after setting all properties.
function dezingerPer_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dezingerPer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in resizeWinButton.
function resizeWinButton_Callback(hObject, eventdata, handles)
% hObject    handle to resizeWinButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(handles.resizeWinButton,'value')
    set (handles.axes1,'ActivePositionProperty','outerposition');
    set(handles.axes1,'ButtonDownFcn','selectmoveresize')
    
else
    set(handles.axes1,'ButtonDownFcn','')
end



function threshold_Callback(hObject, eventdata, handles)
UpdateIntegrationParamsFieldFromUI(hObject, 'Threshold', @(x)str2double(x));

% --- Executes during object creation, after setting all properties.
function threshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in reintigrateAllDirectoryButton.
function reintigrateAllDirectoryButton_Callback(hObject, eventdata, handles)
% hObject    handle to reintigrateAllDirectoryButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

outfilename = get(handles.filenameListBox, 'String');
fileFullPaths = get(handles.filenameListBox, 'UserData');
set(handles.DisplayedFilesList,'String',[]);

waitBarHandle = [];
tStarted = tic();
shouldShowProgress = 0;

try
    for i = 1:length (outfilename)
        tElapsed = toc(tStarted);
        done = (i-1)/numel(outfilename);
        estimatedTimeLeft = tElapsed * (1-done) / done;
        
        if (~shouldShowProgress)
            if (tElapsed > 3 && estimatedTimeLeft > 2)
                shouldShowProgress = 1;
                waitBarHandle = waitbar(0, 'This is taking too long...', ...
                    'CreateCancelBtn', 'setappdata(gcbf, ''canceling'', 1)');
                setappdata(waitBarHandle, 'canceling', 0);
            end
        end
        
        if (shouldShowProgress)
            waitbar(done, waitBarHandle, sprintf('%d/%d files done (%0.1f%%). Approximately %0.0f more seconds.', i-1, numel(outfilename), done*100, estimatedTimeLeft))
            
            % Did the user click "cancel"?
            if (getappdata(waitBarHandle, 'canceling'))
                break;
            end
        end
        
        handles = addingnew(hObject, handles, fileFullPaths{i}, true, false);
    end
catch err
    1;
end

if (~isempty(waitBarHandle))
    delete(waitBarHandle);
end

% Update handles structure
guidata(hObject, handles);
plotit(hObject,handles);


% --- Executes on button press in xhiplotchk.
function xhiplotchk_Callback(hObject, eventdata, handles)
% TODO: Remove this checkbox!!!
UpdateIntegrationParamsFieldFromUI(hObject, 'shouldDoXhi');

% --- Executes on button press in cmap2d.
function cmap2d_Callback(hObject, eventdata, handles)
% hObject    handle to cmap2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
colormapeditor;

function [result] = ShouldUseOnlySelected(hObject, handles)
if (~exist('handles', 'var'))
    handles = guidata(hObject);
end
result = logical(get(handles.UseOnlySelectedCheckbox, 'Value'));

% --- Executes on button press in SumCurvesButton.
function [outputFilename] = SumCurvesButton_Callback(hObject, eventdata, handles, shouldAverage)
% hObject    handle to SumCurvesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (nargin < 4)
    shouldAverage = 0;
end

outputFilename = [];
folder = handles.DisplayOptions.GetDirectory();
filePrefix = get(handles.sumNum,'String');

if (0)
    for i = 1:1000
        tmp = [filePrefix num2str(i) '.fsi'];
        if (~exist([folder tmp], 'file'))
            outputFilename = tmp;
            break;
        end
    end
else
    outputFilename = [filePrefix '.fsi'];
end

if (isempty(outputFilename)), return; end;

outputPath = [folder outputFilename];

if (handles.DisplayOptions.SpreadCurvesMethod ~= 1)
    handles.DisplayOptions.SpreadCurvesMethod = 1;
    UpdateDisplayOptionsDisplay(hObject);
end

filenamelist = get(handles.DisplayedFilesList, 'String');

selectedFileIndexes = [];
if (ShouldUseOnlySelected(hObject, handles))
    selectedFileIndexes = get(handles.DisplayedFilesList, 'Value');
    filenamelist = filenamelist(selectedFileIndexes);
end

len=length(filenamelist);
if len>1
    if (len>2)
        In.notfirst=true;
    else
        In.notfirst=false;
    end
    
    In.diff=str2double(char(get(handles.spread,'String')));
    In.filenames=filenamelist;
    In.fid=handles.axes1;
    In.SP=1;
    In.flagedit=false;
    Out = readitAxes(handles.State.Curves, handles.DisplayOptions, handles.CalibrationData, In);
    
    if (~isempty(selectedFileIndexes))
        Out.X = Out.X(selectedFileIndexes);
        Out.Y = Out.Y(selectedFileIndexes);
        Out.YErr = Out.YErr(selectedFileIndexes);
    end
    
    %minQ = min(cellfun(@min, Out.X));
    %maxQ = max(cellfun(@max, Out.X));

    for i = 2:numel(Out.X)
        if (any(size(Out.X{1}) ~= size(Out.X{i})) || any(abs(Out.X{1} - Out.X{i}) > 1e-9))
            errordlg('Currently summing/averaging requires all curves to be integrated the same.');
            outputFilename = [];
            return;
        end
    end

    newQ = Out.X{1};
    I = cell2mat(Out.Y);
    IErr = cell2mat(Out.YErr);
    
    if (shouldAverage)
        newI = mean(I, 2);
        newIErr = sqrt(sum(IErr .^ 2, 2)) ./ size(I, 2);
    else
        newI = sum(I, 2);
        newIErr = sqrt(sum(IErr .^ 2, 2));
    end
    
    try
        mat = [newQ(:), newI(:), newIErr(:)];
        save (outputPath,'mat','-ascii');
        fid=fopen ([outputPath,'.txt'],'w+');
        fprintf(fid,'summing the following: \n--------------------- \n');
        for i=1:len
            fprintf(fid,'%s \n',filenamelist{i});
        end
        fclose (fid);
        %set (handles.sumNum,'String',num2str(sumNum+1));
        
        handles = addingnew (hObject, handles, outputPath, 0, 1);
        
        set(handles.calcText, 'String', sprintf('Successfully created: %s', outputFilename));
    catch err
        disp ('There is a problem averaging/summing');
        set(handles.calcText, 'String', 'There is a problem averaging/summing');
        disp (err.message);
    end
end

function sumNum_Callback(hObject, eventdata, handles)
% hObject    handle to sumNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sumNum as text
%        str2double(get(hObject,'String')) returns contents of sumNum as a double


% --- Executes during object creation, after setting all properties.
function sumNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sumNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --------------------------------------------------------------------
function sectionmenu_Callback(hObject, eventdata, handles)
% hObject    handle to sectionmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[x,y] = ginput(2);
axes (handles.axes1);
hold on
plot (x,y,'-w');
zlen=round(sqrt(diff(x)^2+diff(y)^2));
% x=round(x);y=round(y);
% [x1,i]=min(x);[x2,i2]=max(x);
% y1=y(i);y2=y(i2);
fid=gcf;
figure(1);
%axes (handles.axes2);
%cla
plot (interpolate_im3(double(handles.State.Image'),getRforSec(x,y,zlen)));
axis tight
figure (fid);
axis (handles.axes1);


% --- Executes on button press in climMin.
function climMin_Callback(hObject, eventdata, handles)
% hObject    handle to climMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of climMin
set(gca,'clim',[str2num(get(handles.cLimMinnew,'string')),str2num(get(handles.cLimMaxnew,'string'))]);

% --- Executes on button press in cLimMaxnew.
%function cLimMaxnew_Callback(hObject, eventdata, handles)
% hObject    handle to cLimMaxnew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cLimMaxnew



function othermenu_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function SmartFindMask_Callback(hObject, eventdata, handles)
% hObject    handle to SmartFindMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.calcText,'String','Finding beam-stop');
% Update handles structure
guidata(hObject, handles);
rec=[0 0 0 0];
zoom off
while (abs(min(rec))<eps)
    %    disp ('in');
    
    %waitforbuttonpress
    rec=getrect(handles.axes1);
    %     disp('out');
end
si=size(handles.State.Image);
rec(1)=max(1,rec(1));rec(2)=max(1,rec(2));
rec(3)=-rec(1)+min(rec(1)+rec(3),si(2));
rec(4)=-rec(2)+min(rec(2)+rec(4),si(1));
if (abs(min(rec))>0)
    
    f=find (rec(1:2)<0);
    rec(f)=0;
    rec=round(rec);
    %doing x;
    
    
    x=rec(1):(rec(1)+rec(3));
    Zx=zeros(1,length(x));
    y=rec(2):(rec(2)+rec(4));
    Zy=zeros(1,length(y));
    xV=[rec(1)+rec(3)+Zy,rec(1)+Zy,x,x];
    yV=[y,y,rec(2)+Zx,rec(2)+rec(4)+Zx];
    len=length(xV);
    
    
    Bx=str2double(char(get (handles.bmx,'String')));
    By=str2double(char(get (handles.bmy,'String')));
    %%% working with smaller matrix
    
    dIm=double(handles.State.Image(y,x)');
    
    if ((Bx < rec(1) || Bx > (rec(1) + rec(3))) || (By < rec(2) || By > (rec(2) + rec(4))))
        Bx = rec(1) + rec(3)/2;
        By = rec(2) + rec(4)/2;
    end
    
    y=y-rec(2)+1;x=x-rec(1)+1;
    Bx=Bx-rec(1)+1;By=By-rec(2)+1;
    xV=xV-rec(1)+1;yV=yV-rec(2)+1;
    
    h = waitbar(0,'Please wait...');
    
    newmsk = false(size(handles.MaskBitmap));
    for i=1:len
        waitbar(i/len)
        x=[Bx,max(1,xV(i)-1)];y=[By,max(1,yV(i)-1)];
        
        zlen=round(sqrt(diff(x)^2+diff(y)^2));
        Rvec=getRforSec(x,y,zlen);
        ZIm=interpolate_im3(dIm,Rvec);
        [zMaxx,Zind]=max(ZIm);
        
        try
            for j=1:Zind+1
                nn=[round(Rvec(j,2))+rec(2)-1, round(Rvec(j,1))+rec(1)-1];
                newmsk(nn(1), nn(2)) = true;
            end
        catch
            pause (0.000001);
        end
        
    end
    
    clear dIm
    
    MaskBitmap = handles.MaskBitmap;
    MaskBitmap(newmsk) = 1;
    handles.MaskBitmap = MaskBitmap;
    guidata(hObject, handles);
    
    
    plotit(hObject);
    handles.TrasformMat.param=zeros(1,9);
    
    close(h)
    
end
set(handles.calcText,'String','SAXSi is ready');
% Update handles structure
guidata(hObject, handles);


% --------------------------------------------------------------------
function savemaskMenu_Callback(hObject, eventdata, handles)
% hObject    handle to settingMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
savemaskBu_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function settingMenu_Callback(hObject, eventdata, handles)
% hObject    handle to settingMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.DisplayOptions.CurrentPlotType == 2)
    set(handles.setQminmenu, 'Enable', 'on');
    set(handles.setQmaxmenu, 'Enable', 'on');
    set(handles.setCentermenu, 'Enable', 'on');
else
    set(handles.setQminmenu, 'Enable', 'off');
    set(handles.setQmaxmenu, 'Enable', 'off');
    set(handles.setCentermenu, 'Enable', 'off');
end

% --------------------------------------------------------------------
function loadmaskmenu_Callback(hObject, eventdata, handles)
% hObject    handle to loadmaskmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadmaskBu_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function clearmaskmenu_Callback(hObject, eventdata, handles)
% hObject    handle to clearmaskmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clearmaskbu_Callback(hObject, eventdata, handles);
plotit(hObject, handles);

% --------------------------------------------------------------------
function addtomaskmenu_Callback(hObject, eventdata, handles)
% hObject    handle to addtomaskmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%addmaskbu_Callback(hObject, eventdata, handles);
AddMaskRoi(hObject, handles, 'box')

% --------------------------------------------------------------------
function setCentermenu_Callback(hObject, eventdata, handles)
% hObject    handle to setCentermenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dobeamstop_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function setQmaxmenu_Callback(hObject, eventdata, handles)
% hObject    handle to setQmaxmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
QmaxBu_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function setQminmenu_Callback(hObject, eventdata, handles)
% hObject    handle to setQminmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
QminBu_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function saveSettingsmenu_Callback(hObject, eventdata, handles)
% hObject    handle to saveSettingsmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
savesetting_Callback(hObject, [], handles);

% --------------------------------------------------------------------
function loadSettingsmenu_Callback(hObject, eventdata, handles)
% hObject    handle to loadSettingsmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadsettingbu_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function save1dmenu_Callback(hObject, eventdata, handles)
% hObject    handle to save1dmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
save1D_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function exportFigmenu_Callback(hObject, eventdata, handles)
% hObject    handle to exportFigmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

exportFigure_Callback(hObject, eventdata, handles);


% --------------------------------------------------------------------
function Mask_Callback(hObject, eventdata, handles)
% hObject    handle to maskmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function UpdateGeneralOptionsDisplay(hObject)
1;

function UpdateDisplayOptionsDisplay(hObject)
handles = guidata(hObject);
DisplayOptions = handles.DisplayOptions;
set(handles.spread, 'string', num2str(DisplayOptions.SpreadCurvesBy, 5));
set(handles.flipTag, 'Value', DisplayOptions.shouldFlipY);
set(handles.switchIt, 'Value', DisplayOptions.CurrentPlotType);
set(handles.filterNameEditBox,'String', DisplayOptions.FilesFilter);
set(handles.slist, 'Value', DisplayOptions.SpreadCurvesMethod);
set(handles.AutoMaxIntensityCheckbox, 'Value', DisplayOptions.AutoMaxIntensity);
set(handles.refreshTm, 'String', num2str(DisplayOptions.FileRefreshInterval));
set(handles.AutoRefreshCheckbox, 'Value', DisplayOptions.AutoRefresh);
set(handles.autoaddnew, 'Value', DisplayOptions.AutoAddNewFiles);
UpdateAllBoundMenuItems(hObject, handles);

function UpdateIntegrationParamsDisplay(hObject)
handles = guidata(hObject);
IntegrationParams = handles.IntegrationParams;
set(handles.qmin, 'string', num2str(IntegrationParams.QMin, 5));
set(handles.qmax, 'string', num2str(IntegrationParams.QMax, 5));
set(handles.qStepsCount, 'string', num2str(IntegrationParams.QStepsCount));
set(handles.threshold, 'string', num2str(IntegrationParams.Threshold));
set(handles.xhiplotchk, 'Value', IntegrationParams.shouldDoXhi);

selectedIntegrationMethod = find(strcmp(get(handles.integrationMethodList, 'UserData'), IntegrationParams.IntegrationMethod), 1);
if (~isempty(selectedIntegrationMethod))
    set(handles.integrationMethodList, 'Value', selectedIntegrationMethod);
end
1;

function UpdateCalibrationDataDisplay(hObject)
handles = guidata(hObject);
CalibrationData = handles.CalibrationData;
set(handles.alpha, 'string',num2str(CalibrationData.AlphaDegrees));
set(handles.s2d, 'string',num2str(CalibrationData.SampleToDetDist));
set(handles.bmx, 'string',num2str(CalibrationData.BeamCenterX));
set(handles.bmy, 'string',num2str(CalibrationData.BeamCenterY));
set(handles.beta, 'string',num2str(CalibrationData.BetaDegrees));

set(handles.lambda, 'string', num2str(CalibrationData.Lambda, 7));
set(handles.pxSz, 'string', num2str(CalibrationData.PixelSize, 7));

% --------------------------------------------------------------------
function CalibrationMenuItem_Callback(hObject, eventdata, handles)

CalibrationData = handles.CalibrationData;
if (Calibration(CalibrationData, handles.State.Image) ~= 0);
    UpdateCalibrationDataDisplay(hObject);
    saveDefaultSettings(hObject);
    plotit(hObject,handles);
end

% --------------------------------------------------------------------
function Calibration2MenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to othermenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
imageForCalibration = double(handles.State.Image);
mask = GetMask(hObject, handles);
imageForCalibration = imageForCalibration .* double(mask == 0) + double(mask ~= 0) .* (-1);

newCalibration = CalibrationDataClass();
newCalibration.CopyFrom(handles.CalibrationData);

[newCalibration wasOK] = CalibrationDialog(imageForCalibration, newCalibration);

if (wasOK)
    handles.CalibrationData.CopyFrom(newCalibration);

    UpdateCalibrationDataDisplay(hObject);
    saveDefaultSettings(hObject);
    plotit(hObject,handles);
end


function cLimMinnew_Callback(hObject, eventdata, handles)
% hObject    handle to cLimMinnew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cLimMinnew as text
%        str2double(get(hObject,'String')) returns contents of cLimMinnew as a double

set(gca,'clim',[str2num(get(handles.cLimMinnew,'string')),str2num(get(handles.cLimMaxnew,'string'))]);
% --- Executes during object creation, after setting all properties.
function cLimMinnew_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cLimMinnew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function cLimMaxnew_Callback(hObject, eventdata, handles)
% hObject    handle to cLimMaxnew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cLimMaxnew as text
%        str2double(get(hObject,'String')) returns contents of cLimMaxnew as a double
set(gca,'clim',[str2num(get(handles.cLimMinnew,'string')),str2num(get(handles.cLimMaxnew,'string'))]);

% --- Executes during object creation, after setting all properties.
function cLimMaxnew_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cLimMaxnew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in checkboxSubBck.
function checkboxSubBck_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSubBck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSubBck



function mulBck_Callback(hObject, eventdata, handles)
% hObject    handle to mulBck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mulBck as text
%        str2double(get(hObject,'String')) returns contents of mulBck as a double


% --- Executes during object creation, after setting all properties.
function mulBck_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mulBck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in getbckFN.
function getbckFN_Callback(hObject, eventdata, handles)
% hObject    handle to getbckFN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename, pathname] = uigetfile('*.fsi', 'Pick an Background file');
if isequal(filename,0)
    disp('User selected Cancel')
else
    set(handles.bckFN,'String',fullfile(pathname, filename));
end


function AddMaskRoi(hObject, handles, roiShape)
set(handles.calcText,'String', sprintf('Draw mask %s - double click to finish', roiShape));
% Update handles structure
guidata(hObject, handles);
newmskBIT=setroi(gcf, roiShape);

MaskBitmap = GetMask(hObject, handles);
MaskBitmap(newmskBIT) = 1;
handles.MaskBitmap = MaskBitmap;
guidata(hObject, handles);

plotit(hObject, [], 0, 0);

handles.TrasformMat.param=0*handles.TrasformMat.param;
set(handles.calcText,'String','SAXSi is ready');
% Update handles structure
guidata(hObject, handles);

% --------------------------------------------------------------------
function addpolymask_Callback(hObject, eventdata, handles)
% hObject    handle to addpolymask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
AddMaskRoi(hObject, handles, 'polygon')

% --------------------------------------------------------------------
function MaskBelowThresholdMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MaskBelowThresholdMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update handles structure
prompt = {'Smaller than:'};
dlg_title = 'Threshold mask';
num_lines = 1;
%def = {'eps'};
def = {'0'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
try
    [val status] = str2num(answer{1});
catch
    status=false;
end

if status
    MaskBitmap = GetMask(hObject, handles);

    rows = 1:size(handles.State.Image, 1);
    cols = 1:size(handles.State.Image, 2);
    MaskBitmap(rows, cols) = MaskBitmap(rows, cols) | ...
        handles.State.Image < val;
    
    handles.MaskBitmap = MaskBitmap;
    
    handles.TrasformMat.param=zeros(1,9);
    guidata(hObject, handles);
    saveDefaultSettings(hObject);
    
    plotit(hObject, [], 0, 0);
end


% --------------------------------------------------------------------
function MaskSpecificValueMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MaskSpecificValueMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update handles structure
prompt = {'Value equal to:', 'Minimal area of constant value (input either "N" or "NxM"):'};
dlg_title = 'Mask specific value with minimal area constraint';
num_lines = 1;
%def = {'eps'};
def = {'0', '10x10'};
answer = inputdlg(prompt, dlg_title, num_lines, def);

try
    [val status] = str2num(answer{1});
    
    result = regexpi(answer{2}, '^(?<N>\d+)x(?<M>\d+)$', 'names');
    
    if (~isempty(result))
        area = [str2num(result.N) str2num(result.M)];
    else
        result = str2num(answer{2});
        area = [result result];
    end
catch
    status=false;
end

if status
    MaskBitmap = GetMask(hObject, handles);

    rows = 1:size(handles.State.Image, 1);
    cols = 1:size(handles.State.Image, 2);
    
    whichEqual = (~MaskBitmap) & (handles.State.Image == val);
    
    areaSize = prod(area);
    areaImage = ones(area)';
    tmpImage = conv2(double(whichEqual), areaImage, 'same');
    
    evenDimensions = (mod(area, 2) == 0);
    area(evenDimensions) = area(evenDimensions)+1;
    areaImage = ones(area)';
    
    tmpImage = (conv2(double(tmpImage == areaSize), areaImage, 'same') ~= 0);
    
    MaskBitmap(rows, cols) = MaskBitmap(rows, cols) | tmpImage;
    handles.MaskBitmap = MaskBitmap;
    
    handles.TrasformMat.param=zeros(1,9);
    guidata(hObject, handles);
    saveDefaultSettings(hObject);
    
    plotit(hObject, [], 0, 0);
end


% --------------------------------------------------------------------
function MaskNegativePixelsMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MaskNegativePixelsMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Update handles structure
handles = ExpandMaskToMatchImage(hObject, handles);
handles.MaskBitmap(handles.State.Image < 0) = 1;

handles.TrasformMat.param=zeros(1,9);
guidata(hObject, handles);
saveDefaultSettings(hObject);
plotit(hObject, handles, 0, 0);


% --------------------------------------------------------------------
function MaskAboveThresholdMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MaskAboveThresholdMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update handles structure
prompt = {'Larger than:'};
dlg_title = 'Threshold mask';
num_lines = 1;
%def = {'eps'};
def = {'1e6'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
try
    [val status] = str2num(answer{1});
catch
    status=false;
end

if status
    MaskBitmap = GetMask(hObject, handles);

    rows = 1:size(handles.State.Image, 1);
    cols = 1:size(handles.State.Image, 2);

    MaskBitmap(rows, cols) = MaskBitmap(rows, cols) | ...
        handles.State.Image > val;
    
    handles.MaskBitmap = MaskBitmap;
    
    handles.TrasformMat.param=zeros(1,9);
    guidata(hObject, handles);
    saveDefaultSettings(hObject);
    
    plotit(hObject, [], 0, 0);
end


function alpha_Callback(hObject, eventdata, handles)
handles.CalibrationData.AlphaDegrees = str2double(get(handles.alpha, 'String'));
UpdateCalibrationDataDisplay(hObject);
saveDefaultSettings(hObject);
plotit(hObject, handles);

% --- Executes during object creation, after setting all properties.
function alpha_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function beta_Callback(hObject, eventdata, handles)
handles.CalibrationData.BetaDegrees = str2double(get(handles.beta, 'String'));
UpdateCalibrationDataDisplay(hObject);
saveDefaultSettings(hObject);
plotit(hObject, handles);

% --- Executes during object creation, after setting all properties.
function beta_CreateFcn(hObject, eventdata, handles)
% hObject    handle to beta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function HandlePostZoom(hObject, eventdata)
% ax = eventdata.Axes;
% xl = ax.XLim;
% yl = ax.YLim;
% axis equal;
% 
% xlAfter = ax.XLim;
% ylAfter = ax.YLim;
% 
% ratioBefore = (xl(2)-xl(1))/(yl(2)-yl(1));
% ratioAfter = (xlAfter(2)-xlAfter(1))/(ylAfter(2)-ylAfter(1));
% 
% axis manual;
% ax.XLim = xl;
% ax.YLim = yl;

1;

% --------------------------------------------------------------------
function zoomMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to zoomMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);

zoomHandle = zoom(handles.fig_main);

if (strcmp(zoomHandle.Enable, 'off'))
%     axis manual;
    
    set(zoomHandle, 'ActionPostCallback', @HandlePostZoom);
    zoomHandle.UIContextMenu = handles.PlotMenu;
    zoomHandle.Enable = 'on';
else
    zoomHandle.Enable = 'off';
    %axis equal;
end

% r = getrect(handles.axes1);
%
% if (r(3) > 20 && r(4) > 20)
%     xlim([r(1), r(1) + r(3)]);
%     ylim([r(2), r(2) + r(4)]);
% end


% --------------------------------------------------------------------
function getXYQMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to getXYQMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Left mouse button picks points.')
disp('Right mouse button picks last point.')
but = 1;
while but == 1
    [xi,yi,but] = ginput(1);
    
    if (handles.DisplayOptions.CurrentPlotType == 2)
        q = handles.CalibrationData.GetQForXY(xi, yi);
        intensity = handles.State.Image(floor(yi), floor(xi));
        str = sprintf('x,y=%0.1f,%0.1f  q=%0.4f intensity=%0.4f', xi, yi, q, intensity);
    elseif (any(handles.DisplayOptions.CurrentPlotType == [5 6]))
        q = handles.CalibrationData.GetQForXY(xi, yi);
        v = handles.State.DisplayedImage(round(yi), round(xi));
        str = sprintf('x,y=%0.1f,%0.1f  q=%0.4f value=%0.4f', xi, yi, q, v);
    else
        % TODO: Of all curves, find the closest one and present its value
        
        %str = sprintf('x,y=%0.5g,%0.5g f(x)=%d', xi, yi, 0);
        str = sprintf('x,y=%0.5g,%0.5g   2pi/x=%0.5g', xi, yi, 2*pi/xi);
    end
    
    %str=['x=',num2str(xi),' y=',num2str(yi)];
    set(handles.calcText, 'String', str)
end

set(handles.calcText,'String','SAXSi is ready');

% --------------------------------------------------------------------
function logLinIScaleMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to logLinIScaleMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loglinI_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function logLinQScaleMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to logLinQScaleMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loglinQ_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function PlotMenu_Callback(hObject, eventdata, handles)
% hObject    handle to PlotMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

onoff = {'off', 'on'};

menuClick = get(handles.axes1, 'CurrentPoint');
menuClick = menuClick(1, 1:2);

handles.State.PositionWhereMenuWasOpened = [menuClick 0];

zoomHandle = zoom(handles.fig_main);
set(handles.zoomMenuItem, 'Checked', zoomHandle.Enable);
panHandle = pan(handles.fig_main);
set(handles.panMenuItem, 'Checked', panHandle.Enable);
%cursorMode = datacursormode(handles.fig_main);
%set(handles.dataPickerMenuItem, 'Checked', get(cursorMode, 'enable'));

cbar = findobj(get(handles.fig_main,'Children'),'Tag','Colorbar');
if (isempty(cbar)), set(handles.colorbarMenuItem, 'Checked', 'off');
else, set(handles.colorbarMenuItem, 'Checked', 'on'); end

set(handles.ShowErrorbarsMenuItem, 'Checked', onoff{1 + (handles.DisplayOptions.DisplayErrorBars ~= 0)});




% --------------------------------------------------------------------
function panMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to panMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);

panHandle = pan(handles.fig_main);

if (strcmp(panHandle.Enable, 'off'))
    panHandle.UIContextMenu = handles.PlotMenu;
    panHandle.Enable = 'on';
else
    panHandle.Enable = 'off';
end


% --------------------------------------------------------------------
function resetZoomMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to resetZoomMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (handles.DisplayOptions.CurrentPlotType ~= 2)
    if (0) % for debug
        figure;
        plot([0], [0]);
        a1 = handles.axes1;
        handles.axes1 = gca;
        guidata(hObject, handles);
        plotit(hObject, [], 0, 1);
        handles.axes1 = a1;
        guidata(hObject, handles);
    end
    
    %axes(handles.axes1);
    axis tight;
    xl = xlim(handles.axes1);
    yl = ylim(handles.axes1);
    
    if (strcmp(get(handles.axes1, 'XScale'), 'log'))
        xl = log(xl);
    end
    
    if (strcmp(get(handles.axes1, 'YScale'), 'log'))
        yl = log(yl);
    end
    
    k = 0.02;
    xl = xl + [-1 1] .* (xl(2)-xl(1)) * k;
    yl = yl + [-1 1] .* (yl(2)-yl(1)) * k;
    
    if (strcmp(get(handles.axes1, 'XScale'), 'log'))
        xl = exp(xl);
    end
    
    if (strcmp(get(handles.axes1, 'YScale'), 'log'))
        yl = exp(yl);
    end
    
    xlim(handles.axes1, xl);
    ylim(handles.axes1, yl);
else
    axes(handles.axes1);
    axis auto;
end
1;

% --------------------------------------------------------------------
function sum2DMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to sum2DMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sum2dimages();


% --------------------------------------------------------------------
function toolsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to toolsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --------------------------------------------------------------------
function colorbarMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to colorbarMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);

cbar = findobj(get(handles.fig_main,'Children'),'Tag','Colorbar');

if (isempty(cbar))
    cbar = colorbar();
else
    colorbar(cbar, 'off');
end




% --------------------------------------------------------------------
function displayTypeMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to displayTypeMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function display1dMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to display1dMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.switchIt, 'Value', 1);
switchIt_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function display2dMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to display2dMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.switchIt, 'Value', 2);
switchIt_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function displayXhiMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to displayXhiMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.switchIt, 'Value', 3);
switchIt_Callback(hObject, eventdata, handles)

function txt = setDataTipText(empt,event_obj)
pos = get(event_obj,'Position');
txt = {['Time: ',num2str(pos(1))],...
    ['Amplitude: ',num2str(pos(2))]};
1;

% --------------------------------------------------------------------
function dataPickerMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to dataPickerMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cursorMode = datacursormode(handles.fig_main);

if (strcmp(get(cursorMode, 'enable'), 'on'))
    set(cursorMode, 'enable', 'off');
    cursorMode.removeAllDataCursors();
else
    hTarget = handle(handles.ImageHandle);
    hDatatip = cursorMode.createDatatip(hTarget);
    %     set(hDatatip,'UIContextMenu',get(cursorMode,'UIContextMenu'));
    set(hDatatip,'HandleVisibility','off');
    set(hDatatip,'Host',hTarget);
    set(hDatatip,'ViewStyle','datatip');
    % Set the data-tip orientation to top-right rather than auto
    set(hDatatip,'OrientationMode','manual');
    set(hDatatip,'Orientation','top-right');
    % Update the datatip marker appearance
    set(hDatatip, 'MarkerSize',5, 'MarkerFaceColor','none', ...
        'MarkerEdgeColor','k', 'Marker','o', 'HitTest','off');
    
    %     set(cursorMode, 'UIContextMenu', handles.PlotMenu);
    set(cursorMode, 'enable', 'on', 'UpdateFcn', @setDataTipTxt, 'NewDataCursorOnClick',false);
    
    % Then clear it's UIContextMenu
    set(hDatatip,'UIContextMenu',[]);
end


% --------------------------------------------------------------------
function colormapsMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to colormapsMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function jetColormapMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to jetColormapMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
colormap('jet');

% --------------------------------------------------------------------
function copperColormapMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to copperColormapMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
colormap('copper');

% --------------------------------------------------------------------
function grayColormapMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to grayColormapMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
colormap('gray');


% --- Executes on selection change in integrationMethodList.
function integrationMethodList_Callback(hObject, eventdata, handles)
%UpdateIntegrationParamsFieldFromUI(hObject, 'IntegrationMethod');

IntegrationParams = handles.IntegrationParams;

value = get(hObject, 'Value');
userData = get(hObject, 'UserData');

if (~isempty(value))
    IntegrationParams.IntegrationMethod = userData{value};
end

UpdateIntegrationParamsDisplay(hObject);
plotit(hObject,handles);
saveDefaultSettings(hObject)


% --- Executes during object creation, after setting all properties.
function integrationMethodList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to integrationMethodList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox5.
function listbox5_Callback(hObject, eventdata, handles)
% hObject    handle to listbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox5


% --- Executes during object creation, after setting all properties.
function listbox5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function ResetIntensityRangeMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to ResetIntensityRangeMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function QMarksMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to QMarksMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.State.PositionWhereMenuWasOpened(3) == 0)
    try
        pos = handles.State.PositionWhereMenuWasOpened(1:2);
        
        switch (handles.DisplayOptions.CurrentPlotType)
            case 1
                q = pos(1);
            case 2
                q = handles.CalibrationData.GetQForXY(pos);
            otherwise
                return;
                1;
        end
        
        handles.State.PositionWhereMenuWasOpened = [pos, q];
    catch
    end
    
    display(handles.State.PositionWhereMenuWasOpened);
end

function HandleMarkQMenuItems(hObject, color)
userData = get(hObject, 'UserData');
handles = guidata(hObject);

[xi,yi,but] = ginput(1);

if (but ~= 1)
    return;
end

if (handles.DisplayOptions.CurrentPlotType == 2)
    q = handles.CalibrationData.GetQForXY(xi, yi);
else
    q = xi;
end

if (isempty(userData))
    qMark = QMarkClass();
    handles.State.QMarks{end + 1} = qMark;
    set(hObject, 'UserData', qMark);
else
    qMark = userData;
end

if (~qMark.Visible)
    set(hObject, 'Checked', 'on');
    
    qMark.Q = q;
    qMark.Color = color;
    qMark.Width = 2.5;
    qMark.Visible = 1;
else
    qMark.Visible = 0;
    %toRemove = cellfun(@(qm)qm.Q == qMark.Q, handles.State.QMarks);
    %handles.State.QMarks(toRemove) = [];
    set(hObject, 'Checked', 'off');
end

plotit(hObject, handles, 0, 1);


% --------------------------------------------------------------------
function MarkThisQWhiteMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MarkThisQWhiteMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
HandleMarkQMenuItems(hObject, 'white');

% --------------------------------------------------------------------
function MarkThisQGreenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MarkThisQGreenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
HandleMarkQMenuItems(hObject, 'green');


% --------------------------------------------------------------------
function MarkThisQYellowMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MarkThisQYellowMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
HandleMarkQMenuItems(hObject, 'yello');

% --------------------------------------------------------------------
function MarkThisQRedMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MarkThisQRedMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
HandleMarkQMenuItems(hObject, 'red');

% --------------------------------------------------------------------
function MarkThisQBlackMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MarkThisQBlackMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
HandleMarkQMenuItems(hObject, 'black');

% --------------------------------------------------------------------
function MarkThisQClearAllMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MarkThisQClearAllMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.State.QMarks(:) = [];

for h = allchild(handles.QMarksMenuItem)
    set(h, 'UserData', []);
    set(h, 'Checked', 'off');
end

plotit(hObject);

% --------------------------------------------------------------------
function QMarksAddMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to QMarksAddMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
qMark = QMarkClass();
handles.State.QMarks{end+1} = qMark;

qMark.Q = handles.State.PositionWhereMenuWasOpened(3);
qMark.Color = 'black';
qMark.Width = 1.0;
qMark.LineStyle = '--';
qMark.Series = [];
qMark.Visible = 1;

m = uimenu(handles.QMarksMenuItem, 'Label', sprintf('Q: %0.3f', qMark.Q),...
    'UserData', qMark, 'Callback', @(obj, ed, h)HandleMarkQMenuItems(obj, 'black'));

MarkQDialog(qMark);

% if (strcmp(get(hObject, 'Checked'), 'on'))
%     handles.State.QMarks(1) = 0;
%     set(hObject, 'Checked', 'off');
% else
%     handles.State.QMarkColors{1} = 'white';
%     set(hObject, 'Checked', 'on');
% end

plotit(hObject);

% --- Executes on button press in AutoMaxIntensityCheckbox.
function AutoMaxIntensityCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to AutoMaxIntensityCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.DisplayOptions.AutoMaxIntensity = get(handles.AutoMaxIntensityCheckbox, 'Value');
SaveAndUpdateDisplayOptions(hObject);

function edit20_Callback(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit20 as text
%        str2double(get(hObject,'String')) returns contents of edit20 as a double


% --- Executes during object creation, after setting all properties.
function edit20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AutoRefreshCheckbox.
function AutoRefreshCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to AutoRefreshCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.DisplayOptions.AutoRefresh = get(handles.AutoRefreshCheckbox, 'Value');
SaveAndUpdateDisplayOptions(hObject);

Timers = getappdata(handles.fig_main, 'Timers');
stop(Timers.monitoring);

if (handles.DisplayOptions.AutoRefresh)
    start(Timers.monitoring);
end

% --- Executes on button press in averageCurvesButton.
function averageCurvesButton_Callback(hObject, eventdata, handles)
% hObject    handle to averageCurvesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[outputFilename] = SumCurvesButton_Callback(hObject, eventdata, handles, 1);

% --- Executes on button press in KeepCurvesButton.
function KeepCurvesButton_Callback(hObject, eventdata, handles)
% hObject    handle to KeepCurvesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = get(handles.DisplayedFilesList,'String');
selected = get(handles.DisplayedFilesList, 'Value');

if (length(contents) > 1)
    
    handles.State.Curves = handles.State.Curves(selected);
    handles.State.XhiCurves = handles.State.XhiCurves(selected);
    
    set(handles.DisplayedFilesList, 'String', contents(selected));
    set(handles.DisplayedFilesList, 'Value', 1);
    
    plotit(hObject, handles);
end


% --------------------------------------------------------------------
function OptionsMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OptionsMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
onoff = {'off', 'on'};
set(handles.IntegrationSavesFsiMenuItem, 'Checked', onoff{1 + (handles.GeneralOptions.SaveIntegrationToFsiFile ~= 0)});
set(handles.IntegrationSavesFsxMenuItem, 'Checked', onoff{1 + (handles.GeneralOptions.SaveIntegrationFsxFile ~= 0)});
set(handles.IntegrationSavesDatMenuItem, 'Checked', onoff{1 + (handles.GeneralOptions.SaveIntegrationToDatFile ~= 0)});
set(handles.IntegrationSavesDatAMenuItem, 'Checked', onoff{1 + (handles.GeneralOptions.SaveIntegrationToDatFile == 1)});
set(handles.IntegrationSavesDatNMMenuItem, 'Checked', onoff{1 + (handles.GeneralOptions.SaveIntegrationToDatFile == 2)});
set(handles.LoadIntegratedFilesInsteadOfIntegratingMenuItem, 'Checked', onoff{1 + (handles.GeneralOptions.ShouldLoadIntegratedFileInsteadOfIntegrating ~= 0)});
set(handles.reintegrateTracesBackToImagesMenuItem, 'Checked', onoff{1 + (handles.GeneralOptions.ReintegrateTracesBackToImages ~= 0)});

1;

% --------------------------------------------------------------------
function DisplayQScaleIn_nm_MenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayQScaleIn_nm_MenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function DisplayQScaleIn_A_MenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayQScaleIn_A_MenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function DisplayScaleMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayScaleMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function DisplayScaleInAMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayScaleInAMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function DisplayScaleInNMMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayScaleInNMMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function DisplayScaleInvertedInA_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayScaleInvertedInA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function DisplayScaleInvertedInNM_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayScaleInvertedInNM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function DisplayScaleInDegrees_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayScaleInDegrees (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function IntegrationSavesFsiMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to IntegrationSavesFsiMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.GeneralOptions.SaveIntegrationToFsiFile = ~handles.GeneralOptions.SaveIntegrationToFsiFile;
saveDefaultSettings(hObject);

% --------------------------------------------------------------------
function IntegrationSavesFsxMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to IntegrationSavesFsxMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.GeneralOptions.SaveIntegrationFsxFile = ~handles.GeneralOptions.SaveIntegrationFsxFile;
saveDefaultSettings(hObject);

% --------------------------------------------------------------------
function IntegrationSavesDatMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to IntegrationSavesDatMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function IntegrationSavesDatAMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to IntegrationSavesDatAMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.GeneralOptions.SaveIntegrationToDatFile == 1)
    handles.GeneralOptions.SaveIntegrationToDatFile = 0;
else
    handles.GeneralOptions.SaveIntegrationToDatFile = 1;
end

saveDefaultSettings(hObject);


% --------------------------------------------------------------------
function IntegrationSavesDatNMMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to IntegrationSavesDatNMMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.GeneralOptions.SaveIntegrationToDatFile == 2)
    handles.GeneralOptions.SaveIntegrationToDatFile = 0;
else
    handles.GeneralOptions.SaveIntegrationToDatFile = 2;
end

saveDefaultSettings(hObject);
1;

% --------------------------------------------------------------------
function DebugObjectsTreeMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to DebugObjectsTreeMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addpath('findjobj');
findjobj();

function LoadFileFilters(hObject)
handles = guidata(hObject);

if (exist('FileFilters.txt', 'file'))
    try
        f = fopen('FileFilters.txt', 'r');
        if (f <= 0);
            display('Was not able to read the filename-filters list file (FileFilters.txt)!');
            return;
        end
        
        fileFilters = {};
        while (~feof(f))
            line = strtrim(fgetl(f));
            
            if (~isempty(line))
                fileFilters{end + 1} = line;
            end
        end
        
        fclose(f);
        
        prevFileFilters = get(handles.ChooseFileFilterDropDown, 'String');
        set(handles.ChooseFileFilterDropDown, 'String', {prevFileFilters{1}, fileFilters{:}}');
    catch
    end
end
1;

% --- Executes on selection change in ChooseFileFilterDropDown.
function ChooseFileFilterDropDown_Callback(hObject, eventdata, handles)
% hObject    handle to ChooseFileFilterDropDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selectedIndex = get(hObject, 'Value');
if (selectedIndex > 1)
    strings = cellstr(get(hObject,'String'));
    filterString = strings{selectedIndex};
    set(handles.filterNameEditBox, 'String', filterString); % Set the filter
    set(hObject, 'Value', 1); % Return to the explanation string
    
    % Call the callback for the change
    filterNameEditBox_Callback(handles.filterNameEditBox, [], handles);
end

% --- Executes during object creation, after setting all properties.
function ChooseFileFilterDropDown_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ChooseFileFilterDropDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over filterNameEditBox.
function filterNameEditBox_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to filterNameEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SortFileListByNameMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to SortFileListByNameMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.DisplayOptions.FilesSort.Field = 'name';
handles.DisplayOptions.FilesSort.Func = [];
handles.DisplayOptions.FilesSort.Direction = 1;
saveDefaultSettings(hObject);
RefreshFilesList(hObject);

% --------------------------------------------------------------------
function SortFileListByTimeMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to SortFileListByTimeMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.DisplayOptions.FilesSort.Field = 'datenum';
handles.DisplayOptions.FilesSort.Func = [];
handles.DisplayOptions.FilesSort.Direction = -1;
saveDefaultSettings(hObject);
RefreshFilesList(hObject);

% --------------------------------------------------------------------
function FileListMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileListMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function [lastNumber] = ExtractFileNameNumericSuffix(str)
[~, name, ext] = fileparts(str);
numeric = name >= '0' & name <= '9';

lastNumber = 0;

if (any(numeric))
    numericChange = [numeric(1) diff(numeric) -1];
    numericStart = (numericChange == 1);
    numericEnd = (numericChange == -1);
    numericStart = find(numericStart);
    numericEnd = find(numericEnd) - 1;
    lastNumber = str2double(name(numericStart(end):numericEnd(end)));
end
1;

% --------------------------------------------------------------------
function SortFileListByLastNumberMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to SortFileListByLastNumberMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.DisplayOptions.FilesSort.Field = 'name';
handles.DisplayOptions.FilesSort.Func = @ExtractFileNameNumericSuffix;
handles.DisplayOptions.FilesSort.Direction = -1;
saveDefaultSettings(hObject);
RefreshFilesList(hObject);

% --------------------------------------------------------------------
function RecentFoldersMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to RecentFoldersMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SortByMenuItem_Callback(hObject, ~, handles)
% hObject    handle to SortByMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --------------------------------------------------------------------
function ShowErrorbarsMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to ShowErrorbarsMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.DisplayOptions.DisplayErrorBars = ~handles.DisplayOptions.DisplayErrorBars;
saveDefaultSettings(hObject);
plotit(hObject, handles);

% --------------------------------------------------------------------
function LoadIntegratedFilesInsteadOfIntegratingMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to LoadIntegratedFilesInsteadOfIntegratingMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.GeneralOptions.ShouldLoadIntegratedFileInsteadOfIntegrating = ...
    ~handles.GeneralOptions.ShouldLoadIntegratedFileInsteadOfIntegrating;
saveDefaultSettings(hObject);


% --- Executes on button press in UseOnlySelectedCheckbox.
function UseOnlySelectedCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to UseOnlySelectedCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotit (hObject, handles);


% --- Executes on button press in SubFoldersCheckbox.
function SubFoldersCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to SubFoldersCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.DisplayOptions.ShouldSearchFilesRecursively = get(handles.SubFoldersCheckbox, 'Value');
SaveAndUpdateDisplayOptions(hObject);
RefreshFilesList(hObject);

% --- Executes on button press in RegExpCheckbox.
function RegExpCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to RegExpCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.DisplayOptions.ShouldSearchFilesUsingRegExp = get(handles.RegExpCheckbox, 'Value');
SaveAndUpdateDisplayOptions(hObject);
RefreshFilesList(hObject);

function [lp] = LongProcessStarted(totalSteps, nameOfSteps)
lp = LongProcessDataClass();
lp.TotalSteps = totalSteps;
lp.StepsDone = 0;
lp.TimeStarted = tic();
lp.EstimatedTimeLeft = 1e9;

if (~exist('nameOfStep', 'var') || isempty(nameOfSteps))
    lp.TextFormat = '{StepsDone:%d}/{TotalSteps:%d} steps done ({StepsDone:%0.1f%%}). Approximately {EstimatedTimeLeft:%0.0f} more seconds.';
else
    lp.TextFormat = ['{StepsDone:%d}/{TotalSteps:%d} ' nameOfSteps ' done ({StepsDone:%0.1f%%}). Approximately {EstimatedTimeLeft:%0.0f} more seconds.'];
end



function LongProcessEnded(lp)
lp.TimeEnded = toc(lp.TimeStarted);

if (~isempty(lp.DialogHandle))
    delete(lp.DialogHandle);
    lp.DialogHandle = [];
end

function [shouldContinue] = LongProcessStep(lp, stepsDone, totalSteps)
shouldContinue = 1;
tElapsed = toc(lp.TimeStarted);

if (~exist('stepsDone', 'var') || isempty(stepsDone))
    stepsDone = lp.StepsDone + 1;
end
lp.StepsDone = stepsDone;

if (~exist('totalSteps', 'var') || isempty(totalSteps))
    totalSteps = lp.TotalSteps;
else
    lp.TotalSteps = totalSteps;
end

textFormat = lp.TextFormat;
% if (~exist('textFormat', 'var') || isempty(textFormat))
%     textFormat = lp.TextFormat;
% else
%     lp.TextFormat = textFormat;
% end

done = (stepsDone-1)/totalSteps;
estimatedTimeLeft = tElapsed * (1-done) / done;
lp.EstimatedTimeLeft = estimatedTimeLeft;

if (isempty(lp.DialogHandle)) % Not displaying dialog yet?
    if (tElapsed > 2 && estimatedTimeLeft > 2)
        lp.DialogHandle = waitbar(0, '', ...
            'CreateCancelBtn', 'setappdata(gcbf, ''canceling'', 1)')
        setappdata(lp.DialogHandle, 'canceling', 0);

        if (0)
            % An example code - how to delete a rogue wait-bar
            set(0,'ShowHiddenHandles','on')
            delete(get(0,'Children'))
        end
    end
end

if (~isempty(lp.DialogHandle))
    try
        [tokenNames, split] = regexp(textFormat, '{(?<FieldName>.*?):(?<Format>.*?)}','names', 'split');
        
        displayedString = split{1};
        for i = 1:numel(tokenNames)
            displayedString = [displayedString sprintf(tokenNames(i).Format, lp.(tokenNames(i).FieldName)) split{i+1}];
        end
        
        waitbar(done, lp.DialogHandle, displayedString);
    catch err
        1;
    end
    
    % Did the user click "cancel"?
    if (getappdata(lp.DialogHandle, 'canceling'))
        lp.ShouldCancel = 1;
        LongProcessEnded(lp);
        shouldContinue = 0;
        return;
    end
end


% --- Executes on button press in plotAllButton.
function plotAllButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotAllButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

outfilename = get(handles.filenameListBox, 'String');
fileFullPaths = get(handles.filenameListBox, 'UserData');
set(handles.DisplayedFilesList,'String',[]);

lp = LongProcessStarted(numel(outfilename), 'files');
try
    for i = 1:length (outfilename)
        if (~LongProcessStep(lp, i, [])); break; end
        handles = addingnew(hObject, handles, fileFullPaths{i}, false, false);
    end
catch err
    1;
end

LongProcessEnded(lp);

% Update handles structure
guidata(hObject, handles);
plotit(hObject,handles);



% --------------------------------------------------------------------
function ExportCurvesMatrixMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to ExportCurvesMatrixMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

displayOptions = handles.DisplayOptions;

numOfCurves = numel(handles.State.Curves);
shouldExportSpreading = 0;

curves = handles.State.Curves;

if (ShouldUseOnlySelected(hObject, handles))
    selectedFileIndexes = get(handles.DisplayedFilesList, 'Value');
    curves = curves(selectedFileIndexes);
end


curveFilenames = cellfun(@(c)strrep(c, ',', '_'), {curves.Filename}, 'UniformOutput', false);
X = {curves.Q};
Y = {curves.I};
YErr = {curves.IErr};

smallNum = 1e-9;

% sizes = cellfun(@(c)size(c), X, 'UniformOutput', false)';
% sizes = vertcat(sizes{:});

if (0)
    for i = 2:numel(X)
        if (any(size(X{1}) ~= size(X{i})) || any(abs(X{1} - X{i}) > smallNum))
            errordlg('Currently export requires all curves to be integrated the same. Some of the curves have different Q scale.');
            return;
        end
    end
end

if (numOfCurves > 1 && displayOptions.SpreadCurvesMethod > 1)
    button = questdlg('Export data computed with the selected spreading?', '', 'Original Data', 'Include Spreading', 'Original Data');
    
    switch button
        case 'Original Data'
            shouldExportSpreading = 0;
        case 'Include Spreading'
            shouldExportSpreading = 1;
        otherwise
            return;
    end
end

currentFolder = handles.DisplayOptions.GetDirectory();
[saveFilename,saveFolder,filterIndex] = uiputfile('*.csv', 'Save data file', currentFolder);
if saveFilename
    len=length(saveFilename);
    if ~(strcmpi(saveFilename(len-3:len),'.csv'))
        saveFilename = [saveFilename '.csv'];
    end
end

saveFilePath = [saveFolder saveFilename];

if (numOfCurves > 1 && shouldExportSpreading)
    switch(displayOptions.SpreadCurvesMethod)
        case 2
            [Y Err] = SpreadCurvesMultiplicatively(X, Y, YErr, displayOptions.SpreadCurvesBy);
        case 3
            Y = SpreadCurvesAdditively(X, Y, displayOptions.SpreadCurvesBy);
        case 4
            [Y Err] = SpreadCurvesMultiplicatively(X, Y, YErr, displayOptions.SpreadCurvesBy, 1);
        case 5
            Y = SpreadCurvesAdditively(X, Y, YErr, displayOptions.SpreadCurvesBy, 1);
    end
end

sharedXCurves = struct();
sharedXCurves.X = X{1};
sharedXCurves.Y = [];
sharedXCurves.Filenames = {};

for i = 1:numel(X)
    
    whichFit = arrayfun(@(j)(all(size(sharedXCurves(j).X) == size(X{i})) && all(abs(sharedXCurves(j).X - X{i}) < smallNum)), 1:numel(sharedXCurves));
    firstFit = find(whichFit, 1); % Actually this is just formal. There should be only one.
    
    if (isempty(firstFit))
        sharedXCurves(end+1).X = X{i};
        firstFit = numel(sharedXCurves);
    end
    
    sharedXCurves(firstFit).Y = [sharedXCurves(firstFit).Y Y{i}];
    sharedXCurves(firstFit).Filenames{end + 1} = curveFilenames{i};
end


f = fopen(saveFilePath, 'w');
if (f == -1)
    errordlg('Could not open the selected file for writing!');
    return;
end

try
    %% Write headers
    for sharedXindex = 1:numel(sharedXCurves)
        if (sharedXindex > 1)
            fprintf(f, ',');
        end
        
        fprintf(f, 'Q');
        fprintf(f, ',%s', sharedXCurves(sharedXindex).Filenames{:});
    end
    fprintf(f, '\r\n');
    
    %% Write data
    rowLengths = cellfun(@(c)numel(c), {sharedXCurves.X});
    for row = 1:max(rowLengths)
        for sharedXindex = 1:numel(sharedXCurves)
            c = sharedXCurves(sharedXindex);
            
            if (sharedXindex > 1)
                fprintf(f, ',');
            end
            
            % Write out empty data if no more
            if (row > rowLengths(sharedXindex))
                fprintf(f, char(zeros(1, size(c.Y, 2)) + ','));
                continue;
            end
            
            fprintf(f, '%f', c.X(row));
            
            rowData = c.Y(row, :);
            fprintf(f, ',%f', c.Y(row, :));
        end
        
        fprintf(f, '\r\n');
    end
catch
end

fclose(f);
1;



% --------------------------------------------------------------------
function Displayed1dFilesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to Displayed1dFilesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_2_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function InInverseAngstromMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to InInverseAngstromMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function InInverseNanometerMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to InInverseNanometerMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Save2dImageMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to Save2dImageMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fn,pathn]=uiputfile('*.png', 'Save image file');

if fn
    len=length(fn);
    if ~(strcmp(lower(fn(len-3:len)),'.png'))
        fn=[fn '.png'];
    end
    
    %I = getframe(handles.fig_main);
    %imwrite(I.cdata, fn);
    %uisave
    %saveas(handles.fig_main, 'sdfsf.jpg')
    %print(handles.axes1, 'test1.png', '-dpng')
end


% --------------------------------------------------------------------
function Save2dImageMinLogScanSeriesMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to Save2dImageMinLogScanSeriesMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on key press with focus on fig_main and none of its controls.
function fig_main_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to fig_main (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

display(eventdata.Character);
1;


% --------------------------------------------------------------------
function MarkPeaksMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to MarkPeaksMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function [q, I, plotHandles] = MarkSeries(hObject, eventdata, handles, seriesRatios, lineStyle)
plotType = get(handles.switchIt, 'Value');
if (plotType ~= 1); return; end

[q, I, but] = ginput(1);
if (but ~= 1); return; end;

% set(handles.axes2, 'position', get(handles.axes1, 'position'));
% set(handles.axes2, 'xlim', get(handles.axes1, 'xlim'));
% set(handles.axes2, 'ylim', get(handles.axes1, 'ylim'));
set(handles.axes2, ...
    'XScale', get(handles.axes1, 'XScale'), ...
    'YScale', get(handles.axes1, 'YScale'), ...
    'Position', get(handles.axes1, 'Position'));

axes(handles.axes2);

xl = xlim();
yl = ylim();

peaks = q*seriesRatios;
peaks(peaks > xl(2)) = [];

colorMap = jet(32);
color = colorMap(round(1 + rand(1) * 31), :);

hold on;
plotHandles = plot(bsxfun(@times, peaks, [1;1]), bsxfun(@times, peaks .* 0 + 1, yl(:)), 'LineStyle', lineStyle, 'Color', color);
hold off;
xlim(xl);
ylim(yl);

function [] = UpdateLegend(handles)
which = arrayfun(@(c)~isempty(get(c, 'UserData')), [handles.axes2.Children]);
legendStrings = arrayfun(@(c)get(c, 'UserData'), [handles.axes2.Children(which)], 'UniformOutput', false);
plotHandles = handles.axes2.Children(which);
%l = legend(handles.axes2, plotHandles, legendStrings);
l = legend(handles.axes2, plotHandles(end:-1:1), legendStrings(end:-1:1));
set(l, 'Color', 'w', 'Location', 'northwest');

% --------------------------------------------------------------------
function MarkLamellarPeaks_Callback(hObject, eventdata, handles)
% hObject    handle to MarkLamellarPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[q, I, plotHandles] = MarkSeries(hObject, eventdata, handles, [1:10], '--');
set(plotHandles(1), 'UserData', sprintf('Lamellar d = %0.5g', 2*pi/q));
set(handles.calcText, 'String', sprintf('Lamellar q = %0.5g, d = 2pi/x = %0.5g', q, 2*pi/q));
UpdateLegend(handles);


% --------------------------------------------------------------------
function MarkHexagonalPeaks_Callback(hObject, eventdata, handles)
% hObject    handle to MarkHexagonalPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[q, I, plotHandles] = MarkSeries(hObject, eventdata, handles, sqrt([1 3 4 7 9 12 13 19]), '-.');
set(handles.calcText, 'String', sprintf('Hexagonal q = %0.5g, a = (4pi/sqrt(3))/x = %0.5g', q, (4*pi/sqrt(3))/q));
set(plotHandles(1), 'UserData', sprintf('Hexagonal a = %0.5g', (4*pi/sqrt(3))/q));
UpdateLegend(handles);

% --------------------------------------------------------------------
function MarkCubicPeaks_Callback(hObject, eventdata, handles)
% hObject    handle to MarkCubicPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[q, I, plotHandles] = MarkSeries(hObject, eventdata, handles, sqrt([1 2 3 4 5 6 8 9]), ':');
set(handles.calcText, 'String', sprintf('Cubic q = %0.5g, d = 2pi/x = %0.5g', q, 2*pi/q));
set(plotHandles(1), 'UserData', sprintf('Cubic d = %0.5g', 2*pi/q));
UpdateLegend(handles);


% --------------------------------------------------------------------
function DeleteAllMarkedPeaks_Callback(hObject, eventdata, handles)
% hObject    handle to DeleteAllMarkedPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (~isempty(handles.axes2) && ishandle(handles.axes2))
    children = get(handles.axes2, 'Children');
    for c = children
        delete(c);
    end
    
    cla(handles.axes2);
    legend(handles.axes2, 'off');
end
    
% --------------------------------------------------------------------
function GuessAvgSumFilenameMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to GuessAvgSumFilenameMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filenamelist = get(handles.DisplayedFilesList, 'String');

selectedFileIndexes = [];
if (get(handles.UseOnlySelectedCheckbox, 'Value'))
    selectedFileIndexes = get(handles.DisplayedFilesList, 'Value');
    filenamelist = filenamelist(selectedFileIndexes);
end

guess = filenamelist{1};

for i = 2:numel(filenamelist)
    filename = filenamelist{i};
    if (length(guess) > length(filename))
        guess = guess(1:length(filename));
    end
    
    whichNotEqual = ~(lower(guess) == lower(filename(1:numel(guess))));
    firstNotEqual = find(whichNotEqual, 1);
    
    if (~isempty(firstNotEqual))
        guess = guess(1:firstNotEqual-1);
    end
end

set(handles.sumNum, 'String', guess);

1;


% --- Executes on button press in framesButton.
function framesButton_Callback(hObject, eventdata, handles)
% hObject    handle to framesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
1;


% --------------------------------------------------------------------
function Orient2dImagesMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to Orient2dImagesMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
displayOptions = handles.DisplayOptions;
onoff = {'off', 'on'};
set(handles.DoNotReorientMenuItem, 'Checked', onoff{1 + (displayOptions.Normalize2dImageOrientation == 0)});
set(handles.OrientLargeDimVertMenuItem, 'Checked', onoff{1 + (displayOptions.Normalize2dImageOrientation == 1)});
set(handles.OrientLargeDimHorzMenuItem, 'Checked', onoff{1 + (displayOptions.Normalize2dImageOrientation == 2)});
1;

% --------------------------------------------------------------------
function DoNotReorientMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to DoNotReorientMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.DisplayOptions.Normalize2dImageOrientation = 0;
plotit(hObject,handles);

% --------------------------------------------------------------------
function OrientLargeDimVertMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OrientLargeDimVertMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.DisplayOptions.Normalize2dImageOrientation = 1;
plotit(hObject,handles);

% --------------------------------------------------------------------
function OrientLargeDimHorzMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OrientLargeDimHorzMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.DisplayOptions.Normalize2dImageOrientation = 2;
plotit(hObject,handles);


% --------------------------------------------------------------------
function reintegrateTracesBackToImagesMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to reintegrateTracesBackToImagesMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.GeneralOptions.ReintegrateTracesBackToImages = ~handles.GeneralOptions.ReintegrateTracesBackToImages;
saveDefaultSettings(hObject);
1;
