# Cheatsheet de Trivy

Forma general: `trivy <objetivo> [flags] <destino>`

| Objetivo | Qué escanea | Ejemplo |
|---|---|---|
| `image` | Imagen de contenedor | `trivy image nginx:1.25` |
| `fs` | Un directorio | `trivy fs .` |
| `repo` | Un repositorio git remoto | `trivy repo https://github.com/OWASP/NodeGoat` |
| `config` | Solo IaC (Dockerfile, Terraform, K8s) | `trivy config .` |
| `sbom` | Un SBOM ya generado | `trivy sbom sbom.cdx.json` |
| `k8s` | Un clúster Kubernetes | `trivy k8s --report summary cluster` |

## Escaneo y filtrado

```bash
trivy image bkimminich/juice-shop
trivy image --severity HIGH,CRITICAL bkimminich/juice-shop
trivy image --severity HIGH,CRITICAL --ignore-unfixed bkimminich/juice-shop
```

`--ignore-unfixed` esconde los CVE que todavía no tienen versión corregida. Sirve para ver lo que se puede arreglar hoy, pero esos CVE siguen existiendo.

![Con y sin --ignore-unfixed](../images/06-resumen-severidad-all-vs-fixed.png)

| | CRITICAL | HIGH |
|---|---|---|
| Sin filtro | 11 | 30 |
| Con `--ignore-unfixed` | 8 | 29 |

## Qué analizar (`--scanners`)

```bash
trivy image --scanners vuln bkimminich/juice-shop          # solo CVE, más rápido
trivy fs --scanners secret .                               # solo secretos
trivy fs --scanners vuln,secret,misconfig .                # todo
```

El log de Trivy avisa de que si el escaneo va lento se pruebe con `--scanners vuln`, porque la búsqueda de secretos es lo que más tarda.

## Formatos de salida

```bash
trivy image -q --format json -o informe.json IMAGEN
trivy image -q --format sarif -o informe.sarif IMAGEN
trivy image -q --format cyclonedx -o sbom.cdx.json IMAGEN
```

`-q` quita los mensajes INFO. Con `-o` no sale nada por pantalla porque todo va al fichero (me despistó la primera vez).

La tabla por defecto, en una imagen con cientos de `package.json`, se llena de filas con 0 y es difícil de leer. Lo que me funcionó fue sacar el JSON y filtrarlo con `jq`.

## Recetas con jq

```bash
# recuento por severidad
jq -r '[.Results[].Vulnerabilities[]?.Severity] | group_by(.) | map("\(.[0]): \(length)") | .[]' informe.json

# CVE críticos con paquete y versión que lo corrige
jq -r '.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL") | "\(.VulnerabilityID)  \(.PkgName)  \(.InstalledVersion) -> \(.FixedVersion // "sin parche")"' informe.json | sort -u

# secretos y dónde están
jq -r '.Results[] | select(.Secrets) | .Target + " -> " + (.Secrets[].Title)' informe.json
```

![CVE críticos y secretos con jq](../images/08-cves-criticos-jq.png)

## Misconfiguraciones (IaC)

```bash
trivy config .
trivy config -q --severity HIGH Dockerfile
```

Lo probé con los ficheros de [examples/iac](../examples/iac):

![Resumen](../images/10-config-resumen.png)
![Detalle de USER root](../images/11-config-dockerfile-detalle.png)

El `Dockerfile` da 5 fallos (`USER root`, el puerto 22 expuesto, `ADD` en vez de `COPY`...) y el `main.tf` da 9, casi todos por lo mismo: un bucket S3 con `acl = "public-read"` y sin bloqueo de acceso público.

## Secretos

```bash
trivy fs --scanners secret .
```

![Secretos en config.py](../images/12-secretos-config-py.png)

Trivy enmascara el valor con asteriscos en el informe. Ojo: con la clave de ejemplo de la documentación de AWS (`AKIAIOSFODNN7EXAMPLE`) no encontró nada, porque la tiene excluida. Con una cadena de formato válido pero sin la palabra `EXAMPLE` sí saltó.

## SBOM

```bash
trivy image -q --format cyclonedx -o sbom.cdx.json IMAGEN
trivy sbom -q --severity HIGH,CRITICAL sbom.cdx.json
```

![Generar y escanear el SBOM](../images/13-sbom-cyclonedx.png)

Al escanear el SBOM salen los mismos números que con la imagen (11 CRITICAL y 30 HIGH):

![Resumen del SBOM](../images/14-sbom-resumen-severidad.png)

## Falsos positivos

```bash
echo "CVE-2015-9235" > .trivyignore
```

![Antes y después de .trivyignore](../images/16-trivyignore-antes-despues.png)

También hay formato YAML, que permite poner motivo, ruta y fecha de caducidad: [examples/.trivyignore.yaml](../examples/.trivyignore.yaml).

## Otros flags útiles

| Flag | Para qué |
|---|---|
| `--skip-dirs DIR` / `--skip-files FILE` | Saltarse rutas |
| `--exit-code 1` | Que falle si hay hallazgos (CI) |
| `--skip-db-update` | No actualizar la base de datos |
| `--list-all-pkgs` | Incluir todos los paquetes en el JSON |
| `--dependency-tree` | Ver de qué dependencia directa viene una vulnerable |
| `--config trivy.yaml` | Cargar los flags desde un fichero ([ejemplo](../examples/trivy.yaml)) |

No he probado todos estos flags, están sacados de la ayuda y la documentación de Trivy.
