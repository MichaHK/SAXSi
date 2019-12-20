function [xd,yd]=find_Direct_Beam_conX(X,Y,beta)
% Converts the beam's position on the image coordinates to the coordinate
% space used by CONEX.
%
% Solves XX=YY=0
%         XX=Xd+xy(:,1)*cos(beta)-xy(:,2)*sin(beta);
%         YY=Yd-xy(:,1)*sin(beta)-xy(:,2)*cos(beta);
%    


xyD=[-cos(beta), sin(beta);sin(beta), +cos(beta)]*[X;Y];
xd=xyD(1);yd=xyD(2);
end