function live_capture
    % From: Optitrack Sample for Rigid Body Pose Data
    clc
    % change this to your location of the Matlab plugin folder
    addpath('..\..\OptiTrack_MATLAB_Plugin_1.1.0', '..\..\OptiTrack_MATLAB_Plugin_1.1.0\Matlab');

    % to be accessible in cleanupFn, needs to be passed by reference - use a handle
    % TODO or use global vars - but considered bad practice
    natnetclient = SharedVar();
    natnetclient.Value = natnet;
    connection = natnetclient.Value.ConnectToNatNet('127.0.0.1', '127.0.0.1', 'Multicast');

    if connection < 1
        disp("no connection, quitting");
        return
    end

    global optitrack_data
    global model_data
    model_data = [];

    global m_line

    model_start = -1;
    optitrack_data = []

    % Initial starts of optitrack and model may not be synchronized. ie optitrack_start - model_start may not be zero
    global optitrack_start
    optitrack_start = [];

    global stdout
    stdout = "";

    % TODO or cud use polling directly
    natnetclient.Value.addlistener(1, 'natnet_callback');
    natnetclient.Value.enable(0);

    % calling clear/using persistent var doesn't clear optitrack_start between runs

    % model data from UDP
    u = udpport("datagram", "LocalHost", "0.0.0.0", "LocalPort", 5014);

    cleanup = onCleanup(@() cleanupFn(natnetclient));

    plot_time_look_ahead = 0.5;
    plot_time_look_back = 25;
    CreatePlots(plot_time_look_ahead + plot_time_look_back);

    i = 1;

    while true

        if u.NumDatagramsAvailable > 0
            datagrams = read(u, u.NumDatagramsAvailable, "uint8");

            for datagram = datagrams
                % datagram = datagrams(i);
                timestamp = typecast(uint8(datagram.Data(1:8)), 'double') / 1000;
                value = typecast(uint8(datagram.Data(9:16)), 'double');

                % TODO move this out of the for loop
                if model_start == -1
                    model_start = timestamp;
                    stdout = stdout + "mstart\n";
                end

                % this should always happen! timestamp=0 on first frame
                timestamp = timestamp - model_start;

                % TODO can reserve memory?
                model_data = [model_data [timestamp; value]];

                % TODO initial time for both still isnt subtracted
                % TODO if statement makes the call happen less often. i is being modified elsewhere?
                % if i ~= 1
                m_line.addpoints(timestamp, value);
                stdout = stdout + sprintf("m: %f, %f\n", timestamp, value);
                % fprintf("added points\n");
                % end

                % fprintf('m: %f %f\n', model_data(1, end), model_data(2, end));
            end

        end

        if ~isempty(optitrack_data)
            % Dynamically move the axis of the graph
            axis([-plot_time_look_back + optitrack_data(1, end), plot_time_look_ahead + optitrack_data(1, end), -90, 90]);

            if abs(optitrack_data(end) - 0) < 1
                set(gca, 'color', [0 1 1]);
            elseif abs(optitrack_data(end) - 30) < 1
                set(gca, 'color', [1 0 0]);
            elseif abs(optitrack_data(end) - 60) < 1
                set(gca, 'color', [0 1 0]);
            elseif abs(optitrack_data(end) - 90) < 1
                set(gca, 'color', [0 0 1]);
            else
                set(gca, 'color', [0 0 0]);
            end

        end

        drawnow

        % TODO needed else CtrlC doesnt call cleanupFn
        pause(1/60); % avoid busy wait

        disp(i);
        fprintf(stdout);
        stdout = "";
        i = i + 1;

    end

end

function cleanupFn(natnetclient)
    global model_data
    global optitrack_data
    % if don't cleanup, matlab process keeps port open, can't reuse it
    clear u
    disp('closed socket.');

    natnetclient.Value.disable(0);
    disp('disabled natnet callbacks.');

    % this uses the same filename format as optitrack, but appends " model" before .csv
    csv_file = string(datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd HH.mm.ss')) + ".csv";
    writematrix(model_data', "model " + csv_file);
    writematrix(optitrack_data', "optitrack " + csv_file);

    disp('exported CSVs.');
end

function CreatePlots(total_time)
    % making animated lines global so they can be accessed in the
    % callback functions
    global o_line m_line

    title('Head Tracking - Optitrack vs Model');
    xlabel('Time (s)')
    ylabel('Head Angle (deg)')
    xline(0);
    yline(0);
    grid on

    % optitrack camera frequency is 120Hz currently
    point_count = total_time * 120;

    o_line = animatedline;
    o_line.MaximumNumPoints = point_count;
    o_line.Marker = '.';
    o_line.LineWidth = 3;
    o_line.Color = [0 1 0];
    % o_line.DisplayName = 'Optitrack';

    m_line = animatedline;
    m_line.MaximumNumPoints = point_count;
    m_line.Marker = '.';
    m_line.LineWidth = 3;
    m_line.Color = [1 0 0];
    % m_line.DisplayName = 'Model';

    fontsize(scale = 1.6)
    % TODO legend not working
    % legend();
end
