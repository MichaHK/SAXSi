function Detector_position=FindDetectorPosition_GUI_SAXSi(Lines)

MN=Lines(1).size;
Detector_position=[MN(1) MN(2) 0 0 0 0 0];

N_l=length(Lines); 

Color=lines(9); Color=Color([(1:6)'; (8:9)'],:);

Theta=zeros(N_l,1);

fig_h = figure('Units','centimeters','Position',[1 2 25 14]);
set(fig_h,'menubar','none','numbertitle','off','name','Find Detector Position');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fr_h = uipanel('parent',fig_h,'Units','centimeters','Position',[1 1 5 6.75]);
uicontrol('parent',fr_h,'Style','text','String','Alpha (°)','horizontalalignment','left',...
        'units','centimeters','Position', [0.3 5.3 2.5 0.75]);
uicontrol('parent',fr_h,'Style','text','String','Distance (pixels)','horizontalalignment','left',...
        'units','centimeters','Position', [0.3 4.3 2.5 0.75]);
uicontrol('parent',fr_h,'Style','text','String','X detector (pixels)','horizontalalignment','left',...
        'units','centimeters','Position', [0.3 3.3 2.5 0.75]);
uicontrol('parent',fr_h,'Style','text','String','Y detector (pixels)','horizontalalignment','left',...
        'units','centimeters','Position', [0.3 2.3 2.5 0.75]);
uicontrol('parent',fr_h,'Style','text','String','Beta (°)','horizontalalignment','left',...
        'units','centimeters','Position', [0.3 1.3 2.5 0.75]);

alpha_h = uicontrol('parent',fr_h,'Style','edit','String','0.0','horizontalalignment','center',...
        'units','centimeters','Position', [3 5.5 1.6 0.75],'callback',@change_param0);
distance_h =uicontrol('parent',fr_h,'Style','edit','String','0.0','horizontalalignment','center',...
        'units','centimeters','Position', [3 4.5 1.6 0.75],'callback',@change_param0);
Xd_h=uicontrol('parent',fr_h,'Style','edit','String','0.0','horizontalalignment','center',...
        'units','centimeters','Position', [3 3.5 1.6 0.75],'callback',@change_param0);
Yd_h=uicontrol('parent',fr_h,'Style','edit','String','0.0','horizontalalignment','center',...
        'units','centimeters','Position', [3 2.5 1.6 0.75],'callback',@change_param0);
beta_h=uicontrol('parent',fr_h,'Style','edit','String','0.0','horizontalalignment','center',...
        'units','centimeters','Position', [3 1.5 1.6 0.75],'callback',@change_param0);
    
fitbut_h=uicontrol('parent',fr_h,'Style','pushbutton','String','Fit','horizontalalignment','center','enable','off',...
        'units','centimeters','Position', [0.25 0.25 4.4 1],'callback',@fit_callback);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Cones_h = axes('Parent',fig_h,'Units','centimeters','Position',[1 8.25 5 4.75],'color',get(fig_h,'color'); 
%set(Cones_h,'Xtick',[],'Ytick',[],'Ydir','reverse','nextplot','replace'); box off;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ax_h = axes('Parent',fig_h,'nextplot','add','Units','centimeters','Position',...
    [6.5 1 10 12],'color',[0.25 0.25 0.25],'ButtonDownFcn',@Click_on_Graph); 

xmin=1e6; xmax=-1e6; ymin=1e6; ymax=-1e6;
for l=1:N_l
    xy=Lines(l).xy;
    xmin=min([xmin min(xy(:,1))]); xmax=max([xmax max(xy(:,1))]);
    ymin=min([ymin min(xy(:,2))]); ymax=max([ymax max(xy(:,2))]);       
    
    plot(ax_h,xy(:,1),xy(:,2),'+k','Markersize',10,'MarkerEdgeColor',Color(l,:));
    Theta(l)=pi*(Lines(l).theta)/180;
end
f=0.5;
xinf=xmin-f*(xmax-xmin); xsup=xmax+f*(xmax-xmin);
yinf=ymin-f*(ymax-ymin); ysup=ymax+f*(ymax-ymin);
Width=min([20,12*(xsup-xinf)/(ysup-yinf)]);

set(ax_h,'Position',[6.5 1 Width 12]);
axis(ax_h,'equal');
set(ax_h,'box','on','Xlim',[xinf xsup],'Ylim',[yinf ysup],'Ydir','reverse');
set(ax_h,'Xtick',(-1000:500:2000),'Ytick',(-1000:500:2000),'Xticklabel',[],'Yticklabel',[]);
grid(ax_h,'off');

set(fig_h,'Position',[1 2 14.5+Width 14]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Weight=ones(N_l,1);

frame_h = uipanel('parent',fig_h,'Units','centimeters','Position',[7+Width 2.5 6.5 10.5]);
uicontrol('parent',frame_h,'Style','text','String','Sample','horizontalalignment','center',...
        'units','centimeters','Position', [0.1 9.25 1 0.75]);
uicontrol('parent',frame_h,'Style','text','String','2 theta (°)','horizontalalignment','center',...
        'units','centimeters','Position', [1.5 9.25 1.5 0.75]);
uicontrol('parent',frame_h,'Style','text','String','Statistical Weight','horizontalalignment','center',...
        'units','centimeters','Position', [3 9.25 3 0.75]);
    
samples_h=zeros(N_l,1); angles_h=zeros(N_l,1); slider_h=zeros(N_l,1); dy=0.8;
for n=1:N_l
    samples_h(n) = uicontrol('parent',frame_h,'Style','text','String',Lines(n).Sample,'horizontalalignment','center',...
        'units','centimeters','Position', [0.1 9.2-n*dy 1 0.75]);  
    angles_h(n) = uicontrol('parent',frame_h,'Style','text','String',num2str(Lines(n).theta),'horizontalalignment','left',...
        'units','centimeters','Position', [1.5 9.2-n*dy 1.5 0.75]);  
    slider_h(n) = uicontrol('parent',frame_h,'Style','slider','value',Weight(n),'units','centimeters','Position', [3 9.65-n*dy 3 0.35],...
        'backgroundcolor',Color(n,:),'horizontalalignment','center');      
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finishbut_h=uicontrol('parent',fig_h,'Style','pushbutton','String','Keep Values','horizontalalignment','center','enable','off',...
        'units','centimeters','Position', [7+Width 1 6.5 1],'callback',@finish_callback);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Cones_h = axes('Parent',fig_h,'Units','centimeters','Position',[1 8.25 5 4.75],'color',get(fig_h,'color'),'Visible','off'); 
axes(Cones_h);
show_detector_3D([],Theta,0);

uiwait

    function Click_on_Graph(gcbo,eventdata,handles)
        
        draw_lines;
        
        brol=get(ax_h,'CurrentPoint'); x0=brol(1,1); y0=brol(2,1);
        [xyc,RR]=fit_circles(Lines,[x0 y0]);
        %xyc       %
        q=(0:0.01:1)*2*pi; c=cos(q); s=sin(q);
        for n=1:N_l
           x=xyc(1)+RR(n)*c; y=xyc(2)+RR(n)*s;
           plot(ax_h,x,y,':w');
        end
        
        alpha0=mean(Theta);
        if (length(Theta)>1)  %%% added by Roy
            
            par=polyfit(Theta(:),RR(:),1); d0=par(1);
            beta0=atan(xyc(1)/xyc(2)); %ATTENTION! A MODIFIER POUR TOUTES LES CONFIGURATIONS POSSIBLES
            Yd0=sqrt(sum(xyc.^2));
            Xd0=0;
            par_0=[alpha0 d0 Xd0 Yd0 beta0];
            for r=1:10
                par=fminsearch(@Error_on_Lines_theta,par_0,[],Lines,Weight);
                par_0=par;
            end
        else %%%%%  added by Roy Beck %%%%
            d0=RR(1)./Theta(1);
            beta0=0; 
            Yd0=xyc(2);
            Xd0=-xyc(1);
            par_0=[0 d0 Xd0 Yd0 0];
          %  par_0=[0 d0 Xd0 Yd0 1];
            par=par_0;
        end
        
        
        
       
        par=par_0;
        axes(ax_h);
        redraw_lines(par);   
        %find_Direct_Beam(par(3),par(4),par(5))
        set(alpha_h,'string',num2str(180*par(1)/pi,3));
        set(distance_h,'string',num2str(par(2),4));
        set(Xd_h,'string',num2str(par(3),4));
        set(Yd_h,'string',num2str(par(4),4));
        set(beta_h,'string',num2str(par(5)*180/pi,3));
        
        Detector_position(3:7)=par;
        
        delete(Cones_h);
        Cones_h = axes('Parent',fig_h,'Units','centimeters','Position',...
            [1 8.25 5 4.75],'color',get(fig_h,'color'),'Visible','off'); 
        axes(Cones_h);
        show_detector_3D(Detector_position,Theta,1);
       
         set(fitbut_h,'enable','on');
         set(finishbut_h,'enable','on');
    end

    function change_param0(gcbo,eventdata,handles)

        alpha0=str2double(get(alpha_h,'String'))*pi/180;
        d0=str2double(get(distance_h,'String'));
        Xd0=str2double(get(Xd_h,'String'));
        Yd0=str2double(get(Yd_h,'String'));
        beta0=str2double(get(beta_h,'String'))*pi/180;
        
        parameters_0=[alpha0 d0 Xd0 Yd0 beta0];        

        axes(ax_h);
        redraw_lines(parameters_0);
        
        delete(Cones_h);
        Cones_h = axes('Parent',fig_h,'Units','centimeters','Position',...
            [1 8.25 5 4.75],'color',get(fig_h,'color'),'Visible','off'); 
        axes(Cones_h);
        show_detector_3D([MN parameters_0],Theta,1);
        
    end

    function fit_callback(gcbo,eventdata,handles)
        alpha0=str2double(get(alpha_h,'String'))*pi/180;
        d0=str2double(get(distance_h,'String'));
        Xd0=str2double(get(Xd_h,'String'));
        Yd0=str2double(get(Yd_h,'String'));
        beta0=str2double(get(beta_h,'String'))*pi/180;
        
        for n=1:N_l, Weight(n)=get(slider_h(n),'Value'); end;
        
        par_0=[alpha0 d0 Xd0 Yd0 beta0];
        
        for r=1:10
            par=fminsearch(@Error_on_Lines_theta,par_0,[],Lines,Weight);
            par_0=par;
        end
       par=par_0;
                
        axes(ax_h);
        redraw_lines(par);   
        
        set(alpha_h,'string',num2str(180*par(1)/pi,3));
        set(distance_h,'string',num2str(par(2),4));
        set(Xd_h,'string',num2str(par(3),4));
        set(Yd_h,'string',num2str(par(4),4));
        set(beta_h,'string',num2str(par(5)*180/pi,3));
        
        set(finishbut_h,'enable','on');
        Detector_position(3:7)=par;
        
        delete(Cones_h);
        Cones_h = axes('Parent',fig_h,'Units','centimeters','Position',...
            [1 8.25 5 4.75],'color',get(fig_h,'color'),'Visible','off'); 
        axes(Cones_h);
        show_detector_3D(Detector_position,Theta,1);
        
    end

    function redraw_lines(param)

        set(ax_h,'NextPlot','replacechildren');
        for li=1:N_l
            xy=Lines(li).xy;    
            plot(ax_h,xy(:,1),xy(:,2),'+k','Markersize',10,'MarkerEdgeColor',Color(li,:)); hold on;
        end
        
        add_lines_to_graph(Theta,param,ax_h,'-',[0.5 0.5 0.7]);

    end

    function draw_lines

        set(ax_h,'NextPlot','replacechildren');
        for l=1:N_l
            xy=Lines(l).xy;    
            plot(ax_h,xy(:,1),xy(:,2),'+k','Markersize',10,'linewidth',2,'MarkerEdgeColor',Color(l,:)); hold on;
        end        
        
    end

    function finish_callback(gcbo,eventdata,handles)
        
        alpha0=str2double(get(alpha_h,'String'))*pi/180;
        d0=str2double(get(distance_h,'String'));
        Xd0=str2double(get(Xd_h,'String'));
        Yd0=str2double(get(Yd_h,'String'));
        beta0=str2double(get(beta_h,'String'))*pi/180;
        
        parameters_0=[alpha0 d0 Xd0 Yd0 beta0];        
        Detector_position(3:7)=parameters_0;

        uiresume
        delete(fig_h);
    %%%% removed by Roy Beck
    
%         [file,path] = uiputfile('calibration_file.pos','Save file name');
%         filename=strcat(path,file);
%         
%         save(filename, 'Detector_position','-ascii');
        
    end

end