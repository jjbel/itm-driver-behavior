clc

model_files = dir('./model *.csv');
[~, index] = max([model_files.datenum]);
model_file = fullfile(model_files(index).folder, model_files(index).name);

optitrack_files = dir('./optitrack *.csv');
[~, index] = max([optitrack_files.datenum]);
optitrack_file = fullfile(optitrack_files(index).folder, optitrack_files(index).name);

% or set manually:de
% model_file=""
% optitrack_file=""
model_data = readmatrix(model_file)';
optitrack_data = readmatrix(optitrack_file)';

fontsize(scale = 1.6)
title('Head Tracking - Optitrack vs Model')
xlabel('Time (s)')
ylabel('Head Angle (deg)')
legend("Optitrack", "Model Scaled");
hold on
plot(model_data(1, :), model_data(2, :), '-r', 'LineWidth', 2.2)
plot(optitrack_data(1, :), optitrack_data(2, :), '-g', 'LineWidth', 2.2)
hold off

function r = f(model_data, xstart, xend)
    condition = model_data(1, :) > xstart & model_data(1, :) < xend;
    r = mean(model_data(2, condition));
end

disp(f(model_data, 36.4, 43.6))
disp(f(model_data, 46.3, 54.5))
disp(f(model_data, 58.7, 64.1))
disp(f(model_data, 67.2, 70.2))
