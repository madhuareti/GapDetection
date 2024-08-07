function avg_space = AvgSpace3D(pts)
    pt_cloud = pointCloud(pts);
    avg_space = 0;
    if size(pts,1) > 1
        for i = 1 : size(pts,1)
            [~, distance] = findNearestNeighbors(pt_cloud,pts(i,:),2, 'Sort', true);
            dist(i) = distance(2);
        end
        avg_space = sum(dist)/size(pts,1);
    end
end