from pydantic import BaseModel,Field,model_validator,HttpUrl
from typing import Optional
from datetime import datetime,timezone
from enum import Enum

#가구 배치 종류에 따라서 수정
class FurnitureCategory(int,Enum):
    One = 1

#가구 베이스 모델
class FurnitureBase(BaseModel):
    name: str
    furniture_type: FurnitureCategory
    id : str
    price: int
    image_url: HttpUrl
    
#가구 제작
class FurnitureCreate(FurnitureBase):
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    
#가구 수정
class FurnitureUpdate(BaseModel):
    name : Optional[str] = Field(min_length=2, max_length= 15)
    category: Optional[FurnitureCategory]
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

#가구 Db
class FurnitureDb(FurnitureBase):
    created_at : datetime
    updated_at : datetime 
    model_config = {"from_attributes" : True}

#의상 응답
class FashionResponse(FurnitureBase):
    created_at : datetime 
    updated_at : datetime 
    model_config = {"from_attributes" : True}