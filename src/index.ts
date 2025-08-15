import express from "express";
import pg from "pg";

const app = express();

// Get client from pg library
const { Client } = pg;

// Initialize the client
const client = new Client({
  host: process.env.POSTGRES_HOST,
  port: process.env.POSTGRES_PORT ? parseInt(process.env.POSTGRES_PORT) : 5432,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB,
});

// Connect to the database
await client.connect();

// Let's create a new route to test our DB connection
app.get("/test", async (req, res) => {
  const result = await client.query("SELECT NOW()");
  res.send(result.rows[0]);
});

app.get("/", (req, res) => {
  res.send("Hello World!");
});

app.get("/health", (req, res) => {
  res.send("OK - Server is healthy");
});

app.listen(3000, () => {
  console.log("Server is running on port 3000");
});
export default app;
