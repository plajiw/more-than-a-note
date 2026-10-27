"""Create an isolated E2 notebook profile under an explicit XDG data root.

Usage: python3 tests/fixtures/make_e2_fixture.py /tmp/mtn-e2-data
Then launch the app with XDG_DATA_HOME=/tmp/mtn-e2-data.
"""

import pathlib
import sqlite3
import sys
import uuid


def identifier():
    return str(uuid.uuid4())


def make_notebook(root, title, sections):
    notebook_id = identifier()
    directory = root / "more-than-a-note" / "more-than-a-note" / "notebooks" / notebook_id
    directory.mkdir(parents=True, exist_ok=False)
    connection = sqlite3.connect(directory / "notebook.sqlite")
    try:
        connection.executescript(
            """
            PRAGMA foreign_keys = ON;
            PRAGMA user_version = 1;
            CREATE TABLE notebook (id TEXT PRIMARY KEY, title TEXT NOT NULL, last_section TEXT, last_page TEXT);
            CREATE TABLE sections (id TEXT PRIMARY KEY, title TEXT NOT NULL, color TEXT NOT NULL, position INTEGER NOT NULL);
            CREATE TABLE pages (id TEXT PRIMARY KEY, section_id TEXT NOT NULL REFERENCES sections(id), title TEXT NOT NULL, position INTEGER NOT NULL);
            """
        )
        connection.execute("INSERT INTO notebook (id, title) VALUES (?, ?)", (notebook_id, title))
        for section_position, (section_title, pages) in enumerate(sections):
            section_id = identifier()
            connection.execute(
                "INSERT INTO sections VALUES (?, ?, ?, ?)",
                (section_id, section_title, "#C58E61", section_position),
            )
            for page_position, page_title in enumerate(pages):
                connection.execute(
                    "INSERT INTO pages VALUES (?, ?, ?, ?)",
                    (identifier(), section_id, page_title, page_position),
                )
        connection.commit()
    finally:
        connection.close()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: make_e2_fixture.py XDG_DATA_HOME")
    data_root = pathlib.Path(sys.argv[1]).resolve()
    make_notebook(data_root, "Caderno E2", [
        ("Aulas", ["Página 1", "Página com um título bem longo para testar navegação e anúncio"]),
        ("Seção sem páginas", []),
    ])
    make_notebook(data_root, "Caderno vazio", [])
    print(data_root)
