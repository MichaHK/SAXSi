function [f] = AreFieldsEqual(s1, s2)
f = 1;
fields = fieldnames(s1);
for i = 1:numel(fields)
    if (s1.(fields{i}) ~= s2.(fields{i}))
        f = 0;
        return;
    end
end
end
