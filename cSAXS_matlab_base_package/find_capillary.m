function [varargout] = find_capillary(varargin)
    vararg = varargin;
    vararg{end+1} = 'UnhandledParError';
    vararg{end+1} = 0;
    [S,vararg] = spec_read(vararg{1},vararg{2:end});
    
    for jj = 1:2:length(vararg)
        name = vararg{jj};
        value = vararg{jj+1};
        switch name
            case 'Counter'
            counter = S.(value);
        end
    end
    
    arrout = regexp(S.S,' +','split');
    motor = S.(arrout{4});
    threshold = .1 * max(counter);
    
    motor = motor(counter>threshold);
    counter = counter(counter>threshold);
    

    threshold = .9 * max(counter);
    i_i = find(counter>threshold,1,'first');
    i_f = find(counter>threshold,1,'last');
    
    p = polyfit(motor(counter>threshold),counter(counter>threshold),1);
    dy = polyval(p,motor)-counter;
    COM = sum(motor(i_i:i_f).*dy(i_i:i_f))/sum(dy(i_i:i_f));
    
    do_plot = 1;
    figure(1)
    if (do_plot)
        plot(motor,dy)
        hold on
        area(motor(i_i:i_f),dy(i_i:i_f))
        plot([1 1]*COM,[0 max(dy(i_i:i_f))],'r','LineWidth',2)
        hold off
    end
    
    varargout{1} = COM;
    
    

end