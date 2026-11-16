import { Pool } from 'pg';
const globalDb = globalThis as unknown as { pool?: Pool };
export const pool = globalDb.pool ?? new Pool({connectionString:process.env.DATABASE_URL ?? 'postgresql://postgres@127.0.0.1:55443/gymfinder_almaty',max:8});
globalDb.pool=pool;
