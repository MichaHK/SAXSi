function [varargout] = accumarrayMultiFun(subs, val, sz, varargin)

for i = 1:numel(varargin)
    varargout{i} = accumarray(subs, val, sz, varargin{i});
end

end
