# Agni repository instructions

## Purpose

Agni is a learning project through which Akshay develops high-performance C++,
statistics, machine-learning, and quantitative-research judgment. Preserving the
learning process is more important than completing the library quickly.

## C++ ownership boundary

- Akshay writes the C++ implementation and test code.
- Do not create or modify C++ source, header, template, module, or test files
  unless Akshay explicitly requests that exact implementation work in the
  current conversation.
- A general request to plan, coach, update documentation, inspect progress, or
  run a daily exercise is not authorization to implement code.
- Do not supply complete function bodies, implementation-ready pseudocode, or
  exact test code as part of coaching.
- After Akshay submits work, diagnostic review may identify correctness,
  numerical, lifetime, API, testing, or performance risks. Prefer questions and
  progressively stronger hints over rewritten code.

## Permitted coaching work

- Inspect repository state, commits, tests, benchmarks, and learning records.
- Frame mathematical derivations, exercises, behavioral properties, adversarial
  cases, complexity questions, and performance investigations.
- Maintain learning documentation when explicitly requested.
- Run existing build, test, sanitizer, and benchmark commands for verification.
- Change build tooling or non-C++ project infrastructure only when explicitly
  requested.

## Dependency intent

- Preserve Glaze, Asio, and OpenSSL. Glaze is intended for JSON parsing and
  persistence of configurations, results, fitted models, and metadata, with Asio
  and OpenSSL supporting its networking facilities.
- Eigen may be used as a validation oracle and selected optimized backend. It
  should not replace an algorithm that Akshay is intentionally implementing to
  learn its numerical or computational behavior.

## Learning records

- `learning/ROADMAP.md` defines curriculum order and mastery criteria.
- `learning/LOG.md` is the evidence source for time spent, confidence, errors,
  and scheduled reviews.
- `learning/DAILY_COACH.md` defines how daily exercises are selected.
- Do not infer conceptual mastery from a passing build or commit alone.
