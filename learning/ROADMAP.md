# Agni learning roadmap

## Objective

Build a useful C++23 statistics and machine-learning library while deliberately
practicing the skills expected of an experienced quantitative researcher:

- numerical and statistical reasoning;
- high-performance and memory-conscious C++;
- experimental design, validation, and reproducibility;
- time-series reasoning without look-ahead leakage;
- clear explanations of assumptions and failure modes.

The roadmap is dependency-driven rather than date-driven. A missed day does not
make a task overdue and does not cause later work to accumulate.

## Daily session

A standard session is approximately 75–90 minutes:

1. 10 minutes of active retrieval from topics due for review.
2. 15 minutes deriving the new method and its assumptions from memory.
3. 35–45 minutes implementing one bounded slice.
4. 15 minutes adding tests or investigating numerical edge cases.
5. 5 minutes updating `learning/LOG.md`.

On a constrained day, complete a 20–30 minute minimum slice: one derivation, one
test, one benchmark, or one small implementation milestone. Never compensate for
missed days by assigning several new exercises at once.

## Mastery gates

A feature is complete only when the evidence supports all of these gates:

1. **Derivation:** explain the mathematics, assumptions, and edge cases.
2. **Reference implementation:** implement a simple correct version without AI.
3. **Verification:** use examples, properties, adversarial inputs, and an
   independent oracle where appropriate.
4. **Performance reasoning:** state time and space complexity, identify
   allocations, and measure before optimizing.
5. **Recall:** revisit the concept after approximately 1, 3, 7, and 21 days.

Use Eigen, Python, R, or another mature library to validate behavior, not to copy
the implementation being learned.

## Phase 0 — Turn the scaffold into Agni

1. Rename template-facing project and target identities to Agni while preserving
   the working Glaze/Asio/OpenSSL demo.
2. Decide and create the library, example, test, and benchmark target boundaries.
3. Define conventions for namespaces, translation units, headers, ownership,
   errors, floating-point types, NaNs, empty inputs, and degrees of freedom.

Learning focus: translation units, linkage, ODR, dependency boundaries, build
modes, sanitizer behavior, and reliable benchmarks.

## Phase 1 — Stable descriptive statistics

Suggested implementation sequence:

1. Sum and mean.
2. Two-pass population and sample variance.
3. Welford online variance.
4. Naive, pairwise, and compensated summation.
5. Covariance and correlation.
6. Minimum, maximum, argmin, and argmax with an explicit NaN policy.
7. Median and quantiles using sorting and selection.
8. Weighted mean and variance with documented weight semantics.
9. Rolling mean and variance without per-window allocation.

Learning focus: floating-point cancellation, invariants, iterator/range design,
`std::span`, allocation behavior, complexity, and adversarial testing.

## Phase 2 — Probability and simulation

- Reproducible random-number interfaces and seed handling.
- Uniform transformations and Box–Muller normal generation.
- Empirical CDFs and histograms.
- Bootstrap estimates and confidence intervals.
- Permutation tests.
- Monte Carlo standard errors and convergence experiments.
- Random-walk and execution-oriented simulations.

Learning focus: distributional assumptions, reproducibility, estimator variance,
simulation diagnostics, and parallel random streams.

## Phase 3 — Linear algebra and regression

- Dot product, AXPY, and matrix-vector multiplication with Eigen comparisons.
- Simple and multivariate ordinary least squares.
- Normal equations and Cholesky decomposition.
- Householder QR and conditioning experiments.
- Ridge regression.
- Residual diagnostics and coefficient uncertainty.
- Heteroskedasticity-robust standard errors.

Learning focus: numerical conditioning, decompositions, cache access, vectorized
kernels, statistical inference, and choosing reliable solvers.

## Phase 4 — Time-series and quant primitives

- Timestamped-series invariants.
- Lags, differences, simple returns, and log returns.
- Rolling covariance and beta.
- EWMA volatility.
- Autocorrelation and autoregressive models.
- Exact and causal as-of joins.
- Walk-forward data splitting.
- Explicit tests for look-ahead leakage.

Learning focus: causality, data integrity, temporal indexing, rolling-state
algorithms, and execution-research workflows.

## Phase 5 — Machine learning and optimization

- Stateful fit/transform preprocessing.
- Logistic-regression loss and gradients.
- Gradient descent, line search, and Newton/IRLS methods.
- K-means clustering.
- Metrics, calibration, regularization, and time-series cross-validation.
- Finite-difference gradient checks.

Learning focus: objective functions, optimization diagnostics, leakage-resistant
evaluation, regularization, and model failure analysis.

Neural networks, boosted trees, and elaborate generic ML abstractions are
deliberately postponed until the statistical and numerical core is strong.

## Phase 6 — Performance and execution-research capstone

- Allocation measurement and preallocation.
- Array-of-structs versus struct-of-arrays experiments.
- Compiler vectorization reports and cache-aware reductions.
- Parallel Monte Carlo with reproducible per-thread random streams.
- Deterministic parallel reductions.
- Synthetic market and execution data.
- Rolling feature pipelines and market-impact regression.
- Walk-forward evaluation and parallel coefficient bootstrap.
- Reproducible correctness, methodology, and performance report.

The capstone should integrate the library into a small execution-research study,
not merely demonstrate disconnected utility functions.

## Initial 14-session sequence

| Session | Deliverable | Retrieval and learning focus |
| --- | --- | --- |
| 1 | Rename the template identity; preserve and isolate the JSON/HTTP demo; write the module map | Translation units, linkage, dependency boundaries |
| 2 | Add library, test, and benchmark targets with a smoke test | Static versus header-only design, ODR, linker behavior |
| 3 | Define range-statistics API and policies for empty inputs, NaNs, errors, and degrees of freedom | Ownership, lifetimes, `std::span`, contracts |
| 4 | Reference sum and mean | Reductions, overflow, complexity |
| 5 | Two-pass variance and standard deviation | Population versus sample variance, cancellation |
| 6 | Welford online variance | Online invariants and numerical behavior |
| 7 | Review, derive both variance methods from memory, add adversarial cases, run sanitizers | Retrieval and error diagnosis |
| 8 | Naive, pairwise, and compensated summation | Accuracy/performance tradeoffs |
| 9 | Covariance and correlation | Centering, scaling, statistical identities |
| 10 | Min/max/argmin/argmax with explicit NaN behavior | Iterator design and edge semantics |
| 11 | Median and quantiles using sorting and selection | Order statistics and complexity |
| 12 | Weighted mean and variance | Weight semantics and effective sample size |
| 13 | Rolling mean and variance without allocation per window | Stateful algorithms and downdate stability |
| 14 | Property tests, benchmark report, and one reimplementation from memory | Integrated mastery check |

Sessions may span several calendar days. The next session number advances only
when the current exercise has sufficient evidence in the log and repository.
