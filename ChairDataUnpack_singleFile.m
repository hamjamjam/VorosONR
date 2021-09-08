%% single file unpack
% USER MUST INPUT FILENAME BELOW

cd C:\Users\ander\Documents\VorosONR\

clear;
%close all;
%% USER INPUT
filenames = 'Subject102_trial28.txt';
herepath = pwd;
logpath = fullfile(pwd,'\Assets\logs');

%logpath = fullfile(pwd, 'ONR-Subject-Data\Subject1');

%flipped = 1; %flipped = 1 if controllers were in the wrong hands(!)
flipped = 0; %flipped = 0 if controllers were in CORRECT hands

%% PROFILE INPUT -- values used to write the profiles (rotoChairProfileWriter.m)
pad = 1; % set pad length (sec)
transition = 1; % set transition length (sec)

load('T.mat');

%% Read text file
cd(logpath);
fid = fopen(filenames,'r');
txt = textscan(fid,'%s','delimiter','\n'); 
fclose(fid);
cd(herepath);


if flipped == 1
    flip = -1;
else
    flip = 1;
end

currentLightState = 0;
currentPerceivedPosition = 0;

% initialize text variables
time = [];
angularVelocity = [];
rawChairPosition = [];
trackpadTimes = [];
stillTimesD = [];
stillTimesU = [];
perceivedPositions = [];
lightChangeTimes = [0];
lightStates = [0];
chairPosition = [];
profStartTime = [];
profName = {};
leftEye = [];
rightEye = [];
leftGaze = [];
rightGaze = [];
eyeTimes = [];
gazeTimes = [];
%fixPoint = [];

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

    elseif line(1) == "C"
        %record chair position
        mycell = split(line, ' ');

        if ~isempty(chairPosition)
            if (str2double(mycell{3}) - tempChairPosition) > 300
                adjust = adjust + 360;
            elseif (str2double(mycell{3}) - tempChairPosition) < -300
                adjust = adjust - 360;
            end
        end

        tempChairPosition = str2double(mycell{3});
        rawChairPosition = [rawChairPosition tempChairPosition];
        chairPosition = [chairPosition (tempChairPosition - adjust)];


    elseif line(1:5) == "Right"
        if line(1:19) == "Right Trackpad Down"
            %record right trackpad press
            mycell = split(line, ' ');
            tempTime = str2double(mycell{5});

            currentPerceivedPosition = currentPerceivedPosition + 90*flip;
            perceivedPositions = [perceivedPositions currentPerceivedPosition];
            trackpadTimes = [trackpadTimes tempTime];
        end
    elseif line(1:4) == "Left"
        if line(1:18) == "Left Trackpad Down"
            %record left trackpad press
            mycell = split(line, ' ');
            tempTime = str2double(mycell{5});

            currentPerceivedPosition = currentPerceivedPosition - 90*flip;
            perceivedPositions = [perceivedPositions currentPerceivedPosition];
            trackpadTimes = [trackpadTimes tempTime];
        end
    elseif line(1:7) == "Trigger"
        if line(1:12) == "Trigger Down"
            % record trigger downpress
            mycell = split(line, ' ');
            tempTime = str2double(mycell{4});
            stillTimesD = [stillTimesD tempTime];
            
        elseif line(1:10) == "Trigger Up"
            % record trigger release
            mycell = split(line, ' ');
            tempTime = str2double(mycell{4});
            stillTimesU = [stillTimesU tempTime];
            
            % add trigger up click as a trackpad click
            trackpadTimes = [trackpadTimes tempTime];
            % BUT assume perceived position hasn't changed since last trackpad click
            perceivedPositions = [perceivedPositions currentPerceivedPosition];
        end
    elseif line(1:5) == "Light"
        %record change of lighting state
        mycell = split(line, ' ');
        
        % Kieran commented out for testing 6/7/21 -- now, lightState is
        % updated every timestep, so the 'change' isn't applicable anymore.
        %currentLightState = currentLightState*(-1)+1;
        lightChangeTimes = [lightChangeTimes tempTime];
        %lightStates = [lightStates currentLightState];
        
        % Kieran added 6/7/21
        lightStates = [lightStates str2num(mycell{2})];

    elseif line(1:2) == "St"
        % record times profiles are run
        mycell = split(line, ' ');
        profStartTime = [profStartTime str2num(mycell{2})];

    elseif line(1:2) == "Pr"
        % record times profiles are run
        mycell = split(line, ' ');
        profName = mycell{3};
    elseif line(1:4) == "Eyes"
        % parses eye tracking data
        mycell = split(line, ' ');
        leftEye = [leftEye; str2num(mycell{3}(2:end-1)),str2num(mycell{4}(1:end-2))];
        rightEye = [rightEye; str2num(mycell{6}(2:end-1)),str2num(mycell{7}(1:end-2))];      
        eyeTimes = [eyeTimes tempTime];
    elseif line(1:4) == "Gaze"
        % parses eye tracking gaze data
        mycell = split(line, ' ');
        leftGaze = [leftGaze; str2num(mycell{3}(2:end-1)),str2num(mycell{4}(1:end-1)),str2num(mycell{5}(1:end-2))];
        rightGaze = [rightGaze; str2num(mycell{7}(2:end-1)),str2num(mycell{8}(1:end-1)),str2num(mycell{9}(1:end-2))]; 
        gazeTimes = [gazeTimes tempTime];
    end
    
end

chairPosition = chairPosition - chairPosition(20);

inferredAngularVelocity = [];
inferredAngularVelocityTimes = [];

for i = 2:length(trackpadTimes)
    tempInferredAngularVelocity = (perceivedPositions(i) - perceivedPositions(i-1))/(trackpadTimes(i) - trackpadTimes(i-1));
    inferredAngularVelocity = [inferredAngularVelocity tempInferredAngularVelocity*pi/180];
    tempInferredAngularVelocityTimes = (trackpadTimes(i) + trackpadTimes(i-1))/2;
    inferredAngularVelocityTimes = [inferredAngularVelocityTimes tempInferredAngularVelocityTimes];
end

inferredAngularVelocityTimes = trackpadTimes(2:end);

allInferredValues(:,1) = [inferredAngularVelocityTimes, stillTimesD, stillTimesU];
allInferredValues(:,2) = [inferredAngularVelocity zeros(1,length(stillTimesD)) zeros(1,length(stillTimesU))];
allInferredValues = sortrows(allInferredValues);

lightChangeTimes(end+1) = time(end);
lightStates(end+1) = lightStates(end);

%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% angular velocity with light colourblock
angVelfromPos = 2*pi/180 * smooth(diff(chairPosition)/(time(2)-time(1)), 300); % rad/s,  
lightStatesPlot = (lightStates-1)*(-1);
ylimMin = min(angularVelocity(2,:)) - 3;
ylimMax = max(angularVelocity(2,:)) + 3;

bottom = ylimMin;
for i = 1:length(lightStatesPlot)
    if lightStatesPlot(i) == 0
        lightStatesPlot(i) = ylimMin;
    else
        lightStatesPlot(i) = ylimMax;
    end
end

figure('visible','off');
sh = stairs(lightChangeTimes,lightStatesPlot);
x = [sh.XData(1),repelem(sh.XData(2:end),2)];
y = [repelem(sh.YData(1:end-1),2),sh.YData(end)];

fig2 = figure(); fig2.Position = [426   918   560   420];
hold on;

fill([x,fliplr(x)],2*180/pi * [y,bottom*ones(size(y))], [0.8,0.8,0.8],'LineStyle','none') % added 2x multiplier in y so that we can expand ylim

plot(time(2:end), -180/pi*angularVelocity(2,2:end), 'b');
%plot(time(2:end), -180/pi * angVelfromPos, 'b'); 

% scatter(infferedAngularVecloityTimes, infferedAngularVelocity);
fudge = -1;
% plot(inferredAngularVelocityTimes, fudge * 180/pi * inferredAngularVelocity, 'o-', 'color', [0 0.5 0]);
plot(allInferredValues(:,1), fudge * 180/pi * allInferredValues(:,2), 'o-', 'color', [0 0.5 0]);

plot(stillTimesD, zeros(1,length(stillTimesD)), 'rv');
plot(stillTimesU, zeros(1,length(stillTimesU)), 'r^');

% This adds the assumed perception of 0 angular velocity until they press
% the button for the first time. 
% plot([0 inferredAngularVelocityTimes(1)-(inferredAngularVelocityTimes(2)-inferredAngularVelocityTimes(1)) inferredAngularVelocityTimes(1)], fudge * 180/pi * [0 0 inferredAngularVelocity(1)], 'color', [0 0.5 0]);
% And this does the back end towards 0 at the end of the trial
%plot([inferredAngularVelocityTimes(end) inferredAngularVelocityTimes(end)+(inferredAngularVelocityTimes(end)-inferredAngularVelocityTimes(end-1)) time(end)], fudge * 180/pi * [inferredAngularVelocity(end) 0 0], 'color', [0 0.5 0])
plot(time(2:end), zeros(1,length(time(2:end))),'--','color', [0.5,0.5,0.5]);

if ~isempty(stillTimesD)
    legend('Lights Off', 'Angular Velocity','Inferred Perceived Angular Velocity', 'Inferred No Motion', 'Location', 'SouthWest');
else
    legend('Lights Off', 'Angular Velocity','Inferred Perceived Angular Velocity', 'Location', 'SouthWest');
end

ylabel('Angular velocity (deg/s)');
xlabel('Time (s)');

xlim([2.1 time(end)]);
ylim(180/pi * [ylimMin ylimMax]);

saveas(fig2, ['angVel_' filenames(1:end-4) '.png']);




%% Eye tracking data
% eyeAngVel_L = zeros(length(leftGaze),1);
% eyeAngVel_R = zeros(length(rightGaze),1);
% 
% z_vec = [0 1];
% for i = 1:length(leftGaze)
%     if leftGaze(i,1)>=0
%         x_angleL(i) = acosd(dot(-[leftGaze(i,1) leftGaze(i,3)],z_vec)/(norm([leftGaze(i,1) leftGaze(i,3)])));
%     elseif leftGaze(i,1)<0
%         x_angleL(i) = -acosd(dot(-[leftGaze(i,1) leftGaze(i,3)],z_vec)/(norm([leftGaze(i,1) leftGaze(i,3)])));
%     end
%     if x_angleL(i)<0
%         x_angleL(i) = x_angleL(i)+360;
%     end
% 
% end
% 
% for i = 1:length(rightGaze)
%     if rightGaze(i,1)>=0
%         x_angleR(i) = acosd(dot([rightGaze(i,1) rightGaze(i,3)],z_vec)/(norm([rightGaze(i,1) rightGaze(i,3)])));
%     elseif rightGaze(i,1)<0
%         x_angleR(i) = -acosd(dot([rightGaze(i,1) rightGaze(i,3)],z_vec)/(norm([rightGaze(i,1) rightGaze(i,3)])));
%     end
% 
% end
% 
% x_angleL = 180-x_angleL;
% 
% fig4 = figure; fig4.Position = [426   397   560   420];
% fill([x,fliplr(x)]-profStartTime(1),2*180/pi * [y,bottom*ones(size(y))], [0.8,0.8,0.8],'LineStyle','none'); hold on;% added 2x multiplier in y so that we can expand ylim
% 
% plot(eyeTimes-profStartTime(1), (x_angleL),'.'); hold on;
% plot(eyeTimes-profStartTime(1), x_angleR,'.');
% xlabel('time [s]'); ylabel('X Angle [deg]'); legend('left','right');
% xlim([0 110]); ylim([-50 50]);
% 
% % plots profile on right y-axis
% yyaxis right
% plot(time(2:end)-profStartTime(1), -180/pi * angularVelocity(2,2:end), 'color', [0.3961 0.6745 0.9216]);
% if exist('profStartTime','var') && exist('DATA','var')
%     plot((1:length(DATA))/90,DATA(:,1),'-k');
% end
% ylabel('Angular Vel [deg/s]');
% legend('lights','left','right','angular velocity','profile','Location','SouthOutside','Orientation','Horizontal');
% %ylim([0 1]);
%% get the commanded profile information (inputted chair angular velocities, light/noise status)
whichProf = 0;
if exist('profName','var')
   for i = 1:length(T.fileNames)
       if strcmp(T.fileNames{i},strcat(profName,'.txt'))
           whichProf = i;
       end
   end
end

if whichProf >0
    DATA = profileWriterFxn(T(whichProf,:), pad, transition);
end

% % convert chair input powers to angular velocities 
% if DATA(30,1)>0 
%     DATA(:,1) = DATA(:,1)*1.41-13.2;
% else
%     DATA(:,1) = DATA(:,1)*1.5+16.3;
% end
%% Data Output
% startIndex = max(find(eyeTimes<profStartTime(1)));
% EYEDATA = table(eyeTimes(startIndex:end)', x_angleL(startIndex:end)', x_angleR(startIndex:end)', -180/pi *angularVelocity(2,startIndex:end)', lightStates(startIndex:end-2)');
% EYEDATA.Properties.VariableNames = {'time_s','leftEyeAng_deg','rightEyeAng_deg','trueAngVel_dps','visualCues_io'};
% 
% filename = strcat('EyeData_',profName,'.xlsx');
% if exist(filename,'file')
%     delete(filename)
% end
% writetable(EYEDATA,filename)
% 
% % 
% % figure; hold on;
% % plot(EYEDATA.time_s,EYEDATA.leftEyeAng_deg,'.b');
% % plot(EYEDATA.time_s,EYEDATA.rightEyeAng_deg,'.r');
% % plot(EYEDATA.time_s,EYEDATA.trueAngVel_dps);
% % plot(EYEDATA.time_s,EYEDATA.visualCues_io);
% 


%% if a profile was run, plot the angular velocities

fig5 = figure; fig5.Position =  [1002, 396, 560, 420]; hold on;
xlabel('time [s]'); ylabel('Angular Velocity [deg/s]');
title('Compare headset and chair velocity recordings');
plot(time(2:end), -180/pi * angularVelocity(2,2:end));
if exist('profStartTime','var') && exist('DATA','var')
    plot((1:length(DATA))/90+profStartTime(1),DATA(:,1),'k');
end
legend({'Headset','Commanded'});
xlim([2.1 time(end)]);