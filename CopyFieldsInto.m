function [s] = CopyFieldsInto(s, from)
fields = fieldnames(from);
for i = 1:numel(fields)
    s.(fields{i}) = from.(fields{i});
end
end
