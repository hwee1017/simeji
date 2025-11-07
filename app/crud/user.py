from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserCreate, UserLogin,UserUpdate
from fastapi import HTTPException, status

#유저생성
def create_user(db: Session, user_in: UserCreate)-> User:
    db_user = User(
        user_id = user_in.id,
        hashed_password = user_in.password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

#유저조회 
def get_user_by_id(db: Session, user_id: str) -> User:
    user = db.qurey(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with id {user_id} not found"
        )
    return user

#전체유저조회
def get_users(db: Session, skip: int=0)->list[User]:
    return db.query(User).offset(skip).all()

#유저업데이트 (id를 이용)
def update_user(db: Session, user_id: str, user_in: UserUpdate) -> User:
    user = db.qurey(User).filter(User.id == user_id).first()
    if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with id {user_id} not found"
        )
    db.commit()
    db.refresh(user)
    return user
           
#유저삭제    
def delete_user(db:Session, user_id: str) -> None:
    user = db.qurey(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with id {user_id} not found"
        )
    db.delete(user)
    db.commit()
    
#유저 코인 수정
def charge_coin(db,user_id, amount: int):
    user = get_user_by_id(db,user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "USER_NOT_FOUND",
                "message": "존재하지 않는 유저입니다."
            }
        )
    user.coin += amount
    db.commit()
    db.refresh(user)
    return user
