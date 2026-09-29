var zoomHomeButton = true;

var map = generateMap(zoomHomeButton);

if (configuration.MAP.ENABLE_SLIDER) {
    generateSliderOnMap();
}
// Layer display on window ready

/*GLOBAL VARIABLE*/

// Current observation Layer: leaflet layer type
var currentLayer;

// Current observation geoJson:  type object
// eslint-disable-next-line no-unused-vars
var myGeoJson;

// global variable to see if the slider has been touch
var sliderTouch = false;

// variable globale: observations récupérer en AJAX
var observationsMaille;
var observationsPoint;
var onlyPointLoaded = false; // Indique si les points peuvent être chargés (nb_obs <= limite)
var shouldDisplayMailles = false; // Indique si les mailles doivent être affichées

// variable globale: year filters
var yearMin = null;
var yearMax = null;

/**
 * Affiche les données selon le contexte
 */
function displayDataByZoomLevel() {
    const isZoomedToPoints = map.getZoom() >= configuration.ZOOM_LEVEL_POINT;
    if (onlyPointLoaded || isZoomedToPoints) {
        clearObservationsFeatureGroup();

        // Afficher les points
        displayMarkerLayerFicheEspece(
            observationsPoint,
            yearMin,
            yearMax,
            sliderTouch,
        );
        // Laisser displayMarkerLayerFicheEspece gérer la légende des points
    } else if (shouldDisplayMailles) {
        // Afficher les mailles
        map.removeLayer(currentLayer);
        displayGeojsonMailles(observationsMaille, onEachFeatureMaille);
        const legendColorObs = document.querySelector("#legend-color-obs");
        legendColorObs.querySelectorAll("div").forEach((elem) => elem.remove());
        legendColorObs.appendChild(generateObservationsLegend(true));

        const legendblock = $("div.info");
        legendblock.removeAttr("hidden");

        // Mettre à jour le compteur
        setObservationCounter(observationsMaille);
    }
}

/**
 * Lance le rechargement des mailles selon les filtres d'année
 */
function reloadMaillesWithYearFilter() {
    map.removeLayer(currentLayer);

    $("#loaderSpinner").show();
    loadMailles({year_min: yearMin, year_max: yearMax}, () => {
        displayDataByZoomLevel();
    });
}

/**
 * Configure les événements du slider si activé
 */
function setupSlider() {
    if (!configuration.MAP.ENABLE_SLIDER) {
        return;
    }

    mySlider.on("change", function () {
        sliderTouch = true;
        years = mySlider.getValue();
        yearMin = years[0];
        yearMax = years[1];

        $("#yearMin").text(yearMin);
        $("#yearMax").text(yearMax);
    });

    mySlider.on("slideStop", function () {
        sliderTouch = true;

        if (shouldDisplayMailles) {
            // Si on a les mailles, les recharger avec le filtre
            reloadMaillesWithYearFilter();
        } else {
            // Sinon juste réafficher les points filtrés
            map.removeLayer(currentLayer);
            displayDataByZoomLevel();
        }
    });
}

function loadPoints() {
    $.ajax({
        url: configuration.URL_APPLICATION + "/api/observationsPoint",
        dataType: "json",
        type: "get",
        data: {
            cd_ref: cd_ref,
        },
    }).done(function (observations) {
        $("#loaderSpinner").hide();
        observationsPoint = observations;

        // Réactiver le zoom après chargement des points
        map.scrollWheelZoom.enable();

        // Afficher les points
        displayDataByZoomLevel();
        setObservationCounter(observationsMaille);
        eventOnZoom();
        setupSlider();
    });
}

function loadMailles(params, onSuccess = undefined) {
    $.ajax({
        url: configuration.URL_APPLICATION + "/api/observationsMaille",
        dataType: "json",
        type: "get",
        data: { cd_ref: cd_ref, ...params },
    }).done(function (observations) {
        $("#loaderSpinner").hide();
        observationsMaille = observations;
        setObservationCounter(observationsMaille);
        if (onSuccess !== undefined) {
            onSuccess();
        }
    });
}

$("#loaderSpinner").show();

// Vérifier le nombre d'observations et décider de la stratégie de chargement
if (nb_obs <= configuration.LIMIT_POINT_MAILLE) {
    // nb_obs faible: charger UNIQUEMENT les points
    onlyPointLoaded = true;
    shouldDisplayMailles = false;
    loadPoints();
} else {
    // nb_obs élevé: charger d'abord les mailles, puis les points
    shouldDisplayMailles = true;
    loadMailles({}, () => {
        displayGeojsonMailles(observationsMaille, onEachFeatureMaille);
        // Bloquer le zoom pendant le chargement des points
        map.scrollWheelZoom.disable();
        // Charger les points en arrière-plan
        loadPoints();
    })
}

function eventOnZoom() {
    // ZoomEvent: change maille to point (seulement si on a les deux types de données)
    var activeMode = shouldDisplayMailles ? "Maille" : "Point";

    map.on("zoomend", function () {
        const isZoomedToPoints =
            map.getZoom() >= configuration.ZOOM_LEVEL_POINT;

        // Si on n'a que les points, ne rien faire
        if (!shouldDisplayMailles) {
            return;
        }

        // Si on a les mailles et points, basculer selon le zoom
        if (activeMode === "Maille" && isZoomedToPoints) {
            displayDataByZoomLevel();
            activeMode = "Point";
        }
        if (activeMode === "Point" && !isZoomedToPoints) {
            displayDataByZoomLevel();
            activeMode = "Maille";
        }
    });
}

function setObservationCounter(observations) {
    const uuidSet = new Set();
    observations.features
        .map(f => f.properties.ids_obs)
        .forEach(uuidList => uuidList.forEach(uuid => uuidSet.add(uuid)));
    nbObs = uuidSet.size;
    $("#nbObs").text(nbObs);
}