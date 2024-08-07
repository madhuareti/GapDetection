function result = DouglasPeucker(Points,epsilon,axes_info)
% The Ramer–Douglas–Peucker algorithm (RDP) is an algorithm for reducing 
% the number of points in a curve that is approximated by a series of 
% points. The initial form of the algorithm was independently suggested 
% in 1972 by Urs Ramer and 1973 by David Douglas and Thomas Peucker and 
% several others in the following decade. This algorithm is also known 
% under the names Douglas–Peucker algorithm, iterative end-point fit 
% algorithm and split-and-merge algorithm. [Source Wikipedia]
%
% Input:
%           Points: List of Points 2xN
%           epsilon: distance dimension, specifies the similarity between
%           the original curve and the approximated (smaller the epsilon,
%           the curves more similar)
%           edit: MA - axes info is to note which info is considered for 2D
%               ex: [1,3] = means XZ coordinates
% Output:
%           result: List of Points for the approximated curve 2xM (M<=N)    
%           
%
% -------------------------------------------------------
% Code: Reza Ahmadzadeh (2017) 
% modfied: MA to accomodate 3d points but only work with 2d
% -------------------------------------------------------
dmax = 0;
edx = size(Points,2);
% sort the input data and calculate the first and last point based on...
% location in 2D space
sorted_pts_temp = sortrows(Points',1);
sorted_pts = sorted_pts_temp';
% calculate the farthest point from the line segment joining first and last
% point
for ii = 2:edx-1
    d = penDistance(sorted_pts(axes_info,ii),sorted_pts(axes_info,1),sorted_pts(axes_info,edx));
    if d > dmax
        idx = ii;
        dmax = d;
    end
end
if dmax > epsilon
    % recursive call
    recResult1 = DouglasPeucker(sorted_pts(:,1:idx),epsilon,axes_info);
    recResult2 = DouglasPeucker(sorted_pts(:,idx:edx),epsilon,axes_info);
    result = [recResult1(:,1:size(recResult1,2)-1) recResult2(:,1:size(recResult2,2))];
else
    result = [sorted_pts(:,1) sorted_pts(:,edx)];
end
% plot(sorted_pts(:,1),sorted_pts(:,2),'.')
% hold on
% plot(result(:,1),result(:,2),'.')
% hold off
% If max distance is greater than epsilon, recursively simplify
    function d = penDistance(Pp, P1, P2)
        % find the distance between a Point Pp and a line segment between P1, P2.
        d = abs((P2(2,1)-P1(2,1))*Pp(1,1) - (P2(1,1)-P1(1,1))*Pp(2,1) + P2(1,1)*P1(2,1) - P2(2,1)*P1(1,1)) ...
            / sqrt((P2(2,1)-P1(2,1))^2 + (P2(1,1)-P1(1,1))^2);
    end
end