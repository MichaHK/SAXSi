function [fullFilenames, filenames, folders, filesInfo] = ListFiles(searchPattern, shouldSearchSubfolders)
% [fullFilenames, filenames, folders, filesInfo] = ListFiles(searchPattern, shouldSearchSubfolders)
%

if (~exist('shouldSearchSubfolders', 'var') || isempty(shouldSearchSubfolders))
    shouldSearchSubfolders = 0;
end

[startIndex, endIndex, tokIndex, matchStr, tokenStr, exprNames, splitStr] = ...
    regexp(searchPattern, '(?<folder>.*[\\/])?(?<filename>[^\\/]*)$');

folder = exprNames.folder;
searchPattern = exprNames.filename;

if (isempty(folder))
    folder = cd;
end

if (folder(end) ~= '\' && folder(end) ~= '/')
    folder = [folder filesep];
end

[filenames, folders, filesInfo] = InternalListFilesRecursive(folder);

filenames = filenames(:);
folders = folders(:);
fullFilenames = cell(size(filenames));
for j = 1:numel(filenames)
    fullFilenames{j} = [folders{j} filenames{j}];
end

    function [subFolders] = InternalListSubfolders(folder)
        dirResult = dir(folder);
        filenames = arrayfun(@(i)dirResult(i).name, 1:numel(dirResult), 'UniformOutput', false);
        whichDirectories = logical(arrayfun(@(i)dirResult(i).isdir, 1:numel(dirResult), 'UniformOutput', true));
        subFolders = filenames(whichDirectories);
    end

    function [filenames, folders, filesInfo] = InternalListFilesRecursive(folder)
        tic; dirResult = dir([folder, searchPattern]); toc;
        filenames = arrayfun(@(i)dirResult(i).name, 1:numel(dirResult), 'UniformOutput', false);
        whichDirectories = logical(arrayfun(@(i)dirResult(i).isdir, 1:numel(dirResult), 'UniformOutput', true));

        filenames = filenames(~whichDirectories);
        filesInfo = dirResult(~whichDirectories);
        folders = repmat({folder}, size(filenames));
        
        if (shouldSearchSubfolders)
            directoryNames = InternalListSubfolders(folder);
            for i = 1:numel(directoryNames)
                if (~strcmp('.', directoryNames{i}) && ~strcmp('..', directoryNames{i}))
                    [moreFilenames, moreFolders, moreFilesInfo] = InternalListFilesRecursive([folder directoryNames{i} filesep]);

                    filenames = [filenames moreFilenames];
                    folders = [folders moreFolders];
                    filesInfo = [filesInfo; moreFilesInfo];
                end
            end
        end
    end
end
