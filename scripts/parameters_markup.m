%% ============================================================
%% FILE: parameters_markup.m
%% ============================================================
%% Computes Phillips-curve objects with sectoral markup shocks
%% μ_t^D
%%
%% Extension of the original paper:
%% inflation can now arise from exogenous pricing-power shocks
%% instead of productivity shocks only.
%% ============================================================

function [lambda,b,v,kappa,u,kappa_w,vC,sector_markup] = ...
    parameters_markup(Alpha,Beta,omega,delta,gamma,phi,muD)

n = length(Alpha);

%% ------------------------------------------------------------
%% Leontief exposure
%% λ = β'(I-Ω)^(-1)
%% ------------------------------------------------------------

lambda = Beta'*(eye(n)-omega)^(-1);

%% ------------------------------------------------------------
%% Denominator of NKPC system
%% ------------------------------------------------------------

den = 1 - Beta'*delta*(eye(n)-omega*delta)^(-1)*Alpha;

%% ------------------------------------------------------------
%% Sectoral Phillips slopes
%% ------------------------------------------------------------

b = (gamma+phi)*delta*(eye(n)-omega*delta)^(-1)*Alpha/den;

%% ------------------------------------------------------------
%% Propagation matrix from productivity shocks
%% (kept for completeness)
%% ------------------------------------------------------------

v = delta*(eye(n)-omega*delta)^(-1)* ...
    (Alpha*(lambda - Beta'*delta*(eye(n)-omega*delta)^(-1))/den ...
    - eye(n));

%% ------------------------------------------------------------
%% Aggregate Phillips slope
%% ------------------------------------------------------------

kappa = Beta'*b;

%% ------------------------------------------------------------
%% Wage Phillips curve
%% ------------------------------------------------------------

kappa_w = 0.2*(gamma+phi)/den;

%% ------------------------------------------------------------
%% Aggregate productivity-shock pass-through
%% ------------------------------------------------------------

u = Beta'*v;

%% ============================================================
%% NEW PART: MARKUP SHOCK PROPAGATION
%%
%% v_t^C =
%% β'Δ(I-ΩΔ)^(-1)/(1-β'Δ(I-ΩΔ)^(-1)α) μ_t^D
%% ============================================================

markup_term = Beta' * delta * ...
    (eye(n)-omega*delta)^(-1) / den;

%% Aggregate CPI response
vC = markup_term * muD;

%% Sectoral inflation response
sector_markup = delta * ...
    (eye(n)-omega*delta)^(-1) * muD;

end