function [data] = ReadLinesOfXNumbers(file, numberOfNumbersInLine, linesToSkip)
% This function reads lines of X numbers from a file. It skips any line
% that does not parse into X numbers, then parses lines of X numbers and
% then stops at the first line that is not X numbers
%
% If the second argument is empty or zero, then the number X is taken as
% the number of numbers in the first line encountered which has only
% numbers
%

if (nargin < 2)
    linesToSkip = 0;
end

wasOpened = 0;

if (~isscalar(file) && ischar(file))
    file = fopen(file, 'r');
    wasOpened = 1;
end

try
    
    for i = 1:linesToSkip
        line = fgetl(file);
    end
    
    line = fgetl(file);
    while (isempty(line))
        line = fgetl(file);
    end
    
    data = [];
    
    if (isempty(numberOfNumbersInLine) || numberOfNumbersInLine == 0)
        result  = sscanf(line, '%f');
        while (numel(result) == 0)
            line = fgetl(file);
            
            if (isempty(line))
                continue;
            end
            
            if (line == -1)
                break;
            end
            
            result  = sscanf(line, '%f');
        end
        
        if (numel(result) ~= 0)
            data(1, :) = result(:);
            numberOfNumbersInLine = numel(result);
        end
    end
    
    result  = sscanf(line, '%f');
    while (numel(result) == numberOfNumbersInLine)
        data(end+1, :) = result;
        line = fgetl(file);
        
        if (isempty(line) || (isscalar(line) && line == -1))
            break;
        end
        
        result  = sscanf(line, '%f');
    end
    
catch err
    display(err);
end

if (wasOpened) % Did this function open the file? if so, close it
    fclose(file);
end

end
