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

% Last Modified by GUIDE v2.5 08-May-2012 09:13:32

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

if (numel(varargin) >= 2)
    handles.CalibrationData = varargin{2};
else
    handles.CalibrationData = CalibrationDataClass();
end

handles.CalibrationDialogData = CalibrationDialogDataClass();

% Update handles structure
guidata(hObject, handles);

if (numel(varargin) >= 1)
    handles.CalibrationDialogData.Image = double(varargin{1});
    HandleNewImage(hObject);
    Redraw(hObject);
else
    handles.CalibrationDialogData.Image = [];
end

ShowDefaultStatus(handles);

% UIWAIT makes CalibrationDialog wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CalibrationDialog_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout{1} = handles.CalibrationData;

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


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on slider movement.
function UpperLimit_h_Callback(hObject, eventdata, handles)
% hObject    handle to UpperLimit_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


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

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function LowerLimit_h_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LowerLimit_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in Done_h.
function Done_h_Callback(hObject, eventdata, handles)
% hObject    handle to Done_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in Cancel_h.
function Cancel_h_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
pilatusGaps = [195+[1:17], 407+[1:17]];
if (all(data.Image(pilatusGaps, :) <= 0))
    data.Image(pilatusGaps, :) = NaN;
end

% TODO: Use the gradient of the image to find the center. If the gradient
% and center of intensity do not match, deny the visibility of the center

I = sort(data.Image(:), 'descend');
I(isnan(I)) = [];
I99 = I(floor(numel(I)/100));
which = (data.Image >= I99);
[x,y] = meshgrid(1:size(data.Image, 2),1:size(data.Image, 1));
x = sum(x(which) .* data.Image(which)) / sum(data.Image(which));
y = sum(y(which) .* data.Image(which)) / sum(data.Image(which));
data.EstimatedCenter = [x, y];

% --- Executes on button press in SelectImageBtn.
function SelectImageBtn_Callback(hObject, eventdata, handles)
% hObject    handle to SelectImageBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = handles.CalibrationDialogData;
I = SelectImageAndRead();
data.Image = double(I);
guidata(hObject, handles);
HandleNewImage(hObject);

Redraw(hObject);


% --- Executes on button press in UseGivenImageBtn.
function UseGivenImageBtn_Callback(hObject, eventdata, handles)
% hObject    handle to UseGivenImageBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function MenuItem_StopMarking_h_Callback(hObject, eventdata, handles)
% hObject    handle to MenuItem_StopMarking_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ImageMenu_h_Callback(hObject, eventdata, handles)
% hObject    handle to ImageMenu_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function MenuItem_ResetZoom_h_Callback(hObject, eventdata, handles)
% hObject    handle to MenuItem_ResetZoom_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.Axes_h);
xlim('auto')
ylim('auto')

% --------------------------------------------------------------------
function MenuItem_Zoom_h_Callback(hObject, eventdata, handles)
% hObject    handle to MenuItem_Zoom_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.Axes_h);
r = getrect(handles.Axes_h);

%if (r(3) > 10 && r(4) > 10)
xlim([r(1), r(1) + r(3)]);
ylim([r(2), r(2) + r(4)]);
%end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Redraw(hObject)
handles = guidata(hObject);
axes(handles.Axes_h); % Focus on the relevant axes
data = handles.CalibrationDialogData;

hold off;

% Display a logarithmic scaled image
I = double(data.Image);
ignoredPixels = I < 0;
I(ignoredPixels) = 0;
I = log(1 + I);
calibImage_h = imagesc(I);
%calibImage_h = imagesc(gradient(I));
axis equal; % Make axes equal

set(calibImage_h,'UIContextMenu', get(handles.Axes_h, 'UIContextMenu'));

% Filter intensity using the sliders
caxis(handles.Axes_h,[max(I(:)) * get(handles.LowerLimit_h,'value') max(I(:)) * get(handles.UpperLimit_h,'value')]);
colormap(handles.Axes_h,'gray'); % Set color map
%set(handles.Axes_h,'Xtick',[],'Ytick',[]); % Remove numbers from axes
PlotBigMark(data.EstimatedCenter);

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


% --- Executes on button press in markPeak5Pts.
function markPeak5Pts_Callback(hObject, eventdata, handles)
% hObject    handle to markPeak5Pts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in markPeak4Pts.
function markPeak4Pts_Callback(hObject, eventdata, handles)
% hObject    handle to markPeak4Pts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
c = conic.GetConicTypeNumeric()  <= 3;
ceq = [];

function [c,ceq] = ValidConicNonlinearConstraint(qf)
conic = ConicClass();
conic.SetQuadraticForm(qf);
c = conic.GetConicTypeNumeric() - 3;
ceq = [];

function [rect] = GetRectForImageMatrix(image)
if (numel(image) > 2)
    image = size(image);
end
rect = [1, 1, image(2) - 1, image(1) - 1];

% --- Executes on button press in markPeak1Pts.
function markPeak1Pts_Callback(hObject, eventdata, handles)
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
    
    relevantMask = double(image > (peakIntensityEst * 0.5) & image < (peakIntensityEst * 2));
    %figure; imagesc(relevantMask)
    
    lastUsedMask = zeros(size(image));
    usedMask = zeros(size(image));
    
    usedMask(peakRow, peakCol) = 1;
    k = 5;
    
    
    if (0)
        figure; imagesc(usedMask + relevantMask)
    end
    
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
        
        if (0)
            xl = xlim();
            yl = ylim();
            imagesc(usedMask + relevantMask);
            xlim(xl);
            ylim(yl);
        end
    end
    
    if (0)
        xl = xlim();
        yl = ylim();
        imagesc(usedMask + relevantMask);
        xlim(xl);
        ylim(yl);
    end
    
    [rows, cols] = find(usedMask);
    
    selectedIndices = floor(rand(1, 5) * (numel(rows) - 1) + 1);
    selectedRows = rows(selectedIndices);
    selectedCols = cols(selectedIndices);
    
    bestSelectedIndices = selectedIndices;
    
    sumOfDistances = 0;
    for pointIndex = 1:5
        sumOfDistances = sumOfDistances + sumsqr([selectedRows - selectedRows(pointIndex), selectedCols - selectedCols(pointIndex)]);
    end
    
    maxSumOfDistances = sumOfDistances;
    
    for i = 1:50
        selectedIndices = floor(rand(1, 5) * (numel(rows) - 1) + 1);
        selectedRows = rows(selectedIndices);
        selectedCols = cols(selectedIndices);
        
        sumOfDistances = 0;
        for pointIndex = 1:5
            sumOfDistances = sumOfDistances + sumsqr([selectedRows - selectedRows(pointIndex), selectedCols - selectedCols(pointIndex)]);
        end
        
        if (maxSumOfDistances < sumOfDistances)
            maxSumOfDistances = sumOfDistances;
            bestSelectedIndices = selectedIndices;
        end
    end
    
    selectedIndices = bestSelectedIndices;
    selectedRows = rows(selectedIndices);
    selectedCols = cols(selectedIndices);
    
    conic = ConicClass();
    conic.SetSolutionOf5Points(selectedCols * restoreScaleFactor, selectedRows * restoreScaleFactor);
    
    hold on;
    plot(selectedCols, selectedRows, '*g', 'MarkerSize', 16);
    conic.DebugPlot2();
    hold off;
    
    tElapsed = toc(tStarted);
    display(sprintf('Took %0.2f seconds (%i dilation iterations)', ...
        tElapsed, numOfDilationIterations));
    1;

    
    % Fit conic with quadratic for parameterization
    if (1)
        
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


% --------------------------------------------------------------------
function selectCenterMenuItem_Callback(hObject, eventdata, handles)
axes(handles.Axes_h);
data = handles.CalibrationDialogData;

[x, y, ok] = SelectValidPoint(hObject);
if (ok)
    data.EstimatedCenter = [x, y];
end

Redraw(hObject);


% --- Executes on button press in usePeak2.
function usePeak2_Callback(hObject, eventdata, handles)
% hObject    handle to usePeak2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of usePeak2


% --- Executes on button press in usePeak3.
function usePeak3_Callback(hObject, eventdata, handles)
% hObject    handle to usePeak3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of usePeak3


% --- Executes on button press in usePeak4.
function usePeak4_Callback(hObject, eventdata, handles)
% hObject    handle to usePeak4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of usePeak4


% --- Executes on button press in usePeak5.
function usePeak5_Callback(hObject, eventdata, handles)
% hObject    handle to usePeak5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of usePeak5


% --- Executes on button press in usePeak6.
function usePeak6_Callback(hObject, eventdata, handles)
% hObject    handle to usePeak6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of usePeak6


% --- Executes on button press in usePeak1.
function usePeak1_Callback(hObject, eventdata, handles)
% hObject    handle to usePeak1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of usePeak1



function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit7 as text
%        str2double(get(hObject,'String')) returns contents of edit7 as a double


% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit8_Callback(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit8 as text
%        str2double(get(hObject,'String')) returns contents of edit8 as a double


% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in usePeak7.
function usePeak7_Callback(hObject, eventdata, handles)
% hObject    handle to usePeak7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of usePeak7


% --- Executes on button press in usePeak8.
function usePeak8_Callback(hObject, eventdata, handles)
% hObject    handle to usePeak8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of usePeak8
