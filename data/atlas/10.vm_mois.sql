-- Nombre d'observations mensuelles pour chaque taxon observé
-- Dans l'atlas benthos, cette vue est modifiée pour avoir le stade de vie en plus.
-- L'info d'observations par mois est stockée dans une seconde VM ci-dessous.

-- Vue des observations (individus) par mois.
-- On ignore les observations du 1er janvier parce que ce sont probablement des mauvaises dates,
-- et c'est férié dedjeu
CREATE materialized view atlas.vm_mois AS
    WITH
        _01 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 1 AND NOT EXTRACT(DAY FROM dateobs) = 1
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _02 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 2
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _03 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 3
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _04 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 4
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _05 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 5
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _06 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 6
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _07 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 7
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _08 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 8
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _09 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 9
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _10 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 10
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _11 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 11
            GROUP BY cd_ref, id_nomenclature_life_stage
        ),
        _12 AS (
            SELECT cd_ref, id_nomenclature_life_stage, count(*) AS nb
            FROM atlas.vm_observations
            WHERE EXTRACT(MONTH FROM dateobs) = 12
            GROUP BY cd_ref, id_nomenclature_life_stage
        )
    SELECT DISTINCT
        o.cd_ref,
        o.id_nomenclature_life_stage,
        COALESCE(a.nb::integer, 0) AS _01,
        COALESCE(b.nb::integer, 0) AS _02,
        COALESCE(c.nb::integer, 0) AS _03,
        COALESCE(d.nb::integer, 0) AS _04,
        COALESCE(e.nb::integer, 0) AS _05,
        COALESCE(f.nb::integer, 0) AS _06,
        COALESCE(g.nb::integer, 0) AS _07,
        COALESCE(h.nb::integer, 0) AS _08,
        COALESCE(i.nb::integer, 0) AS _09,
        COALESCE(j.nb::integer, 0) AS _10,
        COALESCE(k.nb::integer, 0) AS _11,
        COALESCE(l.nb::integer, 0) AS _12
    FROM atlas.vm_observations AS o
        LEFT JOIN _01 AS a ON a.cd_ref = o.cd_ref AND a.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _02 AS b ON b.cd_ref = o.cd_ref AND b.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _03 AS c ON c.cd_ref = o.cd_ref AND c.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _04 AS d ON d.cd_ref = o.cd_ref AND d.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _05 AS e ON e.cd_ref = o.cd_ref AND e.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _06 AS f ON f.cd_ref = o.cd_ref AND f.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _07 AS g ON g.cd_ref = o.cd_ref AND g.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _08 AS h ON h.cd_ref = o.cd_ref AND h.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _09 AS i ON i.cd_ref = o.cd_ref AND i.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _10 AS j ON j.cd_ref = o.cd_ref AND j.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _11 AS k ON k.cd_ref = o.cd_ref AND k.id_nomenclature_life_stage = o.id_nomenclature_life_stage
        LEFT JOIN _12 AS l ON l.cd_ref = o.cd_ref AND l.id_nomenclature_life_stage = o.id_nomenclature_life_stage
    WHERE o.cd_ref IS NOT NULL
    ORDER BY o.cd_ref
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_mois
    USING btree (cd_ref, id_nomenclature_life_stage);

-- Vue des observations (évènements+taxons) par mois.
CREATE materialized view atlas.vm_mois_grp AS
    WITH
        _01 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 1 AND NOT EXTRACT(DAY FROM date_min) = 1
            GROUP BY cd_ref
        ),
        _02 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 2
            GROUP BY cd_ref
        ),
        _03 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 3
            GROUP BY cd_ref
        ),
        _04 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 4
            GROUP BY cd_ref
        ),
        _05 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 5
            GROUP BY cd_ref
        ),
        _06 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 6
            GROUP BY cd_ref
        ),
        _07 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 7
            GROUP BY cd_ref
        ),
        _08 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 8
            GROUP BY cd_ref
        ),
        _09 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 9
            GROUP BY cd_ref
        ),
        _10 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 10
            GROUP BY cd_ref
        ),
        _11 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 11
            GROUP BY cd_ref
        ),
        _12 AS (
            SELECT cd_ref, count(*) AS nb
            FROM atlas.vm_observations_grp
            WHERE EXTRACT(MONTH FROM date_min) = 12
            GROUP BY cd_ref
        )
    SELECT DISTINCT
        o.cd_ref,
        COALESCE(a.nb::integer, 0) AS _01,
        COALESCE(b.nb::integer, 0) AS _02,
        COALESCE(c.nb::integer, 0) AS _03,
        COALESCE(d.nb::integer, 0) AS _04,
        COALESCE(e.nb::integer, 0) AS _05,
        COALESCE(f.nb::integer, 0) AS _06,
        COALESCE(g.nb::integer, 0) AS _07,
        COALESCE(h.nb::integer, 0) AS _08,
        COALESCE(i.nb::integer, 0) AS _09,
        COALESCE(j.nb::integer, 0) AS _10,
        COALESCE(k.nb::integer, 0) AS _11,
        COALESCE(l.nb::integer, 0) AS _12
    FROM atlas.vm_observations AS o
        LEFT JOIN _01 AS a ON a.cd_ref = o.cd_ref
        LEFT JOIN _02 AS b ON b.cd_ref = o.cd_ref
        LEFT JOIN _03 AS c ON c.cd_ref = o.cd_ref
        LEFT JOIN _04 AS d ON d.cd_ref = o.cd_ref
        LEFT JOIN _05 AS e ON e.cd_ref = o.cd_ref
        LEFT JOIN _06 AS f ON f.cd_ref = o.cd_ref
        LEFT JOIN _07 AS g ON g.cd_ref = o.cd_ref
        LEFT JOIN _08 AS h ON h.cd_ref = o.cd_ref
        LEFT JOIN _09 AS i ON i.cd_ref = o.cd_ref
        LEFT JOIN _10 AS j ON j.cd_ref = o.cd_ref
        LEFT JOIN _11 AS k ON k.cd_ref = o.cd_ref
        LEFT JOIN _12 AS l ON l.cd_ref = o.cd_ref
    WHERE o.cd_ref IS NOT NULL
    ORDER BY o.cd_ref
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_mois_grp
    USING btree (cd_ref);
