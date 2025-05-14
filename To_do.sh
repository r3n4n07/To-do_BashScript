#!/bin/bash

# Arquivo que guarda as tarefas
tasksFilePath="$HOME/Tasks.txt"

# Arquivo que guarda o número da última tarefa criada
numCountFilePath="$HOME/.NUMCOUNT.txt"

# Verifica se o número da tarefa é válido
isValidNumber () {
  NUMCOUNT=`cat $numCountFilePath`
  taskNumber=$1

  if ! [[ "$taskNumber" =~ ^[0-9]+$ ]]; then
   echo "Opção Inválida: o primeiro argumento deve ser o número da tarefa." >&2
   exit 1
  fi

  if (( $taskNumber <= 0 || $taskNumber > $NUMCOUNT)); then
    echo "Erro: O número da tarefa não existe.">&2
    exit 1
  fi
}

# Verifica se os argumentos são válidos
argumentsTotal () {
  argumentsTotalNumber=$1
  maxArguments=$2
  argumentLetter=$3
  example=$4

  if (($argumentsTotalNumber > $maxArguments)); then
    echo "Erro: ao utilizar a opção '$argumentLetter'."
    echo "Exemplo de como utilizar: $example">&2
    exit 1
  fi
}

# Verifica se o valor da tarefa está vazio
isTaskEmpty () {
  taskValue=$1

  if [ -z "$taskValue" ]; then
    echo "Erro: não se pode passar uma tarefar com valor vazio">&2
    exit 1
  fi
}

# Verifica se o arquivo existe
checkFileExists () {
  filePath=$1

  if [ ! -f "$filePath" ]; then
    echo "Erro: o arquivo '$filePath' não foi encontrado.">&2
    exit 1
  fi
}

# Resconstrói o arquivo Tasks.txt
rebuildFile () {
  rm "$tasksFilePath"
  touch "$tasksFilePath"
}


while getopts "i:e:c:d:l" opt; do

  case $opt in
    i)
	# Este caso inclui uma nova tarefa

	# Recebe o valor do argumento passado na execução do script
	task=$OPTARG

	argumentsTotal $# "2" "-i" 'comando -i "minha tarefa é..."'

	isTaskEmpty $task

	# Verifica se o arquivo de tarefas existe
	[ ! -f "$tasksFilePath" ] && touch "$tasksFilePath"

	# Verifica se o arquivo contador existe
	[ ! -f "$numCountFilePath" ] && echo 0 > "$numCountFilePath"

	# Lê o valor do arquivo contador
	NUMCOUNT=`cat "$numCountFilePath"`

	# Acrescenta 1 na variável contador
	NUMCOUNT=$((NUMCOUNT+1))

	# Lê o valor do arquivo de tarefas
	isTaskFileEmpty=`cat "$tasksFilePath"`

	# Verifica se o arquivo Tasks está vázio
	[ -z "$isTaskFileEmpty" ] && echo "$NUMCOUNT $task" > "$tasksFilePath" || echo "$NUMCOUNT $task" >> "$tasksFilePath"

	# Altera o valor do contador de NUMCOUNT.txt
	echo $NUMCOUNT > "$numCountFilePath"

	# Lista as tarefas
	cat "$tasksFilePath"
        ;;
    e)
	# Este caso edita uma tarefa

	# Recebe o valor do argumento passado na execução do script
	taskNumber=$OPTARG

	argumentsTotal $# "3" "-e" 'comando -e "1" "Minha tarefa editada"'

	isValidNumber $taskNumber

	# Recebe o valor passado como argumento da nova tarefa editada
	newTask="$3"

	isTaskEmpty $newTask

	checkFileExists $tasksFilePath

	# Cada tarefa será lida, linha por linha
	mapfile -t allTasks < "$tasksFilePath"

	rebuildFile

	for task in "${allTasks[@]}"
	do
	  # Comparamos o primeiro número de cada linha com o número da tarefa que deve ser editada
	  if [[ "${task:0:1}" != "$taskNumber" ]]; then
	   echo "$task" >> "$tasksFilePath"
	  else
	   echo "$taskNumber $newTask" >> "$tasksFilePath"
	  fi
	done

	# Lista as tarefas
	cat "$tasksFilePath"
        ;;
     c)
	# Este caso completa uma tarefa

	# Recebe o valor do argumento passado na execução do script
	taskNumber=$OPTARG

	argumentsTotal $# "2" "-c" 'comando -c "1"'

	isValidNumber $taskNumber

	# Cada tarefa será lida, linha por linha
	mapfile -t allTasks < "$tasksFilePath"

	rebuildFile

	for task in "${allTasks[@]}"
	do
	  if [[ "${task:0:1}" != "$taskNumber" ]]; then
	   echo "$task" >> "$tasksFilePath"
	  else
	   if [[ "$task" == *"[✓]" ]]; then
	      echo "$task" >> "$tasksFilePath"
	   else
	   echo "$task [✓]" >> "$tasksFilePath"
	   fi
	  fi
	done

	# Lista as tarefas
	cat "$tasksFilePath"
	;;
     d)
	# Este caso deleta uma tarefa

	# Recebe o valor do argumento passado na execução do script
	taskNumber=$OPTARG

	argumentsTotal $# "2" "-d" 'comando -d "1"'

	isValidNumber $taskNumber

	# Cada tarefa será lida, linha por linha
	mapfile -t allTasks < "$tasksFilePath"

	rebuildFile

	# Exclui o arquivo NUMCOUNT.txt
	rm "$numCountFilePath"

	# Inicia um novo contador
	NUMCOUNT=0

	for task in "${allTasks[@]}"
	do
	  if [[ "${task:0:1}" != "$taskNumber" ]]; then
	   NUMCOUNT=$((NUMCOUNT+1))
	   echo "$NUMCOUNT ${task:2}" >> "$tasksFilePath"
	  fi
	done

	# Atribui um novo valor para o arquivo NUMCOUNT.txt
	echo "$NUMCOUNT" > "$numCountFilePath"

	# Lista as tarefas
	cat "$tasksFilePath"
	;;
     l)

	# Este caso lista as tarefas

	argumentsTotal $# "1" "-l" 'comando -l'

	checkFileExists "$tasksFilePath"

	less "$tasksFilePath"
	;;
    \?)
        echo "Opção inválida -$OPTARG" >&2
	exit 1
	;;
    :)
	echo "A opção -OPTARG requer um argumento." >&2
	exit 1
	;;
    esac
done
