# -*- coding:utf-8 -*-

from sqlalchemy.sql import extract, func, select, or_
from atlas.modeles.entities.vmMois import VmMois, VmMoisGrp
from atlas.modeles.entities.vmNomenclatures import VmNomenclatures
from atlas.env import db
from atlas.utils import get_locale

MONTH_COLUMNS = [f"_{month:02d}" for month in range(1, 13)]

# Map lang codes to the appropriate VmNomenclatures column.
LABEL_COLUMNS = {
    attr[6:]: getattr(VmNomenclatures, attr)
    for attr in dir(VmNomenclatures)
    if attr.startswith('label_') and attr != 'label_default'
}


def getMonthlyObservations(cd_ref):
    childs_ids = select(func.atlas.find_all_taxons_childs(cd_ref))

    mesMois = (
        db.session.query(
            *[func.sum(getattr(VmMoisGrp, col)).label(col) for col in MONTH_COLUMNS],
        )
        .filter(or_(VmMoisGrp.cd_ref.in_(childs_ids), VmMoisGrp.cd_ref == cd_ref))
        .one()
    )

    return [mois for mois in mesMois]


def getMonthlyIndividualsPerLifeStage(cd_ref):
    childs_ids = select(func.atlas.find_all_taxons_childs(cd_ref))
    label_column = LABEL_COLUMNS.get(get_locale(), VmNomenclatures.label_default)

    mesMois = (
        db.session.query(
            VmMois.id_nomenclature_life_stage.label("life_stage_id"),
            func.coalesce(label_column, VmNomenclatures.label_default).label("life_stage"),
            *[func.sum(getattr(VmMois, col)).label(col) for col in MONTH_COLUMNS],
        )
        .outerjoin(
            VmNomenclatures,
            VmNomenclatures.id_nomenclature == VmMois.id_nomenclature_life_stage,
        )
        .filter(or_(VmMois.cd_ref.in_(childs_ids), VmMois.cd_ref == cd_ref))
        .group_by(
            VmMois.id_nomenclature_life_stage,
            VmNomenclatures.label_default,
            label_column,
        )
        .order_by(VmMois.id_nomenclature_life_stage)
    )

    return [
        {
            "life_stage": inter.life_stage,
            "values": [getattr(inter, col) for col in MONTH_COLUMNS],
        }
        for inter in mesMois
    ]
