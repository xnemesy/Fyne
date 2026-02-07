const { app } = require('./app');
const db = require('./utils/db');

const port = process.env.PORT || 8080;

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
  // Initialize Schema on startup
  db.initSchema().catch(console.error);
});
