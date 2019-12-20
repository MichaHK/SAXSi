function [updateFunc] = UIBindNumFieldToStringProperty(uiObj, obj, fieldName, formattingFunc, chainedUIHandler)

if (nargin)
    chainedUIHandler = [];
end

set(uiObj, 'UserData', struct('Object', obj, 'FieldName', fieldName, 'ChainedUIHandler', chainedUIHandler));
set(uiObj, 'Callback', @HandleUIUpdate);

updateFunc = @HandleUpdateFromObject;

    function HandleUpdateFromObject(hObject) % Intended to be called as part of an update to all UI fields
        ud = get(hObject, 'UserData');
        
        o = ud.Object;
        set(hObject, 'String', formattingFunc(o.(ud.FieldName)));
    end

    function HandleUIUpdate(hObject, eventData, handles) % Intended to handle something like an editbox callback
        ud = get(hObject, 'UserData');
        o = ud.Object;
        o.(ud.FieldName) = str2double(get(hObject, 'String'));
        
        if (~isempty(ud.ChainedUIHandler))
            ud.ChainedUIHandler(hObject, eventData, handles);
        end
    end

end
