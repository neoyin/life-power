import json
from datetime import datetime, date
from typing import Any


def format_datetime(dt: datetime) -> str:
    """将 datetime 格式化为人类可读的字符串"""
    if dt is None:
        return "N/A"
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def format_date_only(dt: datetime) -> str:
    """仅格式化日期部分"""
    if dt is None:
        return "N/A"
    return dt.strftime("%Y-%m-%d")


def format_time_only(dt: datetime) -> str:
    """仅格式化时间部分"""
    if dt is None:
        return "N/A"
    return dt.strftime("%H:%M:%S")


def debug_datetime_list(datetimes: list, description: str = "") -> str:
    """格式化 datetime 列表为可读字符串"""
    if not datetimes:
        return f"{description} []" if description else "[]"

    formatted = [format_datetime(dt) for dt in datetimes]
    prefix = f"{description}: " if description else ""
    return f"{prefix}[{', '.join(formatted)}]"


def object_to_dict(obj: Any) -> dict:
    """将对象转换为字典，支持 Pydantic 模型、SQLAlchemy 模型和普通对象"""
    if obj is None:
        return None

    # 如果已经是字典
    if isinstance(obj, dict):
        return obj

    # datetime 对象
    if isinstance(obj, datetime):
        return format_datetime(obj)

    # 列表或元组
    if isinstance(obj, (list, tuple)):
        return [_format_value(item) for item in obj]

    # Pydantic 模型
    if hasattr(obj, 'model_dump'):
        return obj.model_dump()

    # SQLAlchemy 模型 - 通过检查是否有 __table__ 属性来判断
    if hasattr(obj, '__table__'):
        return {c.name: _format_value(getattr(obj, c.name)) for c in obj.__table__.columns}

    # 尝试转为字典
    if hasattr(obj, '__dict__'):
        return {k: _format_value(v) for k, v in obj.__dict__.items() if not k.startswith('_')}

    return str(obj)


def _format_value(value: Any) -> Any:
    """格式化单个值为 JSON 兼容格式"""
    if value is None:
        return None
    if isinstance(value, datetime):
        return format_datetime(value)
    if isinstance(value, date):
        return format_datetime(datetime(value.year, value.month, value.day))
    if isinstance(value, (list, tuple)):
        return [_format_value(v) for v in value]
    if isinstance(value, dict):
        return {k: _format_value(v) for k, v in value.items()}
    if hasattr(value, '__table__'):
        return object_to_dict(value)
    return value


def to_json(obj: Any, indent: int = 2) -> str:
    """将对象转换为格式化的 JSON 字符串"""
    return json.dumps(object_to_dict(obj), indent=indent, ensure_ascii=False)


def debug_log(message: str, obj: Any = None, prefix: str = "DEBUG") -> str:
    """生成调试日志字符串

    Args:
        message: 日志消息
        obj: 要输出的对象（可选）
        prefix: 日志前缀

    Returns:
        格式化的日志字符串
    """
    result = f"[{prefix}] {message}"
    if obj is not None:
        result += f"\n{to_json(obj)}"
    return result
