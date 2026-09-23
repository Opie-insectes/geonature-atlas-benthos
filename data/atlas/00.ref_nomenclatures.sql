-- Importe quelques nomenclatures utiles depuis le GN

CREATE materialized view atlas.vm_nomenclatures AS
    SELECT bnt.mnemonique AS mnemonique_nomenclature, tn.*
    FROM ref_nomenclatures.t_nomenclatures tn 
    JOIN ref_nomenclatures.bib_nomenclatures_types bnt USING (id_type)
    WHERE bnt.mnemonique = 'STADE_VIE'
WITH DATA;