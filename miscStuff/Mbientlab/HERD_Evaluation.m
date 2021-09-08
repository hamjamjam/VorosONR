%% Evaluate Sensor at 1g
% Author: Aaron Allred
clc;clear;
fig = 1;

% 1g stationary test
name = "IMU-2021-06-17T12.43.48.700-C7116A831ED9";

% import accelerometer data
name_acc = convertStringsToChars(name+"_Accelerometer.csv");

[Xg, Yg, Zg] = csvimport(name_acc, 'columns',...
    {'x-axis (g)', 'y-axis (g)', 'z-axis (g)'});

% import gyroscope data
name_gyro = convertStringsToChars(name+"_Gyroscope.csv");
[Xt, Yt, Zt, T] = csvimport(name_gyro, 'columns',...
    {'x-axis (deg/s)', 'y-axis (deg/s)', 'z-axis (deg/s)','epoc (ms)'});
T = T - T(1);

%% Accelerometer Evaluation
Truth = [0;0;1];
freq = 80.6;
tend = 10;
bounds = [1 tend*freq];

%EvaluateAccelerometer
[New_g, ~, ~, bias_acc] = EvaluateSensor(Xg,Yg,Zg,Truth,bounds);
Zg_new = New_g(3,:);
% plot(Zg_new-bias_acc(3))

% Autocorrelation
% [acf,lags,~] = autocorr(Zg_new-bias_acc(3));  %autocorrelate the vector
% periodogram(acf)
% figure(2)
% plot(lags,acf)

%% Gyroscope Evaluation
Truth = [0;0;0];
tend = 10;
bounds = [1 tend*freq];

%EvaluateGyro
[New_t, angles, Cov_gyro, bias_gyro] = EvaluateGyro(Xt,Yt,Zt,Truth,bounds);

Zt_new = New_t(3,:);
Zmean = mean(Zt_new);
% plot(Zt_new-bias_gyro(3))

% Autocorrelation
% [acf,lags,~] = autocorr(Zt_new-bias_gyro(3));  %autocorrelate the vector
% periodogram(acf)
% figure(2)
% plot(lags,acf)

%% Kalman Filter

H = eye(3);
F = eye(3);
G = eye(3);
R = Cov_gyro;
% Q = diag([0.001 0.001 0.001])./100;
Q = diag([0 0 0]); % no process noise

% Match up Measurement Data
Time = 100;
delay = 1515;
stop = 1052;
dt = 1/100;
yd = (New_t(:,delay:end)-bias_gyro);

%load in commands
% looks like the actual command is really about Hz 10.7195 hz
[yaw] = csvimport('thresholds_0.5Hz_gap6s_100trials_20193281550_1.csv',...
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
Tm = linspace(0,T(end-delay)/1000,length(T)-delay+1);
sig2 = 2*P_est(3,:).^(1/2);

figure(fig)
plot(Tm,x_est(3,:),'r',Tm,x_est(3,:)+sig2,'b',...
     Tm,x_est(3,:)-sig2,'b',Tm,u3,'--k');
fig = fig+1;
% Angular Velocity (threshold) actual is about 1.9% higher than command
 
%% Plot Angular acceleration
dz_est = (x_est(3,2:end)-x_est(3,1:end-1))./(Tm(2:end)-Tm(1:end-1));
ddz_est = (dz_est(1,2:end)-dz_est(1,1:end-1))./(Tm(3:end)-Tm(2:end-1));

Ac = (x_est(3,:)).^2*21*0.0254/9.81*(2*pi/180)^2;
At = zeros(1,length(Ac));
At(1,2:end) = dz_est*21*0.0254/9.81*(2*pi/180);

a = vecnorm([Ac' At'],2,2);
figure(fig)
plot(Tm(1:end-1),dz_est)
fig = fig+1;

figure(fig)
plot(Tm(1:end-2),ddz_est)
fig = fig+1;
% hertz: ~0.53

%% Load in '24 inches off axis' Data
name = "TorinsIMU_2021-01-16T09.03.57.696_C7116A831ED9";

% import accelerometer data
name_acc = convertStringsToChars(name+"_Accelerometer.csv");
[Xg2, Yg2, Zg2, T2] = csvimport(name_acc, 'columns',...
    {'x-axis (g)', 'y-axis (g)', 'z-axis (g)','epoc (ms)'});

% import gyroscope data
name_gyro = convertStringsToChars(name+"_Gyroscope.csv");
[Xt2, Yt2, Zt2] = csvimport(name_gyro, 'columns',...
    {'x-axis (deg/s)', 'y-axis (deg/s)', 'z-axis (deg/s)'});

% get angles
Truth = [0;0;0];
[New_t2, angles_gyro2, ~, ~] = EvaluateSensor(Xt2,Yt2,Zt2,Truth,bounds);

% rotate accelerometor data and get rid of bias
Truth = [0;0;1];
[New_g2, ~, ~, bias_acc2] = EvaluateSensor(Xg2,Yg2,Zg2,Truth,bounds,angles_gyro2);
Xg2r = New_g2(1,:)' - bias_acc2(1);
Yg2r = New_g2(2,:)' - bias_acc2(2);
Zg2r = New_g2(3,:)' - bias_acc2(3);

% Plot Acceleration
delay2 = 2316-754;
T2 = T2 - T2(1);
figure(fig)
plot(linspace(0,T2(end-delay2)/1000,length(T2)-delay2),Yg2r(delay2:end-1),'b',...
     linspace(0,T(end-delay)/1000,length(T)-delay),At(1:end-1),'r')
legend('IMU','Theoretical')
xlabel('time (s)')
ylabel('m/s/s')
title('Tangential Acceleration Comparison')
fig = fig+1;

%% 45.5 inches off axis
name = "TorinsIMU_2021-01-16T09.13.16.922_C7116A831ED9";

% import accelerometer data
name_acc = convertStringsToChars(name+"_Accelerometer.csv");
[Xg3, Yg3, Zg3, T3] = csvimport(name_acc, 'columns',...
    {'x-axis (g)', 'y-axis (g)', 'z-axis (g)','epoc (ms)'});

% import gyroscope data
name_gyro = convertStringsToChars(name+"_Gyroscope.csv");
[Xt3, Yt3, Zt3] = csvimport(name_gyro, 'columns',...
    {'x-axis (deg/s)', 'y-axis (deg/s)', 'z-axis (deg/s)'});

% get angles
Truth = [0;0;0];
[New_t3, angles_gyro3, ~, ~] = EvaluateSensor(Xt3,Yt3,Zt3,Truth,bounds);

% rotate accelerometor data and get rid of bias
Truth = [0;0;1];
[New_g3, ~, ~, bias_acc3] = EvaluateSensor(Xg3,Yg3,Zg3,Truth,bounds,angles_gyro3);
Xg3r = New_g3(1,:)' - bias_acc3(1);
Yg3r = New_g3(2,:)' - bias_acc3(2);
Zg3r = New_g3(3,:)' - bias_acc3(3);

% Plot Acceleration
delay3 = 1200;
T3 = T3 - T3(1);
figure(fig)
plot(linspace(0,T3(end-delay3)/1000,length(T3)-delay3),Yg3r(delay3:end-1),'b',...
     linspace(0,T(end-delay)/1000,length(T)-delay),At(1:end-1).*42.5/21,'r')
legend('IMU','Theoretical')
xlabel('time (s)')
ylabel('m/s/s')
title('Tangential Acceleration Comparison')
fig = fig+1;

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