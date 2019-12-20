function [result] = IsExtensionOf1dCurve(ext)

validExtensions = {'.dat', '.chi', '.fsi', '.fsx'};

if (ext(1) ~= '.') % is this a full filename?
    [~, ~, ext] = fileparts(ext);
end

if (nargin == 0)
    result = validExtensions;
    return;
end

switch (lower(ext))
    case validExtensions
        result = 1;
    otherwise
        result = 0;
end

end
