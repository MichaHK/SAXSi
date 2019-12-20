%
% Filename: $RCSfile: identify_eaccount.m,v $
%
% $Revision: 1.1 $  $Date: 2010/04/28 18:00:56 $
% $Author: bunk $
% $Tag: $
%
% Description:
% Return the current e-account user name in case this function is executed
% at the X12SA beamline, [] otherwise. 
%
% Note:
% none
%
% Dependencies:
% identify_system.m
%
%
% history:
%
% April 28th, 2010, Oliver Bunk: 1st version
%

function [return_user_name] = identify_eaccount()

persistent user_name;

if (isempty(user_name))
    user_name = [];
    % at the cSAXS beamline return the name of the current user as
    % e-account name
    sys_id = identify_system();
    if (strcmp(sys_id,'X12SA'))
        [st,un] = system('echo $USER');
        if ((st == 0) && (length(un) > 1))
            user_name = un(1:end-1);
        end
    end
end

return_user_name = user_name;
