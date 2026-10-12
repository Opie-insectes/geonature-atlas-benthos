from sqlalchemy import select

from atlas.env import db
from atlas.modeles.entities.vmAreas import VmAreas
from atlas.modeles.entities.vmRegionalResponsibilities import VmRegionalResponsibilities
from atlas.modeles.repositories import vmAreasRepository


def getResponsabilities(cd_ref: int):
    regions = {
        region["id_area"]: {
            "name_region": region["area_name"],
            "percentage_region": "0.00",
        }
        for region in vmAreasRepository.getAreasByType("REG")
    }

    query = (
        select(
            VmRegionalResponsibilities.id_area,
            VmAreas.area_name,
            VmRegionalResponsibilities.percentage,
        )
        .join(VmAreas, VmAreas.id_area == VmRegionalResponsibilities.id_area)
        .where(VmRegionalResponsibilities.cd_ref == cd_ref)
    )
    for row in db.session.execute(query).all():
        if row.percentage > 0:
            regions[row.id_area]["percentage_region"] = row.percentage

    return list(regions.values())
