const express = require('express');
const cors = require('cors');
require('dotenv').config();

const maintenanceRoutes = require('./src/modules/maintenance/maintenance.route');
const dashboardRoutes = require('./src/modules/dashboard/dashboard.route');
const reportRoutes = require('./src/modules/reports/report.route');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
    res.json({ message: 'quản lý trọ' });
});

app.use('/api/maintenance-requests', maintenanceRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/reports', reportRoutes);

app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Không tìm thấy API',
    });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});