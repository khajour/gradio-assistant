#!/usr/bin/env python3

import logging
import time
import os
import random

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from openai import AzureOpenAI

endpoint = "https://aif-assistant.cognitiveservices.azure.com/"
deployment = "gpt-4o-model_deployment"
api_version = "2024-12-01-preview"

logging.basicConfig(level=logging.WARNING)

# Set up Azure AD token provider
token_provider = get_bearer_token_provider(
    DefaultAzureCredential(), 
    "https://cognitiveservices.azure.com/.default"
    )

# Initialize the Azure OpenAI client with Azure AD authentication
# Make sure you added <Cognitive Services OpenAI Contributor> role to your user in the portal for AI Foundry instance
client = AzureOpenAI(
    api_version=api_version,
    azure_endpoint=endpoint,
    azure_ad_token_provider=token_provider
)

def predict(message):
    
    try:
        stream = client.chat.completions.create(
            stream=True,
            messages=[
                    {
                "role": "user",
                "content": message,
            }
            ],
            max_tokens=4096,
            temperature=0.3,
            top_p=1.0,
            model=deployment,
        )
    

        for chunk in stream:
            if chunk.choices:
                print(chunk.choices[0].delta.content, end='', flush=True)
                time.sleep(0.03)

    except Exception as e:
        print("------------------------------------------------------")
        print(f"Something went wrong: {e}")
        print("------------------------------------------------------")
        return None

def main():
    predict(message="I am going to Zurich, what should I see?")

if __name__ == "__main__":
    main()

