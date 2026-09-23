# coding: utf-8
from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column
from atlas.env import db


class VmNomenclatures(db.Model):
    __tablename__ = "vm_nomenclatures"
    __table_args__ = {"schema": "atlas"}

    id_nomenclature: Mapped[int] = mapped_column(primary_key=True)
    label_default: Mapped[str] = mapped_column(String(255))
    label_fr: Mapped[str] = mapped_column(String(255))
