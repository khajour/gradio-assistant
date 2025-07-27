# Gradio Assistant

An AI assistant application with both command-line and web interfaces, powered by Azure AI Foundry and Azure OpenAI's GPT-4o model Gradio.

<img src="assets/screen-001.png" alt="Gradio Assistant Web UI Screenshot" width="300">

## Overview

This project provides two interfaces for interacting with an AI assistant:

1. **gradio-app-ui.py** - Web-based chat interface using Gradio
2. **gradio-app-cli.py** - Command-line interface for direct API interaction

 
## Requirements

- Python 3.7+
- Azure OpenAI subscription and API key
- Required Python packages (see requirements.txt)

## Installation

1. Clone or download this repository
2. Install the required dependencies:

```bash
pip install -r requirements.txt
```

3. Set up your Azure OpenAI API key as an environment variable:

```bash
export AI_FOUNDRY_KEY="your_azure_openai_api_key_here"
```

## Usage

### Web Interface (gradio-app-ui.py)

The web interface provides an interactive chat experience with predefined examples.

```bash
./gradio-app-ui.py
```

**Features:**
- Interactive chat interface
- Message history preservation
- Predefined examples:
  - "Teach me Finance and banking"
  - "Translate this into french"
  - "Give me advice on best stock investments"
- Soft theme for comfortable viewing
- Real-time streaming responses

**Access:** Once started, the application will launch in your default web browser, typically at `http://localhost:7860`

### Command Line Interface (gradio-app-cli.py)

The CLI version provides a simple way to get responses directly in your terminal.

```bash
./gradio-app-cli.py
```

**Customization:** Modify the `main()` function to change the default query or add interactive input.

## Configuration

### Azure OpenAI Settings

Both applications are pre-configured with the following settings:

- **Endpoint:** `https://ai-foundry-instance.cognitiveservices.azure.com/`
- **Model:** `gpt-4o`
- **API Version:** `2024-12-01-preview`
- **Temperature:** `0.3` (for consistent, focused responses)
- **Max Tokens:** `4096`
- **Top P:** `1.0`

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `AI_FOUNDRY_KEY` | Your Azure OpenAI API key | Yes |

## File Structure

```
gradio-assistant/
├── gradio-app-ui.py      # Web interface application
├── gradio-app-cli.py     # Command-line interface application
├── requirements.txt      # Python dependencies
├── readme.md            # This documentation file
└── infra/               # Terraform infrastructure
    ├── main.tf          # Main resource definitions
    ├── variables.tf     # Input variables
    ├── dev.tfvars       # Development environment values
    ├── network.tf       # Network configuration
    ├── terraform.tf     # Provider configuration
    └── outputs.tf       # Output values
```

## Infrastructure Deployment (Terraform)

The `infra/` directory contains Terraform configuration for deploying Azure AI Foundry with secure networking:

<img src="assets/ai-foundry-architecture.png" alt="Gradio Assistant Web UI Screenshot" width="600">


### Quick Deploy

```bash
cd infra/
terraform init
terraform apply -var-file="dev.tfvars"
```

### Infrastructure Components

- **Azure AI Foundry** - GPT-4o model access with private networking
- **Virtual Network** - Private endpoints and agent subnets
- **Storage & Key Vault** - Supporting services for AI Foundry
- **Network Security** - Private access only, public access disabled

### Required Configuration

Update `dev.tfvars` with your Azure details:
```bash
subscription_id = "your-subscription-id"
tenant_id      = "your-tenant-id"
resource_group_name = "rg-assistant"
```

### Cleanup

```bash
terraform destroy -var-file="dev.tfvars"
```

## Error Handling

Both applications include comprehensive error handling:

- **Connection errors** - Handles Azure OpenAI service connectivity issues
- **API errors** - Manages authentication and quota-related errors
- **Streaming errors** - Gracefully handles interruptions in token streaming
- **User-friendly messages** - Displays clear error messages to users

## Development Notes

- The applications use the Azure OpenAI Python SDK
- Streaming is implemented with a small delay (0.03s) for smooth user experience
- The web interface maintains conversation history within the session
- The CLI interface processes single queries (can be extended for interactive mode)

## Troubleshooting

1. **"API key not found" error:**
   - Ensure `AI_FOUNDRY_KEY` environment variable is set
   - Verify the API key is valid and has proper permissions

2. **Connection timeout:**
   - Check your internet connection
   - Verify the Azure endpoint URL is correct
   - Confirm your Azure OpenAI service is active

3. **Import errors:**
   - Ensure all requirements are installed: `pip install -r requirements.txt`
   - Check Python version compatibility

## License

This project is provided as-is for educational and development purposes. 