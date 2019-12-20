function [avg] = Calibration_AvgOnQConic(img, lambda, p, q)

if (p(3) <= 1)
    avg = 0;
else
    avg = IntegrateQConic(img, lambda, p(1), p(2), p(3), p(4), p(5), q);
end

end
