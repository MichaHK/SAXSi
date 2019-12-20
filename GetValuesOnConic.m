function [values, unitedX, unitedY] = GetValuesOnConic(image, conic, N)

if (isa(conic, 'double'))
    qf = conic(:);
    assert(numel(qf) == 6, '''conic'' parameter should have 6 values');
    
    conic = ConicClass();
    conic.SetQuadraticForm(qf);
elseif (isa(conic, 'ConicClass'))
else
    error('Unhandled type for the ''conic'' parameter');
end

values = [];

imageSize=size(image);

[segments, segmentsSum] = conic.GetSegmentsWithinRect([1,1,imageSize(2)-1,imageSize(1)-1]);
segmentsLengths = diff(segments, 1, 2);

unitedValues = [];
unitedX = [];
unitedY = [];

for segIdx = 1:size(segments, 1)
    portion = segmentsLengths(segIdx) / segmentsSum;
    [x, y] = conic.GetPointsFromParametricForm(...
        linspace(segments(segIdx, 1), segments(segIdx, 2), ...
        floor(portion * N)));
    
    if (~isreal(x) || ~isreal(y))
        % TODO: Add a property to the class that checks validity for
        % getting points
        values = [];
        return;
    end
    
    % TODO: To avoid NaN values, expand the image to [0..W+1] x [0..H+1]
    
    values = interp2(image, x, y);
    %unitedValues = [unitedValues values(~isnan(values))];
    unitedValues = [unitedValues values];
    unitedX = [unitedX, x];
    unitedY = [unitedY, y];
end

values = unitedValues;
