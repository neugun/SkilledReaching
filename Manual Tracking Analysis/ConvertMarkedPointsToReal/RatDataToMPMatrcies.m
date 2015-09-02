%Titus John
%Leventhal Lab, University of Michigan 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%This scripts takes the rat data and creates the direct and the indirect
%matricies x1 and x2 respectively that are then fed into
%convertMarkedPointstoRealWorld script. 

function  [X1,X2] = RatDataToMPMatrcies(RatData)


    [allPawData] = ReadPawDataFromRatData(RatData);
    
    for i = 1:length(allPawData) 
        pawPointsData = allPawData{1,i};
        [allLeft{i},allCenter{i},allRight{i}] = SplitPawData(pawPointsData);
    end

    
   for i =1%:length(allLeft)
       trialLeft = allLeft{1,i};
       trialCenter = allCenter{1,i};
       for j = 1:5
            frameLeft = cell2mat(trialLeft{1,j});
            frameCenter = cell2mat(trialCenter{1,j}); 
            counterLeft = 1;
            for k = 1:16
                if sum(frameCenter(k,:)) > 0 
                    if sum(frameLeft(k,:)) > 0
                        x1(counterLeft,:) = frameCenter(k,:);
                        x2(counterLeft,:) = frameLeft(k,:);
                        counterLeft = counterLeft + 1;
                    end
               end
            end
           X1{i,j} = x1;
           X2{i,j} = x2;
       end
   end
    
    
end


function [left,center,right] = SplitPawData(pawPointsData)
  overallCounter = 1;
  

  
    for i=1:5
        for j=1:3
            
              counterLeft = 1;
              counterCenter = 1;
              counterRight = 1;
            
            
            for k=overallCounter:(overallCounter+15) 
                if overallCounter<241
                    
                       if j == 1
                            frameLeft(:,counterLeft) =  [pawPointsData(k,7),pawPointsData(k,8)];
                            counterLeft = counterLeft + 1;
                       end
                       
                       if j == 2
                            frameCenter(:,counterCenter) = [pawPointsData(k,7),pawPointsData(k,8)];
                            counterCenter = counterCenter+ 1;
                       end
                       
                       if j ==3 
                            frameRight(:,counterRight) = [pawPointsData(k,7),pawPointsData(k,8)];
                            counterRight = counterRight +1;
                       end
                       
                       overallCounter = overallCounter + 1;
                end
            end
        end
        
        trialLeft{i} = frameLeft';
        trialCenter{i} = frameCenter';
        trialRight{i} = frameRight';
        
    end
    
    
    left = trialLeft;
    center = trialCenter;
    right = trialRight;

end

function [allPawData] = ReadPawDataFromRatData(RatData) 
    allPawData = [];
    Scores=[RatData.VideoFiles.Score]';

    j= 1;
    for i=1:length(Scores)
        if Scores(i) == 1 
            tempAllPawData = RatData.VideoFiles(i).Paw_Points_Tracking_Data;
            
            counter = 1; %This is the counter that represents the actual length of filled data
            for k =1:length(tempAllPawData)
                if sum(cell2mat(tempAllPawData(k,1))) > 0
                    filteredPawData(counter,:) = tempAllPawData(k,:);
                    
                    counter = counter + 1;
                end
            end         
            allPawData{j}= filteredPawData; 
            j = j+1;
        end
    end
end