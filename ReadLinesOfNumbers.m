function [data] = ReadLinesOfNumbers(file, linesToSkip)

if (nargin < 2)
    linesToSkip = 0;
end

wasOpened = 0;

if (~isscalar(file) && ischar(file))
    file = fopen(file, 'r');
    wasOpened = 1;
end

for i = 1:linesToSkip
    line = fgetl(file);
end

line = fgetl(file);
result  = textscan(line, '%f');

while (numel([result{:}]) == 0)
    line = fgetl(file);
    result  = textscan(line, '%f');
end


data = [result{:}];
allData = textscan(file, '%f');
allData = allData{1};

data = [data(:)'; reshape(allData, numel(data), numel(allData) / numel(data))'];

if (wasOpened)
    fclose(file);
end

end
