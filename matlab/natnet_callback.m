function natnet_callback(~, evnt)
    % The event callback function executs each time a frame of mocap data is delivered.
    % to Matlab. Matlab will lag if the data rate from the Host is too high.

    global data

    % local variables
    persistent frame1
    persistent lastframe1

    % Get the frame number
    frame1 = double(evnt.data.iFrame);

    if ~isempty(frame1) && ~isempty(lastframe1)

        if frame1 < lastframe1
            % clear points?
        end

    end

    rbnum = 1;

    % Get the rb rotation
    rb = evnt.data.RigidBodies(rbnum);
    q = quaternion(rb.qx, rb.qy, rb.qz, rb.qw);
    qRot = quaternion(0, 0, 0, 1);
    q = mtimes(q, qRot);
    a = EulerAngles(q, 'zyx');
    eulerx = a(1) * -180.0 / pi;
    eulery = a(2) * 180.0 / pi;
    eulerz = a(3) * -180.0 / pi;

    % Fill the animated line's queue with the rb position
    frame = frame1;
    data = [data [frame; eulery]];
    lastframe1 = frame1;
end
