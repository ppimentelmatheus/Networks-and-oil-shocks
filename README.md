# Rubbo Cost-Push Markup Shock Extension

This project extends the Rubbo (2023) replication code to study oil-sector
desired-markup shocks, interpreted as cost-push shocks, and simple monetary-policy
responses.

The original prototype files are preserved:

- `parameters_markup.m`
- `oil_markup_shocks.m`

The new files add a cleaner modular layer for static pass-through, dynamic IRFs,
policy comparison, interest-rate implementation, and documentation.

## Main Question

What should a central bank do after an oil-sector cost-push shock?

The project answers this in stages:

1. How much does an oil markup shock move CPI inflation?
2. How much does it move Rubbo's divine-coincidence inflation index?
3. What output gap would stabilize CPI or DC inflation?
4. What nominal interest-rate movement, relative to the natural rate, implements
   those output-gap paths?
5. Which simple policy rule has the lowest quadratic loss?

## Core Scripts

### Static Markup Objects

`markup_costpush_static.m`

Computes:

- `CPI_markup`
- `DC_markup`
- `y_DC_stabilizing`
- `network_pressure`
- `sector_markup_pc`
- `lambda`, `b`, `V`, `kappaC`

This is the first-pass pass-through calculation.

### Dynamic Markup IRFs

`markup_costpush_irf.m`

Builds an AR(1) path for desired-markup shocks:

```matlab
mu_{t+1} = rho_mu * mu_t
```

and solves the sectoral Phillips curves backward over a finite horizon.

Implemented output-gap policies:

- `zero_gap`
- `stabilize_DC`
- `custom_y`

### Policy Comparison

`markup_costpush_policy_compare.m`

Compares five rules:

- `zero_gap`
- `stabilize_CPI`
- `stabilize_DC`
- `lean_CPI`
- `lean_DC`

It reports:

- peak absolute CPI response
- peak absolute DC response
- maximum absolute output gap
- CPI-objective loss
- DC-objective loss
- dual-objective loss

Losses are simple quadratic losses, not the full Rubbo welfare matrix.

### Interest-Rate Conversion

`markup_policy_rate_path.m`

Uses Rubbo's IS curve:

```text
y_t = E_t y_{t+1} - (1/gamma)(i_{t+1} - E_t pi^C_{t+1} - r^nat_{t+1})
```

to compute:

```text
i_{t+1} - r^nat_{t+1}
    = E_t pi^C_{t+1} + gamma(E_t y_{t+1} - y_t)
```

The output is the nominal policy-rate response relative to the natural rate.

## Main Drivers

### Oil Markup Module Example

`run_oil_markup_module_example.m`

Runs:

- baseline oil markup shock
- illustrative oil-sector subsidy
- CPI and DC dynamic responses
- network-pressure plots

Outputs are saved under:

```text
calibration/oil shocks/output/markup_module
```

### Monetary Policy Comparison

`oil_markup_monetary_policy.m`

Runs the full policy comparison:

- CPI responses
- DC responses
- output-gap paths
- quadratic losses
- policy-rate paths

Outputs are saved under:

```text
calibration/oil shocks/output/markup_policy
```

### Interest-Rate Policy Focus

`oil_markup_interest_rate_policy.m`

Focuses on the interest-rate implementation of each rule. It reports impact and
peak interest-rate responses in quarterly and annualized percentage points.

Outputs are saved under:

```text
calibration/oil shocks/output/markup_policy
```

## Paths

The drivers follow Rubbo-style folder conventions and can be run from:

- the project root containing `ecta200578-sup-0002-dataandprograms`
- `ecta200578-sup-0002-dataandprograms/calibration/oil shocks`
- `ecta200578-sup-0002-dataandprograms/calibration/data cleaning/IO tables`

The scripts load:

```matlab
IO_path = fullfile(IO_dir, 'clean data', '2012_clean');
delta_path = fullfile(IO_dir, 'clean data', 'delta_long');
```

and then reconstruct Rubbo's 406-dimensional economy with:

```matlab
Delta = diag(delta_q);
[alpha, beta, Omega, Delta, lambda, b, v, kappa, u, kappa_w] = ...
    parameters(alpha, beta, Omega, Delta, gamma, phi);
```

## Baseline Shock

The current baseline is:

```matlab
oil_sector = 15;
mu0 = 0.10;
rho_mu = 0.80;
```

This means a 10 percent desired-markup shock in the oil sector with AR(1)
persistence.

## Main Interpretation

For the U.S. calibration, an oil markup shock moves divine-coincidence inflation
much more than CPI inflation because oil is important along production chains.

Stabilizing CPI requires a larger output-gap contraction and can generate a large
negative movement in DC inflation. Stabilizing DC requires a smaller output-gap
contraction and still reduces CPI meaningfully.

The interest-rate scripts translate these output-gap paths into nominal rate changes
relative to the natural rate using the IS curve.

## Documentation

`markup_costpush_supplement.tex`

Documents:

- baseline primitives
- productivity-shock term
- desired-markup cost-push shocks
- sectoral Phillips curves
- dynamic IRF recursion
- policy rules
- quadratic losses
- interest-rate implementation
- code procedures

## Next Extensions

Natural next steps:

1. Add a full Taylor-rule block with CPI vs DC targeting.
2. Connect markup shocks to Rubbo's welfare matrix.
3. Rank sectoral subsidies by CPI reduction, DC reduction, and fiscal cost.
4. Port the calibrated objects to Brazilian input-output data.
