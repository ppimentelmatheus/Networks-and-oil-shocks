%% Interest-rate response after an oil-sector markup shock.
%
% This script builds on oil_markup_monetary_policy.m. It computes the
% nominal policy-rate path, relative to the natural rate, required to
% implement each output-gap policy path.

clear all
clc

%% Locate data using Rubbo-style folder conventions.

start_dir = cd;
this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir)
    this_dir = start_dir;
end

addpath(this_dir)
addpath(start_dir)
addpath(fileparts(this_dir))
addpath(fileparts(fileparts(this_dir)))
addpath(fileparts(fileparts(fileparts(this_dir))))

[parent_dir, current_name] = fileparts(start_dir);
[~, parent_name] = fileparts(parent_dir);

if exist(fullfile(start_dir, ...
        'ecta200578-sup-0002-dataandprograms', ...
        'calibration', 'data cleaning', 'IO tables'), 'dir')
    IO_dir = fullfile(start_dir, ...
        'ecta200578-sup-0002-dataandprograms', ...
        'calibration', 'data cleaning', 'IO tables');
elseif exist(fullfile(start_dir, ...
        'calibration', 'data cleaning', 'IO tables'), 'dir')
    IO_dir = fullfile(start_dir, ...
        'calibration', 'data cleaning', 'IO tables');
elseif strcmp(current_name, 'oil shocks')
    IO_dir = fullfile(parent_dir, 'data cleaning', 'IO tables');
elseif strcmp(current_name, 'IO tables') && strcmp(parent_name, 'data cleaning')
    IO_dir = start_dir;
else
    error(['Could not locate calibration/data cleaning/IO tables from: ', start_dir])
end

addpath(IO_dir)
IO_path = fullfile(IO_dir, 'clean data', '2012_clean');
load(IO_path)
delta_path = fullfile(IO_dir, 'clean data', 'delta_long');
load(delta_path)

data_cleaning_dir = fileparts(IO_dir);
calibration_dir = fileparts(data_cleaning_dir);
oil_dir = fullfile(calibration_dir, 'oil shocks');
if ~exist(oil_dir, 'dir')
    oil_dir = start_dir;
end

%% Build Rubbo's 406-dimensional economy.

gamma = 1;
phi = 2;

Delta = diag(delta_q);
[alpha, beta, Omega, Delta, lambda, b, v, kappa, u, kappa_w] = ...
    parameters(alpha, beta, Omega, Delta, gamma, phi);

n = length(alpha);

%% Shock and policy settings.

oil_sector = 15;
mu0 = 0.10;

shock = zeros(n,1);
shock(oil_sector) = mu0;

opts = struct();
opts.T = 40;
opts.rho_disc = 0.9975;
opts.rho_mu = 0.80;
opts.has_wage_sector = true;
opts.theta_cpi = 0.50;
opts.theta_dc = 0.50;
opts.loss_weight_y = 1;
opts.loss_weight_cpi = 1;
opts.loss_weight_dc = 1;
opts.loss_discount = opts.rho_disc;

results = markup_costpush_policy_compare(alpha, beta, Omega, Delta, ...
    gamma, phi, shock, opts);

%% Convert each output-gap policy into an interest-rate path.

rate_opts = struct();
rate_opts.terminal_y = 0;
rate_opts.terminal_piC = 0;

rates = struct([]);
rate_summary = zeros(length(results.policies), 4);

for i = 1:length(results.policies)
    rates(i).name = results.names{i};
    rates(i).rate = markup_policy_rate_path(results.policies(i).irf, ...
        gamma, rate_opts);

    rate_summary(i,:) = [
        rates(i).rate.impact_q_pp, ...
        rates(i).rate.peak_abs_q_pp, ...
        rates(i).rate.impact_ann_pp, ...
        rates(i).rate.peak_abs_ann_pp
    ];
end

rate_summary_columns = {'impact_q_pp', 'peak_abs_q_pp', ...
    'impact_ann_pp', 'peak_abs_ann_pp'};

disp(' ')
disp('Policy-rate response relative to natural rate')
disp('Columns:')
disp(rate_summary_columns')
disp('Rows:')
disp(results.names')
disp(rate_summary)

try
    RateTable = array2table(rate_summary, ...
        'VariableNames', rate_summary_columns, ...
        'RowNames', results.names)
catch
    RateTable = rate_summary;
end

%% Save outputs and figures.

outdir = fullfile(oil_dir, 'output', 'markup_policy');
if ~exist(outdir, 'dir')
    mkdir(outdir)
end

save(fullfile(outdir, 'oil_markup_interest_rate_results.mat'), ...
    'results', 'rates', 'rate_summary', 'rate_summary_columns', ...
    'oil_sector', 'mu0', 'opts')

figure
hold on
for i = 1:length(rates)
    plot(1:opts.T, rates(i).rate.rate_gap_ann_pp, 'LineWidth', 2)
end
xlabel('Quarters')
ylabel('Annualized p.p. relative to natural rate')
title('Policy-rate response under alternative rules')
legend(results.names, 'Location', 'northeast')
grid on
saveas(gcf, fullfile(outdir, 'policy_rate_paths_ann.png'))

figure
bar(rate_summary(:,3:4))
set(gca, 'XTickLabel', results.names)
ylabel('Annualized p.p.')
title('Impact and peak policy-rate response')
legend({'Impact', 'Peak absolute'}, 'Location', 'northwest')
grid on
saveas(gcf, fullfile(outdir, 'policy_rate_summary.png'))
