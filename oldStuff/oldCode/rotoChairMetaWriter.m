%rotoChairMetaWriter

filename = '35_to_neg20--Lights_oi.txt';
filename = '35_to_neg20--Lights_i.txt';
filename = '35_to_neg20--Lights_o.txt';
filename = '35_to_neg20--Lights_io.txt';

filename = 'lights_camera_action';

% designate the desired angular velocity and duration of each step
%%% min = 20, max = 145 (approx.)
%%% profile will be padded by one second of zeros on either side
%%% There will be a 1-second transition added between any two velocities
ang_vel = [35,-20]; % degrees/sec 
dur = [30, 30]; % seconds
pad = 1; % set pad length (sec)
transition = 1; % set transition length (sec)

totalDuration = sum(dur) + 2*pad + transition*(length(ang_vel)+1)

% designate the desired light profile and switch time
% off = 0 & on = 1; [1, 0] = switch off when (time = toggle)
% time (in sec) when the switch occurs (take intermediate transitions into account!!)
% set lights to [1] for always on and toggle will be ignored                  
lights = [0,1];       
ldur = [17.5,17.5];

%%
av1 = [ones(12,1)*35;ones(12,1)*60];
av2 = [ones(4,1)*60; ones(4,1)*0; ones(4,1)*-20; ones(4,1)*20; ones(4,1)*0; ones(4,1)*-20];
ang_vel = [av1 av2];

l = [1, 1; 0, 1; 1, 0; 0, 0];
lights = [l;l;l;l;l;l];
ldur = [];
% for i = 1:length(lights)
%     toggle = dur(1);
%     while(toggle ~= dur(1) && toggle ~= dur(1)+1)
%         toggle = round(rand*sum(dur));
%     end
%     ldur(i,:) = [toggle+2,totalDuration-(toggle+2)];
% end

ldur = round(rand(length(lights),1))*60

[ang_vel lights ldur]