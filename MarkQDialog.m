function varargout = MarkQDialog(varargin)
% MARKQDIALOG MATLAB code for MarkQDialog.fig
%      MARKQDIALOG, by itself, creates a new MARKQDIALOG or raises the existing
%      singleton*.
%
%      H = MARKQDIALOG returns the handle to a new MARKQDIALOG or the handle to
%      the existing singleton*.
%
%      MARKQDIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MARKQDIALOG.M with the given input arguments.
%
%      MARKQDIALOG('Property','Value',...) creates a new MARKQDIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MarkQDialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MarkQDialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MarkQDialog

% Last Modified by GUIDE v2.5 15-Sep-2012 21:26:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MarkQDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @MarkQDialog_OutputFcn, ...
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


% --- Executes just before MarkQDialog is made visible.
function MarkQDialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MarkQDialog (see VARARGIN)

addpath('UIHelpers\');

% Choose default command line output for MarkQDialog
handles.output = hObject;

if (numel(varargin) >= 1)
    handles.Object = varargin{1};
else
    handles.Object = QMarkClass();
end
binding = UIBindingsClass();
handles.Binding = binding;


handles.Object.Q = 2.123;
handles.Object.Width = 1.5;
handles.Object.Visible = 0;

binding.BindNumFieldToStringProperty(handles.QValueEditbox, handles.Object, 'Q');
binding.BindNumFieldToDropdown(handles.WidthSelectionBox, handles.Object, 'Width');
binding.BindStringFieldToDropdown(handles.ColorSelectionBox, handles.Object, 'Color');
%binding.BindStringFieldToDropdown(handles.LineStyleSelectionBox, handles.Object, 'LineStyle');
binding.BindNumFieldToDropdownIndex(handles.SeriesSelectionBox, handles.Object, 'SeriesType', @HandleSeriesUpdate);
%binding.BindOneWayDropdownIndexToField(handles.SeriesSelectionBox, handles.Object, 'Series', @GenerateSeries);

% Update handles structure
guidata(hObject, handles);

binding.UpdateAllRegisteredFields();
UpdateShowHideButton(hObject, eventdata, handles);

% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MarkQDialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function [] = HandleSeriesUpdate(hObject, eventData)
handles = guidata(hObject);
selectedIndex = get(handles.SeriesSelectionBox, 'Value');
handles.Object.Series = GenerateSeries(selectedIndex);
1;

function [series] = GenerateSeries(seriesIndex)

switch (seriesIndex)
    case 2
        series = [1:9];
    case 3
        series = [1 sqrt(3) 2 sqrt(7) 3  sqrt(12) sqrt(13)];
    case 4
        series = [1 sqrt(2) sqrt(3) 2 sqrt(5) sqrt(6) sqrt(8) 3];
    otherwise
        series = [];
end
1;

function QValueEditbox_Callback(hObject, eventdata, handles)
% hObject    handle to QValueEditbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of QValueEditbox as text
%        str2double(get(hObject,'String')) returns contents of QValueEditbox as a double


% --- Executes during object creation, after setting all properties.
function QValueEditbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to QValueEditbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ColorSelectionBox.
function ColorSelectionBox_Callback(hObject, eventdata, handles)
% hObject    handle to ColorSelectionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ColorSelectionBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ColorSelectionBox


% --- Executes during object creation, after setting all properties.
function ColorSelectionBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ColorSelectionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in WidthSelectionBox.
function WidthSelectionBox_Callback(hObject, eventdata, handles)
% hObject    handle to WidthSelectionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns WidthSelectionBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from WidthSelectionBox


% --- Executes during object creation, after setting all properties.
function WidthSelectionBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WidthSelectionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SeriesSelectionBox.
function SeriesSelectionBox_Callback(hObject, eventdata, handles)
% hObject    handle to SeriesSelectionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SeriesSelectionBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SeriesSelectionBox


% --- Executes during object creation, after setting all properties.
function SeriesSelectionBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SeriesSelectionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function UpdateShowHideButton(hObject, eventdata, handles)
if (handles.Object.Visible)
    set(handles.ShowHideButton, 'String', 'Hide');
else
    set(handles.ShowHideButton, 'String', 'Show');
end

% --- Executes on button press in ShowHideButton.
function ShowHideButton_Callback(hObject, eventdata, handles)
% hObject    handle to ShowHideButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Object.Visible = 1 - (handles.Object.Visible ~= 0);
UpdateShowHideButton(hObject, eventdata, handles);
1;
