function [LINES, BeamWavelength, BeamEnergy] = ...
    AddCalibrationSample_GUI_SAXSi(LINES_0, BeamWavelength, BeamEnergy, I)

LINES = [];
useNewMethod = 1;
calibImage_h = [];

% Taken from: "X-ray transition energies: new approach to a comprehensive evaluation", Rev. Mod. Phys. 75, 35–99 (2003) 
E2L = 12398.41857; %lambda (Angstroem)=E2L / E(keV);
T=41;
% idx=randperm(8); Colors=hsv(8); Colors=Colors(idx,:);
Colors=lines(9); Colors=Colors([(1:6)'; (8:9)'],:);

if (nargin < 3)
    BeamWavelength = CopperKAlpha();
    BeamEnergy = E2L / BeamWavelength;
end

% Allow missing redundent parameters
if (isempty(BeamWavelength)), BeamWavelength = E2L / BeamEnergy; end;
if (isempty(BeamEnergy)), BeamEnergy = E2L / BeamWavelength; end;

if (nargin < 3 || isempty(I))
    %[FILENAME, PATHNAME] = uigetfile('*.tif', 'Choose Calibration Sample');
    
    [FILENAME, PATHNAME] = uigetfile( ...
        {'*.tif;*.mat;*.image','Compatible Image Files (*.tif,*.image,*.mat)';
        '*.*',  'All Files (*.*)'}, ...
        'Choose Calibration Sample');
    
    I=read2D(strcat(PATHNAME,FILENAME));
end

PilatusBlankRows = [[1:17] + 195, [1:17] + 17 + 195 * 2];

ProcessedImage = double(I);
I=log10(1+double(abs(I)));

if (all(size(ProcessedImage) == [619, 487]) && ...
    ~any(sum(ProcessedImage(PilatusBlankRows, :))))
    ProcessedImage(PilatusBlankRows, :) = -inf;
end

[M,N]=size(I);

%if N>M, I=I'; [M,N]=size(I); end % Tilt the image to have largest size vertical

Width_axes=12*N/M; Imax=max(I(:)); Imin=min(I(:));

Diffraction_lines=struct([]);
for li=1:8,
    Diffraction_lines(li).Np=0;
    Diffraction_lines(li).size=[M N];
    Diffraction_lines(li).xy=[];
    Diffraction_lines(li).theta=[];
    Diffraction_lines(li).Sample=[];
end

%--------------------------------------------------------------------------
% CREATES THE AXES AND SLIDERS TO ADJUST CONTRAST

screenResolution = get(0, 'ScreenSize');
screenDPI = get(0, 'ScreenPixelsPerInch');
screenSizeInCm = (screenResolution(3:4) / screenDPI) * 2.54;

if (Width_axes > (screenSizeInCm(1)*0.8-9))
    Width_axes = screenSizeInCm(1)*0.8-9;
end

figureSize = [9+Width_axes 15];
    

fig_h = figure('Units','centimeters','Position',[1 2 figureSize]);
set(fig_h,'menubar','none','numbertitle','off','name','Calibration Data');
ax_h = axes('Parent',fig_h,'Units','centimeters','Position',[2 2.51 Width_axes 12],'ButtonDownFcn',@Click_on_Image);

% contextMenu = uicontextmenu;
% zoomMenuItem = uimenu('Parent',contextMenu, 'Label', 'Zoom', 'Callback', 'axes(ax_h); zoom on;');
% set(gcf, 'UIContextMenu', contextMenu);


Clicktext = uicontrol(fig_h,'Style','text','Units','centimeters','Position',[0.5 0.25 9+Width_axes 1],...
    'string','Click left to add a new point, and right to stop adding points to that line',...
    'horizontalalignment','left',...
    'Foregroundcolor',[1 0 0],'Backgroundcolor',get(fig_h,'Color'),'visible','off');

slinf_h = uicontrol(fig_h,'Style','slider','Max',Imax,'Min',Imin,'Value',Imin,...
    'Units','centimeters','Position',[0.5 2.51 0.5 12],'Callback',@slinf_callback);

slsup_h = uicontrol(fig_h,'Style','slider','Max',Imax,'Min',Imin,'Value',Imax,...
    'Units','centimeters','Position',[1.1 2.51 0.5 12],'Callback',@slsup_callback);

More_h = uicontrol(fig_h,'Style','pushbutton','string','Add Calibration Sample',...
    'Units','centimeters','Position',[3+Width_axes 3.5 5 0.75],...
    'Callback',@More_callback);

Done_h = uicontrol(fig_h,'Style','pushbutton','string','Done',...
    'Units','centimeters','Position',[3+Width_axes 2.5 5 0.75],...
    'Callback',@Done_callback);

undo_h = uicontrol(fig_h,'Style','pushbutton','string','Remove Points',...
    'Units','centimeters','Position',[3+Width_axes 1.5 5 0.75],...
    'Callback',@Undo_callback);

zoom_h = uicontrol(fig_h,'Style','pushbutton','string','Zoom',...
    'Units','centimeters','Position', [2 1.5 2 0.75],...
    'Callback',@Zoom_callback);

uicontrol(fig_h,'Style','pushbutton','string','Reset Zoom',...
    'Units','centimeters','Position', [4.2 1.5 2 0.75],...
    'Callback',@ResetZoom_callback);

uicontrol('parent',fig_h,'Style','text','String','Scan Width (px)', ...
    'horizontalalignment','left','units','centimeters', 'Position', [6.4 1.9 2.3 0.4]);
scanWidthEdit_h = uicontrol('parent',fig_h,'Style','edit','String','40','units','centimeters',...
    'Position',[6.4 1.4 2.3 0.4],'backgroundcolor',[1 1 1],'Callback',@Initializes_calibration_values);


uicontrol('parent',fig_h,'Style','text','String','Auto Steps (#)', ...
    'horizontalalignment','left','units','centimeters', 'Position', [8.9 1.9 2.3 0.4]);
autoStepsEdit_h = uicontrol('parent',fig_h,'Style','edit','String','20','units','centimeters',...
    'Position',[8.9 1.4 2.3 0.4],'backgroundcolor',[1 1 1],'Callback',@Initializes_calibration_values);


% auto_h = uicontrol(fig_h,'Style','pushbutton','string','I''m feeling lucky!',...
%     'Units','centimeters','Position',[3+Width_axes 0.5 5 0.75],...
%     'Callback',@Auto_callback);

%--------------------------------------------------------------------------
% CREATES THE CALIBRATION FILE FRAME

cframe_h = uipanel('parent',fig_h,'Units','centimeters','Position',[3+Width_axes 4.5 5 10]);

popup_h = uicontrol('parent',cframe_h,'Style', 'popup','String', 'AgBh|LAB6|HDPE|Other','Backgroundcolor',[1 1 1],'units','centimeters','Position', [0.5 8.5 4 1],...
    'Callback',@Initializes_calibration_values);

text1_h = uicontrol('parent',cframe_h,'Style','text','String','Energy (eV)','horizontalalignment','left','units','centimeters',...
    'Position', [0.5 8.00 2.5 0.5]);
text2_h = uicontrol('parent',cframe_h,'Style','text','String','Wavelength (Å)','horizontalalignment','left','units','centimeters',...
    'Position', [0.5 7.35 2.5 0.5]);
uicontrol('parent',cframe_h,'Style','text','String','Auto-mark','horizontalalignment','left','units','centimeters',...
    'Position', [0.5 6.70 2.5 0.5],'Callback',@AutoMarkCheckChange);

Energy_h = uicontrol('Tag', 'energyBox', 'parent',cframe_h,'Style','edit', 'String', num2str(BeamEnergy, 7), 'units','centimeters',...
    'Position',[3 8.00 1.5 0.5],'backgroundcolor',[1 1 1],'Callback',@HandleEnergyChanged);
Wavelength_h = uicontrol('Tag', 'lambdaBox', 'parent',cframe_h,'Style','edit', 'String', num2str(BeamWavelength, 7), 'units','centimeters',...
    'Position',[3 7.35 1.5 0.5],'backgroundcolor',[1 1 1],'Callback',@HandleLambdaChanged);
auto_h = uicontrol('parent',cframe_h,'Style','checkbox','units','centimeters',...
    'Position',[3 6.70 1.5 0.5], 'Value', 1);

%----------------------

text3_h = uicontrol('parent',cframe_h,'Style','text','String','2 theta','horizontalalignment','center','units','centimeters',...
    'Position', [2.5 6.00 2 0.5]);
text4_h = uicontrol('parent',cframe_h,'Style','text','String','Select','horizontalalignment','center','units','centimeters',...
    'Position', [0.5 6.00 2 0.5]);

angle1_h = uicontrol('parent',cframe_h,'Style','edit','units','centimeters','Position', [2.5 5.60 2 0.5]);
angle2_h = uicontrol('parent',cframe_h,'Style','edit','units','centimeters','Position', [2.5 4.85 2 0.5]);
angle3_h = uicontrol('parent',cframe_h,'Style','edit','units','centimeters','Position', [2.5 4.10 2 0.5]);
angle4_h = uicontrol('parent',cframe_h,'Style','edit','units','centimeters','Position', [2.5 3.35 2 0.5]);
angle5_h = uicontrol('parent',cframe_h,'Style','edit','units','centimeters','Position', [2.5 2.60 2 0.5]);
angle6_h = uicontrol('parent',cframe_h,'Style','edit','units','centimeters','Position', [2.5 1.85 2 0.5]);
angle7_h = uicontrol('parent',cframe_h,'Style','edit','units','centimeters','Position', [2.5 1.10 2 0.5]);
angle8_h = uicontrol('parent',cframe_h,'Style','edit','units','centimeters','Position', [2.5 0.35 2 0.5]);
aa_h=[angle1_h angle2_h angle3_h angle4_h angle5_h angle6_h angle7_h angle8_h];


% CREATES THE BUTTON GROUP

bgroup_h = uibuttongroup('Parent',cframe_h,'visible','on','units','centimeters','Position',[1 0.0 1 6.5],'bordertype','none','SelectionChangeFcn',@selcbk);
u1 = uicontrol('Style','Radio','units','centimeters','pos',[0.25 5.60 0.5 0.5],'parent',bgroup_h,'HandleVisibility','off','backgroundcolor',Colors(1,:));
u2 = uicontrol('Style','Radio','units','centimeters','pos',[0.25 4.85 0.5 0.5],'parent',bgroup_h,'HandleVisibility','off','backgroundcolor',Colors(2,:));
u3 = uicontrol('Style','Radio','units','centimeters','pos',[0.25 4.10 0.5 0.5],'parent',bgroup_h,'HandleVisibility','off','backgroundcolor',Colors(3,:));
u4 = uicontrol('Style','Radio','units','centimeters','pos',[0.25 3.35 0.5 0.5],'parent',bgroup_h,'HandleVisibility','off','backgroundcolor',Colors(4,:));
u5 = uicontrol('Style','Radio','units','centimeters','pos',[0.25 2.60 0.5 0.5],'parent',bgroup_h,'HandleVisibility','off','backgroundcolor',Colors(5,:));
u6 = uicontrol('Style','Radio','units','centimeters','pos',[0.25 1.85 0.5 0.5],'parent',bgroup_h,'HandleVisibility','off','backgroundcolor',Colors(6,:));
u7 = uicontrol('Style','Radio','units','centimeters','pos',[0.25 1.10 0.5 0.5],'parent',bgroup_h,'HandleVisibility','off','backgroundcolor',Colors(7,:));
u8 = uicontrol('Style','Radio','units','centimeters','pos',[0.25 0.35 0.5 0.5],'parent',bgroup_h,'HandleVisibility','off','backgroundcolor',Colors(8,:));
set(bgroup_h,'SelectedObject',[]);
uu_h =[u1 u2 u3 u4 u5 u6 u7 u8]; idx_active=137;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Initializes_calibration_values;
FirstImageDraw
Initializes_point_plotting

%hgsave(gcf, 'AddCalibrationSampleDialog.fig');
%saveas(gcf, 'AddCalibrationSampleDialog.fig');
uiwait
1;

    function ResetZoom_callback(~,~)
        FirstImageDraw
        Initializes_point_plotting
    end

    function Zoom_callback(~,~)
        axes(ax_h);
        
        r = getrect(ax_h);
        
        if (r(3) > 10 && r(4) > 10)
            xlim([r(1), r(1) + r(3)]);
            ylim([r(2), r(2) + r(4)]);
        end
    end

    function Undo_callback(~,~)
        rect = getrect(ax_h);
        
        if (isempty(rect) || rect(3) == 0 || rect(4) == 0)
            return;
        end
        
        rect(3) = rect(1) + rect(3);
        rect(4) = rect(2) + rect(4);
        
        for i = 1:numel(Diffraction_lines)
            xy = Diffraction_lines(i).xy;
            
            if (isempty(xy)); continue; end
            
            xy(xy(:, 1) > rect(1) & xy(:, 1) < rect(3) & ...
               xy(:, 2) > rect(2) & xy(:, 2) < rect(4), :) = [];
            
            Diffraction_lines(i).xy = xy;
            Diffraction_lines(i).Np=size(xy, 1);
        end
        
        Initializes_point_plotting;
    end

    % Automatic first ring finding
    function Auto_callback(hObject,eventdata)
        
        % TODO: Handle Zingers
        
        gaussianAmplitudeThreshold = PercentileValue(I, 0.99);
        
        % Find Approximate Center of beam
        maxI=max(max(I));
        sortedI = sort(I(:));
        
        selectedThreshold = sortedI(floor(length(sortedI) * 0.999));
        
        [X, Y, Values] = find(I>selectedThreshold);
        beamcenterX = mean(X);
        beamcenterY = mean(Y);
        
        %Diffraction_lines(1).Np = 1;
        %Diffraction_lines(1).xy = [beamcenterX beamcenterY]
        %Initializes_point_plotting;
        
        
        % Find points on first ring
        
        xy = [];
        
        twoPi = 2*pi();
        N = 100;
        angles =  2.5133 + [0:1/N:1-1/N] * twoPi;
        
        for a = angles
            [stepX, stepY] = pol2cart(a, 1);
            %step = [stepX, stepY];
            
            maxLength = sqrt(2) * max(size(I));
            x = beamcenterX + stepX * [1:maxLength];
            y = beamcenterY + stepY * [1:maxLength];
            
            ind = find(x < 1, 1);
            if (~isempty(ind)); x = x(1:ind-1); y = y(1:ind-1); end;
            
            ind = find(y < 1, 1);
            if (~isempty(ind)); x = x(1:ind-1); y = y(1:ind-1); end;
            
            ind = find(x > size(I, 1), 1);
            if (~isempty(ind)); x = x(1:ind-1); y = y(1:ind-1); end;
            
            ind = find(y > size(I, 2), 1);
            if (~isempty(ind)); x = x(1:ind-1); y = y(1:ind-1); end;
            
            r = sqrt((x - beamcenterX) .^ 2 + (y - beamcenterY) .^ 2);
            profile = interp2(1:size(I, 1), 1:size(I, 2), I', x, y, 'linear');
            smoothProfile = conv(profile, gausswin(19), 'same');
            
            maxI = max(profile);
            maxIndex = find(profile == maxI, 1);
            r = r(maxIndex:end);
            profile = profile(maxIndex:end);
            smoothProfile = conv(profile, gausswin(19), 'same');
            
            figure(2); plot(smoothProfile);
            
            r = r';
            profile = profile';
            %gaussFit = fit(r, profile, fittype('gauss2'));
            expFit = fit(r, profile, fittype('exp1'))
            
            figure(3);
            plot(r, profile, '-g');
            hold on;
            plot(r, expFit.a * exp(expFit.b * r), '-k');
            plot(r, profile - expFit.a * exp(expFit.b * r), '-b');
            hold off;
            
            smoothProfile = conv(profile - expFit.a * exp(expFit.b * r), gausswin(10), 'same');
            plot(r, smoothProfile);
            
            smoothProfile(smoothProfile < 1) = 0;
            plot(r, smoothProfile);
            
            gaussFit = fit(r, smoothProfile, fittype('gauss1'));
            
            if (gaussFit.a1 > gaussianAmplitudeThreshold)
                gaussianCenterR = gaussFit.b1;
                x = beamcenterX + stepX * gaussianCenterR;
                y = beamcenterY + stepY * gaussianCenterR;
                xy = [xy; [y, x]];
            end
        end
        
        Diffraction_lines(1).xy = xy;
        Diffraction_lines(1).Np=size(xy, 1);
        Initializes_point_plotting;
    end

    function [v] = PercentileValue(x, percentile)
        x = sort(x(:));
        v = x(1 + floor((length(x) - 1) * percentile));
    end

    function Done_callback(hObject,eventdata)
        
        CS=get(popup_h,'Value'); if CS==1, Sample='AgBh'; elseif CS==2, Sample='Lab6'; elseif CS==3, Sample='HDPE'; else Sample='Other'; end
        
        nl=0;
        
        for l=1:length(LINES_0)
            nl=nl+1;
            LINES(nl).theta=LINES_0(l).theta;
            LINES(nl).xy=LINES_0(l).xy;
            LINES(nl).size=LINES_0(l).size;
            LINES(nl).Sample=LINES_0(l).Sample;
        end
        
        for l=1:8
            Np=Diffraction_lines(l).Np;
            if Np>0
                nl=nl+1;
                % TODO: Change this, this is a very bad way to get the angle
                LINES(nl).theta=str2double(get(aa_h(l),'string'));
                LINES(nl).xy=Diffraction_lines(l).xy;
                LINES(nl).size=Diffraction_lines(l).size;
                LINES(nl).Sample=Sample;
            end
        end
        
        uiresume
        delete(fig_h);
        save ('linesSaved.mat','LINES');
        %       save('line_Center.mat','LINES');
        
        %   FindDetectorPosition_GUI_SAXSi(LINES);
        
    end

    function More_callback(hObject,eventdata)
        
        CS=get(popup_h,'Value'); if CS==1, Sample='AgBh'; elseif CS==2, Sample='Lab6'; elseif CS==3, Sample='HDPE'; else Sample='Other'; end
        
        nl=0;
        
        for l=1:length(LINES_0)
            nl=nl+1;
            LINES(nl).theta=LINES_0(l).theta;
            LINES(nl).xy=LINES_0(l).xy;
            LINES(nl).size=LINES_0(l).size;
            LINES(nl).Sample=LINES_0(l).Sample;
        end
        
        for l=1:8
            Np=Diffraction_lines(l).Np;
            if Np>0
                nl=nl+1;
                LINES(nl).theta=str2double(get(aa_h(l),'string'));
                LINES(nl).xy=Diffraction_lines(l).xy;
                LINES(nl).size=Diffraction_lines(l).size;
                LINES(nl).Sample=Sample;
            end
        end
        
        uiresume
        delete(fig_h);
        
        AddCalibrationSample_GUI_SAXSi(LINES, BeamWavelength, BeamEnergy);
        
    end

    function selcbk(source,eventdata)
        
        idx_active=find(uu_h==eventdata.NewValue);
        %Diffraction_lines(idx_active).Np=0; Diffraction_lines(idx_active).xy=[];
        Initializes_point_plotting;
        
        set(uu_h(1:end),'enable','off');
        set(Clicktext,'visible','on');
        
        useNewMethod = get(auto_h, 'Value');
        
        xy = Diffraction_lines(idx_active).xy;
        
        if (~useNewMethod)
            xy=get_point_zoom(xy);
        else
            
            profileWidth = str2num(get(scanWidthEdit_h, 'String'));
            maxSteps = str2num(get(autoStepsEdit_h, 'String'));
            
            xy=get_auto_points(xy, maxSteps, profileWidth);
        end
        
        set(Clicktext,'visible','off');
        Diffraction_lines(idx_active).Np=size(xy,1); Diffraction_lines(idx_active).xy=xy;
        
        set(bgroup_h,'SelectedObject',[]); idx_active=137;
        set(uu_h(1:end),'enable','on');
        
        Initializes_point_plotting
    end

    function AutoMarkCheckChange(hObject,eventdata)
        1;
    end

    function HandleLambdaChanged(hObject,eventdata)
        Lambda = str2double(get(Wavelength_h,'String'));
        Energy = E2L / Lambda;
        set(Energy_h, 'String', num2str(Energy, 7));

        Initializes_calibration_values;
    end

    function HandleEnergyChanged(hObject,eventdata)
        Energy = str2double(get(Energy_h,'String'));
        Lambda = E2L / Energy;
        set(Wavelength_h, 'String', num2str(Lambda, 7));
        
        Initializes_calibration_values;
    end

    function Initializes_calibration_values(hObject,eventdata)
        
        Energy=str2double(get(Energy_h,'String'));
        
        lambda=E2L / Energy;
        set(Wavelength_h,'String',num2str(lambda,7));
        
        %%% AgBH
        Calib(1).Spacings=58.38./(1:8); %Angstroms
        Calib(1).Angles_deg=2*asin(0.5*lambda./Calib(1).Spacings)*180/pi; %degrees
        
        %%% LAB6
        % http://link.aps.org/doi/10.1103/PhysRevA.69.042101
        LAB6_2d = 4.1568; % Å
        LAB6_Spacing = [];
        for h = 1:3
            LAB6_Spacing(end + 1) = LAB6_2d / h;
            
            for k = 1:h
                hkl = [h k 0];
                LAB6_Spacing(end + 1) = LAB6_2d / sqrt(hkl * hkl');

                for l = 1:k
                    hkl = [h k l];
                    LAB6_Spacing(end + 1) = LAB6_2d / sqrt(hkl * hkl');
                end
            end
        end
        
        LAB6_Spacing = unique(LAB6_Spacing);
        LAB6_Qs = 2 * pi() ./ LAB6_Spacing;
        LAB6_Spacing = sort(LAB6_Spacing, 'descend');
        
        Calib(2).Spacings = LAB6_Spacing(1:8); %Angstroms
        %Calib(2).Angles_deg = 2*asin(0.5*lambda./LAB6_Spacing)*180/pi; %degrees
        
        % Values given with the calibrant powder
        Calib(2).Angles_deg = [21.352, 30.35, 37.412, 43.481, 48.935, 53.962, 63.194, 67.521];
        
        %%% HDPE
        Calib(3).Spacings=[4.166 3.78 3.014 2.49]; %Angstroms
        Calib(3).Angles_deg=2*asin(0.5*lambda./Calib(3).Spacings)*180/pi; %degrees
        
        
        CS=get(popup_h,'Value');
        
        if CS==3
            set(text1_h,'visible','on'); set(text2_h,'visible','on');
            set(Energy_h,'visible','on'); set(Wavelength_h,'visible','on');
            
            if idx_active>=5,
                set(uu_h(5:8),'value',0);
                idx_active=137;
                set(bgroup_h,'SelectedObject',[]);
            end
            ang=Calib(3).Angles_deg;
            for l=1:4, set(aa_h(l),'String',num2str(ang(l),4),'enable','off'); end
            set(aa_h(5:8),'visible','off');
            set(uu_h(5:8),'visible','off');
            
        elseif CS==1
            
            set(text1_h,'visible','on'); set(text2_h,'visible','on');
            set(Energy_h,'visible','on'); set(Wavelength_h,'visible','on');
            
            ang=Calib(1).Angles_deg;
            for l=1:8, set(aa_h(l),'String',num2str(ang(l),4),'enable','off'); end
            set(aa_h(5:8),'visible','on');
            set(uu_h(5:8),'visible','on');
            
        elseif CS==2
            
            set(text1_h,'visible','on'); set(text2_h,'visible','on');
            set(Energy_h,'visible','on'); set(Wavelength_h,'visible','on');
            
            ang=Calib(2).Angles_deg;
            for l=1:8, set(aa_h(l),'String',num2str(ang(l),4),'enable','off'); end
            set(aa_h(5:8),'visible','on');
            set(uu_h(5:8),'visible','on');
        else % CS==4
            
            set(text1_h,'visible','off'); set(text2_h,'visible','off');
            set(Energy_h,'visible','off'); set(Wavelength_h,'visible','off');
            
            for l=1:8, set(aa_h(l),'String','','enable','on','backgroundcolor',[1 1 1]); end
            set(aa_h(5:8),'visible','on');
            set(uu_h(5:8),'visible','on');
        end
    end

    function FirstImageDraw()
        axes(ax_h);
        hold off
        calibImage_h = imshow(I); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        caxis(ax_h,[get(slinf_h,'value') get(slsup_h,'value')]);
        colormap(ax_h,'gray'); set(ax_h,'Xtick',[],'Ytick',[]);
        hold(ax_h,'on');
    end


    function Initializes_point_plotting(hObject,eventdata)
        
        %        hold(ax_h,'off');
        %        imshow(I,'Parent',ax_h);
        
        xLimits = xlim;
        yLimits = ylim;
        
        axes(ax_h);
        hold off
        calibImage_h = imshow(I); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        caxis(ax_h,[get(slinf_h,'value') get(slsup_h,'value')]);
        colormap(ax_h,'gray'); set(ax_h,'Xtick',[],'Ytick',[]);
        hold(ax_h,'on');
        
        for l=1:8
            Np=Diffraction_lines(l).Np;
            if Np>0
                xy=Diffraction_lines(l).xy;
                plot(xy(:,1),xy(:,2),'+','markersize',10,'markeredgecolor',Colors(l,:));
            end
        end

        hold on;
        xlim(xLimits);
        ylim(yLimits);
        hold off;
    end

    function [xy]=get_auto_points(xy, MaxStepCount, profileWidth)
        %%%% Roy %%%% add fiting by a line %%%%%%%%%%%%
        Done=0;
        
        if (nargin < 1)
            xy = [];
        end
        
        if (nargin < 2)
            MaxStepCount = 10;
        end
        
        if (nargin < 3)
            profileWidth = 30;
        end
        
        while not(Done)
            axes(ax_h); [xl0,yl0,BUTTON]=ginput(1);
            if BUTTON==3,
                Done=1;
                break;
            end
            
            axes(ax_h); [xl1,yl1,BUTTON]=ginput(1);
            if BUTTON==3,
                Done=1;
                break;
            end
            
            positions = [xl0,yl0; xl1,yl1];
            
%             l = imline(ax_h);
%             
%             if (isempty(l))
%                 Done = 1;
%                 break;
%             end
%             
%             positions = l.getPosition;

            firstStepSize = 5;
            stepSize = 15;
            
            % *** Find tangent ***
            
            success = 0;
            
            % Try 10 angles (~every 36 degrees)
%             angles = [0:1/10:1-1e-9] * 2 * pi();
%             
%             for a = angles
%                 [stepX, stepY] = pol2cart(a, 1);
%                 
%                  tangent = [stepX, stepY];
                 
%                  r = [xl0,yl0];
             r = positions(1, :);
             tangent = positions(2, :) - r;
             stepSize = sqrt(sum(tangent .^ 2));

             %[success, newR, newTangent, guassianFit] = TraceStep(r, tangent, ProcessedImage, firstStepSize, 30, profileWidth, 4, 0.5);
             %[success, newR, newTangent, guassianFit] = TraceStepFaster(r, tangent, ProcessedImage, firstStepSize, 30, profileWidth, 4);
             [success, newR, newTangent, guassianFit] = TraceStep(r, tangent, ProcessedImage, firstStepSize, 30, profileWidth, 5, 0.5);

%                  if (success)
%                      break;
%                  end
% 
%             end

            %NextStep = @(currentR, currentTangent)TraceStep(currentR, currentTangent, ProcessedImage, stepSize, 30, profileWidth, 2, 0.5);
            %NextStep = @(currentR, currentTangent)TraceStepFaster(currentR, currentTangent, ProcessedImage, stepSize, 30, profileWidth, 2);
            NextStep = @(currentR, currentTangent)TraceStep(currentR, currentTangent, ProcessedImage, stepSize, 30, profileWidth, 4, 0.5);

            stepsCount = 0;
                        
            if (success)
                firstSuccessfulR = newR;
                firstSuccessfulTangent = newTangent;
                
                while (success && stepsCount < MaxStepCount)
                    r = newR;
                    tangent = newTangent;
                    
                    stepsCount = stepsCount + 1;
                    display(sprintf('Step %i', stepsCount));
                    
                    xy = [xy ; r];
                    [success, newR, newTangent, guassianFit] = NextStep(newR, newTangent);
                    
                    % Draw while processing
                    Diffraction_lines(idx_active).Np=size(xy,1); Diffraction_lines(idx_active).xy=xy;
                    Initializes_point_plotting
                    
                    if (stepsCount > 2 && norm(r - firstSuccessfulR) < stepSize)
                        break;
                    end
                end
                
%                 r = firstSuccessfulR;
%                 tangent = -firstSuccessfulTangent;
%                 
%                 [success, newR, newTangent, guassianFit] = NextStep(newR, newTangent);
%                 
%                 while (success)
%                     r = newR;
%                     tangent = newTangent;
%                     
%                     stepsCount = stepsCount + 1;
%                     display(sprintf('Step %i', stepsCount));
%                     
%                     xy = [xy ; r];
%                     [success, newR, newTangent, guassianFit] = NextStep(newR, newTangent);
%                     
%                     % Draw while processing
%                     Diffraction_lines(idx_active).Np=size(xy,1); Diffraction_lines(idx_active).xy=xy;
%                     Initializes_point_plotting
%                 end
            end
            
        end
    end

    function [xy]=get_point_zoom(xy)
        %%%% Roy %%%% add fiting by a line %%%%%%%%%%%%
        Done=0;
        
        if (nargin < 1)
            xy = [];
        end
        
        while not(Done)
            
            axes(ax_h); [xl0,yl0,BUTTON]=ginput(1);
            if BUTTON==3,
                Done=1;
                break;
            end
            
            % For debug - quick marking without zoom (Ram)
            if (0)
                xy=[xy;[xl0, yl0]];
                hold on
                plot(xl0, yl0,'+','MarkerSize',10,'MarkerEdgeColor',Colors(idx_active,:));
                hold off
                continue;
            end
            
            if xl0<=T, xl=[1;2*T+1]; elseif xl0>N-T, xl=[N-2*T;N]; else xl=round([xl0-T;xl0+T]); end
            if yl0<=T, yl=[1;2*T+1]; elseif yl0>M-T, yl=[M-2*T;M]; else yl=round([yl0-T;yl0+T]); end
            
            Id=I(yl(1):yl(2),xl(1):xl(2)); Id=medfilt2(Id,[3 3],'symmetric');
            
            h = figure('Units','centimeters','Position',[5 5 12 12]);
            set(h,'menubar','none','numbertitle','off','name','Choose a point (left click) or close (right click)');
            a_h = axes('Parent',h,'Units','centimeters','Position',[1 1 10 10]);
            axes(a_h); imshow(Id,[]); colormap(hsv);
            
            try %in case you close the window with "X"
                [xp,yp,BUTTON_z]=ginput(1);
                if BUTTON_z==1,
                    xy=[xy;[xp+xl(1)-1 yp+yl(1)-1]];
                    axes(ax_h);
                    hold on
                    %plot(xp+xl(1)-1,yp+yl(1)-1,'+','MarkerSize',10,'Linewidth',2,'MarkerEdgeColor',Colors(idx_active,:));
                    plot(xp+xl(1)-1,yp+yl(1)-1,'+','MarkerSize',10,'MarkerEdgeColor',Colors(idx_active,:));
                    hold off
                end
                close(h);
            end
            
        end
        
    end

% ----------------------------------------------------
% Sliders to adjust contrast
    function slinf_callback(hObject,eventdata)
        val_inf = get(hObject,'Value');
        val_sup = get(slsup_h,'Value');
        if val_inf>=val_sup
            val_inf=val_sup-eps;
            set(hObject,'Value',val_inf);
        end
        caxis(ax_h,[val_inf val_sup]);
    end
    function slsup_callback(hObject,eventdata)
        val_inf = get(slinf_h,'Value');
        val_sup = get(hObject,'Value');
        if val_sup<=val_inf
            val_sup=val_inf+eps;
            set(hObject,'Value',val_sup);
        end
        caxis(ax_h,[val_inf val_sup]);
    end

end
