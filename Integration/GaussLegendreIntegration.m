function I = GaussLegendreIntegration(f,a,b,N,varargin)
%GaussLegendreIntegration integration of f over [a,b] with N grid points
%
% From "Applied Numerical Methods Using MATLAB by Won Y. Yang"

% Note from the book: "Never try N larger than 25"... ?? Could be because
% of concern for growing numerical errors?...

[t,w] = GaussLegendreNodesAndWeights(N);
x = ((b - a)*t + a + b)/2; %Eq.(5.9.9)
fx = feval(f,x,varargin{:});
I = w*fx'*(b - a)/2; %Eq.(5.9.10)
