# more-than-a-note

more-than-a-note is the working name for a desktop notebook for students and teachers, planned to be free and open source. It aims to combine movable text, handwriting, images and diagrams on pages organized into notebooks and sections. The product is planned to work offline, with local files and export options.

## Building

See [BUILDING.md](BUILDING.md) for step-by-step instructions on Windows, Linux
and macOS, packaging and troubleshooting.

Quick start on Windows with MSYS2 (PowerShell, from the repository root):

```powershell
$env:PATH = "C:\msys64\ucrt64\bin;$env:PATH"      # once per terminal
cmake --preset release                             # first time, or after adding files
cmake --build --preset release                     # compile what changed
cmake --install build/release --prefix build/dist  # refresh the runnable folder
& ".\build\dist\bin\more_than_a_note.exe"            # add --gallery for the visual gallery
```

## Documentation

Product and technical documents are in [docs/](docs/README.md).
