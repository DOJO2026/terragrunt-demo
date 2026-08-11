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
