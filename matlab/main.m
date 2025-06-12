function main
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

    % TODO or cud use polling directly
    natnetclient.Value.addlistener(1, 'natnet_callback');
    natnetclient.Value.enable(0);

    global optitrack_data
    global model_data
    global m_line

    % Initial starts of optitrack and model may not be synchronized. ie optitrack_start - model_start may not be zero

    % calling clear/using persistent var doesn't clear optitrack_start between runs
    global optitrack_start
    optitrack_start = [];

    model_start = -1;

    % model data from UDP
    u = udpport("datagram", "LocalHost", "0.0.0.0", "LocalPort", 5014);

    model_data = [];

    cleanup = onCleanup(@() cleanupFn(natnetclient));

    plot_time_look_ahead = 1;
    plot_time_look_back = 10;
    CreatePlots(plot_time_look_ahead + plot_time_look_back);

    i = 1;

    while true

        if u.NumDatagramsAvailable > 0
            datagrams = read(u, u.NumDatagramsAvailable, "uint8");

            for i = 1:length(datagrams)
                datagram = datagrams(i);
                timestamp = typecast(uint8(datagram.Data(1:8)), 'double') / 1000;
                value = typecast(uint8(datagram.Data(9:16)), 'double');

                % TODO move this out of the for loop
                if model_start == -1
                    model_start = timestamp;
                else
                    timestamp = timestamp - model_start;
                end

                % TODO can reserve memory?
                model_data = [model_data [timestamp; value]];

                % TODO initial time for both still isnt subtracted
                if i ~= 1
                    m_line.addpoints(timestamp, value);
                end

            end

        end

        if ~isempty(optitrack_data)
            optitrack_data(1, :) = optitrack_data(1, :) - optitrack_data(1, 1);
            axis([-plot_time_look_back + optitrack_data(1, end), plot_time_look_ahead + optitrack_data(1, end), -90, 90]);
        end

        if ~isempty(model_data)
            model_data(1, :) = model_data(1, :) - model_data(1, 1);
        end

        if ~isempty(optitrack_data)
            fprintf('o: %f %f\n', optitrack_data(1, end), optitrack_data(2, end));
        end

        if ~isempty(model_data)
            fprintf('m: %f %f\n', model_data(1, end), model_data(2, end));
        end

        % Dynamically move the axis of the graph
        drawnow

        % TODO needed else CtrlC doesnt call cleanupFn
        pause(1/60); % avoid busy wait

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

    % this uses the same filename format as optirack, but appends " model" before .csv
    csv_file = "Take " + string(datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd hh.mm.ss a')) + " model.csv"
    disp(csv_file)
    % writematrix(model_data.Value', csv_file);
    disp('exported csv.');

    clear
end

function CreatePlots(total_time)
    % making animated lines global so they can be accessed in the
    % callback functions
    global o_line m_line

    % create a figure which will contain two subplots
    % hf1 = figure;
    % hf1.WindowStyle = 'docked';

    % plot and animated line for position
    % a1 = subplot(1, 2, 1);
    % plt = subplot();
    title('Position');
    xlabel('Frame')
    ylabel('Position (m)')
    axis([-10, 10, -180, 180]);

    % optitrack camera frequency is 120Hz currently
    point_count = total_time * 120;

    o_line = animatedline;
    o_line.MaximumNumPoints = point_count;
    o_line.Marker = '.';
    % TODO linewidth not working
    o_line.LineWidth = 1.9;
    o_line.Color = [0 1 0];

    m_line = animatedline;
    m_line.MaximumNumPoints = point_count;
    m_line.Marker = '.';
    m_line.LineWidth = 1.9;
    m_line.Color = [1 0 0];
end
