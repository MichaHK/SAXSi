function [representativeWL, CuKa1WL, CuKa2WL, CuKa1Energy, CuKa2Energy] = CopperKAlpha()

% http://cxro.lbl.gov/x-ray-data-booklet
% http://xdb.lbl.gov/
% http://physics.nist.gov/cuu/Constants/


% Values used from:
% "X-ray transition energies: new approach to a comprehensive evaluation", Rev. Mod. Phys. 75, 35–99 (2003) 

CuKa1Energy = 8047.8227; % ev
CuKa2Energy = 8027.8416; % ev

%CuKa1WL = 1.54060; % Å
%CuKa2WL = 1.54443; % Å

CuKa1WL = 12398.41857 / CuKa1Energy;
CuKa2WL = 12398.41857 / CuKa2Energy;

representativeWL = (CuKa1WL + CuKa2WL * 2) / 3;

end
