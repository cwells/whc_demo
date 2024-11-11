window.dashExtensions = Object.assign({}, window.dashExtensions, {
    default: {
        function0: function(feature, latlng) {
            const markerBaseUrl = "https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-"
            const category = feature.properties.category
            const palette = {
                "Natural": "red",
                "Cultural": "blue",
                "Mixed": "violet",
            }
            const icon = L.icon({
                iconUrl: `${markerBaseUrl}${palette[category]}.png`
            })

            return L.marker(latlng, {
                icon: icon
            })
        }

    }
});