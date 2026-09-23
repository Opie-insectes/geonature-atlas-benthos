# coding: utf-8
from geoalchemy2.types import Geometry
from sqlalchemy import Integer, String, Text, ARRAY, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from babel.dates import format_datetime
from atlas.env import db
from atlas.modeles.entities.vmTaxons import VmTaxons

from typing import List
import datetime
import uuid


class VmObservations(db.Model):
    __tablename__ = "vm_observations"
    __table_args__ = {"schema": "atlas"}

    id_observation: Mapped[int] = mapped_column(primary_key=True)
    dateobs: Mapped[datetime.date] = mapped_column(index=True)
    observateurs: Mapped[str] = mapped_column(String(255))
    altitude_retenue: Mapped[int] = mapped_column(index=True)
    cd_ref: Mapped[int] = mapped_column(ForeignKey("atlas.vm_taxons.cd_ref"), index=True)
    the_geom_point: Mapped[object] = mapped_column(Geometry(geometry_type="POINT", srid=4326))
    geojson_point: Mapped[str] = mapped_column(Text)
    cd_sensitivity: Mapped[str] = mapped_column(String(255))
    id_dataset: Mapped[int] = mapped_column()
    taxon: Mapped[VmTaxons] = relationship(VmTaxons)
    id_nomenclature_life_stage: Mapped[int] = mapped_column()

    def as_dict(self):
        return {
            "dateobs": self.dateobs.strftime("%d-%m-%Y"),
            "year": self.dateobs.year if self.dateobs else None,
            "id_observation": self.id_observation,
            "observateurs": self.observateurs,
            "altitude_retenue": self.altitude_retenue,
            "cd_ref": self.cd_ref,
            "cd_sensitivity": self.cd_sensitivity,
        }


class VMCorMailleObservation(db.Model):
    """
    Table des observations par maille
    """

    __tablename__ = "vm_cor_maille_observation"
    __table_args__ = {"schema": "atlas"}

    id_maille: Mapped[int] = mapped_column(primary_key=True)
    id_observation: Mapped[int] = mapped_column(primary_key=True)
    type_code: Mapped[str] = mapped_column(String(25))


class VmObservationsGrp(db.Model):
    """
    Table des observations réelles.

    En termes SOTv3, cette table contient des informations plus proche des
    concepts SujetObservation (et Evenement) contrairement à VmObservations qui
    contient en réalité des dénombrements (DescriptifSujet).
    """

    __tablename__ = "vm_observations_grp"
    __table_args__ = {"schema": "atlas"}

    uuid_observation: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True)
    id_observations: Mapped[List[int]] = mapped_column(ARRAY(Integer))
    uuid_denombrements: Mapped[List[uuid.UUID]] = mapped_column(ARRAY(UUID(as_uuid=True)))

    date_min: Mapped[datetime.date] = mapped_column(index=True)
    date_max: Mapped[datetime.date] = mapped_column()
    observateurs: Mapped[str] = mapped_column(String(255))
    altitude_retenue: Mapped[int] = mapped_column(index=True)
    cd_ref: Mapped[int] = mapped_column(ForeignKey("atlas.vm_taxons.cd_ref"), index=True)
    the_geom_point: Mapped[object] = mapped_column(Geometry(geometry_type="POINT", srid=4326))
    geojson_point: Mapped[str] = mapped_column(Text)
    cd_sensitivity: Mapped[str] = mapped_column(String(255))
    id_dataset: Mapped[int] = mapped_column()
    taxon: Mapped[VmTaxons] = relationship(VmTaxons)

    def as_dict(self):
        return {
            "date_min": self.date_min.strftime("%d-%m-%Y"),
            "date_max": self.date_max.strftime("%d-%m-%Y"),
            "year": self.date_min.year if self.date_min else None,
            "uuid_observation": self.uuid_observation,
            "observateurs": self.observateurs,
            "altitude_retenue": self.altitude_retenue,
            "cd_ref": self.cd_ref,
            "cd_sensitivity": self.cd_sensitivity,
        }


class VMCorMailleObservationGrp(db.Model):
    """
    Table des observations par maille (version observation réelle)
    """

    __tablename__ = "vm_cor_maille_observation_grp"
    __table_args__ = {"schema": "atlas"}

    id_maille: Mapped[int] = mapped_column(primary_key=True)
    uuid_observation: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True)
    type_code: Mapped[str] = mapped_column(String(25))
