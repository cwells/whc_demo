from contextvars import copy_context
from dash._callback_context import context_value
from dash._utils import AttributeDict

from ..app import update_map_layout


def test_update_map_layout_callback():
    """ Test the update_map_layout callback """

    def run_callback():
        context_value.set(AttributeDict(**{"triggered_inputs": [{"url": "search"}]}))
        return update_map_layout("en")

    ctx = copy_context()
    output = ctx.run(run_callback)
    
    assert isinstance(output, list)
    