%% Generalized IoU Implementation 
function [giou_val_vec,iou_val_vec] = GIouIdx(closest_cluster_proj_strct)
    iou_val_vec = [];
    giou_val_vec = [];
    c = {'r','g','b','cyan','magenta','yellow','black',[0.6350 0.0780 0.1840],[0.4940 0.1840 0.5560],[0.8500 0.3250 0.0980]}; % last three colors: 'Maroon', 'Purple', 'Orange-ish'
    figure
    for itr = 1 : size(closest_cluster_proj_strct,2)
        cur_gt_pts = closest_cluster_proj_strct(itr).gt_data;
        cur_res_pts = closest_cluster_proj_strct(itr).res_data;
        % Calculation of Planar Convex polygon
        conv_res = [];
        conv_gt = alphaShape(cur_gt_pts,Inf); 
        if size(cur_res_pts,1) > 0
            conv_res = alphaShape(cur_res_pts,Inf); 
            % Determine the Union Area
            conv_poly_res = [];
            conv_poly_gt = [];
            union_pts = []; 
            conv_union = [];
            [~,conv_poly_res] = boundaryFacets(conv_res);
            [~,conv_poly_gt] = boundaryFacets(conv_gt);
            gt_plyshp_obj = polyshape(conv_poly_gt);
            res_plyshp_obj = polyshape(conv_poly_res);
            plot(gt_plyshp_obj,'FaceColor','none','EdgeColor',c{itr},'LineWidth',1.5,'FaceAlpha',0.1);hold on; 
            plot(res_plyshp_obj,'FaceColor',c{itr},'EdgeColor',c{itr},'FaceAlpha',0.1); hold on;
            % Determine the intersection area
            inter_pts = [];
            gt_plyshp_obj = [];
            res_plyshp_obj = [];
            idx1 = [];
            idx2 = [];
            conv_inter = [];
            idx1 = false(size(cur_gt_pts,1),1);
            idx2 = false(size(cur_res_pts,1),1);
            if size(conv_poly_res,1) > 0
                idx1 = inShape(conv_res,cur_gt_pts);
            end 
            if size(conv_poly_gt,1) > 0
                idx2 = inShape(conv_gt,cur_res_pts);
            end
            inter_area(itr,1) = 0;
            inter_pts = [cur_gt_pts(idx1,:);cur_res_pts(idx2,:)];
            if size(inter_pts,1) > 0
                conv_inter = alphaShape(inter_pts,Inf);
                inter_area(itr,1) = area(conv_inter);
            end
            union_area(itr,1) = area(conv_gt) + area(conv_res) - inter_area(itr,1);
            % Calculate the value of Intersection over Union
            iou_val_vec(itr,1) = inter_area(itr,1)/union_area(itr,1);
            % Smallest Region enclosing both the shapes
            enclse_pts = [];
            conv_enclse = [];
            enclse_pts = [cur_gt_pts(~idx1,:);cur_res_pts(~idx2,:)];
            if size(enclse_pts,1) > 0
                conv_enclse = alphaShape(enclse_pts,Inf);
                encls_area(itr,1) = area(conv_enclse);
            else
                encls_area(itr,1) = 0;
            end
            giou_val_temp = 0;
            if encls_area(itr,1) > 0 % only calculate GIoU if enclosed points area > 0
                giou_val_temp = (encls_area(itr,1) - union_area(itr,1))/encls_area(itr,1);
            end
            giou_val_vec(itr,1) = iou_val_vec(itr,1) - giou_val_temp;
        else
            giou_val_vec(itr,1) = - 1;
        end
    end
end