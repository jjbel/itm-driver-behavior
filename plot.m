u = udpport("datagram", "LocalHost", "0.0.0.0", "LocalPort", 5014);
disp("Polling for UDP data...");

cleanupObj = onCleanup(@cleanMeUp);

while true
    if u.NumDatagramsAvailable > 0
        data = read(u, u.NumDatagramsAvailable, "uint8");
        disp("Received:");
        disp(char(data.Data));
    end

    % pause(0.1); % avoid busy wait
end

function cleanMeUp()
    clear u
    % saves data to file (or could save to workspace)
    filename = [datestr(now, 'yyyy-mm-dd_HHMMSS') '.mat'];
    disp(filename)
    % save(filename, 'I', 'Z', 'U');
end
