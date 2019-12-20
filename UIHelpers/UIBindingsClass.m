classdef UIBindingsClass < handle
    
    properties
        UIObjects = {};
        DataObjects = {};
        UpdateFunctions = {};
    end
    
    properties(Hidden, Access = private)

    end
    
    methods
        
        function [] = UpdateAllRegisteredFields(self)
            %%
            for i = 1:numel(self.UIObjects)
                updateFunc = self.UpdateFunctions{i};
                uiObj = self.UIObjects{i};
                
                updateFunc(uiObj);
            end
        end
        
        function [updateFunc] = BindNumFieldToStringProperty(self, uiObj, dataObj, fieldName, formattingFunc, chainedUIHandler)
            
            if (~exist('chainedUIHandler', 'var'))
                previousCallback = get(uiObj, 'Callback');
                if (~isempty(previousCallback))
                    chainedUIHandler = previousCallback;
                else
                    chainedUIHandler = @()1;
                end
            end
            
            if (~exist('formattingFunc', 'var'))
                formattingFunc = @(x)num2str(x);
            end
            
            updateFunc = @HandleUpdateFromObject;

            self.UIObjects{end+1} = uiObj;
            self.DataObjects{end+1} = dataObj;
            self.UpdateFunctions{end+1} = updateFunc;
            
            set(uiObj, 'UserData', struct('Object', dataObj, 'FieldName', fieldName, 'ChainedUIHandler', chainedUIHandler));
            set(uiObj, 'Callback', @HandleUIUpdate);
            
            
            function HandleUpdateFromObject(hObject) % Intended to be called as part of an update to all UI fields
                ud = get(hObject, 'UserData');
                
                o = ud.Object;
                set(hObject, 'String', formattingFunc(o.(ud.FieldName)));
            end
            
            function HandleUIUpdate(hObject, eventData) % Intended to handle something like an editbox callback
                ud = get(hObject, 'UserData');
                o = ud.Object;
                o.(ud.FieldName) = str2double(get(hObject, 'String'));
                
                if (~isempty(ud.ChainedUIHandler))
                    ud.ChainedUIHandler(hObject, eventData);
                end
                
                if (~isempty(self.DataObjectUpdateCallback))
                    self.DataObjectUpdateCallback(o, self.DataObjectUpdateContext);
                end
            end
            
        end
        
        function [updateFunc] = BindNumFieldToDropdown(self, uiObj, dataObj, fieldName, formattingFunc, chainedUIHandler)
            
            if (~exist('chainedUIHandler', 'var'))
                previousCallback = get(uiObj, 'Callback');
                if (~isempty(previousCallback))
                    chainedUIHandler = previousCallback;
                else
                    chainedUIHandler = @()1;
                end
            end
            
            if (~exist('formattingFunc', 'var'))
                formattingFunc = @(x)num2str(x);
            end
            
            updateFunc = @HandleUpdateFromObject;

            self.UIObjects{end+1} = uiObj;
            self.DataObjects{end+1} = dataObj;
            self.UpdateFunctions{end+1} = updateFunc;
            
            set(uiObj, 'UserData', struct('Object', dataObj, 'FieldName', fieldName, 'ChainedUIHandler', chainedUIHandler));
            set(uiObj, 'Callback', @HandleUIUpdate);
            
            
            function HandleUpdateFromObject(hObject) % Intended to be called as part of an update to all UI fields
                ud = get(hObject, 'UserData');
                o = ud.Object;
                
                strings = get(hObject, 'String');
                numericValues = cellfun(@str2double, strings);
                selectedIndex = find(numericValues == o.(ud.FieldName));
                
                if (~isempty(selectedIndex))
                    set(hObject, 'Value', selectedIndex(1));
                else
                    set(hObject, 'Value', 1);
                end
            end
            
            function HandleUIUpdate(hObject, eventData) % Intended to handle something like an editbox callback
                ud = get(hObject, 'UserData');
                o = ud.Object;

                strings = get(hObject, 'String');
                selectedIndex = get(hObject, 'Value');
                o.(ud.FieldName) = str2double(strings{selectedIndex});
                
                if (~isempty(ud.ChainedUIHandler))
                    ud.ChainedUIHandler(hObject, eventData);
                end
            end
            
        end
        
        function [updateFunc] = BindNumFieldToDropdownIndex(self, uiObj, dataObj, fieldName, chainedUIHandler)
            
            if (~exist('chainedUIHandler', 'var'))
                previousCallback = get(uiObj, 'Callback');
                if (~isempty(previousCallback))
                    chainedUIHandler = previousCallback;
                else
                    chainedUIHandler = @()1;
                end
            end
            
            updateFunc = @HandleUpdateFromObject;

            self.UIObjects{end+1} = uiObj;
            self.DataObjects{end+1} = dataObj;
            self.UpdateFunctions{end+1} = updateFunc;
            
            set(uiObj, 'UserData', struct('Object', dataObj, 'FieldName', fieldName, 'ChainedUIHandler', chainedUIHandler));
            set(uiObj, 'Callback', @HandleUIUpdate);
            
            
            function HandleUpdateFromObject(hObject) % Intended to be called as part of an update to all UI fields
                ud = get(hObject, 'UserData');
                o = ud.Object;
                
                strings = get(hObject, 'String');
                selectedIndex = o.(ud.FieldName);
                
                if (~isempty(selectedIndex) && selectedIndex(1) >= 1 && selectedIndex(1) < numel(strings))
                    set(hObject, 'Value', selectedIndex(1));
                else
                    set(hObject, 'Value', 1);
                end
            end
            
            function HandleUIUpdate(hObject, eventData) % Intended to handle something like an editbox callback
                ud = get(hObject, 'UserData');
                o = ud.Object;

                selectedIndex = get(hObject, 'Value');
                o.(ud.FieldName) = selectedIndex;
                
                if (~isempty(ud.ChainedUIHandler))
                    ud.ChainedUIHandler(hObject, eventData);
                end
            end
            
        end
        
        function [] = BindOneWayDropdownIndexToField(self, uiObj, dataObj, fieldName, valueTranslationFunc, chainedUIHandler)
            
            if (~exist('chainedUIHandler', 'var'))
                previousCallback = get(uiObj, 'Callback');
                if (~isempty(previousCallback))
                    chainedUIHandler = previousCallback;
                else
                    chainedUIHandler = @()1;
                end
            end
            
            if (~exist('valueTranslationFunc', 'var'))
                valueTranslationFunc = @(x)x;
            end
            
            self.UIObjects{end+1} = uiObj;
            self.DataObjects{end+1} = dataObj;
            self.UpdateFunctions{end+1} = @(x)1;
            
            set(uiObj, 'UserData', struct('Object', dataObj, 'FieldName', fieldName, ...
                'ValueTranslationFunc', valueTranslationFunc, 'ChainedUIHandler', chainedUIHandler));
            set(uiObj, 'Callback', @HandleUIUpdate);
            
            
            function HandleUIUpdate(hObject, eventData) % Intended to handle something like an editbox callback
                ud = get(hObject, 'UserData');
                o = ud.Object;

                selectedIndex = get(hObject, 'Value');
                o.(ud.FieldName) = ud.ValueTranslationFunc(selectedIndex);
                
                if (~isempty(ud.ChainedUIHandler))
                    ud.ChainedUIHandler(hObject, eventData);
                end
            end
            
        end
        
        function [updateFunc] = BindStringFieldToDropdown(self, uiObj, dataObj, fieldName, chainedUIHandler)
            
            if (~exist('chainedUIHandler', 'var'))
                previousCallback = get(uiObj, 'Callback');
                if (~isempty(previousCallback))
                    chainedUIHandler = previousCallback;
                else
                    chainedUIHandler = @()1;
                end
            end
            
            updateFunc = @HandleUpdateFromObject;

            self.UIObjects{end+1} = uiObj;
            self.DataObjects{end+1} = dataObj;
            self.UpdateFunctions{end+1} = updateFunc;
            
            set(uiObj, 'UserData', struct('Object', dataObj, 'FieldName', fieldName, 'ChainedUIHandler', chainedUIHandler));
            set(uiObj, 'Callback', @HandleUIUpdate);
            
            
            function HandleUpdateFromObject(hObject) % Intended to be called as part of an update to all UI fields
                ud = get(hObject, 'UserData');
                o = ud.Object;
                
                strings = get(hObject, 'String');
                value = o.(ud.FieldName);
                selectedIndex = find(cellfun(@(x)strcmp(x, value), strings));
                
                if (~isempty(selectedIndex))
                    set(hObject, 'Value', selectedIndex(1));
                else
                    set(hObject, 'Value', 1);
                end
            end
            
            function HandleUIUpdate(hObject, eventData) % Intended to handle something like an editbox callback
                ud = get(hObject, 'UserData');
                o = ud.Object;

                strings = get(hObject, 'String');
                selectedIndex = get(hObject, 'Value');
                o.(ud.FieldName) = strings{selectedIndex};
                
                if (~isempty(ud.ChainedUIHandler))
                    ud.ChainedUIHandler(hObject, eventData);
                end
            end
            
        end
        
        
    end
    
end
