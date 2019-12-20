function [filepath] = ReplaceFileExtension(filepath, newExtension)

[fileFolder, fileName, fileExt] = fileparts(filepath);
filepath = fullfile(fileFolder, [fileName, newExtension]);

end
