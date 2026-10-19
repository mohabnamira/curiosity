from typing import Literal
from pydantic import BaseModel, Field


class HistoryItem(BaseModel):
    question: str = Field(max_length=2000)
    answer: str = Field(max_length=20000)


class ChatBody(BaseModel):
    type: Literal["chat"]
    id: str
    query: str = Field(min_length=1, max_length=2000)
    history: list[HistoryItem] = Field(default_factory=list, max_length=10)
    focus: str = "all"
    max_results: int = Field(default=5, ge=1, le=10)