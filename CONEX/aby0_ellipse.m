function [a,b,y0,fp,fm,vp,vm]=aby0_ellipse(alpha,theta)

t_a=tan(alpha);
t_qma2=tan((theta-alpha)/2);
t_qpa2=tan((alpha+theta)/2);
c_a=cos(alpha);
s_q=sin(theta);

fp=t_a.*s_q./(c_a+s_q);
fm=t_a.*s_q./(c_a-s_q);

vp=(t_a+(1+t_qma2)./(1-t_qma2)).*s_q./(c_a+s_q);
vm=(t_a+(1-t_qpa2)./(1+t_qpa2)).*s_q./(c_a-s_q);

a=0.5*(vp+vm);
b=0.5*sqrt((vp+vm).^2-(fp+fm).^2);
y0=0.5*(fp-fm);
