model_file = "Take 2025-06-04 04.29.11 PM model.csv";
model_data = readmatrix(model_file)';
% start_time_model = datetime(B(1) / 1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'Europe/Berlin');

optitrack_file = "Take 2025-06-04 02.04.01 PM_001.csv";
optitrack_data = readmatrix(optitrack_file, NumHeaderLines = 7);

info = textscan(fopen(optitrack_file), ' %s', 24, Delimiter = ',');
startTimeStr = info{1}{12}(1:26);
start_time_optitrack = datetime(startTimeStr, InputFormat = 'yyyy-MM-dd hh.mm.ss.SSS a', TimeZone = 'Europe/Berlin');

% disp(start_time_optitrack);
% disp(posixtime(start_time_optitrack));

model_data(1, :) = model_data(1, :) / 1000 - posixtime(start_time_optitrack);
model_data(2, :) = model_data(2, :) * 180/3.1415 + 90;
model_data(2, :) = (model_data(2, :) - 8) * 5;

% export settings:
% Markers: Off
% TODO

hold on

otimes = optitrack_data(:, 2);
oX = optitrack_data(:, 3);
oY = optitrack_data(:, 4);
oZ = optitrack_data(:, 5);

% plot(otimes, oX, '-r');
plot(otimes, oY, '-g');
% plot(otimes, oZ, '-b');

% disp(model_data)
plot(model_data(1, :), model_data(2, :), '-r');

legend("optitrack", "model");

hold off
