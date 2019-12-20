function [a,b,y0]=aby0_hyperbola(alpha,theta)

t_a=tan(alpha);
t_qma=tan(theta-alpha);

c_a=cos(alpha);
s_a=sin(alpha);
s_q=sin(theta);

f=t_a.*s_q./(c_a+s_q);
v=(t_a+t_qma);
d=s_q.*(1+s_q.*c_a)./((s_q+c_a).*c_a.*s_a);

e=(v-f)./(d-v);

a=e.*(d-f)./(e.^2-1);
b=e.*(d-f)./(e.^2-1).^0.5;
y0=f+a.*e;
