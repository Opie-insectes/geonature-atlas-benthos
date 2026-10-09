/**
 * Department map (alternative view to the maille map).
 *
 * The department geometries are not part of the page payload: they are fetched
 * from the `/api/areasGeojson` route when the user selects the "Départements"
 * toggle, and cached in the browser (see areaGeometryCache.js) so that a
 * department already downloaded is reused on another species sheet.
 */
(function () {
    if (typeof taxonDepartments === "undefined" || !taxonDepartments) {
        return;
    }

    const departmentButton = document.getElementById("btnShowDepMap");
    const meshButton = document.getElementById("btnShowMeshMap");
    if (!departmentButton || !meshButton) {
        return;
    }

    if (taxonDepartments.length === 0) {
        // No department to display for this taxon.
        departmentButton.disabled = true;
        return;
    }

    const baseUrl = window.LANGUAGE_PREFIXED_URL_APPLICATION || configuration.URL_APPLICATION || "";
    function fetchGeometries(ids) {
        const url = `${baseUrl}/api/areasGeojson?ids=${ids.join(",")}`;
        return fetch(url).then((response) => {
            if (!response.ok) {
                throw new Error(`Unable to load area geometries (HTTP ${response.status})`);
            }
            return response.json();
        });
    }

    function styleDepartment() {
        return {
            color: configuration.COULEUR_CONTOUR_MAILLE,
            weight: 1,
            opacity: 1,
            fillColor: getColor(5), // see mapGenerator.js for the full palette
            fillOpacity: 0.8,
        };
    }

    function onEachDepartment(feature, layer) {
        const idArea = feature.properties.id_area;
        const areaName = feature.properties.area_name || "";
        layer.bindPopup(`
            <b>${areaName}</b><br>
            <a href="${baseUrl}/area/${idArea}">Voir la fiche du départment</a>
        `);
    }

    function removeDepartmentsLayer() {
        if (departmentsLayer && map.hasLayer(departmentsLayer)) {
            map.removeLayer(departmentsLayer);
        }
        departmentsLayer = null;
    }

    function hideMailleLayers() {
        Object.values(observationsFeatureGroup).forEach((featureGroup) => {
            if (map.hasLayer(featureGroup)) {
                map.removeLayer(featureGroup);
            }
        });
        $("#sliderContainerWrapper").hide();
    }

    function restoreMailleLayer() {
        const featureGroups = Object.values(observationsFeatureGroup);
        // Only the least sensitive level is displayed by default, as in
        // createLayersSelector.
        if (featureGroups.length > 0 && !map.hasLayer(featureGroups[0])) {
            map.addLayer(featureGroups[0]);
        }
        $("#sliderContainerWrapper").show();
    }

    let departmentsLayer = null;
    const departmentIds = taxonDepartments.map((area) => area.id_area);
    // Read by mapGenerator.js createLayersSelector: while this view is active,
    // a redraw of the maille layers (e.g. from the year slider) must not put
    // the maille feature groups back on the map.
    window.departmentViewActive = false;

    function showDepartments() {
        $("#loaderSpinner").show();
        AreaGeometryCache.getOrFetch(departmentIds, fetchGeometries)
            .then((records) => {
                // The user may have switched back to the maille view while the
                // geometries were being fetched.
                if (!departmentButton.checked) {
                    return;
                }
                const features = Object.values(records).map((record) => ({
                    type: "Feature",
                    id: record.id_area,
                    properties: {
                        id_area: record.id_area,
                        area_name: record.area_name || "",
                    },
                    geometry: record.geojson,
                }));

                window.departmentViewActive = true;
                hideMailleLayers();
                removeDepartmentsLayer();
                departmentsLayer = L.geoJson(
                    { type: "FeatureCollection", features: features },
                    { style: styleDepartment, onEachFeature: onEachDepartment },
                );
                departmentsLayer.addTo(map);
                departmentsLayer.bringToFront();
            })
            .catch((error) => console.error(error))
            .finally(() => $("#loaderSpinner").hide());
    }

    function showMaille() {
        window.departmentViewActive = false;
        removeDepartmentsLayer();
        restoreMailleLayer();
    }

    departmentButton.addEventListener("change", () => {
        if (departmentButton.checked) {
            showDepartments();
        }
    });

    meshButton.addEventListener("change", () => {
        if (meshButton.checked) {
            showMaille();
        }
    });
})();
