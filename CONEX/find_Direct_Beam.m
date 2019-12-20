function [x, y] = find_Direct_Beam(Xd,Yd,beta)
% Converts the beam's position from the coordinate space used by CONEX to
% the image's image coordinates.
%
% Solves XX=YY=0
%         XX=Xd+xy(:,1)*cos(beta)-xy(:,2)*sin(beta);
%         YY=Yd-xy(:,1)*sin(beta)-xy(:,2)*cos(beta);
%        xyc=inv([[-cos(beta) +sin(beta)];[sin(beta) +cos(beta)]])*[Xd;Yd];


%xyc = [[ -cos(b)/cos(2*b), +sin(b)/cos(2*b)];[ sin(b)/cos(2*b), +cos(b)/cos(2*b)]]*[Xd;Yd];
%beta=b;
xy=inv([[-cos(beta) +sin(beta)];[sin(beta) +cos(beta)]])*[Xd;Yd];

if (nargout == 1)
    x = xy;
else
    x = xy(1);
    y = xy(2);
end

end
