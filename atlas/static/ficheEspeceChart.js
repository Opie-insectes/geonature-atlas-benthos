//Generic vertical bar graph
genericChart = function (element, labels, values) {
    return new Chart(element, {
        type: "bar",
        data: {
            labels: labels,
            datasets: [
                {
                    label: window.i18n.observations + ' ',
                    data: values,
                    backgroundColor: chartMainColor,
                    hoverBackgroundColor: chartHoverMainColor,
                    borderWidth: 0,
                },
            ],
        },
        options: {
            scales: {
                y: {
                    ticks: {
                        beginAtZero: true,
                    },
                },
                x: {
                    gridLines: {
                        display: false,
                    },
                },
            },
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: "top",
                    display: false,
                },
            },
        },
    });
};

// Stacked vertical bar graph (one dataset per life stage, should be 3)
const monthsBarColors = {
    Adulte: "#395ca3",
    Larve: "#7ea0e6",
    Exuvie: "#e7dbc1",
}

monthsBarChart = function (element, labels, series) {
    return new Chart(element, {
        type: "bar",
        data: {
            labels: labels,
            datasets: series
                .filter((serie) => serie.life_stage !== 'Inconnu')
                .map((serie, index) => ({
                    label: (serie.life_stage || "N/A") + ' ',
                    data: serie.values,
                    backgroundColor: monthsBarColors[serie.life_stage] ?? "#7f7f7f",
                    borderWidth: 0,
                })),
        },
        options: {
            scales: {
                y: {
                    ticks: {
                        beginAtZero: true,
                    },
                },
                x: {
                    grid: {
                        display: false,
                    },
                },
            },
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: "top",
                    display: true,
                },
            },
        },
    });
};

// pie chart config for zoning sheet and areaSheet

pieChartConfig = function (element, data) {
    return new Chart(element, {
        type: "doughnut",
        data: data,
        options: {
            responsive: true,
            cutout: "30%",
            maintainAspectRatio: false,
            layout: {
                padding: 25,
            },
            plugins: {
                legend: {
                    position: "top",
                },
                title: {
                    display: false,
                },
            },
        },
    });
};

// use for zoning and species sheet

function formatPieData(data) {
    const labels = [];
    const data_count = [];
    Object.keys(data).forEach((key) => {
        labels.push(key);
        data_count.push(data[key]);
    });

    return {
        labels: labels,
        datasets: [
            {
                label: window.i18n["obs.number.s"],
                data: data_count,
                backgroundColor: configuration.COLOR_PIE_CHARTS,
                hoverOffset: 25,
            },
        ],
    };
}

const responsabilityColorThresholds = [
    [35, "#dc3545"],
    [20, "#fd7e14"],
    [10, "#ffc107"],
    [5, "#20c997"],
    [0, "#198754"],
];

mapDataToColors = (data) =>
    data.map(value =>
        responsabilityColorThresholds.find(threshold => value >= threshold[0])[1]
    );

regionalRespChart = (element, data) => {
    data = data.sort((a, b) => b.percentage_region - a.percentage_region);
    const labels = data.map(region => region.name_region);
    const dataPoints = data.map(region => Number(region.percentage_region));
    const colors = mapDataToColors(dataPoints);
    return new Chart(element, {
        type: "bar",
        data: {
            labels: labels,
            datasets: [
                {
                    data: dataPoints,
                    backgroundColor: colors,
                    borderWidth: 0,
                },
            ],
        },
        options: {
            indexAxis: 'y',
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false,
                },
            },
        },
    });
};

const getChartDatas = function (data, key) {
    const values = [];
    for (var i = 0; i < data.length; i++) {
        values.push(data[i][key]);
    }
    return values;
};

const monthObsChartElement = document.getElementById("monthObsChart");
if (monthObsChartElement) {
    genericChart(monthObsChartElement, months_name, months_obs_value);
}

const monthLifeStagesChartElement = document.getElementById("monthLifeStagesChart");
if (monthLifeStagesChartElement) {
    monthsBarChart(monthLifeStagesChartElement, months_name, months_den_value);
}

const altiChartElement = document.getElementById("altiChart");
if (altiChartElement) {
    genericChart(
        altiChartElement,
        getChartDatas(dataset, "altitude"),
        getChartDatas(dataset, "value"),
    );
}

const regionalRespChartElement = document.getElementById("regionsRespChart");
if (regionalRespChartElement) {
    regionalRespChart(regionalRespChartElement, responsabilities);
}

const dataSourceChartElement = document.getElementById("organismChart");
if (dataSourceChartElement) {
    pieChartConfig(
        dataSourceChartElement,
        formatPieData(organism_stats, dataSourceChartElement),
    );
}
