/**
 * Browser-side cache for area geometries (e.g. departments).
 *
 * Area geometries only depend on the area itself, not on the taxon. They are
 * therefore cached by `id_area` and reused across species sheets, so that a
 * department already downloaded for one species is not downloaded again for
 * another one.
 *
 * Records are plain objects with at least an `id_area` field, e.g.
 * `{ id_area: 44, area_name: "Loire-Atlantique", geojson: {...} }`.
 * Storage uses IndexedDB and silently falls back to an in-memory Map when
 * IndexedDB is unavailable (private mode, old browser...).
 */
// eslint-disable-next-line no-unused-vars
const AreaGeometryCache = (function () {
    const DB_NAME = "geonature-atlas-area-cache";
    const STORE_NAME = "areaGeometries";
    const DB_VERSION = 1;

    const memoryFallback = new Map();
    let dbPromise = null;

    function supportsIndexedDB() {
        try {
            return typeof indexedDB !== "undefined" && indexedDB !== null;
        } catch {
            return false;
        }
    }

    function openDatabase() {
        if (dbPromise) {
            return dbPromise;
        }
        dbPromise = new Promise((resolve, reject) => {
            const request = indexedDB.open(DB_NAME, DB_VERSION);
            request.onupgradeneeded = () => {
                const database = request.result;
                if (!database.objectStoreNames.contains(STORE_NAME)) {
                    database.createObjectStore(STORE_NAME, { keyPath: "id_area" });
                }
            };
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
        return dbPromise;
    }

    function readFromStore(ids) {
        return openDatabase().then(
            (database) =>
                new Promise((resolve, reject) => {
                    const records = {};
                    if (ids.length === 0) {
                        resolve(records);
                        return;
                    }
                    const transaction = database.transaction(STORE_NAME, "readonly");
                    const store = transaction.objectStore(STORE_NAME);
                    let pending = ids.length;
                    ids.forEach((id) => {
                        const request = store.get(id);
                        request.onsuccess = () => {
                            if (request.result) {
                                records[id] = request.result;
                            }
                            pending -= 1;
                            if (pending === 0) {
                                resolve(records);
                            }
                        };
                        request.onerror = () => reject(request.error);
                    });
                }),
        );
    }

    function writeToStore(records) {
        return openDatabase().then(
            (database) =>
                new Promise((resolve, reject) => {
                    const transaction = database.transaction(STORE_NAME, "readwrite");
                    const store = transaction.objectStore(STORE_NAME);
                    records.forEach((record) => store.put(record));
                    transaction.oncomplete = () => resolve();
                    transaction.onerror = () => reject(transaction.error);
                }),
        );
    }

    /**
     * Return the cached records for the given ids, as an object keyed by id_area.
     * Ids without a cached record are simply absent from the result.
     */
    async function get(ids) {
        const uniqueIds = [...new Set(ids.map(Number))];
        if (!supportsIndexedDB()) {
            const records = {};
            uniqueIds.forEach((id) => {
                if (memoryFallback.has(id)) {
                    records[id] = memoryFallback.get(id);
                }
            });
            return records;
        }
        try {
            return await readFromStore(uniqueIds);
        } catch (error) {
            console.error("AreaGeometryCache: unable to read from IndexedDB", error);
            return {};
        }
    }

    /**
     * Store records (each one must contain an `id_area` field).
     */
    async function put(records) {
        if (!records || records.length === 0) {
            return;
        }
        if (!supportsIndexedDB()) {
            records.forEach((record) => memoryFallback.set(Number(record.id_area), record));
            return;
        }
        try {
            await writeToStore(records);
        } catch (error) {
            console.error("AreaGeometryCache: unable to write to IndexedDB", error);
        }
    }

    /**
     * Return the records for the given ids, fetching and caching the missing ones.
     *
     * @param {Array<number|string>} ids
     * @param {function(Array<number>): Promise<Array<object>>} fetchMissing
     *        called with the list of ids that are not cached yet, and must
     *        resolve with the corresponding records.
     * @returns {Promise<Object<number, object>>} records keyed by id_area
     */
    async function getOrFetch(ids, fetchMissing) {
        const uniqueIds = [...new Set(ids.map(Number))];
        const records = await get(uniqueIds);

        const missingIds = uniqueIds.filter((id) => !(id in records));
        if (missingIds.length > 0) {
            const fetched = await fetchMissing(missingIds);
            await put(fetched);
            fetched.forEach((record) => {
                records[Number(record.id_area)] = record;
            });
        }
        return records;
    }

    /**
     * Remove every cached geometry.
     */
    async function clear() {
        memoryFallback.clear();
        if (!supportsIndexedDB()) {
            return;
        }
        try {
            const database = await openDatabase();
            await new Promise((resolve, reject) => {
                const transaction = database.transaction(STORE_NAME, "readwrite");
                transaction.objectStore(STORE_NAME).clear();
                transaction.oncomplete = () => resolve();
                transaction.onerror = () => reject(transaction.error);
            });
        } catch (error) {
            console.error("AreaGeometryCache: unable to clear IndexedDB", error);
        }
    }

    return { get, put, getOrFetch, clear };
})();
