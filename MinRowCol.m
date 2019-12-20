function [value, row, col] = MinRowCol(A)

[rowValues, row] = min(A, [], 1);
[value, col] = min(rowValues);
row = row(col);

end