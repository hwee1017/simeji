from datetime import datetime,timezone
from app.schemas.myhome.fashion_inventory import FashionInventoryDb,FashionInventoryUpdate
from app.schemas.myhome.furniture_inventory import FurnitureInventoryDb,FurnitureInventoryUpdate
from app.schemas.myhome.emotion_inventory import EmotionInventoryDb,EmotionInventoryUpdate

#fashion_inventory update
def fashion_inventory_update(original: FashionInventoryDb, patch: FashionInventoryUpdate) -> FashionInventoryDb:
    updated = original.model_copy(deep=True)

    # 전체 교체
    if patch.fashions is not None:
        updated.fashions = patch.fashions
    # 추가
    if patch.add_fashions:
        updated.fashions.extend(patch.add_fashions)

    # 제거 (fashion_id 기준)
    if patch.remove_fashions_id:
        remove_set = set(patch.remove_fashions_id)
        updated.fashions = [
            f for f in updated.fashions
            if getattr(f, "fashion_id", None) not in remove_set
        ]

    updated.updated_at = datetime.now(timezone.utc)
    return updated

#furniture_inventory update
def furniture_inventory_update(original: FurnitureInventoryDb, patch: FurnitureInventoryUpdate) -> FurnitureInventoryDb:
    updated = original.model_copy(deep=True)

    # 전체 교체
    if patch.furnitures is not None:
        updated.furnitures = patch.furnitures

    # 추가
    if patch.add_furnitures:
        updated.furnitures.extend(patch.add_furnitures)

    # 제거 (fashion_id 기준)
    if patch.remove_furnitures_id:
        remove_set = set(patch.remove_furnitures_id)
        updated.furnitures= [
            f for f in updated.furnitures
            if getattr(f, "furniture_id", None) not in remove_set
        ]

    updated.updated_at = datetime.now(timezone.utc)
    return updated

#emotion_inventory_update
def emotion_inventory_update(original: EmotionInventoryDb, patch: EmotionInventoryUpdate) -> EmotionInventoryDb:
    updated = original.model_copy(deep=True)

    # 전체 교체
    if patch.emotions is not None:
        updated.emotions = patch.emotions

    # 추가
    if patch.add_emotions:
        updated.emotions.extend(patch.add_emotions)

    # 제거 (fashion_id 기준)
    if patch.remove_emotions_id:
        remove_set = set(patch.remove_emotions_id)
        updated.emotions= [
            f for f in updated.emotions
            if getattr(f, "emotion_id", None) not in remove_set
        ]

    updated.updated_at = datetime.now(timezone.utc)
    return updated

