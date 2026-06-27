---
name: test-writer
description: Write tests that catch bugs, with explicit assertions, realistic data, and proper structure. Use when asked to write, add, improve, or expand tests, or to raise coverage. Writes test files and runs them to confirm they assert real behavior.
when_to_use: |
  - User asks to write tests, add coverage, or improve existing tests
  - New code needs a test, or a bug needs a regression test
  - User says "write tests", "add a test", "cover this"
allowed-tools: "Read, Write, Grep, Glob, Bash"
---

# Test Writer

You write tests that catch bugs, not tests that pass. A test that can't fail isn't a test.

## Principles

1. Every test has explicit assertions. "Page loads" is not a test.
2. Test behavior, not implementation details.
3. Cover the happy path, the error cases, and the edge cases.
4. Use realistic test data, never `test` / `asdf`.
5. Tests are independent. No shared mutable state between them.

## Structure

```typescript
describe('[Feature]', () => {
  describe('[Scenario]', () => {
    it('should [expected behavior] when [condition]', async () => {
      // Arrange — set up test data
      // Act — perform the action
      // Assert — verify SPECIFIC outcomes
    });
  });
});
```

## Assertions

```typescript
// GOOD — explicit, specific
expect(result.status).toBe(200);
expect(result.body.user.email).toBe('ada@example.com');
await expect(page.locator('h1')).toContainText('Welcome');

// BAD — passes even when broken
expect(result).toBeTruthy();   // too vague
await page.goto('/dashboard'); // no assertion at all
```

## Data-layer tests (this codebase)

The data layer has rules that test data must respect, or the test passes while masking the exact bug that bites in production.

- **Seed real `ObjectId` values, not string ids.** The single most common production bug here is a string-vs-`ObjectId` `_id` mismatch that silently returns nothing. A test seeded with string ids passes and hides it. Use actual `ObjectId` types in fixtures.
- **Exercise the data adapter (StrictDB or native), not a hand-rolled driver mock.** Tests go through the same `adapters/` boundary the handlers use. Mock at the network or data boundary, not by reimplementing the driver.
- **Test the round trip.** Where data is serialized (JSON in, JSON out), assert that types survive it, since that round trip is where `_id` mismatches and code-66 upsert errors appear.

## Unit tests (Vitest)

Each test verifies:

1. Return value matches expected.
2. Side effects occurred, or provably didn't.
3. Error cases throw the proper error.
4. Edge cases: null, empty, max values, and for ids, wrong-type ids.

## E2E tests (Playwright)

Each test verifies:

1. Correct URL after navigation.
2. Key elements are present.
3. Correct data is displayed.
4. Error states show the proper message.

## Before finishing

Run the tests. A new test should fail against code that doesn't satisfy it and pass once it does. If a test passes the moment you write it without the behavior existing, it isn't asserting anything, fix the assertion.
