from pydantic import BaseModel,Field,model_validator
from typing import Optional, List
from datetime import datetime,timezone
from enum import Enum

#이벤트 등록하기
class EventCreate(BaseModel):
    user_id : str
    start_date : datetime
    end_date : datetime
    title : str
    description : str
    all_day : bool
    location : str

#이벤트 수정하기    
class EventUpdate(BaseModel):
    user_id : Optional[str] = None
    start_date : Optional[datetime] = None
    end_date : Optional[datetime] = None
    title : Optional[str] = None
    description : Optional[str] = None
    all_day : Optional[bool] = None
    location : Optional[str] = None
    
    @model_validator(mode = 'after')
    def at_least_one_field(self):
        targets = [
            'user_id',
            'start_date',
            'end_date',
            'title',
            'description',
            'all_day',
            'location',
        ]
        if all (getattr(self,f) is None for f in targets):
            raise ValueError('최소 1개 이상의 변경 필드를 제공해야 합니다')
        return self

#특정날짜 이벤트 조회하기
class Event    
class EventResponse(BaseModel):
    success : bool
    event_id : int
    