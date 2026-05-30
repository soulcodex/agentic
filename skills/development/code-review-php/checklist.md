# PHP Code Review Checklist

Extends the generic checklist. Apply every item to PHP-specific concerns.

## Type System and Strict Mode

- [ ] Every file declares `declare(strict_types=1)` at the top
  *Ref: [PHP Manual — strict_types](https://www.php.net/manual/en/language.types.declarations.php#language.types.declarations.strict)*
- [ ] All properties, parameters, and return types are declared
  *Ref: [PHP Manual — Type declarations](https://www.php.net/manual/en/language.types.declarations.php)*
- [ ] `readonly` used for value objects and DTOs where mutation is never intended
  *Ref: [PHP 8.1 — Readonly properties](https://www.php.net/manual/en/language.oop5.properties.php#language.oop5.properties.readonly-properties)*
- [ ] Constructor property promotion used for concise, typed DTOs
  *Ref: [PHP 8.0 — Constructor promotion](https://www.php.net/manual/en/language.oop5.decon.php#language.oop5.decon.constructor.promotion)*
- [ ] Enums (PHP 8.1+) used instead of class constants for closed sets of values
  *Ref: [PHP 8.1 — Enumerations](https://www.php.net/manual/en/language.types.enumerations.php)*

## Static Analysis

- [ ] PHPStan runs at level 8 with no suppressed errors (no `@phpstan-ignore` without comment)
  *Ref: [PHPStan — Rule Levels](https://phpstan.org/user-guide/rule-levels); [Ignoring errors](https://phpstan.org/user-guide/ignoring-errors)*
- [ ] PHP-CS-Fixer passes with the project's configured ruleset
  *Ref: [PHP-CS-Fixer docs](https://cs.symfony.com/)*

## Error Handling

- [ ] No bare `catch (\Exception $e)` or `catch (\Throwable $e)` without re-throwing or structured logging
  *Ref: [PHP Manual — Exceptions](https://www.php.net/manual/en/language.exceptions.php)*
- [ ] Custom exception classes extend `\DomainException` or `\RuntimeException`, not generic `\Exception`
- [ ] No swallowed exceptions in finally blocks

## Domain Modeling

- [ ] No ORM entity (Doctrine `#[Entity]`, `#[Column]`) annotations inside domain classes
  *Ref: [Doctrine best practices — Entities and the repository pattern](https://www.doctrine-project.org/projects/doctrine-orm/en/latest/reference/best-practices.html)*
- [ ] No primitive obsession: domain IDs use typed value objects (e.g. `UserId`), not raw `string`/`int`
  *Ref: [Refactoring — Replace Primitive with Object, Martin Fowler](https://refactoring.com/catalog/replacePrimitiveWithObject.html)*
- [ ] No `static` methods in domain services — static methods cannot be mocked or overridden
  *Ref: [PHPUnit docs — Test doubles](https://phpunit.de/documentation.html)*
- [ ] Authorization checks NOT inside domain entities or aggregates (keep domain ignorant of permissions)
  *Ref: [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture/)*
- [ ] No direct `$_GET`/`$_POST`/`$_REQUEST`/`$_SERVER` access outside adapter/controller layer

## PSR Compliance

- [ ] PSR-12 coding style followed
  *Ref: [PSR-12 Extended Coding Style](https://www.php-fig.org/psr/psr-12/)*
- [ ] PSR-4 autoloading configured in `composer.json` with namespace mirroring directory structure
  *Ref: [PSR-4 Autoloader](https://www.php-fig.org/psr/psr-4/)*
- [ ] PSR-3 logger interface used (not vendor-specific logger type-hinted directly)
  *Ref: [PSR-3 Logger Interface](https://www.php-fig.org/psr/psr-3/)*