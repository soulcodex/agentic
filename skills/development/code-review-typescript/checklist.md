# TypeScript Code Review Checklist

Extends the generic checklist. Apply every item to TypeScript-specific concerns.

## Type Safety

- [ ] No `any` type used — use `unknown` + type guards for genuinely unknown values
  *Ref: [TypeScript Handbook — unknown](https://www.typescriptlang.org/docs/handbook/2/functions.html#unknown); [noImplicitAny](https://www.typescriptlang.org/tsconfig#noImplicitAny)*
- [ ] `tsconfig.json` has `"strict": true` enabled
  *Ref: [TypeScript strict mode](https://www.typescriptlang.org/tsconfig#strict)*
- [ ] `noUncheckedIndexedAccess: true` enabled (array/object access returns `T | undefined`)
  *Ref: [TypeScript 4.1 release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-1.html)*
- [ ] Type assertions `as Foo` only at validated system boundaries (HTTP, file I/O, DB), not mid-logic
  *Ref: [TypeScript Handbook — Type Assertions](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions)*
- [ ] Discriminated unions used for state and error modeling (not string enums + any)
  *Ref: [TypeScript Handbook — Discriminated Unions](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#discriminated-unions)*
- [ ] `readonly` on all DTO/value-object fields that should not be mutated
  *Ref: [TypeScript readonly](https://www.typescriptlang.org/docs/handbook/2/objects.html#readonly-properties)*
- [ ] No primitive obsession: domain IDs use branded/nominal types, not raw `string`
  *Ref: [TypeScript Branding — Matt Pocock](https://www.totaltypescript.com/branded-types)*

## Module System

- [ ] No CommonJS `require()` or `module.exports` in TypeScript/ESM projects
  *Ref: [Node.js ESM docs](https://nodejs.org/api/esm.html); [TypeScript module resolution](https://www.typescriptlang.org/docs/handbook/module-resolution.html)*
- [ ] No barrel `index.ts` re-exporting everything — risk of circular deps and poor tree-shaking
  *Ref: [TypeScript module best practices](https://www.typescriptlang.org/docs/handbook/module-resolution.html)*
- [ ] Cross-directory imports use path aliases (tsconfig `paths`), not `../../..` traversal

## Async and Concurrency

- [ ] No floating Promises — every `async` call is awaited or explicitly fire-and-forget with error handling
  *Ref: [Node.js — unhandledRejection event](https://nodejs.org/api/process.html#event-unhandledrejection)*
- [ ] No CPU-heavy synchronous computation on the main thread in a Node.js server context
  *Ref: [Node.js Event Loop docs](https://nodejs.org/en/docs/guides/event-loop-timers-and-nexttick)*
- [ ] `Promise.all` not used where tasks share mutable state that can create races
- [ ] No `async` function inside `Array.forEach` — use `Promise.all(arr.map(async ...))` or `for...of`
  *Ref: [MDN — Array.prototype.forEach](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/forEach)*

## Money and Precision

- [ ] Financial/currency values not computed with native `number` floating-point arithmetic
  *Ref: [What Every Programmer Should Know About Floating-Point Arithmetic](https://floating-point-gui.de/)*
- [ ] `decimal.js` or integer minor-unit representation used for money/rates/fees/taxes
  *Ref: [decimal.js docs](https://mikemcl.github.io/decimal.js/)*
- [ ] Rounding happens only at explicit domain boundaries, never implicitly mid-calculation

## Domain Modeling

- [ ] Domain layer has zero imports from framework packages (Hono, Express, Next.js, NestJS)
- [ ] `toPrimitives()` / `fromSnapshot()` mappers used at all layer boundaries
- [ ] No default exports — named exports used for better refactoring support and tree-shaking
  *Ref: [TypeScript ESM named exports best practices](https://www.typescriptlang.org/docs/handbook/modules/theory.html)*

## Error Handling

- [ ] Expected domain errors modeled as values (Result type, discriminated union), not thrown exceptions
  *Ref: [TypeScript error handling patterns](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#union-types)*
- [ ] `isXxxError()` type guard helpers co-located with error type definitions
- [ ] No silent `catch` blocks swallowing errors without logging or re-throwing