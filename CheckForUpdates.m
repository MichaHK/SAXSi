function CheckForUpdates()
if (~exist('Temp', 'dir'))
    mkdir('Temp');
end

if (exist('Temp/LastVersionCheck.mat', 'file'))
    load('Temp/LastVersionCheck.mat');
    
    %     if (now() - lastVersionCheck < 7)
    %         return;
    %     end
end

lastVersionCheck = now();
save('Temp/LastVersionCheck.mat', 'lastVersionCheck');

[verMajor, verMinor] = GetVersion();
[filestr,status] = urlwrite('https://dl.dropbox.com/u/329030/SAXSi%20Updates/Updates.csv', 'Temp/Updates.csv');

if (status)
    updates = MyCsvRead('Temp/Updates.csv');
    updateVersions = updates.NumericData(:, [1 2]);
    newest = (updateVersions(:, 1) == max(updateVersions(:, 1)));
    newest = (updateVersions(newest, 2) == max(updateVersions(newest, 2)));
    newest = find(newest, 1);
    
    isNewer = (updateVersions(newest, 1) > verMajor) || (updateVersions(newest, 1) == verMajor & updateVersions(newest, 2) > verMinor);
    
    %% Ask the user whether to update
    [~, ~, ~, currentVerString] = GetVersion();
    
    while (1)
        choice = questdlg(sprintf(['Would you like to update SAXSi? \n\nYour version is "' currentVerString '". \nNewest version is "' updates.Data{newest, 4} '"']), ...
            'SAXSi update available', ...
            'Yes', 'No thank you', 'Where did this come from??', 'No thank you');
        % Handle response
        switch choice
            case 'Yes'
                break;
            case 'Where did this come from??'
                h = helpdlg(sprintf(['This code runs from the "CheckForUpdates.m" script and checks every few days for an update.' ...
                    '\nThe updates are checked in an online location (Ram''s public Dropbox folder) and then offered to you. ' ...
                    '\n\nIf you''d like you can turn off automatic updates in the options menu.']));
                waitfor(h);
            otherwise % case 'No thank you'
                return;
        end
    end
    
    %%
    
    h = [];
    try
        h = waitbar(1/3,'[Step 1/3] Fetching update ...', ...
            'Name','SAXSi Update',...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
        setappdata(h,'canceling',0)
        
        updateFilename = updates.Data{newest, 3};
        [filestr,status] = urlwrite(['https://dl.dropbox.com/u/329030/SAXSi%20Updates/' updateFilename], ['Temp/' updateFilename]);
        
        % Check for Cancel button press
        if getappdata(h,'canceling')
            delete(h);
            return;
        end
        
        
        if (status)
            try
                [~, filenameWithoutExtension, ~] = fileparts(updateFilename);
                unzipFolder = ['Temp/' filenameWithoutExtension ' Unzipped'];
                % Report current estimate in the waitbar's message field
                waitbar(2/3, h, ['[Step 2/3] Unzipping update to: ' unzipFolder])
                
                mkdir(unzipFolder);
                [unzippedFiles] = unzip(filestr, unzipFolder);

                waitbar(3/3, h, '[Step 3/3] Done unzipping. User needs run "UpdateSAXSi".')
                pause(3);
            catch
                errordlg('Failed to unzip');
            end
        else
            errordlg('Failed to download update');
        end
        
    catch
    end
    
    delete(h)       % DELETE the waitbar; don't try to CLOSE it
end

end
