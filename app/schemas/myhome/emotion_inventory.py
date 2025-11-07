from pydantic import BaseModel,Field,model_validator
from typing import Optional,List
from datetime import datetime,timezone
from app.schemas.myhome.emotion import EmotionBase

class EmotionInventoryBase(BaseModel):
    id : str
    user_id: str
    emotions : List[EmotionBase]
    

#회원가입하여서 user생성시 invetory도 같이 생성되게함
class EmotionInventoryCreate(EmotionInventoryBase):
    emotions : List[EmotionBase] = Field(default_factory=list)
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    
class EmotionInventoryUpdate(BaseModel):
    # 전체 가구목록으로 교체
    emotions: Optional[List[EmotionBase]] = None
    # 가구 추가및 삭제
    add_emotions: Optional[List[EmotionBase]] = None
    remove_emotions : Optional[List[str]] = None
    
    @model_validator(mode = 'after')
    def at_least_one_field(self):
        targets = [
            'emotions',
            'add_emotions',
            'remove_emotions',
        ]
        if all (getattr(self,f) is None for f in targets):
            raise ValueError('최소 1개 이상의 변경 필드를 제공해야 합니다')
        return self

class EmotionInventoryDb(EmotionInventoryBase):
    created_at : datetime
    updated_at: datetime
    model_config = {"from_attributes" : True}
            
class EmotionInventoryResponse(EmotionInventoryBase):
    created_at : datetime 
    updated_at : datetime 
    model_config = {"from_attributes" : True}
    
