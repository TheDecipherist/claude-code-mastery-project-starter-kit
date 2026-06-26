---
name: schema-source-of-truth
description: One canonical Zod schema per entity, reused across the stack instead of redeclared at each layer. Use whenever defining or changing a data shape, a TypeScript type or interface for an entity, an API request/response validator, an Express body/query/params check, a frontend form validator, or a DB document shape. Catches the same-entity-defined-four-times drift. TypeScript-first, derive types and per-layer variants from one base instead of hand-writing parallel copies.
when_to_use: |
  - Defining or editing an entity's shape (a User, Order, etc.) in types, an API, a form, or the DB
  - Writing API request/response validation or Express middleware that checks req.body / query / params
  - Writing a frontend form validator, or a TypeScript interface/type for data that also lives on the backend
  - Any moment you're about to write a second definition of a shape that already exists somewhere
  - Do NOT use for one-off internal types with no cross-layer counterpart
---

# Schema as a Single Source of Truth

A data entity should be defined once, as a Zod schema, and everything else derived from it. The failure pattern to kill: declaring the same entity separately at each layer, a frontend `interface User`, a backend `interface User`, a hand-written API validator, and a manual Mongo `$jsonSchema`. Four shapes for one entity, kept in sync by hand, guaranteed to drift the first time a field is added or renamed.

## One schema per entity, derive the rest

Define the canonical schema once and generate every other representation from it:

- **TypeScript type:** `type User = z.infer<typeof UserSchema>`. Never hand-write an `interface` that parallels a schema, infer it so it can't fall out of sync.
- **API validation:** parse `req.body` / `req.query` / `req.params` through the schema in middleware. `safeParse` and return 400 on failure, no field-by-field `if` checks.
- **Frontend forms:** the same schema drives form validation (`zodResolver` with react-hook-form), so client and server reject the same inputs by the same rules.
- **Pre-write guard:** parse before writing to the DB. See the `mongodb-rules` skill for the Mongo-specific parse-before-write and `$jsonSchema` floor.
- **OpenAPI and `$jsonSchema`:** generate them from the schema (`zod-to-openapi`, `zod-to-json-schema`) rather than maintaining them by hand.

Zod is TypeScript-first with zero runtime dependencies, so this costs one small library and removes every duplicated definition.

## One base, many variants (they are not identical)

"Same schema everywhere" is the goal, but a create payload is not the stored document and a response is not the request, so don't pretend they're one object. Model it honestly: one base schema, with per-layer variants derived from it, sharing a single origin while differing where they genuinely must.

```typescript
const UserSchema = z.object({
  _id: z.string(),
  email: z.string().email(),
  name: z.string().min(1),
  createdAt: z.date(),
});

const CreateUser   = UserSchema.omit({ _id: true, createdAt: true }); // POST body
const UpdateUser   = CreateUser.partial();                            // PATCH body
const UserResponse = UserSchema.extend({ displayName: z.string() });  // adds computed field
type User = z.infer<typeof UserSchema>;
```

Derive variants with `.omit()`, `.partial()`, `.pick()`, `.extend()`. When the base gains a field, every variant inherits it automatically, which is the entire point. A hand-copied variant is just the drift problem at smaller scale.

## Make it physically shared

Single source of truth only holds if there is literally one file. Put entity schemas in a shared module both sides import, a `packages/schemas` workspace, or a shared `src/schemas/` reachable by frontend and backend. If each side keeps its own copy, they diverge no matter how disciplined the intent. The shared import is the enforcement, not the convention.
