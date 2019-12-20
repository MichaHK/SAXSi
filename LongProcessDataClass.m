classdef LongProcessDataClass < handle
    
    properties
        TextFormat;
        TotalSteps;
        StepsDone;
        TimeStarted;
        TimeEnded;
        DialogHandle;

        ShouldCancel = 0;
        PercentageDone;
        EstimatedTimeLeft
    end
    
end
