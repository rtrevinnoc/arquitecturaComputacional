# Arquitectura Computacional — sumadores

## Instalación

```bash
pip install siliconcompiler
```

### Verilator + Surfer

**Linux (Ubuntu/Debian):**

```bash
sc-install -group digital-simulation
```

**macOS:**

```bash
brew install verilator
```

Surfer: <https://surfer-project.org>

**Windows:**

Instalar WSL: <https://learn.microsoft.com/windows/wsl/install>

Dentro de WSL (Ubuntu), seguir las instrucciones de Linux de arriba
(`pip install siliconcompiler` + `sc-install -group digital-simulation`).

Surfer (nativo, sin WSL): <https://gitlab.com/api/v4/projects/42073614/jobs/artifacts/main/raw/surfer_win.zip?job=windows_build>

Si ya tienen Surfer instalado, `make view` abre la onda incluida sin
necesidad de WSL.

Verificar instalación (dentro de WSL):

```bash
verilator --version
surfer --version
```

## Ejecutar

```bash
python3 sc_run.py
python3 sc_run.py --wave
python3 sc_run.py --view
```

Alternativa con Verilator directo:

```bash
make adders
make wave-adders
make view
make clean
```
