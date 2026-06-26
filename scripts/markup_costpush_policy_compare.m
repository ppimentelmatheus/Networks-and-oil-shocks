function results = markup_costpush_policy_compare(alpha, beta, Omega, Delta, gamma, phi, shock, opts)
%MARKUP_COSTPUSH_POLICY_COMPARE Compare simple policy rules after markup shocks.
%
% Policies are expressed in output-gap space. This is the cleanest first
% layer for asking how a central bank should react before adding a full IS
% curve and interest-rate rule.
%
% Implemented rules:
%   zero_gap       y_t = 0
%   stabilize_CPI  choose y_t so CPI inflation is zero each period
%   stabilize_DC   choose y_t so DC inflation is zero each period
%   lean_CPI       partial reaction toward stabilize_CPI
%   lean_DC        partial reaction toward stabilize_DC

if nargin < 8 || isempty(opts)
    opts = struct();
end

T = get_opt(opts, 'T', 40);
rho_disc = get_opt(opts, 'rho_disc', 0.9975);
theta_cpi = get_opt(opts, 'theta_cpi', 0.5);
theta_dc = get_opt(opts, 'theta_dc', 0.5);

loss_weight_y = get_opt(opts, 'loss_weight_y', 1);
loss_weight_cpi = get_opt(opts, 'loss_weight_cpi', 1);
loss_weight_dc = get_opt(opts, 'loss_weight_dc', 1);
loss_discount = get_opt(opts, 'loss_discount', rho_disc);

shock = shock(:);
n = length(shock);

base_opts = opts;
base_opts.policy = 'zero_gap';
base = markup_costpush_irf(alpha, beta, Omega, Delta, gamma, phi, shock, base_opts);

static0 = base.static;

y_zero = zeros(T,1);
y_dc = base.y_dc_stabilizing;
y_cpi = compute_cpi_stabilizing_gap(static0, base.sector_markup_pc, rho_disc);

y_lean_cpi = theta_cpi * y_cpi;
y_lean_dc = theta_dc * y_dc;

names = {'zero_gap', 'stabilize_CPI', 'stabilize_DC', ...
    'lean_CPI', 'lean_DC'};
y_paths = {y_zero, y_cpi, y_dc, y_lean_cpi, y_lean_dc};

policies = struct([]);
summary = zeros(length(names), 6);

for i = 1:length(names)
    irf_opts = opts;
    irf_opts.policy = 'custom_y';
    irf_opts.y_path = y_paths{i};
    irf_opts.mu_path = base.mu_path;

    irf = markup_costpush_irf(alpha, beta, Omega, Delta, gamma, phi, shock, irf_opts);
    losses = compute_losses(irf, loss_weight_y, loss_weight_cpi, ...
        loss_weight_dc, loss_discount);

    policies(i).name = names{i};
    policies(i).y_path = y_paths{i};
    policies(i).irf = irf;
    policies(i).losses = losses;

    summary(i,:) = [
        100 * max(abs(irf.CPI_dynamic)), ...
        100 * max(abs(irf.DC_dynamic)), ...
        100 * max(abs(irf.y_path)), ...
        1e4 * losses.CPI_objective, ...
        1e4 * losses.DC_objective, ...
        1e4 * losses.dual_objective ...
    ];
end

results = struct();
results.policies = policies;
results.names = names;
results.summary = summary;
results.summary_columns = {'peak_abs_CPI_pp', 'peak_abs_DC_pp', ...
    'max_abs_output_gap_pp', 'loss_CPI_x1e4', ...
    'loss_DC_x1e4', 'loss_dual_x1e4'};
results.base = base;
results.y_cpi_stabilizing = y_cpi;
results.y_dc_stabilizing = y_dc;
results.options = opts;

end

function y_cpi = compute_cpi_stabilizing_gap(static0, sector_markup_pc, rho_disc)
T = size(sector_markup_pc, 2);
n = length(static0.beta);
y_cpi = zeros(T,1);
pi_next = zeros(n,1);

if abs(static0.kappaC) < 1e-12
    error('Cannot stabilize CPI: kappaC is too close to zero.')
end

for t = T:-1:1
    expected_term = rho_disc * static0.beta' * static0.IminusV * pi_next;
    shock_term = static0.beta' * sector_markup_pc(:,t);
    y_cpi(t) = -(expected_term + shock_term) / static0.kappaC;

    pi_t = rho_disc * static0.IminusV * pi_next ...
        + static0.b * y_cpi(t) + sector_markup_pc(:,t);
    pi_next = pi_t;
end
end

function losses = compute_losses(irf, loss_weight_y, loss_weight_cpi, loss_weight_dc, loss_discount)
T = irf.T;
disc = (loss_discount .^ (0:T-1))';
y = irf.y_path;
piC = irf.CPI_dynamic;
piDC = irf.DC_dynamic;

losses = struct();
losses.CPI_objective = sum(disc .* (piC.^2 + loss_weight_y * y.^2));
losses.DC_objective = sum(disc .* (piDC.^2 + loss_weight_y * y.^2));
losses.dual_objective = sum(disc .* ...
    (loss_weight_cpi * piC.^2 + loss_weight_dc * piDC.^2 ...
    + loss_weight_y * y.^2));
end

function value = get_opt(opts, field, default)
if isstruct(opts) && isfield(opts, field) && ~isempty(opts.(field))
    value = opts.(field);
else
    value = default;
end
end
