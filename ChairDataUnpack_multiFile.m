%% single file unpack
% USER MUST INPUT FILENAME BELOW

clear all;
close all;
%% USER INPUT
% filename = 'P9_13May21_60snolights.txt';
% filename = 'p9_13May_nolights_run2.txt';
filenames = {'Log15.txt','Log16.txt','Log17.txt','Log18.txt'};
herepath = pwd;
logpath = fullfile(pwd,'\Assets\logs');
% filename = 'p9_13May_lightson.txt';
% filename = 'p9_13May_lightsonhalf.txt';
% filename = 'p9_13May_lightsonhalf_run2.txt';
% filename = 'p9_13May_lightsonhalf_run3.txt';


%% Get angular velocities
load('T.mat');
whichProf = 17;
DATA = cell(1,length(filenames));
angVelfromPos = cell(1,length(filenames));
angularVelocity = cell(1,length(filenames));
time = cell(1,length(filenames));
profStartTime = cell(1,length(filenames));

for i = 1:length(filenames)
    [DATA{i}, angVelfromPos{i}, angularVelocity{i}, time{i}, profStartTime{i}] = getAngVel(whichProf,filenames{i},T, herepath, logpath);
end

%% if a profile was run, plot the angular velocities
figure;
leg = cell(1,length(filenames)*3);

for i = 1:length(filenames)
   %figure;
    plot(time{i}(2:end), -180/pi * angVelfromPos{i}); hold on;
    plot(time{i}(2:end), -180/pi * angularVelocity{i}(2,2:end));
    if exist('profStartTime','var')
        plot((1:length(DATA{i}))/90+profStartTime{i}(1),DATA{i}(:,1),'k','Linewidth',2);
    end
    leg{(i-1)*3+1} = sprintf('Position %d',i);
    leg{(i-1)*3+2} = sprintf('Headset %d',i);
    leg{(i-1)*3+3} = sprintf('Commanded %d',i);
    xlabel('time [s]'); ylabel('Angular Velocity [deg/s]');
    xlim([2.1 time{i}(end)]);
    %legend(leg{(i-1)*3+1:(i-1)*3+3},'Location','Best');
end
legend(leg,'Location','Best');
%%
function [DATA, angVelfromPos, angularVelocity, time, profStartTime] = getAngVel(whichProf, filename, T, herepath, logpath)

pad = 1; % set pad length (sec)
transition = 1; % set transition length (sec)
DATA = profileWriterFxn(T(whichProf,:), pad, transition);
%profile = "35_to_neg20--Lights_oo.txt";
%propath = fullfile(pwd,'\Assets\SteamVR_Resources\Resources');


%% Script
cd(logpath);
fid = fopen(filename,'r');
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

time = [];
angularVelocity = [];
rawChairPosition = [];
triggerTimes = [];
perceivedPositions = [];
lightChangeTimes = [0];
lightStates = [0];
chairPosition = [];
profStartTime = [];

adjust = 0;

for i=3:size(txt{1})
    line = txt{1}{i};
    if line(1) == "T"
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


    elseif line(1) == "R"
        %record right trigger press
        mycell = split(line, ' ');
        tempTime = str2double(mycell{3});

        currentPerceivedPosition = currentPerceivedPosition + 90*flip;
        perceivedPositions = [perceivedPositions currentPerceivedPosition];
        triggerTimes = [triggerTimes tempTime];

    elseif line(1:2) == "Le"
        %record left trigger press
        mycell = split(line, ' ');
        tempTime = str2double(mycell{3});

        currentPerceivedPosition = currentPerceivedPosition - 90*flip;
        perceivedPositions = [perceivedPositions currentPerceivedPosition];
        triggerTimes = [triggerTimes tempTime];

    elseif line(1:2) == "Li"
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

    end
end

chairPosition = chairPosition - chairPosition(20);

inferredAngularVelocity = [];
inferredAngularVelocityTimes = [];

for i = 2:length(triggerTimes)
    tempInfferedAngularVelocity = (perceivedPositions(i) - perceivedPositions(i-1))/(triggerTimes(i) - triggerTimes(i-1));
    inferredAngularVelocity = [inferredAngularVelocity tempInfferedAngularVelocity*pi/180];
    tempInfferedAngularVecloityTimes = (triggerTimes(i) + triggerTimes(i-1))/2;
    inferredAngularVelocityTimes = [inferredAngularVelocityTimes tempInfferedAngularVecloityTimes];
end

inferredAngularVelocityTimes = triggerTimes(2:end);

lightChangeTimes(end+1) = time(end);
lightStates(end+1) = lightStates(end);

%%%%%%%%%%%%% plotting

% Torin: Since angular velocity didn't record, we are computing it from the chair position.
% It is noisy, so I am smoothing it. I don't know why I need a factor of 2,
% but it sure seems the position perception is fairly accurate, but the
% angular velocity is offset by a factor of 2, so I threw that in for now.
% Going forward we won't use this, so its not worth trying to figure out! 
% plot(time, angularVelocity(2,:));
angVelfromPos = 2*pi/180 * smooth(diff(chairPosition)/(time(2)-time(1)), 300); % rad/s,  

end

