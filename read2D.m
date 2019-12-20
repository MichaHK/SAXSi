function im = read2D(filename, shouldReturnFrames)

if (~exist('shouldReturnFrames', 'var') || isempty(shouldReturnFrames))
    shouldReturnFrames = 0;
end

im = [];

try

    % This is important for some network scenarios, but not for our daily
    % use. The loop waits for a file being downloaded.
    % TODO: Consider creating a flag for this
    if (0)
        tStart=tic;
        dir1=dir(filename);
        dir2=dir1;
        dir1.bytes=-dir1.bytes-3;
        while (dir2.bytes~=dir1.bytes)
            pause (0.1);
            dir1=dir2;
            dir2=dir(filename);
            % disp ('waiting for file to be downloaded');
        end
        tElapsed=toc(tStart);
        display(sprintf('Waited %02.1f seconds for file to complete download', tElapsed));
    end
    
    tStart=tic;
    
    frameNum = [];
    if (~isempty(strfind(filename, ';')))
        parts = strsplit(filename, ';');
        frameNum = str2double(parts{2});
        filename = parts{1};
    end
    
    %disp ('file is ready');
    [pathstr, name, ext] = fileparts(filename);
    
    if (strcmp (ext,'.img'))
        [im, minmin, maxmax, filenameIn] = readimgSAXS(filename);
    elseif (strcmp (ext,'.tif') || strcmp (ext,'.tiff'))
        try
            %tif = Tiff(filename, 'r');
            %bits = tif.getTag('BitsPerSample');
            %im = tif.read();
            
            % Really all that's required
            im=imread (filename);
            
            %         iminf=imfinfo(filename);
            %         %         im2=zeros([iminf.Width iminf.Height]);
            %         if (iminf.BitDepth   <=16)
            %             im=imread (filename);
            %         else
            %             %  im=imageread(filename, iminf.Format,[iminf.Width iminf.Height]);
            %             tmp=image_read(filename);
            %             im=tmp.data;
            %         end
            
            %         size(im2);
            %             im=im2(500:2000,1:3000);
        catch
            disp ('could not read waiting 5 sec')
            pause (5);
            try
                if (iminf.BitDepth   <= 16)
                    im=imread (filename);
                else
                    tmp=image_read(filename);
                    im=tmp.data;
                end
                
            catch
                disp ('couldnt read at all');
                im=[];
            end
            
        end
    elseif strcmp (ext,'.raw2300')
        %    im=imageread(filename,'img',[2300,2300],16);
        im=imageread(filename,'img',[2300,2300],16);
    elseif strcmp (ext,'.raw1200')
        %    im=imageread(filename,'img',[1200,1200],16);
        im=imageread (filename,'img',[1200,1200],16);
    elseif strcmp (ext,'.image');
        im=readMar345 (filename);
    elseif (strcmp (ext,'.gfrm'))
        [im,minmin,maxmax,filenameIn]=readimgSAXSgfrm (filename);
    elseif (strcmp (ext,'.edf'))
        try
            edf = edfread(filename);
            if (~isempty(edf))
                im = edf.data;
            end
        catch exception
            im = [];
        end
    elseif (strcmp (ext,'.cbf'))
        try
            cbf = cbfread(filename);
            if (~isempty(cbf))
                im = cbf.data;
            end
        catch exception
            im = [];
        end
    elseif (strcmp(ext, '.nxs') || strcmp(ext, '.h5'))
        %hinfo = hdf5info(filename);
        
        success = 0;
        
        if (~success)
            try
                im = hdf5read(filename, '/entry/mask/100');
                success = 1;
            catch
            end
        end
        
        
        if (~success)
            try
                im = hdf5read(filename, '/entry/instrument/detector/data');
                success = 1;
            catch
            end
        end
        
        
        if (~success)
            try
                im = hdf5read(filename, '/entry1/instrument/detector/data');
                success = 1;
            catch
            end
        end

        %im = im';
        im = permute(im, [2 1 3]);
    elseif(strcmp(ext, '.c04'))
         hinfo = hdf5info(filename);
        im = hdf5read(hinfo.GroupHierarchy.Groups.Groups.Groups(1,2).Datasets(1));
        im = im';
    elseif (strcmp (ext,'.mat'))
        imt = load(filename);
        fields = fieldnames(imt);
        if (numel(fields) == 1)
            im = imt.(fields{1});
        else
            im = imt.im;
        end
    else
        try
            tmp=image_read(filename);
            im=tmp.data;
        catch
            disp ('could not read the file type');
        end
    end
    % else
    %     im=[];disp ('could not read your file type');
    %     filename
    % end
    % im(100:105,320:327)=99999; % o check mask
    
    if (numel(size(im)) == 3)
        if (isempty(frameNum))
            [~, whichDimIsFrames] = min(size(im)); % Assume the smallest dimension if the frames
            
            if (shouldReturnFrames)
                im = double(im);
                if (whichDimIsFrames == 3)
                    im = shiftdim(im, 2);
                end
            else
                %im = mean(double(im), 3);
                im = mean(double(im), whichDimIsFrames);
            end
        else
            im = double(im(:, :, frameNum));
        end
    end
    
    tElapsed=toc(tStart);
    display(sprintf('Took %02.1f seconds to load image file', tElapsed));
    
catch err
    display('Something went wrong while trying to load the image');
end


