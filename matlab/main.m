function main
    clc

    addpath('..\..\OptiTrack_MATLAB_Plugin_1.1.0', '..\..\OptiTrack_MATLAB_Plugin_1.1.0\Matlab');
    % to be accessible in cleanupFn, needs to be passed by reference - use a handle
    natnetclient = SharedVar();
    natnetclient.Value = natnet;
    connection = natnetclient.Value.ConnectToNatNet('127.0.0.1', '127.0.0.1', 'Multicast');

    if connection < 1
        disp("no connection, quitting");
        return
    end

    natnetclient.Value.addlistener(1, 'natnet_callback');
    natnetclient.Value.enable(0);

    global data

    u = udpport("datagram", "LocalHost", "0.0.0.0", "LocalPort", 5014);

    % to be accessible in cleanupFn, needs to be passed by reference - use a handle
    model_data_var = SharedVar();
    model_data_var.Value = [];

    cleanup = onCleanup(@() cleanupFn(model_data_var, natnetclient));

    disp("C5");

    % Run and execute eventhandler queues until a key is pressed to exit pause.
    % fprintf('(Enter any key to quit)\n\n')
    % pause;

    while true

        if u.NumDatagramsAvailable > 0
            datagrams = read(u, u.NumDatagramsAvailable, "uint8");
            % disp("Received:");

            for i = 1:length(datagrams)
                datagram = datagrams(i);
                timestamp = typecast(uint8(datagram.Data(1:8)), 'double');
                value = typecast(uint8(datagram.Data(9:16)), 'double');
                % disp(datetime(timestamp / 1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'Europe/Berlin'));
                % disp(value);
                fprintf('m: %f\n', value);

                model_data_var.Value = [model_data_var.Value [timestamp; value]];
            end

        end

        if ~isempty(data)
            % disp(data(end));
            fprintf('o: %f', data(end));
        end

        fprintf('\n\n');

        % TODO needed else CtrlC doesnt call cleanupFn
        pause(1/60); % avoid busy wait
    end

end

function cleanupFn(model_data_var, natnetclient)
    % if don't cleanup, matlab process keeps port open, can't reuse it
    clear u
    disp('closed socket.');

    natnetclient.Value.disable(0);
    disp('disabled natnet callbacks.');

    % this uses the same filename format as optirack, but appends " model" before .csv
    csv_file = "Take " + string(datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd hh.mm.ss a')) + " model.csv"
    disp(csv_file)
    % writematrix(model_data_var.Value', csv_file);
    disp('exported csv.');
end
