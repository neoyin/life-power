@echo off

cd life-power-api

echo Starting LifePower API server...
echo Server will run at http://localhost:8000
echo Press Ctrl+C to stop the server

python -m uvicorn app.main:app --reload
