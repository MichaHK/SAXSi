function varargout = CalibrationDialog(varargin)
% CALIBRATIONDIALOG MATLAB code for CalibrationDialog.fig
%      CALIBRATIONDIALOG, by itself, creates a new CALIBRATIONDIALOG or raises the existing
%      singleton*.
%
%      H = CALIBRATIONDIALOG returns the handle to a new CALIBRATIONDIALOG or the handle to
%      the existing singleton*.
%
%      CALIBRATIONDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CALIBRATIONDIALOG.M with the given input arguments.
%
%      CALIBRATIONDIALOG('Property','Value',...) creates a new CALIBRATIONDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CalibrationDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CalibrationDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CalibrationDialog

addpath('CONEX');
addpath('Conic');

% Last Modified by GUIDE v2.5 19-Nov-2013 19:53:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @CalibrationDialog_OpeningFcn, ...
    'gui_OutputFcn',  @CalibrationDialog_OutputFcn, ...
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

% --- Executes just before CalibrationDialog is made visible.
function CalibrationDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CalibrationDialog (see VARARGIN)

handles.CalibrationDialogData = CalibrationDialogDataClass();
data = handles.CalibrationDialogData;

if (numel(varargin) >= 2)
    handles.CalibrationData = varargin{2};
    data.WasInitialCalibrationGiven = 1;
else
    handles.CalibrationData = CalibrationDataClass();
    data.WasInitialCalibrationGiven = 0;
end

if (0)
NET.addAssembly('C:\Files\The Lab (Synced)\Code\SAXSi Dev\SAS.Calibration\SAS.Calibration.Bridge\bin\Debug\SAS.Calibration.Bridge.dll');
calibrationTools = SAS.Calibration.Bridge.CalibrationTools;
%calibrationTools.Calibration2dScore(0, 0, 0);

handles.CalibrationTools = calibrationTools;
end

% Update handles structure
guidata(hObject, handles);

if (numel(varargin) >= 1 && ~isempty(varargin{1}))
    handles.CalibrationDialogData.Image = double(varargin{1});
    HandleNewImage(hObject);
    Redraw(hObject, 0);
else
    handles.CalibrationDialogData.Image = [];
end

LoadCalibrants(hObject, handles);
UpdateCalibrationDisplay(hObject);
ShowDefaultStatus(handles);

% UIWAIT makes CalibrationDialog wait for user response (see UIRESUME)
uiwait(handles.figure1);

function [calibrants] = LoadCalibrants(hObject, handles)
[folder,name,ext] = fileparts(mfilename('fullpath'));
calibrantsCsv = MyCsvRead([folder filesep 'Calibrants.csv']);
calibrants = [];

defaultLambda = 1.5405929; % ?

for i = 1:size(calibrantsCsv.Data, 1)
    try
        calName = calibrantsCsv.Data{i, 1};
        calCsv = MyCsvRead([folder filesep calibrantsCsv.Data{i, 2}]);
        qPeaks = [];
        
        for calLine = 1:size(calCsv.Data, 1)
            peakValue = calCsv.NumericData(calLine, 2);
            
            switch (calCsv.Data{calLine, 1})
                case 'd-spacing'
                    peakValue = (2 * pi()) / peakValue;
                case 'bragg-angle'
                    lambda = defaultLambda;
                    
                    if (size(calCsv.Data, 2) >= 3 && ~isempty(calCsv.Data{calLine, 3}))
                        lambda = calCsv.NumericData(calLine, 3);
                    end
                    
                    peakValue = (4 * pi() / lambda) * sin(deg2rad(peakValue * 0.5));
                case 'q'
                    1; % Do nothing
                otherwise
                    continue;
            end
            
            for harmony = 1:calCsv.NumericData(calLine, 3)
                qPeaks(end+1) = peakValue * harmony;
            end
        end
        
        calibrants(end+1).Name = calName;
        calibrants(end).Peaks = sort(qPeaks);
    catch err
        1;
    end
end

handles.Calibrants = calibrants;
guidata(hObject, handles);

calibrantNames = {calibrants.Name};
set(handles.SelectCalibrantDropdown, 'String', calibrantNames);
set(handles.SelectCalibrantDropdown, 'Value', 1);
SelectCalibrantDropdown_Callback(handles.SelectCalibrantDropdown, [], handles);
SelectPeakDropdown_Callback(handles.SelectPeakDropdown, [], handles);

1;

% --- Outputs from this function are returned to the command line.
function varargout = CalibrationDialog_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (~isempty(handles))
    %varargout{1} = handles.figure1;
    varargout{1} = handles.CalibrationData;
    varargout{2} = handles.CalibrationDialogData.WasCalibrationAccepted;
end
delete(hObject);

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% axes(handles.Axes_h);
% cla;
%
% popup_sel_index = get(handles.popupmenu1, 'Value');
% switch popup_sel_index
%     case 1
%         plot(rand(5));
%     case 2
%         plot(sin(1:0.01:25.99));
%     case 3
%         bar(1:.5:10);
%     case 4
%         plot(membrane);
%     case 5
%         surf(peaks);
% end

function ShowStatus(handles, msg)
set(handles.StatusLine_h, 'String', msg);

function ShowDefaultStatus(handles)
ShowStatus(handles, '... Waiting for Action ...');

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
    ['Close ' get(handles.figure1,'Name') '...'],...
    'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)

% --- Executes on slider movement.
function UpperLimit_h_Callback(hObject, eventdata, handles)
% hObject    handle to UpperLimit_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UpdateColorAxis(handles);

% --- Executes during object creation, after setting all properties.
function UpperLimit_h_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UpperLimit_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function LowerLimit_h_Callback(hObject, eventdata, handles)
% hObject    handle to LowerLimit_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UpdateColorAxis(handles);

% --- Executes during object creation, after setting all properties.
function LowerLimit_h_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LowerLimit_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function [x, y, ok] = SelectValidPoint(hObject)
handles = guidata(hObject);
axes(handles.Axes_h);
data = handles.CalibrationDialogData;

[x,y,but] = ginput(1);
if (but == 1 && WithinRect([0, 0, size(data.Image, 2), size(data.Image, 1)], x-1, y-1))
    ok = true;
else
    x = [];
    y = [];
    ok = false;
end

function HandleNewImage(hObject)
handles = guidata(hObject);
data = handles.CalibrationDialogData;

% Handle pilatus image gaps
% pilatusGaps = [195+[1:17], 407+[1:17]];
% if (all(data.Image(pilatusGaps, :) <= 0))
%     data.Image(pilatusGaps, :) = NaN;
% end

data.IntensityMin = min(data.Image(:));
data.IntensityMax = max(data.Image(:));

% TODO: Use the gradient of the image to find the center. If the gradient
% and center of intensity do not match, deny the visibility of the center

I = sort(data.Image(:), 'descend');
I(isnan(I) | (I < 0)) = [];
I99 = I(floor(numel(I)/100));
which = (data.Image >= I99);
[x,y] = meshgrid(1:size(data.Image, 2),1:size(data.Image, 1));
x = sum(x(which) .* data.Image(which)) / sum(data.Image(which));
y = sum(y(which) .* data.Image(which)) / sum(data.Image(which));

if (~data.WasInitialCalibrationGiven)
    handles.CalibrationData.BeamCenterX = x;
    handles.CalibrationData.BeamCenterY = y;
end

set(handles.SelectImageBtn, 'String', 'Replace image...');
resetZoomMenuItem_Callback(hObject, [], handles);

% --- Executes on button press in SelectImageBtn.
function SelectImageBtn_Callback(hObject, eventdata, handles)
% hObject    handle to SelectImageBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = handles.CalibrationDialogData;
I = SelectImageAndRead();

if (~isempty(I))
    data.Image = double(I);
    guidata(hObject, handles);
    HandleNewImage(hObject);
    
    Redraw(hObject);
end


% --------------------------------------------------------------------
function StopMarkingMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to StopMarkingMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ImageMenu_Callback(hObject, eventdata, handles)
% hObject    handle to ImageMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
SetCheckMark(handles.logScaleMenuItem, data.DisplayLogScale);
SetCheckMark(handles.showColorbar, data.ShowColorbar);
SetCheckMark(handles.displayIntensityMenuItem, data.DisplayType == 1);
SetCheckMark(handles.displayGradientMenuItem, data.DisplayType >= 2 && data.DisplayType <= 4);
SetCheckMark(handles.displayXGradientMenuItem, data.DisplayType == 2);
SetCheckMark(handles.displayYGradientMenuItem, data.DisplayType == 3);
SetCheckMark(handles.displayXYGradientMenuItem, data.DisplayType == 4);
SetCheckMark(handles.displayLaplacianMenuItem, data.DisplayType == 5);

SetCheckMark(handles.blurZeroMenuItem, data.BlurSize <= 0);
SetCheckMark(handles.blur7MenuItem, data.BlurSize == 7);
SetCheckMark(handles.blur17MenuItem, data.BlurSize == 17);
SetCheckMark(handles.blur31MenuItem, data.BlurSize == 31);

zoomHandle = zoom(handles.figure1);
set(handles.zoomMenuItem, 'Checked', zoomHandle.Enable);
panHandle = pan(handles.figure1);
set(handles.panMenuItem, 'Checked', panHandle.Enable);


% --------------------------------------------------------------------
function resetZoomMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to resetZoomMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.Axes_h);
hold on;
xlim('auto')
ylim('auto')
hold off;

% --------------------------------------------------------------------
function zoomMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to zoomMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.Axes_h);
zoomHandle = zoom(handles.figure1);

if (strcmp(zoomHandle.Enable, 'off'))
    zoomHandle.UIContextMenu = handles.ImageMenu;
    zoomHandle.Enable = 'on';
else
    zoomHandle.Enable = 'off';
end

function DrawMask(hObject, handles, data)

if (~exist('handles', 'var') || isempty(handles))
    handles = guidata(hObject);
end

if (~exist('data', 'var') || isempty(data))
    data = handles.CalibrationDialogData;
end

mask = GetMask(hObject, data);

axes(handles.Axes_h);
hold on;
maskImage = zeros([size(mask), 3]);
maskImage(:, :, 1) = 1;

h = image(maskImage, 'AlphaData', ~mask);
set(h, 'UIContextMenu', handles.ImageMenu);
hold off;

%%
function Redraw(hObject, restoreLimits)

if (nargin < 2)
    restoreLimits = 1;
end

handles = guidata(hObject);
axes(handles.Axes_h); % Focus on the relevant axes
data = handles.CalibrationDialogData;

if (restoreLimits)
    savedXlimits = xlim();
    savedYlimits = ylim();
end

hold off;

% Display a logarithmic scaled image
I = double(data.Image);

ignoredPixels = I < 0;

if (data.BlurSize > 1)
    I = conv2(I, kron(gausswin(data.BlurSize)', gausswin(data.BlurSize)), 'same');
end

switch data.DisplayType
    case 1 % Intensity (do nothing)
        1;
    case 2 % X gradient
        [gX, gY] = gradient(I);
        I = gX;
    case 3 % Y gradient
        [gX, gY] = gradient(I);
        I = gY;
    case 4 % X+Y gradient
        [gX, gY] = gradient(I);
        I = abs(gX) + abs(gY); % "abs", otherwise they migh "destructively interfere"
    case 5 % Laplacian
        I = conv2(I, kron([-1 2 -1], [-1 2 -1]'), 'same');
        %I = del2(I);
    otherwise
        1;
end

I(ignoredPixels) = 0;

if (data.DisplayLogScale)
    %I = log(abs(I) + 1);
    s = sign(I);
    I = s .* log(abs(I) + 1);
end

if (numel(I) > 1e6) % Display image with reduced resolution?
    XVector = 1:size(I, 2);
    YVector = 1:size(I, 1);
    [X, Y] = meshgrid(XVector, YVector);
    which = (mod(X, 2) == 0) & (mod(Y, 2) == 0);
    imageToDisplay = reshape(I(which), floor(size(I, 1)/2), floor(size(I, 2)/2));
    %maskToDisplay = 
    calibImage_h = imagesc([1:size(imageToDisplay, 2)]*2, [1:size(imageToDisplay, 1)]*2, imageToDisplay);
    %DrawMask(hObject, handles, data);
else
    calibImage_h = imagesc(I);
    DrawMask(hObject, handles, data);
end

axis equal; % Make axes equal

set(calibImage_h,'UIContextMenu', get(handles.Axes_h, 'UIContextMenu'));

data.DisplayedImageMin = min(I(:));
data.DisplayedImageMax = max(I(:));
UpdateColorAxis(handles);

colormap(handles.Axes_h, data.Colormap); % Set color map

if (data.ShowColorbar)
    colorbar;
end

%set(handles.Axes_h,'Xtick',[],'Ytick',[]); % Remove numbers from axes
PlotBigMark([handles.CalibrationData.BeamCenterX, handles.CalibrationData.BeamCenterY]);

for i = 1:numel(data.DrawQ)
    q = data.DrawQ(i);
    color = data.DrawQColor{i};
    PlotQ(hObject, q, color);
end

if (restoreLimits)
    xlim(savedXlimits);
    ylim(savedYlimits);
end


function UpdateColorAxis(handles)
data = handles.CalibrationDialogData;

if (isempty(data.DisplayedImageMin))
    return;
end

% Filter intensity using the sliders
minimalIntensity = data.DisplayedImageMin;
intensityRange = data.DisplayedImageMax - minimalIntensity;

loLimit = get(handles.LowerLimit_h,'value');
hiLimit = get(handles.UpperLimit_h,'value');

if (data.DisplayLogScale == 0 && data.DisplayType == 1)
    loLimit = exp(-(1-loLimit)*10);
    hiLimit = exp(-(1-hiLimit)*10);
end

loLimit = minimalIntensity + loLimit * intensityRange;
hiLimit = minimalIntensity + hiLimit * intensityRange;

caxis(handles.Axes_h, [loLimit, hiLimit]);

function PlotCircle(at, r, color, lineWidth)

if (~exist('r', 'var') || isempty(r))
    r = 10;
end

if (~exist('color', 'var') || isempty(color))
    color = 'red';
end

if (~exist('lineWidth', 'var') || isempty(lineWidth))
    lineWidth = 2;
end

hold on;
theta = linspace(0, 2 * pi, 36*2);
x = at(1) + r .* cos(theta);
y = at(2) + r .* sin(theta);
plot(x, y, '-', 'Color', color, 'LineWidth', lineWidth);


hold off;

function PlotBigMark(at)
hold on;
r = 25;
theta = linspace(0, 2 * pi, 100);
x = at(1) + r .* cos(theta);
y = at(2) + r .* sin(theta);
plot(x, y, '-g', 'LineWidth', 2);

theta = [0.25,0.75,1.25,1.75] * pi;
x = zeros(1, 8);
x(2:2:8) = r .* cos(theta);
x = x + at(1);
y = zeros(1, 8);
y(2:2:8) = r .* sin(theta);
y = y + at(2);

plot(x, y, '-g', 'LineWidth', 1);

hold off;


function [score] = MinimizedConicScoreFunction(image, conic, x, y)
if (conic.IsValidForParametricForm())
    %     [avg, avgErr] = AverageOnGenericConic(image, conic);
    %     score = -avg / (avgErr + 1e-12);
    val = interp2(image, x, y);
    values = GetValuesOnConic(image, conic, 1000);
    
    qf = conic.QuadraticForm;
    score = meansqr(values - val) + 1e-2 * (qf(1) * x ^ 2 + qf(2) * x * y + qf(3) * y ^ 2 + qf(4) * x + qf(5) * y + qf(6));
    
else
    %score = 0;
    score = 1e9;
end

function [score] = MinimizedQuadraticFormScoreFunction(image, qf)
conic = ConicClass();
conic.SetQuadraticForm(qf);

values = GetValuesOnConic(image, conic, 1000);
score = -mean(values);


function [score] = MinimizedQConicScoreFunction(image, x, y, peakIntensityEst, alpha, d, Xd, Yd, beta, coneAngle)
conic = ConicClass();
conic.SetConexParameters(alpha, d, Xd, Yd, beta, coneAngle);

factor = max(image(:));

VeryHighScore = 1e9;

score = VeryHighScore;

if (conic.IsValidForParametricForm())
    conic.DebugPlotInRect(GetRectForImageMatrix(image));
    %uiwait(gcf, 0.1);
    
    %     [avg, avgErr] = AverageOnGenericConic(image, conic);
    %     score = -avg / (avgErr + 1e-12);
    val = interp2(image, x, y);
    [~, tx] = conic.GetYForX(x);
    [~, ty] = conic.GetXForY(y);
    
    % Look for intersections with the given X,Y coordinates and their
    % distance
    [intX, intY] = conic.GetPointsFromParametricForm([tx ty]);
    dist = sqrt(min([intX - x] .^ 2 + [intY - y] .^ 2));
    
    % Penalty for having a conic that does not pass in the
    % proximity of the marked point (proximity being ?? pixels)
    if (~isempty(dist))
        if (dist < 50)
            values = GetValuesOnConic(image, conic, 1000);
            conic.DebugPlot2();
            if (all(values < 10 * peakIntensityEst))
                %score = -mean(values) / std(values);
                %score = -mean(values) + std(values);
                %score = -mean(values) + mean(abs(diff(values))) * 10;
                score = -mean(values);
                
                % "std" treats a continuous change and an abrupt change the
                % same, so to favor le
                
                % This is to make this function sort of smooth
                if (dist > 25) % 25 < dist < 50
                    blending = exp(1-25/(dist-25));
                    score = score * (1-blending) + VeryHighScore * blending;
                end
            else
                1;
            end
        else % Make the score dominated by proximity to the selected point
            score = VeryHighScore * exp(1-50/dist);
        end
    end
    
    %qf = conic.QuadraticForm;
    %score = meansqr(values - val) + factor * abs(qf(1) * x ^ 2 + qf(2) * x * y + qf(3) * y ^ 2 + qf(4) * x + qf(5) * y + qf(6));
    %score = -mean(values) + factor * abs(qf(1) * x ^ 2 + qf(2) * x * y + qf(3) * y ^ 2 + qf(4) * x + qf(5) * y + qf(6));
    %score = -mean(values);
    
else
    1;
end

function [c,ceq] = ValidConexConicNonlinearConstraint(p, theta)
conic = ConicClass();
conic.SetConexParameters(p(1), p(2), p(3), p(4), p(5), theta);
c = conic.GetConicTypeNumeric()  <= 3; % Make sure this is either of: Circle, Ellipse, Hyperbola
ceq = [];

function [c,ceq] = ValidConicNonlinearConstraint(qf)
conic = ConicClass();
conic.SetQuadraticForm(qf);
c = conic.GetConicTypeNumeric() - 3; % Make sure this is either of: Circle, Ellipse, Hyperbola
ceq = [];

function [rect] = GetRectForImageMatrix(image)
if (numel(image) > 2)
    image = size(image);
end
rect = [1, 1, image(2) - 1, image(1) - 1];

% --- Executes on button press in markPeak1Pts.
function markPeak1Pts_Callback_old(hObject, eventdata, handles)
data = handles.CalibrationDialogData;
cal = handles.CalibrationData;

[x, y, ok] = SelectValidPoint(hObject);

tStarted = tic();

downScaleFactor = 0.5;
restoreScaleFactor = 1 / downScaleFactor;

if (1)
    image = imresize(data.Image, downScaleFactor);
    x = x * downScaleFactor;
    y = y * downScaleFactor;
end

directions = [...
    1 -1 0  0;...
    0  0 1 -1];

if (ok)
    
    q = 0.1075; % ?^-1
    twoK = (4 * pi) / cal.Lambda;
    twoTheta = 2 * asin(q / twoK);
    
    smoothingKernelSize = 5;
    smoothingKernel = kron(gausswin(smoothingKernelSize), gausswin(smoothingKernelSize)');
    smoothingKernel = smoothingKernel / sum(smoothingKernel(:)); % Average with neighbors
    smootherI = conv2(image, smoothingKernel, 'same');
    
    if (0)
        g = gradient(smootherI);
        figure; imagesc(abs(g));
        figure; imagesc(log(1+abs(g)));
        %figure; imagesc(log(abs(g) ./ (2+smootherI)));
    end
    
    % Find the max intensity in the clicked area
    e = 10;
    %peakIntensityEst = max(max(smootherI([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e])));
    [peakIntensityEst, peakRow] = max(image([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]));
    [peakIntensityEst, peakCol] = max(peakIntensityEst);
    peakRow = peakRow(peakCol) + floor(y) - e - 1;
    peakCol = peakCol + floor(x) - e - 1;
    
    sortedIntensities = sort(image(:));
    minUsedIntensity = peakIntensityEst / 4;
    
    if (minUsedIntensity < sortedIntensities(floor(0.99*end)))
        minUsedIntensity = sortedIntensities(floor(0.99*end));
    end
    
    %%
    
    relevantMask = double(image > minUsedIntensity & image < (peakIntensityEst * 4));
    %figure; imagesc(relevantMask)
    
    lastUsedMask = zeros(size(image));
    usedMask = zeros(size(image));
    
    usedMask(peakRow, peakCol) = 1;
    k = 5;
    
    
    if (0)
        figure; imagesc(usedMask + relevantMask)
    end
    
    % Grow a relevant area with the "relevantMask" as a constraint
    numOfDilationIterations = 0;
    while (any(usedMask(:) ~= lastUsedMask(:)))
        numOfDilationIterations = numOfDilationIterations + 1;
        
        lastUsedMask = usedMask;
        
        if (1)
            minRow = max(find(sum(usedMask, 2), 1, 'first') - k, 1);
            maxRow = min(find(sum(usedMask, 2), 1, 'last') + k, size(usedMask, 1));
            
            minCol = max(find(sum(usedMask, 1), 1, 'first') - k, 1);
            maxCol = min(find(sum(usedMask, 1), 1, 'last') + k, size(usedMask, 2));
            
            modifiedMask = imdilate(usedMask(minRow:maxRow, minCol:maxCol), ones(k)) .* relevantMask(minRow:maxRow, minCol:maxCol);
            
            if (0)
                changed = modifiedMask - usedMask(minRow:maxRow, minCol:maxCol);
                available = relevantMask - usedMask;
                usedMask(minRow:maxRow, minCol:maxCol) = modifiedMask;
                
                [changedRows, changedCols] = find(changed);
                changedRows = changedRows + minRow - 1;
                changedCols = changedCols + minCol - 1;
                
                for i = unique(randi([1, numel(changedRows)], 1, 7))
                    r = changedRows(i);
                    c = changedCols(i);
                    
                    optionalDirections = available(sub2ind(r + directions(1, :), c + directions(2, :)));
                    optionalDirections = find(optionalDirections);
                    if (~isempty(optionalDirections))
                        dir = optionalDirections(randi(numel(optionalDirections), 1));
                    end
                    
                end
            else
                usedMask(minRow:maxRow, minCol:maxCol) = modifiedMask;
            end
            
        else
            usedMask = imdilate(usedMask, ones(k)) .* relevantMask;
        end
        
        if (1)
            xl = xlim();
            yl = ylim();
            imagesc(usedMask + relevantMask);
            xlim(xl);
            ylim(yl);
        end
    end
    
    if (1)
        xl = xlim();
        yl = ylim();
        imagesc(usedMask + relevantMask);
        xlim(xl);
        ylim(yl);
    end
    
    [rows, cols] = find(usedMask);
    
    centerOfMass = [mean(rows) mean(cols)];
    hold on; plot(centerOfMass(2), centerOfMass(1), 'r*', 'MarkerSize', 16); hold off;
    
    %%
    
    bestSelectedIndices = [];
    minSumOfDistances = inf;
    
    for i = 1:50
        selectedIndices = floor(rand(1, 5) * (numel(rows) - 1) + 1);
        selectedRows = rows(selectedIndices);
        selectedCols = cols(selectedIndices);
        
        sumOfDistances = 0;
        rmin = 100;
        for i = 1:numel(selectedIndices)
            dists = sqrt((selectedRows - selectedRows(i)) .^ 2 + (selectedCols - selectedCols(i)) .^ 2)
            tmp = (rmin ./ dists) .^ 6;
            pot = tmp .^ 2 - 2 * tmp;
            sumOfDistances = sumOfDistances + sum(pot(~isnan(pot)));
        end
        
        if (minSumOfDistances > sumOfDistances)
            minSumOfDistances = sumOfDistances;
            bestSelectedIndices = selectedIndices;
        end
    end
    
    selectedIndices = bestSelectedIndices;
    selectedRows = rows(selectedIndices);
    selectedCols = cols(selectedIndices);
    
    %%
    
    conic = ConicClass();
    conic.SetSolutionOf5Points(selectedCols * restoreScaleFactor, selectedRows * restoreScaleFactor);
    
    hold on;
    xl = xlim();
    yl = ylim();
    plot(selectedCols * restoreScaleFactor, selectedRows * restoreScaleFactor, '*g', 'MarkerSize', 16);
    conic.DebugPlotInRect([1, 1, size(data.Image, 2), size(data.Image, 1)]);
    xlim(xl);
    ylim(yl);
    hold off;
    
    tElapsed = toc(tStarted);
    display(sprintf('Initial conic took %0.2f seconds (%i dilation iterations)', ...
        tElapsed, numOfDilationIterations));
    1;
    
    %% Fit a circle
    
    pointsX = cols * restoreScaleFactor;
    pointsY = rows * restoreScaleFactor;
    centerX = data.EstimatedCenter(1);
    centerY = data.EstimatedCenter(2);
    
    radiusGuess = mean(sqrt((pointsX - centerX) .^ 2 + (pointsY - centerY) .^ 2));
    
    initialParameters = [data.EstimatedCenter, radiusGuess];
    
    opt = optimset('maxfunevals', 1e6, 'maxiter', 1e4, 'display','on');
    
    bestParameters = fminsearch(@(p)sum(abs((pointsX - p(1)) .^ 2 + (pointsY - p(2)) .^ 2 - p(3)^2)), initialParameters, opt);
    initialParameters = bestParameters;
    
    xyc = bestParameters(1:2);
    radiusGuess = bestParameters(3);
    
    %% Fit to geometric paramteres (CONEX)
    
    d0 = radiusGuess / twoTheta(1);
    Yd0 = xyc(2);
    Xd0 = xyc(1);
    initialParameters = [0 d0 Xd0 Yd0 0];
    
    xy = [pointsX, pointsY];
    
    hold on;
    conic = ConicClass();
    p = initialParameters;
    conic.SetConexParameters(p(1), p(2), p(3), p(4), p(5), twoTheta);
    conic.DebugPlotInRect([1, 1, size(data.Image, 2), size(data.Image, 1)]);
    conic.DebugPlot2();
    hold off;
    
    minimizedFunc = @(p)sum(abs(twoTheta - Theta_xy_radians(xy, p)));
    
    for r = 1:1
        bestParameters = fminsearch(minimizedFunc, initialParameters);
        initialParameters = bestParameters;
    end
    
    hold on;
    conic = ConicClass();
    p = bestParameters;
    conic.SetConexParameters(p(1), p(2), p(3), p(4), p(5), twoTheta);
    conic.DebugPlotInRect([1, 1, size(data.Image, 2), size(data.Image, 1)]);
    conic.DebugPlot2();
    hold off;
    drawnow expose;
    1;
    
    %%
    
    % Fit conic with quadratic for parameterization
    if (0)
        
        options = optimset('fminbnd');
        options.Algorithm = 'interior-point';
        options.Display = 'testing'; % off, notify, final, iter, testing
        options.Diagnostics = 'on';
        options.MaxTime = 20;
        options.MaxIter = 500;
        options.AlwaysHonorConstraints = 'on';
        options.MaxFunEvals = 1e3;
        options.TolX = 1e-12;
        options.TolFun = 1e-4;
        
        %options.DiffMinChange = [1e-3, 1, 1e-2, 1e-2, 1e-3];
        %options.DiffMaxChange = [0.3, 5e3, 5, 5, 0.3];
        options.DiffMinChange = 1e-7;
        options.DiffMaxChange = 0.1;
        
        options.FinDiffType = 'central';
        options.FinDiffRelStep = 1e-8;
        
        % TODO: Minimize over a set of 10 parameters: 2 for each pair of
        % coordinates for points defining the conic
        
        
        qf0 = conic.QuadraticForm / conic.QuadraticForm(6);
        [optimal,fval,exitflag,output] = fmincon(@(qf)MinimizedQuadraticFormScoreFunction(...
            data.Image, [qf; 1]), ...
            qf0(1:5),...
            [],[],[],[],...
            min([qf0(1:5) * 0.1, qf0(1:5) * 10], [], 2),...
            max([qf0(1:5) * 0.1, qf0(1:5) * 10], [], 2),...
            @(qf)ValidConicNonlinearConstraint([qf; 1]), options);
        
        Redraw(hObject);
        conic = ConicClass();
        
        qf = optimal;
        conic.SetQuadraticForm([optimal; 1]);
        conic.DebugPlot2();
        1;
        
        return;
        
    end
    
    
    
    
    
    CompleteQuadraticForm = @(p)[p (-p(1)*x^2-p(2)*x*y-p(3)*y^2-p(4)*x-p(5)*y)];
    
    if (0)
        [optimal,fval,exitflag,output] = fminsearch(@(p)MinimizedConicScoreFunction(log(3 + smootherI), ConicClass(CompleteQuadraticForm(p)), x, y),...
            zeros(1,5));
        
        figure; imagesc(log(3 + smootherI));
        conic = ConicClass(CompleteQuadraticForm(optimal));
        conic.DebugPlotInRect(GetRectForImageMatrix(smootherI));
        1;
    end
    
    %     minimizedFunc = @(p)MinimizedQConicScoreFunction(smootherI, x, y, ...
    %         abs(p(1)), abs(p(2)), data.EstimatedCenter(1), data.EstimatedCenter(2), abs(p(3)), asin(q / twoK));
    %
    %     [optimal,fval,exitflag,output] = fminsearch(minimizedFunc, ...
    %         [cal.AlphaRadians, cal.SampleToDetDist / cal.PixelSize, cal.BetaRadians]);
    %     1;
    
    validConicConstraint = @(p)ValidConexConicNonlinearConstraint(p, twoTheta);
    validCircleConstraint = @(p)ValidConexConicNonlinearConstraint([0, p, 0], twoTheta);
    
    minimizedCirclesFunc = @(p)MinimizedQConicScoreFunction(smootherI, x, y, peakIntensityEst, ...
        0, p(1), p(2), p(3), 0, twoTheta);
    
    minimizedFunc = @(p)MinimizedQConicScoreFunction(smootherI, x, y, peakIntensityEst, ...
        p(1), p(2), p(3), p(4), p(5), twoTheta);
    
    %     [optimal,fval,exitflag,output] = fminsearch(minimizedFunc, ...
    %         [cal.AlphaRadians, cal.SampleToDetDist / cal.PixelSize, ...
    %         data.EstimatedCenter(1), data.EstimatedCenter(2), cal.BetaRadians]);
    
    options = optimset('fminbnd');
    options.Algorithm = 'interior-point';
    options.Display = 'testing'; % off, notify, final, iter, testing
    options.Diagnostics = 'on';
    options.MaxTime = 5;
    options.MaxIter = 100;
    options.AlwaysHonorConstraints = 'on';
    options.MaxFunEvals = 1e3;
    options.TolX = 1e-5;
    options.TolFun = 1e-4;
    
    %options.DiffMinChange = [1e-3, 1, 1e-2, 1e-2, 1e-3];
    %options.DiffMaxChange = [0.3, 5e3, 5, 5, 0.3];
    options.DiffMinChange = 1e-7;
    options.DiffMaxChange = 0.1;
    
    options.FinDiffType = 'central';
    options.FinDiffRelStep = 1e-2;
    
    Redraw(hObject);
    
    %cal.SampleToDetDist = ;
    %dGuess = cal.SampleToDetDist / cal.PixelSize;
    dGuess = sqrt((x - data.EstimatedCenter(1))^2 + (y - data.EstimatedCenter(2))^2) / tan(twoTheta);
    % tan(2 theta) = r / d   =>   d = r/tan(2 theta)
    
    deltaCenter = 70;
    
    options.TypicalX = [dGuess, data.EstimatedCenter];
    
    %figure; imagesc(smootherI);
    %figure; imagesc(log(1+smootherI));
    
    conic = ConicClass();
    conic.SetConexParameters(0, dGuess, ...
        data.EstimatedCenter(1), data.EstimatedCenter(2),...
        0, twoTheta);
    %figure; imagesc(log(3 + smootherI));
    conic.DebugPlotInRect([1, 1, size(smootherI, 2) - 1, size(smootherI, 1) - 1]);
    
    % Minimize on circles to find a coarse fit
    [optimal,fval,exitflag,output] = fmincon(minimizedCirclesFunc, ...
        [dGuess, data.EstimatedCenter(1), data.EstimatedCenter(2)],...
        [],[],[],[],...
        [10/cal.PixelSize, data.EstimatedCenter(1) - deltaCenter, data.EstimatedCenter(2) - deltaCenter],...
        [3.5e3/cal.PixelSize, data.EstimatedCenter(1) + deltaCenter, data.EstimatedCenter(2) + deltaCenter],...
        validCircleConstraint, options);
    
    % TODO: Confine the conic to a band with intensity similar to that of
    % the marked peak
    
    1;
    data.EstimatedCenter = optimal(2:3);
    Redraw(hObject);
    conic = ConicClass();
    optimal = abs(optimal);
    conic.SetConexParameters(0, optimal(1), ...
        optimal(2), optimal(3),...
        0, twoTheta);
    %figure; imagesc(log(3 + smootherI));
    conic.DebugPlotInRect([1, 1, size(smootherI, 2) - 1, size(smootherI, 1) - 1]);
    1;
    
    options.TypicalX = [0.1, 1e3, data.EstimatedCenter, 0.1];
    
    [optimal,fval,exitflag,output] = fmincon(minimizedFunc, ...
        [cal.AlphaRadians, dGuess, ...
        data.EstimatedCenter(1), data.EstimatedCenter(2), cal.BetaRadians],...
        [],[],[],[],...
        [0, 10/cal.PixelSize, data.EstimatedCenter(1) - deltaCenter, data.EstimatedCenter(2) - deltaCenter, 0],...
        [pi/2-1e-4, 3.5e3/cal.PixelSize, data.EstimatedCenter(1) + deltaCenter, data.EstimatedCenter(2) + deltaCenter, 2*pi-1e-4],...
        validConicConstraint, options);
    
    % For secondary refinement
    %options.FinDiffRelStep = output.stepsize * 10;
    options.FinDiffRelStep = [1e-3, 1e-4, 1e-3, 1e-3, 1e-3];
    
    1;
    data.EstimatedCenter = optimal(3:4);
    Redraw(hObject);
    conic = ConicClass();
    optimal = abs(optimal);
    conic.SetConexParameters(optimal(1), optimal(2), ...
        optimal(3), optimal(4),...
        optimal(5), twoTheta);
    %figure; imagesc(log(3 + smootherI));
    conic.DebugPlotInRect([1, 1, size(smootherI, 2) - 1, size(smootherI, 1) - 1]);
    
    1;
    
    
end

Redraw(hObject);


function [x, y] = AdjustPositionTowardsCenterOfIntensity(image, x, y, times, k)
% Adjust position to the highest intensity within K pixels

if (nargin < 4)
    times = 3;
end

if (nargin < 5)
    k = 5; % Size of image-slice to test
end

for i = 1:times
    imageSlice = image([floor(y)-k:floor(y)+k], [floor(x)-k:floor(x)+k]);
    [centerX, centerY] = CenterOfIntensity(imageSlice);
    
    if (0) % for debug
        e = 30;
        imageSlice = image([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);
        figure(2); imagesc(imageSlice);
        ginput(1);
    end
    
    % Move towards the center of intensity
    x = x + centerX - k - 1;
    y = y + centerY - k - 1;
end

function [selectedAngle, scorePerAngle] = DetermineAngleForProfile(image, mask, x, y, blur, testProfileLength, anglesCount)
% [selectedAngle, scorePerAngle] = DetermineAngleForProfile(image, x, y, blur, testProfileLength, anglesCount)

if (~exist('blur', 'var')) blur = 7; end
if (~exist('testProfileLength', 'var')); testProfileLength = 7; end
if (~exist('anglesCount', 'var')); anglesCount = 100; end

smoothingKernel = Normalized2dGaussian(blur);
smootherI = conv2(image, smoothingKernel, 'same');
smootherMask = conv2(mask, smoothingKernel, 'same');
smootherI = smootherI ./ smootherMask;

e = ceil(testProfileLength);
imageSlice = smootherI([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);
maskSlice = mask([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);

% Find an angle for the profile. Choose the direction in which the
% intensity diminishes the most.
angles = linspace(0, 2 * pi - 1e-5, anglesCount);

IntensitySum = @(a, r)sum(GetCentralProfile(imageSlice, a, r) ./ ...
    (GetCentralProfile(maskSlice, a, r) + 1e-5));

scorePerAngle = arrayfun(@(a)IntensitySum(a, linspace(e/2, e, 50)) / IntensitySum(a, linspace(0, e/2, 50)), angles);
[~, angleIndex] = min(scorePerAngle);
selectedAngle = angles(angleIndex);

function [blurSize, blurKernel, peakSigma, blurredImage, blurredMask] = DetermineProperBlurring(image, mask, x, y, profileAngle, profileWidth, blurSizesToTry);

if (exist('profileWidth', 'var'))
    e = profileWidth;
else
    e = 20;
end

display('Determining Appropriate blurring...');
rsquare = [0];
prevBlurSize = 1;
prevPeakSigma = 1;

for blurSize = blurSizesToTry
    blurKernel = Normalized2dGaussian(blurSize);
    blurredImage = conv2(image .* mask, blurKernel, 'same');
    blurredMask = conv2(mask, blurKernel, 'same');
    
    % Exclude pixels for which most of the contribution is masked
    blurredImage(blurredMask < 0.5) = 0;
    
    imageSlice = blurredImage([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);
    maskSlice = blurredMask([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);
    r = [-e:0.5:e];
    profile = GetCentralProfile(imageSlice, profileAngle, r) ./ (GetCentralProfile(maskSlice, profileAngle, r) + 1e-5);
    r(isnan(profile)) = [];
    profile(isnan(profile)) = [];
    
    %warning off;
    [gaussFit, gof] = GaussianSimpleFit(r, profile);
    
    if (0)
        gaussFit
        gof
    end
    
    if (0)
        figure(2); plot(r, profile);
        hold on; plot(r, feval(gaussFit, r), '-k'); hold off;
        ginput(1);
    end
    
    rsquare(end+1) = gof.rsquare;
    peakSigma = gaussFit.c;
    
    gaussianProfile = gaussFit.a*exp(-((r-gaussFit.b)./(gaussFit.c*2)).^2);
    gaussianProfile = gaussianProfile ./ max(gaussianProfile);
    gaussianTails = (gaussianProfile <= 0.01);
    profileInTails = gaussianTails .* profile;
    backgroundUnderPeak = gaussFit.d * gaussFit.b + gaussFit.e;
    peakHeightAboveBackground = gaussFit.a;
    
    % Either enough of a match, or little gain from extra blurring
    improvementRate = (rsquare(end) - rsquare(end - 1)) / 4;
    if (rsquare(end) >= 0.99 || improvementRate < 0.002 || any(profileInTails > backgroundUnderPeak + 0.5 * peakHeightAboveBackground))
        
        if (improvementRate < 0) % Worsened?...
            blurSize = prevBlurSize;
            peakSigma = prevPeakSigma;
            
            blurKernel = Normalized2dGaussian(blurSize);
            blurredImage = conv2(image .* mask, blurKernel, 'same');
            blurredMask = conv2(mask, blurKernel, 'same');
            
            % Exclude pixels for which most of the contribution is masked
            blurredImage(blurredMask < 0.5) = 0;
        end
        
        display(improvementRate);
        display(sprintf('Selected Blur Size: %d', blurSize));
        display(sprintf('Determined Peak Sigma: %g', peakSigma));
        
        if (0)
            figure(2); plot(r, profile);
            hold on; plot(r, feval(gaussFit, r), '-k'); hold off;
            ginput(1);
        end
        
        break;
    end
    
    prevBlurSize = blurSize;
    prevPeakSigma = peakSigma;
end

if (0) % for debug
    ginput(1);
    figure(2); plot(blurSequence, rsquare);
    ginput(1);
    figure(2); plot(blurSequence, [0 diff(rsquare)]);
end

%%
1;

function [peakMask] = FindRelevantMaskByIntensityContinuity(image, mask, x, y, peakSigma)
% Take a portion of the image that contains the full peak width
e = ceil(peakSigma * 5);
imageSlice = CropImageAround(image, floor(x), floor(y), e);
maskSlice = CropImageAround(mask, floor(x), floor(y), e);

% Find value and position of maximal intensity nearby
[peakIntensityEst, peakRow] = max(imageSlice);
[peakIntensityEst, peakCol] = max(peakIntensityEst);
peakRow = peakRow(peakCol) + floor(y) - e - 1;
peakCol = peakCol + floor(x) - e - 1;

if (0)
    figure(2); imagesc(imageSlice);
end

% Estimate local background intensity by the 5th percentile of the current
% neighborhood intensity
sortedIntensities = sort(imageSlice(:));
nearbyBackgroundIntensity = sortedIntensities(ceil(0.05 * numel(sortedIntensities)))

% Include 0.5 to 1.5 the local peak intensity, adjusting for estimated background
minUsedIntensity = (peakIntensityEst - nearbyBackgroundIntensity) * 0.5 + nearbyBackgroundIntensity;
maxUsedIntensity = (peakIntensityEst - nearbyBackgroundIntensity) * 1.5 + nearbyBackgroundIntensity;

% Create a mask image, seed it with the local maximal intensity and the
% selected (clicked) point
lastUsedMask = zeros(size(image));
peakMask = zeros(size(image));
peakMask(peakRow, peakCol) = 1;
peakMask(floor(y), floor(x)) = 1;
k = 5;

relevantMask = double(image >= minUsedIntensity & image <= maxUsedIntensity);

% Debug plot
if (0), figure(2); imagesc(peakMask + relevantMask); end

directions = [...
    1 -1 0  0;...
    0  0 1 -1];

% Grow a relevant area with the "relevantMask" as a constraint
numOfDilationIterations = 0;
while (any(peakMask(:) ~= lastUsedMask(:)))
    numOfDilationIterations = numOfDilationIterations + 1;
    
    lastUsedMask = peakMask;
    
    % TODO: Try to revise this expansion code into something faster
    if (1) % Select the method of selection expansion
        minRow = max(find(sum(peakMask, 2), 1, 'first') - k, 1);
        maxRow = min(find(sum(peakMask, 2), 1, 'last') + k, size(peakMask, 1));
        
        minCol = max(find(sum(peakMask, 1), 1, 'first') - k, 1);
        maxCol = min(find(sum(peakMask, 1), 1, 'last') + k, size(peakMask, 2));
        
        modifiedMask = imdilate(peakMask(minRow:maxRow, minCol:maxCol), ones(k)) .* relevantMask(minRow:maxRow, minCol:maxCol);
        
        % TODO: Remove this?
        if (0)
            changed = modifiedMask - usedMask(minRow:maxRow, minCol:maxCol);
            available = relevantMask - usedMask;
            usedMask(minRow:maxRow, minCol:maxCol) = modifiedMask;
            
            [changedRows, changedCols] = find(changed);
            changedRows = changedRows + minRow - 1;
            changedCols = changedCols + minCol - 1;
            
            for i = unique(randi([1, numel(changedRows)], 1, 7))
                r = changedRows(i);
                c = changedCols(i);
                
                optionalDirections = available(sub2ind(r + directions(1, :), c + directions(2, :)));
                optionalDirections = find(optionalDirections);
                if (~isempty(optionalDirections))
                    dir = optionalDirections(randi(numel(optionalDirections), 1));
                end
                
            end
        else
            peakMask(minRow:maxRow, minCol:maxCol) = modifiedMask;
        end
        
    else
        usedMask = imdilate(usedMask, ones(k)) .* relevantMask;
    end
    
    % Debug plot
    if (0)
        xl = xlim();
        yl = ylim();
        imagesc(peakMask + relevantMask);
        xlim(xl);
        ylim(yl);
        %ginput(1);
        pause(0.1);
    end
end

%%
1;

function [initialConic, controlPoints, profileAnglePerPoint] = GuessInitialConic(image, mask, peakMask, profileWidth)
[Ys, Xs] = find(peakMask);

if (0)
    [centerOfIntX, centerOfIntY] = CenterOfIntensity(peakMask);
    hold on; plot(centerOfIntX, centerOfIntY, 'r*', 'MarkerSize', 16); hold off;
end

bestSelectedIndices = [];
minSumOfDistances = inf;

xMaskLimits = [min(Xs) max(Xs)];
yMaskLimits = [min(Ys) max(Ys)];

% Determine a lengthscale
diagonalLength = norm([diff(xMaskLimits), diff(yMaskLimits)]);
%rmin = 100;
rmin = (diagonalLength / sqrt(2)) * pi / 5 / 2; % Treat as if this was the diagonal of a box containing the peak's circle

% Choose a set of adequately distant point (using Lennard-Jones potential)
for i = 1:100
    selectedIndices = floor(rand(1, 5) * (numel(Ys) - 1) + 1);
    selectedX = Xs(selectedIndices);
    selectedY = Ys(selectedIndices);
    
    sumOfDistances = 0;
    
    for i = 1:numel(selectedIndices)
        dists = sqrt((selectedY - selectedY(i)) .^ 2 + (selectedX - selectedX(i)) .^ 2);
        tmp = (rmin ./ dists) .^ 6; % Calculate Lennard-Jones
        pot = tmp .^ 2 - 2 * tmp;
        
        if (any(isnan(pot))) % Quality control
            continue;
        end
        
        sumOfDistances = sumOfDistances + sum(pot);
    end
    
    if (minSumOfDistances > sumOfDistances)
        minSumOfDistances = sumOfDistances;
        bestSelectedIndices = selectedIndices;
    end
end

selectedIndices = bestSelectedIndices;
selectedX = Xs(selectedIndices);
selectedY = Ys(selectedIndices);

controlPoints = [selectedX(:), selectedY(:)];

initialConic = ConicClass();
initialConic.SetSolutionOf5Points(selectedX, selectedY);

% Optimize the selected points to be in the center of their local profile
if (0)
    figure(2); imagesc(peakMask + relevantMask);
end

e = profileWidth;
profileAnglePerPoint = zeros(size(selectedIndices));
for pointIndex = 1:numel(selectedIndices)
    x = selectedX(pointIndex);
    y = selectedY(pointIndex);
    imageSlice = CropImageAround(image, floor(x), floor(y), e);
    maskSlice = CropImageAround(mask, floor(x), floor(y), e);
    
    % Find an angle for the profile. Choose the direction in which the
    % intensity diminishes the most.
    angles = linspace(0, 2 * pi - 1e-5, 100);
    % TODO: Account for the mask
    b = 1:e;
    ImageSliceValues = @(a, r)interp2(imageSlice, r * cos(a) + e, r * sin(a) + e) ./ interp2(maskSlice, r * cos(a) + e, r * sin(a) + e) + 1e-5;
    %AngleScore = @(a)sum(ImageSliceValues(a, b(floor(numel(b)/2 + 1):end))) / sum(ImageSliceValues(a, b(1:ceil(numel(b)/2))));
    AngleScore = @(a)sum(ImageSliceValues(a, b(floor(numel(b)/2 + 1):end)));
    
    values = arrayfun(AngleScore, angles);
    %     values = arrayfun(@(a)sum(interp2(imageSlice, b * cos(a) + e, b * sin(a) + e) ./ ...
    %         (interp2(maskSlice, b * cos(a) + e, b * sin(a) + e) + 1e-5)), angles);
    [~, angleIndex] = min(values);
    profileAnglePerPoint(pointIndex) = angles(angleIndex);
    
    if (1)
        %[x, y]
        a = profileAnglePerPoint(pointIndex);
        
        hold on;
        plot(b * cos(a) + x + 1, b * sin(a) + y + 1, '*r', 'MarkerSize', 4);
        hold off;
        
        %xlim('auto');
        %ylim('auto');
        %[tmpY, tmpX] = find(peakMask);
        %xlim([min(tmpX), max(tmpX)]);
        %ylim([min(tmpY), max(tmpY)]);
    end
end

function [mask] = GetMask(hObject, data)
mask = data.ImageMask;

% Generate an automatic mask
if (isempty(mask))
    image = data.Image;
    mask = double(~isnan(image) & (image >= 0));
end
image(~mask) = 0;


%%
1;

function markPeak1Pts_Callback_1(hObject, eventdata, handles)

tStarted = tic();

data = handles.CalibrationDialogData;
cal = handles.CalibrationData;

q = 0.1075; % AgB first peak
twoK = (4 * pi) / cal.Lambda;
twoTheta = 2 * asin(q / twoK);

%% Select a point near the peak
[x, y, ok] = SelectValidPoint(hObject);

% Get given image & mask
image = data.Image;
mask = data.ImageMask;

% Reduce size of large image
if (size(image, 1) > 1000 || size(image, 2) > 1000)
    image = conv2(image, ones(2) .* 0.25, 'same');
    image = image(1:2:end, 1:2:end);
    mask = conv2(mask, ones(2) .* 0.25, 'same');
    mask = mask(1:2:end, 1:2:end);
    
    x = x / 2;
    y = y / 2;
end

if (~isempty(mask) && any(size(mask) < size(image)))
    error('Bad mask! Not empty, and doesn''t fit the image size');
end

% Generate an automatic mask
if (isempty(mask))
    mask = double(~isnan(image) & (image >= 0));
end
image(~mask) = 0;

%save('state01'); %  debug debug debug

%% Mildly adjust position towards higher intensity
%load('state01'); %  debug debug debug

display('Adjusting position.');
[x, y] = AdjustPositionTowardsCenterOfIntensity(image, x, y, 3, 5);

% Find the max intensity in the clicked area
e = 15;

if (0) % for debug: show the image
    imageSlice = image([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);
    figure(2); imagesc(imageSlice);
end

%save('state02'); %  debug debug debug

%% Determine angle for profile testing
%load('state02'); %  debug debug debug

display('Determining profile angle...');
[profileAngle, scorePerAngle] = DetermineAngleForProfile(image, mask, x, y, 7, 10, 100);

if (0) % For debug
    hold on;
    plot([1:10] .* cos(profileAngle) + x, [1:10] .* sin(profileAngle) + y, 'or');
    hold off;
end

tElapsed = toc(tStarted);
display(sprintf('Took %0.3f seconds to execute until stage 4.', tElapsed));

%save('state03'); %  debug debug debug
%% Determine appropriate blur and width of peak
%load('state03'); %  debug debug debug

display('Determining Appropriate blurring...');

blurSizesToTry = 3:4:31; %[3 7 11 17 23 31]
[blurSize, blurKernel, peakSigma, blurredImage, blurredMask] = DetermineProperBlurring(image, mask, x, y, profileAngle, 15, blurSizesToTry);
smootherI = blurredImage;
smootherMask = blurredMask;

tElapsed = toc(tStarted);
display(sprintf('Took %0.3f seconds to execute until stage 5.', tElapsed));

%save('state04'); %  debug debug debug
%% Seed a selection and expand it to include similar intensity to the peak
%load('state04'); %  debug debug debug

[peakMask] = FindRelevantMaskByIntensityContinuity(smootherI, smootherMask, x, y, peakSigma);

tElapsed = toc(tStarted);
display(sprintf('Took %0.3f seconds to execute until stage 6.', tElapsed));

%save('state05'); %  debug debug debug
%% Select an initial guess for a conic
%load('state05'); %  debug debug debug

% TODO: A 2d-spline that passes through x,y.
% Construct a 2d-spline by using 2 splines on the given x,y and 2
% additional random control points to be moved by the fitting
% * Move the additional control points until the gradient is
% minimized
% * Fragment the segments and re-minimize until adequately on zero
% gradient.


if (1) % Experimental
    a = rand(1, 2) * 2 * pi();
    r = 10;
    
    x1 = r * cos(a(1)) + x;
    y1 = r * sin(a(1)) + y;
    x2 = r * cos(a(2)) + x;
    y2 = r * sin(a(2)) + y;
    
    ppX = spline([-1 0 1], [x1 x x2]);
    ppY = spline([-1 0 1], [y1 y y2]);
    %ppval(ppX, t)
    
    t = -1:0.1:1;
    xx = ppval(ppX, t);
    yy = ppval(ppY, t);
    hold on;
    plot(xx, yy, '*r');
    hold off;
    
    return;
end

if (1)
    imagesc(log(smootherI + 1))
end

[initialConic, controlPoints, profileAnglePerPoint] = GuessInitialConic(...
    smootherI, smootherMask, peakMask, 3 * peakSigma);
selectedX = controlPoints(:, 1);
selectedY = controlPoints(:, 2);

tElapsed = toc(tStarted);
display(sprintf('Took %0.3f seconds to execute until stage 7.', tElapsed));

save('state06'); %  debug debug debug
%% Adjust selected points to be on the center of the peak profile
load('state06'); %  debug debug debug

if (1)
    r = [-e:0.5:e];
    %figure(2); imagesc(peakMask + relevantMask);
    figure(2); imagesc(peakMask);
    [tmpY, tmpX] = find(peakMask);
    xlim([min(tmpX), max(tmpX)] .* [0.95 1.05]);
    ylim([min(tmpY), max(tmpY)] .* [0.95 1.05]);
    
    ginput(1);
    %imagesc(log(image + 1));
    imagesc(log(smootherI + 1));
    xlim([min(tmpX), max(tmpX)] .* [0.95 1.05]);
    ylim([min(tmpY), max(tmpY)] .* [0.95 1.05]);
    
    hold on;
    for pointIndex = 1:numel(selectedX)
        x = selectedX(pointIndex);
        y = selectedY(pointIndex);
        a = profileAnglePerPoint(pointIndex);
        %plot([1:7] * cos(a) + x + 1, [1:7] * sin(a) + y + 1, '*r', 'MarkerSize', 4);
        plot(r * cos(a) + x, r * sin(a) + y, '*r', 'MarkerSize', 4);
        
        
        % TODO: A 2d-spline that passes through x,y.
        % Construct a 2d-spline by using 2 splines on the given x,y and 2
        % additional random control points to be moved by the fitting
        % * Move the additional control points until the gradient is
        % minimized
        % * Fragment the segments and re-minimize until adequately on zero
        % gradient.
        
    end
    hold off;
end

restoreScaleFactor = 1;
if (1) % [DEBUG] Plot initial conic
    conic = ConicClass();
    conic.SetSolutionOf5Points(selectedX * restoreScaleFactor, selectedY * restoreScaleFactor);
    
    figure(2);
    hold on;
    xl = xlim();
    yl = ylim();
    plot(selectedX * restoreScaleFactor, selectedY * restoreScaleFactor, '*g', 'MarkerSize', 16);
    conic.DebugPlotInRect([1, 1, size(data.Image, 2), size(data.Image, 1)], 'Black');
    xlim(xl);
    ylim(yl);
    hold off;
end

% Adjust the selected point to be on the peak of the gaussian profile next
% to it
e = 15;
for pointIndex = 1:numel(selectedX)
    x = selectedX(pointIndex);
    y = selectedY(pointIndex);
    
    % Take a local slice of the image & mask
    imageSlice = smootherI([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);
    maskSlice = smootherMask([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);
    r = [-e:0.5:e];
    a = profileAnglePerPoint(pointIndex);
    
    ImageSliceValues = @(a, r)interp2(imageSlice, r * cos(a) + e, r * sin(a) + e) ./ (interp2(maskSlice, r * cos(a) + e, r * sin(a) + e) + 1e-5);
    profile = ImageSliceValues(a, r);
    r(isnan(profile)) = [];
    profile(isnan(profile)) = [];
    
    if (1) % [DEBUG] Plot the profile being fitted, and the fit
        figure(3);
        plot(r, profile);
        
        %         figure(2);
        %         hold on;
        %         plot(x * restoreScaleFactor, y * restoreScaleFactor, 'og', 'MarkerSize', 10);
        %         hold off;
        %         ginput(1); % Pause before continuing
    end
    
    % Fit to a gaussian
    [gaussFit, gof, relativeCoeffErr] = GaussianSimpleFit(r, profile);
    
    if (1) % [DEBUG] Plot the profile being fitted, and the fit
        figure(3);
        hold on; plot(r, feval(gaussFit, r), '-k'); hold off;
    end
    
    if (1) % [DEBUG] Display the fit result & goodness
        gaussFit
        gof
    end
    
    % Check if the gaussian is good enough to use, and adjust
    if (gof.adjrsquare > 0.95 && all(relativeCoeffErr(1:3) < 0.2))
        shift = gaussFit.b; % Get center (it's relative to the selected point)
        adjustedX = selectedX(pointIndex) + shift * cos(a);
        adjustedY = selectedY(pointIndex) + shift * sin(a);
        
        if (1) % [DEBUG] Add the adjusted dot
            figure(2);
            %ginput(1); % Pause before adding the spot
            hold on;
            plot(adjustedX * restoreScaleFactor, adjustedY * restoreScaleFactor, '*y', 'MarkerSize', 16);
            hold off;
        end
        
        selectedX(pointIndex) = adjustedX;
        selectedY(pointIndex) = adjustedY;
    else
        display('Not good enough');
        display(gof.adjrsquare);
    end
    
    figure(2);
    ginput(1); % Pause before continuing
    
end

if (1) % Plot final conic
    conic = ConicClass();
    conic.SetSolutionOf5Points(selectedX * restoreScaleFactor, selectedY * restoreScaleFactor);
    
    figure(2);
    % imagesc(log(image + 1));
    hold on;
    xl = xlim();
    yl = ylim();
    plot(selectedX * restoreScaleFactor, selectedY * restoreScaleFactor, '*y', 'MarkerSize', 16);
    conic.DebugPlotInRect([1, 1, size(data.Image, 2), size(data.Image, 1)], 'Red');
    xlim(xl);
    ylim(yl);
    hold off;
end

%save('state07'); %  debug debug debug
%% Optimize conic by 5 point (10 parameters), with max-intensity as score
% Use a gaussian peak profile and sum on it. This allows to "pick up the
% scent" of the nearby peak conic so there would be a smooth gradient
% towards it.
%load('state07'); %  debug debug debug

% Actually the peak's width in momenta space should be used, but we don't assume we can know it.
peakWidth = 3 * peakSigma;

options = FitConicToNearbyPeak();
[controlX, controlY] = FitConicToNearbyPeak(options, smootherI, smootherMask, selectedX, selectedY);
%[controlX, controlY] = FitConicToNearbyPeak(options, smootherI, smootherMask, controlX, controlY);
return;


if (0)
    x = [1:2:7];
    y = [2:2:8];
    reshape([x;y], 1, 8)
end

initialCoordinates = reshape([selectedCols(:)'; selectedRows(:)'], 2 * numel(selectedCols), 1);

% mininum-finding options
options = optimset('fminbnd');
options.Algorithm = 'interior-point';
options.Display = 'testing'; % off, notify, final, iter, testing
options.Diagnostics = 'on';
options.MaxTime = 20;
options.MaxIter = 500;
options.AlwaysHonorConstraints = 'on';
options.MaxFunEvals = 1e3;
options.TolX = 1e-5;
options.TolFun = 1e-4;

%options.DiffMinChange = [1e-3, 1, 1e-2, 1e-2, 1e-3];
%options.DiffMaxChange = [0.3, 5e3, 5, 5, 0.3];
options.DiffMinChange = 1e-7;
options.DiffMaxChange = 3;

options.FinDiffType = 'central';
options.FinDiffRelStep = 1e-8;

% Two methods to fine the minimum. Usually work if we're very close to the
% desired configuration.
if (1)
    [bestCoordinates, bestValue,exitflag,output] = fminsearch(...
        @(coordinates)MinimizedControlPointsScoreFunction(smootherI, smootherMask, coordinates), ...
        initialCoordinates);
else
    [bestCoordinates,bestValue,exitflag,output] = fmincon(...
        @(coordinates)MinimizedControlPointsScoreFunction(smootherI, smootherMask, coordinates), ...
        initialCoordinates,...
        [],[],[],[],...
        initialCoordinates - 20,...
        initialCoordinates + 20,...
        @ValidConexConicFromPointsNonlinearConstraint, options);
end

DebugPlotImageWithConic(image, bestCoordinates);

%Redraw(hObject);
1;

function [x, y] = GetPointsWithinImage(handles, x, y)
data = handles.CalibrationDialogData;
which = (x >= 0.5) & (x <= (0.5 + size(data.Image, 2)));
which = which & (y >= 0.5) & (y <= (0.5 + size(data.Image, 1)));
x = x(which);
y = y(which);
1;

function [twoTheta] = GetTwoTheta(hObject, handles, qValue)
if(isempty(handles))
    handles = guidata(hObject);
end

cal = handles.CalibrationData;
twoK = (4 * pi) / cal.Lambda;
twoTheta = 2 * asin(qValue / twoK);

function [] = PlotQ(hObject, qValue, color)
handles = guidata(hObject);
data = handles.CalibrationDialogData;
cal = handles.CalibrationData;

if (nargin < 3)
    color = 'red';
end

twoTheta = GetTwoTheta(hObject, handles, qValue);

conic = ConicClass();
conic.SetConexParameters(cal.AlphaRadians, cal.SampleToDetDist / cal.PixelSize, cal.BeamCenterX, cal.BeamCenterY, cal.BetaRadians, twoTheta);

conic.DebugPlotInRect([1, 1, size(data.Image, 2), size(data.Image, 1)], color);
1;

function markPeak1Pts_Callback(hObject, eventdata, handles)

tStarted = tic();

data = handles.CalibrationDialogData;
cal = handles.CalibrationData;

peaksList = get(handles.SelectPeakDropdown, 'UserData');
selectedPeakIndex = get(handles.SelectPeakDropdown, 'Value');
q = peaksList(selectedPeakIndex);
%q = 0.1077; % AgB first peak

twoTheta = GetTwoTheta(hObject, handles, q);

%% Select a point near the peak
[clickedX, clickedY, ok] = SelectValidPoint(hObject);

if (~ok)
    return;
end

% Get given image & mask
image = data.Image;
mask = data.ImageMask;

% Reduce size of large image
if (0 && (size(image, 1) > 1000 || size(image, 2) > 1000))
    image = conv2(image, ones(2) .* 0.25, 'same');
    image = image(1:2:end, 1:2:end);
    mask = conv2(mask, ones(2) .* 0.25, 'same');
    mask = mask(1:2:end, 1:2:end);
    
    clickedX = clickedX / 2;
    clickedY = clickedY / 2;
end

if (~isempty(mask) && any(size(mask) < size(image)))
    error('Bad mask! Not empty, and doesn''t fit the image size');
end

% Generate an automatic mask
if (isempty(mask))
    mask = double(~isnan(image) & (image >= 0));
end
image(~mask) = 0;


options = SingleClickCalibrationProcedure();
options.ShouldPlot = 1;
options.ShouldAnimate = 1 & data.ShouldAnimate;

calibration = SingleClickCalibrationProcedure(image, mask, [clickedX clickedY], twoTheta, options);

if (~isempty(calibration))
    cal.AlphaRadians = calibration.Alpha;
    cal.BetaRadians = calibration.Beta;
    cal.BeamCenterX = calibration.BeamX;
    cal.BeamCenterY = calibration.BeamY;
    cal.SampleToDetDist = calibration.SampleToDetector * cal.PixelSize;
    
    UpdateCalibrationDisplay(hObject);
    Redraw(hObject);
end
1;





% Try fitting in a growing area in the final stage
function markPeak1Pts_Callback_20130707(hObject, eventdata, handles)

tStarted = tic();

data = handles.CalibrationDialogData;
cal = handles.CalibrationData;

peaksList = get(handles.SelectPeakDropdown, 'UserData');
selectedPeakIndex = get(handles.SelectPeakDropdown, 'Value');
q = peaksList(selectedPeakIndex);
%q = 0.1077; % AgB first peak

twoTheta = GetTwoTheta(hObject, handles, q);

%% Select a point near the peak
[clickedX, clickedY, ok] = SelectValidPoint(hObject);

% Get given image & mask
image = data.Image;
mask = data.ImageMask;

% Reduce size of large image
if (size(image, 1) > 1000 || size(image, 2) > 1000)
    image = conv2(image, ones(2) .* 0.25, 'same');
    image = image(1:2:end, 1:2:end);
    mask = conv2(mask, ones(2) .* 0.25, 'same');
    mask = mask(1:2:end, 1:2:end);
    
    clickedX = clickedX / 2;
    clickedY = clickedY / 2;
end

if (~isempty(mask) && any(size(mask) < size(image)))
    error('Bad mask! Not empty, and doesn''t fit the image size');
end

% Generate an automatic mask
if (isempty(mask))
    mask = double(~isnan(image) & (image >= 0));
end
image(~mask) = 0;

%save('state01'); %  debug debug debug

%% Mildly adjust position towards higher intensity
%load('state01'); %  debug debug debug

display('Adjusting position.');
[clickedX, clickedY] = AdjustPositionTowardsCenterOfIntensity(image, clickedX, clickedY, 3, 5);
data.ClickedXY = [clickedX, clickedY];

% Find the max intensity in the clicked area
e = 15;

if (0) % for debug: show the image
    x = clickedX;
    y = clickedY;
    imageSlice = image([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);
    figure(2); imagesc(imageSlice);
end

%save('state02'); %  debug debug debug

%% Determine angle for profile testing
%load('state02'); %  debug debug debug

display('Determining profile angle...');
[profileAngle, scorePerAngle] = DetermineAngleForProfile(image, mask, clickedX, clickedY, 7, 10, 100);

if (1) % For debug
    hold on;
    plot([1:10] .* cos(profileAngle) + clickedX, [1:10] .* sin(profileAngle) + clickedY, 'or');
    hold off;
end

tElapsed = toc(tStarted);
display(sprintf('Took %0.3f seconds to execute until stage 4.', tElapsed));

%save('state03'); %  debug debug debug
%% Determine appropriate blur and width of peak
%load('state03'); %  debug debug debug

display('Determining Appropriate blurring...');

blurSizesToTry = 3:4:31; %[3 7 11 17 23 31]
[blurSize, blurKernel, peakSigma, blurredImage, blurredMask] = DetermineProperBlurring(image, mask, clickedX, clickedY, profileAngle, 15, blurSizesToTry);
smootherI = blurredImage;
smootherMask = blurredMask;

tElapsed = toc(tStarted);
display(sprintf('Took %0.3f seconds to execute until stage 5.', tElapsed));

data.ClickedProfileSigma = peakSigma;
data.ClickedProfileAngle = profileAngle;
data.SmoothedImage = smootherI;
data.SmoothedMask = smootherMask;

%save('state04'); %  debug debug debug

if (0)
    
    %% Seed a selection and expand it to include similar intensity to the peak
    %load('state04'); %  debug debug debug
    
    [peakMask] = FindRelevantMaskByIntensityContinuity(smootherI, smootherMask, clickedX, clickedY, peakSigma);
    
    tElapsed = toc(tStarted);
    display(sprintf('Took %0.3f seconds to execute until stage 6.', tElapsed));
    
    %save('state05'); %  debug debug debug
    %% Select an initial guess for a conic
    %load('state05'); %  debug debug debug
    
    % TODO: A 2d-spline that passes through x,y.
    % Construct a 2d-spline by using 2 splines on the given x,y and 2
    % additional random control points to be moved by the fitting
    % * Move the additional control points until the gradient is
    % minimized
    % * Fragment the segments and re-minimize until adequately on zero
    % gradient.
    
    if (1)
        imagesc(log(smootherI + 1))
    end
    
    [initialConic, controlPoints, profileAnglePerPoint] = GuessInitialConic(...
        smootherI, smootherMask, peakMask, 3 * peakSigma);
    selectedX = controlPoints(:, 1);
    selectedY = controlPoints(:, 2);
    
    tElapsed = toc(tStarted);
    display(sprintf('Took %0.3f seconds to execute until stage 7.', tElapsed));
    
    %save('state06'); %  debug debug debug
    %% Adjust selected points to be on the center of the peak profile
    %load('state06'); %  debug debug debug
    
    if (1)
        r = [-e:0.5:e];
        %figure(2); imagesc(peakMask + relevantMask);
        figure(2); imagesc(peakMask);
        [tmpY, tmpX] = find(peakMask);
        xlim([min(tmpX), max(tmpX)] .* [0.95 1.05]);
        ylim([min(tmpY), max(tmpY)] .* [0.95 1.05]);
        
        ginput(1);
        %imagesc(log(image + 1));
        imagesc(log(smootherI + 1));
        xlim([min(tmpX), max(tmpX)] .* [0.95 1.05]);
        ylim([min(tmpY), max(tmpY)] .* [0.95 1.05]);
        
        hold on;
        for pointIndex = 1:numel(selectedX)
            x = selectedX(pointIndex);
            y = selectedY(pointIndex);
            a = profileAnglePerPoint(pointIndex);
            %plot([1:7] * cos(a) + x + 1, [1:7] * sin(a) + y + 1, '*r', 'MarkerSize', 4);
            plot(r * cos(a) + x, r * sin(a) + y, '*r', 'MarkerSize', 4);
            
        end
        hold off;
    end
    
    restoreScaleFactor = 1;
    if (1) % [DEBUG] Plot initial conic
        conic = ConicClass();
        conic.SetSolutionOf5Points(selectedX * restoreScaleFactor, selectedY * restoreScaleFactor);
        
        figure(2);
        hold on;
        xl = xlim();
        yl = ylim();
        plot(selectedX * restoreScaleFactor, selectedY * restoreScaleFactor, '*g', 'MarkerSize', 16);
        conic.DebugPlotInRect([1, 1, size(data.Image, 2), size(data.Image, 1)], 'Black');
        xlim(xl);
        ylim(yl);
        hold off;
    end
    
    % Adjust the selected point to be on the peak of the gaussian profile next
    % to it
    e = 15;
    for pointIndex = 1:numel(selectedX)
        x = selectedX(pointIndex);
        y = selectedY(pointIndex);
        
        % Take a local slice of the image & mask
        imageSlice = smootherI([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);
        maskSlice = smootherMask([floor(y)-e:floor(y)+e], [floor(x)-e:floor(x)+e]);
        r = [-e:0.5:e];
        a = profileAnglePerPoint(pointIndex);
        
        ImageSliceValues = @(a, r)interp2(imageSlice, r * cos(a) + e, r * sin(a) + e) ./ (interp2(maskSlice, r * cos(a) + e, r * sin(a) + e) + 1e-5);
        profile = ImageSliceValues(a, r);
        r(isnan(profile)) = [];
        profile(isnan(profile)) = [];
        
        if (0) % [DEBUG] Plot the profile being fitted, and the fit
            figure(3);
            plot(r, profile);
            
            %         figure(2);
            %         hold on;
            %         plot(x * restoreScaleFactor, y * restoreScaleFactor, 'og', 'MarkerSize', 10);
            %         hold off;
            %         ginput(1); % Pause before continuing
        end
        
        % Fit to a gaussian
        [gaussFit, gof, relativeCoeffErr] = GaussianSimpleFit(r, profile);
        
        if (0) % [DEBUG] Plot the profile being fitted, and the fit
            figure(3);
            hold on; plot(r, feval(gaussFit, r), '-k'); hold off;
        end
        
        if (0) % [DEBUG] Display the fit result & goodness
            gaussFit
            gof
        end
        
        % Check if the gaussian is good enough to use, and adjust
        if (gof.adjrsquare > 0.95 && all(relativeCoeffErr(1:3) < 0.2))
            shift = gaussFit.b; % Get center (it's relative to the selected point)
            adjustedX = selectedX(pointIndex) + shift * cos(a);
            adjustedY = selectedY(pointIndex) + shift * sin(a);
            
            if (0) % [DEBUG] Add the adjusted dot
                figure(2);
                %ginput(1); % Pause before adding the spot
                hold on;
                plot(adjustedX * restoreScaleFactor, adjustedY * restoreScaleFactor, '*y', 'MarkerSize', 16);
                hold off;
            end
            
            selectedX(pointIndex) = adjustedX;
            selectedY(pointIndex) = adjustedY;
        else
            display('Not good enough');
            display(gof.adjrsquare);
        end
        
        if (0)
            figure(2);
            ginput(1); % Pause before continuing
        end
    end
    
    if (0) % Plot final conic
        conic = ConicClass();
        conic.SetSolutionOf5Points(selectedX * restoreScaleFactor, selectedY * restoreScaleFactor);
        
        figure(2);
        % imagesc(log(image + 1));
        hold on;
        xl = xlim();
        yl = ylim();
        plot(selectedX * restoreScaleFactor, selectedY * restoreScaleFactor, '*y', 'MarkerSize', 16);
        conic.DebugPlotInRect([1, 1, size(data.Image, 2), size(data.Image, 1)], 'Red');
        xlim(xl);
        ylim(yl);
        hold off;
    end
    
end

%% Generate initial calibration values by assuming the given center and fitting just the sample-det distance
options = CalibrationFromPoints();
options.ShouldFitWithoutTiltFirst = 1;
options.ShouldFitTilt = 0;
options.DoNotChangeBeamCenter = 1;
options.InitialBeamCenterX = cal.BeamCenterX;
options.InitialBeamCenterY = cal.BeamCenterY;
calibration = CalibrationFromPoints(clickedX, clickedY, twoTheta, options);

cal.AlphaRadians = calibration.Alpha;
cal.BetaRadians = calibration.Beta;
cal.BeamCenterX = calibration.BeamX;
cal.BeamCenterY = calibration.BeamY;
cal.SampleToDetDist = calibration.SampleToDetector * cal.PixelSize;

UpdateCalibrationDisplay(hObject);

1;

data.DrawQ = [q];
data.DrawQColor = { 'red' };

handles.CalibrationDialogData.CalibrationStep = 'ConstructInitialConic';

SetPanel(hObject, handles, handles.FitStepsPanel);
Redraw(hObject);

return;
1;

%save('state07'); %  debug debug debug
%% Optimize conic by 5 point (10 parameters), with max-intensity as score
% Use a gaussian peak profile and sum on it. This allows to "pick up the
% scent" of the nearby peak conic so there would be a smooth gradient
% towards it.
load('state07'); %  debug debug debug

options = ReconstructPeakShortSimpleSteps();
[curve] = ReconstructPeakShortSimpleSteps(smootherI, smootherMask, clickedX, clickedY, profileAngle, peakSigma, options);

t = linspace(0, 2 * pi, 5 + 1);
t(end) = [];
[controlX, controlY] = curve.Conic.GetPointsFromParametricForm(t);

% Actually the peak's width in momenta space should be used, but we don't assume we can know it.
peakWidth = 3 * peakSigma;

%options = FitConicToNearbyPeak();
%[controlX, controlY] = FitConicToNearbyPeak(options, smootherI, smootherMask, controlX, controlY);

options = FitConicToNearbyPeak2d();
[controlX, controlY] = FitConicToNearbyPeak2d(options, image, mask, controlX, controlY);

lambda = 1.543;
twoK = 4 * pi / lambda;
twoTheta = 2 * asin(q / twoK);
optimizedConic = ConicClass();
optimizedConic.SetSolutionOf5Points(controlX, controlY);
optimizedCalibration = CalibrationFromConic(optimizedConic, twoTheta);

calData = handles.CalibrationData;
calData.AlphaRadians = optimizedCalibration.Alpha;
calData.BetaRadians = optimizedCalibration.Beta;
calData.BeamCenterX = optimizedCalibration.BeamX;
calData.BeamCenterY = optimizedCalibration.BeamY;
calData.SampleToDetDist = optimizedCalibration.SampleToDetector;

%optimizedCalibration.FinalConic.DebugPlotInRect([1, 1, size(smootherI, 2), size(smootherI, 1)], 'Red');

% TODO: Find out why the result s2d is half what it's suppose to be (using
% 2-theta instead of theta somewhere)

%Redraw(hObject);
UpdateCalibrationDisplay(hObject);
%FineFitPanelMenuItem_Callback(hObject, [], handles);
1;

function UpdateCalibrationDisplay(hObject)
handles = guidata(hObject);

calData = handles.CalibrationData;

set(handles.AlphaEditBox, 'String', num2str(calData.AlphaDegrees));
set(handles.BetaEditBox, 'String', num2str(calData.BetaDegrees));
set(handles.BeamCenterXEditBox, 'String', num2str(calData.BeamCenterX));
set(handles.BeamCenterYEditBox, 'String', num2str(calData.BeamCenterY));
set(handles.SampleToDetectorEditBox, 'String', num2str(calData.SampleToDetDist));
set(handles.PixelSizeEditBox, 'String', num2str(calData.PixelSize));
set(handles.WavelengthEditBox, 'String', num2str(calData.Lambda));

1;

% --------------------------------------------------------------------
function SelectCenterMenuItem_Callback(hObject, eventdata, handles)
axes(handles.Axes_h);
cal = handles.CalibrationData;

[x, y, ok] = SelectValidPoint(hObject);
if (ok)
    cal.BeamCenterX = x;
    cal.BeamCenterY = y;
end

UpdateCalibrationDisplay(hObject);
Redraw(hObject);


% --------------------------------------------------------------------
function displayIntensityMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to displayIntensityMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.DisplayType = 1;
Redraw(hObject);


% --------------------------------------------------------------------
function displayGradientMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to displayGradientMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function displayLaplacianMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to displayLaplacianMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.DisplayType = 5;
Redraw(hObject);


function SetCheckMark(handle, value)
if (value);
    set(handle, 'checked', 'on');
else
    set(handle, 'checked', 'off');
end


% --------------------------------------------------------------------
function showColorbar_Callback(hObject, eventdata, handles)
% hObject    handle to showColorbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.ShowColorbar = ~data.ShowColorbar; % The ">0" thing is just in case...
Redraw(hObject);

% --------------------------------------------------------------------
function displayXGradientMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to displayXGradientMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.DisplayType = 2;
Redraw(hObject);

% --------------------------------------------------------------------
function displayYGradientMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to displayYGradientMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.DisplayType = 3;
Redraw(hObject);

% --------------------------------------------------------------------
function displayXYGradientMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to displayXYGradientMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.DisplayType = 4;
Redraw(hObject);

% --------------------------------------------------------------------
function colormapMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to colormapMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function grayColormapMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to grayColormapMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.Colormap = colormap('gray');
Redraw(hObject);

% --------------------------------------------------------------------
function jetColormapMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to jetColormapMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.Colormap = colormap('jet');
Redraw(hObject);


% --------------------------------------------------------------------
function copperColormapMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to copperColormapMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.Colormap = colormap('copper');
Redraw(hObject);


% --------------------------------------------------------------------
function debugMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to debugMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function debug1MenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to debug1MenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
I = double(data.Image);
figure; semilogy(I(:, 235), '-*');


% --------------------------------------------------------------------
function debug2MenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to debug2MenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
I = double(data.Image);
figure; semilogy(I(:, 235), '-');


% --------------------------------------------------------------------
function logScaleMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to logScaleMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.DisplayLogScale = 1 - (data.DisplayLogScale > 0); % The ">0" thing is just in case...
Redraw(hObject);

% --------------------------------------------------------------------
function blurMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to blurMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function blurZeroMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to blurZeroMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.BlurSize = 0;
Redraw(hObject);

% --------------------------------------------------------------------
function blur7MenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to blur7MenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.BlurSize = 7;
Redraw(hObject);

% --------------------------------------------------------------------
function blur17MenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to blur17MenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.BlurSize = 17;
Redraw(hObject);

% --------------------------------------------------------------------
function blur31MenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to blur31MenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
data.BlurSize = 31;
Redraw(hObject);

% --------------------------------------------------------------------
function RedrawMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to RedrawMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Redraw(hObject, 1);


% --------------------------------------------------------------------
function panMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to panMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.Axes_h);
panHandle = pan(handles.figure1);

if (strcmp(panHandle.Enable, 'off'))
    panHandle.UIContextMenu = handles.ImageMenu;
    panHandle.Enable = 'on';
else
    panHandle.Enable = 'off';
end


% --- Executes on button press in FitToSelectedPeaksButton.
function FitToSelectedPeaksButton_Callback(hObject, eventdata, handles)
% hObject    handle to FitToSelectedPeaksButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function WavelengthEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to WavelengthEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cal = handles.CalibrationData;
data = handles.CalibrationDialogData;

q = GetSelectedQPeak(hObject, handles);

image = handles.CalibrationDialogData.Image;
mask = handles.CalibrationDialogData.ImageMask;
if (isempty(mask))
    mask = double(~isnan(image) & (image >= 0));
end
image(~mask) = 0;

q = 0.1075981;

A = 1;
score = CalibrationParametersScore(image, mask, q, cal.Lambda, cal.BeamCenterX, cal.BeamCenterY, ...
    cal.SampleToDetDist / cal.PixelSize, cal.AlphaRadians, cal.BetaRadians, A);

[A, score] = fminsearch(@(A)CalibrationParametersScore(image, mask, q, cal.Lambda, cal.BeamCenterX, cal.BeamCenterY, ...
    cal.SampleToDetDist / cal.PixelSize, cal.AlphaRadians, cal.BetaRadians, A), A);

1;

% --- Executes during object creation, after setting all properties.
function WavelengthEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WavelengthEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SampleToDetectorEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to SampleToDetectorEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cal = handles.CalibrationData;
UpdateCalibrationFieldFromUI(hObject, 'SampleToDetDist', @(x)str2double(x));


% --- Executes during object creation, after setting all properties.
function SampleToDetectorEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SampleToDetectorEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PixelSizeEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to PixelSizeEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.CalibrationData.UpdatePixelSize(str2double(get(hObject, 'String')));
UpdateCalibrationDisplay(hObject);
Redraw(hObject);
%UpdateCalibrationFieldFromUI(hObject, 'PixelSize', @(x)str2double(x));


% --- Executes during object creation, after setting all properties.
function PixelSizeEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PixelSizeEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BetaEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to BetaEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UpdateCalibrationFieldFromUI(hObject, 'BetaDegrees', @(x)str2double(x));


% --- Executes during object creation, after setting all properties.
function BetaEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BetaEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function UpdateCalibrationFieldFromUI(hObject, fieldName, convertValueHandler)
% UpdateIntegrationParamsFieldFromUI(hObject, fieldName, convertValueHandler)

handles = guidata(hObject);
cal = handles.CalibrationData;

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

cal.(fieldName) = value;
UpdateCalibrationDisplay(hObject);
Redraw(hObject);

function AlphaEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to AlphaEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UpdateCalibrationFieldFromUI(hObject, 'AlphaDegrees', @(x)str2double(x));


% --- Executes during object creation, after setting all properties.
function AlphaEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AlphaEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BeamCenterXEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to BeamCenterXEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UpdateCalibrationFieldFromUI(hObject, 'BeamCenterX', @(x)str2double(x));
Redraw(hObject);

% --- Executes during object creation, after setting all properties.
function BeamCenterXEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BeamCenterXEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BeamCenterYEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to BeamCenterYEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UpdateCalibrationFieldFromUI(hObject, 'BeamCenterY', @(x)str2double(x));
Redraw(hObject);

% --- Executes during object creation, after setting all properties.
function BeamCenterYEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BeamCenterYEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in OkButton.
function OkButton_Callback(hObject, eventdata, handles)
% hObject    handle to OkButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.CalibrationDialogData.WasCalibrationAccepted = 1;
uiresume(handles.figure1);

% --- Executes on button press in CancelButton.
function CancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to CancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.CalibrationDialogData.WasCalibrationAccepted = 0;
uiresume(handles.figure1);

% --- Executes on button press in UsePeakForFineFitCheckbox1.
function UsePeakForFineFitCheckbox1_Callback(hObject, eventdata, handles)
% hObject    handle to UsePeakForFineFitCheckbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of UsePeakForFineFitCheckbox1


% --- Executes on slider movement.
function WeightOfPeakForFineFitSlider1_Callback(hObject, eventdata, handles)
% hObject    handle to WeightOfPeakForFineFitSlider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function WeightOfPeakForFineFitSlider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WeightOfPeakForFineFitSlider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in SelectPeakForFineFitDropdown1.
function SelectPeakForFineFitDropdown1_Callback(hObject, eventdata, handles)
% hObject    handle to SelectPeakForFineFitDropdown1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SelectPeakForFineFitDropdown1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SelectPeakForFineFitDropdown1


% --- Executes during object creation, after setting all properties.
function SelectPeakForFineFitDropdown1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SelectPeakForFineFitDropdown1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MarkPeakCoarsely.
function MarkPeakCoarsely_Callback(hObject, eventdata, handles)
% hObject    handle to MarkPeakCoarsely (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on selection change in SelectPeakDropdown.
function SelectPeakDropdown_Callback(hObject, eventdata, handles)
% hObject    handle to SelectPeakDropdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
qPeaks = get(hObject, 'UserData');
peakIndex = get(hObject, 'Value');
selectedPeak = qPeaks(peakIndex);

data = handles.CalibrationDialogData;
data.DrawQ = [selectedPeak];
data.DrawQColor = {'red'};

Redraw(hObject);

1;

% --- Executes during object creation, after setting all properties.
function SelectPeakDropdown_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SelectPeakDropdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SelectCalibrantDropdown.
function SelectCalibrantDropdown_Callback(hObject, eventdata, handles)
% hObject    handle to SelectCalibrantDropdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
calibrants = handles.Calibrants;

calibrantIndex = get(handles.SelectCalibrantDropdown, 'Value');

qPeakStrings = arrayfun(@(i)sprintf('%01.5f', calibrants(calibrantIndex).Peaks(i)), ...
    1:numel(calibrants(calibrantIndex).Peaks), 'UniformOutput', 0);
set(handles.SelectPeakDropdown, 'String', qPeakStrings);
set(handles.SelectPeakDropdown, 'UserData', calibrants(calibrantIndex).Peaks);
1;

% --- Executes during object creation, after setting all properties.
function SelectCalibrantDropdown_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SelectCalibrantDropdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in ReturnToInitialFitButton.
function ReturnToInitialFitButton_Callback(hObject, eventdata, handles)
% hObject    handle to ReturnToInitialFitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function ShowPanel(hObject, panelHanle)
handles = guidata(hObject);
hold on;
set(handles.InitialFitPanel, 'Visible', 'off');
set(handles.FineFitPanel, 'Visible', 'off');
set(panelHanle, 'Visible', 'on');
hold off;

% --------------------------------------------------------------------
function InitialFitPanelMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to InitialFitPanelMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShowPanel(hObject, handles.InitialFitPanel);

% --------------------------------------------------------------------
function FineFitPanelMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to FineFitPanelMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShowPanel(hObject, handles.FineFitPanel);

% --------------------------------------------------------------------
function PanelsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to PanelsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton29.
function pushbutton29_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton28.
function pushbutton28_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton27.
function pushbutton27_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu12.
function popupmenu12_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu12 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu12


% --- Executes during object creation, after setting all properties.
function popupmenu12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu11.
function popupmenu11_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu11 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu11


% --- Executes during object creation, after setting all properties.
function popupmenu11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in BeamIsWithinImageCheckbox.
function BeamIsWithinImageCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to BeamIsWithinImageCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of BeamIsWithinImageCheckbox



% --- Executes on button press in pushbutton31.
function pushbutton31_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton31 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton33.
function pushbutton33_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton33 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function [panels] = GetPanels(hObject, handles)
panels = [ handles.InitialFitPanel, handles.FitStepsPanel, handles.FineFitPanel ];

function SetPanel(hObject, handles, panelIndex)
panels = GetPanels(hObject, handles);

if (panelIndex > numel(panels))
    panelIndex = find(panels == panelIndex, 1);
    if (isempty(panelIndex))
        return;
    end
end

for i = 1:numel(panels)
    set(panels(i), 'Visible', 'off');
end

set(panels(panelIndex), 'Visible', 'on');
1;

function ShiftPanel(hObject, eventdata, handles, direction)
panels = GetPanels(hObject, handles);

visiblePanels = arrayfun(@(p)strcmp(get(p, 'Visible'), 'on'), panels);
firstVisible = find(visiblePanels, 1);

SetPanel(hObject, handles, 1 + mod(firstVisible - 1 + direction, numel(panels)));
1;

% --- Executes on button press in PrevPanelButton.
function PrevPanelButton_Callback(hObject, eventdata, handles)
% hObject    handle to PrevPanelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShiftPanel(hObject, eventdata, handles, -1);

% --- Executes on button press in NextPanelButton.
function NextPanelButton_Callback(hObject, eventdata, handles)
% hObject    handle to NextPanelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ShiftPanel(hObject, eventdata, handles, 1);


% --- Executes on button press in AdjustCenterByFittingPowerLawButton.
function AdjustCenterByFittingPowerLawButton_Callback(hObject, eventdata, handles)
% hObject    handle to AdjustCenterByFittingPowerLawButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
cal = handles.CalibrationData;

peaksList = get(handles.SelectPeakDropdown, 'UserData');
q = peaksList(1); % Use the first peak to determine limits of power law

options = FitPowerLaw2d();
options.InitialBeamX = cal.BeamCenterX;
options.InitialBeamY = cal.BeamCenterY;
options.MinQ = q / 10;
options.MaxQ = q / 2;
options.Alpha = cal.AlphaRadians;
options.Beta = cal.BetaRadians;
options.SampleDetectorDist = cal.SampleToDetDist / cal.PixelSize;
options.WavelengthAngstrom = cal.Lambda;

[adjustedX, adjustedY] = FitPowerLaw2d(options, data.Image, data.ImageMask);

cal.BeamCenterX = adjustedX;
cal.BeamCenterY = adjustedY;
UpdateCalibrationDisplay(hObject);
Redraw(hObject);
display('Done adjusting');
1;

function [q] = GetSelectedQPeak(hObject, handles)
peaksList = get(handles.SelectPeakDropdown, 'UserData');
selectedPeakIndex = get(handles.SelectPeakDropdown, 'Value');
q = peaksList(selectedPeakIndex);

% --- Executes on button press in FitSampleDetectorDistanceButton.
function FitSampleDetectorDistanceButton_Callback(hObject, eventdata, handles)
% hObject    handle to FitSampleDetectorDistanceButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cal = handles.CalibrationData;
data = handles.CalibrationDialogData;

q = GetSelectedQPeak(hObject, handles);

image = handles.CalibrationDialogData.Image;
mask = handles.CalibrationDialogData.ImageMask;
if (isempty(mask))
    mask = double(~isnan(image) & (image >= 0));
end
image(~mask) = 0;

[Xs, Ys] = meshgrid(1:size(image, 2), 1:size(image, 1));
which = ((Xs - data.ClickedXY(1)) .^ 2 + (Ys - data.ClickedXY(2)) .^ 2) < (9 * data.ClickedProfileSigma ^ 2);
which = logical(which .* double(mask));
estimatedPeakAmplitude = max(image(which));

options = FitPeak2d();

options.PeakAmplitude = estimatedPeakAmplitude;

options.InitialAlpha = cal.AlphaRadians;
options.InitialBeta = cal.BetaRadians;
options.InitialBeamCenterX = cal.BeamCenterX;
options.InitialBeamCenterY = cal.BeamCenterY;
options.InitialSample2DetectorDist = cal.SampleToDetDist / cal.PixelSize;
options.DoNotChangeBeamCenter = 1;
options.ShouldFitTilt = 0;
options.ShouldFitWithoutTiltFirst = 1;
options.TwoK = (4 * pi) / cal.Lambda;
result = FitPeak2d(options, image, mask, q, 0.0033);

cal.SampleToDetDist = result.SampleToDetDist * cal.PixelSize;
UpdateCalibrationDisplay(hObject);
Redraw(hObject);

1;


% --- Executes on button press in FitSampleDetectorDistanceAndTilt.
function FitSampleDetectorDistanceAndTilt_Callback(hObject, eventdata, handles)
% hObject    handle to FitSampleDetectorDistanceAndTilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cal = handles.CalibrationData;
data = handles.CalibrationDialogData;

q = GetSelectedQPeak(hObject, handles);

image = handles.CalibrationDialogData.Image;
mask = handles.CalibrationDialogData.ImageMask;
if (isempty(mask))
    mask = double(~isnan(image) & (image >= 0));
end
image(~mask) = 0;

[Xs, Ys] = meshgrid(1:size(image, 2), 1:size(image, 1));
which = ((Xs - data.ClickedXY(1)) .^ 2 + (Ys - data.ClickedXY(2)) .^ 2) < (9 * data.ClickedProfileSigma ^ 2);
which = logical(which .* double(mask));
estimatedPeakAmplitude = max(image(which));

options = FitPeak2d();

options.PeakAmplitude = estimatedPeakAmplitude;

options.InitialAlpha = cal.AlphaRadians;
options.InitialBeta = cal.BetaRadians;
options.InitialBeamCenterX = cal.BeamCenterX;
options.InitialBeamCenterY = cal.BeamCenterY;
options.InitialSample2DetectorDist = cal.SampleToDetDist / cal.PixelSize;
options.DoNotChangeBeamCenter = 1;
options.ShouldFitTilt = 1;
options.ShouldFitWithoutTiltFirst = 0;
options.TwoK = (4 * pi) / cal.Lambda;
result = FitPeak2d(options, image, mask, q, 0.0033);

cal.AlphaRadians = result.Alpha;
cal.BetaRadians = result.Beta;
cal.SampleToDetDist = result.SampleToDetDist * cal.PixelSize;
UpdateCalibrationDisplay(hObject);
Redraw(hObject);

1;


% --- Executes on button press in TraceSelectedPeakAndCoarseFitButton.
function TraceSelectedPeakAndCoarseFitButton_Callback(hObject, eventdata, handles)
% hObject    handle to TraceSelectedPeakAndCoarseFitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;
options = ReconstructPeakShortSimpleSteps();
[curve] = ReconstructPeakShortSimpleSteps(data.SmoothedImage, data.SmoothedMask, ...
    data.ClickedXY(1), data.ClickedXY(2), ...
    data.ClickedProfileAngle, data.ClickedProfileSigma, options);

t = linspace(0, 2 * pi, 1000);
t(end) = [];
[plotX, plotY] = curve.Conic.GetPointsFromParametricForm(t);
[plotX, plotY] = GetPointsWithinImage(handles, plotX, plotY);

hold on;
plot(plotX, plotY, '--g', 'LineWidth', 1);
hold off;
1;


% --- Executes on button press in GuessCenterButton.
function GuessCenterButton_Callback(hObject, eventdata, handles)
% hObject    handle to GuessCenterButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = handles.CalibrationDialogData;

% TODO: Use the gradient of the image to find the center. If the gradient
% and center of intensity do not match, deny the visibility of the center

I = sort(data.Image(:), 'descend');
I(isnan(I) | (I < 0)) = [];
I99 = I(floor(numel(I)/100));
which = (data.Image >= I99);
[x,y] = meshgrid(1:size(data.Image, 2),1:size(data.Image, 1));
x = sum(x(which) .* data.Image(which)) / sum(data.Image(which));
y = sum(y(which) .* data.Image(which)) / sum(data.Image(which));

handles.CalibrationData.BeamCenterX = x;
handles.CalibrationData.BeamCenterY = y;

UpdateCalibrationDisplay(hObject);
Redraw(hObject);
1;


% --- Executes on button press in FitAllParametersButton.
function FitAllParametersButton_Callback(hObject, eventdata, handles)
% hObject    handle to FitAllParametersButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cal = handles.CalibrationData;
data = handles.CalibrationDialogData;

q = GetSelectedQPeak(hObject, handles);

image = handles.CalibrationDialogData.Image;
mask = handles.CalibrationDialogData.ImageMask;
if (isempty(mask))
    mask = double(~isnan(image) & (image >= 0));
end
image(~mask) = 0;

[Xs, Ys] = meshgrid(1:size(image, 2), 1:size(image, 1));
which = ((Xs - data.ClickedXY(1)) .^ 2 + (Ys - data.ClickedXY(2)) .^ 2) < (9 * data.ClickedProfileSigma ^ 2);
which = logical(which .* double(mask));
estimatedPeakAmplitude = max(image(which));

options = FitPeak2d();

options.PeakAmplitude = estimatedPeakAmplitude;

options.InitialAlpha = cal.AlphaRadians;
options.InitialBeta = cal.BetaRadians;
options.InitialBeamCenterX = cal.BeamCenterX;
options.InitialBeamCenterY = cal.BeamCenterY;
options.InitialSample2DetectorDist = cal.SampleToDetDist / cal.PixelSize;
options.DoNotChangeBeamCenter = 0;
options.ShouldFitTilt = 1;
options.ShouldFitWithoutTiltFirst = 0;
options.TwoK = (4 * pi) / cal.Lambda;
result = FitPeak2d(options, image, mask, q, 0.0033);

cal.AlphaRadians = result.Alpha;
cal.BetaRadians = result.Beta;
cal.SampleToDetDist = result.SampleToDetDist * cal.PixelSize;
UpdateCalibrationDisplay(hObject);
Redraw(hObject);

1;


% --- Executes on button press in pushbutton44.
function pushbutton44_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton44 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu13.
function popupmenu13_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu13 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu13


% --- Executes during object creation, after setting all properties.
function popupmenu13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in technicalPageButton.
function technicalPageButton_Callback(hObject, eventdata, handles)
% hObject    handle to technicalPageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in initialFitPageButton.
function initialFitPageButton_Callback(hObject, eventdata, handles)
% hObject    handle to initialFitPageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in addPeaksPageButton.
function addPeaksPageButton_Callback(hObject, eventdata, handles)
% hObject    handle to addPeaksPageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in animateCheckbox.
function animateCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to animateCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of animateCheckbox



function stepsBetweenAnimationDrawEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to stepsBetweenAnimationDrawEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stepsBetweenAnimationDrawEditBox as text
%        str2double(get(hObject,'String')) returns contents of stepsBetweenAnimationDrawEditBox as a double


% --- Executes during object creation, after setting all properties.
function stepsBetweenAnimationDrawEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stepsBetweenAnimationDrawEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox18.
function checkbox18_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox18



function secondToPauseBetweenMajorStepsEditBox_Callback(hObject, eventdata, handles)
% hObject    handle to secondToPauseBetweenMajorStepsEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of secondToPauseBetweenMajorStepsEditBox as text
%        str2double(get(hObject,'String')) returns contents of secondToPauseBetweenMajorStepsEditBox as a double


% --- Executes during object creation, after setting all properties.
function secondToPauseBetweenMajorStepsEditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to secondToPauseBetweenMajorStepsEditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox19.
function checkbox19_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox19
