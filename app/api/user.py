from fastapi import APIRouter, Depends, HTTPException,status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.user import UserCreate,CoinChargeRequest,CoinChargeResponse
from app.crud.user import create_user
from app.services.user import charge_coin

user = APIRouter()

#코인지급
@user.post("/coin",response_class=CoinChargeResponse,status_code= status.HTTP_200_OK)
def charge_user_coin(data:CoinChargeRequest,db:Session = Depends(get_db)):
    result = charge_coin(db,data.user_id,data.coin)
    return {"success": True, "coin": result.coin}

    



