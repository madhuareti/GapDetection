% logic to delete results based on string matching
function bin = MatchKeys(ip, key)
% if multiple keys are given use ismember
    if size(key,1) > 1
        if ismember(ip,key,'rows') 
            bin = 1;
        else
            bin = 0;
        end
    else
        % for one key use split
        temp = split(ip,key);
        if size(temp,1) > 1
            bin = 1;
        else
            bin = 0;
        end
    end
end