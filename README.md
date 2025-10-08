# Infraestructura - News API

Repositorio que contiene toda la infraestructura como código (IaC) necesaria para desplegar la **News API** en AWS.

Implementado con:
- **Terraform** (EKS, ECR, Security Groups, etc.)
- **GitHub Actions** (CI/CD para despliegue automatizado)
- **AWS Learner Lab** (entorno de prueba)

---

## Estructura del proyecto

````

infra-news-api/
│
├── main.tf               # Recursos principales (EKS, ECR, Security Groups)
├── providers.tf          # Configuración de proveedor AWS
├── variables.tf          # Variables del entorno
├── outputs.tf            # Outputs clave del despliegue
├── k8s/                  # Manifiestos de Kubernetes (deployment, service, namespace)
└── .github/workflows/    # Pipelines de CI/CD (deploy, destroy, deploy k8s)

````

---

## 🚀 Requisitos

- **Terraform >= 1.8.0**
- **AWS CLI** configurado con credenciales del Learner Lab
- **GitHub Actions secrets** configurados:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_SESSION_TOKEN`
  - `AWS_REGION`
  - `EKS_CLUSTER_NAME`

---

## Despliegue automático (CI/CD)

Los flujos de despliegue se ejecutan en GitHub Actions:

| Workflow | Descripción |
|-----------|--------------|
| **Deploy Infra** | Ejecuta `terraform init` y `terraform apply` para crear ECR, EKS y SGs |
| **Deploy K8s** | Aplica los manifiestos (`kubectl apply -f k8s/`) en el cluster |
| **Destroy Infra** | Limpia todos los recursos con `terraform destroy -auto-approve` |

Los estados de Terraform se almacenan en un bucket S3 remoto para mantener consistencia entre ejecuciones.

---

## Ejecución manual local

```
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
````

Para destruir la infraestructura:

```
terraform destroy -auto-approve
```

---

## Kubernetes

El directorio `k8s/` contiene los manifiestos necesarios para desplegar la aplicación:

```
k8s/
├── namespace.yaml
├── deployment.yaml
└── service.yaml
```

### Aplicar manualmente:

```
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Ver estado:

```bash
kubectl get pods -n news-api
kubectl get svc -n news-api
```

---

## 🔗 Integración con el backend

El repositorio `backend-news-api`:

* Construye y publica la imagen Docker en **ECR**.
* La imagen se referencia en los manifiestos Kubernetes dentro de este repo.
* Luego este repositorio ejecuta el despliegue en **EKS**.

---