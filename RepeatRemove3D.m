function op_pts = RepeatRemove3D(pts)
    op_pts = [];
    % remove the repeating points
    i = 1;
    while (i <= size(pts,1))
        j = i + 1;
        while (j <= size(pts,1)) 
            if ((sum(pts(i,:) == pts(j,:))) == 3)
                % if the repreated point is identified, delete it
                pts(j,:) = [];
                j = j - 1;
            end
            j = j + 1;
        end
        i = i + 1 ;
    end
        op_pts = pts;
end