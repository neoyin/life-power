from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional


class ChargeResponse(BaseModel):
    message: str
    current_energy: int
    daily_charges: int
    remaining_charges: int


class DayChargeSummary(BaseModel):
    date: str
    breathing_count: int
    manual_count: int
    total_charges: int
    has_activity: bool


class ChargeHistoryResponse(BaseModel):
    days: int
    total_breathing: int
    total_manual: int
    total_charges: int
    streak_days: int
    daily_summaries: List[DayChargeSummary]
