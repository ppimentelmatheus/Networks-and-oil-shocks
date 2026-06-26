function irf = markup_costpush_irf(alpha, beta, Omega, Delta, gamma, phi, shock, opts)
%MARKUP_COSTPUSH_IRF IRFs to sectoral desired-markup shocks.
%
% This function separates two objects:
%   1. static pass-through each period, computed by markup_costpush_static;
%   2. forward-looking sectoral NKPC dynamics from Rubbo's supplement:
%        pi_t = rho (I - V) E_t pi_{t+1} + b y_t
%               + (I - V) Delta (I - Delta)^(-1) mu_t^D.
%
% The dynamic block currently supports simple output-gap rules:
%   opts.policy = 'zero_gap'     -> y_t = 0
%   opts.policy = 'stabilize_DC' -> y_t closes the DC Phillips curve
%   opts.policy = 'custom_y'     -> opts.y_path must be T x 1

if nargin < 8 || isempty(opts)
    opts = struct();
end

T = get_opt(opts, 'T', 40);
rho_disc = get_opt(opts, 'rho_disc', 0.9975);
rho_mu = get_opt(opts, 'rho_mu', 0.80);
policy = get_opt(opts, 'policy', 'zero_gap');

shock = shock(:);
n = length(shock);

subsidy = get_opt(opts, 'subsidy', zeros(n,1));
subsidy = subsidy(:);
rho_subsidy = get_opt(opts, 'rho_subsidy', rho_mu);

mu_path = get_opt(opts, 'mu_path', []);
if isempty(mu_path)
    mu_path = zeros(n,T);
    subsidy_path = zeros(n,T);
    mu_path(:,1) = shock;
    subsidy_path(:,1) = subsidy;
    for t = 2:T
        mu_path(:,t) = rho_mu * mu_path(:,t-1);
        subsidy_path(:,t) = rho_subsidy * subsidy_path(:,t-1);
    end
    mu_path = mu_path - subsidy_path;
else
    assert(all(size(mu_path) == [n T]), 'opts.mu_path must be n x T.');
end

static0 = markup_costpush_static(alpha,beta,Omega,Delta,gamma,phi,mu_path(:,1),opts);

CPI_static = zeros(T,1);
DC_static = zeros(T,1);
y_dc_stabilizing = zeros(T,1);
network_pressure = zeros(n,T);
sector_markup_pc = zeros(n,T);

for t = 1:T
    CPI_static(t) = static0.markup_weights_CPI * mu_path(:,t);
    DC_static(t) = static0.markup_weights_DC * mu_path(:,t);
    y_dc_stabilizing(t) = -DC_static(t) / (gamma + phi);
    network_pressure(:,t) = static0.network_pressure_operator * mu_path(:,t);
    if static0.can_compute_structural_sector_markup
        sector_markup_pc(:,t) = static0.sector_markup_operator * mu_path(:,t);
    else
        sector_markup_pc(:,t) = NaN(n,1);
    end
end

switch policy
    case 'zero_gap'
        y_path = zeros(T,1);
    case 'stabilize_DC'
        y_path = y_dc_stabilizing;
    case 'custom_y'
        y_path = get_opt(opts, 'y_path', []);
        assert(length(y_path) == T, 'opts.y_path must be T x 1.');
        y_path = y_path(:);
    otherwise
        error('Unknown policy: %s', policy);
end

pi_sector = NaN(n,T);
CPI_dynamic = NaN(T,1);
DC_dynamic = NaN(T,1);

if static0.can_compute_structural_sector_markup
    pi_next = zeros(n,1);
    for t = T:-1:1
        pi_t = rho_disc * static0.IminusV * pi_next ...
            + static0.b * y_path(t) + sector_markup_pc(:,t);
        pi_sector(:,t) = pi_t;
        pi_next = pi_t;
    end
    CPI_dynamic = (static0.beta' * pi_sector)';
end

% The divine-coincidence index has its own scalar Phillips curve.
pi_dc_next = 0;
for t = T:-1:1
    pi_dc_t = rho_disc * pi_dc_next ...
        + (gamma + phi) * y_path(t) + DC_static(t);
    DC_dynamic(t) = pi_dc_t;
    pi_dc_next = pi_dc_t;
end

irf = struct();
irf.T = T;
irf.rho_disc = rho_disc;
irf.rho_mu = rho_mu;
irf.policy = policy;
irf.mu_path = mu_path;
irf.y_path = y_path;
irf.CPI_static = CPI_static;
irf.DC_static = DC_static;
irf.y_dc_stabilizing = y_dc_stabilizing;
irf.network_pressure = network_pressure;
irf.sector_markup_pc = sector_markup_pc;
irf.pi_sector = pi_sector;
irf.CPI_dynamic = CPI_dynamic;
irf.DC_dynamic = DC_dynamic;
irf.static = static0;

end

function value = get_opt(opts, field, default)
if isstruct(opts) && isfield(opts, field) && ~isempty(opts.(field))
    value = opts.(field);
else
    value = default;
end
end
