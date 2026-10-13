document.addEventListener('DOMContentLoaded', function () {
    const block = document.querySelector("#ephemeraRefs");

    const loading_cue = block.querySelector(".spinner-grow");
    loading_cue.classList.remove("visually-hidden");

    const params = new URLSearchParams();
    params.set('search', document.getElementById('taxonName').dataset.lbnom);
    const url = `https://ephemera.insectes.org/wp-json/wp/v2/search?${params}`;

    return fetch(url)
        .then(response => response.json())
        .then(data => {
            if (data.length === 0) {
                const error_message = document.createElement("p");
                error_message.innerText = "Aucune référence trouvée.";
                block.appendChild(error_message);
            }
            const ref_list = document.createElement("ul");
            ref_list.classList.add("mb-0");
            data.forEach(item => {
                const element = document.createElement("li");
                element.innerHTML = `<a href="${item.url}" target="_blank">${item.title}</a>`;
                ref_list.appendChild(element);
            });
            block.appendChild(ref_list);
        })
        .catch(err => {
            console.error(err);
            const error_message = document.createElement("p");
            error_message.classList.add("text-danger");
            error_message.innerText = "Impossible de contacter Ephemera.";
            block.appendChild(error_message);
        })
        .finally(() => loading_cue.classList.add("visually-hidden"))
});
