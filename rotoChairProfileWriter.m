%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%     RotoChair Motion Profile Writer          %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% designate file name -> will be saved to \Assets\SteamVR_Resources\Resources
% filename = '[starting ang vel]_to_[ending ang vel]--Lights_[light status].txt';
%       light status  = i (always on), o (always off), io (on to off), oi(off to on)


% Set Values for Profile 
pad = 1;    % # seconds of 0 at start and finish
transition = 1; % actually meaningless right now

angVels = cell(24,1);
avDurations = cell(24,1);
lights = cell(24,1);
lDurations = cell(24,1);
fileNames = cell(24,1);
lightstrings = {'ii','io','oi','oo'};

%% generate light transitions -- random time between 20 and 80 seconds 
rng(5)
lRand = round(rand*60)+20;
for i = 1:24
    lDurations{i} = [lRand];
    
    if mod(i,4)==1
        lights{i} = [1,1];
    elseif mod(i,4)==2
        lights{i} = [1,0];
    elseif mod(i,4)==3
        lights{i} = [0,1];
    elseif mod(i,4)==0
        lRand = round(rand*60)+20; % New duration for each profile every 4 
        lights{i} = [0,0];
    end
end

%% ------------------------------ Ramps ------------------------------------
for i = 1:4
    angVels{i} = [29, 30:36, 37, 36:-1:30, 29]; % 1st Ramp
    avDurations{i} = [5, 1*ones(1,7), 30, 4*ones(1,7), 30];
    fileNames{i} = sprintf('ramp29-to-37--Lights_%s.txt',lightstrings{i});
    
    angVels{i+4} = [51, 49:-1:44, 43, 44:49, 51]; %2nd Ramp
    avDurations{i+4} = [5, 1*ones(1,6), 30, 4*ones(1,6), 30];
    fileNames{i+4} = sprintf('ramp51-to-43--Lights_%s.txt',lightstrings{i});
end

%% ------------------------ Multi-Steps ------------------------------------

%{
Velocities we can Command:
1) Negative Ramp-Up
    -   -16 to -20
    -   -30 to -36
    -   -43 to -51
    -   -58 to -100
2) Negative Ramp-Down
    -   -14 to -19
    -   -30 to -36
    -   -43 to -52
    -   -58 to -102
3) Positive Ramp-Up
    -   13 to 22
    -   29 to 35
    -   44 to 51
    -   58 to 100
4) Positive Ramp-Down
    -   14 to 22
    -   30 to 38
    -   43 to 51
    -   58 to 102
5) OVERALL Commandable Velocities[deg/s]
    -   16 to 19
    -   30 to 36
    -   44 to 51
    -   58 to 100
%}

for i = 1:4
    angVels{i+8} = [30:36 44:49 50:-1:44]; % 1st Steps
    avDurations{i+8} = [10 ones(1,5) 30 10 ones(1,5) 20 ones(1,5) 15];
    fileNames{i+8} = sprintf('multistep1--Lights_%s.txt',lightstrings{i});
        
    angVels{i+12} = [50:-1:44, 36:-1:30, 31:36]; %2nd Steps
    avDurations{i+12} = [20 ones(1,5) 10 15 ones(1,5) 30 ones(1,5) 10];
    fileNames{i+12} = sprintf('multistep2--Lights_%s.txt',lightstrings{i});
end

%% ------------------------ Normal-Steps ------------------------------------


for i = 1:4
    angVels{i+16} = [20, 50]; % 1st Step
    avDurations{i+16} = [37 73];
    fileNames{i+16} = sprintf('20_to_50--Lights_%s.txt',lightstrings{i});
        
    angVels{i+20} = [35, 0]; %2nd Step
    avDurations{i+20} = [58 52];
    fileNames{i+20} = sprintf('35_to_0--Lights_%s.txt',lightstrings{i});
end



%% Generate T Table and Profiles
T = table(angVels, avDurations, lights, lDurations, fileNames);

for i = 1:length(fileNames)
    DATA{i} = profileWriterFxn(T(i,:), pad, transition, 0,'off');
end

if exist('T.mat','file')
    delete('T.mat');
end
save('T.mat','T');
