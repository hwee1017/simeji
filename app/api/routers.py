from fastapi import APIRouter
from app.api.user import user

api_router = APIRouter()

api_router.include_router(user.router, prefix = "/user", tags = ["user"])
