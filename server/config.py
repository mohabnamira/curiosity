from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    TAVILY_API_KEY: str = ""
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-3.5-flash"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    ALLOWED_ORIGINS: str = "*"
    APP_TOKEN: str = ""

    class Config:
        env_file = ".env"
        extra = "ignore"
