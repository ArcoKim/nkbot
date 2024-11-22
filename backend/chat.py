import os
import boto3
import json

kb_id = os.environ.get("KNOWLEDGE_BASE_ID")
bedrock = boto3.client("bedrock-agent-runtime")
model_arn = "arn:aws:bedrock:ap-northeast-2::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"

def retrieveAndGenerate(input, kbId, model_arn, sessionId):
    print(input, kbId, model_arn, sessionId)

    prompt = f"""
    모든 질문에 한국어로 대답해줘.
    질문 : {input}
    """
    if sessionId != "":
        return bedrock.retrieve_and_generate(
            input={
                "text": prompt
            },
            retrieveAndGenerateConfiguration={
                "type": "KNOWLEDGE_BASE",
                "knowledgeBaseConfiguration": {
                    "knowledgeBaseId": kbId,
                    "modelArn": model_arn
                }
            },
            sessionId=sessionId
        )
    else:
        return bedrock.retrieve_and_generate(
            input={
                "text": input
            },
            retrieveAndGenerateConfiguration={
                "type": "KNOWLEDGE_BASE",
                "knowledgeBaseConfiguration": {
                    "knowledgeBaseId": kbId,
                    "modelArn": model_arn
                }
            }
        )

def handler(event, context):
    body = json.loads(event["body"])
    query = body["question"]
    sessionId = body["sessionId"]
    response = retrieveAndGenerate(query, kb_id, model_arn, sessionId)
    generated_text = response["output"]["text"]
    print(generated_text)
    return {
        "answer": generated_text.strip(), 
        "sessionId": response["sessionId"]
    }