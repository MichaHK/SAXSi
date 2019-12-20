% this script contains the necessary loop for 'find_capillary.m' to be called
%    as function of 'spec'
% written by Andreas Menzel (last change: 2011-06-16)
%    in case of bugs, problems, and suggestions for improvements, please contact
%    andreas.menzel@psi.ch
%
% note that EPICS communication works only on local machines at the beamline, i.e.,
%    NOT on the compute nodes
% run this (or related scripts that use EPICS for communication), for instance, on
%    x12sa-cons-1

lastscan = 0;

while(1)
    scall = sprintf('caget ''X12SA-ES1-DOUBLE-00''');
    [err,io] = system(scall);
    arrout = regexp(io,' +','split');
    scannr = str2double(arrout{2});
    if (scannr > lastscan)
        COM = find_capillary('..','ScanNr',scannr,'Counter','diode')
    else
        pause(1);
    end
    scall = sprintf('caputq X12SA-ES1-DOUBLE-02 %f',COM);
    [err,io] = system(scall);
    scall = sprintf('caputq X12SA-ES1-DOUBLE-01 %d',scannr);
    [err,io] = system(scall);
    lastscan = scannr;
end
