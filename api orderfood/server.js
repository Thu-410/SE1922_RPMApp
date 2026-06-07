const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();

app.use(cors());

const conn = mysql.createConnection({
    host: "localhost",
    port: 3306, // port MySQL
    user: "root",
    password: "123456",
    database: "OrderFood"
});

conn.connect((err)=>{
    if(err){
        console.log(err);
    }else{
        console.log("Ket noi MySQL thanh cong");
    }
});

app.get('/data',(req,res)=>{
    conn.query('SELECT * FROM mytable',(err,results)=>{
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