% orient PCA vectors in a single directions
function oriented_vecs = OrientVec(ip_data, vec_init, ref_pt)
    % Align all the point PCA in direction of reference point]
    % Ref: https://www.mathworks.com/help/vision/ref/pcnormals.html
    for itr = 1 : size(vec_init,1)
       vec1 = ref_pt - ip_data(itr,:);
       vec2 = vec_init(itr,:);
       % Flip the vector if it is not pointing towards the reference point.
       angle = atan2(norm(cross(vec1,vec2)),vec1*vec2');
       if angle > pi/2 || angle < -pi/2
           vec_init(itr,:) = -vec_init(itr,:);
       end
    end 
    oriented_vecs = vec_init;
end