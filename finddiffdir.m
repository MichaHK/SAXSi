function [filenameList, filePathsList, newFiles, newestFileTime] = finddiffdir(folder, fileFilter, DisplayOptions)

sortInfo = DisplayOptions.FilesSort;
newFilesThresholdTime = DisplayOptions.LastSeenFileTime;
shouldSearchRecursively = DisplayOptions.ShouldSearchFilesRecursively;

newFiles = 0;
filenameList = {};
filePathsList = {};
newestFileTime = [];

if (~exist(folder, 'dir'))
    return;
end

if (~exist('sortInfo', 'var') || isempty(sortInfo))
    sortInfo = [];
end

if (~exist('newFilesThresholdTime', 'var'))
    newFilesThresholdTime = now();
end

folder = strrep(folder, '\', '/');

if (isempty(folder))
    folder = fileFilter;
    fileFilter = [];
end

if (isempty(fileFilter))
    [folder, filename, fileExt] = fileparts(folder);
    fileFilter = [filename fileExt];
end

allFiles = [];
allFileFullpaths = [];

if (~DisplayOptions.ShouldSearchFilesUsingRegExp)
    fileFiltersList = strSplit(fileFilter, {';', ','}, 1);
    
    tStarted = tic();
    if (0) % old way
        for fileFilterIndex = 1:numel(fileFiltersList)
            fileFilter = fileFiltersList{fileFilterIndex};
            
            [fullFilenames, filenames, ~, filesInfo] = ListFiles([folder '/' fileFilter], shouldSearchRecursively);
            
            allFileFullpaths = [allFileFullpaths; fullFilenames];
            allFiles = [allFiles; filesInfo];
        end
    else
        [allFileFullpaths, filenames, ~, allFiles] = ListFiles([folder '/*'], shouldSearchRecursively);
        
        fileFilter = WildcardsToRegexp(fileFiltersList);
        which = cellfun(@(f)(~isempty(regexpi(f, fileFilter))), filenames);
        
        allFileFullpaths = allFileFullpaths(which);
        allFiles = allFiles(which);
    end
    
    tElapsed = toc(tStarted)
    
else
    [allFileFullpaths, filenames, ~, allFiles] = ListFiles([folder '/*'], shouldSearchRecursively);
    
    which = cellfun(@(f)(~isempty(regexpi(f, fileFilter))), filenames);
    allFileFullpaths = allFileFullpaths(which);
    allFiles = allFiles(which);
end


if (numel(allFiles) > 0)
    allFileFullpaths([allFiles.isdir]) = [];
    allFiles([allFiles.isdir]) = [];
    
    if (~isempty(sortInfo))
        if (ischar(sortInfo))
            sortInfo = struct('Field', sortInfo, 'Func', [], 'Direction', -1);
        end
        
        % Check if the sorted field is a string
        if (ischar(allFiles(1).(sortInfo.Field)))
            keys = {allFiles.(sortInfo.Field)};
            
            if (isfield(sortInfo, 'Func') && ~isempty(sortInfo.Func))
                keys = cellfun(sortInfo.Func, keys, 'UniformOutput', 0);
            end
        else
            keys = [allFiles.(sortInfo.Field)];
            
            if (isfield(sortInfo, 'Func') && ~isempty(sortInfo.Func))
                keys = arrayfun(sortInfo.Func, keys, 'UniformOutput', 0);
            end
        end
        
        if (iscell(keys) && isnumeric(keys{1}))
            keys = [keys{:}];
        end
        
        [~, order] = sort(keys);
        
        if (sortInfo.Direction < 0)
            order = order(end:-1:1);
        end
        
        allFiles = allFiles(order);
        allFileFullpaths = allFileFullpaths(order);
    end
    
    newestFileTime = max([allFiles.datenum]);
    
    if (~isempty(newFilesThresholdTime))
        newFiles = find(cellfun(@(d)d > newFilesThresholdTime, {allFiles.datenum}));
    end
    
    filenameList = {allFiles.name};
    filePathsList = allFileFullpaths;
end

end
