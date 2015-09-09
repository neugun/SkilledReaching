%Titus John
%Leventhal Lab, University of Michigan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This scripts will take the X1 and the X2 matricies and push them to the
%conver markter poiints to real worl in order to spit out the 3d points for
%a given trial and frame

function [all3dPoints] = RatDatatoReal3Dpoints(RatData)
    load('rubiksX1.mat');
    load('rubiksX2.mat');

    all3dPoints=[];
    
    
    [X1,X2] = RatDataToMPMatrcies(RatData);

    for i=1:length(X1(:,1))
        for j= 1:5
            x1 = X1{i,j};
            x2 = X2{i,j};
    
          if size(x1) > 1
                [points3d,reprojectedPoints,errors] = ConvertMarkedPointsToRealWorld(x1,x2);
                all3dPoints{i,j} = points3d;
          else
               all3dPoints{i,j} = [];
          end
             
        end          
    end

    
%         
%     for i =1:length(all3dPoints(:,1))
%         figure(i)
%         for j=1:5
%             
%         
%             
%             currentFrame = cell2mat(all3dPoints(i,j));
%             x = currentFrame(:,1);
%             y = currentFrame(:,2);
%             z = currentFrame(:,3);
%             scatter3(x,y,z)
%             xlabel('x');ylabel('y');zlabel('z');
%             xlim([-1,1]);ylim([-1 1]),zlim([-1,1]);
%             hold on
%             
%         end
%     end
end





%sqrt((points3d(6,1)-points3d(5,1))^2+(points3d(6,2)-points3d(5,2))^2)