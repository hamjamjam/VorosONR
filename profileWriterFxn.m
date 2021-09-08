function DATA = profileWriterFxn(T, pad, transition, powerOption, plotVisibilityOnOff)
    %% T is a table with columns 
    % 1) angVels: 1xn row vector of the desired angular velocities [deg/s]
    % 2) avDurations: 1xn row vector of the durations [s] of each angVel
    % 3) lights: 1x2 row vec dictating whether the lights are on (1) or off (0)
    % 4) lDurations: 1x2 row vec dictating how long each light setting plays for (must add up to totalDuration variable below
    % 5) fileNames: string containing {'filename.txt'} for the output  profile
    %% pad and transition are integers 
    % pad represents the time [sec] spent running zeros at the start and
    % end of the profile
    % transition represents the time [sec] spent transitioning between
    % velocities
    %% powerOption should be set to zero or one
    % the code will treat the input angVels as input powers if you set
    % powerOption to 1
    % it will not do this if you set powerOption to 0 or just don't include
    % it at all
    
    %% Check if powerOption was included
    if ~exist('powerOption')
        powerOption = 0;
    end
    
    %% read data from the table into local variables
    filename = T.fileNames{:};
    ang_vel = T.angVels{1,:}; % degrees/sec 
    dur = T.avDurations{1,:}; % seconds
    lights = T.lights{1,:};
    ldur = T.lDurations{1,:};
    totalDuration = sum(dur) + 2*pad + transition*(length(ang_vel)+1);

    %% Checks to make sure the table meets specs defined above :-)

    if length(dur)~=length(ang_vel)
        msg = sprintf("Add a duration for EVERY angular velocity!");
        error(msg);
    end 
 
    % designate the chair update frequency
    freq = 90;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% CREATE POWER PROFILE
    % add 0°/sec padding around profile
    ang_vel_temp = [0 ang_vel 0];
    dur_temp = [pad dur pad];

    % convert angular velocity to power
    % calculated these empirically with an IMU on the chair, ask Kieran/Victoria for data
    pwr = zeros(length(ang_vel_temp), 1);
    pwr(ang_vel_temp>0) = round((ang_vel_temp(ang_vel_temp>0)+13.2)./1.41);
    pwr(ang_vel_temp==0) = 0;
    pwr(ang_vel_temp<0) = -round((abs(ang_vel_temp(ang_vel_temp<0))+16.3)./1.5);

    % make matrix of power for durations specified
    % data is the power profile
    % data2 is the commanded angular velocity profile
    pwr_data = ones(dur_temp(1)*freq,1)*pwr(1);
    angvel_data = ones(dur_temp(1)*freq,1)*ang_vel_temp(1);
    for i = 2:length(pwr)
        %data = [data; round(linspace(pwr(i-1),pwr(i),freq*transition))'];
        pwr_data = [pwr_data; round(linspace(pwr(i-1),pwr(i),3*(abs(pwr(i)-pwr(i-1))+1)))'];
        pwr_data = [pwr_data; ones(dur_temp(i)*freq,1)*pwr(i)];
        angvel_data = [angvel_data; round(linspace(ang_vel_temp(i-1),ang_vel_temp(i),3*(abs(pwr(i)-pwr(i-1))+1)))'];
        angvel_data = [angvel_data; ones(dur_temp(i)*freq,1)*ang_vel_temp(i)];
    end

    % interpolate between points using chair update frequency
    % data = round(interp1(1:length(data), data, 1:1/freq:length(data)));
    % data2 = round(interp1(1:length(data2), data2, 1:1/freq:length(data2)));

    % plot the power and angular velocity to confirm
    %{
    figure; hold on; title('RotoChair Power and Velocity Inputs');
    scatter([1:length(data2)]/freq, data2, 'LineWidth', 1); grid on; ylabel('Angular Velocity [deg/sec]'); ylim([-100 65]);
    yyaxis right 
    scatter([1:length(data)]/freq, data, 'LineWidth', 1); grid on; xlabel('Time [sec]'); ylabel('RotoChair Power'); ylim([-100 65]);
    legend('Angular Velocity', 'Power', 'Location', 'best');
    close
    %}
    
    %% CREATE SOUND PROFILE
    totalDur = length(pwr_data)/90-2*pad;
    
    noise = [0,1,0];       
    ndur = [pad, totalDur, pad];
    noise_data = [];
    for i = 1:length(noise)
        noise_data = [noise_data; ones(round(ndur(i)*freq),1)*noise(i)];
    end

    %% CREATE LIGHTS PROFILE
    lights = [0, lights, 0];
    ldur = [pad, ldur(1), totalDur-ldur(1), pad];
    light_data = [];
    for i = 1:length(lights)
        light_data = [light_data; ones(round(ldur(i)*freq),1)*lights(i)];
    end

    %% Remove power levels between 20 and -20
    i=1;
    while i<length(pwr_data)
        if pwr_data(i)<15 && pwr_data(i)>-15 && pwr_data(i)~=0
            pwr_data(i) = [];
            angvel_data(i) = [];
            light_data(i) = [];
            noise_data(i) = [];
            i=i-1;
        end
        i=i+1;
    end
        
    %% Plot the lights and angular velocity to confirm
    if plotVisibilityOnOff == "on"
        figure(); hold on; title('RotoChair Angular Velocity and Light Profile');
        plot([1:length(angvel_data)]/freq, angvel_data,'-*k', 'LineWidth', 1); grid on; ylabel('Angular Velocity [deg/s]'); ylim([-100 65]);
        ylim([-60 60]);
        yyaxis right 

        plot([1:length(pwr_data)]/freq, light_data, '-.r', 'LineWidth', 1); grid on; xlabel('Time [sec]'); ylabel('Status'); ylim([-1 2]);
        plot([1:length(pwr_data)]/freq, noise_data, '--b', 'LineWidth', 1);
        yticks([0 1]); yticklabels({'Off','On'});
        legend('Angular Velocity','Light Status','Noise Status', 'Location', 'best');
    end 
    %% Write power profile to SteamVR resources folder
    %%{
    % comment out writing if profiles are already written
    path = fullfile(pwd,'\Assets\SteamVR_Resources\Resources',filename);
    %path = fullfile(pwd,'Assets/SteamVR_Resources/Resources',filename); % MAC
    % path = fullfile(pwd,filename); % for working off the VR CPU
    if powerOption==0
        writematrix([pwr_data light_data noise_data],path);
    elseif powerOption==1
        writematrix([angvel_data light_data noise_data],path);
    else
        msg = sprintf("Bad Input! powerOption must be set to 0/1 or excluded from the function call altogether.");
        error(msg);
    end
    %}        
    
    DATA = [angvel_data light_data noise_data];
end