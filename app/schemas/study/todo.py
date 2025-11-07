from pydantic import BaseModel,Field
from typing import Optional, List
from datetime import datetime,timezone
from enum import Enum

class ToDoRole(str, Enum):
    Today = 'today'
    Week = 'week'
    Routine = 'routine'
    
class ToDoBase(BaseModel):
    content: str

class ToDoWeekBase(BaseModel):
    content: str
                    

#오늘 해야할일 리스트 생성
class DayToDoListCreate(BaseModel):
    user_id : str
    
#루틴 생성
class RoutineCreate(BaseModel):
    user_id: str
    session_id: str
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))      

#이번주 할일 생성
class WeekToDoCreate(BaseModel):
    user_id: str
    session_id: str
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))    

#이번주 할일 Db
class WeekToDoDb(BaseModel):
    user_id : str
    session_id : str
    list :List[ToDo] = Field(default_factory=list)
    created_at : datetime
    updated_at: datetime