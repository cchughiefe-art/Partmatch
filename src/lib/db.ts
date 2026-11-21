import { neon } from "@neondatabase/serverless";
const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL;
export const db = connectionString ? neon(connectionString) : null;
export function databaseConfigured(): boolean { return Boolean(db); }
