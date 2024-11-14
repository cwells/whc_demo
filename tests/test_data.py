from ..app import import_dataframe, WHC_DATA, ALL_LANGUAGES


def test_import_dataframe():
    """ Ensure we have the minimum required column headers in the CSV """

    df = import_dataframe(WHC_DATA)

    needs = {
        "id_no",
        "name_en",
        "name_fr",
        "name_es",
        "name_ru",
        "name_ar",
        "name_zh",
        "short_description_en",
        "short_description_fr",
        "short_description_es",
        "short_description_ru",
        "short_description_ar",
        "short_description_zh",
        "date_inscribed",
        "longitude",
        "latitude",
        "area_hectares",
        "category",
        "category_short",
        "states_name_en",
        "states_name_fr",
        "states_name_es",
        "states_name_ru",
        "states_name_ar",
        "states_name_zh",
        "region_en",
        "region_fr",
        "iso_code",
        "udnp_code",
    }

    has = set(df.columns.tolist())

    assert len(needs - has) == 0

def test_for_null_values_in_descriptions_and_names():
    """ Ensure descriptions and names have values """

    df = import_dataframe(WHC_DATA)

    for lang in ALL_LANGUAGES:
        for col in "short_description", "name":
            assert df[f"{col}_{lang}"].all()

