% for cleanup to work, apparently needs to be in function of the same name
function plot
    u = udpport("datagram", "LocalHost", "0.0.0.0", "LocalPort", 5014);

    cleanup = onCleanup(@cleanupFn);

    while true

        if u.NumDatagramsAvailable > 0
            data = read(u, u.NumDatagramsAvailable, "uint8");
            disp("Received:");
            disp(char(data.Data));
        end

        pause(0.1); % avoid busy wait
    end

end

% if don't cleanup, matlab process keeps port open, can't reuse it
function cleanupFn
    clear u
    disp('closed socket.')
end
