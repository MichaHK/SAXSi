function [parts] = strSplit(str, delimiter, shouldTrim)

if (nargin < 3)
    shouldTrim = 0;
end

parts = {};
subStart = [];
subEnd = [];

if (ischar(delimiter))
    delLen = length(delimiter);
    found = strfind(str, delimiter);
    subStart = [1 found + delLen];
    subEnd = [found(1:end)-1 length(str)];
else
    
    delimitersList = delimiter;
    
    found = cellfun(@(d)strfind(str, d), delimiter, 'UniformOutput', 0);
    delLen = arrayfun(@(i)kron(length(delimitersList{i}), ones(1, numel(found{i}))), ...
        1:numel(delimitersList), 'UniformOutput', 0);
    
    found = horzcat(found{:});
    delLen = horzcat(delLen{:});
    
    if (~isempty(found))
        [found, order] = sort(found);
        delLen = delLen(order);
        
        subStart = [1 found+delLen];
        subEnd = [found(1:end)-1 length(str)];
    else
        subStart = 1;
        subEnd = length(str);
    end
end

parts = arrayfun(@(i)str(subStart(i):subEnd(i)), 1:numel(subStart), 'UniformOutput', 0);

if (shouldTrim)
    parts = cellfun(@(s)strtrim(s), parts, 'UniformOutput', 0);
end

% tests
% if (0)
%     [strSplit('', ',')]
%     [strSplit('a,b', ',')]
%     [strSplit('a,', ',')]
%     [strSplit(',b', ',')]
%     [strSplit(',', ',')]
%     [strSplit(',,', ',')]
%     [strSplit(',,,', { ',,', ',' })]
%     [strSplit(',,,', { ',', ',,' })]
% end



