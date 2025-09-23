const express = require('express');
const sql = require('mssql');
const app = express();
const port = process.env.PORT || 8080;

function getConnectionString() {
  const cands = [
    process.env.DefaultConnection,
    process.env.SQLAZURECONNSTR_DefaultConnection,
    process.env.SQLCONNSTR_DefaultConnection,
    process.env.CUSTOMCONNSTR_DefaultConnection
  ];
  for (const c of cands) if (c && c.trim()) return c;
  return null;
}
const connStr = getConnectionString();
let poolPromise = null;
async function getPool() {
  if (!connStr) throw new Error('No SQL connection string available');
  if (!poolPromise) poolPromise = sql.connect(connStr);
  return poolPromise;
}

app.get('/', (req,res)=>res.type('text/plain').send(
`OK: Azure LZ Demo app is running.

Endpoints:
  /health
  /db/ping
  /db/init
  /db/messages
`));

app.get('/health', (req,res)=>res.json({status:'ok', time:new Date().toISOString()}));

app.get('/db/ping', async (req,res)=>{
  try{
    const pool = await getPool();
    const r = await pool.request().query('SELECT 1 AS ok');
    res.json({ok:r.recordset[0].ok===1});
  }catch(e){ res.status(500).json({error:e.message}); }
});

app.get('/db/init', async (req,res)=>{
  const create = `IF OBJECT_ID('dbo.Messages','U') IS NULL
  CREATE TABLE dbo.Messages (Id INT IDENTITY(1,1) PRIMARY KEY, Text NVARCHAR(200) NOT NULL, CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME());`;
  const insert = "INSERT INTO dbo.Messages (Text) VALUES (N'Hello from Azure App Service via Azure SQL')";
  try{
    const pool = await getPool();
    await pool.request().batch(create);
    await pool.request().query(insert);
    res.json({created:true});
  }catch(e){ res.status(500).json({error:e.message}); }
});

app.get('/db/messages', async (req,res)=>{
  try{
    const pool = await getPool();
    const r = await pool.request().query('SELECT TOP 50 Id, Text, CreatedAt FROM dbo.Messages ORDER BY Id DESC');
    res.json(r.recordset);
  }catch(e){ res.status(500).json({error:e.message}); }
});

app.listen(port, ()=>console.log(`Server on ${port}`));
