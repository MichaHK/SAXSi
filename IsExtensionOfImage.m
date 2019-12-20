function [result] = IsExtensionOfImage(ext)
[extensions] = GetCommonImageExtensions();

if (ext(1) ~= '.') % is this a full filename?
    [~, ~, ext] = fileparts(ext);
end

switch (lower(ext))
    case extensions
        result = 1;
    otherwise
        result = 0;
end

end
