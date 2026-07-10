require('dotenv').config();

const app = require('./src/app');
const { connectDB, closeDB } = require('./src/config/db');

const port = Number(process.env.PORT || 3000);
let server;

const startServer = async () => {
  try {
    await connectDB();
    server = app.listen(port, () => {
      console.log(`Server is running at http://localhost:${port}`);
    });
  } catch (error) {
    console.error('Unable to start server:', error.message);
    process.exitCode = 1;
  }
};

const shutdown = (signal) => {
  console.log(`${signal} received. Shutting down...`);

  if (!server) {
    closeDB().finally(() => process.exit(0));
    return;
  }

  server.close(() => {
    closeDB()
      .then(() => process.exit(0))
      .catch((error) => {
        console.error('Error while closing database pool:', error.message);
        process.exit(1);
      });
  });
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

startServer();
