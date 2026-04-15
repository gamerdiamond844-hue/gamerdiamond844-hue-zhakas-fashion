from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.api_v1.api import api_router
from app.core.logging import setup_logging

app = FastAPI(
    title="ZHAKAS Fashion API",
    description="FastAPI backend for the ZHAKAS FASHION luxury e-commerce app",
    version="1.0.0",
)

setup_logging()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def root():
    return {"status": "ZHAKAS FASHION backend is running"}
