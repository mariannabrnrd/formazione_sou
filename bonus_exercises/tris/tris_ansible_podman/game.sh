#!/bin/bash

#Variabili globali
CELLS=(A1 A2 A3 B1 B2 B3 C1 C2 C3)
TURN=1
MOVE=""

#Se vogliamo resettare il gioco
reset_game(){
    for CELL in ${CELLS[@]}; do
        podman exec "$CELL" sh -c "echo EMPTY > /app/status.txt"
    done
    TURN=1
    echo "Reset del gioco completato!"
}

#Controlliamo la casistica di pareggio
check_draw(){
    for CELL in "${CELLS[@]}"; do
        STATUS=$(podman exec "$CELL" cat /app/status.txt)
        if [[ "$STATUS" == "EMPTY" ]]; then
            return 1
        fi
    done
    show_grid
    echo "Pareggio! Nessun giocatore ha vinto."
    game_end
}

#Se vogliamo giocare di nuovo
game_end(){
    while true; do
        read -r -p "Vuoi giocare di nuovo? (s/n): " ANSWER
        if [[ "$ANSWER" == "s" ]]; then
            reset_game
            break
        elif [[ "$ANSWER" == "n" ]]; then
            echo "Grazie per aver giocato!"
            reset_game
            exit 0
        else
            echo "Risposta non valida! Inserisci 's' o 'n'"
        fi
    done
}

#Controlliamo la casistica di vittoria
check_win(){

    #Creo una variabile per ogni cella
    for CELL in "${CELLS[@]}"; do
        declare "$CELL=$(podman exec "$CELL" cat /app/status.txt)"
    done
    for COMBO in \
        "$A1$A2$A3" "$B1$B2$B3" "$C1$C2$C3" \
        "$A1$B1$C1" "$A2$B2$C2" "$A3$B3$C3" \
        "$A1$B2$C3" "$A3$B2$C1"; do
        if [[ $COMBO == "XXX" ]]; then
            show_grid
            echo "Giocatore 1 (X) ha vinto!"
            game_end
            return
        elif [[ "$COMBO" == "OOO" ]]; then
            show_grid
            echo "Giocatore 2 (O) ha vinto!"
            game_end
            return
        fi
    done
}

#Cambiamo il turno del giocatore
change_turn(){
    if (( TURN == 1)); then
        TURN=2
    else
        TURN=1
    fi
}

#Scriviamo la mossa del giocatore
write_move(){
    if (( TURN == 1)); then
        podman exec "$MOVE" sh -c "echo X > /app/status.txt"
    else
        podman exec "$MOVE" sh -c "echo O > /app/status.txt"
    fi
}

#Prendiamo l'azione del giocatore
get_action(){
    
    #Ciclo finchè non riceviamo una mossa valida
    while true; do
        if (( TURN == 1)); then
            echo "Turno del giocatore 1 (X) inserisci una casella:"
        else
            echo "Turno del giocatore 2 (0) inserisci una casella:"
        fi

        #Leggiamo la mossa
        read -r MOVE
        #Inizializziamo a falso
        VALID=false

        #Controlliamo che la mossa sia valida
        for CELL in "${CELLS[@]}"; do
            if [[ "$MOVE" == "$CELL" ]]; then
                VALID=true
                break
            fi
        done

        #Se la mossa non è valida
        if [[ "$VALID" == "false" ]]; then
            echo "Casella non valida! Scegli tra: ${CELLS[@]}"
            continue
        fi

        #Verifichiamo che la casella sia vuota
        STATUS=$(podman exec "$MOVE" cat /app/status.txt)
        if [[ "$STATUS" != "EMPTY" ]]; then
            echo "Casella già occupata! Scegline un'altra."
            continue
        fi

        #Se siamo qui la mossa è valida
        break
    done
}

show_grid(){
    for CELL in "${CELLS[@]}"; do
        VALUE=$(podman exec "$CELL" cat /app/status.txt)
        if [[ "$VALUE" == "EMPTY" ]]; then
            VALUE="."
        fi
        declare "$CELL=$VALUE"
    done

    echo ""
    echo "      1     2     3"
    echo "A  |  $A1  |  $A2  |  $A3  |"
    echo "B  |  $B1  |  $B2  |  $B3  |"
    echo "C  |  $C1  |  $C2  |  $C3  |"
    echo ""
}

#Sanificazione
check_container(){
    RUNNING=$(podman ps --format "{{.Names}}" | grep -v "infra" | sort)
    EXPECTED=$(echo "${CELLS[@]}" | tr ' ' '\n' | sort)

    #Controlla che i container siano 9
    if [[ "$RUNNING" != "$EXPECTED" ]]; then
        echo "Errore: i container attivi non corrispondono alle 9 caselle!"
        echo "Container attivi: $RUNNING"
        exit 1
    fi

    #Controlla che i container siano vuoti
    for CELL in "${CELLS[@]}"; do
        STATUS=$(podman exec "$CELL" cat /app/status.txt)
        if [[ "$STATUS" != "EMPTY" ]]; then
            echo "Errore: il container $CELL non è vuoto!"
            exit 1
        fi
    done
}

reset_game(){
    for CELL in "${CELLS[@]}"; do
        podman exec "$CELL" sh -c "echo EMPTY > /app/status.txt"
    done
    TURN=1
    echo "Reset del gioco completato!"
}

trap 'echo ""; echo "Gioco interrotto! Reset del gioco..."; reset_game; echo "Arrivederci!"; exit 1' SIGINT

#Inizio gioco
check_container
echo "SI GIOCA!!"
while true; do
    show_grid
    get_action
    write_move
    change_turn
    check_win
    check_draw
done
