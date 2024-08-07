function [rot_zero_pc,tform] = PCZerCntrOrient(ip_data, pcMean, pcaVec)
    ptCloudOriginal = pointCloud(ip_data); % create a PC object
    pcZeroCentered = bsxfun(@minus, ptCloudOriginal.Location, pcMean);   
    % Get the rotation angles
    deg = zeros(1,3);
    for itr = 1 : 3
        pca_temp = pcaVec(itr,:);
        plane_vec_temp = zeros(3,1);
        [max_val,eye_idx] = max(abs(pca_temp));
        % define rotation angle only if PC vector is considerably far from
        % corresponding axes
        if max_val < 0.9
            plane_vec_temp(eye_idx) = 1;
            plane_vec = plane_vec_temp; 
            pca_temp1 = pca_temp*sign(dot(pca_temp,plane_vec)); %orientation convention
            deg(itr) = acosd(dot(pca_temp1,plane_vec));
        end
    end
    % Transformation matrix 
    Radians = deg2rad(deg);
    eul = Radians;
    rotMat = eul2rotm(eul,'XYZ');
    trans = [0 0 0];
    tform = rigid3d(rotMat,trans);

    % Convert to pointCloud class
    ptCloudNew = pointCloud(pcZeroCentered);
    ptCloudNew.Color =  ptCloudOriginal.Color;
    ptCloudNew = pctransform(ptCloudNew,tform);
    rot_zero_pc = ptCloudNew.Location; % extract the point cloud
end