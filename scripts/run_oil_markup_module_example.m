%% Clean cost-push module example using Rubbo's calibrated U.S. data.
% This leaves the prototype files untouched.

clear all
clc

% Resolve paths in the same spirit as Rubbo's scripts, but without assuming
% the current folder. This works from:
%   1) the project root containing ecta200578-sup-0002-dataandprograms
%   2) replication files_original/calibration/oil shocks
%   3) replication files_original/calibration/data cleaning/IO tables
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
[grandparent_dir, parent_name] = fileparts(parent_dir);

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

gamma = 1;
phi = 2;

% Expand from the 405-sector real economy to Rubbo's 406-dimensional system
% with the wage/labor-union sector as sector 1.
Delta = diag(delta_q);
[alpha, beta, Omega, Delta, lambda, b, v, kappa, u, kappa_w] = ...
    parameters(alpha, beta, Omega, Delta, gamma, phi);

n = length(alpha);
oil_sector = 15;  % In 2012_full, sector 1 is wage/labor union.

mu0 = 0.10;
shock = zeros(n,1);
shock(oil_sector) = mu0;

opts = struct();
opts.T = 40;
opts.rho_disc = 0.9975;
opts.rho_mu = 0.80;
opts.policy = 'zero_gap';
opts.has_wage_sector = true;

static_oil = markup_costpush_static(alpha,beta,Omega,Delta,gamma,phi,shock,opts);
irf_zero_gap = markup_costpush_irf(alpha,beta,Omega,Delta,gamma,phi,shock,opts);

opts.policy = 'stabilize_DC';
irf_stabilize_dc = markup_costpush_irf(alpha,beta,Omega,Delta,gamma,phi,shock,opts);

% Example subsidy: offset half of the oil markup shock in the same sector.
subsidy = zeros(n,1);
subsidy(oil_sector) = 0.05;

opts.policy = 'zero_gap';
opts.subsidy = subsidy;
irf_subsidy = markup_costpush_irf(alpha,beta,Omega,Delta,gamma,phi,shock,opts);

disp('Static impact responses to oil markup shock')
Table = table(static_oil.CPI_markup, static_oil.DC_markup, ...
    static_oil.y_DC_stabilizing, ...
    'VariableNames', {'CPI_markup','DC_markup','y_DC_stabilizing'})

outdir = fullfile(oil_dir, 'output', 'markup_module');
if ~exist(outdir, 'dir')
    mkdir(outdir)
end

save(fullfile(outdir, 'oil_markup_module_results.mat'), ...
    'static_oil', 'irf_zero_gap', 'irf_stabilize_dc', 'irf_subsidy', ...
    'oil_sector', 'mu0', 'subsidy')

figure
plot(1:opts.T, 100*irf_zero_gap.CPI_dynamic, 'LineWidth', 2)
hold on
plot(1:opts.T, 100*irf_zero_gap.DC_dynamic, '--', 'LineWidth', 2)
plot(1:opts.T, 100*irf_subsidy.CPI_dynamic, ':', 'LineWidth', 2)
xlabel('Quarters')
ylabel('Inflation response, p.p.')
title('Dynamic response to oil markup shock')
legend('CPI, no subsidy', 'DC, no subsidy', 'CPI, subsidy')
grid on
saveas(gcf, fullfile(outdir, 'oil_markup_dynamic_irf.png'))

figure
plot(1:opts.T, 100*irf_zero_gap.network_pressure(oil_sector,:), 'LineWidth', 2)
hold on
plot(1:opts.T, 100*irf_subsidy.network_pressure(oil_sector,:), '--', 'LineWidth', 2)
xlabel('Quarters')
ylabel('Network pressure, p.p.')
title('Oil-sector network pressure')
legend('No subsidy', 'Subsidy')
grid on
saveas(gcf, fullfile(outdir, 'oil_markup_network_pressure.png'))
