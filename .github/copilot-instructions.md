# Copilot Instructions for Gradio Assistant

## Project Overview
- **Gradio Assistant** is an AI assistant with both web (Gradio) and CLI interfaces, powered by Azure AI Foundry and OpenAI GPT-4o.
- Infrastructure is managed via Terraform in `foundry/` (sometimes referenced as `infra/` in docs).
- The app is designed for secure, private deployment using Azure networking, Key Vault, and private endpoints.

## Key Components
- `app/gradio-app-ui.py`: Web UI (Gradio-based)
- `app/gradio-app-cli.py`: Command-line interface
- `app/requirements.txt`: Python dependencies
- `foundry/ai-foundry.tf`: Main Terraform for AI Foundry, model deployments, networking, and security
- `foundry/keyvault.tf`: Key Vault and encryption resources
- `foundry/dev.tfvars`: Environment-specific variables

## Developer Workflows
- **Infrastructure:**
  - Deploy: `cd foundry/ && terraform init && terraform apply -var-file=dev.tfvars`
  - Destroy: `terraform destroy -var-file=dev.tfvars`
- **App:**
  - Install: `cd app/ && pip install -r requirements.txt`
  - Run Web UI: `./gradio-app-ui.py` (launches browser)
  - Run CLI: `./gradio-app-cli.py`
  - Set API key: `export AI_FOUNDRY_KEY=...`

## Patterns & Conventions
- **Environment variables** are used for secrets (never hardcode keys).
- **Terraform**: Uses `azapi_resource` for custom Azure resources and updates, with explicit role assignments for Key Vault access.
- **Networking**: All AI endpoints are private; public access is disabled by default.
- **Model deployments**: Managed in `ai-foundry.tf` as `azapi_resource` blocks.
- **Error handling**: Both UI and CLI handle API, connection, and streaming errors with user-friendly messages.
- **Python**: Follows standard Gradio and Azure OpenAI SDK usage; streaming responses use a 0.03s delay for smooth UX.

## Integration Points
- **Azure OpenAI**: Endpoint, model, and API version are set in code; see `Configuration` in README.
- **Key Vault**: Encryption keys are referenced in Terraform and require role assignments for access.
- **Private DNS/Endpoints**: Managed in Terraform for secure, internal-only access.

## Examples
- To add a new model deployment, copy the `azapi_resource` block for `model_deployment` in `ai-foundry.tf`.
- To extend the CLI, modify the `main()` function in `gradio-app-cli.py`.

## References
- See `readme.md` for architecture, setup, and troubleshooting.
- See `assets/ai-foundry-architecture.png` for a visual overview.

---
For questions about project-specific patterns, check the README or existing Terraform and Python files for examples.
