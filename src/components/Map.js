import { useEffect, useRef } from 'react';

const Map = ({ eventData, center, zoom }) => {
    const mapRef = useRef(null);
    const mapInstance = useRef(null);

    useEffect(() => {
        if (mapRef.current && !mapInstance.current) {
            // Initialize Map
            const L = window.L;
            if (!L) return; // Wait for Leaflet to load

            const map = L.map(mapRef.current).setView(center, zoom);

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
            }).addTo(map);

            mapInstance.current = map;
        }
    }, [center, zoom]);

    // Update markers when data changes
    useEffect(() => {
        if (!mapInstance.current || !eventData) return;

        const L = window.L;
        const map = mapInstance.current;

        // Clear existing markers (optional implementation for simplicity, we just add new ones)
        // Ideally use a LayerGroup

        eventData.forEach(ev => {
            if (ev.coordinates && ev.coordinates.length === 2 && !isNaN(ev.coordinates[0])) {
                // Create red icon
                const fireIcon = L.divIcon({
                    html: '<div style="font-size: 20px;">🔥</div>',
                    className: 'custom-div-icon',
                    iconSize: [20, 20],
                    iconAnchor: [10, 10]
                });

                L.marker(ev.coordinates, { icon: fireIcon })
                    .addTo(map)
                    .bindPopup(`<b>${ev.title}</b><br/>ID: ${ev.id}`);
            }
        });

    }, [eventData]);

    return <div id="mapid" ref={mapRef} style={{ height: '100vh', width: '100vw', background: '#e0f7fa' }}></div>;
}

Map.defaultProps = {
    center: [42.3265, -122.8756],
    zoom: 6
}

export default Map;