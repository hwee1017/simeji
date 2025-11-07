from sqlalchemy import mapped_column, Integer, String, Time,DateTime, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from datetime import time
from enum import Enum
from app.database.session import Base

class Emotion(Base):
    __tablename__ = "emotion"
    
    id = mapped_column(Integer, primary_key=True, index=True, autoincrement=True)
    name = mapped_column(String, nullable=False, unique=True)
    price = mapped_column(Integer, nullable=False, default=0)
    image_url = mapped_column(String(500), nullable=False)
    created_at =  mapped_column(DateTime, server_default=func.now(), nullable = False)
    updated_at =  mapped_column(DateTime, server_default=func.now(), onupdate=func.now(),nullable = False)
    
    # Relationship
    inventory = relationship("EmotionInventory", back_populates="emotion")
    