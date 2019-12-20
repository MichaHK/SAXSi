function Out = readitAxes(curves, DisplayOptions, CalibrationData, In, xFieldName)

persistent previouslyClickedLineHandle;
defaultLineWidth = 2;

if (~exist('xFieldName', 'var') || isempty(xFieldName))
    xFieldName = 'Q';
end

% Get the converter for the selected Q-scale display
% The converter is a function of the original q-scale.
[QScaleConversion, QScaleDescription] = GetQScaleConversion(DisplayOptions, CalibrationData);
[IScaleConversion, IScaleDescription] = GetIScaleConversion(DisplayOptions, CalibrationData);

% tic
try
    fid = In.fid;
    axes(fid);
    
    notfirst = In.notfirst;
    Out.v = [get(fid,'xlim'), get(fid,'ylim')];
    
    lengthOfEachCurve = cellfun ('length', {curves.(xFieldName)});
    [maxlen, maxindex] = max(lengthOfEachCurve);
%     whichZeroLengthCurves = find(lengthOfEachCurve == 0);
    
    if (maxlen == 0)
        return;
    end
    
%     for i = whichZeroLengthCurves
%         curves(i).(xFieldName) = curves(maxindex).(xFieldName);
%         curves(i).I = 0 .* curves(i).(xFieldName);
%         curves(i).IErr = 0 .* curves(i).(xFieldName);
%     end
    
    numOfCurves = numel(curves);
 
    % Handle background subtraction
    if (~isempty(In.backgroundCurve))        
        for i = 1:numOfCurves
            curves(i).I = curves(i).I - interp1(In.backgroundCurve.Q, In.backgroundCurve.I, curves(i).Q);
        end
    end
    
    %% Actual plotting
    hold(fid, 'off');
    %plot (fid,1:2,1:2);
    
    % Use the default colormap (manually)
    plot([0, 1], [1 1]);
    colorMap = get(gca,'ColorOrder');
    cla;
    hold(fid, 'on');
    
    %Out.ColorMap = gray(16 + 4);
    %Out.ColorMap(end-3:end, :) = [];
    Out.ColorMap = colorMap;
    %Out.ColorMap = lines(16);
    Out.X = cellfun(QScaleConversion, {curves.(xFieldName)}, 'UniformOutput', 0);
    Out.Y = cellfun(IScaleConversion, {curves.I}, 'UniformOutput', 0);
    %Out.Y = {curves.I};
    % For the log scale. Avoid zeros.
    Out.Y = cellfun(@(y)y + (y == 0) .* 1e-5, Out.Y, 'UniformOutput', 0);
    Out.YErr = {curves.IErr};
    
    %% Handle curve spreading
    if (numOfCurves > 1 && In.SP > 1)
        switch(In.SP)
            case 2
                [Out.Y Out.YErr] = SpreadCurvesMultiplicatively(Out.X, Out.Y, Out.YErr, In.diff);
            case 3
                Out.Y = SpreadCurvesAdditively(Out.X, Out.Y, In.diff);
        case 4
            [Out.Y Out.YErr] = SpreadCurvesMultiplicatively(Out.X, Out.Y, Out.YErr, In.diff, 1);
        case 5
            Out.Y = SpreadCurvesAdditively(Out.X, Out.Y, In.diff, 1);
        case 6
            Out.Y = ScaleCurves(Out.X, Out.Y, Out.YErr, DisplayOptions.CurveScalingRegion);
        end
    end
    
    %% Plot the curves
    if (DisplayOptions.DisplayErrorBars)
        errorBarWidth = min(diff(Out.X{1})) * 0.5;

        for i = 1:numel(Out.X)
            colorIndex = 1 + mod(i-1, size(Out.ColorMap, 1));
            h = errorbar(fid, Out.X{i}, Out.Y{i}, Out.YErr{i}, 'Color', Out.ColorMap(colorIndex, :), 'LineWidth', 2); % , 'LineWidth', defaultLineWidth
            %errorbar_tick(h, errorBarWidth, 'units');
        end
    else
        for i = 1:numel(Out.X)
            colorIndex = 1 + mod(i-1, size(Out.ColorMap, 1));
            
            if (0) % Show a smoothed version of the signal?
                %[smoothCurve, goodness, output] = fit(Out.X{i}, Out.Y{i}, 'smoothingspline', 'SmoothingParam', 0.99993);
                [smoothCurve, goodness, output] = fit(Out.X{i}, Out.Y{i}, 'smoothingspline', 'SmoothingParam', 0.9999999999);
                plot(fid, Out.X{i}, feval(smoothCurve, Out.X{i}), 'Color', Out.ColorMap(colorIndex, :), 'LineWidth', 2);
            else
                h = plot(fid, Out.X{i}, Out.Y{i}, 'Color', Out.ColorMap(colorIndex, :), 'LineWidth', defaultLineWidth);
                set(h, 'ButtonDownFcn', @HandleLineClick);
                1;
            end
        end
    end
    
    
    if (1)
        minY = min(cellfun(@min, Out.Y));
        maxY = max(cellfun(@max, Out.Y));
        
        handles = guidata(fid);
        
        if (strcmp(xFieldName, 'Q'))
            
            %% Plot Q-marks
            hold(fid, 'on');
            
            qMarks = handles.State.QMarks;
            
            minQ = min(cellfun(@min, Out.X));
            maxQ = max(cellfun(@max, Out.X));
            
            for i = 1:length(qMarks)
                q = qMarks{i}.Q;
                if (qMarks{i}.Visible && q >= minQ && q <= maxQ)
                    plot([q q], [minY maxY], 'Color', qMarks{i}.Color, 'LineWidth', qMarks{i}.Width, 'LineStyle', qMarks{i}.LineStyle);
                    
                    derivedQs = qMarks{i}.Series * q;
                    derivedQs(derivedQs < minQ) = [];
                    derivedQs(derivedQs > maxQ) = [];
                    % Draw the chosen series as well
                    for q = derivedQs
                        plot([q q], [minY maxY], 'Color', qMarks{i}.Color, 'LineWidth', qMarks{i}.Width, 'LineStyle', qMarks{i}.LineStyle);
                    end
                end
            end
        end
        
    end
    
    hold(fid, 'off');
    
    
    %% Legend, Scale
    
    legend(fid, In.DisplayedLabels, 'Interpreter', 'none');
    
    %xlabel(fid,'q(Å^{-1})');ylabel(fid,'I(a.u.)');
    xlabel(fid, QScaleDescription);
    ylabel(fid,'I(a.u.)');
    
    displayXLogarithmic = DisplayOptions.DisplayXLogarithmic(DisplayOptions.CurrentPlotType);
    displayYLogarithmic = DisplayOptions.DisplayYLogarithmic(DisplayOptions.CurrentPlotType);

    if (1)
        linlogStrings = {'linear', 'log'};
        set(fid, 'XScale', linlogStrings{displayXLogarithmic + 1});
        set(fid, 'YScale', linlogStrings{displayYLogarithmic + 1});
    else
        % TODO: Implement log-plot manually. For some reason zoom in
        % log-plot works horribly
    end
    
    if notfirst
        axis(fid, Out.v);
    else
        %axis(fid, 'tight');
        axis(fid, 'fill');
    end
    
    Out.xl = get(fid, 'XScale');
    Out.yl = get(fid, 'YScale');
    Out.DisplayedLabels = In.DisplayedLabels;
    
catch exception
    disp('could not plot...');
    disp(exception);
end

% toc
% disp('ploting in figure');
%title (In.filter);
% Out.fid=fid;
% Out.diff=In.diff;
% Out.filter=In.filter;

    function HandleLineClick(linePlot, eventdata, handles)
        if (ishandle(previouslyClickedLineHandle))
            previouslyClickedLineHandle.LineWidth = defaultLineWidth;
        end
        
        if (isempty(previouslyClickedLineHandle) || previouslyClickedLineHandle ~= linePlot)
            previouslyClickedLineHandle = linePlot;
            linePlot.LineWidth = defaultLineWidth * 2;
            %linePlot.Color = rand(1,3);
        else
            previouslyClickedLineHandle = [];
        end
    end
end
