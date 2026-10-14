CREATE MATERIALIZED VIEW atlas.vm_cor_taxon_area AS
    WITH taxons AS (
        SELECT
            cd_ref,
            array_agg(id_observation) AS observations
        FROM atlas.vm_observations
        GROUP BY cd_ref
    )
    SELECT DISTINCT
        t.cd_ref,
        cas.id_area
    FROM taxons AS t
        JOIN atlas.vm_cor_area_synthese AS cas
            ON cas.id_synthese = ANY(t.observations)
    WHERE cas.is_valid_for_display IS TRUE ;

CREATE UNIQUE INDEX ON atlas.vm_cor_taxon_area
    USING btree (cd_ref, id_area);


-- Version spécifique à partir des années 2000, par tranches de 5 ans. 🍞
-- La première tranche a NULL en year_min car on prend toutes les anciennes observations.
-- La dernière tranche a NULL en year_max car elle n'est pas terminée.
-- Attention cette vue ne doit pas avoir de recoupement entre les tranches !
CREATE MATERIALIZED VIEW atlas.vm_cor_taxon_area_by_range AS
    WITH taxons AS (
        SELECT cd_ref, array_agg(id_observation) AS observations, NULL AS year_min, 1999 AS year_max
        FROM atlas.vm_observations
        WHERE EXTRACT (YEAR FROM dateobs) < 2000
        GROUP BY cd_ref
        UNION ALL
        SELECT cd_ref, array_agg(id_observation) AS observations, 2000 AS year_min, 2004 AS year_max
        FROM atlas.vm_observations
        WHERE EXTRACT (YEAR FROM dateobs) BETWEEN 2000 AND 2004
        GROUP BY cd_ref
        UNION ALL
        SELECT cd_ref, array_agg(id_observation) AS observations, 2005 AS year_min, 2009 AS year_max
        FROM atlas.vm_observations
        WHERE EXTRACT (YEAR FROM dateobs) BETWEEN 2005 AND 2009
        GROUP BY cd_ref
        UNION ALL
        SELECT cd_ref, array_agg(id_observation) AS observations, 2010 AS year_min, 2014 AS year_max
        FROM atlas.vm_observations
        WHERE EXTRACT (YEAR FROM dateobs) BETWEEN 2010 AND 2014
        GROUP BY cd_ref
        UNION ALL
        SELECT cd_ref, array_agg(id_observation) AS observations, 2015 AS year_min, 2019 AS year_max
        FROM atlas.vm_observations
        WHERE EXTRACT (YEAR FROM dateobs) BETWEEN 2015 AND 2019
        GROUP BY cd_ref
        UNION ALL
        -- Toutes les observations de 2020 à maintenant (tranche actuelle et non terminée)
        SELECT cd_ref, array_agg(id_observation) AS observations, 2020 AS year_min, NULL AS year_max
        FROM atlas.vm_observations
        WHERE EXTRACT (YEAR FROM dateobs) >= 2020
        GROUP BY cd_ref
    )
    SELECT DISTINCT
        t.cd_ref,
        cas.id_area,
        year_min,
        year_max
    FROM taxons AS t
    JOIN atlas.vm_cor_area_synthese AS cas ON cas.id_synthese = ANY(t.observations)
    WHERE cas.is_valid_for_display IS TRUE
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_cor_taxon_area
    USING btree (cd_ref, id_area);


CREATE MATERIALIZED VIEW atlas.vm_cor_taxon_area_by_cumul AS
    WITH ranges AS (
        SELECT *
        FROM vm_cor_taxon_area_by_range cta
        JOIN vm_l_areas a USING (id_area)
        WHERE year_min >= 2000
    )
    SELECT cd_ref, id_type, COUNT(DISTINCT id_area) AS cumul, 2004 AS year_max
    FROM ranges
    WHERE year_max <= 2004
    GROUP BY cd_ref, id_type
    UNION ALL
    SELECT cd_ref, id_type, COUNT(DISTINCT id_area) AS cumul, 2009 AS year_max
    FROM ranges
    WHERE year_max <= 2009
    GROUP BY cd_ref, id_type
    UNION ALL
    SELECT cd_ref, id_type, COUNT(DISTINCT id_area) AS cumul, 2014 AS year_max
    FROM ranges
    WHERE year_max <= 2014
    GROUP BY cd_ref, id_type
    UNION ALL
    SELECT cd_ref, id_type, COUNT(DISTINCT id_area) AS cumul, 2019 AS year_max
    FROM ranges
    WHERE year_max <= 2019
    GROUP BY cd_ref, id_type
    UNION ALL
    SELECT cd_ref, id_type, COUNT(DISTINCT id_area) AS cumul, NULL AS year_max
    FROM ranges
    GROUP BY cd_ref, id_type
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_cor_taxon_area
    USING btree (cd_ref, id_type, year_max);


-- Calcul des responsabilités régionales.
CREATE MATERIALIZED VIEW atlas.vm_regional_responsibilities AS
	WITH mailles_per_region AS (
		SELECT cd_ref, vla.id_area, COUNT(*) AS num_mailles
		FROM atlas.vm_cor_taxon_area_by_range cta
		JOIN atlas.vm_cor_maille_region cmr ON cmr.id_maille = cta.id_area
		JOIN atlas.vm_l_areas vla ON vla.id_area = cmr.id_region
	    JOIN ref_geo.bib_areas_types bat USING (id_type)
		WHERE bat.type_code = 'REG' AND cta.year_min >= 2000
		GROUP BY cd_ref, vla.id_area
		ORDER BY cd_ref
	),
	total_per_taxon AS (
		SELECT cd_ref, SUM(num_mailles) AS total
		FROM mailles_per_region
		GROUP BY cd_ref
	)
	SELECT
		cd_ref,
		mpr.id_area,
		mpr.num_mailles,
		tpt.total AS total_mailles,
		(mpr.num_mailles::numeric / tpt.total * 100)::numeric(5, 2) AS percentage
	FROM mailles_per_region mpr
	JOIN total_per_taxon tpt USING (cd_ref)
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_regional_responsibilities
    USING btree (cd_ref, id_area);
