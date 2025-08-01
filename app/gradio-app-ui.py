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

def predict(message, history):
    
    try:
        history.append({"role": "user", "content": message})

        stream = client.chat.completions.create(
            stream=True,
            messages=history,
            max_tokens=4096,
            temperature=0.3,
            top_p=1.0,
            model=deployment,
        )
    
        chunks = []
        for chunk in stream:
            if chunk.choices:
                chunks.append(chunk.choices[0].delta.content or "")
                yield "".join(chunks)
                time.sleep(0.03)
    except Exception as e:
        print("------------------------------------------------------")
        print(f"Something went wrong: {e}")
        print("------------------------------------------------------")
        yield "Error: " + str(e)    

demo = gr.ChatInterface(fn=predict, type="messages", theme="default", title="Finance Assistant", examples=["Teach me Finance and banking", "Translate this into french", "Give me advice on best stock investments"],)

demo.launch()



