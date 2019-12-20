function [result] = LongProcess(phase, totalSteps, nameOfSteps)
% TODO: This isn't finished yet!!!
%
% Usage:
% [handle] = LongProcess('Start', totalNumberOfSteps, nameOfSteps)
% [shouldContinue] = LongProcess('Step', numberOfStepsDone)
% [shouldContinue] = LongProcess('Step', numberOfStepsDone, totalNumberOfSteps)
% [] = LongProcess('End')
%

result = [];

persistent lp;

switch (phase)
    case 'Start'
        result = LongProcessStarted(totalSteps, nameOfSteps);
    case 'End'
        LongProcessEnded(lp);
    case 'Step'
        LongProcessStep(stepsDone, totalSteps);
end


function LongProcessStarted(totalSteps, nameOfSteps)
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



function LongProcessEnded()
lp.TimeEnded = toc(lp.TimeStarted);

if (~isempty(lp.DialogHandle))
    delete(lp.DialogHandle);
    lp.DialogHandle = [];
end

function [shouldContinue] = LongProcessStep(stepsDone, totalSteps)
shouldContinue = 1;
tElapsed = toc(lp.TimeStarted);

if (~exist('stepsDone', 'var') || isempty(stepsDone))
    stepsDone = lp.StepsDone + 1;
end

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

