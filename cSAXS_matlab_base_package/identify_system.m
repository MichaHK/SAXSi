%
% Filename: $RCSfile: identify_system.m,v $
%
% $Revision: 1.3 $  $Date: 2010/07/22 15:08:21 $
% $Author: bunk $
% $Tag: $
%
% Description:
% Identify the current system to set useful default parameter values in
% default_parameter_value.m. 
% A modified version of both macros at the beginning of the Matlab search
% path may be used to define local standard parameters. 
%
% Note:
% none
%
% Dependencies:
% none
%
%
% history:
%
% June 2nd 2009, Pierre Thibault, Martin Dierolf, and Oliver Bunk:
% buffer current system ID for later calls to speed up execution
%
% April 16th, 2009, Oliver Bunk: 1st version
%

function [return_system_id_str return_other_system_flags] = identify_system()

persistent system_id_str;
persistent parallel_computing_toolbox_available;

if (isempty(system_id_str))
    % default value
    system_id_str = 'other';

    if (isunix)
        % check for a known network name of the PC Matlab is running on
        [status,hostname] = unix('hostname');
        if (status == 0)
            hostname = sscanf(hostname,'%s');
            if (strcmp(hostname(1:5),'x12sa'))
                system_id_str = 'X12SA';
            else
                switch hostname 
                    case {'pc6024', 'pc5369'}
                        system_id_str = 'DPC lab';
                    case {'mpc1054'}
                        system_id_str = 'mDPC lab';
                    case {'pc5211', 'mpc1144', 'mpc1145'}
                        system_id_str = 'cSAXS-mobile';
                    case {'lccxs01', 'lccxs02', 'mpc1208'}
                        system_id_str = 'CXS compute node';
                end
            end
        end
    else
        % neither Linux nor Mac
        system_id_str = 'Windows';
    end
end

% check for the parallel computing toolbox being available
if (isempty(parallel_computing_toolbox_available))
    parallel_computing_toolbox_available = false;
    
    versions = ver;
    for line = 1:length(versions)
        if strfind(versions(line).Name, 'Parallel Computing Toolbox')
            parallel_computing_toolbox_available = true;
        end
    end
end


% compile return values

return_system_id_str = system_id_str;

return_other_system_flags.parallel_computing_toolbox_available = parallel_computing_toolbox_available;
