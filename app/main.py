from fastapi import FastAPI,Request
from app.api.routers import api_router
from fastapi.responses import JSONResponse
from fastapi.exceptions import HTTPException
from app.database.session import DATABASE_URL
from dotenv import load_dotenv

load_dotenv()
from app.database.__init__ import init_db 
import os


app = FastAPI()

#오류 JSON 자동완성
@app.exception_handler(HTTPException)
async def http_expection_handler(request: Request, exc: HTTPException):
    if isinstance(exc.detail,dict):
        error_detail = exc.detail
    else:
        error_detail - {
            "code" : "INTERNAL_ERROR",
            "message" : str(exc.detail)
        }
    
    return JSONResponse(
        status_code= exc.status_code,
        content={
            "success" : False,
            "error" : error_detail
        }
    )

#이외의 오류 자동완성
@app.exception_handler(Exception)
async def internal_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "서버 내 오류."
            }
        }
    )

#router 등록
app.include_router(api_router, prefix = "/api")

#앱 시작시 Database 초기화
@app.on_event("startup")
async def startup_event():
    init_db()
    print("데이터베이스가 성공적으로 초기화되었습니다.")

DATABASE = os.getenv()



  

