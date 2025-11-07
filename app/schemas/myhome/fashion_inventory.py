from pydantic import BaseModel,Field,model_validator
from typing import Optional,List
from datetime import datetime,timezone
from app.schemas.myhome.fashion import FashionBase

class FashionInInventory(FashionBase):
    is_equipped: bool = False
    acquired_at: datetime
    equipped_at: datetime

class FashionInventoryBase(BaseModel):
    id : str
    user_id: str
    fashions : List[FashionInInventory]
    
#회원가입하여서 user생성시 invetory도 같이 생성되게함
class FashionInventoryCreate(FashionInventoryBase):
    fashions : List[FashionInInventory] = Field(default_factory=list)
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    
class FashionInventoryUpdate(BaseModel):
    # 전체 의상목록으로 교체
    fashions: Optional[List[FashionInInventory]] = None
    # 의상 추가및 삭제
    add_fashions: Optional[List[FashionInInventory]] = None
    remove_fashions_id : Optional[List[str]] = None
    
    @model_validator(mode = 'after')
    def at_least_one_field(self):
        targets = [
            'fashions',
            'add_fashions',
            'remove_fashion',
        ]
        if all (getattr(self,f) is None for f in targets):
            raise ValueError('최소 1개 이상의 변경 필드를 제공해야 합니다')
        return self

class FashionInventoryDb(FashionInventoryBase):
    created_at : datetime
    updated_at: datetime
    model_config = {"from_attributes" : True}
            
class FashionInventoryResponse(FashionInventoryBase):
    created_at : datetime 
    updated_at : datetime 
    model_config = {"from_attributes" : True}
    
