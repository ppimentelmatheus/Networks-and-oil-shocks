function out = markup_costpush_static(alpha, beta, Omega, Delta, gamma, phi, muD, opts)
%MARKUP_COSTPUSH_STATIC Static cost-push objects in Rubbo's network NKPC.
%
%   out = markup_costpush_static(alpha,beta,Omega,Delta,gamma,phi,muD)
%
% Inputs must already be in the same dimensional system. For Rubbo's
% calibrated 2012_full.mat this means the wage/labor-union sector is already
% included, so all objects are 406-dimensional.
%
% muD is an n x 1 vector of desired-markup shocks. A positive entry is a
% cost-push shock; a subsidy can be represented as a negative entry.

if nargin < 8 || isempty(opts)
    opts = struct();
end

tol = get_opt(opts, 'tol', 1e-10);

alpha = alpha(:);
beta = beta(:);
muD = muD(:);
Delta = as_diag_matrix(Delta);

n = length(alpha);
I = eye(n);

assert(length(beta) == n, 'beta must be n x 1.');
assert(length(muD) == n, 'muD must be n x 1.');
assert(all(size(Omega) == [n n]), 'Omega must be n x n.');
assert(all(size(Delta) == [n n]), 'Delta must be n x n.');

R = (I - Omega * Delta) \ I;
lambda = beta' / (I - Omega);
den = 1 - beta' * Delta * R * alpha;

% B is the slope vector before multiplying by (gamma + phi). The object b
% follows Rubbo's Matlab convention and already includes (gamma + phi).
B = Delta * R * alpha / den;
b = (gamma + phi) * B;

V = (Delta * R - B * (lambda - beta' * Delta * R)) * (I - Omega);
IminusV = I - V;

vA = Delta * R * ...
    (alpha * (lambda - beta' * Delta * R) / den - I);
uA = beta' * vA;

kappaC = beta' * b;
kappaDC = gamma + phi;

delta_diag = diag(Delta);
has_wage_sector = get_opt(opts, 'has_wage_sector', ...
    abs(alpha(1) - 1) < 1e-8 && abs(beta(1)) < 1e-8);
if has_wage_sector
    kappa_w = delta_diag(1) * (gamma + phi) / den;
else
    kappa_w = NaN;
end

markup_weights_CPI = beta' * Delta * R / den;
CPI_markup = markup_weights_CPI * muD;

DC_markup = lambda * muD;
y_DC_stabilizing = -DC_markup / (gamma + phi);

% Network pressure is a direct pass-through object. It is useful for
% decompositions along chains, but it is not by itself the full sectoral
% Phillips-curve markup term.
network_pressure_operator = Delta * R;
network_pressure = network_pressure_operator * muD;

markup_weights_DC = lambda;

can_compute_structural = all(abs(1 - delta_diag) > tol);
if can_compute_structural
    sector_markup_operator = IminusV * Delta / (I - Delta);
    sector_markup_pc = sector_markup_operator * muD;
else
    sector_markup_operator = NaN(n,n);
    sector_markup_pc = NaN(n,1);
end

out = struct();
out.alpha = alpha;
out.beta = beta;
out.Omega = Omega;
out.Delta = Delta;
out.gamma = gamma;
out.phi = phi;
out.muD = muD;
out.den = den;
out.R = R;
out.lambda = lambda;
out.B = B;
out.b = b;
out.V = V;
out.IminusV = IminusV;
out.vA = vA;
out.uA = uA;
out.kappaC = kappaC;
out.kappaDC = kappaDC;
out.kappa_w = kappa_w;
out.CPI_markup = CPI_markup;
out.DC_markup = DC_markup;
out.y_DC_stabilizing = y_DC_stabilizing;
out.network_pressure = network_pressure;
out.sector_markup_pc = sector_markup_pc;
out.network_pressure_operator = network_pressure_operator;
out.sector_markup_operator = sector_markup_operator;
out.markup_weights_CPI = markup_weights_CPI;
out.markup_weights_DC = markup_weights_DC;
out.can_compute_structural_sector_markup = can_compute_structural;

end

function Delta = as_diag_matrix(Delta)
if isvector(Delta)
    Delta = diag(Delta(:));
end
end

function value = get_opt(opts, field, default)
if isstruct(opts) && isfield(opts, field) && ~isempty(opts.(field))
    value = opts.(field);
else
    value = default;
end
end
