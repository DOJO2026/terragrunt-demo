# Demo: Terraform → Terragrunt

Esta demo toma una porción controlada del proyecto actual (**Resource Group + App
Service**, sin SQL para mantenerlo simple) y la reorganiza con Terragrunt en
dos ambientes: `dev` y `qa`.

## Cómo correrla en GitHub Codespaces

1. Instalar Terragrunt en el Codespace (agregar al `Dockerfile` o `devcontainer.json`,
   ver sección más abajo). Verificar con:
   ```bash
   terragrunt --version
   ```

2. Exportar las variables sensibles como variables de entorno (igual que hoy
   usan `TF_VAR_*` en GitHub Actions):
   ```bash
   export TF_VAR_client_id="..."
   export TF_VAR_client_secret="..."
   export TF_VAR_tenant_id="..."
   export TF_VAR_subscription_id="..."
   ```

3. Ajustar en `terragrunt.hcl` (root) el `storage_account_name` del backend
   por uno real que exista en su suscripción (o comentar el bloque
   `remote_state` y usar backend local solo para la demo).

4. Aplicar UN módulo puntual:
   ```bash
   cd environments/dev/resource_group
   terragrunt plan
   ```

5. Aplicar TODO el ambiente dev de una sola vez (Terragrunt resuelve el
   orden usando los `dependency` blocks):
   ```bash
   cd environments/dev
   terragrunt run-all plan
   terragrunt run-all apply
   ```

6. Repetir para `qa` — noten que **no se copió ni una línea de código
   Terraform**, solo un `terragrunt.hcl` de ~15 líneas con los valores que
   cambian por ambiente.

## Qué comparar en la sesión

| Aspecto | Terraform actual (main.tf) | Con Terragrunt |
|---|---|---|
| Archivos por ambiente nuevo | Habría que duplicar todo `main.tf`/`variables.tf` | Solo 2 `terragrunt.hcl` (~15-20 líneas c/u) |
| Backend remoto | No configurado | Centralizado en el root, generado automático |
| Bloque provider | 1 vez (todo en un archivo) | Generado automático en cada módulo, sin copiar/pegar |
| Orden de creación (RG antes que App Service) | Implícito por referencias `azurerm_resource_group.rg.name` en el mismo archivo | Explícito vía `dependency` block, funciona incluso separado en carpetas distintas |
| Aplicar todo un ambiente | `terraform apply` (un solo state) | `terragrunt run-all apply` (orquesta múltiples módulos/states) |
| Curva de aprendizaje | La de Terraform | Terraform + sintaxis/convenciones propias de Terragrunt |
| Herramientas extra en CI/CD y Codespaces | Solo `terraform` | Instalar y mantener también el binario `terragrunt` |
| Beneficio real hoy (1 solo ambiente) | — | Limitado: el ahorro se nota cuando hay 2+ ambientes o módulos repetidos |

## Bootstrap del backend remoto (`bootstrap/` + workflow dedicado)

Problema clásico de "huevo y gallina": Terragrunt necesita un Storage Account
para guardar el state, pero no se puede crear ese Storage Account *con*
Terraform si ese mismo Terraform ya intenta usarlo como backend remoto.

`bootstrap/` es una carpeta de Terraform **aparte**, con backend **local**
(no usa el backend remoto que ella misma va a crear), pensada para correrse
**una sola vez**. Se ejecuta a través de un workflow dedicado —
**no manualmente en tu terminal** — para que quede todo el aprovisionamiento
dentro de GitHub Actions:

`.github/workflows/bootstrap.yaml` (disparo manual, `workflow_dispatch`):

1. Corre `terraform init/plan/apply` sobre `bootstrap/`, usando los mismos
   4 secrets (`AZURE_CLIENT_ID`, etc.) que ya configuraste.
2. Como los runners de Actions son efímeros, el `.tfstate` de esa carpeta
   **se guarda como artifact** del workflow (`bootstrap-tfstate`) al
   terminar, y se intenta recuperar al inicio de la próxima corrida — así,
   si necesitas volver a correr el bootstrap, no intenta recrear recursos
   que ya existen.
3. Al final imprime en el **resumen del job** (pestaña Actions → el run →
   Summary) el bloque exacto para pegar en el `remote_state.config` del
   `terragrunt.hcl` raíz.

**Cómo correrlo:**
- Repo → pestaña **Actions** → workflow **"Bootstrap - Backend remoto
  Terragrunt"** → **Run workflow**
- Ingresa un `storage_account_name` único (solo minúsculas/números, 3-24
  caracteres) — los nombres de Storage Account son globales en todo Azure,
  así que no puede ser un valor fijo genérico.
- Espera a que termine, abre el **Summary** del run, copia el bloque de
  salida al `terragrunt.hcl` raíz, haz commit y push.

Este workflow se corre **una sola vez** por proyecto (o cada vez que se
quiera recrear el backend desde cero) — no forma parte del flujo normal de
`plan`/`apply` de la infraestructura de aplicación.

## Pipeline CI/CD (`.github/workflows/terragrunt-apply.yaml`)

Equivalente al `apply.yaml` actual del proyecto, pero adaptado a Terragrunt:

- **`plan`**: corre siempre (push a `main` o disparo manual), en **matrix** para
  `dev` y `qa` en paralelo. Es solo preview, no toca infraestructura.
- **`apply`**: **solo manual** (`workflow_dispatch`), pidiendo elegir el
  ambiente (`dev`/`qa`) y confirmando la acción. Usa `environment:` de GitHub
  para poder configurar un *approval* manual antes de aplicar si lo desean
  (Settings → Environments → Required reviewers).

Diferencias clave frente al `apply.yaml` original:

| `apply.yaml` (Terraform actual) | `terragrunt-apply.yaml` (esta demo) |
|---|---|
| `terraform init/plan/apply` | `terragrunt run-all plan` / `run-all apply` (orquesta módulos + dependencias automáticamente) |
| Un solo ambiente, auto-approve en cada push a main | Plan automático, pero apply manual con selección de ambiente |
| Sin paso de instalación extra | Requiere instalar el binario de `terragrunt` (paso `curl` en el workflow) |

Para probarlo: en el repo de GitHub, pestaña **Actions** → seleccionar el
workflow → **Run workflow** → elegir ambiente y acción (`plan` o `apply`).

Nota: sigue usando autenticación por `ARM_CLIENT_SECRET` (igual que el
`apply.yaml` original), no OIDC federado — el `federated-main.json` que
tienen configurado apunta al repo `ProyectoCloudComputing`, no a este repo
de demo, así que si más adelante quieren usar OIDC aquí también, habría que
crear una credencial federada nueva apuntando a `jgonzaloDev/terragrunt-demo`.

## Limitaciones / puntos a discutir

- **El proyecto actual solo tiene un ambiente.** Terragrunt reduce
  repetición *entre* ambientes o módulos parecidos; con un único ambiente
  como hoy, el beneficio inmediato es menor — el ahorro se proyecta a
  futuro (cuando aparezca `qa`/`staging`/`prod`).
- **Capa de abstracción adicional.** Cada carpeta necesita su propio
  `terragrunt.hcl`, y hay que aprender su sintaxis (`include`, `dependency`,
  `generate`, `mock_outputs`) además de HCL de Terraform.
- **Un binario más que mantener** en el `Dockerfile`/devcontainer y en el
  workflow de GitHub Actions (`apply.yaml` tendría que cambiar `terraform`
  por `terragrunt` en los pasos de init/plan/apply).
- **Backend remoto es un prerequisito real**, no solo de la demo: hoy no
  existe (`.tfstate` local, según el `.gitignore`), así que antes de usar
  Terragrunt en serio habría que crear el Storage Account para el state.
- **Soporte de editor/IDE** para `.hcl` de Terragrunt es más limitado que
  el de `.tf` puro.
