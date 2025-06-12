% for cleanup to work, apparently needs to be in function of the same name
function model_to_csv
    u = udpport("datagram", "LocalHost", "0.0.0.0", "LocalPort", 5014);

    % to be accessible in cleanupFn, needs to be passed by reference - use a handle
    model_data_var = SharedVar();
    model_data_var.Value = []; % [1]; [1]
    % plot(model_data_var.Value(1,:), model_data_var.Value(2,:))
    % linkdata on

    cleanup = onCleanup(@() cleanupFn(model_data_var));

    while true

        if u.NumDatagramsAvailable > 0
            datagrams = read(u, u.NumDatagramsAvailable, "uint8");
            disp("Received:");

            for i = 1:length(datagrams)
                datagram = datagrams(i);
                timestamp = typecast(uint8(datagram.Data(1:8)), 'double');
                value = typecast(uint8(datagram.Data(9:16)), 'double');
                disp(datetime(timestamp / 1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'Europe/Berlin'));
                disp(value);

                % disp(model_data_var.Value(1, :));

                model_data_var.Value = [model_data_var.Value [timestamp; value]];
            end

        end

        % TODO needed else CtrlC doesnt call cleanupFn
        pause(0.0-1); % avoid busy wait
    end

end

function cleanupFn(data)
    % if don't cleanup, matlab process keeps port open, can't reuse it
    clear u
    disp('closed socket.');

    % this uses the same filename format as optirack, but appends " model" before .csv
    csv_file = "Take " + string(datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd hh.mm.ss a')) + " model.csv"
    disp(csv_file)
    writematrix(data.Value', csv_file);
    disp('exported csv.');
end
