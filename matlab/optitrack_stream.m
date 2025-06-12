% From: Optitrack Sample for Rigid Body Pose Data
clc
% change this to your location of the Matlab plugin folder
addpath('..\..\OptiTrack_MATLAB_Plugin_1.1.0', '..\..\OptiTrack_MATLAB_Plugin_1.1.0\Matlab');
NatNetEventHandlerSample();

function NatNetEventHandlerSample
    global data

    fprintf('\nNatNet Event Handler Sample Start\n')
    fprintf('=========================================================\n')
    pause(2);

    % create an instance of the natnet client class
    fprintf('Creating natnet class object\n')
    natnetclient = natnet;

    % connect the client to the server (multicast over local loopback)
    connection = natnetclient.ConnectToNatNet('127.0.0.1', '127.0.0.1', 'Multicast');

    if connection < 1
        return
    end

    fprintf('Adding callback functions to execute with each frame of mocap\n')
    natnetclient.addlistener(1, 'natnet_callback');
    natnetclient.enable(0)

    for i = 1:400
        % disp(i);

        if ~isempty(data)
            disp(data(end));
        end

        pause(1/60);
    end

    natnetclient.disable(0)
    disp('NatNet Event Handler Sample End')
end
