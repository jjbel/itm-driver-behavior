function natnet_callback(~, evnt)
    % The event callback function executs each time a frame of mocap data is delivered.
    % to Matlab. Matlab will lag if the data rate from the Host is too high.

    global optitrack_data
    global optitrack_start
    global o_line
    global stdout

    timestamp = double(evnt.data.fTimestamp);

    if isempty(optitrack_start)
        optitrack_start = timestamp;
        stdout = stdout + "ostart\n";
    end

    % this should always happen! timestamp=0 on first frame
    timestamp = timestamp - optitrack_start;

    % TODO printing in callback does nothing
    % fprintf("hello");

    % Get the rb rotation
    rbnum = 1;
    rb = evnt.data.RigidBodies(rbnum);
    q = quaternion(rb.qx, rb.qy, rb.qz, rb.qw);
    qRot = quaternion(0, 0, 0, 1);
    q = mtimes(q, qRot);
    a = EulerAngles(q, 'zyx');
    % eulerx = a(1) * -180.0 / pi;
    eulery = a(2) * 180.0 / pi;
    % eulerz = a(3) * -180.0 / pi;

    % just to match orientation of model
    eulery = -eulery;

    % Fill the animated line's queue with the rb position
    optitrack_data = [optitrack_data [timestamp; eulery]];

    o_line.addpoints(timestamp, eulery);
    stdout = stdout + sprintf("o: %f, %f\n", timestamp, eulery);
end
