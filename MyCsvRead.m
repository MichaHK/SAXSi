function [csv] = MyCsvRead(filename)

csv = struct();
f = fopen(filename, 'r');

csv.Error = [];

if (f > 0)
    try
        lines = {};

        line = fgetl(f);
        while ischar(line)
            lines{end + 1} = line;
            line = fgetl(f);
        end
        
        csv.Lines = lines;
        
        %% Represent lines as a cell matrix
        if (~isempty(lines))
            line = lines{1};
            strData = strSplit(line, ',');
            
            for i = 2:numel(lines)
                line = lines{i};
                strData(end+1, :) = strSplit(line, ',');
            end
        end
        csv.Data = strData;
        
        %% Convert numeric data
        numericData = cellfun(@(s)str2double(s), strData);
        csv.NumericData = numericData;

        %% Find numeric columns
        numericColumns = ~isnan(sum(numericData, 1));
        numericColumns = find(numericColumns);
        csv.AllNumericColumns = numericColumns;
        
    catch exception
        csv.Error= exception;
    end
    
    fclose(f);
end

end
