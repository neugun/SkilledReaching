function h=plot1dDistanceScores(allAlignedXyzDistPawCenters,plotFrames,superTitle,lineColor)
    disp('Select the scoring CSV file...');
    [scoreFile,scorePath] = uigetfile({'.csv'});
    %scoreFile = 'Quant scoring R28 20140426.csv'; %REMOVE
    %scorePath = 'C:\Users\Spike Sorter\Documents\MATLAB\SkilledReaching\videos\R0030_20140426a\'; %REMOVE
    scoreData = csvread(fullfile(scorePath,scoreFile));

    if(~isempty(superTitle))
        h = figure('Position', [0,0,1800,800]);
        suptitle(superTitle);
    end

    startFrame = 2;
%     plot1Indexes = find(ismember(scoreData(:,2),[1]));
%     plot2Indexes = find(ismember(scoreData(:,2),[2,3,4,7]));
%     plot1Cells = allAlignedXyzDistPawCenters(plot1Indexes);
    allDistData = [];
    plot1Indexes = ismember(scoreData(:,2),1);
    plot2Indexes = ismember(scoreData(:,2),[2,3,4,7]);
    for i=1:numel(allAlignedXyzDistPawCenters)
        % nans or empties? figure this out!!!
        if(~isempty(allAlignedXyzDistPawCenters{i}) && isa(allAlignedXyzDistPawCenters{i},'double'))
            distData = allAlignedXyzDistPawCenters{i}(startFrame:plotFrames);
            switch scoreData(i,2)
                case 1
                    subplot(1,2,1);
                case {2,3,4,7}
                    subplot(1,2,2);
                otherwise
                    disp(['bad trial: ',num2str(i)]);
                    continue;
            end
            distFilt = smoothn(distData,10,'robust');
            allDistData(i,:) = distFilt; % removes nans so mean works
            %colormapline(startFrame:plotFrames,distFilt,[]);
            hold on;
        else
            disp(['skipped session: ',num2str(i)]);
            plot1Indexes(i) = 0;
            plot2Indexes(i) = 0;
        end
    end
    
    for k=1:2
        h(k) = subplot(1,2,k);
        %view(h(k),[37.5,30]); % az,el
        %view(h(k),azel); % az,el
        xlabel(h(k),'frames');
        ylabel(h(k),'distance (mm)');
        %zlabel(h(k),'z');
        %legend on;
        grid(h(k));
        box(h(k));
        axis(h(k),[0 plotFrames 0 70]); % x y z
        hold on;
        switch k
            case 1
                title(h(k),'First Trial Success - 1');
                plot1Data = allDistData(plot1Indexes,:);
                plot(startFrame:plotFrames,mean(plot1Data),'Color',lineColor,'Marker','o');
                plot(startFrame:plotFrames,mean(plot1Data)+std(plot1Data),'Color',lineColor,'LineStyle','--');
                plot(startFrame:plotFrames,mean(plot1Data)-std(plot1Data),'Color',lineColor,'LineStyle','--');
            case 2
                title(h(k),'Unsuccessful - {2,3,4,7}');
                plot2Data = allDistData(plot2Indexes,:);
                plot(startFrame:plotFrames,mean(plot2Data),'Color',lineColor,'Marker','o');
                plot(startFrame:plotFrames,mean(plot2Data)+std(plot2Data),'Color',lineColor,'LineStyle','--');
                plot(startFrame:plotFrames,mean(plot2Data)-std(plot2Data),'Color',lineColor,'LineStyle','--');
        end
    end
end