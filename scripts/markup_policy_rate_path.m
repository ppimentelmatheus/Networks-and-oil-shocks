function rate = markup_policy_rate_path(irf, gamma, opts)
%MARKUP_POLICY_RATE_PATH Convert output-gap IRFs into interest-rate IRFs.
%
% Uses Rubbo's log-linear IS curve:
%   y_t = E_t y_{t+1} - (1/gamma)(i_{t+1}-E_t pi^C_{t+1}-r^nat_{t+1})
%
% Rearranged:
%   i_{t+1} - r^nat_{t+1}
%       = E_t pi^C_{t+1} + gamma(E_t y_{t+1} - y_t).
%
% The output is the nominal policy-rate response relative to the natural
% nominal rate. For markup shocks only, the productivity component of
% r^nat is unchanged in Rubbo's model.

if nargin < 3 || isempty(opts)
    opts = struct();
end

y = irf.y_path(:);
piC = irf.CPI_dynamic(:);
T = length(y);

terminal_y = get_opt(opts, 'terminal_y', 0);
terminal_piC = get_opt(opts, 'terminal_piC', 0);
exclude_terminal_peak = get_opt(opts, 'exclude_terminal_peak', true);

y_lead = [y(2:end); terminal_y];
piC_lead = [piC(2:end); terminal_piC];

rate_gap_q = piC_lead + gamma * (y_lead - y);

rate = struct();
rate.rate_gap_q = rate_gap_q;
rate.rate_gap_ann = 4 * rate_gap_q;
rate.rate_gap_q_pp = 100 * rate_gap_q;
rate.rate_gap_ann_pp = 400 * rate_gap_q;

if exclude_terminal_peak && T > 1
    peak_index = 1:(T-1);
else
    peak_index = 1:T;
end

rate.peak_abs_q_pp = max(abs(rate.rate_gap_q_pp(peak_index)));
rate.peak_abs_ann_pp = max(abs(rate.rate_gap_ann_pp(peak_index)));
rate.impact_q_pp = rate.rate_gap_q_pp(1);
rate.impact_ann_pp = rate.rate_gap_ann_pp(1);
rate.terminal_y = terminal_y;
rate.terminal_piC = terminal_piC;
rate.exclude_terminal_peak = exclude_terminal_peak;
rate.T = T;

end

function value = get_opt(opts, field, default)
if isstruct(opts) && isfield(opts, field) && ~isempty(opts.(field))
    value = opts.(field);
else
    value = default;
end
end
