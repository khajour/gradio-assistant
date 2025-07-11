#!/usr/bin/env python3

import gradio as gr
#import aifprivate as ai_foundry
import time
import os
from openai import AzureOpenAI
import random

endpoint = "https://aiaibankby42.cognitiveservices.azure.com/"
deployment = "gpt-4o"

# export AI_FOUNDRY_KEY="YOUR KEY"
subscription_key = os.environ.get('AI_FOUNDRY_KEY')
api_version = "2024-12-01-preview"
client = AzureOpenAI(
    api_version=api_version,
    azure_endpoint=endpoint,
    api_key=subscription_key,
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

