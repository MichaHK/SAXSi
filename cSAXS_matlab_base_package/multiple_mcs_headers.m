
function [] = multiple_mcs_headers(scan_no_from,scan_no_to)

if (nargin ~= 2)
    fprintf('Usage: %s <scan no. from> <scan no. to>\n',mfilename);
    fprintf('Searches for multiple MCS headers, renames the matching files and\n');
    fprintf('writes a new file with only the last header and its data.\n');
    fprintf('This is just a workaround for the current implementation of the MCS\n');
    fprintf('where spec stores the MCS data several times in case a cont_line is repeated.\n');
end

for (scan_no = scan_no_from:scan_no_to)
    dirname = compile_x12sa_filename(scan_no, -1, 'BasePath','~/Data10/mcs/');
    dirinfo = dir([ dirname '*.dat' ]);
    if (length(dirinfo) < 1)
        fprintf('%s not found\n',filename);
    else
        for (ind = 1:length(dirinfo))
            filename = [dirname dirinfo(ind).name];
            fid = fopen(filename,'r');
            % read all data at once
            [fdat,~] = fread(fid,'uint8=>uint8');
            fclose(fid);
            % check for multiple fileheaders
            header_start = strfind(fdat','# MCS file version');
            if (length(header_start) > 1)
                fprintf('%s has %d headers\n',filename, length(header_start));
                % rename the file
                movefile(filename, [filename '_org']);
                % use the last file part
                fdat = fdat(header_start(end):end);
                % store the truncated data
                fid = fopen(filename,'w');
                fwrite(fid,fdat);
                fclose(fid);
            end
        end
    end
end
