function T = rotoChairMetaWriter(pad, transition)
%% clear;clc;
posNeg = randperm(6)-3.5;
posNeg = posNeg./abs(posNeg);
av1 = [ones(4,1)*35*posNeg(1); ones(4,1)*35*posNeg(2); ones(4,1)*35*posNeg(3); 
       ones(4,1)*-50*posNeg(4); ones(4,1)*50*posNeg(5); ones(4,1)*-50*posNeg(6)];
av2 = [ones(4,1)*50*posNeg(1);  ones(4,1)*0*posNeg(2); ones(4,1)*-20*posNeg(3); 
       ones(4,1)*-20*posNeg(4); ones(4,1)*0*posNeg(5); ones(4,1)*20*posNeg(6)];
angVels = [av1 av2];

pad = 1; % set pad length (sec)
transition = 1; % set transition length (sec)
totalDur = 100;

rng(7);
l = [1, 1; 0, 1; 1, 0; 0, 0];
lights = [l;l;l;l;l;l];

avRand = round(rand(length(lights)/4,1)*30)+35;
avDurations = [];
for i = 1:length(avRand)
    avDurations = [avDurations; avRand(i)*ones(4,1) totalDur-avRand(i)*ones(4,1)];
end

totalDuration = sum(avDurations(1,:)) + 2*pad + transition*(length(angVels(1,:))+1);

%%rng(11);
lRand = zeros(length(lights)/4,1);
lDurations = [];
for i = 1:length(lRand)
    if round(rand) == 1
       lRand(i) = round(rand*(avDurations(i*4,1)-20));
       lDurations = [lDurations; (avRand(i)-lRand(i)-10)*ones(4,1) totalDuration-(avRand(i)-lRand(i)-10)*ones(4,1)];
    else
       lRand(i) = -round(rand*(avDurations(i*4,2)-20));
       lDurations = [lDurations; (avRand(i)-lRand(i)+10)*ones(4,1) totalDuration-(avRand(i)-lRand(i)+10)*ones(4,1)];
    end
end
clear posNeg;
for i = 1:length(angVels)
    if angVels(i,2)<0
        posNeg = 'neg';
    else
        posNeg = '';
    end
    
    if lights(i,1)==0
        io1 = 'o';
    else
        io1 = 'i';
    end
    
    if lights(i,2)==0
        io2 = 'o';
    else
        io2 = 'i';
    end
    fileNames{i} = sprintf('%d_to_%s%d--Lights_%c%c.txt',angVels(i,1),posNeg,abs(angVels(i,2)),io1,io2);
end
fileNames = fileNames';
T = table(angVels, avDurations, lights, lDurations, fileNames)
T.Properties.VariableDescriptions = {'Angular velocities [deg/s] for intv''ls A & B.',...
    'Durations [s] for each intv''l.','Light status for intv''ls A1 & B1','Durations [s] for intv''ls A1 & B1.',''};

end