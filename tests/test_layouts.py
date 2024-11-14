from dash.development.base_component import Component

from ..app import map_layout, import_dataframe, WHC_DATA


def recurse(lst, test):
    """ Recursively walk nested list, performing test on each item """

    for item in lst:
        if isinstance(item, list):
            recurse(item)
        else:
            yield test(item)


def test_map_layout():
    """ Ensure the map_layout returns one or more Components """

    df = import_dataframe(WHC_DATA)
    layout = map_layout(df, lang="en")

    assert len(layout)
    assert all(recurse(layout, test=lambda i: isinstance(i, Component)))