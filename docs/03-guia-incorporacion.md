# Guía rápida para quien se incorpora al equipo

## Cuándo usar Trivy

Sirve para:
- Revisar una imagen de contenedor antes de desplegarla (SO, librerías y secretos en una pasada).
- Mirar las dependencias de un repositorio (`trivy fs` lee `package-lock.json`, `pom.xml`, `requirements.txt`...).
- Revisar Dockerfile, Terraform o manifiestos de Kubernetes en una pull request.
- Comprobar un SBOM que nos da un proveedor.
- Volver a escanear lo que ya está desplegado, porque salen CVE nuevos aunque el código no cambie.

No sirve para:
- Probar una aplicación web en ejecución (XSS, SQLi, autenticación). Es análisis estático, para eso hay que usar un escáner dinámico como Nuclei, ZAP o Burp.
- Encontrar fallos nuevos en nuestro propio código. Solo conoce CVE publicados, para eso hace falta SAST (Semgrep, CodeQL) o revisión manual.
- Escanear una red o puertos abiertos (Nmap, OpenVAS).

## Qué evitar

- Ignorar un CVE porque molesta. Un `.trivyignore` sin comentario se olvida. Además actúa por ID: ignorar `CVE-2015-9235` me quitó 2 hallazgos porque `jsonwebtoken` estaba con dos versiones.
- Fiarse de `--ignore-unfixed` para decir que está limpio. Solo oculta lo que no tiene parche.
- Fiarse de un "0 vulnerabilidades". En la tabla `-` significa *not scanned* y `0` significa *clean*, no es lo mismo.
- Probar los secretos con la clave de ejemplo de AWS (`AKIAIOSFODNN7EXAMPLE`). Trivy la excluye y parece que no funciona.
- Pegar la tabla entera en el informe. Con cientos de filas a 0 no se lee. Mejor resumir con `jq`.
- Olvidar poner la fecha y la versión de Trivy en el informe.

## Con qué combinarlo

- **jq**: para resumir el JSON ([cheatsheet](01-cheatsheet.md)).
- **NVD y EPSS**: CVSS dice lo grave que es técnicamente y EPSS la probabilidad de que se explote ([caso práctico](04-caso-practico.md)).
- **GitHub Actions con SARIF**: los hallazgos salen en la pestaña Security ([workflow](../examples/ci/.github/workflows/trivy.yml)).
- **Grype**: como segunda opinión, usa otra base de datos ([comparación](05-limitaciones-alternativas.md)).
- **Nuclei o ZAP**: Trivy mira dentro de la imagen y ellos miran el servicio en marcha.
- **Dependabot o Renovate**: para automatizar la corrección una vez priorizada.

## Los cinco comandos para un escaneo nuevo

```bash
trivy --version
trivy image -q --format json -o informe.json IMAGEN
jq -r '[.Results[].Vulnerabilities[]?.Severity]|group_by(.)|map("\(.[0]): \(length)")|.[]' informe.json
jq -r '.Results[]|select(.Secrets)|.Target+" -> "+(.Secrets[].Title)' informe.json
trivy image -q --severity HIGH,CRITICAL --ignore-unfixed IMAGEN
```
