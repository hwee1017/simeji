from sqlalchemy import Column, Integer, String
from app.database.session import Base

class User(Base):
    __tablename__ = "user"
    
