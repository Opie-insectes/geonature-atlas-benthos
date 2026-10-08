CREATE MATERIALIZED VIEW atlas.vm_observations_centroids AS
    -- Unsensitive data or id_nomenclature_sensitivity = NULL
    SELECT
        s.id_synthese,
        coalesce(se.cd_nomenclature, '0') AS cd_sensitivity, -- si le niveau de sensi est null on le met à 0 (non sensible) - obligatoire pour ne pas créé une layer "NULL" en front
        s.the_geom_point AS geom_point
    FROM :observation_data_source AS s
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS se
            ON se.id_nomenclature = s.id_nomenclature_sensitivity
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS st
            ON s.id_nomenclature_observation_status = st.id_nomenclature
    WHERE s.the_geom_point IS NOT NULL
        AND (st.cd_nomenclature = 'Pr' OR s.id_nomenclature_observation_status IS NULL)
        AND (se.cd_nomenclature = '0' OR s.id_nomenclature_sensitivity IS NULL)

    UNION

    -- Sensitive data
    SELECT
        s.id_synthese,
        se.cd_nomenclature AS cd_sensitivity,
        st_centroid(st_union(a.the_geom)) AS geom_point
    FROM :observation_data_source AS s
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS st
            ON s.id_nomenclature_observation_status = st.id_nomenclature
        JOIN gn_synthese.cor_area_synthese AS cas
            ON cas.id_synthese = s.id_synthese
        JOIN atlas.vm_l_areas AS a
            ON a.id_area = cas.id_area
        JOIN ref_geo.bib_areas_types AS bat
            ON bat.id_type = a.id_type
        JOIN ref_nomenclatures.t_nomenclatures AS se
            ON se.id_nomenclature = s.id_nomenclature_sensitivity
        JOIN atlas.vm_cor_sensitivity_area_type AS csat
            ON (
                csat.sensitivity_code = se.cd_nomenclature
                AND csat.area_type_code = bat.type_code
            )
    WHERE s.the_geom_point IS NOT NULL
        AND (st.cd_nomenclature = 'Pr' OR s.id_nomenclature_observation_status IS NULL)
        AND se.cd_nomenclature NOT IN ('0', '4', '2.8')
    GROUP BY s.id_synthese, se.cd_nomenclature
WITH DATA;

-- All the observations to use in the Atlas
CREATE MATERIALIZED VIEW atlas.vm_observations AS
    SELECT
        s.id_synthese AS id_observation,
        c.geom_point AS the_geom_point,
        st_asgeojson(c.geom_point) AS geojson_point,
        c.cd_sensitivity,
        s.date_min AS dateobs,
        (s.altitude_min + s.altitude_max) / 2 AS altitude_retenue,
        s.observers AS observateurs,
        s.id_dataset,
        tx.cd_ref,
        s.id_nomenclature_life_stage
    FROM :observation_data_source AS s
        JOIN atlas.vm_observations_centroids AS c
            ON c.id_synthese = s.id_synthese
        JOIN atlas.vm_taxref AS tx
            ON tx.cd_nom = s.cd_nom
        JOIN gn_meta.t_datasets d
            USING (id_dataset)
        JOIN gn_meta.t_acquisition_frameworks af
            USING (id_acquisition_framework)
        JOIN ref_nomenclatures.t_nomenclatures tn
            ON tn.id_nomenclature = s.id_nomenclature_valid_status
    WHERE
        af.unique_acquisition_framework_id = :'acquisition_framework'
        AND tn.cd_nomenclature = '1'
    ORDER BY s.id_synthese
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_observations
    USING btree (id_observation);

CREATE INDEX ON atlas.vm_observations
    USING btree (cd_ref);

CREATE INDEX ON atlas.vm_observations
    USING btree (altitude_retenue);

CREATE INDEX ON atlas.vm_observations
    USING btree (dateobs);

CREATE INDEX ON atlas.vm_observations
    USING btree (cd_sensitivity);

CREATE INDEX ON atlas.vm_observations
    USING gist (the_geom_point);

-- A second observation VM that groups actual observations together:
-- GN synthese splits determinations into individual rows whereas 
-- we want to have them grouped per actual observation in many cases.
CREATE MATERIALIZED VIEW atlas.vm_observations_grp AS
    WITH observations AS (
	    SELECT
	        s.id_synthese,
	        s.unique_id_sinp,
	        s.unique_id_sinp_grp,
	        c.geom_point AS the_geom_point,
	        st_asgeojson(c.geom_point) AS geojson_point,
	        c.cd_sensitivity,
	        s.date_min AS date_min,
	        s.date_max AS date_max,
	        (s.altitude_min + s.altitude_max) / 2 AS altitude_retenue,
	        s.observers AS observateurs,
	        s.id_dataset,
	        tx.cd_ref
        FROM gn_synthese.synthese AS s
        JOIN atlas.vm_observations_centroids AS c
            ON c.id_synthese = s.id_synthese
        JOIN atlas.vm_taxref AS tx
            ON tx.cd_nom = s.cd_nom
        JOIN gn_meta.t_datasets d
            USING (id_dataset)
        JOIN gn_meta.t_acquisition_frameworks af
            USING (id_acquisition_framework)
        JOIN ref_nomenclatures.t_nomenclatures tn
            ON tn.id_nomenclature = s.id_nomenclature_valid_status
        WHERE
            af.unique_acquisition_framework_id = :'acquisition_framework'
            AND tn.cd_nomenclature = '1'
    )
    SELECT
        unique_id_sinp_grp AS uuid_observation,
        array_agg(id_synthese) AS id_observations,
        array_agg(unique_id_sinp) AS uuid_denombrements,
        the_geom_point, geojson_point,
        cd_sensitivity,
        date_min, date_max,
        altitude_retenue,
        observateurs,
        id_dataset,
        cd_ref
    FROM observations
    GROUP BY unique_id_sinp_grp,
        the_geom_point, geojson_point, cd_sensitivity,
        date_min, date_max, altitude_retenue, observateurs, id_dataset,
        cd_ref
    ORDER BY unique_id_sinp_grp
WITH DATA;

CREATE UNIQUE INDEX ON atlas.vm_observations_grp
    USING btree (uuid_observation);

CREATE INDEX ON atlas.vm_observations_grp
    USING btree (cd_ref);

CREATE INDEX ON atlas.vm_observations_grp
    USING btree (altitude_retenue);

CREATE INDEX ON atlas.vm_observations_grp
    USING btree (date_min);

CREATE INDEX ON atlas.vm_observations_grp
    USING btree (cd_sensitivity);

CREATE INDEX ON atlas.vm_observations_grp
    USING gist (the_geom_point);
