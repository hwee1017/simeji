from pydantic import BaseModel,HttpUrl,model_validator,Field
from typing import Optional
from datetime import datetime,timezone
from app.schemas.myhome.fashion import FashionBase

#기본캐릭터
class CharacterBase(BaseModel):
    name: Optional[str] = '옷장'
    id: int
    charcter_profile: HttpUrl
    charcter_hair : FashionBase
    charcter_face : FashionBase
    charcter_fashion : FashionBase
    
    
class CharacterCreate(CharacterBase):
    created_at: datetime
    #기본의상으로 나중에 수정하기
    charcter_profile: HttpUrl = None
    charcter_hair : FashionBase = None
    charcter_face : FashionBase = None
    charcter_fashion : FashionBase = None
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class CharacterResponse(CharacterBase):
    created_at : datetime
    updated_at : datetime
    model_config = {"from_attributes" : True}

#캐릭터 수정    
class CharcterUpdate(BaseModel):
    name: Optional[str] = None
    charcter_profile: Optional[HttpUrl] = None
    charcter_hair : Optional[FashionBase] = None
    charcter_face : Optional[FashionBase] = None
    charcter_fashion : Optional[FashionBase] = None
    
    @model_validator(mode = 'after')
    def at_least_one_field(self):
        targets = [
            'name',
            'charcter_profile',
            'charcter_hair',
            'charcter_face',
            'charcter_fashion',
        ]    
        if all (getattr(self,f) is None for f in targets):
            raise ValueError('최소 1개 이상의 변경 필드를 제공해야 합니다')
        self.latest = datetime.now(timezone.utc)
        return self
    
    created_at : datetime 
    updated_at : datetime 
    model_config = {"from_attributes" : True}

#캐릭터 DB    
class CharcterDb(CharacterBase):
    model_config = {"from_attributes" : True}
