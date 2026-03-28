from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from datetime import datetime

from app.db.base import get_db
from app.core.security import get_current_user_id
from app.models.user import UserSettings

router = APIRouter()


@router.get("", response_model=dict)
async def get_settings(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get all settings for current user."""
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == user_id)
    )
    settings = result.scalar_one_or_none()

    if not settings:
        # Create default settings if they don't exist
        settings = UserSettings(
            user_id=user_id,
            default_risk_percent=1,
            max_risk_percent=5,
            auto_execute_signals=False,
            min_confidence_score=70,
            compounding_enabled=False,
            daily_target_percent=5,
            stop_after_daily_target=True,
            push_notifications_enabled=True,
            email_notifications_enabled=True,
            signal_notifications=True,
            trade_notifications=True,
            price_alerts=True,
            biometric_auth_enabled=False,
        )
        db.add(settings)
        await db.commit()
        await db.refresh(settings)

    return settings.to_dict()


@router.get("/trading", response_model=dict)
async def get_trading_settings(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get trading settings for current user."""
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == user_id)
    )
    settings = result.scalar_one_or_none()

    if not settings:
        # Return defaults
        return {
            "default_risk_percent": 1,
            "max_risk_percent": 5,
            "auto_execute_signals": False,
            "min_confidence_score": 70,
            "compounding_enabled": False,
            "daily_target_percent": 5,
            "stop_after_daily_target": True,
        }

    return {
        "default_risk_percent": settings.default_risk_percent,
        "max_risk_percent": settings.max_risk_percent,
        "auto_execute_signals": settings.auto_execute_signals,
        "min_confidence_score": settings.min_confidence_score,
        "compounding_enabled": settings.compounding_enabled,
        "daily_target_percent": settings.daily_target_percent,
        "stop_after_daily_target": settings.stop_after_daily_target,
    }


@router.put("/trading")
async def update_trading_settings(
    settings_data: dict,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Update trading settings for current user."""
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == user_id)
    )
    settings = result.scalar_one_or_none()

    if not settings:
        # Create new settings
        settings = UserSettings(
            user_id=user_id,
            default_risk_percent=settings_data.get("default_risk_percent", 1),
            max_risk_percent=settings_data.get("max_risk_percent", 5),
            auto_execute_signals=settings_data.get("auto_execute_signals", False),
            min_confidence_score=settings_data.get("min_confidence_score", 70),
            compounding_enabled=settings_data.get("compounding_enabled", False),
            daily_target_percent=settings_data.get("daily_target_percent", 5),
            stop_after_daily_target=settings_data.get("stop_after_daily_target", True),
        )
        db.add(settings)
    else:
        # Update existing settings
        if "default_risk_percent" in settings_data:
            settings.default_risk_percent = settings_data["default_risk_percent"]
        if "max_risk_percent" in settings_data:
            settings.max_risk_percent = settings_data["max_risk_percent"]
        if "auto_execute_signals" in settings_data:
            settings.auto_execute_signals = settings_data["auto_execute_signals"]
        if "min_confidence_score" in settings_data:
            settings.min_confidence_score = settings_data["min_confidence_score"]
        if "compounding_enabled" in settings_data:
            settings.compounding_enabled = settings_data["compounding_enabled"]
        if "daily_target_percent" in settings_data:
            settings.daily_target_percent = settings_data["daily_target_percent"]
        if "stop_after_daily_target" in settings_data:
            settings.stop_after_daily_target = settings_data["stop_after_daily_target"]

    settings.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(settings)

    return {
        "message": "Trading settings updated successfully",
        "settings": settings.to_dict()
    }


@router.get("/notifications", response_model=dict)
async def get_notification_settings(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get notification settings for current user."""
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == user_id)
    )
    settings = result.scalar_one_or_none()

    if not settings:
        # Return defaults
        return {
            "push_notifications_enabled": True,
            "email_notifications_enabled": True,
            "signal_notifications": True,
            "trade_notifications": True,
            "price_alerts": True,
        }

    return {
        "push_notifications_enabled": settings.push_notifications_enabled,
        "email_notifications_enabled": settings.email_notifications_enabled,
        "signal_notifications": settings.signal_notifications,
        "trade_notifications": settings.trade_notifications,
        "price_alerts": settings.price_alerts,
    }


@router.put("/notifications")
async def update_notification_settings(
    settings_data: dict,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Update notification settings for current user."""
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == user_id)
    )
    settings = result.scalar_one_or_none()

    if not settings:
        # Create new settings
        settings = UserSettings(
            user_id=user_id,
            push_notifications_enabled=settings_data.get("push_notifications_enabled", True),
            email_notifications_enabled=settings_data.get("email_notifications_enabled", True),
            signal_notifications=settings_data.get("signal_notifications", True),
            trade_notifications=settings_data.get("trade_notifications", True),
            price_alerts=settings_data.get("price_alerts", True),
        )
        db.add(settings)
    else:
        # Update existing settings
        if "push_notifications_enabled" in settings_data:
            settings.push_notifications_enabled = settings_data["push_notifications_enabled"]
        if "email_notifications_enabled" in settings_data:
            settings.email_notifications_enabled = settings_data["email_notifications_enabled"]
        if "signal_notifications" in settings_data:
            settings.signal_notifications = settings_data["signal_notifications"]
        if "trade_notifications" in settings_data:
            settings.trade_notifications = settings_data["trade_notifications"]
        if "price_alerts" in settings_data:
            settings.price_alerts = settings_data["price_alerts"]

    settings.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(settings)

    return {
        "message": "Notification settings updated successfully",
        "settings": settings.to_dict()
    }


@router.get("/security", response_model=dict)
async def get_security_settings(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get security settings for current user."""
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == user_id)
    )
    settings = result.scalar_one_or_none()

    if not settings:
        # Return defaults
        return {
            "biometric_auth_enabled": False,
        }

    return {
        "biometric_auth_enabled": settings.biometric_auth_enabled,
    }


@router.put("/security")
async def update_security_settings(
    settings_data: dict,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Update security settings for current user."""
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == user_id)
    )
    settings = result.scalar_one_or_none()

    if not settings:
        # Create new settings
        settings = UserSettings(
            user_id=user_id,
            biometric_auth_enabled=settings_data.get("biometric_auth_enabled", False),
        )
        db.add(settings)
    else:
        # Update existing settings
        if "biometric_auth_enabled" in settings_data:
            settings.biometric_auth_enabled = settings_data["biometric_auth_enabled"]

    settings.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(settings)

    return {
        "message": "Security settings updated successfully",
        "settings": settings.to_dict()
    }


@router.put("")
async def update_all_settings(
    settings_data: dict,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Update all settings for current user."""
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == user_id)
    )
    settings = result.scalar_one_or_none()

    if not settings:
        # Create new settings with all provided values
        settings = UserSettings(
            user_id=user_id,
            default_risk_percent=settings_data.get("default_risk_percent", 1),
            max_risk_percent=settings_data.get("max_risk_percent", 5),
            auto_execute_signals=settings_data.get("auto_execute_signals", False),
            min_confidence_score=settings_data.get("min_confidence_score", 70),
            compounding_enabled=settings_data.get("compounding_enabled", False),
            daily_target_percent=settings_data.get("daily_target_percent", 5),
            stop_after_daily_target=settings_data.get("stop_after_daily_target", True),
            push_notifications_enabled=settings_data.get("push_notifications_enabled", True),
            email_notifications_enabled=settings_data.get("email_notifications_enabled", True),
            signal_notifications=settings_data.get("signal_notifications", True),
            trade_notifications=settings_data.get("trade_notifications", True),
            price_alerts=settings_data.get("price_alerts", True),
            biometric_auth_enabled=settings_data.get("biometric_auth_enabled", False),
        )
        db.add(settings)
    else:
        # Update all settings
        settings.default_risk_percent = settings_data.get("default_risk_percent", settings.default_risk_percent)
        settings.max_risk_percent = settings_data.get("max_risk_percent", settings.max_risk_percent)
        settings.auto_execute_signals = settings_data.get("auto_execute_signals", settings.auto_execute_signals)
        settings.min_confidence_score = settings_data.get("min_confidence_score", settings.min_confidence_score)
        settings.compounding_enabled = settings_data.get("compounding_enabled", settings.compounding_enabled)
        settings.daily_target_percent = settings_data.get("daily_target_percent", settings.daily_target_percent)
        settings.stop_after_daily_target = settings_data.get("stop_after_daily_target", settings.stop_after_daily_target)
        settings.push_notifications_enabled = settings_data.get("push_notifications_enabled", settings.push_notifications_enabled)
        settings.email_notifications_enabled = settings_data.get("email_notifications_enabled", settings.email_notifications_enabled)
        settings.signal_notifications = settings_data.get("signal_notifications", settings.signal_notifications)
        settings.trade_notifications = settings_data.get("trade_notifications", settings.trade_notifications)
        settings.price_alerts = settings_data.get("price_alerts", settings.price_alerts)
        settings.biometric_auth_enabled = settings_data.get("biometric_auth_enabled", settings.biometric_auth_enabled)

    settings.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(settings)

    return {
        "message": "All settings updated successfully",
        "settings": settings.to_dict()
    }
