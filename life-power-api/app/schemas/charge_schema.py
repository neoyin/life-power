from pydantic import BaseModel
from datetime import datetime


class ChargeResponse(BaseModel):
    message: str
    current_energy: int
    daily_charges: int
    remaining_charges: int
