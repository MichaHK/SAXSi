%DICT  Dictonary data storage.  Stores data by key/value pairs.
% Creates a key/value dictionary similar to the DICT object in Python.
% Keys and values may be any valid Matlab data type.
% 
% Examples:
%   x=dict;          % Create dictionary object
%   x(12)='hello';   % Store value.
%   x('hi')=[1 2 3]; % Store value.
%
%   x('hi')          % Lookup value
%     ans =
%        1 2 3
%
%   x(12)            % Lookup value
%     ans = 
%   hello
%
%   lookup(x,12)     % Lookup value
%     ans = 
%   hello
%
%  Other methods:
%    KEYS    - Returns cell array of all keys.
%    VALUES  - Returns cell array of all values.
%
%    ISEMPTY - Returns true if dictionary is empty.
%    LENGTH  - Returns number of elements stored in dictionary.
%    ISKEY   - Determines if a key exists in dictionary.
%    INDEX   - Returns index of key in key array.
%
%    PLUS    - Combines two dictionaries.
%    MINUS   - Creates dictionary of unique keys.
%    RMKEY   - Removes key/value pair from dictionary.
%
%    RENAME  - Renames a key.
%
% Credits: Inspired by and based on LOOKUPTABLE by Dan Cohn, available on
%          Matlab Central:
%          http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=19381&objectType=file
%

% Written by: Doug Harriman (doug <dot> harriman <at> gmail <dot> com)
% 25-Apr-08 - Added RENAME.
% 20-Apr-08 - '.' access to methods working.  Allethods have help text.
%             Added '+' and '-' methods to composite DICT's.
% 03-Apr-08 - More methods to make more similar to Python dict object.
% 02-Apr-08 - Initial version.

classdef dict < handle

    properties (SetAccess=protected)
    
        % Cell arrays to hold keys and values of any Matlab data type
        key   = {};
        value = {};
        
    end % properties - protected
    
    methods 

        % Was called "subsref". But this really slows things down. Ram
        % Avinery.
        function val = subsref_decomissioned(obj,ref)
            %DICT/SUBSREF Subscript referencing for DICT objects.
            %  
            %  See also: DICT
            %

            % Re-implement dot referencing.
            if strcmp(ref(1).type,'.')
                % User trying to access a property or method.
                
                % Property access
                props = fieldnames(struct(obj));
                if ismember(ref(1).subs,props)
                   val = obj.(ref.subs);
                   return;
                end
               
                % Methods access
                if ismember(ref(1).subs,methods(obj))
                    if length(ref) > 1
                        % Call with args
                        val = obj.(ref(1).subs)(ref(2).subs{:});
                    else
                        % No args
                        val = obj.(ref.subs);
                    end
                    return;
                end
                
                % User trying to access something else.
                error(['Reference to non-existant property or method ''' ref.subs '''']);
            end
            
            if ~strcmp(ref.type,'()')
                error('Cell indexing not supported.');
            end

            % Vectorized calls not supported
            if length(ref.subs) > 1
                error('DICT only supports storing key/value pairs one at a time.');
            end
            key = ref.subs{1};

            val = lookup(obj,key);
            
        end % subsref
        
        
        function obj = subsasgn(obj,ref,value)
            %DICT/SUBSASGN  Subscript assignment for DICT objects.
            %
            %  See also: DICT
            %
            
            if ~strcmp(ref.type,'()')
                error('Cell and dot indexing for assignment not supported.');
            end
            
            % Vectorized calls not supported
            if length(ref.subs) > 1
                error('DICT only supports storing key/value pairs one at a time.');
            end
            key = ref.subs{1};

            % Existing or new key?
            idx = index(obj,key);
            if isempty(idx)
                % New
                idx = length(obj.key) + 1;
            end

            obj.key{idx}   = key;
            obj.value{idx} = value;

        end % subsasgn
        
        
        function val = length(obj)
            %DICT/LENGTH  Number of key/value pairs in dictionary.
            %
            %  See also: DICT
            %
            
            val = length(obj.key);
        end
        
        
        function idx = index(obj,key)
            %DICT/INDEX  Find index of a key in the dictionary key array.
            %
            %  See also: DICT
            %
            
            idx = cellfun(@(x)isequal(x,key),obj.key);
            idx = find(idx);
        end % index
        
        
        function [] = disp(obj)
            %DICT/DISP  Display a DICT object.
            %  
            %  See also: DICT
            %
            
            disp(' Dictionary:');
            disp(struct(obj));
        end % disp
        
        
        % DISPLAY 
        function [] = display(obj)
            %DICT/DISPLAY  Display a DICT object.
            %  
            %  See also: DICT
            %
            disp(obj);
        end
        
        
        function val = lookup(obj,key)
            %DICT/LOOKUP  Return a value given a key.
            %
            %  See also: DICT, DICT/INDEX
            %

            % Make sure key exists
            idx = index(obj,key);
            if isempty(idx)
                val = [];
                return;
            end
            
            % Extract value
            val = obj.value(idx);
            val = val{1};
        end

        
        function data = keys(obj)
            %DICT/KEYS  Returns cell array of all keys in a DICT object.
            %
            %  See also: DICT, DICT/VALUES
            %
            
            data = obj.key';
        end % keys

        
        function data = values(obj)
            %DICT\VALUES  Returns cell array of all values in a DICT object.
            %
            %  See also: DICT, DICT/KEYS
            %
            
            data = obj.value';
        end % values

        
        function tf = iskey(obj,keys)
            %DICT/ISKEY  Returns bool array denoting if key(s) exist in dictionary.
            %
            %  See also: DICT, DICT/KEYS
            %
            
            if ~iscell(keys)
                keys = {keys};
            end
            nkeys = length(keys);
            tf    = false(nkeys,1);
            for i = 1:nkeys
                key = keys{i};
                tf(i) = any(cellfun(@(x)isequal(x,key),obj.key));
            end
        end % iskey
        
        
        function obj = rmkey(obj,key)
            %DICT/RMKEY  Removes a key/value pair from a dictionary by key.
            %
            %  See also: DICT, DICT/ISKEY
            % 
            
            idx = index(obj,key);
            obj.key(idx)   = [];
            obj.value(idx) = [];
            
            % Make the display look nice
            if isempty(obj.key)
                obj.key   = {};
                obj.value = {};
            end
        end % rmkey

        
        function tf = isempty(obj)
            %DICT/ISEMPTY  Returns true if dictionary isempty.
            %
            %  See also: DICT, DICT/KEYS
            %
            
            tf = isempty(obj.key);
        end % isempty
        
        
        function obj1 = plus(obj1,obj2)
            %DICT/PLUS  Creates composite dictionary.
            %  DICT1+DICT2 returns a dictionary composed of key value pairs
            %  from both DICT1 and DICT2.  If both dictionaries contain the
            %  same key, the value stored in DIC1 will be used.
            %
            %  See also: DICT, DICT/MINUS, DICT/KEYS, DICT/ISKEY
            %
            
            % Error check inputs
            error(nargchk(2,2,nargin));
            if ~isa(obj2,'dict')
                error('Both inputs must be DICT objects.');
            end
            
            % Look for key collisions
            idx = obj1.iskey(obj2.keys);
            
            % Tack on unique keys and values to x.
            obj1.key   = {obj1.key{:} obj2.key{~idx}};
            obj1.value = {obj1.value{:} obj2.value{~idx}};
            
        end % plus

        
        function obj1 = minus(obj1,obj2)
            %DICT/MINUS  Creates dictionary of unique keys.
            %  DICT1-DICT2 returns a dictionary composed of key value pairs
            %  which have keys that only exist in DICT1.
            %
            %  See also: DICT, DICT/PLUS, DICT/KEYS, DICT/ISKEY
            %

            % Error check inputs
            error(nargchk(2,2,nargin));
            if ~isa(obj2,'dict')
                error('Both inputs must be DICT objects.');
            end
            
            % Look for key collisions
            idx = ~obj2.iskey(obj1.keys);
            
            % Tack on unique keys and values to x.
            obj1.key   = obj1.key(idx);
            obj1.value = obj1.value(idx);

        end % minus

        function obj = rename(obj,key_old,key_new)
            %DICT/RENAME  Renames a key.
            %  RENAME(DICT,KEY_OLD,KEY_NEW) 
            %
            %  See also: DICT, DICT/ISKEY
            % 
            
            idx = index(obj,key_old);

            if isempty(idx)
                return;
            end
               
            obj.key{idx} = key_new;
            
        end % rename

        
    end % methods
    
end % classdef 

