function     [digit13dcoords,digit23dcoords,digit33dcoords,digit43dcoords] = analyzeManualTrialData



    workingDirectory= uigetdir('\\172.20.138.142\RecordingsLeventhal3\SkilledReaching');

    workingDirectoryParts = strsplit(workingDirectory,filesep);
    trialName = workingDirectoryParts{end};
    
    
    %score data pull
    scorePaths = workingDirectory; 
    folderPaths = workingDirectory; 
    scoreLookup = dir(fullfile(scorePaths,'*.csv'));
  
    if strfind(scoreLookup(1).name, '._') %Cork noticed in fullfile .csv where have to pull second element of scorelookup
        scoreData = scoreVideoData(fullfile(scorePaths,scoreLookup(2).name),folderPaths);
    else
         scoreData = scoreVideoData(fullfile(scorePaths,scoreLookup(1).name),folderPaths);
    end
    
    scoreData = scoreData(:,2);

    disp(['Scoring: ',scorePaths]);
   
    reachesWithScore1 = 0;
    reachesWithScoreNot1 = 0;
    totalNumReaches = 0;
    
    for z= 1:length(scoreData)
        if cell2mat(scoreData(z)) == 1
            reachesWithScore1= reachesWithScore1 +1;
        else
            reachesWithScoreNot1 =reachesWithScoreNot1 +1;
        end
        
        if cell2mat(scoreData(z)) == 0|| 2 || 4 || 7
            totalNumReaches = totalNumReaches +1; 
        end
           
    end
    
        
    % load all the .mat trials created for each video, from each angle
    leftTrials = dir(fullfile(workingDirectory,'left','manual_trials','*.mat'));
    centerTrials = dir(fullfile(workingDirectory,'center','manual_trials','*.mat'))
    rightTrials = dir(fullfile(workingDirectory,'right','manual_trials','*.mat'));
    
    
    disp('number of left trials =')
    disp(numel(leftTrials))
    disp('number of center trials =')
    disp(numel(centerTrials))
    disp('number of right trials =')
    disp(numel(rightTrials))
 
    if(numel(leftTrials) == numel(centerTrials) && numel(leftTrials) == numel(rightTrials))
        
        % load the pawCenter variables from the trial files
        allLeftPawCenters = loadPawCenters(leftTrials,fullfile(workingDirectory,'left','manual_trials'));
        allCenterPawCenters = loadPawCenters(centerTrials,fullfile(workingDirectory,'center','manual_trials'));
        allRightPawCenters = loadPawCenters(rightTrials,fullfile(workingDirectory,'right','manual_trials'));
        
        allLeftPelletCenters = loadPelletCenters(leftTrials,fullfile(workingDirectory,'left','manual_trials'));
        allCenterPelletCenters = loadPelletCenters(centerTrials,fullfile(workingDirectory,'center','manual_trials'));
        allRightPelletCenters = loadPelletCenters(rightTrials,fullfile(workingDirectory,'right','manual_trials'));
    
        
        allLeftMcpHulls= loadMcpHulls(leftTrials,fullfile(workingDirectory,'left','manual_trials'));
        allCenterMcpHulls = loadMcpHulls(centerTrials,fullfile(workingDirectory,'center','manual_trials'));
        allRightMcpHulls = loadMcpHulls(rightTrials,fullfile(workingDirectory,'right','manual_trials'));
        
        
        allLeftMphHulls= loadMphHulls(leftTrials,fullfile(workingDirectory,'left','manual_trials'));
        allCenterMphHulls = loadMphHulls(centerTrials,fullfile(workingDirectory,'center','manual_trials'));
        allRightMphHulls = loadMphHulls(rightTrials,fullfile(workingDirectory,'right','manual_trials'));
        
        allLeftDphHulls= loadDphHulls(leftTrials,fullfile(workingDirectory,'left','manual_trials'));
        allCenterDphHulls = loadDphHulls(centerTrials,fullfile(workingDirectory,'center','manual_trials'));
        allRightDphHulls = loadDphHulls(rightTrials,fullfile(workingDirectory,'right','manual_trials'));
        
   
%         pawLeftCenterDistances = calcPawCenterDistances(allLeftPelletCenters, allLeftPawCenters);
%         pawCenterCenterDistances = calcPawCenterDistances(allCenterPelletCenters, allCenterPawCenters);
%         pawRightCenterDistances = calcPawCenterDistances(allRightPelletCenters, allRightPawCenters);
%     
    end
    
    
    
    %[digit1MphPelletDist, digit2MphPelletDist, digit3MphPelletDist, digit4MphPelletDist ] =calc3DistancesfromPellet(allRightPelletCenters,allRightMphHulls, allCenterPelletCenters,allCenterMphHulls,  allLeftPelletCenters,allLeftMphHulls)
    [digit1DphPelletDist, digit2DphPelletDist, digit3DphPelletDist, digit4DphPelletDist ] =calc3DistancesfromPellet(allRightPelletCenters,allRightDphHulls, allCenterPelletCenters,allCenterDphHulls,  allLeftPelletCenters,allLeftDphHulls)
    [distanceWithScoresof1, distanceWithScoresofNot1] = plotDistanceResults(digit1DphPelletDist,digit2DphPelletDist,digit3DphPelletDist,digit4DphPelletDist,scoreData)
    %[distanceWithScoresof1, distanceWithScoresofNot1] = plotDistanceResults(digit1MphPelletDist,digit2MphPelletDist,digit3MphPelletDist,digit4MphPelletDist,scoreData)
    %distance3d =calcPawCenter3Distances(allRightPawCenters, allRightPelletCenters,allCenterPawCenters, allCenterPelletCenters )
    %[digit1DistCenter, digit2DistCenter, digit3DistCenter, digit4DistCenter  ] =calcMcp3Distances(allRightPawCenters,allRightMcpHulls, allCenterPawCenters,allCenterMcpHulls,  allLeftPawCenters,allLeftMcpHulls)

    
  [digit13dcoords,digit23dcoords,digit33dcoords,digit43dcoords] = pawSpread(allRightDphHulls, allCenterDphHulls, allLeftDphHulls)
  [distanceWithScoresof1, distanceWithScoresofNot1] = plotPawSpread(scoreData,digit13dcoords, digit23dcoords, digit33dcoords, digit43dcoords)

end


% Load and return the pawCenters variable from a trial file
function allPawCenters=loadPawCenters(trials,trialsPath)
    allPawCenters = cell(1,numel(trials));
    for i=1:numel(trials)
        load(fullfile(trialsPath,trials(i).name));
        allPawCenters{i} = manual_paw_centers; % "pawCenters" variable is loaded via .mat file
    end
end

% Load and return the pelletCenters variable from the trial file
function allPelletCenters=loadPelletCenters(trials,trialsPath)
    allPelletCenters = cell(1,numel(trials));
    for i=1:numel(trials)
        load(fullfile(trialsPath,trials(i).name));
        allPelletCenters{i} = {pellet_center_x,pellet_center_y}; % "pelletCenters" variable is loaded via .mat file
    end
end


% Load and return the mcp variables from the trial file
function allMcpHulls=loadMcpHulls(trials,trialsPath)
        allMcpHulls = cell(1,numel(trials));
    for i=1:numel(trials)
        load(fullfile(trialsPath,trials(i).name));
        for j=1:length(mcp_hulls)
            allMcpHulls{i,j} = mcp_hulls{1,j}; %"mat file
        end
    end
end


% Load and return the MPH variables from the trial file
function allMphHulls=loadMphHulls(trials,trialsPath)
        allMphHulls = cell(1,numel(trials));
    for i=1:numel(trials)
        load(fullfile(trialsPath,trials(i).name));
        for j=1:length(mph_hulls)
            allMphHulls{i,j} = mph_hulls{1,j}; %"mat file
        end
    end
end

% Load and return the DPH variables from the trial file
function allDphHulls=loadDphHulls(trials,trialsPath)
        allDphHulls = cell(1,numel(trials));
    for i=1:numel(trials)
        load(fullfile(trialsPath,trials(i).name));
        for j=1:length(dph_hulls)
            allDphHulls{i,j} = dph_hulls{1,j}; %"mat file
        end
    end
end



%Load and return the distance from the center of the pellet to the center
%of the paw for the three given prespective 
function distance =calcPawCenterDistances(pelletCenters, allPawCenters)
    for i =1:length(allPawCenters)
       framePelletCenters = pelletCenters{1,i};
       framePawCenters = allPawCenters{1,i};
       for j =1:length(framePawCenters)
           framePawCenterCords =   framePawCenters(j,:);
           distance{i,j} = sqrt((cell2mat(framePelletCenters(1))-framePawCenterCords(1))^2+(cell2mat(framePelletCenters(2))-framePawCenterCords(2))^2);
       end
    end
end

% 
function distance3dpawcenter =calcPawCenter3Distances(allRightPawCenters, allRightPelletCenters,allCenterPawCenters, allCenterPelletCenters )
   for i = 1:length(allRightPawCenters)
       rightFramePawCenter    = allRightPawCenters{1,i};
       centerFramePawCenter   = allCenterPawCenters{1,i};
       
       rightFramePelletCenter    = allRightPelletCenters{1,i};
       centerFramePelletCenter   = allCenterPelletCenters{1,i};
       
       for j =1:length(rightFramePawCenter)
            framePawCenterCords = centerFramePawCenter(j,:); %x,y cords
            framePawRightCords  = rightFramePawCenter(j,:); %z-coord is the x cord in this array
            
            framePelletCenterCords = centerFramePelletCenter(1,:); %x,y cords
            framePelletRightCords  = rightFramePelletCenter (1,:); %z-cord is the x cord in this array
            
            
            distance3dpawcenter{i,j} = sqrt(((cell2mat(framePelletCenterCords(1)) - framePawCenterCords(1))^2)+((cell2mat(framePelletCenterCords(2))-framePawCenterCords(2))^2)+((cell2mat(framePelletRightCords(1))- framePawRightCords(1))^2)); %x ^2 + y^2 + z^2
       end

   end
end

function [digit1Dist, digit2Dist, digit3Dist, digit4Dist] =calc3DistancesfromPellet(allRightPelletCenters,allRightMcpHulls, allCenterPelletCenters,allCenterMcpHulls,  allLeftPelletCenters,allLeftMcpHulls)
   for i = 1:length(allRightPelletCenters)
       for j =1:length(allRightMcpHulls(1,:))
           rightFramePawCenter  =   allRightPelletCenters{1,i};
           rightFramePawHulls   =   allRightMcpHulls{i,j};

           centerFramePawCenter   =  allCenterPelletCenters{1,i};
           centerFramePawHulls    =  allCenterMcpHulls{i,j};


           leftFramePawCenter   =  allLeftPelletCenters{1,i};
           leftFramePawHulls    =  allLeftMcpHulls{i,j};

               
          for k = 1:length(rightFramePawHulls)
             
            framePawCenterCords  = cell2mat(centerFramePawCenter);
            centerFramePawHullCords = cell2mat(centerFramePawHulls(k,:));
            
            framePawRightCords  = cell2mat(rightFramePawCenter);
            rightFramePawHullCords = cell2mat(rightFramePawHulls(k,:));
            
            framePawLeftCords  = cell2mat(leftFramePawCenter);
            leftFramePawHullCords = cell2mat(leftFramePawHulls(k,:));

                
                    if rightFramePawHullCords(1) ~= 0 && centerFramePawHullCords(1) ~= 0;  
                        digitDistCenter{i,j} = sqrt((centerFramePawHullCords(1)-framePawCenterCords(1))^2+(centerFramePawHullCords(2)-framePawCenterCords(2))^2+(framePawRightCords(1)-rightFramePawHullCords(1))^2);
                    elseif  rightFramePawHullCords(1) == 0 && centerFramePawHullCords(1) ~= 0 &&    leftFramePawHullCords(1) ~=0 
                        digitDistCenter{i,j} = sqrt((centerFramePawHullCords(1)-framePawCenterCords(1))^2+(centerFramePawHullCords(2)-framePawCenterCords(2))^2+(leftFramePawHullCords(1)-framePawLeftCords(1))^2);
                    else
                        disp('check')
                        digitDistCenter{i,j}=0;
                    end
                    
                   
                if     k == 1
                    digit1Dist {i,j} = digitDistCenter {i,j};
                         
                elseif k == 2
                    digit2Dist{i,j} = digitDistCenter {i,j};
                         
                elseif k == 3
                    digit3Dist{i,j} = digitDistCenter{i,j};
                         
                elseif k == 4
                    digit4Dist{i,j} = digitDistCenter{i,j};
                end
                
           
          end
       end
   end
end

function [distanceWithScoresof1, distanceWithScoresofNot1]= plotDistanceResults(digit1,digit2,digit3,digit4,scoreData)
    for i =1:4
    
     if i==1
        data = digit1;
     elseif i== 2
        data = digit2;
     elseif i==3
        data = digit3;
     else
        data = digit4; 
     end
     
     
     counter1 = 1;
     counter2 = 1;
     


     for j=1:length(data)
         if cell2mat(scoreData(j)) == 1
             distanceWithScoresof1{counter1} = cell2mat(data(j,:));
             %ylabel(strcat('digit',num2str(i)))
             %plot(frames,cell2mat(data(j,:)),'r')
             counter1  =counter1+1;          
         else
              distanceWithScoresofNot1{counter2} = cell2mat(data(j,:));
              %ylabel(strcat('digit',num2str(i)))
              %plot(frames,cell2mat(data(j,:)),'b')
              counter2  =counter2+1;
         end
            hold on
     end
             for k = 1:length(distanceWithScoresof1)
                 distanceHolder = cell2mat(distanceWithScoresof1(k));
                 for l= 1:length(distanceHolder)
                        allDistances1{k,l} =  distanceHolder(l) ;
                 end
             end
             
           
            
             
             
              for k = 1:length(distanceWithScoresofNot1)
                 distanceHolder = cell2mat(distanceWithScoresofNot1(k));
                 for l= 1:length(distanceHolder)
                        allDistancesNot1{k,l} =  distanceHolder(l) ;
                 end
              end
             
             
             averageDistance1= nanmean(cell2mat(allDistances1)) 
             averageDistanceNot1= nanmean(cell2mat(allDistancesNot1))
             
             
             
             for m= 1:5
                stdAverageDistance1(m) = std(cell2mat(allDistances1(:,m)));
                stdAverageDistanceNot1(m) = std(cell2mat(allDistancesNot1(:,m)));
             end
             
             
            figure(1) 
            subplot(4,1,i)
            time = [0:(1/30):4*(1/30)];
            xlabel('time')
            ylabel(strcat('digit',num2str(i)))
            ylim([0 150])
            hold on
            errorbar(time, averageDistance1,stdAverageDistance1,'r')
            errorbar(time, averageDistanceNot1,stdAverageDistanceNot1,'b')
            
             
%            figure(2)
%            averageVelocity1 = diff(averageDistance1,1)
%            averageVelocityNot1 = diff(averageDistanceNot1,1)
%            subplot(4,1,i)
%            xlabel('time')
%            ylabel(strcat('digit',num2str(i)))
%            hold on
%            plot(averageVelocity1,'r')
%            plot(averageVelocityNot1,'b')
%            
%                    
%            figure(3)
%            averageAccel1 = diff(averageDistance1,2)
%            averageAccelNot1 = diff(averageDistanceNot1,2)
%            subplot(4,1,i)
%            xlabel('time')
%            ylabel(strcat('digit',num2str(i)))
%            hold on
%            plot(averageAccel1,'r')
%            plot(averageAccelNot1,'b')
            
    end
end

function [digit13dcoords,digit23dcoords,digit33dcoords,digit43dcoords] =pawSpread(allRightHulls, allCenterHulls, allLeftHulls)

    digit13dcoords = [];
    digit23dcoords = [];
    digit33dcoords = [];
    digit43dcoords = [];


    for i = 1:length(allRightHulls)
           for j =1:length(allRightHulls(1,:))
               rightFramePawHulls   =   allRightHulls{i,j};

               centerFramePawHulls    =  allCenterHulls{i,j};

               leftFramePawHulls    =  allLeftHulls{i,j};


              for k = 1:length(rightFramePawHulls)

                centerFramePawHullCords = cell2mat(centerFramePawHulls(k,:))

                rightFramePawHullCords = cell2mat(rightFramePawHulls(k,:));

                leftFramePawHullCords = cell2mat(leftFramePawHulls(k,:))
                
                if rightFramePawHullCords(1) ~= 0 && centerFramePawHullCords(1) ~= 0  
                    coord3dDataHold = [centerFramePawHullCords(1),centerFramePawHullCords(2),rightFramePawHullCords(1)];
                elseif  rightFramePawHullCords(1) == 0 && centerFramePawHullCords(1) ~= 0 &&    leftFramePawHullCords(1) ~=0 
                    coord3dDataHold = [centerFramePawHullCords(1),centerFramePawHullCords(2),rightFramePawHullCords(1)];
                else
                    coord3dDataHold = [0,0,0];
                end
                   
                if     k == 1
                    digit13dcoords{i,j} = coord3dDataHold;
                         
                elseif k == 2
                    digit23dcoords{i,j} = coord3dDataHold;
                         
                elseif k == 3
                    digit33dcoords{i,j} = coord3dDataHold;
                         
                elseif k == 4
                    digit43dcoords{i,j} =  coord3dDataHold;
                end

              end
           end
       end
end

function  [ distanceWithScoresof1, distanceWithScoresofNot1]= plotPawSpread(scoreData, digit13dcoords, digit23dcoords, digit33dcoords, digit43dcoords)

            for i=1:length(digit13dcoords)
                    for j=1:length(digit13dcoords(1,:))
                        digit1coordHold = cell2mat(digit13dcoords(i,j));
                        digit2coordHold = cell2mat(digit23dcoords(i,j));
                        digit3coordHold = cell2mat(digit33dcoords(i,j));
                        digit4coordHold = cell2mat(digit43dcoords(i,j));
                        
                        if digit1coordHold(1) ~=0 && digit2coordHold(1)~0
                            digit1to2Dist{i,j} = sqrt((digit2coordHold(1)-digit1coordHold(1))^2+(digit2coordHold(2)-digit1coordHold(2))^2+(digit2coordHold(3)-digit1coordHold(3))^2)
                        end
                        
                        
                        if digit2coordHold(1) ~=0 && digit3coordHold(1)~0
                            digit2to3Dist{i,j} = sqrt((digit3coordHold(1)-digit2coordHold(1))^2+(digit3coordHold(2)-digit2coordHold(2))^2+(digit3coordHold(3)-digit2coordHold(3))^2)
                        end
                        
                        if digit3coordHold(1) ~=0 && digit4coordHold(1)~0
                            digit4to3Dist{i,j} = sqrt((digit4coordHold(1)-digit3coordHold(1))^2+(digit4coordHold(2)-digit3coordHold(2))^2+(digit4coordHold(3)-digit3coordHold(3))^2)
                        end
                        
                        if digit1coordHold(1) ~=0 && digit4coordHold(1)~0
                            digit4to1Dist{i,j} = sqrt((digit4coordHold(1)-digit1coordHold(1))^2+(digit4coordHold(2)-digit1coordHold(2))^2+(digit4coordHold(3)-digit1coordHold(3))^2)
                        end
                    end
                end
                

                
            
                
            
            data = digit4to1Dist; % This is the data being plotted
            
            
            
            counter1 = 1;
            counter2 = 1;
            for j=1:length(data)
                 if cell2mat(scoreData(j)) == 1
                     distanceWithScoresof1{counter1} = cell2mat(data(j,:));
                     %ylabel(strcat('digit',num2str(i)))
                     %plot(frames,cell2mat(data(j,:)),'r')
                     counter1  =counter1+1;          
                 else
                      distanceWithScoresofNot1{counter2} = cell2mat(data(j,:));
                      %ylabel(strcat('digit',num2str(i)))
                      %plot(frames,cell2mat(data(j,:)),'b')
                      counter2  =counter2+1;
                 end
             end
                
           
             for k = 1:length(distanceWithScoresof1)
                 distanceHolder = cell2mat(distanceWithScoresof1(k));
                 for l= 1:length(distanceHolder)
                        allDistances1{k,l} =  distanceHolder(l) ;
                 end
             end
             
           
            
             
             
              for k = 1:length(distanceWithScoresofNot1)
                 distanceHolder = cell2mat(distanceWithScoresofNot1(k));
                 for l= 1:length(distanceHolder)
                        allDistancesNot1{k,l} =  distanceHolder(l) ;
                 end
              end
           
             
            
             for i = 1:length(allDistances1(:,1))
                for j =1:length(allDistances1(1,:))
                    if allDistances1{i,j} > 0;
                         Distance1(i,j) = allDistances1{i,j};
                    else  
                          Distance1(i,j) = 0; 
                    end
                end
             end
             
              for i = 1:length(allDistancesNot1(:,1))
                for j =1:length(allDistancesNot1(1,:))
                    if allDistancesNot1{i,j} > 0;
                         DistanceNot1(i,j) = allDistancesNot1{i,j};
                    else  
                         DistanceNot1(i,j) = 0; 
                    end
                end
              end
             
             averageDistance1= nanmean(Distance1) ;
             averageDistanceNot1= nanmean(DistanceNot1);
             
              size(Distance1)
              size(DistanceNot1)
             
             for m= 1:length(Distance1(1,:))
                semAverageDistance1(m) = std(Distance1(:,m))/sqrt(length(Distance1(:,m)));
             end
             
             for m= 1:length(DistanceNot1(1,:))
                semAverageDistanceNot1(m) = std(DistanceNot1(:,m))/sqrt(length(DistanceNot1(:,m)));
             end
            
            time = [0:(1/30):4*(1/30)];
              
            figure
            set(gca,'ylim',[0 260])
            hold on
            
 
            title('Paw Spread: Distance between digit 1 & 4')
            errorbar(time(1:length(averageDistance1)), averageDistance1,semAverageDistance1,'r')
            errorbar(time(1:length(averageDistanceNot1)), averageDistanceNot1,semAverageDistanceNot1,'b')
            legend('Scores 1', 'Scores Not 1')
            
end