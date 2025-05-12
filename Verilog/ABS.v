`timescale 1ns / 1ps

module EFSM_ABS_System(
    input clk, // clock del sistema
    input reset, // reset del sistema
    input [7:0] wheel_speed, // velocità di una ruote
    input [7:0] vehicle_speed, // velocità del veicolo
    input [1:0] direction, // direzione del veicolo (0 = dritto, 1 = sinistra, 2 = destra)
    input direction, // direzione del veicolo (0 = dritto, 1 = sinistra, 2 = destra)
    input brake_signal, // segnale del pedale del freno
    input accelerometer, // accelerometro
    input engine_status, // stato del motore
    output reg Vrc1, // output elettrovavola, 1 bit perchè ha due stati (aperto o chiuso)
    output reg Vrc2, // output elettrovavola 2, 1 bit perchè ha due stati (aperto o chiuso)
    output reg recovery_pump // pompa di recupero, 1 bit perchè ha due stati (attiva o non attiva)
);


    parameter // Stati della macchina a stati
    NORMAL_OPERATION = 2'b00, // Funzionamento normale
    ANTILOCKING = 2'b01, // Stato di blocco delle ruote
    RELEASE_PRESSURE = 2'b10, // Rilascio della pressione frenante
    REAPPLY_PRESSURE = 2'b11;  // Riadattamento della pressione frenante

    reg[2:0] current_state, next_state; // Stato corrente e successivo

    reg cont = 1'b0;  // contatore per contare quante volte interviene l'ABS
    reg valore_empirico = 16'd26; // valore empirico per quando si sterza a destra o sinistra, 0,1 rappresentato in Q8.8

    // Parametri di soglia (REGOLABILI)
    parameter SPEED_THRESHOLD = 8'd10;  // Differenza di velocità accettabile

    // Stato successivo e logica della macchina a stati
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= NORMAL_OPERATION;
        else
            current_state <= next_state;
    end

    // Logica combinatoria per le transizioni degli stati
    always @(*) begin // il blocco always @(*) viene eseguito ogni volta che uno dei segnali di input cambia
        next_state = current_state;
        case (current_state)
            NORMAL_OPERATION: begin
                if (vehicle_speed > 3'b101 && engine_status == 1'b1 && brake_signal == 1'b1 && ((vehicle_speed - wheel_speed) / vehicle_speed) < SPEED_THRESHOLD) begin
                    next_state = ANTILOCKING; // se il motore e' acceso e il pedale del freno e' premuto e la differenza di velocita' e' minore della soglia, allora passo allo stato di antilocking
                end
                else begin 
                    next_state = NORMAL_OPERATION; // rimango nello stato di normal operation
                end
            end
            
            ANTILOCKING: begin
                if(vehicle_speed > 3'b101 && (vehicle_speed - wheel_speed) / vehicle_speed > SPEED_THRESHOLD || accelerometer > 1 || cont > 7) begin // controllo se la strada e' possibilmente bagnata, controllo che lo slip sia maggiore del 25%
                    Vrc1 = 1'b0; // chiudo la valvola 1
                    next_state = RELEASE_PRESSURE; // passo allo stato di rilascio della pressione frenante
                end else begin
                    next_state = NORMAL_OPERATION; // rimango nello stato di normal operation
                end
            end

            RELEASE_PRESSURE: begin
                if(direction == 2'b10) begin // sto sterzando a destra
                    if (vehicle_speed > 3'b101 && (vehicle_speed - wheel_speed) / vehicle_speed > SPEED_THRESHOLD || accelerometer > 1 || cont > 7) begin
                        Vrc2 = 1'b1; // apro la valvola 2, scarico la pressione
                        if ((vehicle_speed - wheel_speed) / vehicle_speed > SPEED_THRESHOLD) begin
                            recovery_pump = 1'b1; // attivo la pompa di recupero
                            next_state = ANTILOCKING; // sto ancora bloccando le ruote
                        end
                    end
                end
                if(direction == 2'b01) begin // sto sterzando a sinistra
                    if (vehicle_speed > 3'b101 && ((vehicle_speed - wheel_speed) / vehicle_speed) + valore_empirico > SPEED_THRESHOLD || accelerometer > 1 || cont > 7) begin
                        Vrc2 = 1'b1; // apro la valvola 2, scarico la pressione
                        if ((vehicle_speed - wheel_speed) / vehicle_speed > SPEED_THRESHOLD) begin
                            recovery_pump = 1'b1; // attivo la pompa di recupero
                            next_state = ANTILOCKING; // sto ancora bloccando le ruote

                        end
                    end
                end
                if(direction == 2'b00) begin // sto andando dritto
                    if (vehicle_speed > 3'b101 && (vehicle_speed - wheel_speed) / vehicle_speed > SPEED_THRESHOLD || accelerometer > 1 || cont > 7) begin
                        Vrc2 = 1'b1; // apro la valvola 2, scarico la pressione
                        if ((vehicle_speed - wheel_speed) / vehicle_speed > SPEED_THRESHOLD) begin
                            recovery_pump = 1'b1; // attivo la pompa di recupero
                            next_state = ANTILOCKING; // sto ancora bloccando le ruote
                        end
                    end
                end
                else begin // non sto piu bloccando
                    next_state = REAPPLY_PRESSURE; // riappllico la pressione frenante
                end
            end

             REAPPLY_PRESSURE: begin
                if ((vehicle_speed - wheel_speed) / vehicle_speed > SPEED_THRESHOLD || accelerometer > 1 || cont > 7) begin
                    next_state = ANTILOCKING;
                    cont = cont + 1; // incremento il contatore, ho completato un ciclo di ABS
                end else begin
                    Vrc2 = 1'b0; // chiudo la valvola 2, riapplico la pressione
                    recovery_pump = 1'b0; // disattivo la pompa di recupero
                    Vrc1 = 1'b1; // riapro la valvola 1, riapplico la pressione
                    next_state = NORMAL_OPERATION; // rimango nello stato di normal operation, non sto piu bloccando le ruote
                end
            end
        endcase
    end

endmodule
