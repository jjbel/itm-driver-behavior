clc

model_file = "Take 2025-06-11 05.36.59 PM model.csv";
model_data = readmatrix(model_file)';
% start_time_model = datetime(B(1) / 1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'Europe/Berlin');

optitrack_file = "Take 2025-06-11 04.40.35 PM_004.csv";
optitrack_data = readmatrix(optitrack_file, NumHeaderLines = 7);

info = textscan(fopen(optitrack_file), ' %s', 24, Delimiter = ',');
disp(info{1}{12});
startTimeStr = info{1}{12}(1:26);
start_time_optitrack = datetime(startTimeStr, InputFormat = 'yyyy-MM-dd hh.mm.ss.SSS a', TimeZone = 'Europe/Berlin');

otimes = optitrack_data(:, 2);
oX = optitrack_data(:, 3);
oY = optitrack_data(:, 4);
oZ = optitrack_data(:, 5);

mtimes = model_data(1, :);
mY = model_data(2, :);
mtimes = mtimes / 1000 - posixtime(start_time_optitrack);
% mY = mY * 180/3.1415 + 90;
% mY = mY + 22;
mY = -1 * mY;

% export settings:
% Markers: Off
% TODO

f = @(xq) interp1(otimes, oY, xq);

function error = compute_objective(f, x, y, params)
    a = params(2) * y + params(3);
    b = f(x + params(1));
    % f(mtimes(121)) is NaN. surrounding are zero
    b(isnan(b)) = 0;
    error = mean((a -b) .^ 2);
end

objective = @(params)compute_objective(f, mtimes, mY, params);

hold on
yline(0)
% plot(otimes, oX, '-r');
plot(otimes, oY, '-g', 'LineWidth', 2.2);
% plot(otimes, oZ, '-b');

% disp(model_data)
plot(mtimes, mY, '-b', 'LineWidth', 2.2);

disp(objective([0, 1, 0]));
disp(objective([0, 5, -40]));

[args, val] = fminsearch(objective, [0, 1, 0]);
disp(args);
disp(val);

[args, val] = fminsearch(objective, [0, 5, -40]);
disp(args);
disp(val);

[args, val] = fminunc(objective, [0, 5, -40]);
disp(args);
disp(sqrt(val));

mY = mY * args(2) + args(3);
% plot(mtimes + args(1), mY, '-r', 'LineWidth', 2.2);

fontsize(scale = 1.6)
xlabel('Time (s)')
ylabel('Head Angle (deg)')
title('Head Tracking - Optitrack vs Model')

% legend("Optitrack", "Model", "Model Scaled");
legend("Optitrack", "Model Scaled");

hold off
