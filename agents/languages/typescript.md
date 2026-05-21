## TypeScript

### Compiler Configuration

Always enable strict mode in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

### Type System

- Prefer `type` aliases over `interface` for union types and computed types.
  Use `interface` for object shapes that may be extended (especially public APIs).
- Never use `any`. Use `unknown` for genuinely unknown values and narrow with guards.
- Avoid type assertions (`as Foo`) except at system boundaries with validation.
- Use discriminated unions for modeling state:
  ```typescript
  type Result<T> = { ok: true; value: T } | { ok: false; error: Error }
  ```
- Prefer `readonly` for all data that should not be mutated.
- Use template literal types for string-constrained values: `type EventName = `${string}.${string}``

### Domain Modeling Conventions

- Model value objects with immutable types/classes plus runtime validation.
- Keep aggregate state private; mutate through intentful methods only.
- Keep domain types isolated from framework/transport concerns.
- Use explicit `toPrimitives` / `fromSnapshot` mapping at boundaries.
- Mapping code is acceptable when contexts have different semantics.

### Money and Precision Rules

- Mandatory: if the domain handles money/currency, taxes, fees, discounts, balances, rates,
  or any precision-sensitive quantity, do not use native `number` arithmetic.
- Mandatory: use `decimal.js` as the default decimal arithmetic library. If another decimal
  library is chosen, document the rationale and keep usage consistent across the codebase.
- Canonical money representation in domain and persistence is signed integer minor units
  (`amountMinor: -1234`, `currency: 'USD'`). Negative values are valid when the domain allows
  debts, refunds, credits, or reversals.
- Use decimal strings only at explicit interoperability boundaries (external APIs, CSV/import,
  UI formatting/parsing), then map to/from minor units.
- Introduce a domain value object (for example `Money`) that owns parsing, scale normalization,
  rounding mode, and serialization boundaries. Keep formatting/localization in adapters/UI.
- Keep decimal library types (for example `Decimal`) at infrastructure/application boundaries.
  Domain entities/value objects must not expose library-specific types in their public API.
- Currency policy source:
  - fixed-currency products: keep scale/rounding/symbol metadata in code.
  - dynamic/multi-tenant currency catalogs: resolve metadata through a port/adaptor and pass
    normalized policy data into domain operations.
- For complex financial/precision workloads (allocation engines, compound interest schedules,
  tax/regulatory rules, cross-currency settlement, or long chained calculations), delegate to a
  specialized precision port/service. Do not embed ad-hoc complex math in domain/application code
  where language/runtime numeric behavior can leak into business outcomes.
- For expected domain mismatches (for example currency mismatch), use one project-level convention
  consistently across the codebase (for example Result-union style or typed domain errors), and
  do not mix styles per module.
- Do not mix `number` and decimal instances in the same calculation chain.
- Do not round implicitly at arbitrary steps; round only at explicit domain boundaries.

```typescript
// Do: canonical domain representation uses signed minor units.
import Decimal from 'decimal.js'

// Use your project's standard expected-error contract consistently.
type DomainResult<T, E> = { ok: true; value: T } | { ok: false; error: E }
type Currency = 'USD' | 'JPY' | 'KWD'
type MoneyError = { type: 'CURRENCY_MISMATCH'; left: Currency; right: Currency }

type CurrencyPolicy = { scale: number; symbol: string }
const CURRENCY_POLICY: Record<Currency, CurrencyPolicy> = {
  USD: { scale: 2, symbol: 'USD' },
  JPY: { scale: 0, symbol: 'JPY' },
  KWD: { scale: 3, symbol: 'KWD' },
}

class Money {
  private constructor(
    readonly amountMinor: bigint,
    readonly currency: Currency,
    readonly policy: CurrencyPolicy,
  ) {}

  static fromMinor(amountMinor: bigint, currency: Currency): Money {
    return new Money(amountMinor, currency, CURRENCY_POLICY[currency])
  }

  add(other: Money): DomainResult<Money, MoneyError> {
    if (other.currency !== this.currency) {
      return {
        ok: false,
        error: { type: 'CURRENCY_MISMATCH', left: this.currency, right: other.currency },
      }
    }
    return { ok: true, value: Money.fromMinor(this.amountMinor + other.amountMinor, this.currency) }
  }

  toPrimitives(): { amountMinor: string; currency: Currency } {
    return { amountMinor: this.amountMinor.toString(), currency: this.currency }
  }
}

// Boundary mapper: decimal.js stays outside the domain type.
function moneyFromDecimalString(amount: string, currency: Currency): Money {
  const scale = CURRENCY_POLICY[currency].scale
  const minor = new Decimal(amount).mul(new Decimal(10).pow(scale)).toDecimalPlaces(0)
  return Money.fromMinor(BigInt(minor.toString()), currency)
}
```

```typescript
// Don't: floating-point money math
const subtotal = 19.99
const tax = 0.2
const total = subtotal + subtotal * tax // precision risk
```

### Naming Conventions

| Construct | Convention | Example |
|---|---|---|
| Variables, functions | camelCase | `getUserById` |
| Classes, interfaces, types | PascalCase | `UserRepository` |
| Enums | PascalCase (values: SCREAMING_SNAKE) | `Status.ACTIVE` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Files | kebab-case | `user-repository.ts` |
| Test files | `*.test.ts` or `*.spec.ts` | `user-repository.test.ts` |

### Module System

- Use ES module syntax everywhere in TS/JS (`import` / `export` only).
- Never introduce CommonJS syntax (`require`, `module.exports`, `exports.foo`) in TS/JS code.
- Use ESModules (`"module": "ESNext"` or `"NodeNext"`). Avoid CommonJS for new code.
- Avoid barrel files (`index.ts` re-exporting everything). They hurt tree-shaking and create
  circular dependency risks.
- Use absolute alias imports configured via `paths` in tsconfig for cross-directory references.
- Relative imports are only allowed for files in the same folder (`./foo`); avoid parent traversal
  (`../`, `../../..`) and other cross-directory relative imports.

### Error Handling

- Model expected errors as values, not exceptions:
  ```typescript
  // Return Result type for expected failures
  function parseAge(raw: string): Result<number> { ... }
  ```
- Reserve `throw` for truly exceptional/unexpected conditions (programming errors, I/O failures).
- Never `catch` an error and silently swallow it. At minimum, log it.
- Prefer custom domain/application error classes over generic `Error` for business failures.
- Use explicit type guards for error branching (for example `isOrderAlreadyPaidError(err)`), never
  `instanceof` chains spread across handlers.
- Co-locate `isXxxError()` helpers with the corresponding error type and reuse them across controllers,
  presenters, and tests.

### Boundary Validation and Webhooks

- Validate all external payloads (HTTP, webhook, queue) with schemas at the edge.
- Zod is a valid and recommended schema/validation option for TypeScript-first codebases.
- Keep schema versions explicit and synchronized with handler behavior.
- For webhooks, enforce signature verification, replay-window checks, and idempotency keys.
- Keep authorization checks in application handlers/services, not domain models.

### Code Style

- Use `pnpm` as the package manager.
- Format with Prettier (`.prettierrc` in repo root); lint with ESLint (flat config `eslint.config.ts`).
- Prefer `const` over `let`; never use `var`.
- Prefer named exports over default exports for better refactoring support.
- Keep functions small (fits on a screen). Extract when logic becomes layered.
- Prefer dependency injection/composition in the app layer; avoid global singletons.
- For HTTP adapters/middleware with infra dependencies (Redis, SDK clients, config), construct
  those dependencies in the composition root and inject handlers/factories — never instantiate
  infra clients inside controllers.
