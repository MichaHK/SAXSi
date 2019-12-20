function [fields, values, structuredData] = P12TextLinesToStruct(lines, shouldConvertNumbers)

if (~exist('shouldConvertNumbers', 'var'))
    shouldConvertNumbers = 0;
end

structuredData = struct();
fields = {};
values = {};

for lineIndex = 1:numel(lines)
    l = lines{lineIndex};

    l = strtrim(l);
    if (1) % Remove "#" from comments
        if (isempty(l))
            continue;
        end
        
        if (l(1) == '#')
            l = strtrim(l(2:end));
        end
    end
    
    lineParts = strsplit(l, ':');
    
    if (numel(lineParts) < 2)
        continue;
    end
    
    if (numel(lineParts) > 2)
        lineParts{2} = strjoin(lineParts(2:end), ':');
    end
    
    fields{end+1} = lineParts{1};
    values{end+1} = strtrim(lineParts{2});
    
    structuredData.(ToIdentifier(fields{end})) = values{end};

    if (shouldConvertNumbers)
        value = values{end};
        
        allFramesStr = ' (all frames)';
        if (length(value) > length(allFramesStr) && strcmp(value(end + 1 - [length(allFramesStr):-1:1]), allFramesStr))
            value = value(1:end+1-length(allFramesStr));
        end
        
        value = str2double(value);
        if (~isnan(value))
            try
                structuredData.(ToIdentifier(fields{end})) = value;
            catch err
                err
            end
        end
    end
end

    function [identifier] = ToIdentifier(identifier)
        if (isempty(identifier))
            return;
        end
        
        identifier = regexprep(identifier, '\s+', '_');
        identifier = regexprep(identifier, '[\[\]/()-\.]', '');

        identifier = regexprep(identifier, '^([^a-zA-Z])', 'Identifier_$1');
    end

end
