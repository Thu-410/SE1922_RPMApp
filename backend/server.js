const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json()); 

const tenantRoutes = require('./src/modules/tenants/tenant.route');
app.use('/api/tenants', tenantRoutes);

const conn = mysql.createConnection({
    host: "localhost",
    port: 3306, // port MySQL
    user: "root",
    password: "123456",
    database: "quan_ly_tro"
});

conn.connect((err)=>{
    if(err){
        console.log(err);
    }else{
        console.log("Ket noi MySQL thanh cong");
    }
});

app.get('/data',(req,res)=>{
    conn.query('SELECT * FROM users',(err,results)=>{
        if(err){
            res.status(500).json(err);
        }else{
            res.json({products: results});
        }
    });
});

app.listen(3000,()=>{
    console.log("Ung dung dang chay o cong 3000");
});