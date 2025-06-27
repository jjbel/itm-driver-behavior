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

    global m_line_y m_line_z subplot_my subplot_mz plot_time_look_ahead plot_time_look_back

    model_start = -1;
    optitrack_data = []

    % Initial starts of optitrack and model may not be synchronized. ie optitrack_start - model_start may not be zero
    global optitrack_start
    optitrack_start = [];

    global stdout
    stdout = "";

    global axis_setting

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

    fprintf("hello");

    while true
        fprintf("bee");

        if u.NumDatagramsAvailable > 0
            datagrams = read(u, u.NumDatagramsAvailable, "uint8");

            for datagram = datagrams
                % datagram = datagrams(i);
                timestamp = typecast(uint8(datagram.Data(1:8)), 'double') / 1000;
                m_y = typecast(uint8(datagram.Data(9:16)), 'double');
                m_z = typecast(uint8(datagram.Data(17:24)), 'double');

                % TODO move this out of the for loop
                if model_start == -1
                    model_start = timestamp;
                    stdout = stdout + "mstart\n";
                end

                % this should always happen! timestamp=0 on first frame
                timestamp = timestamp - model_start;

                % TODO can reserve memory?
                model_data = [model_data [timestamp; m_y; m_z]];

                % m_y = -m_y / 20;
                % m_z = m_z / 2;

                if size(model_data, 2) > 1
                    m_y = m_y - model_data(2, 1);
                    m_z = m_z - model_data(3, 1);

                    m_y = m_y / 4;
                    m_z = m_z / 4;
                end

                m_line_y.addpoints(timestamp, m_y);
                m_line_z.addpoints(timestamp, m_z);
                stdout = stdout + sprintf("m: %f %.2f %.2f\n", timestamp, m_y, m_z);
            end

        end

        if ~isempty(optitrack_data)

        end

        set(gcf, 'CurrentAxes', subplot_my)
        axis(axis_setting);
        drawnow
        set(gcf, 'CurrentAxes', subplot_mz)
        axis(axis_setting);
        drawnow

        % TODO needed else CtrlC doesnt call cleanupFn
        pause(1/60); % avoid busy wait

        fprintf("\n\n%u\n", i);
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
    global o_line_y o_line_z m_line_y m_line_z

    global fig subplot_oy subplot_oz subplot_my subplot_mz

    % create a figure which will contain two subplots
    fig = figure;
    fig.WindowStyle = 'docked';

    % title('Head Tracking - Optitrack vs Model');
    % xlabel('Time (s)')
    % ylabel('Head Angle (deg)')
    % xline(0);
    % yline(0);
    % grid on

    % optitrack camera frequency is 120Hz currently
    point_count = total_time * 120;

    subplot_oy = subplot(2, 2, 1);
    title('Optitrack Y')
    xlabel('Time (s)');
    ylabel('Head Displacement (m)');

    o_line_y = animatedline;
    o_line_y.MaximumNumPoints = point_count;
    o_line_y.Marker = '.';
    o_line_y.LineWidth = 3;
    o_line_y.Color = [0 1 0];
    % o_line.DisplayName = 'Optitrack';

    subplot_oz = subplot(2, 2, 2);
    title('Optitrack Z')
    xlabel('Time (s)');
    ylabel('Head Displacement (m)');

    o_line_z = animatedline;
    o_line_z.MaximumNumPoints = point_count;
    o_line_z.Marker = '.';
    o_line_z.LineWidth = 3;
    o_line_z.Color = [0 0 1];

    subplot_my = subplot(2, 2, 3);
    title('Model Y')
    xlabel('Time (s)');
    ylabel('Head Displacement (scaled units)');

    m_line_y = animatedline;
    m_line_y.MaximumNumPoints = point_count;
    m_line_y.Marker = '.';
    m_line_y.LineWidth = 3;
    m_line_y.Color = [1 0 0];
    % m_line.DisplayName = 'Model';

    subplot_mz = subplot(2, 2, 4);
    title('Model Z')
    xlabel('Time (s)');
    ylabel('Head Displacement (scaled units)');

    m_line_z = animatedline;
    m_line_z.MaximumNumPoints = point_count;
    m_line_z.Marker = '.';
    m_line_z.LineWidth = 3;
    m_line_z.Color = [1 0 1];

    fontsize(scale = 1.6)
    % TODO legend not working
    % legend();
end
