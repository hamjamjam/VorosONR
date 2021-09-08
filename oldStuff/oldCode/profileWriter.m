%profileWriter
filename = 'profileName.txt';

avel = [0 30 60 -20 -90];
for i = 1:length(avel)
    if(avel(i)>0)
        pwr(i) = round((avel(i)+13.057)./1.5701);
    elseif avel == 0
        pwr(i) = 0;
    elseif avel(i)<0
        pwr(i) = round(-(abs(avel(i))+13.057)./1.5701);
    end
end
% pwr = [0, 20, 30, -20, -30];
dur = [5, 10, 10, 10, 10];
freq = 90;

data = [];
for i = 1:length(pwr)
    data = [data; ones(dur(i)*freq,1)*pwr(i)];
end

path = fullfile(pwd,'\Assets\SteamVR_Resources\Resources',filename);
writematrix(data,path);