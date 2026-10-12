from typing import ClassVar

from sqlalchemy import Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship

from atlas.env import db


class VmRegionalResponsibilities(db.Model):
    __tablename__: ClassVar = "vm_regional_responsibilities"
    __table_args__: ClassVar = {"schema": "atlas"}

    cd_ref: Mapped[int] = mapped_column(primary_key=True)
    id_area: Mapped[int] = mapped_column(primary_key=True)
    num_mailles: Mapped[int]
    total_mailles: Mapped[int]
    percentage: Mapped[float] = mapped_column(Numeric(5, 2))

    def as_dict(self):
        return {"diese": True}
