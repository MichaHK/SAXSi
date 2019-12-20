
close all hidden;

%clear classes;

c = ConicClass;

%c.SetHyperbola(2, 3, [0 0], 0.4*pi);
c.SetEllipse(2, 3, [0 0], 0.4*pi);
c.DebugPlot();
%c.DebugPlotUsingRandomSolutions();
xlim([-9, 9]);
ylim([-9, 9]);

if (0)
    hold on;
    %[x, y] = c.GetPointsFromParametricForm(linspace(-pi+(i-1)/10*2*pi, -pi+i/10*2*pi, 10));
    [x, y] = c.GetPointsFromParametricForm(linspace(0, 2*pi, 100));
    dx = diff(x);
    dy = diff(y);
    which = (dx .^ 2 + dy .^ 2) < 3;
    which = find(which);
    quiver(x(which), y(which), dx(which), dy(which), 1);
    hold off;
end

r = [-3, -0.5, 9, 1];
[x, y, t, out] = c.GetIntersectionWithRect(r);
hold on;
rectangle('Position', r);
plot(x(out), y(out), '*r');
plot(x(~out), y(~out), '*g');
hold off;
%testSegmentsOfIntegration(c, r, t, out, '*k');

r = [-5, -2, 10, 10];
[x, y, t, out] = c.GetIntersectionWithRect(r);
hold on;
rectangle('Position', r);
plot(x(out), y(out), '*r');
plot(x(~out), y(~out), '*g');
hold off;
%testSegmentsOfIntegration(c, r, t, out, 'og');


r = [-4, -4, 8, 8];
[x, y, t, out] = c.GetIntersectionWithRect(r);
hold on;
rectangle('Position', r);
plot(x(out), y(out), '*r');
plot(x(~out), y(~out), '*g');
hold off;
testSegmentsOfIntegration(c, r, t, out, '*g');


r = [3, -4, 1, 1];
[x, y, t, out] = c.GetIntersectionWithRect(r);
hold on;
rectangle('Position', r);
plot(x(out), y(out), '*r');
plot(x(~out), y(~out), '*g');
hold off;
testSegmentsOfIntegration(c, r, t, out, '+r');

