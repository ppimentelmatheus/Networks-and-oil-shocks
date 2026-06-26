%% ============================================================
%% FILE: oil_markup_shock.m
%% ============================================================
%% IRFs and tables for an oil-sector markup shock
%%
%% Implements the supplement extension:
%% μ_t^D shocks instead of productivity shocks.
%% ============================================================

clear all
clc

%% ============================================================
%% LOAD DATA
%% ============================================================

IO_dir = fullfile(cd,'..');
IO_dir = [IO_dir '/data cleaning/IO tables'];

addpath(IO_dir)

IO_path = [IO_dir '/final data/2012_full'];
load(IO_path)

%% ============================================================
%% PARAMETERS
%% ============================================================

gamma = 1;
phi   = 2;

n = length(alpha);

%% ============================================================
%% OIL SECTOR
%%
%% Verify whether oil is 14 or 15 in your classification
%% ============================================================

oil_sector = 15;

%% ============================================================
%% MARKUP SHOCK
%%
%% μ_t^D
%% ============================================================

mu0 = 0.10;

%% ============================================================
%% BASELINE RIGIDITY
%% ============================================================

Delta_actual = Delta;

%% ============================================================
%% UNIFORM RIGIDITY
%% ============================================================

Delta_mean = diag(mean(diag(Delta))*ones(n,1));

%% ============================================================
%% UNIFORM + FLEXIBLE OIL
%% ============================================================

Delta_meanOil = Delta_mean;
Delta_meanOil(oil_sector,oil_sector) = 1;

%% ============================================================
%% STATIC COMPARISON TABLE
%% ============================================================

muD = zeros(n,1);
muD(oil_sector) = mu0;

%% ------------------------------------------------------------
%% Actual δ
%% ------------------------------------------------------------

[~,~,~,~,~,~,vC_actual,~] = ...
    parameters_markup(alpha,beta,Omega,...
    Delta_actual,gamma,phi,muD);

%% ------------------------------------------------------------
%% Uniform δ
%% ------------------------------------------------------------

[~,~,~,~,~,~,vC_mean,~] = ...
    parameters_markup(alpha,beta,Omega,...
    Delta_mean,gamma,phi,muD);

%% ------------------------------------------------------------
%% Uniform δ + flexible oil
%% ------------------------------------------------------------

[~,~,~,~,~,~,vC_oilflex,~] = ...
    parameters_markup(alpha,beta,Omega,...
    Delta_meanOil,gamma,phi,muD);

%% ============================================================
%% DISPLAY TABLE
%% ============================================================

disp(' ')
disp('============================================')
disp('CPI RESPONSE TO OIL MARKUP SHOCK')
disp('============================================')

Table = table( ...
    vC_actual, ...
    vC_oilflex, ...
    vC_mean, ...
    'VariableNames', ...
    {'ActualDelta','UniformDeltaOilFlex','UniformDelta'})

%% ============================================================
%% IRFs
%% ============================================================

T = 40;

rho_mu = 0.80;

IRF_CPI_actual  = zeros(T,1);
IRF_CPI_mean    = zeros(T,1);
IRF_CPI_oilflex = zeros(T,1);

%% Sectoral IRFs
IRF_transport = zeros(T,1);
IRF_manuf     = zeros(T,1);
IRF_oil       = zeros(T,1);

%% ------------------------------------------------------------
%% Build AR(1) markup process
%% ------------------------------------------------------------

mu_path = zeros(n,T);

mu_path(oil_sector,1) = mu0;

for t = 2:T
    mu_path(:,t) = rho_mu * mu_path(:,t-1);
end

%% ============================================================
%% COMPUTE IRFs
%% ============================================================

for t = 1:T

    %% --------------------------------------------------------
    %% Actual δ
    %% --------------------------------------------------------

    [~,~,~,~,~,~,vC,sector_markup] = ...
        parameters_markup(alpha,beta,Omega,...
        Delta_actual,gamma,phi,mu_path(:,t));

    IRF_CPI_actual(t) = vC;

    %% --------------------------------------------------------
    %% Sectoral examples
    %%
    %% Check sector numbering in your data
    %% --------------------------------------------------------

    IRF_oil(t)       = sector_markup(oil_sector);

    IRF_transport(t) = sector_markup(20);

    IRF_manuf(t)     = sector_markup(30);

    %% --------------------------------------------------------
    %% Uniform δ
    %% --------------------------------------------------------

    [~,~,~,~,~,~,vC_mean_temp,~] = ...
        parameters_markup(alpha,beta,Omega,...
        Delta_mean,gamma,phi,mu_path(:,t));

    IRF_CPI_mean(t) = vC_mean_temp;

    %% --------------------------------------------------------
    %% Uniform δ + flexible oil
    %% --------------------------------------------------------

    [~,~,~,~,~,~,vC_oilflex_temp,~] = ...
        parameters_markup(alpha,beta,Omega,...
        Delta_meanOil,gamma,phi,mu_path(:,t));

    IRF_CPI_oilflex(t) = vC_oilflex_temp;

end

%% ============================================================
%% PLOT CPI IRFs
%% ============================================================

figure

plot(1:T,IRF_CPI_actual,'LineWidth',2)
hold on

plot(1:T,IRF_CPI_mean,'--','LineWidth',2)

plot(1:T,IRF_CPI_oilflex,':','LineWidth',2)

xlabel('Quarters')
ylabel('CPI inflation')

title('IRF to Oil Markup Shock')

legend('Actual \delta',...
       'Uniform \delta',...
       'Uniform \delta + Flexible Oil')

grid on

%% ============================================================
%% PLOT SECTORAL IRFs
%% ============================================================

figure

plot(1:T,IRF_oil,'LineWidth',2)
hold on

plot(1:T,IRF_transport,'--','LineWidth',2)

plot(1:T,IRF_manuf,':','LineWidth',2)

xlabel('Quarters')
ylabel('Sectoral inflation')

title('Sectoral Inflation Responses')

legend('Oil','Transport','Manufacturing')

grid on

%% ============================================================
%% SAVE FIGURES
%% ============================================================

figdir = [cd '/figures'];
mkdir(figdir)

saveas(gcf,fullfile(figdir,'oil_markup_sectoral_irf.png'))

%% ============================================================
%% SAVE IRF DATA
%% ============================================================

save('oil_markup_irfs',...
    'IRF_CPI_actual',...
    'IRF_CPI_mean',...
    'IRF_CPI_oilflex',...
    'IRF_oil',...
    'IRF_transport',...
    'IRF_manuf')

disp(' ')
disp('Oil markup shock exercise completed.')
disp(' ')