import { defineConfig, env } from 'prisma/config';

// The migration connection is supplied by the operator or isolated test harness.
// Never fall back to a runtime login or an unrelated database.
export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: { path: 'prisma/migrations' },
  datasource: { url: env('DATABASE_URL') },
});
