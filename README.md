# El arsenal de un analista: Trivy

Trabajo de la actividad colaborativa del Módulo 6 (Vulnerabilidades) del Máster en Ciberseguridad.

He elegido Trivy porque con un solo binario puedes buscar CVE en paquetes y dependencias, secretos olvidados en el código, errores de configuración en Dockerfile o Terraform, y además generar un SBOM. Lo he probado en una VM de Kali con Trivy 0.76.1, contra aplicaciones hechas vulnerables a propósito (OWASP Juice Shop y NodeGoat) y unos ficheros de ejemplo que he escrito yo.

## Qué hay en el repositorio

- [docs/00-instalacion.md](docs/00-instalacion.md): instalación en Kali y preparación del laboratorio
- [docs/01-cheatsheet.md](docs/01-cheatsheet.md): comandos y flags con ejemplos reales
- [docs/02-flujo-trabajo.md](docs/02-flujo-trabajo.md): diagrama del análisis de principio a fin
- [docs/03-guia-incorporacion.md](docs/03-guia-incorporacion.md): cuándo usarlo, qué evitar y con qué combinarlo
- [docs/04-caso-practico.md](docs/04-caso-practico.md): el caso completo con Juice Shop
- [docs/05-limitaciones-alternativas.md](docs/05-limitaciones-alternativas.md): lo que Trivy no hace y qué usar en su lugar
- [examples/](examples/): ficheros de ejemplo (IaC de prueba, `.trivyignore`, workflow de CI, informe JSON y SBOM)
- [images/](images/): capturas, numeradas en el orden en que las hice

## Lo que me ha parecido más interesante

- Juice Shop trae 41 hallazgos HIGH/CRITICAL (11 críticos y 30 altos). Con `--ignore-unfixed` quedan 37, pero los otros 4 siguen ahí sin parche.
- Un CVSS de 9.1 no significa que haya que correr: el CVE-2019-10744 de lodash tiene un EPSS de solo el 5 %.
- Al ignorar un CVE con `.trivyignore` bajé de 11 a 9 críticos, no a 10, porque `jsonwebtoken` aparecía con dos versiones.
- Trivy no detectó la clave de ejemplo de AWS de la documentación (`AKIAIOSFODNN7EXAMPLE`). La excluye a propósito.
- Grype da 49 hallazgos HIGH/CRITICAL sobre la misma imagen y Trivy 41. No coinciden.

## Aviso

Todo se ha probado sobre laboratorios vulnerables a propósito. Las claves de ejemplo (`AKIA...`, `ghp_...`) son inventadas.
