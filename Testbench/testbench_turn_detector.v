`timescale 1ns / 1ps

module tb_EFSM_ABS_System;

    //--- segnali per il DUT (Device Under Test) 
    reg         clk;
    reg         reset;
    reg  [7:0]  wheel_speed;
    reg  [7:0]  vehicle_speed;
    reg  [1:0]  direction;
    reg         brake_signal;
    reg  [7:0]  accelerometer; // ho corretto il tipo per poter stimolare >1
    reg         engine_status;

    wire        Vrc1;
    wire        Vrc2;
    wire        recovery_pump;

    // Istanziazione DUT (Device Under Test)
    EFSM_ABS_System dut (
        .clk(clk),
        .reset(reset),
        .wheel_speed(wheel_speed),
        .vehicle_speed(vehicle_speed),
        .direction(direction),
        .brake_signal(brake_signal),
        .accelerometer(accelerometer),
        .engine_status(engine_status),
        .Vrc1(Vrc1),
        .Vrc2(Vrc2),
        .recovery_pump(recovery_pump)
    );

    // Clock: periodo 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Dump per GTKWave
    initial begin
        $dumpfile("tb_EFSM_ABS_System.vcd");
        $dumpvars(0, tb_EFSM_ABS_System);
    end

    // Monitoraggio dei segnali
    initial begin
        $display("time clk reset vs ws dir brk acc eng | Vrc1 Vrc2 pump");
        $monitor("%4t   %b   %b    %2d  %2d  %b   %2d   %b  |   %b    %b     %b",
                 $time, clk, reset,
                 vehicle_speed, wheel_speed,
                 brake_signal, accelerometer, engine_status,
                 Vrc1, Vrc2, recovery_pump);
    end

    // Stimoli
    initial begin
        // 1) Reset iniziale
        reset = 1;  
        wheel_speed   = 8'd50;
        vehicle_speed = 8'd50;
        direction     = 2'b00;
        brake_signal  = 0;
        accelerometer = 8'd0;
        engine_status = 0;
        #20;
        reset = 0;

        // 2) NORMAL_OPERATION (motore spento, freno non premuto)
        #20;

        // 3) Passo ad ANTILOCKING: accendo motore e premo freno, differenza sotto soglia
        engine_status = 1;
        brake_signal  = 1;
        wheel_speed   = 8'd45;  // slip = (50-45)/50 = 10% < soglia
        #20;

        // 4) Forzo slip > soglia per ANTILOCKING e RELEASE_PRESSURE
        wheel_speed   = 8'd30;  // slip = 40% > soglia
        #20;

        // 5) RELEASE_PRESSURE con sterzo a destra
        direction     = 2'b10;
        #30;

        // 6) RELEASE_PRESSURE con sterzo sinistra (valore_empirico influente)
        direction     = 2'b01;
        wheel_speed   = 8'd20;  // slip ulteriore
        #30;

        // 7) RELEASE_PRESSURE dritto, poi riprenderà NORMAL_OPERATION
        direction     = 2'b00;
        wheel_speed   = 8'd49;  // slip = 2% < soglia
        #30;

        // 8) Verifica REAPPLY_PRESSURE → ANTILOCKING ricorrente
        wheel_speed   = 8'd30;  
        #20;

        // 9) Dopo bloccaggio e attivazione pompa, torniamo a situazione normale
        // Disinserisco il freno e riallineo velocità ruota/veicolo
        brake_signal  = 0;
        wheel_speed   = vehicle_speed;  // ruota riprende la velocità del veicolo
        accelerometer = 8'd0;
        #50;
        // 10) Anomalia: wheel_speed > vehicle_speed durante frenata → falso negativo
        wheel_speed   = 8'd60;  // inverosimile, ruota più veloce del veicolo
        vehicle_speed = 8'd40;
        brake_signal  = 1;
        #20;

        // 11) Improvvisa perdita di aderenza (ice simulation)
        wheel_speed   = 8'd10;  // slip = 75%
        vehicle_speed = 8'd40;
        direction     = 2'b00;
        accelerometer = 8'd0;
        #20;

        // 12) Inversione direzione (simula sbandamento)
        direction     = 2'b10;
        #10;
        direction     = 2'b01;
        #10;
        direction     = 2'b11;  // condizione "non valida"
        #10;

        // 13) Accelerazione improvvisa con freno attivo
        accelerometer = 8'd50;
        brake_signal  = 1;
        engine_status = 1;
        vehicle_speed = 8'd60;
        wheel_speed   = 8'd20;
        #30;

        // 14) Freno intermittente (flickering)
        repeat (5) begin
            brake_signal = ~brake_signal;
            #3;
        end
        brake_signal = 1;
        #20;

        // 15) Ritorno graduale alla normalità
        wheel_speed   = 8'd58;
        vehicle_speed = 8'd60;
        brake_signal  = 0;
        direction     = 2'b00;
        accelerometer = 8'd0;
        #30;

        // 16) Finta anomalia del sensore (ruota a 0 ma auto in movimento)
        wheel_speed   = 8'd0;
        vehicle_speed = 8'd50;
        brake_signal  = 1;
        #30;

        // 17) Fine simulazione dopo stabilizzazione
        wheel_speed   = 8'd50;
        brake_signal  = 0;
        #30;

        // Verifica che recovery_pump torni a 0 e valvole a NORMAL_OPERATION
        #20;

        // Fine simulazione
        #20;
        $finish;
    end

endmodule
