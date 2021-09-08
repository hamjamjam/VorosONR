%% Compare Across Light Transitions -- Single Subject
% USER MUST INPUT FILENAMES BELOW; may also need to change ylim 

clear;
close all;
%%
run profileRandomizer.m
add4 = 4;
if subjNum==0
    add4=3;
end
[~,reorder] = sort(order);
for i = 1:6
    for j = 1:4
        counter = (i-1)*4+j;
        allFilenames{i,j} = sprintf('Subject%d_trial%d.txt',subjNum,reorder(counter)+add4);
    end
    YLIMS(i,1) = min(T.angVels{i*4});
    YLIMS(i,2) = max(T.angVels{i*4});
end

plotAngVels = input('Do you want to plot headset angular velocity data? no[0] or yes [1]:  ');
plotObserver = input('Do you want to plot Observer expectations? no[0] or yes [1]:  ');

%% USER INPUT
for k = 1:6
    filenames = allFilenames(k,:);
    herepath = pwd;
    logpath = fullfile(pwd,'\Assets\logs');
    dataString = sprintf('ONR-Subject-Data\\Subject%d',subjNum);
    logpath = fullfile(pwd,dataString);
    compareProfiles = figure();


    % create a panel for each available light transition file
    for j = 1:length(filenames)

        cd(logpath);
        fid = fopen(filenames{j},'r');
        trialNo = extractBetween(filenames{j},'trial','.txt');
        txt = textscan(fid,'%s','delimiter','\n'); 
        fclose(fid);
        cd(herepath);

        %flipped = 1; %flipped = 1 if controllers were in the wrong hands(!)
        flipped = 0; %flipped = 0 if controllers were in CORRECT hands

        if flipped == 1
            flip = -1;
        else
            flip = 1;
        end

        currentLightState = 0;
        currentPerceivedPosition = 0;

        % initialize variables from log file
        time = [];
        angularVelocity = [];
        trackpadTimes = [];
        stillTimesD = [];
        stillTimesU = [];
        perceivedPositions = [];
        lightChangeTimes = [0];
        lightStates = [0];
        profStartTime = [];
        profName = {};
        clicks = [];
        adjust = 0;

        % Parse text file
        for i=3:size(txt{1})
            line = txt{1}{i};
            if line(1:4) == "Time"
                %record time
                mycell = split(line, ' ');
                tempTime = str2double(mycell{2});
                time = [time tempTime];

            elseif line(1) == "A"
                %record angular velocity
                mycell = split(line, '(');
                mycell2 = split(mycell{2}, ')');
                mycell3 = split(mycell2{1}, ', ');
                omega = str2double(mycell3);
                angularVelocity = [angularVelocity omega];
            elseif line(1:5) == "Right"
                if line(1:19) == "Right Trackpad Down"
                    %record right trackpad press
                    mycell = split(line, ' ');
                    tempTime = str2double(mycell{5});

                    currentPerceivedPosition = currentPerceivedPosition + 90*flip;
                    perceivedPositions = [perceivedPositions currentPerceivedPosition];
                    trackpadTimes = [trackpadTimes tempTime];

                    % 1 means right trackpad down
                    clicks = [clicks; tempTime 1];
                end
            elseif line(1:4) == "Left"
                if line(1:18) == "Left Trackpad Down"
                    %record left trackpad press
                    mycell = split(line, ' ');
                    tempTime = str2double(mycell{5});

                    currentPerceivedPosition = currentPerceivedPosition - 90*flip;
                    perceivedPositions = [perceivedPositions currentPerceivedPosition];
                    trackpadTimes = [trackpadTimes tempTime];

                    % 2 means left trackpad down
                    clicks = [clicks; tempTime 2];
                end
            elseif line(1:7) == "Trigger"
                if line(1:12) == "Trigger Down"
                    % record trigger downpress
                    mycell = split(line, ' ');
                    tempTime = str2double(mycell{4});
                    stillTimesD = [stillTimesD tempTime];

                    % 3 means trigger down
                    clicks = [clicks; tempTime 3];
                elseif line(1:10) == "Trigger Up"
                    % record trigger release
                    mycell = split(line, ' ');
                    tempTime = str2double(mycell{4});
                    stillTimesU = [stillTimesU tempTime];

                    % 4 means trigger up
                    clicks = [clicks; tempTime 4];

                    % add trigger up click as a trackpad click
                    %trackpadTimes = [trackpadTimes tempTime];
                    % BUT assume perceived position hasn't changed since last trackpad click
                    %perceivedPositions = [perceivedPositions currentPerceivedPosition];
                end
%             elseif line(1:5) == "Light"
%                 %record change of lighting state
%                 mycell = split(line, ' ');
% 
%                 % Kieran commented out for testing 6/7/21 -- now, lightState is
%                 % updated every timestep, so the 'change' isn't applicable anymore.
%                 %currentLightState = currentLightState*(-1)+1;
%                 lightChangeTimes = [lightChangeTimes tempTime];
%                 %lightStates = [lightStates currentLightState];
% 
%                 % Kieran added 6/7/21
%                 lightStates = [lightStates str2num(mycell{2})];

            elseif line(1:2) == "St"
                % record times profiles are run
                mycell = split(line, ' ');
                profStartTime = [profStartTime str2num(mycell{2})];

            elseif line(1:2) == "Pr"
                % record times profiles are run
                mycell = split(line, ' ');
                profName = mycell{3};
            end

        end

        if ~exist('profStartTime','var')
            profStartTime = 0;
        else
            profStartTime = profStartTime(1);
        end
 

        % calculate inferred perceived velocities 
        inferredAngularVelocity = [];
        inferredAngularVelocityTimes = [];
        for i = 2:length(trackpadTimes)
            tempInferredAngularVelocity = (perceivedPositions(i) - perceivedPositions(i-1))/(trackpadTimes(i) - trackpadTimes(i-1));
            inferredAngularVelocity = [inferredAngularVelocity tempInferredAngularVelocity*pi/180];
            tempInferredAngularVelocityTimes = (trackpadTimes(i) + trackpadTimes(i-1))/2;
            inferredAngularVelocityTimes = [inferredAngularVelocityTimes tempInferredAngularVelocityTimes];
        end
        inferredAngularVelocityTimes = trackpadTimes(2:end);

        % concatenate velocity and still perceptions & associated times
        allInferredValues(:,1) = [inferredAngularVelocityTimes, stillTimesD, stillTimesU];
        allInferredValues(:,2) = [inferredAngularVelocity zeros(1,length(stillTimesD)) zeros(1,length(stillTimesU))];
        allInferredValues = sortrows(allInferredValues);

        % determines which profile was run
        whichProf = 0;
        if exist('profName','var')
           for i = 1:length(T.fileNames)
               if strcmp(T.fileNames{i},strcat(profName,'.txt'))
                   whichProf = i;
               end
           end
        end
        
        % pulls the velocity levels and timings for that profile
        if whichProf > 0
            DATA = profileWriterFxn(T(whichProf,:), pad, transition, 0, 'off');
        end       
        
        % send warnings about likely misclicks
        angVel = ones(length(clicks)-1,1)*-99999;
        times2 = zeros(length(angVel),1);
        for i = 1:length(clicks)-1
            if clicks(i+1,2) == 1
                times2(i) = clicks(i+1,1);
                angVel(i) = -90/(clicks(i+1,1)-clicks(i,1));
                if clicks(i,2) == 2 || clicks(i,2) == 3
                    warning('Potential mis-click in %s at %0.3f seconds. (Profile: %s)',allFilenames{k,j}, clicks(i,1)-profStartTime, profName);
                end
            elseif clicks(i+1,2) == 2
                times2(i) = clicks(i+1,1);
                angVel(i) = 90/(clicks(i+1,1)-clicks(i,1));
                if clicks(i,2) == 1 || clicks(i,2) == 3
                    warning('Potential mis-click in %s at %0.3f seconds. (Profile: %s)',allFilenames{k,j}, clicks(i,1)-profStartTime, profName);
                end
            elseif clicks(i+1,2) == 3
                times2(i) = clicks(i+1,1);
                angVel(i) = 0;
            elseif clicks(i+1,2) == 4
                times2(i) = clicks(i+1,1);
                angVel(i) = 0;
            end
        end
        %{
        % Kieran working on code to ramp down to the zero clicks
        % it isn't going well
        % 7/13/2021
        c = 2;
        while c < length(yb)
            if yb(c)==0 && yb(c-1)~=0
                nextDown = clicks(clicks(:,2)==3)-profStartTime; 
                nextDownIndex = min(find(nextDown>xb(c))); % finds next downclick time
                nextDown = nextDown(nextDownIndex);
                
                d=c;
                while ~isempty(nextDown) && xb(d)<nextDown && d < length(yb)  
                    yb(d) = [];
                    xb(d) = [];
                    c = c+1;
                end
            end
            
            c = c+1;
        end
        %}        

%% %%%%%%%%%%%%% plotting %%%%%%%%%%%%%%%%%        
        % set up the figure/subplot
        figure(compareProfiles);
        subplot(length(filenames),1,j);
        hold on;  
        
        % Plot light states
        lightTimes = 1/90:1/90:length(DATA)/90;
        area(lightTimes, (DATA(:,2)-1)*100, 'FaceColor', [0.8 0.8 0.8],'EdgeColor',[1,1,1]); % gray above y=0
        area(lightTimes, (DATA(:,2)-1)*-100,'FaceColor', [0.8 0.8 0.8],'EdgeColor',[1,1,1]); % gray below y=0

        plot((1:length(DATA))/90, DATA(:,1),'k:','LineWidth', 2); % plots the velocity profile in black
       
        % Plot headset velocity if desired
        if plotAngVels
            plot(time(2:end)-profStartTime, -180/pi*angularVelocity(2,2:end), 'color', [0.3961 0.6745 0.9216]); % plots measured angular velocities in a pretty blue
        end
        
        [xb,yb]=stairs(times2-profStartTime, angVel);
        plot(xb,[yb(3:end); 0; 0], 'color', [0 0.5 0], 'LineWidth', 2); % plots the inferred perceived angular velocities as a staircase function 
        
        plot(stillTimesD-profStartTime, zeros(1,length(stillTimesD)), 'rv'); % plots the trigger downclicks
        plot(stillTimesU-profStartTime, zeros(1,length(stillTimesU)), 'r^'); %plots the trigger upclicks
        
        % plot the observer model results
        if plotObserver
            cd Observer
            run AnalysisForSOE1a.m
            cd(herepath)
        end
        
        plot(time(2:end), zeros(1,length(time(2:end))),'--','color', [0.5,0.5,0.5]); % plots x-axis

        % final plot formatting
        trialNoStr = strcat('Trial #',trialNo{:});
        
        YLIM = [YLIMS(k,1)-30 YLIMS(k,2)+30];
        xlim([0 lightTimes(end)]); ylim(YLIM);
        ylabel({trialNoStr;'Ang Vel [deg/s]'});
        xlabel('Time [sec]');

        hold off;
        clear allInferredValues
    end
    
    axP = get(gca,'Position');
    
    if plotAngVels && plotObserver
        lgd0 = legend('Lights Off','', 'Profile', 'Ang Vel', 'Inferred Per Ang Vel', '', '',   'Observer Model',  'Location', 'SouthOutside', 'Orientation', 'Horizontal');
    elseif plotAngVels && ~plotObserver
        lgd0 = legend('Lights Off','', 'Profile', 'Ang Vel', 'Inferred Per Ang Vel', '', '',  'Location', 'SouthOutside', 'Orientation', 'Horizontal');
    elseif ~plotAngVels && plotObserver
        lgd0 = legend('Lights Off','', 'Profile', 'Inferred Per Ang Vel', '', '', 'Observer Model',  'Location', 'SouthOutside', 'Orientation', 'Horizontal');
    elseif ~plotAngVels && ~plotObserver
        lgd0 = legend('Lights Off','', 'Profile', 'Inferred Per Ang Vel', '', '',   'Location', 'SouthOutside', 'Orientation', 'Horizontal');
    end 
    set(gca, 'Position', axP)
    sgtitle('Compare Light Transitions Across Single Subject');
    
    figName = strcat('plot_',extractBefore(profName,'--'));
    cd(logpath);
    % saveas(compareProfiles,figName,'jpeg'); % Does not want to open these files
    saveas(compareProfiles,figName,'fig');
    cd(herepath);
end