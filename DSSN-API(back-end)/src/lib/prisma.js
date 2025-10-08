import { PrismaClient } from '@prisma/client';

export const prisma =
  globalThis.prisma ??
  new PrismaClient({
    log:
      process.env.NODE_ENV !== 'production'
        ? ['query', 'warn', 'error']
        : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalThis.prisma = prisma;
