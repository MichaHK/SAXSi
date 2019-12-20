function [c,ceq] = ValidConexConicFromPointsNonlinearConstraint(coordinates)
conic = ConicClass();
conic.SetSolutionOf5Points(coordinates(1:2:end), coordinates(2:2:end));
c = conic.GetConicTypeNumeric()  <= 3; % Make sure this is either of: Circle, Ellipse, Hyperbola
ceq = [];
