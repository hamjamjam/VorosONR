%% Profile Randomizer
% !!! Make sure T.mat exists and has the right profiles for you !!!
clear;clc;

subjNum = input('Enter subject number: ');
nProfiles = 24;

% Generate Profiles
pad = 1; % set pad length (sec)
transition = 1; % set transition length (sec)
rng(subjNum);
run rotoChairProfileWriter.m
close all;
load('T.mat');
DATA = cell(1,length(T.fileNames));

% Randomize positive/negative
rng(subjNum);
posNeg = [round(randperm(2)-1.5) round(randperm(2)-1.5) round(randperm(2)-1.5)];

for i = 1:length(T.fileNames)
    if posNeg(ceil(i/4)) < 0 % randomly negates angVels for 3 profiles & renames them with 'neg_'
        T(i,:).angVels{:} = T(i,:).angVels{:}*posNeg(ceil(i/4));
        T(i,:).fileNames{:} = strcat('neg_',T(i,:).fileNames{:});
    end
    DATA{i} = profileWriterFxn(T(i,:), pad, transition, 0,'off');
end

% Randomize order
rng(subjNum);
order = randperm(nProfiles);

% Practice Trials
practiceTrials = {'Practice_1','Practice_2','Practice_3','Practice_4'};
nPractice = length(practiceTrials);

% Write to text file
filename = sprintf('Subject%dOrder.txt',subjNum);
fileID = fopen(filename,'w');

for i = 1:nPractice     % write practice trials
    fprintf(fileID,'Practice #%d:  |   %s\n',i, practiceTrials{i});
end

fprintf(fileID,'=========================================\n');

for i = 5:nProfiles+4     % write randomized test trials
    fprintf(fileID,'Trial #%2d:    |   %s\n',i, T.fileNames{order(i-4)}(1:end-4));
end
fclose(fileID);
fileloc=fullfile(pwd,filename);
%winopen(fileloc);
open(fileloc);

if exist('T.mat','file')
    delete('T.mat');
end
save('T.mat','T');
close all;