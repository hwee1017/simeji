from pydantic import BaseModel,Field
from typing import Optional, List
from datetime import datetime,timezone
from enum import Enum

class MessageRole(str, Enum):
    User = 'user'
    Character = 'character'

#사용자가 대화를 시작하며 응답 기대   
class ChatCreate(BaseModel):
    user_id: str
    character_id : str
    content : str
    #없으면 새로운 세션 생성
    session_id: Optional[str] = None
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

#채팅방 생성
class SessionCreate(BaseModel):
    user_id: str
    character_id : str
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))    

#캐릭터의 채팅 생성 요청 
class MessageCreate(BaseModel):
    session_id : str
    content : str
    role :MessageRole = MessageRole.User
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

#대화방 상위정보 저장
class SessionResponse(BaseModel):
    session_id: str
    user_id : str
    character_id : str
    created_at : datetime
    updated_at : datetime
    
    model_config = {"from_attributes": True}

#캐릭터의 채팅 응답    
class MessageResponse(BaseModel):
    content : str
    role : MessageRole
    created_at : datetime 
    updated_at : datetime
    
    model_config = {"from_attributes": True}

#캐릭터 대화 요청에 대한 결과    
class ChatResponse(BaseModel):
    session_id : str
    content : str
    created_at : datetime 
    updated_at : datetime
    messages: Optional[List[MessageResponse]] = None
    
    model_config = {"from_attributes": True}
    
#채팅방 요약정보
class SessionBrief(BaseModel):
    session_id: str
    user_id : str
    character_id : str
    message_count : int
    last_message_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime   
    
    model_config = {"from_attributes": True}

#채팅방 상세정보
class SessionDetail(SessionBrief):
    messages: List[MessageResponse] = Field(default_factory=list)
    model_config = {"from_attributes": True}
    