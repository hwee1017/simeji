from pydantic import BaseModel,Field,model_validator,HttpUrl
from typing import Optional
from datetime import datetime,timezone
from enum import Enum

#의상 카테고리
class FashionCategory(str,Enum):
    Face = "face"
    Hair = "hair"
    Clothes = "clothes"

#의상 베이스모델
class FashionBase(BaseModel):
    name: str = Field(min_length= 1)
    category: FashionCategory
    id: str
    price: int
    image_url : HttpUrl

#의상 제작
class FashionCreate(FashionBase):
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    
#의상 수정
class FashionUpdate(BaseModel):
    name : Optional[str] = Field(min_length=2, max_length= 15)
    category: Optional[FashionCategory]
    price: Optional[int] = Field(default=None,ge = 0)
    image_url : Optional[HttpUrl]
    
    @model_validator(mode = 'after')
    def at_least_one_field(self):
        targets = [
            'name',
            'category',
            'price',
            'image_url',
        ]
        if all (getattr(self,f) is None for f in targets):
            raise ValueError('최소 1개 이상의 변경 필드를 제공해야 합니다')
        return self

#의상 Db
class FashionDb(FashionBase):
    created_at : datetime
    updated_at : datetime 
    model_config = {"from_attributes" : True}

#의상 응답
class FashionResponse(FashionBase):
    created_at : datetime 
    updated_at : datetime 
    model_config = {"from_attributes" : True}
        