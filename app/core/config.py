from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    #데이터베이스 설정
    DATABASE_URL: str = ""
    
    #JWT 설정
    SECRET_KEY = ""
    ALGORITHM = ""
    ACCESS_TOKEN_EXPIRE_MINUTES = None
    
    #앱 설정
    APP_NAME: str = ""
    DEBUG:bool = True
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()    
