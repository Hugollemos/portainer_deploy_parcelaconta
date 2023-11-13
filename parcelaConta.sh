#!/bin/bash
# Defina suas variáveis
URL=$API_URL
API_KEY=$API_KEY
STACK_NAME=$STACK_NAME
FILE_PATH=$FILE_PATH
ENDPOINT=2
docker_api="$docker_api"
MANIPULA_CONTAINER="$docker_api/containers"
GET_IMAGE_SHA="$docker_api/images/json"
DELETE_IMAGE="$docker_api/images"
tags=$tags

  #Faz a solicitação pra URL das stacks e armazena a resposta em uma variável
  response=$(curl -k -X GET "$URL" -H "X-API-Key: $API_KEY" --insecure)
  echo "*******************************"
  echo "fim da chamada do response"
  echo "*******************************"

  # Faz a solicitação GET para a URL das stacks e armazena a resposta do SHA da imagem em uma variável
  response_get_sha=$(curl -k -X GET "$GET_IMAGE_SHA" -H "X-API-Key: $API_KEY")
  echo "fim da chamada do response do response_get_sha"
  echo "*******************************"

  # Obter o ID do contêiner com base na stack
  CONTAINER_ID=$(curl -k -X  GET "$MANIPULA_CONTAINER/json" -H "X-Api-Key: $API_KEY" | jq -r '.[] | select(.Names[] | contains("'$STACK_NAME'")) | .Id' )
  echo $CONTAINER_ID
  echo "fim da chamada do CONTAINER_ID" 
  echo "*******************************"

  # Obeter o SHA da imagem do contêiner
  CONTAINER_IMAGE=$(curl -k -X GET "$MANIPULA_CONTAINER/$CONTAINER_ID/json" -H "X-Api-Key: $API_KEY" | jq -r '.Image')
  echo $CONTAINER_IMAGE
  echo "fim da chamada do CONTAINER_ID" 
  echo "*******************************"

  # Filtra todas as tags do portainer baseado no nome da tag que foi fornecida
  filtered_tags=$(echo "$response_get_sha" | jq -r '.[] | select(.RepoTags) | .RepoTags[] | select(startswith("'"$tags"'"))')

  echo $filtered_tags
  echo "fim da chamada do filtered_tags" 
  echo "*******************************"

  echo "Tags filtradas para a imagem $tags"
  for fil in $filtered_tags; do
      echo "- $fil"
  done

  #Validando se a stack existe
  validar=$(echo "$response" | jq -e '.[] | select(.Name == "'"$STACK_NAME"'")' > /dev/null; echo $?)

  # Verifica se a stack está criada. SE SIM
if [ $validar -eq 0 ]; then
  
  # Extrai o valor do campo "Name" usando jq
  name=$(echo "$response" | jq -r '.[] | select(.Name == "'"$STACK_NAME"'") | .Name')
  echo "A Stack chamada $name está criada."

  # Obtém o ID da stack
  stack_id=$(echo "$response" | jq -r '.[] | select(.Name == "'"$STACK_NAME"'") | .Id')
  echo "O ID da stack $name é: $stack_id"

  # verifica se o container existe. SE SIM 
  if [ ! -z "$stack_id" ]; then

    # Solicitação para pausar a stack
    curl -k -s -X POST "$URL/$stack_id/stop" \
      -H "X-API-Key: $API_KEY" \
      -F "type=2" \
      -F "method=file" \
      -F "file=@$FILE_PATH" \
      -F "endpointId=$ENDPOINT" \
      -F "Name=$STACK_NAME" --insecure
      
    sleep 6

      echo "Deletando imagens..."
      echo "Deletando imagem T_T"
      curl -X DELETE "$DELETE_IMAGE/$CONTAINER_IMAGE" -H "X-API-Key: $API_KEY" --insecure
      echo "Imagem deletada. :)"

    sleep 6

    echo "entrando no processo de start da stack"
      # Solicitação para startar a stack
      curl -k -s -X POST "$URL/$stack_id/start" \
        -H "X-API-Key: $API_KEY" \
        -F "type=2" \
        -F "method=file" \
        -F "file=@$FILE_PATH" \
        -F "endpointId=$ENDPOINT" \
        -F "Name=$STACK_NAME" --insecure

  else 
    echo "STACK ENCONTRADA, PORÉM O CONTAINER NÃO FOI ENCONTRADO"

    # Solicitação para pausar a stack
    curl -k -s -X POST "$URL/$stack_id/stop" \
      -H "X-API-Key: $API_KEY" \
      -F "type=2" \
      -F "method=file" \
      -F "file=@$FILE_PATH" \
      -F "endpointId=$ENDPOINT" \
      -F "Name=$STACK_NAME" --insecure
    sleep 6

    echo "Deletando imagens..."
    echo "Deletando imagem T_T"
    curl -X DELETE "$DELETE_IMAGE/$CONTAINER_IMAGE" -H "X-API-Key: $API_KEY" --insecure
    echo "Imagem deletada. :)"

    sleep 5

    echo "entrando no processo de start da stack"
      # Solicitação para startar a stack
      curl -k -s -X POST "$URL/$stack_id/start" \
        -H "X-API-Key: $API_KEY" \
        -F "type=2" \
        -F "method=file" \
        -F "file=@$FILE_PATH" \
        -F "endpointId=$ENDPOINT" \
        -F "Name=$STACK_NAME" --insecure

  fi

else
  echo "======================================"
  echo "NENHUMA STACK DA APLICAÇÃO ENCONTRADA."
  echo "======================================"

      # Deletando a imagem. 
  echo "Deletando imagens..."
  echo "Deletando imagem T_T"
  curl -X DELETE "$DELETE_IMAGE/$CONTAINER_IMAGE" -H "X-API-Key: $API_KEY" --insecure
  echo "Imagem deletada. :)"

  sleep 5  

  echo "CRIANDO A NOVA STACK"
  echo "======================================"
    response=$(curl -v -X POST "$URL" \
    -H "X-API-Key: $API_KEY" \
    -F "type=2" \
    -F "method=file" \
    -F "file=@$FILE_PATH" \
    -F "endpointId=$ENDPOINT" \
    -F "Name=$STACK_NAME" --insecure)


  # Imprimir a resposta da requisição 
  echo "Resposta da solicitação POST: $response"

  # Extrair o valor do campo "Id" da nova stack usando jq
  id=$(echo "$response" | jq -r '.Id')

  # Imprimir o valor do Id
  echo "Nova Stack criada. Id: $id"
fi
