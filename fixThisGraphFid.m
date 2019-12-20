function fixThisGraphFid (fid)
xl=[3e-3 0.1636];
if (nargin<1)
    tl='35wt%M 40mM salts';
    %    leg={'40','20','17.5','15','10','5','2.5','1.25','0.75','0.5','0.25','0'};
    %      leg={'40','20','17.5','15','10','5','2.5','1.25','0.75','0.5','0.25','0'};
    %     leg={'40','20','17.5','15','10','5','2.5','1.25','0.75','0.5','0.25','0'};
    %     leg={'40','20','17.5','15','10','5','2.5','1.25','0.75','0.5','0.25','0'};
    %     leg={'40','20','17.5','15','10','5','2.5','1.25','0.75','0.5','0.25','0'};
    %     leg={'40','20','17.5','15','10','5','2.5','1.25','0.75','0.5','0.25','0'};
    %     leg={'40','20','17.5','15','10','5','2.5','1.25','0.75','0.5','0.25','0'};
    leg={'40','20','17.5','15','10','5','2.5','1.25','0.75','0.5','0.25','0'};
    %   leg={'20','17.5','15','10','5','2.5','1.25','0.75','0.25','0'};
    %leg={'20','17.5','15','10','5','2.5','1.25','0.75','0.5','0.25','0'};
    [fn pathn]=uigetfile('.fig');
    fid=open (fullfile (pathn,fn));
    figure (fid);
else
    leg={'40','20','17.5','15','10','5','2.5','1.25','0.75','0.5','0.25','0'};
    leg={'40','17.5','15','10','5','2.5','0.5','0'};
   
    % leg={'40','20','10','5','1.25','0.75','0.5','0.25','0'};
    %leg={'9 days from exchange','7 days from exchange','4 days from exchange','with PEG before exchange'};
    figure (fid);fida=gca;
    [legend_h,object_h,plot_h,text_strings]=legend (fida);
    pr = {'title:',text_strings{:}};
    lent=length(text_strings);
    dlg_title = 'Input title and legend';
    num_lines = 1;
    if (lent==length(leg))
        def = {'title',leg{:}};
    else
        def = {'title',text_strings{:}};
    end
    answer=[];
    answer = inputdlg(pr,dlg_title,num_lines,def,'on');
    if ~isempty (answer)
        leg=answer(2:lent+1);
        tl=answer{1};
    else
        tl='Runrun July - 10wt%NFH 90mM';
    end
end
[fn pathn]=uiputfile('.fig','save figure',[tl,'.fig']);
tl=fn;
hgsave (fid,fullfile (pathn,fn));
set (fid,'color',[1 1 1]);
fida=gca;
set (fida,'XScale','log');
set (fida,'YScale','log');
axis tight
set (fida,'Xlim',xl);
title(tl,'fontsize',16)
set (fid,'WindowStyle','normal');
set (fid,'Position',[1 100 500,850]);
set (fida,'fontsize',16)
set (fida,'FontWeight','bold');
xlabel('q(Å^{-1})','fontsize',16);
ylabel('I(a.u.)','fontsize',16);
[legend_h,object_h,plot_h,text_strings]=legend (fida);
if (length(text_strings)==length(leg))
    legend (leg);
else
    legend (text_strings,'fontsize',8);
end
[pathstr, name, ext] = fileparts(fullfile(pathn,fn));

%saveas (fid,fullfile (pathstr,[name,'.tif']),'tif');
hgsave (fid,fullfile (pathstr,[name,'_corrected.fig']));
hgexport(fid,  '-clipboard')

%legend (leg)
