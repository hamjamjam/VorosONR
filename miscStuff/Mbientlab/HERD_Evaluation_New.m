%% Evaluate Sensor at 1g
% Author: Aaron Allred
clc;clear;
fig = 1;

% 1g stationary test
name = "IMU-2021-06-17T13.36.30.990-C7116A831ED9";

% import gyroscope data
name_gyro = convertStringsToChars(name+"-Gyroscope.csv");

[Xt, Yt, Zt, T] = csvimport(name_gyro, 'columns',...
    {'x-axis (deg/s)', 'y-axis (deg/s)', 'z-axis (deg/s)','epoc (ms)'});
Ttotal = T - T(1);

%% Gyroscope Evaluation
Truth = [0;0;0];
tend = 10;
freq = 100;
bounds = [1 tend*freq];

%EvaluateGyro
[New_t, angles, Cov_gyro, bias_gyro] = EvaluateGyro(Xt,Yt,Zt,Truth,bounds);

Zt_new = New_t(3,:);
Zmean = mean(Zt_new);
figure;
plot(Ttotal,Xt); hold on;
plot(,Ttotal,Yt);
plot(,Ttotal,Zt);
plot(,Ttotal,Zt_new-bias_gyro(3));
legend({'X','Y','Z','Z corrected'});
xlabel('Time [s]');
ylabel('Angular Velocity [deg/s]');
%% Split Up
Zunbiased = Zt_new-bias_gyro(3);

% Match up Measurement Data
Freq01 = Zunbiased(1:37859);
delay = 1150;
stop = 3881;
yd = Freq01(delay:end);
T = Ttotal(delay:37859)-Ttotal(delay);

Freq03 = Zunbiased(41726:63419);
delay = 1511;
stop = 2137;
yd = Freq03(delay:end);
T = Ttotal(41726+delay:63419)-Ttotal(41726+delay);

% Freq05 = Zunbiased(67100:85184);
% delay = 1150;
% stop = 3881;
% yd = Freq05(delay:end);
% T = Ttotal(delay:37859)-Ttotal(delay);

%% Kalman Filter
dt = 1/100;
Time = 100;

H = eye(3);
F = eye(3);
G = eye(3);
R = Cov_gyro;
% Q = diag([0.001 0.001 0.001])./100;
Q = diag([0 0 0]); % no process noise

%load in commands
% looks like the actual command is really about Hz 10.7195 hz
[yaw] = csvimport('thresholds_0.3Hz_Initializer.csv',...
    'columns', {'yaw'});
cmd = yaw(1:stop)*6; % convert to deg/s from rpm
time1 = linspace(1,length(cmd),length(cmd));
time2 = linspace(1,length(cmd),length(yd));
u3 = interp1(time1,cmd,time2)*-1;
ucmd = [zeros(1,length(u3));zeros(1,length(u3));u3];

u = (ucmd(:,2:end)-ucmd(:,1:end-1));
u(:,length(u3)) = zeros(3,1);

% initial conditions
x = [0;0;0];
P = eye(3)*100;

% Run Kalman Filter
x_est = zeros(3,length(u3));
P_est = zeros(3,length(u3));
inn = zeros(3,length(u3));
for i = 1:length(u3)
    % Prediction Step
    x = F*x+G*u(:,i); %x-  
    P = F*P*F'+ Q; %P-
    K = P*H'/(H*P*H'+R);

    % Update with Kalman Filter
    P = (eye(3)-K*H)*P; %P+
    x = x+K*(yd(:,i) - H*x); %x+

    x_est(:,i) = x;
    P_est(:,i) = diag(P);
    inn(:,i) = yd(:,i)-H*x;
end

%% Plot Estimate against Command
Tm = linspace(0,T(end)/1000,length(T));
sig2 = 2*P_est(3,1:length(Tm)).^(1/2);

figure(fig)
plot(Tm,x_est(3,1:length(Tm)),'r',Tm,x_est(3,1:length(Tm))+sig2,'b',...
     Tm,x_est(3,1:length(Tm))-sig2,'b',Tm,u3(1:length(Tm)),'--k');
fig = fig+1;
% Angular Velocity (threshold) actual is about 1.9% higher than command
 

%% GyroStim Recording

name = '99999-1-8-2021-10-06-49 AM.csv';
[T3, GS] = csvimport(name, 'columns',...
    {'10Hz', 'YAW'});

T3 = T3/1000;

% Raw
figure(fig)
plot(Tm,yd(3,:),'b',time1./10,cmd*-1,'r',T3,GS*-6,'--k')
legend('IMU','Cmd (10Hz)','GyroStim (10Hz)')
xlabel('time (s)')
ylabel('deg/s')
title('Raw Yaw Data')
fig = fig+1;

% Altered Frequency
figure(fig)
plot(Tm,yd(3,:),'b',time1./10.71,cmd*-1,'r',T3.*10./10.71,GS*-6,'--k')
legend('IMU','Cmd (10.72Hz)','GyroStim (10.72Hz)')
xlabel('time (s)')
ylabel('deg/s')
title('Adjusted Yaw Data')
fig = fig+1;

% Filtered Measurements
figure(fig)
plot(Tm,x_est(3,:),'b',time1./10.71,cmd*-1,'r',T3.*10./10.71,GS*-6,'--k')
legend('IMU','Cmd (10.72Hz)','GyroStim (10.72Hz)')
xlabel('time (s)')
ylabel('deg/s')
title('Filtered Yaw Data')
fig = fig+1;

%% Threshold comparison
p1 = findpeaks(x_est(3,:));
p1 = p1(p1>1);

p2 = findpeaks(u3);
p2 = p2(p2>1);

error = (p1-p2)./p2*100;