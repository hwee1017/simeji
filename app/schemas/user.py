from pydantic import BaseModel,Field,SecretStr,ConfigDict,field_validator,model_validator
from typing import Optional
from datetime import date,time,timedelta,datetime,timezone
from enum import Enum
from app.schemas.myhome.fashion_inventory import FashionInventoryCreate
from app.schemas.myhome.furniture_inventory import FurnitureInventoryCreate
from app.schemas.myhome.emotion_inventory import EmotionInventoryCreate
#사용자 역할
class UserRole(str,Enum):
    User = "user"
    Admin = "admin"

class UserBase(BaseModel):
    user_name: str = Field(min_length=2 , max_length=10, description= "유저 이름")
    id: str = Field(min_length=4 , max_length=10, description= "유저 아이디")
    coin : int
    role : UserRole
    character_count : int

#사용자 생성
class UserCreate(UserBase):
    password : SecretStr = Field(min_length=8, max_length=20, description="비밀번호")
    coin : int = Field(0, ge = 0)
    role: UserRole = UserRole.User
    #inventory 설정
    character_count : int = 1
    fashion_inventory : FashionInventoryCreate
    furniture_inventory : FurnitureInventoryCreate
    emotion_inventory : EmotionInventoryCreate
    #시간설정
    study_time : timedelta = timedelta(minutes=25)
    break_time : timedelta = timedelta(minutes=5)
    standard_time: time = time(5,0,0)
    timetable : bool = True
    correction_time : timedelta = timedelta(hours=4)
    #생성시간
    created_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at : datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v: SecretStr) -> SecretStr:
        raw = v.get_secret_value()
        if not any(c.isalpha() for c in raw):
            raise ValueError('비밀번호는 최소 1개의 영문자를 포함해야 합니다')
        if not any(c.isdigit() for c in raw):
            raise ValueError('비밀번호는 최소 1개의 숫자를 포함해야 합니다')
        if not any(c in '!@#$%^&*(),.?":{}|<>' for c in raw):
            raise ValueError('비밀번호는 최소 1개의 특수문자를 포함해야 합니다')
        return v

#사용자 로그인
class UserLogin(BaseModel):
    id : str
    password: str
    
#사용자 변경
class UserUpdate(BaseModel):
    user_name:Optional[str] = Field(None, min_length = 2, max_length = 10)
    coin : Optional[int] = Field(None, ge=0)
    role: Optional[UserRole] = None
    #설정변경
    character_count : Optional[int] = None
    #시간
    study_time : Optional[timedelta] = None
    break_time : Optional[timedelta] = None
    standard_time: Optional[time] = None
    timetable : Optional[bool] = None
    correction_time : Optional[timedelta] = None
    password : Optional[SecretStr] = Field(default=None,min_length=8, max_length=20, description="비밀번호")
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v: Optional[SecretStr]) -> Optional[SecretStr]:
        if v is None: return v
        raw = v.get_secret_value()
        if not any(c.isalpha() for c in raw):
            raise ValueError('비밀번호는 최소 1개의 영문자를 포함해야 합니다')
        if not any(c.isdigit() for c in raw):
            raise ValueError('비밀번호는 최소 1개의 숫자를 포함해야 합니다')
        if not any(c in '!@#$%^&*(),.?":{}|<>' for c in raw):
            raise ValueError('비밀번호는 최소 1개의 특수문자를 포함해야 합니다')
        return v
    
    #변경사항이 없을경우
    @model_validator(mode = 'after')
    def at_least_one_field(self):
        targets = [
            'charcter_count'
            'user_name',
            'coin',
            'role',
            'study_time',
            'break_time',
            'standard_time',
            'timetable',
            'correction_time',
            'password',
        ]
        if all (getattr(self,f) is None for f in targets):
            raise ValueError('최소 1개 이상의 변경 필드를 제공해야 합니다')
        return self
    
#사용자 Db로 가는값
class UserDb(UserBase):
    password: str #해쉬화
    role: UserRole
    character_count : int
    study_time : timedelta 
    break_time : timedelta
    standard_time: time 
    timetable : bool
    correction_time : timedelta
    created_at : datetime 
    updated_at : datetime 

    model_config = {"from_attributes" : True}

#사용자 응답    
class UserResponse(UserBase):
    coin : int
    role : UserRole
    character_count : int
    study_time : timedelta
    break_time : timedelta
    standard_time : time
    timetable: bool
    correction_time : timedelta
    created_at : datetime 
    updated_at : datetime 
    model_config = {"from_attributes" : True}
    
#코인 요청
class CoinChargeRequest(BaseModel):
    user_id : str
    coin : int

#코인 응답
class CoinChargeResponse(BaseModel):
    success: bool
    coin: int