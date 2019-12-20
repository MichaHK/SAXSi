function [value, row, col] = MaxRowCol(A)

[rowValues, row] = max(A, [], 1);
[value, col] = max(rowValues);
row = row(col);

end
