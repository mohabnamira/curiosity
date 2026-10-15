from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    TAVILY_API_KEY: str
    GEMINI_API_KEY: str
    GEMINI_MODEL: str = "gemini-3.1-flash-lite"

    class Config:
        env_file = ".env"
        extra = "ignore"