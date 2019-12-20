function add_lines_to_graph(theta,parameters,axes_handle,linetype,linecolor)

addpath('Conic');

alpha0=parameters(1);
d0=parameters(2);
Xd0=parameters(3);
Yd0=parameters(4);
beta0=parameters(5);

% Rotation matrix
c=cos(beta0); s=sin(beta0);
RotBetaAndFlipY = [[c -s];[-s -c]]; % This is a rotation + flipping of "y" sign

theta_lim=pi/2-alpha0;

idx_1=find(theta<(theta_lim-0.0005));
idx_2=find(theta>(theta_lim+0.0005));

q=(0:0.0005:1)*2*pi; c=cos(q); s=sin(q);

for i=1:length(idx_1)
    [a,b,Y0]=aby0_ellipse(alpha0,theta(idx_1(i)));
    a2=(a*d0)^2; b2=(b*d0)^2; Y0=Y0*d0;

    % This is of the form where "r" is the distance from one of the foci
    % (located at [0,Y0]) and the major axis is on the Y axis
    r=1./sqrt(s.^2/a2+c.^2/b2);
    XX=r.*c; YY=Y0+r.*s;
    
    junk=RotBetaAndFlipY*[XX-Xd0;YY-Yd0];
    xx=junk(1,:); yy=junk(2,:);
    
    hold on; plot(axes_handle,xx(:),yy(:),'linestyle',char(linetype),'color',linecolor);

    %% Debug plotting (Ram)
    if (0)
        figure;
        plot(XX(:),YY(:),'linestyle',char(linetype),'color',linecolor);
        conic = ConicClass(); % Create a conic object
        conic.SetConexParameters(alpha0, d0, 0, 0, 0, theta(idx_1(i)));
        [xx, yy] = conic.GetPointsFromParametricForm(linspace(0, 2*pi, 100));
        hold on; plot(xx(:), yy(:), '*g'); hold off;
        
        figure;
        
        %% Draw debug plot
        alpha0 = 1.1;
        beta0 = 2.1;
        
        c=cos(beta0); s=sin(beta0);
        RotBetaAndFlipY=[[c -s];[-s -c]]; % This is a rotation + flipping of "y" sign
        q=(0:0.0005:1)*2*pi; c=cos(q); s=sin(q);
        
        [a,b,Y0,fp,fm,vp,vm]=aby0_ellipse(alpha0,theta(idx_1(i)));
        a2=(a*d0)^2; b2=(b*d0)^2; Y0=Y0*d0;
        
        r=1./sqrt(s.^2/a2+c.^2/b2);
        XX=r.*c; YY=Y0+r.*s;
        
        q=(0:0.25:1)*2*pi; c=cos(q); s=sin(q);
        linesR=1./sqrt(s.^2/a2+c.^2/b2);
        linesXY = [ linesR.*c; Y0+linesR.*s];
        linesXY = RotBetaAndFlipY*[linesXY(1,:)-Xd0;linesXY(2,:)-Yd0];
        
        fp = RotBetaAndFlipY*[-Xd0; fp*d0-Yd0];
        fm = RotBetaAndFlipY*[-Xd0; -fm*d0-Yd0];
        vp = RotBetaAndFlipY*[-Xd0; vp*d0-Yd0];
        vm = RotBetaAndFlipY*[-Xd0; -vm*d0-Yd0];
        
        junk=RotBetaAndFlipY*[XX-Xd0;YY-Yd0];
        xx=junk(1,:); yy=junk(2,:);
        
        plot(xx(:),yy(:),'linestyle',char(linetype),'color',linecolor);
        set(gca, 'Ydir','reverse');
        axis equal
        hold on;
        plot(fp(1), fp(2), '+g');
        plot(fm(1), fm(2), '+g');
        plot(vp(1), vp(2), '+r');
        plot(vm(1), vm(2), '+r');
        
        for lineIdx = 1:numel(linesR)
            plot([0 linesXY(1, lineIdx)], [0 linesXY(2, lineIdx)], '-k');
        end
        hold off;
        
        % plot conic
        
        conic = ConicClass(); % Create a conic object
        conic.SetConexParameters(alpha0, d0, Xd0, Yd0, beta0, theta(idx_1(i)));
        [xx, yy] = conic.GetPointsFromParametricForm((0:0.05:1)*2*pi);
        hold on; plot(xx(:), yy(:), '*g'); hold off;
        %hold on; plot(xx(:), yy(:), 'g', 'linestyle',char(linetype)); hold off;
    end
    
    %% Some more debug plotting (Ram)
    % This is just test code for the compliance of the conic class
    % "SetConexParameters" to the existing CONEX code...
    if (0)
        conic = ConicClass(); % Create a conic object
        conic.SetConexParameters(alpha0, d0, Xd0, Yd0, beta0, theta(idx_1(i)));
        [xx, yy] = conic.GetPointsFromParametricForm((0:0.05:1)*2*pi);
        %[xx, yy] = conic.GetPointsFromParametricForm(q);
        hold on; plot(xx(:), yy(:), '*g'); hold off;
        %hold on; plot(axes_handle, xx(:), yy(:), 'g', 'linestyle',char(linetype));
    end
end

for i=1:length(idx_2)
    [a,b,Y0]=aby0_hyperbola(alpha0,theta(idx_2(i)));
    a2=(a*d0)^2; b2=(b*d0)^2; Y0=Y0*d0;
    
    qmin=atan(sqrt(a2/b2))+0.01; qmax=pi-qmin;
    q=linspace(qmin,qmax,500); c=cos(q); s=sin(q);
    
    r=1./sqrt(s.^2/a2-c.^2/b2);
    XX=r.*c;YY=Y0-r.*s;
    
    junk=RotBetaAndFlipY*[XX-Xd0;YY-Yd0];
    xx=junk(1,:); yy=junk(2,:);
    
    hold on; plot(axes_handle,xx(:),yy(:),'linestyle',char(linetype),'color',linecolor);
    
end


