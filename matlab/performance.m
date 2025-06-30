clc

model_files = dir('./model *.csv');
[~, index] = max([model_files.datenum]);
model_file = fullfile(model_files(index).folder, model_files(index).name);

optitrack_files = dir('./optitrack *.csv');
[~, index] = max([optitrack_files.datenum]);
optitrack_file = fullfile(optitrack_files(index).folder, optitrack_files(index).name);

% or set manually:
% model_file=""
% optitrack_file=""
model_data = readmatrix(model_file)';
optitrack_data = readmatrix(optitrack_file)';

times = diff(model_data(1, :));
% histogram(times, 2000)
fprintf('Mean update time for model: %4.fms', 1000 * median(times))
