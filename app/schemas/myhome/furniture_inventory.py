from pydantic import BaseModel,Field,model_validator
from typing import Optional,List
from datetime import datetime,timezone
from app.schemas.myhome.furniture import FurnitureBase,FurnitureCategory

class FurnitureInInventory(FurnitureBase):
    is_equipped: bool = False
    acquired_at: datetime
    equipped_at: datetime

class FurnitureInventoryBase(BaseModel):
    id : str
    user_id: str
    furnitures : List[FurnitureBase]
    
#회원가입하여서 user생성시 invetory도 같이 생성되게함
class FurnitureInventoryCreate(FurnitureInventoryBase):
    furnitures : List[FurnitureInInventory] = Field(default_factory=list)
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    
class FurnitureInventoryUpdate(BaseModel):
    # 전체 가구목록으로 교체
    furnitures: Optional[List[FurnitureInInventory]] = None
    # 가구 추가및 삭제
    add_furnitures: Optional[List[FurnitureInInventory]] = None
    remove_furniture : Optional[List[str]] = None
    
    @model_validator(mode = 'after')
    def at_least_one_field(self):
        targets = [
            'Furnitures',
            'add_Furnitures',
            'remove_Furniture',
        ]
        if all (getattr(self,f) is None for f in targets):
            raise ValueError('최소 1개 이상의 변경 필드를 제공해야 합니다')
        return self

class FurnitureInventoryDb(FurnitureInventoryBase):
    created_at : datetime
    updated_at: datetime
    model_config = {"from_attributes" : True}
            
class FurnitureInventoryResponse(FurnitureInventoryBase):
    created_at : datetime 
    updated_at : datetime 
    model_config = {"from_attributes" : True}
    
#가구배치/미완성
class FurniturePut(BaseModel):
    furniture: FurnitureBase
    location: FurnitureCategory
