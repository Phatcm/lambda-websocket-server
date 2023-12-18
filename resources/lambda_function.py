import json
import boto3
import os
import asyncio

dynamodb = boto3.client('dynamodb')

ENDPOINT = 'https://sr51rfrt51.execute-api.ap-northeast-1.amazonaws.com/production/'
client = boto3.client('apigatewaymanagementapi', endpoint_url=ENDPOINT)
names = {}

async def send_to_one(id, body):
    try:
        await client.post_to_connection(
            ConnectionId=id,
            Data=bytes(json.dumps(body), 'utf-8')
        )
    except Exception as err:
        print(err)

async def send_to_all(ids, body):
    all_tasks = [send_to_one(id, body) for id in ids]
    await asyncio.gather(*all_tasks)

    
def lambda_handler(event, context):
    if 'requestContext' in event:
        connectionId = event['requestContext']['connectionId']
        routeKey = event['requestContext']['routeKey']
        print(event)
        
        if 'body' in event:
            body = json.loads(event['body'])
            print(body)

        if routeKey == '$connect':
            print("Connection establish")
            #await send_to_all(get_all_connection_ids(), {'systemMessage': f"{name} has joined the chat"})
            pass
        
        elif routeKey == '$disconnect':
            asyncio.run(send_to_all(list(names), {'systemMessage': f"{names[connectionId]} has left the chat"}))
            del names[connectionId]
            asyncio.run(send_to_all(list(names), {'members': list(names.values())}))
            print("DISCONECTED")
            
        elif routeKey == '$default':
            # Handle default logic
            pass
        
        elif routeKey == 'setName':
            names[connectionId] = body['name']
            asyncio.run(send_to_all(list(names), {'members': list(names.values())}))
            print(list(names))
            asyncio.run(send_to_all(list(names), {'systemMessage': f"{names[connectionId]} has join the chat"}))
            print("THIS LINE COMPLETED")
            
        elif routeKey == 'sendPublic':
            asyncio.run(send_to_all(list(names), {'publicMessage': f"{names[connectionId]}: {body['message']}"}))
            
        elif routeKey == 'sendPrivate':
            #take the first key match, the to connectionid
            toId = next((key for key,values in names.items() if values == body['to']),None)
            plist = (toId,connectionId)
            asyncio.run(send_to_all(plist, {'privateMessage': f"{names[connectionId]}: {body['message']}"}))
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
