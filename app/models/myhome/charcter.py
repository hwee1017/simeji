from sqlalchemy import Integer, String, ForeignKey, UniqueConstraint, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship, foreign
from app.database.session import Base
from app.schemas.myhome.fashion import FashionCategory
from app.models.myhome.fashion import Fashion


class Character(Base):
    __tablename__ = "character"  

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String, nullable=False, unique=True)

    equipments: Mapped[list["CharacterEquipment"]] = relationship(
        "CharacterEquipment",
        back_populates="character",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

class CharacterEquipment(Base):
    __tablename__ = "character_equipments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    character_id: Mapped[int] = mapped_column(
        ForeignKey("character.id", ondelete="CASCADE"), nullable=False, index=True,)
    fashion_id: Mapped[int] = mapped_column( ForeignKey("fashion.id", ondelete="CASCADE"), nullable=False, index=True)
    category: Mapped[FashionCategory] = mapped_column(SAEnum(FashionCategory), nullable=False)

    __table_args__ = (
        UniqueConstraint("character_id", "category", name="uq_character_category"),
    )

    character: Mapped["Character"] = relationship("Character",back_populates="equipments",passive_deletes=True,
    )
    fashion: Mapped["Fashion"] = relationship("Fashion")
