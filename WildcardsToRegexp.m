function [regexpPattern] = WildcardsToRegexp(patterns, shouldDropEnds)

if (~exist('shouldDropEnds', 'var') || isempty(shouldDropEnds))
    shouldDropEnds = 0;
end

if (iscell(patterns))
    regexpPattern = WildcardsSingleToRegexp(patterns{1});
    for i = 2:numel(patterns)
        regexpPattern = [regexpPattern '|' WildcardsSingleToRegexp(patterns{i})];
    end
else
    regexpPattern = WildcardsSingleToRegexp(patterns);
end

if (~shouldDropEnds)
    regexpPattern = ['^' regexpPattern '$'];
end

    function [regexpPattern] = WildcardsSingleToRegexp(pattern)
        
        pattern = regexprep(pattern, '([.|\(\)\[\]^$\\])', '\\$1');
        [tokens, splitParts] = regexpi(pattern, '([\*\?])', 'tokens', 'split');
        regexpPattern = '';
        
        for i = 1:numel(tokens)
            tok = tokens{i};
            tok = tok{1};
            
            if (strcmp(tok, '*'))
                regexpPattern = [regexpPattern splitParts{i} '.*'];
            elseif (strcmp(tok, '?'))
                regexpPattern = [regexpPattern splitParts{i} '.'];
%             elseif (~isempty(strfind('.|[]()^$\', tok)))
%                 regexpPattern = [regexpPattern splitParts{i} '\' tok];
            else
                error('Bad pattern');
            end
        end
        
        regexpPattern = [regexpPattern splitParts{end}];
    end

end
