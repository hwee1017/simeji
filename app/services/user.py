from app.crud.user import get_user_by_userid
from app.core.security import verify_password, create_access_token
from fastapi import HTTPException, status
from app.core.security import get_password_hash
from app.api.user import create_user
from app.crud.user import update_user_coin

#유저 회원가입
def user_register(db, user_id: str,password: str):
    existing_user = get_user_by_userid(db,user_id)
    if existing_user:
        raise HTTPException(
            status_code= status.HTTP_400_BAD_REQUEST,
            detail="유저ID가 이미 존재합니다."
        )
    
    hashed_pw = get_password_hash(password)
    new_user = create_user(db,user_id,hashed_pw)
    return {
        "msg" : "회원가입에 성공하였습니다.",
        "user_id" : new_user.id
    }    

#유저 로그인
def user_login(db, user_id: str, password: str):
    user = get_user_by_userid(db,user_id)
    if not user or not verify_password(password,user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    token = create_access_token({"sub": user.id})
    return {"access_token" : token, "token_type": "bearer"}

#코인 추가
def charge_coin(db,user_id, amount: int):
    user = get_user_by_userid(db,user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "USER_NOT_FOUND",
                "message": "존재하지 않는 유저입니다."
            }
        )
    new_coin = user.coin + amount
    updated_user = update_user_coin(db, user_id, new_coin)
    return updated_user
    
#상점에서 상품구매