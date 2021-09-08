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
plot(Ttotal/1000,Xt); hold on;
plot(Ttotal/1000,Yt);
plot(Ttotal/1000,Zt);
plot(Ttotal/1000,Zt_new-bias_gyro(3));
legend({'X','Y','Z','Z corrected'});
xlabel('Time [s]');
ylabel('Angular Velocity [deg/s]');

figure;
plot(Ttotal/1000,Zt_new-bias_gyro(3));
legend({'Z corrected'});
xlabel('Time [s]');
ylabel('Angular Velocity [deg/s]');

%%
ZZ = Zt_new-bias_gyro(3);

x1 = 14.524;
x2 = 28.783;

vel = mean(ZZ(x1*1000:x2*1000))

