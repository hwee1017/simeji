from sqlalchemy import mapped_column, Integer, String, Boolean, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database.session import Base

class EmotionInventory(Base):
    __tablename__ = "emotion_inventory"
    
    id = mapped_column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = mapped_column(String, ForeignKey("user.id", ondelete="CASCADE"), nullable=False, index=True)
    emotion_id = mapped_column(String, ForeignKey("emotion.id", ondelete="CASCADE"), nullable=False, index=True)
    
    acquired_at = mapped_column(DateTime, nullable=False, server_default=func.now())
    equipped_at = mapped_column(DateTime, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="emotion_inventories")
    emotion = relationship("emotion")
    
    # 한 유저가 같은 의상을 중복으로 가질 수 없음
    __table_args__ = (
        UniqueConstraint('user_id', 'emotion_id', name='uq_user_emotion'),
    )
    