from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, Date, Time, Boolean, ForeignKey,func,DateTime
from app.database.session import Base

#캘린더 일정
class Event(Base):
    __tablename__ = "event"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index = True, autoincrement=True)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("user.user_id", ondelete="CASCADE")nullable=False, index=True,)
    start_date: Mapped[Date] = mapped_column(Date, nullable=False)
    end_date: Mapped[Date] = mapped_column(Date, nullable=False)
    start_time: Mapped[Time] = mapped_column(Time, nullable=True)
    end_time: Mapped[Time] = mapped_column(Time, nullable=True)
    title: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str] = mapped_column(String(500), nullable=True)
    is_all_day: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    location: Mapped[str] = mapped_column(String(100), nullable=True)
    
    created_at: Mapped[DateTime] = mapped_column( DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[DateTime] = mapped_column( DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    #relaionship
    user = relationship("User", back_populates="event")