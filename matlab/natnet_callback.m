function natnet_callback(~, evnt)
    % The event callback function executs each time a frame of mocap data is delivered.
    % to Matlab. Matlab will lag if the data rate from the Host is too high.

    global optitrack_data
    global optitrack_start
    global o_line_x o_line_y o_line_z subplot_ox subplot_oy subplot_oz plot_time_look_ahead plot_time_look_back
    global stdout
    global axis_setting

    timestamp = double(evnt.data.fTimestamp);

    if isempty(optitrack_start)
        optitrack_start = timestamp;
        stdout = stdout + "ostart\n";
    end

    % this should always happen! timestamp=0 on first frame
    timestamp = timestamp - optitrack_start;

    % Get the rb rotation
    sim = transform(evnt.data.RigidBodies(1));
    head = transform(evnt.data.RigidBodies(2));
    pos = trvec(se3inv(sim) * head);
    % stdout = stdout + sprintf("o: %f %.2f %.2f\n", [timestamp, pos(2) pos(3)]);

    % Fill the animated line's queue with the rb position
    optitrack_data = [optitrack_data [timestamp; pos(1); pos(2); pos(3)]];

    o_line_x.addpoints(timestamp, pos(1));
    o_line_y.addpoints(timestamp, pos(2));
    o_line_z.addpoints(timestamp, pos(3));
    % stdout = stdout + sprintf("o: %f, %f\n", timestamp, z);

    %  Dynamically move the axis of the graph
    axis_setting = [-plot_time_look_back + optitrack_data(1, end), plot_time_look_ahead + optitrack_data(1, end), -0.6, 0.6];

    set(gcf, 'CurrentAxes', subplot_ox)
    axis(axis_setting);
    drawnow

    set(gcf, 'CurrentAxes', subplot_oy)
    axis(axis_setting);
    drawnow

    set(gcf, 'CurrentAxes', subplot_oz)
    axis(axis_setting);
    drawnow
end

function r = transform(rigidbody)
    q = quaternion(rigidbody.qx, rigidbody.qy, rigidbody.qz, rigidbody.qw);
    qRot = quaternion(0, 0, 0, 1);
    q = mtimes(q, qRot); % TODO needed?

    translation = [rigidbody.x rigidbody.y rigidbody.z];

    r = se3(RotationMatrix(q), translation);
end

function T_inv = se3inv(T)
    R = rotm(T);
    t = trvec(T)';
    T_inv = se3(R', (-R' * t)');
end

function s = m2str(M)
    s = sprintf(['%.2f\t%.2f\t%.2f\t%.2f\n' ...
                     '%.2f\t%.2f\t%.2f\t%.2f\n' ...
                     '%.2f\t%.2f\t%.2f\t%.2f\n' ...
                 '%.2f\t%.2f\t%.2f\t%.2f\n'], M);
end
