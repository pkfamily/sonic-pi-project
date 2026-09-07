# REAPER MCP setup and troubleshooting

This documents the macOS setup used to connect Codex to REAPER for the
Aerodynamic stem-mixing workflow.

## Working versions and locations

- REAPER: 7.79, Apple Silicon/macOS universal application
- Python: Homebrew Python 3.12
- REAPER MCP fork: <https://github.com/pkfamily/reaper-mcp>
- Compatibility branch: `fix-reaper-api-compatibility`
- Compatibility commit: `68f995d5372ddcb8e7b60bfc4d94d4c9495cf006`
- Local checkout: `/Users/poonv/Downloads/Repos/reaper-mcp`
- MCP virtual environment: `/Users/poonv/Downloads/Repos/reaper-mcp/venv`

The compatibility branch fixes project time-signature handling, explicit
project saving, and native REAPER track volume, pan, mute, and solo access.
It has been pushed to the fork and submitted upstream as a pull request.

## Install the server

Clone the fork and install it into an isolated Python environment. Python 3.12
is recommended for the setup because the installed `python-reapy` release has
configuration problems under Python 3.14.

```sh
cd /Users/poonv/Downloads/Repos
git clone git@github.com:pkfamily/reaper-mcp.git
cd reaper-mcp
git switch fix-reaper-api-compatibility
/opt/homebrew/opt/python@3.12/bin/python3.12 -m venv venv
venv/bin/python -m pip install -e .
```

The server command is:

```text
/Users/poonv/Downloads/Repos/reaper-mcp/venv/bin/reaper-mcp-server
```

## Configure Python in REAPER

In REAPER, open **REAPER → Preferences → Plug-ins → ReaScript** and enable
Python. For the Homebrew Python 3.12 framework, use:

```text
Custom path to Python dylib directory:
/opt/homebrew/opt/python@3.12/Frameworks/Python.framework/Versions/3.12/lib

Force ReaScript to use specific Python dylib:
libpython3.12.dylib
```

The first field is a directory; the second is the dylib filename. Do not put
the full dylib path in both fields. Restart REAPER after it reports that
Python is installed.

## Enable the distant API

The repository's `scripts/enable_reapy.py` assumes that `reapy` is installed in
REAPER's embedded Python. A separate MCP virtual environment does not make
that module available inside REAPER, so running the script can fail with:

```text
ModuleNotFoundError: No module named 'reapy'
```

With REAPER closed, configure the API from the MCP environment instead. The
following command enables Python, adds the HTTP interface on port `2307`,
registers the activation script, and stores its action ID:

```sh
cd /Users/poonv/Downloads/Repos/reaper-mcp
venv/bin/python -c 'from reapy.config.resource_path import get_resource_path; from reapy.config.config import enable_python, add_web_interface, add_reascript, set_ext_state, get_activate_reapy_server_path; p=get_resource_path(detect_portable_install=False); enable_python(p); add_web_interface(p); a=add_reascript(p,get_activate_reapy_server_path()); set_ext_state("reapy","activate_reapy_server",a,p); print("configured",p,a)'
```

Launch or restart REAPER after this command. Verify the connection with:

```sh
venv/bin/python -c 'import reapy; print(reapy.get_projects())'
```

## Register it with Codex

```sh
codex mcp add reaper -- \
  /Users/poonv/Downloads/Repos/reaper-mcp/venv/bin/reaper-mcp-server
codex mcp get reaper
```

Restart Codex or open a new Codex session after registering a new server. A
read-only first test is to ask Codex to list the current REAPER tracks.

## Import the Aerodynamic stems

The V10 stem workflow produces seven aligned WAV files under
`renders/aerodynamic_v10/`. A safe import sequence is:

1. Create a 120 BPM, 4/4 REAPER project.
2. Create one audio track for each profile: `full`, `drums`, `bass`, `lead`,
   `melody`, `harmony`, and `fx`.
3. Import every WAV at position `0.0` seconds.
4. Keep `full` muted as a reference.
5. Save the project as `renders/aerodynamic_v10/aerodynamic_v10_reaper_mix.rpp`.

The current saved project follows this layout and has seven 210-second items.

## Troubleshooting history

### Python scripts are not selectable

Python must be enabled under **Preferences → Plug-ins → ReaScript** before
`.py` files appear in **Actions → New action → Load ReaScript**. The custom
directory must point to the directory containing `libpython3.12.dylib`, not to
the `Python` framework binary itself.

### `enable_reapy.py` cannot import `reapy`

This is an environment-boundary issue, not a failed Python installation.
REAPER's embedded Python and the MCP server's virtual environment are
separate. Use the external API-configuration command above.

### `configure_reaper()` fails or truncates `reaper.ini`

The `python-reapy 0.10.0` configuration helper was not reliable with this
REAPER/Python combination. It raised a Python 3.14 `configparser` error and a
second attempt left `reaper.ini` empty. Before retrying any configuration
helper:

1. Quit REAPER completely.
2. Check for `reaper.ini.bak` or `reaper.ini.before-reapy.bak`.
3. Restore a known-good backup if necessary.
4. Apply the individual configuration steps while REAPER is closed.
5. Relaunch REAPER and verify the API before starting Codex.

### MCP tool errors on projects and tracks

The original server used reapy properties that are not available in the
installed REAPER API wrapper. The fork branch replaces them with native API
calls. If the branch is not installed, errors may include:

- read-only `Project.time_signature`
- invalid argument errors from `save_project`
- missing `Track.volume` or `Track.pan` attributes

Use the fork branch until the upstream pull request is merged.
