function handles = observer_for_SOE1a(time, omega_z, lights)

% clc; clear all; close all; 

G_MAG = 1;
KAAXY = -4;
KAAZ = -4;

tic;

%% Read in data
% Initialize the internal GRAVITY STATE of the model
GG0 = [0 0 -1]'; % initial gravity direction for upright orientation
% Note the actual GRAVITY STATE of the model is set from the input file

% Tilt Angle
% initial gravity direction for upright orientation
g_x = 0;
g_y = 0;
g_z = -1;
% initial gravity direction for supine subject
% g_x = -1;
% g_y = 0;
% g_z = 0;
% g_mag = sqrt(g_x^2 + g_y^2 + g_z^2);
g_norm = [g_x g_y g_z]'./sqrt(g_x^2 + g_y^2 + g_z^2);

% Initialize Quaternions
if g_norm(1) == GG0(1) && g_norm(2) == GG0(2)
    Q0 = [1 0 0 0]';
    VR_IC = [0 0 0 0];
else
    % Perpendicular Vector
    E_vec = cross(g_norm,[0 0 -1]);
    % Normalize E vector
    E_mag = sqrt(E_vec(1)*E_vec(1) + E_vec(2)*E_vec(2) + E_vec(3)*E_vec(3));
    E = E_vec./E_mag;
    % Calculate Rotation angle
    E_angle = acos(dot(g_norm,[0 0 -1]));
    % Calculate Quaternion
    Q0 = [cos(E_angle/2) E(1)*sin(E_angle/2) E(2)*sin(E_angle/2) E(3)*sin(E_angle/2)]';
    VR_IC = [E,E_angle];
end
assignin('base', 'Q0', Q0);

% Preload Idiotropic Vecdtor
h = [0 0 -1];
% assignin('base', 'h', h);

% Initialize scc time constants [x y z]'
handles.tau_scc_value = 5.7;
tau_scc = handles.tau_scc_value*[1 1 1]';
assignin('base', 'tau_scc', tau_scc);

%Internal Model SCC Time Constant is Set to CNS time constant,
tau_scc_cap = tau_scc;
assignin('base', 'tau_scc_cap', tau_scc_cap);

% Initialize scc adaptation time constants
handles.tau_a_value = 80;
tau_a = handles.tau_a_value*[1 1 1]';
assignin('base', 'tau_a', tau_a);

% Initialize the lpf frequency for ssc
handles.f_scc = 2;
f_scc=handles.f_scc;
assignin('base', 'f_scc', f_scc);

% Initialize the low-pass filter frequency for otolith
handles.f_oto = 2;
% handles.f_oto = 10;
% handles.f_oto = 20;
f_oto = handles.f_oto;
assignin('base', 'f_oto', f_oto);

% Initialize the Ideotropic Bias Amount 'w'
handles.w = 0;
w = handles.w;
assignin('base', 'w', w);

% Initialize Kww feedback gain
handles.kww = 8; 
assignin('base', 'kww', handles.kww);


% Initialize Kfg feedback gain
handles.kfg = 4;
assignin('base', 'kfg', handles.kfg);


% Initialize Kfw feedback gain
handles.kfw = 8;
assignin('base', 'kfw', handles.kfw);


% Initialize Kaa feedback gain
handles.kaa = KAAZ;
assignin('base', 'kaa', handles.kaa);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial Kaax and Kaay feedback gains
handles.kaaxy = KAAXY;
assignin('base', 'kaaxy', handles.kaaxy);

% Initialize Kwg feedback gain
handles.kwg = 1;
assignin('base', 'kwg', handles.kwg);

% Initialize Kvg feedback gain
% handles.kgvg = 10;
handles.kgvg = 5;
assignin('base', 'kgvg', handles.kgvg);

% Initialize Kvw feedback gain
handles.kwvw = 10;
assignin('base', 'kwvw', handles.kwvw);

% Initialize Kxdotva feedback gain
handles.kxdotva = 0.75;
assignin('base', 'kxdotva', handles.kxdotva);

% Initialize Kxvv feedback gain
handles.kxvv = 0.1;
assignin('base', 'kxvv', handles.kxvv);

% Initialize Visual Position LPF Frequency
handles.f_visX = 2;
assignin('base', 'f_visX', handles.f_visX);

% Initialize Visual Velocity LPF Frequency
handles.f_visV = 2;
assignin('base', 'f_visV', handles.f_visV);

% Initialize Visual Angular Velocity LPF Frequency
handles.f_visO = 0.2;
assignin('base', 'f_visO', handles.f_visO);

% Initialize Graviceptor Gain
oto_a = 60*[1 1 1]';
assignin('base','oto_a', oto_a);

% Initialize Adapatation time constant
oto_Ka = 1.3*[1 1 1]';
assignin('base','oto_Ka', oto_Ka);

% Initialize  X Leaky Integration Time Constant
handles.x_leak = 0.6;
assignin('base', 'x_leak', handles.x_leak);

% Initialize  Y Leaky Integration Time Constant
handles.y_leak = 0.6;
assignin('base', 'y_leak', handles.y_leak);

% Initialize  Z Leaky Integration Time Constant
handles.z_leak = 10;
assignin('base', 'z_leak', handles.z_leak);



t = time;
L = length(time);
x_in = zeros(L,3);
omega_in = [zeros(L,2), omega_z];
xv_in = zeros(L,3);
xvdot_in = zeros(L,3);
omegav_in = -omega_in;
gv_in = [zeros(L,2), -ones(L,1)];   % [0 0 -1]
g_variable_in = ones(L,1);
pos_ON = zeros(L,1);
vel_ON = zeros(L,1);
angVel_ON = lights;
g_ON = zeros(L,1);
pitch_in = zeros(L,1);

% Time and Tolerance Properties set by data input file to ensure a correct
% sampling rate.
delta_t = time(2) - time (1);
duration = length(time)*delta_t;
handles.duration = duration;
handles.sample_rate = 1/delta_t;
t = time;
tolerance = 0.02;

% Differentiate Position to Velcoity to Acceleration
% v_in = zeros(size(x_in,1),3);
% v_in(1:size(x_in,1)-1,:) = diff(x_in,1)/delta_t;
% 
% a_in = zeros(size(x_in,1),3);
% a_in(1:size(x_in,1)-2,:) = diff(x_in,2)/(delta_t*delta_t);

% If we want to input straight acceleration NEED TO COMMENT OUT ABOVE and
% uncomment the below. Note that Actual Position and Actual velocity plots
% will be innaccurate if we do so.
a_in = x_in;
v_in = a_in;

% Set File Information GUI strgns
duration_string =num2str(duration);
delta_t_string =num2str(1/delta_t);

% Read Data to Workspace
assignin('base', 't', t);
assignin('base', 'x_in', x_in);
assignin('base', 'xv_in', xv_in);
assignin('base', 'a_in', a_in);
assignin('base', 'v_in', v_in);
assignin('base', 'xvdot_in', xvdot_in);
assignin('base', 'omega_in', omega_in);
assignin('base', 'omegav_in', omegav_in);
assignin('base', 'gv_in', gv_in);
assignin('base', 'g_variable_in', g_variable_in);
assignin('base', 'pos_ON', pos_ON);
assignin('base', 'vel_ON', vel_ON);
assignin('base', 'angVel_ON', angVel_ON);
assignin('base', 'g_ON', g_ON);
assignin('base', 'pitch_in', pitch_in);
assignin('base', 'delta_t', delta_t);
assignin('base', 'duration', duration);
assignin('base', 'tolerance', tolerance);
handles.t = t;
handles.x_in = x_in;

model='observerModel';

%% Run the model
% Execute Simulink Model
options=simset('Solver','ode45','MaxStep',tolerance,'RelTol',tolerance,'AbsTol',tolerance);                  %%%%%
[t_s, XDATA, a_est, gif_est, gif_head, a_head, omega_head,g_head,g_est,omega_est,x_est,lin_vel_est,lin_vel,x,error_f,error_a,alpha_oto,alpha_oto_hat,omega_G_est] = sim(model,duration,options,[]);

% Calculate Time of simulation
sim_Time = num2str(toc);

%% Take all the data
% Bring variables from GUI to workspace
sim_time = t_s;
assignin('base', 'model', model);
assignin('base', 't_s', t_s);
assignin('base', 'sim_time', sim_time);
assignin('base', 'a_est', a_est);
assignin('base', 'omega_est', omega_est);
assignin('base', 'gif_est', gif_est);
assignin('base', 'gif_head', gif_head);
assignin('base', 'a_head', a_head);
assignin('base', 'omega_head', omega_head);
assignin('base', 'g_head', g_head);
assignin('base', 'g_est', g_est);
assignin('base', 'x_est', x_est);
assignin('base', 'lin_vel_est', lin_vel_est);
assignin('base', 'lin_vel', lin_vel);
assignin('base', 'x', x);
assignin('base', 'error_f', error_f);
assignin('base', 'error_a', error_a);
assignin('base', 'alpha_oto', alpha_oto);
assignin('base', 'alpha_oto_hat', alpha_oto_hat);
assignin('base', 'omega_G_est', omega_G_est);

% Load Variables in the handle structure
handles.t_s = t_s;
handles.a_est = a_est;
handles.omega_est = omega_est;
handles.gif_est = gif_est;
handles.gif_head = gif_head;
handles.a_head = a_head;
handles.omega_head = omega_head;
handles.g_est = g_est;
handles.g_head = g_head;
handles.x_est = x_est;
handles.lin_vel_est = lin_vel_est;
handles.lin_vel = lin_vel;
handles.x = x;
handles.error_f = error_f;  
handles.error_a = error_a;   
handles.alpha_oto = alpha_oto;
handles.alpha_oto_hat = alpha_oto_hat;  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handles.omega_G_est = omega_G_est;
handles.switch_xvdot = xvdot_switch;
handles.switch_xv = xv_switch;
handles.switch_omegav = omegav_switch;
handles.switch_gv = gv_switch;
handles.azimuth_head = azimuth_head;
handles.azimuth_est = azimuth_est;
handles.euler_head = euler_head;
handles.euler_est = euler_est;
handles.tilt = tilt;
handles.SVV = SVV;
handles.tilt_est = tilt_est;
handles.SVV_est = SVV_est;
handles.g_world = g_world;
handles.g_mag = G_MAG;

%Calculate the time step from simulink
sim_dt = t_s(size(t_s,1)) - t_s(size(t_s,1)-1);

omega_dot_head = zeros(size(omega_head,1),3);
omega_dot_head(1:size(omega_head,1)-1,:) = diff(omega_head,1)/sim_dt;

omega_dot_est = zeros(size(omega_est,1),3);
omega_dot_est(1:size(omega_est,1)-1,:) = diff(omega_est*180/pi,1)/sim_dt;

handles.omega_dot_head = omega_dot_head;
handles.omega_dot_est = omega_dot_est;

assignin('base', 'omega_dot_head', omega_dot_head);
assignin('base', 'omega_dot_est', omega_dot_est);
assignin('base', 'sim_dt', sim_dt);

%Calculate Vertical, SVV, Tilt, and Estimated Tilt, along with Errors
tilt_estTEMP(:,1) = tilt_est(1,1,:);
tiltTEMP(:,1) = tilt(1,1,:);
tilt = tiltTEMP;
tilt_est = tilt_estTEMP;
SVV = SVV*180/pi;
SVV_est = SVV_est*180/pi;
tilt = real(tilt*180/pi);
tilt_est = real(tilt_est*180/pi);

assignin('base', 'azimuth_est', azimuth_est);
assignin('base', 'azimuth_head', azimuth_head);
assignin('base', 'euler_head', euler_head);
assignin('base', 'euler_est', euler_est);
assignin('base', 'switch_xvdot', handles.switch_xvdot(:,1));
assignin('base', 'switch_xv', handles.switch_xv(:,1));
assignin('base', 'switch_omegav', handles.switch_omegav(:,1));
assignin('base', 'switch_gv', handles.switch_gv(:,1));
assignin('base', 'tilt_est', tilt_est);
assignin('base', 'SVV_est', SVV_est);
assignin('base', 'tilt', tilt);
assignin('base', 'SVV', SVV);
assignin('base', 'g_world', g_world);

%% Plot the results
% figure; hold on; 
% plot(t_s, euler_est(:,2), '--r', 'LineWidth', 2)
% xlabel('Time [seconds]'); ylabel('Pitch Angle [degrees]');
% legend('Perceived Angle')
%  
% figure; hold on;
% subplot(2,1,1); plot(t_s, a_head, 'LineWidth', 2)
% ylabel('Acceleration [Gs]'); title('Actual Acceleration')
% subplot(2,1,2); plot(t_s, a_est, 'LineWidth', 2)
% ylabel('Acceleration [Gs]'); title('Perceived Acceleration')
% xlabel('Time [seconds]');
% legend('x', 'y', 'z')
% 
% figure; hold on;
% subplot(4,1,1); plot(handles.t_s,handles.alpha_oto,'LineWidth',2); ylabel('\alpha_{oto}'); legend('x', 'y', 'z')
% subplot(4,1,2); plot(handles.t_s,handles.alpha_oto_hat, 'LineWidth',2); ylabel('$\hat{\alpha}_{oto}$','Interpreter','latex')
% subplot(4,1,3); plot(handles.t_s,handles.error_a,'LineWidth',2); ylabel('e_a');
% subplot(4,1,4); plot(handles.t_s,handles.error_f, 'LineWidth',2); ylabel('e_f');
% 
% figure; hold on;
% plot(t_s, 180/pi*atan(alpha_oto(:,2)./alpha_oto(:,3)), 'k', t_s, 180/pi*atan(alpha_oto_hat(:,2)./alpha_oto_hat(:,3)), '--r', 'LineWidth', 2)
% xlabel('Time [seconds]'); ylabel('Roll direction of afferent [degrees]');
% legend('Actual Afferent', 'Expected Afferent')











