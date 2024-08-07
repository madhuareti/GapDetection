% check the output of dir function in matlab for unwanted files
% filter paths based on input key word -  select only relevent files
% function to setup for the check folder function
function data_paths = CheckFolderSetup(path, del_keys, slsh, ext_key)
    data_paths_temp = struct;
    data_paths = CheckFolder(path, data_paths_temp, del_keys, slsh, ext_key);
    % function for checking the folders for nested directories and data
    function data_paths = CheckFolder(path, data_paths, del_keys, slsh, ext_key)
        if isfolder(path)
            cur_dir_list = dir(fullfile(path)); 
            cur_dir_list = cur_dir_list(~cellfun(@(x) MatchKeys(x, del_keys), {cur_dir_list.name}));
            for itr = 1 : size(cur_dir_list,1)
                upd_path = strcat(cur_dir_list(itr).folder,slsh,cur_dir_list(itr).name);
                data_paths = CheckFolder(upd_path, data_paths, del_keys, slsh, ext_key);
            end
        else
            if size(split(path,ext_key),1) > 1
                if size(fieldnames(data_paths),1) == 0
                    data_paths.val = path;
                else
                    data_paths(size(data_paths,2) + 1).val = path;
                end
            end
        end
    end
end