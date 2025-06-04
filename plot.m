% for cleanup to work, apparently needs to be in function of the same name
function plot
    u = udpport("datagram", "LocalHost", "0.0.0.0", "LocalPort", 5014);

    cleanup = onCleanup(@cleanupFn);

    data = [];

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
            end

        end

        pause(0.1); % avoid busy wait
    end

end

% if don't cleanup, matlab process keeps port open, can't reuse it
function cleanupFn
    clear u
    disp('closed socket.')
end
