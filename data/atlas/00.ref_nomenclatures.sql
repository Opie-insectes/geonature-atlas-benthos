-- Importe quelques nomenclatures utiles depuis le GN

CREATE MATERIALIZED VIEW atlas.vm_nomenclatures AS
    SELECT bnt.mnemonique AS mnemonique_nomenclature, tn.*
    FROM ref_nomenclatures.t_nomenclatures tn
    JOIN ref_nomenclatures.bib_nomenclatures_types bnt USING (id_type)
    WHERE bnt.mnemonique IN ('STADE_VIE', 'STATUT_VALID')
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_nomenclatures
    USING btree (id_nomenclature);
