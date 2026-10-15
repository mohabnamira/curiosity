from typing import Literal
from pydantic import BaseModel, Field

class ChatBody(BaseModel):
    type: Literal["chat"]
    id: str
    query: str = Field(min_length=1)
    history: list[dict] = []
    focus: str = "all"