%% Monetary-policy comparison after an oil-sector markup shock.
%
% This script follows Rubbo-style paths and uses the clean cost-push modules.
% It compares output-gap rules after an oil desired-markup shock:
%   1. zero output gap
%   2. stabilize CPI
%   3. stabilize divine-coincidence inflation
%   4. partial reaction to CPI
%   5. partial reaction to divine-coincidence inflation

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

% Partial-reaction rules. theta = 1 is full stabilization of the target.
opts.theta_cpi = 0.50;
opts.theta_dc = 0.50;

% Loss weights. These are simple quadratic losses, not Rubbo's welfare
% matrix. They are useful for comparing policy rules transparently.
opts.loss_weight_y = 1;
opts.loss_weight_cpi = 1;
opts.loss_weight_dc = 1;
opts.loss_discount = opts.rho_disc;

results = markup_costpush_policy_compare(alpha, beta, Omega, Delta, ...
    gamma, phi, shock, opts);

rate_opts = struct();
rate_opts.terminal_y = 0;
rate_opts.terminal_piC = 0;
rates = struct([]);
rate_summary = zeros(length(results.policies), 2);
for i = 1:length(results.policies)
    rates(i).name = results.names{i};
    rates(i).rate = markup_policy_rate_path(results.policies(i).irf, ...
        gamma, rate_opts);
    rate_summary(i,:) = [rates(i).rate.impact_ann_pp, ...
        rates(i).rate.peak_abs_ann_pp];
end

%% Display summary table.

disp(' ')
disp('Policy comparison after oil-sector markup shock')
disp('Columns:')
disp(results.summary_columns')
disp('Rows:')
disp(results.names')
disp(results.summary)

try
    SummaryTable = array2table(results.summary, ...
        'VariableNames', results.summary_columns, ...
        'RowNames', results.names)
catch
    SummaryTable = results.summary;
end

%% Save outputs.

outdir = fullfile(oil_dir, 'output', 'markup_policy');
if ~exist(outdir, 'dir')
    mkdir(outdir)
end

save(fullfile(outdir, 'oil_markup_policy_results.mat'), ...
    'results', 'rates', 'rate_summary', 'oil_sector', 'mu0', 'opts')

%% Plot inflation responses.

figure
hold on
for i = 1:length(results.policies)
    plot(1:opts.T, 100*results.policies(i).irf.CPI_dynamic, 'LineWidth', 2)
end
xlabel('Quarters')
ylabel('CPI inflation response, p.p.')
title('CPI response under alternative policy rules')
legend(results.names, 'Location', 'northeast')
grid on
saveas(gcf, fullfile(outdir, 'policy_CPI_responses.png'))

figure
hold on
for i = 1:length(results.policies)
    plot(1:opts.T, 100*results.policies(i).irf.DC_dynamic, 'LineWidth', 2)
end
xlabel('Quarters')
ylabel('DC inflation response, p.p.')
title('Divine-coincidence response under alternative policy rules')
legend(results.names, 'Location', 'northeast')
grid on
saveas(gcf, fullfile(outdir, 'policy_DC_responses.png'))

figure
hold on
for i = 1:length(results.policies)
    plot(1:opts.T, 100*results.policies(i).y_path, 'LineWidth', 2)
end
xlabel('Quarters')
ylabel('Output gap, p.p.')
title('Output-gap paths under alternative policy rules')
legend(results.names, 'Location', 'southeast')
grid on
saveas(gcf, fullfile(outdir, 'policy_output_gap_paths.png'))

%% Plot loss comparison.

figure
bar(results.summary(:,4:6))
set(gca, 'XTickLabel', results.names)
ylabel('Discounted loss, x 10^4')
title('Quadratic loss comparison')
legend({'CPI objective', 'DC objective', 'Dual objective'}, ...
    'Location', 'northwest')
grid on
saveas(gcf, fullfile(outdir, 'policy_loss_comparison.png'))

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
