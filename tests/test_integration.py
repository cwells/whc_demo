import dash
from dash import html

from ..app import app


def test_meta_description(dash_duo):
    """ Check to see if the <meta description> element is present and valid. """
    
    el = "meta[name=description]:not([content=''])"

    dash_duo.start_server(app)
    dash_duo.wait_for_element_by_css_selector(el, timeout=10)

    assert dash_duo.find_element(el).get_attribute("content") == app.description
    assert dash_duo.get_logs() == [], "browser console should contain no error"

    dash_duo.percy_snapshot("test_meta_description-layout")