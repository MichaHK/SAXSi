function [f] = WithinRect(rect, x, y)
% WithinRect(rect, x, y)
% 
% "rect" should be [x0, y0, width, height]

f = (x >= rect(1) & x <= (rect(1) + rect(3)) & y >= rect(2) & y <= (rect(2) + rect(4)));
end
