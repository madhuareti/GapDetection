% extract all the files of the spcified files in a dirrectory including the subdirectories within and fitler
% files based on key words
function dir_strs = FileExtractDirAll(dir_str,bin_key,keys,file_ext,slsh)
    data_paths = CheckFolderSetup(dir_str, [".";".."], slsh, file_ext);
    for itr = 1 : max(size(data_paths,2))
        cur_path = data_paths(itr).val;
        final_dir_temp = split(cur_path,file_ext); % name of the file
        final_dir_temp2 = split(final_dir_temp{1},dir_str); % path split from input directory string
        final_dir_temp3 = split(final_dir_temp2{2},slsh); % split path variable
        % find the final directory where the data file is present
        final_dir = [];
        for itr1 = 1 : size(final_dir_temp3,1)
            if isfolder(strcat(dir_str,slsh,final_dir_temp3(itr1)))
                % append the string until the final directory is reached
                if size(final_dir,1) > 0
                    final_dir = strcat(final_dir,slsh);
                end
                final_dir = strcat(final_dir,final_dir_temp3(itr1));
                continue;
            else
                final_dir_str = strcat(dir_str,final_dir);
                break;
            end
        end
        dir_strs(itr,1).folder = final_dir_str;
        dir_strs(itr,1).name = strcat(final_dir_temp3(itr1),file_ext);
    end
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