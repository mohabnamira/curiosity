from pydantic import BaseModel, Field

class ChatBody(BaseModel):
    id: str
    query: str
    history: list[dict] = Field(default_factory=list)
    focus: str = "all"