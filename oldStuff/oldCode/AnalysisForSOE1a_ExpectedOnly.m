%clc; clear all; close all; 

%herepath = pwd;
%cd 'C:\Users\ander\Documents\VorosONR\Assets\SteamVR_Resources\Resources'
cd([herepath, '\Assets\SteamVR_Resources\Resources']);

data = table2array(readtable(profName));

cd([herepath, '\Observer']) 

omega_z = data(:,1); 
lights = data(:, 2); 
% lights = ones(length(lights),1); % force the lights to be on the whole time
% lights(2500:end) = 1; % force the lights on halfway through
dt = 1/90; 

time = [0:dt:(length(omega_z)-1)*dt]';

% figure; 
% subplot(2,1,1); plot(time, lights); 
% ylabel('lights'); ylim([-0.1 1.1]); yticks([0 1]); yticklabels({'OFF', 'ON'});
% 
% subplot(2,1,2); plot(time, omega_z); ylabel('ang vel (deg/s)'); xlabel('time (sec)');

warning off;
handles = observer_for_SOE1a(time, omega_z, lights); % input in deg/s

omega_z_est = interp1(t_s, 180/pi*omega_est(:,3), time); % deg/s

%%
%hold on; 
%plot(time, omega_z_est, '--');

smooth_seconds = 2; % smooth of 2 seconds
span = round(smooth_seconds/(time(2)-time(1)));
omega_z_est_smooth = smooth(omega_z_est, span); 
plot(time, omega_z_est_smooth, 'b--', 'LineWidth', 2)

%ylim([min(omega_z)-10 max(omega_z)+10])
%legend('Expected Perceived')
