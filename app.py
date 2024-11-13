import os
from functools import partial

from apig_wsgi import make_lambda_handler

# import awsgi
import dash_bootstrap_components as dbc
import dash_leaflet as dl
import dash_leaflet.express as dlx
import flask
import pandas as pd
from dash import Dash, dcc, html, Input, Output, register_page
from dash.development.base_component import Component
from dash_extensions import javascript
from prometheus_client import Gauge, make_wsgi_app, Summary
from werkzeug.middleware.dispatcher import DispatcherMiddleware
from yarl import URL


STAGE = os.environ.get("STAGE", "dev")
DEBUG = os.environ.get("DEBUG", False)
WHC_DATA = os.environ.get("WHC_DATA", "data/whc-sites.csv")
ALL_LANGUAGES = {
    "en": "English",
    "fr": "Français",
    "es": "Español",
    "ru": "Русский",
    "ar": "اَلْعَرَبِيَّةُ",
    "zh": "中文",
}
DEFAULT_LANGUAGE = os.environ.get("LANGUAGE", "en")
PIN_COLORS = {"Mixed": "#00F", "Natural": "#0F0", "Cultural": "#F00"}
WHC_LINK = "https://whc.unesco.org/en/list"
WHC_IMG_PREFIX = "https://whc.unesco.org/uploads/sites/site_"
MARKER_IMG_PREFIX = "https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-"

# Prometheus metrics
request_metrics = Summary("request_processing_seconds", "Time spent processing request")
data_metrics = Gauge("import_processing_seconds", "Time spent importing data")

map_pins = javascript.assign(
    """
    function(feature, latlng) {
        const markerBaseUrl = "%s"
        const category = feature.properties.category
        const palette = {
            "Natural": "red",
            "Cultural": "blue",
            "Mixed": "violet",
        }
        const icon = L.icon({
            iconUrl: `${markerBaseUrl}${palette[category]}.png`
        })

        return L.marker(latlng, {icon: icon})
    }
    """
    % MARKER_IMG_PREFIX,
)


def popup_layout(id_no: int, title: str, text: str, category: str) -> str:
    """Layout for the site popup."""

    palette = {
        "Natural": "red",
        "Cultural": "blue",
        "Mixed": "violet",
    }

    layout = f"""
        <div class="container popup">
            <div class="row justify-content-start">
                <div class="col-12">
                    <h5>{title}</h5>
                    <span style="float: left; margin: 0.75rem 0.5rem 0 0;">
                        <img src='{WHC_IMG_PREFIX}{id_no}.jpg'>
                    </span>
                    <p>{text}</p>
                </div>
            </div>
            <div class="row">
                <div class="col-4">
                    <span class="badge rounded-pill badge-{palette[category]}">{category}</span>
                </div> 
                <div class="col-8">
                    <a href='{WHC_LINK}/{id_no}' target='_new'>
                        View on the UNESCO website
                    </a>
                </div>
            </div>
        </div>
    """

    return layout


@data_metrics.time()
def import_dataframe(filename: str, lang: str = DEFAULT_LANGUAGE) -> pd.DataFrame:
    """Import CSV into Dataframe. Format short_description."""

    df = pd.read_csv(filename, header=0, index_col=0, encoding="utf-8")
    df["lat"] = df["latitude"]
    df["lon"] = df["longitude"]

    return df


@request_metrics.time()
def map_layout(df: pd.DataFrame, lang: str) -> Component:
    """Generates the primary map layout."""

    df["popup"] = df.apply(  # update popups with language
        lambda o: popup_layout(
            id_no=o["id_no"],
            title=o[f"name_{lang}"],
            text=o[f"short_description_{lang}"],
            category=o["category"],
        ),
        axis=1,
    )
    sites = dlx.dicts_to_geojson(df.to_dict("records"))
    map_container = dl.MapContainer(
        id="map",
        center=[39, -98],
        zoom=4,
        zoomControl=True,
        minZoom=2,
        boxZoom=True,
        worldCopyJump=True,
        children=[
            dl.TileLayer(),
            dl.LocateControl(locateOptions={"enableHighAccuracy": True}),
            dl.GeoJSON(
                data=sites,
                id="sites",
                cluster=True,
                superClusterOptions={"radius": 50},
                zoomToBoundsOnClick=True,
                pointToLayer=map_pins,
            ),
        ],
        style={"height": "86vh"},
    )

    return [
        dbc.Row(
            [
                dbc.Col(md=1),
                dbc.Col(
                    html.H5("UNESCO World Heritage Sites", style={"padding": "1rem"}),
                    md=3,
                ),
                dbc.Col(
                    dbc.Nav(
                        [
                            dbc.NavLink(
                                dbc.NavLink(l, href=f"/?lang={c}", external_link=True)
                            )
                            for c, l in ALL_LANGUAGES.items()
                        ]
                    ),
                ),
            ],
        ),
        dbc.Row(
            [
                dbc.Col(md=1),
                dbc.Col(map_container, md=10),
            ]
        ),
    ]


def main_layout(df, lang=DEFAULT_LANGUAGE, *args, **kwargs) -> list:
    """Generates global layout."""

    return [
        dcc.Location(id="url", refresh=False),
        html.Div(map_layout(df, lang), id="map_layout"),
    ]


def application(*args, **kwargs) -> Dash:
    """Generate the Dash app."""

    desc = "WHC Demo App"
    df = import_dataframe(WHC_DATA)

    server = flask.Flask(__name__)
    server.wsgi_app = DispatcherMiddleware(
        server.wsgi_app,
        {
            f"/metrics": make_wsgi_app(),  # prometheus endpoint
        },
    )
    app = Dash(
        server=server,
        external_stylesheets=[dbc.themes.BOOTSTRAP],
        use_pages=True,
        pages_folder="",
        suppress_callback_exceptions=True,  # necessary for generated components
        serve_locally=True,
        meta_tags=[
            {"name": "description", "content": desc}
        ],
    )

    register_page(
        "home",
        path=f"/",
        layout=partial(main_layout, df),
        meta_tags=[
            {"name": "description", "content": desc}
        ],
    )

    app.dataframe = df
    app.description = desc

    return app


app = application()


@app.callback(
    Output("map_layout", "children"),
    Input("url", "search"),
    prevent_initial_call=True,
)
def update_map_layout(search):
    url = URL(search)
    lang = url.query.get("lang", DEFAULT_LANGUAGE)
    return map_layout(app.dataframe, lang=lang)


if __name__ == "__main__":
    app.run_server(host="0.0.0.0", port=8000, debug=DEBUG, use_reloader=DEBUG)
