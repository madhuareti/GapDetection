% extract all the files of the spcified files in a dirrectory and filer
% files based on key words
function dir_strs = FileExtractDir(dir_str,bin_key,keys)
    dir_strs = dir(fullfile(dir_str));
    if size(bin_key,2) ~= size(keys,2)
        error('input keys and operations not matching');
    end
    for itr = 1 : size(bin_key,2)
        dir_strs_bin = cellfun(@(x) MatchKeys(x, keys(itr).value),...
            {dir_strs.name}); % paths of all directories (unique datasets)
        
        if bin_key(itr).value == "keep"
            dir_strs_bin2 = find(dir_strs_bin);
            dir_strs = dir_strs(dir_strs_bin2);
        else
            if bin_key(itr).value == "delete"
                dir_strs_bin2 = find(~dir_strs_bin);
                dir_strs = dir_strs(dir_strs_bin2);
            else
                error('invalid option for file filtering');
                dir_strs = [];
            end
        end
    end
end