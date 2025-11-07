from sqlalchemy import mapped_column, Integer, String,Interval,Time,DateTime,Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.session import Base
from datetime import time,datetime,date,timedelta

class User(Base):
    __tablename__ = "user"
    
    #유저가 회원가입시 입력한 id
    id = mapped_column(String,primary_key = True, index = True, nullable = False)
    name = mapped_column(String(10), nullable= False)
    password = mapped_column(String, nullable = False)
    role = mapped_column(String , default='user',nullable = False)
    coin = mapped_column(Integer, default=0, nullable = False)
    #시간 설정
    study_time  = mapped_column(Interval,default=timedelta(minutes=25), nullable = False)
    break_time  = mapped_column(Interval,default=timedelta(minutes=5), nullable = False)
    standard_time =  mapped_column(Time,default=time(5, 0, 0), nullable = False)
    timetable =  mapped_column(Boolean, default=True,nullable = False)
    correction_time =  mapped_column(Interval, default=timedelta(hours=4),nullable = False)
    #생성시간
    created_at =  mapped_column(DateTime, server_default=func.now(), nullable = False)
    updated_at =  mapped_column(DateTime, server_default=func.now(), onupdate=func.now(),nullable = False)
    
    #relationship
    fashion_inventroy = relationship("FashionInventory",back_populates='user',uselist=False,cascade="all, delete-orphan")
    charcters = relationship("Character",back_populates='user',cascade="all, delete-orphan")
    events = relationship("Event", back_populates="user", cascade="all, delete-orphan")