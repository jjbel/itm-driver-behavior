clc

model_file = "Take 2025-06-04 04.29.11 PM model.csv";
model_data = readmatrix(model_file)';
% start_time_model = datetime(B(1) / 1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'Europe/Berlin');

optitrack_file = "Take 2025-06-04 02.04.01 PM_001.csv";
optitrack_data = readmatrix(optitrack_file, NumHeaderLines = 7);

info = textscan(fopen(optitrack_file), ' %s', 24, Delimiter = ',');
startTimeStr = info{1}{12}(1:26);
start_time_optitrack = datetime(startTimeStr, InputFormat = 'yyyy-MM-dd hh.mm.ss.SSS a', TimeZone = 'Europe/Berlin');

otimes = optitrack_data(:, 2);
oX = optitrack_data(:, 3);
oY = optitrack_data(:, 4);
oZ = optitrack_data(:, 5);

mtimes = model_data(1, :);
mY = model_data(2, :);
mtimes = mtimes / 1000 - posixtime(start_time_optitrack);
mY = mY * 180/3.1415 + 90;

% export settings:
% Markers: Off
% TODO

f = @(xq) interp1(otimes, oY, xq);

function error = compute_objective(f, x, y, params)
    a = params(3) * y + params(4);
    b = f(params(1) * x + params(2));
    % f(mtimes(121)) is NaN. surrounding are zero
    b(isnan(b)) = 0;
    error = mean((a -b) .^ 2);
end

objective = @(params)compute_objective(f, mtimes, mY, params);

hold on

% plot(otimes, oX, '-r');
plot(otimes, oY, '-g', 'LineWidth', 2.2);
% plot(otimes, oZ, '-b');

% disp(model_data)
plot(mtimes, mY, '-b', 'LineWidth', 2.2);

mY = (mY - 8) * 5;
plot(mtimes, mY, '-r', 'LineWidth', 2.2);

fontsize(scale = 1.6)
xlabel('Time (s)')
ylabel('Head Angle (deg)')
title('Head Tracking - Optitrack vs Model')

legend("Optitrack", "Model", "Model Scaled");

disp(objective([1, 0, 1, 0]));
disp(objective([1, 0, 5, -40]));
disp(fminsearch(objective, [1, 0, 1, 0]));

hold off
