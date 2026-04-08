from typing import Dict, Tuple, Optional
from app.models.energy import SignalFeatureDaily


def calculate_energy_score(signal: SignalFeatureDaily) -> Tuple[int, str, str, float]:
    """
    计算能量分数
    
    Args:
        signal: 信号特征数据
    
    Returns:
        Tuple[int, str, str, float]: (score, level, trend, confidence)
    """
    # 初始化分数
    score = 50
    
    # 权重配置
    weights = {
        "steps": 0.2,
        "sleep_hours": 0.3,
        "active_minutes": 0.15,
        "water_intake": 0.1,
        "mood_score": 0.2,
        "breathing": 0.05
    }
    
    # 计算各维度得分
    if signal.steps is not None:
        # 步数得分（目标：8000步）
        steps_score = min(signal.steps / 8000, 1.0) * 100
        score += steps_score * weights["steps"] - 10
    
    if signal.sleep_hours is not None:
        # 睡眠得分（目标：7-8小时）
        if 7 <= signal.sleep_hours <= 8:
            sleep_score = 100
        elif signal.sleep_hours < 7:
            sleep_score = max(0, 100 - (7 - signal.sleep_hours) * 20)
        else:
            sleep_score = max(0, 100 - (signal.sleep_hours - 8) * 10)
        score += sleep_score * weights["sleep_hours"] - 15
    
    if signal.active_minutes is not None:
        # 活动分钟数得分（目标：30分钟）
        active_score = min(signal.active_minutes / 30, 1.0) * 100
        score += active_score * weights["active_minutes"] - 7.5
    
    if signal.water_intake is not None:
        # 饮水量得分（目标：2000ml）
        water_score = min(signal.water_intake / 2000, 1.0) * 100
        score += water_score * weights["water_intake"] - 5
    
    if signal.mood_score is not None:
        # 情绪得分（1-10）
        mood_score = (signal.mood_score / 10) * 100
        score += mood_score * weights["mood_score"] - 10
        
    if signal.breathing_sessions is not None:
        # 呼吸训练得分 (目标：5次循环，每次+20点次元分)
        breathing_score = min(signal.breathing_sessions / 5, 1.0) * 100
        score += breathing_score * weights["breathing"]
    
    # 确保分数在0-100范围内
    score = max(0, min(100, score))
    
    # 确定等级
    if score >= 70:
        level = "high"
    elif score >= 40:
        level = "medium"
    else:
        level = "low"
    
    # 计算趋势（这里简化处理，实际应该与历史数据比较）
    trend = "stable"
    
    # 计算置信度（基于数据完整性）
    data_points = 0
    if signal.steps is not None: data_points += 1
    if signal.sleep_hours is not None: data_points += 1
    if signal.active_minutes is not None: data_points += 1
    if signal.water_intake is not None: data_points += 1
    if signal.mood_score is not None: data_points += 1
    if signal.breathing_sessions is not None: data_points += 1
    
    confidence = data_points / 6.0
    
    return int(score), level, trend, confidence
